readonly DOCKER_HOSTNAME="localhost"
readonly REDACTED_VALUE="********"
readonly STARTUP_TIME=2
readonly TEST_DIRECTORY="test"
readonly PUBLIC_KEY_ID_RSA_TEST_1="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDHzd+mYXSGLQSZwUJWwYKOBI6I7mhHh3Ow0DbTQvQUHhkDcQVrqjpBKZq8SsnEK4ExyJeRQ5TtT5VqolfVG6LlaT3yxXmJxx75Y8oypFAKz7oCOQCJugqubAkx2YpT6KO7d6UOPqOuLpmFi3t+Ryf49TbNljSes1sbSCxUDlTekxG+It+/eZUqXWudornYJCfmMe1UAYtRwMKiyDWqU1LN1Kb2zVR76YpjMxK9IiEJjhpZS/R70zxGEijFrL+Rv4Bx8y/UjAVVtTkvpaEajx7pMnd0fsfnUwhYLoVHgG5ZdHAYSRy8j/0+mpeVEsTQZJAnegUbVNuBEc3x2b1xgkS3 test_key_1"
readonly PUBLIC_KEY_ID_RSA_TEST_1_SIGNATURE="45:46:b0:ef:a5:e3:c9:6f:1e:66:94:ba:e1:fd:df:65"
readonly PUBLIC_KEY_ID_RSA_TEST_2="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDD/sMi/JkrYtXVi6+pYuwvsUxLDXowp3okvK2+2qqnPA6nWGBu/LSSQZnYmHZYyhcbRKrdscnsbM0jfmU0cKf/lGiRRK1YfUepomtRWVBxzA3mvBu+qmbuU/PDHfJJxB19HHuc6a8/NPOZINNMGIZg91W79bW0gXIEh3+PiNVvuelOdFJdvKSWtElJlMk/ll7dS1vpwJ9iZ8EPbalSzEZ30SzqG8Xg4VMhOn9ybnvcNWGJVCg4yughmdVA32H2+rj6qis4AJdQYUNoh9kBK/XUoggRV7LEaeeyjMWPn6GxM4yM7IYkstpilbKiPIQjw9EDTN4FdIJ/LcescfwDT7KZ test_key_2"
readonly PUBLIC_KEY_ID_RSA_TEST_2_SIGNATURE="b3:2e:5d:8c:76:d3:c7:24:13:a3:4f:6f:4d:a2:31:9c"
readonly PUBLIC_KEY_ID_RSA_TEST_COMBINED_BASE64="c3NoLXJzYSBBQUFBQjNOemFDMXljMkVBQUFBREFRQUJBQUFCQVFESHpkK21ZWFNHTFFTWndVSld3WUtPQkk2STdtaEhoM093MERiVFF2UVVIaGtEY1FWcnFqcEJLWnE4U3NuRUs0RXh5SmVSUTVUdFQ1VnFvbGZWRzZMbGFUM3l4WG1KeHg3NVk4b3lwRkFLejdvQ09RQ0p1Z3F1YkFreDJZcFQ2S083ZDZVT1BxT3VMcG1GaTN0K1J5ZjQ5VGJObGpTZXMxc2JTQ3hVRGxUZWt4RytJdCsvZVpVcVhXdWRvcm5ZSkNmbU1lMVVBWXRSd01LaXlEV3FVMUxOMUtiMnpWUjc2WXBqTXhLOUlpRUpqaHBaUy9SNzB6eEdFaWpGckwrUnY0Qng4eS9VakFWVnRUa3ZwYUVhang3cE1uZDBmc2ZuVXdoWUxvVkhnRzVaZEhBWVNSeThqLzArbXBlVkVzVFFaSkFuZWdVYlZOdUJFYzN4MmIxeGdrUzMgdGVzdF9rZXlfMQpzc2gtcnNhIEFBQUFCM056YUMxeWMyRUFBQUFEQVFBQkFBQUJBUUREL3NNaS9Ka3JZdFhWaTYrcFl1d3ZzVXhMRFhvd3Azb2t2SzIrMnFxblBBNm5XR0J1L0xTU1FablltSFpZeWhjYlJLcmRzY25zYk0wamZtVTBjS2YvbEdpUlJLMVlmVWVwb210UldWQnh6QTNtdkJ1K3FtYnVVL1BESGZKSnhCMTlISHVjNmE4L05QT1pJTk5NR0laZzkxVzc5YlcwZ1hJRWgzK1BpTlZ2dWVsT2RGSmR2S1NXdEVsSmxNay9sbDdkUzF2cHdKOWlaOEVQYmFsU3pFWjMwU3pxRzhYZzRWTWhPbjl5Ym52Y05XR0pWQ2c0eXVnaG1kVkEzMkgyK3JqNnFpczRBSmRRWVVOb2g5a0JLL1hVb2dnUlY3TEVhZWV5ak1XUG42R3hNNHlNN0lZa3N0cGlsYktpUElRanc5RURUTjRGZElKL0xjZXNjZndEVDdLWiB0ZXN0X2tleV8yCg=="

# This should ideally be a static value but hosts might be using this port so 
# need to allow for an alternative.
DOCKER_PORT_MAP_TCP_22="${DOCKER_PORT_MAP_TCP_22:-2020}"

function __destroy ()
{
	:
}

function __get_container_port ()
{
	local container="${1:-}"
	local port="${2:-}"
	local value=""

	value="$(
		docker port \
			${container} \
			${port}
	)"
	value=${value##*:}

	printf -- \
		'%s' \
		"${value}"
}

