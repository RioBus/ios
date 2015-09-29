import Foundation
import XCTest

class RioBusUITests: XCTestCase {
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
    
    /**
    * Ignora possíveis alertas na tela, que podem ter sido causados por problemas de comunicação
    * com o servidor ou porque a linha não foi encontrada.
    */
    func ignoreOkAlerts(app: XCUIApplication) {
        if (app.alerts.count > 0) {
            app.alerts.element.collectionViews.buttons["OK"].tap()
        }
    }
    
    /**
     * Garante que existam pelo menos duas linhas no histórico de pesquisa, adicionando-as caso
     * necessário.
     */
    func addSomeLinesToHistory() {
        let normalCells = app.tables.cells.containingType(.Button, identifier: "Star")
        
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
    }
    
    /**
    * Pesquisa por uma linha e verifica se a mesma foi adicionada na tabela de pesquisas recentes.
    */
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
    
    /**
    * Testa a funcionalidade da linha favorita. Pra isso, testa como marcar a linha como favorita 
    * quando não existe outra, desmarcar a linha como favorita e substituir uma linha favorita.
    */
    func testMarkBusLineAsFavorite() {
        searchField.tap()
        
        let favoriteCell = app.tables.cells.containingType(.Button, identifier: "StarFilled").element
        let normalCells = app.tables.cells.containingType(.Button, identifier: "Star")
        
        // Se já existir uma linha favorita, removê-la
        if (favoriteCell.exists) {
            favoriteCell.buttons["StarFilled"].tap()
            app.alerts.collectionViews.buttons["Excluir"].tap()
            XCTAssertFalse(favoriteCell.exists, "Não removeu a linha favorita");
        }
        
        addSomeLinesToHistory()
        
        // Marcar uma linha como favorita
        let normalCell = normalCells.elementBoundByIndex(0)
        normalCell.buttons["Star"].tap()
        XCTAssertEqual(favoriteCell.staticTexts.elementBoundByIndex(0).value as? String, normalCell.staticTexts.elementBoundByIndex(0).value as? String, "Não salvou a primeira linha como favorito")
        
        // Marcar outra linha como favorita
        normalCell.buttons["Star"].tap()
        app.alerts.collectionViews.buttons["Redefinir"].tap()
        XCTAssertEqual(favoriteCell.staticTexts.elementBoundByIndex(0).value as? String, normalCell.staticTexts.elementBoundByIndex(0).value as? String, "Não salvou a segunda linha como favorito")
        
        // Remover dos favoritos
        favoriteCell.buttons["StarFilled"].tap()
        app.alerts.collectionViews.buttons["Excluir"].tap()
        XCTAssertFalse(favoriteCell.exists, "Não removeu a linha favorita");
    }
    
    /**
    * Testa se a barra de informações da linha é exibida na pesquisa
    */
    func testBusLineSearchScreen() {
        searchField.tap()
        searchField.typeText("636")
        app.typeText("\r")
        
        XCTAssertEqual(app.alerts.count, 0, "Ocorreu um erro fazendo uma pesquisa")
        
        XCTAssert(app.staticTexts["636 - Saens Pena X Gardenia Azul"].exists, "Não exibiu a barra de informações")
        XCTAssert(app.buttons["Saens Pena"].exists, "Não exibiu o botão do sentido 1")
        XCTAssert(app.buttons["Gardenia Azul"].exists, "Não exibiu o botão do sentido 2")
        XCTAssertEqual(searchField.value as? String, "636", "Não atualizou a barra de pesquisa")
    }
    
    /**
     * Testa a funcionalidade de apagar o histórico de pesquisas recentes. Para isso, garante
     * primeiro que exista pelo menos duas linhas na tabela e então as remove.
     */
    func testClearFromTable() {
        searchField.tap()
        
        addSomeLinesToHistory()
        
        let normalCells = app.tables.cells.containingType(.Button, identifier: "Star")
        let limparPesquisasButton = app.tables.cells.containingType(.StaticText, identifier: "Limpar pesquisas").element
        
        XCTAssert(limparPesquisasButton.exists, "Botão de limpar pesquisas deveria existir");
        limparPesquisasButton.tap()
        app.alerts["Limpar histórico"].collectionViews.buttons["Excluir"].tap()
        
        XCTAssertEqual(normalCells.count, 0, "Lista de linhas recentes não foi limpa")
        XCTAssertFalse(limparPesquisasButton.exists, "Botão de limpar pesquisas não deveria existir mais");
    }
    
    /**
     * Testa a abertura da tela de informações assim como suas funcionalidades, como reportar problema
     * e o botão para abrir a página do Facebook.
    */
    func testInfoScreen() {
        // Tap info button
        app.buttons["Informações"].tap()
                
        // Test: Reportar problema
        app.buttons["Reportar problema"].tap()
        
        let table = app.tables
        let voltarParaProblemasButton = app.navigationBars["Problema"].buttons["Problemas"]
        let enviarMensagemButton = app.buttons["Enviar mensagem"]
        
        table.staticTexts["Não encontrei uma linha"].tap()
        XCTAssertEqual(app.navigationBars.element.identifier, "Problema", "Não abriu a tela do problema")
        XCTAssertFalse(enviarMensagemButton.exists, "Report foi parar na tela para enviar mensagem pro RioBus erroneamente")
        voltarParaProblemasButton.tap()
        
        table.staticTexts["Localização incorreta no mapa"].tap()
        XCTAssertEqual(app.navigationBars.element.identifier, "Problema", "Não abriu a tela do problema")
        XCTAssertFalse(enviarMensagemButton.exists, "Report foi parar na tela para enviar mensagem pro RioBus erroneamente")
        voltarParaProblemasButton.tap()
        
        table.staticTexts["Itinerário incorreto"].tap()
        XCTAssertEqual(app.navigationBars.element.identifier, "Problema", "Não abriu a tela do problema")
        XCTAssertFalse(enviarMensagemButton.exists, "Report foi parar na tela para enviar mensagem pro RioBus erroneamente")
        voltarParaProblemasButton.tap()
        
        table.staticTexts["Problemas com o aplicativo"].tap()
        XCTAssertEqual(app.navigationBars.element.identifier, "Problema", "Não abriu a tela do problema")
        XCTAssert(enviarMensagemButton.exists, "Report deveria ter mostrado tela para enviar mensagem pro RioBus")
        voltarParaProblemasButton.tap()
        
        table.staticTexts["Outro"].tap()
        
        XCTAssertEqual(app.navigationBars.element.identifier, "Problema", "Não abriu a tela do problema")
        XCTAssert(enviarMensagemButton.exists, "Report deveria ter mostrado tela para enviar mensagem pro RioBus")
        voltarParaProblemasButton.tap()
        
        // Voltar para tela de info
        app.navigationBars["Reportar problema"].buttons["RioBus"].tap()
        
        // Botão para a página do Facebook
        XCTAssert(app.buttons["RioBus no Facebook"].exists, "Botão para o Facebook não encontrado")
        
        app.navigationBars["RioBus"].buttons["Fechar"].tap()
    }
    
}
