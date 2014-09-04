class Photo < ActiveRecord::Base
	def full_path
		return "#{camera_folder}/#{date_folder}/#{self.filename}"
	end

	def camera_folder
		return "SSM-#{self.camera_id.to_s.rjust(2, '0')}"
	end

	def date_folder
		return self.date.strftime("%-m-%-d-%Y")
	end
end
