/*
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
*/

var MenuItems = {
	show: function() {
		PageOverlay.showTransparent();
		$('plusMenuContents').show();
		$('plusMenuLink').removeClassName('collapsed').addClassName('expanded');
		return false;		
	},

	hide: function() {
		if (! $('plusMenuContents').visible()) return false;
		new Effect.Fade('plusMenuContents', { duration:0.15 });
		$('plusMenuLink').removeClassName('expanded').addClassName('collapsed');
		return false;		
	},

	toggle: function() {
		if ($('plusMenuContents').visible()) {
			JoyentPage.hideEverything();
		} else {
			MenuItems.show();
		}
		return false;
	}
}


var DeveloperTools = {
	show: function() {
		PageOverlay.showTransparent();
		$('developerToolsContents').show();
		$('developerToolsLink').removeClassName('collapsed').addClassName('expanded');
		return false;		
	},

	hide: function() {
	  if (!(element = $('developerToolsContents'))) return;
		element.hide();
		$('developerToolsLink').removeClassName('expanded').addClassName('collapsed');
		return false;		
	},

	toggle: function() {
		if ($('developerToolsContents').visible()) {
			JoyentPage.hideEverything();
		} else {
			DeveloperTools.show();
		}
		return false;
	}
}

var Search = {
	init: function() {
		Event.observe('searchField', 'focus', function(event){ Search.select(); });
		Event.observe('searchField', 'blur', function(event){ Search.deselect(); });
		$('searchField').value = Search.text();
		Search.deselect();
	},

	select: function() {
		$('searchField').removeClassName('deselected').addClassName('selected');
		if ($('searchField').value == Search.text()) $('searchField').value = '';
	},

	deselect: function() {
		$('searchField').removeClassName('selected').addClassName('deselected');
		if ($('searchField').value == '') $('searchField').value = Search.text();
	},

	text: function() {
		return JoyentL10n['Search'];

		if (Joyent.applicationName == 'connect') {
			return JoyentL10n['Search All'];
		} else {
			return JoyentL10n['Search '] + Joyent.applicationName.capitalize();
		}
	}
}

var CollapsiblePalette = {
	show: function(element) {
	  if (!(element = $(element))) return;

		element.removeClassName('collapsed').addClassName('expanded');
		Effect.BlindDown(element.id + 'Inset', { duration: Joyent.effectsDuration });
	},
	
	hide: function(element) {
	  if (!(element = $(element))) return;

		element.removeClassName('expanded').addClassName('collapsed');
		Effect.BlindUp(element.id + 'Inset', { duration: Joyent.effectsDuration });
	},
	
	toggle: function(element) {
	  if (!(element = $(element))) return;

		if (element.hasClassName('expanded')) {
			CollapsiblePalette.hide(element);
		} else {
			CollapsiblePalette.show(element);
		}
	}
}

var PeekView = {
	toggle: function(updateId, url) {
		icon = $(updateId + '_td_details_icon');

	  if (icon.className == 'details') {
	    icon.className = 'detailsActivated';
	    $(updateId + '_td_details').innerHTML = Joyent.loadingMessageSmall;
	    $(updateId + '_tr_details').toggle();
	    new Ajax.Request(url, {asynchronous:true, evalScripts:true, method:'get', onFailure: function() {
		    $(updateId + '_td_details').update('Details currently unavailable');
			}});
		} else if (icon.className == 'notificationDetails details') {
	    icon.className = 'notificationDetailsActivated';
	    $(updateId + '_td_details').innerHTML = Joyent.loadingMessageSmall;
	    $(updateId + '_tr_details').toggle();
	    new Ajax.Request(url, {asynchronous:true, evalScripts:true, method:'get', onFailure: function() {
		    $(updateId + '_td_details').update('Details currently unavailable');
			}});
		} else if (icon.className == 'detailsActivated') {
	    $(updateId + '_tr_details').toggle();
	    icon.className = 'details';
	  } else if (icon.className == 'notificationDetailsActivated') {
	    $(updateId + '_tr_details').toggle();
	    icon.className = 'notificationDetails details';
	  }
	}
}

var CommentList = {
	toggle: function() {
		if ($('commentsExpanded').visible()) {
			Effect.BlindUp('commentsExpanded', { duration: Joyent.effectsDuration });
	    $('comments').removeClassName('CommentsExpanded').addClassName('CommentsCollapsed');
		} else {
			Effect.BlindDown('commentsExpanded', { duration: Joyent.effectsDuration });
	    $('comments').removeClassName('CommentsCollapsed').addClassName('CommentsExpanded');
			$('comment-body').activate();
		}

	  return false;
	}
}

