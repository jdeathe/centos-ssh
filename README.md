centos-ssh
==========

Docker Image of CentOS-6 6.7 x86_64

Includes public key authentication, Automated password generation, supports custom configuration via environment variables and/or a configuration data volume.

## Overview & links

The [Dockerfile](https://github.com/jdeathe/centos-ssh/blob/centos-6/Dockerfile) can be used to build a base image that is the bases for several other docker images.

Included in the build are the [SCL](https://www.softwarecollections.org/), [EPEL](http://fedoraproject.org/wiki/EPEL) and [IUS](https://ius.io) repositories. Installed packages include [OpenSSH](http://www.openssh.com/portable.html) secure shell, [Sudo](http://www.courtesan.com/sudo/) and [vim-minimal](http://www.vim.org/) are along with python-setuptools, [supervisor](http://supervisord.org/) and [supervisor-stdout](https://github.com/coderanger/supervisor-stdout).

[Supervisor](http://supervisord.org/) is used to start and the sshd daemon when a docker container based on this image is run. To enable simple viewing of stdout for the sshd subprocess, supervisor-stdout is included. This allows you to see output from the supervisord controlled subprocesses with `docker logs <docker-container-name>`.

SSH access is by public key authentication and, by default, the [Vagrant](http://www.vagrantup.com/) [insecure private key](https://github.com/mitchellh/vagrant/blob/master/keys/vagrant) is required.

### SSH Alternatives

SSH is not required in order to access a terminal for the running container. The simplest method is to use the docker exec command to run bash (or sh) as follows:

```
$ docker exec -it <docker-name-or-id> bash
```

For cases where access to docker exec is not possible the preferred method is to use Command Keys and the nsenter command. See [command-keys.md](https://github.com/jdeathe/centos-ssh/blob/centos-6/command-keys.md) for details on how to set this up.

## Quick Example

### SSH Mode

Run up an SSH container named 'ssh.pool-1.1.1' from the docker image 'jdeathe/centos-ssh' on port 2020 of your docker host.

```
$ docker run -d \
  --name ssh.pool-1.1.1 \
  -p 2020:22 \
  jdeathe/centos-ssh:latest
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
  app-admin@<docker-host-ip>
```

### SFTP Mode

Run up an SFTP container named 'sftp.pool-1.1.1' from the docker image 'jdeathe/centos-ssh' on port 2021 of your docker host.

```
$ docker run -d \
  --name sftp.pool-1.1.1 \
  -p 2021:22 \
  -e SSH_USER_FORCE_SFTP=true \
  jdeathe/centos-ssh:latest
```

Connect using the `sftp` command line client with the [insecure private key](https://github.com/mitchellh/vagrant/blob/master/keys/vagrant).

```
$ sftp -p 2021 -i id_rsa_insecure \
  app-admin@<docker-host-ip>
```

## Instructions

### (Optional) Configuration Data Volume

A configuration "data volume" allows you to share the same configuration files between multiple docker containers. Docker mounts a host directory into the data volume allowing you to edit the default configuration files and have those changes persist.

#### Standard volume

Naming of the volume is optional, it is possible to leave the naming up to Docker by simply specifying the container path only.

```
$ docker run \
  --name volume-config.ssh.pool-1.1.1 \
  -v /etc/services-config \
  jdeathe/centos-ssh:latest \
  /bin/true
```

To identify the docker host directory path to the volume within the container volume-config.ssh.pool-1.1.1 you can use ```docker inspect``` to view the Mounts.

```
$ docker inspect \
  --format '{{ json (index .Mounts 0).Source }}' \
  volume-config.ssh.pool-1.1.1
```

#### Named volume

To create a named data volume, mounting our docker host's configuration directory /var/lib/docker/volumes/volume-config.ssh.pool-1.1.1 to /etc/services-config in the docker container use the following run command. Note that we use the same image as for the application container to reduce the number of images/layers required.

```
$ docker run \
  --name volume-config.ssh.pool-1.1.1 \
  -v volume-config.ssh.pool-1.1.1:/etc/services-config \
  jdeathe/centos-ssh:latest \
  /bin/true
```

When using named volumes the directory path from the docker host mounts the path on the container so we need to upload the configuration files. The simplest method of achieving this is to upload the contents of the [etc/services-config](https://github.com/jdeathe/centos-ssh/blob/centos-6/etc/services-config/) directory using ```docker cp```.

```
$ docker cp \
  ./etc/services-config/. \
  volume-config.ssh.pool-1.1.1:/etc/services-config
```

#### Editing configuration

To make changes to the configuration files you need a running container that uses the volumes from the configuration volume. To edit a single file you could use the following, where <path_to_file> can be one of the [required configuration files](https://github.com/jdeathe/centos-ssh/blob/centos-6/README.md#required-configuration-files), or you could run a ```bash``` shell and then make the changes required using ```vi```. On exiting the container it will be removed since we specify the ```--rm``` parameter.

```
$ docker run --rm -it \
  --volumes-from volume-config.ssh.pool-1.1.1 \
  jdeathe/centos-ssh:latest \
  vi /etc/services-config/<path_to_file>
```

##### Required configuration files

The following configuration files are required to run the application container and should be located in the directory /etc/services-config/.

- [ssh/authorized_keys](https://github.com/jdeathe/centos-ssh/blob/centos-6/etc/services-config/ssh/authorized_keys)
- [ssh/sshd-bootstrap.conf](https://github.com/jdeathe/centos-ssh/blob/centos-6/etc/services-config/ssh/sshd-bootstrap.conf)
- [ssh/sshd-bootstrap.env](https://github.com/jdeathe/centos-ssh/blob/centos-6/etc/services-config/ssh/sshd-bootstrap.env)
- [ssh/sshd_config](https://github.com/jdeathe/centos-ssh/blob/centos-6/etc/services-config/ssh/sshd_config)
- [supervisor/supervisord.conf](https://github.com/jdeathe/centos-ssh/blob/centos-6/etc/services-config/supervisor/supervisord.conf)
- [supervisor/supervisord.d/sshd.conf](https://github.com/jdeathe/centos-ssh/blob/centos-6/etc/services-config/supervisor/supervisord.d/sshd.conf)
- [supervisor/supervisord.d/sshd-bootstrap.conf](https://github.com/jdeathe/centos-ssh/blob/centos-6/etc/services-config/supervisor/supervisord.d/sshd-bootstrap.conf)

### Running

To run the a docker container from this image you can use the included [run.sh](https://github.com/jdeathe/centos-ssh/blob/centos-6/run.sh) and [run.conf](https://github.com/jdeathe/centos-ssh/blob/centos-6/run.conf) scripts. The helper script will stop any running container of the same name, remove it and run a new daemonised container on an unspecified host port. Alternatively you can use the following methods.

#### Using environment variables

The following example overrides the default "app-admin" SSH username and home directory path with "app-user". The same technique could also be applied to set the SSH_USER_PASSWORD value.

*Note:* Settings applied by environment variables will override those set within configuration volumes from release 1.3.1. Existing installations that use the sshd-bootstrap.conf saved on a configuration "data" volume will not allow override by the environment variables. Also users can update sshd-bootstrap.conf to prevent the value being replaced by that set using the environment variable.

```
$ docker stop ssh.pool-1.1.1 \
  && docker rm ssh.pool-1.1.1 \
  ; docker run -d \
  --name ssh.pool-1.1.1 \
  -p :22 \
  --env "SSH_USER=app-user" \
  --env "SSH_USER_HOME_DIR=/home/app-user" \
  jdeathe/centos-ssh:latest
```

#### Using configuration volume

The following example uses the settings from the optional configuration volume volume-config.ssh.pool-1.1.1.

```
$ docker stop ssh.pool-1.1.1 \
  && docker rm ssh.pool-1.1.1 \
  ; docker run -d \
  --name ssh.pool-1.1.1 \
  -p :22 \
  --volumes-from volume-config.ssh.pool-1.1.1 \
  jdeathe/centos-ssh:latest
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
SSH Credentials
--------------------------------------------------------------------------------
user : app-user
password : QDQE12uVMyagLEsQ
uid : 500
home : /home/app-admin
chroot path : N/A
shell : /bin/bash
sudo : ALL=(ALL) ALL
key fingerprints :
dd:3b:b8:2e:85:04:06:e9:ab:ff:a8:0a:c0:04:6e:d6 (insecure key)
--------------------------------------------------------------------------------

sshd stdout | Server listening on 0.0.0.0 port 22.
sshd stdout | Server listening on :: port 22.
2016-02-01 02:26:54,464 INFO exited: sshd-bootstrap (exit status 0; expected)
```

#### Runtime Environment Variables

There are several environmental variables defined at runtime these allow the operator to customise the running container.

##### SSH_AUTHORIZED_KEYS

As detailed below the public key added for the SSH user is insecure by default. This is intentional and allows for access using a known private key. Using ```SSH_AUTHORIZED_KEYS``` you can replace the insecure public key with another one (or several). Further details on how to create your own private + public key pair are detailed below.

```
...
--env "SSH_AUTHORIZED_KEYS=
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAqmLedI2mEJimvIm1OzT1EYJCMwegL/jfsXARLnYkZvJlEHFYDmRgS+YQ+MA9PKHyriCPmVNs/6yVc2lopwPWioXt0+ulH/H43PgB6/4fkP0duauHsRtpp7z7dhqgZOXqdLUn/Ybp0rz0+yKUOBb9ggjE5n7hYyDGtZR9Y11pJ4TuRHmL6wv5mnj9WRzkUlJNYkr6X5b6yAxtQmX+2f33u2qGdAwADddE/uZ4vKnC0jFsv5FdvnwRf2diF/9AagDb7xhZ9U3hPOyLj31H/OUce4xBpGXRfkUYkeW8Qx+zEbEBVlGxDroIMZmHJIknBDAzVfft+lsg1Z06NCYOJ+hSew== another public key
"  \
...
```

##### SSH_CHROOT_DIRECTORY

This option is only applicable when ```SSH_USER_FORCE_SFTP``` is set to `true`. When using the using the SFTP option the user is jailed into the ChrootDirectory. The value can contain the placeholders `%h` and `%u` which will be replaced with the values of ```SSH_USER_HOME_DIR``` and ```SSH_USER``` respectively. The default value of `%h` is the best choice in most cases but the user requires a sub-directory in their HOME directory which they have write access to. If no volume is mounted into the path of the SSH user's HOME directory the a directory named `_data` is created automatically. If you need the user to be able to write to their HOME directory they use an alternative value such as `/chroot/%u` so that the user's HOME path, (relative to the ChrootDirectory), becomes `/chroot/app-admin/home/app-admin` by default.

```
...
  --env "SSH_CHROOT_DIRECTORY=%h" \
...
```

##### SSH_INHERIT_ENVIRONMENT

The SSH user's environment is reset by default meaning that the Docker environmental variables are not available. Use ```SSH_INHERIT_ENVIRONMENT``` to allow the Docker environment variables to be passed to the SSH user's environment. Note that some values are removed to prevent issues; such as SSH_USER_PASSWORD, HOME, HOSTNAME, PATH, TERM etc.

```
...
  --env "SSH_INHERIT_ENVIRONMENT=true" \
...
```

##### SSH_SUDO

On first run the SSH user is created with a the sudo rule ```ALL=(ALL)  ALL``` which allows the user to run all commands but a password is required. If you want to limit the access to specific commands or allow sudo without a password prompt ```SSH_SUDO``` can be used.

```
...
  --env "SSH_SUDO=ALL=(ALL) NOPASSWD:ALL" \
...
```

##### SSH_USER

On first run the SSH user is created with the default username of "app-admin". If you require an alternative username ```SSH_USER``` can be used when running the container.

```
...
  --env "SSH_USER=app-1" \
...
```

##### SSH_USER_FORCE_SFTP

To force the use of the internal-sftp command set ```SSH_USER_FORCE_SFTP``` to `true`. This will prevent shell access, remove the ability to use `sudo` and restrict the user to the ChrootDirectory set using ```SSH_SHROOT_DIRECTORY```. Using SFTP in combination with --volumes-from another running container can be used to allow write access to an applications data volume - for example using the ```SSH_USER_HOME_DIR``` value to `/var/www/` could be used to allow access to the data volume of an Apache container.

```
...
  --env "SSH_USER_FORCE_SFTP=false" \
...
```

##### SSH_USER_HOME_DIR

On first run the SSH user is created with the default HOME directory of "/home/app-admin". If you require an alternative HOME directory ```SSH_USER_HOME_DIR``` can be used when running the container.

```
...
  --env "SSH_USER_HOME_DIR=/home/app-1" \
...
```

##### SSH_USER_PASSWORD

On first run the SSH user is created with a generated password. If you require a specific password ```SSH_USER_PASSWORD``` can be used when running the container. If set to an empty string then a password is auto-generated and, if ```SSH_SUDO``` is not set to allow no password for all commands, will be displayed in the docker logs.

```
...
  --env "SSH_USER_PASSWORD=Passw0rd!" \
...
```

##### SSH_USER_PASSWORD_HASHED

If setting a password for the SSH user you might not want to store the plain text password value in the ```SSH_USER_PASSWORD``` environment variable. Setting ```SSH_USER_PASSWORD_HASHED``` to `true` indicates that the value stored in ```SSH_USER_PASSWORD``` should be treated as a crypt SHA-512 salted password hash.

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

On first run the SSH user is created with a default shell of "/bin/bash". If you require a specific shell ```SSH_USER_SHELL``` can be used when running the container. You could use "/sbin/nologin" to prevent login with the user account.

```
...
  --env "SSH_USER_SHELL=/bin/sh" \
...
```

##### SSH_USER_UID

Use ```SSH_USER_UID``` to set a specific UID for the ```SSH_USER```. The value should be greater than or equal to 500 - where the default is 500. This may be useful when running an SFTP container and mounting data volumes from an existing container.

```
...
  --env "SSH_USER_UID=500" \
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
$ ssh -p <container-port> \
  -i ~/.ssh/id_rsa_insecure \
  app-admin@<docker-host-ip> \
  -o StrictHostKeyChecking=no
```

### Custom Configuration

If using the optional data volume for container configuration you are able to customise the configuration. In the following examples your custom docker configuration files should be located on the Docker host under the directory ```/var/lib/docker/volumes/<volume-name>/``` where ```<volume-name>``` should identify the applicable container name such as "volume-config.ssh.pool-1.1.1" if using named volumes or will be an ID generated automatically by Docker. To identify the correct path on the Docker host use the ```docker inspect``` command.

#### [ssh/authorized_keys](https://github.com/jdeathe/centos-ssh/blob/centos-6/etc/services-config/ssh/authorized_keys)

The supplied insecure private key is for demonstration/review purposes only. You should create your own private key if you don't already have one using the following command; pressing the enter key when asked for a passphrase to prevent you being prompted for a passphrase.

```
$ ssh-keygen -q -t rsa -f ~/.ssh/id_rsa
```

You should now have an SSH public key, (~/.ssh/id_rsa.pub), that can be used to replace the default one in your custom authorized_keys file.

To copy your file to a remote docker host where using a configuration "data" volume container named "volume-config.ssh.pool-1.1.1" with a volume mapping of "volume-config.ssh.pool-1.1.1:/etc/services-config" use:

```
$ docker cp ~/.ssh/id_rsa.pub \
  volume-config.ssh.pool-1.1.1:/etc/services-config/ssh/authorized_keys
```

Alternatively, to replace the autorized_keys directly on a running container with the ```SSH_USER``` app-admin using SSH use:

```
$ cat ~/.ssh/id_rsa.pub | ssh -p <container-port> \
  -i ~/.vagrant.d/insecure_private_key \
  app-admin@<docker-host-ip> \
  "cat > ~/.ssh/authorized_keys"
```

To connect to the running container use:

```
$ ssh -p <container-port> \
  app-admin@<docker-host-ip> \
  -o StrictHostKeyChecking=no
```

#### [ssh/sshd-bootstrap.conf](https://github.com/jdeathe/centos-ssh/blob/centos-6/etc/services-config/ssh/sshd-bootstrap.conf)

The bootstrap script sets up the sudo user and generates a random 8 character password you can override this behaviour by supplying your own values in your custom sshd-bootstrap.conf file. You can also change the sudoer username to something other that the default "app-admin".

#### [ssh/sshd-bootstrap.env](https://github.com/jdeathe/centos-ssh/blob/centos-6/etc/services-config/ssh/sshd-bootstrap.env)

This is an intentionally empty file used for storing the Docker environment variables. If the environment variable ```SSH_INHERIT_ENVIRONMENT``` is set to true then environment variables stored in this file are added to the SSH user's environment.

#### [ssh/sshd_config](https://github.com/jdeathe/centos-ssh/blob/centos-6/etc/services-config/ssh/sshd_config)

The SSH daemon options can be overridden with your custom sshd_config file.

#### [supervisor/supervisord.conf](https://github.com/jdeathe/centos-ssh/blob/centos-6/etc/services-config/supervisor/supervisord.conf)

The supervisor service's primary configuration can also be overridden by editing the custom supervisord.conf file. Program specific configuration files will be loaded from /etc/supervisor.d/ from the container.

#### [supervisor/supervisord.d/sshd.conf](https://github.com/jdeathe/centos-ssh/blob/centos-6/etc/services-config/supervisor/supervisord.d/sshd.conf)

The supervisor program configuration for the sshd service.

#### [supervisor/supervisord.d/sshd-bootstrap.conf](https://github.com/jdeathe/centos-ssh/blob/centos-6/etc/services-config/supervisor/supervisord.d/sshd-bootstrap.conf)

The supervisor program configuration for the sshd_boostrap script.
