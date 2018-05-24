# Create a basic docker image which resembles the travis platform.
#
# See https://docs.travis-ci.com/user/reference/trusty/
#
# It will not have travis' build scripts which act on .travis.yml
# but it will be the same OS and apt-get packages available, useful 
# for testing Tubi build compatibility.
#
FROM ubuntu:trusty

# Add some packages that Tubi needs for Make-based build. These
# roughly resemble the .travis.yml 'install' target
RUN /usr/bin/apt-get update
RUN /usr/bin/apt-get install -y make
RUN /usr/bin/apt-get install -y rsync
RUN /usr/bin/apt-get install -y sudo
RUN /usr/bin/apt-get install -y curl

# Use a non-standard version of node from PPA
RUN curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
RUN /usr/bin/apt-get install -y nodejs

# Add a user besides root just to get familiar bash behavior
RUN useradd -ms /bin/bash build
RUN echo "build:build" | chpasswd
RUN adduser build sudo
USER build

# By default just launch into a shell
CMD /bin/bash
