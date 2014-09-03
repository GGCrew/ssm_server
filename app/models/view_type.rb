class ViewType < ActiveRecord::Base
  
	acts_as_list
	stampable
	
	#..#
	
	has_many	:display_history,	:class_name => 'History', :foreign_key => 'view_type_id',	:dependent => :nullify
	
	#..#
	
  attr_accessible :name, :default_view_time

	end
