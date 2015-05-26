class AddEffectToClientPhoto < ActiveRecord::Migration
  def change
		add_column	'client_photos', 'color_mode', 			:integer
		add_column	'client_photos', 'effect_vignette',	:boolean,	default: false
  end
end
