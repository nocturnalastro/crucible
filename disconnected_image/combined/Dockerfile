FROM descon_registry AS BUILD

FROM descon_httpd AS BUILD2

COPY --from=BUILD /bin/registry /bin/registry
COPY --from=BUILD /etc/docker/registry/config.yml /etc/docker/registry/config.yml
COPY --from=BUILD /entrypoint.sh /entrypoint.sh
COPY ./run_combined.sh /run.sh
RUN ls -l /entrypoint.sh /bin/registry

FROM scratch
COPY --from=BUILD2 / /
RUN ls -l /entrypoint.sh /bin/registry

EXPOSE 5000
EXPOSE 80

ENTRYPOINT [ "/run.sh" ]