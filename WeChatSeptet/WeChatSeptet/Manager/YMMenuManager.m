//
//  YMMenuManager.m
//  WeChatSeptet
//
//  Created by MustangYM on 2020/5/25.
//  Copyright © 2020 WeChatSeptet. All rights reserved.
//

#import "YMMenuManager.h"
#import "NSMenu+Action.h"
#import "NSMenuItem+Action.h"
#import "TKAboutWindowController.h"
#import <objc/runtime.h>
#import "NSWindowController+Action.h"

@implementation YMMenuManager
+ (instancetype)shareInstance
{
    static id share = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        share = [[self alloc] init];
    });
    return share;
}

- (void)initAssistantMenuItems
{
    NSMenuItem *preventRevokeItem = [NSMenuItem menuItemWithTitle:YMLanguage(@"开启消息防撤回", @"Revoke")
                                                           action:@selector(onPreventRevoke:)
                                                           target:self
                                                    keyEquivalent:@"T"
                                                            state:[[YMWeChatConfig sharedConfig] preventRevokeEnable]];
    if ([[YMWeChatConfig sharedConfig] preventRevokeEnable]) {
        NSMenuItem *preventSelfRevokeItem = [NSMenuItem menuItemWithTitle:YMLanguage(@"双向拦截", @"Revoke Self")
                                                                   action:@selector(onPreventSelfRevoke:)
                                                                   target:self
                                                            keyEquivalent:@""
                                                                    state:[[YMWeChatConfig sharedConfig] preventSelfRevokeEnable]];
        
        NSMenuItem *preventAsyncRevokeItem = [NSMenuItem menuItemWithTitle:YMLanguage(@"同步拦截结果", @"Revoke Sync To Phone")
                                                                    action:@selector(onPreventAsyncRevokeToPhone:)
                                                                    target:self
                                                             keyEquivalent:@""
                                                                     state:[[YMWeChatConfig sharedConfig] preventAsyncRevokeToPhone]];
        
        if ([[YMWeChatConfig sharedConfig] preventAsyncRevokeToPhone]) {
            NSMenuItem *asyncRevokeSignalItem = [NSMenuItem menuItemWithTitle:YMLanguage(@"同步单聊", @"Sync Single Chat")
                                                                       action:@selector(onAsyncRevokeSignal:)
                                                                       target:self
                                                                keyEquivalent:@""
                                                                        state:[[YMWeChatConfig sharedConfig] preventAsyncRevokeSignal]];
            NSMenuItem *asyncRevokeChatRoomItem = [NSMenuItem menuItemWithTitle:YMLanguage(@"同步群聊", @"Sync Group Chat")
                                                                         action:@selector(onAsyncRevokeChatRoom:)
                                                                         target:self
                                                                  keyEquivalent:@""
                                                                          state:[[YMWeChatConfig sharedConfig] preventAsyncRevokeChatRoom]];
            NSMenu *subAsyncMenu = [[NSMenu alloc] initWithTitle:@""];
            [subAsyncMenu addItems:@[asyncRevokeSignalItem, asyncRevokeChatRoomItem]];
            preventAsyncRevokeItem.submenu = subAsyncMenu;
        }
        
        
        NSMenu *subPreventMenu = [[NSMenu alloc] initWithTitle:YMLanguage(@"开启拦截", @"Revoke")];
        [subPreventMenu addItems:@[preventSelfRevokeItem, preventAsyncRevokeItem]];
        preventRevokeItem.submenu = subPreventMenu;
    }
       
    
    #pragma mark - 主题
    NSMenuItem *backGroundItem = [NSMenuItem menuItemWithTitle:YMLanguage(@"应用主题", @"Themes")
                                                           action:nil
                                                           target:self
                                                    keyEquivalent:@""
                                                            state:YMWeChatConfig.sharedConfig.usingTheme];
    
    NSMenuItem *darkModeItem = [NSMenuItem menuItemWithTitle:YMLanguage(@"浅黑色", @"Dark Mode")
                                                      action:@selector(onChangeDarkMode:)
                                                      target:self
                                               keyEquivalent:@""
                                                       state:[YMWeChatConfig sharedConfig].darkMode];
    
    NSMenuItem *blackModeItem = [NSMenuItem menuItemWithTitle:YMLanguage(@"深黑色", @"Black Mode")
                                                       action:@selector(onChangeBlackMode:)
                                                       target:self
                                                keyEquivalent:@""
                                                        state:YMWeChatConfig.sharedConfig.blackMode];
    
    NSMenuItem *pinkColorItem = [NSMenuItem menuItemWithTitle:YMLanguage(@"浅粉色", @"Pink Mode")
                                                       action:@selector(onChangePinkModel:)
                                                       target:self
                                                keyEquivalent:@""
                                                        state:[YMWeChatConfig sharedConfig].pinkMode];
    
    NSMenuItem *groupMulticolorItem = [NSMenuItem menuItemWithTitle:YMLanguage(@"色彩差分", @"Group Member Multicolor")
                                                             action:@selector(onGroupMultiColorModel:)
                                                             target:self
                                                      keyEquivalent:@""
                                                              state:[YMWeChatConfig sharedConfig].groupMultiColorMode];
    
    NSMenu *subBackgroundMenu = [[NSMenu alloc] initWithTitle:@""];
    [subBackgroundMenu addItems:@[darkModeItem, blackModeItem, pinkColorItem, groupMulticolorItem]];
    backGroundItem.submenu = subBackgroundMenu;
    
    
    NSMenuItem *aboutPluginItem = [NSMenuItem menuItemWithTitle:YMLanguage(@"关于", @"About")
                                                          action:@selector(onAboutPluginControl:)
                                                          target:self
                                                   keyEquivalent:@""
                                                           state:0];
    
    NSMenu *subMenu = [[NSMenu alloc] initWithTitle:YMLanguage(@"小助手简版", @"Assistant")];
    [subMenu addItems:@[
        preventRevokeItem,
        backGroundItem,
        aboutPluginItem
    ]];
    
    NSMenuItem *menuItem = [[NSMenuItem alloc] init];
    [menuItem setSubmenu:subMenu];
    menuItem.target = self;
    [[[NSApplication sharedApplication] mainMenu] addItem:menuItem];
}

