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
				Rectangle().fill( SLIDER_FG ).frame( width: width, height: height * ( value - lower ) / span )
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
	@Binding	var	accent_phrase	: VVAccentPhrase

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

struct
CIMorasEditorView: View {
	@Binding	var	moras	: [ CIMora ]

	var
	body: some View {
		ForEach( moras.indices, id: \.self ) { index in
			VStack {
				Spacer()
				
				SystemImageButton( moras[ index ].accent > 0 ? "circle.fill" : "circle" ) {
					moras[ index ].accent = moras[ index ].accent > 0 ? 0 : 1
				}
				
				Text( moras[ index ].hira )
			}
		}
	}
}

struct
EditorView: View {
	@Environment(\.dismiss) var	dismiss
	@EnvironmentObject		var	voices		: Voices

	@State	private			var	error		= ZMMError() as Error
	@State	private			var	alert		= false

	@Binding				var	line		: ScriptLine

	@State	private			var	editingText	= ""
	
	var
	body: some View {
		VStack {
			TextEditor( text: $editingText ).onAppear {
				editingText = line.dialog
			}
			Divider()
			Button( "Commit" ) {
				line.dialog = editingText
				Task {
					do {
						( line.parametersVV, line.parametersCI ) = try await line.Parameters( voices )
					} catch {
						await MainActor.run { ( self.error, alert ) = ( error, true ) }
					}
				}
			}
			ScrollView( .horizontal ) {
				HStack {
					Divider()
					if line.isVV( voices ) {
						ForEach( line.parametersVV.accent_phrases.indices, id: \.self ) { index in
							AccentPhraseEditorView( accent_phrase: $line.parametersVV.accent_phrases[ index ] ).frame( width: 64 )
							if let pause_mora = line.parametersVV.accent_phrases[ index ].pause_mora {
								VStack{
									Text( String( format: "%.2f", pause_mora.vowel_length ) ).monospacedDigit()
									ZMMHorizontalSlider( value: $line.parametersVV.accent_phrases[ index ].pause_length, range: 0.0...3.0 ).frame( width: 64, height: 12 ).onAppear {
										line.parametersVV.accent_phrases[ index ].pause_length = pause_mora.vowel_length
									}
									Spacer()
									SystemImageButton( "circle.slash" ) {}.opacity( 0.5 )
									Text( pause_mora.text )
								}.frame( width: 64 )
							}
							Divider()
						}
					}
					if line.isCI( voices ) {
						ForEach( line.parametersCI.prosodyDetail.indices, id: \.self ) { index in
							CIMorasEditorView( moras: $line.parametersCI.prosodyDetail[ index ] ).frame( width: 64 )
							Divider()
						}
					}
				}.padding()
			}
			HStack {
				AudioControllerView {
					do {
						return try await line.WAV( voices )
					} catch {
						//	TODO: MainActorにする必要あるか調査
						( self.error, alert ) = ( error, true )
						return Data()
					}
				}
				Spacer()
				Button( "閉じる" ) { dismiss() }
			}
		}.alert( isPresented: $alert ) {
			ZMMAlert( "再生に失敗しました", error )
		}
	}
}
