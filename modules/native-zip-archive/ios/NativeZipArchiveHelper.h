#import <Foundation/Foundation.h>

// C API — Swift imports via the module map, no bridging header needed.
#ifdef __cplusplus
extern "C" {
#endif

BOOL NativeZipArchiveUnzipFile(NSString *zipPath, NSString *destDir, NSError **error);
BOOL NativeZipArchiveCreateZip(NSString *zipPath, NSString *srcDir, NSError **error);

#ifdef __cplusplus
}
#endif
