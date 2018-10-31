#import <Foundation/Foundation.h>

@class LineupStore, Lineup, PhotoAssetImporter, LineupViewController;
@protocol LineupViewControllerDelegate;

@interface LineupViewControllerConfigurer : NSObject

- (instancetype)initWithLineupStore:(LineupStore *)lineupStore
                 photoAssetImporter:(PhotoAssetImporter *)photoAssetImporter
                           delegate:(id<LineupViewControllerDelegate>)delegate;

- (void) configureLineupViewControllerForLineupCreation:(LineupViewController *)lineupViewController;
- (void) configureLineupViewController:(LineupViewController *)lineupViewController forEditingLineup:(Lineup *)lineup;
@end
