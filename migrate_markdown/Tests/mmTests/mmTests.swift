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
::alert[This guide assumes that you are familiar with iOS development and tools. If you are new to iOS development, you can follow [these steps](https://developer.apple.com/library/archive/referencelibrary/GettingStarted/DevelopiOSAppsSwift/BuildABasicUI.html) to create your first iOS application using Swift.]{header="Info" type="info"}
End of Hello World
"""    

        let replace = ReplaceEnclosure(
                src: Enclosure(start: "{{% notice info %}}\n", end: "\n{{% /notice %}}"),
                dst: Enclosure(start: "::alert[", end: "]{header=\"Info\" type=\"info\"}")
            )

        // when 
        let changed = replace.replace(oldContent: source, forFile: URL(fileURLWithPath: "/dummy"))

        // then 
        XCTAssertEqual(destination, changed)

    }

    func testTitlesPreInIndex() {

        // given 
        let source = """
---
title : "Prerequisites"
chapter : true
weight : 10
pre : "<b>1. </b>"
---

### Section 1

## Prerequisites for the Workshop

* [AWS Temporary Account](/10_prerequisites/05_event_engine.html)
* [Create an IAM User](/10_prerequisites/10_iam_user.html)
* [Installs](/10_prerequisites/20_installs.html)
* [Configs](/10_prerequisites/30_configs.html)
"""

    let destination = """
---
title : "Prerequisites"
chapter : true
weight : 10

---





* [AWS Temporary Account](/10_prerequisites/05_event_engine.html)
* [Create an IAM User](/10_prerequisites/10_iam_user.html)
* [Installs](/10_prerequisites/20_installs.html)
* [Configs](/10_prerequisites/30_configs.html)
"""

        // when 
        let replace = ReplaceTitlesAndPreInIndex()
        let changed = replace.replace(oldContent: source, forFile: URL(fileURLWithPath: "/_index.md"))

        // then 
        XCTAssertEqual(destination, changed)
    }

    func testreInvent() {

        // given 
        let source = """
When attending this workshop during an event organised by AWS, such as [AWS re:Invent](https://reinvent.awsevents.com/), you may choose to use one of AWS' temporary AWS Account instead of using your personal or company AWS account.  Follow the instructions from this page and the AWS instructor in the room to access the temporary account.
"""

    let destination = """
When attending this workshop during an event organised by AWS, such as [AWS re\\:Invent](https://reinvent.awsevents.com/), you may choose to use one of AWS' temporary AWS Account instead of using your personal or company AWS account.  Follow the instructions from this page and the AWS instructor in the room to access the temporary account.
"""

        // when 
        let replace = ReplaceReIvent()
        let changed = replace.replace(oldContent: source, forFile: URL(fileURLWithPath: "/dummy"))

        // then 
        XCTAssertEqual(destination, changed)
    }

        func testImages() {

        // given 
        let source = """
![open console](/images/10-05-30.png)
"""

    let destination = """
![open console](/static/images/10-05-30.png)
"""

        // when 
        let replace = ReplaceImages()
        let changed = replace.replace(oldContent: source, forFile: URL(fileURLWithPath: "/dummy"))

        // then 
        XCTAssertEqual(destination, changed)
    }

    func testReplaceTabs() {

        // given
        let src = 
"""
...
text
...
{{< tabs groupId="install-group" >}}
{{% tab name="Install" %}}
...
text 1
...
{{% /tab %}}
{{% tab name="Verify" %}}
...
text 2
...
{{% /tab %}}
{{< /tabs >}}
...
text
...
"""

        let dst = 
"""
...
text
...
::::tabs{variant="install-group"}
:::tab{id="Install" label="Install"}
...
text 1
...
:::
:::tab{id="Verify" label="Verify"}
...
text 2
...
:::
::::
...
text
...
"""

        // when 
        let replace = ReplaceTwoTabs()
        let changed = replace.replace(oldContent: src, forFile: URL(fileURLWithPath: "/dummy"))

        // then 
        XCTAssertEqual(dst, changed)

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
