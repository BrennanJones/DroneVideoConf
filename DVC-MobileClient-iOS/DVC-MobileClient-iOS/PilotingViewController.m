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
//  PilotingViewController.m
//  DVC-MobileClient-iOS
//


#import <CoreLocation/CoreLocation.h>
#import <libARDataTransfer/ARDataTransfer.h>

#import "PilotingViewController.h"
#import "DeviceController.h"

#import "gps.h"
#import "SocketIOWrapper.h"
#import "Utility.h"


#define TAG "PilotingViewController"


KalmanFilter droneKalmanFilter;
KalmanFilter phoneKalmanFilter;

static const int DRONE_CONTROL_LOOP_IN_MS = 25;  // control loop interval
BOOL droneControlLoopRunning = false;

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

double droneSpeed = 0;
double droneVelocityDirectionAlongXY = 0;

BOOL posPhoneSet = false;
BOOL posDroneSet = false;
BOOL bearingDroneSet = false;
BOOL requiredBearingDroneSet = false;
BOOL distanceApartSet = false;

BOOL droneProperlyOriented = false;
BOOL droneAtProperDistance = false;

static const double DRONE_REQUIRED_ALTITUDE_LOWER_BOUND = 4.0;
static const double DRONE_REQUIRED_ALTITUDE_UPPER_BOUND = 6.0;


@interface PilotingViewController () <DeviceControllerDelegate>

@property (nonatomic, strong) DeviceController *deviceController;
@property (nonatomic, strong) UIAlertView *alertView;

@property (nonatomic, strong) NSThread *droneControlLoopThread;

@end


@implementation PilotingViewController

@synthesize service = _service;
@synthesize batteryLabel = _batteryLabel;


#pragma mark Initialization Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"viewDidLoad ...");
    
    [_batteryLabel setText:@"?%"];
    
    _alertView = [[UIAlertView alloc] initWithTitle:[_service name] message:@"Connecting ..."
                                           delegate:self cancelButtonTitle:nil otherButtonTitles:nil, nil];
    
    [_droneVideoView setupVideoView];
    
    droneKalmanFilter = alloc_filter_velocity2d(1.0);
    phoneKalmanFilter = alloc_filter_velocity2d(1.0);
    
    [self initializePhoneGPS];
    
    _droneControlLoopThread = [[NSThread alloc] initWithTarget:self selector:@selector(droneControlLoopRun) object:nil];
    droneControlLoopRunning = true;
    [_droneControlLoopThread start];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [_alertView show];
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        _deviceController = [[DeviceController alloc]initWithARService:_service];
        [_deviceController setDelegate:self];
        BOOL connectError = [_deviceController start];
        
        NSLog(@"connectError = %d", connectError);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [_alertView dismissWithClickedButtonIndex:0 animated:TRUE];
            
        });
        
        if (connectError)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.navigationController popViewControllerAnimated:YES];
            });
        }
    });
}

- (void)viewDidDisappear:(BOOL)animated
{
    _alertView = [[UIAlertView alloc] initWithTitle:[_service name] message:@"Disconnecting ..."
                                           delegate:self cancelButtonTitle:nil otherButtonTitles:nil, nil];
    [_alertView show];
    
    [_locationManager stopUpdatingLocation];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self disconnectFromServer];
        [_deviceController stop];
        [_alertView dismissWithClickedButtonIndex:0 animated:TRUE];
        
        free_filter(droneKalmanFilter);
        
        droneControlLoopRunning = false;
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    
    // update battery label on the UI thread
    dispatch_async(dispatch_get_main_queue(), ^{
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
    
    if (latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180)
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
    NSLog(@"onFrameComplete");
    
    if (_socket.connected)
    {
        NSData *data = [[NSData alloc] initWithBytes:frame length:frameSize];
        NSArray *args = [[NSArray alloc] initWithObjects:data, nil];
        [SocketIOWrapper emit:_socket withEvent:@"DroneVideoFrame" withItems:args];
    }
    
    [_droneVideoView updateVideoViewWithFrame:frame frameSize:frameSize];
}

- (void)onDisconnectNetwork:(DeviceController *)deviceController
{
    NSLog(@"onDisconnect ...");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.navigationController popViewControllerAnimated:YES];
    });
}


#pragma mark Phone Location Event Handler Methods

// Delegate method from the CLLocationManagerDelegate protocol.
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
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
    NSLog(@"didFailWithError: %@", error);
    UIAlertView *errorAlert = [[UIAlertView alloc]
                               initWithTitle:@"Error" message:@"Failed to Get Your Location" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [errorAlert show];
}


#pragma mark Server Connection Methods

