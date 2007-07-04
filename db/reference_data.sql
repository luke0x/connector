-- Copyright 2004-2007 Joyent Inc.
-- 
-- Redistribution and/or modification of this code is governed
-- by either the GPLv2 or Joyent Commercial Software licenses.
-- 
-- Report issues and contribute at http://dev.joyent.com/
-- 
-- $Id$

SELECT pg_catalog.setval(pg_catalog.pg_get_serial_sequence('recurrence_descriptions', 'id'), 6, false);
SELECT pg_catalog.setval(pg_catalog.pg_get_serial_sequence('smart_group_attribute_descriptions', 'id'), 20, false);
SELECT pg_catalog.setval(pg_catalog.pg_get_serial_sequence('smart_group_descriptions', 'id'), 6, false);

COPY recurrence_descriptions (id, name, rule_text, seconds_to_increment, advance_arguments) FROM stdin;
3	Monthly	FREQ=MONTHLY	-1	--- \n:months: 1\n
1	Daily	FREQ=DAILY	86400	\N
5	Fortnightly	FREQ=WEEKLY;INTERVAL=2	1209600	\N
2	Weekly	FREQ=WEEKLY	604800	\N
4	Yearly	FREQ=YEARLY	-1	--- \n:years: 1\n
\.

COPY smart_group_attribute_descriptions (id, name, attribute_name, smart_group_description_id, body) FROM stdin;
1	Filename	filename	2	false
2	Owner Username	owner_name	2	false
3	Owner Username	owner_name	1	false
4	First Name	first_name	3	false
5	Company Name	company_name	3	false
6	Full Name	full_name	3	false
7	Last Name	last_name	3	false
8	Location	location	4	false
9	Notes	notes	4	false
10	Item Type	item_type	1	false
11	Owner Username	owner_name	4	false
14	Event Name	name	4	false
15	Repeat Type	recurrence_name	4	false
16	Owner Username	owner_name	5	false
17	From	from	5	false
18	To	to	5	false
19	Subject	subject	5	false
20	Any Condition		1	true
21	Any Condition		5	true
22	Any Condition		4	true
23	Any Condition		3	true
24	Any Condition		2	true
25	Date	date	5	false
26	Owner Username	owner_name	3	false
27	Status	status	5	false
28	Any Condition		6	true
29	Address	uri	6	false
30	Title	title	6	false
31	Notes	notes	6	false
32	Owner Username	owner_name	6	false
33	Item Type	item_type	7 false
34	Owner Username	owner_name	7	false
35	Any Condition		7	true
\.

COPY smart_group_descriptions (id, name, item_type) FROM stdin;
1	All Items	\N
2	Files	JoyentFile
3	People	Person
4	Events	Event
5	Messages	Message
6	Bookmarks	Bookmark
7	Lists	List
\.

COPY report_descriptions (id, name) FROM stdin;
1	connect_notifications
2	mail_notifications
3	files_notifications
4	calendar_notifications
5	people_notifications
6	connect_smart_group
7	mail_smart_group
8	files_smart_group
9	calendar_smart_group
10	people_smart_group
11	mailbox
12	folder
13	calendar
14	calendar_all
15	users
16	contacts
17	current_time
18	unread_messages
19	recent_comments
20	todays_events
21	weeks_events
22	bookmarks_notifications
23	bookmarks_all
24	bookmarks_everyone
25	bookmarks_smart_group
26  files_strongspace
27  files_service
28  lists_standard_group
29  lists_smart_group
30  lists_notifications
\.

COPY affiliates (id, name) FROM stdin;
1	joyent
2	corel
\.
