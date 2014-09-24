class AddPlayStateToControls < ActiveRecord::Migration
  def change
		add_column	'controls',	'play_state',	:string

		reversible do |migration|
			migration.up do
				ActiveRecord::Base.connection.execute("UPDATE controls SET play_state='play' WHERE play_state IS NULL;")
			end
			
			migration.down do
				#nothing needed
			end
		end
  end
end
