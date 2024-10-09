import SwiftUI

struct
VoicePicker: View {
	@EnvironmentObject	var	environ	: Environ
	@Binding			var	speaker	: String
	@Binding			var	style	: String

	func
	Styles( _ speaker: String ) -> [ String ] {
		guard let speaker = environ.speakers.filter( { $0.name == speaker } ).first else { return [] }
		return speaker.styles.map( { $0.name } )
	}

	var
	body: some View {
		Menu( speaker + " " + style ) {
			ForEach( environ.speakers.map( { $0.name } ), id: \.self ) { speaker in
				let styles = Styles( speaker )
				if styles.count > 1 {
					Menu( speaker ) {
						ForEach( styles, id: \.self ) { style in
							Button( style ) {
								self.speaker	= speaker
								self.style		= style
							}
						}
					}
				} else {
					Button( speaker ) {
						self.speaker = speaker
						self.style = styles[ 0 ]
					}
				}
			}
		}.frame( width: 200 )
	}
}

struct
DoubleParamView: View {
	
	@Binding	var	value	: Double

				let	title	: String
				let	low		: Double
				let	high	: Double

	var
	body: some View {
		HStack {
			Text( title )
			Text( String( format: "%.2f", value ) ).monospacedDigit()
			Slider( value: $value , in: low...high )
			Divider()
		}
	}
}


