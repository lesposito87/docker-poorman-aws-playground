# Define version variables
ARG PACKER_VERSION=1.12
ARG TERRAGRUNT_VERSION=1.10.3
ARG ANSIBLE_VERSION=11.3.0

# Stage 1: Packer
FROM hashicorp/packer:${PACKER_VERSION} AS packer

# Stage 2: Terragrunt
FROM alpine/terragrunt:${TERRAGRUNT_VERSION} AS terragrunt

# Stage 3: Final Image with All Binaries
FROM debian:bookworm-slim

# Define the same ARG variables again for use in this final stage
ARG ANSIBLE_VERSION

# Install dependencies (including Python and Pip for Ansible)
RUN apt-get update && apt-get install -y --no-install-recommends \
  curl \
  unzip \
  wget \
  ca-certificates \
  bash \
  python3 \
  python3-pip \
  && rm -rf /var/lib/apt/lists/*

# Install the latest AWS CLI version based on architecture (amd64 or arm64)
RUN if [ "$(uname -m)" = "x86_64" ]; then \
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"; \
    elif [ "$(uname -m)" = "aarch64" ]; then \
        curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"; \
    fi && \
    unzip awscliv2.zip && \
    sudo ./aws/install && \
    rm -rf awscliv2.zip

# Install Ansible
RUN pip3 install --no-cache-dir --break-system-packages ansible==${ANSIBLE_VERSION}

# Copy the binaries from the previous stages
COPY --from=packer /bin/packer /usr/local/bin/packer
COPY --from=terragrunt /bin/terraform /usr/local/bin/terraform
COPY --from=terragrunt /usr/local/bin/terragrunt /usr/local/bin/terragrunt

# Make sure the binaries are executable
RUN chmod +x /usr/local/bin/packer /usr/local/bin/terraform /usr/local/bin/terragrunt /usr/local/bin/aws

CMD ["bash"]
