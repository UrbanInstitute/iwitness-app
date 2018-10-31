#import "PerpetratorDescriptionViewController.h"
#import "PerpetratorAttributesTableViewController.h"
#import "PerpetratorDescription.h"

@interface PerpetratorDescriptionViewController ()
@property (nonatomic, strong) PerpetratorDescription *perpetratorDescription;
@property (nonatomic, copy) NSString *caseID;
@end

@implementation PerpetratorDescriptionViewController
//MOK Adds
@dynamic view;

- (void)configureWithCaseID:(NSString *)caseID perpetratorDescription:(PerpetratorDescription *)perpetratorDescription {
    self.caseID = caseID;
    self.perpetratorDescription = perpetratorDescription;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.caseIDLabel.text = self.caseID;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateDescriptionText];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.view.descriptionScrollView flashScrollIndicators];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];

    if ([segue.destinationViewController isKindOfClass:[PerpetratorAttributesTableViewController class]]) {
        [(PerpetratorAttributesTableViewController *)segue.destinationViewController configureWithCaseID:self.caseID
                                                                                  perpetratorDescription:self.perpetratorDescription];
    }
}

#pragma mark - Private

- (void)updateDescriptionText {
    if ([self.perpetratorDescription.additionalNotes length] > 0) {
        //MOK CHANGED
        self.view.descriptionLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@", nil), self.perpetratorDescription.additionalNotes];
    } else {
        self.view.descriptionLabel.text = @"";
    }
}

@end
