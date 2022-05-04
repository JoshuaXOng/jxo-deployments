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

module "digital-ocean-jxo-landing" {
  source = "./ops/jxo-landing/digital-ocean"
}

module "digital-ocean-jxo-gateway" {
  source = "./ops/jxo-gateway/digital-ocean"

  jxo-landing-live-url = module.digital-ocean-jxo-landing.jxo-landing-live-url

  depends_on = [
    module.digital-ocean-jxo-landing
  ]
}

module "digital-ocean-balendar" {
  source = "./ops/balendar/digital-ocean"

  jxo-gateway-main-ipv4-address = module.digital-ocean-jxo-gateway.jxo-gateway-main-ipv4-address

  depends_on = [
    module.digital-ocean-jxo-gateway
  ]
}