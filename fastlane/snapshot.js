#import "SnapshotHelper.js"


var target = UIATarget.localTarget();

target.delay(2)

target.frontMostApp().mainWindow().searchBars()[0].searchBars()[0].tap();
captureLocalizedScreenshot("0-TabelaPesquisa")

target.frontMostApp().keyboard().typeString("485\n");
target.delay(2)
target.frontMostApp().mainWindow().buttons()["General Osorio"].tap();
captureLocalizedScreenshot("0-PesquisaLinha")

target.frontMostApp().mainWindow().searchBars()[0].buttons()["Limpar texto"].tap();
target.frontMostApp().mainWindow().buttons()["Informações"].tap();
captureLocalizedScreenshot("0-TelaInformacoes")

