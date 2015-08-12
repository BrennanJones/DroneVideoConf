//
//  ManualOverrideViewController.m
//  DVC-InvestigatorClient-iOS
//


#import "ManualOverrideViewController.h"

#import "DVCTabBarController.h"


@interface ManualOverrideViewController ()

@property (nonatomic, strong) DVCTabBarController *dvcTabBarController;

@end


@implementation ManualOverrideViewController

#pragma mark Initialization Methods

- (void)loadView
{
    [super loadView];
    NSLog(@"ManualOverrideViewController: loadView ...");
    
    _dvcTabBarController = (DVCTabBarController *)(self.tabBarController);
    
    for (UIViewController *viewController in self.tabBarController.viewControllers)
    {
        if ([viewController isKindOfClass:[MainViewController class]])
        {
            [(MainViewController *)viewController setServerConnectionDelegate:self];
            [(MainViewController *)viewController setManualOverrideStateDelegate:self];
            [(MainViewController *)viewController setDroneStateDelegate:self];
        }
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"ManualOverrideViewController: viewDidLoad ...");
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSLog(@"ManualOverrideViewController: viewWillAppear ... ");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tabBarController.tabBar setBarStyle:UIBarStyleDefault];
        [self.tabBarController.tabBar setTranslucent:NO];
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark ServerConnectionDelegate

- (void)onConnectToServer:(NSString *)serverURL
{
    NSLog(@"ManualOverrideViewController: onConnectToServer ...");
}

- (void)onDisconnectFromServer
{
    NSLog(@"ManualOverrideViewController: onDisconnectFromServer ...");
    
    _takeoffBt.enabled = false;
    _landingBt.enabled = false;
    _emergencyBt.enabled = false;
    
    _manualOverrideSwitch.on = false;
    _manualOverrideSwitch.enabled = false;
    [_manualOverrideStateChangeIndicator stopAnimating];
    
    _rollForwardButton.enabled = false;
    _rollBackButton.enabled = false;
    _rollLeftButton.enabled = false;
    _rollRightButton.enabled = false;
    _yawUpButton.enabled = false;
    _yawDownButton.enabled = false;
    _yawLeftButton.enabled = false;
    _yawRightButton.enabled = false;
}


#pragma mark ManualOverrideStateDelegate

- (void)onManualOverrideStateChanged:(BOOL)newState
{
    NSLog(@"ManualOverrideViewController: onManualOverrideStateChanged: %d", newState);
    
    [_manualOverrideStateChangeIndicator stopAnimating];
    _manualOverrideSwitch.on = newState;
    _manualOverrideSwitch.enabled = true;
    
    _rollForwardButton.enabled = _manualOverrideSwitch.on;
    _rollBackButton.enabled = _manualOverrideSwitch.on;
    _rollLeftButton.enabled = _manualOverrideSwitch.on;
    _rollRightButton.enabled = _manualOverrideSwitch.on;
    _yawUpButton.enabled = _manualOverrideSwitch.on;
    _yawDownButton.enabled = _manualOverrideSwitch.on;
    _yawLeftButton.enabled = _manualOverrideSwitch.on;
    _yawRightButton.enabled = _manualOverrideSwitch.on;
}


#pragma mark UI Event Handler Methods

- (IBAction)emergencyClick:(id)sender
{
    NSArray *args = [[NSArray alloc] initWithObjects:@"Emergency", nil];
    [_dvcTabBarController.socket emit:@"InvestigatorCommand" withItems:args];
}

- (IBAction)takeoffClick:(id)sender
{
    NSArray *args = [[NSArray alloc] initWithObjects:@"Takeoff", nil];
    [_dvcTabBarController.socket emit:@"InvestigatorCommand" withItems:args];
}

- (IBAction)landingClick:(id)sender
{
    NSArray *args = [[NSArray alloc] initWithObjects:@"Land", nil];
    [_dvcTabBarController.socket emit:@"InvestigatorCommand" withItems:args];
}

- (IBAction)manualOverrideSwitchValueChanged:(id)sender
{
    NSArray *args = [[NSArray alloc] initWithObjects:[NSNumber numberWithBool:_manualOverrideSwitch.on], nil];
    [_dvcTabBarController.socket emit:@"ManualOverrideStateRequestChange" withItems:args];
    
    _manualOverrideSwitch.enabled = false;
    [_manualOverrideStateChangeIndicator startAnimating];
}

- (IBAction)returnToHomeClick:(id)sender
{
    NSArray *args = [[NSArray alloc] initWithObjects:@"ReturnToHome", nil];
    [_dvcTabBarController.socket emit:@"ManualOverrideCommand" withItems:args];
}

