#import <Foundation/Foundation.h>

@interface NSMutableArray (Randomization)

- (void) insertObject:(id)object atRandomIndexInRange:(NSRange)insertionRange randomSeed:(unsigned)randomSeed;

@end
