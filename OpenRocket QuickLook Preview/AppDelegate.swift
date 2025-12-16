//
//  AppDelegate.swift
//  OpenRocket QuickLook Preview
//
//  Created by David Hoerl on 11/2/25.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

  var previewWindow: NSWindow!
  var previewWindowController: NSWindowController!

  // The application has finished launching.
    func applicationDidFinishLaunching(_ aNotification: Notification) {
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

}
