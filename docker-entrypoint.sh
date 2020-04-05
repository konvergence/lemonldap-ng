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


echo update /var/lib/lemonldap-ng/test/index.pl
cp -fp /usr/share/lemonldap-ng/assets/test/index.pl /var/lib/lemonldap-ng/test/index.pl
sed  -i "s/auth\./$(echo ${PORTAL_URI} | cut -d '.' -f 1)\./g" /var/lib/lemonldap-ng/test/index.pl
sed  -i "s/manager\./$(echo ${MANAGER_URI}  | cut -d '.' -f 1)\./g" /var/lib/lemonldap-ng/test/index.pl


echo update /etc/lemonldap-ng/lemonldap-ng.ini and /etc/lemonldap-ng/*.conf
cp -fp /usr/share/lemonldap-ng/assets/etc/* /etc/lemonldap-ng/

sed -i "s/example\.com/${SSODOMAIN}/g" /etc/lemonldap-ng/*.conf /etc/lemonldap-ng/lemonldap-ng.ini

# force https if need
sed -i "s/http:/${HTTPSCHEME}:/g" /etc/lemonldap-ng/*.conf /etc/lemonldap-ng/lemonldap-ng.ini
sed -i "s/:80/:${HTTPPORT}/g"  /etc/lemonldap-ng/*.conf /etc/lemonldap-ng/lemonldap-ng.ini

#change URI if need
sed -i "s/auth\.${SSODOMAIN}/${PORTAL_URI}/g" /etc/lemonldap-ng/*.conf /etc/lemonldap-ng/lemonldap-ng.ini
sed -i "s/manager\.${SSODOMAIN}/${MANAGER_URI}/g" /etc/lemonldap-ng/*.conf /etc/lemonldap-ng/lemonldap-ng.ini
sed -i "s/reload\.${SSODOMAIN}/${RELOAD_URI}/g" /etc/lemonldap-ng/*.conf /etc/lemonldap-ng/lemonldap-ng.ini


#echo update /var/lib/lemonldap-ng/conf/lmConf-1.json
#cp -fp /usr/share/lemonldap-ng/assets/conf/lmConf-1.json /var/lib/lemonldap-ng/conf/lmConf-1.json
sed -i "s/example\.com/${SSODOMAIN}/g" /var/lib/lemonldap-ng/conf/lmConf-1.json

# force https if need
sed -i "s/http:/${HTTPSCHEME}:/g" /var/lib/lemonldap-ng/conf/lmConf-1.json
sed -i "s/:80/:${HTTPPORT}/g"  /var/lib/lemonldap-ng/conf/lmConf-1.json

#change URI if need
sed -i "s/auth\.${SSODOMAIN}/${PORTAL_URI}/g" /var/lib/lemonldap-ng/conf/lmConf-1.json
sed -i "s/manager\.${SSODOMAIN}/${MANAGER_URI}/g" /var/lib/lemonldap-ng/conf/lmConf-1.json
sed -i "s/reload\.${SSODOMAIN}/${RELOAD_URI}/g" /var/lib/lemonldap-ng/conf/lmConf-1.json


if [ ! -z "$CUSTOM_LOGO_URI" ]; then
   curl -s $CUSTOM_LOGO_URI -o /var/lib/lemonldap-ng/common/logos/$(basename $CUSTOM_LOGO_URI)
fi

if [ ! -z "$CUSTOM_BACKGROUND_URI" ]; then
   curl -s $CUSTOM_BACKGROUND_URI -o /var/lib/lemonldap-ng/common/backgrounds/$(basename $CUSTOM_BACKGROUND_URI)

   if grep -q portalSkinBackground /etc/lemonldap-ng/lemonldap-ng.ini; then
         sed -i "s/portalSkinBackground.*/portalSkinBackground =  $(basename $CUSTOM_BACKGROUND_URI)/" /etc/lemonldap-ng/lemonldap-ng.ini
   else
        startline=$(grep -n '\[portal\]' /etc/lemonldap-ng/lemonldap-ng.ini  | cut -d ':' -f1)
        sed -i "$(($startline + 1))iportalSkinBackground =  $(basename $CUSTOM_BACKGROUND_URI)" /etc/lemonldap-ng/lemonldap-ng.ini
   fi
fi



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
