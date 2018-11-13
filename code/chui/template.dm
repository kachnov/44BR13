/chui/template
	var/chui/window/winder

/chui/template/New(window)
	winder = window

/chui/template/proc/SetTemplate( var/code )
	throw EXCEPTION( "Method stub: SetCode" )
	
/chui/template/proc/CallAction( var/ref, var/type, var/client/cli )
	return FALSE
	
/chui/template/proc/Generate()
	return FALSE

/chui/template/proc/OnRequest( var/method, var/list/data )
	return null

/*
/bysql/value/function/chui
	var/chui/template/bysql/tmpl
	New( chui/template/bysql/template )
		tmpl = template
	proc/Call()
		//fart
	Invoke( var/list/bysql/value/argz )
		Call( arglist( argz ) )//utility

	addButton/Call( bysql/value/label, bysql/value/callback, bysql/value/data )
		if ( !label || !callback || label.type != "TEXT" || callback.type != "FUNCTION" )
			throw EXCEPTION( "Expected TEXT, FUNCTION!" )
		var/id = num2text( tmpl.id++ )

		tmpl.rendered += tmpl.winder.theme.generateButton( id, label )
		tmpl.hook( id, callback, data )

chui/template/bysql
	var/bysql/engine/template
	var/bysql/closure/closure
	var/id = 0

	var/list/hooks

	proc/hook( var/id, var/bysql/value/function/func, var/bysql/value/data )
		hooks[ id ] = list( func, data )

	var/rendered = ""
	New(var/chui/window/window)
		template = new
		template.LoadLibs( "chui", "chui", src )
		..()

	SetTemplate( var/code )
		closure = template.LoadString( code )
*/