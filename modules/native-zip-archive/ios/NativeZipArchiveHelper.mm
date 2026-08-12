#import "NativeZipArchiveHelper.h"
#import <SSZipArchive/SSZipArchive.h>

BOOL NativeZipArchiveUnzipFile(NSString *zipPath, NSString *destDir, NSError **error) {
  return [SSZipArchive unzipFileAtPath:zipPath toDestination:destDir overwrite:YES password:nil error:error];
}

BOOL NativeZipArchiveCreateZip(NSString *zipPath, NSString *srcDir, NSError **error) {
  // SSZipArchive zips the directory's contents (not the folder itself).
  return [SSZipArchive createZipFileAtPath:zipPath withContentsOfDirectory:srcDir keepParentDirectory:NO];
}
