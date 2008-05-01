/*
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
*/

AddressManager = Class.create();
Object.extend(AddressManager.prototype, {
  initialize: function(to, cc, bcc) {
    this.to_addresses  = [];
    this.cc_addresses  = [];
    this.bcc_addresses = [];
	this.groups_ids = [];
	this.kind = '';
    
    if (to)  to.each((function(v, i)  { this.to_addresses.push(v);  }).bind(this));
    if (cc)  cc.each((function(v, i)  { this.cc_addresses.push(v);  }).bind(this));
    if (bcc) bcc.each((function(v, i) { this.bcc_addresses.push(v); }).bind(this));
  },

  addAddress: function(kind) {
  	this.kind = kind;
    address = $('message_' + kind + '_complete').value.strip();

    if (address != '') {
		if (address.indexOf('<') == -1 && address.indexOf('>') == -1){
			var groupName = address.substring(0, address.indexOf('(') - 1);
			var groupId = this.getGroupId(groupName);
			if (groupId != -1)
				this.addGroupEmailsAjax(kind, groupId);
		}else{
			name = address.substring(0, address.indexOf('<') - 1);
			email = address.substring(address.indexOf('<') + 1, address.indexOf('>'));		
			this[kind + '_addresses'].push(email);
		    $(kind + '_addresses').innerHTML += this.drawAddress(kind, name, email);	 			
		}		
	}

    $('message_' + kind + '_complete').value = '';
    $('message_' + kind + '_complete').activate();

	return false;
  },
	
  removeAddress: function(kind, id) {
		this[kind + '_addresses'][id] = null;
    $('address_' + kind + '_' + id).hide();

    return false;
	},

  addGroupEmailsAjax: function (kind, groupId) {
    var url = '/mail/add_group_emails_ajax?group_id=' + groupId;
    new Ajax.Request(url, {onComplete: this.onComplete.bind(this)});
  },	
  
  setGroupsIds: function (groupsIds){
  	groupsIds.each((function(v, i) { this.groups_ids.push(v); }).bind(this));
  },
  
  getGroupId: function (groupName){
	var index = -1;
	this.groups_ids.each(function(item){
			if (item.group_name == groupName)
				index = item.group_id;
	});  	
	return index;
  },
  
  onComplete: function (request) {
		request.responseText.evalJSON().each((function(item){
			this[this.kind + '_addresses'].push(item.email);
			$(this.kind + '_addresses').innerHTML += this.drawAddress(this.kind, item.name, item.email);		
		}).bind(this)); 
  },
	
  drawAddress: function(kind, name, email) {
		id = this[kind + '_addresses'].length;

		html = '';
		html += '<a href="#" onclick="';
		html += "return addresses.removeAddress('" + kind + "', '" + id + "');";
		html += '" class="removeEmail" id="address_' + kind + '_' + id + '" ';
		html += 'title="' + email + '">';
		html += name;
		html += '</a>';

		return html;
  },
  
  dumpAddresses: function() {
    if (! this.validateAdressesPresent()) return false;

    $('message_to').value  = this.to_addresses.compact().join(', ');
    $('message_cc').value  = this.cc_addresses.compact().join(', ');
    $('message_bcc').value = this.bcc_addresses.compact().join(', ');
  },
  
  validateAdressesPresent: function() {
    if (this.to_addresses.length  == 0 && $('message_to_complete').value.strip()  == '' &&
        this.cc_addresses.length  == 0 && $('message_cc_complete').value.strip()  == '' &&
        this.bcc_addresses.length == 0 && $('message_bcc_complete').value.strip() == '') {
      return false;
    } else {
      return true;
    }
  }
});
