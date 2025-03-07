# Define version variables
ARG PACKER_VERSION=1.8.4
ARG TERRAFORM_VERSION=1.5.0
ARG ANSIBLE_VERSION=5.0.0

# Stage 1: Packer
FROM hashicorp/packer:${PACKER_VERSION} as packer

# Stage 2: Terraform
FROM hashicorp/terraform:${TERRAFORM_VERSION} as terraform

# Stage 3: Ansible (Using python:3-slim for the latest Python 3)
FROM python:3-slim as ansible

# Install specific version of Ansible
RUN pip install --no-cache-dir ansible==${ANSIBLE_VERSION}

# Stage 4: Final Image with All Binaries
FROM debian:bullseye-slim

# Install dependencies
RUN apt-get update && apt-get install -y \
  curl \
  unzip \
  wget \
  ca-certificates \
  bash \
  && rm -rf /var/lib/apt/lists/*

# Copy the binaries from the previous stages
COPY --from=packer /usr/local/bin/packer /usr/local/bin/packer
COPY --from=terraform /bin/terraform /usr/local/bin/terraform
COPY --from=ansible /usr/local/bin/ansible /usr/local/bin/ansible

# Make sure the binaries are executable
RUN chmod +x /usr/local/bin/packer /usr/local/bin/terraform /usr/local/bin/ansible

CMD ["bash"]
