#import <UIKit/UIKit.h>

@class PerpetratorDescription, PerpetratorDescriptionViewControllerProvider;
@class Lineup;

@interface LineupPerpetratorDescriptionViewController : UIViewController
@property (weak, nonatomic, readonly) UIButton *addDescriptionButton;
@property (weak, nonatomic, readonly) UILabel *perpetratorDescriptionLabel;

- (void)configureWithLineup:(Lineup *)lineup perpetratorDescriptionViewControllerProvider:(PerpetratorDescriptionViewControllerProvider *)provider;
@end
