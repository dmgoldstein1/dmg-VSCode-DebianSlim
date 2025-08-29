FROM debian:bookworm-slim

# Install necessary packages
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    sudo \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user
RUN useradd -m -s /bin/bash vscode && \
    echo "vscode ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install VS Code Server
USER vscode
WORKDIR /home/vscode

# Download and install VS Code Server
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Create workspace directory
RUN mkdir -p /home/vscode/workspace

# Copy entrypoint script
COPY entrypoint.sh /home/vscode/entrypoint.sh
RUN sudo chown vscode:vscode /home/vscode/entrypoint.sh && \
    chmod +x /home/vscode/entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/home/vscode/entrypoint.sh"]
