// Simple JavaScript Calendar

var JSCalendar = Class.create();
JSCalendar.prototype = {
	// We accept upto 3 arguments for this constructor:
	// The same first 3 arguments than Date constructor can take
	initialize: function() {
		switch(arguments.length) {
			case 2:
				this.refDate = new Date(arguments[0], arguments[1]);
			break;
			case 3:
				this.refDate = new Date(arguments[0], arguments[1], arguments[2]);
			break;
			default:
				this.refDate = new Date(arguments[0]);
			break;
		}
		
		this.currentDate = new Date();
	},
	// We have to localize this couple of arrays
	monthNames: [
		JoyentL10n['January'], 
		JoyentL10n['February'], 
		JoyentL10n['March'], 
		JoyentL10n['April'], 
		JoyentL10n['May'], 
		JoyentL10n['June'], 
		JoyentL10n['July'], 
		JoyentL10n['August'], 
		JoyentL10n['September'], 
		JoyentL10n['October'], 
		JoyentL10n['November'], 
		JoyentL10n['December']
	],
	abbreviatedMonthNames: [
		JoyentL10n['Su'],
		JoyentL10n['Mo'], 
		JoyentL10n['Tu'], 
		JoyentL10n['We'], 
		JoyentL10n['Th'], 
		JoyentL10n['Fr'], 
		JoyentL10n['Sa']
	],
	// Returns the days for the month used to build the object
	daysInMonth: function () {
	   return new Date(this.refDate.getFullYear(), this.refDate.getMonth()+1, 0).getDate()
	},
	// Return the month name for the month used to build the object
	getMonthName: function() {
	   return this.monthNames[this.refDate.getMonth()]; 
	},
	// Sets internal reference Date to the same day of the next month (not needed)
	nextMonth: function() {
		// Javascript knows that the day after the current month's last day is the first day for
		// the next month
		this.refDate = new Date(this.refDate.getFullYear(), this.refDate.getMonth(), this.daysInMonth()+1);
	},
	// Sets internal reference Date to the same day of the previous month (not needed)
	prevMonth: function() {
		// Javascript returns the previous month if you pass a zero day to a month
		this.refDate = new Date(this.refDate.getFullYear(), this.refDate.getMonth(), 0);
	},
	// Sets internal reference Date to the same day of the next year (not needed)
	nextYear: function() {
		this.refDate = new Date(this.refDate.getFullYear()+1, this.refDate.getMonth());
	},
	// Sets internal reference Date to the same day of the previous year (not needed)
	prevYear: function() {
		this.refDate = new Date(this.refDate.getFullYear()-1, this.refDate.getMonth());
	},
	// Creates the HTML required to build the calendar table
	// Note that this will add onclick events to all calendar days using the 
	// function JSCalendar.JSCalendar.doSelectDay(y,m,d) 
	// and to JSCalendar.selectMonth(y,m) which needs to be defined.
	drawMonthCalendar: function(field_name) {

		// The number of days in the month (when date=0 Javascript gives last date of previous month).
		var numDays = this.daysInMonth();
		// Get the starting day of this calendar, mon, tue, wed, etc.
		var startDay= new Date(this.refDate.getFullYear(), this.refDate.getMonth(), 1).getDay();

		// We'll build our table in the buildStr variable then pass what we build back.
		// This will be a HTML table -- Build the header rows...
		var buildStr ='<div id="jsCalendar"><table summary="Calendar" class="jscalendar" style="text-align: center">';
		buildStr+= '<tr class="jscalendar-table-title">';
		// Do not allow previous month navigation when firstValidDate is in the current month or earlier:
		if(JSCalendar.firstValidDate && (JSCalendar.firstValidDate > (new Date(this.refDate.getFullYear(), this.refDate.getMonth(), 1)))) {
			buildStr+='<th><a href="#" class="prev-month">&#60;</a></th>';
		}else {
			buildStr+='<th><a href="#" class="prev-month" onclick="JSCalendar.selectMonth('+this.refDate.getFullYear()+','+(this.refDate.getMonth()-1)+',\''+field_name+'\')">&#60;</a></th>';
		}
		
		buildStr+='<th colspan=5>'+this.getMonthName()+' '+this.refDate.getFullYear()+'</th>';
		buildStr+='<th><a href="#" class="next-month" onclick="JSCalendar.selectMonth('+this.refDate.getFullYear()+','+(this.refDate.getMonth()+1)+',\''+field_name+'\')">&#62;</a></th>';
		buildStr+='</tr>';
		
		// Day Headers
		buildStr+='<tr>';
		for(var i=0; i<this.abbreviatedMonthNames.length; i++){
			buildStr+='<th>'+this.abbreviatedMonthNames[i]+'</th>';
		}
		buildStr+='</tr>';

		buildStr+='<tr>';

		// No link on dates until we get to the day which actually starts the month
		
		// We'll need the number of previous padding days at end, when adding
		// the next month padding:
		padding = 0;
		for(var i=0; i<startDay; i++) {
			// This is the number of days we have to substract to the current month in
			// order to have past month days
			j = 0 - (startDay - i -1);
			padding++;
			prev_month_date = new Date(this.refDate.getFullYear(),this.refDate.getMonth(),j);
		  buildStr+='<td>'+prev_month_date.getDate()+'</td>';
		}
		
		// Border is a counter, initialize it with the number of "blank" days at the
		// start of the calendar.  Now each time we add a new date we'll do a modulus
		// 7 and check for 0 (remainder of border/7 = 0), if it's zero it's time to
		// make a new row.
		var border=startDay;

		// For each day in the month, insert it into the calendar.
		for(i=1; i<=numDays; i++) {
			the_day = new Date(this.refDate.getFullYear(), this.refDate.getMonth(), i);
			if(JSCalendar.firstValidDate && (JSCalendar.firstValidDate > the_day)){
				if(this.isCurrentDate(i)){
					buildStr+='<td id="day_'+i+'" class="today-day">'+i+'</td>';
				}else {
					buildStr+='<td id="day_'+i+'">'+i+'</td>';
				}
			}else {
				if(this.isCurrentDate(i)) {
					buildStr+='<td class="today-day"><a href="#" id="day_'+i+'" onclick="JSCalendar.doSelectDay('+this.refDate.getFullYear()+','+this.refDate.getMonth()+','+i+',\''+field_name+'\')">'+i+'</a></td>';
				}else {
					buildStr+='<td><a href="#" id="day_'+i+'" onclick="JSCalendar.doSelectDay('+this.refDate.getFullYear()+','+this.refDate.getMonth()+','+i+',\''+field_name+'\')">'+i+'</a></td>';
				}
			}

		   
			border++;
			if (((border%7)==0)&&(i<numDays)) {
			   // Time to start a new row, if there are any days left.
			   buildStr+='</tr><tr>';
			}
		}

		// All the days have been used up, so just pad empty days until the
		// end of the calendar with the day numbers for the next month.
		while((border++%7)!=0) {
			next_month_date = new Date(this.refDate.getFullYear(),this.refDate.getMonth(),(border-padding));
		  buildStr+='<td>'+next_month_date.getDate()+'</td>';
		}

		// Finish the table.
		buildStr+='</tr>';
		buildStr+='</table></div>';

		// return it.
		return buildStr;
	},
	
	isCurrentDate: function(day){
		return (this.refDate.getMonth() == this.currentDate.getMonth()) && (this.refDate.getFullYear() == this.currentDate.getFullYear()) && (day == this.currentDate.getDate());
	},
	selectDay: function(day) {
		// Remove any selected day
		$$('.selected-day').each(function(s){
			s.removeClassName('selected-day');
		});
		$("day_"+day).addClassName('selected-day');
	}
	
}

