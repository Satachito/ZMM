import SwiftUI

struct
AccentEditorV: View {
	@Binding	 var
	line		: ScriptLine
	var
	body: some View {
		HStack {
			Divider()
			ForEach( line.parameters.accent_phrases, id: \.self ) { accent_phrase in
//				ForEach( accent_phrase.moras.indices(), id: \.self ) { index in
//					let
//					mora = accent_phrase.moras[ index ]
//					VStack{
//						SystemImageB( index + 1 == accent_phrase.accent ? "circle.fill" : "circle" ) {}
//					//	Text( mora.text )
//					}
//				}
				if let pause_mora = accent_phrase.pause_mora {
					VStack{
						SystemImageB( "circle.slash" ) {}
						Text( pause_mora.text )
					}
				}
				Divider()
			}
		}
	}
}
struct
GEMINIView: View {
    let items = ["Apple", "Banana", "Orange"]

    var body: some View {

		ForEach(items.indices, id: \.self) { index in
			Text("Index: \(index), Item: \(items[index])")
		}
    }
}


struct
OldAccentEditorV: View {
	@Binding	var
	line		: ScriptLine
	var
	body: some View {
		ScrollView( .horizontal ) {
			Canvas() { context, size in
				guard line.fetched else { return }
				
				let
				w = 24
				var
				x = 16
				
				func
				DrawText( _ text: String, _ x: Int ) {
					context.draw(
						Text( text ).monospaced()
					,	at	: CGPoint( x: x, y: 180 )
					)
				}
				line.parameters.accent_phrases.forEach(
					{	moras in
						for i in 0 ..< moras.moras.count {
							DrawText( moras.moras[ i ].text, x )
							let path = Path { path in
								path.addEllipse( in: CGRect( x: x - 4, y: 150, width: 8, height: 8 ) )
							}
							if i + 1 == moras.accent {
								context.fill( path, with: .color( .green ) )
							} else {
								context.stroke( path, with: .color( .green ) )
							}
							x += w
						}
						if let pause_mora = moras.pause_mora {
							DrawText( pause_mora.text, x )
							x += w
						}
					}
				)
			}.background( .white ).frame( width: 2000, height: 200 )
		}
	}
}
