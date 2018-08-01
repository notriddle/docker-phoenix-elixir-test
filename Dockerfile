FROM janitortechnology/ubuntu-dev
# 16.04 "Xenial"
MAINTAINER Michael Howell "michael@notriddle.com"

ADD supervisord-append.conf /tmp

# Download Elixir/OTP and PostgreSQL
RUN curl -L https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb > /tmp/erlang-solutions.deb && \
    sudo dpkg -i /tmp/erlang-solutions.deb && \
    sudo apt-get update && \
    sudo apt-get -y install --no-install-recommends esl-erlang elixir vim zlib1g-dev libssl-dev openssl libcurl4-openssl-dev libreadline6-dev libpcre3 libpcre3-dev imagemagick postgresql postgresql-contrib-9.5 libpq-dev postgresql-server-dev-9.5 advancecomp gifsicle jhead jpegoptim libjpeg-turbo-progs optipng pngcrush pngquant gnupg2 libsqlite3-dev && \
    sudo rm -rf /var/lib/apt/lists/* && \
    (cat /tmp/supervisord-append.conf | sudo tee -a /etc/supervisord.conf) && \
    sudo rm -f /tmp/supervisord-append.conf && \
    mix local.hex --force && mix local.rebar --force

# Set up database
RUN sudo mkdir /var/run/postgresql/9.5-main.pg_stat_tmp && sudo chown postgres:postgres /var/run/postgresql/9.5-main.pg_stat_tmp && \
    (sudo runuser -u postgres -- /usr/lib/postgresql/9.5/bin/postgres -D /etc/postgresql/9.5/main/ 2>&1 > /dev/null &) && \
    sleep 1 && \
    # Bors will be running with user "postgres"
    sudo -u postgres psql -c "ALTER USER \"postgres\" WITH PASSWORD 'Postgres1234';" && \
    # Bors requires a UTF8 database, which means we have to change the PG template database to be UTF8
    sudo -u postgres psql -c "UPDATE pg_database SET datistemplate = FALSE WHERE datname = 'template1'" && \
    sudo -u postgres psql -c "DROP DATABASE template1" && \
    sudo -u postgres psql -c "CREATE DATABASE template1 WITH ENCODING = 'UTF8' TEMPLATE template0" && \
    sudo -u postgres psql -c "UPDATE pg_database SET datistemplate = TRUE WHERE datname = 'template1'"
