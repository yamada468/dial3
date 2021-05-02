//
//  driver.m
//  dial3
//
//  Created by yamada.468@gmail.com on 2021/05/02.
//

#import "Driver.h"
#import "dial3-Swift.h"

@implementation Driver

IOHIDManagerRef manager;
AppDelegate *instance;

int choice = CHOICE_OFF;
int mode = MODE_VERTICAL;
int kando_cnt = 0;

-(void) test {
    NSLog(@"This is test function.");
    if (NULL != instance) {
        [instance delmemberWithA:1];
    }
}

-(void) runHid {
    [NSThread detachNewThreadSelector:@selector(_run) toTarget:self withObject:nil];
}

-(void) _run {
    CFRunLoopRun();

//    // デモ
//    [instance sync_showWindow];
//    while (1) {
//        [NSThread sleepForTimeInterval:2.0];
//        _right();
//        NSLog(@"@@@@ _run : %d", mode);
//        [instance async_setFuncWithF:mode];
//    }
}

void _right() {
    mode++;
    if (MODE_VERTICAL > mode) {
        mode = MODE_VERTICAL;
    } else if (MODE_3 == mode) {
        mode = MODE_VOLUME;
    } else if (MODE_5 == mode) {
        mode = MODE_BRITE;
    } else if (MODE_7 <= mode) {
        mode = MODE_VERTICAL;
    }
}

void _left() {
    mode--;
    if (MODE_VERTICAL > mode) {
        mode = MODE_BRITE;
    } else if (MODE_3 == mode) {
        mode = MODE_ZOOM;
    } else if (MODE_5 == mode) {
        mode = MODE_VOLUME;
    } else if (MODE_7 <= mode) {
        mode = MODE_BRITE;
    }
}

void _cleanUpHid() {
    if (NULL != manager) {
        CFRelease(manager);
    }
    manager = NULL;
}

-(BOOL) initHid:(AppDelegate *) _instance {
    instance = _instance;
    _cleanUpHid();
    manager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDManagerOptionNone);
    NSDictionary* criteria = @{
        @kIOHIDDeviceUsagePageKey: @(kHIDPage_GenericDesktop),
        @kIOHIDDeviceUsageKey: @(kHIDUsage_GD_SystemMultiAxisController),
        @kIOHIDVendorIDKey: @(0x1234),
        @kIOHIDProductIDKey: @(0x5678),
    };

    IOHIDManagerSetDeviceMatching(manager, (__bridge CFDictionaryRef)criteria);
    IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    IOReturn ret = IOHIDManagerOpen(manager, kIOHIDOptionsTypeSeizeDevice);

    if (ret != kIOReturnSuccess) {
        NSLog(@"Failed to open your HID");
        _cleanUpHid();
        return FALSE;
    }

    IOHIDManagerRegisterInputValueCallback(manager, &_handleInput, NULL);
    NSLog(@"HID init successfly");
    return TRUE;
}

void _handleInput(void *context, IOReturn result, void *sender, IOHIDValueRef valueRef) {
    NSLog(@"Run at");
    if (result != kIOReturnSuccess) {
        return;
    }

    IOHIDElementRef elementRef = IOHIDValueGetElement(valueRef);
    uint32_t usage = IOHIDElementGetUsage(elementRef);
    long value = IOHIDValueGetIntegerValue(valueRef);
    
    if (usage == kHIDUsage_GD_Pointer) {
        NSLog(@"Click event, usage : 0x%x, value : %ld", usage, value);
        kando_cnt = 0;
        
        if (choice == CHOICE_OFF) {
            choice = CHOICE_ON;
            [instance sync_showWindow];
        } else { // CHOICE_ON
            choice = CHOICE_OFF;
            [instance sync_closeWindow];
        }
    } else {
        NSLog(@"Dial event, usage : 0x%x, value : %ld, kando : %d", usage, value, kando_cnt);
        
        if (choice == CHOICE_OFF) {
            _changeSignal(usage, value);
        } else { // CHOICE_ON
            _changeMode(usage, value);
        }
    }
}

void _changeMode(uint32_t usage, long value) {
    if (usage == kHIDUsage_GD_Dial) {
        int kando = KANDO_SCROLL; //KANDO_ZOOM

        if (kando_cnt >= kando) {
            kando_cnt = 0;
            
            if (0 > value) {
                _left();
            } else if (0 < value) {
                _right();
            }
            NSLog(@"_changeMode : %d", mode);
            [instance async_setFuncWithF:mode];
        } else {
            kando_cnt++;
        }
    }
}

void _changeSignal(uint32_t usage, long value) {
    if (usage == kHIDUsage_GD_Dial) {
        int kando = KANDO_SCROLL;
        if (MODE_ZOOM == mode) {
            kando = KANDO_ZOOM;
        }
        if (kando_cnt >= kando) {
            kando_cnt = 0;
            
            NSMutableArray *events = [NSMutableArray array];
            CGEventSourceRef src = CGEventSourceCreate(kCGEventSourceStateHIDSystemState);
            CGEventRef eventRef = NULL;

            if (MODE_VERTICAL == mode) {
                if (0 > value) {
                    eventRef = CGEventCreateScrollWheelEvent(src, kCGScrollEventUnitPixel, 1, -1 * SCROLL_PX, 0);
                } else if (0 < value) {
                    eventRef = CGEventCreateScrollWheelEvent(src, kCGScrollEventUnitPixel, 1, SCROLL_PX, 0);
                }
            } else if (MODE_HORIZONAL == mode) {
                if (0 > value) {
                    eventRef = CGEventCreateScrollWheelEvent(src, kCGScrollEventUnitPixel, 2, 0, -1 * SCROLL_PX);
                } else if (0 < value) {
                    eventRef = CGEventCreateScrollWheelEvent(src, kCGScrollEventUnitPixel, 2, 0, SCROLL_PX);
                }
            } else if (MODE_ZOOM == mode) {
                if (0 > value) {
                    eventRef = CGEventCreateKeyboardEvent(NULL, kVK_ANSI_KeypadPlus, true);
                } else if (0 < value) {
                    eventRef = CGEventCreateKeyboardEvent(NULL, kVK_ANSI_Minus, true);
                }
            } else if (MODE_VOLUME == mode) {
                
            } else if (MODE_BRITE == mode) {
                
            }
            
            if (NULL != eventRef) {
                CGEventSetFlags(eventRef, kCGEventFlagMaskCommand);
                [events addObject:[NSValue valueWithPointer:eventRef]];

                for (NSValue *event in events) {
                    CGEventRef eventRef = (CGEventRef)[event pointerValue];
                    CGEventPost(kCGHIDEventTap, eventRef);
                    CFRelease(eventRef);
                }
            }
        } else {
            kando_cnt++;
        }
    }
}
@end