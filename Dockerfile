FROM archlinux
RUN pacman -Syu apache rrdtool fping gcc make c-ares inetutils --noconfirm
RUN useradd xymon --create-home
COPY ./xymon-4.3.29.tar.gz /root
RUN tar xf /root/xymon-4.3.29.tar.gz -C /home/xymon
WORKDIR /home/xymon/xymon-4.3.29
COPY Makefile ./
RUN make && make install
WORKDIR /home/xymon
RUN cp server/etc/xymon-apache.conf /etc/httpd/conf/extra/
RUN echo -e "\nLoadModule rewrite_module modules/mod_rewrite.so\nInclude conf/extra/xymon-apache.conf" >> /etc/httpd/conf/httpd.conf
ENTRYPOINT /usr/sbin/apachectl -D FOREGROUND && su - xymon -c /home/xymon/server/bin/xymon.sh start
EXPOSE 80