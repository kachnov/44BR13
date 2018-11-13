/tag/span
	New(var/type as text)
		..("span")

	proc/setText(var/txt as text)
		innerHtml = txt