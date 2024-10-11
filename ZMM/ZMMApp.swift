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

	@AppStorage( "engineURL" ) var engineURL: String = "http://localhost:50021"

	let
	json = try JSONSerialization.jsonObject(
		with	: try await SharedData( URLRequest( "\(engineURL)/speakers" ) )
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
	@State private	var	showSettings	= false
	
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
			}.padding().alert( isPresented: $showingAlert ) {
				Alert( title: Text( "VOICEVOXにアクセスできません" ), message: Text( errorString ) )
			}.toolbar {
				ToolbarItem() {
					Menu {
						Button( "設定" ) {
							showSettings = true
						}
//						Button( "ヘルプ" ) {
//							// ヘルプ画面への遷移処理
//						}
					} label: {
						Image( systemName: "ellipsis" )
					}
				}
			}.sheet( isPresented: $showSettings ) {
				SettingsView().padding()
			}
		}
	}
}

struct
SettingsView: View {

	@Environment(\.dismiss) var	dismiss
	@AppStorage( "engineURL" ) var engineURL: String = "http://localhost:50021"

	var body: some View {
		 Form {
			Section( header: Text( "APIs" ) ) {
				TextField( "VOICEVOX ENGINE", text: $engineURL )
//				Button( "CLEAR DEFAULT" ) {
//					UserDefaults.standard.removeObject( forKey: "engineURL" )
//				}
			}
			HStack {
				Button( "閉じる" ) { dismiss() }
			}
		}
	}
}
