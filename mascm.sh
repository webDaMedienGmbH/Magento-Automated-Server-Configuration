#!/bin/bash
#KEY_OWNER=4f09fdcf5c89e32c6f712ecf90632615
#====================================================================#
#  MagenX - Automated Server Configuration for Magento               #
#    Copyright (C) 2014 admin@magenx.com                             #
#       All rights reserved.                                         #
#====================================================================#
SELF=$(basename $0)
MASCM_VER="5.3.1.9"

# The base md5sum location to cotrol license
#MASCM_BASE=http://www.magenx.com/mascm

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
#  KEY_OUT=$(curl $MASCM_BASE/ver 2>&1 | grep $KEY_OWNER | awk '{print $2}')
#  KEY_IN=$(echo $HOSTNAME | md5sum | awk '{print $1}')
#  if [[ "$KEY_OUT" == "$KEY_IN" ]]; then
#    GREENTXT "PASS: INTEGRITY CHECK FOR '$SELF' ON '$HOSTNAME' OK"
# elif [[ "$KEY_OUT" != "$KEY_IN" ]]; then
#    REDTXT "ERROR: INTEGRITY CHECK FAILED! MD5 MISMATCH!"
#    REDTXT "YOU CAN NOT RUN THIS SCRIPT WITHOUT A LICENCE KEY"
#    echo "Local md5:  $KEY_IN"
#    echo "Remote md5: $KEY_OUT"
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
if grep "CentOS Linux release 7" /etc/redhat-release  > /dev/null 2>&1; then
  GREENTXT "PASS: CENTOS RELEASE 7"
  else
  echo
  REDTXT "ERROR: UNABLE TO DETERMINE DISTRIBUTION TYPE."
  YELLOWTXT "------> THIS CONFIGURATION FOR CENTOS 7."
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
  GREENTXT "PASS: YOU HAVE $TOTALMEM kB OF RAM"
  else
  echo
  REDTXT "WARNING: YOU HAVE LESS THAN 3GB OF RAM"
  YELLOWTXT "this is not good for import/export and full reindex"
fi

# some selinux, sir?
SELINUX=$(awk '/^SELINUX=/'  /etc/selinux/config)
if [ "${SELINUX}" != "SELINUX=disabled" ]; then
  echo
  REDTXT "ERROR: SELINUX IS ENABLED"
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
  if [ "$terms_agree" == "y" ];then
    echo "yes" > /root/mascm/.terms
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
        echo -e "${DGREYBG}${BOLD}  Magento Server Configuration v.${MASCM_VER}  ${RESET}"
        BLUETXT ":::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
        echo
        WHITETXT "-> Install repository and LEMP packages :  ${YELLOW}\tlemp"
        WHITETXT "-> Download latest Magento package      :  ${YELLOW}\t\tmagento"
        WHITETXT "-> Setup Magento database enter         :  ${YELLOW}\t\tdatabase"
        WHITETXT "-> Install Magento (no sample data)     :  ${YELLOW}\t\tinstall"
        echo
        BLUETXT ":::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
        echo
        WHITETXT "-> Configure ProFTPd server             :  ${YELLOW}\t\t\tproftpd"
        WHITETXT "-> Configure system backup              :  ${YELLOW}\t\t\tbackup"
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
			echo "tmpfs		/tmp	tmpfs	rw,noexec,nosuid	0	0" >> /etc/fstab
			rm -rf /var/tmp
			ln -s /tmp /var/tmp
			echo
		    GREENTXT "tmp directory is now symlinked"
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
if [ "$repo_epel_install" == "y" ];then
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
            GREENTXT "Installation of Repoforge repository:"
            echo
            echo -n "     PROCESSING  "
            quick_progress &
            pid="$!"
            rpm --quiet -U http://pkgs.repoforge.org/rpmforge-release/rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm >/dev/null 2>&1
            stop_progress "$pid"
            rpm  --quiet -q rpmforge-release
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
            GREENTXT "Installation of additional packages:"
            echo
            echo -n "     PROCESSING  "
            long_progress &
            pid="$!"
            yum -q -y install wget curl bc mcrypt sudo crontabs gcc vim mlocate unzip proftpd inotify-tools >/dev/null 2>&1
            stop_progress "$pid"
            echo
            GREENTXT "ALL PACKAGES WERE INSTALLED  -  OK"
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
if [ "$repo_percona_install" == "y" ];then
          echo
            GREENTXT "Installation of Percona repository:"
            echo
            echo -n "     PROCESSING  "
            quick_progress &
            pid="$!"
            rpm --quiet -U http://www.percona.com/downloads/percona-release/percona-release-0.0-1.x86_64.rpm >/dev/null 2>&1
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
if [ "$repo_nginx_install" == "y" ];then
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
            chkconfig httpd off
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
if [ "$repo_remi_install" == "y" ];then
          echo
            GREENTXT "Installation of Remi repository:"
            echo
            echo -n "     PROCESSING  "
            quick_progress &
            pid="$!"
            rpm -Uvh http://rpms.famillecollet.com/enterprise/6/remi/x86_64/remi-release-6.5-1.el6.remi.noarch.rpm >/dev/null 2>&1
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
if [ "$varnish_install" == "y" ];then
          echo
            GREENTXT "Installation of Varnish repository:"
            echo
            echo -n "     PROCESSING  "
            quick_progress &
            pid="$!"
            rpm --quiet --nosignature -U https://repo.varnish-cache.org/redhat/varnish-3.0.el6.rpm
            stop_progress "$pid"
            rpm  --quiet -q varnish
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
WHITETXT "============================================================================="
echo
echo -n "---> Start Fail2Ban installation? [y/n][n]:"
read f2b_install
if [ "$f2b_install" == "y" ];then
          echo
            GREENTXT "Installation of Fail2Ban package:"
            echo
            echo -n "     PROCESSING  "
            start_progress &
            pid="$!"
            yum -y -q install fail2ban  >/dev/null 2>&1
            stop_progress "$pid"
            rpm  --quiet -q fail2ban
      if [ "$?" = 0 ]
        then
          echo
            GREENTXT "FAIL2BAN HAS BEEN INSTALLED  -  OK"
                        echo
            GREENTXT "Writing nginx 403 filter"
