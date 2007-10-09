/*
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
*/
Browser = Class.create();
Object.extend(Browser.prototype, {

	initialize: function() {
		this.columnWidth = 150;
		this.selected = "0";
		this.loadingHolder = new Template('<div id="loading" style="display:none;"> </div>');
	},
	
	browseComplete: function(elem) {
		$('browserFrame').scrollLeft = this.columnWidth;
		$('temp_column').remove();
		$('loading').hide();
	},
	
	browseBefore: function(elem) {
		this.removeOnceClicked(elem);
		
		var c = 0;
		$(elem).nextSiblings().each(function(element) {
			element.remove();
			c ++;
		});
		this.decreaseContainer(c);
	},
	
	subscribeFinish: function() {
		JoyentPage.hideEverything();
		window.location.reload();
	},
	
	typeId: function(type) {
		return type + "_column";
	},
	
	increaseContainer: function() {
		$('browserColumns').style.width = ($('browserColumns').getWidth() + this.columnWidth) + 'px';
	},
	
	decreaseContainer: function(count) {
		$('browserColumns').style.width = ($('browserColumns').getWidth() - (this.columnWidth * count)) + 'px';
	},
	
	makeSelected: function(elem, id) {
		this.addOnceClicked('browserFrame');
		$(elem).addClassName('highlighted');
		
		this.selected = id;
	},
	
	addOnceClicked: function(elem) {
		$(elem).getElementsByClassName('highlighted').each(function(element){
			if (!element.hasClassName('onceClicked')) { 
				element.removeClassName('highlighted').addClassName('onceClicked'); 
				}
 		});
	},
	
	removeOnceClicked: function(elem) {
		$(elem).getElementsByClassName('onceClicked').each(function(element){
			element.removeClassName('onceClicked');
		});
	},
	
	// Loading functions

	browseLoading: function (elem) {
		this.increaseContainer();
		if (elem) { this.removeOnceClicked(elem); }
		this.showColumnLoading('browserRow');
	},
	
	showColumnLoading: function(elem) {
		new Insertion.Bottom(elem, '<div class="browserList" id="temp_column"><div id="loading" style="display:none;"></div></div>');
		$('loading').update(Joyent.loadingMessageSmall).show();
	},
	
	showSmallLoading: function(elem, pos, name) {
		this.insertLoadingDiv(elem, pos, name);
		$(name).update(Joyent.loadingMessageSmall).show();
	},
	
	showLargeLoading: function(elem, pos, name) {
		this.insertLoadingDiv(elem, pos, name);
		$(name).update(Joyent.loadingMessageLarge).show();
	},
	
	insertLoadingDiv: function(elem, pos, name) {
		// call with pos(position) 'After' or 'Before' etc
		new Insertion[pos](elem, '<div id="'+name+'" style="display:none;"></div>');
	},
	
	subscribeLoading: function() {
		this.browseLoading();
	},
	
	// end loading functions
	
	removeBrowser: function() {
	  	if (b = $('browser')) b.remove();
	},
	
	// must be in the form of whatever_1
	getGroupId: function(elem) {
		return this.lastCharacter(elem);
	},
	
	lastCharacter: function(elem) {
		var s = elem;
		return s.charAt(s.length - 1);
	},
	
	showBrowser: function(elem, context, options, specificView) {
		var view = specificView ? '&view=' + specificView : ''
		return new Ajax.Updater(elem, '/browser/list?context=' + context + '&app=' + Joyent.applicationName.capitalize() + view, options);
	},
	
	submitAction: function(formName, callback) {
		if (callback.call()) $(formName).submit();
	}
	
});

var browser = new Browser();