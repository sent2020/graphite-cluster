#!/bin/bash
GRAPHITE_SERVER1_IP="SERVERIP1"
GRAPHITE_SERVER2_IP="SERVERIP2"

# Updates
sudo apt-get update

# Install Dependencies
sudo apt-get install curl --yes
sudo apt-get install python --yes
sudo apt-get install git --yes

# Install Python Packages
sudo apt-get install python-pip python-cairo python-django --yes
sudo pip install cffi
sudo pip install -r https://raw.githubusercontent.com/graphite-project/whisper/master/requirements.txt
sudo pip install -r https://raw.githubusercontent.com/graphite-project/carbon/master/requirements.txt
sudo pip install -r https://raw.githubusercontent.com/graphite-project/graphite-web/master/requirements.txt

# Install Whisper, Carbon and Graphite Web
export PYTHONPATH="/opt/graphite/lib/:/opt/graphite/webapp/"
sudo pip install --no-binary=:all: https://github.com/graphite-project/whisper/tarball/master
sudo pip install --no-binary=:all: https://github.com/graphite-project/carbon/tarball/master
sudo pip install --no-binary=:all: https://github.com/graphite-project/graphite-web/tarball/master

# Setting up Carbon
sudo cp ./carbon/carbon.conf /opt/graphite/conf
sudo sed -ri "s/GRAPHITE_SERVER1_IP/$GRAPHITE_SERVER1_IP/g; s/GRAPHITE_SERVER2_IP/$GRAPHITE_SERVER2_IP/g" carbon.conf
sudo cp ./carbon/storage-schemas.conf /opt/graphite/conf
sudo cp ./carbon/whitelist.conf /opt/graphite/conf
sudo cp ./carbon/relay-rules.conf /opt/graphite/conf
sudo sed -ri "s/GRAPHITE_SERVER1_IP/$GRAPHITE_SERVER1_IP/g; s/GRAPHITE_SERVER2_IP/$GRAPHITE_SERVER2_IP/g" relay-rules.conf

# Setting up memcached
sudo apt-get install memcached --yes
sudo service memcached start

# Setting up Graphite Web
sudo cp ./graphite-web/local_settings.py /opt/graphite/webapp/graphite
sudo sed -ri "s/GRAPHITE_SERVER1_IP/$GRAPHITE_SERVER1_IP/g; s/GRAPHITE_SERVER2_IP/$GRAPHITE_SERVER2_IP/g" local_settings.py
sudo PYTHONPATH=/opt/graphite/webapp/ django-admin migrate  --settings=graphite.settings --run-syncdb

# Settig up permissions
sudo useradd -s /bin/false _graphite
sudo chown -R _graphite:_graphite /opt/graphite/

# Setting up uwsgi
sudo apt-get install uwsgi uwsgi-plugin-python --yes
sudo cp /opt/graphite/conf/graphite.wsgi.example /opt/graphite/conf/wsgi.py
cp ./uwsgi/apps-available/graphite.ini /etc/uwsgi/apps-available
sudo ln -s /etc/uwsgi/apps-available/graphite.ini /etc/uwsgi/apps-enabled/graphite.ini

# Setting up nginx
sudo apt-get install nginx --yes
sudo service nginx stop
cp ./nginx/sites-available/graphite /etc/nginx/sites-available
sudo ln -s /etc/nginx/sites-available/graphite /etc/nginx/sites-enabled/graphite

# Setting up supervisor
sudo apt-get install supervisor --yes
sudo service supervisor stop
cp ./supervisor/supervisord.conf /etc/supervisor/conf.d/
sudo service supervisor start

