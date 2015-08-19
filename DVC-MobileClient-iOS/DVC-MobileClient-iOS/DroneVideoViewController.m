//
//  DroneVideoViewController.m
//  DVC-MobileClient-iOS
//


#import "DroneVideoViewController.h"

#import "DeviceController.h"
#import "DroneVideoView.h"
#import "DVCTabBarController.h"
#import "NSMutableArray+Queue.h"


BOOL viewIsVisible = false;

static const int VIDEO_FRAME_QUEUE_LOOP_IN_MS = 20;  // video frame queue loop interval
BOOL videoFrameQueueLoopRunning = false;


@interface DroneVideoViewController ()

@property (nonatomic, strong) DVCTabBarController *dvcTabBarController;

@property (nonatomic, strong) NSThread *videoFrameQueueLoopThread;
@property (nonatomic, strong) NSMutableArray *videoFrameQueue;
@property (nonatomic, strong) NSLock *videoFrameQueueLock;

@end


@implementation DroneVideoViewController

#pragma mark Initialization Methods

- (void)loadView
{
    [super loadView];
    NSLog(@"DroneVideoViewController: loadView ...");
    
    _dvcTabBarController = (DVCTabBarController *)(self.tabBarController);
    
    _videoFrameQueue = [NSMutableArray array];
    _videoFrameQueueLock = [[NSLock alloc] init];
    
    _videoFrameQueueLoopThread = [[NSThread alloc] initWithTarget:self selector:@selector(videoFrameQueueLoopRun) object:nil];
    videoFrameQueueLoopRunning = true;
    [_videoFrameQueueLoopThread start];
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
    
    viewIsVisible = true;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tabBarController.tabBar setBarStyle:UIBarStyleBlack];
        [self.tabBarController.tabBar setTranslucent:YES];
        
        NSArray *args = [[NSArray alloc] initWithObjects:@"DroneVideoView", nil];
        [_dvcTabBarController.socket emit:@"MCTabToggle" withItems:args];
    });
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSLog(@"DroneVideoViewController: viewDidAppear ... ");
    
    if (_dvcTabBarController.deviceController != nil)
    {
        [_dvcTabBarController.deviceController setDroneVideoDelegate:self];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    NSLog(@"DroneVideoViewController: viewWillDisappear ... ");
    
    viewIsVisible = false;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    NSLog(@"DroneVideoViewController: viewDidDisappear ... ");
}

- (void)viewWillUnload
{
    [super viewWillUnload];
    NSLog(@"DroneVideoViewController: viewWillUnload ... ");
    
    videoFrameQueueLoopRunning = false;
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
    
    if (viewIsVisible)
    {
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
            [_videoFrameQueueLock lock];
            if (_videoFrameQueue.count)
            {
                [_videoFrameQueue removeAllObjects];
            }
            [_videoFrameQueueLock unlock];
        }
        
        // Add next frame to queue.
        [_videoFrameQueueLock lock];
        [_videoFrameQueue enqueue:[[NSData alloc] initWithBytes:frame length:frameSize]];
        [_videoFrameQueueLock unlock];
    }
    else
    {
        [_videoFrameQueueLock lock];
        if (_videoFrameQueue.count)
        {
            [_videoFrameQueue removeAllObjects];
        }
        [_videoFrameQueueLock unlock];
    }
}


#pragma mark Video Frame Queue Methods

- (void)videoFrameQueueLoopRun
{
    while (videoFrameQueueLoopRunning)
    {
        [_videoFrameQueueLock lock];
        NSData *nextFrame = (NSData *)[_videoFrameQueue dequeue];
        [_videoFrameQueueLock unlock];
        
        if (nextFrame != nil)
        {
            [_droneVideoView updateVideoViewWithFrame:(uint8_t *)nextFrame.bytes frameSize:nextFrame.length];
        }
        
        usleep(VIDEO_FRAME_QUEUE_LOOP_IN_MS * 1000);
    }
}

@end
