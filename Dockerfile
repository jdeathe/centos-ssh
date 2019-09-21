FROM centos:7.6.1810

ARG RELEASE_VERSION="2.6.1"

# ------------------------------------------------------------------------------
# - Import the RPM GPG keys for repositories
# - Base install of required packages
# - Install supervisord (used to run more than a single process)
# - Install supervisor-stdout to allow output of services started by
#  supervisord to be easily inspected with "docker logs".
# ------------------------------------------------------------------------------
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
	&& yum -y install \
			--setopt=tsflags=nodocs \
			--disableplugin=fastestmirror \
		inotify-tools-3.14-8.el7 \
		openssh-clients-7.4p1-21.el7 \
		openssh-server-7.4p1-21.el7 \
		openssl-1.0.2k-19.el7 \
		python-setuptools-0.9.8-7.el7 \
		sudo-1.8.23-4.el7 \
		yum-plugin-versionlock-1.1.31-52.el7 \
	&& yum versionlock add \
		inotify-tools \
		openssh \
		openssh-server \
		openssh-clients \
		python-setuptools \
		sudo \
		yum-plugin-versionlock \
	&& yum clean all \
	&& easy_install \
		'supervisor == 4.0.4' \
		'supervisor-stdout == 0.1.1' \
	&& mkdir -p \
		/var/log/supervisor/ \
	&& rm -rf /etc/ld.so.cache \
	&& rm -rf /sbin/sln \
	&& rm -rf /usr/{{lib,share}/locale,share/{man,doc,info,cracklib,i18n},{lib,lib64}/gconv,bin/localedef,sbin/build-locale-archive} \
	&& rm -rf /{root,tmp,var/cache/{ldconfig,yum}}/* \
	&& > /etc/sysconfig/i18n

# ------------------------------------------------------------------------------
# Copy files into place
# ------------------------------------------------------------------------------
ADD src /

# ------------------------------------------------------------------------------
# Provisioning
# - UTC Timezone
# - Networking
# - Configure SSH defaults for non-root public key authentication
# - Enable the wheel sudoers group
# - Replace placeholders with values in systemd service unit template
# - Set permissions
# ------------------------------------------------------------------------------
RUN ln -sf \
		/usr/share/zoneinfo/UTC \
		/etc/localtime \
	&& echo "NETWORKING=yes" \
		> /etc/sysconfig/network \
	&& sed -i \
		-e 's~^PasswordAuthentication yes~PasswordAuthentication no~g' \
		-e 's~^#PermitRootLogin yes~PermitRootLogin no~g' \
		-e 's~^#UseDNS yes~UseDNS no~g' \
		-e 's~^\(.*\)/usr/libexec/openssh/sftp-server$~\1internal-sftp~g' \
		/etc/ssh/sshd_config \
	&& sed -i \
		-e 's~^# %wheel\tALL=(ALL)\tALL~%wheel\tALL=(ALL) ALL~g' \
		-e 's~\(.*\) requiretty$~#\1requiretty~' \
		/etc/sudoers \
	&& sed -i \
		-e "s~{{RELEASE_VERSION}}~${RELEASE_VERSION}~g" \
		/etc/systemd/system/centos-ssh@.service \
	&& chmod 644 \
		/etc/{supervisord.conf,supervisord.d/{20-sshd-bootstrap,50-sshd-wrapper}.conf} \
	&& chmod 700 \
		/usr/{bin/healthcheck,sbin/{scmi,sshd-{bootstrap,wrapper},system-{timezone,timezone-wrapper}}}

EXPOSE 22

# ------------------------------------------------------------------------------
# Set default environment variables
# ------------------------------------------------------------------------------
ENV \
	ENABLE_SSHD_BOOTSTRAP="true" \
	ENABLE_SSHD_WRAPPER="true" \
	ENABLE_SUPERVISOR_STDOUT="false" \
	SSH_AUTHORIZED_KEYS="" \
	SSH_CHROOT_DIRECTORY="%h" \
	SSH_INHERIT_ENVIRONMENT="false" \
	SSH_PASSWORD_AUTHENTICATION="false" \
	SSH_SUDO="ALL=(ALL) ALL" \
	SSH_USER="app-admin" \
	SSH_USER_FORCE_SFTP="false" \
	SSH_USER_HOME="/home/%u" \
	SSH_USER_ID="500:500" \
	SSH_USER_PASSWORD="" \
	SSH_USER_PASSWORD_HASHED="false" \
	SSH_USER_PRIVATE_KEY="" \
	SSH_USER_SHELL="/bin/bash" \
	SYSTEM_TIMEZONE="UTC"

# ------------------------------------------------------------------------------
# Set image metadata
# ------------------------------------------------------------------------------
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
	org.deathe.description="OpenSSH 7.4 / Supervisor 4.0 / EPEL/IUS/SCL Repositories - CentOS-7 7.6.1810 x86_64."

HEALTHCHECK \
	--interval=1s \
	--timeout=1s \
	--retries=5 \
	CMD ["/usr/bin/healthcheck"]

CMD ["/usr/bin/supervisord", "--configuration=/etc/supervisord.conf"]
