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
	var	text				: String
	var	consonant			: String?
	var	consonant_length	: Double?
	var	vowel				: String
	var	vowel_length		: Double
	var	pitch				: Double
}

struct
AccentPhrase: Codable, Hashable {
	var	moras				: [ Mora ]
	var	accent				: Int
	var	pause_mora			: Mora?
	var	is_interrogative	: Bool

	var
	pause_length			: Double = 0 {
		didSet {
			if pause_mora != nil { pause_mora!.vowel_length = pause_length }
		}
	}

	enum
	CodingKeys: String, CodingKey {
		case moras
		case accent
		case pause_mora
		case is_interrogative
	}
}

struct
Parameters: Codable, Hashable {
	var	accent_phrases		: [ AccentPhrase ] = []
	var	speedScale			: Double	= 1
	var	pitchScale			: Double	= 0
	var	intonationScale		: Double	= 1
	var	volumeScale			: Double	= 1
	var	prePhonemeLength	: Double	= 0.1
	var	postPhonemeLength	: Double	= 0.1
	var	pauseLength			: Double?	= nil
	var	pauseLengthScale	: Double	= 1
	var	outputSamplingRate	: Int		= 24000
	var	outputStereo		: Bool		= false
	var	kana				: String	= ""
}

struct
ScriptLine: Codable, Hashable {

	var	name				: String
	var	style				: String
	var	dialog				: String

	var	parameters			= Parameters()

	func
	FetchParameters( _ environ: Environ ) async throws -> Parameters {
		var
		request = try URLRequest( "http://127.0.0.1:50021/audio_query?speaker=\( try environ.SpeakerID( name, style ) )&text=\( try URLEncoded( dialog ) )" )
		request.httpMethod = "POST"

		return try JSONDecoder().decode( Parameters.self, from: try await SharedData( request ) )
	}
	func
	WAV( _ environ: Environ ) async throws -> Data {
		var request = try URLRequest( "http://127.0.0.1:50021/synthesis?speaker=\( try environ.SpeakerID( name, style ) )" )
		request.httpMethod = "POST"
		request.setValue( "application/json", forHTTPHeaderField: "Content-Type" )
		request.httpBody = try JSONEncoder().encode( parameters )
		
		return try await SharedData( request )
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
			//	The file isn't in the correct format // The file might be corrupted, truncated, or in an unexpected format.
			throw CocoaError( .fileReadCorruptFile )
		}
		//	Data is missing
		//	Data isn't in the correct format
		script = try JSONDecoder().decode( [ ScriptLine ].self, from: data )
	}
	
	func
	fileWrapper( configuration: WriteConfiguration ) throws -> FileWrapper {
		//	try の検証が難しい
		.init( regularFileWithContents: try JSONEncoder().encode( script ) )
	}
}
