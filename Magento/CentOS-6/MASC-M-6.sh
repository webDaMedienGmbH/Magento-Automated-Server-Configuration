#!/bin/bash
#====================================================================#
#  MagenX - Automated Server Configuration for Magento               #
#    Copyright (C) 2015 admin@magenx.com                             #
#       All rights reserved.                                         #
#====================================================================#
SELF=$(basename $0)
MASCM_VER="6.9.5"

# Software versions 
#MAGE_LATEST=$(wget -q -O- http://connect20.magentocommerce.com/community/Mage_All_Latest/releases.xml | tail -6 | grep -Po '(?<=<v>).*(?=</v>)')
MAGENTO_TMP_FILE="https://www.dropbox.com/s/v6libswo5zd68q2/magento-1.9.2.2-2015-10-27-03-19-32.tar.gz"
MAGENTO_VER="1.9.2.2"
PHPMYADMIN_VER="4.5.1"

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

# do we have CentOS 6?
if grep "CentOS.* 6\." /etc/redhat-release  > /dev/null 2>&1; then
  GREENTXT "PASS: CENTOS RELEASE 6"
  else
  echo
  REDTXT "ERROR: UNABLE TO DETERMINE DISTRIBUTION TYPE."
  YELLOWTXT "------> THIS CONFIGURATION FOR CENTOS 6"
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
SELINUX=$(sestatus | awk {'print $3'})
if [ "${SELINUX}" != "disabled" ]; then
  echo
  REDTXT "ERROR: SELINUX IS NOT DISABLED"
  YELLOWTXT "------> PLEASE CHECK YOUR SELINUX SETTINGS"
  echo
  exit 1
  else
  GREENTXT "PASS: SELINUX IS DISABLED"
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
    mkdir /root/mascm/ && echo "yes" > /root/mascm/.terms
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
        WHITETXT "-> Setup Magento database enter         :  ${YELLOW}\t\tdatabase"
        WHITETXT "-> Install Magento (no sample data)     :  ${YELLOW}\t\tinstall"
        echo
        BLUETXT ":::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
        echo
        WHITETXT "-> Change root user and ssh port        :  ${YELLOW}\t\tprotect"
        WHITETXT "-> Install CSF firewall                 :  ${YELLOW}\t\t\tfirewall"
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
if grep -q "yes" /root/mascm/.tmp >/dev/null 2>&1 ; then
echo
else
echo "-------------------------------------------------------------------------------------"
BLUEBG "| Re-create and symlink  /var/tmp and /tmp |"
echo "-------------------------------------------------------------------------------------"
echo
echo -n "---> Re-create and symlink /tmp and /var/tmp? [y/n][n]:" 
read secure_tmp
if [ "${secure_tmp}" == "y" ];then
        echo
	cd
	rm -rf /tmp
	mkdir /tmp
	mount -t tmpfs -o rw,noexec,nosuid tmpfs /tmp
	chmod 1777 /tmp
	echo "tmpfs  /tmp  tmpfs  rw,noexec,nosuid  0  0" >> /etc/fstab
	rm -rf /var/tmp
	ln -s /tmp /var/tmp
	echo
	GREENTXT "tmp directory is now symlinked"
	echo "yes" > /root/mascm/.tmp
fi
echo
WHITETXT "============================================================================="
echo
fi
echo
if grep -q "yes" /root/mascm/.sysupdate >/dev/null 2>&1 ; then
echo
else
echo "CHECKING UPDATES..."
UPDATES=$(yum check-update | grep updates | wc -l)
KERNEL=$(yum check-update | grep ^kernel | wc -l)
if [ "${UPDATES}" -gt 20 ] || [ "${KERNEL}" -gt 0 ]; then
echo
YELLOWTXT "---> NEW UPDATED PKGS: ${UPDATES}"
YELLOWTXT "---> NEW KERNEL PKGS: ${KERNEL}"
fi
echo
echo -n "---> Start the System Update now? [y/n][n]:"
read sys_update
if [ "${sys_update}" == "y" ]; then
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
	    echo
          else
         echo
       YELLOWTXT "The System Update was skipped by the user. Next step"
   fi
