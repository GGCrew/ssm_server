class Photo < ActiveRecord::Base


	SOURCE_FOLDER = '/photos/eye-fi/'
	ROTATED_FOLDER = '/photos/rotated/'
	RESIZED_FOLDER = '/photos/1920x1080/'

	COLOR_MODE_NORMAL = 0
	COLOR_MODE_GRAYSCALE = 1
	COLOR_MODE_SEPIA = 2

	DEFAULT_DATE = DateTime.parse('1970-01-01 00:00:00')


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


	def self.scan_for_new_photos(auto_approve = false)
		path = 'public' + SOURCE_FOLDER
		processed_files = self.all.map{|photo| path + photo.path}
		all_files = Dir.glob(path + '**/*.{JPG,PNG}', File::FNM_CASEFOLD)
		files = all_files - processed_files
		files.sort!
		files.each_with_index do |file, index|
			#logger.debug("#{index + 1}/#{files.count} - #{file}")
			#photo_hash = path_to_hash(file[path.size..-1])
			photo_hash = path_to_hash(file)
			logger.info("#{index + 1}/#{files.count} - #{photo_hash.to_s}")
			if Photo.where(photo_hash).blank?
				photo_hash.merge!(approval_state: 'approved') if auto_approve
				photo_hash.merge!(Photo.exif_data_hash(file))
				Photo.create!(photo_hash)
			end
		end
	end


	def self.path_to_hash(source_path, generate_md5 = true)
		hash = {
			special: false
		}

		path = source_path.dup

		# Strip superfluous folders from path
		path.gsub!('public' + SOURCE_FOLDER, '')

		path_components = path.split('/')

		case path_components.count
			when 3
				filename = path_components[2]
				hash.merge!(filename: filename)
				case path_components[0]
					when 'special'
						#logger.debug "\t\tSPECIAL"
						special_folder = path_components[1]

						hash.merge!(special: true)
						hash.merge!(special_folder: special_folder)

					when /SSM-\d\d/
						#logger.debug "\t\tSSM-\\d\\d"
						camera_id = path_components[0][-2..-1].to_i
						date = Date.strptime(path_components[1], '%m-%d-%Y')

						hash.merge!(camera_id: camera_id)
						hash.merge!(date: date)
				end

			else
				# Yikes!  Unexpected number of path components!
				logger.info "!!!!! Photo.path_to_hash -- Unexpected number of path components: #{path_components.count} (#{path})"
		end

		hash.merge!(md5: Digest::MD5.file('public' + Photo::SOURCE_FOLDER + '/' + path).hexdigest) if generate_md5

		return hash
	end


	def self.remove_duplicates
		sql = '
			SELECT photos.id, photos_1.id AS duplicate_id
			FROM photos
			INNER JOIN photos AS photos_1
			ON photos.md5 = photos_1.md5
			WHERE photos.id != photos_1.id
			 AND photos.id < photos_1.id
			 AND ((photos.camera_id = photos_1.camera_id) OR (ISNULL(photos.camera_id) AND ISNULL(photos_1.camera_id)))
			 AND ((photos.date = photos_1.date) OR (ISNULL(photos.date) AND ISNULL(photos_1.date)))
			 AND photos.filename = photos_1.filename
			ORDER BY photos.id, photos_1.id
			;
		'

		duplicates = ActiveRecord::Base.connection.execute(sql)
		for duplicate in duplicates
			if self.exists?(duplicate[0])
				keeper = self.find(duplicate[0])
				if self.exists?(duplicate[1])
					extra = self.find(duplicate[1])
					if extra.approval_state == 'approved' && keeper.approval_state != 'approved'
						keeper.approve!
					end
					extra.destroy
				end
			end
		end

		ids = duplicates.map{|i| [i[0], i[1]]}.flatten.uniq.sort
		self.where(['id IN (:ids)', {ids: ids}]).order(:id)
	end


	def self.card_counts
		database_counts = self.group(:camera_id).count.sort_by{|i| i[0].nil? ? -1 : i[0]}

		path = 'public' + SOURCE_FOLDER
		all_files = Dir.glob(path + '**/*.{JPG,PNG}', File::FNM_CASEFOLD)
		#all_files.each{|i| i.sub!(path, '')}
		hashed_files = all_files.map{|i| Photo.path_to_hash(i, false)}
		camera_ids = hashed_files.map{|i| i[:camera_id].nil? ? nil : i[:camera_id]}
		source_counts = camera_ids.uniq.map{|i| [i, camera_ids.count(i)]}.sort_by{|i| i[0].nil? ? -1 : i[0]}

		return {database_counts: database_counts, source_counts: source_counts}
	end


	def self.import_exif_dates
		path = 'public' + SOURCE_FOLDER
		photos = Photo.where(exif_date: nil)
		photo_count = photos.count
		photos.each_with_index do |photo, index|
			logger.info "#{index + 1}/#{photo_count}"
			photo.exif_date = photo.get_exif_date
			photo.save
		end
	end


	def self.get_exif_date(filename)
		exif_date_text = Photo.get_exif_data(filename, :fimd_exif_exif, 'DateTimeOriginal')
		if exif_date_text
			return DateTime.strptime(exif_date_text, '%Y:%m:%d %H:%M:%S')
		else
			return DEFAULT_DATE
		end
	end


	# This block requires FreeImage
	def self.get_exif_data(filename, metadata_model, key_name)
		return_value = nil # Assume failure

		# Load source
		#FreeImage::Bitmap.open(source_folder + path, FreeImage::AbstractSource::Decoder::JPEG_EXIFROTATE) do |image|
		FreeImage::Bitmap.new(
			FreeImage.FreeImage_Load(
				FreeImage::FreeImage_GetFIFFromFilename(filename),
				filename,
				FreeImage::AbstractSource::Decoder::FIF_LOADNOPIXELS
			)
		) do |image_header|

