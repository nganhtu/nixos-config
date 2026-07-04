{ ... }:

# Dịch cấu hình fcitx5-configtool đã chỉnh tay: bamboo Telex 2 làm mặc định,
# trigger đổi thành Super+space, bỏ hẳn AltTriggerKeys (temporarily toggle),
# Share Input State = All để trạng thái bật/tắt + IM đang chọn dùng chung
# giữa các cửa sổ.
#
# LƯU Ý: HM symlink các file này read-only. Sửa qua fcitx5-configtool GUI sau
# khi rebuild sẽ KHÔNG lưu được — đổi setting thì sửa file này, không dùng GUI.
{
  xdg.configFile."fcitx5/config".text = ''
    [Hotkey]
    # Enumerate when holding modifier of Toggle key
    EnumerateWithTriggerKeys=True
    # Temporarily Toggle Input Method
    AltTriggerKeys=
    # Enumerate Input Method Forward
    EnumerateForwardKeys=
    # Enumerate Input Method Backward
    EnumerateBackwardKeys=
    # Skip first input method while enumerating
    EnumerateSkipFirst=False
    # Enumerate Input Method Group Forward
    EnumerateGroupForwardKeys=
    # Time limit in milliseconds for triggering modifier key shortcuts
    ModifierOnlyKeyTimeout=250

    [Hotkey/TriggerKeys]
    0=Super+space
    1=Zenkaku_Hankaku
    2=Hangul

    [Hotkey/ActivateKeys]
    0=Hangul_Hanja

    [Hotkey/DeactivateKeys]
    0=Hangul_Romaja

    [Hotkey/EnumerateGroupBackwardKeys]
    0=Shift+Super+space

    [Hotkey/PrevPage]
    0=Up

    [Hotkey/NextPage]
    0=Down

    [Hotkey/PrevCandidate]
    0=Shift+Tab

    [Hotkey/NextCandidate]
    0=Tab

    [Hotkey/TogglePreedit]
    0=Control+Alt+P

    [Behavior]
    # Activate input method by default
    ActiveByDefault=False
    # Reset state on Focus In
    resetStateWhenFocusIn=No
    # Share Input State
    ShareInputState=All
    # Show preedit in application
    PreeditEnabledByDefault=True
    # Show Input Method Information when switch input method
    ShowInputMethodInformation=True
    # Show Input Method Information when changing focus
    showInputMethodInformationWhenFocusIn=False
    # Show compact input method information
    CompactInputMethodInformation=True
    # Show first input method information
    ShowFirstInputMethodInformation=True
    # Default Candidates per page
    DefaultPageSize=5
    # Override XKB Option
    OverrideXkbOption=False
    # Custom XKB Option
    CustomXkbOption=
    # Force Enabled Addons
    EnabledAddons=
    # Force Disabled Addons
    DisabledAddons=
    # Preload input method to be used by default
    PreloadInputMethod=True
    # Allow input method in the password field
    AllowInputMethodForPassword=False
    # Show preedit text when typing password
    ShowPreeditForPassword=False
    # Interval of saving user data in minutes
    AutoSavePeriod=30
  '';

  xdg.configFile."fcitx5/profile".text = ''
    [Groups/0]
    # Group Name
    Name=Default
    # Layout
    Default Layout=us
    # Default Input Method
    DefaultIM=bamboo

    [Groups/0/Items/0]
    # Name
    Name=keyboard-us
    # Layout
    Layout=

    [Groups/0/Items/1]
    # Name
    Name=bamboo
    # Layout
    Layout=

    [GroupOrder]
    0=Default
  '';

  xdg.configFile."fcitx5/conf/bamboo.conf".text = ''
    # Restore Key Stroke
    RestoreKeyStroke=
    # Input Method
    InputMethod="Telex 2"
    # Output Charset
    OutputCharset=Unicode
    # Enable spell check
    SpellCheck=False
    # Enable Macro
    Macro=False
    # Capitalize Macro
    CapitalizeMacro=True
    # Auto restore keys with invalid words
    AutoNonVnRestore=True
    # Use oà, _uý (instead of òa, úy)
    ModernStyle=False
    # Allow type with more freedom
    FreeMarking=True
    # Underline the preedit text
    DisplayUnderline=True
  '';
}
