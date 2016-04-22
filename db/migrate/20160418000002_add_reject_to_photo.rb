class AddRejectToPhoto < ActiveRecord::Migration
  def change
		add_column	'photos', 'reject', :boolean, default: false, after: 'favorite'
  end
end
