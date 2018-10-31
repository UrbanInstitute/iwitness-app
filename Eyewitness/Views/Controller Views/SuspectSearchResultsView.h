#import <UIKit/UIKit.h>

@class SuspectSearchResultsHeaderView;

@interface SuspectSearchResultsView : UIView

@property (nonatomic, strong) SuspectSearchResultsHeaderView *suspectSearchResultsHeaderView;
@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;

@end
