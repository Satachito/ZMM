import SwiftUI
import UniformTypeIdentifiers

extension
UTType {
	static var
	zmm: UTType {
		UTType( importedAs: "tokyo.828.zmm" )
	}
}

struct
Mora: Codable, Hashable {
	var
	text				: String
	var
	consonant			: String?
	var
	consonant_length	: Double?
	var
	vowel				: String?
	var
	vowel_length		: Double?
	var
	pitch				: Double?
}

struct
AccentPhrase: Codable, Hashable {
	var
	moras				: [ Mora ]
	var
	accent				: Int
	var
	pause_mora			: Mora?
	var
	is_interrogative	: Bool
}

struct
Parameters: Codable, Hashable {
	var
	accent_phrases		: [ AccentPhrase ] = []
	var
	speedScale			: Double	= 1
	var
	pitchScale			: Double	= 0
	var
	intonationScale		: Double	= 1
	var
	volumeScale			: Double	= 1
	var
	prePhonemeLength	: Double	= 0.1
	var
	postPhonemeLength	: Double	= 0.1
	var
	pauseLength			: Double?	= nil
	var
	pauseLengthScale	: Double	= 1
	var
	outputSamplingRate	: Int		= 24000
	var
	outputStereo		: Bool		= false
	var
	kana				: String	= ""
}

struct
ScriptLine: Codable, Hashable {

	var
	name			: String
	var
	style			: String
	var
	dialog			: String

	var
	parameters		= Parameters()
	var
	fetched			= false

	init( _ name: String, _ style: String, _ dialog: String ) {
		self.name			= name
		self.style			= style
		self.dialog			= dialog
	}

	@MainActor func
	Fetch( _ environ: Environ ) async throws -> Parameters {
		let
		query = "?speaker=\( environ.SpeakerID( name, style ) )&text=" + dialog.addingPercentEncoding( withAllowedCharacters: .urlQueryAllowed )!
		var
		request = URLRequest( url: URL( string: "http://127.0.0.1:50021/audio_query" + query )! )
		request.httpMethod = "POST"

		let ( json, s ) = try await URLSession.shared.data( for: request )
		if !( 200..<300 ).contains( ( s as! HTTPURLResponse ).statusCode ) { throw URLError( .badServerResponse ) }
//print( "AUDIO_QUERY", String( data: json ) )
		return try JSONDecoder().decode( Parameters.self, from: json )
	}
	@MainActor func
	WAV( _ environ: Environ ) async throws -> Data {
		var request = URLRequest( url: URL( string: "http://127.0.0.1:50021/synthesis?speaker=\( environ.SpeakerID( name, style ) )" )! )
		request.httpMethod = "POST"
		request.setValue( "application/json", forHTTPHeaderField: "Content-Type" )
		request.httpBody = try JSONEncoder().encode( parameters )
print( request, String( data: request.httpBody!, encoding: .utf8 )! )
		let ( wav, s ) = try await URLSession.shared.data( for: request )
		if !( 200..<300 ).contains( ( s as! HTTPURLResponse ).statusCode ) { throw URLError( .badServerResponse ) }
		return wav
	}
}

struct
ZMMDocument: FileDocument {
	static var
	readableContentTypes: [ UTType ] { [ .zmm ] }

	var
	script: [ ScriptLine ] = []
	
	init() {
	}
	
	init( configuration: ReadConfiguration ) throws {
		guard let data = configuration.file.regularFileContents else {
			throw CocoaError( .fileReadCorruptFile )
		}
		script = try JSONDecoder().decode( [ ScriptLine ].self, from: data )
	}
	
	func
	fileWrapper( configuration: WriteConfiguration ) throws -> FileWrapper {
		.init( regularFileWithContents: try JSONEncoder().encode( script ) )
	}
}
