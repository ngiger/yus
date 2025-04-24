#!/usr/bin/env ruby
require 'fileutils'

puts  $PROGRAM_NAME
exit
RSA_NAME="test_user"
YUS_ROOT="admin"
ROOT_USER="root_user"
ROOT_PW="root_secret"
SHA_CMD="sha256sum"
oddb_group='oddb_group'
oddb_user='desitin'

rsaFile = "#{YUS_ROOT}/data/#{RSA_NAME}_rsa"
crtFile = "#{rsaFile}.crt"
puts "RSA_NAME ist #{RSA_NAME} rsaFile is #{rsaFile} crt #{crtFile}"
ENV['HOME'] ||= '/tmp' # or yus_add_user would fail

def grantAllToRootUser
  passwd3File="#{ENV['HOME']}/passwd3.tmp"
  puts passwd3File
  pwFile = File.open(passwd3File, 'w+')
  pwFile.puts ROOT_PW
  pwFile.puts ROOT_PW
  pwFile.puts ROOT_PW
  pwFile.close
  cmd = "bin/yus_add_user #{ROOT_USER} login org.oddb.RootUser <#{passwd3File}"
  puts cmd
  exit 1 unless system(cmd) 

  passwdFile="#{ENV['HOME']}/passwd2.tmp"
  pwFile = File.open(passwdFile, 'w+')
  pwFile.puts ROOT_PW
  pwFile.close

  # yus_add_user #{ROOT_USER} login org.oddb.#{ROOT_USER} <#{passwdFile}
  setupUser = %(echo #{ROOT_PW} | yus_grant #{ROOT_USER} grant login 
echo #{ROOT_PW} | yus_grant #{ROOT_USER} grant view 
echo #{ROOT_PW} | yus_grant #{ROOT_USER} grant create 
echo #{ROOT_PW} | yus_grant #{ROOT_USER} grant edit 
echo #{ROOT_PW} | yus_grant #{ROOT_USER} grant credit 
echo #{ROOT_PW} | yus_grant #{ROOT_USER} edit yus.entities 
echo #{ROOT_PW} | yus_grant #{ROOT_USER} edit org.oddb.drugs 
echo #{ROOT_PW} | yus_grant #{ROOT_USER} edit 'org.oddb.model.!company.*' 
echo #{ROOT_PW} | yus_grant #{ROOT_USER} edit 'org.oddb.model.!sponsor.*' 
echo #{ROOT_PW} | yus_grant #{ROOT_USER} edit 'org.oddb.model.!indication.*' 
echo #{ROOT_PW} | yus_grant #{ROOT_USER} edit 'org.oddb.model.!galenic_group.*' 
echo #{ROOT_PW} | yus_grant #{ROOT_USER} edit 'org.oddb.model.!address.*' 
echo #{ROOT_PW} | yus_grant #{ROOT_USER} edit 'org.oddb.model.!atc_class.*' 
echo #{ROOT_PW} | yus_grant #{ROOT_USER} create org.oddb.registration 
echo #{ROOT_PW} | yus_grant #{ROOT_USER} create org.oddb.task.background 
echo #{ROOT_PW} | yus_grant #{ROOT_USER} view org.oddb.patinfo_stats 
echo #{ROOT_PW} | yus_grant #{ROOT_USER} credit org.oddb.download 
)

cmdsForOtherUser = %(
echo #{ROOT_PW} | yus_add_user  AdminUser       login org.oddb.AdminUser 
echo #{ROOT_PW} | yus_grant     AdminUser       edit org.oddb.drugs 
echo #{ROOT_PW} | yus_grant     AdminUser       create org.oddb.registration 
echo #{ROOT_PW} | yus_grant     AdminUser       edit 'org.oddb.model.!galenic_group.*' 
echo #{ROOT_PW} | yus_add_user  CompanyUser     login org.oddb.CompanyUser 
echo #{ROOT_PW} | yus_grant     CompanyUser     edit org.oddb.drugs 
echo #{ROOT_PW} | yus_grant     CompanyUser     create org.oddb.registration 
echo #{ROOT_PW} | yus_grant     CompanyUser     edit 'org.oddb.model.!galenic_group.*' 
echo #{ROOT_PW} | yus_grant     CompanyUser     view org.oddb.patinfo_stats.associated 
echo #{ROOT_PW} | yus_add_user  PowerLinkUser   login org.oddb.PowerLinkUser 
echo #{ROOT_PW} | yus_grant     PowerLinkUser   edit org.oddb.drugs 
echo #{ROOT_PW} | yus_grant     PowerLinkUser   edit org.oddb.powerlinks 
echo #{ROOT_PW} | yus_add_user  PowerUser login org.oddb.PowerUser 
echo #{ROOT_PW} | yus_add_user  DownloadUser 
)
#  FileUtils.rm_f(passwdFile, :verbose => true)

  setupUser.split("\n").each{
    |line|
      puts "Running: " + line
      res = system(line)
      unless res
        puts "running '#{line}' failed res #{res.inspect}"
        exit 1
      end
  }
end
cmd = "chown -R <%= scope.lookupvar('oddb_user')f%>:<%= scope.lookupvar('oddb_group') %> #{YUS_ROOT}"
puts cmd
# exit 1 unless system(cmd)

grantAllToRootUser
