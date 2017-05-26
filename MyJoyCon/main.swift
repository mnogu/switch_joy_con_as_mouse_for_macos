//
// Copyright 2017 Muneyuki Noguchi
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import IOKit.hid
import Quartz

let manager = IOHIDManagerCreate(kCFAllocatorDefault,
                                 IOOptionBits(kIOHIDOptionsTypeNone))
let multiple = [
    [
        kIOHIDDeviceUsagePageKey: kHIDPage_GenericDesktop as NSNumber,
        kIOHIDDeviceUsageKey: kHIDUsage_GD_Joystick as NSNumber
    ], [
        kIOHIDDeviceUsagePageKey: kHIDPage_GenericDesktop as NSNumber,
        kIOHIDDeviceUsageKey: kHIDUsage_GD_GamePad as NSNumber
    ]] as CFArray
IOHIDManagerSetDeviceMatchingMultiple(manager, multiple)

let matchingCallback: IOHIDDeviceCallback = {context, result, sender, device in
    print("Match")
    let name = IOHIDDeviceGetProperty(device, kIOHIDProductKey as CFString) as! String
    print(name)

    let leftName = "Joy-Con (L)"
    let rightName = "Joy-Con (R)"
    if name != leftName && name != rightName {
        return
    }

    IOHIDDeviceOpen(device, IOOptionBits(kIOHIDOptionsTypeNone))
    IOHIDDeviceScheduleWithRunLoop(device, CFRunLoopGetCurrent(), CFRunLoopMode.commonModes.rawValue)
    let callback: IOHIDValueCallback = {context, result, sender, value in
        if let context = context {
            let isRight = context.load(as: Bool.self)

            let element = IOHIDValueGetElement(value)
            let cookie = IOHIDElementGetCookie(element)
            if cookie != 1202 {
                return
            }
            let code = IOHIDValueGetIntegerValue(value)
            print(cookie, code)

            let event = CGEvent.init(source: nil)
            if let event = event {
                if code < 0 || code > 7 {
                    return
                }
                let point = event.location
                let distance: CGFloat = 10.0
                let angle: CGFloat = CGFloat(code) * CGFloat.pi / 4 + (isRight ? CGFloat.pi : 0)
                CGWarpMouseCursorPosition(CGPoint(x: point.x + distance * cos(angle),
                                                  y: point.y + distance * sin(angle)))
            }
        }
    }
    let context = UnsafeMutableRawPointer.allocate(bytes: 1, alignedTo: 4)
    context.storeBytes(of: name == rightName, as: Bool.self)
    IOHIDDeviceRegisterInputValueCallback(device, callback, context)
}
IOHIDManagerRegisterDeviceMatchingCallback(manager, matchingCallback,nil)

let removalCallback: IOHIDDeviceCallback = {context, result, sender, device in
    print("Remove")
}
IOHIDManagerRegisterDeviceRemovalCallback(manager, removalCallback, nil)
IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))

CFRunLoopRun()

IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
IOHIDManagerUnscheduleFromRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)

