/*
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
*/

var DefaultGroup = {
	editToggle: function() {
		$('editDefaultGroupDialog').visible() ? DefaultGroup.editCancel() : DefaultGroup.editShow();
		return false;
	},

	editShow: function() {
		$('defaultGroupSelectedEditDivBL').removeClassName('roundbl');
		$('defaultGroupSelectedEditDivBR').removeClassName('roundbr');
		Effect.BlindDown('editDefaultGroupDialog', { duration: Joyent.effectsDuration });

		$('defaultGroupSelectedEditDinger').removeClassName("collapsed").addClassName("expanded");
		return false;
	},

	editCancel: function() {
	  Effect.BlindUp('editDefaultGroupDialog', { duration: Joyent.effectsDuration, afterFinish: function(){
			$('defaultGroupSelectedEditDivBL').addClassName('roundbl');
			$('defaultGroupSelectedEditDivBR').addClassName('roundbr');
		} });

		$('defaultGroupSelectedEditDinger').removeClassName("expanded").addClassName("collapsed");
		return false;
	}
}

var StandardGroup = {
	newShow: function() {
		$('addGroup').hide();
	  $('group_name').value = JoyentL10n['New '] + Joyent.groupName;

	  Effect.BlindDown('addGroupDialog', { duration: Joyent.effectsDuration, afterFinish: function(){
			$('group_name').activate();
		}});
	},

	newCancel: function() {
	  Effect.BlindUp('addGroupDialog', { duration: Joyent.effectsDuration, afterFinish: function(){ $('addGroup').show(); } });
	},

	newSubmit: function(form) {
	  arrErrors = [];

	  if (form.group_name.value.strip() == "") arrErrors.push(JoyentL10n['The group name can not be blank.']);

	  // extra tests for imap mailboxes
	  if (Joyent.applicationName == 'mail') {
	    if (form.group_name.value.indexOf('.') != -1) {
	      arrErrors.push(JoyentL10n['Mailbox names can not contain periods (.)']);
	    }
	  }

	  if (validateErrorsArray(arrErrors)) {
	    preventFormResubmission(form);
	    return true;
	  } else {
	    return false;
	  }
	},

	editToggle: function(group_id) {
		if ($('standardGroupSelectionEdit').visible()) {
			StandardGroup.editCancel(group_id);
		} else {
			StandardGroup.editShow(group_id);
		}
	},

	editShow: function(group_id) {
	  $('standardGroupSelectionEdit').update(standardGroupSelectionEditContents);

		$('standardGroupSelectedEditDivBL').removeClassName('roundbl');
		$('standardGroupSelectedEditDivBR').removeClassName('roundbr');
		Effect.BlindDown('standardGroupSelectionEdit', { duration: Joyent.effectsDuration });

		dinger = $('standard_group_edit_dinger_' + group_id.toString());
    dinger.removeClassName("collapsed");
    dinger.addClassName("expanded");

		return false;
	},

	editCancel: function(group_id) {
	  Effect.BlindUp('standardGroupSelectionEdit', { duration: Joyent.effectsDuration, afterFinish: function(){
			$('standardGroupSelectedEditDivBL').addClassName('roundbl');
			$('standardGroupSelectedEditDivBR').addClassName('roundbr');
		} });

		dinger = $('standard_group_edit_dinger_' + group_id.toString());
    dinger.removeClassName("expanded");
    dinger.addClassName("collapsed");

		return false;
	},

	editSubmit: function(form) {
	  arrErrors = [];

	  if (form.group_name && form.group_name.value.strip() == "")
			arrErrors.push(JoyentL10n['The group name can not be blank.']);
	  if (form.name && form.name.value.strip() == "")
			arrErrors.push(JoyentL10n['The group name can not be blank.']);

	  if (validateErrorsArray(arrErrors)) {
	    preventFormResubmission(form);
	    return true;
	  } else {
	    return false;
	  }
	},
	
	toggleEditRename: function() {
		Effect.toggle('standardGroupEditRename', 'blind', { duration: Joyent.effectsDuration, afterFinish: function() {
			$('standardGroupRenameName').activate();
		}});
		$('standardGroupEditRenameLink').toggleClassName('expanded');
	},
	
	toggleEditMove: function() {
		Effect.toggle('standardGroupEditMove', 'blind', { duration: Joyent.effectsDuration });
		$('standardGroupEditMoveLink').toggleClassName('expanded');
	},
	
	toggleEditAccess: function() {
		Effect.toggle('standardGroupEditAccess', 'blind', { duration: Joyent.effectsDuration });
		$('standardGroupEditAccessLink').toggleClassName('expanded');
	}, 
	
	toggleEditSubscriptions: function() {
		Effect.toggle('standardGroupEditSubscriptions', 'blind', { duration: Joyent.effectsDuration });
		$('standardGroupEditSubscriptionsLink').toggleClassName('expanded');
	},
	
	toggleEditMove: function() {
		Effect.toggle('standardGroupEditMove', 'blind', { duration: Joyent.effectsDuration });
		$('standardGroupEditMoveLink').toggleClassName('expanded');
	}
}

var AddGroupWidget = {
	toggle: function() {
		if ($('addGroupPlus').hasClassName('minus')) {
			JoyentPage.hideEverything();
		} else {
			AddGroupWidget.show();
		}
		return false;
	},

	show: function() {
		PageOverlay.showTransparent();
		$('addGroupMenu').show();
		$('addGroupPlus').addClassName('minus');
		return false;		
	},

	hide: function() {
		$('addGroupMenu').hide();
		$('addGroupPlus').removeClassName('minus');
		return false;
	},

	select: function(mode) {
		JoyentPage.hideEverything();
		if (mode == 'smart') {
			SmartGroup.newShow()
		} else if (mode == 'standard') {
			StandardGroup.newShow()
		}
		return false;
	}
}
