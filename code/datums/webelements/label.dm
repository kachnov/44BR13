/tag/label
	New(var/type as text)
		..("label")
	
	proc/setText(var/txt as text)
		var/tag/span/txtSpan = new
		txtSpan.setText(txt)
		addChildElement(txtSpan)