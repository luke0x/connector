/*
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
*/

Ajax.InPlaceEditor.prototype.__leaveHover    = Ajax.InPlaceEditor.prototype.leaveHover;
Ajax.InPlaceEditor.prototype.__getText       = Ajax.InPlaceEditor.prototype.getText;
Ajax.InPlaceEditor.prototype.__enterEditMode = Ajax.InPlaceEditor.prototype.enterEditMode;
Ajax.InPlaceEditor.prototype.__onSubmit      = Ajax.InPlaceEditor.prototype.onSubmit;
Ajax.InPlaceEditor.prototype.__showSaving    = Ajax.InPlaceEditor.prototype.showSaving;
Ajax.InPlaceEditor.prototype.__leaveEditMode = Ajax.InPlaceEditor.prototype.leaveEditMode;

Field.scrollFreeActivate = function(field) {
  setTimeout(function() {
    field.focus();
  }, 1);
}

Object.extend(Ajax.InPlaceEditor.prototype, {
  leaveHover: function() {
    if (this.options.backgroundColor) {
      this.element.style.backgroundColor = this.oldBackground;
    }
    this.element.removeClassName(this.options.hoverClassName);
  },

  // we have elements with a "non-existant" column value contain &nbsp; in the view, so get rid of that...
  getText: function(){
    if (this.element.hasClassName('listEditable') &&
        this.element.hasClassName('number') &&
        this.__getText().match(/\+/)) {
      return '+';
    } else if (this.__getText().strip() == '&nbsp;') {
			return '';
		} else {
			return this.__getText().strip();
		}
  },

  onKeyPress: function(event) {
    if (this.editing){
      switch(event.keyCode) {
  	  case Event.KEY_RETURN:
    		this.editField.blur();
				break;
      case Event.KEY_TAB:
        // save it, if needed
        this.onSubmit();
        this.activateNextCell(this.element.id);
				break;
      case Event.KEY_ESC:
        this.onclickCancel();
				break;
      }
    }
  },

  enterEditMode: function(evt) {
    if (Prototype.Browser.WebKit) {
      var editStyles = {
        width: ($(this.element).up().getWidth() - parseInt($(this.element).up().getStyle('padding-left')) - 4) + 'px',
  			height: ($(this.element).up().getHeight() - 3) + 'px'
  		}
    } else { // gecko
      var editStyles = {
        width: ($(this.element).up().getWidth() - parseInt($(this.element).up().getStyle('padding-left')) - 5) + 'px',
  			height: ($(this.element).up().getHeight() - 5) + 'px'
  		}
    }
    this.__enterEditMode(evt);

    Event.observe(this.editField, 'keypress', this.onKeyPress.bindAsEventListener(this));
    this.originalContent = this.getText();
    this.editField.setAttribute("autocomplete", "off"); // gecko bug, make it not throw JS exception https://bugzilla.mozilla.org/show_bug.cgi?id=236791
  	this.initialEditText = this.editField.value;
	  $(this.editField).setStyle(editStyles);
	  
	  ListRow.select(this.element.up('tr').readAttribute('arid'));
  },

  onLeaveEditMode: function(){
    Event.stopObserving(this.editField, 'keypress', this.onKeyPress.bindAsEventListener(this));
  },

  activateNextCell: function(elem) {
  	$$('div.listEditable').each(function(e, index) {
  		if (e.id == elem) {
  			var nextCell = $$('div.listEditable')[index + 1];
  			try {
  			  List.cellInPlaceEditors[nextCell.id].enterEditMode();
			  } catch(e) {
			    throw $break;
		    }
  			throw $break;
  		}
  	});
  },

  onSubmit: function(event) {
	  if (this.initialEditText == this.editField.value) {
	  	this.onclickCancel();
	  } else {
	    this.__onSubmit();
	  }
	  return false;
	},
	
  // NOTE: not calling __showSaving
	showSaving: function() {
    this.oldInnerHTML = this.element.innerHTML;
    this.element.innerHTML = this.editField.value; // changed
    this.element.addClassName(this.options.savingClassName);
	  $(this.element.up('tr').id + '_selector').addClassName('saving');
    this.element.style.backgroundColor = this.originalBackground;
    this.element.show(); // ~changed
	},
	
	leaveEditMode: function() {
	  this.__leaveEditMode();
	  $(this.element.up('tr').id + '_selector').removeClassName('saving');
	}
});

