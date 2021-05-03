//
//  AppDelegate.swift
//  dial3
//
//  Created by yamada.468@gmail.com on 2021/05/01.
//

import Cocoa

@main
@objcMembers
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet weak var menu1: NSMenu!
    @IBOutlet weak var menu1ItemShow: NSMenuItem!
    @IBOutlet weak var menu1ItemClose: NSMenuItem!
    
    public var driver: Driver? = nil
    public var winctrl: WindowController!

    public let funcNames = ["縦","横","拡","3","音","5","明","7"]

    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    func delmember(a :Int) {
        NSLog("Here is AppDelegate member : %d", a)
    }

    func showWindow() {
        winctrl?.showWindow(self)
    }

    func async_showWindow() {
        DispatchQueue.main.async {
            self.showWindow()
        }
    }

    func closeWindow() {
        winctrl?.close()
    }

    func async_closeWindow() {
        DispatchQueue.main.async {
            self.closeWindow()
        }
    }

    func setFunc(f: Int) {
        statusItem.title = funcNames[f]
        if let viewcont = self.winctrl.contentViewController as? ViewController {
            viewcont.setFunc(f: f)
        }
    }
    
    func async_setFunc(f: Int) {
        DispatchQueue.main.async {
            self.setFunc(f: f)
        }
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        driver = Driver.init()
        if (false == driver?.initHid(self)) {
            let alert: NSAlert = NSAlert()
            alert.messageText = "Device initialization failed."
            alert.informativeText = "Exit the program."
            alert.addButton(withTitle: "Close")
            alert.runModal()
            
            NSApplication.shared.terminate(self)
        } else {
            driver?.runHid()
        }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        let storyboard = NSStoryboard(name: "Main",bundle: nil)
        winctrl = storyboard.instantiateController(withIdentifier: "WindowController") as? WindowController

        let image: NSImage = NSImage(named: "dial")!
        image.size.width = 24
        image.size.height = 24
        
        statusItem.image = image
        statusItem.menu = menu1
        
        menu1ItemShow.action = #selector(showWindow)
        menu1ItemClose.action = #selector(closeWindow)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}
