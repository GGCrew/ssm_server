class Client < ActiveRecord::Base

	stampable

	#..#
	
	has_many	:display_history,	:class_name => 'History', :foreign_key => 'client_id',	:dependent => :nullify
	
	#..#
	
  # attr_accessible :title, :body
end
