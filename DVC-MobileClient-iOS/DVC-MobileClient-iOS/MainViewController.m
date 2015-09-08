/*
    Copyright (C) 2014 Parrot SA

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions
    are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in
      the documentation and/or other materials provided with the 
      distribution.
    * Neither the name of Parrot nor the names
      of its contributors may be used to endorse or promote products
      derived from this software without specific prior written
      permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
    OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED 
    AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
    OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
    OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
    SUCH DAMAGE.
*/

//
//  MainViewController.m
//  DVC-MobileClient-iOS
//


#import "MainViewController.h"

#import <CoreLocation/CoreLocation.h>
#import <libARDataTransfer/ARDataTransfer.h>

#import "DeviceController.h"
#import "DVCTabBarController.h"
#import "gps.h"
#import "NSMutableArray+Queue.h"
#import "Utility.h"


#define TAG "MainViewController"


KalmanFilter droneKalmanFilter;
KalmanFilter phoneKalmanFilter;

static const int DRONE_CONTROL_LOOP_IN_MS = 25;  // control loop interval
BOOL droneControlLoopRunning = false;

uint8_t droneBatteryPercentage = 0;

double latPhone;
double lonPhone;

double latPhoneEst;
double lonPhoneEst;

double latDrone;
double lonDrone;
double altDrone;

double latDroneEst;
double lonDroneEst;

double yawDrone;
double bearingDrone;

double requiredBearingDrone;

double distanceApart;   // the calculated distance between the drone and the phone

double droneFollowingDistanceInnerBound = 8.0;
double droneFollowingDistanceOuterBound = 10.0;

double droneSpeed = 0;
static const double DRONE_MAX_PITCH = 20.0;
double droneVelocityDirectionAlongXY = 0;

BOOL posPhoneSet = false;
BOOL posDroneSet = false;
BOOL bearingDroneSet = false;
BOOL requiredBearingDroneSet = false;
BOOL distanceApartSet = false;

BOOL droneProperlyOriented = false;
BOOL droneAtProperDistance = false;

double droneRequiredAltitudeLowerBound = 4.0;
double droneRequiredAltitudeUpperBound = 6.0;

static const int OUTPUT_VIDEO_STREAM_LOOP_IN_MS = 20;  // output video stream loop interval
BOOL outputVideoStreamLoopRunning = false;

BOOL manualOverrideOn = false;


@interface MainViewController ()

@property (nonatomic, strong) DVCTabBarController *dvcTabBarController;

@property (nonatomic, strong) NSThread *droneControlLoopThread;

@property (nonatomic, strong) UIColor *dvcRed;
@property (nonatomic, strong) UIColor *dvcGreen;

@property (nonatomic, strong) NSThread *outputVideoStreamLoopThread;
@property (nonatomic, strong) NSMutableArray *outputVideoStreamFrameQueue;
@property (nonatomic, strong) NSLock *outputVideoStreamFrameQueueLock;

@end


@implementation MainViewController

@synthesize service = _service;
@synthesize batteryLabel = _batteryLabel;


#pragma mark Initialization Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"MainViewController: viewDidLoad ...");
    
    _dvcTabBarController = (DVCTabBarController *)(self.tabBarController);
    
    _dvcRed = [UIColor colorWithRed:0.8 green:0.2 blue:0.2 alpha:1.0];
    _dvcGreen = [UIColor colorWithRed:0.2 green:0.8 blue:0.0 alpha:1];
    
    _service = nil;
    
    self.droneConnectionStatusLabel.text = @"Not connected";
    self.droneConnectionStatusLabel.textColor = _dvcRed;
    
    _outputVideoStreamFrameQueue = [NSMutableArray array];
    _outputVideoStreamFrameQueueLock = [[NSLock alloc] init];
    
    _outputVideoStreamLoopThread = [[NSThread alloc] initWithTarget:self selector:@selector(outputVideoStreamLoopRun) object:nil];
    outputVideoStreamLoopRunning = true;
    [_outputVideoStreamLoopThread start];
    
    [_emergencyBt setEnabled:NO];
    
    [self registerApplicationNotifications];
    [[ARDiscovery sharedInstance] start];
    
    [self connectToServerClick:nil];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSLog(@"MainViewController: viewWillAppear ... ");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tabBarController.tabBar setBarStyle:UIBarStyleDefault];
        [self.tabBarController.tabBar setTranslucent:NO];
        
        NSArray *args = [[NSArray alloc] initWithObjects:@"StatusesView", nil];
        [_dvcTabBarController.socket emit:@"MCTabToggle" withItems:args];
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
    [[ARDiscovery sharedInstance] stop];
    
    [_locationManager stopUpdatingLocation];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self disconnectFromServer];
        [_dvcTabBarController.deviceController stop];
        
        free_filter(droneKalmanFilter);
        
        droneControlLoopRunning = false;
        outputVideoStreamLoopRunning = false;
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(discoveryDidUpdateServices:) name:kARDiscoveryNotificationServicesDevicesListUpdated object:nil];
}

