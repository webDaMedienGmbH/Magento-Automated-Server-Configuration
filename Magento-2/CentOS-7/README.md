

do not edit core files!<br/><br/>
Magento 2 intalled per documentation:<br/>
http://devdocs.magento.com/guides/v2.0/install-gde/prereq/integrator_install.html

full webstack configuration = php7, nginx, hhvm, varnish, percona, redis, memcached, proftpd, csf firewall, clamav scanner, images optimization, opcache invalidation, logrotate, webmin control panel.

<br/><br/>
ready for production right after installation!

<br/>
to create server template:<br/>
1. configure your server with `MASC-M-7-v2.sh`<br/>
2. add `reset_server_m2.sh` to `/root/` and `chmod +x`<br/>
3. execute in `~/.bash_profile` after login <br/>
```
if [ -f /root/.reset_server_m2.sh ]; then
        /root/.reset_server_m2.sh
fi
```