# container - Docker container name.
# counter - Timeout counter in seconds.
# process_pattern - Regular expression pattern used to match running process.
# ready_test - Command used to test if the service is ready.
function __is_container_ready ()
{
	local container="${1:-}"
	local counter=$(
		awk \
			-v seconds="${2:-10}" \
			'BEGIN { print 10 * seconds; }'
	)
	local process_pattern="${3:-}"
	local ready_test="${4:-true}"

	until (( counter == 0 )); do
		sleep 0.1

		if docker exec ${container} \
			bash -c "ps axo command \
				| grep -qE \"${process_pattern}\" \
				&& eval \"${ready_test}\"" \
			&> /dev/null
		then
			break
		fi

		(( counter -= 1 ))
	done

	if (( counter == 0 )); then
		return 1
	fi

	return 0
}

function __setup ()
{
	chmod 600 \
		${TEST_DIRECTORY}/fixture/{id_rsa_insecure,id_rsa_test_1,id_rsa_test_2}
}

# Custom shpec matcher
# Match a string with an Extended Regular Expression pattern.
function __shpec_matcher_egrep ()
{
	local pattern="${2:-}"
	local string="${1:-}"

	printf -- \
		'%s' \
		"${string}" \
	| grep -qE -- \
		"${pattern}" \
		-

	assert equal \
		"${?}" \
		0
}

function __terminate_container ()
{
	local container="${1}"

	if docker ps -aq \
		--filter "name=${container}" \
		--filter "status=paused" &> /dev/null; then
		docker unpause ${container} &> /dev/null
	fi

	if docker ps -aq \
		--filter "name=${container}" \
		--filter "status=running" &> /dev/null; then
		docker stop ${container} &> /dev/null
	fi

	if docker ps -aq \
		--filter "name=${container}" &> /dev/null; then
		docker rm -vf ${container} &> /dev/null
	fi
}

function test_basic_ssh_operations ()
{
	local container_port_22=""
	local password=""
	local user_home=""

	describe "Basic SSH operations"
		trap "__terminate_container ssh.pool-1.1.1 &> /dev/null; \
			__destroy; \
			exit 1" \
			INT TERM EXIT

		describe "Runs named container"
			__terminate_container \
				ssh.pool-1.1.1 \
			&> /dev/null

			docker run \
				--detach \
				--name ssh.pool-1.1.1 \
				--publish ${DOCKER_PORT_MAP_TCP_22}:22 \
				jdeathe/centos-ssh:latest \
			&> /dev/null

			it "Can publish container port 22 to host port ${DOCKER_PORT_MAP_TCP_22}."
				container_port_22="$(
					__get_container_port \
						ssh.pool-1.1.1 \
						22/tcp
				)"

				if [[ ${DOCKER_PORT_MAP_TCP_22} == 0 ]] \
					|| [[ -z ${DOCKER_PORT_MAP_TCP_22} ]]; then
					assert gt \
						"${container_port_22}" \
						"30000"
				else
					assert equal \
						"${container_port_22}" \
						"${DOCKER_PORT_MAP_TCP_22}"
				fi
			end
		end

		if ! __is_container_ready \
			ssh.pool-1.1.1 \
			${STARTUP_TIME} \
			"/usr/sbin/sshd " \
			"grep \
				'^Server listening on 0\.0\.0\.0 port 22\.' \
				/var/log/secure"
		then
			exit 1
		fi

		describe "SSH user's password"
			password="$(
				docker logs \
					ssh.pool-1.1.1 \
				| awk '/^password :.*$/ { print $3 }'
			)"

			it "Can be retrieved from the log."
				assert unequal \
					"${password}" \
					""
			end

			it "Displays in plain text."
				assert unequal \
					"${password}" \
					"${REDACTED_VALUE}"
			end
		end

		describe "SSH connection"
			# Prevent sudo lecture output when testing the sudo password
			docker exec ssh.pool-1.1.1 \
				bash -c 'echo "Defaults lecture_file = /dev/null" > /etc/sudoers.d/no_lecture'

			it "Can connect using private key authentication."
				ssh -q \
					-p ${container_port_22} \
					-i ${TEST_DIRECTORY}/fixture/id_rsa_insecure \
					-o StrictHostKeyChecking=no \
					-o LogLevel=error \
					app-admin@${DOCKER_HOSTNAME} \
					-- printf \
						'%s\\n' \
						"\${HOME}" \
					&> /dev/null

				assert equal \
					"${?}" \
					0
			end

			it "Requires a password for sudo."
				user_home="$(
					echo ${password} \
					| ssh -q \
						-p ${container_port_22} \
						-i ${TEST_DIRECTORY}/fixture/id_rsa_insecure \
						-o StrictHostKeyChecking=no \
						-o LogLevel=error \
						app-admin@${DOCKER_HOSTNAME} \
						-- sudo -p "[password_test]" -S \
							printf \
								'%s\\n' \
								"\${HOME}"
				)"

				assert equal \
					"${user_home}" \
					"/home/app-admin"
			end

			# Reset sudo configuration
			docker exec ssh.pool-1.1.1 \
				bash -c 'rm -f /etc/sudoers.d/no_lecture'
		end

		__terminate_container \
			ssh.pool-1.1.1 \
		&> /dev/null

		trap - \
			INT TERM EXIT
	end
}

