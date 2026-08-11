#import <Foundation/Foundation.h>

@interface NativeZipArchiveHelper : NSObject

+ (BOOL)unzipFileAtPath:(NSString *)zipPath toDirectory:(NSString *)destDir error:(NSError **)error;
+ (BOOL)createZipAtPath:(NSString *)zipPath fromDirectory:(NSString *)srcDir error:(NSError **)error;

@end
