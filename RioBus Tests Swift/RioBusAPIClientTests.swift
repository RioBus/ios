import XCTest
@testable import riobus

class RioBusAPIClientTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testGetBusesForLineWithValidLine() {
        let expectation = expectationWithDescription("getBusesForLine")
        
        RioBusAPIClient.getBusesForLine("485") { (buses, error) -> Void in
            XCTAssertNil(error, "The request returned an error")
            XCTAssertNotNil(buses, "The request returned a nil response")
            XCTAssertGreaterThan(buses!.count, 0, "The request returned an empty array")
            
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(5) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    func testGetBusesForLineWithInvalidLine() {
        let expectation = expectationWithDescription("getBusesForLine")
        
        RioBusAPIClient.getBusesForLine("AAAAA") { (buses, error) -> Void in
            XCTAssertNil(error, "The request returned an error")
            XCTAssertNotNil(buses, "The request returned a nil response")
            XCTAssertEqual(buses!.count, 0, "The request should have returned an empty array")
            
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(5) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    func testGetItineraryForLineWithValidLine() {
        let expectation = expectationWithDescription("getItineraryForLine")
        
        RioBusAPIClient.getItineraryForLine("485") { (itinerarySpots, error) -> Void in
            XCTAssertNil(error, "The request returned an error")
            XCTAssertNotNil(itinerarySpots, "The request returned a nil response")
            XCTAssertGreaterThan(itinerarySpots!.count, 0, "The request returned an empty array")
            
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(5) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
}
