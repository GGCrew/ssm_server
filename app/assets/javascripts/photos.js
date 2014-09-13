function show_photo(element, id, short_path, full_path) {
	var photo_sidebar = element.parentElement.parentElement;
	var buttons = photo_sidebar.getElementsByClassName('buttons')[0];
	var button_approve = buttons.getElementsByClassName('approve')[0];
	var button_deny = buttons.getElementsByClassName('deny')[0];

	var photo_section = element.parentElement.parentElement.parentElement;
	var preview_section = photo_section.getElementsByClassName('preview')[0];
	var image = preview_section.getElementsByTagName('img')[0];
	var caption = preview_section.getElementsByClassName('caption')[0];

	image.src = full_path;
	caption.innerHTML = short_path;
	button_approve.onclick = function() {approve_photo(this, id); return false;};
	button_deny.onclick = function() {deny_photo(this, id); return false;};
}


function approve_photo(element, id) {

	delete_element_and_select_next_photo(element);
}


function deny_photo(element, id) {

	delete_element_and_select_next_photo(element);
}


function delete_element_and_select_next_photo(element) {
	alert(element.onclick);
}