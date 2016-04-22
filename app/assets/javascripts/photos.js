function show_photo(list_item_element, id, short_path, full_path, exif_caption) {
	var photo_section = $(list_item_element).parents('.photo_section');

	//var button_approve = $(photo_section).find('.sidebar .approve');
	//var button_deny = $(photo_section).find('.sidebar .deny');

	var image = $(photo_section).find('.preview img');
	var caption = $(photo_section).find('.preview .caption');
	var caption_filename = $(caption).find('.caption_filename');
	var caption_exif = $(caption).find('.caption_exif');
	var rotation_buttons = $(photo_section).find('.preview .buttons a.rotate').parent();

	// highlight selected item
	$(list_item_element).siblings('a').css('background-color', '');
	$(list_item_element).css('background-color', 'darkcyan');

	// keep related items in sync
	$(image).attr('src', full_path);
	$(caption_filename).text(short_path);
	$(caption_exif).text(exif_caption);
	$(rotation_buttons).css('display', 'block');

	update_buttons(photo_section, id);
}


function clear_photo(photo_section) {
	var image = $(photo_section).find('.preview img');
	var caption = $(photo_section).find('.preview .caption');
	var rotation_buttons = $(photo_section).find('.preview .buttons a.rotate').parent();

	$(image).attr('src', '/photos/black.png');
	$(caption).children().text('');
	$(rotation_buttons).css('display', 'none');
}


function update_buttons(photo_section, id) {
	var buttons;
	
	buttons = $(photo_section).find('.sidebar .buttons').children('a');
	buttons.each( function() {
		var url_components = $(this).attr('href').match(/(.*\/photos\/).*(\/.*)/);
		console.log(url_components);
		if(url_components !== null) {
			$(this).attr('href', url_components[1] + id + url_components[2]);
		}
	});

	buttons = $(photo_section).find('.preview .buttons').children('a.rotate');
	buttons.each( function() {
		var url_components = $(this).attr('href').match(/(.*\/photos\/).*(\/.*)/);
		if(url_components !== null) {
			$(this).attr('href', url_components[1] + id + url_components[2]);
		}
	});

	buttons = $(photo_section).find('.preview .buttons').children('a.manage');
	buttons.each( function() {
		var url_components = $(this).attr('href').match(/(.*\/photos\/).*(\/.*)/);
		if(url_components !== null) {
			$(this).attr('href', url_components[1] + id + url_components[2]);
		}
	});
}


function update_photo_counts(pending_count, approved_count, denied_count, recent_count) {
	$('.menu_bar li[data-menuitem="pending"]	a .badge').text(pending_count);
	$('.menu_bar li[data-menuitem="approved"]	a .badge').text(approved_count);
	$('.menu_bar li[data-menuitem="denied"]		a .badge').text(denied_count);
	$('.menu_bar li[data-menuitem="recent"]		a .badge').text(recent_count);
}


function highlight_related_filenames(related_object, color) {
	var filenames = $(related_object).parent().siblings('.filenames');
	$(filenames).children('a').each( function() {
		//console.log('background-color: ' + $(this).css('background-color'));
		if(
			$(this).css('background-color') != 'transparent' // Firefox
			&&
			$(this).css('background-color') != 'rgba(0, 0, 0, 0)' // Chrome
		) {
			$(this).css('background-color', color);
		}
	})
}


$(document).ready(function() {
	$('.approve')
		.on('ajax:beforeSend', function(evt, xhr, settings) {
			highlight_related_filenames(this, 'darkgreen');
		});

	$('.favorite')
		.on('ajax:beforeSend', function(evt, xhr, settings) {
			highlight_related_filenames(this, 'darkgreen');
		});

	$('.deny')
		.on('ajax:beforeSend', function(evt, xhr, settings) {
			highlight_related_filenames(this, 'darkred');
		});

	$('.reject')
		.on('ajax:beforeSend', function(evt, xhr, settings) {
			highlight_related_filenames(this, 'darkred');
		});

	$('.scan')
		.on('ajax:beforeSend', function(evt, xhr, settings) {
			$(this).text('Scanning...');
			console.log(settings.data);
			//settings.data = ('autocomplete=' + $('#autoapprove').is(':checked'));
			settings.data = {autocomplete: $('#autoapprove').is(':checked')};
			console.log(settings.data);
		});

	$('.rotate')
		.on('ajax:beforeSend', function(evt, xhr, settings) {
			$(this).parents('.preview').children('img').attr('src', '/photos/black.png');
			$(this).parents('.preview').children('.caption').children().text('');
		});

	$('ul.menu_bar li a')
		.on('ajax:beforeSend', function(evt, xhr, settings) {
			$(this).parents('ul.menu_bar').find('li a').removeClass('selected');
			$(this).addClass('selected');
			var photo_section = $('.photo_section');
			var filenames = $(photo_section).find('.sidebar .filenames');
			var buttons = $(photo_section).find('.sidebar .buttons a');
			var options = $(photo_section).find('.sidebar').find('.option');
			clear_photo(photo_section);
			update_buttons(photo_section);
			buttons.css('display', 'none');
			options.css('display', 'none');
			filenames.text('');			
		});

	$('#auto_approve')
		.on('click', function() {
			//alert($(this).is(':checked'));
			$.ajax({
				url: 'auto_approve',
				data: {auto_approve: $(this).is(':checked')}
			});
		});
})