- (void)connectToServer:(NSString *)address
{
    [self disconnectFromServer];
    
    
    _socket = [[SocketIOClient alloc] initWithSocketURL:address options:nil];
    
    
    [_socket on:@"connect" callback:^(NSArray* data, void (^ack)(NSArray*)) {
        NSLog(@"socket connected");
        
        [SocketIOWrapper emit:_socket withEvent:@"MobileClientConnected" withItems:[[NSArray alloc] init]];
        
        self.serverConnectionStatusLabel.text = @"Connected to server.";
        [self.serverConnectionButton setTitle:@"Disconnect" forState:UIControlStateNormal];
        self.serverConnectionButton.enabled = true;
    }];
    
    [_socket on:@"disconnect" callback:^(NSArray* data, void (^ack)(NSArray*)) {
        NSLog(@"socket disconnect");
        
        self.serverConnectionStatusLabel.text = @"Disconnected from server.";
        [self.serverConnectionButton setTitle:@"Connect" forState:UIControlStateNormal];
        self.serverConnectionButton.enabled = true;
        self.serverConnectionTextField.enabled = true;
    }];
    
    [_socket on:@"error" callback:^(NSArray* data, void (^ack)(NSArray*)) {
        NSLog(@"socket error");
        
        _alertView = [[UIAlertView alloc] initWithTitle:[_service name] message:@"Connection with server failed." delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [_alertView show];
        
        self.serverConnectionStatusLabel.text = @"Disconnected from server.";
        [self.serverConnectionButton setTitle:@"Connect" forState:UIControlStateNormal];
        self.serverConnectionButton.enabled = true;
        self.serverConnectionTextField.enabled = true;
    }];
    
    
    [_socket on:@"Command" callback:^(NSArray* data, void (^ack)(NSArray*)) {
        if([(NSString *)data[0] isEqualToString:@"CamLeft"])
        {
            [_deviceController setCamPan:-10];
        }
        if([(NSString *)data[0] isEqualToString:@"CamRight"])
        {
            [_deviceController setCamPan:10];
        }
        if([(NSString *)data[0] isEqualToString:@"CamUp"])
        {
            [_deviceController setCamTilt:10];
        }
        if([(NSString *)data[0] isEqualToString:@"CamDown"])
        {
            [_deviceController setCamTilt:-10];
        }
    }];
    
    
    [_socket connect];
}

- (void)disconnectFromServer
{
    if (_socket != nil && _socket.connected)
    {
        [_socket closeWithFast:false];
    }
}


#pragma mark Drone Control Methods

- (void)droneControlLoopRun
{
    NSDate *droneKalmanFilter_lastUpdate = [NSDate date];
    NSDate *phoneKalmanFilter_lastUpdate = [NSDate date];
    
    NSDate *lastLabelsUpdate = [NSDate date];
    
    while (droneControlLoopRunning)
    {
        if ([[NSDate date] timeIntervalSinceDate:lastLabelsUpdate] >= 0.5)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *speedText = [[NSString alloc] initWithFormat:@"%f", droneSpeed];
                [_droneCurrentSpeedLabel setText:speedText];
            });
        }
        
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
                    
                    if (posDroneSet)
                    {
                        latText = [[NSString alloc] initWithFormat:@"%f", latDroneEst];
                        lonText = [[NSString alloc] initWithFormat:@"%f", lonDroneEst];
                    }
                    else
                    {
                        latText = @"--";
                        lonText = @"--";
                    }
                    
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
        
        if (posDroneSet && posPhoneSet)
        {
            if (bearingDroneSet)
            {
                if ([[NSDate date] timeIntervalSinceDate:lastLabelsUpdate] >= 0.5)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSString *bearingText = [[NSString alloc] initWithFormat:@"%f", bearingDrone];
                        [_bearingDroneLabel setText:bearingText];
                        
                        NSString *requiredBearingText = [[NSString alloc] initWithFormat:@"%f", requiredBearingDrone];
                        [_requiredBearingDroneLabel setText:requiredBearingText];
                        
                        NSString *distText = [[NSString alloc] initWithFormat:@"%f", distanceApart];
                        [_droneToPhoneDistanceLabel setText:distText];
                    });
                }
                
                if (altDrone >= DRONE_REQUIRED_ALTITUDE_LOWER_BOUND && altDrone <= DRONE_REQUIRED_ALTITUDE_UPPER_BOUND)
                {
                    [self droneAdjustBearing];
                    [self droneFollowTarget];
                }
                else
                {
                    [_deviceController setYaw:0];
                    
                    [_deviceController setFlag:0];
                    [_deviceController setPitch:0];
                }
            }
        }
        
        if (altDrone < DRONE_REQUIRED_ALTITUDE_LOWER_BOUND)
        {
            [_deviceController setGaz:50];
        }
        else if (altDrone > DRONE_REQUIRED_ALTITUDE_UPPER_BOUND)
        {
            [_deviceController setGaz:-50];
        }
        else
        {
            [_deviceController setGaz:0];
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
                [_deviceController setYaw:35];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_droneYawDirectionLabel setText:@"Right"];
                });
            }
            else if ((angle < 0 && angle >= -1*M_PI) || angle >= M_PI)
            {
                [_deviceController setYaw:-35];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_droneYawDirectionLabel setText:@"Left"];
                });
            }
        }
        else
        {
            [_deviceController setYaw:0];
            
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
    
    
    // If the distance is greater than the outer bound, move forward.
    if (distanceApart > 12.0 && droneProperlyOriented)
    {
        double pitch = 7.0 * (distanceApart - 12.0);
        
        [_deviceController setFlag:1];
        [_deviceController setPitch:pitch];
    }
    
    // Otherwise, stay still.
    else
    {
        [_deviceController setFlag:0];
        [_deviceController setPitch:0];
    }
}


