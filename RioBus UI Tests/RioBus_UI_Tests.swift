import Foundation
import XCTest

class RioBus_UI_Tests: XCTestCase {
    
    let app = XCUIApplication()
    let searchField = XCUIApplication().searchFields.element
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        XCUIApplication().launch()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func ignoreOkAlerts(app: XCUIApplication) {
        if (app.alerts.count > 0) {
            app.alerts.element.collectionViews.buttons["OK"].tap()
        }
    }
    
    func testAddSearchToTable() {
        searchField.tap()
        
        searchField.typeText("324")
        app.typeText("\r")
        
        // Ignorar possíveis erros da pesquisa que não são relevantes neste caso
        ignoreOkAlerts(app);
        
        searchField.tap()
        let newCell = app.tables.cells.containingType(.StaticText, identifier: "324").element
        XCTAssert(newCell.exists, "Linha 324 não foi encontrada na tabela")
    }
    
    func testMarkBusLineAsFavorite() {
        searchField.tap()
        
        let favoriteCell = app.tables.cells.containingType(.Button, identifier: "StarFilled").element
        let normalCells = app.tables.cells.containingType(.Button, identifier: "Star")
        
        // Se já existir uma linha favorita, removê-la
        if (favoriteCell.exists) {
            favoriteCell.buttons["StarFilled"].tap()
            app.alerts.collectionViews.buttons["Excluir"].tap()
            XCTAssert(!favoriteCell.exists, "Não removeu a linha favorita");
        }
        
        // Garantir que exista pelo menos duas linhas normais na tabela
        if (normalCells.count < 2) {
            // Adicionar primeira
            searchField.typeText("324")
            app.typeText("\r")
            // Ignorar possíveis erros da pesquisa que não são relevantes neste caso
            ignoreOkAlerts(app);
            searchField.tap()
            
            // Adicionar segunda
            if (normalCells.count < 2) {
                let deleteKey = XCUIApplication().keys["Delete"]
                deleteKey.tap()
                deleteKey.tap()
                deleteKey.tap()
                
                searchField.typeText("485")
                app.typeText("\r")
                // Ignorar possíveis erros da pesquisa que não são relevantes neste caso
                ignoreOkAlerts(app);
                searchField.tap()
            }
        }
        
        // Marcar uma linha como favorita
        let normalCell = normalCells.elementAtIndex(0)
        normalCell.buttons["Star"].tap()
        XCTAssertEqual(favoriteCell.staticTexts.element.value as! String, normalCell.staticTexts.element.value as! String, "Não salvou a primeira linha como favorito")
        
        // Marcar outra linha como favorita
        normalCell.buttons["Star"].tap()
        app.alerts.collectionViews.buttons["Redefinir"].tap()
        XCTAssertEqual(favoriteCell.staticTexts.element.value as! String, normalCell.staticTexts.element.value as! String, "Não salvou a segunda linha como favorito")
        
        // Remover dos favoritos
        favoriteCell.buttons["StarFilled"].tap()
        app.alerts.collectionViews.buttons["Excluir"].tap()
        XCTAssert(!favoriteCell.exists, "Não removeu a linha favorita");
    }
    
    func testBusLineSearchScreen() {
        searchField.tap()
        searchField.typeText("324")
        app.typeText("\r")
        
        XCTAssertEqual(app.alerts.count, 0, "Ocorreu um erro fazendo uma pesquisa")
        
        XCTAssert(app.staticTexts["324 - Ribeira X Castelo (Circular)"].exists, "Não exibiu a barra de informações")
        XCTAssert(app.buttons["Ribeira"].exists, "Não exibiu o botão do sentido 1")
        XCTAssert(app.buttons["Castelo"].exists, "Não exibiu o botão do sentido 2")
        XCTAssertEqual(searchField.value as! String, "324", "Não atualizou a barra de pesquisa")
        
    }
    
    func testClearFromTable() {
        // TODO: adicionar elementos recentes na lista, limpar, verificar se limpou
        XCTFail("Unimplemented")
    }
    
    func testOptionsScreen() {
        app.buttons["InfoButton"].tap()
        
        let limparCacheButton = app.buttons["Limpar Cache"]
        limparCacheButton.tap()
        app.alerts["Limpar o cache"].collectionViews.buttons["Cancelar"].tap()
        limparCacheButton.tap()
        app.alerts["Limpar o cache"].collectionViews.buttons["Limpar"].tap()
        app.navigationBars["RioBus"].childrenMatchingType(.Button).matchingIdentifier("Back").elementAtIndex(0).tap()

    }
    
}