fi
echo
echo "-------------------------------------------------------------------------------------"
BLUEBG "| START THE INSTALLATION OF REPOSITORIES AND PACKAGES |"
echo "-------------------------------------------------------------------------------------"
echo
WHITETXT "============================================================================="
echo
echo -n "---> Start EPEL and Repoforge repository installation? [y/n][n]:"
read repo_epel_install
if [ "${repo_epel_install}" == "y" ];then
          echo
            GREENTXT "Installation of EPEL repository:"
            echo
            echo -n "     PROCESSING  "
            quick_progress &
            pid="$!"
            rpm --quiet -U http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm >/dev/null 2>&1
            stop_progress "$pid"
            rpm  --quiet -q epel-release
      if [ "$?" = 0 ]
        then
          echo
            GREENTXT "REPOSITORY HAS BEEN INSTALLED  -  OK"
             else
             echo
            REDTXT "REPOSITORY INSTALLATION ERROR"
          exit
      fi
            echo
            echo
            GREENTXT "Installation of additional packages:"
            echo
            echo -n "     PROCESSING  "
            long_progress &
            pid="$!"
            yum -q -y install svn bc gcc inotify-tools rsync mcrypt mlocate unzip vim wget curl sudo >/dev/null 2>&1
            stop_progress "$pid"
            echo
           rpm  --quiet -q wget
           if [ "$?" = 0 ]
        then
          echo
            GREENTXT "ALL PACKAGES WERE INSTALLED OK"
             else
             echo
            yum -q -y install wget >/dev/null 2>&1
        fi
            echo
        else
	      echo
            YELLOWTXT "EPEL repository installation was skipped by the user. Next step"
fi
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
            rpm --quiet -U http://www.percona.com/redir/downloads/percona-release/redhat/latest/percona-release-0.1-3.noarch.rpm >/dev/null 2>&1
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
              yum -y -q install Percona-Server-client-56 Percona-Server-server-56  >/dev/null 2>&1
              stop_progress "$pid"
              rpm  --quiet -q Percona-Server-client-56 Percona-Server-server-56
        if [ "$?" = 0 ] # if package installed then configure
          then
            echo
              GREENTXT "DATABSE HAS BEEN INSTALLED  -  OK"
              echo
              chkconfig mysql on
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
              wget -qO /etc/mysqltuner.pl https://raw.githubusercontent.com/major/MySQLTuner-perl/master/mysqltuner.pl
              echo
              WHITETXT "Please use these tools to check and finetune your database:"
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
baseurl=http://nginx.org/packages/mainline/centos/6/x86_64/
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
            chkconfig nginx on
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
            rpm -U http://rpms.remirepo.net/enterprise/remi-release-6.rpm >/dev/null 2>&1
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
            yum --enablerepo=remi,remi-php55 -y -q install php php-cli php-common php-fpm php-gd php-curl \
            php-mbstring php-bcmath php-soap php-mcrypt php-mysql php-pdo php-xml php-pecl-memcache php-pecl-redis php-opcache php-pecl-geoip >/dev/null 2>&1
            stop_progress "$pid"
            rpm  --quiet -q php
       if [ "$?" = 0 ]
         then
           echo
             GREENTXT "PHP HAS BEEN INSTALLED  -  OK"
             chkconfig php-fpm on
             chkconfig httpd off
             yum list installed | awk '/php.*x86_64/ {print "      ",$1}'
                else
               echo
             REDTXT "PHP INSTALLATION ERROR"
         exit
       fi
         echo
           echo
            GREENTXT "Installation of Memcached and Redis packages:"
            echo
            echo -n "     PROCESSING  "
            start_progress &
            pid="$!"
            yum --enablerepo=remi -y -q install memcached redis >/dev/null 2>&1
            stop_progress "$pid"
            rpm  --quiet -q memcached
       if [ "$?" = 0 ]
         then
           echo
             GREENTXT "MEMCACHED AND REDIS WERE INSTALLED"
             chkconfig memcached on
             chkconfig redis on
                else
               echo
             REDTXT "MEMCACHED AND REDIS INSTALLATION ERROR"
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
echo -n "---> Start Varnish repository and Varnish 3.x installation? [y/n][n]:"
read varnish_install
if [ "${varnish_install}" == "y" ];then
          echo
            GREENTXT "Installation of Varnish repository:"
            echo
            echo -n "     PROCESSING  "
            quick_progress &
            pid="$!"
            rpm --quiet --nosignature -U https://repo.varnish-cache.org/redhat/varnish-3.0.el6.rpm
            stop_progress "$pid"
            rpm  --quiet -q varnish-release
      if [ "$?" = 0 ]
        then
          echo
            GREENTXT "REPOSITORY HAS BEEN INSTALLED  -  OK"
            echo
            GREENTXT "Installation of VARNISH package:"
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
        exit
      fi
        else
            REDTXT "REPOSITORY INSTALLATION ERROR"
        exit
      fi
        else
          echo
            YELLOWTXT "Varnish repository installation was skipped by the user. Next step"
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
echo -n "---> Load optimized configs of php, opcache, fpm, fastcgi, memcached, sysctl, varnish? [y/n][n]:"
read load_configs
if [ "${load_configs}" == "y" ];then
echo
WHITETXT "YOU HAVE TO CHECK THEM AFTER ANYWAY"
cat > /etc/sysctl.conf <<END
fs.file-max = 1000000
fs.inotify.max_user_watches = 700000
vm.swappiness = 10
net.ipv4.ip_forward = 0
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.default.accept_source_route = 0
kernel.sysrq = 0
kernel.core_uses_pid = 1
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 8388608 8388608 8388608
net.ipv4.tcp_rmem = 4096 87380 8388608
net.ipv4.tcp_wmem = 4096 65536 8388608
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
WHITETXT "sysctl.conf loaded ... \033[01;32m  ok"
cat > /etc/php.d/opcache.ini <<END
; Enable Zend OPcache extension
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

