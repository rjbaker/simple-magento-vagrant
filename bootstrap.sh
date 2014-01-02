#!/usr/bin/env bash

# Update
# --------------------
apt-get update

# Install Apache & PHP
# --------------------
apt-get install -y apache2
apt-get install -y php5
apt-get install -y libapache2-mod-php5
apt-get install -y php5-mysql php5-curl php5-gd php5-intl php-pear php5-imap php5-mcrypt php5-ming php5-ps php5-pspell php5-recode php5-snmp php5-sqlite php5-tidy php5-xmlrpc php5-xsl php-apc

# Delete default apache web dir and symlink mounted vagrant dir from host machine
# --------------------
rm -rf /var/www
mkdir /vagrant/httpdocs
ln -fs /vagrant/httpdocs /var/www

# Replace contents of default Apache vhost
# --------------------
VHOST=$(cat <<EOF
<VirtualHost *:80>
  DocumentRoot "/var/www"
  ServerName localhost
  <Directory "/var/www">
    AllowOverride All
  </Directory>
</VirtualHost>
EOF
)

echo "$VHOST" > /etc/apache2/sites-enabled/000-default

a2enmod rewrite
service apache2 restart

# Mysql
# --------------------
# Ignore the post install questions
export DEBIAN_FRONTEND=noninteractive
# Install MySQL quietly
apt-get -q -y install mysql-server-5.5

mysql -u root -e "CREATE DATABASE IF NOT EXISTS magentodb"
mysql -u root -e "GRANT ALL PRIVILEGES ON magentodb.* TO 'magentouser'@'localhost' IDENTIFIED BY 'password'"
mysql -u root -e "FLUSH PRIVILEGES"

# Magento
# --------------------
# http://www.magentocommerce.com/wiki/1_-_installation_and_configuration/installing_magento_via_shell_ssh

# Download and extract
if [ ! -f "/vagrant/httpdocs/index.php" ]; then
  cd /vagrant/httpdocs
  wget http://www.magentocommerce.com/downloads/assets/1.8.1.0/magento-1.8.1.0.tar.gz
  tar -zxvf magento-1.8.1.0.tar.gz
  mv magento/* magento/.htaccess .
  chmod -R o+w media var
  chmod o+w app/etc
  # Clean up downloaded file and extracted dir
  rm -rf magento*
fi

# Run installer
if [ ! -f "/vagrant/httpdocs/app/etc/local.xml" ]; then
  cd /vagrant/httpdocs
  sudo /usr/bin/php -f install.php -- --license_agreement_accepted yes \
  --locale en_US --timezone "America/Los_Angeles" --default_currency USD \
  --db_host localhost --db_name magentodb --db_user magentouser --db_pass password \
  --url "http://127.0.0.1:8080/" --use_rewrites yes \
  --use_secure no --secure_base_url "http://127.0.0.1:8080/" --use_secure_admin no \
  --skip_url_validation yes \
  --admin_lastname Owner --admin_firstname Store --admin_email "admin@example.com" \
  --admin_username admin --admin_password password123123
fi
