#!/bin/bash
#KEY_OWNER=4f09fdcf5c89e32c6f712ecf90632615
#====================================================================#
#  MagenX - Automated Server Configuration for Magento               #
#    Copyright (C) 2013 admin@magentomod.com                      #
#	All rights reserved.                                         #
#====================================================================#
SELF=$(basename $0)
MASCM_VER="2.0"

# The base md5sum location to cotrol license
MASCM_BASE=http://www.magentomod.com/mascm

# quick-n-dirty - color, indent, echo, pause, proggress bar settings
function cecho() {
        COLOR='\033[01;37m'     # bold gray
        RESET='\033[00;00m'     # normal white
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "${COLOR}${MESSAGE}${RESET}" | awk '{print "    ",$0}'
}
function cinfo() {
        COLOR='\033[01;34m'     # bold blue
        RESET='\033[00;00m'     # normal white
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "${COLOR}${MESSAGE}${RESET}" | awk '{print "    ",$0}'
}
function cwarn() {
        COLOR='\033[01;31m'     # bold red
        RESET='\033[00;00m'     # normal white
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "${COLOR}${MESSAGE}${RESET}" | awk '{print "    ",$0}'
} 
function cok() {
        COLOR='\033[01;32m'     # bold green
        RESET='\033[00;00m'     # normal white
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "${COLOR}${MESSAGE}${RESET}" | awk '{print "    ",$0}'
}

function pause() {
   read -p "$*"
}

function start_progress {
  interval=1
  while true
  do
    echo -ne "#"
    sleep $interval
  done
}

function quick_progress {
  interval=0.05
  while true
  do
    echo -ne "#"
    sleep $interval
  done
}

function long_progress {
  interval=3
  while true
  do
    echo -ne "#"
    sleep $interval
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
# Check license key
#  KEY_OUT=$(curl $MASCM_BASE/ver 2>&1 | grep $KEY_OWNER | awk '{print $2}')
#  KEY_IN=$(echo $HOSTNAME | md5sum | awk '{print $1}')
#  if [[ "$KEY_OUT" == "$KEY_IN" ]]; then
#    cok "PASS: INTEGRITY CHECK FOR '$SELF' ON '$HOSTNAME' OK"
# elif [[ "$KEY_OUT" != "$KEY_IN" ]]; then
#    cwarn "ERROR: INTEGRITY CHECK FAILED! MD5 MISMATCH!"
#    cwarn "YOU CAN NOT RUN THIS SCRIPT WITHOUT A LICENSE KEY"
#    echo "Local md5:  $KEY_IN"
#    echo "Remote md5: $KEY_OUT"
#    echo
#    echo "-----> NOTE: PLEASE REPORT IT TO: admin@magentomod.com"
#	echo
#	echo
#	exit 1
#fi

# root?
if [[ $EUID -ne 0 ]]; then
cwarn "ERROR: THIS SCRIPT MUST BE RUN AS ROOT!"
echo "------> USE SUPER-USER PRIVILEGES."
  exit 1
else
  cok PASS: ROOT!
fi

# do we have CentOS 6?
if grep -q "CentOS release 6" /etc/redhat-release ; then
cok "PASS: CENTOS RELEASE 6"
  else 
cwarn "ERROR: UNABLE TO DETERMINE DISTRIBUTION TYPE."
echo "------> THIS CONFIGURATION FOR CENTOS 6."
echo
  exit 1
fi

# check if x64. if not, beat it...
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
cok "PASS: YOUR ARCHITECTURE IS 64-BIT"
  else
  cwarn "ERROR: YOUR ARCHITECTURE IS 32-BIT?"
  echo "------> CONFIGURATION FOR 64-BIT ONLY."
  echo
  exit 1
fi

# check if memory is enough
UNITS=$(cat /proc/meminfo | grep MemTotal | awk '{print $3}')
TOTALMEM=$(cat /proc/meminfo | grep MemTotal | awk '{print $2}')
if [ "$TOTALMEM" -gt "3800000" ]; then
cok "PASS: YOU HAVE $TOTALMEM $UNITS OF RAM"
  else
  cwarn "WARNING: YOU HAVE LESS THAN 4GB OF RAM"
fi

# network is up?
host1=74.125.24.106
host2=208.80.154.225
RESULT=$(((ping -w3 -c2 $host1 || ping -w3 -c2 $host2) > /dev/null 2>&1) && echo "up" || (echo "down" && exit 1))
if [[ $RESULT == up ]]; then
cok "PASS: NETWORK IS UP. GREAT, LETS START!"
  else
cwarn "ERROR: NETWORK IS DOWN?"
echo "------> PLEASE CHECK YOUR NETWORK SETTINGS."
echo
echo
  exit 1
fi
echo
###################################################################################
#                                     CHECKS END                                  #
###################################################################################
echo
if grep -q "yes" ~/mascm/.terms >/dev/null 2>&1 ; then
echo "loading menu"
sleep 1
	else
cecho "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo
cecho "BY INSTALLING THIS SOFTWARE AND BY USING ANY AND ALL SOFTWARE"
cecho "YOU ACKNOWLEDGE AND AGREE:"
echo
cecho "THIS SOFTWARE AND ALL SOFTWARE PROVIDED IS PROVIDED AS IS"
cecho "UNSUPPORTED AND WE ARE NOT RESPONSIBLE FOR ANY DAMAGE"
echo
cecho "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo
echo
			echo -n "---> Do you agree to these terms?  [y/n][y]:"
			read terms_agree
				if [ "$terms_agree" == "y" ];then
				echo "yes" > ~/mascm/.terms
			else
			echo "Exiting"
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
        cecho "Magento Server Configuration v.$MASCM_VER"
        cecho :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
        echo
        cecho "- For repositories installation enter:  \033[01;34m repo"
        cecho "- For packages installation enter:  \033[01;34m packages"
	cecho "- To download latest Magento enter:  \033[01;34m magento"
	cecho "- To setup Magento database enter:  \033[01;34m database"
	cecho "- Install Magento (no sample data):  \033[01;34m install"
	echo
	cecho :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
	echo
	cecho "- To configure system backup enter:  \033[01;34m  backup"
	cecho "- To make your server secure enter:  \033[01;34m protect"
	cecho "- To install CSF firewall enter:  \033[01;34m   firewall"
	echo
	cecho :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
	echo
	cecho "- To quit enter:  \033[01;34m exit"
	echo
	echo
}
while [ 1 ]
do
        showMenu
        read CHOICE
        case "$CHOICE" in
                "repo")
