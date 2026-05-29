//
//  View1.swift
//  dial3
//
//  Created by yamada.468@gmail.com on 2021/05/01.
//

import Cocoa

class View1: NSView {
    @IBOutlet weak var label1: NSTextField!
    @IBOutlet weak var label2: NSTextField!
    
    public let unitDeg: Float = 45.0
    public var currentFunc: Int = 0
    {
        didSet {
            if (0 > currentFunc) {
                currentFunc = 0
            } else if (7 < currentFunc) {
                currentFunc = 7
            }
            
            if oldValue != currentFunc {
                setNeedsDisplay(bounds)
            }
        }
    }
    public var value: String = ""
    {
        didSet {
            if oldValue != value {
                setNeedsDisplay(bounds)
            }
        }
    }
    
    public let funcNames = [
        "スクロール縦",
        "スクロール横",
        "拡大 / 縮小",
        "3",
        "ボリューム",
        "5",
        "明るさ",
        "7"
    ]

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
        let halfWidth = frame.width / 2
        let halfHeight = frame.height / 2
        
        let centerX = frame.width / 2
        let centerY = frame.height / 2
        
        let fillColor: NSColor = NSColor(red: 0, green: 0, blue: 0.01, alpha: 0.9)
        let lightColor: NSColor = NSColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1)
        let arcColor: NSColor = NSColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 0.5)

        let outsideCircle = NSBezierPath(roundedRect: self.frame, xRadius: 360, yRadius: 360)
        fillColor.setFill()
        outsideCircle.fill()

        let innerRect: NSRect = NSRect(x: centerX / 2, y: centerY / 2, width: halfWidth, height: halfHeight)
        let centerCircle = NSBezierPath(roundedRect: innerRect, xRadius: 360, yRadius: 360)
        lightColor.setFill()
        centerCircle.fill()

        let start: Float = Float(currentFunc) * unitDeg - (unitDeg / 2)
        let end: Float = (Float(currentFunc) + 1) * unitDeg - (unitDeg / 2)

        let context = NSGraphicsContext.current
        let circleCenter = NSPoint(x: centerX, y: centerY)
        let circleRadius = halfWidth - 3
        let circleStartAngle = CGFloat(degreeToRadian(angle: start))
        let circleEndAngle = CGFloat(degreeToRadian(angle: end))
        
        context?.cgContext.setLineWidth(5.0)
        context?.cgContext.move(to: circleCenter)
        context?.cgContext.addArc(center: circleCenter, radius: circleRadius, startAngle: circleStartAngle, endAngle: circleEndAngle, clockwise: true)
        
        arcColor.setFill()
        context?.cgContext.fillPath()

        context?.cgContext.setLineWidth(5.0)
        context?.cgContext.addArc(center: circleCenter, radius: circleRadius, startAngle: circleStartAngle, endAngle: circleEndAngle, clockwise: true)

        NSColor.systemBlue.set()
        context?.cgContext.strokePath()
        
        label1.stringValue = funcNames[currentFunc]
        
        if ((4 == currentFunc) || (6 == currentFunc)) {
            label2.stringValue = value
        } else {
            label2.stringValue = ""
        }
    }
    
    func degreeToRadian(angle: Float) -> Double {
        let radian = Double(-angle + 90) * Double.pi / 180
        return radian
    }
}
