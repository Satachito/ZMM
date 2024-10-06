import SwiftUI
import AVFoundation

struct
ShowOptions {
	var speedScale			= false
	var pitchScale			= false
	var intonationScale		= false
	var volumeScale			= false
	var prePhonemeLength	= false
	var postPhonemeLength	= false
	
	var hasTrue: Bool {
		get { speedScale || pitchScale || intonationScale || volumeScale || prePhonemeLength || postPhonemeLength }
	}
}

struct
LineV: View {
	@Binding				var
	script					: [ ScriptLine ]
							var
	index					: Int
							var
	showOptions				: ShowOptions
	
	@EnvironmentObject		var
	environ					: Environ

	@State					var
	showSheet				= false

	@State private			var
	audioPlayer				: AVAudioPlayer?
	
	var
	body: some View {
		VStack {
			HStack {
				VoicePickerV( name: $script[ index ].name, style: $script[ index ].style )
				JPTextField( text: $script[ index ].dialog )
//				TextField( "", text: $script[ index ].dialog )
			}
			if showOptions.hasTrue {
				HStack {
					Divider()
					if showOptions.speedScale			{ DoubleParamV( value: $script[ index ].parameters.speedScale			, title: "話速"		, low: +0.50, high: 2.00 ) }
					if showOptions.pitchScale			{ DoubleParamV( value: $script[ index ].parameters.pitchScale			, title: "音高"		, low: -0.15, high: 0.15 ) }
					if showOptions.intonationScale		{ DoubleParamV( value: $script[ index ].parameters.intonationScale		, title: "抑揚"		, low: +0.00, high: 2.00 ) }
					if showOptions.volumeScale			{ DoubleParamV( value: $script[ index ].parameters.volumeScale			, title: "音量"		, low: +0.00, high: 2.00 ) }
					if showOptions.prePhonemeLength		{ DoubleParamV( value: $script[ index ].parameters.prePhonemeLength		, title: "開始無音"	, low: +0.00, high: 1.50 ) }
					if showOptions.postPhonemeLength	{ DoubleParamV( value: $script[ index ].parameters.postPhonemeLength	, title: "修了無音"	, low: +0.00, high: 1.50 ) }
				}
			}
		}.contextMenu {
			Button( "削除" ) { script.remove( at: index ) }
			Button( "再生" ) {
				Task {
					do {
						audioPlayer = try AVAudioPlayer( data: try await script[ index ].WAV( environ ) )
						audioPlayer!.play()
					} catch {
						print( error )
					}
				}
			}
			Button( "アクセント編集" ) {
				if !script[ index ].fetched {
					Task {
						do {
							script[ index ].parameters = try await script[ index ].Fetch( environ )
							script[ index ].fetched = true
							await MainActor.run { showSheet = true }
						} catch {
							print( error )
						}
					}
				} else {
					showSheet = true
				}
			}
		}.sheet( isPresented: $showSheet ) {
			OldAccentEditorV( line: $script[ index ] )
		}
	}
}

