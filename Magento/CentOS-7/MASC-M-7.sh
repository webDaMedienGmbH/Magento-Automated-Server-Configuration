#!/bin/bash
#====================================================================#
#  MagenX - Automated Server Configuration for Magento               #
#    Copyright (C) 2015 admin@magenx.com                             #
#       All rights reserved.                                         #
#====================================================================#
SELF=$(basename $0)
MASCM_VER="7.7.8"

### DEFINE LINKS AND PACKAGES STARTS ###

# Software versions
#MAGENTO_VER=$(wget -q -O- http://connect20.magentocommerce.com/community/Mage_All_Latest/releases.xml | tail -6 | grep -Po '(?<=<v>).*(?=</v>)')
MAGENTO_TMP_FILE="https://www.dropbox.com/s/v6libswo5zd68q2/magento-1.9.2.2-2015-10-27-03-19-32.tar.gz"
MAGENTO_VER="1.9.2.2"
PHPMYADMIN_VER="4.5.1"
AOE_SCHEDULER="1.2.2"

# Webmin Control Panel
WEBMIN="http://prdownloads.sourceforge.net/webadmin/webmin-1.770-1.noarch.rpm"
WEBMIN_NGINX="https://github.com/magenx/webmin-nginx/archive/nginx-0.08.wbm__0.tar.gz"

# Repositories
REPO_EPEL="http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm"
REPO_PERCONA="http://www.percona.com/redir/downloads/percona-release/redhat/latest/percona-release-0.1-3.noarch.rpm"
REPO_NGINX="http://nginx.org/packages/mainline/centos/7/x86_64/"
REPO_REMI="http://rpms.famillecollet.com/enterprise/remi-release-7.rpm"
REPO_HHVM="https://yum.gleez.com/7/x86_64/hhvm-3.9.1-1.el7.centos.x86_64.rpm"

# WebStack Packages
EXTRA_PACKAGES="boost tbb lz4 libyaml libdwarf bind-utils e2fsprogs svn gcc iptraf inotify-tools net-tools mcrypt mlocate unzip vim wget curl sudo bc mailx clamav-filesystem clamav-server clamav-update clamav-milter-systemd clamav-data clamav-server-systemd clamav-scanner-systemd clamav clamav-milter clamav-lib clamav-scanner proftpd logrotate git patch ipset strace rsyslog gifsicle GeoIP ImageMagick libjpeg-turbo-utils pngcrush lsof goaccess net-snmp net-snmp-utils xinetd python-pip ncftp"
PHP_PACKAGES=(cli common fpm opcache gd curl mbstring bcmath soap mcrypt mysqlnd pdo xml xmlrpc intl) 
PHP_PECL_PACKAGES=(pecl-redis pecl-lzf pecl-geoip)
PERCONA_PACKAGES=(client-56 server-56)
PERL_MODULES=(libwww-perl Time-HiRes ExtUtils-CBuilder ExtUtils-MakeMaker TermReadKey DBI DBD-MySQL Digest-HMAC Digest-SHA1 Test-Simple Moose Net-SSLeay)
PROFTPD_CONF="https://raw.githubusercontent.com/magenx/Magento-Automated-Server-Configuration-from-MagenX/master/tmp/proftpd.conf"

# Nginx extra configuration
NGINX_BASE="https://raw.githubusercontent.com/magenx/Magento-nginx-config/master/magento/"
NGINX_EXTRA_CONF="error_page.conf extra_protect.conf export.conf hhvm.conf headers.conf maintenance.conf multishop.conf pagespeed.conf spider.conf"
NGINX_EXTRA_CONF_URL="https://raw.githubusercontent.com/magenx/Magento-nginx-config/master/magento/conf.d/"

# Debug Tools
MYSQL_TUNER="https://raw.githubusercontent.com/major/MySQLTuner-perl/master/mysqltuner.pl"
MYSQL_TOP="https://launchpad.net/ubuntu/+archive/primary/+files/mytop_1.9.1.orig.tar.gz"

# Malware detector
MALDET="http://www.rfxn.com/downloads/maldetect-current.tar.gz"

### DEFINE LINKS AND PACKAGES ENDS ###

# Simple colors
RED="\e[31;40m"
GREEN="\e[32;40m"
YELLOW="\e[33;40m"
WHITE="\e[37;40m"
BLUE="\e[0;34m"

# Background
DGREYBG="\t\t\e[100m"
BLUEBG="\e[44m"
REDBG="\t\t\e[41m"

# Styles
BOLD="\e[1m"

# Reset
RESET="\e[0m"

# quick-n-dirty settings
function WHITETXT() {
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "\t\t${WHITE}${MESSAGE}${RESET}"
}
function BLUETXT() {
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "\t\t${BLUE}${MESSAGE}${RESET}"
}
function REDTXT() {
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "\t\t${RED}${MESSAGE}${RESET}"
}
function GREENTXT() {
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "\t\t${GREEN}${MESSAGE}${RESET}"
}
function YELLOWTXT() {
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "\t\t${YELLOW}${MESSAGE}${RESET}"
}
function BLUEBG() {
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "${BLUEBG}${MESSAGE}${RESET}"
}

function pause() {
   read -p "$*"
}

function start_progress {
  while true
  do
    echo -ne "#"
    sleep 1
  done
}

function quick_progress {
  while true
  do
    echo -ne "#"
    sleep 0.05
  done
}

function long_progress {
  while true
  do
    echo -ne "#"
    sleep 3
  done
}

function stop_progress {
kill $1
wait $1 2>/dev/null
echo -en "\n"
}

clear
###################################################################################
#                                     START CHECKS                                #
###################################################################################
echo
echo
# Check licence key
# MASCM_BASE="http://www.magenx.com/mascm"
# read -p "---> Paste your licence key and press enter: " KEY_OWNER
# echo
#  KEY_OUT=$(curl ${MASCM_BASE}/ver 2>&1 | grep ${KEY_OWNER} | awk '{print $2}')
#  KEY_IN=$(echo ${HOSTNAME} | md5sum | awk '{print $1}')
#if [[ "${KEY_OUT}" == "${KEY_IN}" ]]; then
#    GREENTXT "PASS: INTEGRITY CHECK FOR '${SELF}' ON '${HOSTNAME}' OK"
# elif [[ "${KEY_OUT}" != "${KEY_IN}" ]]; then
#    echo
#    REDTXT "ERROR: INTEGRITY CHECK FAILED! MD5 MISMATCH!"
#    REDTXT "YOU CAN NOT RUN THIS SCRIPT WITHOUT A LICENCE KEY"
#    echo "Local md5:  ${KEY_IN}"
#    echo "Remote md5: ${KEY_OUT}"
#    echo
#    echo "-----> NOTE: PLEASE REPORT IT TO: admin@magenx.com"
#       echo
#       echo
#       exit 1
#fi

# root?
if [[ ${EUID} -ne 0 ]]; then
  echo
  REDTXT "ERROR: THIS SCRIPT MUST BE RUN AS ROOT!"
  YELLOWTXT "------> USE SUPER-USER PRIVILEGES."
  exit 1
  else
  GREENTXT "PASS: ROOT!"
fi

# do we have CentOS 7?
if grep "CentOS.* 7\." /etc/centos-release  > /dev/null 2>&1; then
  GREENTXT "PASS: CENTOS RELEASE 7"
  else
  echo
  REDTXT "ERROR: UNABLE TO DETERMINE DISTRIBUTION TYPE."
  YELLOWTXT "------> THIS CONFIGURATION FOR CENTOS 7"
  echo
  exit 1
