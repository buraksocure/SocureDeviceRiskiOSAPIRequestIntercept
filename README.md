# SocureDeviceRiskiOSAPIRequestIntercept

# API Request Intercept Testing

# 1) Include Swizzling Methods to your AppDeletegate 

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

# 2) Add Protocol and set Delegate on your ViewController that you are calling sendData

        URLInterceptor.delegate = self
        deviceRiskManager.setTracker(key: "SDK_KEY", sources:  [.device, .locale, .network])
        deviceRiskManager.delegate = self
        deviceAssessmentButton?.isEnabled = false
        deviceRiskManager.sendData()
        
        protocol URLInterceptorDelegate: AnyObject {
            func didInterceptRequest(request: URLRequest)
        }

        class URLInterceptor: URLProtocol {
            static weak var delegate: URLInterceptorDelegate?

            class override func canInit(with request: URLRequest) -> Bool {
                delegate?.didInterceptRequest(request: request)
                return false
            }
        }


        extension ViewController: URLInterceptorDelegate {
            public func didInterceptRequest(request: URLRequest) {
                let requestCopy = (request as NSURLRequest).copy() as! URLRequest
                print(requestCopy.debugDescription)

                if let stream = requestCopy.httpBodyStream {
                  print(String(data: Data(reading: stream), encoding: .utf8)!)
                }
            }
        }
        
# 3) Capture API request 




