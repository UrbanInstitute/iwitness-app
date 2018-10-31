@class LineupCell;
@protocol LineupCellDelegate <NSObject>
- (void)lineupCellDidRequestEditing:(LineupCell *)cell;
- (void)lineupCellDidRequestPresentation:(LineupCell *)cell;
@end

@interface LineupCell : UITableViewCell
@property (nonatomic, copy) NSString *caseID;
@property (nonatomic, copy) NSString *dateString;

@property (nonatomic, weak, readonly) UIButton *editButton;
@property (nonatomic, weak, readonly) UIButton *previewButton;
@property (nonatomic, weak, readonly) UIButton *presentToWitnessButton;

@end
