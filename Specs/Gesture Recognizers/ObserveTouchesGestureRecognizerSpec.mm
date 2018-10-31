#import "ObserveTouchesGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>
#import "TouchLatencyAggregator.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(ObserveTouchesGestureRecognizerSpec)

describe(@"ObserveTouchesGestureRecognizer", ^{
    __block ObserveTouchesGestureRecognizer *recognizer;
    __block TouchLatencyAggregator *touchLatencyAggregator;

    beforeEach(^{
        touchLatencyAggregator = nice_fake_for([TouchLatencyAggregator class]);

        recognizer = [[ObserveTouchesGestureRecognizer alloc] initWithTarget:nil action:nil touchLatencyAggregator:touchLatencyAggregator];
        recognizer.touchLifetimeAfterEnding = 0.1;
    });
    
    describe(@"when a touch begins", ^{
        __block UITouch *touch;
        __block CGPoint touchLocationInView;
        __block NSTimeInterval touchTimestamp;
        
        beforeEach(^{
            touch = nice_fake_for([UITouch class]);
            touch stub_method(@selector(locationInView:)).and_do_block(^CGPoint(UIView *view){
               return touchLocationInView;
            });

            touch stub_method(@selector(timestamp)).and_do_block(^NSTimeInterval{
                return touchTimestamp;
            });

            touchLocationInView = CGPointMake(50, 50);
            touchTimestamp = [[NSProcessInfo processInfo] systemUptime];
            
            [recognizer touchesBegan:[NSSet setWithObject:touch] withEvent:nice_fake_for([UIEvent class])];
        });
        
        it(@"should include the touch in the set of active touches, with no decay", ^{
            ObservedTouch *observedTouch = [[recognizer activeTouches] anyObject];
            observedTouch.location should equal(CGPointMake(50, 50));
            observedTouch.decay should equal(0);
        });
        
        describe(@"when a second touch begins", ^{
            __block UITouch *otherTouch;
            beforeEach(^{
                otherTouch = nice_fake_for([UITouch class]);
                otherTouch stub_method(@selector(locationInView:)).and_return(CGPointMake(100, 100));
                [recognizer touchesBegan:[NSSet setWithObject:otherTouch] withEvent:nice_fake_for([UIEvent class])];
            });
            
            it(@"should include both touches in the set of active touches", ^{
                [[recognizer activeTouches] count] should equal(2);
            });
        });
        
        describe(@"when the touch moves", ^{
            beforeEach(^{
                touchLocationInView = CGPointMake(100, 100);
                [recognizer touchesMoved:[NSSet setWithObject:touch] withEvent:nice_fake_for([UIEvent class])];
            });
            
            it(@"should include the touch in the set of active touches with the new location", ^{
                ObservedTouch *observedTouch = [[recognizer activeTouches] anyObject];
                observedTouch.location should equal(CGPointMake(100, 100));
            });
        });
        
        describe(@"when the touch ends", ^{
            beforeEach(^{
                [recognizer touchesEnded:[NSSet setWithObject:touch] withEvent:nice_fake_for([UIEvent class])];
            });
            
            it(@"should include the touch in the set of active touches with a non-zero decay", ^{
                ObservedTouch *observedTouch = [[recognizer activeTouches] anyObject];
                observedTouch.decay should_not equal(0);
            });

            it(@"should record the touch latency", ^{
                touchLatencyAggregator should have_received(@selector(recordTouchLatency:));
            });
            
            describe(@"when the touch has fully decayed", ^{
                beforeEach(^{
                    [NSThread sleepForTimeInterval:recognizer.touchLifetimeAfterEnding];
                });
                
                it(@"should not include the touch in the set of active touches", ^{
                    [[recognizer activeTouches] count] should equal(0);
                });
            });
        });

        describe(@"stopping touch observation", ^{
            beforeEach(^{
                [recognizer stopObservingTouches];
            });

            it(@"should tell the touch latency aggregator to report its results", ^{
                touchLatencyAggregator should have_received(@selector(reportResults));
            });
        });
    });
});

SPEC_END
