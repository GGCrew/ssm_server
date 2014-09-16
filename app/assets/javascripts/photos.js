function show_photo(list_item_element, id, short_path, full_path) {
	var photo_section = $(list_item_element).parents('.photo_section');

	var button_approve = $(photo_section).find('.sidebar .approve');
	var button_deny = $(photo_section).find('.sidebar .deny');

	var image = $(photo_section).find('.preview img');
	var caption = $(photo_section).find('.preview .caption');

	// highlight selected item
	$(list_item_element).siblings('a').css('background-color', '');
	$(list_item_element).css('background-color', 'darkcyan');

	// keep related item in sync
	$(image).attr('src', full_path);
	$(caption).text(short_path);

	update_buttons(photo_section, id);
}


function clear_photo(photo_section) {
	var image = $(photo_section).find('.preview img');
	var caption = $(photo_section).find('.preview .caption');

	$(image).attr('src', '/photos/black.png');
	$(caption).text('');
}


function update_buttons(photo_section, id) {
	//var buttons = $(list_item_element).parent().siblings('.buttons').children('a');
	var buttons = $(photo_section).find('.sidebar .buttons').children('a');

	buttons.each( function() {
		var url_components = $(this).attr('href').match(/(.*\/photos\/).*(\/.*)/);
		$(this).attr('href', url_components[1] + id + url_components[2]);			
	});
}


$(document).ready(function() {
	$('.approve')
		.on('ajax:beforeSend', function(evt, xhr, settings) {
			var filenames = $(this).parent().siblings('.filenames');
			$(filenames).children('a').each( function() { 
				if($(this).css('background-color') != 'transparent') {
					$(this).css('background-color', 'darkgreen');
				}
			})
		});

	$('.deny')
		.on('ajax:beforeSend', function(evt, xhr, settings) {
			var filenames = $(this).parent().siblings('.filenames');
			$(filenames).children('a').each( function() { 
				if($(this).css('background-color') != 'transparent') {
					$(this).css('background-color', 'darkred');
				}
			})
		});

	$('ul.menu_bar li a')
		.on('ajax:beforeSend', function(evt, xhr, settings) {
			var photo_section = $('.photo_section');
			var filenames = $(photo_section).find('.sidebar .filenames');
			var buttons = $(photo_section).find('.sidebar .buttons a');
			clear_photo(photo_section);
			update_buttons(photo_section);
			buttons.css('display', 'none');
			filenames.text('');			
		});
})
