/*
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
*/

var People = {
	currentRecoveryEmail: '',
	currentNotifierSMS: '',
	currentNotifierSMSProvider: '',
	currentNotifierEmail: '',
	currentNotifierIM: '',
  currentSpecialEmailAddresses: '',

	providers: [
    ['att', 'AT&T'],
    ['nextel', 'Nextel'],
    ['o2_de', 'O2 Germany'],
    ['orange_fr', 'Orange France'],
    ['sprint', 'Sprint PCS'],
	  ['telus', 'Telus Mobility'],
    ['tmobile', 'T-Mobile'],
    ['tmobile_de', 'T-Mobile Germany'],
    ['tmobile_uk', 'T-Mobile UK'],
    ['verizon', 'Verizon'],
	  ['virgin_mobile', 'Virgin Mobile']
	],
	
	setupEdit: function() {
		$('person_first_name').activate();
	},
	
	validateSubmit: function(form) {
	  var arrErrors = [];

		// contact info tab
		if ($F('person_first_name').strip()   == '' &&
				$F('person_middle_name').strip()  == '' &&
				$F('person_last_name').strip()    == '' &&
				$F('person_company_name').strip() == '') {
	    arrErrors.push(JoyentL10n['You must specify either a name or company name.']);
	  }
	  arrPersonPhoneNumberIndexes.each(function(index){
			if ($F('person_phone_numbers_' + index.toString() + '_phone_number').strip() == '') {
				arrErrors.push(JoyentL10n['Phone numbers can not be blank.']);
				throw $break;
			}
		});
	  arrPersonEmailAddressIndexes.each(function(index){
			if ($F('person_email_addresses_' + index.toString() + '_email_address').strip() == '') {
				arrErrors.push(JoyentL10n['Email addresses can not be blank.']);
				throw $break;
			}
		});
	  arrPersonAddressIndexes.each(function(index){
			if ($F('person_addresses_' + index.toString() + '_street'      ).strip() == '' &&
					$F('person_addresses_' + index.toString() + '_city'        ).strip() == '' &&
					$F('person_addresses_' + index.toString() + '_state'       ).strip() == '' &&
					$F('person_addresses_' + index.toString() + '_postal_code' ).strip() == '' &&
					$F('person_addresses_' + index.toString() + '_country_name').strip() == '') {
				arrErrors.push(JoyentL10n['Addresses can not be blank.']);
				throw $break;
			}
		});
	  arrPersonImAddressIndexes.each(function(index){
			if ($F('person_im_addresses_' + index.toString() + '_im_address').strip() == '') {
				arrErrors.push(JoyentL10n['IM addresses can not be blank.']);
				throw $break;
			}
		});
	  arrPersonWebsiteIndexes.each(function(index){
			if ($F('person_websites_' + index.toString() + '_site_title').strip() == '') {
				arrErrors.push(JoyentL10n['Website names can not be blank.']);
				throw $break;
			}
		});
	  arrPersonWebsiteIndexes.each(function(index){
			if ($F('person_websites_' + index.toString() + '_site_url').strip() == '') {
				arrErrors.push(JoyentL10n['Website URLs can not be blank.']);
				throw $break;
			}
		});
	  arrPersonSpecialDateIndexes.each(function(index){
			if ($F('person_special_dates_' + index.toString() + '_description').strip() == '') {
				arrErrors.push(JoyentL10n['Special date descriptions can not be blank.']);
				throw $break;
			}
		});
	  arrPersonSpecialDateIndexes.each(function(index){
			if ($F('person_special_dates_' + index.toString() + '_year' ).strip() == '' ||
				  $F('person_special_dates_' + index.toString() + '_month').strip() == '' ||
					$F('person_special_dates_' + index.toString() + '_day'  ).strip() == '') {
				arrErrors.push(JoyentL10n['Special date dates can not be blank.']);
				throw $break;
			}
		});

		// account tab
    var nameRegex = /^[a-z0-9_]+$/;
    var usernames = User.findAll().collect(function(user){ return user.username; });

		// decide how to handle the account tab forms
		// new person or editing contact
		if ($('person_account_type') && $F('person_account_type') == 'contact') {

			// creating/saving a contact
			if ($('personTypeContactRadio').checked) {
				// nada
			// creating a guest
			} else if ($('personTypeGuestRadio').checked) {
				if ($('person_guest_username') && $F('person_guest_username').strip() == '')
					arrErrors.push(JoyentL10n['The username can not be blank.']);
				if ($('person_guest_recovery_email') && $F('person_guest_recovery_email').strip() == '')
					arrErrors.push(JoyentL10n['Password recovery email address can not be blank.']);
			// creating a user
			} else if ($('personTypeUserRadio').checked) {
				if ($('person_username') && $F('person_username').strip() == '')
					arrErrors.push(JoyentL10n['The username can not be blank.']);
        if (usernames.include(username))
          arrErrors.push(JoyentL10n['A user with the specified username already exists.']);
				if (mailAliasNames.include(username))
				    arrErrors.push(JoyentL10n['An alias with the specified username already exists.']);
				if ($F('person_password').strip() == '')
					arrErrors.push(JoyentL10n['The password can not be blank.']);
				if ($F('person_password') != $F('person_password_confirmation'))
					arrErrors.push(JoyentL10n['The password and confirmation must match.']);
				// only required for admins
				if ($('person_admin') && $('person_admin').checked && $('person_recovery_email') && $F('person_recovery_email').strip() == '')
					arrErrors.push(JoyentL10n['Password recovery email address can not be blank.']);
        if ($F('person_username').length > 0 && ! $F('person_username').match(nameRegex))
          arrErrors.push(JoyentL10n['The username only can contain the characters a-z, 0-9, and _.']);
        if ($F('person_username').length > 50)
          arrErrors.push(JoyentL10n['The username can be no more than 50 characters.']);
        if ($F('person_password').length < 4)
          arrErrors.push(JoyentL10n['The password can be no less than 4 characters.']);
			}
		// editing guest
		} else if ($('person_account_type') && $F('person_account_type') == 'guest') {
			// recovery email must be set
			if ($('person_guest_recovery_email') && $F('person_guest_recovery_email').strip() == '')
				arrErrors.push(JoyentL10n['Password recovery email address can not be blank.']);
		// editing user or admin
		} else if ($('person_account_type') && ($F('person_account_type') == 'user' || $F('person_account_type') == 'admin')) {
			// if any user-filled part of the form is filled out..
			if (($('person_password') && $F('person_password') != '') ||
	 			  ($('person_password_confirmation') && $F('person_password_confirmation') != '') ||
				  ($('person_admin') && $('person_admin').enabled && $('person_admin').checked)) {
				// ..then make sure every required part is valid
				if ($F('person_password').strip() == '')
					arrErrors.push(JoyentL10n['The password can not be blank.']);
				if ($F('person_password').strip() != $F('person_password_confirmation').strip())
					arrErrors.push(JoyentL10n['The password and confirmation must match.']);
        if ($F('person_password').length < 4)
          arrErrors.push(JoyentL10n['The password can be no less than 4 characters.']);
			}
			// only required for admins
			if ($('person_admin') && $('person_admin').checked && $('person_recovery_email') && $F('person_recovery_email').strip() == '')
				arrErrors.push(JoyentL10n['Password recovery email address can not be blank.']);
		}

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
	},

  validateSubmitImport: function(form) {
  	arrErrors = [];

	  if (form.vcard.value.strip() == "") arrErrors.push(JoyentL10n['You must select a file to import.']);

	  if (validateErrorsArray(arrErrors)) {
	    preventFormResubmission(form);
	    return true;
	  } else {
	    return false;
	  }
	},

	toggleResetGuestPassword: function() {
		$('personAccountGuestResetPassword').toggle();
		$('person_guest_send_email').value = $F('person_guest_recovery_email');
		$('person_guest_send_email').activate();
	},

	submitResetGuestPassword: function(url) {
	  var arrErrors = [];

		if ($F('person_guest_send_email').strip() == '')
			arrErrors.push('The email address can not be blank.');

		if (! $F('person_guest_send_email').match(/.+@.+\..+/))
			arrErrors.push('The email address must be valid.');

	  if (validateErrorsArray(arrErrors)) {
			url = url + '&person_guest_send_email=' + $F('person_guest_send_email');
			window.location = url;
	    return true;
	  } else {
	    return false;
	  }
	},

	addPhoneNumber: function() {
		index = People.getNewIndex('arrPersonPhoneNumberIndexes');
		new Ajax.Request('/people/add_phone_number?index=' + index, {asynchronous:true, evalScripts:true, 
			onFailure:function(request){ People.removeNewIndex('arrPersonPhoneNumberIndexes', index); }});
		return false;
	},
	
	addEmailAddress: function() {
		index = People.getNewIndex('arrPersonEmailAddressIndexes');
		new Ajax.Request('/people/add_email_address?index=' + index, {asynchronous:true, evalScripts:true,
		  onFailure:function(request){ People.removeNewIndex('arrPersonEmailAddressIndexes', index); }});
		return false;
	},
	
	addAddress: function() {
		index = People.getNewIndex('arrPersonAddressIndexes');
		new Ajax.Request('/people/add_address?index=' + index, {asynchronous:true, evalScripts:true, 
			onFailure:function(request){ People.removeNewIndex('arrPersonAddressIndexes', index); }});
		return false;
	},
	
	addImAddress: function() {
		index = People.getNewIndex('arrPersonImAddressIndexes');
		new Ajax.Request('/people/add_im_address?index=' + index, {asynchronous:true, evalScripts:true, 
			onFailure:function(request){ People.removeNewIndex('arrPersonImAddressIndexes', index); }});
		return false;
	},
	
	addWebsite: function() {
		index = People.getNewIndex('arrPersonWebsiteIndexes');
		new Ajax.Request('/people/add_website?index=' + index, {asynchronous:true, evalScripts:true, 
			onFailure:function(request){ People.removeNewIndex('arrPersonWebsiteIndexes', index); }});
		return false;
	},
	
	addSpecialDate: function() {
		index = People.getNewIndex('arrPersonSpecialDateIndexes');
		new Ajax.Request('/people/add_special_date?index=' + index, {asynchronous:true, evalScripts:true, 
			onFailure:function(request){ People.removeNewIndex('arrPersonSpecialDateIndexes', index); }});
		return false;
	},

	// index this from 0
	// pass in indexes name as a string since we can't pass by reference
	getNewIndex: function(indexes_name) {
		indexes = eval(indexes_name);
		if (indexes.length > 0) {
			new_index = indexes[indexes.length - 1] + 1;
		} else {
			new_index = 0;
		}
		indexes.push(new_index);
		return new_index;
	},

	// pass in indexes name as a string since we can't pass by reference
	removeNewIndex: function(indexes_name, index) {
		indexes = eval(indexes_name);
		if (indexes.include(index)) indexes.splice(indexes.indexOf(index), 1)[0];
	},

	markAsPrimary: function(id, collection_name) {
	  // unset all the collection's selected's class, title, + value
	  $$('tbody#' + collection_name + ' div.primaryItem input').each(function(item){
	    item.value = 'false';
	  });
	  $$('tbody#' + collection_name + ' div.primaryItem').each(function(item){
	    item.removeClassName('primaryItem');
	    item.addClassName('makePrimaryItem');
	    item.setAttribute('title', JoyentL10n['Mark as primary']);
	  });
	  // set the new class, title, + value
	  $(id).removeClassName('makePrimaryItem');
	  $(id).addClassName('primaryItem');
	  $(id).setAttribute('title', JoyentL10n['Currently marked as primary']);
	  $(id.substr(0, id.length - 4)).value = 'true';
	},

	setPersonContactAccount: function() {
		People.resetPersonAccountGuest();
		People.resetPersonAccountUser();
		if (! $('personContactAccount').visible()) Effect.BlindDown('personContactAccount', { duration: Joyent.effectsDuration });
	},

	setPersonGuestAccount: function() {
		People.resetPersonAccountContact();
		People.resetPersonAccountUser();
		if (! $('personGuestAccount').visible()) Effect.BlindDown('personGuestAccount', { duration: Joyent.effectsDuration });
	},

	setPersonUserAccount: function() {
		People.resetPersonAccountContact();
		People.resetPersonAccountGuest();
		if (! $('personUserAccount').visible()) Effect.BlindDown('personUserAccount', { duration: Joyent.effectsDuration });
	},

	resetPersonAccountContact: function() {
		if ($('personContactAccount').visible()) Effect.BlindUp('personContactAccount', { duration: Joyent.effectsDuration });
	},
	
	resetPersonAccountGuest: function() {
		if ($('personGuestAccount').visible()) Effect.BlindUp('personGuestAccount', { duration: Joyent.effectsDuration });
		$('person_guest_username').value = '';
		$('person_guest_recovery_email').value = '';
		$('person_guest_readwrite').checked = false;
	},

	resetPersonAccountUser: function() {
		if ($('personUserAccount').visible()) Effect.BlindUp('personUserAccount', { duration: Joyent.effectsDuration });
		$('person_username').value = '';
		$('person_password').value = '';
		$('person_password_confirmation').value = '';
		$('person_recovery_email').value = '';
		$('person_admin').checked = false;
	},
		
/*
	  setRandomPassword: function(section) {
		password = People.generateRandomPassword();
		$(section + '_person_password').value = password;
		$(section + '_person_password_confirmation').value = password;
		new Effect.Highlight(section + '_person_password');
		new Effect.Highlight(section + '_person_password_confirmation');
	},
	
	generateRandomPassword: function() {
		password_length = 10;
	  chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890";
	  password = "a";

		for (var i = 0; i < password_length; i++) {
			password += chars.charAt(Math.floor(Math.random() * chars.length));
		}

	  return password;
	},
*/

	getEditEmailAddresses: function() {
		addresses = [];
		$$('tbody#person_email_addresses input[type=text]').each(function(element){
			if (element.value.strip() != '') addresses.push(element.value);
		});
		return addresses;
	},
	
	drawEmailNoticeSelect: function() {
		if (!(container = $('personRecoveryEmailSelectContainer'))) return;
    var currentAddress = '';

		if (e = $('person_recovery_email')) {
		  currentAddress = e.value;
		} else if (People.currentRecoveryEmail != '') {
			currentAddress = People.currentRecoveryEmail;
		}
		emailAddresses = People.getEditEmailAddresses().reject(function(address){
			return address.strip() == '';
		}).sortBy(function(address){
			return address;
		});
		
		container.update('');
		contents = '';
		contents += '<select id="person_recovery_email" name="person[recovery_email]" style="width:280px;">';
		contents += '<option></option>';
		emailAddresses.each(function(address){
			contents += '<option ';
			if (currentAddress == address) contents += 'selected="selected" ';
			contents += 'value="' + address + '">' + address + '</option>';
		});
    contents += '</select>';
		container.update(contents);
	},

	drawEditForwardSelect: function() {
    forwardAddress = (e = $('person_forward_address')) ? e.value : '';
    emailAddresses = People.getEditEmailAddresses().reject(function(address){
      return address.strip() == '';
    }).reject(function(address){
      return People.currentSpecialEmailAddresses.include(address.strip());
    });

    container = $('personEmailForwardSelectContainer');
    container.update('');
    contents = '';

    contents += '<select id="person_forward_address" name="person[forward_address]">';
    contents += '<optgroup label="Don\'t Forward Email:"><option value="">';
    contents += 'Do not forward email';
    contents += '</option></optgroup>';
    contents += '<optgroup label="Forward Email:">';
    emailAddresses.each(function(address){
      contents += '<option ';
      if (forwardAddress == address)
        contents += 'selected="" ';
      contents += 'value="' + address + '">' + address + '</option>';
    });        
    contents += '</optgroup>';
    contents += '</select>';

    container.update(contents);
  }

}

