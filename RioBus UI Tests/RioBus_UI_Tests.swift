import Foundation
import XCTest

class RioBus_UI_Tests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        let app = XCUIApplication()
        app.searchFields["Pesquisar linha de ônibus"].tap()
        
        let pesquisarLinhaDeNibusSearchField = app.searchFields["Pesquisar linha de ônibus"]
        pesquisarLinhaDeNibusSearchField.typeText("324")
        app.typeText("\r")
//        app.alerts["Erro"].collectionViews.buttons["OK"].tap() // FIXME: nao devia ter erro
        pesquisarLinhaDeNibusSearchField.tap()
        
        let suggestionTable = app.tables
        let newCell = suggestionTable.cells["324"]
        XCTAssertEqual(newCell.exists, true)
        
    }
    
    func testOptionsScreen() {
        let app = XCUIApplication()

        app.buttons["InfoButton"].tap()
        
        let limparCacheButton = app.buttons["Limpar Cache"]
        limparCacheButton.tap()
        app.alerts["Limpar o cache"].collectionViews.buttons["Cancelar"].tap()
        limparCacheButton.tap()
        app.alerts["Limpar o cache"].collectionViews.buttons["Limpar"].tap()
        app.navigationBars["RioBus"].childrenMatchingType(.Button).matchingIdentifier("Back").elementAtIndex(0).tap()

    }
    
}
