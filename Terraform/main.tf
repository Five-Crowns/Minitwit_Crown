terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

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

variable "digitalocean_project" {
  description = "Digital Ocean project to assign resources to"
}

variable "db_password" {
  description = "Postgres db password set in tfvars"
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

    # Install Docker and Docker Compose
    sudo apt-get install -y docker.io docker-compose

    # Create minitwit directory structure
    mkdir -p /minitwit

    # Make minitwit the default directory
    echo "cd /minitwit" >> ~/.bash_profile

    docker pull niko391a/minitwitimage:latest
    
    # Allow required ports
    ufw allow 5000
    ufw allow 22/tcp
    ufw allow 80/tcp

    echo "App container finished setup"
  EOT
  
  # Sync remote_files to the server
  provisioner "local-exec" {
    command = "rsync -avz -e 'ssh -i ~/.ssh/do_ssh_key -o StrictHostKeyChecking=no' ../remote_files/ root@${self.ipv4_address}:/minitwit/"
  }
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

    # Install Docker and Docker Compose
    sudo apt-get install -y docker.io docker-compose
    docker pull niko391a/postgresqlimage

    # Create minitwit directory for consistency
    mkdir -p /minitwit
    
    # Make minitwit the default directory
    echo "cd /minitwit" >> /root/.bash_profile

    # Allow required ports
    ufw allow 22/tcp
    ufw allow 5432/tcp

    docker run -d -p 5432:5432 -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=${var.db_password} -e POSTGRES_DB=minitwit --name minitwit-db niko391a/postgresqlimage

    echo "PostgreSQL container finished setup"
  EOT

  # Sync remote_files to the server
  provisioner "local-exec" {
    command = "rsync -avz -e 'ssh -i ~/.ssh/do_ssh_key -o StrictHostKeyChecking=no' ../remote_files/ root@${self.ipv4_address}:/minitwit/"
  }
}

output "app_droplet_ip" {
  value = digitalocean_droplet.app.ipv4_address
}

output "db_droplet_ip" {
  value = digitalocean_droplet.db.ipv4_address
}

data "digitalocean_project" "project" {
  name = var.digitalocean_project
}

resource "digitalocean_project_resources" "project_resources" {
  project = data.digitalocean_project.project.id
  resources = [
    digitalocean_droplet.app.urn,
    digitalocean_droplet.db.urn
  ]
}