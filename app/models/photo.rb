class Photo < ActiveRecord::Base


	SOURCE_FOLDER = '/photos/eye-fi/'
	ROTATED_FOLDER = '/photos/rotated/'
	RESIZED_FOLDER = '/photos/1920x1080/'


	#..#


	has_many	:client_photos
	has_many	:clients,	:through => :client_photos


	#..#


	after_create	:create_rotated_and_scaled_copy


	#..#


	def path
		return "#{camera_folder}/#{date_folder}/#{self.filename}"
	end


	def camera_folder
		return "SSM-#{self.camera_id.to_s.rjust(2, '0')}"
	end


	def date_folder
		return self.date.strftime("%-m-%-d-%Y")
	end


	def create_rotated_and_scaled_copy
		source_folder = 'public' + SOURCE_FOLDER
		rotated_folder = 'public' + ROTATED_FOLDER
		resized_folder = 'public' + RESIZED_FOLDER

		# Load source
		img = Magick::Image.read(source_folder + path)[0]

		# Rotate
		img.auto_orient!

		# Save rotated copy
		begin
			img.write(rotated_folder + path)
		rescue
			Dir.mkdir(rotated_folder) unless Dir.exists?(rotated_folder)
			Dir.mkdir(rotated_folder + camera_folder) unless Dir.exists?(rotated_folder + camera_folder)
			Dir.mkdir(rotated_folder + camera_folder + '/' + date_folder) unless Dir.exists?(rotated_folder + camera_folder + '/' + date_folder)
			img.write(rotated_folder + path)			
		end

		# Scale
		img.resize_to_fit!(1920, 1080)

		# Save rotated & scaled copy
		begin
			img.write(resized_folder + path)
		rescue
			Dir.mkdir(resized_folder) unless Dir.exists?(resized_folder)
			Dir.mkdir(resized_folder + camera_folder) unless Dir.exists?(resized_folder + camera_folder)
			Dir.mkdir(resized_folder + camera_folder + '/' + date_folder) unless Dir.exists?(resized_folder + camera_folder + '/' + date_folder)
			img.write(resized_folder + path)			
		end
	end

end
