import Foundation

func
String( data: Data ) -> String {
	.init( data: data, encoding: .utf8 )!
}

func
Data( string: String ) -> Data {
	.init( string.utf8 )
}

func
JSONable( _ data: Data ) throws -> Any {
	try JSONSerialization.jsonObject( with: data, options: [] )
}

func
Data( jsonable: Any ) throws -> Data {
	try JSONSerialization.data( withJSONObject: jsonable, options: [ .prettyPrinted ] )
}

func
JSONString( jsonable: Any ) throws -> String {
	String( data: try Data( jsonable: jsonable ) )
}

func
Decode< T: Decodable >( _ data: Data ) throws -> T {
	try JSONDecoder().decode( T.self, from: data )
}

func
Encode< T: Encodable >( _ encodable: T ) throws -> Data {
	try JSONEncoder().encode( encodable )
}

func
URL( _ string: String ) throws -> URL {
	guard let url = URL( string: string ) else { throw URLError( .badURL ) }
	return url
}

func
URLRequest( _ string: String ) throws -> URLRequest {
	URLRequest( url: try URL( string ) )
}

func
SharedData( _ request: URLRequest ) async throws -> Data {
	let ( data, s ) = try await URLSession.shared.data( for: request )
	if !( 200..<300 ).contains( ( s as! HTTPURLResponse ).statusCode ) { throw URLError( .badServerResponse ) }
	return data
}

struct
JPError: LocalizedError {
	var	errorDescription	: String?
//	var	failureReason		: String?
//	var	recoverySuggestion	: String?
//	var	helpAnchor			: String?

	init(
		_	errorDescription	: String
	) {
		self.errorDescription = errorDescription
	}
}

func
URLEncoded( _ string: String ) throws -> String {
	guard let urlEncoded = string.addingPercentEncoding( withAllowedCharacters: .urlQueryAllowed ) else {
		throw JPError( "addingPercentEncoding failed on: \( string )" )
	}
	return urlEncoded
}

import	SwiftUI

func
SystemImageButton(
	_	name	: String
,	_	action	: @escaping () -> ()
) -> some View {
	Button( action: action ) { Image( systemName: name ) }.buttonStyle( .plain )
}

#if os( macOS )
//	There's a bug where just focusing on a TextField registers it with the UndoManager, so we wrap the native XXTextField
import AppKit

struct
JPTextField: NSViewRepresentable {

	@Binding	var
	text		: String
	
	func
	makeNSView( context: Context ) -> NSTextField {
		let nsView = NSTextField()
		nsView.isBordered	= true
		nsView.isEditable	= true
		nsView.isBezeled	= true
		nsView.delegate		= context.coordinator
		return nsView
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
		
	//	func
	//	controlTextDidEndEditing( _ obj: Notification ) {
	//	}
		func
		controlTextDidChange( _ obj: Notification ) {
			if let textField = obj.object as? NSTextField {
				parent.text = textField.stringValue
			}
		}
	}
}
struct
JPTextEditor: NSViewRepresentable {

	@Binding	var
	text		: String
	
	func
	makeNSView( context: Context ) -> NSTextView {
		let nsView		= NSTextView()
		nsView.delegate	= context.coordinator
		return nsView
	}
	
	func
	updateNSView( _ nsView: NSTextView, context: Context ) {
		nsView.string = text
	}
	
	func
	makeCoordinator() -> Coordinator {
		Coordinator( self )
	}

	class
	Coordinator: NSObject, NSTextViewDelegate {
		var
		parent: JPTextEditor
		
		init( _ parent: JPTextEditor ) {
			self.parent = parent
		}
		
	//	func
	//	controlTextDidEndEditing( _ obj: Notification ) {
	//	}
		func
		controlTextDidChange( _ obj: Notification ) {
			if let textField = obj.object as? NSTextField {
				parent.text = textField.stringValue
			}
		}
	}
}
//	^^	TODO
#endif

#if os( iOS )
import UniformTypeIdentifiers

struct
DocumentPicker: UIViewControllerRepresentable {

	let
	forExport		: Bool
	
	let
	types			: [ UTType ]
	
	let
	action			: ( [ URL ] ) -> ()

	class
	Coordinator	: NSObject, UIDocumentPickerDelegate {
		var
		parent: DocumentPicker

		init( parent: DocumentPicker ) {
			self.parent = parent
		}

		func
		documentPicker( _ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [ URL ] ) {
			parent.action( urls )
		}

		func
		documentPickerWasCancelled( _ controller: UIDocumentPickerViewController ) {
			// Cancelled
		}
	}

	func
	makeCoordinator() -> Coordinator {
		Coordinator( parent: self )
	}

	func
	makeUIViewController( context: Context ) -> UIDocumentPickerViewController {
		let
		VC = forExport
		?	UIDocumentPickerViewController( forExporting			: []	)
 		:	UIDocumentPickerViewController( forOpeningContentTypes	: types	)
		VC.delegate					= context.coordinator
		VC.allowsMultipleSelection	= false
		return VC
	}

	func
	updateUIViewController( _ uiViewController: UIDocumentPickerViewController, context: Context ) {
		// No update required
	}
}
#endif

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

class
Audio: NSObject, AVAudioPlayerDelegate, ObservableObject {

	@Published	var	player		: AVAudioPlayer?
	@Published	var	isPlaying	= false

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
		Stop()
	}
}

struct
AudioControllerView: View {

							var	fetch	: () async throws -> Data
	@StateObject	private	var	audio	= Audio()
	@State			private	var	loading	= false
	
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
				ZStack {
					SystemImageButton( "play" ) {
						loading = true
						Task {
							do {
								try audio.Load( data: try await fetch() )
								await MainActor.run {
									loading = false
									audio.Play()
								}
							} catch {
								loading = false
								throw error
							}
						}
					}
					if loading {
						ProgressView().progressViewStyle( CircularProgressViewStyle() ).scaleEffect( 0.5 )
					}
				}
			}
			SystemImageButton( "stop" ) {
				audio.Stop()
			}.disabled( !audio.isPlaying )
		}
	}
}

