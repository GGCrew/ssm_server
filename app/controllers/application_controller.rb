class ApplicationController < ActionController::Base

	include Userstamp
	
	#..#
	
  protect_from_forgery
	
end
