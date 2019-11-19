## Tags and respective `Dockerfile` links

- [`2.6.1`](https://github.com/jdeathe/centos-ssh/releases/tag/2.6.1),`centos-7` [(centos-7/Dockerfile)](https://github.com/jdeathe/centos-ssh/blob/centos-7/Dockerfile)
- [`1.11.1`](https://github.com/jdeathe/centos-ssh/releases/tag/1.11.1),`centos-6` [(centos-6/Dockerfile)](https://github.com/jdeathe/centos-ssh/blob/centos-6/Dockerfile)

## Overview

Included in the build are the [EPEL](http://fedoraproject.org/wiki/EPEL), [IUS](https://ius.io) and [SCL](https://www.softwarecollections.org/) repositories. Installed packages include [inotify-tools](https://github.com/rvoicilas/inotify-tools/wiki), [OpenSSH](http://www.openssh.com/portable.html) secure shell, [Sudo](http://www.courtesan.com/sudo/), [vim-minimal](http://www.vim.org/), python-setuptools, [supervisor](http://supervisord.org/) and [supervisor-stdout](https://github.com/coderanger/supervisor-stdout).

[Supervisor](http://supervisord.org/) is used to start the `sshd` daemon when a docker container based on this image is run.

SSH access is by public key authentication and, by default, the [Vagrant](http://www.vagrantup.com/) [insecure private key](https://github.com/mitchellh/vagrant/blob/master/keys/vagrant) is required.

### Image variants

- [OpenSSH 7.4 / Supervisor 4.0 / EPEL/IUS/SCL Repositories - CentOS-7](https://github.com/jdeathe/centos-ssh/tree/centos-7)
- [OpenSSH 5.3 / Supervisor 3.4 / EPEL/IUS/SCL Repositories - CentOS-6](https://github.com/jdeathe/centos-ssh/tree/centos-6)

### SSH alternatives

SSH is not required in order to access a terminal for the running container. The simplest method is to use the docker exec command to run bash (or sh) as follows:

```
$ docker exec -it {{container-name-or-id}} bash
```

For cases where access to docker exec is not possible the preferred method is to use Command Keys and the nsenter command. See [docs/command-keys.md](https://github.com/jdeathe/centos-ssh/blob/centos-7/docs/command-keys.md) for details on how to set this up.

## Quick start

> For production use, it is recommended to select a specific release tag as shown in the examples.

### SSH mode

Run up an SSH container named 'ssh.1' from the docker image 'jdeathe/centos-ssh' on port 2020 of your docker host.

```
$ docker run -d \
  --name ssh.1 \
  -p 2020:22 \
  jdeathe/centos-ssh:2.6.1
```

Check the logs for the password (required for sudo).

```
$ docker logs ssh.1
```

#### Private key setup

Download the [insecure private key](https://github.com/mitchellh/vagrant/blob/master/keys/vagrant).

```
$ curl -LSs \
  https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant \
  > id_rsa_insecure
```

Set restrictive permissions on the private key.

```
$ chmod 600 id_rsa_insecure
```
#### Connecting

Connect using the `ssh` command line client with the [insecure private key](https://github.com/mitchellh/vagrant/blob/master/keys/vagrant).

```
$ ssh -p 2020 -i id_rsa_insecure \
  app-admin@{{docker-host-ip}}
```

### SFTP mode

Run up an SFTP container named 'sftp.1' from the docker image 'jdeathe/centos-ssh' on port 2021 of your docker host.

```
$ docker run -d \
  --name sftp.1 \
  -p 2021:22 \
  -e SSH_USER_FORCE_SFTP=true \
  jdeathe/centos-ssh:2.6.1
```

#### Connecting

Connect using the `sftp` command line client with the [insecure private key](https://github.com/mitchellh/vagrant/blob/master/keys/vagrant).

```
$ sftp \
  -o Port=2021 \
  -o StrictHostKeyChecking=no \
  -i id_rsa_insecure \
  app-admin@{{docker-host-ip}}
```

## Instructions

### Running

To run the a docker container from this image you can use the standard docker commands. Alternatively, there's a [docker-compose.yml](https://github.com/jdeathe/centos-ssh/blob/centos-7/docker-compose.yml) example.

For production use, it is recommended to select a specific release tag as shown in the examples.

#### Using scmi

For advanced use-cases, there's an embedded installer (Service Container Manager Interface) [scmi](https://github.com/jdeathe/centos-ssh/blob/centos-7/docs/scmi.md).

#### Using make

If you have a checkout of the [source repository](https://github.com/jdeathe/centos-ssh), and have `make` installed the Makefile provides targets to build, install, start, stop etc; run `make help` for instructions.

#### Using environment variables

The following example overrides the default "app-admin" SSH username, (and corresponding home directory path), with "centos" and "/home/centos" respectively via the `SSH_USER` environment variable.

```
$ docker stop ssh.1 && \
  docker rm ssh.1; \
  docker run -d \
  --name ssh.1 \
  -p :22 \
  --env "SSH_USER=centos" \
  jdeathe/centos-ssh:2.6.1
```

To identify the `SSH_USER` user's sudoer password, inspect the container's logs as follows:

```
$ docker logs ssh.1
```

The output of the logs will show the auto-generated password for the user specified by `SSH_USER` on first run.

```
2019-06-20 00:10:35,306 WARN No file matches via include "/etc/supervisord.d/*.ini"
2019-06-20 00:10:35,306 INFO Included extra file "/etc/supervisord.d/00-supervisor_stdout.conf" during parsing
2019-06-20 00:10:35,307 INFO Included extra file "/etc/supervisord.d/10-system-timezone-wrapper.conf" during parsing
2019-06-20 00:10:35,307 INFO Included extra file "/etc/supervisord.d/20-sshd-bootstrap.conf" during parsing
2019-06-20 00:10:35,307 INFO Included extra file "/etc/supervisord.d/50-sshd-wrapper.conf" during parsing
2019-06-20 00:10:35,307 INFO Set uid to user 0 succeeded
2019-06-20 00:10:35,310 INFO supervisord started with pid 1
2019-06-20 00:10:36,315 INFO spawned: 'system-timezone-wrapper' with pid 9
2019-06-20 00:10:36,318 INFO spawned: 'sshd-bootstrap' with pid 10
2019-06-20 00:10:36,320 INFO spawned: 'sshd-wrapper' with pid 11
INFO: sshd-wrapper waiting on sshd-bootstrap
2019-06-20 00:10:36,328 INFO success: system-timezone-wrapper entered RUNNING state, process has stayed up for > than 0 seconds (startsecs)
2019-06-20 00:10:36,328 INFO success: sshd-bootstrap entered RUNNING state, process has stayed up for > than 0 seconds (startsecs)

================================================================================
System Time Zone Details
--------------------------------------------------------------------------------
timezone : UTC
--------------------------------------------------------------------------------
0.00640178

2019-06-20 00:10:36,346 INFO exited: system-timezone-wrapper (exit status 0; expected)

================================================================================
SSH Details
--------------------------------------------------------------------------------
chroot path : N/A
home : /home/app-admin
id : 500:500
key fingerprints :
dd:3b:b8:2e:85:04:06:e9:ab:ff:a8:0a:c0:04:6e:d6 (insecure key)
password : uIEqLkiacCvxaN45
password authentication : no
rsa private key fingerprint :
N/A
rsa host key fingerprint :
7d:6f:d2:e8:7e:84:dd:ff:98:05:5e:6f:35:66:51:53
shell : /bin/bash
sudo : ALL=(ALL) ALL
user : app-admin
--------------------------------------------------------------------------------
0.516901

INFO: sshd-wrapper starting sshd
2019-06-20 00:10:36,852 INFO exited: sshd-bootstrap (exit status 0; expected)
Server listening on 0.0.0.0 port 22.
Server listening on :: port 22.
2019-06-20 00:10:41,872 INFO success: sshd-wrapper entered RUNNING state, process has stayed up for > than 5 seconds (startsecs)
```

#### Environment variables

There are several environmental variables defined at runtime these allow the operator to customise the running container.

##### ENABLE_SSHD_BOOTSTRAP & ENABLE_SSHD_WRAPPER

It may be desirable to prevent the startup of the sshd-bootstrap script and/or sshd daemon. For example, when using an image built from this Dockerfile as the source for another Dockerfile you could disable both sshd-booststrap and sshd from startup by setting `ENABLE_SSHD_BOOTSTRAP` and `ENABLE_SSHD_WRAPPER` to `false`. The benefit of this is to reduce the number of running processes in the final container.

```
...
  --env "ENABLE_SSHD_BOOTSTRAP=false" \
  --env "ENABLE_SSHD_WRAPPER=false" \
...
```

##### ENABLE_SUPERVISOR_STDOUT

This image has `supervisor_stdout` installed which can be used to allow a process controlled by supervisord to send output to both a log file and stdout. It is recommended to simply output to stdout in order to reduce the number of running processes to a minimum. Setting `ENABLE_SUPERVISOR_STDOUT` to "false" will prevent the startup of `supervisor_stdout`. Where an image requires this feature for its logging output `ENABLE_SUPERVISOR_STDOUT` should be set to "true".

##### SSH_AUTHORIZED_KEYS

As detailed below the public key added for the SSH user is insecure by default. This is intentional and allows for access using a known private key. Using `SSH_AUTHORIZED_KEYS` you can replace the insecure public key with another one (or several). Further details on how to create your own private + public key pair are provided below. If adding more than one key it is recommended to either base64 encode the value or use a container file path in combination with a bind mounted file or Docker Swarm config etc.

```
...
--env "SSH_AUTHORIZED_KEYS=
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAqmLedI2mEJimvIm1OzT1EYJCMwegL/jfsXARLnYkZvJlEHFYDmRgS+YQ+MA9PKHyriCPmVNs/6yVc2lopwPWioXt0+ulH/H43PgB6/4fkP0duauHsRtpp7z7dhqgZOXqdLUn/Ybp0rz0+yKUOBb9ggjE5n7hYyDGtZR9Y11pJ4TuRHmL6wv5mnj9WRzkUlJNYkr6X5b6yAxtQmX+2f33u2qGdAwADddE/uZ4vKnC0jFsv5FdvnwRf2diF/9AagDb7xhZ9U3hPOyLj31H/OUce4xBpGXRfkUYkeW8Qx+zEbEBVlGxDroIMZmHJIknBDAzVfft+lsg1Z06NCYOJ+hSew== another public key
"  \
...
```

> **Note:** The `base64` command on Mac OSX will encode a file without line breaks by default but if using the command on Linux you need to include use the `-w` option to prevent wrapping lines at 80 characters. i.e. `base64 -w 0 -i {{key-path}}`.

```
...
  --env "SSH_AUTHORIZED_KEYS=$(
    cat ${HOME}/.ssh/id_rsa.pub ${HOME}/.ssh/another_id_rsa.pub | base64 -i -
  )" \
...
```

Using `SSH_AUTHORIZED_KEYS` with a container file path allows for the authorized_keys to be populated from the file path.

```
...
  --env "SSH_AUTHORIZED_KEYS=/var/run/config/authorized_keys"
...
```

##### SSH_CHROOT_DIRECTORY

This option is only applicable when `SSH_USER_FORCE_SFTP` is set to `true`. When using the SFTP option the user is jailed into the ChrootDirectory. The value can contain the placeholders `%h` and `%u` which will be replaced with the values of `SSH_USER_HOME` and `SSH_USER` respectively. The default value of `%h` is the best choice in most cases but the user requires a sub-directory in their HOME directory which they have write access to. If no volume is mounted into the path of the SSH user's HOME directory then a directory named `_data` is created automatically. If you need the user to be able to write to their HOME directory then use an alternative value such as `/chroot/%u` so that the user's HOME path, (relative to the ChrootDirectory), becomes `/chroot/app-admin/home/app-admin` by default.

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

##### SSH_PASSWORD_AUTHENTICATION

The SSH password authentication is disabled by default; allowing access by public/private key based authentication only. This is the recommended configuration however it may be necessary to allow password based access if you have client's that are unable to use key based authentication. Use `SSH_PASSWORD_AUTHENTICATION` to enable password authentication.

```
...
  --env "SSH_PASSWORD_AUTHENTICATION=true" \
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
  --env "SSH_USER=centos" \
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
  --env "SSH_USER_HOME=/home/centos" \
...
```

##### SSH_USER_PASSWORD

On first run the SSH user is created with a generated password. If you require a specific password `SSH_USER_PASSWORD` can be used when running the container. If set to an empty string then a password is auto-generated and, if `SSH_SUDO` is not set to allow no password for all commands, will be displayed in the docker logs.

```
...
  --env "SSH_USER_PASSWORD=Passw0rd!" \
...
```

If set to a valid container file path the value will be read from the file - this allows for setting the value securely when combined with an orchestration feature such as Docker Swarm secrets.

```
...
  --env "SSH_USER_PASSWORD=/var/run/secrets/ssh_user_password" \
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

To generate a hashed password string for the password `Passw0rd!`, use the following method.

```
$ docker run --rm jdeathe/centos-ssh \
  env PASSWORD=Passw0rd! \
  python -c "import crypt,os; print crypt.crypt(os.environ.get('PASSWORD'))"
```

##### SSH_USER_PRIVATE_KEY

Use `SSH_USER_PRIVATE_KEY` to set an RSA private key for `SSH_USER`. It is recommended to use a container file path in combination with a secrets feature of your orchestration system e.g. Docker Swarm secrets. Alternatively, a container file path in combination with a bind mounted file or base64 encode the value (without line-breaks).

> **Note:** Setting a value has no effect if `SSH_USER_FORCE_SFTP` is set to "true" (i.e. running in SFTP mode).

If set to a valid container file path the value will be read from the file - this allows for setting the value securely when combined with an orchestration feature such as Docker Swarm secrets.

```
...
  --env "SSH_USER_PRIVATE_KEY=/var/run/secrets/ssh_user_private_key"
...
```

> **Note:** The `base64` command on Mac OSX will encode a file without line breaks by default but if using the command on Linux you need to include use the `-w` option to prevent wrapping lines at 80 characters. i.e. `base64 -w 0 -i {{key-path}}`.

```
...
  --env "SSH_USER_PRIVATE_KEY=$(
    base64 -i ${HOME}/.ssh/id_rsa
  )" \
...
```

##### SSH_USER_SHELL

On first run the SSH user is created with a default shell of "/bin/bash". If you require a specific shell `SSH_USER_SHELL` can be used when running the container. You could use "/sbin/nologin" to prevent login with the user account.

```
...
  --env "SSH_USER_SHELL=/bin/sh" \
...
```

##### SSH_USER_ID

Use `SSH_USER_ID` to set a specific UID:GID for the `SSH_USER`. The values should be 500 or more for non system users - the default being 500:500. Using values in the range 2-499 is possible but should be used with caution as these values may conflict with existing system accounts.

This may be useful when running an SFTP container and mounting data volumes from an existing container.

```
...
  --env "SSH_USER_ID=1000:1000" \
...
```

##### SYSTEM_TIMEZONE

If you require a locale based system time zone `SYSTEM_TIMEZONE` can be used when running the container.

```
...
  --env "SYSTEM_TIMEZONE=Europe/London" \
...
```

### Connect to the running container using SSH

#### PasswordAuthentication disabled (default)

> **Note:** This documents the process of connecting with a known private key which is **insecure by default**. It is recommended that an alternative private/public key pair is created and used in place of the default value if running a container outside of a local test environment.

Create the .ssh directory in your home directory with the permissions required by SSH.

```
$ mkdir -pm 700 ~/.ssh
```

Get the [Vagrant](http://www.vagrantup.com/) insecure public key using curl.

```
$ curl -LsSO https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant && \
  mv vagrant ~/.ssh/id_rsa_insecure && \
  chmod 600 ~/.ssh/id_rsa_insecure
```

There should now be a new private SSH key installed in the path `~/.ssh/id_rsa_insecure`.

Next, unless specified in the run command, it is necessary to determine what port to connect to on the docker host. For a container named "ssh.1" use the following command:

```
$ docker port ssh.1 22
```

To connect to the running container use the following, where "app-admin" is the default `SSH_USER` value.

```
$ ssh \
  -o Port={{container-port}} \
  -o StrictHostKeyChecking=no \
  -i ~/.ssh/id_rsa_insecure \
  app-admin@{{docker-host-ip}}
```

#### PasswordAuthentication enabled

If connecting to a container running with `SSH_PASSWORD_AUTHENTICATION` set to "true" the process of connecting is simplified and the command used differs slightly.

```
$ ssh \
  -o Port={{container-port}} \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  app-admin@{{docker-host-ip}}
```