var List = {
  selectedRow: null,
  selectedList: null,
  cellInPlaceEditors: {}, // list_row id => inPlaceEditor object

	init: function() {
	  if (Item.selectedEditable()) {
  	  Sortable.create("listHeaderColumns", {
  	    tag: 'th',
  	    only: 'columnHeaderValue',
  	    constraint: 'horizontal',
  	    overlap: 'horizontal',
  	    onChange: function(elem) {
    			$(elem).addClassName('handle');
   	    },
    		starteffect: function() {
    			this.lastValue = Sortable.serialize('listHeaderColumns');
    			new Effect.Opacity('listsTbody', { duration:0.5, from:1.0, to:0.2 });
    		},
    		endeffect: function(elem) {
    			$(elem).removeClassName('handle');
    			if (this.lastValue == Sortable.serialize('listHeaderColumns')) {
    				new Effect.Opacity('listsTbody', { duration:0.5, from:0.2, to:1.0 });
    			}
    		},
    		onUpdate: function(elem) { 
        	new Ajax.Request('/list_columns/reorder/' + List.selectedList, { 
            asynchronous:true, 
            evalScripts:true,
            parameters:Sortable.serialize('listHeaderColumns', { name:"list_columns" })
          });
        }
	    });
    }

		List.restripe();
		List.toggleExpanded(true);
	},
	
	editDisable: function() {
	  $('list_name').disable();
	  $('list_name_save').disable();
	  $('list_name_loading').show();
	},
	
	editEnable: function() {
	  $('list_name').enable();
	  $('list_name_save').enable();
	  List.rememberDrawerValues();
	  $('list_name_loading').hide();
	},
	
	rememberDrawerValues: function() {
	  List.name = $F('list_name');
	  List.columnNames = $H();
	  $$('div#drawerEdit td.listColumnNamesTd input').each(function(i){
	    List.columnNames[i.id] = $F(i.id);
	  });
	},
	
	drawerHide: function() {
	  // save changed fields
	  if ($F('list_name') != List.name) $('list_name').up('form').onsubmit();
	  List.columnNames.each(function(n){
	    if ($F(n.key) != n.value) $(n.key).up('form').onsubmit();
	  });
      Drawers.hide('Edit');
      this.fadeUp('listsTbody');
	},
	
	onKeyPress: function(event) {
		if (Event.element(event).tagName == 'INPUT') return;
		if (ListCell.anyEditing()) return;
		
		if (List.selectedRow != null) {
			if (event.ctrlKey && event.shiftKey) { // ctrl-shift
				switch(event.keyCode || event.charCode) {
				case Event.KEY_UP:
					ListRow.moveUp();
					break;
				case Event.KEY_DOWN:
					ListRow.moveDown();
					break;
    		    case Event.KEY_LEFT:
      		        ListRow.outdent();
					break;
    		    case Event.KEY_RIGHT:
					ListRow.indent();
					break;
				case 68: // d
					ListRow.destroy();
					break;
    		    }
			} else if (event.shiftKey) {
				switch(event.keyCode || event.charCode) {
    		    case Event.KEY_UP:
      		        ListRow.selectPrevious();
					break;
    		    case Event.KEY_DOWN:
      		        ListRow.selectNext();
					break;
				case Event.KEY_LEFT:
					ListRow.collapse(List.selectedRow);
					break;
				case Event.KEY_RIGHT:
					ListRow.expand(List.selectedRow);
					break;
				}
			} else {
                switch(event.keyCode || event.charCode) {
				case 32: // spacebar
				  ListRow.toggleCheckbox();
				  break;
    		}
			}
		} else {
			if (event.ctrlKey && (event.keyCode == Event.KEY_UP || event.keyCode == Event.KEY_DOWN)) {
			  ListRow.selectFirst();
			}
		}
		if (event.shiftKey && event.ctrlKey && event.charCode == 78 | event.keyCode == 78) { // ctrl-shift-n
			ListRow.create();
		}
	},
 
	selectedMoveUpable: function() {
	  if (! Item.selectedEditable()) return false;
		if (! List.selectedRow) return false;
		var listRow = $('list_row_' + List.selectedRow);
		
		if (listRow.hasClassName('root')) {
		  if (listRow.previousSiblings().length == 0) {
		    return false;
		  } else {
		    return listRow.previousSiblings().any(function(sibling){
		      return sibling.hasClassName('root');
		    });
		  }
		} else {
		  if (! listRow.previousSiblings().any(function(r){ return r.tagName == 'TR'; })) return false;
			var childClassName = listRow.classNames().detect(function(className){
				return className.match(/_child/) != null;
			});
			return listRow.previousSiblings().any(function(r){
			  return r.tagName == 'TR' && r.hasClassName(childClassName);
		  });
		}
	},
	
	selectedMoveDownable: function() {
	  if (! Item.selectedEditable()) return false;
		if (! List.selectedRow) return false;
		var listRow = $('list_row_' + List.selectedRow);
		
		if (listRow.hasClassName('root')) {
			if (listRow.nextSiblings().length == 0) {
				return false;
			} else {
				return listRow.nextSiblings().any(function(sibling){
					return sibling.hasClassName('root');
				});
			}
		} else {
			if (! listRow.nextSiblings().any(function(r){ return r.tagName == 'TR'; })) return false;

			var childClassName = listRow.classNames().detect(function(className){
				return className.match(/_child/) != null;
			});
			return listRow.nextSiblings().any(function(r){
			  return r.tagName == 'TR' && r.hasClassName(childClassName);
		  });
		}
	},

	selectedIndentable: function() {
	  if (! Item.selectedEditable()) return false;
		if (! List.selectedRow) return false;
		var listRow = $('list_row_' + List.selectedRow);

		if (listRow.hasClassName('root')) {
			return (listRow.previousSiblings().length > 0);
		} else {
			var childClassName = listRow.classNames().detect(function(className){
				return className.match(/_child/) != null;
			});
			return listRow.previousSiblings().any(function(prevRow){
				return prevRow.hasClassName(childClassName);
			});
		}
	},
	
	selectedOutdentable: function() {
	  if (! Item.selectedEditable()) return false;
		if (! List.selectedRow) return false;
		return ! $('list_row_' + List.selectedRow).hasClassName('root');
	},

	highlightRow: function(id) {
	  row = $('list_row_' + id);
	  row.addClassName('hover');
	},

	unhighlightRow: function(id) {
	  row = $('list_row_' + id);
	  row.removeClassName('hover');
	},

	refresh: function() {
	  new Ajax.Request('/lists/' + List.selectedList, { method:'get', asynchronous:true, evalScripts:true });
	},

	expandAll: function() {
		$$('table#tableList .itemRow').each(function(e){
			e.show();
			var dinger = $(e.id + '_dinger');
			if (dinger.hasClassName('collapsed'))
				dinger.removeClassName('collapsed').addClassName('expanded');
		});
		List.restripe();
	
    if (Item.selectedEditable()) {
  		new Ajax.Request('/lists/expand_all/' + List.selectedList, { asynchronous:true, evalScripts:true });
		}
		$('list_toggle_all').removeClassName('collapsed').addClassName('expanded');
	},

	collapseAll: function() {
		$$('table#tableList .itemRow').each(function(e){
			if (! e.hasClassName('root'))
				e.hide();
			var dinger = $(e.id + '_dinger');
			if (dinger.hasClassName('expanded'))
				dinger.removeClassName('expanded').addClassName('collapsed');
		});
		if (List.selectedRow != null) {
			selectedRow = $('list_row_' + List.selectedRow);
			if (! selectedRow.visible()) ListRow.deselect();
		}
		List.restripe();

	   	if (Item.selectedEditable()) {
	      new Ajax.Request('/lists/collapse_all/' + List.selectedList, { asynchronous:true, evalScripts:true });
	    }
		$('list_toggle_all').removeClassName('expanded').addClassName('collapsed');
	},

	toggleExpanded: function(onLoad) {
		var anyCollapsed = $$('table#tableList .itemRow a').any(function(e){
		  return e.hasClassName('collapsed');
		});
		if (anyCollapsed) {
			onLoad ? $('list_toggle_all').removeClassName('expanded').addClassName('collapsed') : List.expandAll();
		} else {
			onLoad ? $('list_toggle_all').removeClassName('collapsed').addClassName('expanded') :  List.collapseAll();
		}
	},

	restripe: function() {
	  rows = $$('table#tableList tr').findAll(function(element, index){
	 	return index > 0 && element.visible();
		});
	  rows.each(function(value, index){
	    if ((index + 1) % 2 == 0) {
	      value.removeClassName('evenRow').addClassName('oddRow');
	    } else {
	      value.removeClassName('oddRow').addClassName('evenRow');
	    }
	  });
	  return false;
	},

	editingListCell: function(elem) {
		return $$('td.listCell').find(function(e) {
			return $(e).immediateDescendants().include($(elem));
		});
	},
	
	fadeUp: function(elem) {
	    if ($(elem).getStyle('opacity') < 1) {
              new Effect.Opacity(elem, { duration:2.0, from:0.2, to:1.0 });
          }
	},
	
	fadeDown: function(elem) {
	    if ($(elem).getStyle('opacity') > 0.2) {
              new Effect.Opacity(elem, { duration:0.5, from:1.0, to:0.2 });
          }
	},
	
	updateList: function(html) {
	    if (Ajax.activeRequestCount > 1) {
	        $('listContainer').update(html);
	    } else {
	        $('listContainer').setStyle({opacity:0.2});
	        $('listContainer').update(html);
	        this.fadeUp('listContainer');
	    }
	}
};

