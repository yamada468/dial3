//
//  Window1.swift
//  dial3
//
//  Created by yamada.468@gmail.com on 2021/05/01.
//

import Cocoa

class WindowController: NSWindowController {
    func moveToCursor() {
        let half = (window?.frame.width)! / 2
        var point: NSPoint = NSEvent.mouseLocation
        point.x -= half
        point.y -= half
        if (half > point.x) {
            point.x = 0
        }
        if (half > point.y) {
            point.y = 0
        }
        window?.setFrameOrigin(point)
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        window?.level = .floating
        window?.isOpaque = false
        window?.backgroundColor = NSColor(white: 1, alpha: 0)

        moveToCursor()
    }
    
    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        
        moveToCursor()
    }
}
