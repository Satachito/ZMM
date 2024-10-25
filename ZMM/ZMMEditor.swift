import SwiftUI

struct
VVAccentPhraseEditorView: View {
	@Binding	var	accent_phrase	: VVAccentPhrase

	var
	body: some View {
		ForEach( accent_phrase.moras.indices, id: \.self ) { index in
			VStack {
				let	mora	= accent_phrase.moras[ index ]
				let	b_mora	= $accent_phrase.moras[ index ]

				Text( String( format: "%.2f", mora.vowel_length ) ).monospacedDigit()
				ZMMHorizontalSlider( value: b_mora.vowel_length, range: 0.0...3.0 ).frame( width: 64, height: 12 )
				
				if mora.pitch > 0 {
					Text( String( format: "%.2f", mora.pitch ) ).monospacedDigit()
					ZMMVerticalSlider( value: b_mora.pitch, range: 3.0...6.5 ).frame( width: 12, height: 64 )
				} else {
					Button( "無声音" ) {
						accent_phrase.moras[ index ].pitch = 5.5
					}.buttonStyle( BorderlessButtonStyle() )
					Rectangle().fill( SLIDER_BG ).frame( width: 12, height: 64 )
				}
				Spacer()
				
				SystemImageButton( index + 1 == accent_phrase.accent ? "circle.fill" : "circle" ) {
					accent_phrase.accent = index + 1
				}
				
				Text( mora.text )
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
	@State	private			var	errorVV		= ZMMError() as Error
	@State	private			var	alertVV		= false
	@State	private			var	errorCI		= ZMMError() as Error
	@State	private			var	alertCI		= false

	@Binding				var	line		: ScriptLine

	@State	private			var	editingText	= ""
	
	@State	private			var	editingVV	= VVParameters()
	@State	private			var	editingCI	= CIParameters()

	var
	body: some View {
		VStack {
			TextEditor( text: $editingText ).onAppear {
				editingText = line.dialog
			}
			Divider()
			Button( "保存とパラメータ編集(以前のパラメータの編集内容は破棄されます)" ) {
				line.dialog = editingText
				if line.isVV( voices ) {
					Task {
						do {
							let
							parameters = try await line.ParametersVV( voices )
							await MainActor.run{ editingVV = parameters }
						} catch {
							await MainActor.run{ ( errorVV, alertVV ) = ( error, true ) }
						}
					}
				}
				if line.isCI( voices ) {
					Task {
						do {
							let
							parameters = try await line.ParametersCI( voices )
							await MainActor.run{ editingCI = parameters }
						} catch {
							await MainActor.run{ ( errorCI, alertCI ) = ( error, true ) }
						}
					}
				}
			}
			ScrollView( .horizontal ) {
				HStack {
					Divider()
					ForEach( editingVV.accent_phrases.indices, id: \.self ) { index in
						VVAccentPhraseEditorView( accent_phrase: $editingVV.accent_phrases[ index ] ).frame( width: 64 )
						if let pause_mora = editingVV.accent_phrases[ index ].pause_mora {
							VStack{
								Text( String( format: "%.2f", pause_mora.vowel_length ) ).monospacedDigit()
								ZMMHorizontalSlider( value: $editingVV.accent_phrases[ index ].pause_length, range: 0.0...3.0 ).frame( width: 64, height: 12 ).onAppear {
									editingVV.accent_phrases[ index ].pause_length = pause_mora.vowel_length
								}
								Spacer()
								SystemImageButton( "circle.slash" ) {}.opacity( 0.5 )
								Text( pause_mora.text )
							}.frame( width: 64 )
						}
						Divider()
					}
					ForEach( editingCI.prosodyDetail.indices, id: \.self ) { index in
						CIMorasEditorView( moras: $editingCI.prosodyDetail[ index ] ).frame( width: 64 )
						Divider()
					}
				}.padding()
			}.onAppear() {
				if let parameters = line.parametersVV { editingVV = parameters }
				if let parameters = line.parametersCI { editingCI = parameters }
			}
			Button( "Commit" ) {
				if line.isVV( voices ) { line.parametersVV = editingVV }
				if line.isCI( voices ) { line.parametersCI = editingCI }
			}
			
			HStack {
				AudioControllerView {
					do {
						return try await line.WAV( voices )
					} catch {
						( self.error, alert ) = ( error, true )
						return Data()
					}
				}
				Spacer()
				Button( "閉じる" ) { dismiss() }
			}
		}.alert( isPresented: $alert ) {
			ZMMAlert( "再生に失敗しました", error )
		}.alert( isPresented: $alertVV ) {
			ZMMAlert( "VOICEVOX パラメータの取得に失敗しました", errorVV )
		}.alert( isPresented: $alertCI ) {
			ZMMAlert( "COIEROINK パラメータの取得に失敗しました", errorCI )
		}
	}
}
