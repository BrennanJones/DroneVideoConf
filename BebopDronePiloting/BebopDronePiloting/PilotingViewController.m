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
//  BebopDronePiloting
//
//  Created on 19/01/2015.
//  Copyright (c) 2015 Parrot. All rights reserved.
//


#import <CoreLocation/CoreLocation.h>

#import "PilotingViewController.h"
#import "DeviceController.h"


#define TAG "PilotingViewController"


int frameCount = 0;


double latPhone;
double lonPhone;

double latDrone;
double lonDrone;

double yawDrone;
double headingDrone;

double compassDisplacement = 0;

double requiredBearingDrone;

BOOL posPhoneSet = false;
BOOL posDroneSet = false;
BOOL headingDroneSet = false;
BOOL requiredBearingDroneSet = false;


@interface PilotingViewController () <DeviceControllerDelegate>

@property (nonatomic, strong) DeviceController *deviceController;
@property (nonatomic, strong) UIAlertView *alertView;

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
    
    [self initializePhoneGPS];
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
                [_takeoffBt setEnabled:YES];
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
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *latText = [[NSString alloc] initWithFormat:@"%f", latDrone];
            NSString *longText = [[NSString alloc] initWithFormat:@"%f", lonDrone];
            
            [_latDroneLabel setText:latText];
            [_lonDroneLabel setText:longText];
        });
        
        [self droneAdjustBearing];
    }
}

- (void)onAttitudeChanged:(DeviceController *)deviceController roll:(float)roll pitch:(float)pitch yaw:(float)yaw;
{
    NSLog(@"onUpdatePosition");
    
    yawDrone = yaw;
    headingDrone = yawDrone - compassDisplacement;
    if (headingDrone <= -1 * M_PI)
        headingDrone += 2 * M_PI;
    else if (headingDrone > M_PI)
        headingDrone -= 2 * M_PI;
    
    headingDroneSet = true;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *headingText = [[NSString alloc] initWithFormat:@"%f", headingDrone];
        
        [_headingDroneLabel setText:headingText];
    });
    
    [self droneAdjustBearing];
}

- (void)onFrameComplete:(DeviceController *)deviceController frame:(uint8_t *)frame frameSize:(uint32_t)frameSize;
{
    NSLog(@"onFrameComplete: %d", ++frameCount);
    
    if (_socket.connected)
    {
        NSData *data = [[NSData alloc] initWithBytes:frame length:frameSize];
        NSArray *args = [[NSArray alloc] initWithObjects:data, nil];
        [_socket emitObjc:@"DroneVideoFrame" withItems:args];
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
    
    if (abs(howRecent) < 15.0)
    {
        // If the event is recent, do something with it.
        NSLog(@"latitude %+.6f, longitude %+.6f\n", location.coordinate.latitude, location.coordinate.longitude);
        
        latPhone = location.coordinate.latitude;
        lonPhone = location.coordinate.longitude;
        
        posPhoneSet = true;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *latText = [[NSString alloc] initWithFormat:@"%f", latPhone];
            NSString *longText = [[NSString alloc] initWithFormat:@"%f", lonPhone];
            
            [_latPhoneLabel setText:latText];
            [_lonPhoneLabel setText:longText];
        });
        
        [self droneAdjustBearing];
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
        
        [_socket emitObjc:@"MobileClientConnected" withItems:[[NSArray alloc] init]];
        
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
    
    
//    [_socket on:@"Command" callback:^(NSArray* data, void (^ack)(NSArray*)) {
//        [self displayCommand:[data objectAtIndex:0]];
//        
//        [_endCommandButton setAlpha:1.0];
//        
//        if (_socket.connected)
//        {
//            NSArray *args = [[NSArray alloc] initWithObjects:[data objectAtIndex:0], nil];
//            [_socket emit:@"CommandAcknowledged" withItems:args];
//        }
//    }];
    
    
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

- (void)droneAdjustBearing
{
    if (posPhoneSet && posDroneSet && headingDroneSet)
    {
        NSLog(@"droneAdjustBearing");
        
        // The required bearing, in radians.
        requiredBearingDrone = atan2( sin(lonPhone-lonDrone)*cos(latPhone), cos(latDrone)*sin(latPhone) - sin(latDrone)*cos(latPhone)*cos(lonPhone-lonDrone) );
        
        requiredBearingDroneSet = true;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *requiredBearingText = [[NSString alloc] initWithFormat:@"%f", requiredBearingDrone];
            
            [_requiredBearingDroneLabel setText:requiredBearingText];
        });
        
        if (abs(requiredBearingDrone - headingDrone) > 0.3)
        {
            if ((requiredBearingDrone - headingDrone > 0 && requiredBearingDrone - headingDrone <= M_PI) || requiredBearingDrone - headingDrone < -1*M_PI)
            {
                [_deviceController setYaw:10];
            }
            else if ((requiredBearingDrone - headingDrone < 0 && requiredBearingDrone - headingDrone >= -1*M_PI) || requiredBearingDrone - headingDrone > M_PI)
            {
                [_deviceController setYaw:-10];
            }
//            else
//            {
//                [_deviceController setYaw:0];
//            }
        }
        else
        {
            [_deviceController setYaw:0];
        }
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

- (IBAction)endCommandClick:(id)sender
{
    [_socket emitObjc:@"EndCommand" withItems:[[NSArray alloc] init]];
    
    [_endCommandButton setAlpha:0.0];
    _commandLabel.text = @"";
}

- (IBAction)resetNorthClick:(id)sender
{
    compassDisplacement = yawDrone;
}

@end
