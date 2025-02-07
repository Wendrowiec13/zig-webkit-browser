const std = @import("std");
const objc = @import("objc.zig");
const webkit = @import("webkit.zig");

// Global variables to store toolbar items
var cls: ?objc.Class = null;
var webview: ?*const webkit.WKWebView = null;
var back_button: ?webkit.NSToolbarItem = null;
var forward_button: ?webkit.NSToolbarItem = null;

pub fn setWebView(view: *const webkit.WKWebView) void {
    webview = view;
}
const delegate_class_name = "BrowserToolbarDelegate";

// Create the delegate class
pub fn createDelegateClass() bool {
    cls = objc.objc_getClass(objc.str(delegate_class_name));
    if (cls != null) return true;

    const superclass = objc.objc_getClass(objc.str("NSObject")) orelse return false;
    if (objc.objc_allocateClassPair(superclass, objc.str(delegate_class_name), 0)) |new_cls| {
        cls = new_cls;
    } else {
        return false;
    }

    // Add required methods
    _ = objc.class_addMethod(
        cls.?,
        objc.sel_registerName(objc.str("toolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:")) orelse return false,
        @ptrFromInt(@intFromPtr(&toolbarItemForIdentifier)),
        objc.str("@@:@:@:B")
    );

    _ = objc.class_addMethod(
        cls.?,
        objc.sel_registerName(objc.str("toolbarDefaultItemIdentifiers:")) orelse return false,
        @ptrFromInt(@intFromPtr(&toolbarDefaultItemIdentifiers)),
        objc.str("@@:@")
    );

    _ = objc.class_addMethod(
        cls.?,
        objc.sel_registerName(objc.str("toolbarAllowedItemIdentifiers:")) orelse return false,
        @ptrFromInt(@intFromPtr(&toolbarAllowedItemIdentifiers)),
        objc.str("@@:@")
    );

    _ = objc.class_addMethod(
        cls.?,
        objc.sel_registerName(objc.str("goBack:")) orelse return false,
        @ptrFromInt(@intFromPtr(&goBack)),
        objc.str("v@:@")
    );

    _ = objc.class_addMethod(
        cls.?,
        objc.sel_registerName(objc.str("goForward:")) orelse return false,
        @ptrFromInt(@intFromPtr(&goForward)),
        objc.str("v@:@")
    );

    objc.objc_registerClassPair(cls.?);
    return true;
}

pub fn createDelegate() ?objc.id {
    if (!createDelegateClass()) return null;
    
    cls = objc.objc_getClass(objc.str(delegate_class_name)) orelse return null;
    const alloc_sel = objc.sel_registerName(objc.str("alloc")) orelse return null;
    const init_sel = objc.sel_registerName(objc.str("init")) orelse return null;
    
    const alloc_obj = objc.msg_send(cls, alloc_sel) orelse return null;
    return objc.msg_send_init(alloc_obj, init_sel);
}

