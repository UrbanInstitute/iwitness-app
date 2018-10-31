#import "SuspectPhotoDetailViewController.h"
#import "Person.h"
#import "Portrayal.h"
#import "SuspectPhotoDetailViewControllerDelegate.h"
#import "AlertView.h"

@interface SuspectPhotoDetailViewController ()
@property (weak, nonatomic, readwrite) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic, readwrite) IBOutlet UIButton *selectSuspectPhotoButton;
@property (nonatomic, strong) id <SuspectPhotoDetailViewControllerDelegate> delegate;
@property (weak, nonatomic, readwrite) IBOutlet UIImageView *portrayalImageView;
@property (weak, nonatomic, readwrite) IBOutlet UILabel *captionLabel;
@property (nonatomic, strong) Portrayal *portrayal;
@property (nonatomic, strong) Person *person;
@end

@implementation SuspectPhotoDetailViewController

- (void)configureWithDelegate:(id<SuspectPhotoDetailViewControllerDelegate>)delegate person:(Person *)person portrayal:(Portrayal *)portrayal {
    self.delegate = delegate;
    self.portrayal = portrayal;
    self.person = person;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"M/d/yyyy";
    self.captionLabel.text = [NSString stringWithFormat:@"%@. Photo taken %@", self.person.fullName, [dateFormatter stringFromDate:self.portrayal.date]];

    [self.portrayal.getPhotoURLData then:^id(NSData *imageData) {
        self.selectSuspectPhotoButton.enabled = YES;
        self.portrayalImageView.image = [UIImage imageWithData:imageData];
        return nil;
    } error:^id(NSError *error) {
        [[[AlertView alloc] initWithTitle:NSLocalizedString(@"Server Error", nil)
                                  message:NSLocalizedString(@"There was an error loading the image from the server.", nil)
                        cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                        otherButtonTitles:@[]
                            cancelHandler:^{
                                [self.delegate suspectPhotoDetailViewControllerDidCancel:self];
                            }
                      confirmationHandler:nil] show];
        return nil;
    }];
}

- (IBAction)cancelButtonTapped:(UIButton *)sender {
    [self.delegate suspectPhotoDetailViewControllerDidCancel:self];
}

- (IBAction)selectSuspectPhotoButtonTapped:(UIButton *)sender {
    [self.delegate suspectPhotoDetailViewController:self didSelectPortrayal:self.portrayal];
}
@end