var GroupsBrowser = {
	loadChildren: function(groupId) {
		update_id = "groups_standard_group_" + groupId;
		dinger = $("dinger_group_" + groupId);
		spinner = $('standard_group_spinner_' + groupId);
		edit_dinger = $('standard_group_edit_dinger_' + groupId);

		if (dinger.hasClassName('collapsed')) {
			if (edit_dinger) edit_dinger.hide();
			spinner.show();
			new Ajax.Updater(update_id, '/' + Joyent.applicationName + '/children_groups/' + groupId, {asynchronous:true, evalScripts:true, onComplete: function() { spinner.hide(); if (edit_dinger) edit_dinger.show(); }});
			dinger.removeClassName('collapsed');
			dinger.addClassName('expanded');
		} else {
			spinner.hide();
			if (edit_dinger) edit_dinger.show();
			$(update_id).innerHTML = '';
			dinger.removeClassName('expanded');
			dinger.addClassName('collapsed');
		}	
	},

	loadStrongspaceChildren: function(domId, path) {
		update_id = "groups_standard_group_" + domId;
		dinger = $("dinger_group_" + domId);
		spinner = $('standard_group_spinner_' + domId);
		edit_dinger = $('standard_group_edit_dinger_' + domId);

		if (dinger.hasClassName('collapsed')) {
			if (edit_dinger) edit_dinger.hide();
			spinner.show();
			new Ajax.Updater(update_id, '/' + Joyent.applicationName + '/strongspace_children_groups/' + path, {asynchronous:true, evalScripts:true, onComplete: function() { spinner.hide(); if (edit_dinger) edit_dinger.show(); }});
			dinger.removeClassName('collapsed');
			dinger.addClassName('expanded');
		} else {
			spinner.hide();
			if (edit_dinger) edit_dinger.show();
			$(update_id).innerHTML = '';
			dinger.removeClassName('expanded');
			dinger.addClassName('collapsed');
		}	
	},
	
	loadServiceChildren: function(serviceName, groupId) {
		update_id = "groups_standard_group_" + groupId;
		dinger = $("dinger_group_" + groupId);
		spinner = $('standard_group_spinner_' + groupId);
		edit_dinger = $('standard_group_edit_dinger_' + groupId);

		if (dinger.hasClassName('collapsed')) {
			if (edit_dinger) edit_dinger.hide();
			spinner.show();
			new Ajax.Updater(update_id, '/' + Joyent.applicationName + '/service_children_groups/' + serviceName + '/' + groupId, {asynchronous:true, evalScripts:true, onComplete: function() { spinner.hide(); if (edit_dinger) edit_dinger.show(); }});
			dinger.removeClassName('collapsed');
			dinger.addClassName('expanded');
		} else {
			spinner.hide();
			if (edit_dinger) edit_dinger.show();
			$(update_id).innerHTML = '';
			dinger.removeClassName('expanded');
			dinger.addClassName('collapsed');
		}	
	},
	
	showUser: function(userId) {
		content = $('groups_user_' + userId);
		dinger  = $('dinger_user_' + userId);

		$('groups_user_spinner_' + userId).show();
		dinger.removeClassName('collapsed').addClassName('expanded');

		new Ajax.Updater(content, '/' + Joyent.applicationName + '/others_groups?user_id=' + userId, {asynchronous:true, evalScripts:true, onComplete: function(){ $('groups_user_spinner_' + userId).hide(); }});
	},
	
	hideUser: function(userId) {
		content = $('groups_user_' + userId);
		dinger  = $('dinger_user_' + userId);

		$('groups_user_spinner_' + userId).hide();
		dinger.removeClassName('expanded').addClassName('collapsed');
		content.innerHTML = '';
	},

	toggleUser: function(userId) {
		dinger = $('dinger_user_' + userId);

		if (dinger.hasClassName('collapsed')) {
			GroupsBrowser.showUser(userId);
		} else {
			GroupsBrowser.hideUser(userId);
		}
	}
}

var Report = {
	hide: function(id) {
		$('report_body_' + id).hide();
	  $('hide_report_'+id).hide();
	  $('show_report_'+id).show();
	  return false;
	},
   
	show: function(id) {
		$('report_body_' + id).show();
	  $('hide_report_'+id).show();
	  $('show_report_'+id).hide();
	  return false;
	},

	hideAll: function() {
	  var children = $('report_list').childNodes;

	  for(var i = 0; i < children.length; i++) {
	    if (children.item(i).id.substr(0,6) == 'report') {  
	      var id = children.item(i).id.substr(7);
	      $('hide_report_'+id).onclick();
	    }
	  }
	  return false;
	},

	showAll: function() {
	  var children = $('report_list').childNodes;

	  for(var i = 0; i < children.length; i++) {
	    if (children.item(i).id.substr(0,6) == 'report') {  
	      var id = children.item(i).id.substr(7);
	      $('show_report_'+id).onclick();
	    }
	  }
	  return false;
	},

	refreshAll: function() {
	  var children = $('report_list').childNodes;

	  for(var i = 0; i < children.length; i++) {
	    if (children.item(i).id.substr(0,6) == 'report') {
  	    var id = children.item(i).id.substr(7);
  	    $('refresh_report_'+id).onclick();
  	  }
	  }
	  return false;
	}
}

