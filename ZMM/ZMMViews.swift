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
	
	var hasTrue				: Bool {
		get { speedScale || pitchScale || intonationScale || volumeScale || prePhonemeLength || postPhonemeLength }
	}
}

struct
LineView: View {
	
	@EnvironmentObject	var	environ			: Environ

	@State	private		var	showingEditor	= false
	@State	private		var	playAlert		= false
	@State	private		var	playErrorString	= ""

	@State	private		var	audioPlayer		: AVAudioPlayer?

	@Binding			var	script			: [ ScriptLine ]
						let	index			: Int
						let	showOptions		: ShowOptions

	var
	body: some View {
		VStack {
			HStack {
				VoicePicker( speaker: $script[ index ].name, style: $script[ index ].style )
				Text( script[ index ].dialog )
				Spacer()
			}
			if showOptions.hasTrue {
				HStack {
					Divider()
					if showOptions.speedScale			{ DoubleParamView( value: $script[ index ].parameters.speedScale		, title: "話速"		, low: +0.50, high: 2.00 ) }
					if showOptions.pitchScale			{ DoubleParamView( value: $script[ index ].parameters.pitchScale		, title: "音高"		, low: -0.15, high: 0.15 ) }
					if showOptions.intonationScale		{ DoubleParamView( value: $script[ index ].parameters.intonationScale	, title: "抑揚"		, low: +0.00, high: 2.00 ) }
					if showOptions.volumeScale			{ DoubleParamView( value: $script[ index ].parameters.volumeScale		, title: "音量"		, low: +0.00, high: 2.00 ) }
					if showOptions.prePhonemeLength		{ DoubleParamView( value: $script[ index ].parameters.prePhonemeLength	, title: "開始無音"	, low: +0.00, high: 1.50 ) }
					if showOptions.postPhonemeLength	{ DoubleParamView( value: $script[ index ].parameters.postPhonemeLength	, title: "修了無音"	, low: +0.00, high: 1.50 ) }
				}
			}
		}.contextMenu {
			Button( "再生" ) {
				Task {
					do {
						audioPlayer = try AVAudioPlayer( data: try await script[ index ].WAV( environ ) )
						audioPlayer?.play()
					} catch {
						await MainActor.run {
							playErrorString = error.localizedDescription
							playAlert = true
						}
					}
				}
			}.alert( isPresented: $playAlert ) {
				Alert( title: Text( "再生に失敗しました" ), message: Text( playErrorString ) )
			}
			Button( "削除" ) { script.remove( at: index ) }
			Button( "編集" ) { showingEditor = true }
		}.sheet( isPresented: $showingEditor ) {
#if os( iOS )
			EditorView( line: $script[ index ] ).frame( maxWidth: .infinity ).padding()
#endif
#if os( macOS )
			if let window = NSApplication.shared.windows.first {
				EditorView( line: $script[ index ] ).frame( width: window.frame.size.width ).padding()
			}
#endif
		}
	}
}

struct
ScriptView: View {
	@EnvironmentObject	var	environ			: Environ

	@Binding			var	script			: [ ScriptLine ]
	
	@State	private		var	showOptions		= ShowOptions()

	@State	private		var	progress		: Float?

	@State	private		var	wavAlert		= false
	@State	private		var	wavErrorString	= ""
	@State	private		var	txtAlert		= false
	@State	private		var	txtErrorString	= ""
	@State	private		var	addAlert		= false
	@State	private		var	addErrorString	= ""

	@State	private		var	showOpen		= false

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
	AddLine( _ name: String = "ずんだもん", _ style: String = "ノーマル", _ dialog: String = "" ) async throws {
		var
		line = ScriptLine( name: name, style: style, dialog: dialog )
		line.parameters = try await line.FetchParameters( environ )
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
									await MainActor.run {
										wavErrorString = error.localizedDescription
										wavAlert = true
									}
								}
							}
						}
					}
#endif
				}.disabled( progress != nil ).alert( isPresented: $wavAlert ) {
					Alert( title: Text( ".wavの作成に失敗しました。" ), message: Text( "wavErrorString" ) )
				}
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
			List {
				ForEach( script.indices, id: \.self ) { index in
					LineView( script: $script, index: index, showOptions: showOptions )
				}.onMove {
					script.move( fromOffsets: $0, toOffset: $1 )
//				}.onDelete {	//	UX が悪いので、contextMenu でやる
//					script.remove( atOffsets: $0 )
				}
			}
			Divider()
			HStack {
				SystemImageButton( "plus" ) {
					Task {
						do {
							script.count > 0
							?	try await AddLine( script.last!.name, script.last!.style )
							:	try await AddLine()
						} catch {
							await MainActor.run {
								addErrorString = error.localizedDescription
								addAlert = true
							}
						}
					}
				}
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
				}.alert( isPresented: $txtAlert ) {
					Alert( title: Text( ".txtの読み込みに失敗しました。" ), message: Text( "" ) )
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
			}
		}
	}
	func
	OpenTask( _ url: URL ) {
		Task {
			do {
				for line in try String( contentsOfFile: url.path, encoding: .utf8 ).components( separatedBy: "\n" ) {
					let
					components = line.components( separatedBy: "：" )
					if components.count == 2 { try await AddLine( components[ 0 ], "ノーマル", components[ 1 ] ) }
				}
			} catch {
				await MainActor.run {
					txtErrorString = error.localizedDescription
					txtAlert = true
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
			ScriptView( script: $document.script )
		} else {
			Text( "loading" )
		}
	}
}

#Preview {
	ContentView( document: .constant( ZMMDocument() ) )
}