var ListRow = {
	
	create: function() {
	  if (! Item.selectedEditable()) return false;

		var params = $H();
		if (List.selectedList) params['list_id'] = List.selectedList.toString();
		
        if (List.selectedRow) params['selected_list_row_id'] = List.selectedRow.toString();
        
		new Ajax.Request('/list_rows?' + params.toQueryString(), { method: 'post', asynchronous:true, evalScripts:true,
			onSuccess: function(request){
				$('listContainer').update(request.responseText);
			},
			onComplete: function(){
			    window.setTimeout(function(){
                    List.cellInPlaceEditors[$$('table tbody tr td div[new_row="true"]').first().id].enterEditMode();
			    }, 500);
			}
		});
	},

	select: function(listRowId) {
	  if (!(row = $('list_row_' + listRowId))) return;

		ListRow.deselect();
    List.selectedRow = listRowId;
    row.addClassName('selected').scrollTo();

		Toolbar.refresh();
	},
	
	deselect: function() {
    List.selectedRow = null;
    $$('tbody#listsTbody tr').each(function(row){
      row.removeClassName('selected');
    });

		Toolbar.refresh();
	},

  toggleSelected: function(listRowId) {
	  if (!(row = $('list_row_' + listRowId))) return;

    if (row.hasClassName('selected')) {
			ListRow.deselect();
    } else {
			ListRow.select(listRowId);
    }
  },
  
  selectFirst: function() {
    ListRow.select($$('table#tableList .itemRow').first().readAttribute('arid'));
  },

	selectPrevious: function() {
		if (List.selectedRow == null) return false;
		var row = $('list_row_' + List.selectedRow);
		if (row.previousSiblings().any(function(r){ return r.tagName == 'TR' && r.visible(); })) {
			var previousRow = row.previousSiblings().detect(function(r){ return r.tagName == 'TR' && r.visible(); }).readAttribute('arid');
			ListRow.select(previousRow);
		}
	},
	
	selectNext: function() {
		if (List.selectedRow == null) return false;
		var row = $('list_row_' + List.selectedRow);
		if (row.nextSiblings().any(function(r){ return r.tagName == 'TR' && r.visible(); })) {
			var nextRow = row.nextSiblings().detect(function(r){ return r.tagName == 'TR' && r.visible(); }).readAttribute('arid');
			ListRow.select(nextRow);
		}
	},

	expand: function(listRowId) {
    $$('tbody#listsTbody tr.list_row_' + listRowId + '_child').each(function(e){
     ListRow.recursiveExpand(e);
    });
		if ($('list_row_' + listRowId + '_dinger').hasClassName('collapsed')) {
			$('list_row_' + listRowId + '_dinger').removeClassName('collapsed').addClassName('expanded');
			List.restripe();
      if (Item.selectedEditable()) {
  			new Ajax.Request('/list_rows/expand/' + listRowId, { asynchronous:true, evalScripts:true });
			}
			ListRow.select(listRowId);
		}
	},
	
	recursiveExpand: function(listRow) {
		listRow.show();
		listRowDinger = $(listRow.id + '_dinger');
		if (listRowDinger.hasClassName('expanded')) {
			$$('tbody#listsTbody tr.' + listRow.id + '_child').each(function(e){
				ListRow.recursiveExpand(e);
			})
		}
	},
	
	collapse: function(listRowId) {
    $$('tbody#listsTbody tr.list_row_' + listRowId + '_child').each(function(e){
     ListRow.recursiveCollapse(e);
    });

		if ($('list_row_' + listRowId + '_dinger').hasClassName('expanded')) {
	    $('list_row_' + listRowId + '_dinger').removeClassName('expanded').addClassName('collapsed');
			List.restripe();
			if (Item.selectedEditable()) {
  			new Ajax.Request('/list_rows/collapse/' + listRowId, { asynchronous:true, evalScripts:true });
			}
      ListRow.select(listRowId);
		} else {
			var listRow = $('list_row_' + listRowId);
			var listRowParent = ListRow.parentOf(listRow);
			if (! listRowParent) return false;

			ListRow.collapse(listRowParent.readAttribute('arid'));
			ListRow.select(listRowParent.readAttribute('arid'));
		}
	},
	
	parentOf: function(row) {
		if (row.hasClassName('root')) return undefined;

		var parentRegex = /list_row_([0-9]+)_child/;
		var c = row.classNames().detect(function(name){
			return name.match(parentRegex);
		});
		var parentRowId = c.match(parentRegex)[1];
		return $('list_row_' + parentRowId);
	},
	
	recursiveCollapse: function(listRow) {
		listRow.hide();
		$$('tbody#listsTbody tr.' + listRow.id + '_child').each(function(e){
			ListRow.recursiveCollapse(e);
		})
	},
	
	toggleExpanded: function(listRowId) {
		if ($('list_row_' + listRowId + '_dinger').hasClassName('expanded')) {
			ListRow.collapse(listRowId);
		} else {
			ListRow.expand(listRowId);
		}
	},

	destroy: function() {
	  if (! Item.selectedEditable()) return false;
    if (! List.selectedRow) {
      alert('A row must be selected to delete it.');
      return false;
    }
    var row = $('list_row_' + List.selectedRow);
    new Ajax.Request('/list_rows/' + List.selectedRow.toString(), { method: 'delete', asynchronous:true, evalScripts:true, onSuccess:function(){
			ListRow.recursiveRemove(row);
      List.restripe();
      ListRow.deselect();
			Toolbar.refresh();
			ListRow.refreshParentDinger(row);
    }});
    return false;
  },

  refreshParentDinger: function(row) {
    var parentRow = ListRow.parentOf(row);
    if (! parentRow) return false;
    if ($$('tbody#listsTbody tr.' + parentRow.id + '_child').length > 0) return false; // nothing to refresh if siblings remaining

    $(parentRow.id + '_dinger').removeClassName('expanded');
    return false;
  },

  recursiveRemove: function(listRow) {
    $$('tbody#listsTbody tr.' + listRow.id + '_child').each(function(e){
			ListRow.recursiveRemove(e);
		});
		listRow.remove();
	},

  moveUp: function() {
    if (! List.selectedRow) return false;
		if (! List.selectedMoveUpable()) return false;

    new Ajax.Request('/list_rows/up/' + List.selectedRow, { asynchronous:true, evalScripts:true,
			onComplete:function(){
				Toolbar.refresh();
			}
		});
    return false;
  },

  moveDown: function() {
    if (! List.selectedRow) return false;
		if (! List.selectedMoveDownable()) return false;

    new Ajax.Request('/list_rows/down/' + List.selectedRow, { asynchronous:true, evalScripts:true,
			onComplete:function(){
				Toolbar.refresh();
			}
		});
    return false;
  },

  indent: function() {
    if (! List.selectedRow) return false;
		if (! List.selectedIndentable()) return false;

    new Ajax.Request('/list_rows/indent/' + List.selectedRow, { asynchronous:true, evalScripts:true,
			onComplete:function(){
				Toolbar.refresh();
			}
		});
    return false;
  },
  
  outdent: function() {
    if (! List.selectedRow) return false;
		if (! List.selectedOutdentable()) return false;

    new Ajax.Request('/list_rows/outdent/' + List.selectedRow, { asynchronous:true, evalScripts:true,
			onComplete:function(){
				Toolbar.refresh();
			}
		});
    return false;
  },
  
  toggleCheckbox: function() {
    if (! List.selectedRow) return false;
    
    var checkboxes = $$('tbody#listsTbody tr#list_row_' + List.selectedRow + ' input.listEditable.checkbox');
    if (checkboxes.length > 0) {
      checkboxes.first().click();
    }
  }

}

