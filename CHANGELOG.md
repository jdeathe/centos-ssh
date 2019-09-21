# Change Log

## 2 - centos-7

Summary of release changes.

### 2.6.1 - 2019-09-21

- Deprecate Makefile target `logs-delayed`; replaced with `logsdef`.
- Updates `openssh` package to 7.4p1-21.el7.
- Updates `openssl` package to 1.0.2k-19.el7.
- Updates `sudo` package to 1.8.23-4.el7.
- Updates `yum-plugin-versionlock` package to 1.1.31-52.el7.
- Updates supervisord to 4.0.4.
- Updates `test/health_status` helper script with for consistency.
- Updates Makefile target `logs` to accept `[OPTIONS]` (e.g `make -- logs -ft`).
- Updates `healthcheck` script; state file existence confirms bootstrap completion.
- Updates `system-timezone-wrapper` to improve timer accuracy.
- Updates scripts to explicitly check for a file when handling lock/state files.
- Updates method used for returning current script.
- Updates info/error output for consistency.
- Updates healthcheck failure messages to remove EOL character that is rendered in status response.
- Updates wrapper script; only emit "waiting on" info message if bootstrap hasn't completed.
- Updates CHANGELOG.md to simplify maintenance.
- Updates README.md to simplify contents and improve readability.
- Updates README-short.txt to apply to all image variants.
- Updates Dockerfile `org.deathe.description` metadata LABEL for consistency.
- Updates ordering of Tags and respective Dockerfile links in README.md for readability.
- Adds improved test workflow; added `test-setup` target to Makefile.
- Adds Makefile target `logsdef` to handle deferred logs output within a target chain.
- Adds exec proxy function to `sshd-wrapper` used to pass through nice.
- Adds double quotes around value containing spaces.
- Adds `/docs` directory for supplementary documentation and simplify README.
- Fixes validation failure of 0 second --timeout value in `test/health_status`.
- Removes `ENABLE_SSHD_BOOTSTRAP` from docker-compose example configuration.
- Removes `ENABLE_SSHD_WRAPPER` from docker-compose example configuration.

### 2.6.0 - 2019-06-20

- Deprecates `SSH_AUTOSTART_SSHD`, replaced with `ENABLE_SSHD_WRAPPER`.
- Deprecates `SSH_AUTOSTART_SSHD_BOOTSTRAP`, replaced with `ENABLE_SSHD_BOOTSTRAP`.
- Deprecates `SSH_AUTOSTART_SUPERVISOR_STDOUT`, replaced with `ENABLE_SUPERVISOR_STDOUT`.
- Deprecates `SSH_TIMEZONE`, replaced with `SYSTEM_TIMEZONE`.
- Updates source tag to CentOS 7.6.1810.
- Updates supervisord to 4.0.3.
- Updates default value of `ENABLE_SUPERVISOR_STDOUT` to false.
- Updates `sshd-bootstrap` and `sshd-wrapper` configuration to send error log output to stderr.
- Updates order of values in SSH/SFTP Details log output.
- Updates bootstrap timer to use UTC date timestamps.
- Updates bootstrap supervisord configuration file/priority to `20-sshd-bootstrap.conf`/`20`.
- Updates wrapper supervisord configuration file/priority to `50-sshd-wrapper.conf`/`50`.
- Adds reference to `python-setuptools` in README; removed in error.
- Adds `inspect`, `reload` and `top` Makefile targets.
- Adds improved lock/state file implementation in bootstrap and wrapper scripts.
- Adds improved `clean` Makefile target; includes exited containers and dangling images.
- Adds improved wait on bootstrap completion in wrapper script.
- Adds `system-timezone` and `system-timezone-wrapper` to handle system time zone setup.
- Adds system time zone validation to healthcheck.
- Fixes port incrementation failures when installing systemd units via `scmi`.
- Fixes etcd port registration failures when installing systemd units via `scmi` with the `--register` option.
- Fixes binary paths in systemd unit files for compatibility with both EL and Ubuntu hosts.
- Fixes use of printf binary instead of builtin in systemd unit files.
- Fixes docker host connection status check in Makefile.
- Fixes make clean error thrown when removing exited containers.
- Removes support for long image tags (i.e. centos-7-2.x.x).
- Removes system time zone setup from `sshd-bootstrap`.
- Removes redundant directory test from `sshd-bootstrap`; state file ensures it's a one-shot process.

