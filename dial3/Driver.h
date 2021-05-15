//
//  Driver.h
//  dial3
//
//  Created by yamada.468@gmail.com on 2021/05/02.
//

#ifndef Driver_h
#define Driver_h

#import <Foundation/Foundation.h>
#import <IOKit/hid/IOHIDManager.h>
#include <Carbon/Carbon.h>

#define CHOICE_OFF     0
#define CHOICE_ON      1
#define CHOICE_SET     2

#define MODE_VERTICAL  0
#define MODE_HORIZONAL 1
#define MODE_ZOOM      2
#define MODE_3         3
#define MODE_VOLUME    4
#define MODE_5         5
#define MODE_BRITE     6
#define MODE_7         7

#define KANDO_ZOOM     7
#define KANDO_SCROLL   3
#define SCROLL_PX      150
#define VOLUME_STEP    0.01
#define VOLUME_MAX     0.5
#define VOLUME_MIN     0.0

@class AppDelegate;

@interface Driver : NSObject
-(void) test;
-(BOOL) initHid:(AppDelegate *) _instance;
-(void) runHid;
@end

#endif /* Driver_h */
