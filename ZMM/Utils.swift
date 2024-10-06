import SwiftUI
import AVFAudio

func
AnalyzeWAV( _ wav: Data ) {

	let
	int16Header = Array(
		wav.withUnsafeBytes {
			UnsafeBufferPointer(
				start: $0.baseAddress!.assumingMemoryBound( to: Int16.self )
			,   count: 22
			)
		}
	)
	guard int16Header[ 10 ] == 1	else { fatalError() }	//	"audioFormat"
	guard int16Header[ 11 ] == 1	else { fatalError() }	//	"numChannels"
	guard int16Header[ 17 ] == 16	else { fatalError() }	//	"bitsPerSample"
//	print( int16Header[ 16 ], "blockAlign" )

	let
	int32Header = Array(
		wav.withUnsafeBytes {
			UnsafeBufferPointer(
				start: $0.baseAddress!.assumingMemoryBound( to: Int32.self )
			,   count: 11
			)
		}
	)
	guard int32Header[ 0 ] == 0x46464952	else { fatalError() }	//	"RIFF"
	guard int32Header[ 1 ] == wav.count - 8	else { fatalError() }	//	"RIFF SIZE, file size - 8"
	guard int32Header[ 2 ] == 0x45564157	else { fatalError() }	//	"WAVE"
	guard int32Header[ 3 ] == 0x20746d66	else { fatalError() }	//	"fmt "
	guard int32Header[ 6 ] == 24000			else { fatalError() }	//	sampleRate
	guard int32Header[ 9 ] == 0x61746164	else { fatalError() }	//	"data"

//	print( int32Header[  4 ], "subchunk1Size" )
//	print( int32Header[  7 ], "byteRate" )
	print( int32Header[ 10 ], "dataSize" )
}

struct
VoicePickerV: View {
	@EnvironmentObject	var
	environ	: Environ

	@Binding			var
	name	: String

	@Binding			var
	style	: String

	func
	Styles( _ name: String ) -> [ String ] {
		guard let speaker = environ.speakers.filter( { $0.name == name } ).first else { return [] }
		return speaker.styles.map( { $0.style } )
	}

	var
	body: some View {
		Menu( name + " " + style ) {
			ForEach( environ.speakers.map( { $0.name } ), id: \.self ) { name in
				let styles = Styles( name )
				if styles.count > 1 {
					Menu( name ) {
						ForEach( styles, id: \.self ) { style in
							Button( style ) {
								self.name = name
								self.style = style
							}
						}
					}
				} else {
					Button( name ) {
						self.name = name
						self.style = styles[ 0 ]
					}
				}
			}
		}.frame( width: 200 )
	}
}

struct
DoubleParamV: View {
	
	@Binding	var
	value	: Double

	let
	title	: String
	let
	low		: Double
	let
	high	: Double

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


//	GENERIC
/*
class
AudioPlayer: NSObject, ObservableObject {
    @Published var isPlaying = false
    var audioPlayer: AVAudioPlayer?

    func
    Play( wav: Data ) throws {
		audioPlayer = try AVAudioPlayer( data: wav )
		audioPlayer?.play()
		isPlaying = true
    }

    func
    Stop() {
        audioPlayer?.stop()
        isPlaying = false
    }
}

struct
WAVPlayerV: View {
    @State		var
	audioPlayer	: AVAudioPlayer?
	@Binding	var
	wav			: Data? {
		didSet {
			if let wav = wav {
				do {
					audioPlayer = try AVAudioPlayer( data: wav )
					audioPlayer?.delegate = delegate
				} catch {
					print( error )
				}
				
				
				

	class
	Delegate: NSObject, @preconcurrency AVAudioPlayerDelegate {
		var
		parent	: WAVPlayerV
		init( _ parent: WAVPlayerV ) {
			self.parent = parent
		}
		@MainActor func
		audioPlayerDidFinishPlaying( _ player: AVAudioPlayer, successfully flag: Bool ) {
			parent.audioPlayer = nil
		}
	}
	private		var
	delegate	: Delegate
	
	var
	body: some View {
		if let audioPlayer = audioPlayer {
		if let wav = self.wav {
			SystemImageB( "play" ) {
				do {
					audioPlayer = try AVAudioPlayer( data: wav )
					audioPlayer?.delegate = delegate
					audioPlayer?.play()
				} catch {
					print( error )
				}
			}
		}
		if
	}
}
*/

struct
SystemImageB: View {
	let
	action	: () -> ()
	let
	name	: String
	
	init(
		_	name	: String
	,		action	: @escaping () -> ()
	) {
		self.name	= name
		self.action	= action
	}
	var
	body: some View {
		Button( action: action ) { Image( systemName: name ) }
	}
}
/*
func
String( data: Data ) -> String {
	.init( data: data, encoding: .utf8 )!
}

func
Data( string: String ) -> Data {
	.init( string.utf8 )
}

func
JSONable( _ data: Data ) -> Any {
	do {
		return try JSONSerialization.jsonObject( with: data, options: [] )
	} catch {
		fatalError()
	}
}

func
Data( jsonable: Any ) -> Data {
	do {
		return try JSONSerialization.data( withJSONObject: jsonable, options: [ .prettyPrinted ] )
	} catch {
		fatalError()
	}
}

func
JSONString( jsonable: Any ) -> String {
	String( data: Data( jsonable: jsonable ) )
}

func
Decode< T: Decodable >( _ data: Data ) -> T {
	do {
		return try JSONDecoder().decode( T.self, from: data )
	} catch {
		fatalError()
	}
}

func
Encode< T: Encodable >( _ encodable: T ) -> Data {
	do {
		return try JSONEncoder().encode( encodable )
	} catch {
		fatalError()
	}
}
*/
//	vv	TODO: IF MAC
//	There's a bug where just focusing on a TextField registers it with the UndoManager, so we wrap the native XXTextField
import AppKit

struct
JPTextField: NSViewRepresentable {

	@Binding var
	text: String
	
	func
	makeNSView( context: Context ) -> NSTextField {
		let textField = NSTextField()
		textField.isBordered	= true
		textField.isEditable	= true
		textField.isBezeled		= true
		textField.delegate		= context.coordinator
		return textField
	}
	
	func
	updateNSView( _ nsView: NSTextField, context: Context ) {
		nsView.stringValue = text
	}
	
	func
	makeCoordinator() -> Coordinator {
		Coordinator( self )
	}

	class
	Coordinator: NSObject, NSTextFieldDelegate {
		var
		parent: JPTextField
		
		init( _ parent: JPTextField ) {
			self.parent = parent
		}
		
		func
		controlTextDidChange( _ obj: Notification ) {
			if let textField = obj.object as? NSTextField {
				self.parent.text = textField.stringValue
			}
		}
	}
}
//	^^	TODO

