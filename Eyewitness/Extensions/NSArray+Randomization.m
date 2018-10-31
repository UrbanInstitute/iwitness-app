#import "NSArray+Randomization.h"

@implementation NSArray (Randomization)

- (NSArray *)randomizedArrayWithRandomSeed:(unsigned)randomSeed {
    srandom(randomSeed);
    NSMutableArray *unorderedArray = [self mutableCopy];
    NSMutableArray *randomizedArray = [[NSMutableArray alloc] initWithCapacity:[unorderedArray count]];

    while ([unorderedArray count] > 0) {
        long randomIndex = random()%[unorderedArray count];
        [randomizedArray addObject:unorderedArray[randomIndex]];
        [unorderedArray removeObjectAtIndex:randomIndex];
    }
    return randomizedArray;
}

@end
