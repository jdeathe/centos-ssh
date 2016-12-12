readonly BOOTSTRAP_BACKOFF_TIME=2
readonly DOCKER_HOSTNAME="localhost"
readonly REDACTED_VALUE="********"
readonly TEST_DIRECTORY="test"
readonly PUBLIC_KEY_ID_RSA_TEST_1="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDHzd+mYXSGLQSZwUJWwYKOBI6I7mhHh3Ow0DbTQvQUHhkDcQVrqjpBKZq8SsnEK4ExyJeRQ5TtT5VqolfVG6LlaT3yxXmJxx75Y8oypFAKz7oCOQCJugqubAkx2YpT6KO7d6UOPqOuLpmFi3t+Ryf49TbNljSes1sbSCxUDlTekxG+It+/eZUqXWudornYJCfmMe1UAYtRwMKiyDWqU1LN1Kb2zVR76YpjMxK9IiEJjhpZS/R70zxGEijFrL+Rv4Bx8y/UjAVVtTkvpaEajx7pMnd0fsfnUwhYLoVHgG5ZdHAYSRy8j/0+mpeVEsTQZJAnegUbVNuBEc3x2b1xgkS3 test_key_1"
readonly PUBLIC_KEY_ID_RSA_TEST_1_SIGNATURE="45:46:b0:ef:a5:e3:c9:6f:1e:66:94:ba:e1:fd:df:65"
readonly PUBLIC_KEY_ID_RSA_TEST_2="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDD/sMi/JkrYtXVi6+pYuwvsUxLDXowp3okvK2+2qqnPA6nWGBu/LSSQZnYmHZYyhcbRKrdscnsbM0jfmU0cKf/lGiRRK1YfUepomtRWVBxzA3mvBu+qmbuU/PDHfJJxB19HHuc6a8/NPOZINNMGIZg91W79bW0gXIEh3+PiNVvuelOdFJdvKSWtElJlMk/ll7dS1vpwJ9iZ8EPbalSzEZ30SzqG8Xg4VMhOn9ybnvcNWGJVCg4yughmdVA32H2+rj6qis4AJdQYUNoh9kBK/XUoggRV7LEaeeyjMWPn6GxM4yM7IYkstpilbKiPIQjw9EDTN4FdIJ/LcescfwDT7KZ test_key_2"
readonly PUBLIC_KEY_ID_RSA_TEST_2_SIGNATURE="b3:2e:5d:8c:76:d3:c7:24:13:a3:4f:6f:4d:a2:31:9c"
readonly PUBLIC_KEY_ID_RSA_TEST_COMBINED_BASE64="c3NoLXJzYSBBQUFBQjNOemFDMXljMkVBQUFBREFRQUJBQUFCQVFESHpkK21ZWFNHTFFTWndVSld3WUtPQkk2STdtaEhoM093MERiVFF2UVVIaGtEY1FWcnFqcEJLWnE4U3NuRUs0RXh5SmVSUTVUdFQ1VnFvbGZWRzZMbGFUM3l4WG1KeHg3NVk4b3lwRkFLejdvQ09RQ0p1Z3F1YkFreDJZcFQ2S083ZDZVT1BxT3VMcG1GaTN0K1J5ZjQ5VGJObGpTZXMxc2JTQ3hVRGxUZWt4RytJdCsvZVpVcVhXdWRvcm5ZSkNmbU1lMVVBWXRSd01LaXlEV3FVMUxOMUtiMnpWUjc2WXBqTXhLOUlpRUpqaHBaUy9SNzB6eEdFaWpGckwrUnY0Qng4eS9VakFWVnRUa3ZwYUVhang3cE1uZDBmc2ZuVXdoWUxvVkhnRzVaZEhBWVNSeThqLzArbXBlVkVzVFFaSkFuZWdVYlZOdUJFYzN4MmIxeGdrUzMgdGVzdF9rZXlfMQpzc2gtcnNhIEFBQUFCM056YUMxeWMyRUFBQUFEQVFBQkFBQUJBUUREL3NNaS9Ka3JZdFhWaTYrcFl1d3ZzVXhMRFhvd3Azb2t2SzIrMnFxblBBNm5XR0J1L0xTU1FablltSFpZeWhjYlJLcmRzY25zYk0wamZtVTBjS2YvbEdpUlJLMVlmVWVwb210UldWQnh6QTNtdkJ1K3FtYnVVL1BESGZKSnhCMTlISHVjNmE4L05QT1pJTk5NR0laZzkxVzc5YlcwZ1hJRWgzK1BpTlZ2dWVsT2RGSmR2S1NXdEVsSmxNay9sbDdkUzF2cHdKOWlaOEVQYmFsU3pFWjMwU3pxRzhYZzRWTWhPbjl5Ym52Y05XR0pWQ2c0eXVnaG1kVkEzMkgyK3JqNnFpczRBSmRRWVVOb2g5a0JLL1hVb2dnUlY3TEVhZWV5ak1XUG42R3hNNHlNN0lZa3N0cGlsYktpUElRanc5RURUTjRGZElKL0xjZXNjZndEVDdLWiB0ZXN0X2tleV8yCg=="

