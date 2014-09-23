class CreateControls < ActiveRecord::Migration
  def change
    create_table :controls do |t|
			t.integer	'hold_duration'
			t.integer 'transition_duration'
			t.string	'transition_type'

      t.timestamps
    end
  end
end
