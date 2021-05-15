//
//  ViewController.swift
//  dial3
//
//  Created by yamada.468@gmail.com on 2021/05/01.
//

import Cocoa

class ViewController: NSViewController {
    @IBOutlet var view1: View1!
    
    private var currentPoint: NSPoint? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    override func mouseDown(with event: NSEvent) {
        let p:NSPoint = event.locationInWindow
        currentPoint = self.view.convert(p, from: nil)
        self.view.setNeedsDisplay(self.view.bounds)
    }

    override func mouseDragged(with event: NSEvent) {
        let previosPoint:NSPoint = currentPoint!
        let p:NSPoint = event.locationInWindow
        currentPoint = self.view.convert(p, from: nil)
        
        let distance_x = currentPoint!.x - previosPoint.x
        let distance_y = currentPoint!.y - previosPoint.y
        let windowFrame: NSRect = self.view.window!.frame
        var windowOrigin:NSPoint = windowFrame.origin
        windowOrigin.x += distance_x
        windowOrigin.y += distance_y
        currentPoint!.x -= distance_x
        currentPoint!.y -= distance_y
        
        self.view.window?.setFrameOrigin(windowOrigin)
        self.view.setNeedsDisplay(self.view.bounds)
    }
    
    override func mouseUp(with event: NSEvent) {
        let p:NSPoint = event.locationInWindow
        currentPoint = self.view.convert(p, from: nil)
        self.view.setNeedsDisplay(self.view.bounds)
    }
    
    func setFunc(f: Int) {
        view1?.currentFunc = f
    }
    
    func setValue(s: String) {
        view1?.value = s
    }
}

