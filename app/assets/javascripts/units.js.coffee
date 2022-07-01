# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on "turbolinks:load", ->
  ready()

ready = ->
  $("#no").keypress(enterpress)
  $("#name").keypress(enterpress)
  $("#short_name").keypress(enterpress)
  $("#desc").keypress(enterpress)

enterpress = (e) ->
  e = e || window.event;   
  if e.keyCode == 13    
  	return false;