#			begin
				# Check if there were any errors when loading the image.  Most commonly triggered by invalid/incomplete image files.
				# If this fails, Ruby throws an error and we skip to the "rescue" block
				FreeImage.check_last_error

				fitag_pointer = FFI::MemoryPointer.new :pointer

				if FreeImage.FreeImage_GetMetadata(metadata_model, image_header, key_name, fitag_pointer)
					fitag = FreeImage::FITAG.new(fitag_pointer.read_pointer())
					return_value = FreeImage.get_fitag_value(fitag)
				end

#			rescue
#				logger.debug "INSERT COMMENT HERE"
#
#			end
		
		end
		return return_value
	end


	def self.exif_data_hash(filename)
		metadata = [
			{metadata_model: :fimd_exif_exif, key_name: 'DateTimeOriginal',	value: nil, model_attribute: 'exif_date'},
			{metadata_model: :fimd_exif_exif, key_name: 'PixelXDimension',	value: nil, model_attribute: 'exif_width'},
			{metadata_model: :fimd_exif_exif, key_name: 'PixelYDimension',	value: nil, model_attribute: 'exif_height'},
			{metadata_model: :fimd_exif_main, key_name: 'Make',							value: nil, model_attribute: 'exif_make'},
			{metadata_model: :fimd_exif_main, key_name: 'Model',						value: nil, model_attribute: 'exif_model'}
		]

		attribute_hash = {}

		# Load source
		FreeImage::Bitmap.new(
			FreeImage.FreeImage_Load(
				FreeImage::FreeImage_GetFIFFromFilename(filename),
				filename,
				FreeImage::AbstractSource::Decoder::FIF_LOADNOPIXELS
			)
		) do |image_header|

			begin
				# Check if there were any errors when loading the image.  Most commonly triggered by invalid/incomplete image files.
				# If this fails, Ruby throws an error and we skip to the "rescue" block
				FreeImage.check_last_error

				fitag_pointer = FFI::MemoryPointer.new :pointer

				for metadatum in metadata
					if FreeImage.FreeImage_GetMetadata(metadatum[:metadata_model], image_header, metadatum[:key_name], fitag_pointer)
						fitag = FreeImage::FITAG.new(fitag_pointer.read_pointer())
						metadatum[:value] = FreeImage.get_fitag_value(fitag)
						attribute_hash.merge!(metadatum[:model_attribute].to_sym => metadatum[:value])
					end
				end

			rescue
				logger.debug "INSERT ERROR CODE HERE"

			end
		
		end

		(attribute_hash[:exif_date] = DateTime.strptime(attribute_hash[:exif_date], '%Y:%m:%d %H:%M:%S')) if attribute_hash[:exif_date]

		return attribute_hash
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

		logger.debug("\tLoading #{source_folder + path}")
		FreeImage::Bitmap.new(
			FreeImage.FreeImage_Load(
				FreeImage::FreeImage_GetFIFFromFilename(source_folder + path),
				source_folder + path,
				FreeImage::AbstractSource::Decoder::JPEG_EXIFROTATE
			)
		) do |image|

			# Rotate
			logger.debug("\tRotating")
			rotated_image = image.rotate(degrees.to_i)

			# Scale
			logger.debug("\tScaling")
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
			logger.debug("\tSaving #{resized_folder + path}")
			begin
				scaled_image.save(resized_folder + path, :jpeg, save_flags)
			rescue
				Dir.mkdir(resized_folder) unless Dir.exists?(resized_folder)
				#Dir.mkdir(resized_folder + camera_folder) unless Dir.exists?(resized_folder + camera_folder)
				#Dir.mkdir(resized_folder + camera_folder + '/' + date_folder) unless Dir.exists?(resized_folder + camera_folder + '/' + date_folder)
				save_folder = resized_folder[0..-2]
				path_components = path.split('/')[0..-2]
				path_components.each_with_index do |path_component, index|
					save_folder << "/#{path_component}"
					Dir.mkdir(save_folder) unless Dir.exists?(save_folder)
				end
				scaled_image.save(resized_folder + path, :jpeg, save_flags)
			end
		end
		self.update_attributes(rotation: degrees)
		logger.info("\tDone")
	end


	def path
		if self.special
			return "special/#{self.special_folder}/#{self.filename}"
		else
			return "#{camera_folder}/#{date_folder}/#{self.filename}"
		end
	end


	def camera_folder
		#if self.special
		#	return 'special'
		#else
			return "SSM-#{self.camera_id.to_s.rjust(2, '0')}"
		#end
	end


	def date_folder
		#if self.special
		#	return special_folder
		#else
			return self.date.strftime("%-m-%-d-%Y")
		#end
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
		logger.debug("\tLoading #{source_folder + path}")
		FreeImage::Bitmap.new(
			FreeImage.FreeImage_Load(
				FreeImage::FreeImage_GetFIFFromFilename(source_folder + path),
				source_folder + path,
				FreeImage::AbstractSource::Decoder::JPEG_EXIFROTATE
			)
		) do |rotated_image|

			begin
				# Check if there were any errors when loading the image.  Most commonly triggered by invalid/incomplete image files.
				# If this fails, Ruby throws an error and we skip to the "rescue" block
				FreeImage.check_last_error

				# Scale
				logger.debug("\tScaling")
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
				logger.debug("\tSaving #{resized_folder + path}")
				begin
					scaled_image.save(resized_folder + path, :jpeg, save_flags)
				rescue
					Dir.mkdir(resized_folder) unless Dir.exists?(resized_folder)
					#Dir.mkdir(resized_folder + camera_folder) unless Dir.exists?(resized_folder + camera_folder)
					#Dir.mkdir(resized_folder + camera_folder + '/' + date_folder) unless Dir.exists?(resized_folder + camera_folder + '/' + date_folder)
					save_folder = resized_folder[0..-2]
					path_components = path.split('/')[0..-2]
					path_components.each_with_index do |path_component, index|
						save_folder << "/#{path_component}"
						Dir.mkdir(save_folder) unless Dir.exists?(save_folder)
					end
					scaled_image.save(resized_folder + path, :jpeg, save_flags)
				end

			rescue
				# Need to destroy the current record
				logger.debug("\tFreeImage error!")
				logger.debug("\tDestroying newly-created record: #{self.id}")
				self.destroy!
			end
		end
		logger.info("\tDone")
	end


	def exif_data_hash
		source_folder = 'public' + SOURCE_FOLDER

		Photo.exif_data_hash(source_folder + path)
	end


	def get_exif_date
		source_folder = 'public' + SOURCE_FOLDER

		Photo.get_exif_date(source_folder + path)

