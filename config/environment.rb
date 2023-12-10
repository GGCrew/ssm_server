# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Custom global methods
def get_os
	os = nil

	case RbConfig::CONFIG['host_os']
		when /linux/i
			#logger.info('get_os - Linux OS detected.')
			os = 'Linux'

			# Check if we're running via Windows Subsytem for Linux
			osrelease = `cat /proc/sys/kernel/osrelease`.strip
			os = 'WSL' if osrelease.match(/(?:Microsoft|WSL)/i)

		when 'i386-mingw32'
			#logger.info('get_os - Windows OS detected.')
			os = 'Windows'

		else
			#logger.info('get_os - UNKNOWN OS!!!')
	end

	return os
end

# Initialize the Rails application.
Rails.application.initialize!

# Explicitly adding assorted libraries
#require 'RMagick'
require 'free-image'
