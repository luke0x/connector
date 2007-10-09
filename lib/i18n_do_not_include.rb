=begin #(fold)
++
Copyright 2004-2007 Joyent Inc.

Redistribution and/or modification of this code is 
governed by the GPLv2.

Report issues and contribute at http://dev.joyent.com/

$Id$
--
=end #(end)

# This is an small trick in order to make available for GetText some strings
# whose values we know what are going to be, but aren't hardcoded on source.

# With them, you can call _() function containing a variable name witch a value
# which matches anything on the .pot file, and the string value of that variable
# will be localized too. 
i18n_do_not_include = [
  # controller.class.group_name.pluralize.capitalize and beyond!
  _('Mailboxes'), 
  _('Folders'), 
  _('Calendars'), 
  _('Groups'), 
  _('Bookmarks'),
  _('Bookmark Folders'),
  _('Lists'),
  _('List Folders'),
  # matching conditions for smart groups
  _('Any Condition'),
  _('Item Type'),
  _('Owner Username'), 
  _('Event Name'), 
  _('Repeat Type'),
  _('Company Name'),
  _('Full Name'),
  _('Filename'),
  # Singular for applications
  _('Group'),
  _('Calendar'),
  _('Folder'),
  _('Mailbox'),
  _('People'),
  _('Mail'),
  _('Bookmark Folder'),
  _('List'),
  # time in words for calendar event's hour/minutes
  _('hour'),
  _('hours'),
  _('minute'),
  _('minutes'),
  # joyent_file_type.rb
  _('Audio')
  _('Cascading Style Sheet')
  _('Document')
  _('Flash Video')
  _('HTML Document')
  _('Image')
  _('JavaScript')
  _('PDF Document')
  _('Photoshop Image')
  _('Presentation')
  _('Protected Audio')
  _('Source Code')
  _('Spreadsheet')
  _('TeX')
  _('Text')
  _('Unknown Type')
  _('Video')
  _('vCalendar')
  _('vCard')
  # item types
  _('notifications'),
  _('people'),
  _('messages'),
  _('files'),
  _('bookmarks'),
  _('comments'),
  _('lists'),
  # subscription
  _('listfolder'),
  _('bookmark folder'),
  _('calendar'),
  _('mailbox'),
  _('folder'),
  _('group'),
  # have to add in order to localize it
  _('Connect Notifications'),
  # some list strings localized through the row method
  _('Move Left'),
  _('Move Right'),
  _('Select Previous'),
  _('Select Next'),
  _('Collapse'),
  _('Expand'),
  _('ListFolder'),
  _('Spacebar'),
  _('Toggle First Checkbox'),

  # images

  # sidebar tabs
  _('Groups'),
  _('Tags'),
  _('Access'),
  _('Permissions'),
  _('Notify'),
  _('Notifications')
]
