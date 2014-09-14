function show_photo(element, id, short_path, full_path) {
	var photo_section = $(element).parents('.photo_section');

	var button_approve = $(photo_section).find('.sidebar .approve');
	var button_deny = $(photo_section).find('.sidebar .deny');

	var image = $(photo_section).find('.preview img');
	var caption = $(photo_section).find('.preview .caption');

	// highlight selected item
	$(element).siblings('a').css('background-color', '');
	$(element).css('background-color', 'darkcyan');

	// keep related item in sync
	$(image).attr('src', full_path);
	$(caption).text(short_path);
	$(button_approve).off('click');  // Clear existing bindings
	$(button_approve).on('click', function() {approve_photo(element, id); return false;});
	$(button_deny).off('click');  // Clear existing bindings
	$(button_deny).on('click', function() {deny_photo(element, id); return false;});
}


function approve_photo(element, id) {

	delete_element_and_select_next_photo(element);
}


function deny_photo(element, id) {

	delete_element_and_select_next_photo(element);
}


function clear_photo(element) {
	var button_approve = $(element).find('.sidebar .approve');
	var button_deny = $(element).find('.sidebar .deny');

	var image = $(element).find('.preview img');
	var caption = $(element).find('.preview .caption');

	$(image).attr('src', '/photos/black.png');
	$(caption).text('');
	$(button_approve).off('click');  // Clear existing bindings
	$(button_approve).on('click', function() {return false;});
	$(button_deny).off('click');  // Clear existing bindings
	$(button_deny).on('click', function() {return false;});
}


function delete_element_and_select_next_photo(element) {
	console.log('delete_element_and_select_next_photo');
	console.log('\telement: ' + element.id);

	var associated_elements = $(element).nextUntil('a');
	var next_element = $(associated_elements).next('a');
	if(next_element.length == 0) { // We're at the end of the list!
		var siblings = $(element).siblings('a');
		next_element = $(siblings).last();
		if(next_element.length == 0) { // Nothing else in the list!
			clear_photo($(element).parents('.photo_section'));
		}
	}

	$(element).remove();
	$(associated_elements).remove();
	$(next_element).click();
}