fi

# check if x64. if not, beat it...
ARCH=$(uname -m)
if [ "${ARCH}" = "x86_64" ]; then
  GREENTXT "PASS: YOUR ARCHITECTURE IS 64-BIT"
  else
  echo
  REDTXT "ERROR: YOUR ARCHITECTURE IS 32-BIT?"
  YELLOWTXT "------> CONFIGURATION FOR 64-BIT ONLY."
  echo
  exit 1
fi

# check if memory is enough
TOTALMEM=$(awk '/MemTotal/ { print $2 }' /proc/meminfo)
if [ "${TOTALMEM}" -gt "3000000" ]; then
  GREENTXT "PASS: YOU HAVE ${TOTALMEM} Kb OF RAM"
  else
  echo
  REDTXT "WARNING: YOU HAVE LESS THAN 3Gb OF RAM"
fi

# some selinux, sir?
if [ -f "/etc/selinux/config" ]; then
SELINUX=$(sestatus | awk '{print $3}')
if [ "${SELINUX}" != "disabled" ]; then
  echo
  REDTXT "ERROR: SELINUX IS NOT DISABLED"
  YELLOWTXT "------> PLEASE CHECK YOUR SELINUX SETTINGS"
  echo
  exit 1
  else
  GREENTXT "PASS: SELINUX IS DISABLED"
fi
fi

# network is up?
host1=74.125.24.106
host2=208.80.154.225
RESULT=$(((ping -w3 -c2 ${host1} || ping -w3 -c2 ${host2}) > /dev/null 2>&1) && echo "up" || (echo "down" && exit 1))
if [[ ${RESULT} == up ]]; then
  GREENTXT "PASS: NETWORK IS UP. GREAT, LETS START!"
  else
  echo
  REDTXT "ERROR: NETWORK IS DOWN?"
  YELLOWTXT "------> PLEASE CHECK YOUR NETWORK SETTINGS."
  echo
  echo
  exit 1
fi
echo
###################################################################################
#                                     CHECKS END                                  #
###################################################################################
echo
if grep -q "yes" /root/mascm/.terms >/dev/null 2>&1 ; then
  echo "loading menu"
  sleep 1
  else
  YELLOWTXT "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  echo
  YELLOWTXT "BY INSTALLING THIS SOFTWARE AND BY USING ANY AND ALL SOFTWARE"
  YELLOWTXT "YOU ACKNOWLEDGE AND AGREE:"
  echo
  YELLOWTXT "THIS SOFTWARE AND ALL SOFTWARE PROVIDED IS PROVIDED AS IS"
  YELLOWTXT "UNSUPPORTED AND WE ARE NOT RESPONSIBLE FOR ANY DAMAGE"
  echo
  YELLOWTXT "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  echo
   echo
    echo -n "---> Do you agree to these terms?  [y/n][y]:"
    read terms_agree
  if [ "${terms_agree}" == "y" ];then
    mkdir -p /root/mascm/ && echo "yes" > /root/mascm/.terms
          else
        REDTXT "Going out. EXIT"
        echo
    exit 1
  fi
fi
###################################################################################
#                                  HEADER MENU START                              #
###################################################################################

showMenu () {
printf "\033c"
    echo
      echo
        echo -e "${DGREYBG}${BOLD}  MAGENTO SERVER CONFIGURATION v.${MASCM_VER}  ${RESET}"
        BLUETXT ":::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
        echo
        WHITETXT "-> Install repository and LEMP packages :  ${YELLOW}\tlemp"
        WHITETXT "-> Download latest Magento package      :  ${YELLOW}\t\tmagento"
        WHITETXT "-> Setup Magento database               :  ${YELLOW}\t\t\tdatabase"
        WHITETXT "-> Install Magento (no sample data)     :  ${YELLOW}\t\tinstall"
        echo
        BLUETXT ":::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
        echo
        WHITETXT "-> Install CSF firewall                 :  ${YELLOW}\t\t\tfirewall"
        WHITETXT "-> Install Webmin Control Panel         :  ${YELLOW}\t\twebmin"
        echo
        BLUETXT ":::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
        echo
        WHITETXT "-> To quit and exit                     :  ${RED}\t\t\t\texit"
        echo
    echo
}
while [ 1 ]
do
        showMenu
        read CHOICE
        case "${CHOICE}" in
                "lemp")
