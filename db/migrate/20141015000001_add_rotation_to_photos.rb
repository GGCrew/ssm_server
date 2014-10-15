class AddRotationToPhotos < ActiveRecord::Migration
  def change
		add_column	'photos', 'rotation', :integer, :default => 0, :after => 'filename'
  end
end
