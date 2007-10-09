/*
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
*/

var Mail = {

	setupCompose: function() {
		$('message_to_complete').activate();
	},

	validateSubmit: function(form) {
		if ($F('command') == 'discard') return confirm('Would you like to discard the current draft message?');
	  
	  arrErrors = [];

	  // require recipients to send mail
	  if ($F('command') == 'send') {
  	  if (! addresses.validateAdressesPresent()) arrErrors.push('You must enter one or more email addresses.');
	  }

		// prep address + sidebar data
		addresses.dumpAddresses();
		$('new_item_tags').value          = JoyentPage.createTags.collect(function(tag){ return tag.escapeCharacter(','); }).join(',,');
		$('new_item_permissions').value   = JoyentPage.createPermissions.join(',');
		$('new_item_notifications').value = JoyentPage.createNotifications.join(',');

	  if (validateErrorsArray(arrErrors)) {
	    preventFormResubmission(form);
	    return true;
	  } else {
	    return false;
	  }
	},

	toggleFlag: function(message_id) {
		m = $('message_flagged_' + message_id.toString());

		if (m.hasClassName('primaryItem')) {
			m.removeClassName('primaryItem');
			m.addClassName('makePrimaryItem');
			new Ajax.Request('/message/' + message_id + '/unflag', {asynchronous:true, evalScripts:true, onFailure: function() {
				m.removeClassName('makePrimaryItem');
				m.addClassName('primaryItem');
			}});
		} else {
			m.removeClassName('makePrimaryItem');
			m.addClassName('primaryItem');
			new Ajax.Request('/message/' + message_id + '/flag', {asynchronous:true, evalScripts:true, onFailure: function() {
				m.removeClassName('primaryItem');
				m.addClassName('makePrimaryItem');
			}});
		}
		return false;
	},

	showAddressField: function(kind) {
		$('show_' + kind + '_link').hide();
		$(kind).show();
		$('message_' + kind + '_complete').activate();

	  if ($('field_separator')) $('field_separator').hide();
		if ($('cc').visible() && $('bcc').visible()) $('showCcAndBcc').hide();

		UserOptions.set(kind.capitalize() + ' Visible', 'true');

		return false;
	},
	
	hideAddressField: function(kind) {
		$(kind).hide();
		$('show_' + kind + '_link').show();

		$(kind + '_addresses').update('');
		addresses[kind + '_addresses'].clear();

		if ($('cc').visible() || $('bcc').visible()) $('showCcAndBcc').show();
		if (! $('cc').visible() && ! $('bcc').visible() && $('field_separator')) $('field_separator').show();
		
		UserOptions.set(kind.capitalize() + ' Visible', 'false');

		return false;
	},
	
	updateInboxUnreadCount: function() {
		new Ajax.Request('/mail/inbox_unread_count', {asynchronous:true, evalScripts:true, onComplete: function(request) {
			count = request.responseText;
			if (count > 0) {
				$('inbox_name_and_count').innerHTML = '<strong>' + JoyentL10n['Inbox'] + ' (' + count + ')</strong>';
			} else {
				$('inbox_name_and_count').innerHTML = JoyentL10n['Inbox'];
			}
		}});
	}

}
