source ~/.bash_profile

cd /minitwit-db

docker-compose -f docker-compose.db.yml pull
docker-compose -f docker-compose.db.yml up -d