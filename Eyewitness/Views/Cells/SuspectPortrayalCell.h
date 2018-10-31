#import <UIKit/UIKit.h>

@class Portrayal;

@interface SuspectPortrayalCell : UICollectionViewCell
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UIImageView *selectionView;
@property (nonatomic, weak) IBOutlet UILabel *dateLabel;

- (void)configureWithPortrayal:(Portrayal *)portrayal;
@end
