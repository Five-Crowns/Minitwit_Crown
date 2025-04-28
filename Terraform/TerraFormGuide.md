# Install Terraform
https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli

# Generate Digital Ocean API token
https://docs.digitalocean.com/reference/api/create-personal-access-token/

# Add token, project name and secure db password to terraform.tfvars file

# Initialize terraform (download providers)
``terraform init``

# See what changes will be made
``terraform plan``

# Apply the changes
``terraform apply``

# Additional notes:
This simply setups the infrastructure.

For the app to work properly it needs to have a .env file inserted into minitwit directory, and for the developer to run the compose file. This can be don by SSH into the app droplet.

The db password in the .env should be the same as the one defined in terraform.tfvars.

I am unable to test this so if it fails to authenticate then the password may 

Reminder of how to generate ssh key:
``ssh-keygen -f ~/.ssh/do_ssh_key -t rsa -b 4096 -m "PEM"``