- (void)unregisterApplicationNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name: UIApplicationDidEnterBackgroundNotification object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name: UIApplicationWillEnterForegroundNotification object: nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kARDiscoveryNotificationServicesDevicesListUpdated object:nil];
}

- (void)enteredBackground:(NSNotification*)notification
{
    NSLog(@"MainViewController: enteredBackground ... ");
}

- (void)enterForeground:(NSNotification*)notification
{
    NSLog(@"MainViewController: enterForeground ... ");
}

- (void)discoveryDidUpdateServices:(NSNotification *)notification
{
    NSArray *services = [[notification userInfo] objectForKey:kARDiscoveryServicesList];
    
    if (_service == nil)
    {
        for (ARService *service in services)
        {
            if (service.product == ARDISCOVERY_PRODUCT_ARDRONE)
            {
                _service = service;
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    _dvcTabBarController.deviceController = [[DeviceController alloc]initWithARService:_service];
                    [_dvcTabBarController.deviceController setDeviceControllerDelegate:self];
                    
                    BOOL connectError = [_dvcTabBarController.deviceController start];
                    NSLog(@"connectError = %d", connectError);
                    
                    if (connectError)
                    {
                        _service = nil;
                    }
                    else
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [_emergencyBt setEnabled:YES];
                            
                            self.droneConnectionStatusLabel.text = @"Connected";
                            self.droneConnectionStatusLabel.textColor = _dvcGreen;
                            
                            droneKalmanFilter = alloc_filter_velocity2d(1.5);
                            phoneKalmanFilter = alloc_filter_velocity2d(1.5);
                            
                            [self initializePhoneGPS];
                            
                            _droneControlLoopThread = [[NSThread alloc] initWithTarget:self selector:@selector(droneControlLoopRun) object:nil];
                            droneControlLoopRunning = true;
                            [_droneControlLoopThread start];
                            
                            if (_dvcTabBarController.socket.connected)
                            {
                                NSArray *args = [[NSArray alloc] initWithObjects:[NSNumber numberWithUnsignedInteger:1], nil];
                                [_dvcTabBarController.socket emit:@"DroneConnectionUpdate" withItems:args];
                            }
                        });
                    }
                });
                
                break;
            }
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    return YES;
}

- (void)initializePhoneGPS
{
    if (_locationManager == nil)
    {
        _locationManager = [[CLLocationManager alloc] init];
    }
    
    _locationManager.delegate = self;
    
    if ([_locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)])
    {
        [_locationManager requestWhenInUseAuthorization];
    }
    
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    // Set a movement threshold for new events.
    _locationManager.distanceFilter = 0; // metres
    
    [_locationManager startUpdatingLocation];
}


#pragma mark Drone Event Handler Methods

- (void)onUpdateBattery:(DeviceController *)deviceController batteryLevel:(uint8_t)percent;
{
    NSLog(@"onUpdateBattery");
    
    droneBatteryPercentage = percent;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray *args = [[NSArray alloc] initWithObjects:[NSNumber numberWithUnsignedInteger:percent], nil];
        [_dvcTabBarController.socket emit:@"DroneBatteryUpdate" withItems:args];
        
        NSString *text = [[NSString alloc] initWithFormat:@"%d%%", percent];
        [_batteryLabel setText:text];
    });
}

-(void)onFlyingStateChanged:(DeviceController *)deviceController flyingState:(eARCOMMANDS_ARDRONE3_PILOTINGSTATE_FLYINGSTATECHANGED_STATE)state
{
    NSLog(@"onFlyingStateChanged");
    
    // on the UI thread, disable and enable buttons according to flying state
    dispatch_async(dispatch_get_main_queue(), ^{
        switch (state) {
            case ARCOMMANDS_ARDRONE3_PILOTINGSTATE_FLYINGSTATECHANGED_STATE_LANDED:
                if (posDroneSet)
                {
                    [_takeoffBt setEnabled:YES];
                }
                else
                {
                    [_takeoffBt setEnabled:NO];
                }
                [_landingBt setEnabled:NO];
                break;
            case ARCOMMANDS_ARDRONE3_PILOTINGSTATE_FLYINGSTATECHANGED_STATE_HOVERING:
            case ARCOMMANDS_ARDRONE3_PILOTINGSTATE_FLYINGSTATECHANGED_STATE_FLYING:
                [_takeoffBt setEnabled:NO];
                [_landingBt setEnabled:YES];
                break;
            default:
                // in all other cases, take of and landing are not enabled
                [_takeoffBt setEnabled:NO];
                [_landingBt setEnabled:NO];
                break;
        }
    });
}

