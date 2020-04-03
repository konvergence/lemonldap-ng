#!/bin/bash

export HTTPSCHEME=${HTTPSCHEME:-https}


[ -z "$(ls -A /var/lib/lemonldap-ng)" ] && echo "error /var/lib/lemonldap-ng is empty" && exit -1
[ -z "$(ls -A /etc/lemonldap-ng)" ] && echo "error /etc/lemonldap-ng is empty" && exit -1

echo "Work in progress $SSODOMAIN"

if ! grep "ServerName" /etc/apache2/apache2.conf ; then
    echo "ServerName $SSODOMAIN" >> /etc/apache2/apache2.conf
else
   sed -i "s/ServerName .*/ServerName $SSODOMAIN/" /etc/apache2/apache2.conf
fi

find /etc/apache2/sites-available/ -name '*.conf' ! -name '000-default.conf'  -exec ln -sf {} /etc/apache2/sites-enabled/ \;



if [ ! -f /var/lib/lemonldap-ng/test/index.pl.ori ]; then
    echo update /var/lib/lemonldap-ng/test/index.pl
    cp /var/lib/lemonldap-ng/test/index.pl /var/lib/lemonldap-ng/test/index.pl.ori
    sed -i "s/auth\./$(echo ${PORTAL_URI} | cut -d '.' -f 1)\./g" /var/lib/lemonldap-ng/test/index.pl
    sed -i "s/manager\./$(echo ${MANAGER_URI}  | cut -d '.' -f 1)\./g" /var/lib/lemonldap-ng/test/index.pl
   # sed -i "s/example\.com/${SSODOMAIN}/g"  /var/lib/lemonldap-ng/test/index.pl
   # sed -i "s/reload\./$(echo ${RELOAD_URI}  | cut -d '.' -f 1)/g" /var/lib/lemonldap-ng/test/index.pl
fi


if [ ! -d /etc/lemonldap-ng/ori ]; then

    echo 'update /etc/lemonldap-ng/*.conf /etc/lemonldap-ng/*.ini'
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


# move logos and background link
    mkdir -p /var/lib/lemonldap-ng/common
    mv /usr/share/lemonldap-ng/portal/htdocs/static/common/backgrounds/  /var/lib/lemonldap-ng/common
    mv /usr/share/lemonldap-ng/portal/htdocs/static/common/logos  /var/lib/lemonldap-ng/common
    cd /usr/share/lemonldap-ng/portal/htdocs/static/common/ 
    ln -s /var/lib/lemonldap-ng/common/logos logos
    ln -s /var/lib/lemonldap-ng/common/backgrounds backgrounds



if [ "${LDAP_ENABLED}" = "true" ]; then
   echo update config with LDAP
    [ -z "${LDAP_BASE}" ] && echo error LDAP_BASE not defined && exit -1
    [ -z "${LDAP_BINDDN}" ] && echo error LDAP_BINDDN not defined && exit -1
    [ -z "${LDAP_BINDPWD}" ] && echo error LDAP_BINDPWD not defined && exit -1
    [ -z "${LDAP_URL}" ]  && echo error LDAP_URL not defined && exit -1
    [ -z "${LDAP_PORT}" ]  && echo error LDAP_PORT not defined && exit -1
    [ -z "${LLNG_GROUP_ADMIN}" ]  && echo error LLNG_GROUP_ADMIN not defined && exit -1
    [ -z "${LLNG_UID_ADMIN}" ] && echo error LLNG_UID_ADMIN not defined && exit -1


    envsubst '${SSODOMAIN} ${LDAP_ATTR_LOGIN} ${LDAP_BASE} ${LDAP_BINDDN} ${LDAP_BINDPWD} ${LDAP_PORT} ${LDAP_URL} ${LLNG_GROUP_ADMIN} ${LLNG_UID_ADMIN} ${PORTAL_URI} ${MANAGER_URI} ${RELOAD_URI} ${MANAGER_ACLRULE_CONFIGURATION} ${MANAGER_ACLRULE_NOTIFICATION} ${MANAGER_ACLRULE_SESSION}' < /llng-init-conf-ad.dist > /tmp/llng-init-conf-ad.sh

    bash /tmp/llng-init-conf-ad.sh
fi

echo "Start llng for $SSODOMAIN"


exec "$@"
