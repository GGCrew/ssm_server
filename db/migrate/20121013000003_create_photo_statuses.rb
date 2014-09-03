class CreatePhotoStatuses < ActiveRecord::Migration
  def change
    create_table :photo_statuses do |t|
			t.string	'name'
			t.integer	'position'
		
      t.timestamps
			t.userstamps
    end
  end
end
