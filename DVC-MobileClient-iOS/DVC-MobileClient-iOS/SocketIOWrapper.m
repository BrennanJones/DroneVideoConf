//
//  SocketIOWrapper.m
//  DVC-MobileClient-iOS
//

#import "SocketIOWrapper.h"

#import "DVC-Swift.h"

@implementation SocketIOWrapper

#if __IPHONE_OS_VERSION_MAX_ALLOWED < 80300
+ (void)emit:(SocketIOClient *)socket withEvent:(NSString *)event withItems:(NSArray *)items
#else
+ (void)emit:(SocketIOClient * __nonnull)socket withEvent:(NSString * __nonnull)event withItems:(NSArray * __nonnull)items
#endif
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED < 80300
    [socket emitObjc:event withItems:items];
#else
    [socket emit:event withItems:items];
#endif
}

@end
