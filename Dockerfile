FROM registry.access.redhat.com/ubi7/ubi:7.8

# install apache httpd
RUN yum --disableplugin=subscription-manager -y install httpd \
  && yum --disableplugin=subscription-manager clean all

RUN chgrp -R 0 /var/log/httpd /var/run/httpd \
  && chmod -R g=u /var/log/httpd /var/run/httpd

# copy configs to container
COPY conf /etc/httpd/conf
COPY conf.d /etc/httpd/conf.d
COPY conf.dispatcher.d /etc/httpd/conf.dispatcher.d
COPY conf.modules.d /etc/httpd/conf.modules.d
# provide AMS dispatcher environment variables to apache
COPY envvars /etc/sysconfig/httpd

# download dispatcher module
RUN curl -s https://download.macromedia.com/dispatcher/download/dispatcher-apache2.4-linux-x86_64-4.3.3.tar.gz -O
RUN mkdir dispatcher
RUN tar -C dispatcher -zxvf dispatcher-apache2.*.tar.gz
# copy and rename dispatcher module
RUN cp ./dispatcher/dispatcher-apache2.*.so /etc/httpd/modules/
RUN ln -s /etc/httpd/modules/dispatcher-apache2.*.so /etc/httpd/modules/mod_dispatcher.so

# uncomment the below two lines to provide your own dispatcher module instead of cURLing it above
# COPY mod_dispatcher.so /etc/httpd/modules/mod_dispatcher.so
# RUN chmod 644 /etc/httpd/modules/mod_dispatcher.so

# enable dispatcher debug logging
RUN sed -i 's/Define DISP_LOG_LEVEL info/Define DISP_LOG_LEVEL debug/' /etc/httpd/conf.d/variables/ams_default.vars

# disable SSL on author and publish instances
RUN sed -i 's/PUBLISH_FORCE_SSL 1/PUBLISH_FORCE_SSL 0/' /etc/httpd/conf.d/variables/ams_default.vars \
  && sed -i 's/AUTHOR_FORCE_SSL 1/AUTHOR_FORCE_SSL 0/' /etc/httpd/conf.d/variables/ams_default.vars

# create cache directories
RUN mkdir /var/www/author && chown -R apache /var/www/author
RUN mkdir /var/www/default && chown -R apache /var/www/default
RUN mkdir -p /mnt/var/www && chown -R apache /var/www/html

# create symlinks to /mnt 
RUN ln -s /var/www/html /mnt/var/www/html
RUN ln -s /var/www/author /mnt/var/www/author
RUN ln -s /var/www/default /mnt/var/www/default

# start apache
CMD apachectl && tail -F /etc/httpd/logs/dispatcher.log
