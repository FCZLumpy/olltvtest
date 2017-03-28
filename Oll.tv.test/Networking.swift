import Foundation
import Alamofire

class Networking {
    static let sharedInstance = Networking()
    var parameters: Parameters = ["":""]
    let url = "http://oll.tv/demo"
    
    func setParams(serialNumber : String, borderId: Int = 0, direction: Int = 0)
    {
        parameters = [
            "serial_number": serialNumber,
            "borderId": borderId,
            "direction": direction
        ]
    }

    func sendToServerGet(callback:@escaping (Dictionary <String, AnyObject>, Int)  -> Void)
    {
        Alamofire.request(url, method: .get, parameters: parameters, encoding: URLEncoding.queryString, headers: nil).responseJSON { (response) in
            switch(response.result) {
            case .success(_):
                if let data = response.result.value{
                  //  print(response.result.value)
                    callback(data as! Dictionary<String, AnyObject>, 0)
                }
                break
                
            case .failure(_):
                print(response.result.error ?? "")
                break
                
            }
        }
    }
}
