FROM registry.access.redhat.com/ubi8/ubi:latest

ENV LOCAL_REGISTRY_VERSION='2.8.0'
ENV LOCAL_REGISTRY_ARCH='amd64'

ADD "https://github.com/distribution/distribution/releases/download/v${LOCAL_REGISTRY_VERSION}/registry_${LOCAL_REGISTRY_VERSION}_linux_${LOCAL_REGISTRY_ARCH}.tar.gz" registry.tar.gz
RUN set -eux; \
	tar --extract --verbose --file registry.tar.gz --directory /bin/ registry; \
	rm registry.tar.gz; \
	registry --version

RUN mkdir /openshift-clients
WORKDIR  /openshift-clients
ADD "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux.tar.gz" openshift-client-linux.tar.gz
ADD "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/opm-linux.tar.gz" opm-linux.tar.gz
RUN tar -xvzf openshift-client-linux.tar.gz; tar -xvzf opm-linux.tar.gz; mv oc kubectl opm /usr/bin; rm -rf /openshift-clients

ARG ai_version
WORKDIR /

RUN dnf install -yy skopeo
RUN mkdir -p /var/lib/registry
COPY ./config-example.yml /etc/docker/registry/config.yml
COPY docker-entrypoint.sh /entrypoint.sh

EXPOSE 5000
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/etc/docker/registry/config.yml"]

