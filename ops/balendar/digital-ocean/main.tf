terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

resource "null_resource" "attach-balendar-to-gateway" {
  provisioner "remote-exec" {
    connection {
      type = "ssh"
      user = "root"
      host = "${var.jxo-gateway-main-ipv4-address}"
      private_key = file("${var.do_priv_key}")
    }

    inline = [
      "git clone https://github.com/JoshuaXOng/balendar.git",
    ]
  }
}
