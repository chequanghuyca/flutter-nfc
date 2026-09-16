#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_face_sdk.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_face_sdk'
  s.version          = '8.3.0'
  s.summary          = 'Local Flutter FFI wrapper for Luxand FaceSDK 8.3.'
  s.description      = <<-DESC
Local Flutter FFI wrapper for Luxand FaceSDK 8.3.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }

  # This will ensure the source files in Classes/ are included in the native
  # builds of apps using this FFI plugin. Podspec does not support relative
  # paths, so Classes contains a forwarder C file that relatively imports
  # `../src/*` so that the C sources can be shared among all target platforms.
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # FaceSDK 8.3's shared iOS framework is the vendor-supported redistributable.
  # It avoids force-loading the large legacy universal static archive.
  s.vendored_frameworks = 'Frameworks/fsdk.framework'
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'OTHER_LDFLAGS' => '-lc++ -lz'
  }
  s.swift_version = '5.0'
end
