$(document).on "turbolinks:load", ->
	ready()

ready = ->
	$("[name='detail']").click(enterpress)


enterpress = ->	
	$(this).parents('tr').next('.extra-row').slideToggle("fast");