- (void)onDronePositionChanged:(DeviceController *)deviceController latitude:(double)latitude longitude:(double)longitude altitude:(double)altitude;
{
    NSLog(@"onDronePositionChanged");
    
    if (latitude >= -90.0 && latitude <= 90.0 && longitude >= -180.0 && longitude <= 180.0)
    {
        latDrone = latitude;
        lonDrone = longitude;
        
        posDroneSet = true;
    }
}

- (void)onAltitudeChanged:(DeviceController *)deviceController altitude:(double)altitude;
{
    NSLog(@"onAltitudeChanged");
    
    altDrone = altitude;
}

- (void)onAttitudeChanged:(DeviceController *)deviceController roll:(float)roll pitch:(float)pitch yaw:(float)yaw;
{
    NSLog(@"onAttitudeChanged");
    
    bearingDrone = yaw;
    
    bearingDroneSet = true;
}

- (void)onSpeedChanged:(DeviceController *)deviceController speedX:(float)speedX speedY:(float)speedY speedZ:(float)speedZ;
{
    NSLog(@"onSpeedChanged");
    
    droneSpeed = sqrtf(speedX*speedX + speedY*speedY + speedZ*speedZ);
    
    droneVelocityDirectionAlongXY = atan2(speedY, speedX);
}

- (void)onFrameComplete:(DeviceController *)deviceController frame:(uint8_t *)frame frameSize:(uint32_t)frameSize;
{
    NSLog(@"MainViewController: onFrameComplete ...");
    
    // Check what type of NAL unit(s) are in the data.
    int startCodeIndex = 0;
    for (int i = 0; i < 4; i++)
    {
        startCodeIndex = i + 1;
        if (frame[i] == 0x01)
        {
            break;
        }
    }
    int nalu_type = ((uint8_t)frame[startCodeIndex] & 0x1F);
    
    // If a key frame and/or SPS/PPS data found, clear the frame queue.
    if (nalu_type == 5 || nalu_type == 7 || nalu_type == 8)
    {
        [_outputVideoStreamFrameQueueLock lock];
        if (_outputVideoStreamFrameQueue.count)
        {
            [_outputVideoStreamFrameQueue removeAllObjects];
        }
        [_outputVideoStreamFrameQueueLock unlock];
    }
    
    // Add next frame to queue.
    [_outputVideoStreamFrameQueueLock lock];
    [_outputVideoStreamFrameQueue enqueue:[[NSData alloc] initWithBytes:frame length:frameSize]];
    [_outputVideoStreamFrameQueueLock unlock];
}

- (void)onDisconnectNetwork:(DeviceController *)deviceController
{
    NSLog(@"onDisconnect ...");
    
    _service = nil;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray *args = [[NSArray alloc] initWithObjects:[NSNumber numberWithUnsignedInteger:0], nil];
        [_dvcTabBarController.socket emit:@"DroneConnectionUpdate" withItems:args];
        
        self.droneConnectionStatusLabel.text = @"Not connected";
        self.droneConnectionStatusLabel.textColor = _dvcRed;
        
        [_emergencyBt setEnabled:NO];
    });
}


#pragma mark Phone Location Event Handler Methods

// Delegate method from the CLLocationManagerDelegate protocol.
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    NSLog(@"locationManager didUpdateLocations (phone location updated)");
    
    // If it's a relatively recent event, turn off updates to save power.
    CLLocation* location = [locations lastObject];
    NSDate* eventDate = location.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    
    if (fabs(howRecent) < 15.0)
    {
        // If the event is recent, do something with it.
        NSLog(@"latitude %+.6f, longitude %+.6f\n", location.coordinate.latitude, location.coordinate.longitude);
        
        latPhone = location.coordinate.latitude;
        lonPhone = location.coordinate.longitude;
        
        posPhoneSet = true;
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"locationManager didFailWithError: %@ (phone location update failed)", error);
    [Utility showAlertWithTitle:@"Location Error" withMessage:@"Failed to Get Your Location"];
}


#pragma mark Server Connection Methods

