import XCTest
@testable import riobus

class RioBusAPIClientTests: XCTestCase {
    let TIMEOUT_SECONDS = 5.0
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testGetBusesWithValidLine() {
        let expectation = expectationWithDescription("getBusesForLine")
        
        RioBusAPIClient.getBusesForLine("485") { (buses, error) -> Void in
            XCTAssertNil(error, "The request returned an error")
            XCTAssertNotNil(buses, "The request returned a nil response")
            XCTAssertTrue(buses?.count > 0, "The request returned an empty array")
            
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(TIMEOUT_SECONDS) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    func testGetBusesWithInvalidLine() {
        let expectation = expectationWithDescription("getBusesForLine")
        
        RioBusAPIClient.getBusesForLine("AAAAA") { (buses, error) -> Void in
            XCTAssertNil(error, "The request returned an error")
            XCTAssertNotNil(buses, "The request returned a nil response")
            XCTAssertEqual(buses?.count, 0, "The request should have returned an empty array")
            
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(TIMEOUT_SECONDS) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    func testGetItineraryWithValidLine() {
        let expectation = expectationWithDescription("getItineraryForLine")
        
        RioBusAPIClient.getItineraryForLine("485") { (itinerarySpots, error) -> Void in
            XCTAssertNil(error, "The request returned an error")
            XCTAssertNotNil(itinerarySpots, "The request returned a nil response")
            XCTAssertTrue(itinerarySpots?.count > 0, "The request returned an empty array")
            
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(TIMEOUT_SECONDS) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    func testGetTrackedLines() {
        let expectation = expectationWithDescription("getTrackedLines")
        
        RioBusAPIClient.getTrackedBusLines { (trackedLines, error) -> Void in
            XCTAssertNil(error, "The request returned an error")
            XCTAssertNotNil(trackedLines, "The request returned a nil response")
            XCTAssertTrue(trackedLines?.count > 0, "The request returned an empty dictionary")
            
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(TIMEOUT_SECONDS) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
}
