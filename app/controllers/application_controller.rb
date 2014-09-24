class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception


	def set_control
		Control.default_attributes if Control.count == 0
		@control = Control.last
	end

end