var Drawers = {
	refreshDrawer: function(drawerName, enabled) {
    if (!(drawer = $('drawer' + drawerName))) return;
		if (! enabled) Drawers.hide(drawerName);
	},
	
	refresh: function() {
		Drawers.refreshDrawer('Copy', Item.selectedCopyable());
		Drawers.refreshDrawer('Move', Item.selectedMoveable());
		Drawers.refreshDrawer('Jajah', Item.selectedCopyable());
	},

	show: function(drawerName) {
    if (!(drawer = $('drawer' + drawerName))) return;

		Drawers.hideAll();
		$('contentPane').scrollTop = 0;
		Effect.BlindDown('drawer' + drawerName, { duration: Joyent.effectsDuration * 2, queue: 'end' });
		$('action' + drawerName + 'Link').addClassName('active');
		return false;
	},
	
	hide: function(drawerName) {
    if (!(drawer = $('drawer' + drawerName))) return;
    
    var options = Object.extend({
      afterFinish: function() {}
    }, arguments[1] || {});

		Effect.BlindUp('drawer' + drawerName, { duration: Joyent.effectsDuration * 2, queue: 'end', afterFinish: options.afterFinish });
		$('action' + drawerName + 'Link').removeClassName('active');
		return false;
	},
	
	toggle: function(drawerName) {
    if (!(drawer = $('drawer' + drawerName))) return;

		if (drawer.visible()) {
		  Drawers.hideAll();
		} else {
			Drawers.show(drawerName);
		}
		return false;
	},
	// Same thing that show but for Drawers being loaded using AJAX
	load: function(path, drawerName) {
		if (!(drawer = $('drawer' + drawerName))) return;
				
		new Ajax.Request(path, { method:'get', asynchronous:true, evalScripts:true,
			onLoading: function(request) {
				// Show loading
				new Insertion.Bottom($('drawer' + drawerName), '<div id="loading" style="display:none;"></div>');
				$('loading').update(Joyent.loadingMessageSmall).show();
				Drawers.hideAll();
				$('contentPane').scrollTop = 0;
				Effect.BlindDown('drawer' + drawerName, { duration: Joyent.effectsDuration * 2, queue: 'end' });
				$('action' + drawerName + 'Link').addClassName('active');
				return false;
			},
			onSuccess: function(request) {
				new Insertion.Bottom($('drawer' + drawerName), request.responseText);
				$('loading').hide();
				$('contentPane').scrollTop = 0;
				// Override the onClick event for the Drawer link since it has been loaded and we'll
				// not require more AJAX in order to display it:
				Event.stopObserving($('action' + drawerName + 'Link'), 'click', awayEvent.listenerLoad);
				Event.observe($('action' + drawerName + 'Link'), 'click', function(event){
					return Drawers.toggle(drawerName);
				})
				// This is just for the info link, should follow some naming convention, just in case
				if($('awayPointerLink') != undefined) {
					Event.stopObserving($('awayPointerLink'), 'click', awayEvent.listenerLoad);
					Event.observe($('awayPointerLink'), 'click', function(event){
						return Drawers.toggle(drawerName);
					});
				}
				
				
			},
			onComplete: function(request) {
				// Leave it here for now, probably will cleanup later if not used
			}
		});
		
		
		
	},

	hideAll: function() {
		$$('div#Drawers div.drawerContent').each(function(drawer){
			if (drawer.visible()) Drawers.hide(drawer.id.slice(6)); // 'drawerCopy' => 'Copy'
		});
		return false;
	},
	
	toggleBrowser: function(drawerName, specificView) {
    if (!(drawer = $('drawer' + drawerName))) return;
		
		if (drawer.visible()) {
			return this.hideBrowser(drawerName);
		} else {
			this.showBrowser(drawerName.toLowerCase(), drawerName, specificView);
		}
		
		return false;
	},
	
	hideBrowser: function(drawerName) {
	  Drawers.hide(drawerName, { afterFinish: function() {
	    browser.removeBrowser();
		$(drawerName + 'Browser').hide();
	  }});

	  return false;
	},
	
	showBrowser: function(context, drawerName, specificView) {
		browser.showBrowser(drawerName + 'Browser', context, { method:'get', asynchronous:true, evalScripts:true,
			onLoading: function(request) {
				Drawers.hideAll();
				browser.removeBrowser();
				browser.showLargeLoading(drawerName + 'Browser', 'Bottom', 'drawer_loading');
				$(drawerName + 'Browser').show();
				Drawers.show(drawerName);
				setLink('actionCopyLink', false);
				setLink('actionMoveLink', false);
			},
			onSuccess: function(request) {
			  $('drawer_loading').hide();
		  },
			onComplete: function(request) {
				setLink('actionCopyLink', true);
				setLink('actionMoveLink', true);
		  }
		}, specificView);
	}
}

