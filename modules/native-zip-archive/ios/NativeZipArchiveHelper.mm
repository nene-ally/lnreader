#import "NativeZipArchiveHelper.h"
#import <archive.h>
#import <archive_entry.h>
#import <sys/stat.h>
#import <dirent.h>

@implementation NativeZipArchiveHelper

+ (BOOL)unzipFileAtPath:(NSString *)zipPath toDirectory:(NSString *)destDir error:(NSError **)error {
  struct archive *a = archive_read_new();
  archive_read_support_format_zip(a);
  archive_read_support_filter_all(a);
  struct archive *ext = archive_write_disk_new();
  archive_write_disk_set_options(ext, ARCHIVE_EXTRACT_TIME | ARCHIVE_EXTRACT_PERM | ARCHIVE_EXTRACT_SECURE_NODOTDOT);
  archive_write_disk_set_standard_lookup(ext);

  int r = archive_read_open_filename(a, zipPath.UTF8String, 10240);
  if (r != ARCHIVE_OK) {
    if (error) *error = [NSError errorWithDomain:@"NativeZipArchive" code:r userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithUTF8String:archive_error_string(a)]}];
    archive_read_free(a);
    archive_write_free(ext);
    return NO;
  }

  for (;;) {
    struct archive_entry *entry;
    r = archive_read_next_header(a, &entry);
    if (r == ARCHIVE_EOF) break;
    if (r < ARCHIVE_OK) {
      if (error) *error = [NSError errorWithDomain:@"NativeZipArchive" code:r userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithUTF8String:archive_error_string(a)]}];
      archive_read_free(a);
      archive_write_free(ext);
      return NO;
    }
    if (r < ARCHIVE_WARN) continue;

    const char *entryPath = archive_entry_pathname(entry);
    if (!entryPath) continue;
    NSString *safeName = [NSString stringWithUTF8String:entryPath];
    if ([safeName containsString:@"../"]) continue; // path traversal guard

    NSString *fullPath = [destDir stringByAppendingPathComponent:safeName];
    archive_entry_set_pathname(entry, fullPath.UTF8String);

    r = archive_write_header(ext, entry);
    if (r < ARCHIVE_OK) {
      if (error) *error = [NSError errorWithDomain:@"NativeZipArchive" code:r userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithUTF8String:archive_error_string(ext)]}];
      archive_read_free(a);
      archive_write_free(ext);
      return NO;
    }
    if (archive_entry_size(entry) > 0) {
      const void *buff = NULL;
      size_t size;
      la_int64_t offset;
      for (;;) {
        r = archive_read_data_block(a, &buff, &size, &offset);
        if (r == ARCHIVE_EOF) break;
        if (r < ARCHIVE_OK) break;
        r = archive_write_data_block(ext, buff, size, offset);
        if (r < ARCHIVE_OK) {
          if (error) *error = [NSError errorWithDomain:@"NativeZipArchive" code:r userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithUTF8String:archive_error_string(ext)]}];
          archive_read_free(a);
          archive_write_free(ext);
          return NO;
        }
      }
    }
    archive_write_finish_entry(ext);
  }
  archive_read_close(a);
  archive_read_free(a);
  archive_write_close(ext);
  archive_write_free(ext);
  return YES;
}

+ (BOOL)createZipAtPath:(NSString *)zipPath fromDirectory:(NSString *)srcDir error:(NSError **)error {
  struct archive *a = archive_write_new();
  archive_write_set_format_zip(a);
  int r = archive_write_open_filename(a, zipPath.UTF8String);
  if (r != ARCHIVE_OK) {
    if (error) *error = [NSError errorWithDomain:@"NativeZipArchive" code:r userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithUTF8String:archive_error_string(a)]}];
    archive_write_free(a);
    return NO;
  }

  BOOL ok = [self addDirectory:srcDir toArchive:a basePath:srcDir error:error];

  archive_write_close(a);
  archive_write_free(a);
  return ok;
}

+ (BOOL)addDirectory:(NSString *)dir toArchive:(struct archive *)a basePath:(NSString *)basePath error:(NSError **)error {
  NSFileManager *fm = [NSFileManager defaultManager];
  NSArray *items = [fm contentsOfDirectoryAtPath:dir error:nil];
  for (NSString *item in items) {
    NSString *full = [dir stringByAppendingPathComponent:item];
    BOOL isDir = NO;
    [fm fileExistsAtPath:full isDirectory:&isDir];
    if (isDir) {
      [self addDirectory:full toArchive:a basePath:basePath error:error];
      continue;
    }
    NSString *relative = [full substringFromIndex:basePath.length + 1];
    struct archive_entry *entry = archive_entry_new();
    archive_entry_set_pathname(entry, relative.UTF8String);
    struct stat st;
    if (stat(full.UTF8String, &st) == 0) {
      archive_entry_set_size(entry, st.st_size);
      archive_entry_set_filetype(entry, AE_IFREG);
      archive_entry_set_perm(entry, 0644);
    }
    int r = archive_write_header(a, entry);
    if (r < ARCHIVE_OK) {
      if (error) *error = [NSError errorWithDomain:@"NativeZipArchive" code:r userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithUTF8String:archive_error_string(a)]}];
      archive_entry_free(entry);
      return NO;
    }
    NSData *data = [NSData dataWithContentsOfFile:full];
    if (data) {
      archive_write_data(a, data.bytes, data.length);
    }
    archive_write_finish_entry(a);
    archive_entry_free(entry);
  }
  return YES;
}

@end
