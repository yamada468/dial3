//
//  driver.m
//  dial3
//
//  Created by yamada.468@gmail.com on 2021/05/02.
//

#import "Driver.h"
#import "dial3-Swift.h"
#import <CoreAudio/CoreAudio.h>
#import <AudioToolbox/AudioToolbox.h>

@implementation Driver

IOHIDManagerRef manager;
AppDelegate *instance;

AudioObjectPropertyAddress audioaddr;
AudioDeviceID outputAudioDeviceID = 0U;

int choice = CHOICE_OFF;
int mode = MODE_VERTICAL;
int kando_cnt = 0;

-(void) test {
    NSLog(@"This is test function.");
    if (NULL != instance) {
        [instance delmemberWithA:mode];
    }
}

-(void) runHid {
    [NSThread detachNewThreadSelector:@selector(_run) toTarget:self withObject:nil];
}

-(void) _run {
    IOHIDManagerRegisterInputValueCallback(manager, &_handleInput, NULL);
    NSLog(@"_run worker thread. : 0x%x", _handleInput);
    CFRunLoopRun();

//    // デモ
//    [instance async_showWindow];
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
//        @kIOHIDVendorIDKey: @(0x2341),  // Arduino
//        @kIOHIDProductIDKey: @(0x8036), // Leonard
    };

    IOHIDManagerSetDeviceMatching(manager, (__bridge CFDictionaryRef)criteria);
    IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    IOReturn ret = IOHIDManagerOpen(manager, kIOHIDOptionsTypeSeizeDevice);

    if (ret != kIOReturnSuccess) {
        NSLog(@"Failed to open your HID");
        _cleanUpHid();
        return FALSE;
    }

    //IOHIDManagerRegisterInputValueCallback(manager, &_handleInput, NULL);
    NSLog(@"HID init successfly");

    
    audioaddr.mSelector = kAudioHardwarePropertyDefaultOutputDevice;
    audioaddr.mScope = kAudioObjectPropertyScopeGlobal;
    audioaddr.mElement = kAudioObjectPropertyElementMaster;
    
    UInt32 size = sizeof(AudioDeviceID);
    OSStatus err = AudioObjectGetPropertyData(kAudioObjectSystemObject, &audioaddr, 0, NULL, &size, &outputAudioDeviceID);
    if (err == noErr) {
        NSLog(@"AudioDeviceID : %d", outputAudioDeviceID);
        
        audioaddr.mSelector = kAudioHardwareServiceDeviceProperty_VirtualMasterVolume;
        audioaddr.mScope = kAudioObjectPropertyScopeOutput;
        audioaddr.mElement = kAudioObjectPropertyElementMaster;
        Float32 volume;
        AudioObjectGetPropertyData(outputAudioDeviceID, &audioaddr, 0, NULL, &size, &volume);

        NSLog(@"current volume : %lf", volume);
    }
    
    return TRUE;
}

void _handleInput(void *context, IOReturn result, void *sender, IOHIDValueRef valueRef) {
    if (result != kIOReturnSuccess) {
        return;
    }

    IOHIDElementRef elementRef = IOHIDValueGetElement(valueRef);
    uint32_t usage = IOHIDElementGetUsage(elementRef);
    long value = IOHIDValueGetIntegerValue(valueRef);
    
    if (usage == kHIDUsage_GD_Pointer) {
        NSLog(@"Click event, usage : 0x%x, value : %ld", usage, value);
        kando_cnt = 0;
        
        if (1 == value) {
            if (choice == CHOICE_OFF) {
                choice = CHOICE_ON;
                
                if (mode == MODE_VERTICAL) {
                    mode = MODE_HORIZONAL;
                } else {
                    mode = MODE_VERTICAL;
                }
                
                [instance async_showWindow];
                [instance async_setFuncWithF:mode];
            } else if (choice == CHOICE_ON) {
                if (mode == MODE_VOLUME) {
                    choice = CHOICE_SET;
                    
                    if (0 != outputAudioDeviceID) {
                        UInt32 size = sizeof(AudioDeviceID);
                        Float32 volume;
                        AudioObjectGetPropertyData(outputAudioDeviceID, &audioaddr, 0, NULL, &size, &volume);
                        volume = round(volume*100)/100;
                        NSString *s = [NSString stringWithFormat:@"%1.3f", volume];
                        NSLog(@"volume : %@", s);
                        [instance async_setValueWithS:s];
                    }
                } else {
                    choice = CHOICE_OFF;
                    [instance async_closeWindow];
                }
            } else if (choice == CHOICE_SET) {
                choice = CHOICE_OFF;
                mode = MODE_VERTICAL;
                [instance async_setValueWithS:@""];
                [instance async_closeWindow];
            }
        }
    } else {
        NSLog(@"Dial event, usage : 0x%x, value : %ld, kando : %d", usage, value, kando_cnt);
        
        if (choice == CHOICE_ON) {
            _changeMode(usage, value);
        } else { // CHOICE_OFF or CHOICE_SET
            _changeSignal(usage, value);
        }
    }
}

