/*
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
*/

UploadManager = Class.create();
UploadManager.prototype = {
	initialize: function() {
		this.current_file = 0;
	},
	
	attach: function() {
		if ($('file-' + this.current_file).value == '') return;
		
		basename = $('file-' + this.current_file).value.split('/').last();
		this.addListItem(basename);
		this.hideCurrentForm();
		this.createNewForm();
		this.current_file += 1;

		return false;
	},

	addListItem: function(basename) {
		box =  '<span class="file" id="list-' + this.current_file + '">';
		box += '<a href="#" class="deleteAttachment" onclick="uploads.removeListItem(' + this.current_file + '); return false;">' + basename + '</a>';
		box += '</span>';
		
		$('attachmentListRow').show();
		$('attachmentList').innerHTML += box;
	},
	
	hideCurrentForm: function() {
		$('file-form-' + this.current_file).style.position = 'absolute';
		$('file-form-' + this.current_file).style.left = '-1000px';
	},
	
	createNewForm: function() {
		form  = '<div id="file-form-' + (this.current_file + 1) + '">'
		form += '<input type="file" id="file-' + (this.current_file + 1) + '" name="message[files][]" />';
		form += '</div>'
		
		new Insertion.After('fileForms', form);
	},
	
	removeListItem: function(id) {
		$('list-' + id).remove();
		$('file-' + id).remove();

		if ($('attachmentList').innerHTML.strip() == '') $('attachmentListRow').hide();
	},
	
	addJoyentFile: function(id, name) {
		box =  '<span class="file" id="list-' + this.current_file + '">';
		box += '<a href="#" class="deleteAttachment" onclick="uploads.removeJoyentItem(' + this.current_file + '); return false;">' + name + '</a>';
		box += '<input type="hidden" name="message[joyent_files][]" value="' + id + '" />';
		box += '</span>';
		
		$('attachmentListRow').show();
		$('attachmentList').innerHTML += box;
	},
	
	removeJoyentItem: function(id) {
		$('list-' + id).remove();

		if ($('attachmentList').innerHTML.strip() == '') $('attachmentListRow').hide();
	}
	
}
