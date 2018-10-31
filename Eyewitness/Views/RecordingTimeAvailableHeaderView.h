#import <UIKit/UIKit.h>
#import "RecordingTimeAvailableCalculator.h"

@interface RecordingTimeAvailableHeaderView : UITableViewHeaderFooterView

@property (nonatomic) NSUInteger availableMinutes;
@property (nonatomic) RecordingTimeAvailableStatus timeAvailableStatus;

@end
