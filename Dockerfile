FROM debian:buster-slim

ARG DOCKER_VERSION="20.10.5"
ARG HELM_VERSION="3.5.2"

ENV GITHUB_PAT ""
ENV GITHUB_OWNER ""
ENV GITHUB_REPOSITORY ""
ENV RUNNER_WORKDIR "_work"
ENV RUNNER_LABELS ""

RUN apt-get update \
    && apt-get install -y \
        curl \
        sudo \
        git \
        jq \
        iputils-ping \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -m github \
    && usermod -aG sudo github \
    && echo "%sudo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

#install docker client
RUN curl https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz --output docker-${DOCKER_VERSION}.tgz \
    && tar xvfz docker-${DOCKER_VERSION}.tgz \
    && cp docker/* /usr/bin/

#install helms
RUN curl https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz --output helm-${HELM_VERSION}.tgz \
    && tar xvfz helm-${HELM_VERSION}.tgz \
    && cp linux-amd64/helm /usr/bin/

RUN helm plugin install https://github.com/aslafy-z/helm-git --version 0.10.0

USER github
WORKDIR /home/github

RUN GITHUB_RUNNER_VERSION=$(curl --silent "https://api.github.com/repos/actions/runner/releases/latest" | jq -r '.tag_name[1:]') \
    && curl -Ls https://github.com/actions/runner/releases/download/v${GITHUB_RUNNER_VERSION}/actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz | tar xz \
    && sudo ./bin/installdependencies.sh

COPY --chown=github:github entrypoint.sh runsvc.sh ./
RUN sudo chmod u+x ./entrypoint.sh ./runsvc.sh

ENTRYPOINT ["/home/github/entrypoint.sh"]
