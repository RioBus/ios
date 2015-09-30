#import "SnapshotHelper.js"

var target = UIATarget.localTarget();
target.delay(2)

// Capture recent lines table
target.frontMostApp().mainWindow().searchBars()[0].searchBars()[0].tap();
captureLocalizedScreenshot("0-TabelaPesquisa")

// Search for a line
target.frontMostApp().keyboard().typeString("348\n");
target.delay(1)
captureLocalizedScreenshot("1-PesquisaLinha")

// Capture About screen
target.frontMostApp().mainWindow().searchBars()[0].buttons()["Limpar texto"].tap();
target.frontMostApp().mainWindow().buttons()["Informações"].tap();
captureLocalizedScreenshot("2-TelaInformacoes")

