class PhotosController < ApplicationController

  before_action :set_photo, only: [:show, :edit, :update, :destroy]


	#..#


  # GET /photos
  # GET /photos.json
  def index
    #@photos = Photo.all
		approved
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


	def next
		# Identify clients by IP address
		client_ip = request.env['REMOTE_ADDR']
		client = Client.where({ip_address: client_ip}).first
		client = Client.create({ip_address: client_ip}) if client.nil?

		# Get history of client photos to identify any new photos
		client_photo_ids = client.photos.map(&:id)
		if client_photo_ids.empty?
			conditions_new = []
		else
			conditions_new = ["id NOT IN (:client_photo_ids)", {client_photo_ids: client_photo_ids.uniq}]
		end
		@photo = Photo.approved.where(conditions_new).order('created_at ASC').first

		if @photo.nil?
			# Get random old photo, preferably one that hasn't been shown recently
			recent_photo_count = (Photo.approved.count / 2).floor
			recent_client_photo_ids = (recent_photo_count == 0 ? [-1] : client_photo_ids[-recent_photo_count..-1])
			conditions_not_recent = ["id NOT IN (:recent_client_photo_ids)", {recent_client_photo_ids: recent_client_photo_ids}]
			old_photos = Photo.approved.where(conditions_not_recent)

			index = (rand * old_photos.count).floor
			@photo =  old_photos[index]
		end

		# Add the selected photo to the client_photos list (aka "client photo history")
		client.client_photos.create({photo_id: @photo.id}) if @photo

		respond_to do |format|
			format.html {}
			format.json {}
		end
	end


	def pending
		@photos = Photo.pending

		respond_to do |format|
			format.html {render('index')}
			format.json {}
		end
	end


	def approved
		@photos = Photo.approved

		respond_to do |format|
			format.html {render('index')}
			format.json {}
		end
	end


	def denied
		@photos = Photo.denied

		respond_to do |format|
			format.html {render('index')}
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