echo
#echo @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#cwarn "secure /tmp and /var/tmp"
#echo @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#echo
#echo -n "---> Would you like to secure /tmp and /var/tmp? [y/n][n]:" 
#read secure_tmp
#if [ "$secure_tmp" == "y" ];then
#        echo
#		cd
#			rm -rf /tmp
#			mkdir /tmp
#			mount -t tmpfs -o rw,noexec,nosuid tmpfs /tmp
#			chmod 1777 /tmp
#			echo "tmpfs   /tmp    tmpfs   rw,noexec,nosuid        0       0" >> /etc/fstab
#			rm -rf /var/tmp
#			ln -s /tmp /var/tmp
#			echo
#		cok "SECURED OK"
#fi
echo
echo @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
cok NOW BEGIN REPOSITORIES INSTALLATION
echo @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
echo
cecho "============================================================================="
echo
echo -n "---> Start EPEL repository installation? [y/n][n]:"
read repoE_install
if [ "$repoE_install" == "y" ];then
        echo
        cok "Running Installation of Extra Packages for Enterprise Linux"
        echo
			echo -n "     PROCESSING  "
		quick_progress &
		pid="$!"
		rpm -Uvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm >/dev/null 2>&1
		stop_progress "$pid"
                rpm  --quiet -q epel-release
                if [ "$?" = 0 ]
                    then
                    cok "INSTALLED OK"
		else
                    cwarn "ERROR"
		exit
                fi
	else
        cinfo "EPEL repository installation skipped. Next step"
fi
echo
cecho "============================================================================="
echo
echo -n "---> Start CentALT Repository installation? [y/n][n]:"
read repoC_install
if [ "$repoC_install" == "y" ];then
		echo
        cok "Running Installation of CentALT repository"
		echo
			echo -n "     PROCESSING  "
		quick_progress &
		pid="$!"
		rpm -Uvh http://centos.alt.ru/pub/repository/centos/6/x86_64/centalt-release-6-1.noarch.rpm >/dev/null 2>&1
		stop_progress "$pid"
                rpm  --quiet -q centalt-release
                if [ "$?" = 0 ]
                    then
                    cok "INSTALLED OK"
		else
                    cwarn "ERROR"
		exit
                fi
	echo
		cok "Locking CentALT only for Nginx and Memcached always latest build"
		echo "includepkgs=nginx* memcached" >> /etc/yum.repos.d/centalt.repo
  else
        cinfo "CentALT repository installation skipped. Next step"
fi
echo
cecho "============================================================================="
echo
echo -n "---> Start Repoforge repository installation? [y/n][n]:"
read repoF_install
if [ "$repoF_install" == "y" ];then
		echo
        cok "Running Installation of Repoforge"
		echo
			echo -n "     PROCESSING  "
		quick_progress &
		pid="$!"
		rpm -Uvh http://pkgs.repoforge.org/rpmforge-release/rpmforge-release-0.5.2-2.el6.rf.x86_64.rpm >/dev/null 2>&1
		stop_progress "$pid"
                rpm  --quiet -q rpmforge-release
                if [ "$?" = 0 ]
                    then
                    cok "INSTALLED OK"
		else
                    cwarn "ERROR"
		exit
                fi
	echo
  else
        cinfo "Repoforge installation skipped. Next step"
fi
echo
cecho "============================================================================="
echo
echo -n "---> Start Percona repository installation? [y/n][n]:"
read repoP_install
if [ "$repoP_install" == "y" ];then
		echo
        cok "Running Installation of Percona repository"
		echo
			echo -n "     PROCESSING  "
		quick_progress &
		pid="$!"
		rpm -Uhv http://www.percona.com/downloads/percona-release/percona-release-0.0-1.x86_64.rpm >/dev/null 2>&1
		stop_progress "$pid"
                rpm  --quiet -q percona-release
                if [ "$?" = 0 ]
                    then
                    cok "INSTALLED OK"
		else
                    cwarn "ERROR"
		exit
                fi
	echo
  else
        cinfo "Percona repository installation skipped. Next step"
fi
echo
cecho "============================================================================="
echo
echo -n "---> Start IUScommunity repository installation? [y/n][n]:"
read repoIU_install
if [ "$repoIU_install" == "y" ];then
		echo
        cok "Running Installation of IUScommunity repository "
		echo
			echo -n "     PROCESSING  "
		quick_progress &
		pid="$!"
		rpm -Uvh http://dl.iuscommunity.org/pub/ius/stable/Redhat/6/x86_64/ius-release-1.0-10.ius.el6.noarch.rpm >/dev/null 2>&1
		stop_progress "$pid"
                rpm  --quiet -q ius-release
                if [ "$?" = 0 ]
                    then
                    cok "INSTALLED OK"
		else
                    cwarn "ERROR"
		exit
                fi
	echo
  else
        cinfo "IUScommunity repository installation skipped. Next step"
fi
###################################################################################
#                                 REPOSITORIES END                                #
###################################################################################
echo
cecho "============================================================================="
echo -n "---> Start System Update? [y/n][n]:"
read sys_update
if [ "$sys_update" == "y" ];then
        cok "RUNNING SYSTEM UPDATE"
		echo
			echo -n "     PROCESSING  "
		long_progress &
		pid="$!"
		yum -y -q update >/dev/null 2>&1
		stop_progress "$pid"
		cok "UPDATED OK"
		echo
		cok "INSTALLING ADDITIONAL PACKAGES:"
		echo
		echo -n "     PROCESSING  "
			long_progress &
			pid="$!"
			yum -q -y install wget curl mcrypt sudo crontabs gcc vim mlocate unzip >/dev/null 2>&1
			stop_progress "$pid"
		cok "INSTALLED OK"
		echo
  else
        cinfo "System Update skipped. Next step"