- (void)connectToServer:(NSString *)address
{
    _dvcTabBarController.socket = [[SocketIOClient alloc] initWithSocketURL:address options:nil];
    
    [_dvcTabBarController.socket on:@"connect" callback:^(NSArray* data, void (^ack)(NSArray*)) {
        NSLog(@"Socket connected");
        [self socketOnConnect];
    }];
    
    [_dvcTabBarController.socket on:@"disconnect" callback:^(NSArray* data, void (^ack)(NSArray*)) {
        NSLog(@"Socket disconnected");
        [self socketOnDisconnect];
    }];
    
    [_dvcTabBarController.socket on:@"error" callback:^(NSArray* data, void (^ack)(NSArray*)) {
        NSLog(@"Socket error");
        [self socketOnError];
    }];
    
    [_dvcTabBarController.socket on:@"Command" callback:^(NSArray* data, void (^ack)(NSArray*)) {
        NSLog(@"Socket: Command");
        [self socketOnCommand:data];
    }];
    
    [_dvcTabBarController.socket on:@"InvestigatorCommand" callback:^(NSArray* data, void (^ack)(NSArray*)) {
        NSLog(@"Socket: InvestigatorCommand");
        [self socketOnInvestigatorCommand:data];
    }];
    
    [_dvcTabBarController.socket on:@"ManualOverrideStateChanged" callback:^(NSArray* data, void (^ack)(NSArray*)) {
        NSLog(@"Socket: ManualOverrideStateChanged");
        [self socketOnManualOverrideStateChanged:data];
    }];
    
    [_dvcTabBarController.socket on:@"ManualOverrideCommand" callback:^(NSArray* data, void (^ack)(NSArray*)) {
        NSLog(@"Socket: ManualOverrideCommand");
        [self socketOnManualOverrideCommand:data];
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
    [_dvcTabBarController.socket emit:@"MobileClientConnect" withItems:[[NSArray alloc] init]];
    
    [_serverConnectionDelegate onConnectToServer:self.serverConnectionTextField.text];
    
    NSArray *args = [[NSArray alloc] initWithObjects:[NSNumber numberWithBool:_service != nil], nil];
    [_dvcTabBarController.socket emit:@"DroneConnectionUpdate" withItems:args];
    
    args = [[NSArray alloc] initWithObjects:[NSNumber numberWithUnsignedInteger:droneBatteryPercentage], nil];
    [_dvcTabBarController.socket emit:@"DroneBatteryUpdate" withItems:args];
    
    args = [[NSArray alloc] initWithObjects:@{@"pan": [NSNumber numberWithInt:_dvcTabBarController.deviceController.cameraPan],
                                              @"tilt": [NSNumber numberWithInt:_dvcTabBarController.deviceController.cameraTilt]
                                            }, nil];
    [_dvcTabBarController.socket emit:@"DroneCameraUpdate" withItems:args];
    
    args = [[NSArray alloc] initWithObjects:@{@"lowerBound": [NSNumber numberWithInt:droneRequiredAltitudeLowerBound],
                                              @"upperBound": [NSNumber numberWithInt:droneRequiredAltitudeUpperBound]
                                            }, nil];
    [_dvcTabBarController.socket emit:@"DroneAltitudeSettingsUpdate" withItems:args];
    
    args = [[NSArray alloc] initWithObjects:@{@"innerBound": [NSNumber numberWithInt:droneFollowingDistanceInnerBound],
                                              @"outerBound": [NSNumber numberWithInt:droneFollowingDistanceOuterBound]
                                            }, nil];
    [_dvcTabBarController.socket emit:@"DroneFollowingDistanceSettingsUpdate" withItems:args];
    
    self.serverConnectionStatusLabel.text = @"Connected to server";
    self.serverConnectionStatusLabel.textColor = _dvcGreen;
    [self.serverConnectionButton setTitle:@"Disconnect" forState:UIControlStateNormal];
    self.serverConnectionButton.enabled = true;
}

- (void)socketOnDisconnect
{
    [_serverConnectionDelegate onDisconnectFromServer];
    
    self.serverConnectionStatusLabel.text = @"Not connected to server";
    self.serverConnectionStatusLabel.textColor = _dvcRed;
    [self.serverConnectionButton setTitle:@"Connect" forState:UIControlStateNormal];
    self.serverConnectionButton.enabled = true;
    self.serverConnectionTextField.enabled = true;
}

- (void)socketOnError
{
    [Utility showAlertWithTitle:@"Server Connection Error" withMessage:@"Connection with server failed."];
    
    [self disconnectFromServer];
    
    self.serverConnectionStatusLabel.text = @"Not connected to server";
    self.serverConnectionStatusLabel.textColor = _dvcRed;
    [self.serverConnectionButton setTitle:@"Connect" forState:UIControlStateNormal];
    self.serverConnectionButton.enabled = true;
    self.serverConnectionTextField.enabled = true;
}

- (void)socketOnCommand:(NSArray *)data
{
    if ([(NSString *)data[0] isEqualToString:@"CamLeft"] ||
        [(NSString *)data[0] isEqualToString:@"CamRight"] ||
        [(NSString *)data[0] isEqualToString:@"CamUp"] ||
        [(NSString *)data[0] isEqualToString:@"CamDown"])
    {
        if([(NSString *)data[0] isEqualToString:@"CamLeft"])
        {
            [_dvcTabBarController.deviceController setCamPan:-10];
        }
        else if([(NSString *)data[0] isEqualToString:@"CamRight"])
        {
            [_dvcTabBarController.deviceController setCamPan:10];
        }
        else if([(NSString *)data[0] isEqualToString:@"CamUp"])
        {
            [_dvcTabBarController.deviceController setCamTilt:10];
        }
        else if([(NSString *)data[0] isEqualToString:@"CamDown"])
        {
            [_dvcTabBarController.deviceController setCamTilt:-10];
        }
        
        NSArray *args = [[NSArray alloc] initWithObjects:@{@"pan": [NSNumber numberWithInt:_dvcTabBarController.deviceController.cameraPan],
                                                           @"tilt": [NSNumber numberWithInt:_dvcTabBarController.deviceController.cameraTilt]
                                                         }, nil];
        [_dvcTabBarController.socket emit:@"DroneCameraUpdate" withItems:args];
    }
    
    else if ([(NSString *)data[0] isEqualToString:@"MoveUp"] ||
             [(NSString *)data[0] isEqualToString:@"MoveDown"])
    {
        if([(NSString *)data[0] isEqualToString:@"MoveUp"])
        {
            if (droneRequiredAltitudeUpperBound <= 20.0)
            {
                droneRequiredAltitudeLowerBound += 1.0;
                droneRequiredAltitudeUpperBound += 1.0;
            }
        }
        else if([(NSString *)data[0] isEqualToString:@"MoveDown"])
        {
            if (droneRequiredAltitudeLowerBound >= 2.0)
            {
                droneRequiredAltitudeLowerBound -= 1.0;
                droneRequiredAltitudeUpperBound -= 1.0;
            }
        }
        
        NSArray *args = [[NSArray alloc] initWithObjects:@{@"lowerBound": [NSNumber numberWithInt:droneRequiredAltitudeLowerBound],
                                                           @"upperBound": [NSNumber numberWithInt:droneRequiredAltitudeUpperBound]
                                                           }, nil];
        [_dvcTabBarController.socket emit:@"DroneAltitudeSettingsUpdate" withItems:args];
    }
    
    else if ([(NSString *)data[0] isEqualToString:@"MoveForward"] ||
             [(NSString *)data[0] isEqualToString:@"MoveBack"])
    {
        if([(NSString *)data[0] isEqualToString:@"MoveBack"])
        {
            if (droneFollowingDistanceOuterBound <= 20.0)
            {
                droneFollowingDistanceInnerBound += 1.0;
                droneFollowingDistanceOuterBound += 1.0;
            }
        }
        else if([(NSString *)data[0] isEqualToString:@"MoveForward"])
        {
            if (droneFollowingDistanceInnerBound >= 5.0)
            {
                droneFollowingDistanceInnerBound -= 1.0;
                droneFollowingDistanceOuterBound -= 1.0;
            }
        }
        
        NSArray *args = [[NSArray alloc] initWithObjects:@{@"innerBound": [NSNumber numberWithInt:droneFollowingDistanceInnerBound],
                                                           @"outerBound": [NSNumber numberWithInt:droneFollowingDistanceOuterBound]
                                                           }, nil];
        [_dvcTabBarController.socket emit:@"DroneFollowingDistanceSettingsUpdate" withItems:args];
    }
}

- (void)socketOnManualOverrideStateChanged:(NSArray *)data
{
    manualOverrideOn = [(NSNumber *)data[0] boolValue];
    
    [_dvcTabBarController.deviceController setRoll:0];
    [_dvcTabBarController.deviceController setPitch:0];
    [_dvcTabBarController.deviceController setYaw:0];
    [_dvcTabBarController.deviceController setGaz:0];
    [_dvcTabBarController.deviceController setFlag:0];
    
    [_dvcTabBarController.deviceController sendNavigateHomeWithStart:0];
}

- (void)socketOnInvestigatorCommand:(NSArray *)data
{
    if([(NSString *)data[0] isEqualToString:@"Emergency"])
    {
        if (_emergencyBt.enabled)
        {
            [_dvcTabBarController.deviceController sendEmergency];
        }
    }
    else if([(NSString *)data[0] isEqualToString:@"Takeoff"])
    {
        if (_takeoffBt.enabled)
        {
            [_dvcTabBarController.deviceController sendTakeoff];
        }
    }
    else if([(NSString *)data[0] isEqualToString:@"Land"])
    {
        if (_landingBt.enabled)
        {
            [_dvcTabBarController.deviceController sendLanding];
        }
    }
}

- (void)socketOnManualOverrideCommand:(NSArray *)data
{
    if (manualOverrideOn)
    {
        if([(NSString *)data[0] isEqualToString:@"ReturnToHome"])
        {
            [_dvcTabBarController.deviceController sendNavigateHomeWithStart:1];
        }
        
        else if([(NSString *)data[0] isEqualToString:@"RollForwardStart"])
        {
            [_dvcTabBarController.deviceController setFlag:1];
            [_dvcTabBarController.deviceController setPitch:50];
        }
        else if([(NSString *)data[0] isEqualToString:@"RollBackStart"])
        {
            [_dvcTabBarController.deviceController setFlag:1];
            [_dvcTabBarController.deviceController setPitch:-50];
        }
        else if([(NSString *)data[0] isEqualToString:@"RollLeftStart"])
        {
            [_dvcTabBarController.deviceController setFlag:1];
            [_dvcTabBarController.deviceController setRoll:-50];
        }
        else if([(NSString *)data[0] isEqualToString:@"RollRightStart"])
        {
            [_dvcTabBarController.deviceController setFlag:1];
            [_dvcTabBarController.deviceController setRoll:50];
        }
        
        else if([(NSString *)data[0] isEqualToString:@"YawUpStart"])
        {
            [_dvcTabBarController.deviceController setGaz:50];
        }
        else if([(NSString *)data[0] isEqualToString:@"YawDownStart"])
        {
            [_dvcTabBarController.deviceController setGaz:-50];
        }
        else if([(NSString *)data[0] isEqualToString:@"YawLeftStart"])
        {
            [_dvcTabBarController.deviceController setYaw:-50];
        }
        else if([(NSString *)data[0] isEqualToString:@"YawRightStart"])
        {
            [_dvcTabBarController.deviceController setYaw:50];
        }
        
        else if([(NSString *)data[0] isEqualToString:@"RollForwardEnd"])
        {
            [_dvcTabBarController.deviceController setFlag:0];
            [_dvcTabBarController.deviceController setPitch:0];
        }
        else if([(NSString *)data[0] isEqualToString:@"RollBackEnd"])
        {
            [_dvcTabBarController.deviceController setFlag:0];
            [_dvcTabBarController.deviceController setPitch:0];
        }
        else if([(NSString *)data[0] isEqualToString:@"RollLeftEnd"])
        {
            [_dvcTabBarController.deviceController setFlag:0];
            [_dvcTabBarController.deviceController setRoll:0];
        }
        else if([(NSString *)data[0] isEqualToString:@"RollRightEnd"])
        {
            [_dvcTabBarController.deviceController setFlag:0];
            [_dvcTabBarController.deviceController setRoll:0];
        }
        
        else if([(NSString *)data[0] isEqualToString:@"YawUpEnd"])
        {
            [_dvcTabBarController.deviceController setGaz:0];
        }
        else if([(NSString *)data[0] isEqualToString:@"YawDownEnd"])
        {
            [_dvcTabBarController.deviceController setGaz:0];
        }
        else if([(NSString *)data[0] isEqualToString:@"YawLeftEnd"])
        {
            [_dvcTabBarController.deviceController setYaw:0];
        }
        else if([(NSString *)data[0] isEqualToString:@"YawRightEnd"])
        {
            [_dvcTabBarController.deviceController setYaw:0];
        }
    }
}


#pragma mark Drone Control Methods

- (void)droneControlLoopRun
{
    NSDate *droneKalmanFilter_lastUpdate = [NSDate date];
    NSDate *phoneKalmanFilter_lastUpdate = [NSDate date];
    
    NSDate *lastLabelsUpdate = [NSDate date];
    NSDate *lastLocationUpdateToServer = [NSDate date];
    
    while (droneControlLoopRunning)
    {
//        if ([[NSDate date] timeIntervalSinceDate:lastLabelsUpdate] >= 0.5)
//        {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                NSString *speedText = [[NSString alloc] initWithFormat:@"%f", droneSpeed];
//                [_droneCurrentSpeedLabel setText:speedText];
//            });
//        }
        
        if (posDroneSet)
        {
            update_velocity2d(droneKalmanFilter, latDrone, lonDrone, [[NSDate date] timeIntervalSinceDate:droneKalmanFilter_lastUpdate]);
            droneKalmanFilter_lastUpdate = [NSDate date];
            
            get_lat_long(droneKalmanFilter, &latDroneEst, &lonDroneEst);
            
            if ([[NSDate date] timeIntervalSinceDate:lastLabelsUpdate] >= 0.5)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *latText;
                    NSString *lonText;
                    NSString *altText = [[NSString alloc] initWithFormat:@"%f", altDrone];
                    
                    latText = [[NSString alloc] initWithFormat:@"%f", latDroneEst];
                    lonText = [[NSString alloc] initWithFormat:@"%f", lonDroneEst];
                    
                    [_latDroneLabel setText:latText];
                    [_lonDroneLabel setText:lonText];
                    [_altDroneLabel setText:altText];
                });
            }
        }
        
        if (posPhoneSet)
        {
            update_velocity2d(phoneKalmanFilter, latPhone, lonPhone, [[NSDate date] timeIntervalSinceDate:phoneKalmanFilter_lastUpdate]);
            phoneKalmanFilter_lastUpdate = [NSDate date];
            
            get_lat_long(phoneKalmanFilter, &latPhoneEst, &lonPhoneEst);
            
            if ([[NSDate date] timeIntervalSinceDate:lastLabelsUpdate] >= 0.5)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *latText = [[NSString alloc] initWithFormat:@"%f", latPhoneEst];
                    NSString *longText = [[NSString alloc] initWithFormat:@"%f", lonPhoneEst];
                    
                    [_latPhoneLabel setText:latText];
                    [_lonPhoneLabel setText:longText];
                });
            }
        }
        
        if (posDroneSet && posPhoneSet && bearingDroneSet)
        {
//            if ([[NSDate date] timeIntervalSinceDate:lastLabelsUpdate] >= 0.5)
//            {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    NSString *bearingText = [[NSString alloc] initWithFormat:@"%f", bearingDrone];
//                    [_bearingDroneLabel setText:bearingText];
//                    
//                    NSString *requiredBearingText = [[NSString alloc] initWithFormat:@"%f", requiredBearingDrone];
//                    [_requiredBearingDroneLabel setText:requiredBearingText];
//                    
//                    NSString *distText = [[NSString alloc] initWithFormat:@"%f", distanceApart];
//                    [_droneToPhoneDistanceLabel setText:distText];
//                });
//            }
            
            if ([[NSDate date] timeIntervalSinceDate:lastLocationUpdateToServer] >= 2.0 && _dvcTabBarController.socket.connected && _landingBt.enabled)
            {
                NSArray *args = [[NSArray alloc] initWithObjects:@{@"latPhone": [NSNumber numberWithDouble:latPhoneEst],
                                                                   @"lonPhone": [NSNumber numberWithDouble:lonPhoneEst],
                                                                   @"latDrone": [NSNumber numberWithDouble:latDroneEst],
                                                                   @"lonDrone": [NSNumber numberWithDouble:lonDroneEst],
                                                                   @"altDrone": [NSNumber numberWithDouble:altDrone],
                                                                   @"bearingDrone": [NSNumber numberWithDouble:bearingDrone],
                                                                   }, nil];
                [_dvcTabBarController.socket emit:@"LocationUpdate" withItems:args];
                
                lastLocationUpdateToServer = [NSDate date];
            }
            
            if (!manualOverrideOn)
            {
                if (altDrone >= droneRequiredAltitudeLowerBound - 0.5 && altDrone <= droneRequiredAltitudeUpperBound + 0.5)
                {
                    [self droneAdjustBearing];
                    [self droneFollowTarget];
                }
                else
                {
                    [_dvcTabBarController.deviceController setYaw:0];
                    
                    [_dvcTabBarController.deviceController setFlag:0];
                    [_dvcTabBarController.deviceController setPitch:0];
                }
            }
        }
        
        if (!manualOverrideOn)
        {
            if (altDrone < droneRequiredAltitudeLowerBound)
            {
                [_dvcTabBarController.deviceController setGaz:50];
            }
            else if (altDrone > droneRequiredAltitudeUpperBound)
            {
                [_dvcTabBarController.deviceController setGaz:-50];
            }
            else
            {
                [_dvcTabBarController.deviceController setGaz:0];
            }
        }
        
        if ([[NSDate date] timeIntervalSinceDate:lastLabelsUpdate] >= 0.5)
        {
            lastLabelsUpdate = [NSDate date];
        }
        
        usleep(DRONE_CONTROL_LOOP_IN_MS * 1000);
    }
}

