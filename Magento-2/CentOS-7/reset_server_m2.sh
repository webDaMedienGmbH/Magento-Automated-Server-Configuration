#!/bin/bash
#====================================================================#
#  MagenX - SERVER RESET ON FIRST ROOT LOGIN                         #
#    Copyright (C) 2016 admin@magenx.com                             #
#       All rights reserved.                                         #
#====================================================================#
echo "" > ~/.bash_history && history -c

function pause() {
   read -p "$*"
}
sleep 1

printf "\033c"

FLAG="/var/log/password_reset.lock"

if [ ! -f ${FLAG} ]; then
## get ssh connection ip
USER_IP=$(last -i | grep "root.*still logged in" | awk '{print $3}')
for CSF_SSH in ${USER_IP}
do
csf -a ${CSF_SSH}  >/dev/null 2>&1
done
echo
echo
## change domain name
echo "=== RESET SERVER CONFIGURATION ==="
echo
read -e -p "---> Enter your domain name (without www.): " -i "myshop.com" MY_DOMAIN
MY_SHOP_PATH="/home/${MY_DOMAIN%%.*}/public_html"
mv /home/myshop /home/${MY_DOMAIN%%.*}

sed -i "s/myshop.com/${MY_DOMAIN}/g" /etc/nginx/sites-available/magento2.conf
sed -i "s/myshop/${MY_DOMAIN%%.*}/g" /etc/nginx/sites-available/magento2.conf

sed -i "s/myshop.com/${MY_DOMAIN}/g" ${MY_SHOP_PATH}/zend_opcache.sh
sed -i "s/myshop/${MY_DOMAIN%%.*}/g" ${MY_SHOP_PATH}/zend_opcache.sh

sed -i "s/myshop/${MY_DOMAIN%%.*}/" ${MY_SHOP_PATH}/images_opt.sh

sed -i "s/myshop.com/${MY_DOMAIN}/" /etc/cron.daily/clamscan
sed -i "s/myshop/${MY_DOMAIN%%.*}/" /etc/cron.daily/clamscan

sed -i "s/myshop/${MY_DOMAIN%%.*}/g" /etc/logrotate.d/magento

## change proftpd config
SERVER_IP_ADDR=$(ip route get 1 | awk '{print $NF;exit}')
USER_GEOIP=$(geoiplookup ${USER_IP} | awk {'print $4'})

sed -i "s/.*MasqueradeAddress.*/MasqueradeAddress  ${SERVER_IP_ADDR}/" /etc/proftpd.conf
sed -i "s/.*Allow from.*/Allow from ${USER_IP}/" /etc/proftpd.conf
sed -i "s/.*GeoIPAllowFilter.*/GeoIPAllowFilter  CountryCode  ${USER_GEOIP//,/}/" /etc/proftpd.conf

## reset mysql root password
MYSQL_ROOT_RESET=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 15 | head -n 1)
ROOT_DB_PASS=$(grep password .my.cnf | cut -d'=' -f2)
mysqladmin -u root -p${ROOT_DB_PASS} password ${MYSQL_ROOT_RESET}  >/dev/null 2>&1
sed -i "s/.*password.*/password=${MYSQL_ROOT_RESET}/" /root/.my.cnf
sed -i "s/.*pass.*/pass=${MYSQL_ROOT_RESET}/" /root/.mytop
echo " > MySQL root password: ${MYSQL_ROOT_RESET}" >> /root/mascm/.reset_index

## reset mysql user password
MYSQL_USER_RESET=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 15 | head -n 1)
DATABASE_USERNAME=$(grep -Po "(?<='username' => ')\w*" ${MY_SHOP_PATH}/app/etc/env.php)
mysql -u root <<EOMYSQL
use mysql;
update user set password=PASSWORD("${MYSQL_USER_RESET}") where User="${DATABASE_USERNAME}";
flush privileges;
quit
EOMYSQL
MYSQL_USER_PASSWORD=$(grep -Po "(?<='password' => ')\w*" ${MY_SHOP_PATH}/app/etc/env.php)
sed -i "s/${MYSQL_USER_PASSWORD}/${MYSQL_USER_RESET}/" ${MY_SHOP_PATH}/app/etc/env.php
echo " > MySQL user: ${DATABASE_USERNAME}, and password: ${MYSQL_USER_RESET}" >> /root/mascm/.reset_index