echo
echo
if grep -q "yes" /root/mascm/.sysupdate >/dev/null 2>&1 ; then
echo
else
## Install EPEL repository
rpm --quiet -U ${REPO_EPEL} >/dev/null 2>&1
## install all extra packages
GREENTXT "INSTALLING EXTRA PACKAGES. PLEASE WAIT"
yum -q -y install ${EXTRA_PACKAGES} ${PERL_MODULES[@]/#/perl-} >/dev/null 2>&1
echo
GREENTXT "CHECKING UPDATES. PLEASE WAIT"
## checking updates
UPDATES=$(yum check-update | grep updates$ | wc -l)
KERNEL=$(yum check-update | grep ^kernel | wc -l)
if [ "${UPDATES}" -gt 0 ] || [ "${KERNEL}" -gt 0 ]; then
echo
YELLOWTXT "---> NEW UPDATED PKGS: ${UPDATES}"
YELLOWTXT "---> NEW KERNEL PKGS: ${KERNEL}"
echo
GREENTXT "THE UPDATES ARE BEING INSTALLED"
            echo
            echo -n "     PROCESSING  "
            long_progress &
            pid="$!"
            yum -y -q update >/dev/null 2>&1
            stop_progress "$pid"
            echo
            GREENTXT "THE SYSTEM IS UP TO DATE  -  OK"
            echo "yes" > /root/mascm/.sysupdate
            echo
fi
fi
echo
echo
echo "-------------------------------------------------------------------------------------"
BLUEBG "| START THE INSTALLATION OF REPOSITORIES AND PACKAGES |"
echo "-------------------------------------------------------------------------------------"
echo
WHITETXT "============================================================================="
echo
echo -n "---> Start Percona repository and Percona database installation? [y/n][n]:"
read repo_percona_install
if [ "${repo_percona_install}" == "y" ];then
          echo
            GREENTXT "Installation of Percona repository:"
            echo
            echo -n "     PROCESSING  "
            quick_progress &
            pid="$!"
            rpm --quiet -U ${REPO_PERCONA} >/dev/null 2>&1
            stop_progress "$pid"
            rpm  --quiet -q percona-release
      if [ "$?" = 0 ] # if repository installed then install package
        then
          echo
            GREENTXT "REPOSITORY HAS BEEN INSTALLED  -  OK"
              echo
              echo
              GREENTXT "Installation of Percona 5.6 database:"
              echo
              echo -n "     PROCESSING  "
              long_progress &
              pid="$!"
              yum -y -q install ${PERCONA_PACKAGES[@]/#/Percona-Server-}  >/dev/null 2>&1
              stop_progress "$pid"
              rpm  --quiet -q ${PERCONA_PACKAGES[@]/#/Percona-Server-}
        if [ "$?" = 0 ] # if package installed then configure
          then
            echo
              GREENTXT "DATABASE HAS BEEN INSTALLED  -  OK"
              echo
              systemctl enable mysql >/dev/null 2>&1
              echo
              WHITETXT "Downloading my.cnf file from MagenX Github repository"
              wget -qO /etc/my.cnf https://raw.githubusercontent.com/magenx/magento-mysql/master/my.cnf/my.cnf
              echo
                echo
                 WHITETXT "We need to correct your innodb_buffer_pool_size"
                 rpm -qa | grep -qw bc || yum -q -y install bc >/dev/null 2>&1
                 IBPS=$(echo "0.5*$(awk '/MemTotal/ { print $2 / (1024*1024)}' /proc/meminfo | cut -d'.' -f1)" | bc | xargs printf "%1.0f")
                 sed -i "s/innodb_buffer_pool_size = 4G/innodb_buffer_pool_size = ${IBPS}G/" /etc/my.cnf
                 echo
                 YELLOWTXT "Your innodb_buffer_pool_size = ${IBPS}G"
                echo
              echo
              ## get mysql tools
              wget -qO /etc/mysqltuner.pl ${MYSQL_TUNER}
              wget -qO - ${MYSQL_TOP} | tar -xzp && cd mytop*
              perl Makefile.PL && make && make install  >/dev/null 2>&1
              echo
              WHITETXT "Please use these tools to check and finetune your database:"
              WHITETXT "mytop"
              WHITETXT "perl /etc/mysqltuner.pl"
              echo
              else
              echo
              REDTXT "DATABASE INSTALLATION ERROR"
          exit # if package is not installed then exit
        fi
          else
            echo
              REDTXT "REPOSITORY INSTALLATION ERROR"
        exit # if repository is not installed then exit
      fi
        else
              echo
            YELLOWTXT "Percona repository installation was skipped by the user. Next step"
fi
echo
WHITETXT "============================================================================="
echo
echo -n "---> Start Nginx (mainline) Repository installation? [y/n][n]:"
read repo_nginx_install
if [ "${repo_nginx_install}" == "y" ];then
          echo
            GREENTXT "Installation of Nginx (mainline) repository:"
            echo
            WHITETXT "Downloading Nginx GPG key"
            wget -qO /etc/pki/rpm-gpg/nginx_signing.key  http://nginx.org/packages/keys/nginx_signing.key
            echo
            WHITETXT "Creating Nginx (mainline) repository file"
            echo
cat >> /etc/yum.repos.d/nginx.repo <<END
[nginx]
name=nginx repo
baseurl=${REPO_NGINX}
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/nginx_signing.key
gpgcheck=1
END
            echo
            GREENTXT "REPOSITORY HAS BEEN INSTALLED  -  OK"
            echo
            GREENTXT "Installation of NGINX package:"
            echo
            echo -n "     PROCESSING  "
            start_progress &
            pid="$!"
            yum -y -q install nginx  >/dev/null 2>&1
            stop_progress "$pid"
            rpm  --quiet -q nginx
      if [ "$?" = 0 ]
        then
          echo
            GREENTXT "NGINX HAS BEEN INSTALLED  -  OK"
            systemctl enable nginx >/dev/null 2>&1
              else
             echo
            REDTXT "NGINX INSTALLATION ERROR"
        exit
      fi
        else
          echo
            YELLOWTXT "Nginx (mainline) repository installation was skipped by the user. Next step"
fi
echo
WHITETXT "============================================================================="
echo
echo -n "---> Start the Remi repository and PHP 5.5 installation? [y/n][n]:"
read repo_remi_install
if [ "${repo_remi_install}" == "y" ];then
          echo
            GREENTXT "Installation of Remi repository:"
            echo
            echo -n "     PROCESSING  "
            quick_progress &
            pid="$!"
            rpm --quiet -U ${REPO_REMI} >/dev/null 2>&1
            stop_progress "$pid"
            rpm  --quiet -q remi-release
      if [ "$?" = 0 ]
        then
          echo
            GREENTXT "REPOSITORY HAS BEEN INSTALLED  -  OK"
            echo
            GREENTXT "Installation of PHP 5.5:"
            echo
            echo -n "     PROCESSING  "
            long_progress &
            pid="$!"
            yum --enablerepo=remi,remi-php55 -y -q install php ${PHP_PACKAGES[@]/#/php-} ${PHP_PECL_PACKAGES[@]/#/php-} >/dev/null 2>&1
            stop_progress "$pid"
            rpm  --quiet -q php
       if [ "$?" = 0 ]
         then
           echo
             GREENTXT "PHP HAS BEEN INSTALLED  -  OK"
             systemctl enable php-fpm >/dev/null 2>&1
             systemctl disable httpd >/dev/null 2>&1
             yum list installed | awk '/php.*x86_64/ {print "      ",$1}'
                else
               echo
             REDTXT "PHP INSTALLATION ERROR"
         exit
       fi
         echo
           echo
            GREENTXT "Installation of Redis package:"
            echo
            echo -n "     PROCESSING  "
            start_progress &
            pid="$!"
            yum --enablerepo=remi -y -q install redis >/dev/null 2>&1
            stop_progress "$pid"
            rpm  --quiet -q redis
       if [ "$?" = 0 ]
         then
           echo
             GREENTXT "REDIS HAS BEEN INSTALLED"
             systemctl disable redis >/dev/null 2>&1
             echo
for REDISPORT in 6379 6380
do
mkdir -p /var/lib/redis-${REDISPORT}
chmod 755 /var/lib/redis-${REDISPORT}
chown redis /var/lib/redis-${REDISPORT}
\cp -rf /etc/redis.conf /etc/redis.conf-${REDISPORT}
\cp -rf /usr/lib/systemd/system/redis.service /usr/lib/systemd/system/redis-${REDISPORT}.service

sed -i "s/daemonize no/daemonize yes/"  /etc/redis.conf-${REDISPORT}
sed -i "s/^bind 127.0.0.1.*/bind 127.0.0.1/"  /etc/redis.conf-${REDISPORT}
sed -i "s/^dir.*/dir \/var\/lib\/redis-${REDISPORT}\//"  /etc/redis.conf-${REDISPORT}
sed -i "s/^logfile.*/logfile \/var\/log\/redis\/redis-${REDISPORT}.log/"  /etc/redis.conf-${REDISPORT}
sed -i "s/^pidfile.*/pidfile \/var\/run\/redis\/redis-${REDISPORT}.pid/"  /etc/redis.conf-${REDISPORT}
sed -i "s/^port.*/port ${REDISPORT}/" /etc/redis.conf-${REDISPORT}
sed -i "s/redis.conf/redis.conf-${REDISPORT}/" /usr/lib/systemd/system/redis-${REDISPORT}.service
done
rm -rf /usr/lib/systemd/system/redis.service
systemctl daemon-reload
systemctl enable redis-6379 >/dev/null 2>&1
systemctl enable redis-6380 >/dev/null 2>&1
                else
               echo
             REDTXT "REDIS INSTALLATION ERROR"
         exit
       fi
         else
           echo
             REDTXT "REPOSITORY INSTALLATION ERROR"
        exit
      fi
        else
          echo
            YELLOWTXT "The Remi repository installation was skipped by the user. Next step"
fi
echo
WHITETXT "============================================================================="
echo
echo -n "---> Start Varnish 4.x installation? [y/n][n]:"
read varnish_install
if [ "${varnish_install}" == "y" ];then
          echo
            GREENTXT "Installation of Varnish package:"
            echo
            echo -n "     PROCESSING  "
            start_progress &
            pid="$!"
            yum -y -q install varnish  >/dev/null 2>&1
            stop_progress "$pid"
            rpm  --quiet -q varnish
      if [ "$?" = 0 ]
        then
          echo
            GREENTXT "VARNISH HAS BEEN INSTALLED  -  OK"
               else
              echo
            REDTXT "VARNISH INSTALLATION ERROR"
      fi
        else
          echo
            YELLOWTXT "Varnish installation was skipped by the user. Next step"
fi
echo
echo
WHITETXT "============================================================================="
echo
echo -n "---> Start HHVM installation? [y/n][n]:"
read hhvm_install
if [ "${hhvm_install}" == "y" ];then
          echo
            GREENTXT "Installation of HHVM package:"
            echo
            echo -n "     PROCESSING  "
            start_progress &
            pid="$!"
            yum -y -q install ${REPO_HHVM}  >/dev/null 2>&1
            stop_progress "$pid"
            rpm  --quiet -q hhvm
      if [ "$?" = 0 ]
        then
          echo
            GREENTXT "HHVM HAS BEEN INSTALLED  -  OK"
               else
              echo
            REDTXT "HHVM INSTALLATION ERROR"
      fi
        else
          echo
            YELLOWTXT "HHVM installation was skipped by the user. Next step"
fi
echo
echo "-------------------------------------------------------------------------------------"
BLUEBG "| THE INSTALLATION OF REPOSITORIES AND PACKAGES IS COMPLETE |"
echo "-------------------------------------------------------------------------------------"
echo
echo
GREENTXT "NOW WE ARE GOING TO CONFIGURE EVERYTHING"
echo
pause "---> Press [Enter] key to proceed"
echo
echo "Load optimized configs of php, opcache, fpm, fastcgi, sysctl, varnish"
WHITETXT "YOU HAVE TO CHECK THEM AFTER ANYWAY"
cat > /etc/sysctl.conf <<END
fs.file-max = 1000000
fs.inotify.max_user_watches = 1000000
vm.swappiness = 10
net.ipv4.ip_forward = 0
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.default.accept_source_route = 0
kernel.sysrq = 0
kernel.core_uses_pid = 1
kernel.msgmnb = 65535
kernel.msgmax = 65535
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 8388608 8388608 8388608
net.ipv4.tcp_rmem = 4096 87380 8388608
net.ipv4.tcp_wmem = 4096 65535 8388608
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_keepalive_time = 15
net.ipv4.tcp_max_orphans = 262144
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_max_tw_buckets = 400000
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_sack = 1
net.ipv4.route.flush = 1
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.rmem_default = 8388608
net.core.wmem_default = 8388608
net.core.netdev_max_backlog = 262144
net.core.somaxconn = 65535
END

sysctl -q -p
echo
WHITETXT "sysctl.conf loaded ${GREEN} [ok]"
cat > /etc/php.d/opcache.ini <<END
zend_extension=opcache.so
opcache.enable = 1
opcache.enable_cli = 1
opcache.memory_consumption = 256
opcache.interned_strings_buffer = 4
opcache.max_accelerated_files = 50000
opcache.max_wasted_percentage = 5
opcache.use_cwd = 1
opcache.validate_timestamps = 0
;opcache.revalidate_freq = 2
opcache.file_update_protection = 2
opcache.revalidate_path = 0
opcache.save_comments = 1
opcache.load_comments = 1
opcache.fast_shutdown = 0
opcache.enable_file_override = 0
opcache.optimization_level = 0xffffffff
opcache.inherited_hack = 1
opcache.blacklist_filename=/etc/php.d/opcache.blacklist.txt
opcache.max_file_size = 0
opcache.consistency_checks = 0
opcache.force_restart_timeout = 60
opcache.error_log = ""
opcache.log_verbosity_level = 1
opcache.preferred_memory_model = ""
opcache.protect_memory = 0
;opcache.mmap_base = ""
END

WHITETXT "opcache.ini loaded ${GREEN} [ok]"
#Tweak php.ini.
cp /etc/php.ini /etc/php.ini.BACK
sed -i 's/^\(max_execution_time = \)[0-9]*/\17200/' /etc/php.ini
sed -i 's/^\(max_input_time = \)[0-9]*/\17200/' /etc/php.ini
sed -i 's/^\(memory_limit = \)[0-9]*M/\1512M/' /etc/php.ini
sed -i 's/^\(post_max_size = \)[0-9]*M/\132M/' /etc/php.ini
sed -i 's/^\(upload_max_filesize = \)[0-9]*M/\132M/' /etc/php.ini
sed -i 's/expose_php = On/expose_php = Off/' /etc/php.ini
sed -i 's/;realpath_cache_size = 16k/realpath_cache_size = 512k/' /etc/php.ini
sed -i 's/;realpath_cache_ttl = 120/realpath_cache_ttl = 86400/' /etc/php.ini
sed -i 's/short_open_tag = Off/short_open_tag = On/' /etc/php.ini
sed -i 's/; max_input_vars = 1000/max_input_vars = 50000/' /etc/php.ini
sed -i 's/session.gc_maxlifetime = 1440/session.gc_maxlifetime = 86400/' /etc/php.ini
sed -i 's/mysql.allow_persistent = On/mysql.allow_persistent = Off/' /etc/php.ini
sed -i 's/mysqli.allow_persistent = On/mysqli.allow_persistent = Off/' /etc/php.ini
sed -i 's/;date.timezone =/date.timezone = UTC/' /etc/php.ini
sed -i 's/pm = dynamic/pm = ondemand/' /etc/php-fpm.d/www.conf
sed -i 's/;pm.max_requests = 500/pm.max_requests = 10000/' /etc/php-fpm.d/www.conf
sed -i 's/pm.max_children = 50/pm.max_children = 1000/' /etc/php-fpm.d/www.conf

WHITETXT "php.ini loaded ${GREEN} [ok]"
echo
echo "*         soft    nofile          700000" >> /etc/security/limits.conf
echo "*         hard    nofile          1000000" >> /etc/security/limits.conf
echo
echo
echo "-------------------------------------------------------------------------------------"
BLUEBG "| FINISHED PACKAGES INSTALLATION |"
echo "-------------------------------------------------------------------------------------"
echo
echo
pause '------> Press [Enter] key to show the menu'
printf "\033c"
;;
"magento")
###################################################################################
#                                MAGENTO                                          #
###################################################################################
echo
echo "-------------------------------------------------------------------------------------"
BLUEBG "| DOWNLOADING MAGENTO, TURPENTINE, PHPMYADMIN AND CONFIGURING NGINX |"
echo "-------------------------------------------------------------------------------------"
echo
echo -n "---> Download latest Magento version (${MAGENTO_VER}) ? [y/n][n]:"
read new_down
if [ "${new_down}" == "y" ];then
echo
     read -e -p "---> Enter folder full path: " -i "/var/www/html/myshop.com" MY_SHOP_PATH
        echo "  Magento will be downloaded to:"
        GREENTXT ${MY_SHOP_PATH}
        mkdir -p ${MY_SHOP_PATH} && cd $_
        echo -n "      DOWNLOADING MAGENTO  "
        long_progress &
        pid="$!"
        wget -qO - ${MAGENTO_TMP_FILE} | tar -xzp
        stop_progress "$pid"
        echo
fi
     echo
WHITETXT "============================================================================="
GREENTXT "      == MAGENTO DOWNLOADED AND READY FOR INSTALLATION =="
WHITETXT "============================================================================="
echo
echo
echo "---> CREATING NGINX CONFIGURATION FILES NOW"
echo
read -e -p "---> Enter your domain name (without www.): " -i "myshop.com" MY_DOMAIN

wget -qO /etc/nginx/port.conf ${NGINX_BASE}port.conf
wget -qO /etc/nginx/fastcgi_params  ${NGINX_BASE}fastcgi_params
wget -qO /etc/nginx/nginx.conf  ${NGINX_BASE}nginx.conf

sed -i "s/www/sites-enabled/g" /etc/nginx/nginx.conf

mkdir -p /etc/nginx/sites-enabled
mkdir -p /etc/nginx/sites-available && cd $_
wget -q ${NGINX_BASE}www/default.conf
wget -q ${NGINX_BASE}www/magento.conf

sed -i "s/example.com/${MY_DOMAIN}/g" /etc/nginx/sites-available/magento.conf
sed -i "s,root /var/www/html,root ${MY_SHOP_PATH},g" /etc/nginx/sites-available/magento.conf

ln -s /etc/nginx/sites-available/magento.conf /etc/nginx/sites-enabled/magento.conf
ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf

cd /etc/nginx/conf.d/ && rm -rf *
for CONFIG in ${NGINX_EXTRA_CONF}
do
wget -q ${NGINX_EXTRA_CONF_URL}${CONFIG}
done
echo
sed -i "s/user = apache/user = ${MY_DOMAIN%%.*}/" /etc/php-fpm.d/www.conf
sed -i "s/group = apache/group = ${MY_DOMAIN%%.*}/" /etc/php-fpm.d/www.conf
echo
pause '------> Press [Enter] key to continue'
mkdir -p /root/mascm/
cat >> /root/mascm/.mascm_index <<END
webshop ${MY_DOMAIN}    ${MY_SHOP_PATH}    ${MY_DOMAIN%%.*}
END
echo
###################################################################################
#                   LOADING ALL THE EXTRA TOOLS FROM HERE                         #
###################################################################################
echo
GREENTXT "Now we set up the PROFTPD server"
pause '------> Press [Enter] key to continue'
echo
     useradd -d ${MY_SHOP_PATH} -s /sbin/nologin ${MY_DOMAIN%%.*}  >/dev/null 2>&1
     LINUX_USER_PASS=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 15 | head -n 1)
     echo "${MY_DOMAIN%%.*}:${LINUX_USER_PASS}"  | chpasswd  >/dev/null 2>&1
     wget -qO /etc/proftpd.conf ${PROFTPD_CONF}
     ## change proftpd config
     SERVER_IP_ADDR=$(ip route get 1 | awk '{print $NF;exit}')
     USER_IP=$(last -i | grep "root.*still logged in" | awk 'NR==1{print $3}')
     USER_GEOIP=$(geoiplookup ${USER_IP} | awk '{print $4}')
     FTP_PORT=$(shuf -i 5121-5132 -n 1)
     sed -i "s/server_sftp_port/${FTP_PORT}/" /etc/proftpd.conf
     sed -i "s/server_ip_address/${SERVER_IP_ADDR}/" /etc/proftpd.conf
     sed -i "s/client_ip_address/${USER_IP}/" /etc/proftpd.conf
     sed -i "s/geoip_country_code/${USER_GEOIP//,/}/" /etc/proftpd.conf
     echo
     /bin/systemctl restart  proftpd.service
     echo
     WHITETXT "We have created a user: ${REDBG}${MY_DOMAIN%%.*}"
     WHITETXT "With a password: ${REDBG}${LINUX_USER_PASS}"
     WHITETXT "FTP PORT: ${REDBG}${FTP_PORT}"
     WHITETXT "Your GeoIP location: ${REDBG}${USER_GEOIP//,/}"
echo
GREENTXT "Installing phpMyAdmin - advanced MySQL interface"
pause '------> Press [Enter] key to continue'
echo
     cd ${MY_SHOP_PATH}
     PMA_FOLDER=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)
     BLOWFISHCODE=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
     mkdir -p ${PMA_FOLDER}_PMA && cd $_
     wget -qO - https://files.phpmyadmin.net/phpMyAdmin/${PHPMYADMIN_VER}/phpMyAdmin-${PHPMYADMIN_VER}-all-languages.tar.gz | tar -xzp --strip 1
     mv config.sample.inc.php config.inc.php
     sed -i "s/.*blowfish_secret.*/\$cfg['blowfish_secret'] = '${BLOWFISHCODE}';/" ./config.inc.php
     echo
     GREENTXT "phpMyAdmin was installed to http://www.${MY_DOMAIN}/${PMA_FOLDER}_PMA"
echo
echo
echo
GREENTXT "INSTALLING OPCACHE GUI"
pause '------> Press [Enter] key to continue'
echo
    cd ${MY_SHOP_PATH}
    OPCACHE_FILE=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z' | fold -w 12 | head -n 1)
    wget -qO ${OPCACHE_FILE}_opcache_gui.php https://raw.githubusercontent.com/magenx/opcache-gui/master/index.php
    echo
    GREENTXT "OPCACHE interface was installed to http://www.${MY_DOMAIN}/${OPCACHE_FILE}_opcache_gui.php"
echo
echo
echo
GREENTXT "INSTALLING Magento folder monitor and opcache invalidation script"
pause '------> Press [Enter] key to continue'
cat > ${MY_SHOP_PATH}/zend_opcache.sh <<END
#!/bin/bash
## monitor magento folder and log modified files
/usr/bin/inotifywait -e modify,move \\
    -mrq --timefmt %a-%b-%d-%T --format '%w%f %T' \\
    --excludei '/(cache|log|session|report|locks|media|skin|tmp)/|\.(xml|html?|css|js|gif|jpe?g|png|ico|te?mp|txt|csv|swp|sql|t?gz|zip|svn?g|git|log|ini|sh|pl)~?' \\
    ${MY_SHOP_PATH}/ | while read line; do
    echo "\$line " >> /var/log/zend_opcache_monitor.log
    FILE=\$(echo \${line} | cut -d' ' -f1 | sed -e 's/\/\./\//g' | cut -f1-2 -d'.')
    TARGETEXT="(php|phtml)"
    EXTENSION="\${FILE##*.}"
  if [[ "\$EXTENSION" =~ \$TARGETEXT ]];
    then
    curl --silent "http://www.${MY_DOMAIN}/${OPCACHE_FILE}_opcache_gui.php?page=invalidate&file=\${FILE}" >/dev/null 2>&1
  fi
done
END
echo
echo
    GREENTXT "Script was installed to ${MY_SHOP_PATH}/zend_opcache.sh"
echo
echo
    echo "${MY_SHOP_PATH}/zend_opcache.sh &" >> /etc/rc.local
echo
echo
if yum list installed "varnish" >/dev/null 2>&1; then
GREENTXT "VARNISH DAEMON CONFIGURATION FILE"
echo
wget -qO /etc/systemd/system/varnish.service https://raw.githubusercontent.com/magenx/MASC-M/master/tmp/varnish.service
sed -i "s,VCL_PATH,${MY_SHOP_PATH}/var/default.vcl,g" /etc/systemd/system/varnish.service
systemctl daemon-reload  >/dev/null 2>&1
systemctl enable varnish  >/dev/null 2>&1
echo
echo 'Varnish secret key -->'$(cat /etc/varnish/secret)'<-- copy it'
echo
WHITETXT "Varnish settings were loaded ${GREEN} [ok]"
echo
fi
echo
/bin/systemctl start nginx.service
/bin/systemctl start php-fpm.service
service redis-6379 restart
service redis-6380 restart
echo
echo
echo "-------------------------------------------------------------------------------------"
BLUEBG " CONFIGURATION IS COMPLETED "
echo "-------------------------------------------------------------------------------------"
echo
pause '------> Press [Enter] key to show menu'
printf "\033c"
;;
###################################################################################
#                                MAGENTO DATABASE SETUP                           #
###################################################################################
"database")
printf "\033c"
WHITETXT "============================================================================="
/bin/systemctl start mysql.service
echo
WHITETXT "CREATING MAGENTO DATABASE AND DATABASE USER"
echo
echo -n "---> Generate MySQL ROOT strong password? [y/n][n]:"
read mysql_rpass_gen
if [ "${mysql_rpass_gen}" == "y" ];then
   echo
       MYSQL_ROOT_PASSGEN=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 15 | head -n 1)
       WHITETXT "MySQL ROOT password: ${REDBG}${MYSQL_ROOT_PASSGEN}"
       GREENTXT "!REMEMBER IT AND KEEP IT SAFE!"
   echo
