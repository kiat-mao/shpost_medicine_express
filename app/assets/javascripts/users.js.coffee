

# apply non-idempotent transformations to the body
#$ ->
#  switch_user_status()

#$(document).on "page:change", ->
  #$ "a[name='switch_user_status']"
  #.unbind("ajax:success")
  #switch_user_status()


###
$(document).on "ajax:success", "a[name='switch_user_status']", (e, data, status, xhr)->
  if this.text is "用户停用"
    this.href = this.href.replace "lock" , "unlock"
    this.text = "用户启用"
    alert "该用户已停用"
  else
    this.href = this.href.replace "unlock" , "lock"
    this.text = "用户停用"
    alert "该用户已启用"
###  

$(document).on "turbolinks:load", ->
  ready()
  

ready = ->
  $("#username").keypress(enterpress)
  $("#name").keypress(enterpress)
  $("#password").keypress(enterpress)
  $("#email").keypress(enterpress)
  $("#user_unit_id").keypress(enterpress)
  $("a[name='switch_user_status']").on "ajax:success", (event) ->
    if this.text is "用户停用"
      this.href = this.href.replace "lock" , "unlock"
      this.text = "用户启用"
      alert "该用户已停用"
    else
      this.href = this.href.replace "unlock" , "lock"
      this.text = "用户停用"
      alert "该用户已启用"

enterpress = (e) ->
  e = e || window.event;   
  if e.keyCode == 13    
    return false;
