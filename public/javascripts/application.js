/*
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
*/


var Joyent = {
	loadingMessageLarge: '<div class="loadingMessageLarge">&nbsp;</div>',
	loadingMessageSmall: JoyentL10n['<div class="loadingMessageSmall">Loading&hellip;</div>'],
	effectsDuration: 0.15, // also set in ruby
	applicationName: '',
  groupName: '',
  viewKind: ''
}

var JoyentPage = {
	// sidebar on create info
	createTags: [],
	pendingAddTags: [],
	pendingRemoveTags: [],
	createPermissions: [],
	createNotifications: [],

	hideEverything: function() {
		DeveloperTools.hide();
		MenuItems.hide();
		AddGroupWidget.hide();
		PageOverlay.hide();
		ModalDialog.hide();
		return false;
	},

	// call when a list view checkbox is clicked
	toggleItemCheckbox: function(checkbox) {
	  // refresh values
		var item = Item.find(checkbox.readAttribute('itemDomId'));
		Item.update(item, 'selected', checkbox.checked);

	  JoyentPage.refresh();
	},

	// set all checkboxes in the list
	setItemCheckboxes: function() {
		mode = 'all_toggle'; // can be: 'all', 'none', 'toggle', 'all_toggle'
	  var checkboxes = $$('div#contentPane input.listCheckbox[type=checkbox]');

	  if (mode == 'all_toggle') {
			checkedCheckboxes = checkboxes.select(function(checkbox){ return checkbox.checked; });
	    mode = (checkboxes.length == checkedCheckboxes.length) ? 'none' : 'all';
	  }

	  checkboxes.each(function(checkbox) {
			var item = Item.find(checkbox.readAttribute('itemDomId'));
	    if (mode == 'all') {
        checkbox.checked = true;
				Item.update(item, 'selected', true);
	    } else if (mode == 'none') {
        checkbox.checked = false;
				Item.update(item, 'selected', false);
	    } else if (mode == 'toggle') {
	      checkbox.checked = ! checkbox.checked;
				Item.update(item, 'selected', checkbox.checked);
	    }
	  });

		JoyentPage.refresh();
	},

	// re-set the state of the list header checkbox
	refreshItemCheckboxesHeader: function() {
		if (!(e = $('listCheckboxToggle'))) return;
	  e.removeClassName('all').removeClassName('none').removeClassName('some');

		if (Item.findSelected().length == 0) {
			e.addClassName('none');
		} else if (Item.findSelected().length == Item.findAll().length) {
			e.addClassName('all');
		} else {
			e.addClassName('some');
		}
	},
	
  refresh: function() {
		JoyentPage.refreshItemCheckboxesHeader();
		Toolbar.refresh();
		Drawers.refresh();
		Sidebar.refresh();
		return false;
	},
	
	restripe: function() {
	  if (!(element = $('tableList')) && !(element = $('notificationsTable'))) return;
		rows = $$('table#' + element.id + ' tbody tr.itemRow');

		rows.each(function(row, index){
			if ((index + 1) % 2 == 0) {
				row.removeClassName('evenRow').addClassName('oddRow');
				row.next('tr').removeClassName('evenRow').addClassName('oddRow');
			} else {
				row.removeClassName('oddRow').addClassName('evenRow');
				row.next('tr').removeClassName('oddRow').addClassName('evenRow');
			}
		});
	},
	
	refreshPagination: function() {
    if (total = $('paginationTotalCount')) total.innerHTML = parseInt(total.innerHTML) - 1;

		if (Joyent.viewKind == 'notifications') {
			if (end = $('paginationPageEnd'))
				end.innerHTML = Notification.findAll().length == 0 ? '0' : parseInt(end.innerHTML) - 1;
	    if ((start = $('paginationPageStart')) && (Notification.findAll().length == 0))
				start.innerHTML = '0';
		} else {
			if (end = $('paginationPageEnd'))
				end.innerHTML = Item.findAll().length == 0 ? '0' : parseInt(end.innerHTML) - 1;
	    if ((start = $('paginationPageStart')) && (Item.findAll().length == 0))
				start.innerHTML = '0';
		}
	}

}

// pass in an array of strings
// if the array is empty return true (this is a valid error array--no errors)
// otherwise alert the errors as a numbered list
function validateErrorsArray(arrErrors) {
	if (arrErrors.length == 0) return true;

  // prepend a count for multiple error messages
  if (arrErrors.length > 1) {
		arrErrors.each(function(item, index){
			arrErrors[index] = (index + 1).toString() + ". " + arrErrors[index];
		});
  }
  alert(arrErrors.join("\n"));

  return false;
}

// prevent the form from being submitted more than once
function preventFormResubmission(form) {
  form = $(form);

  // get the buttons
  input_buttons = Form.getElements(form).findAll(function(form_element) {
    return (form_element.type == 'button' || form_element.type == 'submit');
  });

  // disable them
  input_buttons.each(function(input_button) {
    input_button = $(input_button);
    input_button.blur();
    input_button.disabled = 'true';
  });

  // clear the form's handler
  form.onsubmit = function(){ return false; };
}

// enable/disable links
function setLink(element, enabled) {
	var element;
  if (!(element = $(element))) return;

	if (enabled) {
  	element.disabled = false;
		element.removeClassName('disabled');
		if (element.oldOnClick) {
			element.onclick = element.oldOnClick;
//			delete element.oldOnClick;
			element.oldOnClick = undefined;
		}
	} else {
  	element.disabled = true;
		element.addClassName('disabled');
		if (! element.oldOnClick) element.oldOnClick = element.onclick;
		element.onclick = new Function("return false;");
	}
}

var UserOptions = {
	set: function(key, value) {
		params = 'key=' + key + '&value=' + value;
		new Ajax.Request('/user_options/set?' + params, { asynchronous:true, evalScripts:true });
	}
}

// Will perform an action based on 'checked' state of the element.
function performCheckboxToggleAction(element, checked_url, unchecked_url) {
  var url = element.checked ? checked_url : unchecked_url;
  new Ajax.Request(url, {asynchronous:true, evalScripts:true});
}

// http://jroller.com/page/rmcmahon?entry=resizingtextarea_with_prototype
var ResizingTextArea = Class.create();
ResizingTextArea.prototype = {
	defaultRows: 1,

	initialize: function(field) {
	  this.defaultRows = Math.max(field.rows, 1);
	  this.resizeNeeded = this.resizeNeeded.bindAsEventListener(this);
	  Event.observe(field, "click", this.resizeNeeded);
	  Event.observe(field, "keyup", this.resizeNeeded);
	},

	resizeNeeded: function(event) {
    var t = Event.element(event);
    var lines = t.value.split('\n');
    var newRows = lines.length + 1;
    var oldRows = t.rows;
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i];
      if (line.length >= t.cols) newRows += Math.floor(line.length / t.cols);
    }
    if (newRows > t.rows) t.rows = newRows;
    if (newRows < t.rows) t.rows = Math.max(this.defaultRows, newRows);
	}
}
