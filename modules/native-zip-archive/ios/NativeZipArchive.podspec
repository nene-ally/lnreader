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
  # SSZipArchive: pure ObjC zip/unzip on top of zlib — the iOS SDK has no
  # public libarchive headers, so we use this instead of hand-rolling.
  s.dependency 'SSZipArchive'

  s.source_files = "**/*.{h,m,mm,swift}"
  s.pod_target_xcconfig = {
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17'
  }
end
