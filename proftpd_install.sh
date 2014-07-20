###################################################################################
#                          INSTALLING PROFTPD SERVER                              #
###################################################################################
"proftpd")
cecho "============================================================================="
echo
echo -n "---> Do you want to install ProFTPd server now? [y/n][n]:"
read install_proftpd
if [ "$install_proftpd" == "y" ];then
          echo
            read -p "---> Enter the latest version number (1.3.5) : " PROFTPD_VER
            echo
            cok "Downloading ProFTPd latest ${PROFTPD_VER} archive"
            echo
            mkdir -p /usr/local/src/proftpd && cd $_
            echo -n "     PROCESSING  "
            start_progress &
            pid="$!"
            wget -qO - ftp://ftp.proftpd.org/distrib/source/proftpd-${PROFTPD_VER}.tar.gz | tar -xzp --strip 1
            stop_progress "$pid"
            echo
            ./configure  --enable-openssl --enable-nls --enable-ctrls --with-modules=mod_sftp:mod_geoip:mod_ban:mod_vroot >/dev/null 2>&1
            make >/dev/null 2>&1
            make install >/dev/null 2>&1
            read -e -p "---> Enter your servers external ip: " -i "9521"  PROFTPD_PORT
			read -e -p "---> Enter your servers external ip: " -i "54.234.56.89"  PROFTPD_MASC_IP
			read -e -p "---> Enter your GeoIP country code: " -i "(ES|IE)"  PROFTPD_GEO_CODE
			read -e -p "---> Enter your whitelist client ip: " -i "54.234.56.89 54.234.56.0/24"  PROFTPD_CLIENT_IP
			echo
            sed -i "s/server_sftp_port/${PROFTPD_PORT}/" /etc/proftpd.conf 
			sed -i "s/server_ip_address/${PROFTPD_MASC_IP}/" /etc/proftpd.conf 
			sed -i "s/geoip_country_code/${PROFTPD_GEO_CODE}/" /etc/proftpd.conf
			sed -i "s/client_ip_address/${PROFTPD_CLIENT_IP}/" /etc/proftpd.conf
			echo
            cp /usr/local/src/proftpd/contrib/dist/rpm/proftpd.init.d  /etc/init.d/proftpd && chmod +x $_
			chkconfig --add proftpd && chkconfig proftpd on
			#mkdir -p /etc/ssl/certs/proftpd/keys && cd $_
			#ssh-keygen -q -t rsa -f ./sftp_rsa -N '' && ssh-keygen -q -t dsa -f ./sftp_dsa -N ''
            echo			
fi
echo
echo
pause '---> Press [Enter] key to show menu'