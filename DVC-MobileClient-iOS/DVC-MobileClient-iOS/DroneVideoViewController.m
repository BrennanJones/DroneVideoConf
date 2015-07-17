//
//  DroneVideoViewController.m
//  DVC-MobileClient-iOS
//


#import "DroneVideoViewController.h"

#import "DeviceController.h"
#import "DroneVideoView.h"
#import "DVCTabBarController.h"


@interface DroneVideoViewController ()

@end


@implementation DroneVideoViewController

#pragma mark Initialization Methods

- (void)loadView
{
    [super loadView];
    NSLog(@"DroneVideoViewController: loadView ...");
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSLog(@"DroneVideoViewController: viewWillAppear ... ");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tabBarController.tabBar setBarStyle:UIBarStyleBlack];
        [self.tabBarController.tabBar setTranslucent:YES];
    });
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSLog(@"DroneVideoViewController: viewDidAppear ... ");
    
    if (((DVCTabBarController *)self.tabBarController).deviceController != nil)
    {
        [((DVCTabBarController *)self.tabBarController).deviceController setDroneVideoDelegate:self];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    NSLog(@"DroneVideoViewController: viewDidDisappear ... ");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}


#pragma mark Drone Event Handler Methods

- (void)onFrameComplete:(DeviceController *)deviceController frame:(uint8_t *)frame frameSize:(uint32_t)frameSize;
{
    NSLog(@"DroneVideoViewController: onFrameComplete ...");
    
    [_droneVideoView updateVideoViewWithFrame:frame frameSize:frameSize];
}

@end
