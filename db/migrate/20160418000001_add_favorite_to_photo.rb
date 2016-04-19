class AddFavoriteToPhoto < ActiveRecord::Migration
  def change
		add_column	'photos', 'favorite', :boolean, default: false, after: 'approval_state'
  end
end
