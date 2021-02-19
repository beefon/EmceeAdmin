import AppKit

public extension NSMenuItem {
    
    private class InternalMenuItemAction {
        private let handler: () -> ()
        
        init(handler: @escaping () -> ()) {
            self.handler = handler
        }
        
        @objc func invoke() { handler() }
    }
    
    static func with(
        title: String,
        image: NSImage? = nil,
        view: NSView? = nil,
        key: String = "",
        keyEquivalentModifierMask: NSEvent.ModifierFlags = [.command],
        enabled: Bool = false,
        action: @escaping () -> () = {},
        submenu: NSMenu? = nil
    ) -> NSMenuItem {
        let item = NSMenuItem()
        item.attributedTitle = NSAttributedString(string: title)
        item.image = image
        item.keyEquivalent = key
        item.keyEquivalentModifierMask = keyEquivalentModifierMask
        item.isEnabled = enabled
        item.submenu = submenu
        item.view = view
        
        let internalHandler = InternalMenuItemAction(handler: action)
        item.target = internalHandler
        item.action = #selector(InternalMenuItemAction.invoke)
        item.representedObject = internalHandler
        
        return item
    }
}

public extension NSMenu {
    static func create(title: String = "", items: [NSMenuItem] = [], delegate: NSMenuDelegate? = nil) -> NSMenu {
        let menu = NSMenu(title: title)
        menu.items = items
        menu.delegate = delegate
        return menu
    }
    
    func add(items: [NSMenuItem]) {
        for item in items {
            addItem(item)
        }
    }
}
