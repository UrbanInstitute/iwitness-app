#import "SuspectPortrayalCell.h"
#import "Portrayal.h"

@implementation SuspectPortrayalCell

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    self.selectionView.hidden = !selected;
}

- (void)configureWithPortrayal:(Portrayal *)portrayal {
    NSString *dateString = [self.dateFormatter stringFromDate:portrayal.date];

    self.dateLabel.text = dateString;
    self.accessibilityLabel = [NSString stringWithFormat:@"Portrayal from: %@", dateString];

    [[portrayal getPhotoURLData] then:^id(NSData *photoData) {
        self.imageView.image = [UIImage imageWithData:photoData];
        return nil;
    } error:^id(NSError *error) {
        self.imageView.image = [UIImage imageNamed:@"PhotoPlaceholder"];
        return nil;
    }];
}

#pragma mark - private

- (NSDateFormatter *)dateFormatter {
    static NSDateFormatter *dateFormatter_;
    if (!dateFormatter_) {
        dateFormatter_ = [[NSDateFormatter alloc] init];
        [dateFormatter_ setDateFormat:@"M/d/yyyy"];
    }
    return dateFormatter_;
}
@end
