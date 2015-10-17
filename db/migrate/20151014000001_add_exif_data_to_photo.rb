class AddExifDataToPhoto < ActiveRecord::Migration
  def change
		add_column	'photos',	'exif_date',		:datetime,	after: 'filename',		default: nil
		add_column	'photos',	'exif_make',		:string,		after: 'exif_date',		default: nil
		add_column	'photos',	'exif_model',		:string,		after: 'exif_make',		default: nil
		add_column	'photos',	'exif_width',		:integer,		after: 'exif_model',	default: nil
		add_column	'photos',	'exif_height',	:integer,		after: 'exif_width',	default: nil
  end
end
