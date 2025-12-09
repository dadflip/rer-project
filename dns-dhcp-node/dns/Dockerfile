FROM ubuntu:22.04

# Evite l'interaction apt
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y dnsmasq && \
    rm -rf /var/lib/apt/lists/*

# Point d'entrée par défaut
CMD ["bash"]
