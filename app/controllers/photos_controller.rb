class PhotosController < ApplicationController

  before_action :set_photo, only: [
		:show,
		:edit,
		:update,
		:destroy,
		:approve,
		:deny,
		:favorite,
		:reject,
		:rotate,
		:queue
	]

	before_action :set_control,	only: [
		:next,
		:index,
		:controls,
		:pending,
		:approved,
		:denied,
		:recent
	]


	after_action :do_copy_action, only: [
		:approve,
		:deny,
		:favorite
	], if: -> { (Control.last.copy_action != Control::COPY_ACTIONS[0]) && @photo.from_camera?}


	#..#


  # GET /photos
  # GET /photos.json
  def index
    #@photos = Photo.all
		#pending
		#redirect_to(controls_photos_path)
		controls
  end


  # GET /photos/1
  # GET /photos/1.json
  def show
  end


  # GET /photos/new
  def new
    @photo = Photo.new
  end

  # GET /photos/1/edit
  def edit
  end


  # POST /photos
  # POST /photos.json
  def create
    @photo = Photo.new(photo_params)

    respond_to do |format|
      if @photo.save
        format.html { redirect_to @photo, notice: 'Photo was successfully created.' }
        format.json { render :show, status: :created, location: @photo }
      else
        format.html { render :new }
        format.json { render json: @photo.errors, status: :unprocessable_entity }
      end
    end
  end


  # PATCH/PUT /photos/1
  # PATCH/PUT /photos/1.json
  def update
    respond_to do |format|
      if @photo.update(photo_params)
        format.html { redirect_to @photo, notice: 'Photo was successfully updated.' }
        format.json { render :show, status: :ok, location: @photo }
      else
        format.html { render :edit }
        format.json { render json: @photo.errors, status: :unprocessable_entity }
      end
    end
  end


  # DELETE /photos/1
  # DELETE /photos/1.json
  def destroy
    @photo.destroy
    respond_to do |format|
      format.html { redirect_to photos_url, notice: 'Photo was successfully destroyed.' }
      format.json { head :no_content }
    end
  end


	def approve
		@photo.approve!
    respond_to do |format|
			format.js { render('update_list') }
      #format.html { redirect_to(photos_path, notice: 'Photo was successfully approved.') }
      #format.json { head :no_content }
		end
	end


	def deny
		@photo.deny!
    respond_to do |format|
			format.js { render('update_list') }
      format.html { redirect_to(photos_path, notice: 'Photo was successfully denied.') }
      format.json { head :no_content }
		end
	end


	def favorite
		@photo.favorite!
		respond_to do |format|
			format.js { render('update_list') }
			format.html { redirect_to(photos_path, notice: 'Photo was successfully favorited') }
			format.json { head :no_content }
		end
	end


	def reject
		@photo.reject!
		respond_to do |format|
			format.js { render('update_list') }
			format.html { redirect_to(photos_path, notice: 'Photo was successfully rejected') }
			format.json { head :no_content }
		end
	end


	def rotate
		@photo.rotate!(params[:degrees])
    respond_to do |format|
			format.js { render('update_photo') }
      format.html { redirect_to(photos_path, notice: 'Photo was successfully rotated.') }
      format.json { head :no_content }
		end
	end


	def next
		# Identify clients by IP address
		client_ip = request.env['REMOTE_ADDR']
		client = Client.where({ip_address: client_ip}).first
		client = Client.create({ip_address: client_ip}) if client.nil?

		# Check for any photos in the queue (these are manually added, and intended to override the normal display order)
		queued_client_photo = ClientPhotoQueue.where(client_id: client.id).first
		if queued_client_photo.nil?
			@photo = nil
		else
			@photo = Photo.find(queued_client_photo.photo_id)
			queued_client_photo.destroy
		end

		if @photo.nil?
			# Check for new photos (compare list of displayed photos to list of all approved photos)
			client_photo_ids = ClientPhoto.select(:photo_id).where(client_id: client.id).group(:photo_id).map(&:photo_id)
			if client_photo_ids.empty?
				# No photo history for this client!
				conditions_new = []
			else
				# Get list of photo ID's that have already been displayed
				conditions_new = ["id NOT IN (:client_photo_ids)", {client_photo_ids: client_photo_ids}]
			end
			@photo = Photo.approved.where(conditions_new).order('created_at ASC').first
		end

		if @photo.nil?
			# Get random old photo, preferably one that hasn't been shown recently
			approved_photo_count = Photo.approved.count
			if approved_photo_count < 2
				recent_photo_count = 0
			else
				recent_photo_count = (approved_photo_count / 2.0).ceil
			end
			recent_client_photo_ids = (recent_photo_count == 0 ? [-1] : ClientPhoto.select(:photo_id).where(client_id: client.id).order(created_at: :desc).limit(recent_photo_count).map(&:photo_id))
			conditions_not_recent = ["id NOT IN (:recent_client_photo_ids)", {recent_client_photo_ids: recent_client_photo_ids}]
			old_photos = Photo.approved.where(conditions_not_recent)

			index = (rand * old_photos.count).floor
			@photo = old_photos[index]

			if @photo.nil?
				# Nothing
			else
				# Check if photo has been updated since last displayed by client
				photo_update_time = @photo.updated_at
				last_display_time = ClientPhoto.where(client_id: client.id, photo_id: @photo.id).order(:id).last.created_at
				@photo_updated = (photo_update_time > last_display_time)
			end
		end

		# Specify client-side color mode
		color_modes = []
		color_modes << Photo::COLOR_MODE_NORMAL			if @control.color_mode_normal
		color_modes << Photo::COLOR_MODE_GRAYSCALE	if @control.color_mode_grayscale
		color_modes << Photo::COLOR_MODE_SEPIA			if @control.color_mode_sepia
		color_modes << Photo::COLOR_MODE_NORMAL			if color_modes.empty?	# Always default to normal if nothing is specified
		@color_mode = color_modes[(rand() * color_modes.count).floor]

		# Apply client-side vignette effect
		@effect_vignette = !!@control.effect_vignette

		# Assume photo has not been updated (if value isn't already set to true)
		@photo_updated ||= false

		# Add the selected photo to the client_photos list (aka "client photo history")
		client.client_photos.create(
			{
				photo_id: @photo.id,
				hold_duration: @control.hold_duration,
				transition_type: @control.transition_type,
				transition_duration: @control.transition_duration,
				color_mode: @color_mode,
				effect_vignette: @effect_vignette
			}
		) if @photo

		respond_to do |format|
			format.html {}
			format.json {
				if @photo
					if @photo.special
						@photo_hash = {
							message_type: 'sequence',
							data: [
								{
									full_path: "#{Photo::RESIZED_FOLDER + @photo.path}",
									updated: @photo_updated,
									updated_time: @photo.updated_at.tv_sec,
									hold_duration: @control.hold_duration,
									transition_type: "#{@control.transition_type}",
									transition_duration: @control.transition_duration
								}
							]
						}
					else
						@photo_hash = {
							message_type: 'photo',
							id: (@photo.id),
							server_path: Photo::RESIZED_FOLDER,
							camera_folder: "#{@photo.camera_folder}",
							date_folder: "#{@photo.date_folder}",
							filename: "#{@photo.filename}",
							full_path: "#{Photo::RESIZED_FOLDER + @photo.path}",
							updated: @photo_updated,
							updated_time: (@photo.updated_at.tv_sec),
							hold_duration: @control.hold_duration,
							transition_type: "#{@control.transition_type}",
							transition_duration: @control.transition_duration,
							color_mode: @color_mode,
							effect_vignette: @effect_vignette
						}
					end
				else
					@photo_hash = {
						message_type: 'photo',
						server_path: Photo::RESIZED_FOLDER,
						hold_duration: @control.hold_duration,
						transition_type: "#{@control.transition_type}",
						transition_duration: @control.transition_duration,
						color_mode: @color_mode,
						effect_vignette: @effect_vignette
					}
				end
			}
		end
	end


	def controls
		@photos = []

		respond_to do |format|
			format.js { render('reload_list') }
			format.html {render('photos')}
			format.json {}
		end
	end


	def pending
		@photos = Photo.pending

		respond_to do |format|
			format.js { render('reload_list') }
			format.html {render('photos')}
			format.json {}
		end
	end


	def approved
		@photos = Photo.approved

		respond_to do |format|
			format.js { render('reload_list') }
			format.html {render('photos')}
			format.json {}
		end
	end


	def denied
		@photos = Photo.denied

		respond_to do |format|
			format.js { render('reload_list') }
			format.html {render('photos')}
			format.json {}
		end
	end


	def recent
		recent_photo_count = get_recent_photos_count
		@photos = Photo.select('photos.*, client_photos.client_id').joins(:client_photos).order('client_photos.created_at DESC').limit(recent_photo_count)
		respond_to do |format|
			format.js { render('reload_list') }
			format.html {render('photos')}
			format.json {}
		end
	end


	def scan
		Photo.scan_for_new_photos(Control.last.auto_approve)
		Photo.remove_duplicates

		@photos = Photo.pending
		respond_to do |format|
			format.js { render('reload_list') }
			format.html {redirect_to(controls_photos_path)}
			format.json {}
		end
	end


	def reset_and_rescan
		# Note: The "Rails Way" is to use Model.destroy_all,
		# but all the before_destroy and after_destroy callbacks were killing performance.
		# Especially when there are over 500 photos.
		# Using Model.delete_all is immeasurably faster.

		# Delete database records
		logger.info("\tDeleting ClientPhoto records (#{ClientPhoto.all.count})...")
		ClientPhoto.delete_all	# Killing these first to prevent associations from triggering (causing massive slowdown)
		logger.info("\tDeleting Photo records (#{Photo.all.count})...")
		Photo.delete_all
		logger.info("\tDeleting Client records (#{Client.all.count})...")
		Client.delete_all

		# TODO: Use Ruby methods or detect OS & make OS-appropriate system calls
		# Delete processed photo files
		logger.info("\tDeleting processed photo files...")
		`rm -Rf #{'public' + Photo::RESIZED_FOLDER}`
		`rm -Rf #{'public' + Photo::ROTATED_FOLDER}`
		#`rm -Rf #{'public' + Photo::REJECT_FOLDER}`
		#`rm -Rf #{'public' + Photo::FAVOTITE_FOLDER}`
		#`rm -Rf #{'public' + Photo::COLLECTION_FOLDER}`
		logger.info("\t\tDone!")

		logger.info("\tScanning for new photos...")
		Photo.scan_for_new_photos
		logger.info("\t\tDone!")

		@photos = Photo.pending
		respond_to do |format|
			format.js { render('reload_list') }
			format.html {redirect_to(controls_photos_path)}
			format.json {}
		end
	end


	def collect_all
		camera_photos = Photo.from_cameras.not_rejected
		camera_photos_count = camera_photos.count
		camera_photos.each_with_index do |photo, index|
			logger.info("#{index+1}/#{camera_photos_count} - Photos#collect_all - collect_for_copying")
			photo.collect_for_copying
		end
	end


	def collect_all_and_copy_all_to_usb
		collect_all

		source = Rails.root.join('public' + Photo::COLLECTION_FOLDER).to_path
		logger.debug(source)

		command_template = nil
		case get_os
			when 'Linux'
				command_template = "cp --recursive --update \"%{source}.\" \"%{destination}\""

			when 'Windows'
				command_template = "start \"Robocopy to %{destination}\" robocopy \"%{source}\" \"%{destination}\" /R:5 /W:15 /XA:SH /Z /NP"

			else
				logger.info("Photos#copy_collected_to_usb - Unexpected OS!")

		end

		if command_template
			destinations = get_ssm_volumes
			local_folder = get_local_folder
			(destinations << local_folder) if local_folder
			logger.info "destinations: #{destinations}"
			destinations_count = destinations.count
			destinations.each_with_index do |destination, destination_index|
				logger.info("#{destination_index + 1}/#{destinations_count} - Copying from #{source} to #{destination}")
				command = command_template % {source: source, destination: destination}
				logger.info(command)
				pid = Process.spawn(command)
				Process.detach(pid)
			end
		end

		respond_to do |format|
			format.js { render( json: nil, status: :ok ) }
			format.html {redirect_to(controls_photos_path)}
			format.json {}
		end
	end


	def rename_usb
		# TODO: prompt for prefix (eg Bride and Groom)
		prefix = 'Harris and Yuki'

		case get_os
			when 'Linux'
				script_header = '#!/bin/bash'
				script_filename_template = 'rename_%{index}.sh'
				script_command_template = '"%{script_filename}"'
				rename_command_template = 'mv --no-target-directory --update --verbose "%{filename}" "%{folder}/%{new_filename}"'

			when 'Windows'
				script_header = nil
				script_filename_template = 'rename_%{index}.bat'
				script_command_template = 'start "Renaming USB Files" "%{script_filename}"'
				rename_command_template = 'ren "%{filename}" "%{new_filename}"'

			else
				logger.info("Photos#rename_usb - Unexpected OS!")

		end

		folders = get_ssm_volumes
		local_folder = get_local_folder
		(folders << local_folder) if local_folder
		folders_count = folders.count
		folders.each_with_index do |folder, folder_index|
			filenames = Dir.glob(folder + '/*.{JPG,PNG}', File::FNM_CASEFOLD)
			filenames_count = filenames.count
			filenames.sort!

			script_filename = Rails.root.join('tmp', script_filename_template % {index: folder_index}).to_path
			File.open(script_filename, 'w', 0755) do |script_file|
				(script_file.puts script_header) if script_header
				filenames.each_with_index do |filename, filename_index|
					new_filename = "#{prefix} #{(filename_index + 1).to_s.rjust(4, '0')}#{File.extname(filename)}".gsub(/[^a-zA-Z0-9_\.\-]/, '_')

					script_file.puts rename_command_template % {folder: folder, filename: filename, new_filename: new_filename}
				end
			end
			pid = Process.spawn(script_command_template % {script_filename: script_filename})
			Process.detach(pid)
		end

		respond_to do |format|
			format.js { render( json: nil, status: :ok ) }
			format.html {redirect_to(controls_photos_path)}
			format.json {}
		end
	end


	def queue
		# Assuming queue for all clients because related client-specific stuffs not implemented yet
		for client_id in Client.select(:id).map(&:id)
			ClientPhotoQueue.create(client_id: client_id, photo_id: @photo.id)
		end

		respond_to do |format|
			format.js {}
			format.html {redirect_to(controls_photos_path)}
			format.json {}
		end
	end


	# This is redundantly repeated in photos_helper.  Best way to DRY?
	# Thinking of crafting a nasty-looking scope to move this functionality to the Photo model
	def get_recent_photos_count
		# TODO: Adjust counts downward when a client goes offline
		client_count = Client.count
		photo_approved_count = Photo.approved.count

		return client_count * (photo_approved_count / 2.0).ceil
	end


	def auto_approve
		control = Control.create!(Control.default_attributes.merge(auto_approve: (params[:auto_approve] == 'true')))

		respond_to do |format|
			format.js {render(partial: 'update_photo_options')}
			format.html {redirect_to(controls_photos_path)}
			format.json {}
		end
	end


	#..#


  private

    # Use callbacks to share common setup or constraints between actions.
    def set_photo
      @photo = Photo.find(params[:id])
    end


    # Never trust parameters from the scary internet, only allow the white list through.
    def photo_params
      params[:photo]
    end


		def do_copy_action
			case Control.last.copy_action
				when Control::COPY_ACTIONS[0]
					# Do nothing

				when Control::COPY_ACTIONS[1]
					@photo.collect_for_copying

				when Control::COPY_ACTIONS[2]
					@photo.collect_for_copying

					source = Rails.root.join('public' + Photo::COLLECTION_FOLDER, @photo.collection_path).to_path

					ssm_volumes = get_ssm_volumes
					ssm_volumes.each do |ssm_volume|
						destination = "#{ssm_volume}/"

						FileUtils.cp source, destination, verbose: true
						# TODO: replace FileUtils.cp with OS-specific calls for increased control over the copy process
					end
			end
		end

end
