Pod::Spec.new do |s|
  s.name           = 'NativeZipArchive'
  s.version        = '1.0.0'
  s.summary        = 'NativeZipArchive module'
  s.description    = 'NativeZipArchive module'
  s.license        = 'MIT'
  s.author         = ''
  s.homepage       = 'https://github.com/LNReader/lnreader'
  s.platforms      = { :ios => '15.5', :tvos => '15.5' }
  s.source         = { git: '' }
  s.static_framework = true

  s.dependency 'ExpoModulesCore'

  s.source_files = "**/*.{h,m,mm,swift}"
  # Swift → ObjC++ bridge
  s.preserve_paths = "NativeZipArchiveHelper.h"
  s.pod_target_xcconfig = {
    'SWIFT_OBJC_BRIDGING_HEADER' => '$(PODS_TARGET_SRCROOT)/NativeZipArchiveHelper.h',
    'OTHER_LDFLAGS' => '-larchive',
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17'
  }
end