static char kAboutWindowControllerKey;             //  关于窗口的关联 key
- (void)onAboutPluginControl:(NSMenuItem *)item
{
    WeChat *wechat = [objc_getClass("WeChat") sharedInstance];
    TKAboutWindowController *aboutControlWC = objc_getAssociatedObject(wechat, &kAboutWindowControllerKey);
    if (!aboutControlWC) {
        aboutControlWC = [[TKAboutWindowController alloc] initWithWindowNibName:@"TKAboutWindowController"];
        objc_setAssociatedObject(wechat, &kAboutWindowControllerKey, aboutControlWC, OBJC_ASSOCIATION_RETAIN);
    }
    [aboutControlWC show];
}

/**
 菜单栏-微信小助手-消息防撤回-拦截自己消息 设置
 
 @param item 消息防撤回的item
 */
- (void)onPreventSelfRevoke:(NSMenuItem *)item
{
    item.state = !item.state;
    [[YMWeChatConfig sharedConfig] setPreventSelfRevokeEnable:item.state];
}

- (void)onPreventAsyncRevokeToPhone:(NSMenuItem *)item
{
    item.state = !item.state;
    [[YMWeChatConfig sharedConfig] setPreventAsyncRevokeToPhone:item.state];
    [[YMWeChatConfig sharedConfig] setPreventAsyncRevokeSignal:item.state];
    [[YMWeChatConfig sharedConfig] setPreventAsyncRevokeChatRoom:item.state];
    if (item.state) {
        NSMenuItem *asyncRevokeSignalItem = [NSMenuItem menuItemWithTitle:YMLanguage(@"同步单聊", @"Sync Single Chat")
                                                                   action:@selector(onAsyncRevokeSignal:)
                                                                   target:self
                                                            keyEquivalent:@""
                                                                    state:[[YMWeChatConfig sharedConfig] preventAsyncRevokeSignal]];
        NSMenuItem *asyncRevokeChatRoomItem = [NSMenuItem menuItemWithTitle:YMLanguage(@"同步群聊", @"Sync Group Chat")
                                                                     action:@selector(onAsyncRevokeChatRoom:)
                                                                     target:self
                                                              keyEquivalent:@""
                                                                      state:[[YMWeChatConfig sharedConfig] preventAsyncRevokeChatRoom]];
        NSMenu *subAsyncMenu = [[NSMenu alloc] initWithTitle:@""];
        [subAsyncMenu addItems:@[asyncRevokeSignalItem, asyncRevokeChatRoomItem]];
        item.submenu = subAsyncMenu;
    } else {
        item.submenu = nil;
    }
}

