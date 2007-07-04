// Copyright 2004-2007 Joyent Inc.
// 
// Redistribution and/or modification of this code is governed
// by either the GPLv2 or Joyent Commercial Software licenses.
// 
// Report issues and contribute at http://dev.joyent.com/
// 
// $Id$


ActiveRecord = Class.create();
Object.extend(ActiveRecord.prototype, {
	initialize: function() {
		this.attributes = $A();
		this.domIdCache = $A();
		return this.attributes;
	},

	create: function(newRecord) {
		if (this.domIdCache.indexOf(newRecord.domId) >= 0) {
			return false;
		} else {
			this.domIdCache.push(newRecord.domId);
			return this.attributes.push($H(newRecord));
		}
	},
	
	find: function(domId) {
		return this.findBy('domId', domId);
	},

	findAll: function() {
		return this.attributes;
	},

	findBy: function(attribute, value) {
		if (this.attributes.length == 0) return this.attributes;
		return this.attributes.detect(function(item){
			return item[attribute] == value;
		});
	},

	findAllBy: function(attribute, value) {
		if (this.attributes.length == 0) return this.attributes;
		return this.attributes.select(function(item){
			return item[attribute] == value;
		});
	},

	indexBy: function(attribute, value) {
		var result;
		this.attributes.each(function(record, index) {
			if (record[attribute] == value) {
				result = index;
				throw $break;
			}
		});
		return result;
	},

	update: function(item, attribute, value) {
		var index = this.indexBy('domId', item.domId);
		this.attributes[index][attribute] = value;
	},
	
	destroy: function(domId) {
		var resultIndex = this.indexBy('domId', domId);
		var resultValue = this.attributes[resultIndex];

		delete this.attributes[resultIndex];
		this.attributes = this.attributes.compact();

		var cacheIndex = this.domIdCache.indexOf(domId);
		if (cacheIndex >= 0) delete this.domIdCache[cacheIndex]

		return resultValue;
	},
	
	clearAll: function() {
		this.attributes = $A();
		this.domIdCache = $A();
		return this.attributes;
	},
	
	inspect: function() {
		return '#<ActiveRecord:' + this.attributes.collect(function(record){
			return record.inspect();
		}).join(', ') + '>';
	}
});

var Item = new ActiveRecord();
Object.extend(Item, {
	taggings: function(item) {
		return Tagging.attributes.select(function(tagging){
			return tagging.itemDomId == item.domId;
		});
	},
	
	tags: function(item) {
		return Item.taggings(item).collect(function(tagging){
			return Tag.find(tagging.tagDomId);
		}).uniq();
	},

	permissions: function(user) {
		return Permission.attributes.select(function(permission){
			return permission.itemDomId == user.domId;
		});
	},

	notifications: function(user) {
		return Notification.attributes.select(function(notification){
			return notification.itemDomId == user.domId;
		});
	},

	findSelected: function() { return Item.attributes.select(function(item){ return item.selected; }); },
	findEditable: function() { return Item.attributes.select(function(item){ return item.canEdit; }); },
	findCopyable: function() { return Item.attributes.select(function(item){ return item.canCopy; }); },
	findMoveable: function() { return Item.attributes.select(function(item){ return item.canMove; }); },
	findDeleteable: function() { return Item.attributes.select(function(item){ return item.canDelete; }); },
	findConfirmDelete: function() { return Item.attributes.select(function(item){ return item.mustConfirmDelete; }); },
	selectedEditable: function() {
		if (Item.findSelected().length == 0) return false;
		return Item.findSelected().all(function(item){ return item.canEdit; });
	},
	selectedCopyable: function() {
		if (Item.findSelected().length == 0) return false;
		return Item.findSelected().all(function(item){ return item.canCopy; });
	},
	selectedMoveable: function() {
		if (Item.findSelected().length == 0) return false;
		return Item.findSelected().all(function(item){ return item.canMove; });
	},
	selectedDeleteable: function() {
		if (Item.findSelected().length == 0) return false;
		return Item.findSelected().all(function(item){ return item.canDelete; });
	},
	// does any of the selection require a confirmation
	selectedConfirmDelete: function() {
		if (Item.findSelected().length == 0) return false;
		return Item.findSelected().any(function(item){ return item.mustConfirmDelete; });
	},
	selectedPublic: function() {
		if (Item.findSelected().length == 0) return false;
		return Item.findSelected().all(function(item){
			itemPermissions = Permission.findAllBy('itemDomId', item.domId);
			return (itemPermissions.length == 0 || itemPermissions.length == User.findAll().length);
		});
	},
	selectedPrivate: function() {
		if (Item.findSelected().length == 0) return false;
		var currentUser = User.findCurrent();
		return Item.findSelected().all(function(item){
			itemPermissions = Permission.findAllBy('itemDomId', item.domId);
			return (itemPermissions.length == 1 && itemPermissions.first().userDomId == currentUser.domId);
		});
	},

	selectedDomIds: function() {
		return Item.findSelected().collect(function(item){return item.domId;}).join(',');
	},

	// fade item rows from list, remove from items array, change pagination count
	removeFromList: function(domId) {
		$$('div#contentPane tr[itemDomId=' + domId + ']').each(function(row){
			Effect.Fade(row, { duration: Joyent.effectsDuration, afterFinish: function(){
				if (row.hasClassName('itemRow')) JoyentPage.refreshPagination();
				row.remove();
				JoyentPage.restripe();
			} });
		});
		Item.destroy(domId);
	}

});

