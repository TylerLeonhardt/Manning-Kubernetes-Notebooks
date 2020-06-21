FROM jupyter/minimal-notebook:latest

# Install .NET CLI dependencies

ARG NB_USER=jovyan
ARG NB_UID=1000
ENV USER ${NB_USER}
ENV NB_UID ${NB_UID}
ENV HOME /home/${NB_USER}

WORKDIR ${HOME}

# Use root to install .NET
USER root

RUN apt-get update \
    && apt-get install -y curl

ENV \
    # Enable detection of running in a container
    DOTNET_RUNNING_IN_CONTAINER=true \
    # Enable correct mode for dotnet watch (only mode supported in a container)
    DOTNET_USE_POLLING_FILE_WATCHER=true \
    # Skip extraction of XML docs - generally not useful within an image/container - helps performance
    NUGET_XMLDOC_MODE=skip \
    # Opt out of telemetry until after we install jupyter when building the image, this prevents caching of machine id
    DOTNET_TRY_CLI_TELEMETRY_OPTOUT=true

# Install .NET CLI dependencies
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        libc6 \
        libgcc1 \
        libgssapi-krb5-2 \
        libicu66 \
        libssl1.1 \
        libstdc++6 \
        zlib1g \
    && rm -rf /var/lib/apt/lists/*

# Install .NET Core SDK
RUN dotnet_sdk_version=3.1.301 \
    && curl -SL --output dotnet.tar.gz https://dotnetcli.azureedge.net/dotnet/Sdk/$dotnet_sdk_version/dotnet-sdk-$dotnet_sdk_version-linux-x64.tar.gz \
    && dotnet_sha512='dd39931df438b8c1561f9a3bdb50f72372e29e5706d3fb4c490692f04a3d55f5acc0b46b8049bc7ea34dedba63c71b4c64c57032740cbea81eef1dce41929b4e' \
    && echo "$dotnet_sha512 dotnet.tar.gz" | sha512sum -c - \
    && mkdir -p /usr/share/dotnet \
    && tar -ozxf dotnet.tar.gz -C /usr/share/dotnet \
    && rm dotnet.tar.gz \
    && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet \
    # Trigger first run experience by running arbitrary cmd
    && dotnet help

# Copy package sources
COPY ./NuGet.config ${HOME}/nuget.config

RUN chown -R ${NB_UID} ${HOME}
USER ${USER}

# Install PowerShell global tool
RUN powershell_version=7.0.2 \
    && curl -SL --output PowerShell.Linux.x64.$powershell_version.nupkg https://pwshtool.blob.core.windows.net/tool/$powershell_version/PowerShell.Linux.x64.$powershell_version.nupkg \
    && powershell_sha512='35ccceb6b72e92028a9a4fb83ca43951433dbb700d7e13ef27c69f15d96e3dcfea91cb0ed616baeb00a173edb0050d1596d826c86b4b6cf327ae182198c1f7fd' \
    && echo "$powershell_sha512  PowerShell.Linux.x64.$powershell_version.nupkg" | sha512sum -c - \
    && mkdir -p ${HOME}/.dotnet/tools/powershell \
    && dotnet tool install -g --add-source . --version $powershell_version PowerShell.Linux.x64 \
    && rm PowerShell.Linux.x64.$powershell_version.nupkg

#Install nteract 
RUN pip install nteract_on_jupyter

# Install lastest build from master branch of Microsoft.DotNet.Interactive from myget
RUN dotnet tool install -g Microsoft.dotnet-interactive --version 1.0.131701 --add-source "https://dotnet.myget.org/F/dotnet-try/api/v3/index.json"

ENV PATH="${PATH}:${HOME}/.dotnet/tools"
RUN echo "$PATH"

# Install kernel specs
RUN dotnet interactive jupyter install

# Enable telemetry once we install jupyter for the image
ENV DOTNET_TRY_CLI_TELEMETRY_OPTOUT=false

# NOTE: EVERYTHING ABOVE THIS SHOULD BE PROVIDED BY A dotnet-interactive OFFICIAL IMAGE
# THIS MEANS IN THE FUTURE, THE ABOVE WILL TURN INTO SIMPLY:
# FROM dotnet/interactive:latest

# INSTALL ANYTHING ELSE YOU WANT IN THIS CONTAINER HERE

USER root

# Install kubectl
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl \
    && chmod +x ./kubectl \
    && mv ./kubectl /usr/local/bin

# Set up kubectl autocompletion
RUN apt-get update && apt-get install -y bash-completion \
    && kubectl completion bash >/etc/bash_completion.d/kubectl

# Install UnixCompleters module so that kubectl completions work
RUN pwsh -c Install-Module Microsoft.PowerShell.UnixCompleters -Force

USER ${USER}

# Copy notebooks (So MyBinder will work)
COPY --chown=${USER}:users . /data/JupyterNotebooks/

# Copy theme settings
RUN mkdir -p ${HOME}/.jupyter/lab/user-settings/
COPY --chown=${USER}:users ./config/ ${HOME}/.jupyter/lab/user-settings/@jupyterlab/

# Copy profile.ps1
COPY --chown=${USER}:users profile.ps1 ${HOME}/.config/powershell/Microsoft.dotnet-interactive_profile.ps1

# Setup volume (So you can run locally with mounted filesystem)
VOLUME /data/JupyterNotebooks/

# Set root to Notebooks
WORKDIR /data/JupyterNotebooks/
