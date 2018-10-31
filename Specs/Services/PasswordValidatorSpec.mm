#import "PasswordValidator.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(PasswordValidatorSpec)

describe(@"PasswordValidator", ^{
    __block PasswordValidator *validator;

    beforeEach(^{
        validator = [[PasswordValidator alloc] initWithCorrectPassword:@"aPassword"];
    });

    describe(@"validating a password", ^{
        it(@"should report the correct password as valid", ^{
            [validator isValidPassword:@"aPassword"] should be_truthy;
        });

        it(@"should report anything else as invalid", ^{
            [validator isValidPassword:@"somethingElse"] should be_falsy;
        });

        it(@"should report 'nil' as invalid", ^{
            [validator isValidPassword:nil] should be_falsy;
        });
    });
});

SPEC_END
