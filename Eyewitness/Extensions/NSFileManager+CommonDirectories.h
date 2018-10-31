#import <Foundation/Foundation.h>

@interface NSFileManager (CommonDirectories)

- (NSURL *)URLForApplicationSandbox;
- (NSURL *)URLForDocumentDirectory;
- (NSURL *)URLForApplicationSupportDirectory;
- (NSURL *)URLForLineupPhotos;

- (void) ensureDirectoryExistsAtURL:(NSURL *)directoryURL;
@end
