#import "PasswordValidator.h"

@interface PasswordValidator ()
@property (nonatomic, strong) NSString *correctPassword;
@end

@implementation PasswordValidator

- (instancetype)initWithCorrectPassword:(NSString *)correctPassword {
    if (self = [super init]) {
        self.correctPassword = correctPassword;
    }
    return self;
}

- (BOOL)isValidPassword:(NSString *)password {
    return [self.correctPassword isEqualToString:password];
}

@end