- (void)onAsyncRevokeSignal:(NSMenuItem *)item
{
    item.state = !item.state;
    [[YMWeChatConfig sharedConfig] setPreventAsyncRevokeSignal:item.state];
}

- (void)onAsyncRevokeChatRoom:(NSMenuItem *)item
{
    item.state = !item.state;
    [[YMWeChatConfig sharedConfig] setPreventAsyncRevokeChatRoom:item.state];
}

- (void)onChangeBlackMode:(NSMenuItem *)item
{
    item.state = !item.state;
    NSString *msg = nil;
    if (item.state) {
        msg = YMLanguage(@"已启用,重启生效!",@"Turn on BLACK MODE and restart to take effect!");
    } else {
        msg = YMLanguage(@"已停用,重启生效!",@"Turn off BLACK MODE and restart to take effect!");
    }
    NSAlert *alert = [NSAlert alertWithMessageText:YMLanguage(@"警告", @"WARNING")
                                     defaultButton:YMLanguage(@"取消", @"cancel")                       alternateButton:YMLanguage(@"确定重启",@"restart")
                                       otherButton:nil                              informativeTextWithFormat:@"%@", msg];
    NSUInteger action = [alert runModal];
    
    if (action == NSAlertAlternateReturn) {
        __weak __typeof (self) wself = self;
        [[YMWeChatConfig sharedConfig] setBlackMode:item.state];
        item.state ? [[YMWeChatConfig sharedConfig] setDarkMode:NO] : nil;
        item.state ? [[YMWeChatConfig sharedConfig] setPinkMode:NO] : nil;
        !item.state ? [[YMWeChatConfig sharedConfig] setGroupMultiColorMode:NO] : nil;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                [[NSApplication sharedApplication] terminate:wself];
            });
        });
    }  else if (action == NSAlertDefaultReturn) {
        item.state = !item.state;
    }
   
}
- (void)onChangeDarkMode:(NSMenuItem *)item
{
    item.state = !item.state;
    NSString *msg = nil;
    if (item.state) {
        msg = YMLanguage(@"已启用,重启生效!",@"Turn on dark mode and restart to take effect!");
    } else {
        msg = YMLanguage(@"已停用重启生效!",@"Turn off dark mode and restart to take effect!");
    }
    NSAlert *alert = [NSAlert alertWithMessageText:YMLanguage(@"警告", @"WARNING")
                                     defaultButton:YMLanguage(@"取消", @"cancel")                       alternateButton:YMLanguage(@"确定重启",@"restart")
                                       otherButton:nil                              informativeTextWithFormat:@"%@", msg];
    NSUInteger action = [alert runModal];
    if (action == NSAlertAlternateReturn) {
        __weak __typeof (self) wself = self;
        [[YMWeChatConfig sharedConfig] setDarkMode:item.state];
        item.state ? [[YMWeChatConfig sharedConfig] setBlackMode:NO]: nil;
        item.state ? [[YMWeChatConfig sharedConfig] setPinkMode:NO] : nil;
        !item.state ? [[YMWeChatConfig sharedConfig] setGroupMultiColorMode:NO] : nil;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                [[NSApplication sharedApplication] terminate:wself];
            });
        });
    }  else if (action == NSAlertDefaultReturn) {
        item.state = !item.state;
    }
   
}

- (void)onChangePinkModel:(NSMenuItem *)item
{
    item.state = !item.state;
    NSString *msg = nil;
    if (item.state) {
        msg = YMLanguage(@"已启用,重启生效!",@"Turn on Pink mode and restart to take effect!");
    } else {
        msg = YMLanguage(@"已停用,重启生效!",@"Turn off Pink mode and restart to take effect!");
    }
    NSAlert *alert = [NSAlert alertWithMessageText:YMLanguage(@"警告", @"WARNING")
                                     defaultButton:YMLanguage(@"取消", @"cancel")                       alternateButton:YMLanguage(@"确定重启",@"restart")
                                       otherButton:nil                              informativeTextWithFormat:@"%@", msg];
    NSUInteger action = [alert runModal];
    if (action == NSAlertAlternateReturn) {
        __weak __typeof (self) wself = self;
        [[YMWeChatConfig sharedConfig] setPinkMode:item.state];
        item.state ? [[YMWeChatConfig sharedConfig] setDarkMode:NO] : nil;
        item.state ? [[YMWeChatConfig sharedConfig] setBlackMode:NO]: nil;
        item.state ? [[YMWeChatConfig sharedConfig] setGroupMultiColorMode:NO] : nil;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                [[NSApplication sharedApplication] terminate:wself];
            });
        });
    }  else if (action == NSAlertDefaultReturn) {
        item.state = !item.state;
    }
    
}

