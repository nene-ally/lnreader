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
  s.public_header_files = "NativeZipArchiveHelper.h"
  # Module map so Swift can `import NativeZipArchiveHelper` (no bridging header —
  # bridging headers are unsupported in framework targets).
  s.module_map = "module.modulemap"
  s.pod_target_xcconfig = {
    'OTHER_LDFLAGS' => '-larchive',
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17'
  }
end