fi
echo -n "---> Start Mysql Secure Installation? [y/n][n]:"
read mysql_secure
if [ "${mysql_secure}" == "y" ];then
   mysql_secure_installation
fi
echo
read -p "---> Enter MySQL ROOT password : " MYSQL_ROOT_PASS
read -p "---> Enter Magento database host : " MAGE_DB_HOST
read -p "---> Enter Magento database name : " MAGE_DB_NAME
read -p "---> Enter Magento database user : " MAGE_DB_USER_NAME
echo
echo -n "---> Generate MySQL USER strong password? [y/n][n]:"
read mysql_upass_gen
if [ "${mysql_upass_gen}" == "y" ];then
   MYSQL_USER_PASSGEN=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 15 | head -n 1)
   WHITETXT "MySQL USER password: ${REDBG}${MYSQL_USER_PASSGEN}"
fi
echo
read -p "---> Enter MySQL USER password : " MAGE_DB_PASS
mysql -u root -p${MYSQL_ROOT_PASS} <<EOMYSQL
CREATE USER '${MAGE_DB_USER_NAME}'@'${MAGE_DB_HOST}' IDENTIFIED BY '${MAGE_DB_PASS}';
CREATE DATABASE ${MAGE_DB_NAME};
GRANT ALL PRIVILEGES ON ${MAGE_DB_NAME}.* TO '${MAGE_DB_USER_NAME}'@'${MAGE_DB_HOST}' WITH GRANT OPTION;
exit
EOMYSQL
echo
GREENTXT "MAGENTO DATABASE ${RED} ${MAGE_DB_NAME} ${GREEN}AND USER ${RED} ${MAGE_DB_USER_NAME} ${GREEN}CREATED, PASSWORD IS ${RED} ${MAGE_DB_PASS}"
GREENTXT "MySQL ROOT password: ${REDBG}${MYSQL_ROOT_PASS}"
echo

