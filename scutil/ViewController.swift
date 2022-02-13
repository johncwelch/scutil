//
//  ViewController.swift
//  scutil
//
//  Created by John Welch on 2/11/22.
//

import Cocoa

class ViewController: NSViewController {

	//outlets for the text fields these are not editable
	@IBOutlet weak var theCurrentComputerName: NSTextField!
	@IBOutlet weak var theCurrentLocalHostName: NSTextField!
	@IBOutlet weak var theCurrentHostName: NSTextField!

	//editable
	@IBOutlet weak var theNewComputerName: NSTextField!
	@IBOutlet weak var theNewLocalHostName: NSTextField!
	@IBOutlet weak var theNewHostName: NSTextField!

	//runs scutil --get <name type> to populate the current fields
	func getNames(nameType: String) -> String {

		//create the process scutil will run in. Since this doesn't require sudo, very simple
		let scutil = Process()

		//pipe to capture the command output of scutil --get <name type>
		let scutilReturnPipe = Pipe()

		//assign stdoutput to the pipe
		scutil.standardOutput = scutilReturnPipe
		//the format for arguments is really important!!
		scutil.arguments = ["--get", nameType]
		//full path to the executable. it's rarely a good idea to rely on random path environment vars
		scutil.executableURL = URL(fileURLWithPath: "/usr/sbin/scutil")
		//run the command
		do {
			try scutil.run()
		}
		catch {}

		//grab the data
		let theScutilPipeData = scutilReturnPipe.fileHandleForReading.readDataToEndOfFile()
		//coerce to UTF8 string
		let theScutilPipeOutput = String(decoding: theScutilPipeData, as: UTF8.self)
		//return <name type> to caller
		return theScutilPipeOutput
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		//initial setup on load
		theCurrentComputerName.stringValue = getNames(nameType: "ComputerName")
		theCurrentLocalHostName.stringValue = getNames(nameType: "LocalHostName")
		theCurrentHostName.stringValue = getNames(nameType: "HostName")
	}

	override var representedObject: Any? {
		didSet {
		// Update the view, if already loaded.
		}
	}

