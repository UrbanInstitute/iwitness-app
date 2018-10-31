#import "LineupPerpetratorDescriptionViewController.h"
#import "FBTweakInline.h"
#import "PerpetratorDescription.h"
#import "PerpetratorDescriptionViewControllerProvider.h"
#import "PerpetratorDescriptionViewController.h"
#import "Lineup.h"

@interface LineupPerpetratorDescriptionViewController ()
@property (weak, nonatomic, readwrite) IBOutlet UIButton *addDescriptionButton;
@property (weak, nonatomic, readwrite) IBOutlet UILabel *perpetratorDescriptionLabel;
@property (nonatomic, strong) PerpetratorDescriptionViewControllerProvider *perpetratorDescriptionViewControllerProvider;
@property (weak, nonatomic) IBOutlet UIScrollView *perpetratorDescriptionScrollView;
@property (nonatomic, strong) Lineup *lineup;
@end

@implementation LineupPerpetratorDescriptionViewController

- (void)configureWithLineup:(Lineup *)lineup perpetratorDescriptionViewControllerProvider:(PerpetratorDescriptionViewControllerProvider *)perpetratorDescriptionViewControllerProvider {
    self.lineup = lineup;
    self.perpetratorDescriptionViewControllerProvider = perpetratorDescriptionViewControllerProvider;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateAdditionalDescription];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.perpetratorDescriptionScrollView flashScrollIndicators];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    if(!editing) {
        [self updateAdditionalDescription];
    }
    self.addDescriptionButton.hidden = !editing;
}

- (IBAction)addDescriptionTapped:(UIButton *)sender {
    PerpetratorDescriptionViewController *perpetratorDescriptionViewController = [self.perpetratorDescriptionViewControllerProvider perpetratorDescriptionViewControllerWithCaseID:self.lineup.caseID perpetratorDescription:self.lineup.perpetratorDescription];
    [self.navigationController pushViewController:perpetratorDescriptionViewController animated:YES];
}

#pragma mark - Private

- (void)updateAdditionalDescription {
    NSString *additionalDescription = self.lineup.perpetratorDescription.additionalNotes;
    if(additionalDescription && additionalDescription.length > 0) {
        //MOK CHANGES //self.perpetratorDescriptionLabel.text = [NSString stringWithFormat:@"Witness said:\n“%@”", additionalDescription];
        self.perpetratorDescriptionLabel.text = [NSString stringWithFormat:@"%@", additionalDescription];
    } else {
        self.perpetratorDescriptionLabel.text = @"";
    }
}

@end