function test_basic_sftp_operations ()
{
	local container_port_22=""
	local user_shell=""

	describe "Basic SFTP operations"
		trap "__terminate_container sftp.pool-1.1.1 &> /dev/null; \
			__destroy; \
			exit 1" \
			INT TERM EXIT

		describe "Runs named container"
			__terminate_container \
				sftp.pool-1.1.1 \
			&> /dev/null

			docker run \
				--detach \
				--name sftp.pool-1.1.1 \
				--publish ${DOCKER_PORT_MAP_TCP_22}:22 \
				--env SSH_USER_FORCE_SFTP=true \
				jdeathe/centos-ssh:latest \
			&> /dev/null

			it "Can publish container port 22 to host port ${DOCKER_PORT_MAP_TCP_22}."
				container_port_22="$(
					__get_container_port \
						sftp.pool-1.1.1 \
						22/tcp
				)"

				if [[ ${DOCKER_PORT_MAP_TCP_22} == 0 ]] \
					|| [[ -z ${DOCKER_PORT_MAP_TCP_22} ]]; then
					assert gt \
						"${container_port_22}" \
						"30000"
				else
					assert equal \
						"${container_port_22}" \
						"${DOCKER_PORT_MAP_TCP_22}"
				fi
			end
		end

		if ! __is_container_ready \
			sftp.pool-1.1.1 \
			${STARTUP_TIME} \
			"/usr/sbin/sshd " \
			"grep \
				'^Server listening on 0\.0\.0\.0 port 22\.' \
				/var/log/secure"
		then
			exit 1
		fi

		describe "SFTP Connection"
			it "Can connect using private key authentication."
				sftp -q \
					-i ${TEST_DIRECTORY}/fixture/id_rsa_insecure \
					-o StrictHostKeyChecking=no \
					-o LogLevel=error \
					-o Port=${container_port_22} \
					app-admin@${DOCKER_HOSTNAME} \
					<<< "version" \
					&> /dev/null

				assert equal \
					"${?}" \
					0
			end

			it "Can write to the user's _data directory."
				sftp -q \
					-i ${TEST_DIRECTORY}/fixture/id_rsa_insecure \
					-o StrictHostKeyChecking=no \
					-o LogLevel=error \
					-o Port=${container_port_22} \
					app-admin@${DOCKER_HOSTNAME}:_data \
					<<< "put ${TEST_DIRECTORY}/fixture/test_file" \
					&> /dev/null

				assert equal \
					"${?}" \
					0
			end

			it "Jails the user into a chroot directory."
				docker exec sftp.pool-1.1.1 \
					touch /home/app-admin/root_test

				sftp -q \
					-i ${TEST_DIRECTORY}/fixture/id_rsa_insecure \
					-o StrictHostKeyChecking=no \
					-o LogLevel=error \
					-o Port=${container_port_22} \
					app-admin@${DOCKER_HOSTNAME} \
					<<< "ls /root_test" \
					| grep -q "^/root_test"

				assert equal \
					"${?}" \
					0
			end

			it "Sets the /sbin/nologin shell."
				user_shell="$(
					docker exec sftp.pool-1.1.1 \
						getent passwd app-admin \
						| cut -d: -f7
				)"

				assert equal \
					"${user_shell}" \
					"/sbin/nologin"
			end
		end

		__terminate_container \
			sftp.pool-1.1.1 \
		&> /dev/null

		trap - \
			INT TERM EXIT
	end
}

