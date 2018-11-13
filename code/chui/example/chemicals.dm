/chui/window/chem
	var/global/list/CHEMS = list("Aluminium", "Bromine", "Copper", "Sugar", "Water")
	var/list/chems = list()
	name = "Chemical Dispensor"
	
/chui/window/chem/New()
	..()

/chui/window/chem/OnClick( var/client/who, var/id )
	if ( !(id in CHEMS))
		return//??
	if ( isnull( chems[ id ] ) )
		chems[ id ] = 0
	chems[ id ] += 10
	CallJSFunction( "addChem", list( id ) )

/chui/window/chem/OnTopic( href, href_list[] )
	switch( href_list[ "action" ] )
		if ( "remove" )
			chems[href_list[ "chem" ]] = null
			CallJSFunction( "removeChem", list( href_list[ "chem" ] ) )

/chui/window/chem/proc/getChems()
	var/ret = "Chem(trails):<div id='chemlist'>"
	for ( var/chem in chems )
		if ( !isnull(chems[ chem ]) )
			world << chem
			ret += "<div id = '[chem]-div'><strong>" + chem + " <em>(<span id='[chem]-count'>[chems[chem]]</span>)</em></strong> - <a href='?src=\ref[src]&action=remove&chem=" + chem + "'>Remove</a></div>"
	return "[ret]</div><hr/>"

/chui/window/chem/GetBody()
	var/generated = getChems()
	for ( var/i = 1, i <= CHEMS.len, i++ )
		generated += theme.generateButton( CHEMS[i], CHEMS[i] ) + "<br/>"

	return {"
	<script type='text/javascript'>
		function addChem( name ){

			var el = document.getElementById( name + "-div" );
			if ( el ){
				$( "#" + name + "-count" ).html( Number( $( "#" + name + "-count" ).html() ) + 10 );
			}else{
				var el = $( "<div id = '" + name + "-div'><strong>" + name + " <em>(<span id='" + name + "-count'>10</span>)</em></strong> - <a href='?src=" + chui.window + "&action=remove&chem=" + name + "'>Remove</a></div>" );
				$( "#chemlist" ).append( el );
				el.hide().fadeIn();
			}

		}
		function removeChem( name ){
			$( "#" + name + "-div" ).fadeOut(300, function(){ $(this).remove(); });
		}
	</script>"} + generated

var/global/chui/window/chem/chems = null

/world/New()
	. = ..()
	chems = new

/client/verb/chemicals()
	set name = "Chem Dispensor"
	set category = "chui"
	if ( chems.IsSubscribed( src ) )
		chems.Unsubscribe( src )
	else
		chems.Subscribe( src )