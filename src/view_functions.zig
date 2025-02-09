const objc = @import("objc.zig");
const webkit = @import("webkit.zig");

pub fn createWindow(frame: webkit.CGRect, style_mask: c_ulong) ?objc.id {
    const window_class = objc.objc_getClass(objc.str("NSWindow")) orelse return null;
    const alloc_sel = objc.sel_registerName(objc.str("alloc")) orelse return null;
    const init_sel = objc.sel_registerName(objc.str("initWithContentRect:styleMask:backing:defer:")) orelse return null;

    const alloc_obj = objc.msg_send(window_class, alloc_sel) orelse return null;

    const init_func: *const fn (objc.id, objc.SEL, webkit.CGRect, c_ulong, c_uint, bool) callconv(.C) ?objc.id =
        @ptrCast(&objc.objc_msgSend);

    return init_func(alloc_obj, init_sel, frame, style_mask, 2, false);
}

pub fn createSplitViewController() ?objc.id {
    const cls = objc.objc_getClass(objc.str("NSSplitViewController")) orelse return null;
    const alloc_sel = objc.sel_registerName(objc.str("alloc")) orelse return null;
    const init_sel = objc.sel_registerName(objc.str("init")) orelse return null;

    const alloc_obj = objc.msg_send(cls, alloc_sel) orelse return null;
    return objc.msg_send(alloc_obj, init_sel);
}

pub fn createViewController() ?objc.id {
    const cls = objc.objc_getClass(objc.str("NSViewController")) orelse return null;
    const alloc_sel = objc.sel_registerName(objc.str("alloc")) orelse return null;
    const init_sel = objc.sel_registerName(objc.str("init")) orelse return null;

    const alloc_obj = objc.msg_send(cls, alloc_sel) orelse return null;
    return objc.msg_send(alloc_obj, init_sel);
}

pub fn createView() ?objc.id {
    const cls = objc.objc_getClass(objc.str("NSView")) orelse return null;
    const alloc_sel = objc.sel_registerName(objc.str("alloc")) orelse return null;
    const init_sel = objc.sel_registerName(objc.str("init")) orelse return null;

    const alloc_obj = objc.msg_send(cls, alloc_sel) orelse return null;
    return objc.msg_send(alloc_obj, init_sel);
}

pub fn setView(view_controller: objc.id, view: objc.id) void {
    const sel = objc.sel_registerName(objc.str("setView:")) orelse return;
    const func: *const fn (objc.id, objc.SEL, objc.id) callconv(.C) void = @ptrCast(&objc.objc_msgSend);
    func(view_controller, sel, view);
}

pub fn addSplitViewItem(split_view_controller: objc.id, view_controller: objc.id, collapsed: bool, fixed_width: bool) void {
    // Create NSSplitViewItem
    const item_cls = objc.objc_getClass(objc.str("NSSplitViewItem")) orelse return;
    const sidebar_sel = objc.sel_registerName(objc.str("sidebarWithViewController:")) orelse return;
    const create_func: *const fn (objc.id, objc.SEL, objc.id) callconv(.C) ?objc.id = @ptrCast(&objc.objc_msgSend);
    const split_view_item = create_func(item_cls, sidebar_sel, view_controller) orelse return;

    // Set collapse status
    const collapse_sel = objc.sel_registerName(objc.str("setCollapsed:")) orelse return;
    const collapse_func: *const fn (objc.id, objc.SEL, bool) callconv(.C) void = @ptrCast(&objc.objc_msgSend);
    collapse_func(split_view_item, collapse_sel, collapsed);

    if (fixed_width) {
        const min_sel = objc.sel_registerName(objc.str("setMinimumThickness:")) orelse return;
        const thickness_func: *const fn (objc.id, objc.SEL, f64) callconv(.C) void = @ptrCast(&objc.objc_msgSend);
        thickness_func(split_view_item, min_sel, 125);

        const max_sel = objc.sel_registerName(objc.str("setMaximumThickness:")) orelse return;
        thickness_func(split_view_item, max_sel, 400);

        // Get the view from the view controller
        const view_sel = objc.sel_registerName(objc.str("view")) orelse return;
        const get_view_func: *const fn (objc.id, objc.SEL) callconv(.C) ?objc.id = @ptrCast(&objc.objc_msgSend);
        const view = get_view_func(view_controller, view_sel) orelse return;

        // Set initial width
        const width_sel = objc.sel_registerName(objc.str("setFrameSize:")) orelse return;
        const size = webkit.CGSize{ .width = 250, .height = 0 };  // height will be determined by constraints
        const set_size_func: *const fn (objc.id, objc.SEL, webkit.CGSize) callconv(.C) void = @ptrCast(&objc.objc_msgSend);
        set_size_func(view, width_sel, size);

        // Set holding priority to maintain width during window resize
        const hold_sel = objc.sel_registerName(objc.str("setHoldingPriority:")) orelse return;
        const priority_func: *const fn (objc.id, objc.SEL, f32) callconv(.C) void = @ptrCast(&objc.objc_msgSend);
        priority_func(split_view_item, hold_sel, 400);
    } else {
        const min_sel = objc.sel_registerName(objc.str("setMinimumThickness:")) orelse return;
        const thickness_func: *const fn (objc.id, objc.SEL, f64) callconv(.C) void = @ptrCast(&objc.objc_msgSend);
        thickness_func(split_view_item, min_sel, 250);
    }

    // Add split view item to split view controller
    const add_sel = objc.sel_registerName(objc.str("addSplitViewItem:")) orelse return;
    const add_func: *const fn (objc.id, objc.SEL, objc.id) callconv(.C) void = @ptrCast(&objc.objc_msgSend);
    add_func(split_view_controller, add_sel, split_view_item);
}

