# benchmark

# Initialize
p "Initializing..."
total_runs = 5
benchmark_camera_folder = 'SSM-99'
benchmark_image_folder = "#{benchmark_camera_folder}/1-1-1970/"
benchmark_condition = ['filename LIKE :filename', {filename: 'benchmark_%'}]	# MySQL-specific wildcard
benchmarks = []
colors = [
	[:red,		:green,	:blue],
	[:red,		:blue,	:green],
	[:green,	:red,		:blue],
	[:green,	:blue,	:red],
	[:blue,		:red,		:green],
	[:blue,		:green,	:red]
]
color = FreeImage::RGBQuad.new
Photo.scan_for_new_photos


# Check for (and create) benchmark image folder
save_folder = "public"
path_components = "#{Photo::SOURCE_FOLDER}#{benchmark_image_folder}".split('/')
path_components.each_with_index do |path_component, index|
	save_folder << "/#{path_component}"
	Dir.mkdir(save_folder) unless Dir.exists?(save_folder)
end


# Create custom images
p "Creating test images..."
colors.count.times do |counter|
	p "  image #{counter + 1}/#{colors.count}"
	image = FreeImage::Bitmap.create(256, 256, 24)

	image.width.times do |x|
		image.height.times do |y|
			# Technically don't need this math, but keeping it for future use.
			color[colors[counter][0]] = (x.to_f/image.width) * 255
			color[colors[counter][1]] =  (y.to_f/image.height) * 255
			color[colors[counter][2]] = 0
			image.set_pixel_color(x, y, color)
		end
	end

	# scale to something more photo-sized
	image = image.rescale(4000, 3000, :bilinear)

	image.save("#{save_folder}/benchmark_#{counter}.png", :png)

	image.free
end


# Benchmark
total_runs.times do |counter|
	p "Test #{counter + 1}/#{total_runs}..."
	
	# Clear the Photo table
	Photo.destroy_all(benchmark_condition)

	# Benchmark
	start_time = DateTime.now
	Photo.scan_for_new_photos
	end_time = DateTime.now

	# Compute and save data
	run_time = (end_time - start_time) * 1.day
	benchmarks << {run_time: run_time, photo_count: Photo.where(benchmark_condition).count}
end


# Cleanup
p "Cleaning up..."

# Delete custom images
image_filenames = Photo.where(benchmark_condition).map{|i| i.filename}
image_filenames.each do |filename|
	p "  deleting #{filename}"
	File.delete "#{save_folder}/#{filename}"
end

# Clear the Photo table
p "  deleting benchmark-related database records"
Photo.destroy_all(benchmark_condition)


# Report
run_times = benchmarks.map{|i| i[:run_time]}
photo_counts = benchmarks.map{|i| i[:photo_count]}
p "Results:"
p "              runs: #{benchmarks.count}"
p "      average time: #{run_times.sum / run_times.count}"
p "    average photos: #{photo_counts.sum / photo_counts.count}"
p " seconds per photo: #{run_times.sum / photo_counts.sum}"


