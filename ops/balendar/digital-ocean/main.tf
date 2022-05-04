terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

resource "null_resource" "attach-balendar-to-gateway" {
  provisioner "local-exec" {
    command = "scp -oStrictHostKeyChecking=no -i ${var.do_priv_key} ${var.gcp_key} root@${var.jxo-gateway-main-ipv4-address}:/root/"
  }

  provisioner "remote-exec" {
    connection {
      type = "ssh"
      user = "root"
      host = "${var.jxo-gateway-main-ipv4-address}"
      private_key = file("${var.do_priv_key}")
    }

    inline = [
      "cd /root/jxo-deployment",
      "ops/balendar/backup-db-volume-job.sh",

      "git clone https://github.com/JoshuaXOng/balendar.git",

      "cd /root/balendar/website",
      "touch .env",
      "echo VITE_API_BASE_URL=${var.balendar-api-base-url} >> .env",

      "cd /root/balendar/server/app/src/main/resources/",
      "touch .env",
      "echo JWT_SECRET_KEY=${var.balendar-jwt-secret-key} >> .env",
      "echo MONGODB_DEFAULT_DATABASE=${var.balendar-mongodb-default-database} >> .env",
      "echo MONGODB_CONNECTION_STRING=${var.balendar-mongodb-connection-string} >> .env",
      "echo VITE_API_BASE_URL=${var.balendar-api-base-url} >> .env",

      "cd /root/balendar/ops/docker/prod/",
      "touch .env",
      "echo JWT_SECRET_KEY=${var.balendar-jwt-secret-key} >> .env",
      "echo MONGODB_DEFAULT_DATABASE=${var.balendar-mongodb-default-database} >> .env",
      "echo MONGODB_CONNECTION_STRING=${var.balendar-mongodb-connection-string} >> .env",
      "echo VITE_API_BASE_URL=${var.balendar-api-base-url} >> .env",

      "docker-compose up"
    ]
  }
}
