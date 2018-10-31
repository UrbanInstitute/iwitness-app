#import <UIKit/UIKit.h>

@class LanguagesViewController;

@protocol LanguagesViewControllerDelegate <NSObject>
- (void)languagesViewController:(LanguagesViewController *)controller didSelectLanguageWithCode:(NSString *)code;
@end


@interface LanguagesViewController : UITableViewController

- (instancetype)initWithDelegate:(id<LanguagesViewControllerDelegate>)delegate;

@end
