# SCMI

Service Container Manager Interface (SCMI) is an [embedded installer](https://github.com/jdeathe/centos-ssh/blob/centos-7/src/usr/sbin/scmi) that has been included in the image since release tags `1.7.2` and `2.1.2`.

## SCMI installation examples

The following example uses docker to run the `scmi install` command to create and start a container named `ssh.1`. To use SCMI it requires the use of the `--privileged` docker run parameter and the docker host's root directory mounted as a volume with the container's mount directory also being set in the `scmi` `--chroot` option. The `--setopt` option is used to add extra parameters to the default docker run command template; in the following example a named configuration volume is added which allows the SSH host keys to persist after the first container initialisation.

> **Note:** The placeholder `{{NAME}}` can be used in options and is replaced with the container's name.

> **Note:** In the following examples replace `{{latest-release-tag}}` with the [latest release tag](https://github.com/jdeathe/centos-ssh/releases/latest)

### SCMI install

```
$ docker run \
  --rm \
  --privileged \
  --volume /:/media/root \
  jdeathe/centos-ssh:{{latest-release-tag}} \
  /usr/sbin/scmi install \
    --chroot=/media/root \
    --tag={{latest-release-tag}} \
    --name=ssh.1 \
    --setopt="--volume {{NAME}}.config-ssh:/etc/ssh"
```

### SCMI uninstall

To uninstall the previous example simply run the same docker run command with the scmi `uninstall` command.

```
$ docker run \
  --rm \
  --privileged \
  --volume /:/media/root \
  jdeathe/centos-ssh:{{latest-release-tag}} \
  /usr/sbin/scmi uninstall \
    --chroot=/media/root \
    --tag={{latest-release-tag}} \
    --name=ssh.1 \
    --setopt="--volume {{NAME}}.config-ssh:/etc/ssh"
```

### SCMI systemd support

If your docker host has systemd (and optionally etcd) installed then `scmi` provides a method to install the container as a systemd service unit. This provides some additional features for managing a group of instances on a single docker host and has the option to use an etcd backed service registry. Using a systemd unit file allows the System Administrator to use a Drop-In to override the settings of a unit-file template used to create service instances. To use the systemd method of installation use the `-m` or `--manager` option of `scmi` and to include the optional etcd register companion unit use the `--register` option.

```
$ docker run \
  --rm \
  --privileged \
  --volume /:/media/root \
  jdeathe/centos-ssh:{{latest-release-tag}} \
  /usr/sbin/scmi install \
    --chroot=/media/root \
    --tag={{latest-release-tag}} \
    --name=ssh.1 \
    --manager=systemd \
    --register \
    --env='SSH_SUDO="ALL=(ALL) NOPASSWD:ALL"' \
    --env='SSH_USER="centos"' \
    --setopt='--volume {{NAME}}.config-ssh:/etc/ssh'
```

### SCMI image information

Since release tags `1.7.2` and `2.1.2` the install template has been added to the image metadata. Using docker inspect, you can access `scmi` to perform install/uninstall tasks.

> **Note:** A prerequisite of the following examples is that the image has been pulled (or loaded from the release package).

```
$ docker pull jdeathe/centos-ssh:{{latest-release-tag}}
```

To see detailed information about the image run `scmi` with the `--info` option. To see all available `scmi` options run with the `--help` option.

```
$ eval "sudo -E $(
    docker inspect \
    -f "{{.ContainerConfig.Labels.install}}" \
    jdeathe/centos-ssh:{{latest-release-tag}}
  ) --info"
```

To perform an installation using the docker name `ssh.2` simply use the `--name` or `-n` option.

```
$ eval "sudo -E $(
    docker inspect \
    -f "{{.ContainerConfig.Labels.install}}" \
    jdeathe/centos-ssh:{{latest-release-tag}}
  ) --name=ssh.2"
```

To uninstall use the *same command* that was used to install but with the `uninstall` Label.

```
$ eval "sudo -E $(
    docker inspect \
    -f "{{.ContainerConfig.Labels.uninstall}}" \
    jdeathe/centos-ssh:{{latest-release-tag}}
  ) --name=ssh.2"
```

### SCMI on Atomic Host

With the addition of install/uninstall image labels it is possible to use [Project Atomic's](http://www.projectatomic.io/) `atomic install` command to simplify install/uninstall tasks on [CentOS Atomic](https://wiki.centos.org/SpecialInterestGroup/Atomic) Hosts.

To see detailed information about the image run `scmi` with the `--info` option. To see all available `scmi` options run with the `--help` option.

```
$ sudo -E atomic install \
  -n ssh.3 \
  jdeathe/centos-ssh:{{latest-release-tag}} \
  --info
```

To perform an installation using the docker name `ssh.3` simply use the `-n` option of the `atomic install` command.

```
$ sudo -E atomic install \
  -n ssh.3 \
  jdeathe/centos-ssh:{{latest-release-tag}}
```

Alternatively, you could use the `scmi` options `--name` or `-n` for naming the container.

```
$ sudo -E atomic install \
  jdeathe/centos-ssh:{{latest-release-tag}} \
  --name ssh.3
```

To uninstall use the *same command* that was used to install but with the `uninstall` Label.

```
$ sudo -E atomic uninstall \
  -n ssh.3 \
  jdeathe/centos-ssh:{{latest-release-tag}}
```