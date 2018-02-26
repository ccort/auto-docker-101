FROM ubuntu:16.04

# Install dependencies
RUN apt-get update \
    && apt-get install -y --force-yes --no-install-recommends g++ make expat libexpat1-dev zlib1g-dev curl wget osmium-tool bzip2 apache2

# Assigning Environmental variables
ARG OSM_VER=0.7.54
ENV EXEC_DIR=/srv/osm3s
ENV DB_DIR=/srv/osm3s/db

# Compiling overpass engine
RUN curl -o osm-3s_v$OSM_VER.tar.gz http://dev.overpass-api.de/releases/osm-3s_v$OSM_VER.tar.gz \
  && tar -zxvf osm-3s_v${OSM_VER}.tar.gz \
  && cd osm-3s_v* \
  && ./configure CXXFLAGS="-O2" --prefix="$EXEC_DIR" \
  && make install

# Setting up apache configurations and modules
RUN a2enmod cgi \
    && a2enmod ext_filter \
    # Disable ServerName warning
    && echo "ServerName localhost" | tee /etc/apache2/conf-available/servername.conf \
    && a2enconf servername

# Copying vhost for overpass
COPY ./vhost.conf /etc/apache2/sites-available/ov.conf

RUN a2ensite ov 
RUN a2dissite 000-default

ARG PLANET_FILE=/mexico_small.osm
RUN wget -O "$PLANET_FILE" https://overpass-api.de/api/map?bbox=-99.6185,19.0725,-98.6023,19.8649 --no-check-certificate

RUN mkdir -p "$DB_DIR/"
RUN cat "$PLANET_FILE" | /srv/osm3s/bin/update_database --db-dir=$DB_DIR/ --meta

CMD service apache2 start && $EXEC_DIR/bin/dispatcher --osm-base --meta --db-dir=$DB_DIR
# CMD service apache2 start