function test_custom_ssh_configuration ()
{
	local append_line=""
	local container_port_22=""
	local user=""
	local user_env_value=""
	local user_home=""
	local user_id=""
	local user_key=""
	local user_key_signature=""
	local user_password=""
	local user_shell=""
	local user_sudo=""

	describe "Customised SSH configuration"
		trap "__terminate_container ssh.pool-1.1.1 &> /dev/null; \
			__destroy; \
			exit 1" \
			INT TERM EXIT

		describe "Configure sudo command"
			__terminate_container \
				ssh.pool-1.1.1 \
			&> /dev/null

			docker run \
				--detach \
				--name ssh.pool-1.1.1 \
				--env "SSH_SUDO=ALL=(ALL) NOPASSWD:ALL" \
				--publish ${DOCKER_PORT_MAP_TCP_22}:22 \
				jdeathe/centos-ssh:latest \
			&> /dev/null

			container_port_22="$(
				__get_container_port \
					ssh.pool-1.1.1 \
					22/tcp
			)"

			if ! __is_container_ready \
				ssh.pool-1.1.1 \
				${STARTUP_TIME} \
				"/usr/sbin/sshd " \
				"grep \
					'^Server listening on 0\.0\.0\.0 port 22\.' \
					/var/log/secure"
			then
				exit 1
			fi

			it "Can set no password for all commands."
				user_home="$(
					ssh -q \
					-p ${container_port_22} \
					-i ${TEST_DIRECTORY}/fixture/id_rsa_insecure \
					-o StrictHostKeyChecking=no \
					-o LogLevel=error \
					app-admin@${DOCKER_HOSTNAME} \
					-- sudo \
						printf \
							'%s\\n' \
							"\${HOME}"
				)"

				assert equal \
					"${user_home}" \
					"/home/app-admin"
			end

			it "Logs the setting value."
				user_sudo="$(
					docker logs ssh.pool-1.1.1 \
					| awk '/^sudo :.*$/ { print $0; }'
				)"

				assert equal \
					"${user_sudo/sudo : /}" \
					"ALL=(ALL) NOPASSWD:ALL"
			end
		end

		describe "Configure username"
			__terminate_container \
				ssh.pool-1.1.1 \
			&> /dev/null

			docker run \
				--detach \
				--name ssh.pool-1.1.1 \
				--env "SSH_SUDO=ALL=(ALL) NOPASSWD:ALL" \
				--env "SSH_USER=centos" \
				--publish ${DOCKER_PORT_MAP_TCP_22}:22 \
				jdeathe/centos-ssh:latest \
			&> /dev/null

			container_port_22="$(
				__get_container_port \
					ssh.pool-1.1.1 \
					22/tcp
			)"

			if ! __is_container_ready \
				ssh.pool-1.1.1 \
				${STARTUP_TIME} \
				"/usr/sbin/sshd " \
				"grep \
					'^Server listening on 0\.0\.0\.0 port 22\.' \
					/var/log/secure"
			then
				exit 1
			fi

			it "Can set the username."
				user_home="$(
					ssh -q \
					-p ${container_port_22} \
					-i ${TEST_DIRECTORY}/fixture/id_rsa_insecure \
					-o StrictHostKeyChecking=no \
					-o LogLevel=error \
					centos@${DOCKER_HOSTNAME} \
					-- printf \
						'%s\\n' \
						"\${HOME}"
				)"

				assert equal \
					"${user_home}" \
					"/home/centos"
			end

			it "Logs the setting value."
				user="$(
					docker logs ssh.pool-1.1.1 \
					| awk '/^user :.*$/ { print $0; }'
				)"

				assert equal \
					"${user/user : /}" \
					"centos"
			end
		end

		describe "Configure public key"
			__terminate_container \
				ssh.pool-1.1.1 \
			&> /dev/null

			docker run \
				--detach \
				--name ssh.pool-1.1.1 \
				--env "SSH_SUDO=ALL=(ALL) NOPASSWD:ALL" \
				--env "SSH_AUTHORIZED_KEYS=${PUBLIC_KEY_ID_RSA_TEST_1}" \
				--publish ${DOCKER_PORT_MAP_TCP_22}:22 \
				jdeathe/centos-ssh:latest \
			&> /dev/null

			container_port_22="$(
				__get_container_port \
					ssh.pool-1.1.1 \
					22/tcp
			)"

			if ! __is_container_ready \
				ssh.pool-1.1.1 \
				${STARTUP_TIME} \
				"/usr/sbin/sshd " \
				"grep \
					'^Server listening on 0\.0\.0\.0 port 22\.' \
					/var/log/secure"
			then
				exit 1
			fi

			it "Can set the key."
				user_home="$(
					ssh -q \
					-p ${container_port_22} \
					-i ${TEST_DIRECTORY}/fixture/id_rsa_test_1 \
					-o StrictHostKeyChecking=no \
					-o LogLevel=error \
					app-admin@${DOCKER_HOSTNAME} \
					-- printf \
						'%s\\n' \
						"\${HOME}"
				)"

				assert equal \
					"${user_home}" \
					"/home/app-admin"
			end

			it "Logs the key signature."
				user_key_signature="$(
					docker logs ssh.pool-1.1.1 \
					| awk '/^45:46:b0:ef:a5:e3:c9:6f:1e:66:94:ba:e1:fd:df:65$/ { print $1; }'
				)"

				assert equal \
					"${user_key_signature}" \
					"${PUBLIC_KEY_ID_RSA_TEST_1_SIGNATURE}"
			end

			it "Can append to key"
				append_line="$(docker exec -t \
					ssh.pool-1.1.1 \
					bash -c "printf -- '#\n' \
						>> /home/app-admin/.ssh/authorized_keys \
						&& tail -n 1 \
						< /home/app-admin/.ssh/authorized_keys \
						| tr -d '\n'"
				)"

				assert equal \
					"${append_line}" \
					"#"
			end
		end

		describe "Configure multiple public keys"
			__terminate_container \
				ssh.pool-1.1.1 \
			&> /dev/null

			docker run \
				--detach \
				--name ssh.pool-1.1.1 \
				--env "SSH_SUDO=ALL=(ALL) NOPASSWD:ALL" \
				--env "SSH_AUTHORIZED_KEYS=${PUBLIC_KEY_ID_RSA_TEST_COMBINED_BASE64}" \
				--publish ${DOCKER_PORT_MAP_TCP_22}:22 \
				jdeathe/centos-ssh:latest \
			&> /dev/null

			container_port_22="$(
				__get_container_port \
					ssh.pool-1.1.1 \
					22/tcp
			)"

			if ! __is_container_ready \
				ssh.pool-1.1.1 \
				${STARTUP_TIME} \
				"/usr/sbin/sshd " \
				"grep \
					'^Server listening on 0\.0\.0\.0 port 22\.' \
					/var/log/secure"
			then
				exit 1
			fi

			it "Can set multiple keys."
				user_home="$(
					ssh -q \
					-p ${container_port_22} \
					-i ${TEST_DIRECTORY}/fixture/id_rsa_test_1 \
					-o StrictHostKeyChecking=no \
					-o LogLevel=error \
					app-admin@${DOCKER_HOSTNAME} \
					-- printf \
						'%s\\n' \
						"\${HOME}"
				)"

				user_home+=":"

				user_home+="$(
					ssh -q \
					-p ${container_port_22} \
					-i ${TEST_DIRECTORY}/fixture/id_rsa_test_2 \
					-o StrictHostKeyChecking=no \
					-o LogLevel=error \
					app-admin@${DOCKER_HOSTNAME} \
					-- printf \
						'%s\\n' \
						"\${HOME}"
				)"

				assert equal \
					"${user_home}" \
					"/home/app-admin:/home/app-admin"
			end

			it "Logs the key signatures."
				user_key_signature="$(
					docker logs ssh.pool-1.1.1 \
					| awk '/^45:46:b0:ef:a5:e3:c9:6f:1e:66:94:ba:e1:fd:df:65$/ { print $1; }'
				)"

				user_key_signature+=" "

				user_key_signature+="$(
					docker logs ssh.pool-1.1.1 \
					| awk '/^b3:2e:5d:8c:76:d3:c7:24:13:a3:4f:6f:4d:a2:31:9c$/ { print $1; }'
				)"

				assert equal \
					"${user_key_signature}" \
					"${PUBLIC_KEY_ID_RSA_TEST_1_SIGNATURE} ${PUBLIC_KEY_ID_RSA_TEST_2_SIGNATURE}"
			end
		end

		describe "Configure home"
			__terminate_container \
				ssh.pool-1.1.1 \
			&> /dev/null

			docker run \
				--detach \
				--name ssh.pool-1.1.1 \
				--env "SSH_SUDO=ALL=(ALL) NOPASSWD:ALL" \
				--env "SSH_USER=app-1" \
				--env "SSH_USER_HOME=/var/www/%u" \
				--publish ${DOCKER_PORT_MAP_TCP_22}:22 \
				jdeathe/centos-ssh:latest \
			&> /dev/null

			container_port_22="$(
				__get_container_port \
					ssh.pool-1.1.1 \
					22/tcp
			)"

			if ! __is_container_ready \
				ssh.pool-1.1.1 \
				${STARTUP_TIME} \
				"/usr/sbin/sshd " \
				"grep \
					'^Server listening on 0\.0\.0\.0 port 22\.' \
					/var/log/secure"
			then
				exit 1
			fi

			it "Can replace %u with username in the path."
				user_home="$(
					ssh -q \
					-p ${container_port_22} \
					-i ${TEST_DIRECTORY}/fixture/id_rsa_insecure \
					-o StrictHostKeyChecking=no \
					-o LogLevel=error \
					app-1@${DOCKER_HOSTNAME} \
					-- printf \
						'%s\\n' \
						"\${HOME}"
				)"

				assert equal \
					"${user_home}" \
					"/var/www/app-1"
			end

			it "Logs the setting value."
				user_home="$(
					docker logs ssh.pool-1.1.1 \
					| awk '/^home :.*$/ { print $0; }'
				)"

				assert equal \
					"${user_home/home : /}" \
					"/var/www/app-1"
			end
		end

		describe "Configure id"
			__terminate_container \
				ssh.pool-1.1.1 \
			&> /dev/null

			docker run \
				--detach \
				--name ssh.pool-1.1.1 \
				--env "SSH_SUDO=ALL=(ALL) NOPASSWD:ALL" \
				--env "SSH_USER_ID=1000:502" \
				--publish ${DOCKER_PORT_MAP_TCP_22}:22 \
				jdeathe/centos-ssh:latest \
			&> /dev/null

			container_port_22="$(
				__get_container_port \
					ssh.pool-1.1.1 \
					22/tcp
			)"

			if ! __is_container_ready \
				ssh.pool-1.1.1 \
				${STARTUP_TIME} \
				"/usr/sbin/sshd " \
				"grep \
					'^Server listening on 0\.0\.0\.0 port 22\.' \
					/var/log/secure"
			then
				exit 1
			fi

			it "Can set the user's uid:gid."
				user_id="$(
					ssh -q \
					-p ${container_port_22} \
					-i ${TEST_DIRECTORY}/fixture/id_rsa_insecure \
					-o StrictHostKeyChecking=no \
					-o LogLevel=error \
					app-admin@${DOCKER_HOSTNAME} \
					-- printf \
						'%s:%s\\n' \
						"\$(id --user app-admin)" \
						"\$(id --group app-admin)"
				)"

				assert equal \
					"${user_id}" \
					"1000:502"
			end

			it "Logs the setting value."
				user_id="$(
					docker logs ssh.pool-1.1.1 \
					| awk '/^id :.*$/ { print $0; }'
				)"

				assert equal \
					"${user_id/id : /}" \
					"1000:502"
			end
		end

		describe "Configure shell"
			__terminate_container \
				ssh.pool-1.1.1 \
			&> /dev/null

			docker run \
				--detach \
				--name ssh.pool-1.1.1 \
				--env "SSH_SUDO=ALL=(ALL) NOPASSWD:ALL" \
				--env "SSH_USER_SHELL=/bin/sh" \
				--publish ${DOCKER_PORT_MAP_TCP_22}:22 \
				jdeathe/centos-ssh:latest \
			&> /dev/null

			container_port_22="$(
				__get_container_port \
					ssh.pool-1.1.1 \
					22/tcp
			)"

			if ! __is_container_ready \
				ssh.pool-1.1.1 \
				${STARTUP_TIME} \
				"/usr/sbin/sshd " \
				"grep \
					'^Server listening on 0\.0\.0\.0 port 22\.' \
					/var/log/secure"
			then
				exit 1
			fi

			it "Can set the user's shell."
				user_shell="$(
					ssh -q \
					-p ${container_port_22} \
					-i ${TEST_DIRECTORY}/fixture/id_rsa_insecure \
					-o StrictHostKeyChecking=no \
					-o LogLevel=error \
					app-admin@${DOCKER_HOSTNAME} \
					-- printf \
						'%s\\n' \
						"\$(getent passwd app-admin \
							| cut -d: -f7
						)"
				)"

				assert equal \
					"${user_shell}" \
					"/bin/sh"
			end

			it "Logs the setting value."
				user_shell="$(
					docker logs ssh.pool-1.1.1 \
					| awk '/^shell :.*$/ { print $0; }'
				)"

				assert equal \
					"${user_shell/shell : /}" \
					"/bin/sh"
			end
		end

		describe "Configure environment"
			__terminate_container \
				ssh.pool-1.1.1 \
			&> /dev/null

			docker run \
				--detach \
				--name ssh.pool-1.1.1 \
				--env "SSH_SUDO=ALL=(ALL) NOPASSWD:ALL" \
				--env "SSH_INHERIT_ENVIRONMENT=true" \
				--publish ${DOCKER_PORT_MAP_TCP_22}:22 \
				jdeathe/centos-ssh:latest \
			&> /dev/null

			container_port_22="$(
				__get_container_port \
					ssh.pool-1.1.1 \
					22/tcp
			)"

			if ! __is_container_ready \
				ssh.pool-1.1.1 \
				${STARTUP_TIME} \
				"/usr/sbin/sshd " \
				"grep \
					'^Server listening on 0\.0\.0\.0 port 22\.' \
					/var/log/secure"
			then
				exit 1
			fi

			it "Can inherit the environment."
				user_env_value="$(
					ssh -q \
					-p ${container_port_22} \
					-i ${TEST_DIRECTORY}/fixture/id_rsa_insecure \
					-o StrictHostKeyChecking=no \
					-o LogLevel=error \
					app-admin@${DOCKER_HOSTNAME} \
					-- printf \
						'%s\\n' \
						"\$(env | grep SSH_INHERIT_ENVIRONMENT=true)"
				)"

				assert equal \
					"${user_env_value}" \
					"SSH_INHERIT_ENVIRONMENT=true"
			end
		end

		describe "Configure password"
			__terminate_container \
				ssh.pool-1.1.1 \
			&> /dev/null

			docker run \
				--detach \
				--name ssh.pool-1.1.1 \
				--env "SSH_USER_PASSWORD=Insecure_Passw0rd£" \
				--publish ${DOCKER_PORT_MAP_TCP_22}:22 \
				jdeathe/centos-ssh:latest \
			&> /dev/null

			# Prevent sudo lecture output when testing the sudo password
			docker exec ssh.pool-1.1.1 \
				bash -c 'echo "Defaults lecture_file = /dev/null" > /etc/sudoers.d/no_lecture'

			container_port_22="$(
				__get_container_port \
					ssh.pool-1.1.1 \
					22/tcp
			)"

			if ! __is_container_ready \
				ssh.pool-1.1.1 \
				${STARTUP_TIME} \
				"/usr/sbin/sshd " \
				"grep \
					'^Server listening on 0\.0\.0\.0 port 22\.' \
					/var/log/secure"
			then
				exit 1
			fi

			it "Can set a plain text password."
				user_home="$(
					echo 'Insecure_Passw0rd£' \
					| ssh -q \
						-p ${container_port_22} \
						-i ${TEST_DIRECTORY}/fixture/id_rsa_insecure \
						-o StrictHostKeyChecking=no \
						-o LogLevel=error \
						app-admin@${DOCKER_HOSTNAME} \
						-- sudo -p "[password_test]" -S \
							printf \
								'%s\\n' \
								"\${HOME}"
				)"

				assert equal \
					"${user_home}" \
					"/home/app-admin"
			end

			# TODO
			# it "Will redact the value of SSH_USER_PASSWORD after bootstrap."
			# 	user_password="$(
			# 		docker exec ssh.pool-1.1.1 env \
			# 		| grep '^SSH_USER_PASSWORD='
			# 	)"
			# 	
			# 	assert equal \
			# 		"${user_password/SSH_USER_PASSWORD=/}" \
			# 		"${REDACTED_VALUE}"
			# end

			it "Logs a redacted value."
				user_password="$(
					docker logs ssh.pool-1.1.1 \
					| awk '/^password :.*$/ { print $0; }'
				)"

				assert equal \
					"${user_password/password : /}" \
					"${REDACTED_VALUE}"
			end

			# Reset sudo configuration
			docker exec ssh.pool-1.1.1 \
				bash -c 'rm -f /etc/sudoers.d/no_lecture'
		end

		describe "Configure hashed password"
			__terminate_container \
				ssh.pool-1.1.1 \
			&> /dev/null

			docker run \
				--detach \
				--name ssh.pool-1.1.1 \
				--env 'SSH_USER_PASSWORD=$6$pepper$g5/OhofGtHVo3wqRgVHFQrJDyK0mV9bDpF5HP964wuIkQ7MXuYq1KRTmShaUmTQW3ZRsjw2MjC1LNPh5HMcrY0' \
				--env "SSH_USER_PASSWORD_HASHED=true" \
				--publish ${DOCKER_PORT_MAP_TCP_22}:22 \
				jdeathe/centos-ssh:latest \
			&> /dev/null

			# Prevent sudo lecture output when testing the sudo password
			docker exec ssh.pool-1.1.1 \
				bash -c 'echo "Defaults lecture_file = /dev/null" > /etc/sudoers.d/no_lecture'

			container_port_22="$(
				__get_container_port \
					ssh.pool-1.1.1 \
					22/tcp
			)"

			if ! __is_container_ready \
				ssh.pool-1.1.1 \
				${STARTUP_TIME} \
				"/usr/sbin/sshd " \
				"grep \
					'^Server listening on 0\.0\.0\.0 port 22\.' \
					/var/log/secure"
			then
				exit 1
			fi

			it "Can set a hashed password."
				user_home="$(
					echo 'Passw0rd!' \
					| ssh -q \
						-p ${container_port_22} \
						-i ${TEST_DIRECTORY}/fixture/id_rsa_insecure \
						-o StrictHostKeyChecking=no \
						-o LogLevel=error \
						app-admin@${DOCKER_HOSTNAME} \
						-- sudo -p "[password_test]" -S \
							printf \
								'%s\\n' \
								"\${HOME}"
				)"

				assert equal \
					"${user_home}" \
					"/home/app-admin"
			end

			# TODO
			# it "Will redact the SSH_USER_PASSWORD environment variable after bootstrap."
			# 	user_password="$(
			# 		docker exec ssh.pool-1.1.1 env \
			# 		| grep '^SSH_USER_PASSWORD='
			# 	)"
			# 
			# 	assert equal \
			# 		"${user_password/SSH_USER_PASSWORD=/}" \
			# 		"${REDACTED_VALUE}"
			# end

			it "Logs a redacted value."
				user_password="$(
					docker logs ssh.pool-1.1.1 \
					| awk '/^password :.*$/ { print $0; }'
				)"

				assert equal \
					"${user_password/password : /}" \
					"${REDACTED_VALUE}"
			end
		end

		describe "Configure autostart"
			__terminate_container \
				ssh.pool-1.1.1 \
			&> /dev/null

			docker run \
				--detach \
				--name ssh.pool-1.1.1 \
				--env "SSH_AUTOSTART_SSHD_BOOTSTRAP=false" \
				--publish ${DOCKER_PORT_MAP_TCP_22}:22 \
				jdeathe/centos-ssh:latest \
			&> /dev/null

			if ! __is_container_ready \
				ssh.pool-1.1.1 \
				${STARTUP_TIME} \
				"/usr/sbin/sshd " \
				"grep \
					'^Server listening on 0\.0\.0\.0 port 22\.' \
					/var/log/secure"
			then
				exit 1
			fi

			it "Can disable sshd-bootstrap."
				docker logs ssh.pool-1.1.1 \
					| grep -qE 'INFO success: sshd-bootstrap entered RUNNING state'

				assert equal \
					"${?}" \
					"1"
			end

			__terminate_container \
				ssh.pool-1.1.1 \
			&> /dev/null

			docker run \
				--detach \
				--name ssh.pool-1.1.1 \
				--env "SSH_AUTOSTART_SSHD=false" \
				--publish ${DOCKER_PORT_MAP_TCP_22}:22 \
				jdeathe/centos-ssh:latest \
			&> /dev/null

			sleep ${STARTUP_TIME}

			it "Can disable sshd daemon."
				docker top ssh.pool-1.1.1 \
					| grep -qE '/usr/sbin/sshd -D'

				assert equal \
					"${?}" \
					"1"
			end
		end

		__terminate_container \
			ssh.pool-1.1.1 \
		&> /dev/null

		trap - \
			INT TERM EXIT
	end
}

