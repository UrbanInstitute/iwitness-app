#import <UIKit/UIKit.h>

@class Person;
@class FaceLoader;

@interface SuspectCardView : UIControl
@property (strong, nonatomic, readonly) UIImageView *imageView;
@property (strong, nonatomic, readonly) UIButton *deleteButton;
@property (strong, nonatomic, readonly) UILabel *nameLabel;
@property (strong, nonatomic, readonly) UILabel *dateOfBirthLabel;
@property (strong, nonatomic, readonly) UILabel *systemIDLabel;
@property (strong, nonatomic, readonly) UILabel *heightLabel;
@property (strong, nonatomic, readonly) UILabel *weightLabel;
@property (strong, nonatomic, readonly) UILabel *raceLabel;
@property (strong, nonatomic, readonly) UILabel *hairLabel;
@property (strong, nonatomic, readonly) UILabel *eyesLabel;

- (void)configureWithPerson:(Person *)person faceLoader:(FaceLoader *)faceLoader;
@end
