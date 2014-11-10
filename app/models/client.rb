class Client < ActiveRecord::Base

	has_many	:client_photos,	:dependent => :destroy
	has_many	:photos,	:through => :client_photos
	
	has_many	:client_photo_queues,	:dependent => :destroy
	has_many	:queued_photos,	:through => :client_photo_queues

end
