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
				clear()
			if ($('#order_bags').val() != "") && ($('#order_bags').val().search($('#bag_no').val())!=-1)
				alert("不可重复扫描");
				$('#bag_no').val("");
				$('#bag_no').focus();
			else
				find_bag_result()
				return false;
		else
			if ($('#order_bags').val() != "")
				if confirm("是否装箱完成并发送预收寄信息?")
					$('#bag_no').blur();
					showMask()
					do_packaged()
					return false;
			else
				if $('#is_packaged').val() == "1"
					if confirm("是否打印面单和配货单？")
						package_id = $('#package_id').val()
						window.open("../packages/tkzd?package_id="+package_id)
						window.open("../packages/zxqd?package_id="+package_id)
				$('#bag_no').focus();
				return false;
				

enterpress2 = ->	
	$('#bag_no').val("");
	clear()
	$('#bag_no').focus();


find_bag_result = -> 
				$.ajax({
					type : 'POST',
					url : '../packages/find_bag_result/',
					data: { bag_no: $('#bag_no').val(), site_no: $('#site_no').val(), order_bags: $('#order_bags').val()},
					dataType : 'script'
				});

do_packaged = -> 
				$.ajax({
					type : 'POST',
					url : '../packages/do_packaged/',
					data: { order_bags: $('#order_bags').val(), package_id: $('#package_id').val()},
					dataType : 'script'
				});


clear = ->
	$('#site_no').val("");
	$('#order_bags').val("");
	$('#is_packaged').val("");
	$('#package_id').val("");
	$('#out_results').html("");
	$('#express_no').text("");
	$('#route_code').text("");
	$('#tkzd').attr('disabled', true);
	$('#zxqd').attr('disabled', true);

showMask = ->
	document.getElementById('mid').style.display="block";
	#setTimeout("document.getElementById('mid').style.display='none';$('#bag_no').focus();",10000);


