//
//  VideoChatViewController.m
//  DVC-MobileClient-iOS
//


#import "VideoChatViewController.h"

#import <AVFoundation/AVFoundation.h>
#import "Peer.h"
#import "Utility.h"


// Padding space for local video view with its parent.
static CGFloat const kLocalViewPadding = 20;

BOOL videoCallViewsAreEstablished = FALSE;


@interface VideoChatViewController () <RTCEAGLVideoViewDelegate>

@property(nonatomic, assign) UIInterfaceOrientation statusBarOrientation;
@property(nonatomic, strong) RTCEAGLVideoView* localVideoView;
@property(nonatomic, strong) RTCEAGLVideoView* remoteVideoView;
@property(nonatomic, strong) Peer *peer;
@property(nonatomic) BOOL isInitiater;

@end


@implementation VideoChatViewController
{
    RTCVideoTrack* _localVideoTrack;
    RTCVideoTrack* _remoteVideoTrack;
    CGSize _localVideoSize;
    CGSize _remoteVideoSize;
}


@synthesize idField = _idField;
@synthesize isInitiater = _isInitiater;
@synthesize peer = _peer;


- (void)loadView
{
    [super loadView];
    NSLog(@"VideoChatViewController: loadView ...");
    
    for (UIViewController *viewController in self.tabBarController.viewControllers)
    {
        if ([viewController isKindOfClass:[MainViewController class]])
        {
            [(MainViewController *)viewController setServerConnectionDelegate:self];
        }
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSessionRouteChange:) name:AVAudioSessionRouteChangeNotification object:nil];
    
    self.remoteVideoView =
    [[RTCEAGLVideoView alloc] initWithFrame:self.blackView.bounds];
    self.remoteVideoView.delegate = self;
    self.remoteVideoView.transform = CGAffineTransformMakeScale(-1, 1);
    [self.blackView addSubview:self.remoteVideoView];
    
    self.localVideoView =
    [[RTCEAGLVideoView alloc] initWithFrame:self.blackView.bounds];
    self.localVideoView.delegate = self;
    [self.blackView addSubview:self.localVideoView];
    
    self.statusBarOrientation =
    [UIApplication sharedApplication].statusBarOrientation;
    self.roomInput.delegate = self;
    [self.roomInput becomeFirstResponder];
    
    _isInitiater = YES;
    
    if (!_isInitiater) { return; }
    [_peer disconnect];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"VideoChatViewController: viewDidLoad ...");
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSLog(@"VideoChatViewController: viewWillAppear ... ");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tabBarController.tabBar setBarStyle:UIBarStyleBlack];
        [self.tabBarController.tabBar setTranslucent:YES];
    });
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSLog(@"VideoChatViewController: viewDidAppear ... ");
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    NSLog(@"VideoChatViewController: viewDidDisappear ... ");
}

- (void)viewDidLayoutSubviews
{
    if (self.statusBarOrientation != [UIApplication sharedApplication].statusBarOrientation)
    {
        self.statusBarOrientation =
        [UIApplication sharedApplication].statusBarOrientation;
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"StatusBarOrientationDidChange"
         object:nil];
    }
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
    NSLog(@"VideoChatViewController: enteredBackground ... ");
}

- (void)enterForeground:(NSNotification*)notification
{
    NSLog(@"VideoChatViewController: enterForeground ... ");
}

