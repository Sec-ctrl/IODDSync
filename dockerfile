# Base image - Smaller & optimized
FROM ubuntu:minimal

# Set timezone to avoid warnings & ensure non-interactive install
ENV DEBIAN_FRONTEND=noninteractive
RUN ln -fs /usr/share/zoneinfo/Etc/UTC /etc/localtime

# Install required packages (minimal install)
RUN apt-get update && apt-get install -y --no-install-recommends \
    rsync \
    bash \
    openssh-client \
    nano \
    curl \
    tar \
    tzdata \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create necessary directories
RUN mkdir -p /mnt/iodd /mnt/logs

# Create a non-root user for security
RUN useradd -m -s /bin/bash iodduser && \
    chown -R iodduser:iodduser /mnt/iodd /mnt/logs

# Set working directory
WORKDIR /mnt/iodd

# Copy the sync script and set permissions
COPY sync_iodd.sh /usr/local/bin/sync_iodd.sh
RUN chmod +x /usr/local/bin/sync_iodd.sh && chown iodduser:iodduser /usr/local/bin/sync_iodd.sh

# Ensure script exists before execution (prevents container failure)
RUN test -f /usr/local/bin/sync_iodd.sh || { echo "❌ Error: Missing sync_iodd.sh"; exit 1; }

# Switch to the non-root user
USER iodduser

# Set up persistent volume for logs
VOLUME /mnt/logs

# Add health check to monitor process
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD ["/bin/bash", "-c", "pgrep -f sync_iodd.sh || exit 1"]

# Use ENTRYPOINT for more predictable execution
ENTRYPOINT ["/bin/bash", "/usr/local/bin/sync_iodd.sh"]
