#import "AlertView.h"

@interface AlertView () <UIAlertViewDelegate>
@property (nonatomic, copy) void (^confirmationHandler)(NSInteger otherButtonIndex);
@property (nonatomic, copy) void (^cancelHandler)(void);
@end

@implementation AlertView

- (instancetype)initWithTitle:(NSString *)title
                      message:(NSString *)message
            cancelButtonTitle:(NSString *)cancelButtonTitle
            otherButtonTitles:(NSArray *)otherButtonTitles
                cancelHandler:(void (^)(void))cancelHandler
          confirmationHandler:(void (^)(NSInteger otherButtonIndex))confirmationHandler {
    if (self = [super initWithTitle:title message:message delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles:nil]) {
        for (NSString *buttonTitle in otherButtonTitles) {
            [self addButtonWithTitle:buttonTitle];
        }

        self.cancelHandler = cancelHandler;
        self.confirmationHandler = confirmationHandler;
    }
    return self;
}

#pragma mark - <UIAlertViewDelegate>

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.cancelButtonIndex) {
        if (self.cancelHandler) {
            self.cancelHandler();
        }
    } else {
        if (self.confirmationHandler) {
            NSInteger indexOffset = (alertView.cancelButtonIndex==-1) ? 0 : 1;
            self.confirmationHandler(buttonIndex - indexOffset);
        }
    }

    self.cancelHandler = nil;
    self.confirmationHandler = nil;
}

@end
