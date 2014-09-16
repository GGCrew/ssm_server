module PhotosHelper
	def format_filename(photo)
		return [
			"<span class='client_id'>#{photo.respond_to?('client_id') ? photo.client_id : nil}</span>",
			"<span class='camera_id'>#{photo.camera_id}</span>",
			"<span class='filename'>#{h(photo.filename)}</span>"
		].join(' ')
	end
end
