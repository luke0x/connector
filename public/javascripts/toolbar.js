/*
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
*/

var Toolbar = {

	// call after item selection changes to enable/disable delete + move
	refresh: function() {
		setLink('actionCopyLink',   Item.selectedCopyable());
		setLink('actionMoveLink',   Item.selectedMoveable());
		setLink('actionEmailLink',  Item.selectedCopyable());
		setLink('actionDeleteLink', Item.selectedDeleteable());

		if (Joyent.applicationName == 'lists') {
			setLink('actionNewRowLink',    Item.selectedEditable());
			setLink('actionMoveUpLink',    List.selectedMoveUpable());
			setLink('actionMoveDownLink',  List.selectedMoveDownable());
			setLink('actionIndentLink',    List.selectedIndentable());
			setLink('actionOutdentLink',   List.selectedOutdentable());
			setLink('actionDeleteRowLink', Item.selectedEditable() && List.selectedRow);
			setLink('actionSpamLink',    Item.selectedMoveable());
			setLink('actionNotSpamLink', Item.selectedMoveable());
		}
		
		if ($('drawerJajah') != null) {
			setLink('actionJajahLink', Item.selectedCopyable());
		  JajahDrawer.refresh();
		}
	},

	deleteList: function(url) {
	  if (Item.findSelected().length == 0) {
	    alert(JoyentL10n["You must select something to delete."]);
	    return false;
	  }
		if (! Item.selectedDeleteable()) {
			alert(JoyentL10n["Not all selected items are deleteable."]);
			return false;
		}
	  if (! confirm(JoyentL10n['Do you want to delete the selected items?'])) return false;

		// delete everything that doesn't require an extra confirmation
		deleteIds = Item.findSelected().reject(function(item){
			return item.mustConfirmDelete;
		}).collect(function(item){
			return item.arId;
		}).join(',');
		if (deleteIds != '') {
			new Ajax.Request(url + '?ids=' + deleteIds, {asynchronous:true, evalScripts:true});
		}

		if (Item.selectedConfirmDelete()) {
			deleteIds = Item.findSelected().select(function(item){
				return item.mustConfirmDelete;
			}).collect(function(item){
				return item.arId;
			}).join(',');

			ModalDialog.showURL('/people/delete_confirm?ids=' + deleteIds);

			return false;
		}

		return false;
	},

	deleteItem: function(link, url) {
		if (! Item.selectedDeleteable()) {
			alert(JoyentL10n["This item is not deleteable."]);
			return false;
		}
	  if (! confirm(JoyentL10n['Do you want to delete this item?'])) return false;

		if (Item.selectedConfirmDelete()) {
		  deleteId = Item.findSelected().first().arId;
			ModalDialog.showURL('/people/delete_confirm?ids=' + deleteId);
		} else {
			if (Joyent.viewKind == 'strongspace') {
			  deleteId = Item.findSelected().reject(function(item){
					return item.mustConfirmDelete;
				}).collect(function(item){
					if (Joyent.viewKind == 'strongspace') {
					  return item.path;
					} else {
						return item.arId;
					}
				}).join(',');
			} else {
			  deleteId = Item.findSelected().first().arId;
			}
			var f = document.createElement('form');
			link.parentNode.appendChild(f);
			f.method = 'POST';
			f.action = url + '?ids=' + deleteId;
			f.submit();
		}

		return false;
	},
	
	contactsCallList: function(form) {
	  $('toolbarCallIDs').value = Item.findSelected().collect(function(item){ return item.arId; }).join(",");
	  return true;
	},

	contactsCopySubmit: function(form) {
	  if (Item.findSelected().length == 0) {
	    alert(JoyentL10n["You must select something to copy."]);
	    return false;
	  }
	  if (!confirm(JoyentL10n['Do you want to copy the selected people to your contacts?'])) {
	    return false;
	  }
	  $('toolbarCopyIDs').value = Item.findSelected().collect(function(item){ return item.arId; }).join(",");
	  preventFormResubmission(form);
	  return true;
	},

	bookmarksCopySubmit: function(form) {
	  if (Item.findSelected().length == 0) {
	    alert(JoyentL10n["You must select something to copy."]);
	    return false;
	  }
	  if (!confirm(JoyentL10n['Do you want to copy the selected bookmarks to your bookmarks?'])) {
	    return false;
	  }
	  $('toolbarCopyIDs').value = Item.findSelected().collect(function(item){ return item.arId; }).join(",");
	  preventFormResubmission(form);
	  return true;
	},
	
	moveSubmit: function(form)	{
		$('toolbarMoveGroupID').value = browser.selected;
	  
		if (Item.findSelected().length == 0) {
		    alert(JoyentL10n["You must select something to move it to another group."]);
		    return false;
		}
		if (Joyent.viewKind != 'strongspace' && $('toolbarMoveGroupID').value == "") {
		    alert(JoyentL10n["You must select a group to move items to."]);
		    return false;
		}

		if (Joyent.viewKind == 'strongspace') {
		  $('toolbarMoveIDs').value = Item.findSelected().collect(function(item){ return item.path; }).join(",");
		} else {
		  $('toolbarMoveIDs').value = Item.findSelected().collect(function(item){ return item.arId; }).join(",");
		}
	 	
		preventFormResubmission(form);
		return true;
	},
	
  copySubmit: function(form)	{
		$('toolbarCopyGroupID').value = browser.selected;

		if (Item.findSelected().length == 0) {
		  alert(JoyentL10n["You must select something to copy it to another group."]);
		  return false;
		}
		if (Joyent.viewKind != 'strongspace' && $('toolbarCopyGroupID').value == "") {
		  alert(JoyentL10n["You must select a group to copy items to."]);
		  return false;
		}

		if (Joyent.viewKind == 'strongspace') {
			$('toolbarCopyIDs').value = Item.findSelected().collect(function(item){ return item.path; }).join(",");
		} else {
			$('toolbarCopyIDs').value = Item.findSelected().collect(function(item){ return item.arId; }).join(",");
		}
   
		preventFormResubmission(form);
		return true;
	},

  emailSubmit: function(form)	{
	  if (Item.findSelected().length == 0) {
	    alert(JoyentL10n["You must select something in order to include it as an attachment."]);
	    return false;
	  }

		if (Joyent.viewKind == 'strongspace') {
			$('toolbarEmailIDs').value = Item.findSelected().collect(function(item){ return item.path; }).join(",");
		} else {
			$('toolbarEmailIDs').value = Item.findSelected().collect(function(item){ return item.arId; }).join(",");
		}
	
	  preventFormResubmission(form);
	  return true;
	},
	
	markAsSpam: function(linkElement, url) {
    	if (! Item.selectedMoveable()) {
    	    alert(JoyentL10n["The selected item(s) can not be marked as spam."]);
    		return false;
    	}

		if (Joyent.viewKind == 'list') {
			itemIds = Item.findSelected().collect(function(item){
				return item.arId;
			}).join(',');
			if (itemIds != '') new Ajax.Request(url + '?ids=' + itemIds, {asynchronous:true, evalScripts:true});
		} else {
			var f = document.createElement('form');
			linkElement.parentNode.appendChild(f);
			f.method = 'POST';
		  itemId = Item.findSelected().first().arId;
			f.action = url + '?ids=' + itemId;
			f.submit();
		}

		return false;
    },
    	
	markAsNotSpam: function(linkElement, url) {
		if (! Item.selectedMoveable()) {
			alert(JoyentL10n["The selected item(s) can not be marked as not spam."]);
			return false;
		}

		if (Joyent.viewKind == 'list') {
			itemIds = Item.findSelected().collect(function(item){
				return item.arId;
			}).join(',');
			if (itemIds != '') new Ajax.Request(url + '?ids=' + itemIds, {asynchronous:true, evalScripts:true});
		} else {
			var f = document.createElement('form');
			linkElement.parentNode.appendChild(f);
			f.method = 'POST';
		  itemId = Item.findSelected().first().arId;
			f.action = url + '?ids=' + itemId;
			f.submit();
		}

		return false;
 	}
}
