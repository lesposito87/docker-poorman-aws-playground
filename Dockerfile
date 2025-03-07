# Define version variables
ARG PACKER_VERSION=1.12
ARG TERRAFORM_VERSION=1.11
ARG ANSIBLE_VERSION=11.3.0

# Stage 1: Packer
FROM hashicorp/packer:${PACKER_VERSION} as packer

# Stage 2: Terraform
FROM hashicorp/terraform:${TERRAFORM_VERSION} as terraform

# Stage 3: Final Image with All Binaries
FROM debian:bookworm-slim

# Define the same ARG variables again for use in this final stage
ARG ANSIBLE_VERSION

# Install dependencies (including Python and Pip for Ansible)
RUN apt-get update && apt-get install -y \
  curl \
  unzip \
  wget \
  ca-certificates \
  bash \
  python3 \
  python3-pip \
  && rm -rf /var/lib/apt/lists/*

# Install Ansible
RUN pip3 install --no-cache-dir --break-system-packages ansible==${ANSIBLE_VERSION}

# Copy the binaries from the previous stages
COPY --from=packer /bin/packer /usr/local/bin/packer
COPY --from=terraform /bin/terraform /usr/local/bin/terraform

# Make sure the binaries are executable
RUN chmod +x /usr/local/bin/packer /usr/local/bin/terraform

CMD ["bash"]
