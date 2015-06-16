//
//  Utility.c
//  DVC-MobileClient-iOS
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