void _changeMode(uint32_t usage, long value) {
    if (usage == kHIDUsage_GD_Dial) {
        int kando = KANDO_ZOOM; // KANDO_SCROLL

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
        if ((MODE_ZOOM == mode) || (MODE_VOLUME == mode) || (MODE_BRITE == mode)) {
            kando = KANDO_ZOOM;
        }
        if (kando_cnt >= kando) {
            kando_cnt = 0;
            
            NSMutableArray *events = [NSMutableArray array];
            CGEventSourceRef src = CGEventSourceCreate(kCGEventSourceStateHIDSystemState);
            
            if (MODE_VERTICAL == mode) {
                if (0 > value) {
                    CGEventRef eventRef = CGEventCreateScrollWheelEvent(src, kCGScrollEventUnitPixel, 1, -1 * SCROLL_PX, 0);
                    [events addObject:[NSValue valueWithPointer:eventRef]];
                } else if (0 < value) {
                    CGEventRef eventRef = CGEventCreateScrollWheelEvent(src, kCGScrollEventUnitPixel, 1, SCROLL_PX, 0);
                    [events addObject:[NSValue valueWithPointer:eventRef]];
                }
            } else if (MODE_HORIZONAL == mode) {
                if (0 > value) {
                    CGEventRef eventRef = CGEventCreateScrollWheelEvent(src, kCGScrollEventUnitPixel, 2, 0, -1 * SCROLL_PX);
                    [events addObject:[NSValue valueWithPointer:eventRef]];
                } else if (0 < value) {
                    CGEventRef eventRef = CGEventCreateScrollWheelEvent(src, kCGScrollEventUnitPixel, 2, 0, SCROLL_PX);
                    [events addObject:[NSValue valueWithPointer:eventRef]];
                }
            } else if (MODE_ZOOM == mode) {
                if (0 > value) {
                    CGEventRef eventRef = CGEventCreateKeyboardEvent(NULL, kVK_ANSI_KeypadPlus, true);
                    CGEventSetFlags(eventRef, kCGEventFlagMaskCommand);
                    [events addObject:[NSValue valueWithPointer:eventRef]];
                } else if (0 < value) {
                    CGEventRef eventRef = CGEventCreateKeyboardEvent(NULL, kVK_ANSI_Minus, true);
                    CGEventSetFlags(eventRef, kCGEventFlagMaskCommand);
                    [events addObject:[NSValue valueWithPointer:eventRef]];
                }
            } else if (MODE_VOLUME == mode) {
                if (0 != outputAudioDeviceID) {
                    UInt32 size = sizeof(AudioDeviceID);
                    Float32 volume;
                    AudioObjectGetPropertyData(outputAudioDeviceID, &audioaddr, 0, NULL, &size, &volume);
                    if (0 > value) {
                        volume += VOLUME_STEP;
                    } else if (0 < value) {
                        volume -= VOLUME_STEP;
                    }
                    if (volume > VOLUME_MAX) {
                        volume = VOLUME_MAX;
                    } else if (volume < VOLUME_MIN) {
                        volume = VOLUME_MIN;
                    }
                    volume = round(volume*100)/100;
                    NSString *s = [NSString stringWithFormat:@"%1.3f", volume];
                    NSLog(@"volume : %@", s);
                    [instance async_setValueWithS:s];
                    size = sizeof(Float32);
                    AudioObjectSetPropertyData(outputAudioDeviceID, &audioaddr, 0, NULL, size, &volume);
                }
            } else if (MODE_BRITE == mode) {
                if (0 > value) {
                    CGEventRef eventRef1 = CGEventCreateKeyboardEvent(NULL, kVK_F15, true);
                    [events addObject:[NSValue valueWithPointer:eventRef1]];

                    CGEventRef eventRef2 = CGEventCreateKeyboardEvent(NULL, kVK_F15, false);
                    [events addObject:[NSValue valueWithPointer:eventRef2]];
                } else if (0 < value) {
                    CGEventRef eventRef1 = CGEventCreateKeyboardEvent(NULL, kVK_F14, true);
                    [events addObject:[NSValue valueWithPointer:eventRef1]];

                    CGEventRef eventRef2 = CGEventCreateKeyboardEvent(NULL, kVK_F14, false);
                    [events addObject:[NSValue valueWithPointer:eventRef2]];
                }
            }
            
            for (NSValue *event in events) {
                CGEventRef eventRef = (CGEventRef)[event pointerValue];
                CGEventPost(kCGHIDEventTap, eventRef);
                CFRelease(eventRef);
            }
        } else {
            kando_cnt++;
        }
    }
}
@end
