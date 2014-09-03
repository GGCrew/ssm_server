class Photo < ActiveRecord::Base
  
	acts_as_list
	stampable
	
	#..#
	
	has_many	:display_history,	:class_name => 'History', :foreign_key => 'photo_id',	:dependent => :nullify
	
	#..#
	
  # attr_accessible :title, :body
end
