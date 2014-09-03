class CreateHistories < ActiveRecord::Migration
  def change
    create_table :histories do |t|
			t.integer	'photo_id'
			t.integer	'client_id'
			t.integer	'screen_height'
			t.integer	'screen_width'
			t.integer	'transition_type_id'
			t.float		'transition_time'
			t.integer	'view_type_id'
			t.float		'view_time'
			t.integer	'position'

      t.timestamps
			t.userstamps
    end
  end
end
