import Alamofire
import Foundation

class RioBusAPIClient: NSObject {
    enum RioBusAPIError: ErrorType {
        case InvalidResponse
    }
    
    private override init() { }
    
    #if DEBUG
    private static let BASE_URL = "http://dev.riob.us:8080/v3"
    #else
    private static let BASE_URL = "http://rest.riob.us/v3"
    #endif
    
    static let ErrorDomain = "us.riob.error.APIError" // FIXME: get rid of NSError!
    
    class func getBusesForLine(lineName: String, completionHandler: (buses: [BusData]?, error: NSError?) -> Void) {
        let webSafeLineName = lineName.webSafeString() as String!
        let requestURLString = "\(BASE_URL)/search/\(webSafeLineName)"
        logRequest(requestURLString)
        
        Alamofire.request(.GET, requestURLString).responseJSON { response in
            if let busesJSON = response.result.value as? [[String: AnyObject]] {
                var buses = [BusData]()
                buses.reserveCapacity(busesJSON.count)
                
                for busJSON in busesJSON {
                    if let bus = BusData(dictionary: busJSON) {
                        buses.append(bus)
                    }
                }
                
                completionHandler(buses: buses, error: nil)
            } else {
                if let error = response.result.error {
                    completionHandler(buses: nil, error: error)
                } else {
                    completionHandler(buses: nil, error: NSError(domain: ErrorDomain, code: -1, userInfo: nil))
                }
            }
        }
        
    }
    
    class func getItineraryForLine(lineName: String, completionHandler: (itinerarySpots: [CLLocation]?, error: NSError?) -> Void) {
        let webSafeLineName = lineName.webSafeString() as String!
        let requestURLString = "\(BASE_URL)/itinerary/\(webSafeLineName)"
        logRequest(requestURLString)

        Alamofire.request(.GET, requestURLString).responseJSON { response in
            if let lineDetailsJSON = response.result.value as? [String: AnyObject] {
                if let spotsJSON = lineDetailsJSON["spots"] as? [[String: AnyObject]] {
                    var spots = [CLLocation]()
                    
                    for spotJSON in spotsJSON {
                        let latitude = spotJSON["latitude"] as! Double
                        let longitude = spotJSON["longitude"] as! Double
                        spots.append(CLLocation(latitude: latitude, longitude: longitude))
                    }
                    
                    completionHandler(itinerarySpots: spots, error: nil)
                } else {
                    completionHandler(itinerarySpots: nil, error: NSError(domain: ErrorDomain, code: -1, userInfo: nil))
                }
                
            } else {
                if let error = response.result.error {
                    completionHandler(itinerarySpots: nil, error: error)
                } else {
                    completionHandler(itinerarySpots: nil, error: NSError(domain: ErrorDomain, code: -1, userInfo: nil))
                }
            }
        }
    }
    
    class func getTrackedBusLines(completionHandler: (trackedLines: [String: BusLine]?, error: NSError?) -> Void) {
        let requestURLString = "\(BASE_URL)/itinerary"
        logRequest(requestURLString)

        Alamofire.request(.GET, requestURLString).responseJSON { response in
            if let linesJSON = response.result.value as? [[String: AnyObject]] {
                var lines = [String: BusLine]()
                
                for line in linesJSON {
                    let lineName = line["line"] as! String
                    let lineDescription = line["description"] as! String
                    lines[lineName] = BusLine(name: lineName, andDescription: lineDescription)
                }
                
                completionHandler(trackedLines: lines, error: nil)
            } else {
                if let error = response.result.error {
                    completionHandler(trackedLines: nil, error: error)
                } else {
                    completionHandler(trackedLines: nil, error: NSError(domain: ErrorDomain, code: -1, userInfo: nil))
                }
            }
        }
    }
    
    private class func logRequest(requestURLString: String) {
        print("Rio Bus API request: \(requestURLString)")
    }
    
}