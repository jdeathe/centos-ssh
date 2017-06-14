# Change Log

## centos-6

Summary of release changes for Version 1 - CentOS-6

### 1.8.1 - 2017-06-14

- Adds clearer, improved [shpec](https://github.com/rylnd/shpec) test case output.
- Updates [supervisor](http://supervisord.org/changes.html) to version 3.3.2.
- Adds use of `/var/lock/subsys/` (subsystem lock directory) for bootstrap lock files.
- Adds a Docker healthcheck.

### 1.8.0 - 2017-05-24

- Update source to CentOS-6 6.9.
- Replaces deprecated Dockerfile `MAINTAINER` with a `LABEL`.
- Adds a `src` directory for the image root files.
- Adds wrapper functions to functional test cases.
- Adds `STARTUP_TIME` variable for the `logs-delayed` Makefile target.

### 1.7.6 - 2017-02-21

- Adds updated CentOS-7 version in `README.md` since updating to `7.3.1611`.
- Updates the `vim` package.
- Fixes `shpec` test definition to allow `make test` to be interruptible.
- Updates the `openssl` and `libxml2` packages that contain high risk security vulnerabilities.
- Adds `README.md` instruction to use `docker pull` before `docker inspect` on an image.

### 1.7.5 - 2016-12-15

- Adds updated `sudo` package.
- Adds functional tests using [shpec](https://github.com/rylnd/shpec). To run all tests, [install `shpec`](https://github.com/rylnd/shpec#installation) and run with `make test`.
- Adds support for running tests on Ubuntu. _Note: May require some additional setup prevent warnings about locale._

  ```
  sudo locale-gen en_US.UTF-8; sudo dpkg-reconfigure locales
  export LANG=en_US.UTF-8; unset LANGUAGE LC_ALL LC_CTYPE
  ```
- Adds correction to examples and test usage of the `sftp` command.
- Adds a "better practices" example of password hash generation in the `README.md`.
- Adds minor code style changes to the `Makefile`.

### 1.7.4 - 2016-12-04

- Adds correct Makefile usage instructions for 'build' target.
- Adds info regarding NULL port values in Makefile help.
- Removes requirement for `gawk` in the port handling functions for SCMI and the systemd template unit-file.
- Adds reduced number of build steps to image which helps reduce final image size.
- Adds `-u` parameter to `sshd` options to help reduce time spent doing DNS lookups during authentication.
- Adds a change log (`CHANGELOG.md`).
- Adds support for semantic version numbered tags.

### 1.7.3 - 2016-10-02

- Adds Makefile help target with usage instructions.
- Splits up the Makefile targets into internal and public types.
- Adds correct `scmi` path in usage instructions.
- Changes `PACKAGE_PATH` to `DIST_PATH` in line with the Makefile environment include. Not currently used by `scmi` but changing for consistency.
- Changes `DOCKER_CONTAINER_PARAMETERS_APPEND` to `DOCKER_CONTAINER_OPTS` for usability. This is a potentially breaking change that could affect systemd service configurations if using the Environment variable in a drop-in customisation. However, if using the systemd template unit-files it should be pinned to a specific version tag. The Makefile should only be used for development/testing and usage in `scmi` is internal only as the `--setopt` parameter is used to build up the optional container parameters. 
- Removes X-Fleet section from template unit-file.
- Adds support for Base64 encoded `SSH_AUTHORIZED_KEYS` values. This resolves issues with setting multiple keys for the systemd installations.

### 1.7.2 - 2016-09-16

- Fixed issue with sshd process not running on container startup.

### 1.7.1 - 2016-09-15

- Fixes issue running `make dist` before creating package path.
- Removes `Default requiretty` from sudoers configuration. This allows for sudo commands to be run via without the requirement to use the `-t` option of the `ssh` command.
- Adds correct path to scmi on image for install/uninstall.
- Improves readability of Dockerfile.
- Adds consistent method of handling publishing of exposed ports. It's now possible to prevent publishing of the default exposed port when using scmi/make for installation.
- Adds minor improvement to the systemd register template unit-file.
- Adds `/usr/sbin/sshd-wrapper` and moves lock file handling out of supervisord configuration.
- Adds bootstrap script syntax changes for consistency and readability.
- Adds correction to scmi usage instructions; using centos-6-1.7.0 release tag would have resulted in error if attempting an `atomic install`.
- Changes Makefile environment variable from `PACKAGE_PATH` to `DIST_PATH` as the name conflicts with the Dockerfile ARG value used in some downstream builds. This is only used when building the, distributable, image package that gets attached to each release.

### 1.7.0 - 2016-08-26

- Added `scmi` (Services Container Manager Interface) to the image to simplify deployment and management of container instances using simply docker itself, using systemd for single docker hosts or fleet for clustered docker hosts.
- Added metadata labels to the Dockerfile which defines the docker commands to run for operation (install/uninstall). This combined with `scmi` enables the use of Atomic Host's `atomic install|uninistall` commands.
- The `xz` archive package has ben added to the image to allow `scmi` to load an image package from disk instead of requiring registry access to pull release images.
- Updated Supervisor to `3.3.1`.
- Removed unnecessary desktop image resources.
- Warn operator if any supplied environment variable values failed validation and have been set to a safe default.
- Added `DOCKER_CONTAINER_PARAMETERS_APPEND` which allows the docker operator to append parameters to the default docker create template.
- Removed handling of Configuration Data Volumes from the helper scripts and from the Systemd unit-file definitions. Volumes can be added using the environment variable `DOCKER_CONTAINER_PARAMETERS_APPEND` or with the `--setopt` option with `scmi`.
- Removed the `build.sh` and `run.sh` helper scripts that were deprecated and have been replaced with the Makefile targets. With `make` installed the process of building and running a container from the Dockerfile is `make build install start` or to replicate the previous build helper `make build images install start ps`.
- Systemd template unit-files have been renamed to `centos-ssh@.service` and `centos-ssh.register@.service`. The (optional) register sidekick now contains placeholder `{{SERVICE_UNIT_NAME}}` that is needs gets replaced with the service unit when installing using `scmi`.
- The default value for `DOCKER_IMAGE_PACKAGE_PATH` in the systemd template unit-file has been changed from `/var/services-packages` to `/var/opt/scmi/packages`.

### 1.6.0 - 2016-06-23

- Update source to CentOS-6 6.8.
- Update OpenSSH package to 5.3p1-118.1.el6_8 from 5.3p1-117.el6.
- Remove redhat-logos to reduce image size.

### 1.5.3 - 2016-06-21

- Updated CentOS-6.7 packages `sudo`, `openssh` and `yum-plugin-versionlock`.
- Fixed broken pipe error returned from get_password function in the sshd_bootstrap script.
- Replaced hard-coded volume configuration volume name with Systemd template with the Environment variable `VOLUME_CONFIG_NAME`.
- Fixed issue with setting an empty string for the `DOCKER_PORT_MAP_TCP_22 ` value - allowing docker to auto-assign a port number.
- Split out build specific configuration from the Makefile into a default.mk file and renamed make.conf to environment.mk - Makefile should now be more portable between Docker projects.

### 1.5.2 - 2016-03-21

- Updated container package `openssh`.
- Updated container's supervisord to 3.2.3.
- Added `SSH_AUTOSTART_SSHD` && `SSH_AUTOSTART_SSHD_BOOTSTRAP` to allow the operator or downstream developer to prevent the sshd service and/or sshd-bootstrap from startup.
- Added Makefile to replace `build.sh` and `run.sh` helper scripts. See [#162](https://github.com/jdeathe/centos-ssh/pull/162) for notes on usage instructions.
- Set Dockerfile environment variable values in a single build step which helps reduce build time.
- Fixed issue with setting SSH USER UID:GID values in systemd installation.
- Fixed issue with setting of `SSH_SUDO` in Systemd installation.
- Replaced custom awk type filters with docker native commands where possible.
- Fixed issue preventing sshd restarts being possible due to bootstrap lock file dependancy.
- Use `exec` to run the sshd daemon within the container.
- Use `exec` to run the docker daemon process from the systemd unit file template.
- Reduced startup time by ~1 second by not requiring supervisord to wait for the sshd service to stay up for the default 1 second.
- Revised systemd installation process, installer script and service template. `ssh.pool-1.1.1@2020.service` has been replaced by `ssh.pool-1@.service` and local instances are created of the form `ssh.pool-1@1.1`, `ssh.pool-1@2.1`, `ssh.pool-1@3.1` etc. which correspond to docker containers named `ssh.pool-1.1.1`, `ssh.pool-1.2.1`, `ssh.pool-1.3.1` etc. To start 3 systemd managed containers you can simply run:

  ```
  $ for i in {1..3}; do sudo env SERVICE_UNIT_LOCAL_ID=$i ./systemd-install.sh; done
  ```

- The systemd service registration feature is now enabled via an optional service unit template file `ssh.pool-1.register@.service`. 

### 1.5.1 - 2016-03-20

- Updated README with details for the CentOS-6 and CentOS-7 Dockerfile sources. Use centos-6 tag in examples as latest is now a centos-7 tag.
- Fixed '/dev/stdin: Stale file handle' issue seen when using Ubuntu 14.04.4 LTS or Kitematic 0.10.0 as the docker host.
- Fixed default value for `SSH_USER_FORCE_SFTP`.
- Removed the delay for output to docker logs.
- Improved bootstrap startup time and included bootstrap time in the SSHD Details log.
- Added a more robust method of triggering the SSHD process; the sshd-boostrap needs to complete with a non-zero exit code to trigger the SSHD process instead of simply waiting for 2 seconds and starting regardless.
- Systemd definition to use specific tag.

### 1.5.0 - 2016-02-09

- Added CentOS SCL repository.
- PAM is now enabled by default.
- Fixed issue with sshd starting before boostrap completion.
- Handle SSH host key generation in the bootstrap - prevents warning log entries.
- Updated method for matching docker images.
- Refactored supervisor configuration to be more modular. Will scan /etc/supervisord.d/ for configuration files matching `*.conf` or `*.ini`.
- Restructured container scripts file locations.
- Improve user feedback in build and run helper scripts.
- Added option for docker environment variable inheritance using `SSH_INHERIT_ENVIRONMENT`.
- Added example Systemd unit file and installation script.
- Added option for `SSH_USER_PASSWORD` to be a SHA-512 hashed string instead of a plaintext password.
- Increase length of auto-generated passwords to 16 characters and redact value from sshd-bootstrap log output unless necessary for sudo access.
- No longer output the root user password in sshd-bootstrap log.
- Display SSH user's public key fingerprints and RSA host key fingerprint in sshd-bootstrap log.
- Added Forced SFTP option with /chroot ChrootDirectory using both `SSH_USER_FORCE_SFTP` and `SSH_CHROOT_DIRECTORY`.
- Added feature to set UID and GID of `SSH_USER`.
- Replaced environment variable `SSH_USER_HOME_DIR` with `SSH_USER_HOME`. 
- Added feature to allow '%u' to be replaced with `SSH_USER` in `SSH_USER_HOME`.

### 1.4.2 - 2016-01-13

- Updated BASH scripts to try and have a more consistent syntax.
- Updated documentation with revised steps on how to implement the optional configuration "data" volume.
- Removed the run.sh feature to automatically mount the configuration volume on the docker host using a full path and attempt to populate the directory locally. This was problematic since the path on the Docker host might not exist and the feature to automatically create paths when adding a volume mount is deprecated. Using `docker cp` to upload a directory to the configuration volume is a much simpler approach.
- Refactored run.conf such that only values are in the configuration file and added `VOLUME_CONFIG_ENABLED` to allow the "optional" configuration volume to be enabled if required instead of using it by default. Most essential settings can be implemented via the use of environment variables now.
- Added `VOLUME_CONFIG_NAMED` to run.conf to allow the operator to use a named volume and, if set to `true` the `VOLUME_CONFIG_NAME` is used for the `docker_host_path` such that the volume is defined as: `-v volume_name:/container_path`. The recommended approach is to not define a host path or named volume so that Docker manages the naming by only setting the container path: `-v /container_path`.
- Added a feature to the run.sh helper script to allow a command to be run as a parameter on running which can be useful if debugging a container that won't start.
- Added a new run.conf variable `DOCKER_HOST_PORT_SSH` that sets the host port to a default of "2020" which corresponds to the value set in the README.md and in the docker-compose.yml.

### 1.4.1 - 2016-01-08

- Added a docker-compose example configuration.
- Use YUM to install IUS and EPEL repositories.
- Updated Supervisord to 3.2.0.
- Removed requirement for Python PIP.
- Added configuration option for a custom sudo command using the environment variable `SSH_SUDO`.
- Added configuration option for custom SSH public keys (authorized_keys) using the environment variable `SSH_AUTHORIZED_KEYS`.
- Added configuration option to set the SSH user's default shell using the environment variable `SSH_USER_SHELL`.
- Fixed an issue with SSH user's home directory not being set correctly if using a path other than `home/${SSH_USER}`
- Added validation to the `SSH_USER` values to prevent issues like setting it to "root".

### 1.4.0 - 2015-11-21

- Updated to CentOS 6.7

### 1.3.1 - 2015-11-21

- Fixed build error + updated package versions.
- Fixed 'Error: could not find config file /etc/supervisord.conf' being logged on non Darwin docker hosts.
- Fixed issues displaying correct image after using the build.sh helper script.
- Fix issue with locale warnings when execing bash.
- Added support for environment variables to allow configuration of user settings.
- Made general improvements to the ssh-bootstrap script.
- Updated Documentation

### 1.3.0 - 2015-07-11

- Add IUS repository.
- Specify package versions, add versionlock package and lock packages.
- Locate the SSH configuration file in a subdirectory to be more consistent.
- Added support for running and building on Mac Docker hosts (when using boot2docker).

### 1.2.0 - 2015-05-02

*Note:* This should have been tagged as 1.1.0.

- Updated to CentOS 6.6 from 6.5
- Added MIT License

### 1.0.2 - 2014-10-22

- Moved container resources into a directory structure representative of the destination it should be added to in the container file system.
- Reduced the number of build commands to reduce the layer count of the final image; there is currently a 127 layer limit.

### 1.0.1 - 2014-09-23

- Fixed an issue with a missing configuration volume required by the run.sh helper script.

### 1.0.0 - 2014-07-06

- Initial release