fi
echo
echo 
echo @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
cok REPOSITORIES INSTALLATION FINISHED
echo @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
echo
echo
pause "---> Press [Enter] key to show menu"
printf "\033c"
;;
"packages")
echo
echo @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
cok NOW INSTALLING PHP, NGINX, PERCONA, VARNISH, MEMCACHED, FAIL2BAN
echo @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
echo
echo
cecho "============================================================================="
echo
echo -n "---> Start Percona installation? [y/n][n]:"
read percona_install
if [ "$percona_install" == "y" ];then
		echo
        cok "Running Percona Installation"
		echo
			echo -n "     PROCESSING  "
		long_progress &
		pid="$!"
		yum -y -q install Percona-Server-client-55 Percona-Server-server-55  >/dev/null 2>&1
		stop_progress "$pid"
			rpm  --quiet -q Percona-Server-client-55 Percona-Server-server-55
			if [ "$?" = 0 ]
		then
                    cok "INSTALLED OK"
		else
                    cwarn "ERROR"
		exit
		fi
			echo
			chkconfig mysql on
		echo
		cecho "Percona doesnt have its own my.cnf file"
		cecho "Downloading from MagenX Github repository default config"
			wget -O /etc/my.cnf_  -q https://raw.github.com/magenx/magento-mysql/master/my.cnf/my.cnf
		echo
		cok "my.cnf downloaded to /etc and saved as my.cnf_"
		cecho "Please correct it according to your servers specs, rename and restart your mysql server"
			wget -O /etc/mysqlreport.pl  -q  http://hackmysql.com/scripts/mysqlreport
			wget -O /etc/mysqltuner.pl  -q  https://raw.github.com/rackerhacker/MySQLTuner-perl/master/mysqltuner.pl
		cecho "Please use these tools to check and finetune your database"
		cecho "perl /etc/mysqlreport.pl"
		cecho "perl /etc/mysqltuner.pl"
  else
        cinfo "Percona installation skipped. Next step"
fi
echo
cecho "============================================================================="
echo
echo -n "---> Start PHP installation? [y/n][n]:"
read php_install
if [ "$php_install" == "y" ];then
		echo
        cok "Running PHP Installation"
		echo
			echo -n "     PROCESSING  "
		long_progress &
		pid="$!"
		yum -y -q install php54 php54-cli php54-common php54-fpm php54-gd php54-curl php54-mbstring php54-bcmath php54-soap php54-mcrypt php54-mysql php54-pdo php54-xml php54-pecl-apc php54-pecl-memcache  >/dev/null 2>&1
		stop_progress "$pid"
		rpm  --quiet -q php54
                if [ "$?" = 0 ]
                    then
                    cok "INSTALLED OK"
		yum list installed | grep php54 | awk '{print "      ",$1}'
		else
                    cwarn "ERROR"
		exit
                fi
		echo
		chkconfig php-fpm on
   else
        cinfo "PHP installation skipped. Next step"
fi
echo
cecho "============================================================================="
echo
echo -n "---> Start NGINX installation? [y/n][n]:"
read nginx_install
if [ "$nginx_install" == "y" ];then
		echo
        cok "Running NGINX Installation"
		echo
			echo -n "     PROCESSING  "
		start_progress &
		pid="$!"
		yum -y -q install nginx  >/dev/null 2>&1
		stop_progress "$pid"
                rpm  --quiet -q nginx
                if [ $? = 0 ]
                    then
                    cok "INSTALLED OK"
		else
                    cwarn "ERROR"
		exit
                fi
	echo
		chkconfig nginx on
		chkconfig httpd off
  else
        cinfo "NGINX installation skipped. Next step"
fi
echo
cecho "============================================================================="
echo
echo -n "---> Start Varnish 3 installation? [y/n][n]:"
read varnish_install
if [ "$varnish_install" == "y" ];then
		echo
        cok "Running Varnish 3 Installation"
		echo
			echo -n "     PROCESSING  "
		quick_progress &
		pid="$!"
		rpm -Uhv http://repo.varnish-cache.org/redhat/varnish-3.0/el6/x86_64/varnish-3.0.3-1.el6.x86_64.rpm http://repo.varnish-cache.org/redhat/varnish-3.0/el6/x86_64/varnish-libs-3.0.3-1.el6.x86_64.rpm >/dev/null 2>&1
		stop_progress "$pid"
		rpm  --quiet -q varnish
                if [ "$?" = 0 ]
                    then
                    cok "INSTALLED OK"
		else
                    cwarn "ERROR"
		exit
                fi
	echo
  else
        cinfo "Varnish 3 installation skipped. Next step"
fi
echo
cecho "============================================================================="
echo
echo -n "---> Start Memcached installation? [y/n][n]:"
read memd_install
if [ "$memd_install" == "y" ];then
		echo
        cok "Running Memcached Installation"
		echo
			echo -n "     PROCESSING  "
		start_progress &
		pid="$!"
		yum -y -q install memcached  >/dev/null 2>&1
		stop_progress "$pid"
                rpm  --quiet -q memcached
                if [ "$?" = 0 ]
                    then
                    cok "INSTALLED OK"
		else
                    cwarn "ERROR"
		exit
                fi
	echo
		chkconfig memcached on
  else
        cinfo "Memcached installation skipped. Next step"
fi
echo
cecho "============================================================================="
echo
echo -n "---> Start Fail2Ban installation? [y/n][n]:"
read f2b_install
if [ "$f2b_install" == "y" ];then
		echo
        cok "Running Fail2Ban Installation"
		echo
			echo -n "     PROCESSING  "
		start_progress &
		pid="$!"
		yum -y -q install fail2ban  >/dev/null 2>&1
		stop_progress "$pid"
                rpm  --quiet -q memcached
                if [ "$?" = 0 ]
                    then
                    cok "INSTALLED OK"
		else
                    cwarn "ERROR"
		exit
                fi
		echo
		chkconfig fail2ban on
