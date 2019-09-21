# build wrapper
FROM golang:1.11.5 as builder
WORKDIR /go/src/csgo
COPY csgo/main.go .
COPY . /go/src/agones.dev/agones
RUN go build -o wrapper .

#final image


FROM ubuntu:18.04


COPY --from=builder /go/src/csgo/wrapper .
COPY --from=builder /go/src/csgo/CSGO ./CSGO

# VARIABLES

ENV USER csgo 
ENV HOME /home/$USER
ENV SERVER $HOME/hlserver

# INITIAL SETUP

#execute and confirm apt-get update
RUN apt-get -y update
#execute and confirm apt-get upgrade
RUN apt-get -y upgrade 
#install dependencies
RUN apt-get -y install lib32gcc1 curl net-tools lib32stdc++6 locales
RUN locale-gen en_US.UTF-8
RUN update-locale LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8 LC_ALL=en_US.UTF-8
RUN dpkg-reconfigure --frontend=noninteractive locales
#clean-up of tmp data
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
#add new user
RUN useradd $USER
#add home dir for user
RUN mkdir $HOME
#make user owner of home dir
RUN chown $USER:$USER $HOME
#add server dir
RUN mkdir $SERVER

# VARIABLES

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

#add files from container to server dir
ADD ./csgo_ds.txt $SERVER/csgo_ds.txt
ADD ./update.sh $SERVER/update.sh
ADD ./autoexec.cfg $SERVER/csgo/csgo/cfg/autoexec.cfg
ADD ./server.cfg $SERVER/csgo/csgo/cfg/server.cfg
ADD ./csgo.sh $SERVER/csgo.sh

#make user owner of server dir & make wrapper executeable
RUN chown -R $USER:$USER $SERVER . && chmod +x wrapper

#switch to user
USER $USER

#get steamcmd, unzip & update it
RUN curl http://media.steampowered.com/client/steamcmd_linux.tar.gz | tar -C $SERVER -xvz
RUN $SERVER/update.sh

#expose server port to the internet
EXPOSE 27015/udp

WORKDIR /home/$USER/hlserver
ENTRYPOINT /home/csgo/wrapper -i /home/csgo/CSGO/csgo.sh
CMD ["-console" "-usercon" "+game_type" "0" "+game_mode" "1" "+mapgroup" "mg_active" "+map" "de_cache"]