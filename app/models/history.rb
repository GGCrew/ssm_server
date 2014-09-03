class History < ActiveRecord::Base
  
	acts_as_list
	stampable
	
	#..#
	
	belongs_to	:photo
	belongs_to	:client
	belongs_to	:transition_type
	belongs_to	:view_type
	
	#..#
	
  # attr_accessible :title, :body
end