## reset magento admin password
ADMIN_PASS=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1)
ADMIN_SALT=$(echo ${RANDOM})
ADMIN_PASS_RESET=${ADMIN_PASS}${ADMIN_SALT}
MAGENTO_DATABASE=$(grep -Po "(?<='dbname' => ')\w*" ${MY_SHOP_PATH}/app/etc/env.php)
mysql -u root <<EOMYSQL
use ${MAGENTO_DATABASE};
delete from admin_user;
delete from authorization_role WHERE authorization_role.role_id NOT IN (1);
update core_config_data set value = "http://www.${MY_DOMAIN}/" where config_id = 2;
exit
EOMYSQL
cd ${MY_SHOP_PATH}
bin/magento admin:user:create --admin-user="admin" --admin-password="${ADMIN_PASS_RESET}" --admin-email="admin@${MY_DOMAIN}" --admin-firstname="Name" --admin-lastname="Lastname"  >/dev/null 2>&1
echo " > Magento admin password: ${ADMIN_PASS_RESET}" >> /root/mascm/.reset_index

## update mysql config
IBPS=$(echo "0.5*$(awk '/MemTotal/ { print $2 / (1024*1024)}' /proc/meminfo | cut -d'.' -f1)" | bc | xargs printf "%1.0f")
sed -i "s/.*innodb_buffer_pool_instances.*/innodb_buffer_pool_instances = ${IBPS}/" /etc/my.cnf
sed -i "s/.*innodb_buffer_pool_size.*/innodb_buffer_pool_size = ${IBPS}G/" /etc/my.cnf

## reset magento admin path
MAGE_ADMIN_PATH=$(grep -Po "(?<='frontName' => ')\w*" ${MY_SHOP_PATH}/app/etc/env.php)
MAGE_ADMIN_RESET=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z' | fold -w 10 | head -n 1)
sed -i "s/${MAGE_ADMIN_PATH}/${MAGE_ADMIN_RESET}/" ${MY_SHOP_PATH}/app/etc/env.php
echo " > Magento admin path: http://www.${MY_DOMAIN}/${MAGE_ADMIN_RESET}" >> /root/mascm/.reset_index

