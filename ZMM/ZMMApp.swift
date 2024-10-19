struct
VVStyle {
	let	name	: String
	let	id		: UInt
}
struct
VVSpeaker {
	let	name	: String
	let	styles	: [ VVStyle ]
}
struct
CIStyle {
	let	name	: String
	let	id		: Int
}
struct
CISpeaker {
	let	name	: String
	let	id		: String
	let	styles	: [ CIStyle ]
}

class
Voices: ObservableObject {

	@AppStorage( "voicevoxURL"	)	var	voicevoxURL		: String = "http://localhost:50021"
	@AppStorage( "coeiroinkURL"	)	var	coeiroinkURL	: String = "http://localhost:50032"

	@Published						var	speakersVV		: [ VVSpeaker ]?
	@Published						var	speakersCI		: [ CISpeaker ]?

	func
	VVSpeakers() async -> [ VVSpeaker ] {
		do {
			let
			json = try JSONSerialization.jsonObject(
				with	: try await SharedData( URLRequest( "\(voicevoxURL)/speakers" ) )
			,	options	: []
			) as! [ [ String: Any ] ]

			return try json.map { speaker in
				guard let name		= speaker[ "name"	] as? String						else { throw ZMMError( "Speakers malformed, speaker name not exists"	) }
				guard let styles	= speaker[ "styles"	] as? [ [ String: Any ] ]			else { throw ZMMError( "Speakers malformed, speaker styles not exists"	) }
				return VVSpeaker(
					name	: name
				,	styles	: try styles.map { style in
						guard let name	= style[ "name"	] as? String						else { throw ZMMError( "Speakers malformed, style name not exists"		) }
						guard let id	= style[ "id"	] as? UInt							else { throw ZMMError( "Speakers malformed, style id not exists"		) }
						return VVStyle( name: name, id: id )
					}
				)
			}
		} catch {
			return []
		}
	}
	func
	CISpeakers() async -> [ CISpeaker ] {
		do {
			let
			json = try JSONSerialization.jsonObject(
				with	: try await SharedData( URLRequest( "\(coeiroinkURL)/v1/speakers" ) )
			,	options	: []
			) as! [ [ String: Any ] ]

			return try json.map { speaker in
				guard let name		= speaker[ "speakerName"	] as? String				else { throw ZMMError( "Speakers malformed, speaker name not exists"	) }
				guard let id		= speaker[ "speakerUuid"	] as? String				else { throw ZMMError( "Speakers malformed, speaker uuid not exists"	) }
				guard let styles	= speaker[ "styles"			] as? [ [ String: Any ] ]	else { throw ZMMError( "Speakers malformed, speaker styles not exists"	) }
				return CISpeaker(
					name	: name
				,	id		: id
				,	styles	: try styles.map { style in
						guard let name	= style[ "styleName"	] as? String				else { throw ZMMError( "Speakers malformed, style name not exists"		) }
						guard let id	= style[ "styleId"		] as? Int					else { throw ZMMError( "Speakers malformed, style id not exists"		) }
						return CIStyle( name: name, id: id )
					}
				)
			}
		} catch {
			return []
		}
	}
	var
	statusVV	: String {
		get {
			var
			status = "VOICEBOX:"
			if let speakers = speakersVV {
				status += "\( voicevoxURL ):\( speakers.count > 0 ? "\( speakers.count )" : "未接続" )"
			} else {
				status += "接続中"
			}
			return status
		}
	}
	var
	statusCI	: String {
		get {
			var
			status = "COEIROINK:"
			if let speakers = speakersCI {
				status += "\( coeiroinkURL ):\( speakers.count > 0 ? "\( speakers.count )" : "未接続" )"
			} else {
				status += "接続中"
			}
			return status
		}
	}
}


import SwiftUI

@main struct
ZMMApp: App {
	@StateObject	private	var	voices			= Voices()
	@State			private	var	showSettings	= false
	
	func
	VVTask() {
		Task {
			let	speakers = await voices.VVSpeakers()
			await MainActor.run { voices.speakersVV = speakers }
		}
	}
	func
	CITask() {
		Task {
			let	speakers = await voices.CISpeakers()
			await MainActor.run { voices.speakersCI = speakers }
		}
	}
	var
	body: some Scene {
		DocumentGroup( newDocument: ZMMDocument() ) {
			if voices.speakersVV == nil {
				Text( "loading VOICEVOX voices" ).onAppear { VVTask() }
			}
			if voices.speakersCI == nil {
				Text( "loading COEIROINK voices" ).onAppear { CITask() }
			}
			ContentView( document: $0.$document ).padding().environmentObject( voices ).toolbar {
				if let speakers = voices.speakersVV, speakers.count == 0 {
					ToolbarItem() { Button( "VOICEVOX に接続"		) { VVTask() } }
				}
				if let speakers = voices.speakersCI, speakers.count == 0 {
					ToolbarItem() { Button( "COEIROINK に接続"	) { CITask() } }
				}
				ToolbarItem() {
					SystemImageButton( "gear" ) { showSettings = true }
				}
			}.sheet( isPresented: $showSettings ) {
				SettingsView( voices: voices ).padding()
			}
		}
	}
}
/*
				ToolbarItem() {
					Menu {
						Button( "設定"	) { showSettings = true }
						Button( "ヘルプ"	) {}
					} label: {
						Image( systemName: "ellipsis" )
					}
				}
*/
struct
SettingsView: View {

							var	voices	: Voices

	@Environment(\.dismiss)	var	dismiss

	var
	body: some View {
		Form {
			Section( header: Text( "エンドポイント" ) ) {
				TextField( "VOICEVOX ENGINE"	, text: voices.$voicevoxURL		)
				TextField( "COEIROINK ENGINE"	, text: voices.$coeiroinkURL	)
//				Button( "CLEAR DEFAULT" ) { UserDefaults.standard.removeObject( forKey: "engineURL" ) }
			}
			HStack {
				Spacer()
				Button( "閉じる" ) { dismiss() }.padding()
			}
		}
	}
}
