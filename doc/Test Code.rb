source_folder = 'public' + Photo::SOURCE_FOLDER
photo = Photo.where(camera_id: 0).last
filename = source_folder + photo.path
filename = 'public/photos/eye-fi/SSM-99/10-15-2015/Al and Tahisha - 0038.JPG'

image_header = FreeImage::Bitmap.new(FreeImage.FreeImage_Load(FreeImage::FreeImage_GetFIFFromFilename(filename), filename, FreeImage::AbstractSource::Decoder::FIF_LOADNOPIXELS))
FreeImage.check_last_error

fitag_pointer = FFI::MemoryPointer.new :pointer

FreeImage.FreeImage_GetMetadata(:fimd_exif_exif, image_header, 'PixelXDimension', fitag_pointer)
fitag = FreeImage::FITAG.new(fitag_pointer.read_pointer())

FreeImage.FreeImage_GetTagKey(fitag)
FreeImage.FreeImage_GetTagDescription(fitag)
FreeImage.FreeImage_GetTagID(fitag)
FreeImage.FreeImage_GetTagType(fitag)
FreeImage.FreeImage_GetTagCount(fitag)
FreeImage.FreeImage_GetTagLength(fitag)
FreeImage.FreeImage_GetTagValue(fitag).read_short
FreeImage.FreeImage_GetTagValue(fitag).read_long


####################


FreeImage.FreeImage_GetMetadata(:fimd_exif_exif, image_header, 'PixelXDimension', fitag_pointer)
fitag = FreeImage::FITAG.new(fitag_pointer.read_pointer())
FreeImage.get_fitag_value(fitag)


####################


photo = Photo.last
photo.exif_date


####################


fitag_pointer = FFI::MemoryPointer.new :pointer

models = [:fimd_exif_exif, :fimd_exif_main, :fimd_exif_gps, :fimd_exif_makernote, :fimd_exif_interop, :fimd_iptc, :fimd_xmp, :fimd_geotiff, :fimd_animation, :fimd_custom, :fimd_exif_raw]

filename = 'public/photos/eye-fi/SSM-99/10-15-2015/Al and Tahisha - 0037.JPG'
image_header = FreeImage::Bitmap.new(FreeImage.FreeImage_Load(FreeImage::FreeImage_GetFIFFromFilename(filename), filename, FreeImage::AbstractSource::Decoder::FIF_LOADNOPIXELS))
FreeImage.check_last_error

for model in models
metadata_pointer = FreeImage.FreeImage_FindFirstMetadata(model, image_header, fitag_pointer)
if metadata_pointer
begin
fitag = FreeImage::FITAG.new(fitag_pointer.read_pointer())
p "#{model} -- #{FreeImage.FreeImage_GetTagKey(fitag)} -- #{FreeImage.FreeImage_GetTagType(fitag)} -- #{FreeImage.get_fitag_value(fitag)}"
end while FreeImage.FreeImage_FindNextMetadata(metadata_pointer, fitag_pointer)
end
end




