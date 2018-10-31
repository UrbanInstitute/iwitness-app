@protocol LineupPhotoCellDelegate;

@interface LineupPhotoCell : UICollectionViewCell

@property (nonatomic, weak, readonly) UIImageView *imageView;
@property (nonatomic, weak, readonly) UIButton *deleteButton;

@property (nonatomic, assign, getter = isEditing) BOOL editing;

- (void)configureWithDelegate:(id<LineupPhotoCellDelegate>)delegate;

@end
