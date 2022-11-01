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

    func testReplaceCode() {

        // given
        let src = 
"""
...
```swift {linenos=false,hl_lines=[8-8]}
// Landmarks/Models/UserData.swift
import Combine
import SwiftUI

final class UserData: ObservableObject {
    @Published var showFavoritesOnly = false
    @Published var landmarks = landmarkData
    @Published var isSignedIn : Bool = false
}
```
...
```xml  {hl_lines=["5-14"]} no_copy
     <!-- YOUR OTHER PLIST ENTRIES HERE -->

     <!-- ADD AN ENTRY TO CFBundleURLTypes for Cognito Auth -->
     <!-- IF YOU DO NOT HAVE CFBundleURLTypes, YOU CAN COPY THE WHOLE BLOCK BELOW -->
     <key>CFBundleURLTypes</key>
     <array>
         <dict>
             <key>CFBundleURLSchemes</key>
             <array>
                 <string>landmarks</string>
             </array>
         </dict>
     </array>
```
...
```bash  
# this is a copy paste from event engine console

# !! PASTE THE LINES FROM AWS EVENT ENGINE PAGE !!

export AWS_ACCESS_KEY_ID="AS (redacted) 6B"
export AWS_SECRET_ACCESS_KEY="pR (redacted) qr"
export AWS_SESSION_TOKEN="IQ (redacted) e94="
```
...
"""

        let dst = 
"""
...
:::code{language=swift}
// Landmarks/Models/UserData.swift
import Combine
import SwiftUI

final class UserData: ObservableObject {
    @Published var showFavoritesOnly = false
    @Published var landmarks = landmarkData
    @Published var isSignedIn : Bool = false
}
:::
...
:::code{language=xml showCopyAction=false}
     <!-- YOUR OTHER PLIST ENTRIES HERE -->

     <!-- ADD AN ENTRY TO CFBundleURLTypes for Cognito Auth -->
     <!-- IF YOU DO NOT HAVE CFBundleURLTypes, YOU CAN COPY THE WHOLE BLOCK BELOW -->
     <key>CFBundleURLTypes</key>
     <array>
         <dict>
             <key>CFBundleURLSchemes</key>
             <array>
                 <string>landmarks</string>
             </array>
         </dict>
     </array>
:::
...
:::code{language=bash}
# this is a copy paste from event engine console

# !! PASTE THE LINES FROM AWS EVENT ENGINE PAGE !!

export AWS_ACCESS_KEY_ID="AS (redacted) 6B"
export AWS_SECRET_ACCESS_KEY="pR (redacted) qr"
export AWS_SESSION_TOKEN="IQ (redacted) e94="
:::
...

"""

        // when 
        let replace = ReplaceCode()
        let changed = replace.replace(oldContent: src, forFile: URL(fileURLWithPath: "/dummy"))

        // then 
        XCTAssertEqual(dst, changed)
        // try! dst.data(using: .utf8)!.write(to:  URL(fileURLWithPath:"/tmp/dst"))
        // try! changed.data(using: .utf8)!.write(to: URL(fileURLWithPath:"/tmp/changed"))

    }

    func testReplaceFilePath() {
        
        // given 
        let src : URL = URL(fileURLWithPath: "\(SRC_FILE_PATH)/index.md")
        let dst : URL = URL(fileURLWithPath: "\(DST_FILE_PATH)/index.md")

        // when 
        let changed = mm().newFilePath(oldFilePath: src)

        // then 
        XCTAssertEqual(dst, changed)

    }

    func testRenameIndex() {
        // given 
        let src : URL = URL(fileURLWithPath: "\(DST_FILE_PATH)/_index.md")
        let dst : URL = URL(fileURLWithPath: "\(DST_FILE_PATH)/index.en.md")

        // when 
        let changed = mm().renameIndexFile(src)

        // then 
        XCTAssertEqual(dst, changed)
    }

    func testButton() {

        // given 
        let src = """
{{% button href="/20_getting_started/20_bootstrapping_the_app.files/HandlingUserInput.zip" icon="fas fa-download" %}}project zip file{{% /button %}}
"""
        let dst = """
:button[project zip file]{href="/static/20_getting_started/20_bootstrapping_the_app.files/HandlingUserInput.zip" action=download}
"""
        // when 
        let replace = ReplaceButton()
        let changed = replace.replace(oldContent: src, forFile: URL(fileURLWithPath: "/dummy"))

        // then 
        XCTAssertEqual(dst, changed)
    }
}
