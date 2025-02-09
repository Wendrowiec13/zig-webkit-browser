const std = @import("std");
const objc = @import("objc.zig");
const webkit = @import("webkit.zig");
const toolbar_delegate = @import("toolbar_delegate.zig");
const view_functions = @import("view_functions.zig");

pub fn main() !void {
    const pool = objc.create_instance("NSAutoreleasePool") orelse {
        std.debug.print("Failed to create autorelease pool\n", .{});
        return error.PoolInitFailed;
    };
    defer _ = objc.msg_send(pool, objc.sel_registerName(objc.str("release")));

    // Get shared application instance
    const NSApp = objc.objc_getClass(objc.str("NSApplication")) orelse {
        std.debug.print("Failed to get NSApplication class\n", .{});
        return error.AppInitFailed;
    };

    const shared_app_sel = objc.sel_registerName(objc.str("sharedApplication")) orelse return error.SelectorFailed;
    const app = objc.msg_send(NSApp, shared_app_sel) orelse {
        std.debug.print("Failed to get shared application\n", .{});
        return error.AppInitFailed;
    };

    // Set activation policy
    const set_activation_policy_sel = objc.sel_registerName(objc.str("setActivationPolicy:")) orelse return error.SelectorFailed;
    const set_policy_func: *const fn (objc.id, objc.SEL, c_long) callconv(.C) void = @ptrCast(&objc.objc_msgSend);
    set_policy_func(app, set_activation_policy_sel, 0);

    const style_mask: c_ulong =
        (1 << 0) | // titled
        (1 << 1) | // closable
        (1 << 2) | // miniaturizable
        (1 << 3) | // resizable
        (1 << 12); // unified title and toolbar

    const frame = webkit.CGRect{
        .origin = .{ .x = 100, .y = 100 },
        .size = .{ .width = 1000, .height = 700 },
    };

    const window = view_functions.createWindow(frame, style_mask) orelse {
        std.debug.print("Failed to create window\n", .{});
        return error.WindowInitFailed;
    };

    // Hide the window's title
    const set_title_visibility_sel = objc.sel_registerName(objc.str("setTitleVisibility:")) orelse return error.SelectorFailed;
    const set_title_visibility_func: *const fn (objc.id, objc.SEL, c_long) callconv(.C) void = @ptrCast(&objc.objc_msgSend);
    set_title_visibility_func(window, set_title_visibility_sel, 2); // NSWindowTitleHidden = 2

    const min_size = webkit.CGSize{ .width = 510, .height = 700 };
    const set_min_size_sel = objc.sel_registerName(objc.str("setMinSize:")) orelse return error.SelectorFailed;
    const set_size_func: *const fn (objc.id, objc.SEL, webkit.CGSize) callconv(.C) void = @ptrCast(&objc.objc_msgSend);
    set_size_func(window, set_min_size_sel, min_size);

    // Create split view controller
    const split_view_controller = view_functions.createSplitViewController() orelse {
        std.debug.print("Failed to create split view controller\n", .{});
        return error.SplitViewControllerFailed;
    };

    const toolbar_delegate_instance = toolbar_delegate.ToolbarDelegate.init() orelse return error.ToolbarDelegateFailed;
    const toolbar = webkit.NSToolbar.init("MainToolbar") orelse return error.ToolbarInitFailed;
    toolbar.setShowsBaselineSeparator(false);

    const set_delegate_sel = objc.sel_registerName(objc.str("setDelegate:")) orelse return error.SelectorFailed;
    const set_delegate_func: *const fn (objc.id, objc.SEL, objc.id) callconv(.C) void = @ptrCast(&objc.objc_msgSend);
    set_delegate_func(toolbar.id, set_delegate_sel, toolbar_delegate_instance.id);

    const set_toolbar_sel = objc.sel_registerName(objc.str("setToolbar:")) orelse return error.SelectorFailed;
    const set_toolbar_func: *const fn (objc.id, objc.SEL, objc.id) callconv(.C) void = @ptrCast(&objc.objc_msgSend);
    set_toolbar_func(window, set_toolbar_sel, toolbar.id);

    // Create sidebar view controller
    const sidebar_view_controller = view_functions.createViewController() orelse return error.ViewControllerFailed;
    const sidebar_view = view_functions.createView() orelse return error.ViewFailed;
    view_functions.setView(sidebar_view_controller, sidebar_view);

    // Create content view controller with webview
    const content_view_controller = view_functions.createViewController() orelse return error.ViewControllerFailed;
    const webview = webkit.WKWebView.init(frame) orelse return error.WebViewInitFailed;
    const padded_view = view_functions.createPaddedView(webview.id, 8) orelse return error.PaddedViewFailed;
    view_functions.setView(content_view_controller, padded_view);

    // Enable layer backing for the webview 
    const wants_layer_sel = objc.sel_registerName(objc.str("setWantsLayer:")) orelse return error.SelectorFailed;
    const set_wants_layer_func: *const fn (objc.id, objc.SEL, bool) callconv(.C) void = @ptrCast(&objc.objc_msgSend);
    set_wants_layer_func(webview.id, wants_layer_sel, true);

    // Get the layer
    const layer_sel = objc.sel_registerName(objc.str("layer")) orelse return error.SelectorFailed;
    const get_layer_func: *const fn (objc.id, objc.SEL) callconv(.C) ?objc.id = @ptrCast(&objc.objc_msgSend);
    const layer = get_layer_func(webview.id, layer_sel) orelse return error.LayerFailed;

    // Set corner radius
    const corner_radius_sel = objc.sel_registerName(objc.str("setCornerRadius:")) orelse return error.SelectorFailed;
    const set_corner_radius_func: *const fn (objc.id, objc.SEL, f64) callconv(.C) void = @ptrCast(&objc.objc_msgSend);
    set_corner_radius_func(layer, corner_radius_sel, 10.0);

    // Add view controllers to split view controller
    view_functions.addSplitViewItem(split_view_controller, sidebar_view_controller, false, true);
    view_functions.addSplitViewItem(split_view_controller, content_view_controller, false, false);

    // Set split view as window's content view
    const set_content_view_sel = objc.sel_registerName(objc.str("setContentViewController:")) orelse return error.SelectorFailed;
    const set_view_func: *const fn (objc.id, objc.SEL, objc.id) callconv(.C) void = @ptrCast(&objc.objc_msgSend);
    set_view_func(window, set_content_view_sel, split_view_controller);

    // Set the window to be full size content view
    const set_style_mask_sel = objc.sel_registerName(objc.str("setStyleMask:")) orelse return error.SelectorFailed;
    const set_style_mask_func: *const fn (objc.id, objc.SEL, c_ulong) callconv(.C) void = @ptrCast(&objc.objc_msgSend);
    set_style_mask_func(window, set_style_mask_sel, style_mask | (1 << 15)); // NSWindowStyleMaskFullSizeContentView = 1 << 15

    const set_titlebar_appearance_sel = objc.sel_registerName(objc.str("setTitlebarAppearsTransparent:")) orelse return error.SelectorFailed;
    const set_titlebar_appearance_func: *const fn (objc.id, objc.SEL, bool) callconv(.C) void = @ptrCast(&objc.objc_msgSend);
    set_titlebar_appearance_func(window, set_titlebar_appearance_sel, true);

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
