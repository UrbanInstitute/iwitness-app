#import <UIKit/UIKit.h>

@class SuspectCardView;

@interface SuspectPortrayalsView : UIView
@property (nonatomic, weak, readonly) SuspectCardView *suspectCardView;
@property (nonatomic, weak, readonly) UICollectionView *collectionView;
@end
