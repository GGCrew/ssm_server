class Photo < ActiveRecord::Base


	SOURCE_FOLDER = '/photos/eye-fi/'
	REJECT_FOLDER = SOURCE_FOLDER + 'rejects/'
	FAVORITE_FOLDER = SOURCE_FOLDER + 'favorites/'
	COLLECTION_FOLDER = SOURCE_FOLDER + 'collection/'
	ROTATED_FOLDER = '/photos/rotated/'
	RESIZED_FOLDER = '/photos/1920x1080/'

	COLOR_MODE_NORMAL = 0
	COLOR_MODE_GRAYSCALE = 1
	COLOR_MODE_SEPIA = 2

	DEFAULT_DATE = DateTime.parse('1970-01-01 00:00:00')

	CAMERA_ID_RANGE = 1..98


	#..#


	has_many	:client_photos,	:dependent => :destroy
	has_many	:clients,	:through => :client_photos

	has_many	:client_photo_queues,	:dependent => :destroy
	has_many	:queued_clients,	:through => :client_photo_queues


	#..#


	scope	:pending,				-> { where(approval_state: 'pending').order(exif_date: :asc).order(updated_at: :asc) }
	scope :approved,			-> { where(approval_state: 'approved').order(exif_date: :asc).order(updated_at: :asc) }
	scope :denied,				-> { where(approval_state: 'denied').order(exif_date: :asc).order(updated_at: :asc) }
	scope :favorited,			-> { where(favorite: true).order(exif_date: :asc).order(updated_at: :asc) }
	scope :rejected,			-> { where(reject: true).order(exif_date: :asc).order(updated_at: :asc) }
	scope :not_rejected,	-> { where(reject: false).order(exif_date: :asc).order(updated_at: :asc) }
	scope	:from_cameras,	-> { where.not(camera_id: [0, 99]).order(exif_date: :asc).order(updated_at: :asc) }
	scope	:from_stock,		-> { where(camera_id: 0).order(exif_date: :asc).order(updated_at: :asc) }
	scope	:from_custom,		-> { where(camera_id: 99).order(exif_date: :asc).order(updated_at: :asc) }


	#..#


	after_create	:create_rotated_and_scaled_copy
	#after_create	:collect_for_copying

	before_destroy	:delete_copies


	#..#


	def self.scan_for_new_photos(auto_approve = false)
		path = 'public' + SOURCE_FOLDER
		processed_files = self.all.map{|photo| path + photo.path}
		rejected_files = Dir.glob('public' + REJECT_FOLDER + '**/*.{JPG,PNG}', File::FNM_CASEFOLD)
		favorited_files = Dir.glob('public' + FAVORITE_FOLDER + '**/*.{JPG,PNG}', File::FNM_CASEFOLD)
		collected_files = Dir.glob('public' + COLLECTION_FOLDER + '**/*.{JPG,PNG}', File::FNM_CASEFOLD)
		all_files = Dir.glob(path + '**/*.{JPG,PNG}', File::FNM_CASEFOLD)
		files = all_files - processed_files - rejected_files - favorited_files - collected_files
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
		path.gsub!(/public#{SOURCE_FOLDER}/i, '')

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

		# ISNULL() is a MySQL function and does not exist in SQLite -- use IFNULL(<<field>>, NULL) instead
		# Good examples here: http://www.techonthenet.com/sqlite/functions/ifnull.php
		sql.gsub!(/ISNULL\((\w*\.\w*)\)/, 'IFNULL(\1, NULL)') if ActiveRecord::Base.configurations[Rails.env]['adapter'] == 'sqlite3'

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
		Photo.exif_data_hash(filename)[:exif_date]
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

		attribute_hash[:exif_date] = (attribute_hash[:exif_date] ? DateTime.strptime(attribute_hash[:exif_date], '%Y:%m:%d %H:%M:%S') : DEFAULT_DATE)

		# Fix for "Binary data inserted for `string` type on column `exif_make/exif_model`" error messages with SQLite
		if ActiveRecord::Base.configurations[Rails.env]['adapter'] == 'sqlite3'
			(attribute_hash[:exif_make] = attribute_hash[:exif_make].encode) if attribute_hash[:exif_make]
			(attribute_hash[:exif_model] = attribute_hash[:exif_model].encode) if attribute_hash[:exif_model]
		end

		return attribute_hash
	end


=begin
	def self.collect_for_copying
		photos = Photo.not_rejected
		photos_count = photos.count

		photos.each_with_index do |photo, index|
			logger.info "Collecting #{index + 1} / #{photos_count}"
			photo.collect_for_copying
		end

		return photos_count
	end
=end


	#..#


	def approve!
		self.update!(approval_state: 'approved')
	end


	def deny!
		self.update!(approval_state: 'denied')
	end


	def favorite!
		self.update!(
			favorite: true,
			reject: false
		)
		self.approve!

		# Copy to Favorite folder
		favorite_folder = "public#{Photo::FAVORITE_FOLDER}"
		source = "public#{Photo::SOURCE_FOLDER}#{path}"
		destination = "#{favorite_folder}#{favorite_path}"

		#TODO: Make a chkdir/mkdir method
		Dir.mkdir(favorite_folder) unless Dir.exists?(favorite_folder)
		save_folder = favorite_folder[0..-2]
		path_components = favorite_path.split('/')[0..-2]
		path_components.each_with_index do |path_component, index|
			save_folder << "/#{path_component}"
			Dir.mkdir(save_folder) unless Dir.exists?(save_folder)
		end

		FileUtils.cp source, destination
	end


	def reject!
		self.update!(
			favorite: false,
			reject: true
		)
		self.deny!

		# Move to Reject folder
		reject_folder = "public#{Photo::REJECT_FOLDER}"
		source = "public#{Photo::SOURCE_FOLDER}#{path}"
		destination = "#{reject_folder}#{reject_path}"

		#TODO: Make a chkdir/mkdir method
		Dir.mkdir(reject_folder) unless Dir.exists?(reject_folder)
		save_folder = reject_folder[0..-2]
		path_components = reject_path.split('/')[0..-2]
		path_components.each_with_index do |path_component, index|
			save_folder << "/#{path_component}"
			Dir.mkdir(save_folder) unless Dir.exists?(save_folder)
		end

		FileUtils.mv source, destination
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


	def reject_path
		#TODO: Why is this commented out?
		#return "#{REJECT_FOLDER}#{date_folder}/#{camera_folder}/#{self.filename}"
		return "#{date_folder}/#{camera_folder}/#{self.filename}"
	end


	def favorite_path
		#TODO: Why is this commented out?
		#return "#{FAVORITE_FOLDER}#{date_folder}/#{camera_folder}/#{self.filename}"
		return "#{date_folder}/#{camera_folder}/#{self.filename}"
	end


	def collection_path
		return "#{self.exif_date.to_formatted_s(:number)}_#{self.camera_id.to_s.rjust(2, '0')}_#{self.basename}_#{self.md5}#{self.extension}".gsub(/[^a-zA-Z0-9_\.\-]/, '_')
	end


	def basename
		return self.filename.chomp("#{self.extension}")
	end


	def extension
		return File.extname(self.filename)
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


	def from_camera?
		return self.camera_id.in?(CAMERA_ID_RANGE)
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


	def collect_for_copying(detach_process = true)
		source_folder = 'public' + SOURCE_FOLDER
		collection_folder = 'public' + COLLECTION_FOLDER
		source = source_folder + self.path
		destination = collection_folder + self.collection_path

		Dir.mkdir(collection_folder) unless Dir.exists?(collection_folder)

		#logger.info("\"#{ENV['ProgramW6432']}\\TeraCopy\\TeraCopy.exe\" \"#{source}\" \"#{destination}\" /OverwriteOlder")

		# TODO: Make get_os a global method
		# possible solution: http://stackoverflow.com/questions/15289065/rails-universal-global-function
		case get_os
			when 'Linux'
				`cp --update "#{source}" "#{destination}"`
				pid = nil

			when 'Windows'
				# Specify full paths
				source = Rails.root.join(source).to_s
				destination = Rails.root.join(destination).to_s

				# Use correct slashes
				source.gsub!('/', '\\')
				destination.gsub!('/', '\\')

				unless File.exists(destination)
					#command = "\"#{ENV['ProgramW6432']}\\TeraCopy\\TeraCopy.exe\" Copy \"#{source}\" \"#{destination}\" /OverwriteOlder"
					#command = "echo f | xcopy \"#{source}\" \"#{destination}\" /Y"
					command = "copy /y /z \"#{source}\" \"#{destination}\""
					#logger.info(command)
					#`#{command}`

					# Using "spawn" to continue execution instead of waiting for copy process to complete
					pid = spawn(command)
				else
					pid = nil
				end
			
			else
				# Unknown OS
				pid = nil
		end

		if pid && detach_process
			logger.info("Detaching process #{pid}")
			Process.detach(pid)
			pid = nil
		end

		return pid
	end


	def delete_copies
		collection_folder = 'public' + COLLECTION_FOLDER
		collection_copy = collection_folder + self.collection_path
		FileUtils.rm collection_copy if File.exists?(collection_copy)

		# TODO: Delete favorite copy
	end


	def exif_data_hash
		source_folder = 'public' + SOURCE_FOLDER

		Photo.exif_data_hash(source_folder + path)
	end


	def get_exif_date
		source_folder = 'public' + SOURCE_FOLDER

		Photo.get_exif_date(source_folder + path)
	end


	# This block requires FreeImage
	def get_exif_data(metadata_model, key_name)
		source_folder = 'public' + SOURCE_FOLDER

		Photo.get_exif_data(source_folder + path, metadata_model, key_name)
	end


	def exif_caption
		#[exif_make, exif_model, exif_date, "#{exif_width}x#{exif_height}"].join(' ')
		captions = []
		if exif_make
			if exif_model
				captions << exif_make unless exif_model.match(exif_make)
			else
				captions << exif_make
			end
		end
		captions << exif_model
		captions << exif_date.strftime('%Y-%m-%d %H:%M:%S')
		captions << "#{exif_width}x#{exif_height}" if (exif_width and exif_height)
		captions.compact.join(' ')
	end
end