## change PMA folder
PMA_FOLDER=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z' | fold -w 7 | head -n 1)
mv ${MY_SHOP_PATH}/pub/*_PMA  ${MY_SHOP_PATH}/pub/${PMA_FOLDER}_PMA
echo " > phpMyAdmin location: http://www.${MY_DOMAIN}/${PMA_FOLDER}_PMA" >> /root/mascm/.reset_index

## change opcache gui file name
OPCACHE_GUI=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z' | fold -w 7 | head -n 1)
mv ${MY_SHOP_PATH}/pub/*_opcache_gui.php ${MY_SHOP_PATH}/pub/${OPCACHE_GUI}_opcache_gui.php
sed -i "s/*_opcache_gui.php/${OPCACHE_GUI}_opcache_gui.php/" ${MY_SHOP_PATH}/zend_opcache.sh
echo " > Opcache GUI file: http://www.${MY_DOMAIN}/${OPCACHE_GUI}_opcache_gui.php" >> /root/mascm/.reset_index

## reset/generate password for linux user
LINUX_USER_RESET=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z' | fold -w 15 | head -n 1)
usermod -l ${MY_DOMAIN%%.*} myshop
groupmod -n ${MY_DOMAIN%%.*} myshop
usermod -d ${MY_SHOP_PATH} ${MY_DOMAIN%%.*}
echo "${MY_DOMAIN%%.*}:${LINUX_USER_RESET}"  | chpasswd
usermod -G ${MY_DOMAIN%%.*} nginx
usermod -G apache ${MY_DOMAIN%%.*}
sed -i "s/user = myshop/user = ${MY_DOMAIN%%.*}/" /etc/php-fpm.d/www.conf
sed -i "s/group = myshop/group = ${MY_DOMAIN%%.*}/" /etc/php-fpm.d/www.conf
echo " > Magento FTP user: ${MY_DOMAIN%%.*}, and password: ${LINUX_USER_RESET}" >> /root/mascm/.reset_index

## fix cron path
mv /var/spool/cron/myshop /var/spool/cron/${MY_DOMAIN%%.*}
sed -i "s/myshop.com/${MY_DOMAIN}/g" /var/spool/cron/${MY_DOMAIN%%.*}
sed -i "s/myshop/${MY_DOMAIN%%.*}/g" /var/spool/cron/${MY_DOMAIN%%.*}

## reset webmin password
WEBMIN_PASS=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 15 | head -n 1)
/usr/libexec/webmin/changepass.pl /etc/webmin/ webadmin ${WEBMIN_PASS}  >/dev/null 2>&1
echo " > Webmin user: webadmin, and password: ${WEBMIN_PASS}" >> /root/mascm/.reset_index

## check magento versions
MAGELATEST=$(curl -s https://api.github.com/repos/magento/magento2/releases 2>&1 | head -12 | grep 'tag_name' | grep -oP '(?<=")\d.*(?=")')
cd ${MY_SHOP_PATH}
MAGELOCAL=$(php bin/magento --version | rev | cut -d' ' -f1)
echo "" >> /root/mascm/.reset_index
echo " > Latest Magento version: ${MAGELATEST}"  >> /root/mascm/.reset_index
echo " > Installed version: ${MAGELOCAL}"  >> /root/mascm/.reset_index
if [[ "${MAGELOCAL//./}" -lt "${MAGELATEST//./}" ]]; then echo " > You need to upgrade to ${MAGELATEST}"  >> /root/mascm/.reset_index; fi
echo "" >> /root/mascm/.reset_index
## set lock file
touch ${FLAG}
## display new details
echo "" >> /root/mascm/.reset_index
echo "================================================================================="
echo
cat /root/mascm/.reset_index
echo
echo "================================================================================="
echo 
echo "To manage your server from Windows use: https://www.netsarang.com/download/down_xsh.html"
echo
echo
## remove old details
rm -rf /root/mascm/.mascm_index
echo
## copy details and do system update
pause "---> Print it out or copy and save these details, then press [Enter] key to quickly update the system"
echo
echo "---> CHECKING UPDATES. PLEASE WAIT ..."
UPDATES=$(yum check-update | grep updates$ | wc -l)
KERNEL=$(yum check-update | grep ^kernel | wc -l)
if [ "${UPDATES}" -gt 0 ] || [ "${KERNEL}" -gt 0 ]; then
echo
echo
echo "---> NEW UPDATED PKGS: ${UPDATES}"
echo "---> NEW KERNEL PKGS: ${KERNEL}"
echo
echo "---> THE UPDATES ARE BEING INSTALLED"
yum -y -q update >/dev/null 2>&1
echo
if [ "${KERNEL}" -gt 0 ]; then
echo "---> THE KERNEL HAS BEEN UPGRADED, PLEASE REBOOT"
fi
fi
echo
echo "---> THE SERVER IS READY. THANK YOU"
echo
/etc/init.d/webmin restart  >/dev/null 2>&1
service proftpd restart  >/dev/null 2>&1
service nginx restart  >/dev/null 2>&1
service mysql restart  >/dev/null 2>&1
service php-fpm restart  >/dev/null 2>&1
pkill zend_opcache.sh  >/dev/null 2>&1
pkill inotifywait  >/dev/null 2>&1
echo
## delete me
echo "" > ~/.bash_history && history -c
rm -- "$0"
else
echo "PASSED: PASSWORDS RESET LOCK FOUND"
fi
