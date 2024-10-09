import SwiftUI

let
SLIDER_BG = Color.black.opacity( 0.1 )
let
SLIDER_FG = Color.blue.opacity ( 0.9 )

struct
ZMMHorizontalSlider: View {
	@Binding	var	value	: Double
				let	range	: ClosedRange< Double >

	var
	body: some View {
		GeometryReader { geometry in
			let	width	= geometry.size.width
			let	height	= geometry.size.height
			let	upper	= range.upperBound
			let	lower	= range.lowerBound
			let	span	= upper - lower
			ZStack( alignment: .leading ) {
				Rectangle().fill( SLIDER_BG ).frame( width: width							, height: height )
				Rectangle().fill( SLIDER_FG ).frame( width: width * ( value - lower ) / span, height: height )
			}.frame( width: width ).gesture(
				DragGesture().onChanged {
					let
					value = span * $0.location.x / width + lower
					guard value >= lower else { return }
					guard value <= upper else { return }
					self.value = value
				}
			)
		}
	}
}
struct
ZMMVerticalSlider: View {
	@Binding	var	value	: Double
				let	range	: ClosedRange< Double >

	var
	body: some View {
		GeometryReader { geometry in
			let	width	= geometry.size.width
			let	height	= geometry.size.height
			let	upper	= range.upperBound
			let	lower	= range.lowerBound
			let	span	= upper - lower
			ZStack( alignment: .bottomLeading ) {
				Rectangle().fill( SLIDER_BG ).frame( width: width, height: height )
				Rectangle().fill( SLIDER_FG ).frame( width: width, height: abs( height * ( value - lower ) / span ) )	//	TODO: Static analyzer のメッセージを止めることができたら、abs をはずす
			}.frame( height: height ).gesture(
				DragGesture().onChanged {
					let
					value = span * ( height - $0.location.y ) / height + lower
					guard value >= lower else { return }
					guard value <= upper else { return }
					self.value = value
				}
			)
		}
	}
}

struct
AccentPhraseEditorView: View {
	@Binding	var	accent_phrase	: AccentPhrase

	var
	body: some View {
		ForEach( accent_phrase.moras.indices, id: \.self ) { index in
			VStack {
				let	mora	= accent_phrase.moras[ index ]
				let	b_mora	= $accent_phrase.moras[ index ]

				Text( String( format: "%.2f", mora.vowel_length ) ).monospacedDigit()
				ZMMHorizontalSlider( value: b_mora.vowel_length, range: 0.0...3.0 ).frame( width: 64, height: 12 )
				
				Text( String( format: "%.2f", mora.pitch ) ).monospacedDigit()
				ZMMVerticalSlider( value: b_mora.pitch, range: 3.0...6.5 ).frame( width: 12, height: 64 )
				
				Spacer()
				
				SystemImageButton( index + 1 == accent_phrase.accent ? "circle.fill" : "circle" ) {
					accent_phrase.accent = index + 1
				}
				
				Text( accent_phrase.moras[ index ].text )
			}
		}
	}
    private var
    numberFormatter: NumberFormatter {
        let v = NumberFormatter()
        v.numberStyle = .decimal
        v.minimumFractionDigits = 2
        v.maximumFractionDigits = 2
        return v
    }
}

import AVFAudio

class
Audio: NSObject, AVAudioPlayerDelegate, ObservableObject {

	@Published	var	player		: AVAudioPlayer?
	@Published	var isPlaying	= false

	func
	Load( data: Data ) throws {
		player = try AVAudioPlayer( data: data )
		player!.delegate = self
	}
	func
	Play() {
		player?.prepareToPlay()
		player?.play()
		isPlaying = true
	}
	func
	Pause() {
		player?.pause()
		isPlaying = false
	}
	func
	Stop() {
		player = nil
		isPlaying = false
	}
	func
	audioPlayerDidFinishPlaying( _ _: AVAudioPlayer, successfully _: Bool ) {
		DispatchQueue.main.async { self.Stop() }
	}
}

struct
AudioControllerView: View {

							var	fetch	: () async throws -> Data
	@StateObject	private	var	audio	= Audio()
//	@State			private	var	audio	= Audio()
	
	init( _ fetch: @escaping () async throws -> Data ) {
		self.fetch = fetch
        _audio = StateObject( wrappedValue: Audio() )
	}
	var
	body: some View {
		HStack {
			if audio.player != nil {
				if audio.isPlaying {
					SystemImageButton( "pause" ) { audio.Pause() }
				} else {
					SystemImageButton( "play" ) { audio.Play() }
				}
			} else {
				SystemImageButton( "play" ) {
					Task {
						 try audio.Load( data: try await fetch() )
						 audio.Play()
					}
				}
			}
			SystemImageButton( "stop" ) { audio.Stop() }
		}
	}
}


struct
EditorView: View {
	@Environment(\.dismiss) var	dismiss
	@EnvironmentObject		var	environ			: Environ
	@Binding				var	line			: ScriptLine
	
	@State					var	editingDialog	= ""
	
	var
	body: some View {
		VStack {
			TextEditor( text: $editingDialog ).onAppear {
				editingDialog = line.dialog
			}
			Divider()
			Button( "Commit" ) {
				line.dialog = editingDialog
				Task {
					let
					parameters = try await line.FetchParameters( environ )
					await MainActor.run { line.parameters = parameters }
				}
			}
			ScrollView( .horizontal ) {
				HStack {
					Divider()
					ForEach( line.parameters.accent_phrases.indices, id: \.self ) { index in
						AccentPhraseEditorView( accent_phrase: $line.parameters.accent_phrases[ index ] ).frame( width: 64 )
						if let pause_mora = line.parameters.accent_phrases[ index ].pause_mora {
							VStack{
								Text( String( format: "%.2f", pause_mora.vowel_length ) ).monospacedDigit()
								ZMMHorizontalSlider( value: $line.parameters.accent_phrases[ index ].pause_length, range: 0.0...3.0 ).frame( width: 64, height: 12 ).onAppear {
									line.parameters.accent_phrases[ index ].pause_length = pause_mora.vowel_length
								}
								Spacer()
								SystemImageButton( "circle.slash" ) {}.opacity( 0.5 )
								Text( pause_mora.text )
							}.frame( width: 64 )
						}
						Divider()
					}
				}.padding()
			}
			HStack {
				AudioControllerView { try await line.WAV( environ ) }
				Spacer()
				Button( "閉じる" ) { dismiss() }
			}
		}
	}
}