// These functions rely on the date field id being passed as argument.
// It expects them to be named following Rails conventions
JSCalendar.doSelectDay = function (year, month, day, field_name) {
	// Remove any selected day
	$$('.selected-day').each(function(s){
		s.removeClassName('selected-day');
	});
	$("day_"+day).addClassName('selected-day');
	$(field_name + '_1i').value = year;
	$(field_name + '_2i').value = month+1;
	$(field_name + '_3i').value = day;
}

JSCalendar.selectMonth = function(year, month, field_name) {
	d = new JSCalendar(year, month, 1);
	Element.replace('jsCalendar', d.drawMonthCalendar(field_name));
	if ($(field_name + '_2i').value == (month+1) && $(field_name + '_1i').value == year){
		JSCalendar.doSelectDay(year, month, $(field_name + '_3i').value, field_name);
	}
}

JSCalendar.printCalendar = function(field_name) {
	var cal_day = $(field_name + '_3i').value;
	var cal_month = $(field_name + '_2i').value -1;
	var cal_year = $(field_name + '_1i').value;
	d = new JSCalendar(cal_year, cal_month, cal_day);
	Element.replace('jsCalendar', d.drawMonthCalendar(field_name));
	d.selectDay(cal_day);
}

JSCalendar.createCalendar = function(field_name) {
	$(field_name + '_3i').hide();
	$(field_name + '_2i').hide();
	$(field_name + '_1i').hide();
	JSCalendar.printCalendar(field_name);
}
// Calendar will not draw links for dates previous to this one when given
JSCalendar.firstValidDate = null;