cok "Writing nginx 403 filter"
cat > /etc/fail2ban/filter.d/nginx-403.conf <<END
[Definition]
failregex = ^<HOST> -.*HTTP/1\..* 403
END
cok "Writing nginx 403 action"
cat > /etc/fail2ban/action.d/nginx-403.conf <<END
[Definition]
actionban = IP=<ip> && echo "deny $IP;" >> /etc/nginx/banlist/403.conf && service nginx reload
actionunban = IP=<ip> && sed -i "/$IP/d" /etc/nginx/banlist/403.conf && service nginx reload
END
cok "Writing nginx 403 jail"
cat >> /etc/fail2ban/jail.conf <<END
[nginx-403]
enabled = true
port = http,https
filter = nginx-403
action = nginx-403
logpath = /var/log/nginx/access.log
bantime = 84600
maxretry = 3
END
cok "Creating banlist dir"
mkdir -p /etc/nginx/banlist/
touch /etc/nginx/banlist/403.conf
cok "Please whitelist your ip addresses in /etc/fail2ban/jail.conf"
cok "ok"
  else
        cinfo "Fail2Ban installation skipped. Next step"
fi
echo
cecho "============================================================================="
echo
echo -n "---> Load optimized apc, php, fpm, fastcgi, memcached, sysctl? [y/n][n]:"
read load_configs
if [ "$load_configs" == "y" ];then
echo
cecho "YOU HAVE TO CHECK THEM AFTER ANYWAY"
   cat > /etc/sysctl.conf <<END
fs.file-max = 360000
 
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
cecho "sysctl.conf loaded ... \033[01;32m  ok"
cat > /etc/php.d/apc.ini <<END
extension = apc.so
[APC]
apc.enabled = 1
apc.shm_segments = 1
apc.shm_size = 256M
apc.num_files_hint = 5000
apc.user_entries_hint = 5000
apc.ttl = 7200
apc.user_ttl = 7200
apc.gc_ttl = 3600
apc.cache_by_default = 1
apc.filters = "apc\.php$"
apc.mmap_file_mask = "/tmp/apc.XXXXXX"
apc.slam_defense = 0
apc.file_update_protection = 2
apc.enable_cli = 1
apc.max_file_size = 5M
apc.use_request_time = 0
apc.stat = 1
apc.write_lock = 1
apc.report_autofilter = 0
apc.include_once_override = 0
apc.coredump_unmap = 0
apc.stat_ctime = 0
END

cecho "apc.ini loaded ... \033[01;32m  ok"
#Tweak php.ini.
cp /etc/php.ini /etc/php.ini.BACK
sed -i 's/^\(max_execution_time = \)[0-9]*/\17200/' /etc/php.ini
sed -i 's/^\(max_input_time = \)[0-9]*/\17200/' /etc/php.ini
sed -i 's/^\(memory_limit = \)[0-9]*M/\1256M/' /etc/php.ini
sed -i 's/^\(post_max_size = \)[0-9]*M/\132M/' /etc/php.ini
sed -i 's/^\(upload_max_filesize = \)[0-9]*M/\132M/' /etc/php.ini
sed -i 's/expose_php = On/expose_php = Off/' /etc/php.ini
sed -i 's/;realpath_cache_size = 16k/realpath_cache_size = 512k/' /etc/php.ini
sed -i 's/;realpath_cache_ttl = 120/realpath_cache_ttl = 84600/' /etc/php.ini
sed -i 's/short_open_tag = Off/short_open_tag = On/' /etc/php.ini
sed -i 's/; max_input_vars = 1000/max_input_vars = 8000/' /etc/php.ini
sed -i 's/pm = dynamic/pm = ondemand/' /etc/php-fpm.d/www.conf
cecho "php.ini loaded ... \033[01;32m  ok"
cat > /etc/sysconfig/memcached <<END 
PORT="11211"
USER="memcached"
MAXCONN="5024"
CACHESIZE="256"
OPTIONS="-l 127.0.0.1"
END
cecho "memcached config loaded ... \033[01;32m  ok"
echo -e '\nfastcgi_read_timeout 7200;\nfastcgi_send_timeout 7200;\nfastcgi_connect_timeout 65;\n' >> /etc/nginx/fastcgi_params
cecho "fastcgi_params loaded ... \033[01;32m  ok"
echo
  else
        cinfo "Not loading optimized configs. Next step"
