import Alamofire
import Foundation

class RioBusAPIClient {
    static let sharedInstance = RioBusAPIClient()
    
    let BASE_URL = "http://rest.riob.us/v3"
    
    func getBusesForLine(lineName: String, completionHandler: (buses: [BusData]?, error: ErrorType?) -> Void) {
        Alamofire.request(.GET, "\(BASE_URL)/search/\(lineName)").responseJSON { response in
            if let JSON = response.result.value {
                let busesJSON = JSON as! [[String: AnyObject]]
                var buses = [BusData]()
                
                for busJSON in busesJSON {
                    if let bus = BusData(dictionary: busJSON) {
                        buses.append(bus)
                    }
                }
                
                completionHandler(buses: buses, error: nil)
            } else {
                completionHandler(buses: nil, error: response.result.error)
            }
        }
        
    }
}