pub fn createPaddedView(content: objc.id, padding: f64) ?objc.id {
    // Create container view
    const view_cls = objc.objc_getClass(objc.str("NSView")) orelse return null;
    const alloc_sel = objc.sel_registerName(objc.str("alloc")) orelse return null;
    const init_sel = objc.sel_registerName(objc.str("init")) orelse return null;
    
    const container = objc.msg_send(objc.msg_send(view_cls, alloc_sel), init_sel) orelse return null;
    
    // Add content view to container
    const add_subview_sel = objc.sel_registerName(objc.str("addSubview:")) orelse return null;
    const add_func: *const fn (objc.id, objc.SEL, objc.id) callconv(.C) void = @ptrCast(&objc.objc_msgSend);
    add_func(container, add_subview_sel, content);
    
    // Enable Auto Layout
    const translates_sel = objc.sel_registerName(objc.str("setTranslatesAutoresizingMaskIntoConstraints:")) orelse return null;
    const translates_func: *const fn (objc.id, objc.SEL, bool) callconv(.C) void = @ptrCast(&objc.objc_msgSend);
    translates_func(container, translates_sel, false);
    translates_func(content, translates_sel, false);
    
    // Add constraints for all sides
    addEdgeConstraint(content, container, .leading, padding);
    addEdgeConstraint(content, container, .trailing, -padding);
    addEdgeConstraint(content, container, .top, padding);
    addEdgeConstraint(content, container, .bottom, -padding);
    
    return container;
}

const NSLayoutAttribute = enum(c_long) {
    leading = 5,    // NSLayoutAttributeLeading
    trailing = 6,   // NSLayoutAttributeTrailing
    top = 3,        // NSLayoutAttributeTop
    bottom = 4,     // NSLayoutAttributeBottom
};

fn addEdgeConstraint(view: objc.id, container: objc.id, attribute: NSLayoutAttribute, constant: f64) void {
    const layout_cls = objc.objc_getClass(objc.str("NSLayoutConstraint")) orelse return;
    const constraint_sel = objc.sel_registerName(objc.str("constraintWithItem:attribute:relatedBy:toItem:attribute:multiplier:constant:")) orelse return;
    
    const constraint_func: *const fn (
        objc.id, objc.SEL,
        objc.id, c_long,
        c_long,
        objc.id, c_long,
        f64, f64
    ) callconv(.C) ?objc.id = @ptrCast(&objc.objc_msgSend);
    
    const constraint = constraint_func(
        layout_cls, constraint_sel,
        view, @intFromEnum(attribute),
        0,              // NSLayoutRelationEqual
        container, @intFromEnum(attribute),
        1.0, constant
    ) orelse return;
    
    const add_constraint_sel = objc.sel_registerName(objc.str("addConstraint:")) orelse return;
    const add_func: *const fn (objc.id, objc.SEL, objc.id) callconv(.C) void = @ptrCast(&objc.objc_msgSend);
    add_func(container, add_constraint_sel, constraint);
}

pub fn createTextField() ?objc.id {
    const cls = objc.objc_getClass(objc.str("NSTextField")) orelse return null;
    const alloc_sel = objc.sel_registerName(objc.str("alloc")) orelse return null;
    const init_sel = objc.sel_registerName(objc.str("init")) orelse return null;

    const text_field = objc.msg_send(objc.msg_send(cls, alloc_sel), init_sel) orelse return null;

    // Configure the text field
    const bezeled_sel = objc.sel_registerName(objc.str("setBezeled:")) orelse return null;
    const bezeled_func: *const fn (objc.id, objc.SEL, bool) callconv(.C) void = @ptrCast(&objc.objc_msgSend);
    bezeled_func(text_field, bezeled_sel, true);

    const editable_sel = objc.sel_registerName(objc.str("setEditable:")) orelse return null;
    const editable_func: *const fn (objc.id, objc.SEL, bool) callconv(.C) void = @ptrCast(&objc.objc_msgSend);
    editable_func(text_field, editable_sel, true);

    const selectable_sel = objc.sel_registerName(objc.str("setSelectable:")) orelse return null;
    const selectable_func: *const fn (objc.id, objc.SEL, bool) callconv(.C) void = @ptrCast(&objc.objc_msgSend);
    selectable_func(text_field, selectable_sel, true);

    // Set placeholder text
    const placeholder_cls = objc.objc_getClass(objc.str("NSString")) orelse return null;
    const str_sel = objc.sel_registerName(objc.str("stringWithUTF8String:")) orelse return null;
    const str_func: *const fn (objc.id, objc.SEL, [*:0]const u8) callconv(.C) ?objc.id = @ptrCast(&objc.objc_msgSend);
    const placeholder = str_func(placeholder_cls, str_sel, objc.str("Enter URL")) orelse return null;

    const set_placeholder_sel = objc.sel_registerName(objc.str("setPlaceholderString:")) orelse return null;
    const set_placeholder_func: *const fn (objc.id, objc.SEL, objc.id) callconv(.C) void = @ptrCast(&objc.objc_msgSend);
    set_placeholder_func(text_field, set_placeholder_sel, placeholder);

    // Disable auto-resizing mask to use constraints
    const translates_sel = objc.sel_registerName(objc.str("setTranslatesAutoresizingMaskIntoConstraints:")) orelse return null;
    const translates_func: *const fn (objc.id, objc.SEL, bool) callconv(.C) void = @ptrCast(&objc.objc_msgSend);
    translates_func(text_field, translates_sel, false);

    return text_field;
}
