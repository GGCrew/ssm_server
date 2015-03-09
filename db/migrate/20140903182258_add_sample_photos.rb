class AddSamplePhotos < ActiveRecord::Migration

=begin
	2015-03-09
	connr001
	Obsolete migration.  The sample photos no longer exist as part of the repository, so any from-scratch migrations will fail.
	Keeping the migration for historical reasons, but commented-out the line that actually processes the obsolete photo data.
=end

  def change
		reversible do |migration|
			migration.up do
				photos = [
					{:camera_id => 1, :date => '9-4-2014', :filename => 'IMG_4690.JPG'},
					{:camera_id => 1, :date => '9-4-2014', :filename => 'IMG_7159.JPG'},
					{:camera_id => 1, :date => '9-4-2014', :filename => 'IMG_7188.JPG'},
					{:camera_id => 1, :date => '9-4-2014', :filename => 'IMG_7627.JPG'},
					{:camera_id => 1, :date => '9-4-2014', :filename => 'IMG_7971.JPG'},
					{:camera_id => 1, :date => '9-4-2014', :filename => 'IMG_8673.JPG'},
					{:camera_id => 1, :date => '9-4-2014', :filename => 'IMG_8710.JPG'},
				]
				
				say_with_time('Adding photos...') do
					photos.each_with_index do |photo, index|
						puts "#{index}/#{photos.count}"
						#Photo.create!(:camera_id => photo[:camera_id], :date => Date.strptime(photo[:date], '%m-%d-%Y'), :filename => photo[:filename])
					end
				end
			end
			
			migration.down do
				Photo.destoy_all()
			end		
		end
  end
end
