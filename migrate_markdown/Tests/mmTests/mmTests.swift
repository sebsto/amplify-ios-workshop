import XCTest
@testable import mm

final class mmTests: XCTestCase {

    func testAlerts() throws {
        
        // given 
        let source: String = """
Hello World
{{% notice info %}}
This guide assumes that you are familiar with iOS development and tools. If you are new to iOS development, you can follow [these steps](https://developer.apple.com/library/archive/referencelibrary/GettingStarted/DevelopiOSAppsSwift/BuildABasicUI.html) to create your first iOS application using Swift.
{{% /notice %}}
End of Hello World
"""

    let destination: String = """
Hello World
::alert[
This guide assumes that you are familiar with iOS development and tools. If you are new to iOS development, you can follow [these steps](https://developer.apple.com/library/archive/referencelibrary/GettingStarted/DevelopiOSAppsSwift/BuildABasicUI.html) to create your first iOS application using Swift.
]{header="Info" type="info"}
End of Hello World
"""    

        let replace = ReplaceEnclosure(
                src: Enclosure(start: "{{% notice info %}}", end: "{{% /notice %}}"),
                dst: Enclosure(start: "::alert[", end: "]{header=\"Info\" type=\"info\"}")
            )

        // when 
        let changed = replace.replace(oldContent: source)

        // then 
        XCTAssertEqual(destination, changed)

    }

    func testReplaceFilePath() {
        
        // given 
        let src : URL = URL(fileURLWithPath: "/workshop-src/content/index.md")
        let dst : URL = URL(fileURLWithPath: "/workshop-dst/content/index.md")

        // when 
        let changed = mm().newFilePath(oldFilePath: src)

        // then 
        XCTAssertEqual(dst, changed)

    }

    func testRenameIndex() {
        // given 
        let src : URL = URL(fileURLWithPath: "/workshop-src/content/_index.md")
        let dst : URL = URL(fileURLWithPath: "/workshop-src/content/index.en.md")

        // when 
        let changed = mm().renameIndexFile(src)

        // then 
        XCTAssertEqual(dst, changed)
    }
}
