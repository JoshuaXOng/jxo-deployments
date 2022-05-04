terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = "${var.do_token}"
}

resource "digitalocean_ssh_key" "racing-odds-scraper-pub" {
  name       = "racing-odds-scraper-pub-key"
  public_key = file("${var.do_pub_key}")
}

resource "digitalocean_vpc" "racing-odds-scraper-main" {
  name     = "racing-odds-scraper-vpc-main"
  region   = "sgp1"
  ip_range = "172.31.255.0/24"
}

resource "digitalocean_droplet" "racing-odds-scraper-main" {
  name   = "racing-odds-scraper-droplet-main"
  image  = "docker-18-04"
  vpc_uuid = "${digitalocean_vpc.racing-odds-scraper-main.id}"
  region = "sgp1"
  size   = "s-1vcpu-1gb"

  ssh_keys = ["${digitalocean_ssh_key.racing-odds-scraper-pub.fingerprint}"]

  provisioner "remote-exec" {
    connection {
      type = "ssh"
      user = "root"
      host = "${self.ipv4_address}"
      private_key = file("${var.do_priv_key}")
    }

    inline = [
      "apt-get update",
      "ufw allow http",
      "ufw allow https",

      "apt -y install curl",
      "curl -sL https://deb.nodesource.com/setup_16.x | sudo bash -",
      "cat /etc/apt/sources.list.d/nodesource.list",
      "apt -y install nodejs",
      "apt -y install npm",
      "npm install -g npm@8.3.1",
      "git clone https://github.com/JoshuaXOng/racing-odds-scraper.git",
      "cd racing-odds-scraper",
      "npm install",
      "docker-compose up -d"
    ]
  }
}

resource "digitalocean_firewall" "racing-odds-scraper-main" {
  name = "racing-odds-scraper-fw-in-22-80-and-443-out-dns"

  droplet_ids = [digitalocean_droplet.racing-odds-scraper-main.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = var.whitelisted_ssh_ips
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "icmp"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "53"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "53"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

# resource "digitalocean_loadbalancer" "racing-odds-scraper-public" {
#   name        = "racing-odds-scraper-lb-public"
#   vpc_uuid = digitalocean_vpc.racing-odds-scraper-main.id
#   region      = "sgp1"

#   droplet_ids = [digitalocean_droplet.racing-odds-scraper-main.id]

#   forwarding_rule {
#     entry_port     = 80
#     entry_protocol = "http"
#     target_port     = 80
#     target_protocol = "http"
#   }

#   forwarding_rule {
#     entry_port     = 443
#     entry_protocol = "https"
#     target_port     = 80
#     target_protocol = "http"

#     certificate_name = digitalocean_certificate.racing-odds-scraper-main.name
#   }
# }
