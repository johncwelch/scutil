//
//  AppDelegate.swift
//  scutil
//
//  Created by John Welch on 2/11/22.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

	
	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Insert code here to initialize your application
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}

	func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
		return true
	}
	//this is a thing I like to do for apps that don't have a document. Close the window == quit
	func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
		   return true
	}

}

