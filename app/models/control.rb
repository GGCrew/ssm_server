class Control < ActiveRecord::Base


	def self.default_attributes
		control = Control.last
		attributes = {
			hold_duration: control.hold_duration,
			transition_duration: control.transition_duration,
			transition_type: control.transition_type
		}
		
		return attributes
	end


end
