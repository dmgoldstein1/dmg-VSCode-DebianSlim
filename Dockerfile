# Dockerfile for Debian + VS Code Server + GitHub CLI
FROM debian:stable-slim

# Install dependencies (add binutils for ar and npm for patching VS Code)
RUN apt-get update && \
    apt-get install -y curl wget sudo git openssh-client ca-certificates gpg binutils npm && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Create a non-root user for development
RUN useradd -ms /bin/bash devuser && echo "devuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER devuser
WORKDIR /home/devuser

# Download and patch VS Code .deb to update critical npm packages before install
RUN curl -L -o vscode.deb "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-arm64" && \
                mkdir vscode_extract && \
                ar x vscode.deb --output=vscode_extract && \
                cd vscode_extract && \
                tar xf data.tar.* && \
                # Deep patch: recursively update critical npm modules in all node_modules
                find . -type d -name node_modules | while read dir; do \
                    cd "$dir" && \
                    npm install handlebars@4.7.7 npm@9.0.0 grunt@1.3.0 ini@1.3.6 diff@3.5.0 json@10.0.0 tar@6.2.1 pug@3.0.3 --no-save || true; \
                    npx npm@9.0.0 update handlebars grunt ini diff json tar pug || true; \
                    cd -; \
                done && \
                cd .. && \
                tar cJf data.tar.xz -C vscode_extract . && \
                ar rcs patched_vscode.deb vscode_extract/debian-binary vscode_extract/control.tar.* data.tar.xz && \
                sudo apt-get clean && sudo rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* && \
                sudo apt-get update && \
                sudo apt-get install -y ./patched_vscode.deb && \
                rm -rf vscode.deb vscode_extract patched_vscode.deb data.tar.xz && \
                sudo apt-get purge -y binutils npm && sudo apt-get autoremove -y && sudo apt-get clean && sudo rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

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