cat > /etc/fail2ban/filter.d/nginx-403.conf <<END
[Definition]
failregex = directory index of .* is forbidden, client: <HOST>
            ^<HOST> .*"GET \/w00tw00t\.at\.ISC\.SANS\.DFind\:\).*".*
            ^<HOST> .*"GET .*phppath/php.*" 444 .*
            ^<HOST> .*"POST .*444 .*
            ^<HOST> .*"GET .*444 .*
            ^<HOST> .*"GET .*wp-login.php.*404.*
END
          echo
            GREENTXT "Writing nginx 403 action"
cat > /etc/fail2ban/action.d/nginx-403.conf <<END
[Definition]
actionban = IP=<ip> && echo "deny $IP;" >> /etc/nginx/banlist/403.conf && service nginx reload
actionunban = IP=<ip> && sed -i "/$IP/d" /etc/nginx/banlist/403.conf && service nginx reload
END
          echo
            GREENTXT "Writing nginx 403 jail"
cat >> /etc/fail2ban/jail.conf <<END
[nginx-403]
enabled = true
port = http,https
filter = nginx-403
action = nginx-403
logpath = /var/log/nginx/error.log
END
          echo
            GREENTXT "Creating banlist directory"
            mkdir -p /etc/nginx/banlist/
            touch /etc/nginx/banlist/403.conf
            echo
            GREENTXT "Please whitelist your ip addresses in /etc/fail2ban/jail.conf"
            chkconfig fail2ban on
            else
            REDTXT "FAIL2BAN INSTALLATION ERROR"
        exit
      fi
        else
          echo
            YELLOWTXT "Fail2Ban installation was skipped by the user. Next step"
fi
echo
WHITETXT "============================================================================="
echo
echo -n "---> Start the System Update? [y/n][n]:"
read sys_update
if [ "$sys_update" == "y" ];then
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
          else
         echo
       YELLOWTXT "The System Update was skipped by the user. Next step"
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
if [ "$load_configs" == "y" ];then
echo
WHITETXT "YOU HAVE TO CHECK THEM AFTER ANYWAY"
   cat > /etc/sysctl.conf <<END
fs.file-max = 360000
fs.inotify.max_user_watches=200000

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
net.core.somaxconn = 262144
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
opcache.max_accelerated_files = 10000
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
opcache.blacklist_filename=/etc/php.d/opcache*.blacklist
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
sed -i 's/;realpath_cache_ttl = 120/realpath_cache_ttl = 84600/' /etc/php.ini
sed -i 's/short_open_tag = Off/short_open_tag = On/' /etc/php.ini
sed -i 's/; max_input_vars = 1000/max_input_vars = 50000/' /etc/php.ini
sed -i 's/mysql.allow_persistent = On/mysql.allow_persistent = Off/' /etc/php.ini
sed -i 's/mysqli.allow_persistent = On/mysqli.allow_persistent = Off/' /etc/php.ini
sed -i 's/;date.timezone =/date.timezone = UTC/' /etc/php.ini
sed -i 's/pm = dynamic/pm = ondemand/' /etc/php-fpm.d/www.conf
sed -i 's/;pm.max_requests = 500/pm.max_requests = 10000/' /etc/php-fpm.d/www.conf
sed -i 's/pm.max_children = 50/pm.max_children = 500/' /etc/php-fpm.d/www.conf

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
echo "*         soft    nofile          60000" >> /etc/security/limits.conf
echo "*         hard    nofile          100000" >> /etc/security/limits.conf
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
echo -n "---> Download latest Magento version (1.9.0.1) ? [y/n][n]:"
read new_down
if [ "$new_down" == "y" ];then
     read -e -p "---> Edit your installation folder full path: " -i "/var/www/html/myshop.com" MY_SHOP_PATH
        echo "  Magento will be downloaded to:"
        GREENTXT ${MY_SHOP_PATH}
                pause '------> Press [Enter] key to continue'
        mkdir -p ${MY_SHOP_PATH} && cd $_
                echo -n "      DOWNLOADING MAGENTO  "
                        long_progress &
                        pid="$!"
                        wget -qO - http://www.magentocommerce.com/downloads/assets/1.9.0.1/magento-1.9.0.1.tar.gz | tar -xzp --strip 1
                        stop_progress "$pid"
                echo
                echo
