class CreateViewTypes < ActiveRecord::Migration
  def change
    create_table :view_types do |t|
			t.string	'name'
			t.float		'default_view_time'
			t.integer	'position'

      t.timestamps
			t.userstamps
    end
  end
end
