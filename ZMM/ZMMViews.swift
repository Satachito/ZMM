import SwiftUI
import AVFoundation

struct
VoiceOptions {
	var	speedScale			= false
	var	pitchScale			= false
	var	intonationScale		= false
	var	volumeScale			= false
	var	prePhonemeLength	= false
	var	postPhonemeLength	= false
	
	var	hasTrue				: Bool {
		get { speedScale || pitchScale || intonationScale || volumeScale || prePhonemeLength || postPhonemeLength }
	}
}

struct
LineView: View {
	@EnvironmentObject	var	voices			: Voices

	@State	private		var	error			= ZMMError() as Error
	@State	private		var	alert			= false

	@State	private		var	showingEditor	= false

	@Binding			var	line			: ScriptLine
						let	voiceOptions	: VoiceOptions

	var
	body: some View {
		VStack {
			HStack {
				VoicePicker(
					speaker	: $line.speaker
				,	style	: $line.style
				).onChange( of: line.speaker ) {
					Task {
						do {
							( line.parametersVV, line.parametersCI ) = try await line.Parameters( voices )
						} catch {
							await MainActor.run { ( self.error, alert ) = ( error, true ) }
						}
					}
				}
				Divider()
				Button( line.dialog ) { showingEditor = true }.buttonStyle( PlainButtonStyle() )
			//	Text( line.dialog )
				Spacer()
				Divider()
				AudioControllerView {
					do {
						return try await line.WAV( voices )
					} catch {
						( self.error, alert ) = ( error, true )
						return Data()
					}
				}.buttonStyle( PlainButtonStyle() ).frame( width: 64 )
			}
			if voiceOptions.hasTrue {
				HStack {
					Divider()
					if voiceOptions.speedScale			{ DoubleParamView( value: $line.speedScale			, title: "話速"		, low: +0.50, high: 2.00 ) }
					if voiceOptions.pitchScale			{ DoubleParamView( value: $line.pitchScale			, title: "音高"		, low: -0.15, high: 0.15 ) }
					if voiceOptions.intonationScale		{ DoubleParamView( value: $line.intonationScale		, title: "抑揚"		, low: +0.00, high: 2.00 ) }
					if voiceOptions.volumeScale			{ DoubleParamView( value: $line.volumeScale			, title: "音量"		, low: +0.00, high: 2.00 ) }
					if voiceOptions.prePhonemeLength	{ DoubleParamView( value: $line.prePhonemeLength	, title: "開始無音"	, low: +0.00, high: 1.50 ) }
					if voiceOptions.postPhonemeLength	{ DoubleParamView( value: $line.postPhonemeLength	, title: "修了無音"	, low: +0.00, high: 1.50 ) }
				}
			}
		}.sheet( isPresented: $showingEditor ) {
#if os( iOS )
			EditorView( line: $line ).frame( maxWidth: .infinity ).padding()
#endif
#if os( macOS )
			if let window = NSApplication.shared.windows.first {
				EditorView( line: $line ).frame( width: window.frame.size.width ).padding()
			}
#endif
		}.alert( isPresented: $alert ) {
			ZMMAlert( "再生に失敗しました", error )
		}
	}
}

