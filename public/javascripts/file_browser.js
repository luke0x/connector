// Copyright 2004-2007 Joyent Inc.
// 
// Redistribution and/or modification of this code is governed
// by either the GPLv2 or Joyent Commercial Software licenses.
// 
// Report issues and contribute at http://dev.joyent.com/
// 
// $Id$


FileBrowser = Class.create();
Object.extend(FileBrowser.prototype, {

	initialize: function() {
	},

  selectYourComputerUi: function () {
    $('fromConnectorUI').hide();
    if (this.allow_from_url) $('fromURLUI').hide();
    $('fromComputerUI').show();

		return false;
  },

  selectConnectorUi: function () {
    if ($('fromComputerUI')) $('fromComputerUI').hide();
    if ($('fromURLUI')) $('fromURLUI').hide();
		$('attachmentFromConnector').checked = 'checked';

		$('fromConnectorUI').innerHTML = Joyent.loadingMessageSmall;
    new Ajax.Updater('fromConnectorUI', '/files/browser');

    $('fromConnectorUI').show();

		return false;
  },

  selectUrlUi: function () {
    if ($('fromComputerUI')) $('fromComputerUI').hide();
    if ($('fromConnectorUI')) $('fromConnectorUI').hide();
    $('fromURLUI').show();
		$('attachmentFromURL').checked = 'checked';
		$('person_icon_url').activate();
		
		return false;
  },

  selectConnectorFolder: function(folderId) {
    var url = '/files/browser?folder_id=' + escape(folderId);
    var options = {
      onLoading: function (transport) {
				$('file_browser_file_list').innerHTML = Joyent.loadingMessageSmall;
				$('fileBrowserFolder' + folderId).addClassName('selected');
      }
    };
    new Ajax.Updater('fromConnectorUI', url, options);

		return false;
  },

  selectConnectorFile: function (fileId, fileName) {
		$$('div#file_browser_file_list ul li.selected').each(function(element){ element.removeClassName('selected'); });
		$('fileBrowserFile' + fileId).addClassName('selected');
		uploads.addJoyentFile(fileId, fileName);

/*	
    if (this.options.target_type == 'mail') {
      this.mail_attach_ajax(fileId);
    }
    else if (this.options.target_type == 'contact_icon') {
     	var url = 'http://' + connectorDomain + '/files/download/' + fileId;
      $(this.options.url_field_id).value = url;
		  $(this.options.icon_preview_id).setAttribute('src', url);
			$('file_browser_selected_file_status').innerHTML = '<strong>' + url + '</strong>';
    }
*/
  },

  mail_attach_ajax: function (fileId) {
    var url = '/mail/add_attachment_ajax?file_id=' + fileId + '&id=' + this.options.target_id;
    var options = {
      onComplete: function (transport) {
        $('attachUI').hide();
      }
    };
    new Ajax.Updater('attachmentList', url, options);
  },

  attachment_delete_ajax: function (url) {
    var options = {
      onLoading: function (transport) {
        $('attachmentList').innerHTML = JoyentL10n['Deleting...'];
      }
    };
    new Ajax.Updater('attachmentList', url, options);
  }

});

var file_browser = new FileBrowser();
