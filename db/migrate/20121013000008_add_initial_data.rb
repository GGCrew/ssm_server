class AddInitialData < ActiveRecord::Migration
  def up
		say_with_time('Addint TransitionTypes...') do
			TransitionType.create!(:name => 'dissolve',				:default_transition_time => 3.0)
			TransitionType.create!(:name => 'fade to black',	:default_transition_time => 3.0)
		end
		
		say_with_time('Addint ViewTypes...') do
			ViewType.create!(:name => 'static',	:default_view_time => 10.0)
		end
		
		say_with_time('Addint PhotoStatuses...') do
			PhotoStatus.find_or_create_by_name('pending')
			PhotoStatus.find_or_create_by_name('approved')
			PhotoStatus.find_or_create_by_name('denied')
		end
  end

  def down
		History.destroy_all
		Client.destroy_all
		Photo.destroy_all
		
		TransitionType.destroy_all
		ViewType.destroy_all
		PhotoStatus.destroy_all
  end
end
