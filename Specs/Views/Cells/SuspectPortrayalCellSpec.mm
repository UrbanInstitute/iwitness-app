#import "SuspectPortrayalCell.h"
#import "Portrayal.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(SuspectPortrayalCellSpec)

describe(@"SuspectPortrayalCell", ^{
    NSURL *portrayalPhotoURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"cathy" withExtension:@"jpg" subdirectory:@"SampleLineup"];
    __block SuspectPortrayalCell *cell;
    __block Portrayal *portrayal;
    __block KSDeferred *getPhotoDataDeferred;

    void(^createCellAndAssignOutlets)() = ^{
        cell = [[SuspectPortrayalCell alloc] init];
        UILabel *label = [[UILabel alloc] init];
        [cell addSubview:label];
        [cell performSelector:@selector(setDateLabel:) withObject:label];

        UIImageView *imageView = [[UIImageView alloc] init];
        [cell addSubview:imageView];
        [cell performSelector:@selector(setImageView:) withObject:imageView];
    };

    beforeEach(^{
        createCellAndAssignOutlets();

        portrayal = [[Portrayal alloc] initWithPhotoURL:portrayalPhotoURL date:[NSDate dateWithTimeIntervalSince1970:999912345]];
        spy_on(portrayal);

        getPhotoDataDeferred = [KSDeferred defer];
        portrayal stub_method(@selector(getPhotoURLData)).and_return(getPhotoDataDeferred.promise);
        [cell configureWithPortrayal:portrayal];
    });
    
    it(@"should show the portrayal date", ^{
        cell.dateLabel.text should equal(@"9/7/2001");
    });

    it(@"should set the accessibility label of the cell", ^{
        cell.accessibilityLabel should equal(@"Portrayal from: 9/7/2001");
    });
    
    it(@"should ask the portrayal for the image data", ^{
        portrayal should have_received(@selector(getPhotoURLData));
    });

    describe(@"when loading the image fails", ^{
        beforeEach(^{
            [getPhotoDataDeferred rejectWithError:nil];
        });

        it(@"should display the placeholder", ^{
            [cell.imageView.image isEqualToByBytes:[UIImage imageNamed:@"PhotoPlaceholder"]] should be_truthy;
        });
    });

    describe(@"when loading the image data succeeds", ^{
        NSData *imageData = [NSData dataWithContentsOfURL:portrayalPhotoURL];

        beforeEach(^{
            [getPhotoDataDeferred resolveWithValue:imageData];
        });
        
        it(@"should display the image", ^{
            [cell.imageView.image isEqualToByBytes:[UIImage imageWithData:imageData]] should be_truthy;
        });
    });
});

SPEC_END
