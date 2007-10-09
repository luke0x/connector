/*
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
*/


var Calendar = {

	setupEdit: function() {
		$('event_name').activate();
	},

	validateSubmit: function(form) {
	  arrErrors = [];

	  // require a name
	  if ($('event_name').value.strip() == "") arrErrors.push(JoyentL10n['You must give a name to the event.']);

	  // require a start date
	  if ($('event_start_month').value.strip() == "" ||
	      $('event_start_day').value.strip() == "" ||
	      $('event_start_year').value.strip() == "") {
	    arrErrors.push(JoyentL10n['You must specify a complete start date.']);
	  }

	  // require either an all day event
	  if ($('event_all_day_true').checked == true) {
	    // do nothing, this is ok
	  // or if it's not all day
	  } else if ($('event_all_day_false').checked == true) {
	    // a start time
	    if ($('event_start_hour').value.strip() == "" ||
	        $('event_start_minute').value.strip() == "") {
	      arrErrors.push(JoyentL10n['You must specify a start time.']);
	    }
	    // and a duration
	    if ($('event_duration_hours').value.strip() == "" &&
	        $('event_duration_minutes').value.strip() == "") {
	      arrErrors.push(JoyentL10n['You must specify an event duration.']);
	    }
	  }

		// prep sidebar data
		$('new_item_tags').value          = JoyentPage.createTags.collect(function(tag){ return tag.escapeCharacter(','); }).join(',,');
		$('new_item_permissions').value   = JoyentPage.createPermissions.join(',');
		$('new_item_notifications').value = JoyentPage.createNotifications.join(',');

	  if (validateErrorsArray(arrErrors)) {
	    preventFormResubmission(form);
	    return true;
	  } else {
	    return false;
	  }
	},
	
	validateSubmitImport: function(form) {
  	arrErrors = [];

	  if (form.icalendar.value.strip() == "") arrErrors.push(JoyentL10n['You must select a file to import.']);

	  if (validateErrorsArray(arrErrors)) {
	    preventFormResubmission(form);
	    return true;
	  } else {
	    return false;
	  }
	},

	changeRepeat: function() {
	  if ($F('event_repeat') == '') {
	    $('event_repeat_options').hide();
			$('event_recur_end_year').value  = '';
			$('event_recur_end_month').value = '';
			$('event_recur_end_day').value   = '';
		} else {
			if ($F('event_repeat') == 'weekly') $('event_by_day_options').show();
			if ($F('event_recur_end_year') == '')  $('event_recur_end_year').value  = $F('event_start_year');
			if ($F('event_recur_end_month') == '') $('event_recur_end_month').value = $F('event_start_month');
			if ($F('event_recur_end_day') == '')   $('event_recur_end_day').value   = $F('event_start_day');
	    	$('event_repeat_options').show();
			$('event_recur_end_month').activate();
		}
	},

	// additional work when a calendar list checkbox is clicked
	checkEvent: function(checkbox) {
		itemDomId = checkbox.readAttribute('itemDomId');
		$$('div#contentPane input[type=checkbox][itemDomId=' + itemDomId + ']').each(function(element){
			element.checked = checkbox.checked;
		});
	},

	showTimeChart: function(day_view_url, chart_date) {
	  $('collapsed_day_view_' + chart_date).hide();
	  $('expanded_day_view_' + chart_date).show();
	  $('day_view_row_' + chart_date).show();

	  $('day_view_td_' + chart_date).innerHTML = Joyent.loadingMessageSmall;
		new Ajax.Updater('day_view_td_' + chart_date, day_view_url, {asynchronous:true, evalScripts:true});

	  return false;
	},

	hideTimeChart: function(chart_date) {
	  $('expanded_day_view_' + chart_date).hide();
	  $('day_view_row_' + chart_date).hide();
	  $('collapsed_day_view_' + chart_date).show();

	  $('day_view_td_' + chart_date).innerHTML = '';

	  return false;
	},

	setToToday: function() {
		now = new Date();
		$('event_start_year').value = now.getFullYear().toString();
		$('event_start_month').value = (now.getMonth() + 1).toString();
		$('event_start_day').value = now.getDate().toString();
	},

	setToAllDay: function() {
		$('event_start_hour').value       = '';
		$('event_start_minute').value     = '';
		$('event_duration_hours').value   = '';
		$('event_duration_minutes').value = '';
		$('event_start_hour').disabled       = true;
		$('event_start_minute').disabled     = true;
		$('event_start_ampm_am').disabled    = true;
		$('event_start_ampm_pm').disabled    = true;
		$('event_duration_hours').disabled   = true;
		$('event_duration_minutes').disabled = true;
	},

	setToNotAllDay: function() {
		$('event_start_hour').disabled       = false;
		$('event_start_minute').disabled     = false;
		$('event_start_ampm_am').disabled    = false;
		$('event_start_ampm_pm').disabled    = false;
		$('event_duration_hours').disabled   = false;
		$('event_duration_minutes').disabled = false;
		$('event_start_hour').focus();
	},

	setToForever: function() {
		$('event_recur_end_month').value = '';
		$('event_recur_end_day').value   = '';
		$('event_recur_end_year').value  = '';
		$('event_recur_end_month').disabled = true;
		$('event_recur_end_day').disabled   = true;
		$('event_recur_end_year').disabled  = true;
	},

	setToNotForever: function() {
		$('event_recur_end_month').disabled = false;
		$('event_recur_end_day').disabled   = false;
		$('event_recur_end_year').disabled  = false;
		$('event_recur_end_month').focus();
	}

}

var CalendarImportDrawer = {
	setToExisting: function() {
		$('existing_calendar_radio').checked = true;
		$('new_calendar').disabled = true;
		$('existing_calendar').disabled = false;
	},
	
	setToNew: function() {
		$('new_calendar_radio').checked = true;
		$('new_calendar').disabled = false;
		$('existing_calendar').disabled = true;
		$('new_calendar').activate();
	}
}