=begin
		exif_date_text = get_exif_data :fimd_exif_exif, 'DateTimeOriginal'
		if exif_date_text
			return DateTime.strptime(exif_date_text, '%Y:%m:%d %H:%M:%S')
		else
			return DEFAULT_DATE
		end
=end
	end


	# This block requires FreeImage
	def get_exif_data(metadata_model, key_name)
		source_folder = 'public' + SOURCE_FOLDER

		Photo.get_exif_data(source_folder + path, metadata_model, key_name)

=begin
		return_value = nil # Assume failure

		# Load source
		#FreeImage::Bitmap.open(source_folder + path, FreeImage::AbstractSource::Decoder::JPEG_EXIFROTATE) do |image|
		FreeImage::Bitmap.new(
			FreeImage.FreeImage_Load(
				FreeImage::FreeImage_GetFIFFromFilename(source_folder + path),
				source_folder + path,
				FreeImage::AbstractSource::Decoder::FIF_LOADNOPIXELS
			)
		) do |image_header|

			begin
				# Check if there were any errors when loading the image.  Most commonly triggered by invalid/incomplete image files.
				# If this fails, Ruby throws an error and we skip to the "rescue" block
				FreeImage.check_last_error

				fitag_pointer = FFI::MemoryPointer.new :pointer

				if FreeImage.FreeImage_GetMetadata(metadata_model, image_header, key_name, fitag_pointer)
					fitag = FreeImage::FITAG.new(fitag_pointer.read_pointer())
					return_value = FreeImage.get_fitag_value(fitag)
				end

			rescue
				logger.debug "INSERT COMMENT HERE"

			end
		
		end
		return return_value
=end
	end
end
