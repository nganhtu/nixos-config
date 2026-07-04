{ ... }:

# Chỉ ghi setting KHÁC default (đối chiếu source fcitx5 5.1.21 globalconfig.cpp
# + fcitx5-bamboo 1.0.10 bambooconfig.h). Key thiếu → fcitx5 tự dùng default
# biên dịch sẵn (đã kiểm chứng thực nghiệm: key thiếu lẫn key lạ đều êm).
#
# LƯU Ý: HM symlink read-only → chỉnh qua fcitx5-configtool GUI sẽ không lưu
# được; đổi setting thì sửa file này.
{
  xdg.configFile."fcitx5/config".text = ''
    [Hotkey]
    # Temporarily Toggle Input Method (default Shift_L — bỏ, hay bấm nhầm)
    AltTriggerKeys=
    # Default Super+space — phải bỏ để nhường phím cho TriggerKeys
    EnumerateGroupForwardKeys=

    # Default Control+space; list thay nguyên khối (không merge) nên giữ cả
    # 2 phím JP/KR của default để không mất
    [Hotkey/TriggerKeys]
    0=Super+space
    1=Zenkaku_Hankaku
    2=Hangul

    [Behavior]
    # Default No — All để trạng thái bật/tắt + IM dùng chung mọi cửa sổ
    ShareInputState=All
  '';

  # Danh sách IM của group — là data đầy đủ, không phải setting, không trim.
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
    # Default "Telex"
    InputMethod="Telex 2"
    # Default True cả hai
    SpellCheck=False
    Macro=False
  '';
}
