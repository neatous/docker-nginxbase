FROM debian:bullseye
MAINTAINER Martin Venuš <martin.venus@neatous.cz>

RUN apt-get update && \
    apt-get -y purge openssl && \
    apt-get -y install \
               build-essential \
               gnupg2 \
               gzip \
               libbz2-dev \
               libpcre3 \
               libpcre3-dev \
               libssl-dev \
               tar \
               wget \
               zlib1g-dev

RUN mkdir /sourcetmp

RUN cd /sourcetmp && \
    wget https://www.openssl.org/source/openssl-3.1.0.tar.gz && \
    tar -xzvf openssl-3.1.0.tar.gz

RUN cd /sourcetmp && \
    wget -q -O headers-more-nginx-module.tar.gz https://github.com/openresty/headers-more-nginx-module/archive/v0.34.tar.gz && \
    tar xzf headers-more-nginx-module.tar.gz && \
    cd headers-more-nginx-module-0.34

RUN mkdir /var/log/nginx /var/cache/nginx

RUN cd /sourcetmp && \
    wget -q https://nginx.org/download/nginx-1.23.3.tar.gz && tar xzf nginx-1.23.3.tar.gz && cd nginx-1.23.3 && ./configure \
      --prefix=/etc/nginx \
      --with-cc-opt="-O3 -fPIE -fstack-protector-strong -Wformat -Werror=format-security" \
      --with-ld-opt="-Wl,-Bsymbolic-functions -Wl,-z,relro" \
      --with-openssl-opt="no-weak-ssl-ciphers no-ssl3 no-shared $ecflag -DOPENSSL_NO_HEARTBEATS -fstack-protector-strong" \
      --with-openssl="/sourcetmp/openssl-3.1.0" \
      --sbin-path=/usr/sbin/nginx \
      --modules-path=/usr/lib/nginx/modules \
      --conf-path=/etc/nginx/nginx.conf \
      --error-log-path=/var/log/nginx/error.log \
      --http-log-path=/var/log/nginx/access.log \
      --pid-path=/var/run/nginx.pid \
      --lock-path=/var/run/nginx.lock \
      --http-client-body-temp-path=/var/cache/nginx/client_temp \
      --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
      --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
      --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
      --with-http_ssl_module \
      --with-http_realip_module \
      --with-http_addition_module \
      --with-http_sub_module \
      --with-http_dav_module \
      --with-http_flv_module \
      --with-http_mp4_module \
      --with-http_gunzip_module \
      --with-http_gzip_static_module \
      --with-http_random_index_module \
      --with-http_secure_link_module \
      --with-http_stub_status_module \
      --with-http_auth_request_module \
#      --with-http_xslt_module=dynamic \
#      --with-http_image_filter_module=dynamic \
#      --with-http_geoip_module=dynamic \
      --with-threads \
      --with-stream \
      --with-stream_ssl_module \
      --with-stream_ssl_preread_module \
      --with-stream_realip_module \
#      --with-stream_geoip_module=dynamic \
      --with-http_slice_module \
      --with-mail \
      --with-mail_ssl_module \
      --with-compat \
      --with-file-aio \
      --with-http_v2_module \
      --add-module=/sourcetmp/headers-more-nginx-module-0.34 && \
    make -j ${NB_CORES} && \
    make install && \
    make clean

RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
	ln -sf /dev/stderr /var/log/nginx/error.log && \
	mkdir /etc/nginx/ssl

RUN rm /etc/nginx/nginx.conf

RUN apt-get -y purge \
               build-essential \
               wget

RUN apt-get -y autoremove

RUN rm -rf /sourcetmp

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /var/www/html

EXPOSE 443
ENTRYPOINT nginx
