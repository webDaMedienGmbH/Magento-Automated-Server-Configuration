
beta<br/>
do not edit core files!<br/><br/>
Magento 2 intalled per documentation:<br/>
http://devdocs.magento.com/guides/v2.0/install-gde/prereq/integrator_install.html

full webstack configuration = php7, nginx, hhvm, varnish, percona, redis, proftpd, csf firewall, webmin control panel

<br/><br/>
ready for production right after installation!


to create server template:
1. configure your server with `MASC-M-7-v2.sh`
2. add `reset_server_m2.sh` to `/root/` and `chmod +x`
3. execute in `~/.bash_profile` after login 

```
if [ -f /root/.reset_server_m2.sh ]; then
        /root/.reset_server_m2.sh
fi
```