struct
ScriptV: View {
	@EnvironmentObject		var
	environ					: Environ

	@Binding				var
	script					: [ ScriptLine ]
	
	@State					var
	showOptions				= ShowOptions()

	@State private			var
	selectionValues			: [ Int ] = []

	@State private			var
	progress				: Float?

	func
	SetProgress( _ progress: Float? ) async {
		await MainActor.run {
			self.progress = progress
		}
	}

	func
	WAV() async throws -> Data? {
	
		var
		wavs	: [ Data ] = []
		for i in 0 ..< script.count {
			await SetProgress( Float( i ) / Float( script.count ) )
			let
			line = script[ i ]
			wavs.append( try await line.WAV( environ ) )
		}
		await SetProgress( 1 )

		var	//	44: WAV HEADER SIZE
		wav = wavs[ 0 ][ 0 ..< 44 ]

		var
		sizePCM = UInt32( wavs.reduce( 0, { $0 + $1.count - 44 } ) )
		wav.replaceSubrange( 40 ..< 44, with: Data( bytes: &sizePCM, count: 4 ) )

		wavs.forEach( { wav.append( $0[ 44... ] ) } )
		
		var
		sizeRIFF = UInt32( wav.count ) - 8
		wav.replaceSubrange( 4 ..< 8, with: Data( bytes: &sizeRIFF, count: 4 ) )

		await SetProgress( nil )

		return wav
	}

	func
	Write() async throws {
		guard let wav = try await WAV() else { return }
		await MainActor.run {
			let savePanel = NSSavePanel()
			savePanel.nameFieldStringValue = "Untitled.wav"
			savePanel.canCreateDirectories = true
			savePanel.allowedContentTypes = [ .wav ]
 
			savePanel.begin { response in
				if response == .OK, let url = savePanel.url {
					do {
						try wav.write( to: url )
						print( "Saved: \(url)" )
					} catch {
						print( error )
					}
				}
			}
		}
	}

	func
	AddLine( _ name: String = "ずんだもん", _ style: String = "ノーマル", _ dialog: String = "" ) async throws {
		var
		line = ScriptLine( name, style, dialog )
		line.parameters = try await line.Fetch( environ )
		line.fetched = true
		await MainActor.run { script.append( line ) }
	}

	var
	body: some View {
		VStack {
			HStack {
				Button( ".wav 作成" ) {
					Task {
						do {
							guard let wav = try await WAV() else { return }
							await MainActor.run {
								let savePanel = NSSavePanel()
								savePanel.nameFieldStringValue = "Untitled.wav"
								savePanel.canCreateDirectories = true
								savePanel.allowedContentTypes = [ .wav ]
								savePanel.begin { response in
									if response == .OK, let url = savePanel.url {
										do {
											try wav.write( to: url )
											print( "Saved: \(url)" )
										} catch {
											print( error )
										}
									}
								}
							}
						} catch {
							print( error )
						}
					}
				}.disabled( progress != nil )
				if let progress = self.progress { ProgressView( "", value: progress ).frame( width: 160, height: 0 ) }
				Spacer()
				Toggle( isOn: $showOptions.speedScale			) { Text( "話速"		) }
				Toggle( isOn: $showOptions.pitchScale			) { Text( "音高"		) }
				Toggle( isOn: $showOptions.intonationScale		) { Text( "抑揚"		) }
				Toggle( isOn: $showOptions.volumeScale			) { Text( "音量"		) }
				Toggle( isOn: $showOptions.prePhonemeLength		) { Text( "開始無音"	) }
				Toggle( isOn: $showOptions.postPhonemeLength	) { Text( "修了無音"	) }
			}
			Divider()
			List( selection: $selectionValues ) {
				ForEach( script.indices, id: \.self ) { index in
					LineV( script: $script, index: index, showOptions: showOptions )
				}.onMove {
					script.move( fromOffsets: $0, toOffset: $1 )
//				}.onDelete {	//	UX が悪いので、contextMenu でやる
//					script.remove( atOffsets: $0 )
				}
			}
			Divider()
			HStack {
				SystemImageB( "plus" ) {
					Task {
						do {
							script.count > 0
							?	try await AddLine( script.last!.name, script.last!.style )
							:	try await AddLine()
						} catch {
							print( error )
						}
					}
				}
				Button( ".txt 読込" ) {
					let panel = NSOpenPanel()
					panel.allowsMultipleSelection = false
					panel.canChooseDirectories = false

					if panel.runModal() == .OK, let url = panel.url {
						Task {
							do {
								for line in try String( contentsOfFile: url.path, encoding: .utf8 ).components( separatedBy: "\n" ) {
									let
									components = line.components( separatedBy: "：" )
									if components.count == 2 { try await AddLine( components[ 0 ], "ノーマル", components[ 1 ] ) }
								}
							} catch {
								print( error )
							}
						}
					}
				}
			}
		}
	}
}

struct
ContentView: View {
	@EnvironmentObject var
	environ	: Environ

	@Binding var
	document: ZMMDocument

	var
	body: some View {
		if environ.speakers.count > 0 {
			ScriptV( script: $document.script ).padding()
		} else {
			Text( "loading" ).padding()
		}
	}
}

#Preview {
	ContentView( document: .constant( ZMMDocument() ) )
}
