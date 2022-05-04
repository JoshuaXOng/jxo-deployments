terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

resource "digitalocean_ssh_key" "jxo-gateway-pub" {
  name       = "jxo-gateway-pub-key"
  public_key = file("${var.do_pub_key}")
}

resource "digitalocean_droplet" "jxo-gateway-main" {
  name   = "jxo-gateway-droplet-main"
  image  = "docker-18-04"
  # vpc_uuid = "${digitalocean_vpc.jxo-gateway-main.id}"
  region = "sgp1"
  size   = "s-1vcpu-1gb"

  ssh_keys = ["${digitalocean_ssh_key.jxo-gateway-pub.fingerprint}"]

  provisioner "remote-exec" {
    connection {
      type = "ssh"
      user = "root"
      host = "${self.ipv4_address}"
      private_key = file("${var.do_priv_key}")
    }

    inline = [
      "git clone https://github.com/JoshuaXOng/balendar.git",
    ]
  }
}
