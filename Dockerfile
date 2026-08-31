FROM eclipse-mosquitto:2

COPY mosquitto/config/mosquitto.conf /mosquitto/config/mosquitto.conf
COPY --chmod=600 --chown=1883:1883 mosquitto/config/acl /mosquitto/config/acl
