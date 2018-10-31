#import <UIKit/UIKit.h>

@interface ObservedTouch : NSObject
@property (nonatomic, readonly) CGPoint location;
@property (nonatomic, readonly) float decay;
@end

@class TouchLatencyAggregator;

@interface ObserveTouchesGestureRecognizer : UIGestureRecognizer

@property (nonatomic) NSTimeInterval touchLifetimeAfterEnding;

- (instancetype)initWithTarget:(id)target action:(SEL)action touchLatencyAggregator:(TouchLatencyAggregator *)touchLatencyAggregator;
- (NSSet *) activeTouches;
- (void)stopObservingTouches;

@end
