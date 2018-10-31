#import <UIKit/UIKit.h>

@interface AlertView : UIAlertView

- (instancetype)initWithTitle:(NSString *)title
                      message:(NSString *)message
            cancelButtonTitle:(NSString *)cancelButtonTitle
            otherButtonTitles:(NSArray *)otherButtonTitles
                cancelHandler:(void (^)(void))cancelHandler
          confirmationHandler:(void (^)(NSInteger otherButtonIndex))confirmationHandler;

@end
