class CreatePhotos < ActiveRecord::Migration
  def change
    create_table :photos do |t|
      t.integer "camera_id"
			t.date		"date"
			t.string  "filename"

      t.timestamps
    end
  end
end
