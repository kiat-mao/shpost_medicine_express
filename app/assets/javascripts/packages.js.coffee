# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on "turbolinks:load", ->
	ready()
	enterpress2()

ready = ->
  $("#bag_no").keypress(enterpress)
  $('#reset').click(enterpress2)
  
  

enterpress = (e) ->
	e = e || window.event;   
	if e.keyCode == 13   
		if $('#bag_no').val() != ""
			if $('#is_packaged').val() == "1"
				$('#is_packaged').val("");
				$('#out_results').html("");
				$('#express_no').text("");
				$('#route_code').text("");
				$('#tkzd').attr('disabled', true);
				$('#zxqd').attr('disabled', true);
			if ($('#order_bags').val() != "") && ($('#order_bags').val().search($('#bag_no').val())!=-1)
				alert("不可重复扫描");
			else
				find_bag_result()
				return false;
		else
			if confirm("是否装箱完成并发送预收寄信息?")
				do_packaged()
				return false;

enterpress2 = ->	
	$('#bag_no').val("");
	$('#site_no').val("");
	$('#order_bags').val("");
	$('#is_packaged').val("");
	$('#out_results').html("");
	$('#express_no').text("");
	$('#route_code').text("");
	$('#tkzd').attr('disabled', true);
	$('#zxqd').attr('disabled', true);
	$('#bag_no').focus();


find_bag_result = -> 
				$.ajax({
					type : 'GET',
					url : '/packages/find_bag_result/',
					data: { bag_no: $('#bag_no').val(), site_no: $('#site_no').val(), order_bags: $('#order_bags').val()},
					dataType : 'script'
				});

do_packaged = -> 
				$.ajax({
					type : 'GET',
					url : '/packages/do_packaged/',
					data: { order_bags: $('#order_bags').val()},
					dataType : 'script'
				});

