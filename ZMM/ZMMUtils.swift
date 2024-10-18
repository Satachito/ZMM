import SwiftUI

struct
ZMMError: LocalizedError {
	let	errorDescription	: String?
	init( _ errorDescription: String = "eh?" ) {
		self.errorDescription = errorDescription
	}
}

func
ZMMAlert( _ title: String, _ error: Error ) -> Alert {
	Alert( title: Text( title ), message: Text( error.localizedDescription ) )
}

struct
VoicePicker: View {
	@EnvironmentObject	var	voices		: Voices
	@Binding			var	speaker		: String
	@Binding			var	style		: String

	func
	VVStyles( _ speaker: String ) -> [ String ] {
		guard let speakersVV = voices.speakersVV, let speaker = speakersVV.filter( { $0.name == speaker } ).first else { return [] }
		return speaker.styles.map( { $0.name } )
	}

	func
	CIStyles( _ speaker: String ) -> [ String ] {
		guard let speakersCI = voices.speakersCI, let speaker = speakersCI.filter( { $0.name == speaker } ).first else { return [] }
		return speaker.styles.map( { $0.name } )
	}

	func
	Update( _ speaker: String, _ style: String ) {
		self.speaker	= speaker
		self.style		= style
	}
	
	var
	body: some View {
		Menu( "\(speaker) \(style)" ) {
			if let speakersVV = voices.speakersVV {
				Menu( "VOICEVOX" ) {
					ForEach( speakersVV.map( { $0.name } ), id: \.self ) { speaker in
						let styles = VVStyles( speaker )
						if styles.count > 1 {
							Menu( speaker ) {
								ForEach( styles, id: \.self ) { style in
									Button( style ) { Update( speaker, style ) }
								}
							}
						} else {
							Button( speaker ) { Update( speaker, styles[ 0 ] ) }
						}
					}
				}
			}
			if let speakersCI = voices.speakersCI {
				Menu( "COEIROINK" ) {
					ForEach( speakersCI.map( { $0.name } ), id: \.self ) { speaker in
						let styles = CIStyles( speaker )
						if styles.count > 1 {
							Menu( speaker ) {
								ForEach( styles, id: \.self ) { style in
									Button( style ) { Update( speaker, style ) }
								}
							}
						} else {
							Button( speaker ) { Update( speaker, styles[ 0 ] ) }
						}
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
			Slider( value: $value , in: low...high ).frame( maxWidth: 160 )
			Divider()
		}
	}
}