cat > /root/.mytop <<END
user=root
pass=${MYSQL_ROOT_PASS}
db=mysql
END

cat > /root/.my.cnf <<END
[client]
user=root
password=${MYSQL_ROOT_PASS}
END

echo
mkdir -p /root/mascm/
cat >> /root/mascm/.mascm_index <<END
database        ${MAGE_DB_HOST}   ${MAGE_DB_NAME}   ${MAGE_DB_USER_NAME}     ${MAGE_DB_PASS}    ${MYSQL_ROOT_PASS}
END
echo
echo "the end"
echo
echo
echo
pause '---> Press [Enter] key to show the menu'
;;
###################################################################################
#                                MAGENTO INSTALLATION                             #
###################################################################################
"install")
printf "\033c"
WHITETXT "============================================================================="
echo
echo "---> ENTER INSTALLATION INFORMATION"
DB_HOST=$(awk '/database/ { print $2 }' /root/mascm/.mascm_index)
DB_NAME=$(awk '/database/ { print $3 }' /root/mascm/.mascm_index)
DB_USER_NAME=$(awk '/database/ { print $4 }' /root/mascm/.mascm_index)
DB_PASS=$(awk '/database/ { print $5 }' /root/mascm/.mascm_index)
DOMAIN=$(awk '/webshop/ { print $2 }' /root/mascm/.mascm_index)
echo
WHITETXT "Database information"
read -e -p "---> Enter your database host: " -i "${DB_HOST}"  MAGE_DB_HOST
read -e -p "---> Enter your database name: " -i "${DB_NAME}"  MAGE_DB_NAME
read -e -p "---> Enter your database user: " -i "${DB_USER_NAME}"  MAGE_DB_USER_NAME
read -e -p "---> Enter your database password: " -i "${DB_PASS}"  MAGE_DB_PASS
echo
WHITETXT "Administrator and domain"
read -e -p "---> Enter your First Name: " -i "Name"  MAGE_ADMIN_FNAME
read -e -p "---> Enter your Last Name: " -i "Lastname"  MAGE_ADMIN_LNAME
read -e -p "---> Enter your email: " -i "admin@${DOMAIN}"  MAGE_ADMIN_EMAIL
read -e -p "---> Enter your admins login name: " -i "admin"  MAGE_ADMIN_LOGIN
MAGE_ADMIN_PASSGEN=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 9 | head -n 1)
read -e -p "---> Use generated admin password: " -i "${RANDOM}${MAGE_ADMIN_PASSGEN}"  MAGE_ADMIN_PASS
read -e -p "---> Enter your shop url: " -i "http://www.${DOMAIN}/"  MAGE_SITE_URL
echo
WHITETXT "Locale settings"
read -e -p "---> Enter your locale: " -i "en_GB"  MAGE_LOCALE
read -e -p "---> Enter your timezone: " -i "Europe/Paris"  MAGE_TIMEZONE
read -e -p "---> Enter your currency: " -i "EUR"  MAGE_CURRENCY
echo
WHITETXT "============================================================================="
echo
GREENTXT "NOW INSTALLING MAGENTO WITHOUT SAMPLE DATA"
MAGE_ADMIN_PATH=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z' | fold -w 12 | head -n 1)
MY_SHOP_PATH=$(awk '/webshop/ { print $3 }' /root/mascm/.mascm_index)
cd ${MY_SHOP_PATH}
chmod +x mage
sed -i "s/CURLOPT_SSL_CIPHER_LIST, 'TLSv1'/CURLOPT_SSLVERSION, CURL_SSLVERSION_TLSv1/" downloader/lib/Mage/HTTP/Client/Curl.php
./mage mage-setup .