var ListCell = {
	
	createIPE: function(element_id, url) {
    if (! Item.selectedEditable()) return false;

		var ipe = new Ajax.InPlaceEditor(element_id, url, {
			hoverClassName: 'inplaceeditor-hover',
			okButton: false,
			cancelLink: false,
			onComplete: function(){},
			highlightcolor: 'transparent',
			submitOnBlur: true,
			ajaxOptions: {method: 'put'},
			rows: 2
		});
		
	  // firefox doesn't adjust cell height based on contents (for multi-line rows)
		if (Prototype.Browser.Gecko) {
      var e = $(element_id);
      var h = (e.up().getHeight() - 5) + 'px';
		  e.setStyle({ height:h });

      Event.observe(window, 'resize', function(){
        $(element_id).setStyle({ height:'' });
      });
		}

		List.cellInPlaceEditors[element_id] = ipe;
	},
	
	updateCheckbox: function(listCellId) {
    if (! Item.selectedEditable()) return false;

	  new Ajax.Request('/list_cells/' + listCellId, { method:'put', asynchronous:true, evalScripts:true, parameters:'value=' + $F('list_cell_' + listCellId) });
	},
	
	anyEditing: function() {
	  return $$('table tbody#listsTbody td.listCell textarea').length == 1;
	}
	
}

