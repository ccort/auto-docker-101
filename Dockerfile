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






CMD service apache2 start
