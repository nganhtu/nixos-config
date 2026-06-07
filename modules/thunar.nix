{ ... }:

{
  # Custom action Thunar "Open Kitty Here" (right-click thư mục → mở kitty tại đó).
  # uca.xml do HM quản → read-only; thêm action mới qua GUI sẽ không lưu được.
  xdg.configFile."Thunar/uca.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <actions>
    <action>
    	<icon>kitty</icon>
    	<name>Open Kitty Here</name>
    	<submenu></submenu>
    	<unique-id>1717718400000000-1</unique-id>
    	<command>kitty --directory %f</command>
    	<description>Open a kitty terminal in this directory</description>
    	<range></range>
    	<patterns>*</patterns>
    	<startup-notify/>
    	<directories/>
    </action>
    </actions>
  '';
}