- (void)droneAdjustBearing
{
    //
    // TO DO: Look into making the drone do bank turns while moving forward instead of yaw turns, to
    //  allow for more stable movement.
    //
    
    
    // The required bearing, in radians.
    requiredBearingDrone = atan2( sin(lonPhoneEst-lonDroneEst)*cos(latPhoneEst), cos(latDroneEst)*sin(latPhoneEst) - sin(latDroneEst)*cos(latPhoneEst)*cos(lonPhoneEst-lonDroneEst) );
    
    requiredBearingDroneSet = true;
    
    double angle = requiredBearingDrone - bearingDrone;
    
    if (droneProperlyOriented && fabs(angle) > 0.2)
    {
        droneProperlyOriented = false;
    }
    
    if (!droneProperlyOriented)
    {
        if (fabs(angle) > 0.05)
        {
            if ((angle >= 0 && angle < M_PI) || angle < -1*M_PI)
            {
                [_dvcTabBarController.deviceController setYaw:50];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_droneYawDirectionLabel setText:@"Right"];
                });
            }
            else if ((angle < 0 && angle >= -1*M_PI) || angle >= M_PI)
            {
                [_dvcTabBarController.deviceController setYaw:-50];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_droneYawDirectionLabel setText:@"Left"];
                });
            }
        }
        else
        {
            [_dvcTabBarController.deviceController setYaw:0];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [_droneYawDirectionLabel setText:@"Still"];
            });
            
            droneProperlyOriented = true;
        }
    }
}

