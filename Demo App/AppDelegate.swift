//
//  AppDelegate.swift
//  Demo App
//
//  Created by Nicolas Dedual on 9/29/20.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    // DeviceRisk SDK uses URLSessionConfiguration.ephemeral configuration in URLSessionManager to create a
    // custom URLSession. Swizzling URLSessionConfiguration.ephemeral to include `URLInterceptor.self` in
    // the `protocolClasses` array.
    private let swizzleEpheremalSessionConfiguration: Void = {
        let m1 = class_getClassMethod(URLSessionConfiguration.self, #selector(getter: URLSessionConfiguration.ephemeral))
        let m2 = class_getClassMethod(URLSessionConfiguration.self, #selector(URLSessionConfiguration.swizzled_ephemeralSessionConfiguration))
        if let m1 = m1, let m2 = m2 { method_exchangeImplementations(m1, m2) }
    }()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        URLProtocol.registerClass(URLInterceptor.self)
        return true
    }
}

extension URLSessionConfiguration {

    @objc dynamic class func swizzled_ephemeralSessionConfiguration() -> URLSessionConfiguration {
        let configuration = swizzled_ephemeralSessionConfiguration()

        // Adding `Interceptor.self` to the protocol classes to receive a callback
        configuration.protocolClasses = [URLInterceptor.self] + configuration.protocolClasses!
        return configuration
    }
}