var Tag = new ActiveRecord();
Object.extend(Tag, {
	create: function(newRecord) {
		if (this.domIdCache.indexOf(newRecord.domId) >= 0) {
			return false;
		} else {
			this.domIdCache.push(newRecord.domId);
			h = $H(newRecord);
			h.name = decodeURIComponent(h.name);
			return this.attributes.push(h);
		}
	},
	
	taggings: function(tag) {
		return Tagging.attributes.select(function(tagging){
			return tagging.tagDomId == tag.domId;
		});
	},
	
	items: function(tag) {
		return Tag.taggings(tag).collect(function(tagging){
			return Item.find(tagging.itemDomId);
		}).uniq();
	},
	
	// tags on every selected item
	findSelected: function() {
		if (Item.findSelected().length == 0) return [];
		var selectedAnywhereTags = Item.findSelected().collect(function(item){ return Item.tags(item); }).flatten().uniq();
		if (selectedAnywhereTags.length == 0) return [];
		var tagsByItem = Item.findSelected().collect(function(item){ return Item.tags(item); });

		return selectedAnywhereTags.findAll(function(tag){
			return tagsByItem.all(function(itemTags){
				return itemTags.any(function(itemTag){
//					if (! self.tag && ! self.itemTag) return false;
					return itemTag.domId == tag.domId;
				});
			});
		}).sortBy(function(tag){
			return tag.name.toLowerCase();
		});
	},
	
	// tags by the current user on all selected items
	findSelectedCurrentUser: function() {
		return Tag.findSelected().reject(function(tag){
			var tagUserItems = User.taggings(User.findCurrent()).select(function(tagging){
				return tagging.tagDomId == tag.domId;
			}).collect(function(tagging){
				return Item.find(tagging.itemDomId);
			});

			if (tagUserItems.length == 0) return [];

			return Item.findSelected().any(function(selectedItem){
				return ! tagUserItems.any(function(userItem){
					return selectedItem.domId == userItem.domId;
				});
			});
		});
	},
	
	// tags by non-current users on every selected item
	findSelectedOtherUsers: function() {
		return Tag.findSelected().reject(function(tag){
			var tagOthersItems = Tagging.findAll().reject(function(tagging){
				return tagging.userDomId == User.findCurrent().domId;
			}).select(function(tagging){
				return tagging.tagDomId == tag.domId;
			}).collect(function(tagging){
				return Item.find(tagging.itemDomId);
			});

			if (tagOthersItems.length == 0) return [];

			return Item.findSelected().any(function(selectedItem){
				return ! tagOthersItems.any(function(othersItem){
					return selectedItem.domId == othersItem.domId;
				});
			});
		});
	}

});

var Tagging = new ActiveRecord();
Object.extend(Tagging, {
  destroyByTagNameAndItemDomIds: function(tagName, itemDomIds) {
    if (! tagName.length > 0) return;
    itemDomIds = itemDomIds.split(',');
    if (! itemDomIds.length > 0) return;

		// limit by user, item and tag name
    Tagging.findAllBy('userDomId', User.findCurrent().domId).select(function(tagging){
      return itemDomIds.include(tagging.itemDomId);
    }).select(function(tagging){
			return Tag.find(tagging.tagDomId).name == tagName;
		}).each(function(tagging){
      Tagging.destroy(tagging.domId);
    });
  }
});

var User = new ActiveRecord();
Object.extend(User, {
	create: function(newRecord) {
		if (this.domIdCache.indexOf(newRecord.domId) >= 0) {
			return false;
		} else {
			this.domIdCache.push(newRecord.domId);
			h = $H(newRecord);
			h.fullName = decodeURIComponent(h.fullName);
			h.sortName = decodeURIComponent(h.sortName);
			return this.attributes.push(h);
		}
	},
	
	taggings: function(user) {
		return Tagging.attributes.select(function(tagging){
			return tagging.userDomId == user.domId;
		});
	},
	
	tags: function(user) {
		return User.taggings(user).collect(function(tagging){
			return Tag.find(tagging.tagDomId);
		}).uniq();
	},
	
	permissions: function(user) {
		return Permission.attributes.select(function(permission){
			return permission.userDomId == user.domId;
		});
	},

	notifications: function(user) {
		return Notification.attributes.select(function(notification){
			return notification.userDomId == user.domId;
		});
	},

	findCurrent: function() {
		return User.findAll().detect(function(user){
			return user.current;
		});
	},
	
	canView: function(user, item) {
		if (Item.permissions(item).length == 0) return true;

		return Item.permissions(item).any(function(permission){
			return permission.userDomId == user.domId;
		});
	},
	
	isNotifiedOf: function(user, item) {
		return Notification.findAll().any(function(notification){
			return notification.userDomId == user.domId && notification.itemDomId == item.domId;
		});
	},
	
	findSorted: function() {
		return User.attributes.sortBy(function(user){ return user.sortName; });
	}
});

var Permission = new ActiveRecord();

var Notification = new ActiveRecord();
Object.extend(Notification, {
	acknowledge: function(domId) {
		notification = Notification.find(domId);
		$$('div#contentPane tr[notifyDomId=' + domId + ']').each(function(row){
			Effect.Fade(row, { duration: Joyent.effectsDuration, afterFinish: function(){
				if (row.hasClassName('itemRow')) JoyentPage.refreshPagination();
				row.remove();
				JoyentPage.restripe();
			} });
		});
		Notification.destroy(notification.domId);
	}
});
