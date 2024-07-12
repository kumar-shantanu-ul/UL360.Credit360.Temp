-- Please update version.sql too -- this keeps clean builds in sync
define version=2390
@update_header

update csr.plugin set cs_class='Credit360.Issues.IssueCalendarDto'
where js_class='Credit360.Calendars.Issues';

@../enable_body

@update_tail
