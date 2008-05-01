/*
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
*/

var SubscriptionGroup = {

	newShow: function(name) {
		$('addGroup').hide();
	  $('group_name').value = JoyentL10n['New '] + 'ICS Subscription';

	  Effect.BlindDown('addSubscriptionGroupDialog', { duration: Joyent.effectsDuration, afterFinish: function(){
			$('group_name').activate();
		}});
	},
	
	newCancel: function() {
	  Effect.BlindUp('addSubscriptionGroupDialog', { duration: Joyent.effectsDuration, afterFinish: function(){ $('addGroup').show(); } });
	},

	newSubmit: function(form) {
	  arrErrors = [];

	  if (form['calendar_subscription[name]'].value.strip() == "") arrErrors.push(JoyentL10n['The group name can not be blank.']);
	
		if (form['calendar_subscription[url]'].value.strip() == "http://" || form['calendar_subscription[url]'].value.strip() == "https://" || form['calendar_subscription[url]'].value.strip() == "") arrErrors.push(JoyentL10n['The group url can not be blank.']);

	  if (validateErrorsArray(arrErrors)) {
	    preventFormResubmission(form);
			$('newICSSubscriptionLoading').show();
			new Ajax.Request(form.action, {asynchronous:true, evalScripts:true, parameters:Form.serialize(form)}); 
			return false;
	  } else {
	    return false;
	  }
	},

	toggleEditICSSettings: function() {
		Effect.toggle('subscriptionGroupEditICSSettings', 'blind', { duration: Joyent.effectsDuration, afterFinish: function() {
			$('calendar_subscription_name').activate();
		}});
		$('subscriptionGroupEditICSSettingsLink').toggleClassName('expanded');
	},

	// Maybe this should be into application.js
	// Leave it here for now.
	// Re-enable form submit buttons when something fails
	reEnableForm: function(form) {
				
		form = $(form);
		
	  // get the buttons
	  input_buttons = Form.getElements(form).findAll(function(form_element) {
	    return (form_element.type == 'button' || form_element.type == 'submit');
	  });

	  // re-enable them
	  input_buttons.each(function(input_button) {
	    input_button.enable();
	  });
		
		form.onsubmit = function(e) {
			return SubscriptionGroup.newSubmit(this);
		}
	
	},
	
	refresh: function(href) {
		new Ajax.Request(href, {asynchronous:true, evalScripts:true, onCreate: function(request){$('refreshICSSubscriptionLoading').addClassName('reload_button');}, onComplete: function(request){$('refreshICSSubscriptionLoading').removeClassName('reload_button');}});
		return false;
	}

}