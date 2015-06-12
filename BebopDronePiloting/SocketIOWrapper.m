//
//  SocketIOWrapper.m
//  BebopDronePiloting
//
//  Created by Brennan Jones on 2015-06-12.
//  Copyright (c) 2015 Parrot. All rights reserved.
//

#import "SocketIOWrapper.h"

#import "DVC-Swift.h"

@implementation SocketIOWrapper

+ (void)emit:(SocketIOClient * __nonnull)socket withEvent:(NSString * __nonnull)event withItems:(NSArray * __nonnull)items
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED < __IPHONE_8_3
    [socket emitObjc:event withItems:items];
#else
    [socket emit:event withItems:items];
#endif
}

@end
