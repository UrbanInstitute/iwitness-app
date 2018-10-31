#import <Foundation/Foundation.h>

@interface PasswordValidator : NSObject

- (instancetype)initWithCorrectPassword:(NSString *)correctPassword;
- (BOOL)isValidPassword:(NSString *)password;

@end
