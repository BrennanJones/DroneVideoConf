//
//  MainViewController.m
//  DVC-InvestigatorClient-iOS
//


#import "MainViewController.h"

#import "DVCTabBarController.h"
#import "Utility.h"


#define TAG "MainViewController"


@interface MainViewController ()

@property (nonatomic, strong) DVCTabBarController *dvcTabBarController;

@property (nonatomic, strong) UIColor *dvcRed;
@property (nonatomic, strong) UIColor *dvcGreen;

@end


@implementation MainViewController

@synthesize batteryLabel = _batteryLabel;


#pragma mark Initialization Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"MainViewController: viewDidLoad ...");
    
    _dvcTabBarController = (DVCTabBarController *)(self.tabBarController);
    
    _dvcRed = [UIColor colorWithRed:0.8 green:0.2 blue:0.2 alpha:1.0];
    _dvcGreen = [UIColor colorWithRed:0.2 green:0.8 blue:0.0 alpha:1];
    
    self.droneConnectionStatusLabel.text = @"Not connected";
    self.droneConnectionStatusLabel.textColor = _dvcRed;
    
    [self registerApplicationNotifications];
    
    [self connectToServerClick:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSLog(@"MainViewController: viewWillAppear ... ");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tabBarController.tabBar setBarStyle:UIBarStyleDefault];
        [self.tabBarController.tabBar setTranslucent:NO];
    });
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSLog(@"MainViewController: viewDidAppear ... ");
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    NSLog(@"MainViewController: viewDidDisappear ... ");
}

- (void)viewWillUnload
{
    [super viewWillUnload];
    NSLog(@"MainViewController: viewWillUnload ... ");
    
    [self unregisterApplicationNotifications];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self disconnectFromServer];
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)registerApplicationNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enteredBackground:) name: UIApplicationDidEnterBackgroundNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterForeground:) name: UIApplicationWillEnterForegroundNotification object: nil];
}

- (void)unregisterApplicationNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name: UIApplicationDidEnterBackgroundNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name: UIApplicationWillEnterForegroundNotification object: nil];
}

- (void)enteredBackground:(NSNotification*)notification
{
    NSLog(@"MainViewController: enteredBackground ... ");
}

- (void)enterForeground:(NSNotification*)notification
{
    NSLog(@"MainViewController: enterForeground ... ");
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    return YES;
}


#pragma mark Server Connection Methods

- (void)connectToServer:(NSString *)address
{
    _dvcTabBarController.socket = [[SocketIOClient alloc] initWithSocketURL:address options:nil];
    
    [_dvcTabBarController.socket on:@"connect" callback:^(NSArray* data, void (^ack)(NSArray*)) {
        NSLog(@"socket connected");
        [self socketOnConnect];
    }];
    
    [_dvcTabBarController.socket on:@"disconnect" callback:^(NSArray* data, void (^ack)(NSArray*)) {
        NSLog(@"socket disconnect");
        [self socketOnDisconnect];
    }];
    
    [_dvcTabBarController.socket on:@"error" callback:^(NSArray* data, void (^ack)(NSArray*)) {
        NSLog(@"socket error");
        [self socketOnError];
    }];
    
    [_dvcTabBarController.socket on:@"DroneConnectionUpdate" callback:^(NSArray* data, void (^ack)(NSArray*)) {
        NSLog(@"Socket: DroneConnectionUpdate");
        [self socketOnDroneConnectionUpdate:data];
    }];
    
    [_dvcTabBarController.socket on:@"DroneBatteryUpdate" callback:^(NSArray* data, void (^ack)(NSArray*)) {
        NSLog(@"Socket: DroneBatteryUpdate");
        [self socketOnDroneBatteryUpdate:data];
    }];
    
    [_dvcTabBarController.socket on:@"ManualOverrideStateChanged" callback:^(NSArray* data, void (^ack)(NSArray*)) {
        NSLog(@"Socket: ManualOverrideStateChanged");
        [_manualOverrideStateDelegate onManualOverrideStateChanged:[(NSNumber *)data[0] boolValue]];
    }];
    
    [_dvcTabBarController.socket connect];
}

