#!/usr/bin/env bash

SAMPLE_DATA=$1
MAGE_VERSION=$2
DATA_VERSION=$3
DOMAIN_NAME=$4

# Update Apt
# --------------------
apt-get update

# Install Apache & PHP
# --------------------
apt-get install -y apache2
apt-get install -y php5
apt-get install -y libapache2-mod-php5
apt-get install -y php5-mysqlnd php5-curl php5-xdebug php5-gd php5-intl php-pear php5-imap php5-mcrypt php5-ming php5-ps php5-pspell php5-recode php5-sqlite php5-tidy php5-xmlrpc php5-xsl php-soap

php5enmod mcrypt

# Delete default apache web dir and symlink mounted vagrant dir from host machine
# --------------------
rm -rf /var/www/magento
sudo mkdir /vagrant
sudo mkdir /vagrant/httpdocs
ln -fs /vagrant/httpdocs /var/www/magento

# Replace contents of default Apache vhost
# --------------------
VHOST="NameVirtualHost *:80
<VirtualHost *:80>
  DocumentRoot '/var/www/magento'
  ServerName $DOMAIN_NAME.local
  ServerAlias www.$DOMAIN_NAME.local
  <Directory '/var/www/magento'>
    AllowOverride All
  </Directory>
</VirtualHost>"

echo "$VHOST" > /etc/apache2/sites-enabled/000-default.conf

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
if [[ ! -f "/vagrant/httpdocs/index.php" ]]; then
  cd /vagrant/httpdocs
  if [[ ! -f "/vagrant/assets/${MAGE_VERSION}.tar.gz" ]]; then
    wget https://github.com/OpenMage/magento-mirror/archive/${MAGE_VERSION}.tar.gz
    sudo cp ${MAGE_VERSION}.tar.gz ../assets/.
  else
    sudo cp ../assets/${MAGE_VERSION}.tar.gz .
  fi
  tar -zxf ${MAGE_VERSION}.tar.gz
  mv magento-mirror-${MAGE_VERSION}/* magento-mirror-${MAGE_VERSION}/.htaccess .
  sed -i 's#<pdo_mysql/>#<pdo_mysql>1</pdo_mysql>#g' app/code/core/Mage/Install/etc/config.xml
  chmod -R o+w media var
  chmod o+w app/etc
  # Clean up downloaded file and extracted dir
  rm -rf magento*
  rm ${MAGE_VERSION}.tar.gz
fi


# Sample Data
if [[ $SAMPLE_DATA == "true" ]]; then
  cd /vagrant
  if [[ ! -f "/vagrant/assets/magento-sample-data-${DATA_VERSION}.tar.gz" ]]; then
    # Only download sample data if we need to
    wget http://mirror.gunah.eu/magento/sample-data/magento-sample-data-${DATA_VERSION}.tar.gz
    cp magento-sample-data-${DATA_VERSION}.tar.gz assets/.
  else
    cp assets/magento-sample-data-${DATA_VERSION}.tar.gz .
  fi

  tar -zxf magento-sample-data-${DATA_VERSION}.tar.gz
  cp -R magento-sample-data-${DATA_VERSION}/media/* httpdocs/media/
  cp -R magento-sample-data-${DATA_VERSION}/skin/*  httpdocs/skin/
  mysql -u root magentodb < magento-sample-data-${DATA_VERSION}/magento_sample_data_for_${DATA_VERSION}.sql
  rm -rf magento-sample-data-${DATA_VERSION}
  rm magento-sample-data-${DATA_VERSION}.tar.gz
  sudo chmod 777 -R httpdocs/media/
fi


# Run installer
if [ ! -f "/vagrant/httpdocs/app/etc/local.xml" ]; then
  cd /vagrant/httpdocs
  sudo /usr/bin/php -f install.php -- --license_agreement_accepted yes --locale fr_FR --timezone "Europe/Paris" --default_currency EUR --db_host localhost --db_name magentodb --db_user magentouser --db_pass password --url "http://"${DOMAIN_NAME}".local/" --use_rewrites yes --use_secure no --secure_base_url "http://"${DOMAIN_NAME}".local/" --use_secure_admin no --skip_url_validation yes --admin_lastname Owner --admin_firstname Store --admin_email "admin@example.com" --admin_username admin --admin_password password123123
  /usr/bin/php -f shell/indexer.php reindexall
fi

# Install n98-magerun
# --------------------
cd /vagrant/httpdocs
wget https://files.magerun.net/n98-magerun.phar
chmod +x ./n98-magerun.phar
sudo mv ./n98-magerun.phar /usr/local/bin/


# after install
sudo cp -r /vagrant/code/* /vagrant/httpdocs/
sudo chown -R www-data:www-data /vagrant/httpdocs/*
sudo chown -R www-data:www-data /vagrant/httpdocs/.*
sudo chmod -R 777 /vagrant/httpdocs/
n98-magerun.phar customer:create atr+client@atolcd.com password123 Antoine Trapet base
n98-magerun.phar dev:merge-js --on --global
n98-magerun.phar dev:merge-css --on --global
n98-magerun.phar dev:log --on --global
n98-magerun.phar cache:dir:flush