WHITETXT "opcache.ini loaded ... \033[01;32m  ok"
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

WHITETXT "php.ini loaded ... \033[01;32m  ok"
cat > /etc/sysconfig/memcached <<END
PORT="11211"
USER="memcached"
MAXCONN="5024"
CACHESIZE="128"
OPTIONS="-l 127.0.0.1"
END
WHITETXT "memcached config loaded ... \033[01;32m  ok"
echo -e '\nfastcgi_read_timeout 7200;\nfastcgi_send_timeout 7200;\nfastcgi_connect_timeout 65;\n' >> /etc/nginx/fastcgi_params
WHITETXT "fastcgi_params loaded ... \033[01;32m  ok"
echo
echo "*         soft    nofile          500000" >> /etc/security/limits.conf
echo "*         hard    nofile          700000" >> /etc/security/limits.conf
  else
        YELLOWTXT "Configuration was skipped by the user. Next step"
fi
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
FPM=$(find /etc/php-fpm.d/ -name 'www.conf')
FPM_USER=$(grep "user" $FPM | grep "=" | awk '{print $3}')
echo -n "---> Download latest Magento version (${MAGENTO_VER}) ? [y/n][n]:"
read new_down
if [ "${new_down}" == "y" ];then
     read -e -p "---> Enter folder full path: " -i "/var/www/html/myshop.com" MY_SHOP_PATH
        echo "  Magento will be downloaded to:"
        GREENTXT ${MY_SHOP_PATH}
        mkdir -p ${MY_SHOP_PATH} && cd $_
        echo -n "      DOWNLOADING MAGENTO  "
        long_progress &
        pid="$!"
        wget -qO- ${MAGENTO_TMP_FILE} | tar -xzp
        stop_progress "$pid"
        echo
        else
        echo "      You are going to move your own files then"
        read -e -p "---> Edit your installation folder full path: " -i "/var/www/html/myshop.com" MY_SHOP_PATH
        GREENTXT ${MY_SHOP_PATH}
        if [ ! -d "${MY_SHOP_PATH}" ]; then
        mkdir -p ${MY_SHOP_PATH}
        fi
        echo "      Move your magento files to this folder now"
        pause '------> Press [Enter] key to continue'
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

wget -qO /etc/nginx/port.conf https://raw.githubusercontent.com/magenx/nginx-config/master/magento/port.conf
wget -qO /etc/nginx/fastcgi_params https://raw.githubusercontent.com/magenx/nginx-config/master/magento/fastcgi_params
wget -qO /etc/nginx/nginx.conf https://raw.githubusercontent.com/magenx/nginx-config/master/magento/nginx.conf

