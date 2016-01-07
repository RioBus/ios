import XCTest

class TakeScreenshots: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        continueAfterFailure = false
        
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testScreenshots() {
        let app = XCUIApplication()
        let searchField = app.searchFields["Pesquisar linha de ônibus"]
        searchField.tap()
        snapshot("0-TabelaPesquisa")
        
        searchField.typeText("485\n")
        snapshot("1-PesquisaLinha")
        
        searchField.buttons["Limpar texto"].tap()
        app.buttons["Informações"].tap()
        snapshot("2-TelaInformacoes")
    }
    
}