#pragma mark Drone Sequential Photo Methods

- (void)onSequentialPhotoReady:(DeviceController *)deviceController filePath:(char *)filePath;
{
    NSLog(@"onSequentialPhotoReady");
    
    if (_socket.connected)
    {
        NSString *filePathString = [NSString stringWithUTF8String:filePath];
        NSData *photo = [NSData dataWithContentsOfFile:filePathString];
        
        NSArray *args = [[NSArray alloc] initWithObjects:photo, nil];
        [SocketIOWrapper emit:_socket withEvent:@"DronePhoto" withItems:args];
    }
}


#pragma mark UI Event Handler Methods

- (IBAction)connectToServerClick:(id)sender
{
    if (_socket.connected)
    {
        self.serverConnectionButton.enabled = false;
        self.serverConnectionStatusLabel.text = @"Disconnecting from server...";
        
        [self disconnectFromServer];
    }
    else
    {
        self.serverConnectionTextField.enabled = false;
        self.serverConnectionButton.enabled = false;
        self.serverConnectionStatusLabel.text = @"Connecting to server...";
        
        [self connectToServer:self.serverConnectionTextField.text];
    }
}

- (IBAction)emergencyClick:(id)sender
{
    [_deviceController sendEmergency];
}

- (IBAction)takeoffClick:(id)sender
{
    [_deviceController resetHome];
    [_deviceController sendTakeoff];
}

- (IBAction)landingClick:(id)sender
{
    [_deviceController sendLanding];
}

//events for gaz:
- (IBAction)gazUpTouchDown:(id)sender
{
    [_deviceController setGaz:50];
}
- (IBAction)gazDownTouchDown:(id)sender
{
    [_deviceController setGaz:-50];
}

- (IBAction)gazUpTouchUp:(id)sender
{
    [_deviceController setGaz:0];
}
- (IBAction)gazDownTouchUp:(id)sender
{
    [_deviceController setGaz:0];
}

//events for yaw:
- (IBAction)yawLeftTouchDown:(id)sender
{
    [_deviceController setYaw:-50];
    
}
- (IBAction)yawRightTouchDown:(id)sender
{
    [_deviceController setYaw:50];
    
}

- (IBAction)yawLeftTouchUp:(id)sender
{
    [_deviceController setYaw:0];
}

- (IBAction)yawRightTouchUp:(id)sender
{
    [_deviceController setYaw:0];
}

//events for yaw:
- (IBAction)rollLeftTouchDown:(id)sender
{
    [_deviceController setFlag:1];
    [_deviceController setRoll:-50];
}
- (IBAction)rollRightTouchDown:(id)sender
{
    [_deviceController setFlag:1];
    [_deviceController setRoll:50];
}

- (IBAction)rollLeftTouchUp:(id)sender
{
    [_deviceController setFlag:0];
    [_deviceController setRoll:0];
}
- (IBAction)rollRightTouchUp:(id)sender
{
    [_deviceController setFlag:0];
    [_deviceController setRoll:0];
}

//events for pitch:
- (IBAction)pitchForwardTouchDown:(id)sender
{
    [_deviceController setFlag:1];
    [_deviceController setPitch:50];
}
- (IBAction)pitchBackTouchDown:(id)sender
{
    [_deviceController setFlag:1];
    [_deviceController setPitch:-50];
}

- (IBAction)pitchForwardTouchUp:(id)sender
{
    [_deviceController setFlag:0];
    [_deviceController setPitch:0];
}
- (IBAction)pitchBackTouchUp:(id)sender
{
    [_deviceController setFlag:0];
    [_deviceController setPitch:0];
}

- (IBAction)camUpClick:(id)sender
{
    [_deviceController setCamTilt:10];
}

- (IBAction)camDownClick:(id)sender
{
    [_deviceController setCamTilt:-10];
}

- (IBAction)camLeftClick:(id)sender
{
    [_deviceController setCamPan:-10];
}

- (IBAction)camRightClick:(id)sender
{
    [_deviceController setCamPan:10];
}

- (IBAction)resetHomeClick:(id)sender
{
    [_deviceController setHomeWithLatitude:latDrone withLongitude:lonDrone withAltitude:altDrone];
}

- (IBAction)takePhotoClick:(id)sender
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [_deviceController takePhoto];
        [_deviceController getLastMediaAsync];
    });
}

@end
