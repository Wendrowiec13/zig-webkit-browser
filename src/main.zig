const std = @import("std");
const objc = @import("objc.zig");
const webkit = @import("webkit.zig");
const toolbar_delegate = @import("toolbar_delegate.zig");

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

    const window = createWindow(frame, style_mask) orelse {
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
    const split_view_controller = createSplitViewController() orelse {
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
    const sidebar_view_controller = createViewController() orelse return error.ViewControllerFailed;
    const sidebar_view = createView() orelse return error.ViewFailed;
    setView(sidebar_view_controller, sidebar_view);

    // Create content view controller with webview
    const content_view_controller = createViewController() orelse return error.ViewControllerFailed;
    const webview = webkit.WKWebView.init(frame) orelse return error.WebViewInitFailed;
    setView(content_view_controller, webview.id);

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
    addSplitViewItem(split_view_controller, sidebar_view_controller, false, true);
    addSplitViewItem(split_view_controller, content_view_controller, false, false);

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

fn createWindow(frame: webkit.CGRect, style_mask: c_ulong) ?objc.id {
    const window_class = objc.objc_getClass(objc.str("NSWindow")) orelse return null;
    const alloc_sel = objc.sel_registerName(objc.str("alloc")) orelse return null;
    const init_sel = objc.sel_registerName(objc.str("initWithContentRect:styleMask:backing:defer:")) orelse return null;

    const alloc_obj = objc.msg_send(window_class, alloc_sel) orelse return null;

    const init_func: *const fn (objc.id, objc.SEL, webkit.CGRect, c_ulong, c_uint, bool) callconv(.C) ?objc.id =
        @ptrCast(&objc.objc_msgSend);

    return init_func(alloc_obj, init_sel, frame, style_mask, 2, false);
}

fn createSplitViewController() ?objc.id {
    const cls = objc.objc_getClass(objc.str("NSSplitViewController")) orelse return null;
    const alloc_sel = objc.sel_registerName(objc.str("alloc")) orelse return null;
    const init_sel = objc.sel_registerName(objc.str("init")) orelse return null;

    const alloc_obj = objc.msg_send(cls, alloc_sel) orelse return null;
    return objc.msg_send(alloc_obj, init_sel);
}

fn createViewController() ?objc.id {
    const cls = objc.objc_getClass(objc.str("NSViewController")) orelse return null;
    const alloc_sel = objc.sel_registerName(objc.str("alloc")) orelse return null;
    const init_sel = objc.sel_registerName(objc.str("init")) orelse return null;

    const alloc_obj = objc.msg_send(cls, alloc_sel) orelse return null;
    return objc.msg_send(alloc_obj, init_sel);
}

fn createView() ?objc.id {
    const cls = objc.objc_getClass(objc.str("NSView")) orelse return null;
    const alloc_sel = objc.sel_registerName(objc.str("alloc")) orelse return null;
    const init_sel = objc.sel_registerName(objc.str("init")) orelse return null;

    const alloc_obj = objc.msg_send(cls, alloc_sel) orelse return null;
    return objc.msg_send(alloc_obj, init_sel);
}

fn setView(view_controller: objc.id, view: objc.id) void {
    const sel = objc.sel_registerName(objc.str("setView:")) orelse return;
    const func: *const fn (objc.id, objc.SEL, objc.id) callconv(.C) void = @ptrCast(&objc.objc_msgSend);
    func(view_controller, sel, view);
}

fn addSplitViewItem(split_view_controller: objc.id, view_controller: objc.id, collapsed: bool, fixed_width: bool) void {
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
