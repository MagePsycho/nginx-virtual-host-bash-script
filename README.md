# Nginx Virtual Host Creator (Magento 1, Magento 2, WordPress)

This Script creates Nginx virtual host for different applications.
Supported Applications:
 - ~~Magento 1~~
 - Magento 2
 - ~~WordPress~~
 - ~~Others~~


## INSTALL
To install, simply download the script file and give it the executable permission.
```
curl -O vhost-nginx.sh https://raw.githubusercontent.com/MagePsycho/nginx-virtual-host-bash-script/master/src/vhost-nginx.sh
chmod +x vhost-nginx.sh
```

To make it system wide command
```
sudo mv vhost-nginx.sh /usr/local/bin/vhost-nginx
```
OR 
```
mv vhost-nginx.sh ~/bin/vhost-nginx
```
Make sure your `$HOME/bin` folder is in executable path

## USAGE
### To display help
```
sudo ./vhost-nginx.sh --help
```

### To Create Virtual Host for Magento 2
```
sudo ./vhost-nginx.sh --domain=magento223ce.local --app=magento2 --root-dir=/var/www/magento2/magento223ce
```

**Notes**
 - In case of system-wide command, you can omit the `--root-dir` parameter if you run the command from the root directory of application. 

## Screenshots
![Nginx Virtual Host Creator Help](https://github.com/MagePsycho/nginx-virtual-host-bash-script/raw/master/docs/nginx-virtual-host-bash-script-help.png "Nginx Virtual Host Creator Help")
Screentshot - Nginx Virtual Host Creator Help

![Nginx Virtual Host Creator Result](https://github.com/MagePsycho/nginx-virtual-host-bash-script/raw/master/docs/nginx-virtual-host-bash-script-result.png "Nginx Virtual Host Creator Result")
Screentshot - Nginx Virtual Host Creator Result

## RoadMap
 - Support multiple applications (Magento 1, WordPress etc.)
 - Option to configure virtual host template from separate file.
 - Option to add SSL configuration