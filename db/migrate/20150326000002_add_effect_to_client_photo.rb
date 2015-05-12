class AddEffectToClientPhoto < ActiveRecord::Migration
  def change
		add_column	'client_photos', 'effect', 					:integer
		add_column	'client_photos', 'apply_vignette',	:boolean,	default: false
  end
end
