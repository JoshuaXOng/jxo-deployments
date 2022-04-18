apt update
apt install snapd

snap install core; snap refresh core

apt-get remove certbot

snap install --classic certbot

ln -s /snap/bin/certbot /usr/bin/certbot

certbot certonly --nginx # or sudo certbot --nginx