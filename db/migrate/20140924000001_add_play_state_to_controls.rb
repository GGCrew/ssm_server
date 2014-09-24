class AddPlayStateToControls < ActiveRecord::Migration
  def change
		add_column	'controls',	'play_state',	:string
  end
end
