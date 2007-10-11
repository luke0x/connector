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

var MailAlias = {
	toggle: function() {
		$('mailAliasEditDialog').visible() ? MailAlias.close() : MailAlias.open();
		return false;
	},

	open: function() {
		$('mailAliasDivBL').removeClassName('roundbl');
		$('mailAliasDivBR').removeClassName('roundbr');
		Effect.BlindDown('mailAliasEditDialog', { duration: Joyent.effectsDuration });

		$('mailAliasDinger').removeClassName("collapsed").addClassName("expanded");
		return false;
	},

	close: function() {
	  Effect.BlindUp('mailAliasEditDialog', { duration: Joyent.effectsDuration, afterFinish: function(){
			$('mailAliasDivBL').addClassName('roundbl');
			$('mailAliasDivBR').addClassName('roundbr');
		} });

		$('mailAliasDinger').removeClassName("expanded").addClassName("collapsed");
		return false;
	},

	newShow: function() {
		$('newMailAliasDialogLink').hide();
	  Effect.BlindDown('newMailAliasDialog', { duration: Joyent.effectsDuration, afterFinish: function(){
			$('newMailAliasName').activate();
		}});
	},
	
	newCancel: function() {
	  Effect.BlindUp('newMailAliasDialog', { duration: Joyent.effectsDuration, afterFinish: function(){
			$('newMailAliasDialogLink').show();
		} });
		$('newMailAliasName').value = '';
	},
	
	newSubmit: function(form) {
		name = $F('newMailAliasName');
		nameRegex = /^[a-z0-9_]+$/;
		usernames = User.findAll().collect(function(user){ return user.username; });
		mailAliasNames = $$('ul#mailAliasList a.mailAliasName').collect(function(element){ return element.innerHTML; });

		arrErrors = [];

		if (name == '')
			arrErrors.push('The alias name can not be blank.');
	  if (name.length > 0 && ! name.match(nameRegex))
			arrErrors.push('The alias name can only contain the characters a-z, 0-9, and _.');
	  if (usernames.include(name))
			arrErrors.push("A user with the name '" + name + "' already exists.");
	  if (mailAliasNames.include(name))
			arrErrors.push("An alias with the name '" + name + "' already exists.");

	  if (validateErrorsArray(arrErrors)) {
	    preventFormResubmission(form);
	    return true;
	  } else {
			$('newMailAliasName').activate();
	    return false;
	  }
	}
}