### 2.5.1 - 2019-02-28

- Deprecates use of `supervisor_stdout` - the default value of `SSH_AUTOSTART_SUPERVISOR_STDOUT` will be switched to "false" in a future release.
- Updates Dockerfile with combined ADD to reduce layer count in final image.
- Fixes `scmi` installation error when using the `--manager=systemd` option on Ubuntu hosts.
- Fixes issues with failure to install/uninstall systemd units installed with scmi.
- Adds improvement to pull logic in systemd unit install template.
- Adds `docker-compose.yml` to `.dockerignore` to reduce size of build context.
- Adds docker-compose configuration example.
- Adds `SSH_AUTOSTART_SUPERVISOR_STDOUT` to control startup of `supervisor_stdout`.
- Adds drop-in configuration for `supervisor_stdout` in `/etc/supervisord.d/00-supervisor_stdout.conf`.
- Adds improved `healtchcheck`, `sshd-bootstrap` and `sshd-wrapper` scripts.
- Adds validation of `SSH_INHERIT_ENVIRONMENT` values.
- Removes reference to `python-setuptools` from README as it's no longer installed.
- Removes requirement of `supervisor_stdout` for output of supervisord logs to stdout.
- Removes unnecessary configuration file `/etc/sshd-bootstrap.conf`.
- Removes unnecessary environment file `/etc/sshd-bootstrap.env`.

### 2.5.0 - 2019-01-28

- Updates `openssl` package to 1.0.2k-16.el7.
- Updates `sudo` package to 1.8.23-3.el7.
- Updates `yum-plugin-versionlock` package to 1.1.31-50.el7.
- Updates supervisor to 3.3.5.
- Updates validation for `SSH_USER_ID` to allow values in the system ID range.
- Updates and restructures Dockerfile to reduce number of layers in image.
- Updates container naming conventions for `scmi` making the node element optional.
- Updates container naming conventions and readability of `Makefile`.
- Updates `docker logs` output example in README document.
- Updates README instructions following review.
- Updates default HEALTHCHECK interval to 1 second from 0.5.
- Replaces awk with native bash regex when testing sudo user's have `NOPASSWD:ALL`.
- Fixes bootstrap errors regarding readonly `PASSWORD_LENGTH`.
- Fixes issue with redacted password when using `SSH_PASSWORD_AUTHENTICATION` in combination with `SSH_USER_FORCE_SFTP`.
- Fixes issue with unexpected published port in run templates when `DOCKER_PORT_MAP_TCP_22` is set to an empty string or 0.
- Fixes missing `SSH_TIMEZONE` from Makefile's install run template.
- Fixes validation of `SSH_TIMEZONE` values - set to defaults with warning and abort on error.
- Adds `SSH_USER_PRIVATE_KEY` to allow configuration of an RSA private key for `SSH_USER`.
- Adds placeholder replacement of `RELEASE_VERSION` docker argument to systemd service unit template.
- Adds error messages to healthcheck script and includes supervisord check.
- Adds a short sleep after bootstrap Details to work-around missing output on CI service's host.
- Adds port incrementation to Makefile's run template for container names with an instance suffix.
- Adds consideration for event lag into test cases for unhealthy health_status events.
- Adds feature to allow configuration of "root" `SSH_USER`.
- Adds validation of `SSH_SUDO` values.
- Removes use of `/etc/services-config` paths.
- Removes fleet `--manager` option in the `scmi` installer.
- Removes X-Fleet section from etcd register template unit-file.
- Removes the unused group element from the default container name.
- Removes the node element from the default container name.
- Removes undocumented `SSH_ROOT_PASSWORD` from bootstrap process.

### 2.4.1 - 2018-11-10

- Adds feature to set system time zone via `SSH_TIMEZONE`.
- Adds feature to enable password authentication.
- Adds default of removing insecure public key when enabling password authentication.

### 2.4.0 - 2018-08-12

- Updates source tag to CentOS 7.5.1804.
- Adds explicit user (root) for running `supervisord`.

### 2.3.2 - 2018-04-24

