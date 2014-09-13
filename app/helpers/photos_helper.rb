module PhotosHelper
	def format_filename(photo)
		return "<span class='camera_id'>#{photo.camera_id}</span> <span class='filename'>#{h(photo.filename)}</span>"
	end
end
