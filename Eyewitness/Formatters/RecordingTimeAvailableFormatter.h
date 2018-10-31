#import <Foundation/Foundation.h>

@interface RecordingTimeAvailableFormatter : NSFormatter

@property (nonatomic) BOOL fullMode;

- (NSString *)stringFromTimeAvailable:(NSTimeInterval)timeAvailable;

@end
