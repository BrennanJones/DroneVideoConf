//
//  SocketIOWrapper.h
//  DVC-MobileClient-iOS
//

#import <Foundation/Foundation.h>

#import "DVC-Swift.h"

@interface SocketIOWrapper : NSObject

#if __IPHONE_OS_VERSION_MAX_ALLOWED < 80300
+ (void)emit:(SocketIOClient *)socket withEvent:(NSString *)event withItems:(NSArray *)items;
#else
+ (void)emit:(SocketIOClient * __nonnull)socket withEvent:(NSString * __nonnull)event withItems:(NSArray * __nonnull)items;
#endif

@end
