class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception


	def set_control
		Control.default_attributes if Control.count == 0
		@control = Control.last
	end


	def get_os
		os = nil

		case RUBY_PLATFORM
			when /linux$/i
				logger.info("get_os - Linux OS detected.")
				os = 'Linux'
			
			else
				logger.info('get_os - UNKNOWN OS!!!')
		end

		return os
	end


	def get_ssm_volumes
		# TODO: Scan for drives (preferably USB) with name "SnapShow"
		ssm_volumes = []

		os = get_os
		case os
			when 'Linux'
				# Linux
				volumes = `df -h`
				volumes = volumes.split("\n")
				logger.debug(volumes)
				volumes.each do |volume|
					# /dev/sdb1          7.7G   34M  7.6G   1% /media/randy/SNAPSHOW
					regex_volume = volume.match(/\s(\S*\/SnapShow\d*)$/i)
					ssm_volumes << regex_volume[1] if regex_volume
				end

			# TODO: when 'Windows'
		end

		logger.info('get_ssm_volumes - No SSM volumes found!!!') if ssm_volumes.empty?

		return ssm_volumes.sort
	end

end
