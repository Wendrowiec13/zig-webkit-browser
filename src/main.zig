const std = @import("std");
const objc = @import("objc.zig");
const webkit = @import("webkit.zig");

pub fn main() !void {
    const pool = objc.create_instance("NSAutoreleasePool") orelse {
        std.debug.print("Failed to create autorelease pool\n", .{});
        return error.PoolInitFailed;
    };
    defer _ = objc.msg_send(pool, objc.sel_registerName(objc.str("release")));

    // Get shared application instance instead of creating a new one
    const NSApp = objc.objc_getClass(objc.str("NSApplication")) orelse {
        std.debug.print("Failed to get NSApplication class\n", .{});
        return error.AppInitFailed;
    };
    
    const shared_app_sel = objc.sel_registerName(objc.str("sharedApplication")) orelse return error.SelectorFailed;
    const app = objc.msg_send(NSApp, shared_app_sel) orelse {
        std.debug.print("Failed to get shared application\n", .{});
        return error.AppInitFailed;
    };

    // Set activation policy to regular (required for window to show)
    const set_activation_policy_sel = objc.sel_registerName(objc.str("setActivationPolicy:")) orelse return error.SelectorFailed;
    const set_policy_func: *const fn (objc.id, objc.SEL, c_long) callconv(.C) void = @ptrCast(&objc.objc_msgSend);
    set_policy_func(app, set_activation_policy_sel, 0); // NSApplicationActivationPolicyRegular = 0
    
    const style_mask: c_ulong = 
        (1 << 0) | // titled
        (1 << 1) | // closable
        (1 << 2) | // miniaturizable
        (1 << 3);  // resizable
    
    const frame = webkit.CGRect{
        .origin = .{ .x = 100, .y = 100 },
        .size = .{ .width = 800, .height = 600 },
    };

    const window = createWindow(frame, style_mask) orelse {
        std.debug.print("Failed to create window\n", .{});
        return error.WindowInitFailed;
    };

    const webview = webkit.WKWebView.init(frame) orelse {
        std.debug.print("Failed to create webview\n", .{});
        return error.WebViewInitFailed;
    };
    
    const set_content_view_sel = objc.sel_registerName(objc.str("setContentView:")) orelse return error.SelectorFailed;
    const set_view_func: *const fn (objc.id, objc.SEL, objc.id) callconv(.C) void = @ptrCast(&objc.objc_msgSend);
    set_view_func(window, set_content_view_sel, webview.id);
    
    const activate_sel = objc.sel_registerName(objc.str("activateIgnoringOtherApps:")) orelse return error.SelectorFailed;
    const activate_func: *const fn (objc.id, objc.SEL, bool) callconv(.C) void = @ptrCast(&objc.objc_msgSend);
    activate_func(app, activate_sel, true);
    
    // Show window
    const show_sel = objc.sel_registerName(objc.str("makeKeyAndOrderFront:")) orelse return error.SelectorFailed;
    const show_func: *const fn (objc.id, objc.SEL, ?objc.id) callconv(.C) void = @ptrCast(&objc.objc_msgSend);
    show_func(window, show_sel, null);
    
    webview.loadURL("https://example.com");
    
    const run_sel = objc.sel_registerName(objc.str("run")) orelse return error.SelectorFailed;
    _ = objc.msg_send(app, run_sel);
}

fn createWindow(frame: webkit.CGRect, style_mask: c_ulong) ?objc.id {
    const window_class = objc.objc_getClass(objc.str("NSWindow")) orelse return null;
    const alloc_sel = objc.sel_registerName(objc.str("alloc")) orelse return null;
    const init_sel = objc.sel_registerName(objc.str("initWithContentRect:styleMask:backing:defer:")) orelse return null;
    
    const alloc_obj = objc.msg_send(window_class, alloc_sel) orelse return null;
    
    // Window initialization
    const init_func: *const fn (objc.id, objc.SEL, webkit.CGRect, c_ulong, c_uint, bool) callconv(.C) ?objc.id =
        @ptrCast(&objc.objc_msgSend);
    
    return init_func(alloc_obj, init_sel, frame, style_mask, 2, false); // 2 is NSBackingStoreBuffered
}