- Updates supervisor to 3.3.4.
- Adds feature to set `SSH_USER_PASSWORD` via a file path. e.g. Docker Swarm secrets.
- Adds feature to set `SSH_AUTHORIZED_KEYS` via a file path. e.g. Docker Swarm config.

### 2.3.1 - 2018-01-12

- Updates `openssh` package to openssh-7.4p1-13.el7_4.
- Adds a `.dockerignore` file.
- Deprecates use of the fleet `--manager` option in the `scmi` installer.

### 2.3.0 - 2017-10-06

- Updates source tag to CentOS 7.4.1708.

### 2.2.4 - 2017-09-13

- Updates [supervisor](http://supervisord.org/changes.html) to version 3.3.3.
- Updates `sudo` package to sudo-1.8.6p7-23.el7_3.
- Adds permissions to restrict access to the healthcheck script.
- Fixes declaration of local readonly and array bash variables in SCMI scripts.
- Fixes missing trailing newline in source vagrant insecure public key.
- Fixes missing trailing newline for keys added to `~/.ssh/authorized_keys`.

### 2.2.3 - 2017-06-14

- Adds clearer, improved [shpec](https://github.com/rylnd/shpec) test case output.
- Updates [supervisor](http://supervisord.org/changes.html) to version 3.3.2.
- Adds use of `/var/lock/subsys/` (subsystem lock directory) for bootstrap lock files.
- Adds a Docker healthcheck.

### 2.2.2 - 2017-05-24

- Updates `openssh` package 6.6.1p1-35.el7_3.
- Replaces deprecated Dockerfile `MAINTAINER` with a `LABEL`.
- Adds a `src` directory for the image root files.
- Adds wrapper functions to functional test cases.
- Adds `STARTUP_TIME` variable for the `logs-delayed` Makefile target.

### 2.2.1 - 2017-02-21

- Updates `vim` and `openssh` packages and the `epel-release`.
- Fixes `shpec` test definition to allow `make test` to be interruptible.
- Adds the `openssl` package (and it's dependency, `make`).
- Adds `README.md` instruction to use `docker pull` before `docker inspect` on an image.

### 2.2.0 - 2016-12-19

- Adds CentOS 7.3.1611 source tag.

### 2.1.5 - 2016-12-15

- Adds updated `sudo`, `openssh`, `yum-plugin-versionlock` and `xz` packages.
- Adds functional tests using [shpec](https://github.com/rylnd/shpec). To run all tests, [install `shpec`](https://github.com/rylnd/shpec#installation) and run with `make test`.
- Adds support for running tests on Ubuntu. _Note: May require some additional setup prevent warnings about locale._

  ```
  sudo locale-gen en_US.UTF-8; sudo dpkg-reconfigure locales
  export LANG=en_US.UTF-8; unset LANGUAGE LC_ALL LC_CTYPE
  ```
- Adds correction to examples and test usage of the `sftp` command.
- Adds a "better practices" example of password hash generation in the `README.md`.
- Adds minor code style changes to the `Makefile`.

### 2.1.4 - 2016-12-04

- Adds correct Makefile usage instructions for 'build' target.
- Adds info regarding NULL port values in Makefile help.
- Removes requirement for `gawk` in the port handling functions for SCMI and the systemd template unit-file.
- Adds reduced number of build steps to image which helps reduce final image size.
- Adds `-u` parameter to `sshd` options to help reduce time spent doing DNS lookups during authentication.
- Adds a change log (`CHANGELOG.md`).
- Adds support for semantic version numbered tags.

### 2.1.3 - 2016-10-02

- Adds Makefile help target with usage instructions.
- Splits up the Makefile targets into internal and public types.
- Adds correct `scmi` path in usage instructions.
- Changes `PACKAGE_PATH` to `DIST_PATH` in line with the Makefile environment include. Not currently used by `scmi` but changing for consistency.
- Changes `DOCKER_CONTAINER_PARAMETERS_APPEND` to `DOCKER_CONTAINER_OPTS` for usability. This is a potentially breaking change that could affect systemd service configurations if using the Environment variable in a drop-in customisation. However, if using the systemd template unit-files it should be pinned to a specific version tag. The Makefile should only be used for development/testing and usage in `scmi` is internal only as the `--setopt` parameter is used to build up the optional container parameters. 
- Removes X-Fleet section from template unit-file.
- Adds support for Base64 encoded `SSH_AUTHORIZED_KEYS` values. This resolves issues with setting multiple keys for the systemd installations.

### 2.1.2 - 2016-09-16

- Fixed issue with sshd process not running on container startup.

### 2.1.1 - 2016-09-15

- Fixes issue running `make dist` before creating package path.
- Removes `Default requiretty` from sudoers configuration. This allows for sudo commands to be run via without the requirement to use the `-t` option of the `ssh` command.
- Adds correct path to scmi on image for install/uninstall.
- Improves readability of Dockerfile.
- Adds consistent method of handling publishing of exposed ports. It's now possible to prevent publishing of the default exposed port when using scmi/make for installation.
- Adds minor improvement to the systemd register template unit-file.
- Adds `/usr/sbin/sshd-wrapper` and moves lock file handling out of supervisord configuration.
- Adds bootstrap script syntax changes for consistency and readability.
- Adds correction to scmi usage instructions; using centos-7-2.1.0 release tag would have resulted in error if attempting an `atomic install`.
- Changes Makefile environment variable from `PACKAGE_PATH` to `DIST_PATH` as the name conflicts with the Dockerfile ARG value used in some downstream builds. This is only used when building the, distributable, image package that gets attached to each release.

### 2.1.0 - 2016-08-26

- Added `scmi` (Services Container Manager Interface) to the image to simplify deployment and management of container instances using simply docker itself, using systemd for single docker hosts or fleet for clustered docker hosts.
- Added metadata labels to the Dockerfile which defines the docker commands to run for operation (install/uninstall). This combined with `scmi` enables the use of Atomic Host's `atomic install|uninistall` commands.
- The `xz` archive package has ben added to the image to allow `scmi` to load an image package from disk instead of requiring registry access to pull release images.
- Updated Supervisor to `3.3.1`.
- Warn operator if any supplied environment variable values failed validation and have been set to a safe default.
- Added `DOCKER_CONTAINER_PARAMETERS_APPEND` which allows the docker operator to append parameters to the default docker create template.
- Removed handling of Configuration Data Volumes from the helper scripts and from the Systemd unit-file definitions. Volumes can be added using the environment variable `DOCKER_CONTAINER_PARAMETERS_APPEND` or with the `--setopt` option with `scmi`.
- Removed the `build.sh` and `run.sh` helper scripts that were deprecated and have been replaced with the Makefile targets. With `make` installed the process of building and running a container from the Dockerfile is `make build install start` or to replicate the previous build helper `make build images install start ps`.
- Systemd template unit-files have been renamed to `centos-ssh@.service` and `centos-ssh.register@.service`. The (optional) register sidekick now contains placeholder `{{SERVICE_UNIT_NAME}}` that is needs gets replaced with the service unit when installing using `scmi`.
- The default value for `DOCKER_IMAGE_PACKAGE_PATH` in the systemd template unit-file has been changed from `/var/services-packages` to `/var/opt/scmi/packages`.

### 2.0.3 - 2016-06-21

- Fixed broken pipe error returned from get_password function in the sshd_bootstrap script.
- Replaced hard-coded volume configuration volume name with Systemd template with the Environment variable `VOLUME_CONFIG_NAME`.
- Fixed issue with setting an empty string for the `DOCKER_PORT_MAP_TCP_22` value - allowing docker to auto-assign a port number.
- Split out build specific configuration from the Makefile into a default.mk file and renamed make.conf to environment.mk - Makefile should now be more portable between Docker projects.

### 2.0.2 - 2016-05-21

- Updated container packages `sudo` and `openssh`.
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

### 2.0.1 - 2016-03-20

- Fixed '/dev/stdin: Stale file handle' issue seen when using Ubuntu 14.04.4 LTS or Kitematic 0.10.0 as the docker host.
- Fixed default value for `SSH_USER_FORCE_SFTP`.
- Removed the delay for output to docker logs.
- Improved bootstrap startup time and included bootstrap time in the SSHD Details log.
- Added a more robust method of triggering the SSHD process; the sshd-boostrap needs to complete with a non-zero exit code to trigger the SSHD process instead of simply waiting for 2 seconds and starting regardless.
- Systemd definition to use specific tag.

### 2.0.0 - 2016-02-28

- Initial release