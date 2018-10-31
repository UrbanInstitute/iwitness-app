@class LineupPhotoCell;

@protocol LineupPhotoCellDelegate <NSObject>
- (void)lineupPhotoCellDidDelete:(LineupPhotoCell *)cell;
@end

