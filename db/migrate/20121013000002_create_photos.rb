class CreatePhotos < ActiveRecord::Migration
  def change
    create_table :photos do |t|
			t.string	'filename'
			t.integer	'photo_status_id'
			t.integer	'position'
			
      t.timestamps
			t.userstamps
    end
  end
end
