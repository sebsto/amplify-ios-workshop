import Foundation

#if os(Linux)

  // when running inside docker
  // docker run --rm -it -v $(pwd):/src \
  //            -v /Users/stormacq/Documents/amazon/code/amplify/amplify-ios-workshop/workshop/instructions:/workshop-src \
  //            -v /Users/stormacq/Documents/amazon/te/2022/reinvent/BOA332\ iOS\ workshop/workshop/amplify-ios-workshop:/workshop-dst \
  //            swift:5.7-amazonlinux2 /bin/bash
  let SRC_FILE_PATH = "/workshop-src/content"
  let DST_FILE_PATH = "/workshop-dst/content"

#elseif os(macOS)

  // when running on OSX (requires Xcode 14 and macOS 13)
  let SRC_BASE_PATH = "/Users/stormacq/Documents/amazon/code/amplify/amplify-ios-workshop"
  let SRC_FILE_PATH =
    "\(SRC_BASE_PATH)/workshop-hugo/instructions/content"
  let DST_FILE_PATH =
    "\(SRC_BASE_PATH)/workshop-aws/amplify-ios-workshop/content"

#endif

protocol Replacement {
  func replace(oldContent: String, forFile: URL) -> String
}
let changes: [any Replacement] = [

  //code
  ReplaceCode(),

  // notice warning
  ReplaceEnclosure(
    src: Enclosure(start: "{{% notice warning %}}\n", end: "\n{{% /notice %}}"),
    dst: Enclosure(start: ":::alert{header=\"Warning\" type=\"warning\"}\n", end: "\n:::")
  ),

  // notice info
  ReplaceEnclosure(
    src: Enclosure(start: "{{% notice info %}}\n", end: "\n{{% /notice %}}"),
    dst: Enclosure(start: ":::alert{header=\"Info\" type=\"info\"}\n", end: "\n:::")
  ),

  // notice tip
  ReplaceEnclosure(
    src: Enclosure(start: "{{% notice tip %}}\n", end: "\n{{% /notice %}}"),
    dst: Enclosure(start: ":::alert{header=\"Tip\" type=\"success\"}\n", end: "\n:::")
  ),

  // notice note
  ReplaceEnclosure(
    src: Enclosure(start: "{{% notice note %}}\n", end: "\n{{% /notice %}}"),
    dst: Enclosure(start: ":::alert{header=\"Note\" type=\"info\"}\n", end: "\n:::")
  ),

  // change image URL
  ReplaceImages(),

  // re:Invent to re:\Invent
  ReplaceReIvent(),

  // in _index.md, remove titles and pre front matter
  ReplaceTitlesAndPreInIndex(),

  // Tabs
  ReplaceTwoTabs(),

  // Download button
  ReplaceButton(),
]

struct ReplaceCode: Replacement {

  /**

```language {highlight} no_copy
code
```

to

:::code{language=language showCopyAction=false}
code
:::

{highlight} if present is ignored
{no_copy} if present is transformed to showCopyAction=false
*/
  private func captureLanguageName(content: String) -> String {

    var result = ""

    // see https://www.swift.org/blog/using-upcoming-feature-flags/
    #if compiler(>=5.8)
      #if hasFeature(BareSlashRegexLiterals)
        let captureLanguageName = /^```(.*?) (.*)$/
        if let captureLanguageName = try? captureLanguageName.wholeMatch(in: content) {
        result = String(captureLanguageName.output.1)
        // print(result)
        // } else {
        //   print("no group match")
      }
      #else
        fatalError("Compile with Swift 5.8")
        // let captureLanguageName = #/^```(.*?) (.*)$/#
      #endif
    #else
      guard let captureLanguageName = try? Regex("^```(.*?) (.*)$") else {
        fatalError("Invalid RegEx")  
      }
      if let captureLanguageName = try? captureLanguageName.wholeMatch(in: content) {
        result = String(captureLanguageName.output[1].substring!)
        // print(result)
        // } else {
        //   print("no group match")
      }
    #endif

    return result
  }

  private func captureNoCopy(content: String) -> Bool {
    let captureLanguageName = /^```.*(no_copy).*$/

    var result = ""

    if let captureLanguageName = try? captureLanguageName.wholeMatch(in: content) {
      result = String(captureLanguageName.output.1)
    }

    return result == "no_copy"
  }

  func replace(oldContent: String, forFile: URL) -> String {

    var result: String = ""
    for line in oldContent.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline) {
      let languageName = captureLanguageName(content: String(line))
      let hasNoCopy = captureNoCopy(content: String(line))

      guard let expressionToReplace = try? Regex("^```\(languageName) .*$") else {
        fatalError("Invalid RegEx")
      }
      let noCopy = hasNoCopy ? " showCopyAction=false" : ""
      let step1 = line.replacing(
        expressionToReplace, with: ":::code{language=\(languageName)\(noCopy)}")
      result += "\(step1)\n"
    }
    let step2 = result.replacingOccurrences(of: "```", with: ":::")
    return step2
  }

}