function test_custom_sftp_configuration ()
{
	local container_port_22=""
	local chroot_path=""
	local user_shell=""

	describe "Customised SFTP configuration"
		trap "__terminate_container sftp.pool-1.1.1 &> /dev/null; \
			__terminate_container www-data.pool-1.1.1 &> /dev/null; \
			docker volume rm www-data.pool-1.1.1 &> /dev/null; \
			__destroy; \
			exit 1" \
			INT TERM EXIT

		__terminate_container \
			sftp.pool-1.1.1 \
		&> /dev/null

		describe "Configure a ChrootDirectory"
			docker run \
				--detach \
				--name sftp.pool-1.1.1 \
				--publish ${DOCKER_PORT_MAP_TCP_22}:22 \
				--env SSH_CHROOT_DIRECTORY="/chroot/%u" \
				--env SSH_USER_FORCE_SFTP=true \
				jdeathe/centos-ssh:latest \
			&> /dev/null

			container_port_22="$(
				__get_container_port \
					sftp.pool-1.1.1 \
					22/tcp
			)"

			if ! __is_container_ready \
				sftp.pool-1.1.1 \
				${STARTUP_TIME} \
				"/usr/sbin/sshd " \
				"grep \
					'^Server listening on 0\.0\.0\.0 port 22\.' \
					/var/log/secure"
			then
				exit 1
			fi

			it "Can replace %u with username in the path."
				docker exec sftp.pool-1.1.1 \
					touch /chroot/app-admin/home/app-admin/root_test
				docker exec sftp.pool-1.1.1 \
					chown app-admin:app-admin /chroot/app-admin/home/app-admin/root_test

				sftp -q \
					-i ${TEST_DIRECTORY}/fixture/id_rsa_insecure \
					-o StrictHostKeyChecking=no \
					-o LogLevel=error \
					-o Port=${container_port_22} \
					app-admin@${DOCKER_HOSTNAME} \
					<<< "ls /home/app-admin/root_test" \
					| grep -q "^/home/app-admin/root_test"

				assert equal \
					"${?}" \
					0
			end

			it "Logs the setting value."
				chroot_path="$(
					docker logs sftp.pool-1.1.1 \
					| awk '/^chroot path :.*$/ { print $0; }'
				)"

				assert equal \
					"${chroot_path/chroot path : /}" \
					"/chroot/app-admin"
			end

			it "Can write to HOME directory."
				sftp -q \
					-i ${TEST_DIRECTORY}/fixture/id_rsa_insecure \
					-o StrictHostKeyChecking=no \
					-o LogLevel=error \
					-o Port=${container_port_22} \
					app-admin@${DOCKER_HOSTNAME} \
					<<< "put ${TEST_DIRECTORY}/fixture/test_file" \
					&> /dev/null

				assert equal \
					"${?}" \
					0
			end
		end

		describe "Cross container data volume"
			__terminate_container \
				sftp.pool-1.1.1 \
			&> /dev/null

			__terminate_container \
				www-data.pool-1.1.1 \
			&> /dev/null

			docker volume \
				rm \
				www-data.pool-1.1.1 \
			&> /dev/null

			docker run \
				--detach \
				--name www-data.pool-1.1.1 \
				--env "SSH_AUTOSTART_SSHD=false" \
				--env "SSH_AUTOSTART_SSHD_BOOTSTRAP=true" \
				--volume www-data.pool-1.1.1:/var/www \
				jdeathe/centos-ssh:latest \
			&> /dev/null

			sleep ${STARTUP_TIME}

			docker cp \
				test/fixture/test_directory/var/www/. \
				www-data.pool-1.1.1:/var/www
			docker exec www-data.pool-1.1.1 \
				chown -R app-admin:app-admin /var/www/test

			docker run \
				--detach \
				--name sftp.pool-1.1.1 \
				--publish ${DOCKER_PORT_MAP_TCP_22}:22 \
				--env SSH_CHROOT_DIRECTORY="/var/www" \
				--env SSH_USER_FORCE_SFTP=true \
				--env SSH_USER_HOME="/var/www" \
				--volumes-from www-data.pool-1.1.1 \
				jdeathe/centos-ssh:latest \
			&> /dev/null

			container_port_22="$(
				__get_container_port \
					sftp.pool-1.1.1 \
					22/tcp
			)"

			if ! __is_container_ready \
				sftp.pool-1.1.1 \
				${STARTUP_TIME} \
				"/usr/sbin/sshd " \
				"grep \
					'^Server listening on 0\.0\.0\.0 port 22\.' \
					/var/log/secure"
			then
				exit 1
			fi

			it "Can list contents of mounted volume."
				sftp -q \
					-i ${TEST_DIRECTORY}/fixture/id_rsa_insecure \
					-o StrictHostKeyChecking=no \
					-o LogLevel=error \
					-o Port=${container_port_22} \
					app-admin@${DOCKER_HOSTNAME} \
					<<< "ls test/public_html/index.html" \
					| grep -q "^test/public_html/index.html"

				assert equal \
					"${?}" \
					0
			end

			__terminate_container \
				sftp.pool-1.1.1 \
			&> /dev/null

			__terminate_container \
				www-data.pool-1.1.1 \
			&> /dev/null

			docker volume \
				rm \
				www-data.pool-1.1.1 \
			&> /dev/null
		end

		trap - \
			INT TERM EXIT
	end
}