- (IBAction)rollForwardTouchDown:(id)sender
{
    NSArray *args = [[NSArray alloc] initWithObjects:@"RollForwardStart", nil];
    [_dvcTabBarController.socket emit:@"ManualOverrideCommand" withItems:args];
}

- (IBAction)rollBackTouchDown:(id)sender
{
    NSArray *args = [[NSArray alloc] initWithObjects:@"RollBackStart", nil];
    [_dvcTabBarController.socket emit:@"ManualOverrideCommand" withItems:args];
}

- (IBAction)rollLeftTouchDown:(id)sender
{
    NSArray *args = [[NSArray alloc] initWithObjects:@"RollLeftStart", nil];
    [_dvcTabBarController.socket emit:@"ManualOverrideCommand" withItems:args];
}

- (IBAction)rollRightTouchDown:(id)sender
{
    NSArray *args = [[NSArray alloc] initWithObjects:@"RollRightStart", nil];
    [_dvcTabBarController.socket emit:@"ManualOverrideCommand" withItems:args];
}

- (IBAction)yawUpTouchDown:(id)sender
{
    NSArray *args = [[NSArray alloc] initWithObjects:@"YawUpStart", nil];
    [_dvcTabBarController.socket emit:@"ManualOverrideCommand" withItems:args];
}

- (IBAction)yawDownTouchDown:(id)sender
{
    NSArray *args = [[NSArray alloc] initWithObjects:@"YawDownStart", nil];
    [_dvcTabBarController.socket emit:@"ManualOverrideCommand" withItems:args];
}

- (IBAction)yawLeftTouchDown:(id)sender
{
    NSArray *args = [[NSArray alloc] initWithObjects:@"YawLeftStart", nil];
    [_dvcTabBarController.socket emit:@"ManualOverrideCommand" withItems:args];
}

- (IBAction)yawRightTouchDown:(id)sender
{
    NSArray *args = [[NSArray alloc] initWithObjects:@"YawRightStart", nil];
    [_dvcTabBarController.socket emit:@"ManualOverrideCommand" withItems:args];
}

- (IBAction)rollForwardTouchUp:(id)sender
{
    NSArray *args = [[NSArray alloc] initWithObjects:@"RollForwardEnd", nil];
    [_dvcTabBarController.socket emit:@"ManualOverrideCommand" withItems:args];
}

- (IBAction)rollBackTouchUp:(id)sender
{
    NSArray *args = [[NSArray alloc] initWithObjects:@"RollBackEnd", nil];
    [_dvcTabBarController.socket emit:@"ManualOverrideCommand" withItems:args];
}

- (IBAction)rollLeftTouchUp:(id)sender
{
    NSArray *args = [[NSArray alloc] initWithObjects:@"RollLeftEnd", nil];
    [_dvcTabBarController.socket emit:@"ManualOverrideCommand" withItems:args];
}

- (IBAction)rollRightTouchUp:(id)sender
{
    NSArray *args = [[NSArray alloc] initWithObjects:@"RollRightEnd", nil];
    [_dvcTabBarController.socket emit:@"ManualOverrideCommand" withItems:args];
}

- (IBAction)yawUpTouchUp:(id)sender
{
    NSArray *args = [[NSArray alloc] initWithObjects:@"YawUpEnd", nil];
    [_dvcTabBarController.socket emit:@"ManualOverrideCommand" withItems:args];
}

- (IBAction)yawDownTouchUp:(id)sender
{
    NSArray *args = [[NSArray alloc] initWithObjects:@"YawDownEnd", nil];
    [_dvcTabBarController.socket emit:@"ManualOverrideCommand" withItems:args];
}

- (IBAction)yawLeftTouchUp:(id)sender
{
    NSArray *args = [[NSArray alloc] initWithObjects:@"YawLeftEnd", nil];
    [_dvcTabBarController.socket emit:@"ManualOverrideCommand" withItems:args];
}

- (IBAction)yawRightTouchUp:(id)sender
{
    NSArray *args = [[NSArray alloc] initWithObjects:@"YawRightEnd", nil];
    [_dvcTabBarController.socket emit:@"ManualOverrideCommand" withItems:args];
}


#pragma mark DroneStateDelegate

- (void)onDroneConnectionUpdate:(BOOL)newState;
{
    if (newState)
    {
        _takeoffBt.enabled = true;
        _landingBt.enabled = true;
        _emergencyBt.enabled = true;
    }
    else
    {
        _takeoffBt.enabled = false;
        _landingBt.enabled = false;
        _emergencyBt.enabled = false;
    }
}

- (void)onDroneBatteryUpdate:(BOOL)newPercentage
{
    // ...
}

@end
