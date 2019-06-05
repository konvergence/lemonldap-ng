#!/bin/bash

export HTTPSCHEME=${HTTPSCHEME:-https}

echo "Work in progress $SSODOMAIN"

if ! grep "ServerName" /etc/apache2/apache2.conf ; then
    echo "ServerName $SSODOMAIN" >> /etc/apache2/apache2.conf
else
   sed -i "s/ServerName .*/ServerName $SSODOMAIN/" /etc/apache2/apache2.conf
fi

find /etc/apache2/sites-available/ -name '*.conf' ! -name '000-default.conf'  -exec ln -sf {} /etc/apache2/sites-enabled/ \;

if [ ! -f /var/lib/lemonldap-ng/test/index.pl.ori ]; then
    cp /var/lib/lemonldap-ng/test/index.pl /var/lib/lemonldap-ng/test/index.pl.ori
    sed -i "s/example\.com/${SSODOMAIN}/g" /var/lib/lemonldap-ng/test/index.pl
    sed -i "s/auth\.${SSODOMAIN}/${PORTAL_URI}/g" /var/lib/lemonldap-ng/test/index.pl
    sed -i "s/manager\.${SSODOMAIN}/${MANAGER_URI}/g" /var/lib/lemonldap-ng/test/index.pl
    sed -i "s/reload\.${SSODOMAIN}/${RELOAD_URI}/g" /var/lib/lemonldap-ng/test/index.pl
fi


if [ ! -d /etc/lemonldap-ng/ori ]; then
    mkdir /etc/lemonldap-ng/ori
    cp /etc/lemonldap-ng/* /etc/lemonldap-ng/ori

    sed -i "s/example\.com/${SSODOMAIN}/g" /etc/lemonldap-ng/*.conf /etc/lemonldap-ng/*.ini
    
    # force https if need
    sed -i "s/http:/${HTTPSCHEME}:/g" /etc/lemonldap-ng/*.conf /etc/lemonldap-ng/*.ini
    sed -i "s/:80/:${HTTPPORT}/g"  /etc/lemonldap-ng/*.conf /etc/lemonldap-ng/*.ini
    
    #change URI if need
    sed -i "s/auth\.${SSODOMAIN}/${PORTAL_URI}/g" /etc/lemonldap-ng/*.conf /etc/lemonldap-ng/*.ini
    sed -i "s/manager\.${SSODOMAIN}/${MANAGER_URI}/g" /etc/lemonldap-ng/*.conf /etc/lemonldap-ng/*.ini
    sed -i "s/reload\.${SSODOMAIN}/${RELOAD_URI}/g" /etc/lemonldap-ng/*.conf /etc/lemonldap-ng/*.ini
fi



if [ ! -d /var/lib/lemonldap-ng/conf/ori ]; then
    mkdir  /var/lib/lemonldap-ng/conf/ori
    cp /var/lib/lemonldap-ng/conf/lmConf-1.js*  /var/lib/lemonldap-ng/conf/ori/

    sed -i "s/example\.com/${SSODOMAIN}/g" /var/lib/lemonldap-ng/conf/lmConf-1.js* 
    
    # force https if need
    sed -i "s/http:/${HTTPSCHEME}:/g" /var/lib/lemonldap-ng/conf/lmConf-1.js*
    sed -i "s/:80/:${HTTPPORT}/g"  /var/lib/lemonldap-ng/conf/lmConf-1.js*
    
    #change URI if need
    sed -i "s/auth\.${SSODOMAIN}/${PORTAL_URI}/g" /var/lib/lemonldap-ng/conf/lmConf-1.js*
    sed -i "s/manager\.${SSODOMAIN}/${MANAGER_URI}/g" /var/lib/lemonldap-ng/conf/lmConf-1.js*
    sed -i "s/reload\.${SSODOMAIN}/${RELOAD_URI}/g" /var/lib/lemonldap-ng/conf/lmConf-1.js* 
fi

echo "Start llng for $SSODOMAIN"


exec "$@"
