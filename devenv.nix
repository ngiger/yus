# Please look at the file [oddb.org/devenv.README.md](https://github.com/zdavatz/oddb.org/blob/ruby-3.2/devenv.README.md)
{ pkgs, config, ... }:

{
  env.GREET = "devenv";
  packages = [ pkgs.git pkgs.libyaml pkgs.procps pkgs.screen]; #  after I added pkgs.openssl here, I could no longer call devenup because of a glibc mismatch
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
    # echo Start the yus daemon in a secreen using; screen -R yus start_yusd
  languages.ruby.enable = true;
  languages.ruby.version = "3.4";
  services.postgres = {
    enable = true;
    package = pkgs.postgresql_16;
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

}
