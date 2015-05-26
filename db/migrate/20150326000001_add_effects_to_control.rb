class AddEffectsToControl < ActiveRecord::Migration
  def change
		add_column	'controls',	'color_mode_normal',		:boolean, :default => true
		add_column	'controls',	'color_mode_grayscale',	:boolean, :default => false
		add_column	'controls',	'color_mode_sepia',			:boolean, :default => false
		add_column	'controls',	'effect_vignette',			:boolean, :default => false
  end
end
