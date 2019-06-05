# lemonldap-ng
Based on https://hub.docker.com/r/coudot/lemonldap-ng
official web site :  https://lemonldap-ng.org/welcome/

Add HTTPSCHEME to be able to make SSL Offloading

define following variables on docker-compose.yml to fixe domain and URIs 
    SSODOMAIN=example.com
    PORTAL_URI=auth.example.com
    MANAGER_URI=manager.example.com
    RELOAD_URI=reload.example.com

define following variables to config LDAP authentication
    LDAP_ATTR_LOGIN: sAMAccountName
    LDAP_BASE: DC=example,DC=com
    LDAP_BINDDN: CN=bind,OU=Users,OU=FRANCE,DC=example,DC=com
    LDAP_BINDPWD: SuperSecretPassword
    LDAP_PORT: '389'
    LDAP_URL: ldap://yourldapserver
    LLNG_GROUP_ADMIN: IAM_Admins
    LLNG_UID_ADMIN: rootaccount


    then run /llng-init-conf-ad.sh first time