struct Enclosure {
  let start: String
  let end: String

  /**
Example:

{{% notice note %}}
...
{{% /notice %}}
*/
}

struct ReplaceEnclosure: Replacement {

  let src: Enclosure
  let dst: Enclosure

  func replace(oldContent: String, forFile: URL) -> String {
    let step1 = oldContent.replacingOccurrences(of: src.start, with: dst.start)
    let step2 = step1.replacingOccurrences(of: src.end, with: dst.end)
    return step2
  }
}

struct ReplaceTwoTabs: Replacement {

  /**
Example:

{{< tabs groupId="installs" >}}
{{% tab name="Install" %}}
...
text
...
{{% /tab %}}
{{% tab name="Verify" %}}
...
text
...
{{% /tab  %}}
{{< /tabs >}}

The replacement captures the groupID and name values
*/

  private func captureGroupName(content: String) -> String {
    guard let captureGroupId = try? Regex("(?s).*{{< tabs groupId=\"(.*?)\" .}}\n.*") else {
      fatalError("Invalid RegEx")
    }

    var result = ""

    if let resultGroupId = try? captureGroupId.wholeMatch(in: content) {
      result = String(resultGroupId.output[1].substring!)
      // } else {
      //     print("no group match")
    }

    return result
  }

  private func captureTabNames(content: String) -> (String, String) {

    // TODO try to do a recurring capture group
    // https://regex101.com/r/3zV61W/1
    // guard let captureTabNames = try? Regex("(?s).*?(?:{{% tab name=\"(.*?)\" %}})\n.*?") else {
    // guard
    //   let captureTabNames = try? Regex(
    //     "(?s).*{{% tab name=\"(.*?)\" %}}\n.*{{% tab name=\"(.*?)\" %}}\n.*")
    // else {
    //   fatalError("Invalid RegEx")
    // }
    let captureTabNames = /(?s).*{{% tab name=\"(.*?)\" %}}\n.*{{% tab name=\"(.*?)\" %}}\n.*/

    var tab1Result = ""
    var tab2Result = ""

    if let resultTabName = try? captureTabNames.wholeMatch(in: content) {
      // assert(resultTabName.output.count == 3)
      tab1Result = String(resultTabName.output.1)
      tab2Result = String(resultTabName.output.2)
      // } else {
      //     print("no tab match")
    }

    return (tab1Result, tab2Result)
  }

  func replace(oldContent: String, forFile: URL) -> String {

    let groupName = captureGroupName(content: oldContent)
    let (tab1Name, tab2Name) = captureTabNames(content: oldContent)

    let step1 = oldContent.replacingOccurrences(
      of: "{{< tabs groupId=\"\(groupName)\" >}}", with: "::::tabs{variant=\"\(groupName)\"}")
    let step2 = step1.replacingOccurrences(
      of: "{{% tab name=\"\(tab1Name)\" %}}",
      with: ":::tab{id=\"\(tab1Name)\" label=\"\(tab1Name)\"}")
    let step3 = step2.replacingOccurrences(
      of: "{{% tab name=\"\(tab2Name)\" %}}",
      with: ":::tab{id=\"\(tab2Name)\" label=\"\(tab2Name)\"}")
    let step4 = step3.replacingOccurrences(of: "{{% /tab %}}", with: ":::")
    let step5 = step4.replacingOccurrences(of: "{{< /tabs >}}", with: "::::")

    return step5
  }
}

struct ReplaceButton: Replacement {

  /**
    Example

{{% button href="/20_getting_started/20_bootstrapping_the_app.files/HandlingUserInput.zip" icon="fas fa-download" %}}project zip file{{% /button %}}

    The replacement captures the path and text values

    */
  private func captureValues(content: String) -> (String, String) {
    //"(?s).*{{% button href=\"(.*)\" icon=\"fas fa-download\" %}}.*")
    let capturePath = #/(?s).*{{% button href=\"(.*)\" icon=\"fas fa-download\" %}}(.*){{% /button %}}.*/#
    
    var pathResult = ""
    var textResult = ""

    if let resultPathName = try? capturePath.wholeMatch(in: content) {
      // assert(resultPathName.output.count == 3)
      pathResult = String(resultPathName.output.1)
      textResult = String(resultPathName.output.2)
    }

    return (pathResult, textResult)
  }

  func replace(oldContent: String, forFile: URL) -> String {

    let (path, text) = captureValues(content: oldContent)

    let step1 = oldContent.replacingOccurrences(
      of: "{{% button href=\"\(path)\" icon=\"fas fa-download\" %}}\(text){{% /button %}}",
      with: ":button[\(text)]{href=\"/static\(path)\" action=download}")

    return step1
  }
}

struct ReplaceTitlesAndPreInIndex: Replacement {
  func replace(oldContent: String, forFile: URL) -> String {

    guard forFile.lastPathComponent == "_index.md" else {
      return oldContent
    }
    let step1 = oldContent.replacing(#/\n### Section.*/#, with: "")
    let step2 = step1.replacing(#/\n## .*/#, with: "")
    let step3 = step2.replacing(#/\n# .*/#, with: "")
    let step4 = step3.replacing(#/pre : .*/#, with: "")
    return step4
  }
}

struct ReplaceReIvent: Replacement {
  func replace(oldContent: String, forFile: URL) -> String {
    return oldContent.replacingOccurrences(of: "re:Invent", with: "re\\:Invent")
  }
}

struct ReplaceImages: Replacement {
  func replace(oldContent: String, forFile: URL) -> String {
    guard let regex = try? Regex("]\\(/images/") else {
      fatalError("Invalid regex")
    }
    return oldContent.replacing(regex, with: "](/static/images/")
  }
}

@main
public struct mm {

  private let bold = "\u{001B}[1m"
  private let blue = "\u{001B}[0;34m"
  private let reset = "\u{001B}[0;0m"

  private func main() throws {

    let files = getMarkdownFiles()
    if files.isEmpty {
      print("No markdown files in \(SRC_FILE_PATH)")
    }

    for f in files {
      print("")
      print("\(bold)------------------------------------------------------------------------")
      print("\(blue)   Processing \(f) \(reset)")
      print("\(bold)------------------------------------------------------------------------")
      print(reset + "\n")

      guard let oldContent: String = try? String(contentsOf: f, encoding: .utf8) else {
        fatalError("Can not read content of \(f)")
      }
      var newContent: String = oldContent
      for c in changes {
        newContent = c.replace(oldContent: newContent, forFile: f)
      }

      var newFile = newFilePath(oldFilePath: f)

      if newFile.lastPathComponent == "_index.md" {
        newFile = renameIndexFile(newFile)
      }

      if newContent != oldContent {
        print("Saving new content to \(newFile)")
        try newContent.data(using: .utf8)!.write(to: newFile)
      }

    }
  }

  private func getMarkdownFiles() -> [URL] {

    let markdownFiles = #/.md$/#
    let files = listFiles(
      startAt: SRC_FILE_PATH,
      forFiles: markdownFiles)

    return files
  }

  public static func main() {
    do {
      try mm().main()
    } catch {
      print("\(error)")
    }
  }
}

// file management
extension mm {
  private func listFiles(startAt: String, forFiles: any RegexComponent) -> [URL] {
    let url = URL(fileURLWithPath: startAt)
    var result = [URL]()

    let fm = FileManager.default
    if let enumerator = fm.enumerator(
      at: url,
      includingPropertiesForKeys: [.isRegularFileKey],
      options: [.skipsHiddenFiles, .skipsPackageDescendants])
    {

      for case let fileURL as URL in enumerator {
        do {
          let fileAttributes = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
          if fileAttributes.isRegularFile ?? false {
            if fileURL.lastPathComponent.contains(forFiles) {
              result.append(fileURL)
            }
          }
        } catch { print(error, fileURL) }
      }
    }
    return result
  }

  func newFilePath(oldFilePath: URL) -> URL {

    // replace
    // file:///workshop-src/content/index.md
    // with
    // file:///workshop-dst/content/index.md

    // workshop-xxx can be anything

    let oldPath = oldFilePath.absoluteString
    let newPath = oldPath.replacing(SRC_FILE_PATH, with: DST_FILE_PATH)
    guard let url = URL(string: newPath) else {
      fatalError("can not create URL with \(newPath)")
    }
    return url
  }

  func renameIndexFile(_ oldFilePath: URL) -> URL {
    let oldPath = oldFilePath.absoluteString
    let newPath = oldPath.replacing("_index.md", with: "index.en.md")
    guard let url = URL(string: newPath) else {
      fatalError("can not create URL with \(newPath)")
    }
    return url
  }
}
