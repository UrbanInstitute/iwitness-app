#import "ObserveTouchesGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>
#import "TouchLatencyAggregator.h"

@interface ObservedTouch ()
@property (nonatomic, readwrite) CGPoint location;
@property (nonatomic) NSTimeInterval endTimestamp;
@property (nonatomic) NSTimeInterval decayLength;
@end

@implementation ObservedTouch
- (instancetype) init {
    if (self = [super init]) {
        self.endTimestamp = NAN;
    }
    return self;
}

- (float)decay {
    if (isnan(self.endTimestamp)) {
        return 0;
    }
    NSTimeInterval timeSinceEnd = [[NSProcessInfo processInfo] systemUptime]-self.endTimestamp;
    return MIN((timeSinceEnd)/self.decayLength, 1);
}

- (NSString *)description {
    return [[super description] stringByAppendingFormat:@" location: %@, decay: %g", NSStringFromCGPoint(self.location), self.decay];
}

@end


@interface ObserveTouchesGestureRecognizer () <UIGestureRecognizerDelegate>
@property (nonatomic, strong) NSMapTable *touches;
@property (nonatomic, strong) TouchLatencyAggregator *touchLatencyAggregator;
@end

@implementation ObserveTouchesGestureRecognizer

- (instancetype)initWithTarget:(id)target action:(SEL)action touchLatencyAggregator:(TouchLatencyAggregator *)touchLatencyAggregator {
    self = [super initWithTarget:target action:action];
    if (self) {
        self.touchLatencyAggregator = touchLatencyAggregator;

        self.cancelsTouchesInView = YES;
        self.delaysTouchesEnded = NO;
        self.delegate = self;
        
        self.touchLifetimeAfterEnding = 1;
        self.touches = [NSMapTable mapTableWithKeyOptions:(NSPointerFunctionsOpaqueMemory|NSPointerFunctionsObjectPointerPersonality) valueOptions:NSPointerFunctionsStrongMemory];
    }
    return self;
}

- (NSSet *)activeTouches {
    BOOL touchesDecayed = NO;
    
    NSMutableSet *touches = [[NSMutableSet alloc] init];
    for (ObservedTouch *touch in [self.touches objectEnumerator]) {
        if (touch.decay < 1) {
            [touches addObject:touch];
        }
        else {
            touchesDecayed = YES;
        }
    }
    
    if (touchesDecayed) {
        [self cleanupDecayedTouches];
    }
    return touches;
}

- (void)stopObservingTouches {
    NSLog(@"================> %@", [self.touchLatencyAggregator reportResults]);
}

#pragma mark - Private

- (void)storeTouch:(UITouch *)touch {
    ObservedTouch *observedTouch = [self.touches objectForKey:touch];
    if (!observedTouch) {
        observedTouch = [[ObservedTouch alloc] init];
        [self.touches setObject:observedTouch forKey:touch];
    }
    observedTouch.location = [touch locationInView:self.view];
}

- (void)finishTouch:(UITouch *)touch {
    ObservedTouch *observedTouch = [self.touches objectForKey:touch];
    observedTouch.endTimestamp = touch.timestamp;
    observedTouch.decayLength = self.touchLifetimeAfterEnding;
}

- (void)cleanupDecayedTouches {
    NSHashTable *decayedTouchKeys = [NSHashTable hashTableWithOptions:NSPointerFunctionsOpaqueMemory|NSHashTableObjectPointerPersonality];
    for (id touchKey in [self.touches keyEnumerator]) {
        ObservedTouch *touch = [self.touches objectForKey:touchKey];
        if (touch.decay >= 1) {
            [decayedTouchKeys addObject:touchKey];
        }
    }
    
    for (id touchKey in decayedTouchKeys) {
        [self.touches removeObjectForKey:touchKey];
    }
}

#pragma mark - Touch Handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    for (UITouch *touch in touches) {
        [self storeTouch:touch];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    for (UITouch *touch in touches) {
        [self storeTouch:touch];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    [self recordLatencyForTouches:touches];
    for (UITouch *touch in touches) {
        [self finishTouch:touch];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    [self recordLatencyForTouches:touches];
    for (UITouch *touch in touches) {
        [self finishTouch:touch];
    }
}

#pragma mark - Touch Latency

- (void)recordLatencyForTouches:(NSSet *)touches {
    NSTimeInterval touchTime = [[touches anyObject] timestamp];
    NSTimeInterval curTime = [[NSProcessInfo processInfo] systemUptime];
    [self.touchLatencyAggregator recordTouchLatency:(curTime - touchTime)];
}

#pragma mark - <UIGestureRecognizerDelegate>

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

@end
