source_folder = 'public' + Photo::SOURCE_FOLDER
photo = Photo.where(camera_id: 0).last

image_header = FreeImage::Bitmap.new(
FreeImage.FreeImage_Load(
FreeImage::FreeImage_GetFIFFromFilename(source_folder + photo.path),
source_folder + photo.path,
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
FreeImage.FreeImage_GetTagValue(fitag)




####################


photo = Photo.last
photo.exif_date
