$(document).on "turbolinks:load", ->
  ready()

ready = ->
  $('#create_at_start').datepicker({
    autoclose: true,
    clearBtn: true,
    language: "zh-CN"});
  $('#create_at_end').datepicker({
    autoclose: true,
    clearBtn: true,
    language: "zh-CN"});
  

