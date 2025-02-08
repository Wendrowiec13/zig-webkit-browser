const std = @import("std");
const objc = @import("objc.zig");
const webkit = @import("webkit.zig");

pub const ToolbarDelegate = struct {
    id: objc.id,

    pub fn init() ?ToolbarDelegate {
        const superclass = objc.objc_getClass("NSObject") orelse return null;
        const delegate_class = objc.objc_allocateClassPair(superclass, "ToolbarDelegate", 0) orelse return null;

        const toolbar_allowed_sel = objc.sel_registerName(objc.str("toolbarAllowedItemIdentifiers:")) orelse return null;
        const toolbar_default_sel = objc.sel_registerName(objc.str("toolbarDefaultItemIdentifiers:")) orelse return null;
        const toolbar_item_for_id_sel = objc.sel_registerName(objc.str("toolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:")) orelse return null;

        const types = objc.str("@@:@");
        _ = objc.class_addMethod(
            delegate_class,
            toolbar_allowed_sel,
            @ptrFromInt(@intFromPtr(&toolbarAllowedItemIdentifiers)),
            types,
        );
        _ = objc.class_addMethod(
            delegate_class,
            toolbar_default_sel,
            @ptrFromInt(@intFromPtr(&toolbarDefaultItemIdentifiers)),
            types,
        );
        _ = objc.class_addMethod(
            delegate_class,
            toolbar_item_for_id_sel,
            @ptrFromInt(@intFromPtr(&toolbarItemForIdentifier)),
            objc.str("@@:@:@:B"),
        );

        objc.objc_registerClassPair(delegate_class);

        const alloc_sel = objc.sel_registerName(objc.str("alloc")) orelse return null;
        const init_sel = objc.sel_registerName(objc.str("init")) orelse return null;
        
        const alloc_obj = objc.msg_send(delegate_class, alloc_sel) orelse return null;
        const delegate_obj = objc.msg_send(alloc_obj, init_sel) orelse return null;

        return ToolbarDelegate{ .id = delegate_obj };
    }
};

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

fn toolbarItemForIdentifier(_: objc.id, _: objc.SEL, _: objc.id, _: objc.id, _: bool) ?objc.id {
    return null;
}