- (void)applicationWillResignActive:(UIApplication*)application
{
    [self disconnect];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)didSessionRouteChange:(NSNotification *)notification
{
    NSDictionary *interuptionDict = notification.userInfo;
    NSInteger routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    
    switch (routeChangeReason) {
        case AVAudioSessionRouteChangeReasonCategoryChange: {
            // Set speaker as default route
            NSError* error;
            [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];
        }
            break;
            
        default:
            break;
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}


#pragma mark ServerConnectionDelegate

- (void)onConnectToServer:(NSString *)serverURL
{
    // Create Configuration object.
    NSDictionary *config = @{@"host": serverURL,
                             @"port": @(9876),
                             @"id": @"1",
                             @"path": @"/dvc",
                             @"secure": @(NO)};
    
    __block typeof(self) __self = self;
    
    // Create Instance of Peer.
    _peer = [[Peer alloc] initWithConfig:config];
    
    // Set Callbacks.
    _peer.onOpen = ^(NSString *id) {
        NSLog(@"onOpen");
        __self.idField.text = id;
    };
    
    _peer.onCall = ^(RTCSessionDescription *sdp) {
        NSLog(@"onCall");
        [__self peerClient:__self.peer didReceiveOfferWithSdp:sdp];
    };
    
    _peer.onReceiveLocalVideoTrack = ^(RTCVideoTrack *videoTrack) {
        NSLog(@"onReceiveLocalVideoTrack");
        [__self peerClient:__self.peer didReceiveLocalVideoTrack:videoTrack];
    };
    
    _peer.onRemoveLocalVideoTrack = ^() {
        NSLog(@"onRemoveLocalVideoTrack");
        [__self peerClientWillRemoveLocalVideoTrack:__self.peer];
    };
    
    _peer.onReceiveRemoteVideoTrack = ^(RTCVideoTrack *videoTrack) {
        NSLog(@"onReceiveRemoteVideoTrack");
        [__self peerClient:__self.peer didReceiveRemoteVideoTrack:videoTrack];
    };
    
    _peer.onError = ^(NSError *error) {
        NSLog(@"onError: %@", error);
        [__self peerClient:__self.peer didError:error];
    };
    
    _peer.onClose = ^() {
        NSLog(@"onClose");
        [__self resetUI];
    };
    
    // Start signaling to peerjs-server.
    [_peer start:^(NSError *error)
     {
         if (error)
         {
             NSLog(@"Error while openning websocket: %@", error);
         }
     }];
}

- (void)onDisconnectFromServer
{
    [self disconnect];
}


#pragma mark - ARDAppClientDelegate

- (void)peerClient:(Peer *)client didReceiveOfferWithSdp:(RTCSessionDescription *)sdp
{
    NSLog(@"setup CaptureSession!");
    _isInitiater = NO;
    [_roomInput resignFirstResponder];
    _roomInput.hidden = YES;
    self.instructionsView.hidden = YES;
    self.logView.hidden = NO;
    [self setupCaptureSession];
    
    [client answerWithSdp:sdp];
}

- (void)peerClient:(Peer *)client didReceiveLocalVideoTrack:(RTCVideoTrack *)localVideoTrack
{
    _localVideoTrack = localVideoTrack;
    [_localVideoTrack addRenderer:self.localVideoView];
    self.localVideoView.hidden = NO;
    
    videoCallViewsAreEstablished = TRUE;
}

- (void)peerClientWillRemoveLocalVideoTrack:(Peer *)client
{
    videoCallViewsAreEstablished = FALSE;
    
    [_localVideoTrack removeRenderer:self.localVideoView];
    _localVideoTrack = nil;
    [self.localVideoView renderFrame:nil];
}

- (void)peerClient:(Peer *)client didReceiveRemoteVideoTrack:(RTCVideoTrack *)remoteVideoTrack
{
    _remoteVideoTrack = remoteVideoTrack;
    [_remoteVideoTrack addRenderer:self.remoteVideoView];
}

- (void)peerClient:(Peer *)client didError:(NSError *)error
{
    [Utility showAlertWithTitle:@"Video Chat Error" withMessage:[NSString stringWithFormat:@"%@", error]];
    [self disconnect];
}


#pragma mark - RTCEAGLVideoViewDelegate

- (void)videoView:(RTCEAGLVideoView*)videoView didChangeVideoSize:(CGSize)size
{
    if (videoView == self.localVideoView) {
        _localVideoSize = size;
    } else if (videoView == self.remoteVideoView) {
        _remoteVideoSize = size;
    } else {
        NSParameterAssert(NO);
    }
    [self updateVideoViewLayout];
}


#pragma mark - UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField*)textField
{
    NSString* dstId = textField.text;
    
    if ([dstId length] == 0) {
        return;
    }
    
    _isInitiater = YES;
    textField.hidden = YES;
    self.instructionsView.hidden = YES;
    self.logView.hidden = NO;
    [_peer callWithId:dstId];
    [self setupCaptureSession];
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
    // There is no other control that can take focus, so manually resign focus
    // when return (Join) is pressed to trigger |textFieldDidEndEditing|.
    [textField resignFirstResponder];
    return YES;
}


#pragma mark - Private

- (void)disconnect
{
    [self resetUI];
    [_peer disconnect];
}

- (void)resetUI
{
    [self.roomInput resignFirstResponder];
    self.roomInput.text = nil;
    self.roomInput.hidden = NO;
    self.logView.hidden = YES;
    self.logView.text = nil;
    
    if (_localVideoTrack)
    {
        [_localVideoTrack removeRenderer:self.localVideoView];
        _localVideoTrack = nil;
        [self.localVideoView renderFrame:nil];
    }
    
    if (_remoteVideoTrack)
    {
        [_remoteVideoTrack removeRenderer:self.remoteVideoView];
        _remoteVideoTrack = nil;
        [self.remoteVideoView renderFrame:nil];
    }
    
    self.blackView.hidden = YES;
}

- (void)setupCaptureSession
{
    self.blackView.hidden = NO;
    [self updateVideoViewLayout];
}

- (void)updateVideoViewLayout
{
    CGSize defaultAspectRatio = CGSizeMake(4, 3);
    CGSize localAspectRatio = CGSizeEqualToSize(_localVideoSize, CGSizeZero) ? defaultAspectRatio : _localVideoSize;
    CGSize remoteAspectRatio = CGSizeEqualToSize(_remoteVideoSize, CGSizeZero) ? defaultAspectRatio : _remoteVideoSize;
    
    CGRect remoteVideoFrame = AVMakeRectWithAspectRatioInsideRect(remoteAspectRatio, self.blackView.bounds);
    self.remoteVideoView.frame = remoteVideoFrame;
    
    CGRect localVideoFrame = AVMakeRectWithAspectRatioInsideRect(localAspectRatio, self.blackView.bounds);
    localVideoFrame.size.width = localVideoFrame.size.width / 3;
    localVideoFrame.size.height = localVideoFrame.size.height / 3;
    localVideoFrame.origin.x = CGRectGetMaxX(self.blackView.bounds) - localVideoFrame.size.width - kLocalViewPadding;
    localVideoFrame.origin.y = CGRectGetMaxY(self.blackView.bounds) - localVideoFrame.size.height - kLocalViewPadding;
    self.localVideoView.frame = localVideoFrame;
}

- (IBAction)swapCameras:(id)sender
{
    if (videoCallViewsAreEstablished)
    {
        [_peer swapCaptureDevicePosition];
    }
}

- (IBAction)finishCall:(id)sender
{
    [self disconnect];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end