php -f install.php -- \
--license_agreement_accepted "yes" \
--locale "${MAGE_LOCALE}" \
--timezone "${MAGE_TIMEZONE}" \
--default_currency "${MAGE_CURRENCY}" \
--db_host "${MAGE_DB_HOST}" \
--db_name "${MAGE_DB_NAME}" \
--db_user "${MAGE_DB_USER_NAME}" \
--db_pass "${MAGE_DB_PASS}" \
--url "${MAGE_SITE_URL}" \
--use_rewrites "yes" \
--use_secure "no" \
--secure_base_url "" \
--skip_url_validation "yes" \
--use_secure_admin "no" \
--admin_frontname "${MAGE_ADMIN_PATH}" \
--admin_firstname "${MAGE_ADMIN_FNAME}" \
--admin_lastname "${MAGE_ADMIN_LNAME}" \
--admin_email "${MAGE_ADMIN_EMAIL}" \
--admin_username "${MAGE_ADMIN_LOGIN}" \
--admin_password "${MAGE_ADMIN_PASS}"

GREENTXT "ok"
    echo
    WHITETXT "============================================================================="
    echo
    GREENTXT "INSTALLED THE LATEST STABLE VERSION OF MAGENTO WITHOUT SAMPLE DATA"
    echo
    WHITETXT "============================================================================="
    WHITETXT " MAGENTO ADMIN ACCOUNT"
    echo "      Admin path: ${MAGE_SITE_URL}${MAGE_ADMIN_PATH}"
    echo "      Username: ${MAGE_ADMIN_LOGIN}"
    echo "      Password: ${MAGE_ADMIN_PASS}"
    echo
    WHITETXT "============================================================================="
    WHITETXT " MAGENTO DATABASE INFO"
    echo
    echo "      Database: ${MAGE_DB_NAME}"
    echo "      Username: ${MAGE_DB_USER_NAME}"
    echo "      Password: ${MAGE_DB_PASS}"
    echo
    WHITETXT "============================================================================="
 echo