var JajahDrawer = {
  refresh: function() {
    if (! Item.selectedCopyable()) return;

    var ids = Item.findSelected().collect(function(item){ return item.arId; }).join(",");
		new Ajax.Updater('to_numbers', '/people/call_list?ids=' + ids, { asynchronous:true, evalScripts:true });
  }
}

var NotificationsConfigurator = {
  update: function(method) {
		if (!(container = $('person_notification_' + method + '_area'))) return;

    if ($('person_notification_' + method).checked) {
      container.update(NotificationsConfigurator.drawSelect(method));
      if (! container.visible()) {
        Effect.BlindDown(container, { duration: Joyent.effectsDuration });
      }
    } else {
      if (container.visible()) {
        Effect.BlindUp(container, { duration: Joyent.effectsDuration, afterFinish: function() {
          container.update('');
        } });
      }
    }
    return false;
  },
  
  drawSelect: function(method) {
    draw = '';

    switch (method) {
      case 'sms':
        var rowValues = $$('input.person_phone_number').collect(function(item){
          return item.value;
        });

        var currentSMS = '';
    		if (e = $('person_notifier_sms')) {
    		  currentSMS = e.value;
    		} else if (People.currentNotifierSMS != '') {
    			currentSMS = People.currentNotifierSMS;
    		}

        draw += '<select id="person_notifier_sms" name="person[notifier_sms]" style="width:200px;">';
    		rowValues.each(function(rowValue){
    			draw += '<option ';
    			if (People.currentNotifierSMS == rowValue) draw += 'selected="selected" ';
    			draw += 'value="' + rowValue + '">' + rowValue + '</option>';
    		});
        draw += '</select> ';
        draw += '<select id="person_notifier_sms_provider" name="person[notifier_sms_provider]" style="width:200px;">';

        People.providers.each(function(provider){
          draw += '<option ';
          if (People.currentNotifierSMSProvider == provider[0]) draw += 'selected="selected" ';
          draw += 'value="' + provider[0] + '">' + provider[1] + '</option>';
        });
        draw += '</select>';

        return draw;
        break;
      case 'email':
        var rowValues = $$('input.person_email_address').collect(function(item){
          return item.value;
        });

        var currentEmail = '';
    		if (e = $('person_notifier_email')) {
    		  currentEmail = e.value;
    		} else if (People.currentNotifierEmail != '') {
    			currentEmail = People.currentNotifierEmail;
    		}

        draw += '<select id="person_notifier_email" name="person[notifier_email]" style="width:200px;">';
    		rowValues.each(function(rowValue){
    			draw += '<option ';
    			if (People.currentNotifierEmail == rowValue) draw += 'selected="selected" ';
    			draw += 'value="' + rowValue + '">' + rowValue + '</option>';
    		});
        draw += '</select>';
        return draw;
        break;
      case 'im':
        var rowValues = $$('input.person_im_address').select(function(item){
          var itemId = item.id.match(/[0-9]/);
          if (itemId) {
            var typeItem = $('person_im_addresses_' + itemId.first() + '_im_type');
            if (typeItem.value == 'Jabber') {
              return true;
            } else {
              return false;
            }
            return true;
          } else {
            return false;
          }
        }).collect(function(item){
          return item.value;
        });

        var currentIM = '';
    		if (e = $('person_notifier_im')) {
    		  currentIM = e.value;
    		} else if (People.currentNotifierIM != '') {
    			currentIM = People.currentNotifierIM;
    		}

        draw += '<select id="person_notifier_im" name="person[notifier_im]" style="width:200px;">';
    		rowValues.each(function(rowValue){
    			draw += '<option ';
    			if (People.currentNotifierIM == rowValue) draw += 'selected="selected" ';
    			draw += 'value="' + rowValue + '">' + rowValue + '</option>';
    		});
        draw += '</select>';

        draw += '<p>';
        draw += JoyentL10n["To receive Jabber notifications add 'notifier@joyent.com' to your IM client contacts."];
        draw += '</p>';
        
        return draw;
        break;
      default:
        return '';
    }
  }
}

var EditAccountArea = {
  toggle: function() {
    if ($('show_edit_account').hasClassName('expanded')) { // collapse
      $('show_edit_account').removeClassName('expanded');
      if ($('person_user_account_area').visible())
        Effect.BlindUp('person_user_account_area', { duration: Joyent.effectsDuration });
    } else { // expand
      $('show_edit_account').addClassName('expanded');
      if (! $('person_user_account_area').visible())
        Effect.BlindDown('person_user_account_area', { duration: Joyent.effectsDuration });
    }
  }
}
