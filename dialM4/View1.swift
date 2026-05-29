//
//  View1.swift
//  dialM4
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
    
    public let shortFuncNames = ["縦", "横", "ズーム", "3", "音量", "5", "輝度", "7"]

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let width = bounds.width
        let height = bounds.height
        let centerX = width / 2
        let centerY = height / 2
        let centerPoint = NSPoint(x: centerX, y: centerY)
        
        // 描画用のコンテキスト取得
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        // ウィンドウシャドウや発光エフェクトの準備
        context.saveGState()
        
        // ---- 1. 背景円 (グラスモーフィズムプレート) の描画 ----
        let outerRadius = min(width, height) / 2 - 12
        let outerPath = NSBezierPath(ovalIn: NSRect(x: centerX - outerRadius, y: centerY - outerRadius, width: outerRadius * 2, height: outerRadius * 2))
        
        // シャドウの適用 (立体的な浮き上がり)
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.5)
        shadow.shadowOffset = NSSize(width: 0, height: -5)
        shadow.shadowBlurRadius = 15
        shadow.set()
        
        // 背景グラデーション (明暗比を強めて立体アクリル調に)
        let bgGradient = NSGradient(starting: NSColor(white: 0.22, alpha: 0.88), ending: NSColor(white: 0.03, alpha: 0.88))
        bgGradient?.draw(in: outerPath, angle: -90)
        
        // シャドウをクリアしてエッジを描画
        context.restoreGState()
        context.saveGState()
        
        // ---- 立体的なベベル効果 (外円のハイライトとシャドウ) ----
        context.saveGState()
        // 下側のシャドウ線 (沈み込みの影)
        let outerShadowPath = outerPath.copy() as! NSBezierPath
        let transformDown = AffineTransform(translationByX: 0, byY: -1)
        outerShadowPath.transform(using: transformDown)
        outerShadowPath.lineWidth = 1.0
        NSColor.black.withAlphaComponent(0.5).setStroke()
        outerShadowPath.stroke()
        
        // 上側のハイライト線 (光源の反射光)
        let outerHighlightPath = outerPath.copy() as! NSBezierPath
        let transformUp = AffineTransform(translationByX: 0, byY: 1)
        outerHighlightPath.transform(using: transformUp)
        outerHighlightPath.lineWidth = 1.0
        NSColor(white: 1.0, alpha: 0.25).setStroke()
        outerHighlightPath.stroke()
        context.restoreGState()
        
        // リングの幅 (太さ) の定義
        let ringWidth: CGFloat = 55.0

        // ---- 2. 全セグメントの目盛りガイド描画 ----
        context.setLineWidth(1.0)
        NSColor(white: 1.0, alpha: 0.08).setStroke()
        for i in 0..<8 {
            let angle = Float(i) * unitDeg - (unitDeg / 2)
            let rad = CGFloat(degreeToRadian(angle: angle))
            context.move(to: NSPoint(x: centerX + cos(rad) * (outerRadius - ringWidth), y: centerY + sin(rad) * (outerRadius - ringWidth)))
            context.addLine(to: NSPoint(x: centerX + cos(rad) * outerRadius, y: centerY + sin(rad) * outerRadius))
            context.strokePath()
        }

        // ---- 3. 選択セグメント (アクティブハイライト) の描画 ----
        let startDeg = Float(currentFunc) * unitDeg - (unitDeg / 2)
        let endDeg = (Float(currentFunc) + 1) * unitDeg - (unitDeg / 2)
        let startRad = CGFloat(degreeToRadian(angle: startDeg))
        let endRad = CGFloat(degreeToRadian(angle: endDeg))
        
        let highlightPath = NSBezierPath()
        highlightPath.move(to: centerPoint)
        highlightPath.appendArc(withCenter: centerPoint, radius: outerRadius, startAngle: startRad * 180 / CGFloat.pi, endAngle: endRad * 180 / CGFloat.pi, clockwise: true)
        highlightPath.close()
        
        // 内側の円でマスクしてドーナツ状にする
        let innerRadius = outerRadius - ringWidth
        let innerPath = NSBezierPath(ovalIn: NSRect(x: centerX - innerRadius, y: centerY - innerRadius, width: innerRadius * 2, height: innerRadius * 2))
        
        context.saveGState()
        highlightPath.addClip()
        
        // クリップ領域から内側の円を除外して、外枠アークだけにする
        let maskPath = NSBezierPath(rect: bounds)
        maskPath.append(innerPath)
        maskPath.windingRule = .evenOdd
        maskPath.addClip()
        
        // ネオン風の発光シャドウ（グロー効果）
        let glowShadow = NSShadow()
        glowShadow.shadowColor = NSColor.systemBlue.withAlphaComponent(0.8)
        glowShadow.shadowBlurRadius = 15
        glowShadow.shadowOffset = NSSize.zero
        glowShadow.set()
        
        // 鮮やかなハイライトグラデーション (Blue -> Purple/Teal)
        let accentGradient = NSGradient(starting: NSColor.systemBlue, ending: NSColor(red: 0.5, green: 0.2, blue: 0.9, alpha: 1.0))
        accentGradient?.draw(in: bounds, angle: -CGFloat(currentFunc) * CGFloat(unitDeg) + 90)
        
        context.restoreGState() // グローとマスクを戻す
        
        // アクティブセグメントの外周に光沢のある輪郭線を追加
        context.saveGState()
        let outlinePath = NSBezierPath()
        outlinePath.appendArc(withCenter: centerPoint, radius: outerRadius - 1.5, startAngle: startRad * 180 / CGFloat.pi, endAngle: endRad * 180 / CGFloat.pi, clockwise: true)
        NSColor.systemBlue.withAlphaComponent(0.8).setStroke()
        outlinePath.lineWidth = 3.0
        outlinePath.stroke()
        context.restoreGState()

        // ---- 4. 内側の円 (インナーダイヤル) の描画 ----
        context.saveGState()
        
        // インナーシャドウ（内円が奥に凹んでいるような影）
        let innerShadow = NSShadow()
        innerShadow.shadowColor = NSColor.black.withAlphaComponent(0.5)
        innerShadow.shadowOffset = NSSize(width: 0, height: -3)
        innerShadow.shadowBlurRadius = 6
        innerShadow.set()
        
        // 内円のグラデーションのコントラストを強めて立体金属感を表現
        let innerGradient = NSGradient(starting: NSColor(white: 0.28, alpha: 0.95), ending: NSColor(white: 0.05, alpha: 0.95))
        innerGradient?.draw(in: innerPath, angle: 90)
        
        context.restoreGState()
        
        // ---- 内円の立体ベベルエフェクト ----
        context.saveGState()
        // 内円の上側シャドウ (くぼみによる影)
        let innerShadowPath = innerPath.copy() as! NSBezierPath
        let innerTransformUp = AffineTransform(translationByX: 0, byY: 1)
        innerShadowPath.transform(using: innerTransformUp)
        innerShadowPath.lineWidth = 1.0
        NSColor.black.withAlphaComponent(0.5).setStroke()
        innerShadowPath.stroke()
        
        // 内円の下側ハイライト (くぼみのエッジに当たる反射光)
        let innerHighlightPath = innerPath.copy() as! NSBezierPath
        let innerTransformDown = AffineTransform(translationByX: 0, byY: -1)
        innerHighlightPath.transform(using: innerTransformDown)
        innerHighlightPath.lineWidth = 1.0
        NSColor(white: 1.0, alpha: 0.2).setStroke()
        innerHighlightPath.stroke()
        context.restoreGState()

        // ---- 5. テキストラベルの更新 ----
        label1.stringValue = funcNames[currentFunc]
        label1.textColor = NSColor.white
        label1.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        
        if ((4 == currentFunc) || (6 == currentFunc)) {
            label2.stringValue = value
            label2.textColor = NSColor.systemBlue
            label2.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        } else {
            label2.stringValue = ""
        }
    }
    
    func degreeToRadian(angle: Float) -> Double {
        let radian = Double(-angle + 90) * Double.pi / 180
        return radian
    }
}
