//
//  ManualOverrideViewController.h
//  DVC-InvestigatorClient-iOS
//


#import <UIKit/UIKit.h>

#import "MainViewController.h"


@interface ManualOverrideViewController : UIViewController <ServerConnectionDelegate, ManualOverrideStateDelegate, DroneStateDelegate>

@property (nonatomic, strong) IBOutlet UIButton *takeoffBt;
@property (nonatomic, strong) IBOutlet UIButton *landingBt;
@property (strong, nonatomic) IBOutlet UIButton *emergencyBt;

@property (strong, nonatomic) IBOutlet UISwitch *manualOverrideSwitch;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *manualOverrideStateChangeIndicator;

@property (strong, nonatomic) IBOutlet UIButton *rollForwardButton;
@property (strong, nonatomic) IBOutlet UIButton *rollBackButton;
@property (strong, nonatomic) IBOutlet UIButton *rollLeftButton;
@property (strong, nonatomic) IBOutlet UIButton *rollRightButton;
@property (strong, nonatomic) IBOutlet UIButton *yawUpButton;
@property (strong, nonatomic) IBOutlet UIButton *yawDownButton;
@property (strong, nonatomic) IBOutlet UIButton *yawLeftButton;
@property (strong, nonatomic) IBOutlet UIButton *yawRightButton;


- (IBAction)emergencyClick:(id)sender;
- (IBAction)takeoffClick:(id)sender;
- (IBAction)landingClick:(id)sender;

- (IBAction)manualOverrideSwitchValueChanged:(id)sender;

- (IBAction)returnToHomeClick:(id)sender;

- (IBAction)rollForwardTouchDown:(id)sender;
- (IBAction)rollBackTouchDown:(id)sender;
- (IBAction)rollLeftTouchDown:(id)sender;
- (IBAction)rollRightTouchDown:(id)sender;
- (IBAction)yawUpTouchDown:(id)sender;
- (IBAction)yawDownTouchDown:(id)sender;
- (IBAction)yawLeftTouchDown:(id)sender;
- (IBAction)yawRightTouchDown:(id)sender;

- (IBAction)rollForwardTouchUp:(id)sender;
- (IBAction)rollBackTouchUp:(id)sender;
- (IBAction)rollLeftTouchUp:(id)sender;
- (IBAction)rollRightTouchUp:(id)sender;
- (IBAction)yawUpTouchUp:(id)sender;
- (IBAction)yawDownTouchUp:(id)sender;
- (IBAction)yawLeftTouchUp:(id)sender;
- (IBAction)yawRightTouchUp:(id)sender;

@end
