#import <Foundation/Foundation.h>

@interface NSURL (RelativeSandboxPaths)

+ (NSURL *)fileURLFromPathRelativeToApplicationSandbox:(NSString *)relativePath;

- (NSString *)pathRelativeToApplicationSandbox;

@end
