#import "UIImageView+FocusOnRect.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(UIImageView_FocusOnRectSpec)

describe(@"UIImageView_FocusOnRect", ^{
    __block UIImageView *view;

    beforeEach(^{
        view = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 20)];

        UIGraphicsBeginImageContext(CGSizeMake(30, 40));
        UIImage *tallImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        view.image = tallImage;
    });

    describe(@"focusing on a rect", ^{
        context(@"for a non-null rect", ^{
            beforeEach(^{
                [view focusOnImageRect:CGRectMake(0, 0, 20, 20)];
            });

            it(@"should switch to use the scale-to-fit content mode", ^{
                view.contentMode should equal(UIViewContentModeScaleAspectFit);
            });

            it(@"should adjust its contents rect to crop areas away from the focus rect", ^{
                view.layer.contentsRect should equal(CGRectMake(0, 0, 1, 0.5f));
            });
        });

        context(@"for a null rect", ^{
            beforeEach(^{
                view.layer.contentsRect = CGRectMake(0, 0, .2f, .2f);
                view.contentMode = UIViewContentModeScaleAspectFit;
                [view focusOnImageRect:CGRectNull];
            });

            it(@"should switch to use the scale-to-fit content mode", ^{
                view.contentMode should equal(UIViewContentModeScaleAspectFill);
            });

            it(@"should clear any focus rect", ^{
                view.layer.contentsRect should equal(CGRectMake(0, 0, 1, 1));
            });
        });
    });
});

SPEC_END
