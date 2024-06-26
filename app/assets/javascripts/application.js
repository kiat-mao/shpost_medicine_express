// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require twitter/bootstrap
//= require bootstrap-datepicker
//= require wice_grid

//= require turbolinks
//= require_tree .

// var ready;

var ready;

ready = function() {
	$('#tkzds').click(function(){
		var vals = [];
		$("input[name='packages[selected][]']:checked").each(function(index, item){vals.push($(this).val())});
		window.open("packages/tkzd?selected="+vals, '_blank');
	});

	$('#zxqds').click(function(){
		var vals = [];
		$("input[name='packages[selected][]']:checked").each(function(index, item){vals.push($(this).val())});
		window.open("packages/zxqd?selected="+vals, '_blank');
	});
}

$(document).on('turbolinks:load', ready);
