struct
Style {
	var
	style		: String
	var
	id			: UInt
}

struct
Speaker {
	var
	name		: String
	var
	styles		: [ Style ]
}

class
Environ: ObservableObject {
	@Published var
	speakers	: [ Speaker ] = []
	@MainActor func
	Fetch() async throws {
		let
		( json, _ ) = try await URLSession.shared.data(
			for: URLRequest( url: URL( string: "http://127.0.0.1:50021/speakers" )! )
		)
		for char in try JSONSerialization.jsonObject( with: json, options: [] ) as! [ [ String: Any ] ] {
			var
			styles: [ Style ] = []
			for style in char[ "styles" ] as! [ [ String: Any ] ] {
				styles.append( Style( style: style[ "name" ] as! String, id: style[ "id" ] as! UInt ) )
			}
			speakers.append( Speaker( name: char[ "name" ] as! String, styles: styles ) )
		}
	}
	func
	SpeakerID( _ name: String, _ style: String ) -> UInt {
	//	TODO:	Fetch がこけたとき、おちるはずなので、Alert
		speakers.first( where: { $0.name == name } )!.styles.first( where: { $0.style == style } )!.id
	}
}

import SwiftUI

@main
struct ZMMApp: App {

	@State private var
	environ = Environ()
	
	var
	body: some Scene {
		DocumentGroup( newDocument: ZMMDocument() ) {
			ContentView( document: $0.$document ).environmentObject( environ ).onAppear {
				Task {
					do {
						try await environ.Fetch()
					} catch {
						print( error )
					}
				}
			}
		}
	}
}
