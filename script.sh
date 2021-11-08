clear

sudo apt-get install ntpdate
sudo ntpdate ntp.midway.ovh

read -t 5 -p "Waiting for 5 seconds ..."

sudo apt-get update 

read -t 30 -p "Waiting..."


sudo apt-get upgrade -y

 
#apt-get install perl libnet-ssleay-perl openssl libauthen-pam-perl libpam-runtime libio-pty-perl apt-show-versions python
#cd /usr/src 
#wget http://prdownloads.sourceforge.net/webadmin/webmin_1.910_all.deb
#dpkg --install webmin_1.910_all.deb 

echo "Installation des librairies"

sudo apt-get install redis-server mongodb npm build-essential ruby-bundler ruby-dev libsqlite3-dev -y 
sudo apt-get install build-essential patch ruby-dev zlib1g-dev liblzma-dev -y

echo "Installation de nodejs"

cd ~ 
sudo curl -sL https://deb.nodesource.com/setup_12.x -o nodesource_setup.sh
sudo chmod +x nodesource_setup.sh
sudo ./nodesource_setup.sh 

echo "Installation de yarn"

sudo curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - 
sudo echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list 

sudo apt-get update

sudo apt-get install yarn nodejs -y
sudo npm install libxmljs --unsafe-perm 

echo "Installation de genieacs"

sudo npm install -g genieacs --unsafe-perm 



echo "Installation de l'interface graphique de genieacs"

git clone https://github.com/zaidka/genieacs-gui 

cd ~ 
cd genieacs-gui 
#cd ~/genieacs-gui

sudo gem install bundler:1.16.6

bundle update mimemagic
bundle
cp config/summary_parameters-sample.yml config/summary_parameters.yml 
cp config/index_parameters-sample.yml config/index_parameters.yml 
cp config/parameter_renderers-sample.yml config/parameter_renderers.yml 
cp config/parameters_edit-sample.yml config/parameters_edit.yml 
cp config/roles-sample.yml config/roles.yml 
cp config/users-sample.yml config/users.yml 
cp config/graphs-sample.json.erb config/graphs.json.erb
cd db/migrate
sudo sed -i '1!b;s/$/\[4.2]/g' *.rb

cd ~ 
cd genieacs-gui
#cd ~/genieacs-gui

echo "Création des scripts de démarrage & d'arrêt"

sudo cat << EOF > ./genieacs-start.sh
#!/bin/sh
if tmux has-session -t 'genieacs'; then
  echo "GenieACS is already running."
  echo "To stop it use: ./genieacs-stop.sh"
  echo "To attach to it use: tmux attach -t genieacs"
else
  tmux new-session -s 'genieacs' -d
  tmux send-keys 'genieacs-cwmp' 'C-m'
  tmux split-window
  tmux send-keys 'genieacs-nbi' 'C-m'
  tmux split-window
  tmux send-keys 'genieacs-fs' 'C-m'
  tmux split-window
  tmux send-keys 'cd genieacs-gui' 'C-m'
  tmux send-keys 'rails server -b 0.0.0.0' 'C-m'
  tmux select-layout tiled 2>/dev/null
  tmux rename-window 'GenieACS'

  echo "GenieACS has been started in tmux session 'geneiacs'"
  echo "To attach to session, use: tmux attach -t genieacs"
  echo "To switch between panes use Ctrl+B-ArrowKey"
  echo "To deattach, press Ctrl+B-D"
  echo "To stop GenieACS, use: ./genieacs-stop.sh"
fi
EOF

sudo cat << EOF > ./genieacs-stop.sh
#!/bin/sh
if tmux has-session -t 'genieacs' 2>/dev/null; then
  tmux kill-session -t genieacs 2>/dev/null
  echo "GenieACS has been stopped."
else
  echo "GenieACS is not running!"
fi
EOF

sudo chmod +x genieacs-start.sh genieacs-stop.sh

echo "Démarrage de l'interface graphique de GenieAcs"

cd ~ 
cd genieacs-gui
sudo ./genieacs-start.sh


sudo bin/rails db:migrate RAILS_ENV=development

echo "Création des services de GenieAcs"

#-----------------------------------------------
# Modifications perso

sudo useradd --system --no-create-home --user-group genieacs

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

