source_folder = 'public' + Photo::SOURCE_FOLDER
photo = Photo.where(camera_id: 0).last
filename = source_folder + photo.path
filename = 'public/photos/eye-fi/SSM-99/10-15-2015/Al and Tahisha - 0037.JPG'

image_header = FreeImage::Bitmap.new(
FreeImage.FreeImage_Load(
FreeImage::FreeImage_GetFIFFromFilename(filename),
filename,
FreeImage::AbstractSource::Decoder::FIF_LOADNOPIXELS
)
)
FreeImage.check_last_error

fitag_pointer = FFI::MemoryPointer.new :pointer

FreeImage.FreeImage_GetMetadata(:fimd_exif_exif, image_header, 'DateTimeOriginal', fitag_pointer)
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


FreeImage.FreeImage_GetMetadata(:fimd_exif_exif, image_header, 'PixelYDimension', fitag_pointer)
fitag = FreeImage::FITAG.new(fitag_pointer.read_pointer())
FreeImage.get_fitag_value(fitag)


####################


photo = Photo.last
photo.exif_date


####################


fitag_pointer = FFI::MemoryPointer.new :pointer
metadata_pointer = FFI::MemoryPointer.new :pointer

filename = 'public/photos/eye-fi/SSM-99/10-15-2015/Al and Tahisha - 0037.JPG'
image_header = FreeImage::Bitmap.new(FreeImage.FreeImage_Load(FreeImage::FreeImage_GetFIFFromFilename(filename), filename, FreeImage::AbstractSource::Decoder::FIF_LOADNOPIXELS))
FreeImage.check_last_error

metadata_pointer = FreeImage.FreeImage_FindFirstMetadata(:fimd_exif_exif, image_header, fitag_pointer)
if metadata_pointer
begin
fitag = FreeImage::FITAG.new(fitag_pointer.read_pointer())
p FreeImage.FreeImage_GetTagKey(fitag)
end while FreeImage.FreeImage_FindNextMetadata(metadata_pointer, fitag_pointer)
end
