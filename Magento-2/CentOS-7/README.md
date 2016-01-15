
beta
to avoid any permission issues, make sure your files are readable for php and nginx.<br/>

```
chmod +x bin/magento
su <files_owner> -s /bin/bash -c "bin/magento setup:static-content:deploy"
find . -type f -exec chmod 644 {} \;
find . -type d -exec chmod 755 {} \;
chmod +x cron_check.sh images_opt.sh zend_opcache.sh wesley.pl bin/magento pub/cron.php
chown -R <files_owner>:<files_owner> *
```

or at least make sure nginx is in the same group...<br/>
do not edit core files!
