module FreeImage

	FreeImage.enum :model, [	
		:fimd_comments, 0,
		:fimd_exif_main, 1,
		:fimd_exif_exif, 2,
		:fimd_exif_gps, 3,
		:fimd_exif_makernote, 4,
		:fimd_exif_interop, 5,
		:fimd_iptc, 6,
		:fimd_xmp, 7,
		:fimd_geotiff, 8,
		:fimd_animation, 9,
		:fimd_custom, 10,
		:fimd_exif_raw, 11
	]

  class FITAG < FFI::Struct
		layout :key,					:string,
					 :description,	:string,
					 :id,						:word,
					 :type,					:word,
					 :count,				:dword, 
					 :length,				:dword,
					 :value,				:dword
	end

  # DLL_API BOOL DLL_CALLCONV FreeImage_GetMetadata(FREE_IMAGE_MDMODEL model, FIBITMAP *dib, const char *key, FITAG **tag);
  attach_function('FreeImage_GetMetadata', [:model, :pointer, :string, :pointer], FreeImage::Boolean)

	# FreeImage_GetMetadata(FIMD_EXIF_MAIN, dib, "Make", &tagMake);

end