WHITETXT "============================================================================="
GREENTXT "      == MAGENTO DOWNLOADED AND READY FOR INSTALLATION =="
WHITETXT "============================================================================="
echo
echo
echo "---> CREATING NGINX CONFIG FILE NOW"
echo
read -e -p "---> Enter your domain name (without www): " -i "myshop.com" MY_DOMAIN
MY_CPU=$(grep -c processor /proc/cpuinfo)
GREENTXT "NGINX CONFIG SET UP WITH:"
WHITETXT " DOMAIN: $MY_DOMAIN"
WHITETXT " ROOT: $MY_SHOP_PATH"
WHITETXT " CPU: $MY_CPU"
if [ -f /etc/fail2ban/jail.conf ]
then
FAIL2BAN='include /etc/nginx/banlist/403.conf;'
fi
cat > /etc/nginx/nginx.conf <<END
user  $FPM_USER;
worker_processes  $MY_CPU;
worker_rlimit_nofile 100000;

error_log   /var/log/nginx/error.log;
#error_log  /var/log/nginx/error.log  notice;
#error_log  /var/log/nginx/error.log  info;

pid        /var/run/nginx.pid;

events {
    worker_connections  1024;
    multi_accept on;
    use epoll;
       }

http   {
    index index.html index.php; ## Allow a static html file to be shown first
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

#    geoip_country  /usr/share/GeoIP/GeoIP.dat; ## the country IP database
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" \$status \$body_bytes_sent "\$http_referer" "\$http_user_agent"';

    #log_format error403  '\$remote_addr - \$remote_user [\$time_local] '
    #                 '\$status "\$request"  "\$http_x_forwarded_for"';

    server_tokens       off;
    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;

        $FAIL2BAN

    ## Gzipping is an easy way to reduce page weight
    gzip                on;
    gzip_vary           on;
    gzip_proxied        any;
    gzip_types          text/css application/x-javascript;
    gzip_buffers        16 8k;
    gzip_comp_level     6;
    gzip_min_length     800;

    open_file_cache max=10000 inactive=8h;
    open_file_cache_valid 1h;
    open_file_cache_min_uses 2;
    open_file_cache_errors off;

    #ssl_session_cache         shared:SSL:15m;
    #ssl_session_timeout       15m;
        #ssl_protocols             SSLv3 TLSv1 TLSv1.1 TLSv1.2;
    #ssl_ciphers               "EECDH+ECDSA+AESGCM EECDH+aRSA+AESGCM EECDH+ECDSA+SHA384 EECDH+ECDSA+SHA256 EECDH+aRSA+SHA384 EECDH+aRSA+SHA256 EECDH+aRSA+RC4 EECDH EDH+aRSA RC4 !aNULL !eNULL !LOW !3DES !MD5 !EXP !PSK !SRP !DSS !RC4";
    #ssl_prefer_server_ciphers on;

    keepalive_timeout   10;

        ## Set real ip address/network
        #set_real_ip_from 127.0.0.1;
        #real_ip_header X-Forwarded-For;

        ## Multi domain configuration
        #map \$http_host \$storecode {
           #www.domain1.com 1store_code;
           #www.domain2.net 2store_code;
           #www.domain3.de 3store_code;
           #www.domain4.com 4store_code;
           #}

server {
    listen 80;
    return 444;
}

#server {
#     listen 443;
#     ssl_certificate     /etc/ssl/certs/server.crt;
#     ssl_certificate_key /etc/ssl/certs/server.key;
#     return 444;
#}

#server {
#    listen 80;
#    server_name $MY_DOMAIN;
#    return 301 \$scheme://www.${MY_DOMAIN}\$request_uri;
#}

server {
    listen 80;
    #listen 443 spdy ssl;
    server_name www.${MY_DOMAIN};
    root $MY_SHOP_PATH;

    access_log  /var/log/nginx/access_${MY_DOMAIN}.log  main;

    ## Nginx will not add the port in the url when the request is redirected.
    #port_in_redirect off;

    ####################################################################################
    ## SSL CONFIGURATION

       #ssl_certificate     /etc/ssl/certs/server.crt;
       #ssl_certificate_key /etc/ssl/certs/server.key;

    ####################################################################################

    ## Server maintenance block. insert dev ip 1.2.3.4 static address www.whatismyip.com
    #if (\$remote_addr !~ "^(1.2.3.4|1.2.3.4)$") {
        #return 503;
        #}

    #error_page 503 @maintenance;
    #location @maintenance {
        #rewrite ^(.*)$ /error_page/503.html break;
        #internal;
        #access_log off;
        #log_not_found off;
        #}

    ####################################################################################

    ## 403 error log/page
    #error_page 403 /403.html;
    #location = /403.html {
        #root /var/www/html/error_page;
        #internal;
        #access_log   /var/log/nginx/403.log  error403;
        #}

    ####################################################################################

    ## Main Magento location
    location / {
        try_files \$uri \$uri/ @handler;
                expires max;
        }

    ####################################################################################

    ## These locations would be hidden by .htaccess normally, protected
    location ~ (/(app/|includes/|/pkginfo/|var/|errors/local.xml)|/\.) {
        deny all;
        #internal;
        }

    ####################################################################################

    ## Protecting /admin/ and /downloader/  1.2.3.4 = static ip (www.whatismyip.com)
    #location /downloader/  {
        #allow 1.2.3.4;
        #allow 1.2.3.4;
        #deny all;
        #rewrite ^/downloader/(.*)$ /downloader/index.php$1;
        #}
    #location /admin  {
        #allow 1.2.3.4;
        #allow 1.2.3.4;
        #deny all;
        #rewrite / /@handler;
        #}

    ####################################################################################

    ## Main Magento location
    location @handler {
        rewrite / /index.php?\$args;
        }

    location ~ \.php/ {
        rewrite ^(.*\.php)/  \$1 last;
        }

    ####################################################################################

    ## Execute PHP scripts
    location ~ \.php$ {
        add_header X-Config-By 'MagenX -= www.magenx.com =-';
                add_header X-UA-Compatible 'IE=Edge,chrome=1';
        add_header X-Time \$request_time;
        try_files \$uri \$uri/ =404;
        #try_files \$uri \$uri/ @handler;
        fastcgi_pass   127.0.0.1:9000;
        fastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;
        ## Store code with multi domain
        #fastcgi_param  MAGE_RUN_CODE \$storecode;
        ## Default Store code
        fastcgi_param  MAGE_RUN_CODE default;
        fastcgi_param  MAGE_RUN_TYPE store; ## or website;
        include        fastcgi_params; ## See /etc/nginx/fastcgi_params
        }
    }
}
END
echo
echo
mkdir -p /root/mascm/
cat >> /root/mascm/.mascm_index <<END
webshop $MY_DOMAIN      $MY_SHOP_PATH   $FPM_USER
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
                MYSQL_FILE=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z' | fold -w 7 | head -n 1)
                mkdir -p ${MYSQL_FILE} && cd $_
                wget -qO - http://sourceforge.net/projects/phpmyadmin/files/phpMyAdmin/4.2.5/phpMyAdmin-4.2.5-all-languages.tar.gz | tar -xzp --strip 1
                echo
        GREENTXT "phpMyAdmin was installed to http://${MY_DOMAIN}/${MYSQL_FILE}"
