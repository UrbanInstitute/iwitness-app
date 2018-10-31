#import "LineupCell.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(LineupCellSpec)

describe(@"LineupCell", ^{
    __block LineupCell *cell;
    __block id<LineupCellDelegate> delegate;

    beforeEach(^{
        cell = [[LineupCell alloc] initWithFrame:CGRectMake(0, 0, 1024, 88)];
        delegate = nice_fake_for(@protocol(LineupCellDelegate));
        [cell setValue:delegate forKey:@"delegate"];
    });

    describe(@"when loaded with its view hierarchy", ^{
        beforeEach(^{
            UIButton *presentToWitnessButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
            UIButton *previewButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
            UIButton *editButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];

            [cell.contentView addSubview:presentToWitnessButton];
            [cell.contentView addSubview:previewButton];
            [cell.contentView addSubview:editButton];

            [cell setValue:presentToWitnessButton forKey:@"presentToWitnessButton"];
            [cell setValue:previewButton forKey:@"previewButton"];
            [cell setValue:editButton forKey:@"editButton"];

            [presentToWitnessButton addTarget:cell action:NSSelectorFromString(@"presentToWitnessButtonTapped") forControlEvents:UIControlEventTouchUpInside];
            [previewButton addTarget:cell action:NSSelectorFromString(@"previewButtonTapped") forControlEvents:UIControlEventTouchUpInside];
            [editButton addTarget:cell action:NSSelectorFromString(@"editButtonTapped") forControlEvents:UIControlEventTouchUpInside];

            [cell awakeFromNib];
        });

        it(@"should not show its action buttons initially", ^{
            cell.editButton.alpha should equal(0);
            cell.previewButton.alpha should equal(0);
            cell.presentToWitnessButton.alpha should equal(0);
        });

        context(@"the cell is selected", ^{
            beforeEach(^{
                cell.selected = YES;
            });

            it(@"should show its action buttons", ^{
                cell.editButton.alpha should equal(1);
                cell.previewButton.alpha should equal(1);
                cell.presentToWitnessButton.alpha should equal(1);
            });
        });

        context(@"the cell is deselected", ^{
            beforeEach(^{
                cell.selected = YES;
                cell.selected = NO;
            });

            it(@"should not show its action buttons", ^{
                cell.editButton.alpha should equal(0);
                cell.previewButton.alpha should equal(0);
                cell.presentToWitnessButton.alpha should equal(0);
            });
        });

        describe(@"tapping the action buttons", ^{
            beforeEach(^{
                cell.selected = YES;
            });

            describe(@"when the Present to Witness button is tapped", ^{
                beforeEach(^{
                    [cell.presentToWitnessButton tap];
                });
                it(@"should notify the delegate for editing", ^{
                    delegate should have_received(@selector(lineupCellDidRequestPresentation:));
                });
            });

            describe(@"when the Edit button is tapped", ^{
                beforeEach(^{
                    [cell.editButton tap];
                });
                it(@"should notify the delegate for editing", ^{
                    delegate should have_received(@selector(lineupCellDidRequestEditing:));
                });
            });
        });
    });
});

SPEC_END
