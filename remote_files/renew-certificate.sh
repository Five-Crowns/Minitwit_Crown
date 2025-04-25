source ~/.bash_profile

sudo certbot renew
sudo service nginx restart

rsync -i ~/.ssh/do_ssh_key -avz /etc/letsencrypt/live/realpingo.tech/ root@209.38.195.229:/etc/letsencrypt/live/realpingo.tech/