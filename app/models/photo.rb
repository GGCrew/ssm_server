class Photo < ActiveRecord::Base


	SOURCE_FOLDER = '/photos/eye-fi/'
	ROTATED_FOLDER = '/photos/rotated/'
	RESIZED_FOLDER = '/photos/1920x1080/'


	#..#


	has_many	:client_photos,	:dependent => :destroy
	has_many	:clients,	:through => :client_photos

	has_many	:client_photo_queues,	:dependent => :destroy
	has_many	:queued_clients,	:through => :client_photo_queues


	#..#


	scope	:pending,		-> { where(approval_state: 'pending').order(updated_at: :asc) }
	scope :approved,	-> { where(approval_state: 'approved').order(updated_at: :asc) }
	scope :denied,		-> { where(approval_state: 'denied').order(updated_at: :asc) }


	#..#


	after_create	:create_rotated_and_scaled_copy


	#..#


	def self.scan_for_new_photos
		path = 'public' + SOURCE_FOLDER
		files = Dir.glob(path + '**/*.{JPG,PNG}', File::FNM_CASEFOLD)
		files.each_with_index do |file, index|
			photo_hash = path_to_hash(file[path.size..-1])
			logger.debug("#{index}/#{files.count} - #{photo_hash.to_s}")
			Photo.create!(photo_hash) if Photo.where(photo_hash).blank?
		end
	end


	def self.path_to_hash(path)
		hash = {}
		path_components = path.split('/')

		if path_components.count == 3
			camera_id = path_components[0][-2..-1].to_i
			date = Date.strptime(path_components[1], '%m-%d-%Y')
			filename = path_components[2]

			hash.merge!(camera_id: camera_id)
			hash.merge!(date: date)
			hash.merge!(filename: filename)
		end

		return hash
	end


	#..#


	def approve!
		self.approval_state = 'approved'
		self.save!
	end


	def deny!
		self.approval_state = 'denied'
		self.save!
	end


	def rotate!(degrees)
		logger.info("rotate!(#{degrees})")

		source_folder = 'public' + SOURCE_FOLDER
		rotated_folder = 'public' + ROTATED_FOLDER
		resized_folder = 'public' + RESIZED_FOLDER

		save_flags =  FreeImage::AbstractSource::Encoder::JPEG_QUALITYSUPERB | FreeImage::AbstractSource::Encoder::JPEG_BASELINE

		logger.info("\tLoading #{source_folder + path}")
		FreeImage::Bitmap.new(
			FreeImage.FreeImage_Load(
				FreeImage::FreeImage_GetFIFFromFilename(source_folder + path),
				source_folder + path,
				FreeImage::AbstractSource::Decoder::JPEG_EXIFROTATE
			)
		) do |image|

			# Rotate
			logger.info("\tRotating")
			rotated_image = image.rotate(degrees.to_i)

			# Scale
			logger.info("\tScaling")
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

			# Save
			logger.info("\tSaving #{resized_folder + path}")
			begin
				scaled_image.save(resized_folder + path, :jpeg, save_flags)
			rescue
				Dir.mkdir(resized_folder) unless Dir.exists?(resized_folder)
				Dir.mkdir(resized_folder + camera_folder) unless Dir.exists?(resized_folder + camera_folder)
				Dir.mkdir(resized_folder + camera_folder + '/' + date_folder) unless Dir.exists?(resized_folder + camera_folder + '/' + date_folder)
				scaled_image.save(resized_folder + path, :jpeg, save_flags)
			end
		end
		self.update_attributes(rotation: degrees)
		logger.info("\tDone")
	end


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
	# Optimization test code (to be run in console)
	photo = {:camera_id => 1, :date => '9-4-2014', :filename => 'IMG_4690.JPG'}
	start_time = Time.now
	Photo.create!(:camera_id => photo[:camera_id], :date => Date.strptime(photo[:date], '%m-%d-%Y'), :filename => photo[:filename])
	end_time = Time.now
	run_time = end_time - start_time
=end

=begin
	# This block requires RMagick
	def create_rotated_and_scaled_copy
		source_folder = 'public' + SOURCE_FOLDER
		rotated_folder = 'public' + ROTATED_FOLDER
		resized_folder = 'public' + RESIZED_FOLDER

		# Load source
		image = Magick::Image.read(source_folder + path)[0]

		# Rotate
		image.auto_orient!

		# Save rotated copy
		begin
			image.write(rotated_folder + path)
		rescue
			Dir.mkdir(rotated_folder) unless Dir.exists?(rotated_folder)
			Dir.mkdir(rotated_folder + camera_folder) unless Dir.exists?(rotated_folder + camera_folder)
			Dir.mkdir(rotated_folder + camera_folder + '/' + date_folder) unless Dir.exists?(rotated_folder + camera_folder + '/' + date_folder)
			image.write(rotated_folder + path)			
		end

		# Scale
		image.resize_to_fit!(1920, 1080)

		# Save rotated & scaled copy
		begin
			image.write(resized_folder + path)
		rescue
			Dir.mkdir(resized_folder) unless Dir.exists?(resized_folder)
			Dir.mkdir(resized_folder + camera_folder) unless Dir.exists?(resized_folder + camera_folder)
			Dir.mkdir(resized_folder + camera_folder + '/' + date_folder) unless Dir.exists?(resized_folder + camera_folder + '/' + date_folder)
			image.write(resized_folder + path)			
		end
	end
=end


	# This block requires FreeImage
	def create_rotated_and_scaled_copy
		logger.info("create_rotated_and_scaled_copy")

		source_folder = 'public' + SOURCE_FOLDER
		rotated_folder = 'public' + ROTATED_FOLDER
		resized_folder = 'public' + RESIZED_FOLDER

		save_flags =  FreeImage::AbstractSource::Encoder::JPEG_QUALITYSUPERB | FreeImage::AbstractSource::Encoder::JPEG_BASELINE

		# Load source
		#FreeImage::Bitmap.open(source_folder + path, FreeImage::AbstractSource::Decoder::JPEG_EXIFROTATE) do |image|
		logger.info("\tLoading #{source_folder + path}")
		FreeImage::Bitmap.new(
			FreeImage.FreeImage_Load(
				FreeImage::FreeImage_GetFIFFromFilename(source_folder + path),
				source_folder + path,
				FreeImage::AbstractSource::Decoder::JPEG_EXIFROTATE
			)
		) do |rotated_image|

			# Scale
			logger.info("\tScaling")
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
			logger.info("\tSaving #{resized_folder + path}")
			begin
				scaled_image.save(resized_folder + path, :jpeg, save_flags)
			rescue
				Dir.mkdir(resized_folder) unless Dir.exists?(resized_folder)
				Dir.mkdir(resized_folder + camera_folder) unless Dir.exists?(resized_folder + camera_folder)
				Dir.mkdir(resized_folder + camera_folder + '/' + date_folder) unless Dir.exists?(resized_folder + camera_folder + '/' + date_folder)
				scaled_image.save(resized_folder + path, :jpeg, save_flags)
			end
		end
		logger.info("\tDone")
	end

end
