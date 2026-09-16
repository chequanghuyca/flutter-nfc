#ifndef CONVERTER
#define CONVERTER

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

FFI_PLUGIN_EXPORT void YUV420ToRGB(const unsigned char*,
                             const unsigned char*,
                             const unsigned char*,
                             const int,
                             const int,
                             const int,
                             const int,
                             const int,
                             unsigned char*);

FFI_PLUGIN_EXPORT void BGRAToRGB(const unsigned char*, const int, const int, const int, unsigned char*);

#endif
