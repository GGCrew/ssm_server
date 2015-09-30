class AddSpecialColumnsToPhotos < ActiveRecord::Migration
  def change
		add_column	'photos',	'special',	:boolean,	default: false
		add_column	'photos',	'special_folder',	:string
  end
end
