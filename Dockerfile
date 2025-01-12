FROM registry.access.redhat.com/ubi8/ubi-minimal as builder

RUN microdnf -y install which go-toolset make
WORKDIR /opt/app-root/src
COPY . .
USER root
RUN make build
#COPY otelcol /otelcol
## Note that this shouldn't be necessary, but in some cases the file seems to be
## copied with the execute bit lost (see #1317)
RUN chmod 755 /opt/app-root/src/_build/otelcol

FROM registry.access.redhat.com/ubi8/ubi-minimal

# Install the systemd package which provides journalctl required by journald receiver.
# https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/receiver/journaldreceiver
RUN microdnf -y install systemd

ARG USER_UID=10001
USER ${USER_UID}

COPY --from=builder /opt/app-root/src/_build/otelcol /
COPY configs/otelcol.yaml /etc/otelcol/config.yaml
ENTRYPOINT ["/otelcol"]
CMD ["--config", "/etc/otelcol/config.yaml"]
EXPOSE 4317 55678 55679
