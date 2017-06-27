#!/bin/bash
GRAPHITE_SERVER1_IP="SERVERIP1"
GRAPHITE_SERVER2_IP="SERVERIP2"
GRAPHITE_SERVER3_IP="SERVERIP3"

RED='\033[0;31m';
GREEN='\033[0;32m';
YELLOW='\033[1;33m';
CYAN='\033[0;36m';
NC='\033[0m';

ERR  (){  echo -e "${RED}$@${NC}"; }
OK   (){  echo -e "${GREEN}$@${NC}";}
WARN (){  echo -e "${YELLOW}$@${NC}"; }
INFO (){  echo -e "${CYAN}$@${NC}"; }

if [ $1 ]
  then
        GRAPHITE_SERVER1_IP=$1
fi

if [ $2 ]
  then
        GRAPHITE_SERVER2_IP=$2
fi

if [ $3 ]
  then
        GRAPHITE_SERVER3_IP=$3
fi

# Updates
sudo apt-get update

# Install Python Packages
sudo apt-get install python-pip python-cairo python-django --yes
sudo pip install cffi
sudo pip install -r https://raw.githubusercontent.com/graphite-project/whisper/1.0.1/requirements.txt
sudo pip install -r https://raw.githubusercontent.com/graphite-project/carbon/1.0.1/requirements.txt
sudo pip install -r https://raw.githubusercontent.com/graphite-project/graphite-web/1.0.1/requirements.txt

# Install Whisper, Carbon and Graphite Web
export PYTHONPATH="/opt/graphite/lib/:/opt/graphite/webapp/"
sudo pip install --no-binary=:all: https://github.com/graphite-project/whisper/tarball/1.0.1
sudo pip install --no-binary=:all: https://github.com/graphite-project/carbon/tarball/1.0.1
sudo pip install --no-binary=:all: https://github.com/graphite-project/graphite-web/tarball/1.0.1

# Setting up Carbon
sudo cp ./carbon/carbon.conf /opt/graphite/conf
sudo sed -ri "s/GRAPHITE_SERVER1_IP/$GRAPHITE_SERVER1_IP/g; s/GRAPHITE_SERVER2_IP/$GRAPHITE_SERVER2_IP/g; s/GRAPHITE_SERVER3_IP/$GRAPHITE_SERVER3_IP/g" /opt/graphite/conf/carbon.conf
sudo cp ./carbon/storage-schemas.conf /opt/graphite/conf
sudo cp ./carbon/storage-aggregation.conf /opt/graphite/conf
sudo cp ./carbon/whitelist.conf /opt/graphite/conf
sudo cp ./carbon/relay-rules.conf /opt/graphite/conf
sudo sed -ri "s/GRAPHITE_SERVER1_IP/$GRAPHITE_SERVER1_IP/g; s/GRAPHITE_SERVER2_IP/$GRAPHITE_SERVER2_IP/g; s/GRAPHITE_SERVER3_IP/$GRAPHITE_SERVER3_IP/g" /opt/graphite/conf/relay-rules.conf

# Setting up Graphite Web
sudo cp ./graphite_web/local_settings.py /opt/graphite/webapp/graphite
sudo sed -ri "s/GRAPHITE_SERVER1_IP/$GRAPHITE_SERVER1_IP/g; s/GRAPHITE_SERVER2_IP/$GRAPHITE_SERVER2_IP/g; s/GRAPHITE_SERVER3_IP/$GRAPHITE_SERVER3_IP/g" /opt/graphite/webapp/graphite/local_settings.py
sudo PYTHONPATH=/opt/graphite/webapp/ django-admin migrate  --settings=graphite.settings --run-syncdb


# Setting up memcached
sudo apt-get install memcached --yes

# Setting up uwsgi
sudo apt-get install uwsgi uwsgi-plugin-python --yes
sudo sysctl -w net.core.somaxconn=4096
sudo cp /opt/graphite/conf/graphite.wsgi.example /opt/graphite/conf/wsgi.py
sudo cp ./uwsgi/apps-available/graphite.ini /etc/uwsgi/apps-available
sudo ln -s /etc/uwsgi/apps-available/graphite.ini /etc/uwsgi/apps-enabled/graphite.ini

# Settig up permissions
sudo useradd -s /bin/false _graphite
sudo chown -R _graphite:_graphite /opt/graphite/

# Setting up nginx
sudo apt-get install nginx --yes
sudo service nginx stop
sudo cp ./nginx/nginx.conf /etc/nginx
sudo cp ./nginx/sites-available/graphite /etc/nginx/sites-available
sudo ln -s /etc/nginx/sites-available/graphite /etc/nginx/sites-enabled/graphite
sudo rm /etc/nginx/sites-enabled/default 
sudo nginx -t

# Starting Daemons
#sudo service memcached start
#sudo /opt/graphite/bin/carbon-cache.py --instance=a start
#sudo /opt/graphite/bin/carbon-cache.py --instance=b start
#sudo /opt/graphite/bin/carbon-relay.py --instance=a start
#sudo /usr/bin/uwsgi --ini /etc/uwsgi/apps-enabled/graphite.ini --pidfile /var/run/uwsgi.pid
#sudo service nginx start

# Setting up supervisor
#sudo apt-get install supervisor --yes
#sudo service supervisor stop
#sudo cp ./supervisor/supervisord.conf /etc/supervisor/conf.d/
#sudo service supervisor start
