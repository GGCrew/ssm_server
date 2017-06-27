class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception


	def set_control
		Control.default_attributes if Control.count == 0
		@control = Control.last
	end


=begin
	def get_os
		os = nil

		case RUBY_PLATFORM
			when /linux$/i
				logger.info('get_os - Linux OS detected.')
				os = 'Linux'
			
			when 'i386-mingw32'
				logger.info('get_os - Windows OS detected.')
				os = 'Windows'

			else
				logger.info('get_os - UNKNOWN OS!!!')
		end

		return os
	end
=end


	def get_ssm_volumes
		# TODO: Scan for drives (preferably USB) with name "SnapShow"
		ssm_volumes = []

		os = get_os
		case os
			when 'Linux'
				# Linux
				volumes = `df -h`
				volumes = volumes.split("\n")
				volumes.each do |volume|
					# /dev/sdb1          7.7G   34M  7.6G   1% /media/randy/SNAPSHOW
					regex_volume = volume.match(/\s(\S*\/SnapShow\d*)$/i)
					ssm_volumes << regex_volume[1] if regex_volume
				end

			when 'Windows'
				# Windows
				volumes = `wmic logicaldisk get name, volumename`
				volumes = volumes.split("\n")                    # break multiline text into array of lines
				volumes.uniq!                                    # remove duplicate items (typically "" items)
				#volumes.reject!{|i| i.empty?}                    # remove empty items (eg "")
				volumes.collect!{|i| i.split(' ')}               # split "D:    SNAPSHOW     " into ["D:", "SNAPSHOW"]
				volumes.select!{|i| i.count == 2}                # remove items without a volumename (eg ["C:"])
				volumes.reject!{|i| (i[1] =~ /SnapShow/i).nil?}  # keep items with "SnapShow" volume name (case-insensitive)
				ssm_volumes = volumes.collect{|i| i[0]}				   # keep only the drive letters (eg ["D:", "E:"])
		end

		logger.info('get_ssm_volumes - No SSM volumes found!!!') if ssm_volumes.empty?

		return ssm_volumes.sort
	end


	def get_local_folder
		local_folder = nil

		case get_os
			when 'Linux'
				# ~
				user_folder = ENV['HOME']

			when 'Windows'
				# %USERPROFILE%\Desktop
				user_folder = Win32::Registry::HKEY_CURRENT_USER.open('Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders')['Desktop']
		end

		if user_folder
			# TODO: figure out a better folder than today's date
			user_folder = File.realdirpath(user_folder)
			local_folder = File.join(user_folder, Date.today.strftime('%Y-%m-%d'))
			Dir.mkdir(local_folder) unless Dir.exists?(local_folder)
		else
			logger.info('get_local_folder - No user folder set!!!')
		end

		return local_folder
	end

end
