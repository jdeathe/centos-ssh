# =============================================================================
# jdeathe/centos-ssh
#
# CentOS-7 7.4.1708 x86_64 - SCL/EPEL/IUS Repos. / Supervisor / OpenSSH.
# 
# =============================================================================
FROM centos:7.4.1708

# -----------------------------------------------------------------------------
# Base Install + Import the RPM GPG keys for Repositories
# -----------------------------------------------------------------------------
RUN rpm --rebuilddb \
	&& rpm --import \
		http://mirror.centos.org/centos/RPM-GPG-KEY-CentOS-7 \
	&& rpm --import \
		https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7 \
	&& rpm --import \
		https://dl.iuscommunity.org/pub/ius/IUS-COMMUNITY-GPG-KEY \
	&& yum -y install \
			--setopt=tsflags=nodocs \
			--disableplugin=fastestmirror \
		centos-release-scl \
		centos-release-scl-rh \
		epel-release \
		https://centos7.iuscommunity.org/ius-release.rpm \
		openssh-7.4p1-13.el7_4 \
		openssh-server-7.4p1-13.el7_4 \
		openssh-clients-7.4p1-13.el7_4 \
		openssl-1.0.2k-8.el7 \
		python-setuptools-0.9.8-7.el7 \
		sudo-1.8.19p2-11.el7_4 \
		vim-minimal-7.4.160-2.el7 \
		yum-plugin-versionlock-1.1.31-42.el7 \
		xz-5.2.2-1.el7 \
	&& yum versionlock add \
		openssh \
		openssh-server \
		openssh-clients \
		python-setuptools \
		sudo \
		vim-minimal \
		yum-plugin-versionlock \
		xz \
	&& yum clean all \
	&& rm -rf /etc/ld.so.cache \
	&& rm -rf /sbin/sln \
	&& rm -rf /usr/{{lib,share}/locale,share/{man,doc,info,cracklib,i18n},{lib,lib64}/gconv,bin/localedef,sbin/build-locale-archive} \
	&& rm -rf /{root,tmp,var/cache/{ldconfig,yum}}/* \
	&& > /etc/sysconfig/i18n

# -----------------------------------------------------------------------------
# Install supervisord (required to run more than a single process in a container)
# Note: EPEL package lacks /usr/bin/pidproxy
# We require supervisor-stdout to allow output of services started by 
# supervisord to be easily inspected with "docker logs".
# -----------------------------------------------------------------------------
RUN easy_install \
		'supervisor == 3.3.4' \
		'supervisor-stdout == 0.1.1' \
	&& mkdir -p \
		/var/log/supervisor/

# -----------------------------------------------------------------------------
# UTC Timezone & Networking
# -----------------------------------------------------------------------------
RUN ln -sf \
		/usr/share/zoneinfo/UTC \
		/etc/localtime \
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
RUN sed -i \
	-e 's~^# %wheel\tALL=(ALL)\tALL~%wheel\tALL=(ALL) ALL~g' \
	-e 's~\(.*\) requiretty$~#\1requiretty~' \
	/etc/sudoers

# -----------------------------------------------------------------------------
# Copy files into place
# -----------------------------------------------------------------------------
ADD src/usr/bin \
	/usr/bin/
ADD src/usr/sbin \
	/usr/sbin/
ADD src/opt/scmi \
	/opt/scmi/
ADD src/etc/systemd/system \
	/etc/systemd/system/
ADD src/etc/services-config/ssh/authorized_keys \
	src/etc/services-config/ssh/sshd-bootstrap.conf \
	src/etc/services-config/ssh/sshd-bootstrap.env \
	/etc/services-config/ssh/
ADD src/etc/services-config/supervisor/supervisord.conf \
	/etc/services-config/supervisor/
ADD src/etc/services-config/supervisor/supervisord.d \
	/etc/services-config/supervisor/supervisord.d/

RUN mkdir -p \
		/etc/supervisord.d/ \
	&& cp -pf \
		/etc/ssh/sshd_config \
		/etc/services-config/ssh/ \
	&& ln -sf \
		/etc/services-config/ssh/sshd_config \
		/etc/ssh/sshd_config \
	&& ln -sf \
		/etc/services-config/ssh/sshd-bootstrap.conf \
		/etc/sshd-bootstrap.conf \
	&& ln -sf \
		/etc/services-config/ssh/sshd-bootstrap.env \
		/etc/sshd-bootstrap.env \
	&& ln -sf \
		/etc/services-config/supervisor/supervisord.conf \
		/etc/supervisord.conf \
	&& ln -sf \
		/etc/services-config/supervisor/supervisord.d/sshd-wrapper.conf \
		/etc/supervisord.d/sshd-wrapper.conf \
	&& ln -sf \
		/etc/services-config/supervisor/supervisord.d/sshd-bootstrap.conf \
		/etc/supervisord.d/sshd-bootstrap.conf \
	&& chmod 700 \
		/usr/{bin/healthcheck,sbin/{scmi,sshd-{bootstrap,wrapper}}}

EXPOSE 22

# -----------------------------------------------------------------------------
# Set default environment variables
# -----------------------------------------------------------------------------
ENV SSH_AUTHORIZED_KEYS="" \
	SSH_AUTOSTART_SSHD=true \
	SSH_AUTOSTART_SSHD_BOOTSTRAP=true \
	SSH_CHROOT_DIRECTORY="%h" \
	SSH_INHERIT_ENVIRONMENT=false \
	SSH_SUDO="ALL=(ALL) ALL" \
	SSH_USER="app-admin" \
	SSH_USER_FORCE_SFTP=false \
	SSH_USER_HOME="/home/%u" \
	SSH_USER_ID="500:500" \
	SSH_USER_PASSWORD="" \
	SSH_USER_PASSWORD_HASHED=false \
	SSH_USER_SHELL="/bin/bash"

# -----------------------------------------------------------------------------
# Set image metadata
# -----------------------------------------------------------------------------
ARG RELEASE_VERSION="2.3.2"
LABEL \
	maintainer="James Deathe <james.deathe@gmail.com>" \
	install="docker run \
--rm \
--privileged \
--volume /:/media/root \
jdeathe/centos-ssh:${RELEASE_VERSION} \
/usr/sbin/scmi install \
--chroot=/media/root \
--name=\${NAME} \
--tag=${RELEASE_VERSION} \
--setopt='--volume {{NAME}}.config-ssh:/etc/ssh'" \
	uninstall="docker run \
--rm \
--privileged \
--volume /:/media/root \
jdeathe/centos-ssh:${RELEASE_VERSION} \
/usr/sbin/scmi uninstall \
--chroot=/media/root \
--name=\${NAME} \
--tag=${RELEASE_VERSION} \
--setopt='--volume {{NAME}}.config-ssh:/etc/ssh'" \
	org.deathe.name="centos-ssh" \
	org.deathe.version="${RELEASE_VERSION}" \
	org.deathe.release="jdeathe/centos-ssh:${RELEASE_VERSION}" \
	org.deathe.license="MIT" \
	org.deathe.vendor="jdeathe" \
	org.deathe.url="https://github.com/jdeathe/centos-ssh" \
	org.deathe.description="CentOS-7 7.4.1708 x86_64 - SCL, EPEL and IUS Repositories / Supervisor / OpenSSH."

HEALTHCHECK \
	--interval=0.5s \
	--timeout=1s \
	--retries=5 \
	CMD ["/usr/bin/healthcheck"]

CMD ["/usr/bin/supervisord", "--configuration=/etc/supervisord.conf"]