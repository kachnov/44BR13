/tag/page
	var/tmp/tag/doctype/dt = new
	var/tmp/tag/head = new /tag("head")
	var/tmp/tag/body = new /tag("body")

	New()
		..("html")

		addChildElement(head)
		addChildElement(body)

	toHtml()
		return dt.toHtml() + ..()

	proc/addToHead(var/tag/child)
		head.addChildElement(child)

	proc/addToBody(var/tag/child)
		body.addChildElement(child)