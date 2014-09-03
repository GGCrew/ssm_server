class TransitionType < ActiveRecord::Base
  
	acts_as_list
	stampable
	
	#..#
	
	has_many	:display_history,	:class_name => 'History', :foreign_key => 'transition_type_id',	:dependent => :nullify
	
	#..#
	
  attr_accessible :name, :default_transition_time
	
end