mkdir -p /etc/nginx/www && cd $_
wget -q https://raw.githubusercontent.com/magenx/nginx-config/master/magento/www/default.conf
wget -q https://raw.githubusercontent.com/magenx/nginx-config/master/magento/www/magento.conf
sed -i "s/example.com/${MY_DOMAIN}/g" /etc/nginx/www/magento.conf
sed -i "s,root /var/www/html,root ${MY_SHOP_PATH},g" /etc/nginx/www/magento.conf

cd /etc/nginx/conf.d/ && rm -rf *
wget -q https://raw.githubusercontent.com/magenx/nginx-config/master/magento/conf.d/export.conf
wget -q https://raw.githubusercontent.com/magenx/nginx-config/master/magento/conf.d/error_page.conf
wget -q https://raw.githubusercontent.com/magenx/nginx-config/master/magento/conf.d/extra_protect.conf
wget -q https://raw.githubusercontent.com/magenx/nginx-config/master/magento/conf.d/hhvm.conf
wget -q https://raw.githubusercontent.com/magenx/nginx-config/master/magento/conf.d/headers.conf
wget -q https://raw.githubusercontent.com/magenx/nginx-config/master/magento/conf.d/maintenance.conf
wget -q https://raw.githubusercontent.com/magenx/nginx-config/master/magento/conf.d/multishop.conf
wget -q https://raw.githubusercontent.com/magenx/nginx-config/master/magento/conf.d/spider.conf
echo
echo
mkdir -p /root/mascm/
cat >> /root/mascm/.mascm_index <<END
webshop ${MY_DOMAIN}      ${MY_SHOP_PATH}   ${FPM_USER}
END
echo
###################################################################################
#                   LOADING ALL THE EXTRA TOOLS FROM HERE                         #
###################################################################################
echo
GREENTXT "INSTALLING phpMyAdmin - advanced MySQL interface"
pause '------> Press [Enter] key to continue'
echo
     cd ${MY_SHOP_PATH}
     MYSQL_FILE=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 7 | head -n 1)
     BLOWFISHCODE=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
     mkdir -p ${MYSQL_FILE} && cd $_
     wget -qO - https://files.phpmyadmin.net/phpMyAdmin/${PHPMYADMIN_VER}/phpMyAdmin-${PHPMYADMIN_VER}-all-languages.tar.gz | tar -xzp --strip 1
     mv config.sample.inc.php config.inc.php
     sed -i 's/a8b7c6d/${BLOWFISHCODE}/' ./config.inc.php
     echo
     GREENTXT "phpMyAdmin was installed to http://${MY_DOMAIN}/${MYSQL_FILE}"
echo
echo
echo
GREENTXT "INSTALLING OPCACHE GUI"
pause '------> Press [Enter] key to continue'
echo
    cd ${MY_SHOP_PATH}
    OPCACHE_FILE=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z' | fold -w 7 | head -n 1)
    wget -qO ${OPCACHE_FILE}_opcache_gui.php https://raw.githubusercontent.com/amnuts/opcache-gui/master/index.php
    echo
    GREENTXT "OPCACHE interface was installed to http://www.${MY_DOMAIN}/opcache_${OPCACHE_FILE}_gui.php"
echo
echo
echo
GREENTXT "INSTALLING Magento /app/ folder monitor and opcache invalidation script"
pause '------> Press [Enter] key to continue'
cat > /root/zend_opcache_monitor.sh <<END
#!/bin/bash
## monitor app folder and log modified files
/usr/bin/inotifywait -e modify,move \
    -mrq --timefmt %a-%b-%d-%T --format '%w%f %T' \
    --excludei '/(cache|log|session|report|locks|media|skin|tmp)/|\.(xml|html?|css|js|gif|jpe?g|png|ico|te?mp|txt|csv|swp|sql|t?gz|zip|svn?g|git|log|ini)~?' \
    ${MY_SHOP_PATH}/ | while read line; do
    echo "\$line " >> /var/log/zend_opcache_monitor.log
    FILE=\$(echo \${line} | cut -d' ' -f1 | sed -e 's/\/\./\//g' | cut -f1-2 -d'.')
    TARGETEXT="(php|phtml)"
    EXTENSION="\${FILE##*.}"
  if [[ "\$EXTENSION" =~ \$TARGETEXT ]];
    then
    curl --silent "http://${MY_DOMAIN}/opcache_${OPCACHE_FILE}_gui.php?page=invalidate&file=\${FILE}" >/dev/null 2>&1
  fi
