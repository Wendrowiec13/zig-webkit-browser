const std = @import("std");

pub const id = *anyopaque;
pub const SEL = *anyopaque;
pub const Class = *anyopaque;
pub const IMP = *anyopaque;
pub extern "c" fn objc_getAssociatedObject(object: id, key: [*:0]const u8) ?*anyopaque;
pub extern "c" fn objc_setAssociatedObject(object: id, key: [*:0]const u8, value: ?*anyopaque, policy: c_ulong) void;

pub extern "c" fn objc_getClass(name: [*:0]const u8) ?Class;
pub extern "c" fn sel_registerName(name: [*:0]const u8) ?SEL;
pub extern "c" fn objc_msgSend() void;
pub extern "c" fn objc_allocateClassPair(superclass: Class, name: [*:0]const u8, extra_bytes: usize) ?Class;
pub extern "c" fn objc_registerClassPair(cls: Class) void;
pub extern "c" fn class_addMethod(cls: Class, name: SEL, imp: IMP, types: [*:0]const u8) bool;

// Helper to convert Zig string to C string
pub fn str(s: []const u8) [*:0]const u8 {
    return @ptrCast(s.ptr);
}

// Safe wrapper around objc_msgSend
pub fn msg_send(obj: ?id, sel: ?SEL) ?id {
    if (obj == null or sel == null) return null;
    
    const func: *const fn (?id, ?SEL) callconv(.C) ?id = @ptrCast(&objc_msgSend);
    return func(obj, sel);
}

pub fn msg_send_init(obj: ?id, sel: ?SEL) ?id {
    if (obj == null or sel == null) return null;
    
    const func: *const fn (?id, ?SEL) callconv(.C) ?id = @ptrCast(&objc_msgSend);
    return func(obj, sel);
}

pub fn create_instance(class_name: []const u8) ?id {
    const cls = objc_getClass(str(class_name)) orelse return null;
    const alloc_sel = sel_registerName(str("alloc")) orelse return null;
    const init_sel = sel_registerName(str("init")) orelse return null;
    
    const alloc_obj = msg_send(cls, alloc_sel) orelse return null;
    return msg_send_init(alloc_obj, init_sel);
}