class ControlsController < ApplicationController


	before_action	:set_control,	only:	[:state]


	#..#


	def create
		logger.debug(params.inspect)
		update
	end


  def update
    respond_to do |format|
			@control = Control.new(Control.default_attributes.merge(control_params))
      if @control.save
        format.html { redirect_to(photos_path, notice: 'Setting was successfully updated.') }
        format.json { 
					#render :show, status: :ok, location: @photo
					}
      else
        format.html { render :edit }
        format.json { render json: @photo.errors, status: :unprocessable_entity }
      end
    end
  end


	def state
		@control = Control.last
		respond_to do |format|
			format.html {}
			format.json {}
		end
	end


	#..#


  private

    # Use callbacks to share common setup or constraints between actions.


    # Never trust parameters from the scary internet, only allow the white list through.
    def control_params
      params[:control]
    end

end
