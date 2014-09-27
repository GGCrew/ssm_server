module PhotosHelper


	def format_filename(photo)
		return [
			"<span class='client_id'>#{photo.respond_to?('client_id') ? photo.client_id : nil}</span>",
			"<span class='camera_id'>#{photo.camera_id}</span>",
			"<span class='filename'>#{h(photo.filename)}</span>"
		].join(' ')
	end


	def set_per_action_css
		# set defaults
		@approve_button_css = ''
		@deny_button_css = ''
		@scan_button_css = 'none'
		@preview_img_css = ''
		@preview_caption_css = ''
		@preview_controls_css = 'none'

		case params[:action]
			when 'pending'
				@scan_button_css = ''

			when 'approved'
				@approve_button_css = 'none'

			when 'denied'
				@deny_button_css = 'none'

			when 'controls', 'index'
				@approve_button_css = 'none'
				@deny_button_css = 'none'
				@preview_img_css = 'none'
				@preview_caption_css = 'none'
				@preview_controls_css = ''

		end
	end


end
