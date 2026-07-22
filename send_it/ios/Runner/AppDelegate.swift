import Flutter
import UIKit
import MessageUI
import Photos
import UniformTypeIdentifiers
import MobileCoreServices

@main
@objc class AppDelegate: FlutterAppDelegate, MFMessageComposeViewControllerDelegate {
  private var pendingResult: FlutterResult?
  private var temporaryFiles: [URL] = []

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
              print("Processing \(mediaPaths.count) media attachments for recipient: \(recipient)")

              for (index, mediaPath) in mediaPaths.enumerated() {
                  let mediaURL = URL(fileURLWithPath: mediaPath)
                  print("Processing media \(index + 1): \(mediaPath)")

                  if FileManager.default.fileExists(atPath: mediaPath) {
                      do {
                                  let mediaData = try Data(contentsOf: mediaURL)
                          let pathExtension = mediaURL.pathExtension.lowercased()

                          // Create a unique temporary file with timestamp for better uniqueness
                          let tempDir = FileManager.default.temporaryDirectory
                          let timestamp = Int(Date().timeIntervalSince1970 * 1000)
                          let uniqueId = UUID().uuidString
                          let tempFile = tempDir.appendingPathComponent("sendit_\(timestamp)_\(uniqueId).\(pathExtension)")

                          // Ensure the temporary file doesn't already exist
                          if FileManager.default.fileExists(atPath: tempFile.path) {
                              try FileManager.default.removeItem(at: tempFile)
                          }

                          try mediaData.write(to: tempFile)

                          // Get the UTI for the file
                          var typeIdentifier: String?
                          if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as CFString, nil)?.takeRetainedValue() {
                              typeIdentifier = uti as String
                          }

                                          if let typeIdentifier = typeIdentifier {
                              // Try using addAttachmentData instead of addAttachmentURL for better reliability
                              // This approach avoids potential file system issues with multiple composers
                              do {
                                  let filename = mediaURL.lastPathComponent
                                  let success = messageVC.addAttachmentData(mediaData, typeIdentifier: typeIdentifier, filename: filename)

                                  if success {
                                      // Track the temporary file for cleanup (still needed for consistency)
                                      self.temporaryFiles.append(tempFile)

                                      // Force a reload of the message composer view to ensure attachments are displayed
                                      messageVC.view.setNeedsLayout()
                                      messageVC.view.layoutIfNeeded()
                                  } else {
                                      print("Failed to add attachment data - addAttachmentData returned false")
                                      // Clean up the temporary file
                                      try? FileManager.default.removeItem(at: tempFile)
                                      result(FlutterError(code: "ATTACHMENT_FAILED", message: "Failed to add attachment data", details: nil))
                                      return
                                  }

                              } catch {
                                  print("Exception in addAttachmentData: \(error)")
                                  // Fallback to URL method if data method fails
                                  print("Falling back to addAttachmentURL method")
                                  do {
                                      try messageVC.addAttachmentURL(tempFile, withAlternateFilename: mediaURL.lastPathComponent)
                                      // Track the temporary file for cleanup
                                      self.temporaryFiles.append(tempFile)
                                      print("Successfully attached via fallback: \(mediaURL.lastPathComponent) as \(tempFile.path)")
                                  } catch {
                                      print("Both attachment methods failed: \(error)")
                                      // Clean up the temporary file if attachment failed
                                      try? FileManager.default.removeItem(at: tempFile)
                                      result(FlutterError(code: "ATTACHMENT_FAILED", message: "Failed to add attachment: \(error.localizedDescription)", details: nil))
                                      return
                                  }
                              }
                          } else {
                              print("Could not determine UTI for file: \(mediaPath)")
                              // Clean up the temporary file
                              try? FileManager.default.removeItem(at: tempFile)
                              result(FlutterError(code: "MEDIA_TYPE_ERROR", message: "Could not determine media type", details: nil))
                              return
                          }
                      } catch {
                          print("Error processing media: \(error)")
                          result(FlutterError(code: "MEDIA_ATTACHMENT_ERROR", message: "Failed to process media: \(error.localizedDescription)", details: nil))
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

          // Only add delays when there are attachments, as the issue only occurs with attachments
          if mediaPaths != nil && !(mediaPaths?.isEmpty ?? true) {
              // Add a delay before presenting to allow system cleanup from previous composer
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                  // Present the message composer with a completion handler to ensure it's fully loaded
                  controller.present(messageVC, animated: true, completion: {
                      // Give the composer additional time to fully load and display attachments
                      DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                          // Force a final layout refresh after presentation
                          messageVC.view.setNeedsLayout()
                          messageVC.view.layoutIfNeeded()
                      }
                  })
              }
          } else {
              // No attachments - present immediately without delays
              controller.present(messageVC, animated: true, completion: nil)
          }
        } else {
          result(FlutterError(code: "SMS_NOT_AVAILABLE", message: "SMS is not available", details: nil))
        }
      } else if call.method == "openShortcutFile" {
        guard let args = call.arguments as? [String: Any],
              let filePath = args["filePath"] as? String else {
          result(FlutterError(code: "INVALID_ARGUMENTS", message: "filePath required", details: nil))
          return
        }
        let fileURL = URL(fileURLWithPath: filePath)
        DispatchQueue.main.async {
          let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
          if let rootVC = self.window?.rootViewController {
            activityVC.popoverPresentationController?.sourceView = rootVC.view
            activityVC.popoverPresentationController?.sourceRect = rootVC.view.bounds
            rootVC.present(activityVC, animated: true, completion: nil)
          }
        }
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
    controller.dismiss(animated: true, completion: nil)

    // Clean up temporary files after the message composer is dismissed
    cleanupTemporaryFiles()

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

  private func cleanupTemporaryFiles() {
    for tempFile in temporaryFiles {
      do {
        if FileManager.default.fileExists(atPath: tempFile.path) {
          try FileManager.default.removeItem(at: tempFile)
          print("Cleaned up temporary file: \(tempFile.path)")
        }
      } catch {
        print("Failed to clean up temporary file \(tempFile.path): \(error)")
      }
    }
    temporaryFiles.removeAll()
  }
}
