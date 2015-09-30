class AddMd5ToPhotos < ActiveRecord::Migration
  def change
		add_column	'photos',	'md5', :string, after: 'approval_state'
  end
end
