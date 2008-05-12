/*
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
*/

var Sidebar = {
	refresh: function() {
		if ((e = $('tagsSidebar'))   && e.hasClassName('selected')) Sidebar.Tags.refresh();
		if ((e = $('accessSidebar')) && e.hasClassName('selected')) Sidebar.Access.refresh();
		if ((e = $('notifySidebar')) && e.hasClassName('selected')) Sidebar.Notify.refresh();
	},

	disabled: function() {
		return ['month', 'notifications', 'report', 'strongspace', 'service', 'calendar_subscriptions'].include(Joyent.viewKind);
	},

	Tabs: {
		select: function(name) {
			Sidebar.Tabs.tabSelect(name);
			UserOptions.set('Sidebar Selected Name', name);

			return false;
		},

		tabSelect: function(name) {
			['groupsSidebar', 'rulesSidebar', 'tagsSidebar', 'accessSidebar', 'notifySidebar'].each(function(domId){
				if (e = $(domId + 'Tab')) e.removeClassName('selected');
				if (e = $(domId)) e.removeClassName('selected');
			});
			$(name + 'SidebarTab').addClassName('selected');
			$(name + 'Sidebar').addClassName('selected');

			Sidebar.refresh();
		},
		
		remoteSelect: function(name) {
			Sidebar.Tabs.tabSelect(name);
//			Effect.Pulsate(name + 'SidebarTab', {duration: .35, from: .1, pulses: 3});
		}
	},
	
	Tags: {
		refresh: function() {
			if (Sidebar.disabled()) {
				$('tagsAvailableContainer').hide();
				$('tagsUnavailableContainer').show();
			} else if (Joyent.viewKind == 'create') {
				$('tagsUnavailableContainer').hide();
				$('tagsAvailableContainer').show();

				var container = $('tagsAssigned');
				container.innerHTML = '';
				if (JoyentPage.createTags.length == 0) {
					$('tagsAssignedWarning').show();
				} else {
					$('tagsAssignedWarning').hide();
				}
				JoyentPage.createTags.sortBy(function(tag){
					return tag.toLowerCase();
				}).each(function(tag){
					new Insertion.Bottom(container, Sidebar.Tags.draw(tag, JoyentPage.createTags.indexOf(tag), 'mine'));
				});

				var container = $('tagsAssignedByOthers');
				container.innerHTML = '';
				$('tagsOthersContainer').hide();

				var container = $('tagsUnassigned');
				container.innerHTML = '';
				unassignedTags = Tag.findAll().reject(function(tag){
					return JoyentPage.createTags.include(tag.name);
				}).sortBy(function(tag){ return tag.name.toLowerCase(); });
				unassignedTags.each(function(tag){
					new Insertion.Bottom(container, Sidebar.Tags.draw(tag.name, tag.arId, 'unused'));
				});
				$('tagsUnusedContainer').show();
			} else {
				$('tagsUnavailableContainer').hide();
				$('tagsAvailableContainer').show();

				var tagsToDraw = [];
				Tag.findSelectedCurrentUser().each(function(tag){
					tagsToDraw.push([tag.name, tag.arId]);
				});
				JoyentPage.pendingAddTags.each(function(tag){
					tagsToDraw.push([tag, 'pending_' + JoyentPage.pendingAddTags.indexOf(tag)]);
				});
				tagsToDraw = tagsToDraw.reject(function(tag){
					return JoyentPage.pendingRemoveTags.include(tag[0]);
				});

				var container = $('tagsAssigned');
				container.innerHTML = '';
				if (tagsToDraw.length == 0) {
					$('tagsAssignedWarning').show();
				} else {
					$('tagsAssignedWarning').hide();
				}

				tagsToDraw.sortBy(function(tag){
					return tag[0].toLowerCase();
				}).each(function(tag){
					new Insertion.Bottom(container, Sidebar.Tags.draw(tag[0], tag[1], 'mine'));
				});

				var container = $('tagsAssignedByOthers');
				container.innerHTML = '';
				if (Tag.findSelectedOtherUsers().length == 0) {
					$('tagsOthersContainer').hide();
				} else {
					$('tagsOthersContainer').show();
				}
				Tag.findSelectedOtherUsers().each(function(tag){
					new Insertion.Bottom(container, Sidebar.Tags.draw(tag.name, tag.arId, 'others'));
				});

				var container = $('tagsUnassigned');
				var currentUser = User.findCurrent();
				container.innerHTML = '';
				if (Item.findSelected().length > 0) {
					var selectedTagDomIds = Tag.findSelectedCurrentUser().collect(function(tag){ return tag.domId; });
					unassignedTags = Tag.findAll().reject(function(tag){
						return selectedTagDomIds.include(tag.domId);
					}).reject(function(tag){
						taggings = Tag.taggings(tag);
						return (taggings.length > 0) && taggings.all(function(tagging){
							return tagging.userDomId != currentUser.domId;
						});
					});

					var tagsToDraw = [];
					unassignedTags.each(function(tag){
						tagsToDraw.push([tag.name, tag.arId]);
					});
					JoyentPage.pendingRemoveTags.each(function(tag){
						tagsToDraw.push([tag, 'pending_' + JoyentPage.pendingRemoveTags.indexOf(tag)]);
					});
					tagsToDraw = tagsToDraw.reject(function(tag){
						return JoyentPage.pendingAddTags.include(tag[0]);
					});

					tagsToDraw.sortBy(function(tag){
						return tag[0].toLowerCase();
					}).each(function(tag){
						new Insertion.Bottom(container, Sidebar.Tags.draw(tag[0], tag[1], 'unused'));
					});
					$('tagsUnusedContainer').show();
				} else {
					$('tagsUnusedContainer').hide();
				}
			}
		},

		draw: function(name, tagId, section) {
			domId = 'tag_' + tagId + '_' + section;

			switch (section) {
				case 'mine':   title = JoyentL10n['unassign tag']; break;
				case 'others': title = JoyentL10n['assign tag as your own']; break;
				case 'unused': title = JoyentL10n['assign tag']; break;
				default:       title = '';
			}

			html = '<li id="' + domId + '">';
			html += '<a href="#" onclick="';
			if (section == 'mine') {
				html += "return Sidebar.Tags.removeFromSelected('" + escape(name) + "');";
			} else {
				html += "return Sidebar.Tags.addToSelected('" + escape(name) + "');";
			}
			html += '" class="tag" title="' + title + '">' + name.escapeHTML() + '</a>';
			html += '<span id="' + domId + '_info" style="display:none;">';
			html += '<a href="/syndicate/tag/' + encodeURIComponent(name) + '/rss" class="orangeBadge rss" title="'+JoyentL10n['Subscribe to this RSS feed']+'">RSS</a>';
			html += '</span>';
			html += '<a href="#" onclick="return Sidebar.Tags.toggle(\'' + domId + '_info\');" class="tagInfo" title="'+JoyentL10n['tag info']+'">&#9998;</a>';
			html += '</li>';
			return html;
		},

		addToSelected: function(tagName) {
			tagName = unescape(tagName);
			if (Joyent.viewKind == 'create') {
				JoyentPage.createTags.push(tagName);
				Sidebar.Tags.refresh();
			} else {
				JoyentPage.pendingAddTags.push(tagName);
				Sidebar.Tags.refresh();
				new Ajax.Request('/tag/tag_item?tag_name=' + encodeURIComponent(tagName) + '&dom_ids=' + Item.selectedDomIds(), {asynchronous:true, evalScripts:true, onComplete: function(){
					JoyentPage.pendingAddTags = JoyentPage.pendingAddTags.reject(function(tag){ return tag == tagName; });
					Sidebar.Tags.refresh();
				}});
			}
			return false;
		},

		removeFromSelected: function(tagName) {
			tagName = unescape(tagName);
			if (Joyent.viewKind == 'create') {
				JoyentPage.createTags = JoyentPage.createTags.reject(function(currentTag){ return currentTag == tagName; });
				Sidebar.Tags.refresh();
			} else {
				JoyentPage.pendingRemoveTags.push(tagName);
				Sidebar.Tags.refresh();
				new Ajax.Request('/tag/untag_item?tag_name=' + encodeURIComponent(tagName) + '&dom_ids=' + Item.selectedDomIds(), {asynchronous:true, evalScripts:true, onComplete: function(){
					JoyentPage.pendingRemoveTags = JoyentPage.pendingRemoveTags.reject(function(tag){ return tag == tagName; });
					Sidebar.Tags.refresh();
				}});
			}
			return false;
		},

		submitTypedTag: function(form) {
		  if (Item.findSelected().length == 0) {
		    alert(JoyentL10n["You must select something to tag."]);
		    return false;
		  }
			tag_field = $('tag_name');

			if (Joyent.viewKind == 'create') {
				JoyentPage.createTags.push(tag_field.value);
				JoyentPage.createTags = JoyentPage.createTags.uniq();
				tag_field.value = TagAddField.text();
				tag_field.blur();
				Sidebar.Tags.refresh();
				tag_field.activate();

				return false; // must return false to prevent ajax submit
			} else {
				JoyentPage.pendingAddTags.push(tag_field.value);
				Sidebar.Tags.refresh();
				$('tag_name_dom_ids').value = Item.findSelected().collect(function(item){ return item.domId; }).join(",");

			  return true; // will add tag via ajax when returning true
			}
		},

		toggle: function(dom_id) {
			if (!(element = $(dom_id))) return;

			if (element.visible()) {
				$(element.parentNode).removeClassName('expanded');
				Effect.SlideLeft(element, { duration: Joyent.effectsDuration });
			} else {
				$(element.parentNode).addClassName('expanded');
				Effect.SlideRight(element, { duration: Joyent.effectsDuration });
			}

 			return false;
		}
	},
	
	Access: {
		refresh: function() {
			$('accessAvailableContainer').hide();
			$('accessUnavailableContainer').hide();

			if (Sidebar.disabled() || (Joyent.applicationName == 'bookmarks' && Joyent.viewKind == 'create')) {
				$('accessUnavailableContainer').show();
			} else if (Joyent.viewKind == 'create') {
				var container = $('accessSidebarUsers')
				container.update('');

				var currentUser = User.findCurrent();
				Sidebar.Access.draw(currentUser);
                                
				new Insertion.Bottom(container, '<tr><td colspan="2"><hr /></td></tr>');

				if (JoyentPage.createPermissions.length == 0 || JoyentPage.createPermissions.length == User.findAll().length) {
					viewableClass = ' on';
					title = JoyentL10n['has access, '];
				} else if (JoyentPage.createPermissions.length == 1 && JoyentPage.createPermissions.include(currentUser.domId)) {
					viewableClass = ' off';
					title = JoyentL10n["doesn't have access, "];
				} else {
					viewableClass = ' some';
					title = JoyentL10n['has access to some selected items, '];
				}
				title += JoyentL10n['can change'];
				everyoneHTML = '';
				everyoneHTML += '<tr id="everyone_access_li" class="everyone">';
	      everyoneHTML += '<td><span class="addIconLeft userFolder">'+JoyentL10n['Everyone Else']+'</span></td>';
				everyoneHTML += '<td>';
	      everyoneHTML += '<a href="#" onclick="return Sidebar.Access.toggleSelectionForEveryone();" class="status viewable' + viewableClass + '" title="' + title + '">'+JoyentL10n['Viewability']+'</a>';
				everyoneHTML += '</td>';
		    everyoneHTML += '</tr>';
				new Insertion.Bottom(container, everyoneHTML);

                                Group.findSorted().each(function(group){
                                    Sidebar.Access.drawGroup(group);
                                });
                                
				User.findSorted().each(function(user){
					if(user.domId != currentUser.domId) Sidebar.Access.draw(user);
				});

				$('accessAvailableContainer').show();
			} else {
				var container = $('accessSidebarUsers')
				container.update('');

				var currentUser = User.findCurrent();
				Sidebar.Access.draw(currentUser);

				new Insertion.Bottom(container, '<tr><td colspan="2"><hr /></td></tr>');

				if (Item.findSelected().length == 0) {
					viewableClass = ' off';
					title = JoyentL10n["no items selected, "];				
				} else {
					if (Item.selectedPublic()) {
						viewableClass = ' on';
						title = JoyentL10n['has access, '];
					} else if (Item.selectedPrivate()) {
						viewableClass = ' off';
					} else {
						viewableClass = ' some';
						title = JoyentL10n['has access to some selected items, '];
					}
				}
				disabled = Item.findSelected().length == 0 || (Item.selectedPublic() && Item.findSelected().any(function(item){
					return User.findAll().any(function(user){
						return item.domId == user.personDomId;
					});
				}));
				if (disabled) {
					title += JoyentL10n["can't change"];
				} else {
					title += JoyentL10n['can change'];
				}
				everyoneHTML = '';
				everyoneHTML += '<tr id="everyone_access_li" class="everyone">';
	      everyoneHTML += '<td><span class="addIconLeft userFolder">'+JoyentL10n['Everyone Else']+'</span></td>';
	      everyoneHTML += '<td><a href="#" id="everyone_access_toggle" onclick="return Sidebar.Access.toggleSelectionForEveryone();" class="status viewable' + viewableClass + '" title="' + title + '">'+JoyentL10n['Viewability']+'</a></td>';
		    everyoneHTML += '</tr>';
				new Insertion.Bottom(container, everyoneHTML);
				if (disabled) setLink('everyone_access_toggle', false);

                                Group.findSorted().each(function(group){
                                    Sidebar.Access.drawGroup(group);
                                });
                                
				User.findSorted().each(function(user){
					if (user.domId != currentUser.domId) Sidebar.Access.draw(user);
				});

				$('accessAvailableContainer').show();
			}
		},

		draw: function(user) {
			html = '';
			currentUser = User.findCurrent();

			if (Joyent.viewKind == 'create') {
				if (JoyentPage.createPermissions.length == 0 || JoyentPage.createPermissions.include(user.domId)) {
					viewableClass = ' on';
				} else {
					viewableClass = ' off';
				}
			} else {
				if (Item.findSelected().length > 0 && Item.findSelected().all(function(item){ return User.canView(user, item); })) {
					viewableClass = ' on';
				} else if (Item.findSelected().length == 0 || Item.findSelected().all(function(item){ return ! User.canView(user, item); })) {
					viewableClass = ' off';
				} else {
					viewableClass = ' some';
				}
			}

			if (Item.findSelected().length == 0) {
				title = JoyentL10n["no items selected, "];				
			} else {
				switch (viewableClass) {
					case ' on':   title = JoyentL10n['has access, ']; break;
					case ' some': title = JoyentL10n['has access to some selected items, ']; break;
					case ' off':  title = JoyentL10n["doesn't have access, "]; break;
					default:      title = '';
				}
			}
			disabled = Item.findSelected().length == 0 ||
								 user.domId == currentUser.domId ||
								(Item.findSelected().all(function(item){ return User.canView(user, item); }) &&
									Item.findSelected().any(function(item){ return item.userDomId == user.domId; }));
			if (disabled) {
				title += JoyentL10n["can't change"];
			} else {
				title += JoyentL10n['can change'];
			}

			userClass = (user.domId == currentUser.domId) ? 'currentUser' : 'user';
			html += '<tr id="' + user.domId + '_access_li">';
			html += '<td>';
			html += '<span class="addIconLeft ' + userClass + '">' + user.fullName.escapeHTML() + '</span>';
			html += '</td>';
			html += '<td>';
			html += '<a href="#" id="' + user.domId + '_access_toggle" onclick="return Sidebar.Access.toggleSelected(\'' + user.domId + '\');" class="status viewable' + viewableClass + '" title="' + title + '">' + JoyentL10n['Viewable'] + '</a>';
			html += '</td>';
			html += '</tr>';
			new Insertion.Bottom('accessSidebarUsers', html);
			if (disabled) setLink(user.domId + '_access_toggle', false);

                        return html;
		},

		drawGroup: function(group) {
			html = '';
			currentUser = User.findCurrent();

			if (Joyent.viewKind == 'create') {
                            var permissionsCounter = 0;
                            
                            if (JoyentPage.createPermissions.length == 0) {
                                permissionsCounter = group.users.length;
                            } else {
                                group.users.each(function(userDomId){
                                    if ( JoyentPage.createPermissions.include(userDomId) ) {
                                        permissionsCounter++;
                                    }
                                });
                            }
                          
                            if (permissionsCounter == 0) {
                                viewableClass = ' off';
                            } else if ( permissionsCounter == group.users.length ) {
                                viewableClass = ' on';
                            } else {
                                viewableClass = ' some'
                            }
                            
			} else {
                            if (Item.findSelected().length > 0 && Item.findSelected().all(function(item){ return Group.allCanView(group, item); })) {
                                viewableClass = ' on';
                            } else if (Item.findSelected().length == 0 || Item.findSelected().all(function(item){ return !Group.someCanView(group, item); })) {
                                viewableClass = ' off';
                            } else {
                                viewableClass = ' some';
                            }
			}

			if (Item.findSelected().length == 0) {
                            title = JoyentL10n["no items selected, "];				
			} else {
                            switch (viewableClass) {
                                case ' on':   title = JoyentL10n['has access, ']; break;
                                case ' some': title = JoyentL10n['has access to some selected items, ']; break;
                                case ' off':  title = JoyentL10n["doesn't have access, "]; break;
                                default:      title = '';
                            }
			}
                        
			disabled = Item.findSelected().length == 0 ||
                                   (group.users.all(function(userDomId){return userDomId == currentUser.domId; }))  ||
                                   (Item.findSelected().all(function(item){ return Group.someCanView(group, item); }) &&
                                    Item.findSelected().any(function(item){ return group.users.any(function(userDomId){ return item.userDomId == userDomId }); }));
                                  
			if (disabled) {
                            title += JoyentL10n["can't change"];
			} else {
                            title += JoyentL10n['can change'];
			}

			html += '<tr id="' + group.domId + '_access_li">';
			html += '<td>';
			html += '<span class="addIconLeft personGroup">' + group.name.escapeHTML() + '</span>';
			html += '</td>';
			html += '<td>';
			html += '<a href="#" id="' + group.domId + '_access_toggle" onclick="return Sidebar.Access.toggleSelectionForGroup(\'' + group.domId + '\');" class="status viewable' + viewableClass + '" title="' + title + '">' + JoyentL10n['Viewable'] + '</a>';
			html += '</td>';
			html += '</tr>';
			new Insertion.Bottom('accessSidebarUsers', html);
			if (disabled) setLink(group.domId + '_access_toggle', false);

                        return html;
		},
                
		toggleSelected: function(userDomId) {
			if (Item.findSelected().length == 0) return false
			var user = User.find(userDomId);

			if (Joyent.viewKind == 'create') {
				if (JoyentPage.createPermissions.length == 0 || JoyentPage.createPermissions.include(user.domId)) {
					Sidebar.Access.removeFromSelected(userDomId);
				} else {
					Sidebar.Access.addToSelected(userDomId);
				}
			} else {
				if (Item.findSelected().any(function(item){ return ! User.canView(user, item); })) {
					Sidebar.Access.addToSelected(userDomId);
				} else {
					Sidebar.Access.removeFromSelected(userDomId);
				}
			}
			return false;
		},
		
		addToSelected: function(userDomId) {
			if (Item.findSelected().length == 0) return false

			if (Joyent.viewKind == 'create') {
				if (! JoyentPage.createPermissions.include(userDomId)) JoyentPage.createPermissions.push(userDomId);
				if (JoyentPage.createPermissions.length == User.findAll().length) JoyentPage.createPermissions = $A();
				Sidebar.Access.refresh();
				Sidebar.Notify.refresh();
			} else {
			  if (e = $(userDomId + '_access_toggle')) {
					e.removeClassName('off');
					e.removeClassName('some');
					e.addClassName('on');
				}
				new Ajax.Request('/permissions/add_user?user_id=' + User.find(userDomId).arId + '&dom_ids=' + Item.selectedDomIds(), {asynchronous:true, evalScripts:true});
			}
			return false;
		},
		
		addGroupToSelected: function(groupDomId) {
			if (Item.findSelected().length == 0) return false
                        var group = Group.find(groupDomId);

			if (Joyent.viewKind == 'create') {
                            group.users.each(function(userDomId){
                              if (! JoyentPage.createPermissions.include(userDomId)) JoyentPage.createPermissions.push(userDomId);
                            });
				
                            if (JoyentPage.createPermissions.length == User.findAll().length) JoyentPage.createPermissions = $A();
                            Sidebar.Access.refresh();
                            Sidebar.Notify.refresh();
			} else {
                            if (e = $(groupDomId + '_access_toggle')) {
                                e.removeClassName('off');
                                e.removeClassName('some');
                                e.addClassName('on');
                            }
                            new Ajax.Request('/permissions/add_person_group?group_id=' + group.arId + '&dom_ids=' + Item.selectedDomIds(), {asynchronous:true, evalScripts:true});
			}
			return false;
		},
		
		removeFromSelected: function(userDomId) {
			if (Item.findSelected().length == 0) return false

			if (Joyent.viewKind == 'create') {
				if (JoyentPage.createPermissions.length == 0) {
					User.findAll().each(function(user){
						if (user.domId != userDomId) JoyentPage.createPermissions.push(user.domId);
					});
				} else {
					JoyentPage.createPermissions = JoyentPage.createPermissions.reject(function(loopUserDomId){ return loopUserDomId == userDomId; });
				}
				JoyentPage.createNotifications = JoyentPage.createNotifications.reject(function(loopUserDomId){ return loopUserDomId == userDomId; });
				Sidebar.Access.refresh();
				Sidebar.Notify.refresh();
			} else {
			  if (e = $(userDomId + '_access_toggle')) {
					e.removeClassName('on');
					e.removeClassName('some');
					e.addClassName('off');
				}
				new Ajax.Request('/permissions/remove_user?user_id=' + User.find(userDomId).arId + '&dom_ids=' + Item.selectedDomIds(), {asynchronous:true, evalScripts:true});
			}
			return false;
		},

		removeGroupFromSelected: function(groupDomId) {
			if (Item.findSelected().length == 0) return false;
                        var group = Group.find(groupDomId);

			if (Joyent.viewKind == 'create') {
                            if (JoyentPage.createPermissions.length == 0) {
                                User.findAll().each(function(user){
                                    if (!group.users.include(user.domId)) JoyentPage.createPermissions.push(user.domId);
                                });
                            } else {
                                JoyentPage.createPermissions = JoyentPage.createPermissions.reject(function(userDomId){ return group.users.include(userDomId); });
                            }
                            JoyentPage.createNotifications = JoyentPage.createNotifications.reject(function(userDomId){ return group.users.include(userDomId); });
                            Sidebar.Access.refresh();
                            Sidebar.Notify.refresh();
			} else {
                            if (e = $(groupDomId + '_access_toggle')) {
                                e.removeClassName('on');
                                e.removeClassName('some');
                                e.addClassName('off');
                            }
                            new Ajax.Request('/permissions/remove_person_group?group_id=' + group.arId + '&dom_ids=' + Item.selectedDomIds(), {asynchronous:true, evalScripts:true});
			}
			return false;
		},
                
		toggleSelectionForEveryone: function() {
			if (Item.findSelected().length == 0) return false

			if (Joyent.viewKind == 'create') {
				if (JoyentPage.createPermissions.length != 0 && JoyentPage.createPermissions.length != User.findAll().length) {
					Sidebar.Access.makeSelectionPublic();
				} else {
					Sidebar.Access.makeSelectionPrivate();
				}
			} else {
				if (! Item.selectedPublic()) {
					Sidebar.Access.makeSelectionPublic();
				} else {
					Sidebar.Access.makeSelectionPrivate();
				}
			}
			return false;
		},
                
                toggleSelectionForGroup: function(groupDomId) {
                  if (Item.findSelected().length == 0) return false
                  var group = Group.find(groupDomId);
                  
                  if (Joyent.viewKind == 'create') {
                      if (JoyentPage.createPermissions.length == 0 || group.users.any(function(userDomId){ return JoyentPage.createPermissions.include(userDomId); })) {
                          Sidebar.Access.removeGroupFromSelected(groupDomId);
                      } else {
                          Sidebar.Access.addGroupToSelected(groupDomId);
                      }
                  } else {
                      if (Item.findSelected().any(function(item){ return !Group.allCanView(group, item); })) {
                          Sidebar.Access.addGroupToSelected(groupDomId);
                      } else {
                          Sidebar.Access.removeGroupFromSelected(groupDomId);
                      }
                  }
                  
                  return false;
                },

		makeSelectionPublic: function() {
			if (Item.findSelected().length == 0) return false

			if (Joyent.viewKind == 'create') {
				JoyentPage.createPermissions = [];
				Sidebar.Access.refresh();
				Sidebar.Notify.refresh();
			} else {
			  if (e = $('everyone_access_toggle')) {
					e.removeClassName('off');
					e.removeClassName('some');
					e.addClassName('on');
				}
				new Ajax.Request('/permissions/make_public?dom_ids=' + Item.selectedDomIds(), {asynchronous:true, evalScripts:true});
			}
			return false;
		},
		
		makeSelectionPrivate: function() {
			if (Item.findSelected().length == 0) return false

			if (Joyent.viewKind == 'create') {
				JoyentPage.createPermissions = [User.findCurrent().domId];
				var currentUser = User.findCurrent();
				JoyentPage.createNotifications = JoyentPage.createNotifications.reject(function(loopUserDomId){ return loopUserDomId != currentUser.domId; });
				Sidebar.Access.refresh();
				Sidebar.Notify.refresh();
			} else {
			  if (e = $('everyone_access_toggle')) {
					e.removeClassName('on');
					e.removeClassName('some');
					e.addClassName('off');
				}
				new Ajax.Request('/permissions/make_private?dom_ids=' + Item.selectedDomIds(), {asynchronous:true, evalScripts:true});
			}
			return false;
		}
	},
	
	Notify: {
		refresh: function() {
			$('notifyAvailableContainer').hide();
			$('notifyUnavailableContainer').hide();
			var container = $('notifySidebarUsers')
			container.update('');

			if (! Sidebar.disabled()) {
				var currentUser = User.findCurrent();
				Sidebar.Notify.drawUser(currentUser);
				new Insertion.Bottom(container, '<tr><td colspan="2"><hr /></td></tr>');

				Group.findSorted().each(function(group){
					if (group.users != '') Sidebar.Notify.drawGroup(group);
				});
				User.findSorted().each(function(user){
					if(user.domId != currentUser.domId) Sidebar.Notify.drawUser(user);
				});
				$('notifyAvailableContainer').show();
			} else {
				$('notifyUnavailableContainer').show();
			}
		},

		drawUser: function(user) {
			html = '';

			if (Joyent.viewKind == 'create') {
				if (JoyentPage.createNotifications.include(user.domId)) {
					viewableClass = ' on';
				} else {
					viewableClass = ' off';
				}
			} else {
				if (Item.findSelected().length > 0 && Item.findSelected().all(function(item){return User.isNotifiedOf(user, item);})) {
					viewableClass = ' on';
				}
				else if (Item.findSelected().length == 0 || Item.findSelected().all(function(item){return !User.isNotifiedOf(user, item);})) {
					viewableClass = ' off';
				}
				else {
					viewableClass = ' some';
				}
			}

			if (Item.findSelected().length == 0) {
				title = JoyentL10n["no items selected, "];				
			} else {
				switch (viewableClass) {
					case ' on':   title = JoyentL10n['is notified, ']; break;
					case ' some': title = JoyentL10n['is notified of some selected items, ']; break;
					case ' off':  title = JoyentL10n["isn't notified, "]; break;
					default:      title = '';
				}
			}
			if (Joyent.viewKind == 'create') {
				disabled = Item.findSelected().length == 0 || (JoyentPage.createPermissions.length > 0 && ! JoyentPage.createPermissions.include(user.domId));
			} else {
				disabled = Item.findSelected().length == 0 || Item.findSelected().any(function(item){return !User.canView(user, item);});
			}
			if (disabled) {
				title += JoyentL10n["can't change"];
			} else {
				title += JoyentL10n['can change'];
			}

			userClass = (user.domId == User.findCurrent().domId) ? 'currentUser' : 'user';
			userName = user.fullName.escapeHTML();
							
			html += '<tr id="' + user.domId + '_notify_li">';
			html += '<td><span class="addIconLeft ' + userClass + '">' + userName + '</span></td>';
			html += '<td>';
			html += '<a href="#" id="' + user.domId + '_notify_toggle" onclick="return Sidebar.Notify.toggleSelected(\'' + user.domId + '\');" class="status viewable' + viewableClass + '" title="' + title + '">' + JoyentL10n['Notified'] + '</a>';
			html += '</td>';
			html += '</tr>';
			new Insertion.Bottom('notifySidebarUsers', html);
			if (disabled) setLink(user.domId + '_notify_toggle', false);

      		return html;
		},	
		
		drawGroup: function(group) {
			html = '';
			if (Joyent.viewKind == 'create') {
				if (group.users.all(function(userDomId){ return JoyentPage.createNotifications.include(userDomId);})) {
					viewableClass = ' on';
				//any number of users but not all users means viewableClass = 'some'
				} else if (group.users.any(function(userDomId){ return JoyentPage.createNotifications.include(userDomId);}) 
						&& !group.users.all(function(userDomId){ return JoyentPage.createNotifications.include(userDomId);})){
					viewableClass = ' some';
				} else {
					viewableClass = ' off';
				}

			} else {
				if (Item.findSelected().length > 0 && Item.findSelected().all(function(item){return Group.allNotifiedOf(group, item);})) {
					viewableClass = ' on';
				}else if (Item.findSelected().length > 0 
					&& Item.findSelected().all(function(item){return Group.someNotifiedOf(group, item );}) 
					&& Item.findSelected().all(function(item){return !Group.allNotifiedOf(group, item );})) {
					viewableClass = ' some';
				}					
				else if (Item.findSelected().length == 0 || Item.findSelected().all(function(item){return !Group.allNotifiedOf(group, item);})) {
					viewableClass = ' off';
				}
				else {
					viewableClass = ' some';
				}
			}

			if (Item.findSelected().length == 0) {
				title = JoyentL10n["no items selected, "];				
			} else {
				switch (viewableClass) {
					case ' on':   title = JoyentL10n['is notified, ']; break;
					case ' some': title = JoyentL10n['is notified of some selected items, ']; break;
					case ' off':  title = JoyentL10n["isn't notified, "]; break;
					default:      title = '';
				}
			}
			if (Joyent.viewKind == 'create') {
				disabled = Item.findSelected().length == 0 || 
						   (JoyentPage.createPermissions.length > 0 && 
						   ! group.users.any(function(userDomId){return JoyentPage.createPermissions.include(userDomId);}));
			} else {
				disabled = Item.findSelected().length == 0 || Item.findSelected().any(function(item){return !Group.someCanView(group, item);});
			}
			if (disabled) {
				title += JoyentL10n["can't change"];
			} else {
				title += JoyentL10n['can change'];
			}

			groupClass = 'personGroup';	
			groupName = group.name.escapeHTML();
							
			html += '<tr id="' + group.domId + '_notify_li">';
			html += '<td><span class="addIconLeft ' + groupClass + '">' + groupName + '</span></td>';
			html += '<td>';
			html += '<a href="#" id="' + group.domId + '_notify_toggle" onclick="return Sidebar.Notify.toggleSelectedGroup(\'' + group.domId + '\');" class="status viewable' + viewableClass + '" title="' + title + '">' + JoyentL10n['Notified'] + '</a>';
			html += '</td>';
			html += '</tr>';
			new Insertion.Bottom('notifySidebarUsers', html);
			if (disabled) setLink(group.domId + '_notify_toggle', false);

      		return html;
		},		

		toggleSelected: function(userDomId) {
			if (Item.findSelected().length == 0) return false;
			var user = User.find(userDomId);

			if (Joyent.viewKind == 'create') {
				if (JoyentPage.createNotifications.include(user.domId)) {
					Sidebar.Notify.unnotifySelected(userDomId);
				} else {
					Sidebar.Notify.notifySelected(userDomId);
				}
			} else {
				if (Item.findSelected().any(function(item){ return ! User.isNotifiedOf(user, item) })) {
					Sidebar.Notify.notifySelected(userDomId);
				} else {
					Sidebar.Notify.unnotifySelected(userDomId);
				}
			}
			return false;
		},
		
		toggleSelectedGroup: function(groupDomId){
			if (Item.findSelected().length == 0) return false;
			var group = Group.find(groupDomId);
			var initialClass;
			
			if ($(groupDomId + '_notify_toggle').hasClassName('on')){
				initialClass = 'on';
			}else{
				initialClass = 'other';
			}
			
			group.users.each(function(userDomId){
				var user = User.find(userDomId);				
			
				if (Joyent.viewKind == 'create') {
					if (JoyentPage.createNotifications.include(userDomId) 
						&& !$(groupDomId + '_notify_toggle').hasClassName('some') && (initialClass == 'on')) {
							Sidebar.Notify.unnotifySelected(userDomId);
					} else if (JoyentPage.createNotifications.include(userDomId) 
						&& $(groupDomId + '_notify_toggle').hasClassName('some') && (initialClass == 'on')){
							Sidebar.Notify.unnotifySelected(userDomId);
					} else {
						Sidebar.Notify.notifySelected(userDomId);
					}
				}
				else {
					if (Item.findSelected().any(function(item){
						return !User.isNotifiedOf(user, item)
					})) {
						Sidebar.Notify.notifySelected(userDomId);
					}
					else {
						if (!$(groupDomId + '_notify_toggle').hasClassName('some')) {
							Sidebar.Notify.unnotifySelected(userDomId);
						}
					}
				}
			});
			return false;			
		},
		
		notifySelected: function(userDomId) {
			if (Item.findSelected().length == 0) return false

			if (Joyent.viewKind == 'create') {
				if (! JoyentPage.createNotifications.include(userDomId)) JoyentPage.createNotifications.push(userDomId);
				Sidebar.Notify.refresh();
			} else {
			  if (e = $(userDomId + '_notify_toggle')) {
					e.removeClassName('off');
					e.removeClassName('some');
					e.addClassName('on');
				}
				new Ajax.Request('/notifications/create?user_id=' + User.find(userDomId).arId + '&dom_ids=' + Item.selectedDomIds(), {asynchronous:true, evalScripts:true});
			}
			return false;
		},
		
		unnotifySelected: function(userDomId) {
			if (Item.findSelected().length == 0) return false

			if (Joyent.viewKind == 'create') {
				JoyentPage.createNotifications = JoyentPage.createNotifications.reject(function(loopUserDomId){ return loopUserDomId == userDomId; });
				Sidebar.Notify.refresh();
			} else {
			  if (e = $(userDomId + '_notify_toggle')) {
					e.removeClassName('on');
					e.removeClassName('some');
					e.addClassName('off');
				}
				new Ajax.Request('/notifications/delete?user_id=' + User.find(userDomId).arId + '&dom_ids=' + Item.selectedDomIds(), {asynchronous:true, evalScripts:true});
			}
			return false;
		}
	}
}
