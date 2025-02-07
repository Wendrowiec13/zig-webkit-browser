// src/webkit.zig
const std = @import("std");
const objc = @import("objc.zig");

pub const CGRect = extern struct {
    origin: CGPoint,
    size: CGSize,
};

pub const CGPoint = extern struct {
    x: f64,
    y: f64,
};

pub const CGSize = extern struct {
    width: f64,
    height: f64,
};

pub const WKWebView = struct {
    id: objc.id,

    pub fn init(frame: CGRect) ?WKWebView {
        const cls = objc.objc_getClass(objc.str("WKWebView")) orelse return null;
        const alloc_sel = objc.sel_registerName(objc.str("alloc")) orelse return null;
        const frame_sel = objc.sel_registerName(objc.str("initWithFrame:")) orelse return null;
        
        const alloc_obj = objc.msg_send(cls, alloc_sel) orelse return null;
        
        // This requires a more complex msgSend that can handle struct arguments
        const init_func: *const fn (objc.id, objc.SEL, CGRect) callconv(.C) ?objc.id = 
            @ptrCast(&objc.objc_msgSend);
        
        if (init_func(alloc_obj, frame_sel, frame)) |view_id| {
            return WKWebView{ .id = view_id };
        }
        return null;
    }

    pub fn loadURL(self: *const WKWebView, url_str: []const u8) void {
        // Get all necessary classes and selectors
        const str_cls = objc.objc_getClass(objc.str("NSString")) orelse return;
        const url_cls = objc.objc_getClass(objc.str("NSURL")) orelse return;
        const request_cls = objc.objc_getClass(objc.str("NSURLRequest")) orelse return;

        // Create msgSend variants for different argument types
        const str_func: *const fn (objc.id, objc.SEL, [*:0]const u8) callconv(.C) ?objc.id = 
            @ptrCast(&objc.objc_msgSend);
        const url_func: *const fn (objc.id, objc.SEL, objc.id) callconv(.C) ?objc.id = 
            @ptrCast(&objc.objc_msgSend);
        
        // Get all necessary selectors
        const str_sel = objc.sel_registerName(objc.str("stringWithUTF8String:")) orelse return;
        const url_sel = objc.sel_registerName(objc.str("URLWithString:")) orelse return;
        const request_sel = objc.sel_registerName(objc.str("requestWithURL:")) orelse return;
        const load_sel = objc.sel_registerName(objc.str("loadRequest:")) orelse return;

        // Create URL string
        const ns_str = str_func(str_cls, str_sel, objc.str(url_str)) orelse return;
        
        // Create URL
        const ns_url = url_func(url_cls, url_sel, ns_str) orelse return;
        
        // Create request
        const request = url_func(request_cls, request_sel, ns_url) orelse return;
        
        // Load request
        _ = url_func(self.id, load_sel, request);
    }

    pub fn addSubview(self: *const WKWebView, subview: objc.id) void {
        const add_sel = objc.sel_registerName(objc.str("addSubview:")) orelse return;
        const add_func: *const fn (objc.id, objc.SEL, objc.id) callconv(.C) void = @ptrCast(&objc.objc_msgSend);
        add_func(self.id, add_sel, subview);
    }

    pub fn canGoBack(self: *const WKWebView) bool {
        const sel = objc.sel_registerName(objc.str("canGoBack")) orelse return false;
        const func: *const fn (objc.id, objc.SEL) callconv(.C) bool = @ptrCast(&objc.objc_msgSend);
        return func(self.id, sel);
    }

    pub fn canGoForward(self: *const WKWebView) bool {
        const sel = objc.sel_registerName(objc.str("canGoForward")) orelse return false;
        const func: *const fn (objc.id, objc.SEL) callconv(.C) bool = @ptrCast(&objc.objc_msgSend);
        return func(self.id, sel);
    }

    pub fn goBack(self: *const WKWebView) bool {
        const sel = objc.sel_registerName(objc.str("goBack")) orelse return false;
        const func: *const fn (objc.id, objc.SEL) callconv(.C) bool = @ptrCast(&objc.objc_msgSend);
        return func(self.id, sel);
    }

    pub fn goForward(self: *const WKWebView) bool {
        const sel = objc.sel_registerName(objc.str("goForward")) orelse return false;
        const func: *const fn (objc.id, objc.SEL) callconv(.C) bool = @ptrCast(&objc.objc_msgSend);
        return func(self.id, sel);
    }
};