echo
echo
WHITETXT "-= FINAL MAINTENANCE AND CLEANUP =-"
echo
echo
echo "---> CHANGING YOUR local.xml FILE WITH REDIS SESSIONS AND CACHE BACKEND"
echo "---> Lets keep sessions on :6379 and cache on :6380"
echo
sed -i '/<session_save>/d' ${MY_SHOP_PATH}/app/etc/local.xml
sed -i '/<global>/ a\
 <session_save>db</session_save> \
    <redis_session> \
        <host>127.0.0.1</host> \
        <port>6379</port> \
        <password></password> \
        <timeout>10</timeout> \
	<persistent><![CDATA[db0]]></persistent> \
	<db>0</db> \
	<compression_threshold>2048</compression_threshold> \
	<compression_lib>lzf</compression_lib> \
	<log_level>1</log_level> \
	<max_concurrency>64</max_concurrency> \
	<break_after_frontend>5</break_after_frontend> \
	<break_after_adminhtml>30</break_after_adminhtml> \
        <first_lifetime>600</first_lifetime> \
	<bot_first_lifetime>60</bot_first_lifetime> \
	<bot_lifetime>7200</bot_lifetime> \
	<disable_locking>0</disable_locking> \
	<min_lifetime>86400</min_lifetime> \
	<max_lifetime>2592000</max_lifetime> \
    </redis_session> \
    <cache> \
        <backend>Cm_Cache_Backend_Redis</backend> \
        <backend_options> \
          <default_priority>10</default_priority> \
          <auto_refresh_fast_cache>1</auto_refresh_fast_cache> \
            <server>127.0.0.1</server> \
            <port>6380</port> \
            <persistent><![CDATA[db0]]></persistent> \
            <database>0</database> \
            <password></password> \
            <force_standalone>0</force_standalone> \
            <connect_retries>1</connect_retries> \
            <read_timeout>10</read_timeout> \
            <automatic_cleaning_factor>0</automatic_cleaning_factor> \
            <compress_data>1</compress_data> \
            <compress_tags>1</compress_tags> \
            <compress_threshold>204800</compress_threshold> \
            <compression_lib>lzf</compression_lib> \
        </backend_options> \
    </cache>' ${MY_SHOP_PATH}/app/etc/local.xml
echo
echo "---> DISABLING MAGENTO LOGS"
echo
sed -i '/<\/admin>/ a\
<frontend> \
        <events> \
            <controller_action_predispatch> \
            <observers><log><type>disabled</type></log></observers> \
            </controller_action_predispatch> \
            <controller_action_postdispatch> \
            <observers><log><type>disabled</type></log></observers> \
            </controller_action_postdispatch> \
            <customer_login> \
            <observers><log><type>disabled</type></log></observers> \
            </customer_login> \
            <customer_logout> \
            <observers><log><type>disabled</type></log></observers> \
            </customer_logout> \
            <sales_quote_save_after> \
            <observers><log><type>disabled</type></log></observers> \
            </sales_quote_save_after> \
            <checkout_quote_destroy> \
            <observers><log><type>disabled</type></log></observers> \
            </checkout_quote_destroy> \
        </events> \
</frontend>' ${MY_SHOP_PATH}/app/etc/local.xml
echo
echo "---> CLEANING UP INDEXES LOCKS AND RUNNING RE-INDEX ALL"
echo
rm -rf  ${MY_SHOP_PATH}/var/locks/*
php ${MY_SHOP_PATH}/shell/indexer.php --reindexall
echo
echo
echo "---> NOW WE INSTALL SELECTED EXTENSIONS"
echo
cd ${MY_SHOP_PATH}
./mage config-set preferred_state beta >/dev/null 2>&1
echo
echo -n "---> Would you like to install WebShopApps MatrixRate? [y/n][n]:"
read wsamr
if [ "${wsamr}" == "y" ];then
./mage install http://connect20.magentocommerce.com/community Auctionmaid_Matrxrate
fi
echo -n "---> Would you like to install M2EPro Ebay? [y/n][n]:"
read m2epro
if [ "${m2epro}" == "y" ];then
./mage install http://connect20.magentocommerce.com/community m2epro_ebay_magento
fi
echo -n "---> Would you like to install Enhanced Admin Grids (+ Editor)? [y/n][n]:"
read eage
if [ "${eage}" == "y" ];then
./mage install http://connect20.magentocommerce.com/community BL_CustomGrid
fi
echo -n "---> Would you like to install SMTP PRO Email? [y/n][n]:"
read smtppro
if [ "${smtppro}" == "y" ];then
./mage install http://connect20.magentocommerce.com/community ASchroder_SMTPPro
fi
echo -n "---> Would you like to install Nexcessnet Turpentine? [y/n][n]:"
read netu
if [ "${netu}" == "y" ];then
./mage install http://connect20.magentocommerce.com/community Nexcessnet_Turpentine
fi
echo
## these we install by default
cd /usr/local/src/
wget -qO - https://github.com/AOEpeople/Aoe_Scheduler/archive/v${AOE_SCHEDULER}.tar.gz | tar -xz
cp -rf Aoe_Scheduler-${AOE_SCHEDULER}/{app,shell,skin,var,scheduler_cron.sh}  ${MY_SHOP_PATH}/
echo
wget -q https://github.com/AOEpeople/Aoe_Profiler/archive/master.zip -O Aoe_Profiler.zip; unzip -qq Aoe_Profiler.zip; rm -rf Aoe_Profiler.zip
cp -rf Aoe_Profiler*/{app,skin,var}  ${MY_SHOP_PATH}/
echo
echo "---> CREATE SIMPLE LOGROTATE SCRIPT FOR MAGENTO LOGS"
cat >> /etc/logrotate.d/magento <<END
${MY_SHOP_PATH}/var/log/*.log
{
weekly
rotate 4
notifempty
missingok
compress
}
END
echo
echo "---> SETUP DAILY CLAMAV SCANNER"
cat >> /etc/cron.daily/clamscan <<END
#!/bin/bash
SCAN_MAGE="${MY_SHOP_PATH}"
SCAN_TMP="/tmp"
LOG_FILE="/var/log/clamav/clamscan.daily"

alert_check () {
    if [ \$(grep "Infected.*[1-9].*" \${LOG_FILE} | wc -l) != 0 ]
    then
        mail -s "INFECTED FILES FOUND ON \${HOSTNAME}" "${MAGE_ADMIN_EMAIL}" < \${LOG_FILE}
        cp \${LOG_FILE} \${LOG_FILE}_INFECTED_\$(date +"%m-%d-%Y")
        echo "" > \${LOG_FILE}
    else
        echo "" > \${LOG_FILE}
    fi
}

/usr/bin/clamscan -i -r \${SCAN_MAGE} >> \${LOG_FILE}
/usr/bin/clamscan -i -r \${SCAN_TMP} >> \${LOG_FILE}

alert_check
END
chmod +x /etc/cron.daily/clamscan
echo
echo "---> IMAGES OPTIMIZATION SCRIPT"
wget -qO ${MY_SHOP_PATH}/wesley.pl https://raw.githubusercontent.com/magenx/MASC-M/master/tmp/wesley.pl
echo
cat >> ${MY_SHOP_PATH}/images_opt.sh <<END
#!/bin/bash
## monitor media folder and optimize new images
/usr/bin/inotifywait -e create \\
    -mrq --timefmt %a-%b-%d-%T --format '%w%f %T' \\
    --excludei '\.(xml|php|phtml|html?|css|js|ico|te?mp|txt|csv|swp|sql|t?gz|zip|svn?g|git|log|ini|opt|prog|crush)~?' \\
    ${MY_SHOP_PATH}/media | while read line; do
    echo "\${line} " >> ${MY_SHOP_PATH}/var/log/images_optimization.log
    FILE=\$(echo \${line} | cut -d' ' -f1)
    TARGETEXT="(jpg|jpeg|png|gif)"
    EXTENSION="\${FILE##*.}"
  if [[ "\${EXTENSION}" =~ \${TARGETEXT} ]];
    then
   su - ${MY_DOMAIN%%.*} -s /bin/bash -c "${MY_SHOP_PATH}/wesley.pl \${FILE} > /dev/null"
  fi
done
END
echo "${MY_SHOP_PATH}/images_opt.sh &" >> /etc/rc.local
chmod +x /etc/rc.local
echo
cat >> ${MY_SHOP_PATH}/cron_check.sh <<END
#!/bin/bash
pgrep images_opt.sh > /dev/null || ${MY_SHOP_PATH}/images_opt.sh &
pgrep zend_opcache.sh > /dev/null || ${MY_SHOP_PATH}/zend_opcache.sh &
END
echo
        crontab -l -u ${MY_DOMAIN%%.*} > magecron
        echo "MAILTO="${MAGE_ADMIN_EMAIL}"" >> magecron
        echo "* * * * * ! test -e ${MY_SHOP_PATH}/maintenance.flag && /bin/bash ${MY_SHOP_PATH}/scheduler_cron.sh --mode always" >> magecron
	echo "* * * * * ! test -e ${MY_SHOP_PATH}/maintenance.flag && /bin/bash ${MY_SHOP_PATH}/scheduler_cron.sh --mode default" >> magecron
        echo "*/5 * * * * /bin/bash ${MY_SHOP_PATH}/cron_check.sh" >> magecron
	echo "*/10 * * * * ! test -e ${MY_SHOP_PATH}/maintenance.flag && cd ${MY_SHOP_PATH}/shell && /usr/bin/php scheduler.php --action watchdog" >> magecron
        crontab -u ${MY_DOMAIN%%.*} magecron
        rm magecron