function test_healthcheck ()
{
	local -r interval_seconds=0.5
	local -r retries=5
	local health_status=""

	describe "Healthcheck"
		trap "__terminate_container ssh.pool-1.1.1 &> /dev/null; \
			__destroy; \
			exit 1" \
			INT TERM EXIT

		describe "Default configuration"
			__terminate_container \
				ssh.pool-1.1.1 \
			&> /dev/null

			docker run \
				--detach \
				--name ssh.pool-1.1.1 \
				jdeathe/centos-ssh:latest \
			&> /dev/null

			it "Returns a valid status on starting."
				health_status="$(
					docker inspect \
						--format='{{json .State.Health.Status}}' \
						ssh.pool-1.1.1
				)"

				assert __shpec_matcher_egrep \
					"${health_status}" \
					"\"(starting|healthy|unhealthy)\""
			end

			sleep $(
				awk \
					-v interval_seconds="${interval_seconds}" \
					-v startup_time="${STARTUP_TIME}" \
					'BEGIN { print 1 + interval_seconds + startup_time; }'
			)

			it "Returns healthy after startup."
				health_status="$(
					docker inspect \
						--format='{{json .State.Health.Status}}' \
						ssh.pool-1.1.1
				)"

				assert equal \
					"${health_status}" \
					"\"healthy\""
			end

			it "Returns unhealthy on failure."
				# sshd-wrapper failure
				docker exec -t \
					ssh.pool-1.1.1 \
					bash -c "mv \
						/usr/sbin/sshd \
						/usr/sbin/sshd2" \
				&& docker exec -t \
					ssh.pool-1.1.1 \
					bash -c "if [[ -n \$(pgrep -f '^/usr/sbin/sshd -D') ]]; then \
						kill -9 \$(pgrep -f '^/usr/sbin/sshd -D'); \
					fi"

				sleep $(
					awk \
						-v interval_seconds="${interval_seconds}" \
						-v retries="${retries}" \
						'BEGIN { print 1 + interval_seconds * retries; }'
				)

				health_status="$(
					docker inspect \
						--format='{{json .State.Health.Status}}' \
						ssh.pool-1.1.1
				)"

				assert equal \
					"${health_status}" \
					"\"unhealthy\""
			end
		end

		describe "Autostart false"
			__terminate_container \
				ssh.pool-1.1.1 \
			&> /dev/null

			docker run \
				--detach \
				--name ssh.pool-1.1.1 \
				--env SSH_AUTOSTART_SSHD=false \
				jdeathe/centos-ssh:latest \
			&> /dev/null

			it "Returns a valid status on starting."
				health_status="$(
					docker inspect \
						--format='{{json .State.Health.Status}}' \
						ssh.pool-1.1.1
				)"

				assert __shpec_matcher_egrep \
					"${health_status}" \
					"\"(starting|healthy|unhealthy)\""
			end

			sleep $(
				awk \
					-v interval_seconds="${interval_seconds}" \
					-v startup_time="${STARTUP_TIME}" \
					'BEGIN { print 1 + interval_seconds + startup_time; }'
			)

			it "Returns healthy after startup."
				health_status="$(
					docker inspect \
						--format='{{json .State.Health.Status}}' \
						ssh.pool-1.1.1
				)"

				assert equal \
					"${health_status}" \
					"\"healthy\""
			end

			it "Returns unhealthy on failure."
				# sshd-bootstrap failure
				docker exec -t \
					ssh.pool-1.1.1 \
					bash -c "sed -i \
						-e 's~# app-admin~~' \
						/etc/sudoers"

				sleep $(
					awk \
						-v interval_seconds="${interval_seconds}" \
						-v retries="${retries}" \
						'BEGIN { print 1 + interval_seconds * retries; }'
				)

				health_status="$(
					docker inspect \
						--format='{{json .State.Health.Status}}' \
						ssh.pool-1.1.1
				)"

				assert equal \
					"${health_status}" \
					"\"unhealthy\""
			end
		end

		__terminate_container \
			ssh.pool-1.1.1 \
		&> /dev/null

		trap - \
			INT TERM EXIT
	end
}

if [[ ! -d ${TEST_DIRECTORY} ]]; then
	printf -- \
		"ERROR: Please run from the project root.\n" \
		>&2
	exit 1
fi

describe "jdeathe/centos-ssh:latest"
	__destroy
	__setup
	test_basic_ssh_operations
	test_basic_sftp_operations
	test_custom_ssh_configuration
	test_custom_sftp_configuration
	test_healthcheck
	__destroy
end
