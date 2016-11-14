require 'rails/commands/server'

class Rails::Server
	# copied (and modified from) gems/railties-4.1.5/lib/rails/commands/server.rb
	if Rails.version == '4.1.5'
		def middleware
		  middlewares = []
		  middlewares << [Rails::Rack::Debugger] if options[:debugger]
		  middlewares << [::Rack::ContentLength]

		  # FIXME: add Rack::Lock in the case people are using webrick.
		  # This is to remain backwards compatible for those who are
		  # running webrick in production. We should consider removing this
		  # in development.
		  if server.name == 'Rack::Handler::WEBrick'
	#        middlewares << [::Rack::Lock]
		  end

		  Hash.new(middlewares)
		end
	end
end