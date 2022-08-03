import UIKit
import DeviceRisk
import TrustKit
import CoreLocation

class ViewController: UIViewController {
    
    let deviceRiskManager = DeviceRiskManager.sharedInstance
    @IBOutlet weak var titleLabel:UILabel?
    @IBOutlet weak var uploadButton:UIButton?
    @IBOutlet weak var deviceAssessmentButton:UIButton?
    @IBOutlet weak var resultsTextView:UITextView?
   
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func configureDeviceRisk(sender:UIButton) {
        URLInterceptor.delegate = self
        deviceRiskManager.setTracker(key: "dff2ebfc-fbdf-4d77-80f2-78f9900978f2", sources:  [.device, .locale, .network])
        deviceRiskManager.delegate = self
        deviceAssessmentButton?.isEnabled = false
        deviceRiskManager.sendData()
    }
     
    @IBAction func sendDeviceRiskData(sender:UIButton) {
        deviceRiskManager.sendData()
    }

}

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

extension ViewController:DeviceRiskUploadCallback {
    func dataUploadFinished(uploadResult: DeviceRiskUploadResult) {
        if let uuid = uploadResult.uuid {
            UserDefaults.standard.setValue(uuid, forKey: "existingSessionID")
            print("SessionID:", uuid)
            resultsTextView?.text = "Session ID is \(uploadResult.uuid ?? "not generated")"
        }
    }
    func onError(errorType: DeviceRiskErrorType, errorMessage: String) {
        resultsTextView?.text = errorMessage
    }
}

extension Data {
    init(reading input: InputStream) {
        self.init()
        input.open()

        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        while input.hasBytesAvailable {
            let read = input.read(buffer, maxLength: bufferSize)
            if (read == 0) {
                break  // added
            }
            self.append(buffer, count: read)
        }
        buffer.deallocate()

        input.close()
    }
}



