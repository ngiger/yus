FROM ruby:2.2.4-onbuild
CMD ["bundle", "exec", "bin/yusd"]

# RUN apt-get update &&  apt-get -y install postgresql-client-9.4

# The names for pgTest => db_host, yus_data => db_name must be in sync between
# docker-compose.yml, test/yus_demo.yml and Dockerfile
COPY 'test/yus_demo.yml' '/etc/yus/yus.yml'
COPY 'bin/yusd' '/usr/src/app/bin/yusd'

