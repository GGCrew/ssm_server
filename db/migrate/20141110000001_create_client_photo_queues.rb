class CreateClientPhotoQueues < ActiveRecord::Migration
  def change
    create_table :client_photo_queues do |t|
			t.integer	'client_id'
			t.integer	'photo_id'

      t.timestamps
    end
  end
end