- (void)disconnectFromServer
{
    if (_dvcTabBarController.socket != nil && _dvcTabBarController.socket.connected)
    {
        [_dvcTabBarController.socket closeWithFast:false];
    }
    _dvcTabBarController.socket = nil;
    
    [self socketOnDisconnect];
}

- (void)socketOnConnect
{
    [_dvcTabBarController.socket emit:@"InvestigatorClientConnect" withItems:[[NSArray alloc] init]];
    
    [_serverConnectionDelegate onConnectToServer:self.serverConnectionTextField.text];
    
    self.serverConnectionStatusLabel.text = @"Connected to server";
    self.serverConnectionStatusLabel.textColor = _dvcGreen;
    [self.serverConnectionButton setTitle:@"Disconnect" forState:UIControlStateNormal];
    self.serverConnectionButton.enabled = true;
}

- (void)socketOnDisconnect
{
    [_serverConnectionDelegate onDisconnectFromServer];
    [self handleDisconnectFromServer];
}

- (void)socketOnError
{
    [Utility showAlertWithTitle:@"Server Connection Error" withMessage:@"Connection with server failed."];
    [self disconnectFromServer];
    [self handleDisconnectFromServer];
}

- (void)handleDisconnectFromServer
{
    self.serverConnectionStatusLabel.text = @"Not connected to server";
    self.serverConnectionStatusLabel.textColor = _dvcRed;
    [self.serverConnectionButton setTitle:@"Connect" forState:UIControlStateNormal];
    self.serverConnectionButton.enabled = true;
    self.serverConnectionTextField.enabled = true;
    
    self.droneConnectionStatusLabel.text = @"Not connected";
    self.droneConnectionStatusLabel.textColor = _dvcRed;
    
    [_batteryLabel setText:@"0%"];
    
    _takeoffBt.enabled = false;
    _landingBt.enabled = false;
    _emergencyBt.enabled = false;
    
    _upButton.enabled = false;
    _downButton.enabled = false;
}

- (void)socketOnDroneConnectionUpdate:(NSArray *)data
{
    if ([(NSNumber *)data[0] boolValue])
    {
        self.droneConnectionStatusLabel.text = @"Connected";
        self.droneConnectionStatusLabel.textColor = _dvcGreen;
        
        _takeoffBt.enabled = true;
        _landingBt.enabled = true;
        _emergencyBt.enabled = true;
        
        _upButton.enabled = true;
        _downButton.enabled = true;
    }
    else
    {
        self.droneConnectionStatusLabel.text = @"Not connected";
        self.droneConnectionStatusLabel.textColor = _dvcRed;
        
        _takeoffBt.enabled = false;
        _landingBt.enabled = false;
        _emergencyBt.enabled = false;
        
        _upButton.enabled = false;
        _downButton.enabled = false;
    }
}

- (void)socketOnDroneBatteryUpdate:(NSArray *)data
{
    NSString *text = [[NSString alloc] initWithFormat:@"%d%%", [(NSNumber *)data[0] unsignedIntegerValue]];
    [_batteryLabel setText:text];
}


#pragma mark UI Event Handler Methods

- (IBAction)connectToServerClick:(id)sender
{
    if (_dvcTabBarController.socket.connected)
    {
        self.serverConnectionButton.enabled = false;
        self.serverConnectionStatusLabel.text = @"Disconnecting from server...";
        self.serverConnectionStatusLabel.textColor = [UIColor blackColor];
        
        [self disconnectFromServer];
    }
    else
    {
        self.serverConnectionTextField.enabled = false;
        self.serverConnectionButton.enabled = false;
        self.serverConnectionStatusLabel.text = @"Connecting to server...";
        self.serverConnectionStatusLabel.textColor = [UIColor blackColor];
        
        [self connectToServer:[NSString stringWithFormat:@"%@%@", self.serverConnectionTextField.text, @":8081"]];
    }
}

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

- (IBAction)upClick:(id)sender
{
    NSArray *args = [[NSArray alloc] initWithObjects:@"MoveUp", nil];
    [_dvcTabBarController.socket emit:@"InvestigatorCommand" withItems:args];
}

- (IBAction)downClick:(id)sender
{
    NSArray *args = [[NSArray alloc] initWithObjects:@"MoveDown", nil];
    [_dvcTabBarController.socket emit:@"InvestigatorCommand" withItems:args];
}

@end
