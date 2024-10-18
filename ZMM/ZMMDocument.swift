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
VVMora			: Codable, Hashable {
	var	text				: String
	var	consonant			: String?
	var	consonant_length	: Double?
	var	vowel				: String
	var	vowel_length		: Double
	var	pitch				: Double
}

struct
VVAccentPhrase	: Codable, Hashable {
	var	moras				: [ VVMora ]
	var	accent				: Int
	var	pause_mora			: VVMora?
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
VVParameters	: Codable, Hashable {
	var	accent_phrases		: [ VVAccentPhrase ]	= []
	var	speedScale			: Double				= 1
	var	pitchScale			: Double				= 0
	var	intonationScale		: Double				= 1
	var	volumeScale			: Double				= 1
	var	prePhonemeLength	: Double				= 0.1
	var	postPhonemeLength	: Double				= 0.1
	var	pauseLength			: Double?				= nil
	var	pauseLengthScale	: Double				= 1
	var	outputSamplingRate	: Int					= 24000
	var	outputStereo		: Bool					= false
	var	kana				: String				= ""
}

struct
CIMora			: Codable, Hashable {
	var	phoneme				: String
	var	hira				: String
	var	accent				: Int
}

struct
CIProsody		: Codable, Hashable {
	var	plain				: [ String ]
	var	detail				: [ [ CIMora ] ]
}

struct
CIParameters	: Codable, Hashable {
	var	speakerUuid			: String			= ""
	var	styleId				: Int				= 0
	var	text				: String			= ""
	var	prosodyDetail		: [ [ CIMora ] ]	= []
	var	speedScale			: Double			= 1
	var	volumeScale			: Double			= 1
	var	pitchScale			: Double			= 0
	var	intonationScale		: Double			= 1
	var	prePhonemeLength	: Double			= 0.1
	var	postPhonemeLength	: Double			= 0.1
	var	outputSamplingRate	: Int				= 24000
}


struct
ScriptLine: Codable, Hashable {

	var	speaker				: String
	var	style				: String
	var	dialog				: String

	var	speedScale			: Double			= 1
	var	volumeScale			: Double			= 1
	var	pitchScale			: Double			= 0
	var	intonationScale		: Double			= 1
	var	prePhonemeLength	: Double			= 0.1
	var	postPhonemeLength	: Double			= 0.1

	var	parametersVV		= VVParameters()
	var	parametersCI		= CIParameters()

	init(
		_	speaker		: String
	,	_	style		: String
	,	_	dialog		: String
	,	_	voices		: Voices
	) async throws {
		self.speaker	= speaker
		self.style		= style
		self.dialog		= dialog
		( parametersVV, parametersCI ) = try await Parameters( voices )
	}

	func
	isVV( _ voices: Voices ) -> Bool {
		guard let speakers	= voices.speakersVV else { return false }
		return speakers.filter( { $0.name == speaker } ).first != nil
	}
	
	func
	isCI( _ voices: Voices ) -> Bool {
		guard let speakers	= voices.speakersCI else { return false }
		return speakers.filter( { $0.name == speaker } ).first != nil
	}
	
	func
	VVStyleID( _ voices: Voices ) throws -> UInt {
		guard let speakers	= voices.speakersVV										else { throw ZMMError( "No VOICEVOX speakers"			) }
		guard let speaker	= speakers.first		( where: { $0.name == speaker	} ) else { throw ZMMError( "Unknown Speaker: \(speaker)"	) }
		guard let style		= speaker.styles.first	( where: { $0.name == style		} ) else { throw ZMMError( "Unknown Style: \(style)"		) }
		return style.id
	}

	func
	CIVoiceID( _ voices: Voices ) throws -> ( String, Int ) {
		guard let speakers	= voices.speakersCI										else { throw ZMMError( "No COEIROINK speakers"			) }
		guard let speaker	= speakers.first		( where: { $0.name == speaker	} ) else { throw ZMMError( "Unknown Speaker: \(speaker)"	) }
		guard let style		= speaker.styles.first	( where: { $0.name == style		} ) else { throw ZMMError( "Unknown Style: \(style)"		) }
		return ( speaker.id, style.id )
	}
	
	func
	Parameters( _ voices: Voices ) async throws -> ( VVParameters, CIParameters ) {
		var
		vv = VVParameters()
		if isVV( voices ) {
			var
			request = try URLRequest( "\(voices.voicevoxURL)/audio_query?speaker=\( try VVStyleID( voices ) )&text=\( try URLEncoded( dialog ) )" )
			request.httpMethod = "POST"
			vv = try JSONDecoder().decode( VVParameters.self, from: try await SharedData( request ) )
		}

		var
		ci = CIParameters()
		if isCI( voices ) {
			var
			request = try URLRequest( "\(voices.coeiroinkURL)/v1/estimate_prosody" )
			request.httpMethod = "POST"
			request.addValue( "application/json", forHTTPHeaderField: "Content-type" )
			request.httpBody = try JSONEncoder().encode( [ "text": dialog ] )
			let
			prosody = try JSONDecoder().decode( CIProsody.self, from: try await SharedData( request ) )
			ci.prosodyDetail = prosody.detail
		}
		return ( vv, ci )
	}

	func
	WAV( _ voices: Voices ) async throws -> Data {
		if isVV( voices ) {
			var
			parameters						= parametersVV
			parameters.speedScale			= speedScale
			parameters.pitchScale			= pitchScale
			parameters.intonationScale		= intonationScale
			parameters.volumeScale			= volumeScale
			parameters.prePhonemeLength		= prePhonemeLength
			parameters.postPhonemeLength	= postPhonemeLength

			var	request = try URLRequest( "\(voices.voicevoxURL)/synthesis?speaker=\( try VVStyleID( voices ) )" )
			request.httpMethod = "POST"
			request.setValue( "application/json", forHTTPHeaderField: "Content-Type" )
			request.httpBody = try JSONEncoder().encode( parameters )
			
			return try await SharedData( request )
		}
		if isCI( voices ) {
			var
			parameters						= parametersCI
			parameters.speedScale			= speedScale
			parameters.pitchScale			= pitchScale
			parameters.intonationScale		= intonationScale
			parameters.volumeScale			= volumeScale
			parameters.prePhonemeLength		= prePhonemeLength
			parameters.postPhonemeLength	= postPhonemeLength

			( parameters.speakerUuid, parameters.styleId ) = try CIVoiceID( voices )
			parameters.text = dialog
	
			var	request = try URLRequest( "\(voices.coeiroinkURL)/v1/synthesis" )
			request.httpMethod = "POST"
			request.setValue( "application/json", forHTTPHeaderField: "Content-Type" )
			request.httpBody = try JSONEncoder().encode( parameters )
print( String( data: try JSONEncoder().encode( parameters ) ) )
			
			return try await SharedData( request )
		}
		throw ZMMError( "No wav data for: \(speaker):\(style)" )
	}
}

struct
ZMMDocument: FileDocument {
	static var
	readableContentTypes: [ UTType ] { [ .zmm ] }

	var
	script: [ ScriptLine ]
	
	init() {
		script = []
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
