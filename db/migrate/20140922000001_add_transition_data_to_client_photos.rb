class AddTransitionDataToClientPhotos < ActiveRecord::Migration
  def change
		add_column	'client_photos', 'hold_duration',				:integer
		add_column	'client_photos', 'transition_type',			:string
		add_column	'client_photos', 'transition_duration',	:integer
  end
end
