FROM registry.access.redhat.com/ubi8/ubi:latest

RUN dnf install -y httpd
RUN rm /etc/httpd/conf.d/welcome.conf
COPY httpd.conf /etc/httpd/conf/httpd.conf 
ADD ./fetch.sh ./fetch.sh
ARG ocp_long_version
RUN set -e; ./fetch.sh "${ocp_long_version}" /var/www/html/
EXPOSE 80
ENTRYPOINT [ "bash" ]
CMD ["httpd", "-DFOREGROUND"]

 