# This should ideally be a static value but hosts might be using this port so 
# need to allow for an alternative.
DOCKER_PORT_MAP_TCP_22="${DOCKER_PORT_MAP_TCP_22:-2020}"

function docker_terminate_container ()
{
	local CONTAINER="${1}"

	if docker ps -aq \
		--filter "name=${CONTAINER}" \
		--filter "status=paused" &> /dev/null; then
		docker unpause ${CONTAINER} &> /dev/null
	fi

	if docker ps -aq \
		--filter "name=${CONTAINER}" \
		--filter "status=running" &> /dev/null; then
		docker stop ${CONTAINER} &> /dev/null
	fi

	if docker ps -aq \
		--filter "name=${CONTAINER}" &> /dev/null; then
		docker rm -vf ${CONTAINER} &> /dev/null
	fi
}

function test_setup ()
{
	chmod 600 ${TEST_DIRECTORY}/fixture/{id_rsa_insecure,id_rsa_test_1,id_rsa_test_2}
}

if [[ ! -d ${TEST_DIRECTORY} ]]; then
	printf -- \
		"ERROR: Please run from the project root.\n" \
		>&2
	exit 1
fi

describe "jdeathe/centos-ssh"
	test_setup

	describe "Basic SSH operations"
		trap "docker_terminate_container ssh.pool-1.1.1 &> /dev/null" \
			INT TERM EXIT

		docker_terminate_container ssh.pool-1.1.1 &> /dev/null

		it "Runs an SSH container named ssh.pool-1.1.1 on port ${DOCKER_PORT_MAP_TCP_22}."
			local container_port_22=""

			docker run -d \
				--name ssh.pool-1.1.1 \
				--publish ${DOCKER_PORT_MAP_TCP_22}:22 \
				jdeathe/centos-ssh:latest &> /dev/null

			container_port_22="$(
				docker port \
				ssh.pool-1.1.1 \
				22/tcp
			)"
			container_port_22=${container_port_22##*:}

			if [[ ${DOCKER_PORT_MAP_TCP_22} == 0 ]] \
				|| [[ -z ${DOCKER_PORT_MAP_TCP_22} ]]; then
				assert gt "${container_port_22}" "30000"
			else
				assert equal "${container_port_22}" "${DOCKER_PORT_MAP_TCP_22}"
			fi
		end

		sleep ${BOOTSTRAP_BACKOFF_TIME}

		it "Generates a password that can be retrieved from the log."
			local password=""

			password="$(
				docker logs ssh.pool-1.1.1 \
				| awk '/^password :.*$/ { print $3 }'
			)"

			assert unequal "${password}" ""

			it "Displays the password in plain text."
				assert unequal "${password}" "${REDACTED_VALUE}"
			end
		end

		it "Allows the user to connect using SSH + private key authentication."
			local status_ssh_connection=""
			local user_home=""

			# Prevent sudo lecture output when testing the sudo password
			docker exec ssh.pool-1.1.1 \
				bash -c 'echo "Defaults lecture_file = /dev/null" > /etc/sudoers.d/no_lecture'

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

			status_ssh_connection=${?}

			assert equal "${status_ssh_connection}" 0

			it "Requires a password for sudo commands."
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

				assert equal "${user_home}" "/home/app-admin"
			end

			# Reset sudo configuration
			docker exec ssh.pool-1.1.1 \
				bash -c 'rm -f /etc/sudoers.d/no_lecture'
		end

		docker_terminate_container ssh.pool-1.1.1 &> /dev/null
		trap - \
			INT TERM EXIT
	end
	
	describe "Basic SFTP operations"
		trap "docker_terminate_container sftp.pool-1.1.1 &> /dev/null" \
			INT TERM EXIT

		docker_terminate_container sftp.pool-1.1.1 &> /dev/null

		it "Runs an SFTP container named sftp.pool-1.1.1 on port ${DOCKER_PORT_MAP_TCP_22}."
			local container_port_22=""

			docker run -d \
				--name sftp.pool-1.1.1 \
				--publish ${DOCKER_PORT_MAP_TCP_22}:22 \
				--env SSH_USER_FORCE_SFTP=true \
				jdeathe/centos-ssh:latest &> /dev/null

			container_port_22="$(
				docker port \
				sftp.pool-1.1.1 \
				22/tcp
			)"
			container_port_22=${container_port_22##*:}

			if [[ ${DOCKER_PORT_MAP_TCP_22} == 0 ]] \
				|| [[ -z ${DOCKER_PORT_MAP_TCP_22} ]]; then
				assert gt "${container_port_22}" "30000"
			else
				assert equal "${container_port_22}" "${DOCKER_PORT_MAP_TCP_22}"
			fi
		end

		sleep ${BOOTSTRAP_BACKOFF_TIME}

		it "Allows the user to connect using SFTP + private key authentication."
			local status_sftp_connection=""

			sftp -q \
				-P ${container_port_22} \
				-i ${TEST_DIRECTORY}/fixture/id_rsa_insecure \
				-o StrictHostKeyChecking=no \
				-o LogLevel=error \
				app-admin@${DOCKER_HOSTNAME} \
				<<< "version" \
				&> /dev/null

			status_sftp_connection=${?}

			assert equal "${status_sftp_connection}" 0

			it "Allows the user to upload a file to their _data directory."
				local status_sftp_connection=""

				sftp -q \
					-P ${container_port_22} \
					-i ${TEST_DIRECTORY}/fixture/id_rsa_insecure \
					-o StrictHostKeyChecking=no \
					-o LogLevel=error \
					app-admin@${DOCKER_HOSTNAME}:_data \
					<<< "put ${TEST_DIRECTORY}/fixture/test_file" \
					&> /dev/null

				status_sftp_connection=${?}

				assert equal "${status_sftp_connection}" 0
			end

			it "Jails the user into a chroot directory."
				local status_sftp_connection=""

				docker exec sftp.pool-1.1.1 \
					touch /home/app-admin/root_test

				sftp -q \
					-P ${container_port_22} \
					-i ${TEST_DIRECTORY}/fixture/id_rsa_insecure \
					-o StrictHostKeyChecking=no \
					-o LogLevel=error \
					app-admin@${DOCKER_HOSTNAME} \
					<<< "ls /root_test" \
					| grep -q "^/root_test"

				status_sftp_connection=${?}

				assert equal "${status_sftp_connection}" 0
			end
		end

		docker_terminate_container sftp.pool-1.1.1 &> /dev/null
		trap - \
			INT TERM EXIT
	end

	describe "Customised SSH configuration"
		trap "docker_terminate_container ssh.pool-1.1.1 &> /dev/null" \
			INT TERM EXIT

		it "Allows configuration of passwordless sudo."
			local container_port_22=""
			local user_home=""

			docker_terminate_container ssh.pool-1.1.1 &> /dev/null

			docker run -d \
				--name ssh.pool-1.1.1 \
				--env "SSH_SUDO=ALL=(ALL) NOPASSWD:ALL" \
				--publish ${DOCKER_PORT_MAP_TCP_22}:22 \
				jdeathe/centos-ssh:latest &> /dev/null

			container_port_22="$(
				docker port \
				ssh.pool-1.1.1 \
				22/tcp
			)"
			container_port_22=${container_port_22##*:}

			sleep ${BOOTSTRAP_BACKOFF_TIME}

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

			assert equal "${user_home}" "/home/app-admin"

			it "Displays the sudo settings in the logs output summary."
				local user_sudo=""

				user_sudo="$(
					docker logs ssh.pool-1.1.1 \
					| awk '/^sudo :.*$/ { print $0; }'
				)"

				assert equal "${user_sudo/sudo : /}" "ALL=(ALL) NOPASSWD:ALL"
			end
		end

		it "Allows configuration of the username."
			local container_port_22=""
			local user_home=""

			docker_terminate_container ssh.pool-1.1.1 &> /dev/null

			docker run -d \
				--name ssh.pool-1.1.1 \
				--env "SSH_SUDO=ALL=(ALL) NOPASSWD:ALL" \
				--env "SSH_USER=centos" \
				--publish ${DOCKER_PORT_MAP_TCP_22}:22 \
				jdeathe/centos-ssh:latest &> /dev/null

			container_port_22="$(
				docker port \
				ssh.pool-1.1.1 \
				22/tcp
			)"
			container_port_22=${container_port_22##*:}

			sleep ${BOOTSTRAP_BACKOFF_TIME}

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

			assert equal "${user_home}" "/home/centos"

			it "Displays the user in the logs output summary."
				local user=""

				user="$(docker logs ssh.pool-1.1.1 \
					| awk '/^user :.*$/ { print $0; }'
				)"

				assert equal "${user/user : /}" "centos"
			end
		end

		it "Allows configuration of an alternative public key."
			local container_port_22=""
			local user_home=""

			docker_terminate_container ssh.pool-1.1.1 &> /dev/null

			docker run -d \
				--name ssh.pool-1.1.1 \
				--env "SSH_SUDO=ALL=(ALL) NOPASSWD:ALL" \
				--env "SSH_AUTHORIZED_KEYS=${PUBLIC_KEY_ID_RSA_TEST_1}" \
				--publish ${DOCKER_PORT_MAP_TCP_22}:22 \
				jdeathe/centos-ssh:latest &> /dev/null

			container_port_22="$(
				docker port \
				ssh.pool-1.1.1 \
				22/tcp
			)"
			container_port_22=${container_port_22##*:}

			sleep ${BOOTSTRAP_BACKOFF_TIME}

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

			assert equal "${user_home}" "/home/app-admin"

			it "Displays the key's signature in the logs output summary."
				local user_key_signature=""

				user_key_signature="$(
					docker logs ssh.pool-1.1.1 \
					| awk '/^45:46:b0:ef:a5:e3:c9:6f:1e:66:94:ba:e1:fd:df:65$/ { print $1; }'
				)"

				assert equal "${user_key_signature}" "${PUBLIC_KEY_ID_RSA_TEST_1_SIGNATURE}"
			end

			it "Allows multiple keys to be added as a base64 encoded string."
				local container_port_22=""
				local user_key=""

				docker_terminate_container ssh.pool-1.1.1 &> /dev/null

				docker run -d \
					--name ssh.pool-1.1.1 \
					--env "SSH_SUDO=ALL=(ALL) NOPASSWD:ALL" \
					--env "SSH_AUTHORIZED_KEYS=${PUBLIC_KEY_ID_RSA_TEST_COMBINED_BASE64}" \
					--publish ${DOCKER_PORT_MAP_TCP_22}:22 \
					jdeathe/centos-ssh:latest &> /dev/null

				container_port_22="$(
					docker port \
					ssh.pool-1.1.1 \
					22/tcp
				)"
				container_port_22=${container_port_22##*:}

				sleep ${BOOTSTRAP_BACKOFF_TIME}

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

				assert equal "${user_home}" "/home/app-admin:/home/app-admin"

				it "Displays the key's signatures in the logs output summary."
					local user_key_signature=""

					user_key_signature="$(
						docker logs ssh.pool-1.1.1 \
						| awk '/^45:46:b0:ef:a5:e3:c9:6f:1e:66:94:ba:e1:fd:df:65$/ { print $1; }'
					)"

					user_key_signature+=" "

					user_key_signature+="$(
						docker logs ssh.pool-1.1.1 \
						| awk '/^b3:2e:5d:8c:76:d3:c7:24:13:a3:4f:6f:4d:a2:31:9c$/ { print $1; }'
					)"

					assert equal "${user_key_signature}" \
						"${PUBLIC_KEY_ID_RSA_TEST_1_SIGNATURE} ${PUBLIC_KEY_ID_RSA_TEST_2_SIGNATURE}"
				end
			end
		end

		it "Allows configuration of the user's home directory where %u is replaced with the username in the path."
			local container_port_22=""
			local user_home=""

			docker_terminate_container ssh.pool-1.1.1 &> /dev/null

			docker run -d \
				--name ssh.pool-1.1.1 \
				--env "SSH_SUDO=ALL=(ALL) NOPASSWD:ALL" \
				--env "SSH_USER=app-1" \
				--env "SSH_USER_HOME=/var/www/%u" \
				--publish ${DOCKER_PORT_MAP_TCP_22}:22 \
				jdeathe/centos-ssh:latest &> /dev/null

			container_port_22="$(
				docker port \
				ssh.pool-1.1.1 \
				22/tcp
			)"
			container_port_22=${container_port_22##*:}

			sleep ${BOOTSTRAP_BACKOFF_TIME}

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

			assert equal "${user_home}" "/var/www/app-1"

			it "Displays the user's home directory in the logs output summary."
				local home=""

				home="$(
					docker logs ssh.pool-1.1.1 \
					| awk '/^home :.*$/ { print $0; }'
				)"

				assert equal "${home/home : /}" "/var/www/app-1"
			end
		end

		it "Allows configuration of the user's uid:gid."
			local container_port_22=""
			local user_id=""

			docker_terminate_container ssh.pool-1.1.1 &> /dev/null

			docker run -d \
				--name ssh.pool-1.1.1 \
				--env "SSH_SUDO=ALL=(ALL) NOPASSWD:ALL" \
				--env "SSH_USER_ID=1000:502" \
				--publish ${DOCKER_PORT_MAP_TCP_22}:22 \
				jdeathe/centos-ssh:latest &> /dev/null

			container_port_22="$(
				docker port \
				ssh.pool-1.1.1 \
				22/tcp
			)"
			container_port_22=${container_port_22##*:}

			sleep ${BOOTSTRAP_BACKOFF_TIME}

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

			assert equal "${user_id}" "1000:502"

			it "Displays the user's uid:gid in the logs output summary."
				local user_id=""

				user_id="$(
					docker logs ssh.pool-1.1.1 \
					| awk '/^id :.*$/ { print $0; }'
				)"

				assert equal "${user_id/id : /}" "1000:502"
			end
		end

		it "Allows configuration of the user's shell."
			local container_port_22=""
			local user_shell=""

			docker_terminate_container ssh.pool-1.1.1 &> /dev/null

			docker run -d \
				--name ssh.pool-1.1.1 \
				--env "SSH_SUDO=ALL=(ALL) NOPASSWD:ALL" \
				--env "SSH_USER_SHELL=/bin/sh" \
				--publish ${DOCKER_PORT_MAP_TCP_22}:22 \
				jdeathe/centos-ssh:latest &> /dev/null

			container_port_22="$(
				docker port \
				ssh.pool-1.1.1 \
				22/tcp
			)"
			container_port_22=${container_port_22##*:}

			sleep ${BOOTSTRAP_BACKOFF_TIME}

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

			assert equal "${user_shell}" "/bin/sh"

			it "Displays the user's shell in the logs output summary."
				local user_shell=""

				user_shell="$(
					docker logs ssh.pool-1.1.1 \
					| awk '/^shell :.*$/ { print $0; }'
				)"

				assert equal "${user_shell/shell : /}" "/bin/sh"
			end
		end

		it "Allows configuration to enable the environment to be inherited."
			local container_port_22=""
			local user_env_value=""

			docker_terminate_container ssh.pool-1.1.1 &> /dev/null

			docker run -d \
				--name ssh.pool-1.1.1 \
				--env "SSH_SUDO=ALL=(ALL) NOPASSWD:ALL" \
				--env "SSH_INHERIT_ENVIRONMENT=true" \
				--publish ${DOCKER_PORT_MAP_TCP_22}:22 \
				jdeathe/centos-ssh:latest &> /dev/null

			container_port_22="$(
				docker port \
				ssh.pool-1.1.1 \
				22/tcp
			)"
			container_port_22=${container_port_22##*:}

			sleep ${BOOTSTRAP_BACKOFF_TIME}

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

			assert equal "${user_env_value}" "SSH_INHERIT_ENVIRONMENT=true"
		end

		it "Allows configuration of a plain text password."
			local container_port_22=""
			local user_home=""

			docker_terminate_container ssh.pool-1.1.1 &> /dev/null

			docker run -d \
				--name ssh.pool-1.1.1 \
				--env "SSH_USER_PASSWORD=Insecure_Passw0rd£" \
				--publish ${DOCKER_PORT_MAP_TCP_22}:22 \
				jdeathe/centos-ssh:latest &> /dev/null

			container_port_22="$(
				docker port \
				ssh.pool-1.1.1 \
				22/tcp
			)"
			container_port_22=${container_port_22##*:}

			# Prevent sudo lecture output when testing the sudo password
			docker exec ssh.pool-1.1.1 \
				bash -c 'echo "Defaults lecture_file = /dev/null" > /etc/sudoers.d/no_lecture'

			sleep ${BOOTSTRAP_BACKOFF_TIME}

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

			assert equal "${user_home}" "/home/app-admin"

			it "Will redact the SSH_USER_PASSWORD environment variable after bootstrap."
				# TODO
				# user_password="$(
				# 	docker exec ssh.pool-1.1.1 env \
				# 	| grep '^SSH_USER_PASSWORD='
				# )"
				# 
				# assert equal \
				# 	"${user_password/SSH_USER_PASSWORD=/}" \
				# 	"${REDACTED_VALUE}"
			end

			it "Will redact the user's password in the logs output summary."
				local password=""

				password="$(
					docker logs ssh.pool-1.1.1 \
					| awk '/^password :.*$/ { print $0; }'
				)"

				assert equal "${password/password : /}" "${REDACTED_VALUE}"
			end
		end

		it "Allows configuration of a hashed password."
			local container_port_22=""
			local user_home=""

			docker_terminate_container ssh.pool-1.1.1 &> /dev/null

			docker run -d \
				--name ssh.pool-1.1.1 \
				--env 'SSH_USER_PASSWORD=$6$pepper$g5/OhofGtHVo3wqRgVHFQrJDyK0mV9bDpF5HP964wuIkQ7MXuYq1KRTmShaUmTQW3ZRsjw2MjC1LNPh5HMcrY0' \
				--env "SSH_USER_PASSWORD_HASHED=true" \
				--publish ${DOCKER_PORT_MAP_TCP_22}:22 \
				jdeathe/centos-ssh:latest &> /dev/null

			container_port_22="$(
				docker port \
				ssh.pool-1.1.1 \
				22/tcp
			)"
			container_port_22=${container_port_22##*:}

			# Prevent sudo lecture output when testing the sudo password
			docker exec ssh.pool-1.1.1 \
				bash -c 'echo "Defaults lecture_file = /dev/null" > /etc/sudoers.d/no_lecture'

			sleep ${BOOTSTRAP_BACKOFF_TIME}

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

			assert equal "${user_home}" "/home/app-admin"

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

			it "Will redact the user's password in the logs output summary."
				local password=""

				password="$(
					docker logs ssh.pool-1.1.1 \
					| awk '/^password :.*$/ { print $0; }'
				)"

				assert equal "${password/password : /}" "${REDACTED_VALUE}"
			end
		end

		it "Allows preventing the startup of the sshd bootstrap."
			local container_port_22=""
			local sshd_bootstrap_info=""

			docker_terminate_container ssh.pool-1.1.1 &> /dev/null

			docker run -d \
				--name ssh.pool-1.1.1 \
				--env "SSH_AUTOSTART_SSHD_BOOTSTRAP=false" \
				--publish ${DOCKER_PORT_MAP_TCP_22}:22 \
				jdeathe/centos-ssh:latest &> /dev/null

			sleep ${BOOTSTRAP_BACKOFF_TIME}

			sshd_bootstrap_info="$(
				docker logs ssh.pool-1.1.1 \
				| awk '/INFO success: sshd-bootstrap entered RUNNING state/ { print $0; }'
			)"

			assert equal "${sshd_bootstrap_info}" ""
		end

		it "Allows preventing the startup of the sshd daemon."
			local container_port_22=""
			local docker_top=""

			docker_terminate_container ssh.pool-1.1.1 &> /dev/null

			docker run -d \
				--name ssh.pool-1.1.1 \
				--env "SSH_AUTOSTART_SSHD=false" \
				--publish ${DOCKER_PORT_MAP_TCP_22}:22 \
				jdeathe/centos-ssh:latest &> /dev/null

			sleep ${BOOTSTRAP_BACKOFF_TIME}

			docker_top="$(
				docker top ssh.pool-1.1.1 \
				| awk '/\/usr\/sbin\/sshd -/ { print $0; }'
			)"

			assert equal "${docker_top}" ""
		end

		docker_terminate_container ssh.pool-1.1.1 &> /dev/null
		trap - \
			INT TERM EXIT
	end

	describe "Customised SFTP configuration"
		trap "docker_terminate_container sftp.pool-1.1.1 &> /dev/null; docker_terminate_container www-data.pool-1.1.1 &> /dev/null; docker volume rm www-data.pool-1.1.1 &> /dev/null" \
			INT TERM EXIT

		docker_terminate_container sftp.pool-1.1.1 &> /dev/null

		it "Allows configuration of the user's ChrootDirectory where %u is replaced with the username in the path."
			local container_port_22=""
			local status_sftp_connection=""

			docker run -d \
				--name sftp.pool-1.1.1 \
				--publish ${DOCKER_PORT_MAP_TCP_22}:22 \
				--env SSH_CHROOT_DIRECTORY="/chroot/%u" \
				--env SSH_USER_FORCE_SFTP=true \
				jdeathe/centos-ssh:latest \
				&> /dev/null

			container_port_22="$(
				docker port \
				sftp.pool-1.1.1 \
				22/tcp
			)"
			container_port_22=${container_port_22##*:}

			sleep ${BOOTSTRAP_BACKOFF_TIME}

			docker exec sftp.pool-1.1.1 \
				touch /chroot/app-admin/home/app-admin/root_test
			docker exec sftp.pool-1.1.1 \
				chown app-admin:app-admin /chroot/app-admin/home/app-admin/root_test

			sftp -q \
				-P ${container_port_22} \
				-i ${TEST_DIRECTORY}/fixture/id_rsa_insecure \
				-o StrictHostKeyChecking=no \
				-o LogLevel=error \
				app-admin@${DOCKER_HOSTNAME} \
				<<< "ls /home/app-admin/root_test" \
				| grep -q "^/home/app-admin/root_test"

			status_sftp_connection=${?}

			assert equal "${status_sftp_connection}" 0

			it "Displays the chroot path in the logs output summary."
				local chroot_path=""

				chroot_path="$(
					docker logs sftp.pool-1.1.1 \
					| awk '/^chroot path :.*$/ { print $0; }'
				)"

				assert equal "${chroot_path/chroot path : /}" "/chroot/app-admin"
			end

			it "Configures the user with the /sbin/nologin shell."
				local user_shell=""

				user_shell="$(
					docker exec sftp.pool-1.1.1 \
						getent passwd app-admin \
						| cut -d: -f7
				)"

				assert equal "${user_shell}" "/sbin/nologin"
			
				it "Displays the user's shell in the logs output summary."
					local user_shell=""

					user_shell="$(
						docker logs sftp.pool-1.1.1 \
						| awk '/^shell :.*$/ { print $0; }'
					)"

					assert equal "${user_shell/shell : /}" "/sbin/nologin"
				end
			end

			it "Allows the user to write to their HOME directory."
				local status_sftp_connection=""

				sftp -q \
					-P ${container_port_22} \
					-i ${TEST_DIRECTORY}/fixture/id_rsa_insecure \
					-o StrictHostKeyChecking=no \
					-o LogLevel=error \
					app-admin@${DOCKER_HOSTNAME} \
					<<< "put ${TEST_DIRECTORY}/fixture/test_file" \
					&> /dev/null

				status_sftp_connection=${?}

				assert equal "${status_sftp_connection}" 0
			end
		end

		it "Allows configuration of SFTP access to a volume mounted from another container."
			local container_port_22=""
			local status_sftp_connection=""

			docker_terminate_container sftp.pool-1.1.1 &> /dev/null
			docker_terminate_container www-data.pool-1.1.1 &> /dev/null
			docker volume rm www-data.pool-1.1.1 &> /dev/null

			docker run -d \
				--name www-data.pool-1.1.1 \
				--volume www-data.pool-1.1.1:/var/www \
				jdeathe/centos-ssh:latest \
				&> /dev/null

			sleep ${BOOTSTRAP_BACKOFF_TIME}

			docker cp \
				test/fixture/test_directory/var/www \
				www-data.pool-1.1.1:/var/
			docker exec www-data.pool-1.1.1 \
				chown -R app-admin:app-admin /var/www/test

			docker run -d \
				--name sftp.pool-1.1.1 \
				--publish ${DOCKER_PORT_MAP_TCP_22}:22 \
				--env SSH_CHROOT_DIRECTORY="/var/www" \
				--env SSH_USER_FORCE_SFTP=true \
				--env SSH_USER_HOME="/var/www" \
				--volumes-from www-data.pool-1.1.1 \
				jdeathe/centos-ssh:latest \
				&> /dev/null

			container_port_22="$(
				docker port \
				sftp.pool-1.1.1 \
				22/tcp
			)"
			container_port_22=${container_port_22##*:}

			sleep ${BOOTSTRAP_BACKOFF_TIME}

			sftp -q \
				-P ${container_port_22} \
				-i ${TEST_DIRECTORY}/fixture/id_rsa_insecure \
				-o StrictHostKeyChecking=no \
				-o LogLevel=error \
				app-admin@${DOCKER_HOSTNAME} \
				<<< "ls test/public_html/index.html" \
				| grep -q "^test/public_html/index.html"

			status_sftp_connection=${?}

			assert equal "${status_sftp_connection}" 0
		end

		docker_terminate_container sftp.pool-1.1.1 &> /dev/null
		docker_terminate_container www-data.pool-1.1.1 &> /dev/null
		docker volume rm www-data.pool-1.1.1 &> /dev/null
		trap - \
			INT TERM EXIT
	end
end
