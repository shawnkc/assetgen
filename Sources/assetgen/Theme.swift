#if os(macOS)
import AppKit
internal typealias Color = NSColor
#elseif os(iOS) || os(tvOS) || os(watchOS)
import UIKit
internal typealias Color = UIColor
#endif


private struct Palette {
	static let flavor1: Color = #colorLiteral(red: 0.1767555773, green: 0.7278817892, blue: 0.9095721841, alpha: 1)
	static let flavor2: Color = #colorLiteral(red: 0.9215686275, green: 0.03137254902, blue: 0.5490196078, alpha: 1)

	static let backgrounds: [Color] = [#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), #colorLiteral(red: 0.9490196078, green: 0.9490196078, blue: 0.9607843137, alpha: 1), #colorLiteral(red: 0.5294117647, green: 0.5960784314, blue: 0.6784313725, alpha: 1)]
	static let text: [Color] = [#colorLiteral(red: 0.3351496278, green: 0.3800235213, blue: 0.4293107723, alpha: 1), #colorLiteral(red: 0.4398039996, green: 0.4986902885, blue: 0.5633680573, alpha: 1), #colorLiteral(red: 0.5650449991, green: 0.6417745948, blue: 0.7237958312, alpha: 1)]

	static let mappingTripStart: Color = #colorLiteral(red: 0, green: 0.8235294118, blue: 0.5450980392, alpha: 1)
	static let mappingTripStop: Color = #colorLiteral(red: 0.9529411765, green: 0.2588235294, blue: 0.2588235294, alpha: 1)
	static let mappingTripTraveledPolyline: Color = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
}

// TODO: make a swiftUI preview with all the colors on a view.
// TODO: make a pre-build step of checking for swiftgen and running it
// TODO: make a pre-build step of generating Colors.xcassets and putting it in the right spot
// TODO: delete all the .swift files in the generated folder
// TODO: automatically generate a swiftgen.yaml that has ${PROJECT_DIR} based directories, etc.
// TODO: think about how to make button usage easier with the 3 states per type

let colorSets = makeColorSets {

	ColorSetGroup("Text") {
		ColorSet("duck", Palette.text[0])
	}

	ColorSetGroup("Views") {

		ColorSetGroup("Buttons") {
			ColorSet("primary", Palette.backgrounds[0])
		}

		ColorSet("primary", Palette.backgrounds[0])
		ColorSet("secondary", Palette.backgrounds[1])
		ColorSet("tertiary", Palette.backgrounds[2])
	}

	ColorSetGroup("Misc") {

		ColorSetGroup("Mapping") {

			ColorSet("traveledPolyline", Palette.mappingTripTraveledPolyline)
			ColorSet("tripStart", Palette.mappingTripStart)
			ColorSet("tripStop", Palette.mappingTripStop)
		}
	}
}

let colorSetsBackup = makeColorSets {

	ColorSetGroup("Text") {
		ColorSet("primary", Palette.text[0])
		ColorSet("secondary", Palette.text[1])
		ColorSet("tertiary", Palette.text[2])
		ColorSet("quadrary", Palette.text[2])
	}

	ColorSetGroup("Views") {

		ColorSetGroup("Buttons") {
			ColorSet("primary", Palette.backgrounds[0])
		}

		ColorSet("primary", Palette.backgrounds[0])
		ColorSet("secondary", Palette.backgrounds[1])
		ColorSet("tertiary", Palette.backgrounds[2])
	}

	ColorSetGroup("Misc") {

		ColorSetGroup("Mapping") {

			ColorSet("traveledPolyline", Palette.mappingTripTraveledPolyline)
			ColorSet("tripStart", Palette.mappingTripStart)
			ColorSet("tripStop", Palette.mappingTripStop)
		}
	}
}