echo
echo
echo
GREENTXT "INSTALLING OPCACHE GUinterface"
pause '------> Press [Enter] key to continue'
echo
                cd ${MY_SHOP_PATH}
                OPCACHE_FILE=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z' | fold -w 7 | head -n 1)
                wget -qO ${OPCACHE_FILE}_opcache_gui.php https://raw.githubusercontent.com/amnuts/opcache-gui/master/index.php
                echo
        GREENTXT "OPCACHE interface was installed to http://www.${MY_DOMAIN}/${OPCACHE_FILE}_opcache_gui.php"
echo
echo
echo
GREENTXT "INSTALLING Magento /app/ folder monitor and opcache invalidation script"
pause '------> Press [Enter] key to continue'
cat > /root/app_monitor.sh <<END
#!/bin/bash
## monitor app folder and log modified files
/usr/bin/inotifywait -e modify \
    -mrq --timefmt %a-%b-%d-%T --format '%w%f %T' ${MY_SHOP_PATH}/app | while read line; do
    echo "\$line " >> /var/log/app_monitor.log
    FILE=$(echo $line | cut -d' ' -f1 | sed 's/\/\./\//g')
    TARGETEXT="(php|phtml)"
    EXTENSION="${FILE##*.}"
  if [[ "\$EXTENSION" =~ \$TARGETEXT ]];
    then
    curl --silent "http://${MY_DOMAIN}/${OPCACHE_FILE}_opcache_gui.php?page=invalidate&file=\${FILE}" >/dev/null 2>&1
  fi
done
END
echo
        GREENTXT "Script was installed to /root/app_monitor.sh"
