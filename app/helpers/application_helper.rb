module ApplicationHelper

	def selected_if(items)
		classname = ''	# set a default
		
		case items.class.name
			when 'String'
				(classname = 'selected') if items == params[:action]

			when 'Array'
				(classname = 'selected') if items.include?(params[:action])
				
		end

		return classname
	end
end
