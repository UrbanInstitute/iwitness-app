#import "RecordingTimeAvailableFormatter.h"

@implementation RecordingTimeAvailableFormatter

- (NSString *)stringFromTimeAvailable:(NSTimeInterval)timeAvailable {
    if (timeAvailable/60/60 > 1.f) {
        return @"More than an hour";
    }
    NSUInteger hoursComponent = timeAvailable/60/60;
    NSUInteger minutesComponent = (timeAvailable/60)-(hoursComponent*60);

    NSMutableArray *stringComponents = [[NSMutableArray alloc] init];
    if (hoursComponent > 0) {
        [stringComponents addObject:({
            NSMutableString *hourString = [[NSMutableString alloc] init];
            [hourString appendString:[NSString localizedStringWithFormat:@"%lu", (unsigned long)hoursComponent]];
            if (self.fullMode) {
                [hourString appendFormat:@" %@", (hoursComponent==1 ? NSLocalizedString(@"hour", nil) : NSLocalizedString(@"hours", nil))];
            } else {
                [hourString appendString:NSLocalizedString(@"h", @"Abbreviation for hour")];
            }
            hourString;
        })];
    }

    if (minutesComponent || hoursComponent==0) {
        [stringComponents addObject:({
            NSMutableString *minuteString = [[NSMutableString alloc] init];
            [minuteString appendString:[NSString localizedStringWithFormat:@"%lu", (unsigned long)minutesComponent]];
            if (self.fullMode) {
                [minuteString appendFormat:@" %@", (minutesComponent==1 ? NSLocalizedString(@"minute", nil) : NSLocalizedString(@"minutes", nil))];
            } else {
                [minuteString appendString:NSLocalizedString(@"m", @"Abbreviation for minute")];
            }
            minuteString;
        })];
    }

    return [stringComponents componentsJoinedByString:@" "];
}

- (NSString *)stringForObjectValue:(id)obj {
    if ([obj respondsToSelector:@selector(doubleValue)]) {
        return [self stringFromTimeAvailable:[obj doubleValue]];
    } else {
        return nil;
    }
}

@end
