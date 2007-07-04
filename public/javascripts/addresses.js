// Copyright 2004-2007 Joyent Inc.
// 
// Redistribution and/or modification of this code is governed
// by either the GPLv2 or Joyent Commercial Software licenses.
// 
// Report issues and contribute at http://dev.joyent.com/
// 
// $Id$


AddressManager = Class.create();
Object.extend(AddressManager.prototype, {
  initialize: function(to, cc, bcc) {
    this.to_addresses  = [];
    this.cc_addresses  = [];
    this.bcc_addresses = [];
    
    if (to)  to.each((function(v, i)  { this.to_addresses.push(v);  }).bind(this));
    if (cc)  cc.each((function(v, i)  { this.cc_addresses.push(v);  }).bind(this));
    if (bcc) bcc.each((function(v, i) { this.bcc_addresses.push(v); }).bind(this));
  },

	addAddress: function(kind) {
    address = $('message_' + kind + '_complete').value.strip();

    if (address != '') {
	    $(kind + '_addresses').innerHTML += this.drawAddress(kind, address);
	    this[kind + '_addresses'].push(address);
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
	
  drawAddress: function(kind, address) {
		id = this[kind + '_addresses'].length;

		html = '';
		html += '<a href="#" onclick="';
		html += "return addresses.removeAddress('" + kind + "', '" + id + "');";
		html += '" class="removeEmail" id="address_' + kind + '_' + id + '">';
		html += address;
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
