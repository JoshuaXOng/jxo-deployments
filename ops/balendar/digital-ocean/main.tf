terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    
    google = {
      source  = "hashicorp/google"
      version = "4.9.0"
    }
  }
}

resource "google_storage_bucket" "balendar-main" {
  name          = "balendar-bucket-main"
  force_destroy = true
  location      = "US"
  storage_class = "ARCHIVE"
  uniform_bucket_level_access = true
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
      "cd /root/jxo-deployments",
      "chmod 751 ops/balendar/backup-db-volume-job.sh",
      "chmod 751 ops/balendar/snapshot-db-volume.sh",
      "ops/balendar/backup-db-volume-job.sh",

      "cd /root/",
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

      "docker-compose up -d"
    ]
  }
}
