# =============================================================================
# jdeathe/centos-ssh
#
# CentOS-6 6.7 x86_64 - SCL/EPEL/IUS Repos. / Supervisor / OpenSSH.
# 
# =============================================================================
FROM centos:centos6.7

MAINTAINER James Deathe <james.deathe@gmail.com>

# -----------------------------------------------------------------------------
# Import the RPM GPG keys for Repositories
# -----------------------------------------------------------------------------
RUN rpm --import http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-6 \
	&& rpm --import https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-6 \
	&& rpm --import https://dl.iuscommunity.org/pub/ius/IUS-COMMUNITY-GPG-KEY

# -----------------------------------------------------------------------------
# Base Install
# -----------------------------------------------------------------------------
RUN rpm --rebuilddb \
	&& yum -y install \
	centos-release-scl \
	centos-release-scl-rh \
	epel-release \
	https://centos6.iuscommunity.org/ius-release.rpm \
	vim-minimal-7.4.629-5.el6 \
	sudo-1.8.6p3-20.el6_7 \
	openssh-5.3p1-112.el6_7 \
	openssh-server-5.3p1-112.el6_7 \
	openssh-clients-5.3p1-112.el6_7 \
	python-setuptools-0.6.10-3.el6 \
	yum-plugin-versionlock-1.1.30-30.el6 \
	&& yum versionlock add \
	vim-minimal \
	sudo \
	openssh \
	openssh-server \
	openssh-clients \
	python-setuptools \
	yum-plugin-versionlock \
	&& rm -rf /var/cache/yum/* \
	&& yum clean all

# -----------------------------------------------------------------------------
# Install supervisord (required to run more than a single process in a container)
# Note: EPEL package lacks /usr/bin/pidproxy
# We require supervisor-stdout to allow output of services started by 
# supervisord to be easily inspected with "docker logs".
# -----------------------------------------------------------------------------
RUN easy_install 'supervisor == 3.2.0' 'supervisor-stdout == 0.1.1' \
	&& mkdir -p /var/log/supervisor/

# -----------------------------------------------------------------------------
# UTC Timezone & Networking
# -----------------------------------------------------------------------------
RUN ln -sf /usr/share/zoneinfo/UTC /etc/localtime \
	&& echo "NETWORKING=yes" > /etc/sysconfig/network

# -----------------------------------------------------------------------------
# Configure SSH for non-root public key authentication
# -----------------------------------------------------------------------------
RUN sed -i \
	-e 's~^PasswordAuthentication yes~PasswordAuthentication no~g' \
	-e 's~^#PermitRootLogin yes~PermitRootLogin no~g' \
	-e 's~^#UseDNS yes~UseDNS no~g' \
	-e 's~^\(.*\)/usr/libexec/openssh/sftp-server$~\1internal-sftp~g' \
	/etc/ssh/sshd_config

# -----------------------------------------------------------------------------
# Enable the wheel sudoers group
# -----------------------------------------------------------------------------
RUN sed -i 's~^# %wheel\tALL=(ALL)\tALL~%wheel\tALL=(ALL) ALL~g' /etc/sudoers

# -----------------------------------------------------------------------------
# Copy files into place
# -----------------------------------------------------------------------------
ADD usr/sbin/sshd-bootstrap /usr/sbin/sshd-bootstrap
ADD etc/services-config/ssh/authorized_keys \
	etc/services-config/ssh/sshd-bootstrap.conf \
	etc/services-config/ssh/sshd-bootstrap.env \
	/etc/services-config/ssh/
ADD etc/services-config/supervisor/supervisord.conf /etc/services-config/supervisor/
ADD etc/services-config/supervisor/supervisord.d/sshd.conf \
	etc/services-config/supervisor/supervisord.d/sshd-bootstrap.conf \
	/etc/services-config/supervisor/supervisord.d/

RUN mkdir -p /etc/supervisord.d/ \
	&& cp -pf /etc/ssh/sshd_config /etc/services-config/ssh/ \
	&& ln -sf /etc/services-config/ssh/sshd_config /etc/ssh/sshd_config \
	&& ln -sf /etc/services-config/ssh/sshd-bootstrap.conf /etc/sshd-bootstrap.conf \
	&& ln -sf /etc/services-config/ssh/sshd-bootstrap.env /etc/sshd-bootstrap.env \
	&& ln -sf /etc/services-config/supervisor/supervisord.conf /etc/supervisord.conf \
	&& ln -sf /etc/services-config/supervisor/supervisord.d/sshd.conf /etc/supervisord.d/sshd.conf \
	&& ln -sf /etc/services-config/supervisor/supervisord.d/sshd-bootstrap.conf /etc/supervisord.d/sshd-bootstrap.conf \
	&& chmod +x /usr/sbin/sshd-bootstrap

# -----------------------------------------------------------------------------
# Purge
# -----------------------------------------------------------------------------
RUN rm -rf /etc/ld.so.cache \ 
	; rm -rf /sbin/sln \
	; rm -rf /usr/{{lib,share}/locale,share/{man,doc,info,gnome/help,cracklib,il8n},{lib,lib64}/gconv,bin/localedef,sbin/build-locale-archive} \
	; rm -rf /{root,tmp,var/cache/{ldconfig,yum}}/* \
	; > /etc/sysconfig/i18n

EXPOSE 22

# -----------------------------------------------------------------------------
# Set default environment variables
# -----------------------------------------------------------------------------
ENV SSH_AUTHORIZED_KEYS="" \
	SSH_CHROOT_DIRECTORY="%h" \
	SSH_INHERIT_ENVIRONMENT=false \
	SSH_SUDO="ALL=(ALL) ALL" \
	SSH_USER="app-admin" \
	SSH_USER_FORCE_SFTP=false \
	SSH_USER_HOME="/home/%u" \
	SSH_USER_PASSWORD="" \
	SSH_USER_PASSWORD_HASHED=false \
	SSH_USER_SHELL="/bin/bash" \
	SSH_USER_ID="500:500"

CMD ["/usr/bin/supervisord", "--configuration=/etc/supervisord.conf"]