// Delegate method implementations
fn toolbarItemForIdentifier(_: objc.id, _: objc.SEL, _: objc.id, identifier_obj: objc.id, _: bool) ?objc.id {
    const utf8_sel = objc.sel_registerName(objc.str("UTF8String")) orelse return null;
    const utf8_func: *const fn (objc.id, objc.SEL) callconv(.C) [*:0]const u8 = @ptrCast(&objc.objc_msgSend);
    const identifier = utf8_func(identifier_obj, utf8_sel);

    if (std.mem.eql(u8, std.mem.span(identifier), "BackButton")) {
        if (back_button == null) {
            back_button = webkit.NSToolbarItem.init("BackButton");
            if (back_button) |*btn| {
                btn.setLabel("Back");
                const set_target_sel = objc.sel_registerName(objc.str("setTarget:")) orelse return null;
                const set_action_sel = objc.sel_registerName(objc.str("setAction:")) orelse return null;
                const set_autovalidates_sel = objc.sel_registerName(objc.str("setAutovalidates:")) orelse return null;
                const set_enabled_sel = objc.sel_registerName(objc.str("setEnabled:")) orelse return null;
                const action_sel = objc.sel_registerName(objc.str("goBack:")) orelse return null;
                
                const set_func: *const fn (objc.id, objc.SEL, objc.id) callconv(.C) void = @ptrCast(&objc.objc_msgSend);
                const set_autovalidates_func: *const fn (objc.id, objc.SEL, bool) callconv(.C) void = @ptrCast(&objc.objc_msgSend);
                const set_action_func: *const fn (objc.id, objc.SEL, objc.SEL) callconv(.C) void = @ptrCast(&objc.objc_msgSend);
                const set_enabled_func: *const fn (objc.id, objc.SEL, bool) callconv(.C) void = @ptrCast(&objc.objc_msgSend);
                
                set_func(btn.id, set_target_sel, @as(objc.id, @ptrCast(cls.?)));
                set_autovalidates_func(btn.id, set_autovalidates_sel, false);
                set_action_func(btn.id, set_action_sel, action_sel);
                set_enabled_func(btn.id, set_enabled_sel, true);
            }
        }
        return if (back_button) |btn| btn.id else null;
    } else if (std.mem.eql(u8, std.mem.span(identifier), "ForwardButton")) {
        if (forward_button == null) {
            forward_button = webkit.NSToolbarItem.init("ForwardButton");
            if (forward_button) |*btn| {
                btn.setLabel("Forward");
                const set_target_sel = objc.sel_registerName(objc.str("setTarget:")) orelse return null;
                const set_action_sel = objc.sel_registerName(objc.str("setAction:")) orelse return null;
                const set_autovalidates_sel = objc.sel_registerName(objc.str("setAutovalidates:")) orelse return null;
                const set_enabled_sel = objc.sel_registerName(objc.str("setEnabled:")) orelse return null;
                const action_sel = objc.sel_registerName(objc.str("goForward:")) orelse return null;
                
                const set_func: *const fn (objc.id, objc.SEL, objc.id) callconv(.C) void = @ptrCast(&objc.objc_msgSend);
                const set_autovalidates_func: *const fn (objc.id, objc.SEL, bool) callconv(.C) void = @ptrCast(&objc.objc_msgSend);
                const set_action_func: *const fn (objc.id, objc.SEL, objc.SEL) callconv(.C) void = @ptrCast(&objc.objc_msgSend);
                const set_enabled_func: *const fn (objc.id, objc.SEL, bool) callconv(.C) void = @ptrCast(&objc.objc_msgSend);
                
                set_func(btn.id, set_target_sel, @as(objc.id, @ptrCast(cls.?)));
                set_autovalidates_func(btn.id, set_autovalidates_sel, false);
                set_action_func(btn.id, set_action_sel, action_sel);
                set_enabled_func(btn.id, set_enabled_sel, true);
            }
        }
        return if (forward_button) |btn| btn.id else null;
    }
    return null;
}

fn createArray(items: []const [*:0]const u8) ?objc.id {
    const array_cls = objc.objc_getClass(objc.str("NSMutableArray")) orelse return null;
    const alloc_sel = objc.sel_registerName(objc.str("alloc")) orelse return null;
    const init_sel = objc.sel_registerName(objc.str("init")) orelse return null;
    
    const array = objc.msg_send(objc.msg_send(array_cls, alloc_sel), init_sel) orelse return null;
    
    const str_cls = objc.objc_getClass(objc.str("NSString")) orelse return null;
    const str_sel = objc.sel_registerName(objc.str("stringWithUTF8String:")) orelse return null;
    const add_sel = objc.sel_registerName(objc.str("addObject:")) orelse return null;
    
    const str_func: *const fn (objc.id, objc.SEL, [*:0]const u8) callconv(.C) ?objc.id = @ptrCast(&objc.objc_msgSend);
    const add_func: *const fn (objc.id, objc.SEL, objc.id) callconv(.C) void = @ptrCast(&objc.objc_msgSend);
    
    for (items) |item| {
        if (str_func(str_cls, str_sel, item)) |str_obj| {
            add_func(array, add_sel, str_obj);
        }
    }
    
    return array;
}

fn toolbarDefaultItemIdentifiers(_: objc.id, _: objc.SEL, _: objc.id) ?objc.id {
    const items = [_][*:0]const u8{
        "BackButton",
        "ForwardButton",
    };
    return createArray(&items);
}

fn toolbarAllowedItemIdentifiers(_: objc.id, _: objc.SEL, _: objc.id) ?objc.id {
    const items = [_][*:0]const u8{
        "BackButton",
        "ForwardButton",
    };
    return createArray(&items);
}

fn goBack(_: objc.id, _: objc.SEL, _: objc.id) void {
    // Empty implementation for now
}

fn goForward(_: objc.id, _: objc.SEL, _: objc.id) void {
    // Empty implementation for now
}