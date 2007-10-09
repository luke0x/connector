/*
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
*/
// load this after prototype.js

Object.extend(Array.prototype, {
	// toggles the presence of value in an array
	toggleValue: function(value) {
		if (this.include(value)) {
			this.splice(this.indexOf(value), 1);
		} else {
	    this.push(value);		
		}
	  return true;
	},
	
  // inserts +value+ at +position+ and returns it as an array, eg:
  // >>> [1,2,3].insertAt(1, "foo")
  // [1,"foo",2,3]
  insertAt: function(position, value) {
    if (position >=0) {
      var first = this.slice();
      var second = first.splice(position, this.length);
      first[position] = value;
      return first.concat(second);
    }
  },
  
  // >>> ["foo", "bar", "baz"].moveValue("baz", 0)
  // ["baz","foo","bar"]
  moveValue: function(value, newpos) {
    if (newpos >= 0) {
      results = this.reject(function(e){ return e == value });
      results = results.insertAt(newpos, value);
      return results;
    }
  }
});

String.prototype.underscoreToTitlecase = function() {
	var str = this.gsub("_", " ");
	str = str.toLowerCase();

	var befores = str.split(" ");
	if (befores.length == 0) return befores[0];

	var afters = [];
	for (var i=0; i < befores.length; i++) {
	  afters[i] = befores[i].substr(0,1).toUpperCase() + befores[i].substr(1, befores[i].length);
	}

	return afters.join(" ");
};

String.prototype.escapeCharacter = function(character) {
  return this.replace('\\', '\\\\').replace(character, '\\' + character);
};

String.prototype.unescapeCharacter = function(character) {
  return this.replace('\\' + character, character).replace('\\\\', '\\');
};

Effect.SlideRight = function(element) {
  element = $(element);
  Element.cleanWhitespace(element);
  // SlideDown need to have the content of the element wrapped in a container element with fixed height!
  var oldInnerRight = Element.getStyle(element.firstChild, 'right');
  var elementDimensions = Element.getDimensions(element);
  return new Effect.Scale(element, 100, Object.extend({ 
    scaleContent: false, 
    scaleY: false, 
    scaleFrom: 0,
    scaleMode: {originalHeight: elementDimensions.height, originalWidth: elementDimensions.width},
    restoreAfterFinish: true,
    afterSetup: function(effect) { with(Element) {
      makePositioned(effect.element);
      makePositioned(effect.element.firstChild);
      if(window.opera) setStyle(effect.element, {top: ''});
      makeClipping(effect.element);
      setStyle(effect.element, {width: '0px'});
      show(element); }},
    afterUpdateInternal: function(effect) { with(Element) {
      setStyle(effect.element.firstChild, {right:
        (effect.dims[0] - effect.element.clientWidth) + 'px' }); }},
    afterFinishInternal: function(effect) { with(Element) {
      undoClipping(effect.element); 
      undoPositioned(effect.element.firstChild);
      undoPositioned(effect.element);
      setStyle(effect.element.firstChild, {right: oldInnerRight}); }}
    }, arguments[1] || {})
  );
}

Effect.SlideLeft = function(element) {
  element = $(element);
  Element.cleanWhitespace(element);
  var oldInnerRight = Element.getStyle(element.firstChild, 'right');
  return new Effect.Scale(element, 0, 
   Object.extend({ scaleContent: false, 
    scaleY: false, 
    scaleMode: 'box',
    scaleFrom: 100,
    restoreAfterFinish: true,
    beforeStartInternal: function(effect) { with(Element) {
      makePositioned(effect.element);
      makePositioned(effect.element.firstChild);
      if(window.opera) setStyle(effect.element, {top: ''});
      makeClipping(effect.element);
      show(element); }},  
    afterUpdateInternal: function(effect) { with(Element) {
      setStyle(effect.element.firstChild, {right:
        (effect.dims[0] - effect.element.clientWidth) + 'px' }); }},
    afterFinishInternal: function(effect) { with(Element) {
        [hide, undoClipping].call(effect.element); 
        undoPositioned(effect.element.firstChild);
        undoPositioned(effect.element);
        setStyle(effect.element.firstChild, {right: oldInnerRight}); }}
   }, arguments[1] || {})
  );
}

// http://agileweb.org/articles/2006/07/28/onload-final-update
//Object.extend(Event, {
//  observe: function(element, name, observer, useCapture) {
//    var element = $(element);
//    useCapture = useCapture || false;
//    if (name == 'keypress' && (navigator.appVersion.match(/Konqueror|Safari|KHTML/) || element.attachEvent))
//      name = 'keydown';
//    if (name == 'load' && element.screen)
//      this._observeLoad(element, name, observer, useCapture);
//    else
//      this._observeAndCache(element, name, observer, useCapture);
//  },
//  _observeLoad : function(element, name, observer, useCapture) {
//    if (!this._readyCallbacks) {
//      var loader = this._onloadWindow.bind(this);
//      if (document.addEventListener)
//          document.addEventListener("DOMContentLoaded", loader, false);
//      /*@cc_on @*/
//      /*@if (@_win32)
//         if (! $("__ie_onload")) {
//            document.write("<script id='__ie_onload' defer='true' src='://'><\/script>");
//            var script = $("__ie_onload");
//            script.onreadystatechange = function() { if (this.readyState == "complete") loader(); };
//        } else {
//            loader();
//        }
//      /*@end @*/
//      if (navigator.appVersion.match(/Konqueror|Safari|KHTML/i))
//        Event._timer = setInterval(function() {if
//(/loaded|complete/.test(document.readyState))loader();}, 10);
//      Event._readyCallbacks =  [];
//      this._observeAndCache(element, name, loader, useCapture);
//    }
//    Event._readyCallbacks.push(observer);
//  },
//  _onloadWindow : function() {
//    if (arguments.callee.done) return;
//    arguments.callee.done = true;
//    if (this._timer) clearInterval(this._timer);
//    this._readyCallbacks.each(function(f) { f() });
//    this._readyCallbacks = null;
//  }
//});
//

Ajax.Responders.register({
  onCreate: function() {
    if (Ajax.activeRequestCount > 0) $('plusMenuLink').addClassName('pulsing');
  },
  onComplete: function() {
    if (Ajax.activeRequestCount == 0) $('plusMenuLink').removeClassName('pulsing');
  }
});