pub const NSToolbar = struct {
    id: objc.id,

    pub fn init(identifier: []const u8) ?NSToolbar {
        const cls = objc.objc_getClass(objc.str("NSToolbar")) orelse return null;
        const alloc_sel = objc.sel_registerName(objc.str("alloc")) orelse return null;
        const init_sel = objc.sel_registerName(objc.str("initWithIdentifier:")) orelse return null;

        const alloc_obj = objc.msg_send(cls, alloc_sel) orelse return null;

        // Create NSString from identifier
        const str_cls = objc.objc_getClass(objc.str("NSString")) orelse return null;
        const str_sel = objc.sel_registerName(objc.str("stringWithUTF8String:")) orelse return null;
        const str_func: *const fn (objc.id, objc.SEL, [*:0]const u8) callconv(.C) ?objc.id = @ptrCast(&objc.objc_msgSend);
        const ns_identifier = str_func(str_cls, str_sel, objc.str(identifier)) orelse return null;

        // Initialize toolbar with identifier
        const init_func: *const fn (objc.id, objc.SEL, objc.id) callconv(.C) ?objc.id = @ptrCast(&objc.objc_msgSend);
        if (init_func(alloc_obj, init_sel, ns_identifier)) |toolbar_id| {
            return NSToolbar{ .id = toolbar_id };
        }
        return null;
    }

    pub fn setShowsBaselineSeparator(self: *const NSToolbar, shows: bool) void {
        const sel = objc.sel_registerName(objc.str("setShowsBaselineSeparator:")) orelse return;
        const func: *const fn (objc.id, objc.SEL, bool) callconv(.C) void = @ptrCast(&objc.objc_msgSend);
        func(self.id, sel, shows);
    }
};

pub const NSToolbarItem = struct {
    id: objc.id,

    pub fn init(identifier: []const u8) ?NSToolbarItem {
        const cls = objc.objc_getClass(objc.str("NSToolbarItem")) orelse return null;
        const alloc_sel = objc.sel_registerName(objc.str("alloc")) orelse return null;
        const init_sel = objc.sel_registerName(objc.str("initWithItemIdentifier:")) orelse return null;

        const alloc_obj = objc.msg_send(cls, alloc_sel) orelse return null;

        // Create NSString from identifier
        const str_cls = objc.objc_getClass(objc.str("NSString")) orelse return null;
        const str_sel = objc.sel_registerName(objc.str("stringWithUTF8String:")) orelse return null;
        const str_func: *const fn (objc.id, objc.SEL, [*:0]const u8) callconv(.C) ?objc.id = @ptrCast(&objc.objc_msgSend);
        const ns_identifier = str_func(str_cls, str_sel, objc.str(identifier)) orelse return null;

        // Initialize toolbar item with identifier
        const init_func: *const fn (objc.id, objc.SEL, objc.id) callconv(.C) ?objc.id = @ptrCast(&objc.objc_msgSend);
        if (init_func(alloc_obj, init_sel, ns_identifier)) |item_id| {
            return NSToolbarItem{ .id = item_id };
        }
        return null;
    }

    pub fn setLabel(self: *const NSToolbarItem, label: []const u8) void {
        const sel = objc.sel_registerName(objc.str("setLabel:")) orelse return;
        
        // Create NSString from label
        const str_cls = objc.objc_getClass(objc.str("NSString")) orelse return;
        const str_sel = objc.sel_registerName(objc.str("stringWithUTF8String:")) orelse return;
        const str_func: *const fn (objc.id, objc.SEL, [*:0]const u8) callconv(.C) ?objc.id = @ptrCast(&objc.objc_msgSend);
        const ns_label = str_func(str_cls, str_sel, objc.str(label)) orelse return;

        const func: *const fn (objc.id, objc.SEL, objc.id) callconv(.C) void = @ptrCast(&objc.objc_msgSend);
        func(self.id, sel, ns_label);
    }

    pub fn setView(self: *const NSToolbarItem, view: objc.id) void {
        const sel = objc.sel_registerName(objc.str("setView:")) orelse return;
        const func: *const fn (objc.id, objc.SEL, objc.id) callconv(.C) void = @ptrCast(&objc.objc_msgSend);
        func(self.id, sel, view);
    }
};