echo
cd ${MY_SHOP_PATH}
mkdir -p var/log
find . -type f -exec chmod 644 {} \;
find . -type d -exec chmod 755 {} \;
chown -R ${MY_DOMAIN%%.*}:${MY_DOMAIN%%.*} ${MY_SHOP_PATH}
rm -rf index.php.sample LICENSE_AFL.txt LICENSE.html LICENSE.txt RELEASE_NOTES.txt php.ini.sample dev
chmod +x cron_check.sh images_opt.sh zend_opcache.sh scheduler_cron.sh mage cron.sh wesley.pl
${MY_SHOP_PATH}/zend_opcache.sh &
${MY_SHOP_PATH}/images_opt.sh &
echo
echo
    GREENTXT "NOW LOGIN TO YOUR BACKEND AND CHECK EVERYTHING"
    echo
  echo
echo
pause '---> Press [Enter] key to show menu'
;;
###################################################################################
#                          INSTALLING CSF FIREWALL                                #
###################################################################################
"firewall")
WHITETXT "============================================================================="
echo
echo -n "---> Would you like to install CSF firewall? [y/n][n]:"
read csf_test
if [ "${csf_test}" == "y" ];then
           echo
               GREENTXT "DOWNLOADING CSF FIREWALL"
               echo
               cd /usr/local/src/
               echo -n "     PROCESSING  "
               quick_progress &
               pid="$!"
               wget -qO - http://www.configserver.com/free/csf.tgz | tar -xz
               stop_progress "$pid"
               echo
               cd csf
               GREENTXT "NEXT, TEST IF YOU HAVE THE REQUIRED IPTABLES MODULES"
               echo
        if perl csftest.pl | grep "FATAL" ; then
               perl csftest.pl
               echo
               pause '---> Press [Enter] key to show menu'
           exit
           else
               perl csftest.pl
               echo
               pause '---> Press [Enter] key to continue'
               echo
               GREENTXT "Running CSF installation"
               echo
               echo -n "     PROCESSING  "
               quick_progress &
               pid="$!"
               sh install.sh
               stop_progress "$pid"
               echo
               GREENTXT "CSF FIREWALL HAS BEEN INSTALLED OK"
               echo
    fi
fi
echo
echo
pause '---> Press [Enter] key to show menu'
;;
###################################################################################
#                               WEBMIN HERE YOU GO                                #
###################################################################################
"webmin")
echo
echo -n "---> Start the Webmin Control Panel installation? [y/n][n]:"
read webmin_install
if [ "${webmin_install}" == "y" ];then
          echo
            GREENTXT "Installation of Webmin package:"
            echo
            echo -n "     PROCESSING  "
            start_progress &
            pid="$!"
            yum -y -q install ${WEBMIN} >/dev/null 2>&1
            stop_progress "$pid"
            rpm  --quiet -q webmin
      if [ "$?" = 0 ]
        then
          echo
            GREENTXT "WEBMIN HAS BEEN INSTALLED  -  OK"
            echo
            WEBMIN_PORT=$(shuf -i 17556-17728 -n 1)
            sed -i 's/theme=gray-theme/theme=authentic-theme/' /etc/webmin/config
            sed -i 's/preroot=gray-theme/preroot=authentic-theme/' /etc/webmin/miniserv.conf
            sed -i "s/port=10000/port=${WEBMIN_PORT}/" /etc/webmin/miniserv.conf
            sed -i "s/listen=10000/listen=${WEBMIN_PORT}/" /etc/webmin/miniserv.conf
            ## nginx module
            cd /usr/local/src/
            wget -q ${WEBMIN_NGINX} -O webmin_nginx
            perl /usr/libexec/webmin/install-module.pl $_ >/dev/null 2>&1
            perl /usr/libexec/webmin/install-module.pl /usr/local/csf/csfwebmin.tgz >/dev/null 2>&1
            sed -i 's/root/webadmin/' /etc/webmin/miniserv.users
            sed -i 's/root:/webadmin:/' /etc/webmin/webmin.acl
            WEBADMIN_PASS=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 15 | head -n 1)
            /usr/libexec/webmin/changepass.pl /etc/webmin/ webadmin ${WEBADMIN_PASS}
            service webmin restart  >/dev/null 2>&1
            YELLOWTXT "Access Webmin on port: ${WEBMIN_PORT}"
            YELLOWTXT "User: webadmin , Password: ${WEBADMIN_PASS}"
            REDTXT "Please enable Two-factor authentication"
               else
              echo
            REDTXT "WEBMIN INSTALLATION ERROR"
      fi
        else
          echo
            YELLOWTXT "Webmin installation was skipped by the user. Next step"
fi
echo
echo
pause '---> Press [Enter] key to show menu'
;;
"exit")
REDTXT "------> EXIT"
exit
;;
###################################################################################
#                               MENU DEFAULT CATCH ALL                            #
###################################################################################
*)
printf "\033c"
;;
esac
done