fi
echo
echo
echo @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
cok FINISHED PACKAGES INSTALLATION
echo @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
echo
echo
pause '------> Press [Enter] key to show menu'
printf "\033c"
;;
"magento")
echo
echo @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
cok NOW DOWNLOADING NEW MAGENTO
echo @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
echo
FPM=$(find /etc/php-fpm.d/ -name 'www.conf')
FPM_USER=$(grep "user" $FPM | grep "=" | awk '{print $3}')
echo -n "---> Download latest Magento version? [y/n][n]:"
read new_down
if [ "$new_down" == "y" ];then
     read -e -p "---> Edit your installation folder full path: " -i "/var/www/html/myshop.com" MY_SHOP_PATH
        echo "  Magento will be downloaded to:" 
		cok $MY_SHOP_PATH
		pause '------> Press [Enter] key to continue'
		mkdir -p $MY_SHOP_PATH	
		echo  
		cd $MY_SHOP_PATH
		echo -n "      DOWNLOADING MAGENTO  "
			long_progress &
			pid="$!"
			wget -qO - http://www.magentocommerce.com/downloads/assets/1.7.0.2/magento-1.7.0.2.tar.gz | tar -xzp
			stop_progress "$pid"
		echo
		cecho "Cleanup"
		mv magento/* .
		rm -rf magento RELEASE_NOTES.txt LICENSE.txt LICENSE.html LICENSE_AFL.txt index.php.sample php.ini.sample
		echo
cecho "============================================================================="
cok "      == MAGENTO DOWNLOADED AND READY FOR INSTALLATION =="
cecho "============================================================================="
echo
echo
echo "---> CREATING NGINX CONFIG FILE NOW"
echo
read -p "---> Enter your domain name: " MY_DOMAIN
MY_CPU=$(grep -c processor /proc/cpuinfo)
cok "NGINX CONFIG SET UP WITH:"
cecho " DOMAIN: $MY_DOMAIN"  
cecho " ROOT: $MY_SHOP_PATH"    
cecho " CPU: $MY_CPU"
if [ -f /etc/fail2ban/jail.conf ]
then
FAIL2BAN='include /etc/nginx/banlist/403.conf;'
fi
cat > /etc/nginx/nginx.conf <<END
user  $FPM_USER;
worker_processes  $MY_CPU; ## = CPU qty

error_log   /var/log/nginx/error.log;
#error_log  /var/log/nginx/error.log  notice;
#error_log  /var/log/nginx/error.log  info;

pid        /var/run/nginx.pid;

events {
    worker_connections  1024;
    use epoll;
       }

http   {
    index index.html index.php; ## Allow a static html file to be shown first
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';

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
    gzip_comp_level     8;
    gzip_min_length     1024;

    #ssl_session_cache shared:SSL:15m;
    #ssl_session_timeout 15m;

    keepalive_timeout   10;

	## Use when Varnish in front
	#set_real_ip_from 127.0.0.1;
	#real_ip_header X-Forwarded-For;

	## Multi domain configuration
	#map \$http_host \$storecode { 
	   #www.domain1.com 1store_code; ## US main
	   #www.domain2.net 2store_code; ## EU store
	   #www.domain3.de 3store_code; ## German store
	   #www.domain4.com 4store_code; ## different products
	   #}

server {   
    listen 80; ## change to 8080 with Varnish
    #listen 443 ssl;
    server_name $MY_DOMAIN; ## Domain is here
    root $MY_SHOP_PATH;

    access_log  /var/log/nginx/access_mydomain.log  main;
    
    ## Nginx will not add the port in the url when the request is redirected.
    #port_in_redirect off; 

    ####################################################################################
    ## SSL CONFIGURATION

       #ssl_certificate     /etc/ssl/certs/www_server_com.chained.crt; 
       #ssl_certificate_key /etc/ssl/certs/server.key;

       #ssl_protocols             SSLv3 TLSv1 TLSv1.1 TLSv1.2;
       #ssl_ciphers               RC4:HIGH:!aNULL:!MD5:!kEDH;
       #ssl_prefer_server_ciphers on;

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
        }

    ####################################################################################

    ## These locations would be hidden by .htaccess normally, protected
    location ~ (/(app/|includes/|/pkginfo/|var/|errors/local.xml)|/\.svn/|/.hta.+) {
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

    ## Images, scripts and styles set far future Expires header
    location ~* \.(js|css|png|jpg|jpeg|gif|ico)$ {
        expires max;
        log_not_found off;
        }

    ####################################################################################

    ## Main Magento location
    location @handler {
        rewrite / /index.php;
        }
 
    location ~ .php/ { ## Forward paths like /js/index.php/x.js to relevant handler
        rewrite ^(.*.php)/ $1 last;
        }

    ####################################################################################
    
    ## Execute PHP scripts
    location ~ .php$ {
        add_header X-Config-By 'MagenX -= www.magentomod.com =-';
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
mkdir -p ~/mascm/
cat >> ~/mascm/.mascm_index <<END
webshop	$MY_DOMAIN	$MY_SHOP_PATH
END
echo
###################################################################################
#                   LOADING ALL THE POSSIBLE EXTENSIONS FROM HERE                 #
###################################################################################
echo
cok "INSTALLING ENHANCED ADMIN GRIDS INTO MAGENTO"
pause '------> Press [Enter] key to continue'
echo
		cd $MY_SHOP_PATH
		wget -qO- -O eagrid.zip --no-check-certificate https://github.com/mage-eag/mage-enhanced-admin-grids/archive/0.8.9.zip && unzip -qq eagrid.zip && rm -rf eagrid.zip
		cp -rf mage-enhanced-admin-grids-0.8.9/* .
		rm -rf mage-enhanced-admin-grids-0.8.9
	cok "Installed ENHANCED ADMIN GRIDS into System > Configuration"
	cok "ok"
echo
cok "INSTALLING APC CACHE CONTROL INTO MAGENTO ADMIN"
pause '------> Press [Enter] key to continue'
echo
		cd $MY_SHOP_PATH
		wget -qO - http://www.magentomod.com/mascm/apcadmin.tar.gz | tar -xzp
	cok "APC cache installed into System > Cache Management"
	cok "ok"
echo
cok "INSTALLING MyWebSQL - Web-based MySQL Admin Interface"
pause '------> Press [Enter] key to continue'
echo
		cd $MY_SHOP_PATH
		wget -qO- -O mywebsql.zip http://sourceforge.net/projects/mywebsql/files/latest/download?source=files && unzip -qq mywebsql.zip && rm -rf mywebsql.zip
		MYWEB_FOLDER=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z' | fold -w 7 | head -n 1)
		mv mywebsql db_$MYWEB_FOLDER
	cok "MyWebSQL installed to db_$MYWEB_FOLDER"
	cecho "Allow access to db_$MYWEB_FOLDER from subdomain or to your ip only!"
	cok "ok"
echo
echo
wget -q https://github.com/magenx/MASC-M/blob/master/local.xml
cecho "Add contents of this file $MY_SHOP_PATH/local.xml to your app/etc/local.xml"
cecho "to enable twolevel cache backend with apc and memcached"
echo
echo
cecho "RESETTING FILE PERMISSIONS ..."
		find . -type f -exec chmod 644 {} \;
		find . -type d -exec chmod 755 {} \;
		chmod -R o+w var app/etc
		chmod -R o+w media       
		chown -R $FPM_USER:$FPM_USER $MY_SHOP_PATH
	cok "ok"
	echo
	cok "Writing Magento cron.php into crontab"
#write out current crontab
	crontab -l > magecron
	cok "thats ok"
#echo new cron into cron file
	echo "*/5 * * * * php -q $MY_SHOP_PATH/cron.php" >> magecron
#install new cron file
	crontab magecron
	rm magecron
	crontab -l
	cok "ok"
