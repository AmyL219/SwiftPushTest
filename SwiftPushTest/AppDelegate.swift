// --------------------------------------------------------------------------
//
// Copyright (c) Microsoft Corporation. All rights reserved.
//
// The MIT License (MIT)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the ""Software""), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED *AS IS*, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.
//
// --------------------------------------------------------------------------
import UIKit
import UserNotifications
import AzureCommunicationChat
import AzureCommunicationCommon

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    let token = "eyJhbGciOiJSUzI1NiIsImtpZCI6IjEwM19pbnQiLCJ4NXQiOiJlU0t5M1lPd2FzazIxN3ZKWmVWZFhOcDBSNm8iLCJ0eXAiOiJKV1QifQ.eyJza3lwZWlkIjoiYWNzOmExZTI1ZmNjLTY1OTctNDRjZi05ODZiLWFhOWM4MmFjMTJmYV8wMDAwMDAxMS0yNjBjLTIxZmYtNTg5Ni0wOTQ4MjIwMDBmYjkiLCJzY3AiOjE3OTIsImNzaSI6IjE2NTE1MTg0MDUiLCJleHAiOjE2NTE2MDQ4MDUsImFjc1Njb3BlIjoiY2hhdCIsInJlc291cmNlSWQiOiJhMWUyNWZjYy02NTk3LTQ0Y2YtOTg2Yi1hYTljODJhYzEyZmEiLCJpYXQiOjE2NTE1MTg0MDV9.JuGd6sqm0HqzHeezYZJOAQmMJ6ZKPIgNDi9EnyQwhEYpxja0Udvc6ZwSb4WRPv2W1_hiav1ih4D28SMfTzWOkyxfP8-boBuh-6gxMQDBP_X4VmOz4aIlvZsa4xwW1Gnxpq7JFn8MaiGFRrop-WafhF180G41cQb7OkCmh2hYtSahzGS8rbLYz8gJ6diGiZmIVnHJb4iXhluM4ARqM4M9oC1xok2iGLSUsvZK3yJYbidhSAvF_GrKCqrdAtV1ktcRBwV1dNV5CiKkv7SWwFFvwvGOSzGDGSFfbWT3bqPowjtjzw0LDv3-ytO2qIf9PvCLm0riFU-NMUsjagk_tBrXyg"
    let endpoint = "https://chat-int-test.int.communication.azure.net"
    private var chatClient: ChatClient?

    var notificationPresentationCompletionHandler: ((UNNotificationPresentationOptions) -> Void)?
    var notificationResponseCompletionHandler: (() -> Void)?

    // MARK: App Launch
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        do{
            let credential = try CommunicationTokenCredential(token: self.token)
            let options = AzureCommunicationChatClientOptions()
            chatClient = try ChatClient(endpoint: self.endpoint, credential: credential, withOptions: options)
            // Override point for customization after application launch.
            registerForPushNotifications()
            // Check if launched from notification
            let notificationOption = launchOptions?[.remoteNotification]
            // 1
            if let notification = notificationOption as? [String: AnyObject], let aps = notification["aps"] as? [String: AnyObject] {
                print("received notification")
                print(aps)
                print(notification)
            }
            return true
        } catch {
            print("Failed to initialize chat client")
            return false
        }
    }

    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

        print("------------")
        if (UIApplication.shared.applicationState == .background) {
            print("Notification received in the background")
        }

        if (notificationResponseCompletionHandler != nil) {
            print("Tapped Notification")
        } else {
            print("Notification received in the foreground")
        }

        // Call notification completion handlers.
        if (notificationResponseCompletionHandler != nil) {
            (notificationResponseCompletionHandler!)()
            notificationResponseCompletionHandler = nil
        }
        if (notificationPresentationCompletionHandler != nil) {
            (notificationPresentationCompletionHandler!)([])
            notificationPresentationCompletionHandler = nil
        }

        completionHandler(.noData)
    }


    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    // MARK: Register for Push Notifications after the launch of App
    func registerForPushNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
            print("Permission granted: \(granted)")
            guard granted else { return }
            self?.getNotificationSettings()
            UNUserNotificationCenter.current().delegate = self

        }
    }

    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("Notification settings: \(settings)")
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    // MARK: Tells the delegate that the app successfully registered with Apple Push Notification service
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data

    ) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
        UserDefaults.standard.set(token, forKey: "APNSToken")

        // Start push notifications
        guard let apnsToken = UserDefaults.standard.string(forKey: "APNSToken") else {
            print("Failed to get APNS token")
            return
        }

        let semaphore = DispatchSemaphore(value: 0)
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            guard let chatClient = self.chatClient else { return }
            chatClient.startPushNotifications(deviceToken: apnsToken) { result in
                switch result {
                case .success:
                    print("Started Push Notifications")
                case let .failure(error):
                    print("Failed To Start Push Notifications: \(error)")
                }
                semaphore.signal()
            }
            semaphore.wait()
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register: \(error)")
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        print("------userNotificationCenter didReceive")
        self.notificationResponseCompletionHandler = completionHandler
        let userInfo = response.notification.request.content.userInfo
        let application = UIApplication.shared
        print("---------------didReceive userInfo:\(userInfo)")

        if let aps = userInfo["aps"] as? [String: AnyObject] {
            print("---------------aps:\(aps)")
            // DO STUFF, in myValue you will find your custom data
        }
        completionHandler()

    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        self.notificationPresentationCompletionHandler = completionHandler
        let userInfo = notification.request.content.userInfo
        let application = UIApplication.shared
        print("---------------userNotificationCenter willPresent:\(userInfo)")

        if let aps = userInfo["aps"] as? [String: AnyObject] {
            print("---------------aps:\(aps)")
            // DO STUFF, in myValue you will find your custom data
        }

        if (UIApplication.shared.applicationState == .background) {
            print("Notification received in the background")
        }

        if (notificationResponseCompletionHandler != nil) {
            print("Tapped Notification")
        } else {
            print("Notification received in the foreground")
        }

            completionHandler( [.alert, .badge, .sound])

    }
}

