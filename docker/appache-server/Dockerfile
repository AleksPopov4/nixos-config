# Use an official Debian-based image
FROM debian:latest

# Update the package index and install Apache
RUN apt-get update && \
    apt-get install -y apache2 && \
    apt-get clean

# Expose port 80 to the host
EXPOSE 80

# Start the Apache server in the foreground
CMD ["apachectl", "-D", "FOREGROUND"]