- (void)droneFollowTarget
{
    // Calculate the distance between the drone and the target.
    
    int R = 6371000;    // the approximate radius of the Earth, in metres
    double dLat = degreesToRadians(latPhoneEst - latDroneEst);
    double dLon = degreesToRadians(lonPhoneEst - lonDroneEst);
    double lat1 = degreesToRadians(latDroneEst);
    double lat2 = degreesToRadians(latPhoneEst);
    
    double a = sin(dLat/2) * sin(dLat/2) + sin(dLon/2) * sin(dLon/2) * cos(lat1) * cos(lat2);
    double c = 2 * atan2(sqrt(a), sqrt(1-a));
    
    distanceApart = R * c;    // the distance between the drone and the target
    distanceApartSet = true;
    
    
    double pitch = 0;
    
    // If the drone is properly oriented, can begin (or continue) following the target.
    if (droneProperlyOriented)
    {
        // If the distance is greater than the outer bound, move forward.
        if (distanceApart > droneFollowingDistanceOuterBound)
        {
            pitch = fmin(DRONE_MAX_PITCH, 6.0 * (distanceApart - droneFollowingDistanceOuterBound));
        }
        
        // If the distance is less than the inner bound, move backward.
        else if (distanceApart < droneFollowingDistanceInnerBound)
        {
            pitch = fmax(-1 * DRONE_MAX_PITCH, -6.0 * (droneFollowingDistanceInnerBound - distanceApart));
        }
    }
    
    // If the distance is between the inner and upper bounds, or the drone is not properly oriented, stay still.
    
    [_dvcTabBarController.deviceController setFlag:(pitch == 0) ? 0 : 1];
    [_dvcTabBarController.deviceController setPitch:pitch];
}


