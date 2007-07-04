// Copyright 2004-2007 Joyent Inc.
// 
// Redistribution and/or modification of this code is governed
// by either the GPLv2 or Joyent Commercial Software licenses.
// 
// Report issues and contribute at http://dev.joyent.com/
// 
// $Id$


var Bookmarks = {
	setupEdit: function(){
		if ($F('bookmark_uri') != '' && $F('bookmark_title') != '') {
			$('bookmark_uri').activate();
		} else if ($F('bookmark_uri') == '') {
			$('bookmark_uri').activate();
		} else {
			$('bookmark_title').activate();
		}
	},
	
	validateSubmit: function(form){
	  arrErrors = [];

		if ($F('bookmark_uri').strip() == '') arrErrors.push('You must specify an address.');
		if ($F('bookmark_title').strip() == '') arrErrors.push('You must specify a title.');

		// prep sidebar data
		$('new_item_tags').value          = JoyentPage.createTags.collect(function(tag){ return tag.escapeCharacter(','); }).join(',,');
		$('new_item_permissions').value   = JoyentPage.createPermissions.join(',');
		$('new_item_notifications').value = JoyentPage.createNotifications.join(',');

	  if (validateErrorsArray(arrErrors)) {
	    preventFormResubmission(form);
	    return true;
	  } else {
	    return false;
	  }
	}
}
