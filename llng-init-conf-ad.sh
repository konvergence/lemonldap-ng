envsubst '${SSODOMAIN} ${LDAP_ATTR_LOGIN} ${LDAP_BASE} ${LDAP_BINDDN} ${LDAP_BINDPWD} ${LDAP_PORT} ${LDAP_URL} ${LLNG_GROUP_ADMIN} ${LLNG_UID_ADMIN} ${PORTAL_URI} ${MANAGER_URI} ${RELOAD_URI}' < /llng-init-conf-ad.dist > /tmp/llng-init-conf-ad.sh
bash /tmp/llng-init-conf-ad.sh