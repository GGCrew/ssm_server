class Client < ActiveRecord::Base

	has_many	:client_photos
	has_many	:photos,	:through => :client_photos

end
