FROM ubuntu:22.04

# Install required packages
RUN apt-get update && \
    apt-get install -y nginx python3 curl net-tools nano vim systemctl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy scenario files
COPY setup.sh /setup.sh
COPY nginx.conf /tmp/configs/nginx.conf
COPY verify-step1.sh /verify-step1.sh
COPY verify-step2.sh /verify-step2.sh
COPY verify-step3.sh /verify-step3.sh

# Make scripts executable
RUN chmod +x /setup.sh /verify-step*.sh

# Expose port 80
EXPOSE 80

# Run setup and keep container running
CMD ["/bin/bash", "-c", "/setup.sh && tail -f /dev/null"]