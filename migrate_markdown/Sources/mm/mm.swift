import Foundation

#if os(Linux)

  // when running inside docker
  // docker run --rm -it -v $(pwd):/src \
  //            -v /Users/stormacq/Documents/amazon/code/amplify/amplify-ios-workshop/BOA332/instructions:/workshop-src \
  //            -v /Users/stormacq/Documents/amazon/te/2022/reinvent/BOA332\ iOS\ workshop/workshop/amplify-ios-workshop:/workshop-dst \
  //            swift:5.7-amazonlinux2 /bin/bash
  let SRC_FILE_PATH = "/workshop-src/content"
  let DST_FILE_PATH = "/workshop-dst/content"

#elseif os(macOS)

  // when running on OSX (requires Xcode 14 and macOS 13)
  let SRC_FILE_PATH =
    "/Users/stormacq/Documents/amazon/code/amplify/amplify-ios-workshop/BOA332/instructions/content"
  let DST_FILE_PATH =
    "/Users/stormacq/Documents/amazon/te/2022/reinvent/BOA332 iOS workshop/workshop/amplify-ios-workshop/content"

#endif

protocol Replacement {
  func replace(oldContent: String) -> String
}
let changes: [Replacement] = [

  // notice info
  ReplaceEnclosure(
    src: Enclosure(start: "{{% notice info %}}", end: "{{% /notice %}}"),
    dst: Enclosure(start: "::alert[", end: "]{header=\"Info\" type=\"info\"}")
  )
]

struct Enclosure {
  let start: String
  let end: String
}

struct ReplaceEnclosure: Replacement {

  let src: Enclosure
  let dst: Enclosure

  func replace(oldContent: String) -> String {
    let step1 = oldContent.replacingOccurrences(of: src.start, with: dst.start)
    let step2 = step1.replacingOccurrences(of: src.end, with: dst.end)
    return step2
  }
}

@main
public struct mm {

  private let bold = "\u{001B}[1m"
  private let blue = "\u{001B}[0;34m"
  private let reset = "\u{001B}[0;0m"

  private func main() throws {

    let files = getMarkdownFiles()

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
        newContent = c.replace(oldContent: newContent)
      }

      var newFile = newFilePath(oldFilePath: f)

      if newFile.lastPathComponent == "_index.md" {
        newFile = renameIndexFile(newFile)
      }

      if newContent == oldContent {
        print("Saving new content to \(newFile)")
        try newContent.data(using: .utf8)!.write(to: newFile)
      }
      
    }
  }

  private func getMarkdownFiles() -> [URL] {

    let markdownFiles = /.md$/
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
