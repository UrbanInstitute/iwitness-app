#import "Presentation+SpecHelpers.h"
#import "Lineup.h"
#import "Person.h"
#import "Portrayal.h"
#import "NSURL+RelativeSandboxPaths.h"

@implementation Presentation (SpecHelpers)

- (instancetype)initFromSampleLineupWithSeed:(unsigned int)seed {
    return [self initWithLineup:[self buildSampleLineup] randomSeed:seed];
}

- (Lineup *)buildSampleLineup {
    NSArray *unorderedPhotoURLs = [[NSBundle bundleForClass:NSClassFromString(@"PresentationSpec")] URLsForResourcesWithExtension:@"jpg" subdirectory:@"SampleLineup"];
    NSArray *relativeUnorderedPhotoURLs = [unorderedPhotoURLs collect:^NSURL *(NSURL *url) {
        return [NSURL fileURLFromPathRelativeToApplicationSandbox:[url pathRelativeToApplicationSandbox]];
    }];

    Lineup *lineup = [[Lineup alloc] initWithCreationDate:[NSDate date] suspect:[[Person alloc] init]];
    lineup.caseID = @"987654321";
    lineup.suspect.portrayals = @[[[Portrayal alloc] initWithPhotoURL:relativeUnorderedPhotoURLs.firstObject date:[NSDate date]]];
    lineup.fillerPhotosFileURLs = [relativeUnorderedPhotoURLs subarrayWithRange:NSMakeRange(1, unorderedPhotoURLs.count - 1)];
    return lineup;
}

@end
