/*
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
*/

var Files = {
	validateSubmitNew: function(form) {
	  arrErrors = [];
		uploadIds = ['upload_0', 'upload_1', 'upload_2', 'upload_3', 'upload_4'];

		if (uploadIds.all(function(uploadId){ return $(uploadId).value.strip() == ''; }))
			arrErrors.push(JoyentL10n['You must select a file to upload.']);

		// prep sidebar data
		if (Joyent.viewKind == 'create') {
			$('new_item_tags').value          = JoyentPage.createTags.collect(function(tag){ return tag.escapeCharacter(','); }).join(',,');
			$('new_item_permissions').value   = JoyentPage.createPermissions.join(',');
			$('new_item_notifications').value = JoyentPage.createNotifications.join(',');
		}

	  if (validateErrorsArray(arrErrors)) {
	    preventFormResubmission(form);
	    return true;
	  } else {
	    return false;
	  }
	},

	validateSubmitEdit: function(form)	{
	  arrErrors = [];

	  if (form.elements['file[name]'].value.strip() == "")
			arrErrors.push(JoyentL10n['The file name can not be blank.']);

	  if (validateErrorsArray(arrErrors)) {
	    preventFormResubmission(form);
	    return true;
	  } else {
	    return false;
	  }
	}
}