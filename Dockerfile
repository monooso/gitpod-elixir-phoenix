FROM gitpod/workspace-full

# -----------------------------------------------------------------------------
# PostgreSQL
# -----------------------------------------------------------------------------
# Install PostgreSQL 15
ENV PGWORKSPACE="/workspace/.pgsql"
ENV PGDATA="$PGWORKSPACE/data"

RUN sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' \
    && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - \
    && sudo apt -y update

RUN sudo install-packages postgresql-15 postgresql-contrib-15

# Setup PostgreSQL server for user gitpod
ENV PATH="/usr/lib/postgresql/15/bin:$PATH"

SHELL ["/usr/bin/bash", "-c"]
RUN PGDATA="${PGDATA//\/workspace/$HOME}" \
 && mkdir -p ~/.pg_ctl/bin ~/.pg_ctl/sockets $PGDATA \
 && initdb -D $PGDATA \
 && printf '#!/bin/bash\npg_ctl -D $PGDATA -l ~/.pg_ctl/log -o "-k ~/.pg_ctl/sockets" start\n' > ~/.pg_ctl/bin/pg_start \
 && printf '#!/bin/bash\npg_ctl -D $PGDATA -l ~/.pg_ctl/log -o "-k ~/.pg_ctl/sockets" stop\n' > ~/.pg_ctl/bin/pg_stop \
 && chmod +x ~/.pg_ctl/bin/*
ENV PATH="$HOME/.pg_ctl/bin:$PATH"
ENV DATABASE_URL="postgresql://gitpod@localhost"
ENV PGHOSTADDR="127.0.0.1"
ENV PGDATABASE="postgres"
COPY --chown=gitpod:gitpod ./start-db.bash $HOME/.bashrc.d/200-start-db

# -----------------------------------------------------------------------------
# Install asdf, used to manage language versions
# -----------------------------------------------------------------------------
RUN brew install asdf

# Ensure the correct language versions are used in the shell
RUN bash -c ". $(brew --prefix asdf)/libexec/asdf.sh" \
    && echo -e "\n. $(brew --prefix asdf)/libexec/asdf.sh" >> ~/.bashrc

# -----------------------------------------------------------------------------
# Erlang
# -----------------------------------------------------------------------------
# Install dependencies
RUN sudo install-packages \
    build-essential autoconf m4 libncurses5-dev libwxgtk3.0-gtk3-dev libwxgtk-webview3.0-gtk3-dev \
    libgl1-mesa-dev libglu1-mesa-dev libpng-dev libssh-dev unixodbc-dev xsltproc fop libxml2-utils libncurses-dev openjdk-11-jdk

# Add the asdf Erlang plugin
RUN asdf plugin add erlang

# Install the required version of Erlang, and set it globally
RUN asdf install erlang 25.2 && asdf global erlang 25.2

# -----------------------------------------------------------------------------
# Elixir
# -----------------------------------------------------------------------------
# Install dependencies
RUN sudo install-packages unzip

# Add the asdf Erlang plugin
RUN asdf plugin add elixir

# Install the required version of Elixir, and set it globally
RUN asdf install elixir 1.14-otp-25 && asdf global elixir 1.14-otp-25

# -----------------------------------------------------------------------------
# Node.js
# -----------------------------------------------------------------------------
# Install dependencies
RUN sudo install-packages python3 g++ make python3-pip

# Add the asdf Node.js plugin
RUN asdf plugin add nodejs

# Install the required version of Node.js, and set it globally
RUN asdf install nodejs 18.13.0 && asdf global nodejs 18.13.0

# -----------------------------------------------------------------------------
# Oddments
# -----------------------------------------------------------------------------
# Install Phoenix dependencies
RUN sudo install-packages inotify-tools

# Install Hex and Rebar
RUN asdf reshim \
    && mix local.hex --force \
    && mix local.rebar --force

USER gitpod
