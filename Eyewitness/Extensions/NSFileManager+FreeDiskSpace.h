#import <Foundation/Foundation.h>

@interface NSFileManager (FreeDiskSpace)

- (BOOL)getFreeDiskSpaceBytes:(unsigned long long *)outFreeDiskSpace totalDiskSpaceBytes:(unsigned long long *)outTotalDiskSpace;

@end
