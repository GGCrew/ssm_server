class ClientPhotoQueue < ActiveRecord::Base

	belongs_to	:client
	belongs_to	:photo

end