#pragma mark Output Video Stream Methods

- (void)outputVideoStreamLoopRun
{
    while (outputVideoStreamLoopRunning)
    {
        [_outputVideoStreamFrameQueueLock lock];
        NSData *nextFrame = (NSData *)[_outputVideoStreamFrameQueue dequeue];
        [_outputVideoStreamFrameQueueLock unlock];
        
        if (nextFrame != nil && _dvcTabBarController.socket.connected)
        {
            NSArray *args = [[NSArray alloc] initWithObjects:nextFrame, nil];
            [_dvcTabBarController.socket emit:@"DroneVideoFrame" withItems:args];
        }
        
        usleep(OUTPUT_VIDEO_STREAM_LOOP_IN_MS * 1000);
    }
}


#pragma mark Drone Sequential Photo Methods

- (void)onSequentialPhotoReady:(DeviceController *)deviceController filePath:(char *)filePath;
{
    NSLog(@"onSequentialPhotoReady");
    
    if (_dvcTabBarController.socket.connected)
    {
        NSString *filePathString = [NSString stringWithUTF8String:filePath];
        NSData *photo = [NSData dataWithContentsOfFile:filePathString];
        
        NSArray *args = [[NSArray alloc] initWithObjects:photo, nil];
        [_dvcTabBarController.socket emit:@"DronePhoto" withItems:args];
    }
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
    NSLog(@"emergencyClick");
    
    [_dvcTabBarController.deviceController sendEmergency];
}

- (IBAction)takeoffClick:(id)sender
{
    NSLog(@"takeoffClick");
    
    [_dvcTabBarController.deviceController resetHome];
    [_dvcTabBarController.deviceController sendTakeoff];
}

- (IBAction)landingClick:(id)sender
{
    NSLog(@"landingClick");
    
    [_dvcTabBarController.deviceController sendLanding];
}

@end
