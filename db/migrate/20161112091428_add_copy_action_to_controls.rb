class AddCopyActionToControls < ActiveRecord::Migration
  def up
		add_column	'controls', 'copy_action', :string, default: nil, after: 'auto_approve'

		remove_column 	'controls', 'collect_for_copying'
  end

  def down
		remove_column	'controls', 'copy_action'

		add_column 	'controls', 'collect_for_copying', :boolean, default: false, after: 'auto_approve'
  end
end
