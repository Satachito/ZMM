struct
Style {
	let	name	: String
	let	id		: UInt
}
struct
Speaker {
	let	name	: String
	let	styles	: [ Style ]
}
struct
ZMMError: LocalizedError {
    let	errorDescription	: String?
    init( _ errorDescription: String ) {
		self.errorDescription = errorDescription
	}
}

class
Environ: ObservableObject {

	@Published	var
	speakers	: [ Speaker ] = []
	
	func
	SpeakerID( _ speaker: String, _ style: String ) throws -> UInt {
		guard let speaker	= speakers.first		( where: { $0.name == speaker	} ) else { throw ZMMError( "Unknown Speaker: \(speaker)"	) }
		guard let style		= speaker.styles.first	( where: { $0.name == style		} ) else { throw ZMMError( "Unknown Style: \(style)"		) }
		return style.id
	}
}
func
FetchSpeakers() async throws -> [ Speaker ] {
	let
	json = try JSONSerialization.jsonObject(
		with	: try await SharedData( URLRequest( "http://127.0.0.1:50021/speakers" ) )
	,	options	: []
	) as! [ [ String: Any ] ]

	return try json.map { speaker in
		guard let name		= speaker[ "name"	] as? String				else { throw ZMMError( "Speakers malformed, speaker name not exists"	) }
		guard let styles	= speaker[ "styles"	] as? [ [ String: Any ] ]	else { throw ZMMError( "Speakers malformed, speaker styles not exists"	) }
		return Speaker(
			name	: name
		,	styles	: try styles.map { style in
				guard let name	= style[ "name"	] as? String	else { throw ZMMError( "Speakers malformed, style name not exists"	) }
				guard let id	= style[ "id"	] as? UInt		else { throw ZMMError( "Speakers malformed, style id not exists"	) }
				return Style( name: name, id: id )
			}
		)
	}
}

import SwiftUI

@main struct
ZMMApp: App {

	private			let	environ			= Environ()
	@State private	var	showingAlert	= false
	@State private	var	errorString		= ""
	
	var
	body: some Scene {
		DocumentGroup( newDocument: ZMMDocument() ) {
			ContentView( document: $0.$document ).environmentObject( environ ).onAppear {
				Task {
					do {
						environ.speakers = try await FetchSpeakers()
					} catch {
						await MainActor.run {
							errorString = error.localizedDescription
							showingAlert = true
						}
					}
				}
			}.alert( isPresented: $showingAlert ) {
				Alert( title: Text( "VOICEVOXにアクセスできません" ), message: Text( errorString ) )
			}
		}
	}
}
