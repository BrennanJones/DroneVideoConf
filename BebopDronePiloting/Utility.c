//
//  Utility.c
//  BebopDronePiloting
//
//  Created by Interactions Lab on 2015-05-27.
//  Copyright (c) 2015 Parrot. All rights reserved.
//

#include "Utility.h"

#include <math.h>

inline double radiansToDegrees(double radians)
{
    return radians * (180.0 / M_PI);
}

inline double degreesToRadians(double degrees)
{
    return degrees * (M_PI / 180.0);
}