var ManageDrawer = {
  toggle: function(element, class_name) {
    if (element.hasClassName(class_name)) {
      element.removeClassName(class_name)
    } else {
      element.addClassName(class_name)
    }
  }
}

var SidebarResizer = {

	refresh: function() {
		x = $('gripperSidebarTab').offsetLeft;
		if (x > 500) x = 500;
		if (x < 200) x = 200;
		pos = (x + 29).toString() + 'px';
		pos2 = (x).toString() + 'px';
		pos3 = (x - 35).toString() + 'px';

		if (e = $('sidebars'))    e.style.width = pos;
		if (e = $('contentPane')) e.style.left = pos;
		if (e = $('Toolbar'))     e.style.left = pos;

		if (e = $(document.body)) e.style.backgroundPosition = pos2;

		if (e = $('groupsSidebar')) e.style.width = pos3;
		if (e = $('tagsSidebar'))   e.style.width = pos3;
		if (e = $('accessSidebar')) e.style.width = pos3;
		if (e = $('notifySidebar')) e.style.width = pos3;
		if (e = $('searchField'))   e.style.width = pos3;

		return false;
	},

	revertHandle: function() {
		$('gripperSidebarTab').setStyle({left: '0px'});
		return false;
	},
	
	savePosition: function() {
		x = $('gripperSidebarTab').offsetLeft;
		if (x > 500) x = 500;
		if (x < 200) x = 200;
		UserOptions.set('Sidebar Width', x);
	}

}

var PageOverlay = {
	overlay: new Lightbox(),

	show: function() {
		JoyentPage.hideEverything();
		$('overlay').removeClassName('transparent');
		this.overlay.show();
	},

	showTransparent: function() {
		JoyentPage.hideEverything();
		$('overlay').addClassName('transparent');
		this.overlay.show();
		$('overlay').observe('click', JoyentPage.hideEverything);
	},
	
	hide: function() {
		this.overlay.hide();
		$('overlay').stopObserving('click', JoyentPage.hideEverything);
	}
}

var ModalDialog = {
	showURL: function(url) {
		
		$('modalDialog').removeClassName('done');
		if ($('lbLoadMessage')) $('lbLoadMessage').update(Joyent.loadingMessageLarge);
		PageOverlay.show();
		$('modalDialog').style.display = 'block';
		new Ajax.Request(url, {method:'get', asynchronous:true, evalScripts:true,
			onSuccess: function(request) { ModalDialog.showText(request.responseText); },
			onFailure: function() { JoyentPage.hideEverything(); }
		});
	},

	showText: function(text) {
		$('modalDialog').removeClassName('done');
		$('lbLoadMessage').update(Joyent.loadingMessageLarge);
		PageOverlay.show();
		$('modalDialog').style.display = 'block';
		$('modalDialog').addClassName('done');
		$('modalDialog').update('<div id="lbLoadMessage"></div><div id="lbContent">' + text + '</div>');
	},

	showSpinner: function() {
		$('modalDialog').removeClassName('done').addClassName('loading');
		$('lbLoadMessage').update(Joyent.loadingMessageLarge);
	},
	
	hide: function() {
		$('modalDialog').style.display = 'none';
	}
}

var TagAddField = {
	init: function() {
		Event.observe('tag_name', 'focus', function(event){ TagAddField.select(); });
		Event.observe('tag_name', 'blur', function(event){ TagAddField.deselect(); });
		$('tag_name').value = TagAddField.text();
		TagAddField.deselect();
	},

	select: function() {
		if ($('tag_name').value == TagAddField.text()) {
			$('tag_name').value = '';
		} else {
			$('tag_name').activate();
		}
	},

	deselect: function() {
		if ($('tag_name').value == '') {
			$('tag_name').value = TagAddField.text();
		}
	},

	text: function() {
		return JoyentL10n[' Type new tag here'];
	}
}
