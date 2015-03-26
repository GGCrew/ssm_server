class AddEffectToClientPhoto < ActiveRecord::Migration
  def change
		add_column	'client_photos', 'effect', :integer
  end
end
