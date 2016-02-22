import XCTest
@testable import riobus

class ItineraryCacheTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testGetInvalidLine() {
        let itinerary = ItineraryCache.getItineraryForLine("AAAAA")
        XCTAssertNil(itinerary, "Itinerary should return a nil object")
    }
    
    func testSaveAndReadLine() {
        let mockLineName = "MOCK123"
        let mockItinerary = [
            CLLocation(latitude: -20.512421, longitude: -15.023210),
            CLLocation(latitude: -25.391700, longitude: -18.230201)
        ]
        
        let saved = ItineraryCache.saveItineraryForLine(mockLineName, itinerarySpots: mockItinerary)
        XCTAssertTrue(saved, "ItineraryCache was unable to save the itinerary")
        
        guard let savedItinerary = ItineraryCache.getItineraryForLine(mockLineName)
            else {
                XCTFail("ItineraryCache did not find the saved itinerary")
                return
            }
        
        XCTAssertEqual(savedItinerary.count, mockItinerary.count, "Size of saved and read array should match")
        
        for var i = 0; i < mockItinerary.count; ++i {
            XCTAssertEqual(savedItinerary[i].coordinate.latitude, mockItinerary[i].coordinate.latitude, "The saved latitude does not match")
            XCTAssertEqual(savedItinerary[i].coordinate.longitude, mockItinerary[i].coordinate.longitude, "The saved longitude does not match")
        }
    }
    
}
