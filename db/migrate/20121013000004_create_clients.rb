class CreateClients < ActiveRecord::Migration
  def change
    create_table :clients do |t|
			t.string	'ip_address'
			t.string	'mac_address'
			t.integer	'screen_height'
			t.integer	'screen_width'
			t.integer	'current_view_type_id'
			t.float		'current_view_time'
			t.integer	'current_transition_type_id'
			t.float		'current_transition_time'

      t.timestamps
			t.userstamps
    end
  end
end
