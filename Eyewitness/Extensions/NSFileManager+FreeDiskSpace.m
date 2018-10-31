#import "NSFileManager+FreeDiskSpace.h"

@implementation NSFileManager (FreeDiskSpace)

- (BOOL)getFreeDiskSpaceBytes:(unsigned long long *)outFreeDiskSpace totalDiskSpaceBytes:(unsigned long long *)outTotalDiskSpace {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error:NULL];

    if (dictionary) {
        NSNumber *fileSystemSizeInBytes = [dictionary objectForKey: NSFileSystemSize];
        NSNumber *freeFileSystemSizeInBytes = [dictionary objectForKey:NSFileSystemFreeSize];

        if (outTotalDiskSpace) {
            *outTotalDiskSpace = [fileSystemSizeInBytes unsignedLongLongValue];
        }
        if (outFreeDiskSpace) {
            *outFreeDiskSpace = [freeFileSystemSizeInBytes unsignedLongLongValue];
        }
        return YES;
    } else {
        return NO;
    }
}

@end
