FROM ubuntu:22.04
RUN apt-get update && apt-get install -y --no-install-recommends python3 \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /var/www
COPY script.sh /var/www/script.sh
RUN chmod +x /var/www/script.sh
CMD ["/bin/bash", "-c", "/var/www/script.sh & exec python3 -m http.server 8080"]