var ListColumn = {
	validateDelete: function() {
	  if ($$("div#Drawers div#drawerEdit ul#list_columns li").length > 1) {
	    return true;
	  } else {
	    alert('The last list column can not be deleted.');
	    return false;
	  }
	},
	
	toggleEdit: function(id) {
		if ($('delete_column_' + id + '_loading').visible()) {
			$('list_column_name_' + id).enable();
			$('list_column_' + id + '_kind').enable();
			$('delete_column_' + id).show();
			$('delete_column_' + id + '_loading').hide();
		} else {
            new Effect.Opacity('listContainer', { duration:0.5, from:1.0, to:0.2 });
            $('list_column_name_' + id).disable();
            $('list_column_' + id + '_kind').disable();
            $('delete_column_' + id).hide();
            $('delete_column_' + id + '_loading').show();
		}
	},

	tempColumn: '<li id="temp_column"><table><tbody><tr><td class="listColumnNamesTd"><form><input id="list_column_name" type="text" value="New Column" style="width: 150px;" name="list_column[name]" disabled="disabled"/></form></td><td><select id="list_column_kind" name="list_column[kind]" disabled="disabled"><option value="Text">Text</option><option value="Checkbox">Checkbox</option></select></td><td><div class="loadingMessageSmall" style="background-position:0;"></div></td></tr></tbody></table></li>'
}
