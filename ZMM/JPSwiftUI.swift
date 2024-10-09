import	SwiftUI

struct
SystemImageButton: View {
	let	name	: String
	let	action	: () -> ()
	
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

//	vv	TODO: IF MAC
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
