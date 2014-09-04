class AddSamplePhotos < ActiveRecord::Migration
  def change
		reversible do |migration|
			migration.up do
				Photo.create!(:camera_id => 1, :date => Date.strptime('9-4-2014', '%m-%d-%Y'), :filename => 'IMG_4690.JPG')
				Photo.create!(:camera_id => 1, :date => Date.strptime('9-4-2014', '%m-%d-%Y'), :filename => 'IMG_7159.JPG')
				Photo.create!(:camera_id => 1, :date => Date.strptime('9-4-2014', '%m-%d-%Y'), :filename => 'IMG_7188.JPG')
				Photo.create!(:camera_id => 1, :date => Date.strptime('9-4-2014', '%m-%d-%Y'), :filename => 'IMG_7627.JPG')
				Photo.create!(:camera_id => 1, :date => Date.strptime('9-4-2014', '%m-%d-%Y'), :filename => 'IMG_7971.JPG')
				Photo.create!(:camera_id => 1, :date => Date.strptime('9-4-2014', '%m-%d-%Y'), :filename => 'IMG_8673.JPG')
				Photo.create!(:camera_id => 1, :date => Date.strptime('9-4-2014', '%m-%d-%Y'), :filename => 'IMG_8710.JPG')
			end
			
			migration.down do
				Photo.destoy_all()
			end		
		end
  end
end