echo
echo
service php-fpm start
service nginx start
service memcached start
echo
echo
echo @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
cok GET READY FOR DATABASE CONFIGURATION
echo @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
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
cecho "============================================================================="
service mysql restart
echo
cecho "CREATING MAGENTO DATABASE AND DATABASE USER"
echo
echo -n "---> Generate MySQL ROOT strong password? [y/n][n]:"
read mysql_rpass_gen
if [ "$mysql_rpass_gen" == "y" ];then
echo
        MYSQL_ROOT_PASSGEN=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 15 | head -n 1)
                cecho "MySQL ROOT password: \033[01;31m $MYSQL_ROOT_PASSGEN"
                cok "!REMEMBER IT AND KEEP IT SAFE!"
        fi
	echo
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
                cecho "MySQL USER password: \033[01;31m $MYSQL_USER_PASSGEN"
        fi
echo
read -p "---> Enter MySQL USER password : " MAGE_DB_PASS
mysql -u root -p$MYSQL_ROOT_PASS <<EOMYSQL
CREATE USER '$MAGE_DB_USER_NAME'@'$MAGE_DB_HOST' IDENTIFIED BY '$MAGE_DB_PASS';
CREATE DATABASE $MAGE_DB_NAME;
GRANT ALL PRIVILEGES ON $MAGE_DB_NAME.* TO '$MAGE_DB_USER_NAME'@'$MAGE_DB_HOST' WITH GRANT OPTION;
exit
EOMYSQL
echo
cok "MAGENTO DATABASE \033[01;31m $MAGE_DB_NAME \033[01;32mAND USER \033[01;31m $MAGE_DB_USER_NAME \033[01;32m CREATED, PASSWORD IS \033[01;31m $MAGE_DB_PASS"
echo
mkdir -p ~/mascm/
cat >> ~/mascm/.mascm_index <<END
database	$MAGE_DB_HOST	$MAGE_DB_NAME	$MAGE_DB_USER_NAME	$MAGE_DB_PASS
END
echo
echo "Finita"
echo
echo
echo
pause '---> Press [Enter] key to show menu'
;;
###################################################################################
#                                MAGENTO INSTALLATION                             #
###################################################################################
"install")
printf "\033c"
cecho "============================================================================="
echo
echo "---> ENTER INSTALLATION INFORMATION"
DB_HOST=$(cat ~/mascm/.mascm_index | grep database | awk '{print $2}')
DB_NAME=$(cat ~/mascm/.mascm_index | grep database | awk '{print $3}')
DB_USER_NAME=$(cat ~/mascm/.mascm_index | grep database | awk '{print $4}')
DB_PASS=$(cat ~/mascm/.mascm_index | grep database | awk '{print $5}')
DOMAIN=$(cat ~/mascm/.mascm_index | grep webshop | awk '{print $2}')
echo
cecho "Database information"
read -e -p "---> Enter your database host: " -i "$DB_HOST"  MAGE_DB_HOST
read -e -p "---> Enter your database name: " -i "$DB_NAME"  MAGE_DB_NAME
read -e -p "---> Enter your database user: " -i "$DB_USER_NAME"  MAGE_DB_USER_NAME
read -e -p "---> Enter your database password: " -i "$DB_PASS"  MAGE_DB_PASS
echo
cecho "Administrator and domain"
read -e -p "---> Enter your First Name: " -i "Name"  MAGE_ADMIN_FNAME
read -e -p "---> Enter your Last Name: " -i "Lastname"  MAGE_ADMIN_LNAME
read -e -p "---> Enter your email: " -i "admin@domain.com"  MAGE_ADMIN_EMAIL
read -e -p "---> Enter your admins login name: " -i "admin"  MAGE_ADMIN_LOGIN
MAGE_ADMIN_PASSGEN=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 15 | head -n 1)
read -e -p "---> Use generated admin password: " -i "$MAGE_ADMIN_PASSGEN"  MAGE_ADMIN_PASS
read -e -p "---> Enter your shop url: " -i "http://$DOMAIN/"  MAGE_SITE_URL
echo
cecho "Check locale, timezone and currency options over here - https://github.com/magenx/MASC-M"
read -e -p "---> Enter your locale: " -i "en_GB"  MAGE_LOCALE
read -e -p "---> Enter your timezone: " -i "Europe/Budapest"  MAGE_TIMEZONE
read -e -p "---> Enter your currency: " -i "EUR"  MAGE_CURRENCY
echo
cecho "============================================================================="
echo
cok "NOW INSTALLING MAGENTO WITHOUT SAMPLE DATA"
SHOP_PATH=$(cat ~/mascm/.mascm_index | grep webshop | awk '{print $3}')
cd $SHOP_PATH
    chmod o+x mage
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

cok "ok"
    echo
    cecho "============================================================================="
    echo
    cok "INSTALLED THE LATEST STABLE VERSION OF MAGENTO WITHOUT SAMPLE DATA"
    echo
    cecho "============================================================================="
    cecho " MAGENTO FRONTEND AND BACKEND LINKS"
    echo
    echo "      Store: $MAGE_SITE_URL"
    echo "      Admin: $MAGE_SITE_URL/ admin/"
    echo
    cecho "============================================================================="
    cecho " MAGENTO ADMIN ACCOUNT"
    echo
    echo "      Username: $MAGE_ADMIN_LOGIN"
    echo "      Password: $MAGE_ADMIN_PASS"
    echo
    cecho "============================================================================="
    cecho " MAGENTO DATABASE INFO"
    echo
    echo "      Database: $MAGE_DB_NAME"
    echo "      Username: $MAGE_DB_USER_NAME"
    echo "      Password: $MAGE_DB_PASS"
    echo
    cecho "============================================================================="
	echo
