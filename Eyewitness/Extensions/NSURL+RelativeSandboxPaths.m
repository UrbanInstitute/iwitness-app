#import "NSURL+RelativeSandboxPaths.h"
#import "NSFileManager+CommonDirectories.h"

@implementation NSURL (RelativeSandboxPaths)

+ (NSURL *)fileURLFromPathRelativeToApplicationSandbox:(NSString *)relativePath {
    if (relativePath) {
        NSString *applicationPath = [[[NSFileManager defaultManager] URLForApplicationSandbox] path];
        return [NSURL fileURLWithPath:[applicationPath stringByAppendingPathComponent:relativePath]];
    }
    return nil;
}

- (NSString *)pathRelativeToApplicationSandbox {
    NSString *applicationPath = [[[NSFileManager defaultManager] URLForApplicationSandbox] path];
    NSString *fullPath = [self path];
    NSRange applicationPathRange = [fullPath rangeOfString:applicationPath];
    if (applicationPathRange.location != NSNotFound) {
        return [fullPath substringFromIndex:NSMaxRange(applicationPathRange)+1];
    } else {
        return fullPath;
    }
}

@end
