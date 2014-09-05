class CreateClientPhotos < ActiveRecord::Migration
  def change
    create_table :client_photos do |t|
			t.integer	'client_id'
			t.integer	'photo_id'

      t.timestamps
    end
  end
end
