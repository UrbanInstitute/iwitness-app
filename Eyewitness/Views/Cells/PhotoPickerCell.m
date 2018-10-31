#import "PhotoPickerCell.h"

@interface PhotoPickerCell ()

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UIImageView *selectionView;

@end

@implementation PhotoPickerCell

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    self.selectionView.hidden = !selected;
}

@end