	//if we click cancel, clear out any data entered
	@IBAction func cancelButton(_ sender: Any) {
		theNewComputerName.stringValue = ""
		theNewLocalHostName.stringValue = ""
		theNewHostName.stringValue = ""
	}
	//clicking the save button kicks off a lot of work
	@IBAction func saveButton(_ sender: Any) {

		var thePassword: String = ""
		var theUserName: String = NSUserName()
		var newComputerNameText: String = ""
		var newLocalHostNameText: String = ""
		var newHostNameText: String = ""

		//variables for NSAppleScript

		//the actual apple event returned
		var theScriptResult: NSAppleEventDescriptor?
		//if there is an error, it goes here
		var theAppleScriptError: NSDictionary? = nil

		//various flags
		var hasPassword: Bool = false

		//to use the scutil --set options, we need to execute that as root
		//as it turns out, and with good reason, this is not generally easy, so we're going to cheat a bit
		//in a way that works for demonstration purposes, but would absolutely not pass MAS muster, nor should it
		//we're going to use NSAppleScript to run "do shell script" with administrator privilegees
		//we already have the user namd via NSUserName(), so we need to create an alert that will
		//get us the actual password.


		//Code for the NSAlert to get the password

		//create the text field for the password in the alert that shows up on clicking save
		//we use NSSecureTextField as it doesn't show the actual password by defualt.
		let thePasswordText = NSSecureTextField(frame: CGRect(x: 0, y: 0, width: 300, height: 20))

		//make sure this is empty
		thePasswordText.stringValue = ""

		//create an nsalert object named thePassWordAlert
		let thePasswordAlert: NSAlert = NSAlert()
		//set the properties of the alert

		//Alert type is warning
		thePasswordAlert.alertStyle = .warning
		//the explanation of why we are doing this, something too many apps don't do well
		thePasswordAlert.informativeText = "This application needs your password so it can set the new hostname value(s)."
		//title of the alert dialog
		thePasswordAlert.messageText = "Scutil Authentication Request"
		//buttons
		thePasswordAlert.addButton(withTitle: "OK")
		thePasswordAlert.addButton(withTitle: "Cancel")
		//add in the text field
		thePasswordAlert.accessoryView = thePasswordText
		//do the layout *now*, not just before display
		thePasswordAlert.layout()
		//set the focuse of the alert dialog to the text field instead of the Cancel button
		thePasswordText.becomeFirstResponder()
		//run the alert, assign the response to thePasswordAlertResponse, which will be a modalResponse
		let thePasswordAlertResponse = thePasswordAlert.runModal()


		//evaluate the response, which is a ModalResponse
		switch thePasswordAlertResponse {
				//if they clicked OK, assign the text in the text field to thePassword
			case NSApplication.ModalResponse.alertFirstButtonReturn:
				thePassword = thePasswordText.stringValue
				//if they clicked Cancel, blank out the text field and still assign it to thePassword
			case NSApplication.ModalResponse.alertSecondButtonReturn:
				thePasswordText.stringValue = ""
				thePassword = ""
			default:
				print("clicked nothing")
		}

		//if there's no password entered, we literally can't do anything. Maybe pop an alert? sheet alert?
		if thePassword != "" {
			hasPassword = true
		} else {
			hasPassword = false
			//do other stuff besides set the flag
			print("Password is blank")
		}

		//if there is content in the password, we now check to see if there's anything in the various new name fields.
		//we aren't even going to try to eval the password until the command is run
		if hasPassword {
			//empty field check, if it's empty, skip it, if not, do lots of things
			if !theNewComputerName.stringValue.isEmpty {
				//grab the string value
				newComputerNameText = theNewComputerName.stringValue
				//build the command
				var theCommand: String = "do shell script \"/usr/sbin/scutil --set ComputerName " + newComputerNameText + "\"" + " user name \"" + theUserName + "\"" + " password \"" + thePassword + "\" with administrator privileges"
				//run the command, assign the results to theScriptResult, and any errors go to theApplescriptError
				theScriptResult = NSAppleScript(source: theCommand)!.executeAndReturnError(&theAppleScriptError)
				//blank theCommand, this is a me thing, i like doing it
				theCommand = ""

				//if there's an error, grab the message
				if let theErrorValue = theAppleScriptError?.value(forKey: "NSAppleScriptErrorMessage") {
				//look for specific text and do something based on that
					if (theErrorValue as AnyObject).contains("user name or password was incorrect") {
						print("bad user name or password")
					//everything went okay
					} else {
						//reload all the fields via scutil --get
						theCurrentComputerName.stringValue = getNames(nameType: "ComputerName")
						theCurrentLocalHostName.stringValue = getNames(nameType: "LocalHostName")
						theCurrentHostName.stringValue = getNames(nameType: "HostName")
					}

				}
			} else {
				//optional stuff to do, user notification, etc.
			}

			if !theNewLocalHostName.stringValue.isEmpty {
				//print("has a local host name")
				newLocalHostNameText = theNewLocalHostName.stringValue
				var theCommand: String = "do shell script \"/usr/sbin/scutil --set ComputerName " + newLocalHostNameText + "\"" + " user name \"" + theUserName + "\"" + " password \"" + thePassword + "\" with administrator privileges"
				theScriptResult = NSAppleScript(source: theCommand)!.executeAndReturnError(&theAppleScriptError)
				theCommand = ""

				//if there's an error, grab the message
				if let theErrorValue = theAppleScriptError?.value(forKey: "NSAppleScriptErrorMessage") {
				//look for specific text and do something based on that
					if (theErrorValue as AnyObject).contains("user name or password was incorrect") {
						print("bad user name or password")
					//everything went okay
					} else {
						theCurrentComputerName.stringValue = getNames(nameType: "ComputerName")
						theCurrentLocalHostName.stringValue = getNames(nameType: "LocalHostName")
						theCurrentHostName.stringValue = getNames(nameType: "HostName")
					}

				}
			} else {
				//optional stuff to do, user notification, etc.
			}

			if !theNewHostName.stringValue.isEmpty {
				newHostNameText = theNewHostName.stringValue
				var theCommand: String = "do shell script \"/usr/sbin/scutil --set ComputerName " + newHostNameText + "\"" + " user name \"" + theUserName + "\"" + " password \"" + thePassword + "\" with administrator privileges"
				theScriptResult = NSAppleScript(source: theCommand)!.executeAndReturnError(&theAppleScriptError)
				theCommand = ""

				//example of error handling with NSAppleScript, in this case based on a bad password error
				//NSAppleScript returns an NSDictionary with the following keys:
				//NSAppleScriptErrorAppName - the name of the process running the command. If in a swift playground, you get: com.apple.dt.Xcode.PlaygroundStub-macosx.xpc
				//NSAppleScriptErrorBriefMessage - the "Short" error message
				//NSAppleScriptErrorMessage - the error message
				//NSAppleScriptErrorRange - an NSRange for the error
				//NSAppleScriptErrorNumber - this may not exist any more, if so, it should be the apple event error number. I didn't see it testing this code

				//if there's an error, grab the message
				if let theErrorValue = theAppleScriptError?.value(forKey: "NSAppleScriptErrorMessage") {
					//look for specific text and do something based on that
					if (theErrorValue as AnyObject).contains("user name or password was incorrect") {
						print("bad user name or password")
					}
				} else {
					theCurrentComputerName.stringValue = getNames(nameType: "ComputerName")
					theCurrentLocalHostName.stringValue = getNames(nameType: "LocalHostName")
					theCurrentHostName.stringValue = getNames(nameType: "HostName")
				}

			} else {
				//optional stuff to do, user notification, etc.
			}
		}
	}
}




