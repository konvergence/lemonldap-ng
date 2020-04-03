FROM ubuntu:16.04

# dpkg no interactive mode
ENV DEBIAN_FRONTEND noninteractive

ENV SSODOMAIN=example.com \
    PORTAL_URI=auth.example.com \
    MANAGER_URI=manager.example.com \
    RELOAD_URI=reload.example.com \
    HTTPSCHEME=https \
    HTTPPORT=443 \
    HTTPS=on

# Add Tini
ARG TINI_VERSION="v0.18.0"
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

#  apt-cache madison lemonldap-ng
ARG LLPNG_VERSION="2.0.7-1"

# install perl and apache2
RUN apt-get update \
&& echo "#Install install perl and apache2" \
    && apt-get install -y apache2 libapache2-mod-perl2 libapache2-mod-fcgid libapache-session-perl libnet-ldap-perl libcache-cache-perl libdbi-perl perl-modules libwww-perl libxml-simple-perl libsoap-lite-perl libhtml-template-perl libregexp-assemble-perl libregexp-common-perl libjs-jquery libxml-libxml-perl libcrypt-rijndael-perl libio-string-perl libxml-libxslt-perl libconfig-inifiles-perl libjson-perl libstring-random-perl libemail-date-format-perl libmime-lite-perl libcrypt-openssl-rsa-perl libdigest-hmac-perl libdigest-sha-perl libclone-perl libauthen-sasl-perl libnet-cidr-lite-perl libcrypt-openssl-x509-perl libauthcas-perl libtest-pod-perl libtest-mockobject-perl libauthen-captcha-perl libnet-openid-consumer-perl libnet-openid-server-perl libunicode-string-perl libconvert-pem-perl libmoose-perl libplack-perl libapache-session-browseable-perl libdbd-pg-perl \
	                      libconvert-base32-perl \
						  liblasso-perl \
&& echo "#Install install lemonldap-ng" \
    && apt-get install -y apt-transport-https \
            ca-certificates \
            software-properties-common \
            curl \
            gnupg2 \
            gettext-base \
    && curl -fsSL https://lemonldap-ng.org/_media/rpm-gpg-key-ow2 | apt-key add - \
    && add-apt-repository "deb  https://lemonldap-ng.org/deb stable main" \
    && apt-get update \
    && apt-get install -y lemonldap-ng=${LLPNG_VERSION} \
&& echo "# Remove cached configuration" \
     && rm -rf /tmp/lemonldap-ng-config   \
     && rm -fr /var/lib/apt/lists/*

RUN echo "# Enable module ssl fcgid perl alias rewrite headers" \
    && a2enmod ssl fcgid perl alias rewrite headers

##&& echo "# Enable site for lemonldap-ng" \
##  && a2ensite manager-apache2.conf portal-apache2.conf handler-apache2.conf  test-apache2.conf

COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY llng-init-conf-ad.dist /llng-init-conf-ad.dist


RUN  mkdir -p /var/lib/lemonldap-ng/common \
    && cd /usr/share/lemonldap-ng/portal/htdocs/static/common \
    && mv backgrounds  /var/lib/lemonldap-ng/common \
    && mv logos  /var/lib/lemonldap-ng/common \
    && cd /usr/share/lemonldap-ng/portal/htdocs/static/common/ \
    && ln -s /var/lib/lemonldap-ng/common/logos logos \
    && ln -s /var/lib/lemonldap-ng/common/backgrounds backgrounds

ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin


# specific regexp for lemonldap 2.0.7 Access Rule on manager uri
#  format is (?#Commentary)/(rule)
ENV LDAP_ENABLED=false \
    MANAGER_ACLRULE_CONFIGURATION='(?#Configuration)^/(.*?\.(fcgi|psgi)/)?(manager\.html|confs/|$)' \
    MANAGER_ACLRULE_NOTIFICATION='(?#Notifications)/(.*?\.(fcgi|psgi)/)?notifications' \
    MANAGER_ACLRULE_SESSION='(?#Sessions)/(.*?\.(fcgi|psgi)/)?sessions'



WORKDIR /root


# Metadata
EXPOSE 80 443
VOLUME [ "/var/lib/lemonldap-ng", "/etc/lemonldap-ng" ]

ENTRYPOINT [ "/tini", "--", "bash", "/docker-entrypoint.sh" ]
CMD [ "/usr/sbin/apache2ctl", "-D", "FOREGROUND" ]
