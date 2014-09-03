class PhotoStatus < ActiveRecord::Base
  
	acts_as_list
	stampable
	
	#..#
	
	# attr_accessible :title, :body
	
	PENDING		= self.find_or_create_by_name('pending')
	APPROVED	= self.find_or_create_by_name('approved')
	DENIED		= self.find_or_create_by_name('denied')
	
	#..#
	
	has_many	:photos,	:class_name => 'Photo',	:foreign_key => 'photo_status_id',	:dependent => :nullify	

end
