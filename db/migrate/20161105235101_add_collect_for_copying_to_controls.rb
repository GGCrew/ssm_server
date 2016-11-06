class AddCollectForCopyingToControls < ActiveRecord::Migration
  def change
		add_column	'controls', 'collect_for_copying', :boolean, default: false, after: 'auto_approve'
  end
end
