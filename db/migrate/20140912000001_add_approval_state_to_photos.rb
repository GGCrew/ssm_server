class AddApprovalStateToPhotos < ActiveRecord::Migration
  def change
		add_column	'photos', 'approval_state', :string, default: 'pending'
  end
end
