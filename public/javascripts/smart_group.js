/*
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
*/

// smart groups new

var SmartGroup = {

  newTagIndexes: [],
  newAttributeIndexes: [],
	editTagIndexes: [],
	editAttributeIndexes: [],
	editTagOriginalIndexes: [],
	editAttributeOriginalIndexes: [],

	newContents: '',
	editContents: '',

	attributeDescriptions: [],

	// new smart group

	newShow: function() {
		$('addGroup').hide();
	  Effect.BlindDown('smartGroupNew', { duration: Joyent.effectsDuration, afterFinish: function(){
			$('smart_group_name').activate();
		} });
	},
	
	newCancel: function() {
	  Effect.BlindUp('smartGroupNew', { duration: Joyent.effectsDuration, afterFinish: function() {
			$('addGroup').show();
		} });

	  $('smart_group_name').value = JoyentL10n['New Smart'] + ' ' + Joyent.groupName;
	  $('smartGroupNew').innerHTML = SmartGroup.newContents;

		SmartGroup.newTagIndexes.each(function(index) {
			$('smartGroupNewTagAutoComplete_' + index.toString()).remove();
		});

	  SmartGroup.newTagIndexes = [];
	  SmartGroup.newAttributeIndexes = [];
	},
	
	newSubmit: function(form) {
	  arrErrors = [];

	  if (form.smart_group_name.value == "") arrErrors.push(JoyentL10n['The smart group name can not be blank.']);
	  if ((SmartGroup.newTagIndexes.length + SmartGroup.newAttributeIndexes.length) < 1) arrErrors.push(JoyentL10n['You must specify at least one tag or condition.']);

	  // make sure all displayed fields are filled in
	  var allFilled = true;
		SmartGroup.newTagIndexes.each(function(index) {
	    if (form.elements['tag[' + index.toString() + ']'].value.strip() == "") allFilled = false;
		});
		SmartGroup.newAttributeIndexes.each(function(index) {
	    if (form.elements['attribute[' + index.toString() + '][value]'].value.strip() == "") allFilled = false;
		});
	  if (!allFilled) arrErrors.push(JoyentL10n['No tag or condition fields may be blank.']);

	  if (validateErrorsArray(arrErrors)) {
	    preventFormResubmission(form);
	    return true;
	  } else {
	    return false;
	  }
	},

	newAddTag: function() {
	  if (SmartGroup.newTagIndexes.length > 0) {
	    new_index = SmartGroup.newTagIndexes.last() + 1;
	  } else {
	    new_index = 1;
	  }
	  SmartGroup.newTagIndexes.push(new_index);
	  new Insertion.Bottom('smartGroupNewTagList', SmartGroup.tagRow('smartGroupNewTag', new_index, 'SmartGroup.newRemoveTag'));
	  Effect.BlindDown('smartGroupNewTagRow_' + new_index.toString(), { duration: Joyent.effectsDuration, afterFinish: function(){ 
			$('smartGroupNewTag_' + new_index.toString()).activate();
		} });

	  new Insertion.Bottom(document.body, '<div class="autocompleteMenu" id="smartGroupNewTagAutoComplete_' + new_index.toString() + '"></div>');
	  new Ajax.Autocompleter('smartGroupNewTag_' + new_index.toString(), 'smartGroupNewTagAutoComplete_' + new_index.toString(), '/tag/auto_complete', {});
	},

	newRemoveTag: function(index) {
		if (SmartGroup.newTagIndexes.include(index)) {
			index_pos = SmartGroup.newTagIndexes.indexOf(index);
	    remove_index = SmartGroup.newTagIndexes.splice(index_pos, 1)[0];
	    Effect.BlindUp('smartGroupNewTagRow_' + remove_index.toString(), { duration: Joyent.effectsDuration, afterFinish: function(){
				$('smartGroupNewTagRow_' + remove_index.toString()).remove();
				$('smartGroupNewTagAutoComplete_' + remove_index.toString()).remove();
			} });
	  }
	},

	newAddAttribute: function() {
	  if (SmartGroup.newAttributeIndexes.length > 0) {
	    new_index = SmartGroup.newAttributeIndexes.last() + 1;
	  } else {
	    new_index = 1;
	  }
	  SmartGroup.newAttributeIndexes.push(new_index);
	  new Insertion.Bottom('smartGroupNewAttributeList', SmartGroup.attributeRow('smartGroupNewAttribute', new_index, 'SmartGroup.newRemoveAttribute'));
	  Effect.BlindDown('smartGroupNewAttributeRow_' + new_index.toString(), { duration: Joyent.effectsDuration, afterFinish: function() { 
			$('smartGroupNewAttributeText_' + new_index.toString()).activate();
		} });
	},

	newRemoveAttribute: function(index) {
		if (SmartGroup.newAttributeIndexes.include(index)) {
			index_pos = SmartGroup.newAttributeIndexes.indexOf(index);
	    remove_index = SmartGroup.newAttributeIndexes.splice(index_pos, 1)[0];
	    Effect.BlindUp('smartGroupNewAttributeRow_' + remove_index.toString(), { duration: Joyent.effectsDuration, afterFinish: function() {
		  	$('smartGroupNewAttributeRow_' + remove_index.toString()).remove();
			} });
	  }
	},

	// edit smart group

	editToggle: function() {
		if ($('smartGroupEdit').visible()) {
			SmartGroup.editCancel();
		} else {
			SmartGroup.editShow();
		}
	},

	editShow: function() {
		// reset the dialog
	  $('smartGroupEdit').innerHTML = SmartGroup.editContents;
	  // remove the old divs
		SmartGroup.editTagIndexes.each(function(index) {
			if (e = $('smartGroupEditTagAutoComplete_' + index.toString())) e.remove();
		});
	  SmartGroup.editTagIndexes = SmartGroup.editTagOriginalIndexes;
	  SmartGroup.editAttributeIndexes = SmartGroup.editAttributeOriginalIndexes;
	  // create + auto_complete init the new divs
		SmartGroup.editTagOriginalIndexes.each(function(index) {
			if ($('smartGroupEditTag_' + index.toString())) {
	    	new Insertion.Bottom(document.body, '<div class="autocompleteMenu" id="smartGroupEditTagAutoComplete_' + index.toString() + '"></div>');
	    	new Ajax.Autocompleter('smartGroupEditTag_' + index.toString(), 'smartGroupEditTagAutoComplete_' + index.toString(), '/tag/auto_complete', {paramName: 'tag_name'});
			}
		});

		$('smartGroupSelectedEditDivBL').removeClassName('roundbl');
		$('smartGroupSelectedEditDivBR').removeClassName('roundbr');
		Effect.BlindDown('smartGroupEdit', { duration: Joyent.effectsDuration });

		dinger = $('smartGroupSelectedEditDinger');
    dinger.removeClassName("collapsed");
    dinger.addClassName("expanded");

		return false;
	},
	
	editCancel: function() {
	  Effect.BlindUp('smartGroupEdit', { duration: Joyent.effectsDuration, afterFinish: function(){
			$('smartGroupSelectedEditDivBL').addClassName('roundbl');
			$('smartGroupSelectedEditDivBR').addClassName('roundbr');
		} });

		dinger = $('smartGroupSelectedEditDinger');
    dinger.removeClassName("expanded");
    dinger.addClassName("collapsed");

		return false;
	},

	editSubmit: function(form) {
	  arrErrors = [];

	  if ((SmartGroup.editTagIndexes.length + SmartGroup.editAttributeIndexes.length) < 1) arrErrors.push(JoyentL10n['You must specify at least one tag or condition.']);

	  // make sure all displayed fields are filled in
	  var allFilled = true;
		SmartGroup.editTagIndexes.each(function(index) {
			if (form.elements['tag[' + index.toString() + ']'].value.strip() == "") allFilled = false;
		});
		SmartGroup.editAttributeIndexes.each(function(index) {
	    if (form.elements['attribute[' + index.toString() + '][value]'].value.strip() == "") allFilled = false;
		});
	  if (!allFilled) arrErrors.push(JoyentL10n['No tag or condition fields may be blank.']);

	  if (validateErrorsArray(arrErrors)) {
	    preventFormResubmission(form);
	    return true;
	  } else {
	    return false;
	  }
	},

	editAddTag: function() {
	  if (SmartGroup.editTagIndexes.length > 0) {
	    new_index = SmartGroup.editTagIndexes.last() + 1;    
	  } else {
	    new_index = 1;
	  }
	  SmartGroup.editTagIndexes.push(new_index);
	  new Insertion.Bottom('smartGroupEditTagList', SmartGroup.tagRow('smartGroupEditTag', new_index, 'SmartGroup.editRemoveTag'));
	  Effect.BlindDown('smartGroupEditTagRow_' + new_index.toString(), { duration: Joyent.effectsDuration, afterFinish: function(){
			new Insertion.Bottom(document.body, '<div class="autocompleteMenu" id="smartGroupEditTagAutoComplete_' + new_index.toString() + '"></div>');
			new Ajax.Autocompleter('smartGroupEditTag_' + new_index.toString(), 'smartGroupEditTagAutoComplete_' + new_index.toString(), '/tag/auto_complete', {});
		} });
	},

	editRemoveTag: function(index) {
		if (SmartGroup.editTagIndexes.include(index)) {
			index_pos = SmartGroup.editTagIndexes.indexOf(index);
	    remove_index = SmartGroup.editTagIndexes.splice(index_pos, 1)[0];
	    Effect.BlindUp('smartGroupEditTagRow_' + remove_index.toString(), { duration: Joyent.effectsDuration, afterFinish: function(){ 
				$('smartGroupEditTagRow_' + remove_index.toString()).remove();
				$('smartGroupEditTagAutoComplete_' + remove_index.toString()).remove();
			} });
	  }		
	},

	editAddAttribute: function() {
	  if (SmartGroup.editAttributeIndexes.length > 0) {
	    new_index = SmartGroup.editAttributeIndexes.last() + 1;    
	  } else {
	    new_index = 1;
	  }
	  SmartGroup.editAttributeIndexes.push(new_index);
	  new Insertion.Bottom('smartGroupEditAttributeList', SmartGroup.attributeRow('smartGroupEditAttribute', new_index, 'SmartGroup.editRemoveAttribute'));
	  Effect.BlindDown('smartGroupEditAttributeRow_' + new_index.toString(), { duration: Joyent.effectsDuration });
	},
	
	editRemoveAttribute: function(index) {
		if (SmartGroup.editAttributeIndexes.include(index)) {
			index_pos = SmartGroup.editAttributeIndexes.indexOf(index);
	    remove_index = SmartGroup.editAttributeIndexes.splice(index_pos, 1)[0];
	    Effect.BlindUp('smartGroupEditAttributeRow_' + remove_index.toString(), { duration: Joyent.effectsDuration, afterFinish: function(){
		  	$('smartGroupEditAttributeRow_' + remove_index.toString()).remove();
			} });
	  }
	},

	// html builders

	tagRow: function(prefix, index, remove_function_name) {
	  index = index.toString();
	  row = '';
	  row += '<div id="' + prefix + 'Row_' + index + '" style="display:none;">';
	  row += ' <a href="#" onclick="' + remove_function_name + '(' + index + '); return false;" class="smallRemoveLink">-</a> ';
	  row += JoyentL10n[' tag is<br />'];
	  row += '<input type="text" id="' + prefix + '_' + index + '" name="tag[' + index + ']" style="font-size:9px; width: 85%;" autocomplete="off" />';
	  // can't add autocomplete div here, positioning off
	  // can't add the autocomplete js here, it won't get executed
		row += '<hr />';
	  row += '</div>';
	  return row;
	},
	
	// specify a prefix (ie 'smartGroupNewAttribute')
	attributeRow: function(prefix, index, remove_function_name) {
	  index = index.toString();
	  row = '';
	  row += '<div id="' + prefix + 'Row_' + index + '" style="display:none;">';
	  row += '<table style="width: 100%;"><tr><td>';
	  row += ' <select name="attribute[' + index + '][key]" size="1" style="font-size:9px; width: 100%;">';
	  row += SmartGroup.attributeOptions();
	  row += '</select> ';
	  row += '</td><td rowspan="2">';
	  row += ' <a href="#" onclick="' + remove_function_name + '(' + index + '); return false;" class="smallRemoveLink">-</a> ';
	  row += '</td></tr><tr><td>';
	  row += JoyentL10n[' contains<br />'];
	  row += '<input id="' + prefix + 'Text_' + index + '" type="text" name="attribute[' + index + '][value]" style="font-size:9px; width: 90%; margin-top: 2px;" /> ';
	  row += '</td></tr></table>';
	  row += '<hr />';
	  row += '</div>';
	  return row;		
	},
	
	attributeOptions: function() {
	  if (!SmartGroup.attributeDescriptions) return "";
	  if (SmartGroup.attributeDescriptions.length == 0) return "";

		return SmartGroup.attributeDescriptions.collect(function(condition) {
	    return '<option value="' + condition[0] + '">' + condition[1] + '</option>';
		}).join('');		
	},
	
	// others'

	othersShow: function() {
	  $('selectedOtherGroup').hide();
	  $('editOtherGroupDialog').show();
	},

	othersCancel: function() {
	  $('editOtherGroupDialog').hide();
	  $('selectedOtherGroup').show();
	}

}
