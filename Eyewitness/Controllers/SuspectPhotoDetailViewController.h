#import <UIKit/UIKit.h>

@class Person, Portrayal;
@protocol SuspectPhotoDetailViewControllerDelegate;

@interface SuspectPhotoDetailViewController : UIViewController
@property (weak, nonatomic, readonly) UIButton *cancelButton;
@property (weak, nonatomic, readonly) UIButton *selectSuspectPhotoButton;
@property (weak, nonatomic, readonly) UIImageView *portrayalImageView;
@property (weak, nonatomic, readonly) UILabel *captionLabel;

- (void)configureWithDelegate:(id<SuspectPhotoDetailViewControllerDelegate>)delegate
                       person:(Person *)person
                    portrayal:(Portrayal *)portrayal;

@end