- (void)onGroupMultiColorModel:(NSMenuItem *)item
{
    item.state = !item.state;
    
    NSString *msg = nil;
    if ([[YMWeChatConfig sharedConfig] pinkMode]) {
        msg = YMLanguage(@"只在深色背景时有效",@"roupMultiColor mode only in dark mode and black mode has effect!");
    } else {
        if (item.state) {
            msg = YMLanguage(@"已启用,重启生效!",@"Turn on GroupMultiColor mode only in dark mode and black mode and restart to take effect!");
        } else {
            msg = YMLanguage(@"已停用,重启生效!",@"Turn off GroupMultiColor mode and restart to take effect!");
        }
    }
    
    NSAlert *alert = [NSAlert alertWithMessageText:YMLanguage(@"警告", @"WARNING")
                                     defaultButton:YMLanguage(@"取消", @"cancel")
                                   alternateButton: YMWeChatConfig.sharedConfig.usingDarkTheme ? YMLanguage(@"确定重启",@"restart") : nil
                                       otherButton:nil                              informativeTextWithFormat:@"%@", msg];
    NSUInteger action = [alert runModal];
    if (action == NSAlertAlternateReturn) {
        __weak __typeof (self) wself = self;
         [[YMWeChatConfig sharedConfig] setGroupMultiColorMode:item.state];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                [[NSApplication sharedApplication] terminate:wself];
            });
        });
    }  else if (action == NSAlertDefaultReturn) {
        item.state = !item.state;
    }
}

- (void)onPreventRevoke:(NSMenuItem *)item
{
    item.state = !item.state;
    [[YMWeChatConfig sharedConfig] setPreventRevokeEnable:item.state];
    if (item.state) {
        NSMenuItem *preventSelfRevokeItem = [NSMenuItem menuItemWithTitle:YMLanguage(@"双向拦截", @"Revoke Self")
                                                                   action:@selector(onPreventSelfRevoke:)
                                                                   target:self
                                                            keyEquivalent:@""
                                                                    state:[[YMWeChatConfig sharedConfig] preventSelfRevokeEnable]];
        
        NSMenuItem *preventAsyncRevokeItem = [NSMenuItem menuItemWithTitle:YMLanguage(@"同步拦截", @"Revoke Sync To Phone")
                                                                    action:@selector(onPreventAsyncRevokeToPhone:)
                                                                    target:self
                                                             keyEquivalent:@""
                                                                     state:[[YMWeChatConfig sharedConfig] preventAsyncRevokeToPhone]];
        
        if (preventAsyncRevokeItem.state) {
            NSMenuItem *asyncRevokeSignalItem = [NSMenuItem menuItemWithTitle:YMLanguage(@"同步单聊", @"Sync Single Chat")
                                                                       action:@selector(onAsyncRevokeSignal:)
                                                                       target:self
                                                                keyEquivalent:@""
                                                                        state:[[YMWeChatConfig sharedConfig] preventAsyncRevokeSignal]];
            NSMenuItem *asyncRevokeChatRoomItem = [NSMenuItem menuItemWithTitle:YMLanguage(@"同步群聊", @"Sync Group Chat")
                                                                         action:@selector(onAsyncRevokeChatRoom:)
                                                                         target:self
                                                                  keyEquivalent:@""
                                                                          state:[[YMWeChatConfig sharedConfig] preventAsyncRevokeChatRoom]];
            NSMenu *subAsyncMenu = [[NSMenu alloc] initWithTitle:@""];
            [subAsyncMenu addItems:@[asyncRevokeSignalItem, asyncRevokeChatRoomItem]];
            preventAsyncRevokeItem.submenu = subAsyncMenu;
        } else {
            preventAsyncRevokeItem.submenu = nil;
        }
        
        NSMenu *subPreventMenu = [[NSMenu alloc] initWithTitle:YMLanguage(@"开启消息防撤回", @"Revoke")];
        [subPreventMenu addItems:@[preventSelfRevokeItem, preventAsyncRevokeItem]];
        item.submenu = subPreventMenu;
    } else {
        item.submenu = nil;
    }
    
}

@end
