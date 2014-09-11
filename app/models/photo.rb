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


=begin
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
=end


	def create_rotated_and_scaled_copy
		source_folder = 'public' + SOURCE_FOLDER
		rotated_folder = 'public' + ROTATED_FOLDER
		resized_folder = 'public' + RESIZED_FOLDER

		# Load source
		FreeImage::Bitmap.open(source_folder + path) do |img|

			# Rotate
			# To-do: use EXIF to determine orientation
			rotated_image = image.rotate(90, nil)

			# Save rotated copy
			begin
				rotated_image.save(rotated_folder + path, :jpeg, FreeImage::AbstractSource::Encoder::JPEG_QUALITYSUPERB)
			rescue
				Dir.mkdir(rotated_folder) unless Dir.exists?(rotated_folder)
				Dir.mkdir(rotated_folder + camera_folder) unless Dir.exists?(rotated_folder + camera_folder)
				Dir.mkdir(rotated_folder + camera_folder + '/' + date_folder) unless Dir.exists?(rotated_folder + camera_folder + '/' + date_folder)
				rotated_image.save(rotated_folder + path, :jpeg, FreeImage::AbstractSource::Encoder::JPEG_QUALITYSUPERB)			
			end

			# Scale
			width_scale = rotated_image.width / 1920.0
			height_scale = rotated_image.height / 1080.0
			if(width_scale > height_scale)
				new_width = (rotated_image.width / width_scale).to_i
				new_height = (rotated_image.height / width_scale).to_i
			else
				new_width = (rotated_image.width / height_scale).to_i
				new_height = (rotated_image.height / height_scale).to_i
			end
			scaled_image = rotated_image.rescale(new_width, new_height, :bilinear)

			# Save rotated & scaled copy
			begin
				scaled_image.save(resized_folder + path, :jpeg, FreeImage::AbstractSource::Encoder::JPEG_QUALITYSUPERB)
			rescue
				Dir.mkdir(resized_folder) unless Dir.exists?(resized_folder)
				Dir.mkdir(resized_folder + camera_folder) unless Dir.exists?(resized_folder + camera_folder)
				Dir.mkdir(resized_folder + camera_folder + '/' + date_folder) unless Dir.exists?(resized_folder + camera_folder + '/' + date_folder)
				scaled_image.save(resized_folder + path, :jpeg, FreeImage::AbstractSource::Encoder::JPEG_QUALITYSUPERB)			
			end
		end
	end

end