done
END
echo
    GREENTXT "Script was installed to /root/zend_opcache_monitor.sh"
echo
echo
    echo "/root/zend_opcache_monitor.sh &" >> /etc/rc.local
echo
echo
GREENTXT "VARNISH DAEMON CONFIGURATION FILE"
echo -e '\nDAEMON_OPTS="-a :80 \
             -T localhost:6082 \
             -f '${MY_SHOP_PATH}'/var/default.vcl \
             -u varnish -g varnish \
             -p thread_pool_min=200 \
             -p thread_pool_max=4000 \
             -p thread_pool_add_delay=2 \
             -p cli_timeout=25 \
             -p cli_buffer=26384 \
             -p esi_syntax=0x2 \
             -p session_linger=100 \
             -S /etc/varnish/secret \
             -s malloc,2G"' >> /etc/sysconfig/varnish
echo
echo 'Varnish secret key -->'$(cat /etc/varnish/secret)'<-- copy it'
echo
WHITETXT "Varnish settings were loaded \033[01;32m  ok"
echo
pause '------> Press [Enter] key to reset permissions and create a cronjob'
echo
WHITETXT "RESETTING FILE PERMISSIONS ..."
         find . -type f -exec chmod 664 {} \;
         find . -type d -exec chmod 775 {} \;
         chmod 777 -R var media
         chown -R ${FPM_USER}:${FPM_USER} ${MY_SHOP_PATH}
    echo
        echo
        GREENTXT "Now we need to add cron.sh to crontab"
        chmod +x ${MY_SHOP_PATH}/cron.sh
        crontab -l > magecron
        echo "* * * * * /bin/bash ${MY_SHOP_PATH}/cron.sh" >> magecron
        crontab magecron
        rm magecron
        crontab -l
echo
echo
service php-fpm start
service nginx start
service memcached start
service redis start
echo
echo
echo "-------------------------------------------------------------------------------------"
BLUEBG " CONFIGURATION IS COMPLETE "
echo "-------------------------------------------------------------------------------------"
echo
pause '---> Press [Enter] key to show menu'
printf "\033c"
;;
###################################################################################
#                                MAGENTO DATABASE SETUP                           #
###################################################################################
"database")
printf "\033c"
WHITETXT "============================================================================="
service mysql restart
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
echo
mkdir -p /root/mascm/
cat >> /root/mascm/.mascm_index <<END
database        ${MAGE_DB_HOST}   ${MAGE_DB_NAME}   ${MAGE_DB_USER_NAME}     ${MAGE_DB_PASS}
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
MAGE_ADMIN_PATH=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z' | fold -w 10 | head -n 1)
MY_SHOP_PATH=$(awk '/webshop/ { print $3 }' /root/mascm/.mascm_index)
cd ${MY_SHOP_PATH}
chmod +x mage
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
    echo
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
echo "---> CHANGING YOUR local.xml FILE WITH MEMCACHE SESSIONS AND REDIS CACHE BACKENDS"
echo
sed -i '/<session_save>/d' ${MY_SHOP_PATH}/app/etc/local.xml
sed -i '/<global>/ a\
<session_save><![CDATA[memcache]]></session_save> \
<session_save_path><![CDATA[tcp://127.0.0.1:11211?persistent=1&weight=2&timeout=10&retry_interval=10]]></session_save_path> \
        <cache> \
        <backend>Cm_Cache_Backend_Redis</backend> \
        <backend_options> \
          <default_priority>10</default_priority> \
          <auto_refresh_fast_cache>1</auto_refresh_fast_cache> \
            <server>127.0.0.1</server> \
            <port>6379</port> \
            <persistent><![CDATA[db1]]></persistent> \
            <database>1</database> \
            <password></password> \
            <force_standalone>0</force_standalone> \
            <connect_retries>1</connect_retries> \
            <read_timeout>10</read_timeout> \
            <automatic_cleaning_factor>0</automatic_cleaning_factor> \
            <compress_data>1</compress_data> \
            <compress_tags>1</compress_tags> \
            <compress_threshold>204800</compress_threshold> \
            <compression_lib>gzip</compression_lib> \
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
chmod +x /root/zend_opcache_monitor.sh
/root/zend_opcache_monitor.sh &
echo
echo
echo "---> CREATE SAMPLE LOGROTATE SCRIPT FOR MAGENTO LOGS"
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
echo
    GREENTXT "NOW LOGIN TO YOUR BACKEND AND CHECK EVERYTHING"
    echo
  echo
