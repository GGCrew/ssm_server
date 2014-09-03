class TransitionTypesController < ApplicationController
  # GET /transition_types
  # GET /transition_types.json
  def index
    @transition_types = TransitionType.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @transition_types }
    end
  end

  # GET /transition_types/1
  # GET /transition_types/1.json
  def show
    @transition_type = TransitionType.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @transition_type }
    end
  end

  # GET /transition_types/new
  # GET /transition_types/new.json
  def new
    @transition_type = TransitionType.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @transition_type }
    end
  end

  # GET /transition_types/1/edit
  def edit
    @transition_type = TransitionType.find(params[:id])
  end

  # POST /transition_types
  # POST /transition_types.json
  def create
    @transition_type = TransitionType.new(params[:transition_type])

    respond_to do |format|
      if @transition_type.save
        format.html { redirect_to @transition_type, notice: 'Transition type was successfully created.' }
        format.json { render json: @transition_type, status: :created, location: @transition_type }
      else
        format.html { render action: "new" }
        format.json { render json: @transition_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /transition_types/1
  # PUT /transition_types/1.json
  def update
    @transition_type = TransitionType.find(params[:id])

    respond_to do |format|
      if @transition_type.update_attributes(params[:transition_type])
        format.html { redirect_to @transition_type, notice: 'Transition type was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @transition_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /transition_types/1
  # DELETE /transition_types/1.json
  def destroy
    @transition_type = TransitionType.find(params[:id])
    @transition_type.destroy

    respond_to do |format|
      format.html { redirect_to transition_types_url }
      format.json { head :no_content }
    end
  end
end
