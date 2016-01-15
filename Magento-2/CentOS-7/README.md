
beta
to avoid any permission issues, make sure your files are readable for php and nginx.<br/>

```
su <files_owner> -s /bin/bash -c "bin/magento setup:static-content:deploy"
find . -type f -exec chmod 644 {} \;
find . -type d -exec chmod 755 {} \;
```

or at least make sure nginx is in the same group...<br/>
do not edit core files!
