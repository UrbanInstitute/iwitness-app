#import <UIKit/UIKit.h>

@class Person, SuspectCardView;
@class FaceLoader;

@interface PersonResultCell : UICollectionViewCell
@property(nonatomic, weak, readonly) SuspectCardView *suspectCardView;

- (void)configureWithPerson:(Person *)person faceLoader:(FaceLoader *)faceLoader;
@end
