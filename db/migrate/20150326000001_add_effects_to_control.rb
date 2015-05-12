class AddEffectsToControl < ActiveRecord::Migration
  def change
		add_column	'controls',	'effect_normal',		:boolean, :default => true
		add_column	'controls',	'effect_grayscale',	:boolean, :default => false
		add_column	'controls',	'effect_sepia',			:boolean, :default => false
		add_column	'controls',	'apply_vignette',		:boolean, :default => false
  end
end
