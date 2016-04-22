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
		@favorite_button_css = ''
		@deny_button_css = ''
		@reject_button_css = ''
		@scan_button_css = 'none'
		@preview_img_css = ''
		@preview_caption_css = ''
		@preview_controls_css = 'none'

		case params[:action]
			when 'pending', 'scan'
				@scan_button_css = ''

			when 'approved'
				@approve_button_css = 'none'

			when 'denied'
				@deny_button_css = 'none'

			when 'controls', 'index'
				@approve_button_css = 'none'
				@favorite_button_css = 'none'
				@deny_button_css = 'none'
				@reject_button_css = 'none'
				@preview_img_css = 'none'
				@preview_caption_css = 'none'
				@preview_controls_css = ''

		end
	end


	def get_photo_counts
		@photo_counts = {}
		@photo_counts.merge!({
			pending: Photo.pending.count,
			approved: Photo.approved.count,
			denied: Photo.denied.count,
			recent: get_recent_photos_count
		})
	end


	# This is redundantly repeated in photos_controller.  Best way to DRY?
	# Thinking of crafting a nasty-looking scope to move this functionality to the Photo model
	def get_recent_photos_count
		client_count = Client.count
		photo_approved_count = Photo.approved.count

		return client_count * (photo_approved_count / 2.0).ceil
	end


end
