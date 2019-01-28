# Command Keys

Using command keys to access containers (without sshd).

Access docker containers using docker host SSH public key authentication and nsenter command to start up a bash terminal inside a container. In the following example the container name is "ssh.1"

## Create a unique public/private key pair for each container

```
$ cd ~/.ssh/ && ssh-keygen -q -t rsa -f id-rsa.ssh.1
```

## Prefix the public key with the nsenter command

```
$ sed -i '' \
  '1s#^#command="sudo nsenter -m -u -i -n -p -t $(docker inspect --format \\\"{{ .State.Pid }}\\\" ssh.1) /bin/bash" #' \
  ~/.ssh/id-rsa.ssh.1.pub
```

## Upload the public key to the docker host VM

The host in this example is core-01.local that has SSH public key authentication enabled using the Vagrant insecure private key.

### Generic Linux Host Example

```
$ cat ~/.ssh/id-rsa.ssh.1.pub | ssh -i ~/.vagrant.d/insecure_private_key \
  core@core-01.local \
  "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

### CoreOS Host Example

```
$ cat ~/.ssh/id-rsa.ssh.1.pub | ssh -i ~/.vagrant.d/insecure_private_key \
  core@core-01.local \
  update-ssh-keys -a core@ssh.1
```

### Usage

```
$ ssh -i ~/.ssh/id-rsa.ssh.1 \
  core@core-01.local \
  -o StrictHostKeyChecking=no
```

#### SSH Config

To simplify the command required to access the running container we can add an entry to the SSH configuration file ```~/.ssh/config``` as follows:

```
Host core-01.ssh.1
	HostName core-01.local
	Port 22
	User core
	StrictHostKeyChecking no
	IdentitiesOnly yes
	IdentityFile ~/.ssh/id-rsa.ssh.1
```

With the above entry in place we can now run the following to access the running container:

```
$ ssh core-01.ssh.1
```
