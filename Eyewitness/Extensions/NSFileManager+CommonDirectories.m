#import "NSFileManager+CommonDirectories.h"

@implementation NSFileManager (CommonDirectories)

- (NSURL *)URLForApplicationSandbox {
    return [[self URLForDocumentDirectory] URLByDeletingLastPathComponent];
}

- (NSURL *)URLForDocumentDirectory {
    return [self URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:NULL];
}

- (NSURL *)URLForApplicationSupportDirectory {
    return [self URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:NULL];
}

- (NSURL *)URLForLineupPhotos {
    NSURL *lineupPhotosURL = [[self URLForApplicationSupportDirectory] URLByAppendingPathComponent:@"LineupPhotos"];
    [self ensureDirectoryExistsAtURL:lineupPhotosURL];
    return lineupPhotosURL;
}

- (void) ensureDirectoryExistsAtURL:(NSURL *)directoryURL {
    if (![self fileExistsAtPath:[directoryURL path]]) {
        [self createDirectoryAtURL:directoryURL withIntermediateDirectories:YES attributes:nil error:NULL];
    }
}

@end
