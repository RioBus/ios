import XCTest
@testable import riobus

class RioBusAPIClientTests: XCTestCase {
    let api = RioBusAPIClient.sharedInstance
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testGetBusesForLine() {
        let expectation = expectationWithDescription("getBusesForLine")
        
        expectation.fulfill()
        
        waitForExpectationsWithTimeout(10) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
}
