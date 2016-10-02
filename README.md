centos-ssh
==========

Docker Images of CentOS-6 6.8 x86_64 / CentOS-7 7.2.1511 x86_64

Includes public key authentication, Automated password generation and supports custom configuration via environment variables.

## Overview & links

The latest CentOS-6 / CentOS-7 based releases can be pulled from the centos-6 / centos-7 Docker tags respectively. For a specific release tag the convention is `centos-6-1.5.0` for the [1.5.0](https://github.com/jdeathe/centos-ssh/tree/1.5.0) release tag and `centos-7-2.0.0` for the [2.0.0](https://github.com/jdeathe/centos-ssh/tree/2.0.0) release tag.

- centos-7 [(centos-7/Dockerfile)](https://github.com/jdeathe/centos-ssh/blob/centos-7/Dockerfile)
- centos-6 [(centos-6/Dockerfile)](https://github.com/jdeathe/centos-ssh/blob/centos-6/Dockerfile)

The Dockerfile can be used to build a base image that is the bases for several other docker images.

Included in the build are the [SCL](https://www.softwarecollections.org/), [EPEL](http://fedoraproject.org/wiki/EPEL) and [IUS](https://ius.io) repositories. Installed packages include [OpenSSH](http://www.openssh.com/portable.html) secure shell, [Sudo](http://www.courtesan.com/sudo/) and [vim-minimal](http://www.vim.org/) are along with python-setuptools, [supervisor](http://supervisord.org/) and [supervisor-stdout](https://github.com/coderanger/supervisor-stdout).

[Supervisor](http://supervisord.org/) is used to start and the sshd daemon when a docker container based on this image is run. To enable simple viewing of stdout for the sshd subprocess, supervisor-stdout is included. This allows you to see output from the supervisord controlled subprocesses with `docker logs {container-name}`.

SSH access is by public key authentication and, by default, the [Vagrant](http://www.vagrantup.com/) [insecure private key](https://github.com/mitchellh/vagrant/blob/master/keys/vagrant) is required.

### SSH Alternatives

SSH is not required in order to access a terminal for the running container. The simplest method is to use the docker exec command to run bash (or sh) as follows:

```
$ docker exec -it {container-name-or-id} bash
```

For cases where access to docker exec is not possible the preferred method is to use Command Keys and the nsenter command. See [command-keys.md](https://github.com/jdeathe/centos-ssh/blob/centos-6/command-keys.md) for details on how to set this up.

## Quick Example

### SSH Mode

Run up an SSH container named 'ssh.pool-1.1.1' from the docker image 'jdeathe/centos-ssh' on port 2020 of your docker host.

```
$ docker run -d \
  --name ssh.pool-1.1.1 \
  -p 2020:22 \
  jdeathe/centos-ssh:centos-6
```

Check the logs for the password (required for sudo˜).

```
$ docker logs ssh.pool-1.1.1
```

Download the [insecure private key](https://github.com/mitchellh/vagrant/blob/master/keys/vagrant) and set permissions to 600.

```
$ curl -LSs \
  https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant \
  > id_rsa_insecure
$ chmod 600 id_rsa_insecure
```

Connect using the `ssh` command line client with the [insecure private key](https://github.com/mitchellh/vagrant/blob/master/keys/vagrant).

```
$ ssh -p 2020 -i id_rsa_insecure \
  app-admin@{docker-host-ip}
```

### SFTP Mode

Run up an SFTP container named 'sftp.pool-1.1.1' from the docker image 'jdeathe/centos-ssh' on port 2021 of your docker host.

```
$ docker run -d \
  --name sftp.pool-1.1.1 \
  -p 2021:22 \
  -e SSH_USER_FORCE_SFTP=true \
  jdeathe/centos-ssh:centos-6
```

Connect using the `sftp` command line client with the [insecure private key](https://github.com/mitchellh/vagrant/blob/master/keys/vagrant).

```
$ sftp -p 2021 -i id_rsa_insecure \
  app-admin@{docker-host-ip}
```

## Instructions

### Running

To run the a docker container from this image you can use the standard docker commands. Alternatively, you can use the embedded (Service Container Manager Interface) [scmi](https://github.com/jdeathe/centos-ssh/blob/centos-7/usr/sbin/scmi) that is included in the image since `centos-6-1.7.2`|`centos-7-2.1.2` or, if you have a checkout of the [source repository](https://github.com/jdeathe/centos-ssh), and have make installed the Makefile provides targets to build, install, start, stop etc. where environment variables can be used to configure the container options and set custom docker run parameters.

#### SCMI Installation Examples

The following example uses docker to run the SCMI install command to create and start a container named `ssh.pool-1.1.1`. To use SCMI it requires the use of the `--privileged` docker run parameter and the docker host's root directory mounted as a volume with the container's mount directory also being set in the `scmi` `--chroot` option. The `--setopt` option is used to add extra parameters to the default docker run command template; in the following example a named configuration volume is added which allows the SSH host keys to persist after the first container initialisation. Not that the placeholder `{{NAME}}` can be used in this option and is replaced with the container's name.

##### SCMI Install

```
$ docker run \
  --rm \
  --privileged \
  --volume /:/media/root \
  jdeathe/centos-ssh:centos-6-1.7.2 \
  /usr/sbin/scmi install \
    --chroot=/media/root \
    --tag=centos-6-1.7.2 \
    --name=ssh.pool-1.1.1 \
    --setopt="--volume {{NAME}}.config-ssh:/etc/ssh"
```

##### SCMI Uninstall

To uninstall the previous example simply run the same docker run command with the scmi `uninstall` command.

```
$ docker run \
  --rm \
  --privileged \
  --volume /:/media/root \
  jdeathe/centos-ssh:centos-6-1.7.2 \
  /usr/sbin/scmi uninstall \
    --chroot=/media/root \
    --tag=centos-6-1.7.2 \
    --name=ssh.pool-1.1.1 \
    --setopt="--volume {{NAME}}.config-ssh:/etc/ssh"
```

##### SCMI Systemd Support

If your docker host has systemd (and optionally etcd) installed then `scmi` provides a method to install the container as a systemd service unit. This provides some additional features for managing a group of instances on a single docker host and has the option to use an etcd backed service registry. Using a systemd unit file allows the System Administrator to use a Drop-In to override the settings of a unit-file template used to create service instances. To use the systemd method of installation use the `-m` or `--manager` option of `scmi` and to include the optional etcd register companion unit use the `--register` option.

```
$ docker run \
  --rm \
  --privileged \
  --volume /:/media/root \
  jdeathe/centos-ssh:centos-6-1.7.2 \
  /usr/sbin/scmi install \
    --chroot=/media/root \
    --tag=centos-6-1.7.2 \
    --name=ssh.pool-1.1.1 \
    --manager=systemd \
    --register \
    --env='SSH_SUDO="ALL=(ALL) NOPASSWD:ALL"' \
    --env='SSH_USER="centos"' \
    --setopt='--volume {{NAME}}.config-ssh:/etc/ssh'
```

##### SCMI Fleet Support

If your docker host has systemd, fleetd (and optionally etcd) installed then `scmi` provides a method to schedule the container  to run on the cluster. This provides some additional features for managing a group of instances on a [fleet](https://github.com/coreos/fleet) cluster and has the option to use an etcd backed service registry. To use the fleet method of installation use the `-m` or `--manager` option of `scmi` and to include the optional etcd register companion unit use the `--register` option.

##### SCMI Image Information

Since release tags `centos-6-1.7.2` and `centos-7-2.1.2` the install template has been added to the image metadata. Using docker inspect you can access `scmi` to simplify install/uninstall tasks.

To see detailed information about the image run `scmi` with the `--info` option. To see all available `scmi` options run with the `--help` option.

```
$ eval "sudo -E $(
    docker inspect \
    -f "{{.ContainerConfig.Labels.install}}" \
    jdeathe/centos-ssh:centos-6-1.7.2
  ) --info"
```

To perform an installation using the docker name `ssh.pool-1.2.1` simply use the `--name` or `-n` option.

```
$ eval "sudo -E $(
    docker inspect \
    -f "{{.ContainerConfig.Labels.install}}" \
    jdeathe/centos-ssh:centos-6-1.7.2
  ) --name=ssh.pool-1.2.1"
```

To uninstall use the *same command* that was used to install but with the `uninstall` Label.

```
$ eval "sudo -E $(
    docker inspect \
    -f "{{.ContainerConfig.Labels.uninstall}}" \
    jdeathe/centos-ssh:centos-6-1.7.2
  ) --name=ssh.pool-1.2.1"
```

##### SCMI on Atomic Host

With the addition of install/uninstall image labels it is possible to use [Project Atomic's](http://www.projectatomic.io/) `atomic install` command to simplify install/uninstall tasks on [CentOS Atomic](https://wiki.centos.org/SpecialInterestGroup/Atomic) Hosts.

To see detailed information about the image run `scmi` with the `--info` option. To see all available `scmi` options run with the `--help` option.

```
$ sudo -E atomic install \
  -n ssh.pool-1.3.1 \
  jdeathe/centos-ssh:centos-6-1.7.2 \
  --info
```

To perform an installation using the docker name `ssh.pool-1.3.1` simply use the `-n` option of the `atomic install` command.

```
$ sudo -E atomic install \
  -n ssh.pool-1.3.1 \
  jdeathe/centos-ssh:centos-6-1.7.2
```

Alternatively, you could use the `scmi` options `--name` or `-n` for naming the container.

```
$ sudo -E atomic install \
  jdeathe/centos-ssh:centos-6-1.7.2 \
  --name ssh.pool-1.3.1
```

To uninstall use the *same command* that was used to install but with the `uninstall` Label.

```
$ sudo -E atomic uninstall \
  -n ssh.pool-1.3.1 \
  jdeathe/centos-ssh:centos-6-1.7.2
```

#### Using environment variables

The following example overrides the default "app-admin" SSH username and home directory path with "app-user" and "/home/app-user" respectively. The same technique could also be applied to set the SSH_USER_PASSWORD value.

*Note:* Settings applied by environment variables will override those set within configuration volumes from release 1.3.1. Existing installations that use the sshd-bootstrap.conf saved on a configuration "data" volume will not allow override by the environment variables. Also users can update sshd-bootstrap.conf to prevent the value being replaced by that set using the environment variable.

```
$ docker stop ssh.pool-1.1.1 \
  && docker rm ssh.pool-1.1.1 \
  ; docker run -d \
  --name ssh.pool-1.1.1 \
  -p :22 \
  --env "SSH_USER=app-user" \
  jdeathe/centos-ssh:centos-6
```

Now you can find out the app-admin, (sudoer), user's password by inspecting the container's logs

```
$ docker logs ssh.pool-1.1.1
```

The output of the logs should show the auto-generated password for the app-admin and root users, (if not try again after a few seconds).

```
2016-02-01 02:26:51,420 CRIT Supervisor running as root (no user in config file)
2016-02-01 02:26:51,420 WARN Included extra file "/etc/supervisord.d/sshd-bootstrap.conf" during parsing
2016-02-01 02:26:51,420 WARN Included extra file "/etc/supervisord.d/sshd.conf" during parsing
2016-02-01 02:26:51,420 WARN No file matches via include "/etc/supervisord.d/*.ini"
2016-02-01 02:26:51,422 INFO supervisord started with pid 1
2016-02-01 02:26:52,425 INFO spawned: 'supervisor_stdout' with pid 7
2016-02-01 02:26:52,427 INFO spawned: 'sshd-bootstrap' with pid 8
2016-02-01 02:26:52,429 INFO spawned: 'sshd' with pid 9
2016-02-01 02:26:52,458 INFO success: sshd-bootstrap entered RUNNING state, process has stayed up for > than 0 seconds (startsecs)
2016-02-01 02:26:53,956 INFO success: supervisor_stdout entered RUNNING state, process has stayed up for > than 1 seconds (startsecs)
2016-02-01 02:26:53,957 INFO success: sshd entered RUNNING state, process has stayed up for > than 1 seconds (startsecs)
sshd-bootstrap stdout | Initialising SSH.
sshd-bootstrap stdout |
================================================================================
SSH Details
--------------------------------------------------------------------------------
user : app-user
password : QDQE12uVMyagLEsQ
id : 500:500
home : /home/app-user
chroot path : N/A
shell : /bin/bash
sudo : ALL=(ALL) ALL
key fingerprints :
dd:3b:b8:2e:85:04:06:e9:ab:ff:a8:0a:c0:04:6e:d6 (insecure key)
rsa host key fingerprint :
96:a3:f6:d7:32:d7:a5:38:f8:49:2c:5e:53:e4:86:30
--------------------------------------------------------------------------------

sshd stdout | Server listening on 0.0.0.0 port 22.
sshd stdout | Server listening on :: port 22.
2016-02-01 02:26:54,464 INFO exited: sshd-bootstrap (exit status 0; expected)
```

#### Environment Variables

There are several environmental variables defined at runtime these allow the operator to customise the running container.

##### SSH_AUTHORIZED_KEYS

As detailed below the public key added for the SSH user is insecure by default. This is intentional and allows for access using a known private key. Using `SSH_AUTHORIZED_KEYS` you can replace the insecure public key with another one (or several). Further details on how to create your own private + public key pair are provided below. If adding more than one key it is recommended to base64 encode the value.

```
...
--env "SSH_AUTHORIZED_KEYS=
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAqmLedI2mEJimvIm1OzT1EYJCMwegL/jfsXARLnYkZvJlEHFYDmRgS+YQ+MA9PKHyriCPmVNs/6yVc2lopwPWioXt0+ulH/H43PgB6/4fkP0duauHsRtpp7z7dhqgZOXqdLUn/Ybp0rz0+yKUOBb9ggjE5n7hYyDGtZR9Y11pJ4TuRHmL6wv5mnj9WRzkUlJNYkr6X5b6yAxtQmX+2f33u2qGdAwADddE/uZ4vKnC0jFsv5FdvnwRf2diF/9AagDb7xhZ9U3hPOyLj31H/OUce4xBpGXRfkUYkeW8Qx+zEbEBVlGxDroIMZmHJIknBDAzVfft+lsg1Z06NCYOJ+hSew== another public key
"  \
...
```

*Note:* The `base64` command on Mac OSX will encode a file without line breaks by default but if using the command on Linux you need to include use the `-w` option to prevent wrapping lines at 80 characters. i.e. `base64 -w 0 -i {key-path}`.

```
...
  --env "SSH_AUTHORIZED_KEYS=$(
    cat ${HOME}/.ssh/id_rsa.pub ${HOME}/.ssh/another_id_rsa.pub | base64 -i -
  )" \
...
```

##### SSH_AUTOSTART_SSHD & SSH_AUTOSTART_SSHD_BOOTSTRAP

It may be desirable to prevent the startup of the sshd daemon and/or sshd-bootstrap script. For example, when using an image built from this Dockerfile as the source for another Dockerfile you could disable both sshd and sshd-booststrap from startup by setting `SSH_AUTOSTART_SSHD` and `SSH_AUTOSTART_SSHD_BOOTSTRAP` to `false`. The benefit of this is to reduce the number of running processes in the final container.

```
...
  --env "SSH_AUTOSTART_SSHD=false" \
  --env "SSH_AUTOSTART_SSHD_BOOTSTRAP=false" \
...
```

##### SSH_CHROOT_DIRECTORY

This option is only applicable when `SSH_USER_FORCE_SFTP` is set to `true`. When using the using the SFTP option the user is jailed into the ChrootDirectory. The value can contain the placeholders `%h` and `%u` which will be replaced with the values of `SSH_USER_HOME` and `SSH_USER` respectively. The default value of `%h` is the best choice in most cases but the user requires a sub-directory in their HOME directory which they have write access to. If no volume is mounted into the path of the SSH user's HOME directory the a directory named `_data` is created automatically. If you need the user to be able to write to their HOME directory they use an alternative value such as `/chroot/%u` so that the user's HOME path, (relative to the ChrootDirectory), becomes `/chroot/app-admin/home/app-admin` by default.

```
...
  --env "SSH_CHROOT_DIRECTORY=%h" \
...
```

##### SSH_INHERIT_ENVIRONMENT

The SSH user's environment is reset by default meaning that the Docker environmental variables are not available. Use `SSH_INHERIT_ENVIRONMENT` to allow the Docker environment variables to be passed to the SSH user's environment. Note that some values are removed to prevent issues; such as SSH_USER_PASSWORD, HOME, HOSTNAME, PATH, TERM etc.

```
...
  --env "SSH_INHERIT_ENVIRONMENT=true" \
...
```

##### SSH_SUDO

On first run the SSH user is created with a the sudo rule `ALL=(ALL)  ALL` which allows the user to run all commands but a password is required. If you want to limit the access to specific commands or allow sudo without a password prompt `SSH_SUDO` can be used.

```
...
  --env "SSH_SUDO=ALL=(ALL) NOPASSWD:ALL" \
...
```

##### SSH_USER

On first run the SSH user is created with the default username of "app-admin". If you require an alternative username `SSH_USER` can be used when running the container.

```
...
  --env "SSH_USER=app-1" \
...
```

##### SSH_USER_FORCE_SFTP

To force the use of the internal-sftp command set `SSH_USER_FORCE_SFTP` to `true`. This will prevent shell access, remove the ability to use `sudo` and restrict the user to the ChrootDirectory set using `SSH_SHROOT_DIRECTORY`. Using SFTP in combination with --volumes-from another running container can be used to allow write access to an applications data volume - for example using the `SSH_USER_HOME` value to `/var/www/` could be used to allow access to the data volume of an Apache container.

```
...
  --env "SSH_USER_FORCE_SFTP=false" \
...
```

##### SSH_USER_HOME

On first run the SSH user is created with the default HOME directory of `/home/%u` where `%u` is replaced with the value of `SSH_USER`. If you require an alternative HOME directory `SSH_USER_HOME` can be used when running the container.

```
...
  --env "SSH_USER_HOME=/home/app-1" \
...
```

##### SSH_USER_PASSWORD

On first run the SSH user is created with a generated password. If you require a specific password `SSH_USER_PASSWORD` can be used when running the container. If set to an empty string then a password is auto-generated and, if `SSH_SUDO` is not set to allow no password for all commands, will be displayed in the docker logs.

```
...
  --env "SSH_USER_PASSWORD=Passw0rd!" \
...
```

##### SSH_USER_PASSWORD_HASHED

If setting a password for the SSH user you might not want to store the plain text password value in the `SSH_USER_PASSWORD` environment variable. Setting `SSH_USER_PASSWORD_HASHED` to `true` indicates that the value stored in `SSH_USER_PASSWORD` should be treated as a crypt SHA-512 salted password hash.

```
...
  --env "SSH_USER_PASSWORD_HASHED=true" \
  --env 'SSH_USER_PASSWORD=$6$pepper$g5/OhofGtHVo3wqRgVHFQrJDyK0mV9bDpF5HP964wuIkQ7MXuYq1KRTmShaUmTQW3ZRsjw2MjC1LNPh5HMcrY0'
...
```

###### Generating a crypt SHA-512 password hash

To generate a new hashed password string you can use the following method - given a password of "Passw0rd!" and a salt of "pepper".

```
$ docker exec -it ssh.pool-1.1.1 \
  env \
  PASSWORD=Passw0rd! \
  PASSWORD_SALT=pepper \
  python -c "import crypt,os; print crypt.crypt(os.environ.get('PASSWORD'), '\$6\$' + os.environ.get('PASSWORD_SALT') + '\$')"
```

The result should be the string: ```$6$pepper$g5/OhofGtHVo3wqRgVHFQrJDyK0mV9bDpF5HP964wuIkQ7MXuYq1KRTmShaUmTQW3ZRsjw2MjC1LNPh5HMcrY0```

##### SSH_USER_SHELL

On first run the SSH user is created with a default shell of "/bin/bash". If you require a specific shell `SSH_USER_SHELL` can be used when running the container. You could use "/sbin/nologin" to prevent login with the user account.

```
...
  --env "SSH_USER_SHELL=/bin/sh" \
...
```

##### SSH_USER_ID

Use `SSH_USER_ID` to set a specific UID:GID for the `SSH_USER`. The values should be 500 or more - the default being 500:500. This may be useful when running an SFTP container and mounting data volumes from an existing container.

```
...
  --env "SSH_USER_ID=500:500" \
...
```

### Connect to the running container using SSH

If you have not already got one, create the .ssh directory in your home directory with the permissions required by SSH.

```
$ mkdir -pm 700 ~/.ssh
```

Get the [Vagrant](http://www.vagrantup.com/) insecure public key using curl (you could also use wget if you have that installed).

```
$ curl -LsSO https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant && \
  mv vagrant ~/.ssh/id_rsa_insecure && \
  chmod 600 ~/.ssh/id_rsa_insecure
```

If the command ran successfully you should now have a new private SSH key installed in your home "~/.ssh" directory called "id_rsa_insecure"

Next, unless we specified one, we need to determine what port to connect to on the docker host. You can do this with either `docker ps` or `docker inspect` but the simplest method is to use `docker port`.

```
$ docker port ssh.pool-1.1.1 22
```

To connect to the running container use:

```
$ ssh -p {container-port} \
  -i ~/.ssh/id_rsa_insecure \
  app-admin@{docker-host-ip} \
  -o StrictHostKeyChecking=no
```
