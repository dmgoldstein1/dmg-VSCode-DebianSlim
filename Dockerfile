# Dockerfile for Debian + VS Code Server + GitHub CLI
FROM debian:stable-slim

# Install dependencies
RUN apt-get update && \
    apt-get install -y curl wget sudo git openssh-client ca-certificates gpg && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Create a non-root user for development
RUN useradd -ms /bin/bash devuser && echo "devuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER devuser
WORKDIR /home/devuser

# Install official Microsoft VS Code (ARM64)
RUN curl -L -o vscode.deb "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-arm64" && \
    sudo apt-get update && \
    sudo apt-get install -y ./vscode.deb && \
    rm vscode.deb

# Add Microsoft GPG key for VS Code repo
RUN curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/microsoft.gpg

# Install GitHub CLI
RUN type -p curl >/dev/null || sudo apt install curl -y && \
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    sudo apt update && sudo apt install gh -y

# Expose code-server default port
EXPOSE 8080

# Entrypoint: start shell
CMD ["tail", "-f", "/dev/null"]
