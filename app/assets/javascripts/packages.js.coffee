# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on "turbolinks:load", ->
	ready()
	enterpress2()

ready = ->
  $("#bag_no").keypress(enterpress)
  $('#reset').click(enterpress2)
  if document.getElementById("bag_no")
  	setInterval("$('#bag_no').focus();",3000);
  $("#scan_no").keypress(enterpress3)
  if document.getElementById("scan_no")
  	setInterval("$('#scan_no').focus();",3000);
  $('#tmp_save').click(enterpress4)
  
enterpress = (e) ->
	e = e || window.event;   
	if e.keyCode == 13   
		if $('#bag_no').val() != ""
			if $('#is_packaged').val() == "1"
				clear()
			if ($('#order_bags').val() != "") && ($('#order_bags').val().search($('#bag_no').val())!=-1)
				audio = document.getElementById("failed_alert");
				audio.play();
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
					$('#bag_no').attr("disabled","disabled");
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
	$('#scan_no').val("");
	clear()
	$('#bag_no').focus();
	$('#scan_no').focus();

enterpress3 = (e) ->
	e = e || window.event;   
	if e.keyCode == 13   
		if $('#scan_no').val() != ""
			if ($('#all_scaned').val() != "") && ($('#all_scaned').val() == "true") && ($('#is_packaged').val() != "1")
				audio = document.getElementById("failed_alert");
				audio.play();
				alert("扫描已完成，请装箱");
				$('#scan_no').val("");
				return false;
			else
				if $('#is_packaged').val() == "1"
					clear()
				$('#tmp_package_msg').text("");
				$("#tmp_msg").hide();
				gy_find_bag_result()
				return false;
		else
			if $('#scaned_orders').val() != "" 
				if $('#order_mode').val() == "B2B"
					if confirm("是否装箱完成并打印?")
						$('#scan_no').blur();
						showMask()
						gy_do_packaged()
						$('#scan_no').attr("disabled","disabled");
						return false;
				else
					if $('#all_scaned').val() == "true"
						$('#scan_no').blur();
						showMask()
						gy_do_packaged()
						$('#scan_no').attr("disabled","disabled");
						return false;
					else
						audio = document.getElementById("failed_alert");
						audio.play();
						alert("请将下方列表中包裹全部扫描完成");
						$('#scan_no').focus();
						return false;
			else
				return false;


enterpress4 = ->
	tmp_save()
	$('#scan_no').val("");
	clear()
	$('#scan_no').focus();




find_bag_result = -> 
				$.ajax({
					type : 'POST',
					url : '../packages/find_bag_result/',
					data: { bag_no: $('#bag_no').val(), site_no: $('#site_no').val(), order_bags: $('#order_bags').val(), bag_amount: $('#bag_amount').text()},
					dataType : 'script'
				});

do_packaged = -> 
				$.ajax({
					type : 'POST',
					url : '../packages/do_packaged/',
					data: { order_bags: $('#order_bags').val(), package_id: $('#package_id').val()},
					dataType : 'script'
				});

gy_find_bag_result = -> 
				$.ajax({
					type : 'POST',
					url : '../packages/gy_find_bag_result/',
					data: { scan_no: $('#scan_no').val(), site_no: $('#site_no').val(), bag_amount: $('#bag_amount').text(), order_mode: $('#order_mode').val(), scaned_orders: $('#scaned_orders').val(), scaned_bags: $('#scaned_bags').val(), to_scan_bags: $('#to_scan_bags').val()},
					dataType : 'script'
				});

gy_do_packaged = -> 
				$.ajax({
					type : 'POST',
					url : '../packages/gy_do_packaged/',
					data: { package_id: $('#package_id').val(), scaned_orders: $('#scaned_orders').val(), scaned_bags: $('#scaned_bags').val(), order_mode: $('#order_mode').val()},
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
	$('#bag_amount').text("0");
	$('#gy_out_results').html("");
	$('#order_mode').val("");
	$('#scaned_orders').val("");
	$('#scaned_bags').val("");
	$('#all_scaned').val("");
	$('#to_scan_bags').val("");
	$('#order_mode_show').text("");
	$('#tmp_package_msg').text("");
	$("#tmp_msg").hide();

showMask = ->
	document.getElementById('mid').style.display="block";
	#setTimeout("document.getElementById('mid').style.display='none';$('#bag_no').focus();",10000);

tmp_save = -> 
				$.ajax({
					type : 'POST',
					url : '../packages/tmp_save/',
					data: { scaned_orders: $('#scaned_orders').val(), site_no: $('#site_no').val()},
					dataType : 'script'
				});

