FROM debian:10

# Set environment variables
ENV HOME=/home/gitpod
ENV PGDATA="/workspace/.pgsql/data"
ENV GEM_HOME="/workspace/.rvm"

# Update sources and install necessary packages
RUN printf "deb http://deb.debian.org/debian buster main contrib non-free\ndeb http://security.debian.org/debian-security buster/updates main\ndeb http://deb.debian.org/debian buster-updates main" > /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -yq sudo curl g++ gcc autoconf automake bison libc6-dev \
        libffi-dev libgdbm-dev libncurses5-dev libsqlite3-dev libtool \
        libyaml-dev make pkg-config sqlite3 zlib1g-dev libgmp-dev \
        libreadline-dev libssl-dev gnupg2 procps libpq-dev vim git postgresql postgresql-contrib && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Create Gitpod user with passwordless sudo
RUN useradd -l -u 33333 -G sudo -md $HOME -s /bin/bash gitpod && \
    echo '%sudo ALL=NOPASSWD:ALL' >> /etc/sudoers

WORKDIR $HOME

# Switch to Gitpod user
USER gitpod

# Install RVM and Ruby
RUN gpg2 --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB && \
    curl -sSL https://get.rvm.io | bash -s stable && \
    echo "rvm_gems_path=$HOME/.rvm" > ~/.rvmrc && \
    bash -lc "rvm install ruby-2.7.4 && rvm use ruby-2.7.4 --default" && \
    bash -lc "rvm get stable --auto-dotfiles"

# Install Heroku CLI
RUN curl https://cli-assets.heroku.com/install-ubuntu.sh | sh

# Setup PostgreSQL server for user gitpod
USER postgres
RUN /etc/init.d/postgresql start && \
    psql --command "CREATE USER gitpod WITH SUPERUSER PASSWORD 'gitpod';" && \
    createdb -O gitpod -D $PGDATA gitpod && \
    echo "host all all 0.0.0.0/0 md5" >> /etc/postgresql/11/main/pg_hba.conf && \
    echo "listen_addresses='*'" >> /etc/postgresql/11/main/postgresql.conf

# Expose the PostgreSQL port
EXPOSE 5432
