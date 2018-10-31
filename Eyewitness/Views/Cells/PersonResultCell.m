#import "PersonResultCell.h"
#import "SuspectCardView.h"
#import "Person.h"
#import "FaceLoader.h"

@interface PersonResultCell ()
@property(nonatomic, weak, readwrite) SuspectCardView *suspectCardView;
@end

@implementation PersonResultCell

- (void)configureWithPerson:(Person *)person faceLoader:(FaceLoader *)faceLoader {
    [self.suspectCardView configureWithPerson:person faceLoader:faceLoader];
}

- (SuspectCardView *)suspectCardView {
    if (!_suspectCardView) {
        SuspectCardView *portrayalView = [[SuspectCardView alloc] init];
        [self.contentView addSubview:portrayalView];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:portrayalView
                                                         attribute:NSLayoutAttributeTop
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self.contentView
                                                         attribute:NSLayoutAttributeTop
                                                        multiplier:1
                                                          constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:portrayalView
                                                         attribute:NSLayoutAttributeLeft
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self.contentView
                                                         attribute:NSLayoutAttributeLeft
                                                        multiplier:1
                                                          constant:0]];
        _suspectCardView = portrayalView;
    }
    return _suspectCardView;
}
@end
