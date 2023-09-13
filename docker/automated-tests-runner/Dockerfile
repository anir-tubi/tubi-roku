# Originally based off of https://github.com/actions/runner/blob/main/images/Dockerfile with some modification

# Source: https://github.com/dotnet/dotnet-docker
FROM mcr.microsoft.com/dotnet/runtime-deps:6.0-jammy as build

WORKDIR /home/runner

ARG RUNNER_VERSION="2.307.1"
ARG RUNNER_ARCH

RUN apt update -y && apt install curl unzip -y

RUN curl -f -L -o runner.tar.gz https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz \
    && tar xzf ./runner.tar.gz \
    && rm runner.tar.gz

ENV ACTIONS_RUNNER_PRINT_LOG_TO_STDOUT=1

RUN apt-get update -y \
    && apt-get install -y --no-install-recommends \
    sudo \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

RUN adduser --disabled-password --gecos "" --uid 1001 runner \
    && groupadd docker --gid 123 \
    && usermod -aG sudo runner \
    && usermod -aG docker runner \
    && echo "%sudo   ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers \
    && echo "Defaults env_keep += \"DEBIAN_FRONTEND\"" >> /etc/sudoers

USER runner

# Start our own content

# Setup runner config

ARG url
ARG token
ARG name

RUN ./config.sh --unattended --url ${url} --token ${token} --name "${name}" --labels automated-tests-runner,enabled

COPY rta-config.json rta-config.json

CMD ./run.sh
