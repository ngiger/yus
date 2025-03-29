# How to use the ywesee user Server (yus)

If you want to know why this software exists, please read https://github.com/zdavatz/oddb.org/blob/master/README.mdch.oddb.org


You must have a working installation of Ruby 3. and git.

    git clone https://github.com/zdavatz/yus.git
    cd yus
    bundle install
    bundle exec rake gem_install 

# Setup the necessary configuration files. 

  In this example we use user_tom as username and domain.com as the domain-name. He must be reachable by email via user_tom@domain.com
  Please adapt this to your need!

    mkdir -p /opt/src/yus/data/

If you do not yet have a private key you will have to create one with 

    ssh-keygen -t rsa -f /opt/src/yus/data/user_tom

    openssl x509 -outform der -in /opt/src/yus/data/user_tom.pem -out /opt/src/yus/data/user_tom.crt
do _not_ set a password for the key otherwise yus-server will always
ask you for a password at startup-time. You will set a password later
using sha256.rb.

ssh-keygen should have created the following two files

    /opt/src/yus/data/user_tom.pub 
    /opt/src/yus/data/user_tom

Create the file /opt/src/yus/data/user_tom.crt, by calling

    openssl req -key /opt/src/yus/data/user_tom -out /opt/src/yus/data/user_tom.crt  -new -x509 -batch -passin pass:''

Determine the SHA256 value of the root_pass (password for the yus root user, in this example hatakeyama). We
use the sha256.rb which is in the root of the yus checkout.

    ruby sha256.rb hatakeyama
  
Create the file /etc/yus/yus.yml with the following content (using the output of the previous command)

    ---
    root_name: user_tom@domain.com
    root_pass: 48714061119f3bb753a0c63dd4230f641ab79e58eb603fc263925c53580acdf1 # [the SHA2-hash of your password]
    log_level: DEBUG
    ssl_key:  /opt/src/yus/data/user_tom      # [path to an rsa private key]
    ssl_cert: /opt/src/yus/data/user_tom.crt  # [path to a ssl x509 certificate]
    session_timeout: 3600

Setup the PostgresDB like this

    sudo -iHu postgres
    psql -c "create user yus with password 'hatakeyama';"
    psql -c "create database yus with encoding 'utf-8' template template0;"
    psql -c "grant all privileges  on database yus to yus";
    exit

Verify that you have a line in you postgres /etc/postgresql-<veryion>/pg_hba.conf like the following

    local   all         all                               trust

If not you will get errors like this 'FATAL:  Peer authentication failed for user "yus" (DBI::OperationalError)' while verifying
that you can connect to your new postgres database yus as user yus. When asked for the password answer with hatakeyama

    psql --user=yus --host=localhost --password yus -c '\dT'
  
Now you should be able to start the yus-daemon

    bin/yusd &

## Note

It seems that the yus server can work without the enconding password 
string, but yus admin tools (yus_add_user etc.) do not work without
the password in my local environment.

root_pass is used when yus admin tools (yus_show, yus_add_user, etc.)
are called. ssl_key and ssl_cert files are used when yusd starts. If you set a
password when you generate the rsa private key, the password is required when yusd
starts. root_pass and ssl_key are independent from each other. The password does
not have to be the same.

Create a new user with

    yus_add_user user_tom@domain.com login org.oddb.RootUser

Verify that everthings is okay by calling

    yus_show user_tom@domain.com

## NOTE

  > This 'org.oddb.RootUser' is refered to in
  > http://scm.ywesee.com/?p=oddb.org/.git;a=blob;f=src/state/admin/login.rb;h=1d910af359a224036fc761187bcf960a0d734b80;hb=HEAD#l45
  >
  > oddb.org/state/admin/login.rb
  >  def viral_modules(user)
  >    [
  >      ['org.oddb.RootUser', State::Admin::Root],
  >      ['org.oddb.AdminUser', State::Admin::Admin],
  >      ['org.oddb.PowerUser', State::Admin::PowerUser],
  >      ['org.oddb.CompanyUser', State::Admin::CompanyUser],
  >      ['org.oddb.PowerLinkUser', State::Admin::PowerLinkUser],
  >    ].each { |key, mod|
  >      if(user.allowed?("login", key))
  >        yield mod
  >      end
  >    }
  >  end
  
Then you have to grant 

    yus_grant zdavatz@ywesee.com edit yus.entities  

like this you will get the 

Benutzer 

menu in ch.oddb.org

## Extensive user privileges

For installing extensive user privileges for ch.oddb.org you need to do the following:

  > 1. create RootUser group by
  >
  >   yus_add RootUser
  >
  > 2. create mhatakeyama@ywesee.com
  >
  >  yus_add_user mhatakeyama@ywesee.com login org.oddb.RootUser
  >
  > 3. add some privileges to RootUser
  >
  >  yus_grant RootUser edit yus.entities
  >  yus_grant RootUser login org.oddb.RootUser
  >  yus_grant RootUser edit org.oddb.drugs
  >
  > 4. check the RootUser group
  >
  >  Admin > Benutzer > mhatakeyama@ywesee.com
  >
  >  check the RootUser box
  >
  > 5. see the mhatakeyama@ywesee.com
  >
  > Then
  >
  >  edit yus.entities
  >  login org.oddb.RootUser
  >  edit org.oddb.drugs
  >
  > become gray. The other box can be checked, but
  > as a default of RootUser, the three privileges are checked.

To run the tests you call

    bundle install
    bundle exec rake test

## The setup is explained by

* Masa in http://dev.ywesee.com/wiki.php/Masa/20101019-debug-importGkv#SetYus
* Michal in http://dev.ywesee.com/wiki.php/Michal/DayTwo#dbi

