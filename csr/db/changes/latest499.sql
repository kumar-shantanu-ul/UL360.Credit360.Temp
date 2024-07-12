-- Please update version.sql too -- this keeps clean builds in sync
define version=499
@update_header

alter table alert_type add (send_trigger varchar2(2000), sent_from varchar2(2000));

begin
update alert_type
   set send_trigger = 'The "welcome" button on the user list page is clicked.',
	   sent_from = 'This is sent from the user who clicked "send" on the user page'
 where alert_type_id = 1;

update alert_type
   set send_trigger = 'A new delegation is created and the creator requests that users be notified. New delegation notifications are grouped together and sent out in a single e-mail. At most one e-mail will be sent per day.',
	   sent_from = 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
 where alert_type_id = 2;

update alert_type
   set send_trigger = 'A sheet has not been submitted, but is is past the due date. Overdue notifications are grouped together and sent out in a single e-mail. At most one e-mail will be sent per day.',
	   sent_from = 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
 where alert_type_id = 3;

update alert_type
   set send_trigger = 'The state of a sheet changes (by submitting, approving, rejecting or merging).',
	   sent_from = 'The user who changed the state.'
 where alert_type_id = 4;

update alert_type
   set send_trigger = 'A sheet has not been submitted, but is is past the reminder date. Reminder notifications are grouped together and sent out in a single e-mail. At most one e-mail will be sent per day.',
	   sent_from = 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
 where alert_type_id = 5;

update alert_type
   set send_trigger = 'A delegation chain is terminated. Termination notifications are grouped together and sent out in a single e-mail. At most one e-mail will be sent per day.',
	   sent_from = 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
 where alert_type_id = 7;

update alert_type
   set send_trigger = 'A new sheet is created.',
	   sent_from ='The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
 where alert_type_id = 9;

update alert_type
   set send_trigger = 'A sheet is submitted. This alert goes to the user who submitted the sheet.',
	   sent_from = 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
 where alert_type_id = 10;

update alert_type
   set send_trigger = 'A submitted sheet is rejected. This alert goes to the user who submitted the sheet.',
	   sent_from = 'The user who rejected the sheet.'
 where alert_type_id = 11;

update alert_type
   set send_trigger = 'A sheet is subdelegated. This alert goes to the user or users who the sheets were subdelegated to',
	   sent_from = 'The user who delegated the sheet.'
 where alert_type_id = 12;

update alert_type
   set send_trigger = 'A sheet is submitted, but when it is the top person who has submitted. This alert goes to the user who submitted the sheet.',
	   sent_from = 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
 where alert_type_id = 13;

update alert_type
   set send_trigger = 'A submitted sheet is rejected, but when it is the top person who has submitted. This alert goes to the user who submitted the sheet.',
	   sent_from = 'The user who rejected the sheet.'
 where alert_type_id = 14;

update alert_type
   set send_trigger = 'A sheet is submitted for approval.',
	   sent_from = 'The user who submitted the sheet.'
 where alert_type_id = 15;

update alert_type
   set send_trigger = 'Data from a sheet is merged into the main database. This alert is sent to the data provider.',
	   sent_from = 'The user who merged the sheet.'
 where alert_type_id = 16;

update alert_type
   set send_trigger = 'A user makes a comment on an issue that you are involved in and requests that users be notified immediately.',
	   sent_from = 'The user who commented on the issue.'
 where alert_type_id = 17;

update alert_type
   set send_trigger = 'Their are comments made on issues you are involved in, but which you have not read. This is sent daily.',
	   sent_from = 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
 where alert_type_id = 18;

update alert_type
   set send_trigger = 'A document in the document library is updated and users have requested to be notified of changes to the document.',
	   sent_from = 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
 where alert_type_id = 19;

update alert_type
   set send_trigger = 'The "message" button on the user list page is clicked. The alert text can be customised before sending.',
	   sent_from = 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
 where alert_type_id = 20;

update alert_type
   set send_trigger = 'A user fills requests a self-registration request, this alert is sent to validate their e-mail address.',
	   sent_from = 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
 where alert_type_id = 21;

update alert_type
   set send_trigger = 'A user has filled out a self-registration request and succesfully validated their e-mail address. The alert is sent to the configured self register approver.',
	   sent_from = 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
 where alert_type_id = 22;

update alert_type
   set send_trigger = 'A user''s self-registration request has been approved.',
	   sent_from = 'The user who approved the self-registration request.'
 where alert_type_id = 23;

update alert_type
   set send_trigger = 'This alert is sent to a user when their account self-registration request is rejected.',
	   sent_from = 'The user who rejected the self-registration request.'
 where alert_type_id = 24;

update alert_type
   set send_trigger = 'This alert is sent when a user asks to reset their password by clicking the "have you forgotten your password" or "are you a new user" links on the home page.',
	   sent_from = 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
 where alert_type_id = 25;

update alert_type
   set send_trigger = 'This alert is sent to a user when they request a reset password link (by clicking the "have you forgotten your password" or "are you a new user" links on the home page) but their account has been deactivated.',
	   sent_from = 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
 where alert_type_id = 26;

update alert_type
   set send_trigger = 'A user is assigned to a product.',
   	   sent_from = 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
 where alert_type_id = 1000;

update alert_type
   set send_trigger = 'The activation state of a product is changed.',
   	   sent_from = 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
 where alert_type_id = 1001;
 
update alert_type
   set send_trigger = 'A product''s approval status is changed.',
   	   sent_from = 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
 where alert_type_id = 1002;

update alert_type
   set send_trigger = 'A work reminder is sent from the user list page.',
   	   sent_from = 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
 where alert_type_id = 1003;

update alert_type
   set send_trigger = 'An initiative is submitted.',
   	   sent_from = 'The submitting user.'
 where alert_type_id = 2000;

update alert_type
   set send_trigger = 'An initiative is approved.',
   	   sent_from = 'The approving user.'
 where alert_type_id = 2001;
 
update alert_type
   set send_trigger = 'An initiative is rejected.',
   	   sent_from = 'The rejecting user.'
 where alert_type_id = 2002;

update alert_type
   set send_trigger = 'An initiative has not been approved or rejected for some time.',
   	   sent_from = 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
 where alert_type_id = 2003;

update alert_type
   set send_trigger = 'On the first day of every month to relevant users.',
   	   sent_from = 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
 where alert_type_id = 2004;

update alert_type
   set send_trigger = 'A scheduled ethics mailout takes place.',
   	   sent_from = 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
 where alert_type_id = 3000;

update alert_type
   set send_trigger = 'A scheduled ethics mailout takes place.',
   	   sent_from = 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
 where alert_type_id = 3001;
 
update alert_type
   set send_trigger = 'A chain invitation is created.',
   	   sent_from = 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
 where alert_type_id = 5000;

update alert_type
   set send_trigger = 'A chain invitation is created.',
   	   sent_from = 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
 where alert_type_id = 5002;

update alert_type
   set send_trigger = 'A scheduled alert run takes place.',
   	   sent_from = 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
 where alert_type_id = 5003;

end;
/

alter table alert_type modify send_trigger not null;
alter table alert_type modify sent_from not null;

@..\alert_body

@update_tail
