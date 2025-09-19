# Define version variables
ARG PACKER_VERSION=1.14
ARG TERRAGRUNT_VERSION=1.13.2
ARG ANSIBLE_VERSION=11.3.0
ARG AWS_CLI_VERSION=2.24.19
ARG KUBECTL_VERSION=1.32.0

# Stage 1: Packer
FROM hashicorp/packer:${PACKER_VERSION} AS packer

# Stage 2: Terragrunt
FROM alpine/terragrunt:${TERRAGRUNT_VERSION} AS terragrunt

# Stage 3: Final Image with All Binaries
FROM debian:bookworm-slim

# Define the same ARG variables again for use in this final stage
ARG ANSIBLE_VERSION
ARG AWS_CLI_VERSION
ARG KUBECTL_VERSION

# Install dependencies (including Python and Pip for Ansible)
RUN apt-get update && apt-get install -y --no-install-recommends \
  curl \
  unzip \
  wget \
  ca-certificates \
  bash \
  less \
  python3 \
  python3-pip \
  git \
  openssh-client \
  netcat-openbsd \
  vim \
  && rm -rf /var/lib/apt/lists/*

# Install AWS CLI version based on architecture (amd64 or arm64)
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        AWS_ARCH="linux-x86_64"; \
    elif [ "$ARCH" = "aarch64" ]; then \
        AWS_ARCH="linux-aarch64"; \
    else \
        echo "[ERROR] Unsupported architecture: $ARCH"; exit 1; \
    fi && \
    curl -sSL "https://awscli.amazonaws.com/awscli-exe-${AWS_ARCH}-${AWS_CLI_VERSION}.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli && \
    rm -rf awscliv2.zip aws/

# Verify AWS CLI version
RUN aws --version

# Install kubectl for both amd64 and arm64
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        KUBECTL_ARCH="amd64"; \
    elif [ "$ARCH" = "aarch64" ]; then \
        KUBECTL_ARCH="arm64"; \
    else \
        echo "[ERROR] Unsupported architecture: $ARCH"; exit 1; \
    fi && \
    curl -LO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/${KUBECTL_ARCH}/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/kubectl

# Install Ansible
RUN pip3 install --no-cache-dir --break-system-packages ansible==${ANSIBLE_VERSION}

# Copy the binaries from the previous stages
COPY --from=packer /bin/packer /usr/local/bin/packer
COPY --from=terragrunt /bin/terraform /usr/local/bin/terraform
COPY --from=terragrunt /usr/local/bin/terragrunt /usr/local/bin/terragrunt

# Make sure the binaries are executable
RUN chmod +x /usr/local/bin/packer /usr/local/bin/terraform /usr/local/bin/terragrunt /usr/local/bin/aws /usr/local/bin/kubectl

RUN chmod +x /usr/local/bin/packer /usr/local/bin/terraform /usr/local/bin/terragrunt /usr/local/bin/aws /usr/local/bin/kubectl && \
    groupadd -g 1000 poorman && \
    useradd -m -u 1000 -g 1000 -s /bin/bash poorman && \
    mkdir -p /poorman-aws-playground && \
    chown -R poorman:poorman /poorman-aws-playground && \
    mkdir -p /home/poorman/.kube && \
    chown -R poorman:poorman /home/poorman/.kube && \
    chmod 700 /home/poorman/.kube && \
    mkdir -p /home/poorman/.vault && \
    chown -R poorman:poorman /home/poorman/.vault && \
    chmod 700 /home/poorman/.vault

WORKDIR /poorman-aws-playground

USER poorman

CMD ["bash"]

