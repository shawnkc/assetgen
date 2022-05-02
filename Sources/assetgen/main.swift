//
//  AssetGenerator.swift
//  AssetGenerator
//
//  Created by Shawn Casey on 4/27/22.
//

import Foundation
import ArgumentParser
import AppKit

let contentsJson: [String: Any] = ["info": ["author": "xcode", "version": 1]]
let contentsJsonDir: [String: Any] = ["info": ["author": "xcode", "version": 1], "properties": ["provides-namespace": true]]

struct ColorSetItem {
	let color: Color
	var isDark: Bool = false
	var idiom = "universal"

	func toDictionary() -> [String: Any] {
		var dict: [String: Any] = ["idiom": idiom]

		dict = dict.merging([
			"color": [
				"color-space": "srgb",
				"components": [
					"alpha": color.alphaComponent,
					"blue": color.blueComponent,
					"green": color.greenComponent,
					"red": color.redComponent
				]
			]
		], uniquingKeysWith: { first, _ in first })

		if isDark {
			dict = dict.merging([
				"appearances": [[
					"appearance": "luminosity",
					"value": "dark"
				]]
			], uniquingKeysWith: { first, _ in first })
		}

		return dict
	}
}

struct ColorSet {
	enum Value {
		case color(ColorSetItem)
		case colors(light: ColorSetItem, dark: ColorSetItem)
		case group([ColorSet])
	}
	let name: String
	let value: Value

	init(_ name: String, _ value: Value) {
		self.name = name
		self.value = value
	}

	init(_ name: String, _ color: Color) {
		self.name = name
		self.value = .color(ColorSetItem(color: color))
	}

	init(_ name: String, _ colorLight: Color, _ colorDark: Color) {
		self.name = name
		self.value = .colors(light: ColorSetItem(color: colorLight), dark: ColorSetItem(color: colorDark, isDark: true))
	}

	// This builds from the parent's directories and creates directories as it goes
	func writeTo(_ basePath: String) {
		makeDirectory(basePath)
		writeData(contentsJsonDir.jsonData, filePath: "\(basePath)/Contents.json")

		// Save to content.json
		let colorSetDir = "\(basePath)/\(name).colorset"

		var colorItems: [ColorSetItem] = []
		switch value {
			case .color(let colorSetItem):
				colorItems = [colorSetItem]
			case .colors(let light, let dark):
				colorItems = [light, dark]
			case .group(let array):
				array.forEach { $0.writeTo("\(basePath)/\(name)") }
				return
		}

		makeDirectory(colorSetDir)
		writeData(toDictionary(colorItems).jsonData, filePath: "\(colorSetDir)/Contents.json")
	}

	func toDictionary(_ colorItems: [ColorSetItem]) -> [String: Any] {
		let colors: [String: Any] = ["colors": colorItems.map { $0.toDictionary() }]
		let dict = contentsJson.merging(colors) { first, _ in first }
		return dict
	}
}

// https://www.swiftbysundell.com/articles/deep-dive-into-swift-function-builders/
@resultBuilder
struct ColorSetBuilder {
	static func buildBlock(_ components: ColorSetConvertible...) -> [ColorSet] {
		components.flatMap { $0.asColorSet() }
	}
}

struct ColorSetGroup {
	typealias ColorSetBuilderType = () -> [ColorSet]

	var name: String
	@ColorSetBuilder var builder: ColorSetBuilderType

	init(_ name: String, @ColorSetBuilder _ builder: @escaping ColorSetBuilderType) {
		self.name = name
		self.builder = builder
	}
}

protocol ColorSetConvertible {
	func asColorSet() -> [ColorSet]
}

extension ColorSet: ColorSetConvertible {
	func asColorSet() -> [ColorSet] { [self] }
}

extension ColorSetGroup: ColorSetConvertible {
	func asColorSet() -> [ColorSet] {
		[ColorSet(name, .group(builder()))]
	}
}

func makeColorSets(@ColorSetBuilder _ content: () -> [ColorSet]) -> [ColorSet] {
	content()
}

extension Dictionary {
	/// Converts Dictionary to Data that can be used to persist to a fle or convert to a string
	/// - SeeAlso: `jsonString`
	public var jsonData: Data? {
		if JSONSerialization.isValidJSONObject(self) {
			return try? JSONSerialization.data(withJSONObject: self, options: [])
		}
		return nil
	}
}

internal func makeDirectory(_ path: String) {
	do {
		if !FileManager.default.fileExists(atPath: path) {
			try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
		}
	} catch {
		print("\(#function): Error creating directory: \(error)")
	}
}

internal func deleteDirectory(_ path: String) {
	do {
		if !FileManager.default.fileExists(atPath: path) {
			try FileManager.default.removeItem(atPath: path)
		}
	} catch {
		print("\(#function): Error deleting directory: \(error)")
	}
}

internal func getFileHandle(path: String) -> FileHandle? {
	do {
		if !FileManager.default.fileExists(atPath: path) {
			if !FileManager.default.createFile(atPath: path, contents: nil, attributes: nil) {
				print("\(#function): Error creating file at: \(path)")
				return nil
			}
		}

		return try FileHandle(forWritingTo: URL(fileURLWithPath: path))
	} catch {
		print("\(#function): Error creating file handle at: \(path): \(error)")
		return nil
	}
}

internal func writeData(_ data: Data?, filePath: String) {
	if let fileHandle = getFileHandle(path: filePath),
		let data = data {
		fileHandle.write(data)
		fileHandle.closeFile()
	}
}

func readStdin() -> String? {
	var input: String?

	while let line = readLine() {
		if input == nil {
			input = line
		} else {
			input! += "\n" + line
		}
	}

	return input
}

@discardableResult
func shell(_ command: String) -> String {
	let task = Process()
	let pipe = Pipe()

	task.standardOutput = pipe
	task.standardError = pipe
	task.arguments = ["-c", command]
	task.launchPath = "/bin/zsh"
	task.launch()

	let data = pipe.fileHandleForReading.readDataToEndOfFile()
	let output = String(data: data, encoding: .utf8)!

	return output
}

//@main
struct AssetGen: ParsableCommand {
	@Argument() var assetFilename: String

	@Option(name: [.customShort("o"), .long], help: "name of output file(the command only writes to current directory)")
	var outputFile: String?

	@Flag(name: [.customShort("!"), .long], help: "use stdin to build new Theme.swift in Sources/assetgen and re-run application")
	var stdin: Bool = false

	func run() {
		var fullAssetFilename = assetFilename
		if !assetFilename.hasSuffix(".xcassets") {
			fullAssetFilename += ".xcassets"
		}

		if stdin {
			if let text = readStdin() {
				let data = text.data(using: .utf8)
				do {
					try data?.write(to: URL(fileURLWithPath: "./Sources/assetgen/Theme.swift"))

					shell("rm -rf \(fullAssetFilename)")
					shell("swift run assetgen \(fullAssetFilename)")
				} catch {
					print("error writing temp file from stdin")
				}
			}
		} else {

			print("Filename passed: \(fullAssetFilename)")

			deleteDirectory(fullAssetFilename)
			colorSets.forEach { $0.writeTo(fullAssetFilename) }
		}
	}
}


AssetGen.main()
