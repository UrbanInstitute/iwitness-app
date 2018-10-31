#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, WitnessResponse) {
    WitnessResponseNone = -1,
    WitnessResponseYes,
    WitnessResponseNo,
    WitnessResponseNotSure
};

@interface WitnessResponseSelector : UIControl

@property (nonatomic, readonly) WitnessResponse selectedResponse;
@property (nonatomic, weak, readonly) UIButton *yesButton, *noButton;
@property (nonatomic, strong, readonly) UIButton *notSureButton;
@property (nonatomic) BOOL allowNotSureResponse;

- (void)reset;
@end