echo
pause '---> Press [Enter] key to show menu'
;;
###################################################################################
#                               SECURE YOUR SERVER                                #
###################################################################################
"protect")
WHITETXT "============================================================================="
echo
WHITETXT "NOW WE PROTECT YOUR SERVER"
echo
GREENTXT "Replacing the root user with a new user"
echo
echo -n "---> Generate a password for the new user? [y/n][n]:"
read new_rupass_gen
if [ "${new_rupass_gen}" == "y" ];then
   echo
      NEW_ROOT_PASSGEN=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9~!@#$%^&' | fold -w 15 | head -n 1)
      WHITETXT "Password: ${RED} ${NEW_ROOT_PASSGEN}"
      GREENTXT "!REMEMBER IT AND KEEP IT SAFE!"
   echo
fi
echo
echo -n "---> Create your new user? [y/n][n]:"
read new_root_user
if [ "${new_root_user}" == "y" ];then
     echo
        read -p "---> Enter the new user name: " NEW_ROOT_NAME
        echo "${NEW_ROOT_NAME}	ALL=(ALL)	ALL" >> /etc/sudoers
        SHOP_PATH=$(awk '/webshop/ { print $3 }' /root/mascm/.mascm_index)
        FPM_USER=$(awk '/webshop/ { print $4 }' /root/mascm/.mascm_index)
        useradd -G ${FPM_USER} -d ${SHOP_PATH} -s /bin/bash ${NEW_ROOT_NAME}
        passwd ${NEW_ROOT_NAME}
     echo
fi
echo
echo -n "---> Change ssh settings snow? [y/n][n]:"
read new_ssh_set
if [ "${new_ssh_set}" == "y" ];then
   echo
      cp /etc/ssh/sshd_config /etc/ssh/sshd_config.BACK
      read -p "---> Enter a new ssh port(9500-65000) : " NEW_SSH_PORT
      sed -i "s/#Port 22/Port ${NEW_SSH_PORT}/g" /etc/ssh/sshd_config
      sed -i 's/.*PermitRootLogin.*/PermitRootLogin no/g' /etc/ssh/sshd_config
     echo
        GREENTXT "SSH PORT HAS BEEN UPDATED  -  OK"
        GREENTXT "ROOT LOGIN  -  DISABLED"
        service sshd restart
        netstat -tulnp | grep sshd
     echo
fi
echo
echo
REDTXT "!IMPORTANT: OPEN NEW SSH SESSION AND TEST YOUR ACCOUNT!"
echo
echo -n "---> Have you logged in? [y/n][n]:"
read new_ssh_test
if [ "${new_ssh_test}" == "y" ];then
      echo
        GREENTXT "REMEMBER YOUR PORT: ${NEW_SSH_PORT}, LOGIN: ${NEW_ROOT_NAME} AND PASSWORD ${NEW_ROOT_PASSGEN}"
        else
        mv /etc/ssh/sshd_config.BACK /etc/ssh/sshd_config
        REDTXT "Writing your sshd_config back ... \033[01;32m ok"
        service sshd restart
        echo
        GREENTXT "SSH PORT HAS BEEN UPDATED  -  OK"
        GREENTXT "ROOT LOGIN  -  ENABLED"
        netstat -tulnp | grep sshd
fi
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
               cd
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
               GREENTXT "Installing perl modules:"
               echo
               echo -n "     PROCESSING  "
               start_progress &
               pid="$!"
               yum -q -y install perl-libwww-perl perl-Time-HiRes >/dev/null 2>&1
               stop_progress "$pid"
               rpm  --quiet -q perl-libwww-perl perl-Time-HiRes
           if [ "$?" = 0 ]
             then
                 GREENTXT "PERL MODULES WERE INSTALLED  -  OK"
                 else
                 REDTXT "ERROR"
             exit
           fi
             echo
               GREENTXT "Running CSF installation"
               echo
               echo -n "     PROCESSING  "
               quick_progress &
               pid="$!"
               sh install.sh >/dev/null 2>&1
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
