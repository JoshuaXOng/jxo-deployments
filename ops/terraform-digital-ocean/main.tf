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

resource "digitalocean_ssh_key" "jxo-gw-pub" {
  name       = "jxo-gw-pub-key"
  public_key = file("${var.do_pub_key}")
}

resource "digitalocean_vpc" "jxo-gw-main" {
  name     = "jxo-gw-vpc-main"
  region   = "sgp1"
  ip_range = "172.31.254.0/24"
}

resource "digitalocean_droplet" "jxo-gw-main" {
  name   = "jxo-gw-droplet-main"
  image  = "docker-18-04"
  vpc_uuid = "${digitalocean_vpc.jxo-gw-main.id}"
  region = "sgp1"
  size   = "s-1vcpu-1gb"

  ssh_keys = ["${digitalocean_ssh_key.jxo-gw-pub.fingerprint}"]

  provisioner "remote-exec" {
    connection {
      type = "ssh"
      user = "root"
      host = "${self.ipv4_address}"
      private_key = file("${var.do_priv_key}")
    }

    inline = [
      "apt-get update",
      
      "apt -y install nginx",

      "mkdir /etc/letsencrypt/",
      "mkdir /etc/letsencrypt/live/",
      "mkdir /etc/letsencrypt/live/${var.racing-odds-scraper-hostname}/",
      "mkdir /etc/letsencrypt/live/${var.jxo-landing-hostname}/",
    ]
  }
  provisioner "local-exec" {
    command = "scp -oStrictHostKeyChecking=no -i ${var.do_priv_key} ${var.racing-odds-scraper-pub-ssl-key} root@${self.ipv4_address}:/etc/letsencrypt/live/${var.racing-odds-scraper-hostname}/"
  }
  provisioner "local-exec" {
    command = "scp -oStrictHostKeyChecking=no -i ${var.do_priv_key} ${var.racing-odds-scraper-priv-ssl-key} root@${self.ipv4_address}:/etc/letsencrypt/live/${var.racing-odds-scraper-hostname}/"
  }
  provisioner "local-exec" {
    command = "scp -oStrictHostKeyChecking=no -i ${var.do_priv_key} ${var.jxo-landing-pub-ssl-key} root@${self.ipv4_address}:/etc/letsencrypt/live/${var.jxo-landing-hostname}/"
  }
  provisioner "local-exec" {
    command = "scp -oStrictHostKeyChecking=no -i ${var.do_priv_key} ${var.jxo-landing-priv-ssl-key} root@${self.ipv4_address}:/etc/letsencrypt/live/${var.jxo-landing-hostname}/"
  }

  provisioner "remote-exec" {
    connection {
      type = "ssh"
      user = "root"
      host = "${self.ipv4_address}"
      private_key = file("${var.do_priv_key}")
    }

    inline = [
      "apt-get update",

      "apt -y install nginx",

      "git clone https://github.com/JoshuaXOng/jxo-gw.git",
      
      "ufw allow http",
      "ufw allow https",
      "ufw allow 3000",
      "ufw allow 8000",
      "ufw allow 1337",
      "ufw allow out 80/tcp",
      "ufw allow out 443/tcp",

      "mv /root/jxo-gw/ops/nginx/jxo-gateway.conf /etc/nginx/conf.d/",

      "nginx -s reload",
    ]
  }
}

resource "digitalocean_firewall" "jxo-gw-main" {
  name = "nginx-fw-in-misc-out-misc"

  droplet_ids = [digitalocean_droplet.jxo-gw-main.id]

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
    protocol         = "tcp"
    port_range       = "3000"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "8000"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "1337"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "icmp"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "80"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "443"
    destination_addresses = ["0.0.0.0/0", "::/0"]
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

resource "digitalocean_domain" "racing-odds-scraper-main" {
  name       = var.racing-odds-scraper-hostname
}

resource "digitalocean_record" "racing-odds-scraper-a" {
  domain = digitalocean_domain.racing-odds-scraper-main.id
  type   = "A"
  name   = "@"
  value  = digitalocean_droplet.jxo-gw-main.ipv4_address
}
