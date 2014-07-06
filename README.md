centos-ssh
==========

Docker Image of CentOS-6 6.5 x86_64

The Dockerfile can be used to build a base image that is the bases for several other docker images.

Included in the build is the EPEL repository and SSH, vi and sudo are installed along with python-pip, supervisor and supervisor-stdout.

[Supervisor](http://supervisord.org/) is used to start and the sshd daemon when a docker container based on this image is run. To enable simple viewing of stdout for the sshd subprocess, supervisor-stdout is included. This allows you to see output from the supervisord controlled subprocesses with `docker logs <docker-container-name>`.

SSH access is by public key authentication and, by default, the [Vagrant](http://www.vagrantup.com/) [insecure private key](https://github.com/mitchellh/vagrant/blob/master/keys/vagrant) is required.

## Quick Example

```
$ sudo docker run -d \
  --name ssh.pool-1.1.1 \
  -p :22 \
  --volumes-from volume-config.ssh.pool-1.1.1 \
  jdeathe/centos-ssh:latest
```

## Instructions

### (Optional) Configuration Data Volume

Create a "data volume" for configuration, this allows you to share the same configuration between multiple docker containers and, by mounting a host directory into the data volume you can override the default configuration files provided.

Make a directory on the docker host for storing container configuration files. This directory needs to contain at least the following files:
- authorized_keys
- ssh-bootstrap.conf
- sshd_config
- supervisord.conf

```
$ sudo mkdir -p /etc/services-config/ssh.pool-1
```

Create the data volume, mounting our docker host's configuration directory to /etc/services-config/ssh in the docker container. Note that docker will pull the busybox:latest image if you don't already have available locally.

```
$ sudo docker run \
  --name volume-config.ssh.pool-1.1.1 \
  -v /etc/services-config/ssh.pool-1:/etc/services-config/ssh \
  busybox:latest \
  /bin/true
```

### Running

To run the a docker container from this image you can use the included run.sh and run.conf scripts. The helper script will stop any running container of the same name, remove it and run a new daemonised container on an unspecified host port. Alternatively you can use the following.

```
$ sudo docker stop ssh.pool-1.1.1
$ sudo docker rm ssh.pool-1.1.1
$ sudo docker run -d \
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
--------------------------------------------------------------------------------
SSH Credentials: 
root : ut5vZhb5
app-admin : s4pjZwT8
--------------------------------------------------------------------------------

2014-07-05 19:35:35,370 INFO exited: sshd_bootstrap (exit status 0; expected)

```

### Connect to the running container using SSH

If you have not already got one, create the .ssh directory in your home directory with the permissions required by SSH.

```
$ mkdir -pm 700 ~/.ssh

```

Get the [Vagrant](http://www.vagrantup.com/) insecure public key using curl (you could also use wget if you have that installed).


```
$  curl -LsSO https://github.com/mitchellh/vagrant/blob/master/keys/vagrant && mv vagrant ~/.ssh/id_rsa_insecure && chmod 600 ~/.ssh/id_rsa_insecure
```

If the command ran successfully you should now have a new private SSH key installed in your home "~/.ssh" directory called "id_rsa_insecure" 

Next we need to determine what port to connect to on the docker host. You can do this with ether `docker ps` or `docker inspect`. In the following example we use `docker ps` to show the list of running containers and pipe to grep to filter out the host port.

```
docker ps | grep ssh.pool-1.1.1 | grep -oe ':[0-9]*->22\/tcp' | grep -oe :[0-9]* | cut -c 2-
```

To connect to the running container use:

```
$ ssh -p <container-port> -i ~/.ssh/id_rsa_insecure app-admin@<docker-host-ip>
```