echo
cok "NOW LOGIN TO YOUR WEB BACKEND AND CHECK EVERYTHING"
echo
pause '---> Press [Enter] key to show menu'
;;
###################################################################################
#                               BACKUP YOUR MAGENTO FILES                         #
###################################################################################
"backup")
echo
cecho "============================================================================="
echo
cecho "ONLY AMAZON S3 AND FTP OPTIONS ARE AVAILABLE DUE TO THE SIZE OF THE FILES"
echo
if [ ! -f /etc/yum.repos.d/s3tools.repo ]
then
	echo -n "---> Install Amazon S3 s3tools? [y/n][n]:"
	read S3_backup
	if [ "$S3_backup" == "y" ];then
	echo
		cecho "AWS Free Tier includes 5GB storage, 20K Get Requests, and 2K Put Requests."
		echo
		cecho "Go to http://aws.amazon.com/s3/ , click on the Sign Up button." 
		cecho "You will have to supply your Credit Card details."
		cecho "At the end you should posses your Access and Secret Keys."
	echo
	sleep 2
		cecho "Lets install s3tools first"
		cd /etc/yum.repos.d/
		wget -q http://s3tools.org/repo/RHEL_6/s3tools.repo
		echo
			echo -n "     PROCESSING  "
		start_progress &
		pid="$!"
		yum -y -q install s3cmd  >/dev/null 2>&1
		stop_progress "$pid"
                rpm  --quiet -q s3cmd
                if [ "$?" = 0 ]
                    then
                    cok "INSTALLED OK"
		else
                    cwarn "ERROR"
		exit
                fi
	echo
		cecho "Prepare your Access and Secret Keys"
	echo
	sleep 2
		cecho "Configuring s3tools now"
		s3cmd --configure
    fi
fi
	echo
echo
cecho "============================================================================="
echo
echo -n "---> CHECKPOINT 1. Backup Magento database now? [y/n][n]: "
read dump_db
if [ "$dump_db" == "y" ];then
DB_HOST=$(cat ~/mascm/.mascm_index | grep database | awk '{print $2}')
DB_NAME=$(cat ~/mascm/.mascm_index | grep database | awk '{print $3}')
DB_USER_NAME=$(cat ~/mascm/.mascm_index | grep database | awk '{print $4}')
DB_PASS=$(cat ~/mascm/.mascm_index | grep database | awk '{print $5}')
		if grep -q "dump" ~/mascm/.mascm_index ; then
		DBSAVE_FOLDER=$(cat ~/mascm/.mascm_index| grep dump | awk '{print $2}')
            echo "Saving the database"
                mysqldump -u $DB_USER_NAME -p$DB_PASS --single-transaction $DB_NAME | gzip > $DBSAVE_FOLDER/db_$(date +%a-%d-%m-%Y-%S).sql.gz
                cok "Magento database dump saved to $DBSAVE_FOLDER"
			echo
			else
            read -e -p "---> Enter mysql backup folder path: " -i "/home/backup/db" DBSAVE_FOLDER
                mkdir -p $DBSAVE_FOLDER
