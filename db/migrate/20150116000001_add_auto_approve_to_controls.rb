class AddAutoApproveToControls < ActiveRecord::Migration
  def change
		add_column	'controls', 'auto_approve', :boolean, :default => false, :after => 'play_state'
  end
end
