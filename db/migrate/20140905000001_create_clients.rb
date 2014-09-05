class CreateClients < ActiveRecord::Migration
  def change
    create_table :clients do |t|
			t.string	'ip_address'

      t.timestamps
    end
  end
end
