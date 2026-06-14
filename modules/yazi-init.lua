-- Linemode tùy biến: hiện cả dung lượng + ngày sửa cạnh mỗi file.
function Linemode:size_and_mtime()
	local time = math.floor(self._file.cha.mtime or 0)
	time = time == 0 and "" or os.date("%Y-%m-%d %H:%M", time)

	local size = self._file:size()
	size = size and ya.readable_size(size) or "-"

	return string.format("%s  %s", size, time)
end