struct
ScriptView: View {
	@EnvironmentObject	var	voices			: Voices

	@State	private		var	error			= ZMMError() as Error
	@State	private		var	alert			= false

	@Binding			var	script			: [ ScriptLine ]
	
	@State	private		var	voiceOptions	= VoiceOptions()

	@State	private		var	progress		: Float?

	@State	private		var	showOpen		= false

	@State	private		var	delimiter		= "："

	func
	WAV() async throws -> Data? {
		func
		SetProgress( _ progress: Float? ) async {
			await MainActor.run { self.progress = progress }
		}
		var
		wavs	: [ Data ] = []
		for i in 0 ..< script.count {
			await SetProgress( Float( i ) / Float( script.count ) )
			wavs.append( try await script[ i ].WAV( voices ) )
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
	AddLine( _ speaker: String = "ずんだもん", _ style: String = "ノーマル", _ dialog: String = "" ) async throws {
		var
		line = try await ScriptLine( speaker, style, dialog, voices )
		( line.parametersVV, line.parametersCI ) = try await line.Parameters( voices )
		script.append( line )
	}

	var
	body: some View {
		VStack {
			HStack {
				Button( ".wav 作成" ) {
#if os( macOS )
					let savePanel = NSSavePanel()
					savePanel.nameFieldStringValue = "Untitled.wav"
					savePanel.canCreateDirectories = true
					savePanel.allowedContentTypes = [ .wav ]
					savePanel.begin { response in
						if response == .OK, let url = savePanel.url {
							Task {
								do {
									guard let wav = try await WAV() else { return }
									try wav.write( to: url )
								} catch {
									await MainActor.run { ( self.error, alert ) = ( error, true ) }
								}
							}
						}
					}
#endif
				}.disabled( progress != nil ).alert( isPresented: $alert ) {
					ZMMAlert( ".wavの作成に失敗しました。", error )
				}
				if let progress = self.progress { ProgressView( "", value: progress ).frame( width: 160, height: 0 ) }
				Spacer()
				Divider()
				Toggle( isOn: $voiceOptions.speedScale			) { Text( "話速"		) }
				Divider()
				Toggle( isOn: $voiceOptions.pitchScale			) { Text( "音高"		) }
				Divider()
				Toggle( isOn: $voiceOptions.intonationScale		) { Text( "抑揚"		) }
				Divider()
				Toggle( isOn: $voiceOptions.volumeScale			) { Text( "音量"		) }
				Divider()
				Toggle( isOn: $voiceOptions.prePhonemeLength	) { Text( "開始無音"	) }
				Divider()
				Toggle( isOn: $voiceOptions.postPhonemeLength	) { Text( "修了無音"	) }
				Divider()
			}.frame( height: 20 )
			Divider()
			List {
				ForEach( script.indices, id: \.self ) { index in
					LineView( line: $script[ index ], voiceOptions: voiceOptions ).contextMenu {
						Button( "削除" ) { script.remove( at: index ) }
					}
				}.onMove {
					script.move( fromOffsets: $0, toOffset: $1 )
				}.onDelete {
					script.remove( atOffsets: $0 )
				}
			}
			Divider()
			HStack {
				SystemImageButton( "plus" ) {
					Task {
						do {
							script.count > 0
							?	try await AddLine( script.last!.speaker, script.last!.style )
							:	try await AddLine()
						} catch {
							await MainActor.run { ( self.error, alert ) = ( error, true ) }
						}
					}
				}.alert( isPresented: $alert ) {
					ZMMAlert( "スクリプトの追加に失敗しました。", error )
				}
				Divider()
				Text( "区切り文字" )
				TextField( "", text: $delimiter ).frame( width: 20 )
				Button( "テキスト読込" ) {
#if os( iOS )
					showOpen = true
#endif
#if os( macOS )
					let panel = NSOpenPanel()
					panel.allowsMultipleSelection = false
					panel.canChooseDirectories = false

					if panel.runModal() == .OK, let url = panel.url {
						OpenTask( url )
					}
#endif
				}.alert( isPresented: $alert ) {
					ZMMAlert( ".txtの読み込みに失敗しました。", error )
				}
#if os( iOS )
				.sheet( isPresented: $showOpen ) {
					DocumentPicker( exportMode: false, types: [ .content ] ) { urls in
						if let url = urls.first {
							OpenTask( url )
  						}
					}
				}
#endif
			}.frame( height: 20 )
		}
	}
	func
	OpenTask( _ url: URL ) {
		Task {
			do {
				for line in try String( contentsOfFile: url.path, encoding: .utf8 ).components( separatedBy: "\n" ) {
					let
					components = line.components( separatedBy: delimiter )
					//	TODO: GET DEFAULT STYLE
					if components.count == 2 { try await AddLine( components[ 0 ], "ノーマル", components[ 1 ] ) }
				}
			} catch {
				await MainActor.run { ( self.error, alert ) = ( error, true ) }
			}
		}
	}
}

struct
ContentView: View {
	@EnvironmentObject	var	voices		: Voices
	@Binding			var	document	: ZMMDocument

	var
	body: some View {
		ScriptView( script: $document.script )
	}
}

#Preview {
	ContentView( document: .constant( ZMMDocument() ) )
}

