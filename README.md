centos-ssh
==========

Docker Image of CentOS-6 6.7 x86_64

Includes public key authentication, Automated password generation, supports custom configuration via a configuration data volume.

## Overview & links

The [Dockerfile](https://github.com/jdeathe/centos-ssh/blob/centos-6/Dockerfile) can be used to build a base image that is the bases for several other docker images.

Included in the build is the EPEL repository, the IUS repository and SSH, vi and are installed along with python-pip, supervisor and supervisor-stdout.

[Supervisor](http://supervisord.org/) is used to start and the sshd daemon when a docker container based on this image is run. To enable simple viewing of stdout for the sshd subprocess, supervisor-stdout is included. This allows you to see output from the supervisord controlled subprocesses with `docker logs <docker-container-name>`.

SSH access is by public key authentication and, by default, the [Vagrant](http://www.vagrantup.com/) [insecure private key](https://github.com/mitchellh/vagrant/blob/master/keys/vagrant) is required.

### SSH Alternatives

SSH is not required in order to access a terminal for the running container. The simplest method is to use the docker exec command to run bash (or sh) as follows: 

```
$ docker exec -it <docker-name-or-id> bash
```

For cases where access to docker exec is not possible the preferred method is to use Command Keys and the nsenter command. See [command-keys.md](https://github.com/jdeathe/centos-ssh/blob/centos-6/command-keys.md) for details on how to set this up.

## Quick Example

Run up a container named 'ssh.pool-1.1.1' from the docker image 'jdeathe/centos-ssh' on port 2020 of your docker host.

```
$ docker run -d \
  --name ssh.pool-1.1.1 \
  -p 2020:22 \
  jdeathe/centos-ssh:latest
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
  --volumes-from=volume-config.ssh.pool-1.1.1 \
  jdeathe/centos-ssh:latest \
  vi /etc/services-config/<path_to_file>
```

##### Required configuration files
- [ssh/authorized_keys](https://github.com/jdeathe/centos-ssh/blob/centos-6/etc/services-config/ssh/authorized_keys)
- [ssh/ssh-bootstrap.conf](https://github.com/jdeathe/centos-ssh/blob/centos-6/etc/services-config/ssh/ssh-bootstrap.conf)
- [ssh/sshd_config](https://github.com/jdeathe/centos-ssh/blob/centos-6/etc/services-config/ssh/sshd_config)
- [supervisor/supervisord.conf](https://github.com/jdeathe/centos-ssh/blob/centos-6/etc/services-config/supervisor/supervisord.conf)

### Running

To run the a docker container from this image you can use the included run.sh and run.conf scripts. The helper script will stop any running container of the same name, remove it and run a new daemonised container on an unspecified host port. Alternatively you can use the following methods.

#### Using environment variables

The following example overrides the default "app-admin" SSH username and home directory path with "app-user". The same technique could also be applied to set the SSH_USER_PASSWORD value.

*Note:* Settings applied by environment variables will override those set within configuration volumes from release 1.3.1. Existing installations that use the ssh-bootstrap.conf saved on a configuration "data" volume will not allow override by the environment variables. Also users can update ssh-bootstrap.conf to prevent the value being replaced by that set using the environment variable.

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

The following example uses the settings from the optonal configuration volume volume-config.ssh.pool-1.1.1.

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
sshd_bootstrap stdout | Initialise SSH...
sshd_bootstrap stdout | 
================================================================================
SSH Credentials
-------------------------------------------------------------------------------- 
root : ut5vZhb5
app-admin : s4pjZwT8
--------------------------------------------------------------------------------

2014-07-05 19:35:35,370 INFO exited: sshd_bootstrap (exit status 0; expected)
```

#### Runtime Environment Variables

There are several environmental variables defined at runtime these allow the operator to customise the running container.

##### 1. SSH_USER

On first run the SSH user is created with the default username of "app-admin". If you require an alternative username ```SSH_USER``` can be used when running the container.

```
...
  --env "SSH_USER=app-1" \
...
```

##### 2. SSH_USER_HOME_DIR

On first run the SSH user is created with the default HOME directory of "/home/app-admin". If you require an alternative HOME directory ```SSH_USER_HOME_DIR``` can be used when running the container.

```
...
  --env "SSH_USER_HOME_DIR=/home/app-1" \
...
```

##### 3. SSH_USER_PASSWORD

On first run the SSH user is created with a generated password. If you require a specific password ```SSH_USER_PASSWORD``` can be used when running the container.

```
...
  --env "SSH_USER_PASSWORD=Passw0rd!" \
...
```

##### 4. SSH_USER_SHELL

On first run the SSH user is created with a default shell of "/bin/bash". If you require a specific shell ```SSH_USER_SHELL``` can be used when running the container. You could use "/sbin/nologin" to prevent login with the user account.

```
...
  --env "SSH_USER_SHELL=/bin/sh" \
...
```

##### 5. SSH_SUDO

On first run the SSH user is created with a the sudo rule ```ALL=(ALL)  ALL``` which allows the user to run all commands but a password is required. If you want to limit the access to specific commands or allow sudo without a password prompt ```SSH_SUDO``` can be used.

```
...
  --env "SSH_SUDO=ALL=(ALL) NOPASSWD:ALL" \
...
```

##### 6. SSH_AUTHORIZED_KEYS

As detailed below the public key added for the SSH user is insecure by default. This is intentional and allows for access using a known private key. Using ```SSH_AUTHORIZED_KEYS``` you can replace the insecure public key with another one (or several). Further details on how to create your own private + public key pair are detailed below.

```
...
--env "SSH_AUTHORIZED_KEYS=
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAqmLedI2mEJimvIm1OzT1EYJCMwegL/jfsXARLnYkZvJlEHFYDmRgS+YQ+MA9PKHyriCPmVNs/6yVc2lopwPWioXt0+ulH/H43PgB6/4fkP0duauHsRtpp7z7dhqgZOXqdLUn/Ybp0rz0+yKUOBb9ggjE5n7hYyDGtZR9Y11pJ4TuRHmL6wv5mnj9WRzkUlJNYkr6X5b6yAxtQmX+2f33u2qGdAwADddE/uZ4vKnC0jFsv5FdvnwRf2diF/9AagDb7xhZ9U3hPOyLj31H/OUce4xBpGXRfkUYkeW8Qx+zEbEBVlGxDroIMZmHJIknBDAzVfft+lsg1Z06NCYOJ+hSew== another public key
"  \
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

To copy your file to a remote docker host where using a configuration volume mapping of "volume-config.ssh.pool-1.1.1:/etc/services-config" linked to a running container named "ssh.pool-1.1.1" use:

```
$ docker cp ~/.ssh/id_rsa.pub \
  ssh.pool-1.1.1:/var/lib/docker/volumes/etc/services-config/ssh/authorized_keys
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

#### [ssh/ssh-bootstrap.conf](https://github.com/jdeathe/centos-ssh/blob/centos-6/etc/services-config/ssh/ssh-bootstrap.conf)

The bootstrap script sets up the sudo user and generates a random 8 character password you can override this behaviour by supplying your own values in your custom ssh-bootstrap.conf file. You can also change the sudoer username to something other that the default "app-admin".

#### [ssh/sshd_config](https://github.com/jdeathe/centos-ssh/blob/centos-6/etc/services-config/ssh/sshd_config)

The SSH daemon options can be overridden with your custom sshd_config file.

#### [supervisor/supervisord.conf](https://github.com/jdeathe/centos-ssh/blob/centos-6/etc/services-config/supervisor/supervisord.conf)

The supervisor service's configuration can also be overridden by editing the custom supervisord.conf file. It shouldn't be necessary to change the existing configuration here but you could include more [program:x] sections to run additional commands at startup.