echo
echo
        echo "/root/app_monitor.sh &" >> /etc/rc.local
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

VSECRET=$(cat /etc/varnish/secret)
echo 'Varnish secret key -->  '${VSECRET}'  <-- copy it'
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
        echo "* * * * * /bin/sh ${MY_SHOP_PATH}/cron.sh" >> magecron
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
pause '------> Press [Enter] key to show menu'
echo
else
echo
echo
pause '---> Press [Enter] key to show menu'
printf "\033c"
fi
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
if [ "$mysql_rpass_gen" == "y" ];then
   echo
       MYSQL_ROOT_PASSGEN=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 15 | head -n 1)
       WHITETXT "MySQL ROOT password: ${REDBG} ${MYSQL_ROOT_PASSGEN} "
       GREENTXT "!REMEMBER IT AND KEEP IT SAFE!"
   echo
fi
echo -n "---> Start Mysql Secure Installation? [y/n][n]:"
read mysql_secure
if [ "$mysql_secure" == "y" ];then
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
if [ "$mysql_upass_gen" == "y" ];then
        MYSQL_USER_PASSGEN=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 15 | head -n 1)
        WHITETXT "MySQL USER password: ${RED} ${MYSQL_USER_PASSGEN} "
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
read -e -p "---> Enter your database name: " -i "$DB_NAME"  MAGE_DB_NAME
read -e -p "---> Enter your database user: " -i "$DB_USER_NAME"  MAGE_DB_USER_NAME
read -e -p "---> Enter your database password: " -i "$DB_PASS"  MAGE_DB_PASS
echo
WHITETXT "Administrator and domain"
read -e -p "---> Enter your First Name: " -i "Name"  MAGE_ADMIN_FNAME
read -e -p "---> Enter your Last Name: " -i "Lastname"  MAGE_ADMIN_LNAME
read -e -p "---> Enter your email: " -i "admin@domain.com"  MAGE_ADMIN_EMAIL
read -e -p "---> Enter your admins login name: " -i "admin"  MAGE_ADMIN_LOGIN
MAGE_ADMIN_PASSGEN=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 15 | head -n 1)
read -e -p "---> Use generated admin password: " -i "$MAGE_ADMIN_PASSGEN"  MAGE_ADMIN_PASS
read -e -p "---> Enter your shop url: " -i "http://$DOMAIN/"  MAGE_SITE_URL
read -e -p "---> Enter your locale: " -i "en_GB"  MAGE_LOCALE
read -e -p "---> Enter your timezone: " -i "Europe/Budapest"  MAGE_TIMEZONE
read -e -p "---> Enter your currency: " -i "EUR"  MAGE_CURRENCY
echo
WHITETXT "============================================================================="
echo
GREENTXT "NOW INSTALLING MAGENTO WITHOUT SAMPLE DATA"
MY_SHOP_PATH=$(awk '/webshop/ { print $3 }' /root/mascm/.mascm_index)
cd ${MY_SHOP_PATH}
    chmod +x mage
    ./mage mage-setup .

php -f install.php -- \
--license_agreement_accepted "yes" \
--locale "$MAGE_LOCALE" \
--timezone "$MAGE_TIMEZONE" \
--default_currency "$MAGE_CURRENCY" \
--db_host "$MAGE_DB_HOST" \
--db_name "$MAGE_DB_NAME" \
--db_user "$MAGE_DB_USER_NAME" \
--db_pass "$MAGE_DB_PASS" \
--url "$MAGE_SITE_URL" \
--use_rewrites "yes" \
--use_secure "no" \
--secure_base_url "" \
--skip_url_validation "yes" \
--use_secure_admin "no" \
--admin_firstname "$MAGE_ADMIN_FNAME" \
--admin_lastname "$MAGE_ADMIN_LNAME" \
--admin_email "$MAGE_ADMIN_EMAIL" \
--admin_username "$MAGE_ADMIN_LOGIN" \
--admin_password "$MAGE_ADMIN_PASS"

GREENTXT "ok"
    echo
    WHITETXT "============================================================================="
    echo
    GREENTXT "INSTALLED THE LATEST STABLE VERSION OF MAGENTO WITHOUT SAMPLE DATA"
    echo
    WHITETXT "============================================================================="
    WHITETXT " MAGENTO FRONTEND AND BACKEND LINKS"
    echo
    echo "      Store: $MAGE_SITE_URL"
    echo
    WHITETXT "============================================================================="
    WHITETXT " MAGENTO ADMIN ACCOUNT"
    echo
    echo "      Username: $MAGE_ADMIN_LOGIN"
    echo "      Password: $MAGE_ADMIN_PASS"
    echo
    WHITETXT "============================================================================="
    WHITETXT " MAGENTO DATABASE INFO"
    echo
    echo "      Database: $MAGE_DB_NAME"
    echo "      Username: $MAGE_DB_USER_NAME"
    echo "      Password: $MAGE_DB_PASS"
    echo
    WHITETXT "============================================================================="
        echo
