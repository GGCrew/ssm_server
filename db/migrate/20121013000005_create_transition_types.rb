class CreateTransitionTypes < ActiveRecord::Migration
  def change
    create_table :transition_types do |t|
			t.string	'name'
			t.float		'default_transition_time'
			t.integer	'position'

      t.timestamps
			t.userstamps
		end
  end
end
