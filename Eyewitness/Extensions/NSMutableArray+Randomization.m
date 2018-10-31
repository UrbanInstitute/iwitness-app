#import "NSMutableArray+Randomization.h"

@implementation NSMutableArray (Randomization)

- (void) insertObject:(id)object atRandomIndexInRange:(NSRange)insertionRange randomSeed:(unsigned)randomSeed {
    srandom(randomSeed);
    if (insertionRange.length == 0) {
        [self insertObject:object atIndex:insertionRange.location];
    }
    else {
        long insertionIndex = random()%insertionRange.length + insertionRange.location;
        [self insertObject:object atIndex:insertionIndex];
    }
}

@end
