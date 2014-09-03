class ViewTypesController < ApplicationController
  # GET /view_types
  # GET /view_types.json
  def index
    @view_types = ViewType.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @view_types }
    end
  end

  # GET /view_types/1
  # GET /view_types/1.json
  def show
    @view_type = ViewType.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @view_type }
    end
  end

  # GET /view_types/new
  # GET /view_types/new.json
  def new
    @view_type = ViewType.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @view_type }
    end
  end

  # GET /view_types/1/edit
  def edit
    @view_type = ViewType.find(params[:id])
  end

  # POST /view_types
  # POST /view_types.json
  def create
    @view_type = ViewType.new(params[:view_type])

    respond_to do |format|
      if @view_type.save
        format.html { redirect_to @view_type, notice: 'View type was successfully created.' }
        format.json { render json: @view_type, status: :created, location: @view_type }
      else
        format.html { render action: "new" }
        format.json { render json: @view_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /view_types/1
  # PUT /view_types/1.json
  def update
    @view_type = ViewType.find(params[:id])

    respond_to do |format|
      if @view_type.update_attributes(params[:view_type])
        format.html { redirect_to @view_type, notice: 'View type was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @view_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /view_types/1
  # DELETE /view_types/1.json
  def destroy
    @view_type = ViewType.find(params[:id])
    @view_type.destroy

    respond_to do |format|
      format.html { redirect_to view_types_url }
      format.json { head :no_content }
    end
  end
end
