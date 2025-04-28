provider "digitalocean" {
  token = var.digitalocean_token
}

variable "digitalocean_token" {}

variable "region" {
  default = "fra1" # Frankfurt region
}

variable "app_droplet_name" {
  default = "minitwit-app"
}

variable "db_droplet_name" {
  default = "minitwit-db"
}

variable "ssh_key_name" {
  default = "do_ssh_key" 
}

resource "digitalocean_droplet" "app" {
  name   = var.app_droplet_name
  region = var.region
  size   = "s-1vcpu-1gb"
  image  = "ubuntu-22-04-x64"

  ssh_keys = [var.ssh_key_name]

  user_data = <<-EOT
    #!/bin/bash
    apt-get update
    apt-get install -y docker.io
    docker pull niko391a/minitwitimage:latest
    docker run -d -p 80:80 niko391a/minitwitimage:latest
    echo "App container deployed"
  EOT
}

resource "digitalocean_droplet" "db" {
  name   = var.db_droplet_name
  region = var.region
  size   = "s-1vcpu-1gb"
  image  = "ubuntu-22-04-x64"

  ssh_keys = [var.ssh_key_name]

  user_data = <<-EOT
    #!/bin/bash
    apt-get update
    apt-get install -y docker.io
    docker pull niko391a/postgresqlimage
    docker run -d -p 5432:5432 -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=placeholder -e POSTGRES_DB=minitwit postgres:latest
    echo "PostgreSQL container deployed"
  EOT
}

output "app_droplet_ip" {
  value = digitalocean_droplet.app.ipv4_address
}

output "db_droplet_ip" {
  value = digitalocean_droplet.db.ipv4_address
}