clear

sudo apt-get install ntpdate
sudo ntpdate ntp.midway.ovh

read -t 5

sudo apt-get update 

read -t 30 -p "Waiting..."


sudo apt-get upgrade -y

 
#apt-get install perl libnet-ssleay-perl openssl libauthen-pam-perl libpam-runtime libio-pty-perl apt-show-versions python
#cd /usr/src 
#wget http://prdownloads.sourceforge.net/webadmin/webmin_1.910_all.deb
#dpkg --install webmin_1.910_all.deb 

echo "Installation de nodejs"

cd ~ 
sudo curl -sL https://deb.nodesource.com/setup_14.x -o nodesource_setup.sh
sudo chmod +x nodesource_setup.sh
sudo bash nodesource_setup.sh 
sudo apt install nodejs


#-----------------------------------------------
echo "Installation de Mogodb"

sudo curl -fsSL https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -

echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list

sudo apt update

read -t 30 -p "Waiting..."

sudo apt install mongodb-org -y

sudo systemctl start mongod.service
sudo systemctl status mongod

sudo systemctl enable mongod

mongo --eval 'db.runCommand({ connectionStatus: 1 })'

sudo systemctl status mongod
sudo systemctl start mongod
sudo systemctl stop mongod
sudo systemctl restart mongod
sudo systemctl disabe mongod
sudo systemctl enable mongod

read -t 30 -p "Waiting..."


echo "Installation de genieacs"

sudo npm install -g genieacs --unsafe-perm 
sudo useradd --system --no-create-home --user-group genieacs


echo "Création des services de GenieAcs"

cd /
sudo mkdir /opt/genieacs
sudo mkdir /opt/genieacs/ext
sudo chown genieacs:genieacs /opt/genieacs/ext


sudo bash -c 'cat << EOF > ./opt/genieacs/genieacs.env
GENIEACS_CWMP_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-cwmp-access.log
GENIEACS_NBI_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-nbi-access.log
GENIEACS_FS_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-fs-access.log
GENIEACS_UI_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-ui-access.log
GENIEACS_DEBUG_FILE=/var/log/genieacs/genieacs-debug.yaml
NODE_OPTIONS=--enable-source-maps
GENIEACS_EXT_DIR=/opt/genieacs/ext
GENIEACS_UI_JWT_SECRET=secret

EOF'

sudo chown genieacs:genieacs /opt/genieacs/genieacs.env
sudo chmod 600 /opt/genieacs/genieacs.env

sudo mkdir /var/log/genieacs
sudo chown genieacs:genieacs /var/log/genieacs

#--------
# Modification des services genieacs

cd /


# Modification du service genieacs-cwmp
# sudo systemctl edit --force --full genieacs-cwmp

sudo bash -c 'cat << EOF > ./etc/systemd/system/genieacs-cwmp.service
[Unit]
Description=GenieACS CWMP
After=network.target

[Service]
User=genieacs
EnvironmentFile=/opt/genieacs/genieacs.env
ExecStart=/usr/bin/genieacs-cwmp

[Install]
WantedBy=default.target

EOF'

# Modification du service genieacs-nbi
# sudo systemctl edit --force --full genieacs-nbi

sudo bash -c 'cat << EOF > ./etc/systemd/system/genieacs-nbi.service
[Unit]
Description=GenieACS NBI
After=network.target

[Service]
User=genieacs
EnvironmentFile=/opt/genieacs/genieacs.env
ExecStart=/usr/bin/genieacs-nbi

[Install]
WantedBy=default.target

EOF'

# Modification du service genieacs-fs
# sudo systemctl edit --force --full genieacs-fs

sudo bash -c 'cat << EOF > ./etc/systemd/system/genieacs-fs.service
[Unit]
Description=GenieACS FS
After=network.target

[Service]
User=genieacs
EnvironmentFile=/opt/genieacs/genieacs.env
ExecStart=/usr/bin/genieacs-fs

[Install]
WantedBy=default.target

EOF'

# Modification du service genieacs-ui
# sudo systemctl edit --force --full genieacs-ui

sudo bash -c 'cat << EOF > ./etc/systemd/system/genieacs-ui.service
[Unit]
Description=GenieACS UI
After=network.target

[Service]
User=genieacs
EnvironmentFile=/opt/genieacs/genieacs.env
ExecStart=/usr/bin/genieacs-ui

[Install]
WantedBy=default.target

EOF'

# Fin des modifications des services genieacs
#-----------

# Configure log file rotation using logrotate

cd /


sudo bash -c 'cat << EOF > ./etc/logrotate.d/genieacs
/var/log/genieacs/*.log /var/log/genieacs/*.yaml {
    daily
    rotate 30
    compress
    delaycompress
    dateext
}

EOF'

echo "Démarrage des services GenieAcs"

# Enable and start services

sudo systemctl enable genieacs-cwmp
sudo systemctl start genieacs-cwmp
sudo systemctl status genieacs-cwmp

sudo systemctl enable genieacs-nbi
sudo systemctl start genieacs-nbi
sudo systemctl status genieacs-nbi

sudo systemctl enable genieacs-fs
sudo systemctl start genieacs-fs
sudo systemctl status genieacs-fs

sudo systemctl enable genieacs-ui
sudo systemctl start genieacs-ui
sudo systemctl status genieacs-ui

#-----------------------------------------------
