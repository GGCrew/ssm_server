class PhotosController < ApplicationController

  before_action :set_photo, only: [:show, :edit, :update, :destroy, :approve, :deny, :rotate]
	before_action :set_control,	only: [:next, :index, :controls, :pending, :approved, :denied, :recent]


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
		logger.debug('PhotosController.approve')
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

		# Get history of client photos to identify any new photos
		#client_photo_ids = client.photos(true).map(&:id)
		#client_photo_ids = ClientPhoto.select(:photo_id).where(client_id: client.id).map(&:photo_id)
		client_photo_ids = ClientPhoto.select(:photo_id).where(client_id: client.id).group(:photo_id).map(&:photo_id)
		if client_photo_ids.empty?
			conditions_new = []
		else
			conditions_new = ["id NOT IN (:client_photo_ids)", {client_photo_ids: client_photo_ids}]
		end
		@photo = Photo.approved.where(conditions_new).order('created_at ASC').first

		if @photo.nil?
			# Get random old photo, preferably one that hasn't been shown recently
			approved_photo_count = Photo.approved.count
			if approved_photo_count < 2
				recent_photo_count = 0
			else
				recent_photo_count = (approved_photo_count / 2.0).ceil
			end
			#recent_client_photo_ids = (recent_photo_count == 0 ? [-1] : client_photo_ids[-recent_photo_count..-1])
			recent_client_photo_ids = (recent_photo_count == 0 ? [-1] : ClientPhoto.select(:photo_id).where(client_id: client.id).order(created_at: :desc).limit(recent_photo_count).map(&:photo_id))
			conditions_not_recent = ["id NOT IN (:recent_client_photo_ids)", {recent_client_photo_ids: recent_client_photo_ids}]
			old_photos = Photo.approved.where(conditions_not_recent)

			index = (rand * old_photos.count).floor
			@photo = old_photos[index]

			# Check if photo has been updated since last displayed by client
			photo_update_time = @photo.updated_at
			last_display_time = ClientPhoto.where(client_id: client.id, photo_id: @photo.id).order(:id).last.created_at
			@photo_updated = (photo_update_time > last_display_time)
		end

		# Assume photo has not been updated (if value isn't already set to true)
		@photo_updated ||= false

#		@hold_duration = @control.hold_duration
#		@transition_type = @control.transition_type
#		@transition_duration = @control.transition_duration

		# Add the selected photo to the client_photos list (aka "client photo history")
		client.client_photos.create(
			{
				photo_id: @photo.id,
				hold_duration: @control.hold_duration,
				transition_type: @control.transition_type,
				transition_duration: @control.transition_duration
			}
		) if @photo

		respond_to do |format|
			format.html {}
			format.json {}
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
		client_count = Client.count
		photo_approved_count = Photo.approved.count
		
		recent_photo_count = client_count * (photo_approved_count / 2.0).ceil
		@photos = Photo.select('photos.*, client_photos.client_id').joins(:client_photos).order('client_photos.created_at DESC').limit(recent_photo_count)
		respond_to do |format|
			format.js { render('reload_list') }
			format.html {render('photos')}
			format.json {}
		end
	end


	def scan
		Photo.scan_for_new_photos

		@photos = Photo.pending
		respond_to do |format|
			format.js { render('reload_list') }
			format.html {redirect_to(controls_photos_path)}
			format.json {}
		end
	end


	def reset_and_rescan
		ClientPhoto.destroy_all
		Photo.destroy_all
		Client.destroy_all
		
		Photo.scan_for_new_photos
		
		@photos = Photo.pending
		respond_to do |format|
			format.js { render('reload_list') }
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


end
