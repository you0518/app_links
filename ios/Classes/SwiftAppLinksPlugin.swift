import Flutter
import UIKit

public class SwiftAppLinksPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  fileprivate var eventSink: FlutterEventSink?

  fileprivate var initialLink: String?
  fileprivate var latestLink: String?

  // Set the initial link manually
  // c.f #47
  public static func setInitialLink(url: URL) -> Void {
    SwiftAppLinksCustom.shared.initialLink = url.absoluteString
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let methodChannel = FlutterMethodChannel(name: "com.llfbandit.app_links/messages", binaryMessenger: registrar.messenger())
    let eventChannel = FlutterEventChannel(name: "com.llfbandit.app_links/events", binaryMessenger: registrar.messenger())

    let instance = SwiftAppLinksPlugin()

    registrar.addMethodCallDelegate(instance, channel: methodChannel)
    eventChannel.setStreamHandler(instance)
    registrar.addApplicationDelegate(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
      case "getInitialAppLink":
        // return initialLink or manually stored value if null
        result(initialLink ?? SwiftAppLinksCustom.shared.initialLink)
        break
      case "getLatestAppLink":
        result(latestLink)
        break      
      default:
        result(FlutterMethodNotImplemented)
        break
    }
  }

  // Universal Links
  public func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([Any]) -> Void) -> Bool {

    switch userActivity.activityType {
      case NSUserActivityTypeBrowsingWeb:
        guard let url = userActivity.webpageURL else {
          return false
        }
        handleLink(url: url)
        return false
      default: return false
    }
  }

  // Custom URL schemes
  public func application(
    _ application: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    
    handleLink(url: url)
    return false
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // .. HERE do other stuff if needed

    // Custom URL
    if let url = launchOptions?[UIApplication.LaunchOptionsKey.url] as? URL {
      SwiftAppLinksPlugin.setInitialLink(url: url)
    }
    // Universal link
    else if let activityDictionary = launchOptions?[UIApplication.LaunchOptionsKey.userActivityDictionary] as? [AnyHashable: Any] { 
      for key in activityDictionary.keys {
        if let userActivity = activityDictionary[key] as? NSUserActivity {
          if let url = userActivity.webpageURL {
            SwiftAppLinksPlugin.setInitialLink(url: url)
            break
          }
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
  public func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink) -> FlutterError? {

    self.eventSink = events
    return nil
  }
    
  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    self.eventSink = nil
    return nil
  }

  fileprivate func handleLink(url: URL) -> Void {
    let link = url.absoluteString

    debugPrint("iOS handleLink: \(link)")

    latestLink = link

    if (initialLink == nil) {
      initialLink = link
    }
    
    guard let _eventSink = eventSink, latestLink != nil else {
      return
    }

    _eventSink(latestLink)
  }
}

// Store the values set manually in a Singleton
// c.f #47
class SwiftAppLinksCustom {
  static let shared = SwiftAppLinksCustom()

  var initialLink: String?

  private init() {}
}