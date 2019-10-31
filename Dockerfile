FROM debian

ENV DEBIAN_FRONTEND noninteractive
ARG VERSION=3.0

WORKDIR /usr/local/src

RUN apt-get update -qq && apt-get -y -q upgrade \
	&& apt-get install -y libpq-dev libpq5 git libssl-dev librabbitmq-dev \
    build-essential bison flex m4 pkg-config libncurses5-dev libxml2-dev libmicrohttpd-dev

RUN git clone https://github.com/OpenSIPS/opensips.git -b $VERSION opensips_$VERSION
RUN cd opensips_$VERSION \
    && make prefix="/opensips" include_modules="db_postgres tls_mgm proto_tls proto_wss xcap presence presence_xml httpd event_rabbitmq" all \
    && make prefix="/opensips" include_modules="db_postgres tls_mgm proto_tls proto_wss xcap presence presence_xml httpd event_rabbitmq" install \
    && rm -rf /opensips/share/doc \
    && rm -rf /opensips/share/man


FROM debian
LABEL maintainer="Vitaly Kovalyshyn"

ENV REFRESHED_AT 2019-10-31
ENV WEBITEL_MAJOR 19
ENV VERSION 3.0

RUN apt-get update && apt-get -y upgrade\
    && apt-get install --no-install-recommends --no-install-suggests -y -q postgresql-client \
    librabbitmq4 libxml2 rsyslog curl libmicrohttpd12 sngrep \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --from=0 /opensips /opensips

WORKDIR /opensips
COPY docker-entrypoint.sh sbin/
COPY opensips.cfg etc/opensips/

ENTRYPOINT ["sbin/docker-entrypoint.sh"]
CMD ["opensips"]
