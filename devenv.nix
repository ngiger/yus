# Please look at the file [oddb.org/devenv.README.md](https://github.com/zdavatz/oddb.org/blob/ruby-3.2/devenv.README.md)
{
  inputs,
  pkgs,
  config,
  lib,
  ...
}: let
  pkgs-old = import inputs.nixpkgs-old {system = pkgs.stdenv.system;};
  pkgs-unstable = import inputs.nixpkgs-unstable {system = pkgs.stdenv.system;};
in {
  env.GREET = "devenv";
  env.YUS_DB_BACKUP = "../db_yus_backup.bz2";
  env.YUS_DB_BACKUP_URL = "file:///opt/path_to_oddb/22:20-postgresql_database-yus-backup";
  packages = [
    pkgs.git
    pkgs.libyaml
    pkgs.nixfmt-rfc-style
    pkgs.openssl
    pkgs.bc
  ];
   #  after I added pkgs.openssl here, I could no longer call devenup because of a glibc mismatch
  # therefore I ${pkgs.openssl}/bin/openssl in the enterShell

  enterShell = ''
    echo This is the devenv shell for oddb2xml
    git --version
    ruby --version
    psql --version
    OLD_YUS_CRT=`git status --porcelain data;`
    if [[ -z $OLD_YUS_CRT ]]; then
      echo Must replace old yus certificat from 2006
      cd data
      pwd
      ${pkgs.openssl}/bin/openssl req -nodes -new -x509 -key yus.key -out yus.crt -subj "/C=CH/ST=Zurich/L=Zurich/O=ywesee GmbH/OU=IT Department CI/CN=ywesee.com"
    else
      echo Found changed data/yus.key
    fi
    bundle install
  '';

  enterTest = ''
    ruby --version
    psql --version
    bundle exec rake test
  '';

  languages.ruby.enable = true;
#  languages.ruby.version = "3.4";
  services.postgres = {
    enable = true;
    package = pkgs.postgresql_17;
    listen_addresses = "0.0.0.0";
    port = 5435;

    initialDatabases = [
      { name = "yus"; }
    ];

    initdbArgs =
      [
        "--locale=C"
        "--encoding=UTF8"
      ];

    initialScript = ''
      create role yus superuser login password null;
      \connect yus;
      \i ../22:20-postgresql_database-yus-backup
    '';
  };

  scripts.wait_for_port_open = {
   package = config.languages.ruby.package;

  exec = ''
      require 'open-uri'
      def connected?(port)
        res = `netstat -tulpen 2>/dev/null| grep #{port}`
        return false unless res&.length > 0
        found = /\:#{port}\s/.match(res)
        return found && (found.length > 0)
      end

      port = ARGV[0]
      while !connected?(port)
          sleep 1
          puts "port: #{port} open? #{connected?(port)}"
      end
        puts "port: #{port} is now connected"
      '';
      };
    scripts.start_yusd.exec = ''
      set -eux
      devenv processes start --detach
      wait_for_port_open 5435 # the postgresql port
      tail -n1 .devenv/processes.log # just to be sure
      bundle install
      bundle exec ruby bin/yusd &
    '';
    scripts.stop_yusd.exec = ''
      set -v
      pkill -f "ruby bin/yusd\$" | true
      devenv processes stop
    '';


    scripts.dump_yus.exec = ''
      set -v
      pg_dump -f yus_dump -Z9 yus.gz
    '';

  scripts.get_yus_database_backup.exec = ''
    set -veux
    if [ ! -f ${config.env.YUS_DB_BACKUP} ]; then
      echo Must download the file ${config.env.YUS_DB_BACKUP}
      ${pkgs.curl}/bin/curl -o ${config.env.YUS_DB_BACKUP} ${config.env.YUS_DB_BACKUP_URL}
    else
      echo I am testing whether I have to update ${config.env.YUS_DB_BACKUP}
      ${pkgs.curl}/bin/curl -z ${config.env.YUS_DB_BACKUP} ${config.env.YUS_DB_BACKUP_URL}
    fi
    ls -l ${config.env.YUS_DB_BACKUP}
  '';


  scripts.load_yus_database_backup.package = pkgs.fish;
  scripts.load_yus_database_backup.exec = ''
    echo (date) started load_yus_database_backup > steps_1.log
    get_yus_database_backup
    echo (date) got get_yus_database_backup status $status >> steps_1.log
    stop_oddb_daemons
    ensure_pg_running
    start-postgres &
    ${pkgs-old.postgresql_10}/bin/psql -c "create role postgres superuser login password null;" postgres | echo Done
    ${pkgs-old.postgresql_10}/bin/psql -c "drop database if exists yus;" postgres
    ${pkgs-old.postgresql_10}/bin/psql -c "create database yus;" postgres
    ${pkgs.bzip2}/bin/bzcat ${config.env.YUS_DB_BACKUP} | ${pkgs-old.postgresql_10}/bin/psql yus
    ${pkgs-old.postgresql_10}/bin/psql yus -c "select count(*) from object;" # ensure that load_yus_database_backup was run
    echo (date) Finished load_yus_database_backup status $status >> steps_1.log
  '';

}
