describe "Makefile"
	readonly DOCKER_NAME="makefile_test"

	it "builds the image"
		local status_make_build

		make build &> /dev/null
		status_make_build=${?}

		assert equal ${status_make_build} 0
	end

	it "creates the container"
		local status_make_install

		make install &> /dev/null
		status_make_install=${?}

		assert equal ${status_make_install} 0
	end

	it "starts the container"
		local status_make_start

		make start &> /dev/null
		status_make_start=${?}

		assert equal ${status_make_start} 0
	end

	it "pauses the container"
		local status_make_pause

		make pause &> /dev/null
		status_make_pause=${?}

		assert equal ${status_make_pause} 0
	end

	it "unpauses the container"
		local status_make_unpause

		make unpause &> /dev/null
		status_make_unpause=${?}

		assert equal ${status_make_unpause} 0
	end

	it "restarts the container"
		local status_make_restart

		make restart &> /dev/null
		status_make_restart=${?}

		assert equal ${status_make_restart} 0
	end

	it "outputs the container logs"
		local status_make_logs
		local content_make_logs

		content_make_logs=$(
			make logs
		)
		status_make_logs=${?}

		assert equal ${status_make_logs} 0
	end

	it "terminates the container"
		local status_make_terminate

		make terminate &> /dev/null
		status_make_terminate=${?}

		assert equal ${status_make_terminate} 0
	end

	it "runs the container"
		local status_make_run

		make run &> /dev/null
		status_make_run=${?}

		assert equal ${status_make_run} 0
	end

	it "stops the container"
		local status_make_stop

		make stop &> /dev/null
		status_make_stop=${?}

		assert equal ${status_make_stop} 0
	end

	it "deletes the container"
		local status_make_rm
	
		make rm &> /dev/null
		status_make_rm=${?}
	
		assert equal ${status_make_rm} 0
	end

	it "untags the image"
		local status_make_clean
	
		make rmi &> /dev/null
		status_make_clean=${?}
	
		assert equal ${status_make_clean} 0
	end
end