cat >> ~/mascm/.mascm_index <<END
dump	$DBSAVE_FOLDER
END
                echo "Saving the database"
                mysqldump -u $DB_USER_NAME -p$DB_PASS --single-transaction $DB_NAME | gzip > $DBSAVE_FOLDER/db_$(date +%a-%d-%m-%Y-%S).sql.gz
                cok "Magento database saved to $DBSAVE_FOLDER"
                chmod 640 $DBSAVE_FOLDER/*
				echo
			echo
        fi
  else
         cinfo "No backup created"
fi
echo
cecho "============================================================================="
echo
# Just compressing files to tmp
echo -n "---> CHECKPOINT 2. Backup your shop files now? [y/n][n]: "
read back_files
	if [ "$back_files" == "y" ];then
	SHOP_PATH=$(cat ~/mascm/.mascm_index | grep webshop | awk '{print $3}')
	cecho "Compressing the backup."
	tar -cvpzf  /tmp/shop_$(date +%a-%d-%m-%Y-%S).tar.gz  $SHOP_PATH
	cecho "Site backup compressed."
	echo
	fi
echo
# Creating cron to S3
echo -n "---> Download backup files and database and add S3 to cron? [y/n][n]: "
read s3_now
	if [ "$s3_now" == "y" ];then
	DB_HOST=$(cat ~/mascm/.mascm_index | grep database | awk '{print $2}')
	DB_NAME=$(cat ~/mascm/.mascm_index | grep database | awk '{print $3}')
	DB_USER_NAME=$(cat ~/mascm/.mascm_index | grep database | awk '{print $4}')
	DB_PASS=$(cat ~/mascm/.mascm_index | grep database | awk '{print $5}')
	DBSAVE_FOLDER=$(cat ~/mascm/.mascm_index| grep dump | awk '{print $2}')
	SHOP_PATH=$(cat ~/mascm/.mascm_index | grep webshop | awk '{print $3}')
	echo
		echo -n "---> Create your new bucket now? [y/n][n]: "
		read s3_bucket_new
	if [ "$s3_bucket_new" == "y" ];then
		cecho "CREATE YOUR BUCKET UNIQUE NAME"
		read -p "---> Confirm your S3 bucket name for files: " S3_BUCKET
		s3cmd mb s3://$S3_BUCKET
	else
		echo
		read -p "---> Confirm your S3 bucket name: " S3_BUCKET
	fi
		cecho "CREATING CRON DATA TO USE AUTO-BACKUP TO S3"	
		cecho "Magento files auto-backup..."
cat > ~/mascm/S3_AB_FILES_CRON.sh <<END
#!/bin/bash
echo "Compressing the backup."
tar -cvpzf  /tmp/shop_$(date +%a-%d-%m-%Y-%S).tar.gz  $SHOP_PATH
echo "Site backup compressed."
echo "Uploading the new site backup..."
s3cmd put /tmp/shop_*.tar.gz  s3://$S3_BUCKET
echo "Backup uploaded."
find  /tmp/shop_*.tar.gz -type f -exec rm {} \;
cecho "Removing the cache files..."
cecho "Files removed."
cok "All done."
END
	
	cecho "Magento database auto-backup..."
cat > ~/mascm/S3_AB_DB_CRON.sh <<END
#!/bin/bash
echo "Compressing the backup."
mysqldump -u $DB_USER_NAME -p$DB_PASS --single-transaction $DB_NAME | gzip > $DBSAVE_FOLDER/db_$(date +%a-%d-%m-%Y-%S).sql.gz
echo "Uploading database dump..."
s3cmd put $DBSAVE_FOLDER/db_*.tar.gz  s3://$S3_BUCKET
echo "Backup uploaded."
END
	
	cok "WRITING DATA TO CRON"
	#write out current crontab
	crontab -l > magecron
	#echo new cron into cron file
	echo "0 0 * * 0 sh ~/mascm/S3_AB_FILES_CRON.sh" >> magecron
	echo "0 5 * * * sh ~/mascm/S3_AB_DB_CRON.sh" >> magecron
	#install new cron file
	crontab magecron
	rm magecron
	crontab -l
	echo
	cecho "Edit crontab if you need different settings"
	echo
	fi	
echo
cecho "PLEASE DOWNLOAD YOUR CHECKPOIN BACKUPS MANUALLY WITH FTP CLIENT"
cecho "at /tmp/shop_*.tar.gz and $DBSAVE_FOLDER/db_*.tar.gz"
echo
cwarn "Then run this cleanup tool:"
echo
echo -n "---> Cleanup your local temporary backup? [y/n][n]: "
	read s3_tmp_rm
	if [ "$s3_tmp_rm" == "y" ];then
	# remove
		find  /tmp/shop_*.tar.gz -type f -exec rm {} \;
		find  $DBSAVE_FOLDER/db_*.tar.gz -type f -exec rm {} \;
	cecho "Removing the cache files..."
	cecho "Files removed."
	cok "All done."
	fi
echo
echo
pause '---> Press [Enter] key to show menu'
;;
###################################################################################
#                               SECURE YOUR SERVER                                #
###################################################################################
"protect")
cecho =============================================================================
echo
cecho "NOW WE PROTECT YOUR SERVER"
cok "replacing the root user with a new user"
echo
echo -n "---> Generate a password for the new user? [y/n][n]:"
read new_rpass_gen
if [ "$new_rpass_gen" == "y" ];then
        NEW_ROOT_PASSGEN=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9~!@#$%^&*-_' | fold -w 15 | head -n 1)
                cecho "Password: \033[01;31m $NEW_ROOT_PASSGEN"
                cok "!REMEMBER IT AND KEEP IT SAFE!"
				echo
		fi
echo
echo -n "---> Create your new user? [y/n][n]:"
read new_root_user
if [ "$new_root_user" == "y" ];then
        read -p "---> Enter the new user name: " NEW_ROOT_NAME
		echo "$NEW_ROOT_NAME   ALL=(ALL)       ALL" >> /etc/sudoers
		adduser $NEW_ROOT_NAME
	    passwd $NEW_ROOT_NAME
        fi
echo
echo -n "---> Change ssh setting snow? [y/n][n]:"
read new_ssh_set
if [ "$new_ssh_set" == "y" ];then
		cp /etc/ssh/sshd_config /etc/ssh/sshd_config.BACK
        read -p "---> Enter a new ssh port(9500-65000) : " NEW_SSH_PORT
		sed -i "s/#Port 22/Port $NEW_SSH_PORT/g" /etc/ssh/sshd_config
		sed -i 's/#PermitRootLogin no/PermitRootLogin no/g' /etc/ssh/sshd_config
		sed -i 's/#PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
if [ -f /etc/fail2ban/jail.conf ]
then
    cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.conf.BACK
    sed -i "s/port=ssh/port=$NEW_SSH_PORT/" /etc/fail2ban/jail.conf
	cok "fail2ban jail has been changed"
fi
		cok "ssh port has been changed ok"
		cok "Root login DISABLED"
		service sshd restart
		netstat -tulnp | grep sshd
        fi
echo
echo
cwarn "!IMPORTANT: OPEN NEW SSH SESSION AND TEST YOUR ACCOUNT!"
echo
echo -n "---> Have you logged in? [y/n][n]:"
read new_ssh_test
if [ "$new_ssh_test" == "y" ];then
    if [ -f /etc/fail2ban/jail.conf ]
then
    service fail2ban restart
fi
	cok "REMEMBER YOUR PORT: $NEW_SSH_PORT, LOGIN: $NEW_ROOT_NAME AND PASSWORD $NEW_ROOT_PASSGEN"
	else
	mv /etc/ssh/sshd_config.BACK /etc/ssh/sshd_config
	cwarn "Writing your ssh_config back ... \033[01;32m ok"
	service sshd restart
	    if [ -f /etc/fail2ban/jail.conf ]
then
    mv /etc/fail2ban/jail.conf.BACK /etc/fail2ban/jail.conf
    service fail2ban restart
fi
	cok "ssh port changed ok"
    cok "Root login ENABLED"
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
cecho "============================================================================="
echo
echo -n "---> Do you want to install CSF firewall? [y/n][n]:"
read csf_test
if [ "$csf_test" == "y" ];then
# INSTALLING CSF FIREWALL
echo
	cok "DOWNLOADING CSF FIREWALL"
		cd
		echo
			echo -n "     PROCESSING  "
            quick_progress &
            pid="$!"
			wget -qO - http://www.configserver.com/free/csf.tgz | tar -xzp
			stop_progress "$pid"
				echo
			cd csf
				cok "NEXT, TEST WHETHER YOU HAVE THE REQUIRED IPTABLES MODULES"
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
				cok "Installing perl modules"
				echo
				echo -n "     PROCESSING  "
				start_progress &
				pid="$!"
				yum -q -y install perl-libwww-perl perl-Time-HiRes >/dev/null 2>&1
				stop_progress "$pid"
                rpm  --quiet -q perl-libwww-perl perl-Time-HiRes
                if [ "$?" = 0 ]
                    then
                    cok "INSTALLED OK"
					else
                    cwarn "ERROR"
					exit
                fi
				echo
				cok "Running CSF installation"
				echo
				echo -n "     PROCESSING  "
				quick_progress &
				pid="$!"
				sh install.sh >/dev/null 2>&1
				stop_progress "$pid"
				cok "INSTALLED OK"
				echo
	if [ -f /etc/fail2ban/jail.conf ]
	then
	cecho "Edit /etc/fail2ban/jail.conf [ssh-iptables] to 'enabled  = false', then restart fail2ban"
	fi
	fi
fi
echo
echo
pause '---> Press [Enter] key to show menu'
;;
"exit")
cwarn "------> Hasta la vista, baby..."
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
