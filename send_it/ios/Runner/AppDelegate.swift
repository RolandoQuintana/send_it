import Flutter
import UIKit
import MessageUI
import Photos
import UniformTypeIdentifiers
import MobileCoreServices

@main
@objc class AppDelegate: FlutterAppDelegate, MFMessageComposeViewControllerDelegate {
  private var pendingResult: FlutterResult?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let messageChannel = FlutterMethodChannel(name: "com.sendit/messages", binaryMessenger: controller.binaryMessenger)

    messageChannel.setMethodCallHandler({
      [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      guard let self = self else { return }

      if call.method == "sendMessage" {
        print("Received method call: sendMessage")
        print("Raw arguments: \(String(describing: call.arguments))")
        print("Arguments type: \(type(of: call.arguments))")

        guard let args = call.arguments as? [String: Any] else {
            print("Failed to cast arguments to dictionary. Type: \(type(of: call.arguments))")
            if let rawArgs = call.arguments {
                print("Raw args content: \(rawArgs)")
            }
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Arguments not in expected format", details: nil))
            return
        }

        print("Arguments dictionary: \(args)")

        guard let recipient = args["recipient"] as? String else {
            print("Failed to get recipient. Value: \(String(describing: args["recipient"]))")
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Recipient not found", details: nil))
            return
        }

        guard let message = args["message"] as? String else {
            print("Failed to get message. Value: \(String(describing: args["message"]))")
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Message not found", details: nil))
            return
        }

        let mediaPaths = args["mediaPaths"] as? [String]

        print("Recipient: \(recipient)")
        print("Message: \(message)")
        print("Media Paths: \(String(describing: mediaPaths))")

        if MFMessageComposeViewController.canSendText() {
          let messageVC = MFMessageComposeViewController()
          messageVC.messageComposeDelegate = self
          messageVC.recipients = [recipient]
          messageVC.body = message

          // Add media attachments if provided
          if let mediaPaths = mediaPaths {
              for mediaPath in mediaPaths {
                  let mediaURL = URL(fileURLWithPath: mediaPath)
                  if FileManager.default.fileExists(atPath: mediaPath) {
                      do {
                          let mediaData = try Data(contentsOf: mediaURL)
                          let pathExtension = mediaURL.pathExtension.lowercased()

                          // Create a temporary file with the correct extension
                          let tempDir = FileManager.default.temporaryDirectory
                          let tempFile = tempDir.appendingPathComponent(UUID().uuidString + "." + pathExtension)
                          try mediaData.write(to: tempFile)

                          // Get the UTI for the file
                          var typeIdentifier: String?
                          if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as CFString, nil)?.takeRetainedValue() {
                              typeIdentifier = uti as String
                          }

                          if let typeIdentifier = typeIdentifier {
                              messageVC.addAttachmentURL(tempFile, withAlternateFilename: mediaURL.lastPathComponent)
                          } else {
                              print("Could not determine UTI for file: \(mediaPath)")
                              result(FlutterError(code: "MEDIA_TYPE_ERROR", message: "Could not determine media type", details: nil))
                              return
                          }
                      } catch {
                          print("Error attaching media: \(error)")
                          result(FlutterError(code: "MEDIA_ATTACHMENT_ERROR", message: "Failed to attach media: \(error.localizedDescription)", details: nil))
                          return
                      }
                  } else {
                      print("Media file not found at path: \(mediaPath)")
                      result(FlutterError(code: "MEDIA_NOT_FOUND", message: "Media file not found", details: nil))
                      return
                  }
              }
          }

          // Store the result to be called later
          self.pendingResult = result

          controller.present(messageVC, animated: true, completion: nil)
        } else {
          result(FlutterError(code: "SMS_NOT_AVAILABLE", message: "SMS is not available", details: nil))
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
    controller.dismiss(animated: true, completion: nil)

    // Send the result back to Flutter
    switch result {
    case .sent:
      pendingResult?("sent")
    case .cancelled:
      pendingResult?("cancelled")
    case .failed:
      pendingResult?(FlutterError(code: "SEND_FAILED", message: "Failed to send message", details: nil))
    @unknown default:
      pendingResult?(FlutterError(code: "UNKNOWN_RESULT", message: "Unknown result", details: nil))
    }
    pendingResult = nil
  }
}
