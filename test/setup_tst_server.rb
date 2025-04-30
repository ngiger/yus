#!/usr/bin/env ruby
# Copyright (c) 2025 Niklaus Giger niklaus.giger@member.fsf.org
# Used to setup an yus server for running unit tests
# Uses an sqlite3 in memory base
require 'fileutils'
require "digest/sha2"
require 'socket'

RSA_NAME="test_user"
YUS_ROOT="admin"
YUS_ROOT_EMAIL="user_tom@example.com"
ROOT_USER="root_user"
ROOT_PW="top_secret"

TEST_DATA_DIR=File.expand_path(File.dirname(__FILE__) + '/data')

def setup_test_server
  FileUtils.makedirs(TEST_DATA_DIR, verbose: true) unless File.exist?(TEST_DATA_DIR)
  cmd = "ssh-keygen -t rsa -f #{TEST_DATA_DIR}/user_tom -b 4096 -C 'user_tom@domain.com' -q -N ''"
  puts cmd
  res =  system(cmd)
  puts res
  cmd = "openssl genrsa -out  /opt/src/yus/test/data/user_tom.pem 2048"
#    openssl x509 -outform der -in /opt/src/yus/data/user_tom.pem -out /opt/src/yus/data/user_tom.crt

  exit(3) unless res
  yml_file = create_yus_yml
  puts "Created files needed for a yus server under #{TEST_DATA_DIR}"
  start_yusd = "bin/yusd -c #{yml_file}"
  puts start_yusd
  yus_add_rootuser = "bin/yus_add_user -c #{yml_file} -r admin"
  puts yus_add_rootuser
  system(start_yusd)
  system(yus_add_rootuser)
end

def create_yus_yml(yml_file = TEST_DATA_DIR + '/yus.yml')
  hexdigest =  Digest::SHA256.hexdigest(ROOT_PW)
  puts "YUS_ROOT is #{YUS_ROOT} whith password #{ROOT_PW} => sh256 #{hexdigest}"
  # create passwortless key.pem and cert.pem
  # DO NOT USE this on a production server!
  res = system("openssl req -x509 -newkey rsa:4096 -keyout #{TEST_DATA_DIR}/key.pem -out #{TEST_DATA_DIR}/cert.pem -days 10000 -nodes   -subj '/C=US/ST=Delaware/L=Delaware/O=SELFSIGNED/CN=#{Addrinfo.getaddrinfo(Socket.gethostname, nil).first.getnameinfo}'")
  exit(4) unless res

  File.open(yml_file, 'w+') do |file|
    file.puts(
%(---
    root_name: #{YUS_ROOT_EMAIL}
    root_pass: #{hexdigest} # [the SHA2-hash of your password]
    log_level: DEBUG
    db_name: sqlite
    unit_test:   true
    config: #{yml_file}
    yus_dir: #{TEST_DATA_DIR}
    ssl_key:  #{TEST_DATA_DIR}/user_tom      # [path to an rsa private key]
    ssl_cert: #{TEST_DATA_DIR}/user_tom.crt  # [path to a ssl x509 ceortificate]
    session_timeout: 3600))
  end
  yml_file
end

setup_test_server

commands_that_show_work = [
  'echo 1234 | bundle exec bin/yus_show info@desitin.ch',
  'echo 1234\ndesitin\ndesitin | bundle exec bin/yus_passwd info@desitin.ch',
  'echo 1234 | bundle exec bin/yus_dump test.yml',
  'echo 1234\n1234 | bundle exec bin/yus_grant info@desitin.ch grant reader2 --revoke',
  'echo 1234\n5678\n5678 | bundle exec bin/yus_add_user -v test@test.com', # fails PG unique
  'echo 1234 | bundle exec bin/yus_delete_user info@desitin.ch'

# bin/yusd -c /opt/src/yus/test/data/yus.yml
# bin/yus_add_user -c /opt/src/yus/test/data/yus.yml -r admin