echo
echo
WHITETXT "-= FINAL MAINTENANCE AND CLEANUP =-"
echo
echo "---> CHANGING YOUR LOCAL.XML FILE WITH MEMCACHE SESSIONS AND REDIS CACHE BACKENDS"
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
            <compression_lib>gzip</compression_lib> \
        </backend_options> \
        </cache>' ${MY_SHOP_PATH}/app/etc/local.xml
echo
echo "---> CLEANING UP INDEXES LOCKS AND RUNNING REINDEXALL"
echo
rm -rf  ${MY_SHOP_PATH}/var/locks/*
php ${MY_SHOP_PATH}/shell/indexer.php --reindexall
echo
chmod +x /root/app_monitor.sh
/root/app_monitor.sh &
echo
echo "---> TRUNCATE LOGS WEEKLY ADD TO CRONTAB"
cat > /root/truncate_logs.sh <<END
#!/bin/bash
TABLES="log_url log_url_info log_visitor log_visitor_info"
for table in \$TABLES
do
  echo "Truncating \$t table from $DB_NAME database"
  mysql -u $DB_USER_NAME -p$DB_PASS -h $DB_HOST $DB_NAME -e "TRUNCATE TABLE \${table};"
done
END
chmod +x /root/truncate_logs.sh
GREENTXT "WRITING DATA TO CRON"
        crontab -l > magecron
        echo "0 6 * * 1 sh /root/truncate_logs.sh" >> magecron
        crontab magecron
        rm magecron
        crontab -l
        echo
        WHITETXT "Edit crontab if you need different settings"
        echo
echo
###################################################################################
#                   LOADING ALL THE EXTRA EXTENSIONS FROM HERE                    #
###################################################################################
echo "-------------------------------------------------------------------------------------"
BLUEBG "| YOU CAN INSTALL SOME ADDITIONAL EXTENSIONS DIRECTLY FROM MAGENTO CONNECT |"
echo "-------------------------------------------------------------------------------------"
echo
echo
pause '------> Press [Enter] key to continue'
cd ${MY_SHOP_PATH} && chmod +x mage
echo
echo -n "---> Would you like to install Turpentine Varnish FPC? [y/n][n]:"
read turpentine
if [ "$turpentine" == "y" ];
  then
    echo
      GREENTXT "INSTALATION OF TURPENTINE VARNISH FULL PAGE CACHE"
       echo
       ./mage install http://connect20.magentocommerce.com/community  Nexcessnet_Turpentine >/dev/null 2>&1
       GREENTXT "TURPENTINE VARNISH FPC HAS BEEN INSTALLED"
      echo
    else
      echo
        YELLOWTXT "TURPENTINE VARNISH FPC installation was skipped by the user. Next step"
      fi
echo
echo
echo -n "---> Would you like to install Lesti FPC? [y/n][n]:"
read lesti
if [ "$lesti" == "y" ];
  then
    echo
      GREENTXT "INSTALLATION OF LESTI FULL PAGE CACHE"
       echo
       cd ${MY_SHOP_PATH}
       wget -qO- -O master.zip --no-check-certificate https://github.com/GordonLesti/Lesti_Fpc/archive/master.zip && unzip -qq master.zip && rm -rf master.zip
       cp -rf Lesti_Fpc-master/app .
       rm -rf Lesti_Fpc-master
       GREENTXT "LESTI FPC HAS BEEN INSTALLED"
      echo
    else
      echo
        YELLOWTXT "LESTI FPC installation was skipped by the user. Next step"
      fi
echo
echo
echo -n "---> Would you like to install Enhanced Admin Grids (+ Editor)? [y/n][n]:"
read eag
if [ "$eag" == "y" ];
  then
    echo
      GREENTXT "INSTALLATION OF ENHANCED ADMIN GRIDS"
       echo
       cd ${MY_SHOP_PATH}
       ./mage install http://connect20.magentocommerce.com/community  BL_CustomGrid
       echo
       GREENTXT "ENHANCED ADMIN GRIDS HAS BEEN INSTALLED"
      echo
    else
      echo
        YELLOWTXT "ENHANCED ADMIN GRIDS installation was skipped by the user. Next step"
      fi
echo
echo
echo -n "---> Would you like to install Magento WordPress Integration? [y/n][n]:"
read mwpi
if [ "$mwpi" == "y" ];
  then
    echo
      GREENTXT "INSTALLATION OF MAGENTO WORDPRESS INTEGRATION"
       echo
       cd ${MY_SHOP_PATH}
       ./mage install http://connect20.magentocommerce.com/community  Fishpig_Wordpress_Integration
       echo
       GREENTXT "MAGENTO WORDPRESS INTEGRATION HAS BEEN INSTALLED"
      echo
    else
      echo
        YELLOWTXT "MAGENTO WORDPRESS INTEGRATION installation was skipped by the user. Next step"
      fi
echo
echo
echo -n "---> Would you like to install One Page Checkout (IWD Extensions)? [y/n][n]:"
read mopciwd
if [ "$mopciwd" == "y" ];
  then
    echo
      GREENTXT "INSTALLATION OF ONE PAGE CHECKOUT (IWD EXTENSIONS)"
       echo
       cd ${MY_SHOP_PATH}
       ./mage install http://connect20.magentocommerce.com/community 1213
       echo
       GREENTXT "ONE PAGE CHECKOUT (IWD EXTENSIONS) HAS BEEN INSTALLED"
      echo
    else
      echo
        YELLOWTXT "ONE PAGE CHECKOUT (IWD EXTENSIONS) installation was skipped by the user. Next step"
      fi
echo
echo
echo -n "---> Would you like to install EU Cookie Law Compliance? [y/n][n]:"
read euclc
if [ "$euclc" == "y" ];
  then
    echo
      GREENTXT "INSTALLATION OF EU Cookie Law Compliance"
       echo
       cd ${MY_SHOP_PATH}
       ./mage install http://connect20.magentocommerce.com/community  Vhaldecode_CookieLaw
       echo
       GREENTXT "EU Cookie Law Compliance HAS BEEN INSTALLED"
      echo
    else
      echo
        YELLOWTXT "EU Cookie Law Compliance installation was skipped by the user. Next step"
      fi
echo
echo
    GREENTXT "NOW LOGIN TO YOUR BACKEND AND CHECK EVERYTHING"
    echo
  echo
echo
pause '---> Press [Enter] key to show the menu'
;;
###################################################################################
#                               BACKUP YOUR MAGENTO FILES                         #
###################################################################################
"backup")
echo
WHITETXT "============================================================================="
echo
WHITETXT "BACKUP YOUR MAGENTO FILES TO AMAZON S3"
WHITETXT "AWS Free Tier includes 5GB storage, 20K Get Requests, and 2K Put Requests."
WHITETXT "Go to http://aws.amazon.com/s3/ , click on the Sign Up button."
echo
echo -n "---> Install AWS Command Line Interface? [y/n][n]:"
read S3_backup
if [ "$S3_backup" == "y" ];then
    echo
       yum -y -q install python-setuptools
       easy_install pip
       pip install --upgrade awscli
       echo
       echo
       WHITETXT "Prepare your Access and Secret Key"
       echo
       sleep 2
       WHITETXT "Configure AWS Command Line Interface now"
       echo
       aws configure
	echo
fi
echo
echo
WHITETXT "============================================================================="
echo
# Creating cron to S3
echo -n "---> Upload backup files and database and add to cron? [y/n][n]: "
echo
read s3_now
if [ "$s3_now" == "y" ];then
    DB_HOST=$(awk '/database/ { print $2 }' /root/mascm/.mascm_index)
    DB_NAME=$(awk '/database/ { print $3 }' /root/mascm/.mascm_index)
    DB_USER_NAME=$(awk '/database/ { print $4 }' /root/mascm/.mascm_index)
    DB_PASS=$(awk '/database/ { print $5 }' /root/mascm/.mascm_index)
    SHOP_PATH=$(awk '/webshop/ { print $3 }' /root/mascm/.mascm_index)
    echo
    read -p "---> Confirm your S3 bucket name for backup: " S3_BUCKET
    read -e -p "---> Confirm your local temporary folder: " -i "/home"  SAVE_FOLDER
    echo
    WHITETXT "CREATING CRON DATA TO USE AUTO-BACKUP TO S3"
    WHITETXT "Magento files cron backup"
cat > /root/S3_AB_FILES_CRON.sh <<END
#!/bin/bash
echo "Compressing the backup."
tar -cvpzf  $SAVE_FOLDER/shop_\$(date +%a-%d-%m-%Y-%S).tar.gz  $SHOP_PATH
echo "Site backup compressed."
echo "Uploading the new site backup..."
aws s3 mv $SAVE_FOLDER/shop_*.tar.gz  s3://$S3_BUCKET/
echo "Backup uploaded."
GREENTXT "All done."
END

WHITETXT "Magento database cron backup..."
cat > /root/S3_AB_DB_CRON.sh <<END
#!/bin/bash
echo "Compressing the backup."
mysqldump -u $DB_USER_NAME -p$DB_PASS --single-transaction $DB_NAME | gzip > $SAVE_FOLDER/db_\$(date +%a-%d-%m-%Y-%S).sql.gz
echo "Uploading database dump..."
aws s3 mv $SAVE_FOLDER/db_*.tar.gz  s3://$S3_BUCKET/
echo "Backup uploaded."
END
        GREENTXT "WRITING DATA TO CRON"
        crontab -l > magecron
        echo "0 0 * * 0 sh /root/S3_AB_FILES_CRON.sh" >> magecron
        echo "0 5 * * * sh /root/S3_AB_DB_CRON.sh" >> magecron
        crontab magecron
        rm magecron
        crontab -l
        echo
        WHITETXT "Edit crontab if you need different settings"
        echo
     fi
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
if [ "$new_rupass_gen" == "y" ];then
   echo
      NEW_ROOT_PASSGEN=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9~!@#$%^&' | fold -w 15 | head -n 1)
      WHITETXT "Password: ${RED} ${NEW_ROOT_PASSGEN}"
      GREENTXT "!REMEMBER IT AND KEEP IT SAFE!"
   echo
fi
echo
echo -n "---> Create your new user? [y/n][n]:"
read new_root_user
if [ "$new_root_user" == "y" ];then
     echo
        read -p "---> Enter the new user name: " NEW_ROOT_NAME
        echo "${NEW_ROOT_NAME}    ALL=(ALL)               ALL" >> /etc/sudoers
        SHOP_PATH=$(awk '/webshop/ { print $3 }' /root/mascm/.mascm_index)
        FPM_USER=$(awk '/webshop/ { print $4 }' /root/mascm/.mascm_index)
        useradd -G ${FPM_USER} -d ${SHOP_PATH} -s /bin/bash ${NEW_ROOT_NAME}
        passwd ${NEW_ROOT_NAME}
     echo
fi
echo
echo -n "---> Change ssh settings snow? [y/n][n]:"
read new_ssh_set
if [ "$new_ssh_set" == "y" ];then
   echo
      cp /etc/ssh/sshd_config /etc/ssh/sshd_config.BACK
      read -p "---> Enter a new ssh port(9500-65000) : " NEW_SSH_PORT
      sed -i "s/#Port 22/Port $NEW_SSH_PORT/g" /etc/ssh/sshd_config
      sed -i 's/.*PermitRootLogin.*/PermitRootLogin no/g' /etc/ssh/sshd_config
  if [ -f /etc/fail2ban/jail.conf ]
     then
        cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.conf.BACK
        sed -i "s/port=ssh/port=$NEW_SSH_PORT/" /etc/fail2ban/jail.conf
        GREENTXT "fail2ban jail has been changed"
     echo
   fi
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
if [ "$new_ssh_test" == "y" ];then
   if [ -f /etc/fail2ban/jail.conf ]
     then
        service fail2ban restart
   fi
      echo
        GREENTXT "REMEMBER YOUR PORT: ${NEW_SSH_PORT}, LOGIN: ${NEW_ROOT_NAME} AND PASSWORD ${NEW_ROOT_PASSGEN}"
      else
        mv /etc/ssh/sshd_config.BACK /etc/ssh/sshd_config
        REDTXT "Writing your sshd_config back ... \033[01;32m ok"
        service sshd restart
   if [ -f /etc/fail2ban/jail.conf ]
     then
        mv /etc/fail2ban/jail.conf.BACK /etc/fail2ban/jail.conf
        service fail2ban restart
   fi
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
#                          INSTALLING PROFTPD SERVER                              #
###################################################################################
"proftpd")
WHITETXT "============================================================================="
echo
echo -n "---> Do you want to configure ProFTPd server now? [y/n][n]:"
read install_proftpd
if [ "$install_proftpd" == "y" ];then
        echo
            echo
            GREENTXT "Downloading ProFTPd latest ${PROFTPD_VER} archive"
            echo
            read -e -p "---> Enter your servers external ip: " -i "9521"  PROFTPD_PORT
            read -e -p "---> Enter your servers external ip: " -i "54.234.56.89"  PROFTPD_MASC_IP
            read -e -p "---> Enter your whitelist client ip: " -i "54.234.56.89 54.234.56.0/24"  PROFTPD_CLIENT_IP
            echo
            sed -i "s/server_sftp_port/${PROFTPD_PORT}/" /etc/proftpd.conf
            sed -i "s/server_ip_address/${PROFTPD_MASC_IP}/" /etc/proftpd.conf
            sed -i "s/client_ip_address/${PROFTPD_CLIENT_IP}/" /etc/proftpd.conf
            echo
        echo
fi
echo
echo
pause '---> Press [Enter] key to show the menu'
echo
echo
;;
###################################################################################
#                          INSTALLING CSF FIREWALL                                #
###################################################################################
"firewall")
WHITETXT "============================================================================="
echo
echo -n "---> Would you like to install CSF firewall? [y/n][n]:"
read csf_test
if [ "$csf_test" == "y" ];then
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
         if [ -f /etc/fail2ban/jail.conf ]
           then
             echo
             WHITETXT "Edit /etc/fail2ban/jail.conf [ssh-iptables] to 'enabled  = false', then restart fail2ban"
         fi
    fi
fi
echo
echo
pause '---> Press [Enter] key to show menu'
;;
"exit")
REDTXT "------> Hasta la vista, baby..."
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