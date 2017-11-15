FROM tobig77/centos7-elixir

MAINTAINER Tobias Gerschner <tobias.gerschner@gmail.com>

ENV PATH=$PATH:/usr/local/elixir/bin
ENV ERL_AFLAGS="-kernel shell_history enabled"

RUN yum -y install inotify-tools make gcc
RUN su -lc "mix archive.install https://github.com/phoenixframework/archives/raw/master/phx_new.ez --force" developer

WORKDIR /opt/app
USER developer

CMD /bin/bash