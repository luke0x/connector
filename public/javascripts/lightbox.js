/*
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
*/

// heavily modified by http://joyent.com
// created by Chris Campbell http://particletree.com 2/1/2006
// inspired by http://www.huddletogether.com/projects/lightbox/

Lightbox = Class.create();
Object.extend(Lightbox.prototype, {
	yPos: 0,
	xPos: 0,

	initialize: function(element) {
	},

/*	initialize: function(element) {
		this.content = element.href;
		Event.observe(element, 'click', this.show.bindAsEventListener(this), false);
		element.onclick = function(){ return false; };
	},
*/	
	show: function() {
		if (navigator.appVersion.match(/\bMSIE\b/)) {
			// get scroll, taken from lightbox implementation found at http://www.huddletogether.com/projects/lightbox/
			if (self.pageYOffset) this.yPos = self.pageYOffset;
			else if (document.documentElement && document.documentElement.scrollTop) this.yPos = document.documentElement.scrollTop; 
			else if (document.body) this.yPos = document.body.scrollTop;
			this.setIE('100%', 'hidden');
			window.scrollTo(0, 0);
			this.setSelects('hidden');
		}
		this.setDisplay('block');
	},

	hide: function() {
		if (e = $('lbContent')) e.remove();
		if (navigator.appVersion.match(/\bMSIE\b/)) {
			window.scrollTo(0, this.yPos);
			this.setIE("auto", "auto");
			this.setSelects('visible');
		}
		this.setDisplay('none');
	},
	
	// Ie requires height to 100% and overflow hidden or else you can scroll down past the lightbox
	setIE: function(height, overflow) {
		bod = document.getElementsByTagName('body')[0];
		bod.style.height = height;
		bod.style.overflow = overflow;
  
		htm = document.getElementsByTagName('html')[0];
		htm.style.height = height;
		htm.style.overflow = overflow; 
	},
	
	// select elements hover on top of the lightbox in ie
	setSelects: function(visibility) {
		selects = document.getElementsByTagName('select');
		for(i = 0; i < selects.length; i++) {
			selects[i].style.visibility = visibility;
		}
	},
		
	setDisplay: function(display) {
		$('overlay').style.display = display;
//		$('modalDialog').style.display = display;
		if (display != 'none') {
//			Event.observe('overlay', 'click', JoyentPage.hideEverything.bindAsEventListener(this), false);
			// Begin Ajax request based off of the href of the clicked linked
//			new Ajax.Request("/test.html", {method: 'get', parameters: "", onComplete: this.processInfo.bindAsEventListener(this)});
//			this.showStuff();
		}
	},
	
	showStuff: function() {
		info = '<div id="lbContent">yo hello</div>';
		new Insertion.Before($('lbLoadMessage'), info)
//		$('modalDialog').className = "done";	
	},
	
	// Display Ajax response
	processInfo: function(response) {
		info = "<div id='lbContent'>" + response.responseText + "</div>";
		new Insertion.Before($('lbLoadMessage'), info)
		$('modalDialog').className = "done";	

		// Search through new links within the lightbox, and attach click event
		lbActions = document.getElementsByClassName('lbAction');
		for(i = 0; i < lbActions.length; i++) {
			Event.observe(lbActions[i], 'click', this[lbActions[i].rel].bindAsEventListener(this), false);
			lbActions[i].onclick = function(){ return false; };
		}
	}
	
// Example of creating your own functionality once lightbox is initiated
//	insert: function(e) {
//	  link = Event.element(e).parentNode;
//	  $('lbContent').remove();
//	  var myAjax = new Ajax.Request(link.href, { method: 'post', parameters: "", onComplete: this.processInfo.bindAsEventListener(this) });
//	},
});

//Event.observe(window, 'load', initialize, false);
function initialize() {
	addLightboxMarkup();
	lbox = document.getElementsByClassName('lbOn');
	for(i = 0; i < lbox.length; i++) {
		valid = new Lightbox(lbox[i]);
	}
}

// Add in markup necessary to make this work. Basically two divs:
// Overlay holds the shadow, Lightbox is the centered square that the content is put into.
function addLightboxMarkup() {
	bod 				  = document.getElementsByTagName('body')[0];
	overlay 			= document.createElement('div');
	overlay.id		= 'overlay';
	lb				  	= document.createElement('div');
	lb.id			  	= 'modalDialog';
	lb.className 	= 'loading';
	lb.innerHTML	= '<div id="lbLoadMessage"><p>Loading</p></div>';
	bod.appendChild(overlay);
	bod.appendChild(lb);
}
