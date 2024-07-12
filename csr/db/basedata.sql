/* If you're updating this then you should consider updating

	/aspen2/npsltr/WorkingTitle.cs

	to add to the SELECT statements in here so that strings get added to the translation resource file
	in /fproot/resource/tr.xml
*/

BEGIN
	INSERT INTO CSR.DB_CONFIG (ONLY_ONE_ROW) VALUES (0);
END;
/

BEGIN
INSERT INTO CSR.DASHBOARD_ITEM_COMPARISON_TYPE (COMPARISON_TYPE,DESCRIPTION) VALUES (1,'This period versus previous period');
INSERT INTO CSR.DASHBOARD_ITEM_COMPARISON_TYPE (COMPARISON_TYPE,DESCRIPTION) VALUES (2,'This period versus same period last year');
INSERT INTO CSR.DASHBOARD_ITEM_COMPARISON_TYPE (COMPARISON_TYPE,DESCRIPTION) VALUES (3,'Last known period versus previous period');
INSERT INTO CSR.DASHBOARD_ITEM_COMPARISON_TYPE (COMPARISON_TYPE,DESCRIPTION) VALUES (4,'Last known period versus same period last year');
INSERT INTO CSR.DASHBOARD_ITEM_COMPARISON_TYPE (COMPARISON_TYPE,DESCRIPTION) VALUES (5,'Year to date versus last year to date');
INSERT INTO CSR.DASHBOARD_ITEM_COMPARISON_TYPE (COMPARISON_TYPE,DESCRIPTION) VALUES (6,'Last full year versus year before last');
END;
/

BEGIN
INSERT INTO CSR.SHEET_ACTION ( SHEET_ACTION_ID, DESCRIPTION, COLOUR, DOWNSTREAM_DESCRIPTION ) VALUES ( 0, 'Data being entered', 'R', 'Data being entered');
INSERT INTO CSR.SHEET_ACTION ( SHEET_ACTION_ID, DESCRIPTION, COLOUR, DOWNSTREAM_DESCRIPTION ) VALUES ( 1, 'Pending approval', 'O', 'Submitted');
INSERT INTO CSR.SHEET_ACTION ( SHEET_ACTION_ID, DESCRIPTION, COLOUR, DOWNSTREAM_DESCRIPTION ) VALUES ( 2, 'Returned', 'R', 'Returned');
INSERT INTO CSR.SHEET_ACTION ( SHEET_ACTION_ID, DESCRIPTION, COLOUR, DOWNSTREAM_DESCRIPTION ) VALUES ( 3, 'Approved', 'G', 'Approved');
INSERT INTO CSR.SHEET_ACTION ( SHEET_ACTION_ID, DESCRIPTION, COLOUR, DOWNSTREAM_DESCRIPTION ) VALUES ( 4, 'Amended', 'G', 'Amended');
INSERT INTO CSR.SHEET_ACTION ( SHEET_ACTION_ID, DESCRIPTION, COLOUR, DOWNSTREAM_DESCRIPTION ) VALUES ( 5, 'Rejected', '-', 'Rejected');
INSERT INTO CSR.SHEET_ACTION ( SHEET_ACTION_ID, DESCRIPTION, COLOUR, DOWNSTREAM_DESCRIPTION ) VALUES ( 6, 'Approved, and changes made afterwards', 'G', 'Approved, and changes made afterwards');
INSERT INTO CSR.SHEET_ACTION ( SHEET_ACTION_ID, DESCRIPTION, COLOUR, DOWNSTREAM_DESCRIPTION ) VALUES ( 7, 'Partially submitted', '-', 'Partially submitted');
INSERT INTO CSR.SHEET_ACTION ( SHEET_ACTION_ID, DESCRIPTION, COLOUR, DOWNSTREAM_DESCRIPTION ) VALUES ( 8, 'Partially authorised', '-', 'Partially authorised');
INSERT INTO CSR.SHEET_ACTION ( SHEET_ACTION_ID, DESCRIPTION, COLOUR, DOWNSTREAM_DESCRIPTION ) VALUES ( 9, 'Merged with main database', 'G', 'Merged with main database');
INSERT INTO CSR.SHEET_ACTION ( SHEET_ACTION_ID, DESCRIPTION, COLOUR, DOWNSTREAM_DESCRIPTION ) VALUES (10, 'Data being entered', 'R', 'Data being entered');
INSERT INTO CSR.SHEET_ACTION ( SHEET_ACTION_ID, DESCRIPTION, COLOUR, DOWNSTREAM_DESCRIPTION ) VALUES (11, 'Pending approval - changes made after submission', 'O', 'Pending approval - changes made after submission');
INSERT INTO CSR.SHEET_ACTION ( SHEET_ACTION_ID, DESCRIPTION, COLOUR, DOWNSTREAM_DESCRIPTION ) VALUES (12, 'Merged, and changes made afterwards - will need remerge', 'R', 'Merged, and changes made afterwards - will need remerge');
INSERT INTO CSR.SHEET_ACTION ( SHEET_ACTION_ID, DESCRIPTION, COLOUR, DOWNSTREAM_DESCRIPTION ) VALUES (13, 'Data being entered', 'R', 'Data being entered');
END;
/

BEGIN
INSERT INTO CSR.AUDIT_TYPE_GROUP (AUDIT_TYPE_GROUP_ID, DESCRIPTION) VALUES (1, 'Securable object');
INSERT INTO CSR.AUDIT_TYPE_GROUP (AUDIT_TYPE_GROUP_ID, DESCRIPTION) VALUES (2, 'Supplier module product');
INSERT INTO CSR.AUDIT_TYPE_GROUP (AUDIT_TYPE_GROUP_ID, DESCRIPTION) VALUES (3, 'Supplier module questionnaire');
INSERT INTO CSR.AUDIT_TYPE_GROUP (AUDIT_TYPE_GROUP_ID, DESCRIPTION) VALUES (4, 'Chain objects');
INSERT INTO CSR.AUDIT_TYPE_GROUP (AUDIT_TYPE_GROUP_ID, DESCRIPTION) VALUES (5, 'Metric object');
INSERT INTO CSR.AUDIT_TYPE_GROUP (AUDIT_TYPE_GROUP_ID, DESCRIPTION) VALUES (6, 'Application object');
END;
/

@@basedata_audit_types

BEGIN
	INSERT INTO csr.std_alert_type_group (std_alert_type_group_id, description) VALUES (1, 'Users');
	INSERT INTO csr.std_alert_type_group (std_alert_type_group_id, description) VALUES (2, 'Delegations');
	INSERT INTO csr.std_alert_type_group (std_alert_type_group_id, description) VALUES (3, 'Actions');
	INSERT INTO csr.std_alert_type_group (std_alert_type_group_id, description) VALUES (4, 'Templated reports');
	INSERT INTO csr.std_alert_type_group (std_alert_type_group_id, description) VALUES (5, 'Document Library');
	INSERT INTO csr.std_alert_type_group (std_alert_type_group_id, description) VALUES (6, 'Framework Manager');
	INSERT INTO csr.std_alert_type_group (std_alert_type_group_id, description) VALUES (7, 'Audits');
	INSERT INTO csr.std_alert_type_group (std_alert_type_group_id, description) VALUES (8, 'Supply Chain');
	INSERT INTO csr.std_alert_type_group (std_alert_type_group_id, description) VALUES (9, 'SRM');
	INSERT INTO csr.std_alert_type_group (std_alert_type_group_id, description) VALUES (10, 'Teamroom');
	INSERT INTO csr.std_alert_type_group (std_alert_type_group_id, description) VALUES (11, 'Initiatives');
	INSERT INTO csr.std_alert_type_group (std_alert_type_group_id, description) VALUES (12, 'Ethics');
	INSERT INTO csr.std_alert_type_group (std_alert_type_group_id, description) VALUES (13, 'CMS');
	INSERT INTO csr.std_alert_type_group (std_alert_type_group_id, description) VALUES (14, 'Other');
	INSERT INTO csr.std_alert_type_group (std_alert_type_group_id, description) VALUES (15, 'Compliance');
END;
/

DECLARE
	ALERT_GROUP_USERS			NUMBER(10) := 1;
	ALERT_GROUP_DELEGTIONS		NUMBER(10) := 2;
	ALERT_GROUP_ACTIONS			NUMBER(10) := 3;
	ALERT_GROUP_TPLREPORTS		NUMBER(10) := 4;
	ALERT_GROUP_DOCLIBRARY		NUMBER(10) := 5;
	ALERT_GROUP_CORPREPORTER	NUMBER(10) := 6;
	ALERT_GROUP_AUDITS			NUMBER(10) := 7;
	ALERT_GROUP_SUPPLYCHAIN		NUMBER(10) := 8;
	ALERT_GROUP_SRM				NUMBER(10) := 9;
	ALERT_GROUP_TEAMROOM		NUMBER(10) := 10;
	ALERT_GROUP_INITIATIVES		NUMBER(10) := 11;
	ALERT_GROUP_ETHICS			NUMBER(10) := 12;
	ALERT_GROUP_CMS				NUMBER(10) := 13;
	ALERT_GROUP_OTHER			NUMBER(10) := 14;
	ALERT_GROUP_COMPLIANCE		NUMBER(10) := 15;
BEGIN
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (1, 'Welcome message',
	'The "welcome" button on the user list page is clicked.',
	'This is sent from the user who clicked "send" on the user page', ALERT_GROUP_USERS);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (2, 'New sub-delegation',
	'You manually sub-delegate a form and choose to notify users by clicking ''Yes - send e-mails''',
	'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', ALERT_GROUP_DELEGTIONS
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (3, 'Delegation data overdue',
	'A sheet has not been submitted, but it is past the due date. Overdue notifications are grouped together and sent out in a single e-mail. At most one e-mail will be sent per day. Only overdue notifications within the last 365 days are considered.',
	'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', ALERT_GROUP_DELEGTIONS
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (4, 'Delegation state changed',
	'The state of a sheet changes (by submitting, approving or rejecting).',
	'The user who changed the state.', ALERT_GROUP_DELEGTIONS
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (5, 'Delegation data reminder',
	'A sheet has not been submitted, but it is past the reminder date. Reminder notifications are grouped together and sent out in a single e-mail. At most one e-mail will be sent per day. Only reminder notifications within the last 365 days are considered.',
	'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', ALERT_GROUP_DELEGTIONS
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (7, 'Delegation terminated',
	'A delegation chain is terminated. Termination notifications are grouped together and sent out in a single e-mail. At most one e-mail will be sent per day.',
	'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', ALERT_GROUP_DELEGTIONS
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (8, 'Delegation plan - forms updated',
	 q'[This alert is sent when the user rolls out changes to existing forms by clicking Synchronise changes on the template for the delegation plan. 'Update delegation' notifications are grouped together and sent out in a single e-mail. At most one e-mail will be sent per day.]',
	 'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', ALERT_GROUP_DELEGTIONS
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (9, 'Mail sent when new approval step form created',
	'A new sheet is created.',
	'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', ALERT_GROUP_DELEGTIONS
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (10, 'Mail sent thanking user for submission of data',
	'A sheet is submitted. This alert goes to the user who submitted the sheet.',
	'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', ALERT_GROUP_DELEGTIONS
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (11, 'Mail sent to user when their data is rejected',
	'A submitted sheet is rejected. This alert goes to the user who submitted the sheet.',
	'The user who rejected the sheet.', ALERT_GROUP_DELEGTIONS
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (12, 'Mail sent to subdelegee when sub-delegation takes place',
	'A sheet is subdelegated. This alert goes to the user or users who the sheets were subdelegated to',
	'The user who delegated the sheet.', ALERT_GROUP_DELEGTIONS
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, PARENT_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (13, 10, 'Mail sent thanking user for submitting to approval step owner',
	'A sheet is submitted, but when it is the top person who has submitted. This alert goes to the user who submitted the sheet.',
	'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', ALERT_GROUP_DELEGTIONS
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, PARENT_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (14, 11, 'Mail sent when approval step owner rejects',
	'A submitted sheet is rejected, but when it is the top person who has submitted. This alert goes to the user who submitted the sheet.',
	'The user who rejected the sheet.', ALERT_GROUP_DELEGTIONS
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (15, 'Mail sent to approver when a new submission is made',
	'A sheet is submitted for approval.',
	'The user who submitted the sheet.', ALERT_GROUP_DELEGTIONS
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (16, 'Mail sent to data provider when final approval occurs',
	'Data from a sheet is merged into the main database. This alert is sent to the data provider.',
	'The user who merged the sheet.', ALERT_GROUP_DELEGTIONS
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (17, 'Mail sent when a comment is made on an issue',
	'A user makes a comment on an issue that you are involved in and requests that users be notified immediately.',
	'The user who commented on the issue.', ALERT_GROUP_ACTIONS
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (18, 'Mail sent containing issue summaries',
	'Their are comments made on issues you are involved in, but which you have not read. This is sent daily.',
	'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', ALERT_GROUP_ACTIONS
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (19, 'Mail sent when a document in the document library is updated',
	'A document in the document library is updated and users have requested to be notified of changes to the document.',
	'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', ALERT_GROUP_DOCLIBRARY
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (20, 'Generic mailout',
	'The "message" button on the user list page is clicked. The alert text can be customised before sending.',
	'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', ALERT_GROUP_USERS
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (21, 'Self register validate e-mail address',
	'A user fills requests a self-registration request, this alert is sent to validate their e-mail address.',
	'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', ALERT_GROUP_SUPPLYCHAIN
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (22, 'Self register notify administrator',
	'A user has filled out a self-registration request and succesfully validated their e-mail address. The alert is sent to the configured self register approver.',
	'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', ALERT_GROUP_SUPPLYCHAIN
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (23, 'Self register account approval',
	'A user''s self-registration request has been approved.',
	'The user who approved the self-registration request.', ALERT_GROUP_SUPPLYCHAIN
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (24, 'Self register account rejection',
	'This alert is sent to a user when their account self-registration request is rejected.',
	'The user who rejected the self-registration request.', ALERT_GROUP_SUPPLYCHAIN
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, OVERRIDE_USER_SEND_SETTING, STD_ALERT_TYPE_GROUP_ID, OVERRIDE_TEMPLATE_SEND_TYPE) VALUES (
	25, 'Password reset',
	'This alert is sent when a user asks to reset their password by clicking the "have you forgotten your password" or "are you a new user" links on the home page.',
	'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', 1, ALERT_GROUP_USERS, 1
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (26, 'Account disabled (password reset)',
	'This alert is sent to a user when they request a reset password link (by clicking the "have you forgotten your password" or "are you a new user" links on the home page) but their account has been deactivated.',
	'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', ALERT_GROUP_USERS
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (27, 'Approval step data reminder',
	'A sheet has not been submitted, but it is past the reminder date. Reminder notifications are grouped together and sent out in a single e-mail. At most one e-mail will be sent per day.',
	'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', ALERT_GROUP_DELEGTIONS
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (28, 'Approval step data overdue',
	'A sheet has not been submitted, but it is past the due date. Overdue notifications are grouped together and sent out in a single e-mail. At most one e-mail will be sent per day.',
	'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', ALERT_GROUP_DELEGTIONS
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (29, 'Delegation data change request',
	'This alert is sent when a user submits a request to change data on a previously submitted delegation.',
	'The user who is requesting the change.', ALERT_GROUP_DELEGTIONS
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (30, 'Delegation state changed',
	'The state of a sheet changes (by submitting, approving or rejecting). Notifications are grouped together and sent out in a single e-mail. At most one e-mail will be sent per day.',
	'The user who changed the state.', ALERT_GROUP_DELEGTIONS
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (31, 'Survey email',
	'A survey email is manually triggered.',
	'The user who triggers the survey release.', ALERT_GROUP_OTHER
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (32, 'Correspondent issue submission confirmation',
	'A issue is created and a correspondent (non-system user) is attached.',
	'A issue type configured address, or the configured system e-mail address when not found (this defaults to no-reply@cr360.com, but can be changed from the site setup page).',
	ALERT_GROUP_ACTIONS
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (33, 'Issue resolved response to correspondent',
	'A system user manually triggers a response to an issue correspondent.',
	'A issue type configured address, or the configured system e-mail address when not found (this defaults to no-reply@cr360.com, but can be changed from the site setup page).',
	ALERT_GROUP_ACTIONS
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (34, 'Message to issue correspondent or user',
	'A system user manually triggers an email to an issue correspondent or user.',
	'A issue type configured address, or the configured system e-mail address when not found (this defaults to no-reply@cr360.com, but can be changed from the site setup page).',
	ALERT_GROUP_ACTIONS
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (35, 'Issue rejected response to correspondent',
	'A system user manually triggers a rejection of an issue which has a correspondent.',
	'A issue type configured address, or the configured system e-mail address when not found (this defaults to no-reply@cr360.com, but can be changed from the site setup page).',
	ALERT_GROUP_ACTIONS
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (36, 'Correspondent notified when the issue priority is first set',
	'A system user manually sets the priority of an issue for the first time, and we notify the correspondent.',
	'A issue type configured address, or the configured system e-mail address when not found (this defaults to no-reply@cr360.com, but can be changed from the site setup page).',
	ALERT_GROUP_ACTIONS
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (37, 'Manual message to users providing data',
	'A user chooses to send a message to users who are providing data to them.',
	'The user who sends the e-mail.', ALERT_GROUP_OTHER
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (38, 'User cover started message',
	'A period of user cover starts.',
	'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', ALERT_GROUP_USERS
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (39, 'Delegation data changed by other user.',
	'User other than delegee(s) edit a value on a delegation form.',
	'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', ALERT_GROUP_DELEGTIONS
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (40, 'Funding Commitment Reminder',
	'Reminder date on Funding Commitment Setup.',
	'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', ALERT_GROUP_OTHER
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (41, 'Inbound e-mail processing failure',
	'A form that was e-mailed in was not processed correctly.',
	'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', ALERT_GROUP_OTHER
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (42, 'Inbound e-mail processed successfully',
	'A form that was e-mailed in was processed correctly.',
	'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', ALERT_GROUP_OTHER
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (43, 'Batch job completed',
	'A batch job has completed successfully.',
	'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', ALERT_GROUP_OTHER
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (44, 'Framework Manager question workflow state change',
	'The status of a question has changed in the workflow',
	'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', ALERT_GROUP_CORPREPORTER
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (45, 'Audits due to expire (reminder)',
	'There are audits that are about to expire that haven''t had a follow-up audit scheduled. This is sent daily.',
	'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', ALERT_GROUP_AUDITS
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (46, 'Audits expired (overdue)',
	'There are audits that have expired that haven''t had a follow-up audit scheduled. This is sent daily.',
	'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', ALERT_GROUP_AUDITS
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (47, 'Weekly issues coming due',
	'There are issues you are involved in that are about to become overdue. This is sent on a scheduled basis, e.g. weekly.',
	'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', ALERT_GROUP_ACTIONS
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (48, 'Framework Manager question reminder',
	'The date the question reminder is due',
	'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', ALERT_GROUP_CORPREPORTER
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (49, 'Framework Manager question overdue',
	'The date the question is due',
	'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', ALERT_GROUP_CORPREPORTER
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (50, 'Form automatically approved notification',
	'A form is automatically approved.',
	'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', ALERT_GROUP_OTHER
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (51, 'Form not automatically approved notification',
	'A form could not be automatically approved due to values changing significantly.',
	'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', ALERT_GROUP_OTHER
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (52, 'Framework Manager question submitted',
  'A user submits a question to the next user in the routing',
  'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', ALERT_GROUP_CORPREPORTER
);

INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (53, 'Framework Manager question returned',
  'A user returns a question to the previous user in the routing',
  'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', ALERT_GROUP_CORPREPORTER
);

INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (54, 'Teamroom invitation',
  'A teamroom invitation is created.',
  'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', ALERT_GROUP_TEAMROOM
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (55, 'Teamroom membership termination',
  'A user is removed from a teamroom.',
  'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', ALERT_GROUP_TEAMROOM
);

INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (56, 'Section document now available notification',
	'A document for a section has been checked in and is now available for user to change.',
	'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', ALERT_GROUP_CORPREPORTER
);

INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (57, 'Delegation returned',
  'A delegation sheet has been returned.',
  'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', ALERT_GROUP_DELEGTIONS
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (58, 'Delegation data change request approved',
	'This alert is sent when a user approves a delegation data change request.',
	'The user who is approving the change request.', ALERT_GROUP_DELEGTIONS
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (59, 'Delegation data change request rejected',
	'This alert is sent when a user rejects a delegation data change request.',
	'The user who is rejecting the change request.', ALERT_GROUP_DELEGTIONS
);

INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (60, 'Issues due to expire (reminder)',
	'There are issues that are about to expire. This is sent daily.',
	'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', ALERT_GROUP_ACTIONS
);
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (61, 'Issues expired (overdue)',
	'There are issues that have expired. This is sent daily.',
	'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', ALERT_GROUP_ACTIONS
);

INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (62, 'Delegation edited',
	'Sent when an approver approves a sheet which they have edited first.',
	'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', ALERT_GROUP_DELEGTIONS
);

INSERT INTO CSR.STD_ALERT_TYPE (std_alert_type_id, description, send_trigger, sent_from) VALUES (63, 'Corporate Reporter questions declined',
	'Sent when a user declines a question which they have been assigned.',
	'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).'
);

INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES(64, 'Schedule report completed',
	'Sent when a scheduled report successfully completes.',
	'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', ALERT_GROUP_TPLREPORTS
);

INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES(65, 'Schedule report failed',
	'Sent when a scheduled report fails to run.',
	'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', ALERT_GROUP_TPLREPORTS
);

INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (66, 'Scheduled import completed',
		'A scheduled import has completeted',
		'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', ALERT_GROUP_OTHER
);

INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (67, 'All audit issues have been closed',
	'When the last open issue in an audit is closed.',
	'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', ALERT_GROUP_AUDITS
);

INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (68, 'Delegation plan - new forms created (legacy)',
     q'[This alert is sent when delegation forms are created from a delegation plan, either by applying the delegation plan or by adding new regions to a delegation plan that has been applied dynamically. 'Delegation plans - new forms created' notifications are grouped together and sent out in a single e-mail. At most one e-mail will be sent per day.]',
     'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', ALERT_GROUP_DELEGTIONS
); 

INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (69, 'Inbound feed - failure',
	 q'[This alert is sent when an inbound feed email was received but not processed. 'Inbound feed - failure' notifications are grouped together and sent out in a single e-mail. At most one e-mail will be sent per day.]',
	 'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', ALERT_GROUP_OTHER
);

INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (70, 'Inbound feed - success',
	 q'[This alert is sent when an inbound feed email was received. 'Inbound feed - success' notifications are grouped together and sent out in a single e-mail. At most one e-mail will be sent per day.]',
	 'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', ALERT_GROUP_OTHER
);

INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (71, 'Filter alert template',
	 'This alert is used as a template when creating new filter alerts',
	 'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed when setting up the alert schedule).', ALERT_GROUP_OTHER
);

INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID) VALUES (72,
	'Automated export completed', 'An automated export has completeted',
	'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', ALERT_GROUP_OTHER
);

INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, override_user_send_setting, std_alert_type_group_id) VALUES (73, 'User account - pending deactivation',
	 'A user account will soon be deactivated automatically because the user has not logged in for a specified number of days.  The alert is sent each of the 15 last days before the account is due to be deactivated.',
	 'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).',
	 1, ALERT_GROUP_USERS
);

INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, OVERRIDE_USER_SEND_SETTING, STD_ALERT_TYPE_GROUP_ID) VALUES (74, 'User account deactivated (system)',
	 'A user account is deactivated automatically because the user has not logged in for a specified number of days.',
	 'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', 1, ALERT_GROUP_USERS
);

INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, OVERRIDE_USER_SEND_SETTING, STD_ALERT_TYPE_GROUP_ID) VALUES (75, 'User account deactivated (manually)',
	 'A user account is deactivated manually by another user.',
	 'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', 1, ALERT_GROUP_USERS
);

INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, OVERRIDE_USER_SEND_SETTING, STD_ALERT_TYPE_GROUP_ID) VALUES (76, 'Like for like dataset calculation complete',
	 'The underlying dataset for a like for like slot has completing calculating.',
	 'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', 1, ALERT_GROUP_OTHER
);

INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, OVERRIDE_USER_SEND_SETTING, STD_ALERT_TYPE_GROUP_ID) VALUES (77, 'Forecasting dataset calculation complete',
	 'Calculating the dataset for a forecasting slot has completed.',
	 'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).', 1, ALERT_GROUP_OTHER
);

INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, OVERRIDE_USER_SEND_SETTING, STD_ALERT_TYPE_GROUP_ID)
VALUES (
		78, 
		'Enhesa import failure',
		'The Enhesa import has failed.',
		'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).',
		1,
		ALERT_GROUP_COMPLIANCE
);

INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, OVERRIDE_USER_SEND_SETTING, STD_ALERT_TYPE_GROUP_ID)
VALUES (
		79, 
		'Compliance items rollout failure',
		'Compliance items rollout has failed.',
		'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).',
		1,
		ALERT_GROUP_COMPLIANCE
);

INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID)
VALUES (
		80,
		'Delegation - new forms created',
		q'[This alert is sent to all users involved in the delegation for each form as they are created. 'Delegation - new forms created' notifications are grouped together and sent out in a single e-mail. At most one e-mail will be sent per day.]',
		'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).',
		ALERT_GROUP_DELEGTIONS
);


END;
/

DECLARE
	alert_id NUMBER(2);
BEGIN
-- Notify user
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (1, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (1, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (1, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (1, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (1, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);

-- New delegation
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2, 1, 'DELEGATOR_FULL_NAME', 'Delegator full name', 'The full name of the user who made the delegation', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2, 1, 'DELEGATOR_EMAIL', 'Delegator e-mail', 'The e-mail address of the user who made the delegation', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2, 1, 'DELEGATION_NAME', 'Delegation name', 'The name of the delegation', 8);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2, 1, 'SUBMISSION_DTM_FMT', 'Submission date', 'The due date of the sheet', 9);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2, 1, 'SHEET_URL', 'Sheet link', 'A hyperlink to the sheet', 10);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2, 1, 'DELEG_ASSIGNED_TO', 'Assigned to', 'The name of the user the delegation is assigned to', 11);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2, 1, 'SHEET_PERIOD_FMT', 'Sheet period', 'The period that the sheet covers', 12);

-- Delegation data overdue
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (3, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (3, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (3, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (3, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (3, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (3, 1, 'DELEGATION_NAME', 'Delegation name', 'The name of the delegation', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (3, 1, 'SUBMISSION_DTM_FMT', 'Submission date', 'The due date of the sheet', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (3, 1, 'SHEET_URL', 'Sheet link', 'A hyperlink to the sheet', 8);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (3, 1, 'DELEG_ASSIGNED_TO', 'Assigned to', 'The name of the user the delegation is assigned to', 9);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (3, 1, 'SHEET_PERIOD_FMT', 'Sheet period', 'The period that the sheet covers', 10);
INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (3, 1, 'FOR_REGIONS_DESCRIPTION', 'Regions description', 'The description of the regions relating to the delegation', 11);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (3, 1, 'ACTION_SHEET_URL', 'Action sheet link', 'A hyperlink that takes you to the sheet with the next available action.', 12);
/*XXX: add? INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2, 1, 'DELEGATOR_FULL_NAME', 'Delegator full name', 'The full name of the user who made the delegation', 10);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (2, 1, 'DELEGATOR_EMAIL', 'Delegator e-mail', 'The e-mail address of the user who made the delegation', 11);*/

-- Delegation state changed
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (4, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (4, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (4, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (4, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (4, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (4, 0, 'FROM_NAME', 'From name', 'The name of the user the alert is being sent from', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (4, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (4, 0, 'DELEGATION_NAME', 'Delegation name', 'The name of the delegation', 8);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (4, 0, 'SUBMISSION_DTM_FMT', 'Submission date', 'The due date of the sheet', 9);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (4, 0, 'SHEET_URL', 'Sheet link', 'A hyperlink to the sheet', 10);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (4, 0, 'SHEET_PERIOD_FMT', 'Sheet period', 'The period that the sheet covers', 11);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (4, 0, 'DESCRIPTION', 'Sheet state', 'The state that the sheet is in', 12);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (4, 0, 'COMMENT', 'Sheet return comment', 'The comment made on the returned delegation sheet.', 13);

-- Delegation data reminder
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5, 1, 'DELEGATION_NAME', 'Delegation name', 'The name of the delegation', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5, 1, 'SHEET_URL', 'Sheet link', 'A hyperlink to the sheet', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5, 1, 'DELEG_ASSIGNED_TO', 'Assigned to', 'The name of the user the delegation is assigned to', 8);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5, 1, 'SUBMISSION_DTM_FMT', 'Submission date', 'The due date of the sheet', 9);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5, 1, 'SHEET_PERIOD_FMT', 'Sheet period', 'The period that the sheet covers', 10);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5, 1, 'DESCRIPTION', 'Description', 'A description of the change', 11);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5, 1, 'FOR_REGIONS_DESCRIPTION', 'Regions description', 'The description of the regions relating to the delegation', 12);

-- Delegation terminated
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (7, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (7, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (7, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (7, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (7, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (7, 1, 'DELEGATION_NAME', 'Delegation name', 'The name of the delegation', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (7, 1, 'TERMINATED_BY_FULL_NAME', 'Sheet link', 'A hyperlink to the sheet', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (7, 1, 'DELEGATOR_FULL_NAME', 'Assigned to', 'The name of the user the delegation is assigned to', 8);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (7, 1, 'DELEGATOR_EMAIL', 'Assigned to', 'The name of the user the delegation is assigned to', 9);

-- Updated Delegation
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (8, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (8, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (8, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (8, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (8, 1, 'DELEGATOR_FULL_NAME', 'Delegator full name', 'The full name of the user who made the delegation', 5);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (8, 1, 'DELEGATOR_EMAIL', 'Delegator e-mail', 'The e-mail address of the user who made the delegation', 6);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (8, 1, 'DELEGATION_NAME', 'Delegation name', 'The name of the delegation', 7);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (8, 1, 'SUBMISSION_DTM_FMT', 'Submission date', 'The due date of the sheet', 8);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (8, 1, 'SHEET_URL', 'Sheet link', 'A hyperlink to the sheet', 9);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (8, 1, 'DELEG_ASSIGNED_TO', 'Assigned to', 'The name of the user the delegation is assigned to', 10);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (8, 1, 'SHEET_PERIOD_FMT', 'Sheet period', 'The period that the sheet covers', 11);

-- Mail sent when new approval step form created
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (9, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (9, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (9, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (9, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (9, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (9, 0, 'FROM_NAME', 'From name', 'The name of the user the alert is being sent from', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (9, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (9, 0, 'FROM_USER_NAME', 'From user name', 'The user name of the user the alert is being sent from', 8);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (9, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 9);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (9, 0, 'LABEL', 'Label', 'The name of the new approval step', 10);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (9, 0, 'SHEET_URL', 'Sheet link', 'A hyperlink to the sheet', 11);

-- Mail sent thanking user for submission of data
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (10, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (10, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (10, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (10, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (10, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (10, 0, 'FROM_NAME', 'From name', 'The name of the user the alert is being sent from', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (10, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (10, 0, 'FROM_USER_NAME', 'From user name', 'The user name of the user the alert is being sent from', 8);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (10, 0, 'TO_NAMES', 'To names', 'The names of the users thanking you', 9);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (10, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 10);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (10, 0, 'LABEL', 'Label', 'The name of approval step', 11);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (10, 0, 'SHEET_URL', 'Sheet link', 'A hyperlink to the sheet', 12);

-- Mail sent to user when their data is rejected
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (11, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (11, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (11, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (11, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (11, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (11, 0, 'FROM_NAME', 'From name', 'The name of the user the alert is being sent from', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (11, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (11, 0, 'FROM_USER_NAME', 'From user name', 'The user name of the user the alert is being sent from', 8);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (11, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 9);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (11, 0, 'LABEL', 'Label', 'The name of the new approval step', 10);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (11, 0, 'DUE_DTM', 'Due date', 'The date the data is due', 11);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (11, 0, 'SHEET_URL', 'Sheet link', 'A hyperlink to the sheet', 12);

-- Mail sent to subdelegee when sub-delegation takes place
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (12, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (12, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (12, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (12, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (12, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (12, 0, 'FROM_NAME', 'From name', 'The name of the user the alert is being sent from', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (12, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (12, 0, 'FROM_USER_NAME', 'From user name', 'The user name of the user the alert is being sent from', 8);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (12, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 9);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (12, 1, 'LABEL', 'Label', 'The name of the new approval step', 10);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (12, 1, 'DELEGATOR_FULL_NAME', 'Delegator full name', 'The full name of the user who made the delegation', 11);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (12, 1, 'SHEET_URL', 'Sheet link', 'A hyperlink to the sheet', 12);

-- Mail sent thanking user for submitting to approval step owner
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (13, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (13, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (13, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (13, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (13, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (13, 0, 'FROM_NAME', 'From name', 'The name of the user the alert is being sent from', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (13, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (13, 0, 'FROM_USER_NAME', 'From user name', 'The user name of the user the alert is being sent from', 8);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (13, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 9);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (13, 0, 'LABEL', 'Label', 'The name of the approval step', 10);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (13, 0, 'TO_NAMES', 'To names', 'The names of the users thanking you', 11);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (13, 0, 'SHEET_URL', 'Sheet link', 'A hyperlink to the sheet', 12);

-- Mail sent when approval step owner rejects
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (14, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (14, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (14, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (14, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (14, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (14, 0, 'FROM_NAME', 'From name', 'The name of the user the alert is being sent from', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (14, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (14, 0, 'FROM_USER_NAME', 'From user name', 'The user name of the user the alert is being sent from', 8);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (14, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 9);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (14, 0, 'LABEL', 'Label', 'The name of the new approval step', 10);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (14, 0, 'DUE_DTM', 'Due date', 'The date the data is due', 11);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (14, 0, 'SHEET_URL', 'Sheet link', 'A hyperlink to the sheet', 12);

-- Mail sent to approver when a new submission is made
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (15, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (15, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (15, 0, 'TO_USER_NAME', 'User name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (15, 0, 'TO_EMAIL', 'E-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (15, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (15, 0, 'FROM_NAME', 'From name', 'The name of the user the alert is being sent from', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (15, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (15, 0, 'FROM_USER_NAME', 'From user name', 'The user name of the user the alert is being sent from', 8);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (15, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 9);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (15, 0, 'LABEL', 'Label', 'The name of the approval step', 10);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (15, 0, 'SHEET_LABEL', 'Sheet label', 'The name of the sheet', 11);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (15, 0, 'SHEET_URL', 'Sheet link', 'A hyperlink to the sheet', 12);

-- Mail sent to data provider when final approval occurs
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (16, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (16, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (16, 0, 'TO_USER_NAME', 'User name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (16, 0, 'TO_EMAIL', 'E-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (16, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (16, 0, 'FROM_NAME', 'From name', 'The name of the user the alert is being sent from', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (16, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (16, 0, 'FROM_USER_NAME', 'From user name', 'The user name of the user the alert is being sent from', 8);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (16, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 9);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (16, 0, 'LABEL', 'Label', 'The name of the new approval step', 10);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (16, 0, 'SHEET_URL', 'Sheet link', 'A hyperlink to the sheet', 11);

-- Mail sent when a comment is made on an issue
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17,0,'ASSIGNED_TO','Assigned to','The user that the issue is currently assigned to',1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17,0,'ASSIGNED_TO_USER_SID','Assigned to user SID','The SID of the user that the issue is currently assigned to',2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17,0,'COMMENT','Comment','The comment',3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17,0,'FROM_EMAIL','From e-mail','The e-mail address of the user the alert is being sent from',4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17,0,'FROM_FRIENDLY_NAME','From friendly name','The friendly name of the user the alert is being sent from',5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17,0,'FROM_NAME','From name','The name of the user the alert is being sent from',6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17,0,'FROM_USER_NAME','From user name','The user name of the user the alert is being sent from',7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17,0,'ISSUE_ID','Issue ID','The issue ID',8);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17,0,'ISSUE_URL','Issue URL','A link to the full screen issue details page',9);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17,0,'CRITICAL','Issue critical','Indicates if the action is critical',10);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17,0,'ISSUE_DETAIL','Issue details','The issue details',11);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17,0,'DUE_DTM','Issue due date','The date the issue should be resolved by',12);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17,0,'ISSUE_LABEL','Issue label','The issue label',13);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17,0,'ISSUE_LINK','Issue link','Link to the issue',14);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17,0,'RAISED_DTM','Issue raised date','The date the issue was raised',15);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17,0,'ISSUE_REF','Issue ref','The issue reference',16);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17,0,'ISSUE_STATUS','Issue status','The status of the issue',17);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17,0,'ISSUE_TYPE_DESCRIPTION','Issue type','The description of the issue type',18);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17,0,'PARENT_OBJECT_URL','Parent object URL','A link to the parent object of the issue, e.g. the audit/delegation/supplier it is associated with.',19);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17,0,'PRIORITY_DESCRIPTION','Priority','The description of the issue priority',20);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17,0,'PRIORITY_DUE_DATE_OFFSET','Priority offset in days','The number of days that the priority is offset from the date the issue was submitted',21);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17,0,'REGION_DESCRIPTION','Region description','The region associated with the issue, if any.',22);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17,0,'SHEET_URL','Sheet URL','A link to the sheet that the issue relates to',23);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17,0,'SHEET_LABEL','Sheet label','The name of the sheet that the issue relates to',24);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17,0,'HOST','Site web address','The web address for your CRedit360 system',25);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17,0,'TO_EMAIL','To e-mail','The e-mail address of the user the alert is being sent to',26);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17,0,'TO_FRIENDLY_NAME','To friendly name','The friendly name of the user the alert is being sent to',27);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17,0,'TO_NAME','To full name','The full name of the user the alert is being sent to',28);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (17,0,'TO_USER_NAME','To user name','The user name of the user the alert is being sent to',29);

-- Mail sent containing issue summaries
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18,1,'ASSIGNED_TO','Assigned to','The user that the issue is currently assigned to',1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18,1,'ASSIGNED_TO_USER_SID','Assigned to user SID','The SID of the user that the issue is currently assigned to',2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18,0,'FROM_EMAIL','From e-mail','The e-mail address of the user the alert is being sent from',3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18,0,'FROM_FRIENDLY_NAME','From friendly name','The friendly name of the user the alert is being sent from',4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18,0,'FROM_NAME','From name','The name of the user the alert is being sent from',5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18,0,'FROM_USER_NAME','From user name','The user name of the user the alert is being sent from',6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18,1,'ISSUE_ID','Issue ID','The issue ID',7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18,1,'ISSUE_URL','Issue URL','A link to the full screen issue details page',8);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18,1,'CRITICAL','Issue critical','Indicates if the action is critical',9);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18,1,'ISSUE_DETAIL','Issue details','The issue details',10);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18,1,'DUE_DTM','Issue due date','The date the issue should be resolved by',11);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18,1,'ISSUE_LABEL','Issue label','The issue label',12);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18,1,'ISSUE_LINK','Issue link','Link to the issue',13);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18,1,'RAISED_DTM','Issue raised date','The date the issue was raised',14);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18,1,'ISSUE_REF','Issue ref','The issue reference',15);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18,1,'ISSUE_STATUS','Issue status','The status of the issue',16);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18,1,'ISSUE_TYPE_DESCRIPTION','Issue type','The description of the issue type',17);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18,1,'PARENT_OBJECT_URL','Parent object URL','A link to the parent object of the issue, e.g. the audit/delegation/supplier it is associated with.',18);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18,1,'PRIORITY_DESCRIPTION','Priority','The description of the issue priority',19);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18,1,'PRIORITY_DUE_DATE_OFFSET','Priority offset in days','The number of days that the priority is offset from the date the issue was submitted',20);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18,1,'REGION_DESCRIPTION','Region description','The region associated with the issue, if any.',21);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18,1,'RELATED_OBJECT_NAME','Related Object Name (e.g Non-Compliance name)','For audit issues this field contains the name of the non-compliance',22);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18,1,'SHEET_URL','Sheet URL','A link to the sheet that the issue relates to',23);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18,1,'SHEET_LABEL','Sheet label','The name of the sheet that the issue relates to',24);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18,0,'HOST','Site web address','The web address for your CRedit360 system',25);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18,0,'TO_EMAIL','To e-mail','The e-mail address of the user the alert is being sent to',26);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18,0,'TO_FRIENDLY_NAME','To friendly name','The friendly name of the user the alert is being sent to',27);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18,0,'TO_NAME','To full name','The full name of the user the alert is being sent to',28);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18,0,'TO_USER_NAME','To user name','The user name of the user the alert is being sent to',29);

-- Mail sent when a document in the document library is updated
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (19, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (19, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (19, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (19, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (19, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (19, 0, 'CHANGED_DTM', 'Changed date', 'The date the change was made', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (19, 0, 'CHANGED_BY', 'Changed by', 'The user who made the change', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (19, 0, 'VERSION', 'Version', 'The version of the document that was created', 8);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (19, 0, 'FILE_NAME', 'Document name', 'The name of the document', 9);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (19, 0, 'CHANGE_DESCRIPTION', 'Change description', 'A description of the change that was made', 10);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (19, 0, 'DOC_LINK', 'Document link', 'A hyperlink to the document', 11);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (19, 0, 'DOC_FOLDER_LINK', 'Folder link', 'A hyperlink to the folder in the document library containing the document', 12);

-- Generic mailout
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (20, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (20, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (20, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (20, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (20, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (20, 0, 'FROM_NAME', 'From name', 'The name of the user the alert is being sent from', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (20, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (20, 0, 'FROM_USER_NAME', 'From user name', 'The user name of the user the alert is being sent from', 8);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (20, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 9);

-- Self register validate e-mail address
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (21, 0, 'TO_NAME', 'User name', 'The user name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (21, 0, 'TO_EMAIL', 'E-mail', 'The e-mail address of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (21, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (21, 0, 'FROM_NAME', 'From name', 'The name of the user the alert is being sent from', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (21, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (21, 0, 'URL', 'Validate link', 'The validation link', 6);

-- Self register notify administrator
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (22, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (22, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (22, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (22, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (22, 0, 'USER_NAME', 'User name', 'The requested user name', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (22, 0, 'USER_FULL_NAME', 'User full name', 'The requested full name', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (22, 0, 'USER_EMAIL', 'User e-mail', 'The e-mail address of the requesting user', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (22, 0, 'URL', 'Validate link', 'The validation link', 8);

-- Self register account approval
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (23, 0, 'TO_NAME', 'User name', 'The user name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (23, 0, 'TO_EMAIL', 'E-mail', 'The e-mail address of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (23, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (23, 0, 'FROM_NAME', 'From name', 'The name of the user the alert is being sent from', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (23, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (23, 0, 'URL', 'Login link', 'Link to the site to login with', 6);

-- Self register account rejection
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (24, 0, 'TO_NAME', 'User name', 'The user name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (24, 0, 'TO_EMAIL', 'E-mail', 'The e-mail address of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (24, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (24, 0, 'FROM_NAME', 'From name', 'The name of the user the alert is being sent from', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (24, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);

-- Password reset
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (25, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (25, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (25, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (25, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (25, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (25, 0, 'URL', 'Reset link', 'The password reset link', 6);

-- Account disabled (password reset)
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (26, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (26, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (26, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (26, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (26, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (26, 0, 'FROM_NAME', 'From name', 'The name of the user the alert is being sent from', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (26, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 7);

-- Approval step data reminder
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (27, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (27, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (27, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (27, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (27, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (27, 1, 'DELEGATION_NAME', 'Delegation name', 'The name of the delegation', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (27, 1, 'SHEET_URL', 'Sheet link', 'A hyperlink to the sheet', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (27, 1, 'SUBMISSION_DTM_FMT', 'Submission date', 'The due date of the sheet', 8);

-- Approval step data overdue
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (28, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (28, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (28, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (28, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (28, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (28, 1, 'DELEGATION_NAME', 'Delegation name', 'The name of the delegation', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (28, 1, 'SHEET_URL', 'Sheet link', 'A hyperlink to the sheet', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (28, 1, 'SUBMISSION_DTM_FMT', 'Submission date', 'The due date of the sheet', 8);

-- Delegation data change request
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (29, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (29, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (29, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (29, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (29, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (29, 0, 'FROM_NAME', 'From name', 'The name of the user the alert is being sent from', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (29, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (29, 0, 'DELEGATION_NAME', 'Delegation name', 'The name of the delegation', 8);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (29, 0, 'SHEET_URL', 'Sheet link', 'A hyperlink to the sheet', 10);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (29, 0, 'SHEET_PERIOD_FMT', 'Sheet period', 'The period that the sheet covers', 11);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (29, 0, 'COMMENT', 'Comment', 'The comment', 12);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (29, 0, 'ACTION_SHEET_URL', 'Action sheet link', 'A hyperlink to the sheet where the data change request was made.', 13);

-- Delegation state changed
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (30, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (30, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (30, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (30, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (30, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (30, 1, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user who changed the delegation state', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (30, 1, 'FROM_NAME', 'From name', 'The name of the user who changed the delegation state', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (30, 1, 'DELEGATION_NAME', 'Delegation name', 'The name of the delegation', 8);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (30, 1, 'SUBMISSION_DTM_FMT', 'Submission date', 'The due date of the sheet', 9);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (30, 1, 'SHEET_URL', 'Sheet link', 'A hyperlink to the sheet', 10);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (30, 1, 'SHEET_PERIOD_FMT', 'Sheet period', 'The period that the sheet covers', 11);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (30, 1, 'DESCRIPTION', 'Sheet state', 'The state that the sheet is in', 12);

-- Survey email
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (31, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (31, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user who changed the delegation state', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (31, 0, 'FROM_NAME', 'From name', 'The name of the user who changed the delegation state', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (31, 0, 'SURVEY_URL', 'Survey link', 'A hyperlink to the survey', 4);

-- Correspondent issue submission confirmation
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (32, 0, 'TO_NAME', 'To full name', 'The full name of the person (correspondent) that the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (32, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the person (correspondent) that the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (32, 0, 'NOTE', 'Log entry note', 'The note that was submitted to open the issue', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (32, 0, 'ISSUE_ID', 'The issue id string', 'The issue identification for the mail reader', 4);

-- Resolved issue
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (33, 0, 'TO_NAME', 'To full name', 'The full name of the person (correspondent) that the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (33, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the person (correspondent) that the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (33, 0, 'FROM_FULL_NAME', 'From full name', 'The full name of the user that is triggering the alert send', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (33, 0, 'NOTE', 'Log entry note', 'The note to the correspondent that is also written into the issue log', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (33, 0, 'LINK', 'Public access link', 'The public link that allows the correspondent to view the issue and add further comments', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (33, 0, 'ATTACHMENT_COUNT', 'Attachment count', 'The number of attachments which are attached to the last log entry that can be downloaded by the correspondent.', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (33, 0, 'ISSUE_ID', 'The issue id string', 'The issue identification for the mail reader', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (33, 0, 'PRIORITY_DESCRIPTION', 'Priority', 'The description of the issue priority', 8);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (33, 0, 'PRIORITY_DUE_DATE_OFFSET', 'Priority offset in days', 'The number of days that the priority is offset from the date the issue was submitted', 9);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (33, 0, 'LONG_DUE_DTM', 'Long due date', 'The due date of the issue, written in long date format', 10);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (33, 0, 'SHORT_DUE_DTM', 'Short due date', 'The due date of the issue, written in short date format', 11);



-- Response to issue correspondent
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (34, 0, 'TO_NAME', 'To full name', 'The full name of the person that the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (34, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the person that the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (34, 0, 'FROM_FULL_NAME', 'From full name', 'The full name of the user that is triggering the alert send', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (34, 0, 'NOTE', 'Log entry note', 'The note to the user or correspondent that is also written into the issue log', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (34, 0, 'LINK', 'Public access link', 'The public link that allows the user or correspondent to view the issue and add further comments', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (34, 0, 'ATTACHMENT_COUNT', 'Attachment count', 'The number of attachments which are attached to the last log entry that can be downloaded following the link.', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (34, 0, 'ISSUE_ID', 'The issue id string', 'The issue identification for the mail reader', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (34, 0, 'PRIORITY_DESCRIPTION', 'Priority', 'The description of the issue priority', 8);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (34, 0, 'PRIORITY_DUE_DATE_OFFSET', 'Priority offset in days', 'The number of days that the priority is offset from the date the issue was submitted', 9);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (34, 0, 'LONG_DUE_DTM', 'Long due date', 'The due date of the issue, written in long date format', 10);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (34, 0, 'SHORT_DUE_DTM', 'Short due date', 'The due date of the issue, written in short date format', 11);


-- a correspondent issue has been rejected
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (35, 0, 'TO_NAME', 'To full name', 'The full name of the person (correspondent) that the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (35, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the person (correspondent) that the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (35, 0, 'FROM_FULL_NAME', 'From full name', 'The full name of the user that is triggering the alert send', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (35, 0, 'NOTE', 'Log entry note', 'The note to the correspondent that is also written into the issue log', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (35, 0, 'LINK', 'Public access link', 'The public link that allows the correspondent to view the issue and add further comments', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (35, 0, 'ATTACHMENT_COUNT', 'Attachment count', 'The number of attachments which are attached to the last log entry that can be downloaded by the correspondent.', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (35, 0, 'ISSUE_ID', 'The issue id string', 'The issue identification for the mail reader', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (35, 0, 'PRIORITY_DESCRIPTION', 'Priority', 'The description of the issue priority', 8);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (35, 0, 'PRIORITY_DUE_DATE_OFFSET', 'Priority offset in days', 'The number of days that the priority is offset from the date the issue was submitted', 9);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (35, 0, 'LONG_DUE_DTM', 'Long due date', 'The due date of the issue, written in long date format', 10);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (35, 0, 'SHORT_DUE_DTM', 'Short due date', 'The due date of the issue, written in short date format', 11);

-- a correspondent issue has had the priority set for the first time
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (36, 0, 'TO_NAME', 'To full name', 'The full name of the person (correspondent) that the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (36, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the person (correspondent) that the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (36, 0, 'FROM_FULL_NAME', 'From full name', 'The full name of the user that is triggering the alert send', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (36, 0, 'LINK', 'Public access link', 'The public link that allows the correspondent to view the issue and add further comments', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (36, 0, 'ISSUE_ID', 'The issue id string', 'The issue identification for the mail reader', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (36, 0, 'PRIORITY_DESCRIPTION', 'Priority', 'The description of the issue priority', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (36, 0, 'PRIORITY_DUE_DATE_OFFSET', 'Priority offset in days', 'The number of days that the priority is offset from the date the issue was submitted', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (36, 0, 'LONG_DUE_DTM', 'Long due date', 'The due date of the issue, written in long date format', 8);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (36, 0, 'SHORT_DUE_DTM', 'Short due date', 'The due date of the issue, written in short date format', 9);

-- Delegation generic mail
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (37, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (37, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (37, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (37, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (37, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user sending the email', 5);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (37, 0, 'FROM_NAME', 'From name', 'The name of the user sending the email', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (37, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (37, 1, 'DELEGATION_NAME', 'Delegation name', 'The name of the delegation', 8);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (37, 1, 'SHEET_URL', 'Sheet link', 'A hyperlink to the sheet', 9);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (37, 1, 'DELEG_ASSIGNED_TO', 'Assigned to', 'The name of the user the delegation is assigned to', 10);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (37, 1, 'SUBMISSION_DTM_FMT', 'Submission date', 'The due date of the sheet', 11);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (37, 1, 'SHEET_PERIOD_FMT', 'Sheet period', 'The period that the sheet covers', 12);

-- user cover started
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (38, 0, 'USER_BEING_COVERED_NAME', 'User being covered name', 'The full name of the person who is now being covered', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (38, 0, 'USER_GIVING_COVER_NAME', 'User giving cover name', 'The full name of the person who is now giving cover (the recipient)', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (38, 0, 'COVER_DURATION', 'Cover duration', 'A description of how long the cover lasts', 3);
INSERT INTO CSR.std_alert_type_param(std_alert_type_id, repeats, field_name, description, help_text,
display_pos)
VALUES (38, 0, 'COVER_START', 'Cover start', 'The date that the cover starts', 4);
INSERT INTO CSR.std_alert_type_param(std_alert_type_id, repeats, field_name, description, help_text,
display_pos)
VALUES (38, 0, 'COVER_END', 'Cover end', 'The date that the cover ends', 5);

-- Sheet value changed by non-delegee
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (39, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (39, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (39, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (39, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (39, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (39, 0, 'FROM_NAME', 'From name', 'The name of the user the alert is being sent from', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (39, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (39, 0, 'DELEGATION_NAME', 'Delegation name', 'The name of the delegation', 8);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (39, 0, 'SUBMISSION_DTM_FMT', 'Submission date', 'The due date of the sheet', 9);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (39, 0, 'SHEET_URL', 'Sheet link', 'A hyperlink to the sheet', 10);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (39, 0, 'SHEET_PERIOD_FMT', 'Sheet period', 'The period that the sheet covers', 11);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (39, 0, 'DESCRIPTION', 'Sheet state', 'The state that the sheet is in', 12);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)

-- Funding commitment reminder
VALUES (40, 0, 'FC_NAME', 'Funding Commitment name', 'The full name of Funding Commitment', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (40, 0, 'PAYMENT_DTM', 'Payment date', 'The date of payment', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (40, 0, 'FC_LINK', 'Link to Funding commitment setup page', 'This will give direct link to correct funding commitment setup', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (40, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 4);

INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (41, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (41, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (41, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (41, 0, 'TABLE_DESCRIPTION', 'Table name', 'The name of the table being inserted into', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (41, 0, 'ERRORS', 'Errors', 'The problems encountered', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (41, 0, 'SUBJECT_RCVD', 'Subject of received e-mail', 'Inbound e-mail subject', 8);

INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (42, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (42, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (42, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (42, 0, 'TABLE_DESCRIPTION', 'Table name', 'The name of the table being inserted into', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (42, 0, 'REF', 'New reference', 'The reference for the logged item', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (42, 0, 'SUBJECT_RCVD', 'Subject of received e-mail', 'Inbound e-mail subject', 8);

-- batch job completion
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (43, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (43, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (43, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (43, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (43, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (43, 0, 'FROM_NAME', 'From name', 'The name of the user the alert is being sent from', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (43, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (43, 0, 'JOB_TYPE', 'Job type', 'The type of the batch job that has completed', 8);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (43, 0, 'JOB_DESCRIPTION', 'Job description', 'A description of the batch job that has completed', 9);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (43, 0, 'JOB_RESULT', 'Job result', 'The result of running the job', 10);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (43, 0, 'JOB_URL', 'Result link', 'A hyperlink to the job results, if applicable, or to the main website if not', 11);

-- Section state change message
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (44, 0, 'TO_FULL_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (44, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (44, 0, 'HOST', 'Site host address', 'Address of the website', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (44, 0, 'STATE_LABEL', 'Workflow status', 'The new workflow status of the question', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (44, 0, 'MY_QUESTIONS_LINK', 'My questions link', 'Link to the page showing the user''s questions', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (44, 1, 'DUE_DTM', 'Due date', 'Date when the question is due', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (44, 1, 'SECTION_TITLE', 'Title', 'Title of question to answer', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (44, 1, 'FROM_FULL_NAME', 'From', 'Full name of the person who changed the status', 3);


-- Expiring audits (reminder)
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (45, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (45, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (45, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (45, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (45, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (45, 1, 'AUDIT_TYPE_LABEL', 'Audit type', 'The name of the audit type that is about to expire', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (45, 1, 'AUDIT_REGION', 'Region name', 'The name of the region that the audit relates to', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (45, 1, 'DUE_DTM', 'Due date', 'The date a re-audit or follow-up audit is due', 8);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (45, 1, 'SCHEDULE_LINK', 'Schedule link', 'A link to schedule an audit of this type at this location', 9);

-- Expired audits (overdue)
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (46, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (46, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (46, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (46, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (46, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (46, 1, 'AUDIT_TYPE_LABEL', 'Audit type', 'The name of the audit type that is about to expire', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (46, 1, 'AUDIT_REGION', 'Region name', 'The name of the region that the audit relates to', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (46, 1, 'DUE_DTM', 'Due date', 'The date a re-audit or follow-up audit is due', 8);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (46, 1, 'SCHEDULE_LINK', 'Schedule link', 'A link to schedule an audit of this type at this location', 9);


-- Mail sent containing issue summaries
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (47, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (47, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (47, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (47, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (47, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (47, 0, 'FROM_NAME', 'From name', 'The name of the user the alert is being sent from', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (47, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (47, 0, 'FROM_USER_NAME', 'From user name', 'The user name of the user the alert is being sent from', 8);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (47, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 9);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (47, 1, 'SHEET_LABEL', 'Sheet label', 'The name of the sheet that the issue relates to', 10);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (47, 1, 'SHEET_URL', 'Sheet URL', 'A link to the sheet that the issue relates to', 11);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (47, 1, 'ISSUE_DETAIL', 'Issue details', 'The issue details', 12);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (47, 1, 'ISSUE_LABEL', 'Issue label', 'The issue label', 13);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (47, 1, 'ISSUE_TYPE_DESCRIPTION', 'Issue type', 'The description of the issue type', 14);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (47, 1, 'ISSUE_ID', 'Issue ID', 'The issue ID', 15);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (47, 1, 'DUE_DTM', 'Due date', 'The due date of the issue', 16);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (47, 1, 'ISSUE_URL', 'Issue URL', 'A link to the full screen issue details page', 17);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (47, 1, 'PARENT_OBJECT_URL', 'Parent object URL', 'A link to the parent object of the issue, e.g. the audit/delegation/supplier it is associated with.', 18);

-- Mail sent when section is close to overdue
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (48, 0, 'TO_FULL_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (48, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (48, 0, 'HOST', 'Site host address', 'Address of the website', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (48, 0, 'MY_QUESTIONS_LINK', 'My questions link', 'Link to the page showing the user''s questions', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (48, 1, 'DUE_DTM', 'Current step due date', 'Date when section is going to be due', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (48, 1, 'SECTION_TITLE', 'Title', 'Title of question to answer', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (48, 1, 'STATE_LABEL', 'Workflow status', 'The current workflow status of the question', 4);

-- Mail sent when section is overdue
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (49, 0, 'TO_FULL_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (49, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (49, 0, 'HOST', 'Site host address', 'Address of the website', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (49, 0, 'MY_QUESTIONS_LINK', 'My questions link', 'Link to the page showing the user''s questions', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (49, 1, 'DUE_DTM', 'Current step due date', 'Date when section is going to be due', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (49, 1, 'SECTION_TITLE', 'Title', 'Title of question to answer', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (49, 1, 'STATE_LABEL', 'Workflow status', 'The current workflow status of the question', 4);

--Auto Approval
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (50, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (50, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (50, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (50, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (50, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (50, 0, 'SHEET_NAME', 'Sheet name', 'The name of the sheet that has been approved.', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (50, 0, 'EDITING_URL', 'Sheet editing URL', 'The editing URL of the sheet that has been approved.', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (51, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (51, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (51, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (51, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (51, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (51, 0, 'SHEET_NAME', 'Sheet name', 'The name of the sheet that has been approved.', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (51, 0, 'EDITING_URL', 'Sheet editing URL', 'The URL of the sheet that has been approved.', 7);

-- Text question route forward
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (52, 0, 'TO_FULL_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (52, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (52, 0, 'HOST', 'Site host address', 'Address of the website', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (52, 0, 'STATE_LABEL', 'Workflow status', 'The new workflow status of the question', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (52, 0, 'MY_QUESTIONS_LINK', 'My questions link', 'Link to the page showing the user''s questions', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (52, 1, 'DUE_DTM', 'Due date', 'Date when the question is due', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (52, 1, 'SECTION_TITLE', 'Title', 'Title of question to answer', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (52, 1, 'FROM_FULL_NAME', 'From', 'Full name of the person who changed the status', 3);

-- Text question route return
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (53, 0, 'TO_FULL_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (53, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (53, 0, 'HOST', 'Site host address', 'Address of the website', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (53, 0, 'STATE_LABEL', 'Workflow status', 'The new workflow status of the question', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (53, 0, 'MY_QUESTIONS_LINK', 'My questions link', 'Link to the page showing the user''s questions', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (53, 1, 'DUE_DTM', 'Due date', 'Date when the question is due', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (53, 1, 'SECTION_TITLE', 'Title', 'Title of question to answer', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (53, 1, 'FROM_FULL_NAME', 'From', 'Full name of the person who changed the status', 3);

-- Teamroom invitation
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (54, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 1);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (54, 0, 'TEAMROOM_NAME', 'Teamroom name', 'The name of the teamroom the user has been invited to', 2);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (54, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 3);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (54, 0, 'LINK', 'Link', 'A hyperlink to the invitation acceptance page', 4);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (54, 0, 'MESSAGE', 'Message', 'The message from the user the alert is being sent from', 5);

-- Teamroom user removed
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (55, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 1);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (55, 0, 'TEAMROOM_NAME', 'Teamroom name', 'The name of the teamroom the user has been removed from', 2);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (55, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 3);

-- Section document now available notification
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (56, 0, 'TO_FULLNAME', 'To Full Name', 'The user that requested to be alerted.', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (56, 0, 'FIN_FULLNAME', 'Full Name', 'The user that has finished editing the document.', 2);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (56, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (56, 0, 'FILENAME', 'Filename', 'The file that has become available for editing.', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (56, 0, 'QUESTION_LABEL', 'Question Name', 'The questions title.', 5);

-- Delegation state returned
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (57, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (57, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (57, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (57, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (57, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (57, 0, 'FROM_NAME', 'From name', 'The name of the user the alert is being sent from', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (57, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (57, 0, 'DELEGATION_NAME', 'Delegation name', 'The name of the delegation', 8);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (57, 0, 'SUBMISSION_DTM_FMT', 'Submission date', 'The due date of the sheet', 9);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (57, 0, 'SHEET_URL', 'Sheet link', 'A hyperlink to the sheet', 10);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (57, 0, 'SHEET_PERIOD_FMT', 'Sheet period', 'The period that the sheet covers', 11);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (57, 0, 'DESCRIPTION', 'Sheet state', 'The state that the sheet is in', 12);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (57, 0, 'COMMENT', 'Sheet return comment', 'The comment made on the returned delegation sheet.', 13);

-- Delegation data change request approved
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (58, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (58, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (58, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (58, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (58, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (58, 0, 'FROM_NAME', 'From name', 'The name of the user the alert is being sent from', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (58, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (58, 0, 'DELEGATION_NAME', 'Delegation name', 'The name of the delegation', 8);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (58, 0, 'SHEET_URL', 'Sheet link', 'A hyperlink to the sheet', 10);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (58, 0, 'SHEET_PERIOD_FMT', 'Sheet period', 'The period that the sheet covers', 11);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (58, 0, 'COMMENT', 'Comment', 'The comment', 12);

-- Delegation data change request rejected
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (59, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (59, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (59, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (59, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (59, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (59, 0, 'FROM_NAME', 'From name', 'The name of the user the alert is being sent from', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (59, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (59, 0, 'DELEGATION_NAME', 'Delegation name', 'The name of the delegation', 8);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (59, 0, 'SHEET_URL', 'Sheet link', 'A hyperlink to the sheet', 10);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (59, 0, 'SHEET_PERIOD_FMT', 'Sheet period', 'The period that the sheet covers', 11);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (59, 0, 'COMMENT', 'Comment', 'The comment', 12);

-- Expiring issues (reminder)
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (60,1,'ASSIGNED_TO','Assigned to','The user that the issue is currently assigned to',1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (60,1,'ASSIGNED_TO_USER_SID','Assigned to user SID','The SID of the user that the issue is currently assigned to',2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (60,0,'FROM_EMAIL','From e-mail','The e-mail address of the user the alert is being sent from',3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (60,0,'FROM_FRIENDLY_NAME','From friendly name','The friendly name of the user the alert is being sent from',4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (60,0,'FROM_NAME','From name','The name of the user the alert is being sent from',5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (60,0,'FROM_USER_NAME','From user name','The user name of the user the alert is being sent from',6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (60,1,'ISSUE_ID','Issue ID','The issue ID',7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (60,1,'ISSUE_URL','Issue URL','A link to the full screen issue details page',8);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (60,1,'CRITICAL','Issue critical','Indicates if the action is critical',9);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (60,1,'ISSUE_DETAIL','Issue details','The issue details',10);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (60,1,'DUE_DTM','Issue due date','The date the issue should be resolved by',11);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (60,1,'ISSUE_LABEL','Issue label','The issue label',12);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (60,1,'ISSUE_LINK','Issue link','Link to the issue',13);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (60,1,'RAISED_DTM','Issue raised date','The date the issue was raised',14);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (60,1,'ISSUE_REF','Issue ref','The issue reference',15);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (60,1,'ISSUE_STATUS','Issue status','The status of the issue',16);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (60,1,'ISSUE_TYPE_LABEL','Issue type','The name of the issue type that is about to expire',17);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (60,1,'PRIORITY_DESCRIPTION','Priority','The description of the issue priority',18);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (60,1,'PRIORITY_DUE_DATE_OFFSET','Priority offset in days','The number of days that the priority is offset from the date the issue was submitted',19);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (60,1,'ISSUE_REGION','Region name','The name of the region that the issue relates to',20);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (60,0,'HOST','Site web address','The web address for your CRedit360 system',21);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (60,0,'TO_EMAIL','To e-mail','The e-mail address of the user the alert is being sent to',22);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (60,0,'TO_FRIENDLY_NAME','To friendly name','The friendly name of the user the alert is being sent to',23);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (60,0,'TO_NAME','To full name','The full name of the user the alert is being sent to',24);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (60,0,'TO_USER_NAME','To user name','The user name of the user the alert is being sent to',25);

-- Expired issues (overdue)
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (61,1,'ASSIGNED_TO','Assigned to','The user that the issue is currently assigned to',1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (61,1,'ASSIGNED_TO_USER_SID','Assigned to user SID','The SID of the user that the issue is currently assigned to',2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (61,0,'FROM_EMAIL','From e-mail','The e-mail address of the user the alert is being sent from',3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (61,0,'FROM_FRIENDLY_NAME','From friendly name','The friendly name of the user the alert is being sent from',4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (61,0,'FROM_NAME','From name','The name of the user the alert is being sent from',5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (61,0,'FROM_USER_NAME','From user name','The user name of the user the alert is being sent from',6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (61,1,'ISSUE_ID','Issue ID','The issue ID',7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (61,1,'ISSUE_URL','Issue URL','A link to the full screen issue details page',8);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (61,1,'CRITICAL','Issue critical','Indicates if the action is critical',9);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (61,1,'ISSUE_DETAIL','Issue details','The issue details',10);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (61,1,'DUE_DTM','Issue due date','The date the issue was to be resolved by',11);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (61,1,'ISSUE_LABEL','Issue label','The issue label',12);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (61,1,'ISSUE_LINK','Issue link','Link to the issue',13);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (61,1,'RAISED_DTM','Issue raised date','The date the issue was raised',14);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (61,1,'ISSUE_REF','Issue ref','The issue reference',15);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (61,1,'ISSUE_STATUS','Issue status','The status of the issue',16);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (61,1,'ISSUE_TYPE_LABEL','Issue type','The name of the issue type that has expired',17);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (61,1,'PRIORITY_DESCRIPTION','Priority','The description of the issue priority',18);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (61,1,'PRIORITY_DUE_DATE_OFFSET','Priority offset in days','The number of days that the priority is offset from the date the issue was submitted',19);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (61,1,'ISSUE_REGION','Region name','The name of the region that the issue relates to',20);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (61,0,'HOST','Site web address','The web address for your CRedit360 system',21);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (61,0,'TO_EMAIL','To e-mail','The e-mail address of the user the alert is being sent to',22);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (61,0,'TO_FRIENDLY_NAME','To friendly name','The friendly name of the user the alert is being sent to',23);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (61,0,'TO_NAME','To full name','The full name of the user the alert is being sent to',24);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (61,0,'TO_USER_NAME','To user name','The user name of the user the alert is being sent to',25);

-- Delegation edited
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (62, 0, 'FROM_NAME', 'From name', 'The full name of the user raising the alert', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (62, 0, 'FROM_EMAIL', 'From email', 'The email of the user raising the alert', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (62, 0, 'DELEGATION_NAME', 'Delegation name', 'The name of the delgation involved', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (62, 0, 'SHEET_LINK', 'Sheet URL', 'Link to the sheet', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (62, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (62, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (62, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (62, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 8);

-- Corporate Reporter questions declined
INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (63, 0, 'TO_FULL_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (63, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (63, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (63, 1, 'BY_FULL_NAME', 'By full name', 'The full name of the user who declined the question', 4);
INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (63, 1, 'BY_FRIENDLY_NAME', 'By friendly name', 'The friendly name of the user who declined the question', 5);
INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (63, 1, 'BY_EMAIL', 'By e-mail', 'The e-mail address of the user who declined the question', 6);
INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (63, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 7);
INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (63, 1, 'ROUTE_STEP_ID', 'Route Step Id', 'The Route Step that was declined', 8);
INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (63, 1, 'SECTION_SID', 'Section Id', 'The Section containing the question that was declined', 9);
INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (63, 1, 'MODULE_TITLE', 'Framework Title', 'The Framework containing the question that was declined', 10);
INSERT INTO CSR.STD_ALERT_TYPE_PARAM (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (63, 1, 'SECTION_TITLE', 'Section Title', 'The Section containing the question that was declined', 11);

-- Scheduled report complete
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (64, 0, 'FROM_NAME', 'From name', 'The name of the schedule owner', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (64, 0, 'FROM_EMAIL', 'From email', 'The email of the schedule owner', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (64, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (64, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (64, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (64, 0, 'TEMPLATE_NAME', 'Template name', 'The name of the template useed for the report', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (64, 0, 'SCHEDULE_NAME', 'Schedule name', 'The name of the schedule which caused the report to be generated', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (64, 0, 'REPORT_URL', 'Report URL', 'Link to the generated report', 8);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (64, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 9);

-- Scheduled report failed
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (65, 0, 'FROM_NAME', 'From name', 'The name of the schedule owner', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (65, 0, 'FROM_EMAIL', 'From email', 'The email of the schedule owner', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (65, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (65, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (65, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (65, 0, 'TEMPLATE_NAME', 'Template name', 'The name of the template useed for the report', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (65, 0, 'SCHEDULE_NAME', 'Schedule name', 'The name of the schedule which caused the report to be generated', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (65, 0, 'ERROR_MES', 'Error message', 'A summary of why the report failed to run', 8);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (65, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 9);

--CMS data import
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (66, 0, 'IMPORT_CLASS_LABEL', 'Import class label', 'The name/description of the import', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (66, 0, 'RESULT', 'To friendly name', 'The result of the import instance', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (66, 0, 'URL', 'To user name', 'A link to the full details of the import instance', 3);

--All audit issues closed
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (67, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (67, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (67, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (67, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (67, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (67, 1, 'AUDIT_REGION', 'Audit region', 'The name of the region that the audit relates to', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (67, 1, 'AUDIT_TYPE_LABEL', 'Audit Type Label', 'Audit type label', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (67, 1, 'AUDIT_LINK', 'Audit link', 'Link to the audit', 8);


alert_id := 68;
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 1, 'DELEGATOR_FULL_NAME', 'Delegator full name', 'The full name of the user who made the delegation', 5);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 1, 'DELEGATOR_EMAIL', 'Delegator e-mail', 'The e-mail address of the user who made the delegation', 6);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 1, 'DELEGATION_NAME', 'Delegation name', 'The name of the delegation', 7);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 1, 'SUBMISSION_DTM_FMT', 'Submission date', 'The due date of the sheet', 8);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 1, 'SHEET_URL', 'Sheet link', 'A hyperlink to the sheet', 9);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 1, 'DELEG_ASSIGNED_TO', 'Assigned to', 'The name of the user the delegation is assigned to', 10);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 1, 'SHEET_PERIOD_FMT', 'Sheet period', 'The period that the sheet covers', 11);

alert_id := 69;
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 2);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'REF', 'Reference', 'The MessageUID of the originating email', 3);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'SUBJECT_RCVD', 'Subject (Received)', 'The subject of the originating email', 4);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'ERRORS', 'Errors', 'The errors in the email', 5);

alert_id := 70;
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 2);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'REF', 'Reference', 'The MessageUID of the originating email', 3);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'SUBJECT_RCVD', 'Subject (Received)', 'The subject of the originating email', 4);

INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (71, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (71, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (71, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (71, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (71, 0, 'HOST', 'Site web address', 'The web address for your CRedit371 system', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (71, 0, 'LIST_PAGE_URL', 'Link to list page', 'A link to the list page with the configured filter applied', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (71, 1, 'OBJECT_ID', 'Object ID', 'The ID of the object that matches the filter', 7);

alert_id := 72;
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'EXPORT_CLASS_LABEL', 'Export class label', 'The name/description of the export', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'RESULT', 'Result of the export', 'The result of the export instance', 2);

-- User account - pending deactivation
alert_id := 73;
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);

-- User account deactivated (system)
alert_id := 74;
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);

-- User account deactivated (manually)
alert_id := 75;
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);

-- Like for like scenario completed
alert_id := 76;
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'SLOT_NAME', 'Slot name', 'The name of the like for like slot', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'SCENARIO_RUN_NAME', 'Scenario name', 'The name of the underlying scenario', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'COMPLETION_DTM', 'Completion time', 'The date and time that the dataset completed calculating', 8);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'START_DTM', 'Start date', 'The start date of the like for like slot', 9);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'END_DTM', 'End date', 'The end date of the like for like slot', 10);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'LINK_URL', 'Link to slot', 'A link to the like for like page for the slot', 11);

-- Forecasting scenario completed
alert_id := 77;
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'SLOT_NAME', 'Slot name', 'The name of the forecasting slot', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'SCENARIO_RUN_NAME', 'Scenario name', 'The name of the underlying scenario', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'COMPLETION_DTM', 'Completion time', 'The date and time that the dataset completed calculating', 8);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'START_DTM', 'Start date', 'The start date of the forecasting slot', 9);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'NUMBER_OF_YEARS', 'Number of years', 'The number of years covered by the forecasting slot', 10);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'LINK_URL', 'Link to slot', 'A link to the forecasting page for the slot', 11);


alert_id := 78;

INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'ERROR_MESSAGE', 'Error message', 'Error generated for the import failure', 5);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'IMPORT_LINK', 'Link to Enhesa settings', 'Link to Enhesa settings page', 6);

alert_id := 79;

INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'UNMAPPED_REGIONS', 'Unmapped Enhesa region items', 'Enhesa region items that with no mapping to regions in cr360', 5);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'MAPPING_LINK', 'Link to Enhesa mapping page', 'Link to Enhesa mapping page', 6);

alert_id := 80;
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 1, 'DELEGATOR_FULL_NAME', 'Delegator full name', 'The full name of the user who made the delegation', 5);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 1, 'DELEGATOR_EMAIL', 'Delegator e-mail', 'The e-mail address of the user who made the delegation', 6);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 1, 'DELEGATION_NAME', 'Delegation name', 'The name of the delegation', 7);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 1, 'SUBMISSION_DTM_FMT', 'Submission date', 'The due date of the sheet', 8);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 1, 'SHEET_URL', 'Sheet link', 'A hyperlink to the sheet', 9);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 1, 'DELEG_ASSIGNED_TO', 'Assigned to', 'The name of the user the delegation is assigned to', 10);
INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (alert_id, 1, 'SHEET_PERIOD_FMT', 'Sheet period', 'The period that the sheet covers', 11);

END;
/

BEGIN
	INSERT INTO CSR.default_alert_frame (default_alert_frame_id, name) VALUES (csr.default_alert_frame_id_seq.nextval, 'Default');
	INSERT INTO CSR.default_alert_frame_body (default_alert_frame_id, lang, html) VALUES (csr.default_alert_frame_id_seq.currval, 'en',
		'<template>'||
		'<table width="700">'||
		'<tbody>'||
		'<tr>'||
		'<td>'||
		'<div style="font-size:9pt;color:#888888;font-family:Arial,Helvetica;border-bottom:4px solid #CA0123;margin-bottom:20px;padding-bottom:10px;">'||
		'<img src="https://resource.credit360.com/csr/shared/branding/images/ul-solutions-logo-red.png" style="height:4em;" />'||
		'</div>'||
		'<table border="0">'||
		'<tbody>'||
		'<tr>'||
		'<td style="font-family:Verdana,Arial;color:#333333;font-size:10pt;line-height:1.25em;padding-right:10px;">'||
		'<mergefield name="BODY" />'||
		'</td>'||
		'</tr>'||
		'</tbody>'||
		'</table>'||
		'<div style="font-family:Arial,Helvetica;font-size:9pt;color:#888888;border-top:4px solid #CA0123;margin-top:20px;padding-top:10px;padding-bottom:10px;"></div>'||
		'</td>'||
		'</tr>'||
		'</tbody>'||
		'</table>'||
		'</template>'
	);
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (1, csr.default_alert_frame_id_seq.currval, 'automatic');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (3, csr.default_alert_frame_id_seq.currval, 'automatic');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (4, csr.default_alert_frame_id_seq.currval, 'automatic');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (5, csr.default_alert_frame_id_seq.currval, 'automatic');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (17, csr.default_alert_frame_id_seq.currval, 'manual');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (18, csr.default_alert_frame_id_seq.currval, 'manual');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (19, csr.default_alert_frame_id_seq.currval, 'manual');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (20, csr.default_alert_frame_id_seq.currval, 'manual');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (21, csr.default_alert_frame_id_seq.currval, 'automatic');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (22, csr.default_alert_frame_id_seq.currval, 'automatic');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (23, csr.default_alert_frame_id_seq.currval, 'automatic');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (24, csr.default_alert_frame_id_seq.currval, 'automatic');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (25, csr.default_alert_frame_id_seq.currval, 'automatic');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (26, csr.default_alert_frame_id_seq.currval, 'automatic');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (27, csr.default_alert_frame_id_seq.currval, 'automatic');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (28, csr.default_alert_frame_id_seq.currval, 'automatic');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (30, csr.default_alert_frame_id_seq.currval, 'manual');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (38, csr.default_alert_frame_id_seq.currval, 'manual');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (39, csr.default_alert_frame_id_seq.currval, 'manual');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (40, csr.default_alert_frame_id_seq.currval, 'automatic');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (41, csr.default_alert_frame_id_seq.currval, 'manual');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (42, csr.default_alert_frame_id_seq.currval, 'manual');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (43, csr.default_alert_frame_id_seq.currval, 'automatic');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (44, csr.default_alert_frame_id_seq.currval, 'manual');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (45, csr.default_alert_frame_id_seq.currval, 'manual');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (46, csr.default_alert_frame_id_seq.currval, 'manual');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (48, csr.default_alert_frame_id_seq.currval, 'manual');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (49, csr.default_alert_frame_id_seq.currval, 'manual');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (50, csr.default_alert_frame_id_seq.currval, 'manual');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (51, csr.default_alert_frame_id_seq.currval, 'manual');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (52, csr.default_alert_frame_id_seq.currval, 'manual');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (53, csr.default_alert_frame_id_seq.currval, 'manual');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (56, csr.default_alert_frame_id_seq.currval, 'manual');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (60, csr.default_alert_frame_id_seq.currval, 'manual');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (61, csr.default_alert_frame_id_seq.currval, 'manual');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (62, csr.default_alert_frame_id_seq.currval, 'manual');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (63, csr.default_alert_frame_id_seq.currval, 'manual');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (64, csr.default_alert_frame_id_seq.currval, 'manual');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (65, csr.default_alert_frame_id_seq.currval, 'manual');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (66, csr.default_alert_frame_id_seq.currval, 'automatic');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (67, csr.default_alert_frame_id_seq.currval, 'manual');

	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (72, csr.default_alert_frame_id_seq.currval, 'automatic');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (73, csr.default_alert_frame_id_seq.currval, 'inactive');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (74, csr.default_alert_frame_id_seq.currval, 'inactive');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (75, csr.default_alert_frame_id_seq.currval, 'inactive');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (76, csr.default_alert_frame_id_seq.currval, 'inactive');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (77, csr.default_alert_frame_id_seq.currval, 'inactive');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (78, csr.default_alert_frame_id_seq.currval, 'inactive');
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (79, csr.default_alert_frame_id_seq.currval, 'inactive');	
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (80, csr.default_alert_frame_id_seq.currval, 'inactive');
	-- There's a default_alert_template with id 5020 that might be a real one, but could also be a spurious one.
	-- There are several chain alerts set up in SetupCsrAlerts, including 5020
	--INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type) VALUES (5020, csr.default_alert_frame_id_seq.currval, 'automatic');


	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (1, 'en',
		'<template>Welcome to the CRedit360 Application</template>',
		'<template>'||
			'<p>Dear <mergefield name="TO_FRIENDLY_NAME" /></p>'||
			'<p>You have now been set-up as a user of the credit360 application. This can be accessed at <mergefield name="HOST" />. Please visit the site and request an email to setup your new password by clicking on the ''Are you a new user?'' link located under the login button. This will then prompt you to enter your user name.</p>'||
			'<p>Your username is <mergefield name="TO_USER_NAME" /></p>'||
			'<p>Click ''Request email''. You will then receive an email containing a link, you have one hour to click on this link and set-up your new password.</p>'||
			'<p>Shortly you will receive data requests that have been specifically allocated to you. These can be viewed by clicking on ''My Data'' and then on any of the listed data requests.</p>'||
			'<p>If you have any questions please contact <a href="mailto:support@credit360.com">support@credit360.com</a>.</p>'||
			'<p>Many thanks for your help in compiling our global data requirements.</p>'||
			'<p>Regards</p>'||
			'<p>CSR Team<br /></p>'||
		'</template>',
		'<template></template>'
	);

	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (3, 'en',
		'<template>Credit360: Data Overdue.</template>',
		'<template>'||
			'<p><font face="arial" size="2">This a reminder that the following data is now overdue and needs to be entered into Credit360:</font></p>'||
			'<p><font face="arial" size="2"><mergefield name="ITEMS" />The Credit360 system is available by clicking on this link below.</font></p>'||
			'<p><mergefield name="HOST" /></p>'||
			'<p><font face="arial" size="2">Many thanks for your co-operation.</font></p>'||
			'<p><font face="arial" size="2">CSR Team<br /></font></p>'||
			'<p><font face="arial" size="2">(If you think you shouldn''t be receiving this email, or you have any questions about it, then please forward it to</font> <a href="mailto:support@credit360.com"><font face="arial" size="2">support@credit360.com</font></a><font face="arial" size="2">).</font></p>'||
		'</template>',
		'<template>'||
			'<div><mergefield name="DELEGATION_NAME" /> (<mergefield name="SHEET_PERIOD_FMT" />) <font face="arial" size="2">- due</font> <mergefield name="SUBMISSION_DTM_FMT" /><font face="arial" size="2"><br />'||
			'<mergefield name="SHEET_URL" /><br />'||
			'<br /></font></div>'||
		'</template>'
	);

	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (4, 'en',
		'<template>Data you are involved with has changed in CRedit360</template>',
		'<template><p>Hello,</p>'||
		'<p>You are receiving this e-mail because the status has changed for data you are responsible for entering or approving for this year'||CHR(38)||'apos;s CSR report.</p>'||
		'<p/>'||
		'<p><mergefield name="FROM_NAME"/> (<mergefield name="FROM_EMAIL"/>) has set the status of '||CHR(38)||'quot;<mergefield name="DELEGATION_NAME"/>'||CHR(38)||'quot; data to '||CHR(38)||'quot;<mergefield name="DESCRIPTION"/>'||CHR(38)||'quot;.</p>'||
		'<p>To view the data and take further action, please go to this web page:</p>'||
		'<p><mergefield name="SHEET_URL"/></p>'||
		'<p>(If you think you shouldn'||CHR(38)||'apos;t be receiving this e-mail, or you have any questions about it, then please forward it to support@credit360.com).</p></template>',
		'<template/>');

	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (5, 'en',
		'<template>New issue raised for your attention in CRedit360</template>',
		'<template>'||
			'Dear <mergefield name="TO_NAME" />,<br /><br />'||
			'An issue has been raised by <mergefield name="FROM_NAME" /> regarding data you provided and it has been classified as urgent:<br /><br />'||
			'<mergefield name="COMMENT" /><br /><br />'||
			'Thank you.<br />'||
		'</template>',
		'<template></template>'
	);

	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (17, 'en',
		'<template>New issue raised for your attention</template>',
		'<template>'||
			'Dear <mergefield name="TO_NAME" />,<br />'||
			'<br />'||
			'An issue has been raised by <mergefield name="FROM_NAME" /> regarding data you provided and it has been classified as urgent:<br />'||
			'<br />'||
			'<mergefield name="COMMENT" /><br />'||
			'<br />'||
			'Thank you.<br />'||
		'</template>',
		'<template></template>'
	);

	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (18, 'en',
		'<template>Issue Summary<br /></template>',
		'<template><mergefield name="ITEMS" /></template>',
		'<template>'||
			'<div style="background: none repeat scroll 0% 0% rgb(238, 238, 238); margin-top: 2em; padding: 4px; border-bottom: 2px solid rgb(221, 221, 221);">'||
			'<div style="font-size: 1.5em;"><mergefield name="SHEET_LABEL" /></div>'||
			'<mergefield name="SHEET_URL" /></div>'||
			'<mergefield name="ISSUE_DETAIL" />'||
		'</template>'
	);

	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (19, 'en',
		'<template>Document updated<br /></template>',
		'<template>'||
			'Dear <mergefield name="TO_FRIENDLY_NAME" />,<br />'||
			'<br />'||
			'The document <mergefield name="FILE_NAME" /> has been updated in the credit360 system by <mergefield name="CHANGED_BY" /> on <mergefield name="CHANGED_DTM" />.<br /><br />'||
			'Please click <mergefield name="DOC_LINK" /> in order to download the latest version. Alternatively, you can check the folder on <mergefield name="DOC_FOLDER_LINK" />.<br /><br /><br /><br />'||
		'</template>',
		'<template></template>'
	);

	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (20, 'en',
		'<template>Environment Data - Credit 360</template>',
		'<template>Dear <mergefield name="TO_FRIENDLY_NAME" /></template>',
		'<template></template>');

	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (21, 'en',
		'<template>Activate your account</template>',
		'<template><div>To validate your e-mail address and activate your account please click on the link below or copy and paste it into your web browser.<br/>'||
		'<mergefield name="URL"/></div></template>', '<template/>');

	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (22, 'en',
		'<template>New user account requested</template>',
		'<template><div>The following user has requested an account:<br/>'||
		'Username: <mergefield name="USER_NAME"/><br/>'||
		'Full Name: <mergefield name="USER_FULL_NAME"/><br/>'||
		'E-mail address: <mergefield name="USER_EMAIL"/><br/><br/>'||
		'You can view and approve uers account requests using the following link:<br/><br/><mergefield name="URL"/></div></template>',
		'<template/>');

	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (23, 'en',
		'<template>Your account has been approved</template>',
		'<template><div>Your account has been approved, you login using the following link:<br/>'||
		'<mergefield name="URL"/></div></template>',
		'<template/>');

	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (24, 'en',
		'<template>Account request rejected</template>',
		'<template><div>Your request for an account has been rejected.</div></template>',
		'<template/>');

	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (25, 'en',
		'<template>Reset Password</template>',
		'<template><div>To reset your password click on the link or copy and paste it into your web browser.<br/><br/>'||
		'<mergefield name="URL"/><br/><br/>'||
		'You have 60 minutes before this link expires.'||
		'</div></template>',
		'<template/>');

	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (26, 'en',
		'<template>Reset Password</template>',
		'<template><div>You cannot reset your password as your user account has been disabled, perhaps because you have not logged in for some time.<br/><br/>'||
		'Please contact support@credit360.com or your local CRedit360 administrator for help.'||
		'</div></template>',
		'<template/>');

	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (27, 'en',
		'<template>Credit360: Reminder for data entry.</template>',
		'<template>'||
			'<p><font face="arial" size="2">Hello <mergefield name="TO_FRIENDLY_NAME" />,</font></p>'||
			'<p><font face="arial" size="2">This a reminder that data is due shortly to be entered into Credit 360.</font></p>'||
			'<p><font face="arial" size="2"><mergefield name="ITEMS" />Many Thanks for your co-operation.</font></p>'||
			'<p><font face="arial" size="2">CSR Team<br /></font></p>'||
			'<p><font face="arial" size="2">(If you think you shouldn''t be receiving this email, or you have any questions about it, then please forward it to</font> <a href="mailto:support@credit360.com"><font face="arial" size="2">support@credit360.com</font></a><font face="arial" size="2">).</font></p>'||
		'</template>',
		'<template>'||
			'<font face="arial" size="2"><mergefield name="DELEGATION_NAME" /> (due</font> <mergefield name="SUBMISSION_DTM_FMT" />)<br />'||
			'<font face="arial" size="2"><mergefield name="SHEET_URL" /></font><br />'||
			'<br />'||
		'</template>'
	);

	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (28, 'en',
		'<template>Credit360: Data Overdue.</template>',
		'<template>'||
			'<p><font face="arial" size="2">This a reminder that data is now Overdue and needs to be entered into Credit360.</font></p>'||
			'<p><font face="arial" size="2"><mergefield name="ITEMS" />The Credit360 system is available by clicking on this link below.</font></p>'||
			'<p><mergefield name="HOST" /></p>'||
			'<p><font face="arial" size="2">Many Thanks for your co-operation.</font></p>'||
			'<p><font face="arial" size="2">CSR Team<br /></font></p>'||
			'<p><font face="arial" size="2">(If you think you shouldn''t be receiving this email, or you have any questions about it, then please forward it to</font> <a href="mailto:support@credit360.com"><font face="arial" size="2">support@credit360.com</font></a><font face="arial" size="2">).</font></p>'||
		'</template>',
		'<template>'||
			'<div><mergefield name="DELEGATION_NAME" /> (due <mergefield name="SUBMISSION_DTM_FMT" />)<br />'||
			'<font face="arial" size="2"><mergefield name="SHEET_URL" /><br />'||
			'<br /></font></div>'||
		'</template>'
	);

	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (30, 'en',
		'<template>Data you are involved with has changed in CRedit360</template>',
		'<template><p>Hello,</p>'||
		'<p>You are receiving this e-mail because the status has changed for data you are responsible for entering or approving for this year'||CHR(38)||'apos;s CSR report.</p>'||
		'<mergefield name="ITEMS"/>'||
		'<p>(If you think you shouldn'||CHR(38)||'apos;t be receiving this e-mail, or you have any questions about it, then please forward it to support@credit360.com).</p></template>',
		'<template><p><mergefield name="FROM_NAME"/> (<mergefield name="FROM_EMAIL"/>) has set the status of '||CHR(38)||'quot;<mergefield name="DELEGATION_NAME"/>'||CHR(38)||'quot; data to '||CHR(38)||'quot;<mergefield name="DESCRIPTION"/>'||CHR(38)||'quot;.</p>'||
		'<p>To view the data and take further action, please go to this web page:</p>'||
		'<p><mergefield name="SHEET_URL"/></p></template>');

	-- 36 no longer exists on live
	/*INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (36, 'en',
		'<template>A message about the data you are providing in CRedit360</template>',
		'<template><p>Message</p>'||
		'<mergefield name="ITEMS"/></template>',
		'<template><div><mergefield name="DELEGATION_NAME"/> - <mergefield name="SHEET_PERIOD_FMT"/> due <mergefield name="SUBMISSION_DTM_FMT"/>: <mergefield name="SHEET_URL"/></div></template>');
	*/

	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (38, 'en',
		'<template>You have been asked to provide cover for another user in CRedit360</template>',
		'<template><p>Hello,</p>'||
		'<p>You are receiving this e-mail because you have been asked to provide cover for another user while they are away.</p>'||
		'<p>Cover requested for <mergefield name="USER_BEING_COVERED_NAME"/> <mergefield name="COVER_DURATION"/>.</p></template>',
		'<template/>');

	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (39, 'en',
		'<template>Data you are entering has been changed in CRedit360</template>',
		'<template><p>Hello,</p>'||
		'<p>You are receiving this e-mail because data you are entering for this year'||CHR(38)||'apos;s CSR report has been changed.</p>'||
		'<p><mergefield name="FROM_NAME"/> (<mergefield name="FROM_EMAIL"/>) has changed values in data you submitted for '||CHR(38)||'quot;<mergefield name="DELEGATION_NAME"/>'||CHR(38)||'quot;.</p>'||
		'<p>To view the data and take further action, please go to this web page:</p>'||
		'<p><mergefield name="SHEET_URL"/></p>'||
		'<p>(If you think you shouldn'||CHR(38)||'apos;t be receiving this e-mail, or you have any questions about it, then please forward it to support@credit360.com).</p></template>',
		'<template/>');


	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (40, 'en',
		'<template>You have been asked to update details of Funding Commitment</template>',
		'<template><p>Hello,</p>'||
		'<p>You are receiving this e-mail because you have been asked to check details of Funding Commitment. Click following link to go to review page <mergefield name="FC_LINK"/>.</p></template>',
		'<template/>');

	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (41, 'en',
	'<template><mergefield name="TABLE_DESCRIPTION"/> form you submitted by e-mail failed</template>',
	'<template><p>Hello,</p>'||
	'<p>Thank you for your e-mail entitled "<mergefield name="SUBJECT_RCVD"/>"</p>'||
	'<p>We were unable to process this for the following reasons:</p>'||
	'<p><mergefield name="ERRORS"/></p>'||
	'</template>',
	'<template/>');

	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (42, 'en',
	'<template><mergefield name="TABLE_DESCRIPTION"/> form you submitted by e-mail was processed successfully</template>',
	'<template><p>Hello,</p>'||
	'<p>Thank you for your e-mail entitled "<mergefield name="SUBJECT_RCVD"/>"</p>'||
	'<p>It was processed successfully. Your reference is <mergefield name="REF"/>.</p>'||
	'</template>',
	'<template/>');

	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (43, 'en',
		'<template>A batch job has completed</template>',
		'<template><p>Hello,</p>'||
		'<p>You are receiving this e-mail because a batch job type '||chr(38)||'quot;<mergefield name="JOB_TYPE"/>'||chr(38)||
		'quot; and description '||chr(38)||'quot;<mergefield name="JOB_DESCRIPTION"/>'||chr(38)||'quot; that you '||
		'submitted has completed with result '||chr(38)||'quot;<mergefield name="JOB_RESULT"/>'||chr(38)||'quot;.</p>'||
		'<p/>'||
		'<p>You can view the results of the job (if applicable) by going to this web page:</p>'||
		'<p><mergefield name="JOB_URL"/></p>'||
		'<p>(If you think you shouldn'||CHR(38)||'apos;t be receiving this e-mail, or you have any questions about it, then please forward it to support@credit360.com).</p></template>',
		'<template/>');

	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (44, 'en',
		'<template>Question status has changed to <mergefield name="STATE_LABEL"/></template>',
		'<template>'||
			'<p>Dear <mergefield name="TO_FRIENDLY_NAME"/>,</p>'||
			'<p>The following questions have changed status to "<mergefield name="STATE_LABEL"/>" and now need your input:</p>'||
			'<ul>'||
				'<mergefield name="ITEMS"/>'||
			'</ul>'||
			'<p>Please go to <mergefield name="MY_QUESTIONS_LINK"/> for more information.</p>'||
		'</template>',
		'<template><li><mergefield name="SECTION_TITLE"/> (from <mergefield name="FROM_FULL_NAME" />)</li></template>'
		);

	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (45, 'en',
		'<template>Audits are about to expire</template>',
		'<template><p>Dear <mergefield name="TO_NAME"/>,</p><p>The following audits are about to expire:</p><mergefield name="ITEMS"/></template>',
		'<template><p><mergefield name="AUDIT_TYPE_LABEL"/> at <mergefield name="AUDIT_REGION"/> expires on <mergefield name="DUE_DTM"/>. <mergefield name="SCHEDULE_LINK"/></p></template>'
		);

	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (46, 'en',
		'<template>Audits have expired</template>',
		'<template><p>Dear <mergefield name="TO_NAME"/>,</p><p>The following audits have expired:</p><mergefield name="ITEMS"/></template>',
		'<template><p><mergefield name="AUDIT_TYPE_LABEL"/> at <mergefield name="AUDIT_REGION"/> expires on <mergefield name="DUE_DTM"/>. <mergefield name="SCHEDULE_LINK"/></p></template>'
		);

	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (48, 'en',
		'<template>Reminder about questions to be submitted</template>',
		'<template>'||
			'<p>Dear <mergefield name="TO_FRIENDLY_NAME"/>,</p>'||
			'<p>You''re receiving this email because there are questions awaiting your input that are due to be submitted shortly.</p>'||
			'<ul>'||
				'<mergefield name="ITEMS"/>'||
			'</ul>'||
			'<p>Please go to <mergefield name="MY_QUESTIONS_LINK"/> to submit these.</p>'||
		'</template>',
		'<template><li><mergefield name="SECTION_TITLE"/> (<mergefield name="STATE_LABEL" /> - due <mergefield name="DUE_DTM" />)</li></template>'
		);

	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (49, 'en',
		'<template>Overdue questions that need to be submitted</template>',
		'<template>'||
			'<p>Dear <mergefield name="TO_FRIENDLY_NAME"/>,</p>'||
			'<p>You''re receiving this email because there are questions awaiting your input that are now passed their due date and need immediate action.</p>'||
			'<ul>'||
				'<mergefield name="ITEMS"/>'||
			'</ul>'||
			'<p>Please go to <mergefield name="MY_QUESTIONS_LINK"/> as soon as possible to submit these.</p>'||
		'</template>',
		'<template><li><mergefield name="SECTION_TITLE"/> (<mergefield name="STATE_LABEL" /> - due <mergefield name="DUE_DTM" />)</li></template>'
		);

	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (50, 'en',
		'<template>A sheet has been automatically approved</template>',
		'<template><p>Hello,</p>'||
		'<p>This is a notification that one of your sheets has been automatically approved for you.</p>'||
		'<p>The sheet <mergefield name="SHEET_NAME"/> has been approved. You can view the sheet here: <mergefield name="EDITING_URL"/>.</p></template>',
		'<template/>');

	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (51, 'en',
		'<template>A sheet could not be automatically approved</template>',
		'<template><p>Hello,</p>'||
		'<p>This is a notification that one of your sheets could not be automatically approved due to intolerances.</p>'||
		'<p>The sheet <mergefield name="SHEET_NAME"/> has intolerances. You can view the sheet here: <mergefield name="EDITING_URL"/>.</p></template>',
		'<template/>');

	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (52, 'en',
		'<template>Questions have been submitted to you for attention</template>',
		'<template>'||
			'<p>Dear <mergefield name="TO_FRIENDLY_NAME"/>,</p>'||
			'<p>The following questions have been submitted to you and need your attention:</p>'||
			'<ul>'||
				'<mergefield name="ITEMS"/>'||
			'</ul>'||
			'<p>Please go to <mergefield name="MY_QUESTIONS_LINK"/> for more information.</p>'||
		'</template>',
		'<template><li><mergefield name="SECTION_TITLE"/> (from <mergefield name="FROM_FULL_NAME" />)</li></template>'
		);

	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (53, 'en',
		'<template>Questions have been returned to you</template>',
		'<template>'||
			'<p>Dear <mergefield name="TO_FRIENDLY_NAME"/>,</p>'||
			'<p>The following questions have been returned to you and need your attention:</p>'||
			'<ul>'||
				'<mergefield name="ITEMS"/>'||
			'</ul>'||
			'<p>Please go to <mergefield name="MY_QUESTIONS_LINK"/> for more information.</p>'||
		'</template>',
		'<template><li><mergefield name="SECTION_TITLE"/> (from <mergefield name="FROM_FULL_NAME" />)</li></template>'
		);

	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (56, 'en',
		'<template>A document you wanted to edit is now available for editing</template>',
		'<template><p>Dear <mergefield name="TO_FULLNAME"/>,</p>'||
		'<p><mergefield name="FIN_FULLNAME"/> has finished editing the document <mergefield name="FILENAME"/>.</p>'||
		'<p>It is now available for you to edit in the question <mergefield name="QUESTION_LABEL"/> via "Your Questions".</p></template>',
		'<template/>');

	--57 no longer exists on live
	/*INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (57, 'en',
		'<template>Data you are involved with has changed in CRedit360</template>',
		'<template><p>Hello,</p>'||
		'<p>You are receiving this e-mail because the status has changed for data you are responsible for entering or approving for this year'||CHR(38)||'apos;s CSR report.</p>'||
		'<mergefield name="ITEMS"/>'||
		'<p>(If you think you shouldn'||CHR(38)||'apos;t be receiving this e-mail, or you have any questions about it, then please forward it to support@credit360.com).</p></template>',
		'<template><p><mergefield name="FROM_NAME"/> (<mergefield name="FROM_EMAIL"/>) has set the status of '||CHR(38)||'quot;<mergefield name="DELEGATION_NAME"/>'||CHR(38)||'quot; data to '||CHR(38)||'quot;<mergefield name="DESCRIPTION"/>'||CHR(38)||'quot;.</p>'||
		'<p>To view the data and take further action, please go to this web page:</p>'||
		'<p><mergefield name="SHEET_URL"/></p></template>');*/

	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (60, 'en',
		'<template>Issues are about to expire</template>',
		'<template><p>Dear <mergefield name="TO_NAME"/>,</p><p>The following issues are about to expire:</p><mergefield name="ITEMS"/></template>',
		'<template><p><mergefield name="CRITICAL"/> <mergefield name="ISSUE_LABEL"/> ' || 
			'assigned to <mergefield name="ASSIGNED_TO"/> at <mergefield name="ISSUE_REGION"/> ' ||
			'expires on <mergefield name="DUE_DTM"/>. <mergefield name="ISSUE_LINK"/>' ||
		'</p></template>');

	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (61, 'en',
		'<template>Issues that have expired</template>',
		'<template><p>Dear <mergefield name="TO_NAME"/>,</p><p>The following issues have expired:</p><mergefield name="ITEMS"/></template>',
		'<template><p><mergefield name="CRITICAL"/> <mergefield name="ISSUE_LABEL"/> ' || 
			'assigned to <mergefield name="ASSIGNED_TO"/> at <mergefield name="ISSUE_REGION"/> ' ||
			'expires on <mergefield name="DUE_DTM"/>. <mergefield name="ISSUE_LINK"/>' ||
		'</p></template>');

	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (62, 'en',
		'<template>A delegation you are involved with has been edited in CRedit360</template>',
		'<template>
		<p>Hello,</p>
		<p>You are receiving this email because a delegation you are involved in has been edited before approval.</p>
		<p><mergefield name="FROM_NAME" /> (<mergefield name="FROM_EMAIL" />) has edited the delegation <mergefield name="DELEGATION_NAME" />.</p>
		<p>To view the changes, please go to this web page:</p>
		<p><mergefield name="SHEET_URL" /></p>
		<p>(If you think you should not be receiving this email, or you have any questions about it, then please forward it to <a href="mailto:support@credit360.com">support@credit360.com</a>).</p>
		</template>',
		'<template/>'
		);

	INSERT INTO CSR.DEFAULT_ALERT_TEMPLATE_BODY (STD_ALERT_TYPE_ID,LANG,SUBJECT,BODY_HTML,ITEM_HTML) VALUES (63,'en',
		'<template>Questions have been declined in CRedit360</template>',
		'<template>
		<p>Hello <mergefield name="TO_FULL_NAME"/>,</p>
		<p>The following questions have been declined by the assigned user and returned to the previous step. The user has been removed from the route.</p>
		<ul>
            		<mergefield name="ITEMS"/>
		</ul>
		<p>To view the changes, please go to this web page:</p>
		<p><mergefield name="MANAGE_QUESTIONS_LINK"/></p>
		<p>(If you think you should not be receiving this email, or you have any questions about it, then please forward it to <a href="mailto:support@credit360.com">support@credit360.com</a>).</p>
		</template>',
		'<template><li>Framework <mergefield name="MODULE_TITLE"/>, Section <mergefield name="SECTION_TITLE"/> - declined by <mergefield name="BY_FULL_NAME"/> (<mergefield name="BY_EMAIL"/>)</li></template>'
		);

	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (64, 'en',
		'<template>A scheduled report has been generated for you in CRedit360</template>',
		'<template>
		<p>Hello,</p>
		<p>You are receiving this email because a schedule report has been generated for you.</p>
		<p>The schedule named <mergefield name="SCHEDULE_NAME" /> successfully ran and generated a report for you to view.</p>
		<p>To view the report, please go to this web page:</p>
		<p><mergefield name="REPORT_URL" /></p>
		<p>(If you think you should not be receiving this email, or you have any questions about it, then please forward it to <a href="mailto:support@credit360.com">support@credit360.com</a>).</p>
		</template>',
		'<template/>'
		);

	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (65, 'en',
		'<template>A scheduled report has failed to run</template>',
		'<template>
		<p>Hello,</p>
		<p>You are receiving this email because a schedule report you were due to recieve has failed to run successfully..</p>
		<p>The schedule named <mergefield name="SCHEDULE_NAME" /> for templated report <mergefield name="TEMPLATE_NAME" /> failed with the following message;</p>
		<p><mergefield name="ERROR_MES" /></p>
		<p>If you are unable to resolve this issue yourself, or think you should not be recieving this email, then please forward it to <a href="mailto:support@credit360.com">support@credit360.com</a>).</p>
		</template>',
		'<template/>'
		);

	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (66, 'en',
		'<template>A scheduled import has completed</template>',
		'<template><p><mergefield name="IMPORT_CLASS_LABEL"/> import has completed with the following result;</p><p><mergefield name="RESULT"/></p>Further results can be accessed at the following page; <mergefield name="URL"/></template>',
		'<template/>'
		);

	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (67, 'en',
		'<template>Audits whose issues have all been closed</template>',
		'<template><p>Dear <mergefield name="TO_FRIENDLY_NAME"/>,</p><p>The following audits'' issues have all now been closed:</p><mergefield name="ITEMS"/></template>',
		'<template><p><mergefield name="AUDIT_TYPE_LABEL"/> at <mergefield name="AUDIT_REGION"/>. <mergefield name="AUDIT_LINK"/></p></template>'
		);

	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (72, 'en',
		'<template>An automated export has completed</template>',
		'<template><p><mergefield name="EXPORT_CLASS_LABEL"/> export has completed with the following result;</p><p><mergefield name="RESULT"/></p></template>',
		'<template/>'
		);
	
	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (80, 'en',
		'<template>New delegation forms to complete</template>',
		'<template><p>Hello <mergefield name="TO_FRIENDLY_NAME" />,</p><p>Delegation forms are now ready for you to complete and submit.</font></p><p><mergefield name="ITEMS" /></font></p><p>Many thanks for your co-operation.</font></p></template>',
		'<template><mergefield name="DELEGATION_NAME"/>(<mergefield name="SHEET_PERIOD_FMT"/>)- due <mergefield name="SUBMISSION_DTM_FMT"/><br/><mergefield name="SHEET_URL"/></template>'
		);
END;
/

BEGIN
INSERT INTO CSR.SHEET_ACTION_PERMISSION ( SHEET_ACTION_ID, USER_LEVEL, CAN_SAVE, CAN_SUBMIT, CAN_ACCEPT,CAN_RETURN, CAN_DELEGATE, CAN_VIEW ) VALUES ( 0, 1, 0, 0, 0, 0, 0, 1);
INSERT INTO CSR.SHEET_ACTION_PERMISSION ( SHEET_ACTION_ID, USER_LEVEL, CAN_SAVE, CAN_SUBMIT, CAN_ACCEPT,CAN_RETURN, CAN_DELEGATE, CAN_VIEW ) VALUES ( 0, 2, 1, 1, 0, 0, 1, 1);
INSERT INTO CSR.SHEET_ACTION_PERMISSION ( SHEET_ACTION_ID, USER_LEVEL, CAN_SAVE, CAN_SUBMIT, CAN_ACCEPT,CAN_RETURN, CAN_DELEGATE, CAN_VIEW ) VALUES ( 0, 3, 0, 0, 0, 0, 0, 0);
INSERT INTO CSR.SHEET_ACTION_PERMISSION ( SHEET_ACTION_ID, USER_LEVEL, CAN_SAVE, CAN_SUBMIT, CAN_ACCEPT,CAN_RETURN, CAN_DELEGATE, CAN_VIEW ) VALUES ( 1, 1, 0, 0, 1, 1, 0, 1);
INSERT INTO CSR.SHEET_ACTION_PERMISSION ( SHEET_ACTION_ID, USER_LEVEL, CAN_SAVE, CAN_SUBMIT, CAN_ACCEPT,CAN_RETURN, CAN_DELEGATE, CAN_VIEW ) VALUES ( 1, 2, 0, 0, 0, 0, 0, 1);
INSERT INTO CSR.SHEET_ACTION_PERMISSION ( SHEET_ACTION_ID, USER_LEVEL, CAN_SAVE, CAN_SUBMIT, CAN_ACCEPT,CAN_RETURN, CAN_DELEGATE, CAN_VIEW ) VALUES ( 1, 3, 0, 0, 0, 0, 0, 0);
INSERT INTO CSR.SHEET_ACTION_PERMISSION ( SHEET_ACTION_ID, USER_LEVEL, CAN_SAVE, CAN_SUBMIT, CAN_ACCEPT,CAN_RETURN, CAN_DELEGATE, CAN_VIEW ) VALUES ( 2, 1, 0, 0, 0, 0, 0, 1);
INSERT INTO CSR.SHEET_ACTION_PERMISSION ( SHEET_ACTION_ID, USER_LEVEL, CAN_SAVE, CAN_SUBMIT, CAN_ACCEPT,CAN_RETURN, CAN_DELEGATE, CAN_VIEW ) VALUES ( 2, 2, 1, 1, 0, 0, 1, 1);
INSERT INTO CSR.SHEET_ACTION_PERMISSION ( SHEET_ACTION_ID, USER_LEVEL, CAN_SAVE, CAN_SUBMIT, CAN_ACCEPT,CAN_RETURN, CAN_DELEGATE, CAN_VIEW ) VALUES ( 2, 3, 0, 0, 0, 0, 0, 0);
INSERT INTO CSR.SHEET_ACTION_PERMISSION ( SHEET_ACTION_ID, USER_LEVEL, CAN_SAVE, CAN_SUBMIT, CAN_ACCEPT,CAN_RETURN, CAN_DELEGATE, CAN_VIEW ) VALUES ( 3, 1, 0, 0, 0, 1, 0, 1);
INSERT INTO CSR.SHEET_ACTION_PERMISSION ( SHEET_ACTION_ID, USER_LEVEL, CAN_SAVE, CAN_SUBMIT, CAN_ACCEPT,CAN_RETURN, CAN_DELEGATE, CAN_VIEW ) VALUES ( 3, 2, 0, 0, 0, 0, 0, 1);
INSERT INTO CSR.SHEET_ACTION_PERMISSION ( SHEET_ACTION_ID, USER_LEVEL, CAN_SAVE, CAN_SUBMIT, CAN_ACCEPT,CAN_RETURN, CAN_DELEGATE, CAN_VIEW ) VALUES ( 3, 3, 0, 0, 0, 0, 0, 0);
INSERT INTO CSR.SHEET_ACTION_PERMISSION ( SHEET_ACTION_ID, USER_LEVEL, CAN_SAVE, CAN_SUBMIT, CAN_ACCEPT,CAN_RETURN, CAN_DELEGATE, CAN_VIEW ) VALUES ( 4, 1, 1, 0, 0, 1, 0, 0);
INSERT INTO CSR.SHEET_ACTION_PERMISSION ( SHEET_ACTION_ID, USER_LEVEL, CAN_SAVE, CAN_SUBMIT, CAN_ACCEPT,CAN_RETURN, CAN_DELEGATE, CAN_VIEW ) VALUES ( 4, 2, 0, 0, 0, 0, 0, 1);
INSERT INTO CSR.SHEET_ACTION_PERMISSION ( SHEET_ACTION_ID, USER_LEVEL, CAN_SAVE, CAN_SUBMIT, CAN_ACCEPT,CAN_RETURN, CAN_DELEGATE, CAN_VIEW ) VALUES ( 4, 3, 0, 0, 0, 0, 0, 0);
INSERT INTO CSR.SHEET_ACTION_PERMISSION ( SHEET_ACTION_ID, USER_LEVEL, CAN_SAVE, CAN_SUBMIT, CAN_ACCEPT,CAN_RETURN, CAN_DELEGATE, CAN_VIEW ) VALUES ( 5, 1, 1, 0, 0, 0, 0, 1);
INSERT INTO CSR.SHEET_ACTION_PERMISSION ( SHEET_ACTION_ID, USER_LEVEL, CAN_SAVE, CAN_SUBMIT, CAN_ACCEPT,CAN_RETURN, CAN_DELEGATE, CAN_VIEW ) VALUES ( 5, 2, 0, 0, 0, 0, 1, 1);
INSERT INTO CSR.SHEET_ACTION_PERMISSION ( SHEET_ACTION_ID, USER_LEVEL, CAN_SAVE, CAN_SUBMIT, CAN_ACCEPT,CAN_RETURN, CAN_DELEGATE, CAN_VIEW ) VALUES ( 5, 3, 0, 0, 0, 0, 0, 0);
INSERT INTO CSR.SHEET_ACTION_PERMISSION ( SHEET_ACTION_ID, USER_LEVEL, CAN_SAVE, CAN_SUBMIT, CAN_ACCEPT,CAN_RETURN, CAN_DELEGATE, CAN_VIEW ) VALUES ( 6, 1, 0, 0, 0, 1, 0, 1);
INSERT INTO CSR.SHEET_ACTION_PERMISSION ( SHEET_ACTION_ID, USER_LEVEL, CAN_SAVE, CAN_SUBMIT, CAN_ACCEPT,CAN_RETURN, CAN_DELEGATE, CAN_VIEW ) VALUES ( 6, 2, 0, 0, 0, 0, 0, 1);
INSERT INTO CSR.SHEET_ACTION_PERMISSION ( SHEET_ACTION_ID, USER_LEVEL, CAN_SAVE, CAN_SUBMIT, CAN_ACCEPT,CAN_RETURN, CAN_DELEGATE, CAN_VIEW ) VALUES ( 6, 3, 0, 0, 0, 0, 0, 0);
INSERT INTO CSR.SHEET_ACTION_PERMISSION ( SHEET_ACTION_ID, USER_LEVEL, CAN_SAVE, CAN_SUBMIT, CAN_ACCEPT,CAN_RETURN, CAN_DELEGATE, CAN_VIEW ) VALUES ( 7, 1, 1, 0, 1, 1, 0, 1);
INSERT INTO CSR.SHEET_ACTION_PERMISSION ( SHEET_ACTION_ID, USER_LEVEL, CAN_SAVE, CAN_SUBMIT, CAN_ACCEPT,CAN_RETURN, CAN_DELEGATE, CAN_VIEW ) VALUES ( 7, 2, 1, 1, 0, 0, 1, 1);
INSERT INTO CSR.SHEET_ACTION_PERMISSION ( SHEET_ACTION_ID, USER_LEVEL, CAN_SAVE, CAN_SUBMIT, CAN_ACCEPT,CAN_RETURN, CAN_DELEGATE, CAN_VIEW ) VALUES ( 7, 3, 0, 0, 0, 0, 0, 0);
INSERT INTO CSR.SHEET_ACTION_PERMISSION ( SHEET_ACTION_ID, USER_LEVEL, CAN_SAVE, CAN_SUBMIT, CAN_ACCEPT,CAN_RETURN, CAN_DELEGATE, CAN_VIEW ) VALUES ( 8, 1, 1, 0, 0, 0, 0, 1);
INSERT INTO CSR.SHEET_ACTION_PERMISSION ( SHEET_ACTION_ID, USER_LEVEL, CAN_SAVE, CAN_SUBMIT, CAN_ACCEPT,CAN_RETURN, CAN_DELEGATE, CAN_VIEW ) VALUES ( 8, 2, 1, 1, 0, 0, 1, 1);
INSERT INTO CSR.SHEET_ACTION_PERMISSION ( SHEET_ACTION_ID, USER_LEVEL, CAN_SAVE, CAN_SUBMIT, CAN_ACCEPT,CAN_RETURN, CAN_DELEGATE, CAN_VIEW ) VALUES ( 8, 3, 0, 0, 0, 0, 0, 0);
INSERT INTO CSR.SHEET_ACTION_PERMISSION ( SHEET_ACTION_ID, USER_LEVEL, CAN_SAVE, CAN_SUBMIT, CAN_ACCEPT,CAN_RETURN, CAN_DELEGATE, CAN_VIEW ) VALUES ( 9, 1, 1, 1, 0, 0, 1, 1);
INSERT INTO CSR.SHEET_ACTION_PERMISSION ( SHEET_ACTION_ID, USER_LEVEL, CAN_SAVE, CAN_SUBMIT, CAN_ACCEPT,CAN_RETURN, CAN_DELEGATE, CAN_VIEW ) VALUES ( 9, 2, 1, 1, 0, 0, 1, 1);
INSERT INTO CSR.SHEET_ACTION_PERMISSION ( SHEET_ACTION_ID, USER_LEVEL, CAN_SAVE, CAN_SUBMIT, CAN_ACCEPT,CAN_RETURN, CAN_DELEGATE, CAN_VIEW ) VALUES ( 9, 3, 0, 0, 0, 0, 0, 0);
INSERT INTO CSR.SHEET_ACTION_PERMISSION ( SHEET_ACTION_ID, USER_LEVEL, CAN_SAVE, CAN_SUBMIT, CAN_ACCEPT,CAN_RETURN, CAN_DELEGATE, CAN_VIEW ) VALUES (10, 1, 0, 0, 0, 0, 0, 1);
INSERT INTO CSR.SHEET_ACTION_PERMISSION ( SHEET_ACTION_ID, USER_LEVEL, CAN_SAVE, CAN_SUBMIT, CAN_ACCEPT,CAN_RETURN, CAN_DELEGATE, CAN_VIEW ) VALUES (10, 2, 1, 1, 0, 0, 1, 1);
INSERT INTO CSR.SHEET_ACTION_PERMISSION ( SHEET_ACTION_ID, USER_LEVEL, CAN_SAVE, CAN_SUBMIT, CAN_ACCEPT,CAN_RETURN, CAN_DELEGATE, CAN_VIEW ) VALUES (10, 3, 0, 0, 0, 0, 0, 0);
INSERT INTO CSR.SHEET_ACTION_PERMISSION ( SHEET_ACTION_ID, USER_LEVEL, CAN_SAVE, CAN_SUBMIT, CAN_ACCEPT,CAN_RETURN, CAN_DELEGATE, CAN_VIEW ) VALUES (11, 1, 1, 0, 1, 1, 0, 1);
INSERT INTO CSR.SHEET_ACTION_PERMISSION ( SHEET_ACTION_ID, USER_LEVEL, CAN_SAVE, CAN_SUBMIT, CAN_ACCEPT,CAN_RETURN, CAN_DELEGATE, CAN_VIEW ) VALUES (11, 2, 0, 0, 0, 0, 0, 1);
INSERT INTO CSR.SHEET_ACTION_PERMISSION ( SHEET_ACTION_ID, USER_LEVEL, CAN_SAVE, CAN_SUBMIT, CAN_ACCEPT,CAN_RETURN, CAN_DELEGATE, CAN_VIEW ) VALUES (11, 3, 0, 0, 0, 0, 0, 0);
INSERT INTO CSR.SHEET_ACTION_PERMISSION ( SHEET_ACTION_ID, USER_LEVEL, CAN_SAVE, CAN_SUBMIT, CAN_ACCEPT,CAN_RETURN, CAN_DELEGATE, CAN_VIEW ) VALUES (12, 1, 1, 1, 0, 0, 1, 1);
INSERT INTO CSR.SHEET_ACTION_PERMISSION ( SHEET_ACTION_ID, USER_LEVEL, CAN_SAVE, CAN_SUBMIT, CAN_ACCEPT,CAN_RETURN, CAN_DELEGATE, CAN_VIEW ) VALUES (12, 2, 1, 1, 0, 0, 1, 1);
INSERT INTO CSR.SHEET_ACTION_PERMISSION ( SHEET_ACTION_ID, USER_LEVEL, CAN_SAVE, CAN_SUBMIT, CAN_ACCEPT,CAN_RETURN, CAN_DELEGATE, CAN_VIEW ) VALUES (12, 3, 0, 0, 0, 0, 0, 0);
INSERT INTO CSR.SHEET_ACTION_PERMISSION (SHEET_ACTION_ID, USER_LEVEL, CAN_SAVE, CAN_SUBMIT, CAN_ACCEPT, CAN_RETURN, CAN_DELEGATE, CAN_VIEW ) VALUES (13, 1, 0, 0, 0, 0, 0, 1);
INSERT INTO CSR.SHEET_ACTION_PERMISSION (SHEET_ACTION_ID, USER_LEVEL, CAN_SAVE, CAN_SUBMIT, CAN_ACCEPT, CAN_RETURN, CAN_DELEGATE, CAN_VIEW ) VALUES (13, 2, 1, 1, 0, 0, 1, 1);
INSERT INTO CSR.SHEET_ACTION_PERMISSION (SHEET_ACTION_ID, USER_LEVEL, CAN_SAVE, CAN_SUBMIT, CAN_ACCEPT, CAN_RETURN, CAN_DELEGATE, CAN_VIEW ) VALUES (13, 3, 0, 0, 0, 0, 0, 0);
END;
/

BEGIN
INSERT INTO CSR.SOURCE_TYPE ( SOURCE_TYPE_ID, DESCRIPTION) VALUES (0, 'Manually entered');
INSERT INTO CSR.SOURCE_TYPE ( SOURCE_TYPE_ID, DESCRIPTION, HELPER_PKG) VALUES (1, 'Delegation', 'delegation_pkg');
INSERT INTO CSR.SOURCE_TYPE ( SOURCE_TYPE_ID, DESCRIPTION, HELPER_PKG) VALUES (2, 'Import', 'imp_pkg');
INSERT INTO CSR.SOURCE_TYPE ( SOURCE_TYPE_ID, DESCRIPTION) VALUES (3, 'Logging aggregation');
INSERT INTO CSR.SOURCE_TYPE ( SOURCE_TYPE_ID, DESCRIPTION) VALUES (4, 'Estimator');
INSERT INTO CSR.SOURCE_TYPE ( SOURCE_TYPE_ID, DESCRIPTION) VALUES (5, 'Region aggregation');
INSERT INTO CSR.SOURCE_TYPE ( SOURCE_TYPE_ID, DESCRIPTION) VALUES (6, 'Stored calculation');
INSERT INTO CSR.SOURCE_TYPE ( SOURCE_TYPE_ID, DESCRIPTION) VALUES (7, 'New delegations');
INSERT INTO CSR.SOURCE_TYPE ( SOURCE_TYPE_ID, DESCRIPTION) VALUES (8, 'Meter');
INSERT INTO CSR.SOURCE_TYPE ( SOURCE_TYPE_ID, DESCRIPTION) VALUES (9, 'Rolled forward');
INSERT INTO CSR.SOURCE_TYPE ( SOURCE_TYPE_ID, DESCRIPTION) VALUES (10, 'Real-time meter');
INSERT INTO CSR.SOURCE_TYPE ( SOURCE_TYPE_ID, DESCRIPTION) VALUES (11, 'Survey');
INSERT INTO CSR.SOURCE_TYPE ( SOURCE_TYPE_ID, DESCRIPTION) VALUES (12, 'Aggregate group');
INSERT INTO CSR.SOURCE_TYPE ( SOURCE_TYPE_ID, DESCRIPTION) VALUES (13, 'Energy Star');
INSERT INTO CSR.SOURCE_TYPE ( SOURCE_TYPE_ID, DESCRIPTION) VALUES (14, 'Region metric');
INSERT INTO CSR.SOURCE_TYPE	( SOURCE_TYPE_ID, DESCRIPTION) VALUES (15, 'Scheduled import');
INSERT INTO CSR.SOURCE_TYPE ( SOURCE_TYPE_ID, DESCRIPTION) VALUES (16, 'Fixed calc result');
INSERT INTO CSR.SOURCE_TYPE ( SOURCE_TYPE_ID, DESCRIPTION) VALUES (17, 'Approval dashboard');
INSERT INTO CSR.SOURCE_TYPE ( SOURCE_TYPE_ID, DESCRIPTION) VALUES (18, 'Chain product metric');
END;
/

BEGIN
INSERT INTO CSR.SOURCE_TYPE_ERROR_CODE ( SOURCE_TYPE_ID, ERROR_CODE, LABEL, DETAIL_URL ) VALUES	(5, 0, 'Blocked', '/csr/site/dataExplorer5/dataNavigator/dataNavigator.acds?valId=%VALID%');
INSERT INTO CSR.SOURCE_TYPE_ERROR_CODE ( SOURCE_TYPE_ID, ERROR_CODE, LABEL, DETAIL_URL ) VALUES	(5, 1, 'Aggregation failure', NULL);
END;
/

BEGIN
INSERT INTO CSR.TEMPLATE_TYPE ( TEMPLATE_TYPE_ID, NAME, MIME_TYPE, DESCRIPTION, DEFAULT_DATA) VALUES ( 1, 'Chart styles', 'text/xml', 'The default chart stylesheet', EMPTY_BLOB());
INSERT INTO CSR.TEMPLATE_TYPE ( TEMPLATE_TYPE_ID, NAME, MIME_TYPE, DESCRIPTION, DEFAULT_DATA) VALUES ( 2, 'Excel export', 'application/vnd.ms-excel', 'A template for spreadsheet exports', EMPTY_BLOB());
INSERT INTO CSR.TEMPLATE_TYPE ( TEMPLATE_TYPE_ID, NAME, MIME_TYPE, DESCRIPTION, DEFAULT_DATA) VALUES ( 3, 'Word export', 'application/msword', 'A template for Word exports', EMPTY_BLOB());
INSERT INTO CSR.TEMPLATE_TYPE ( TEMPLATE_TYPE_ID, NAME, MIME_TYPE, DESCRIPTION, DEFAULT_DATA) VALUES ( 4, 'Explorer export', 'application/msword', 'A template for Explorer exports', EMPTY_BLOB());
INSERT INTO CSR.TEMPLATE_TYPE ( TEMPLATE_TYPE_ID, NAME, MIME_TYPE, DESCRIPTION, DEFAULT_DATA) VALUES ( 5, 'Approval Step export', 'application/vnd.ms-excel', 'A template for Approval Step exports', EMPTY_BLOB());
END;
/

BEGIN
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (0,'Access Denied','Credit360.Portlets.AccessDeniedPortlet', EMPTY_CLOB(),'/csr/site/portal/Portlets/AccessDeniedPortlet.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (1,'Chart','Credit360.Portlets.Chart', EMPTY_CLOB(),'/csr/site/portal/Portlets/Chart.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (2,'Table','Credit360.Portlets.Table', TO_CLOB('{"includeExcelValueLinks":true}'),'/csr/site/portal/Portlets/Table.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (4,'Notes','Credit360.Portlets.StickyNote', EMPTY_CLOB(),'/csr/site/portal/Portlets/StickyNote.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (21,'My delegations','Credit360.Portlets.MyDelegations','{"portletHeight":400}','/csr/site/portal/Portlets/MyDelegations.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (42,'Normal Forms','Credit360.Portlets.NormalForms', EMPTY_CLOB(),'/csr/site/portal/Portlets/NormalForms.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (43,'Report Content','Credit360.Portlets.ReportContent', EMPTY_CLOB(),'/csr/site/portal/Portlets/ReportContent.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (61,'RSS feed','Credit360.Portlets.FeedViewer', EMPTY_CLOB(),'/csr/site/portal/Portlets/FeedViewer.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (81,'Community','Credit360.Portlets.Donated', EMPTY_CLOB(),'/csr/site/portal/Portlets/Donated.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (101,'Target Dashboard','Credit360.Portlets.TargetDashboard', EMPTY_CLOB(),'/csr/site/portal/Portlets/TargetDashboard.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (142,'Action Tasks','Credit360.Portlets.ActionsMyTasks', EMPTY_CLOB(),'/csr/site/portal/Portlets/ActionsMyTasks.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (161,'Gantt Chart','Credit360.Portlets.GanttChart', EMPTY_CLOB(),'/csr/site/portal/Portlets/GanttChart.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (181,'Add Donation','Credit360.Portlets.AddDonation', EMPTY_CLOB(),'/csr/site/portal/Portlets/AddDonation.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (202,'Issues','Credit360.Portlets.Issue', EMPTY_CLOB(),'/csr/site/portal/Portlets/Issue.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH, AVAILABLE_ON_HOME_PORTAL, AVAILABLE_ON_APPROVAL_PORTAL) values (223,'Supply Chain Messages','Credit360.Portlets.Chain.Messages', EMPTY_CLOB(),'/csr/site/portal/Portlets/Chain.Messages.js', 0, 0);
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH, AVAILABLE_ON_HOME_PORTAL, AVAILABLE_ON_APPROVAL_PORTAL) values (224,'Supply Chain Mailbox','Credit360.Portlets.Chain.Mailbox', EMPTY_CLOB(),'/csr/site/portal/Portlets/Chain.Mailbox.js', 0, 0);
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (243,'Your travel','Credit360.Portlets.Travel', EMPTY_CLOB(),'/csr/site/portal/Portlets/Travel.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH, AVAILABLE_ON_HOME_PORTAL, AVAILABLE_ON_APPROVAL_PORTAL) values (263,'Supply Chain Charts','Credit360.Portlets.Chain.Charts', EMPTY_CLOB(),'/csr/site/portal/Portlets/Chain.Charts.js', 0, 0);
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (283,'Region picker','Credit360.Portlets.RegionPicker', EMPTY_CLOB(),'/csr/site/portal/Portlets/RegionPicker.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (303,'Trucost Peer Comparison','Credit360.Portlets.Trucost.PeerComparison', EMPTY_CLOB(),'/trucost/site/portlets/peerComparison.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (323,'Help','Credit360.Portlets.Help', EMPTY_CLOB(),'/csr/site/portal/Portlets/Help.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (343,'My initiatives','Credit360.Portlets.ActionsMyInitiatives','{"portletHeight":450}','/csr/site/portal/Portlets/ActionsMyInitiatives.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (363,'My messages','Credit360.Portlets.MyMessages', EMPTY_CLOB(),'/csr/site/portal/Portlets/MyMessages.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (383,'Document library','Credit360.Portlets.Document', EMPTY_CLOB(),'/csr/site/portal/Portlets/Document.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH, AVAILABLE_ON_HOME_PORTAL, AVAILABLE_ON_APPROVAL_PORTAL) values (403,'Supply Chain News Flash','Credit360.Portlets.Chain.NewsFlash', EMPTY_CLOB(),'/csr/site/portal/Portlets/Chain/NewsFlash.js', 0, 0);
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH, AVAILABLE_ON_HOME_PORTAL, AVAILABLE_ON_APPROVAL_PORTAL) values (404,'Supply Chain Summary','Credit360.Portlets.Chain.InvitationSummary', EMPTY_CLOB(),'/csr/site/portal/Portlets/Chain/InvitationSummary.js', 0, 0);
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH, AVAILABLE_ON_HOME_PORTAL, AVAILABLE_ON_APPROVAL_PORTAL) values (405,'Supply Chain Required Actions','Credit360.Portlets.Chain.Actions', EMPTY_CLOB(),'/csr/site/portal/Portlets/Chain/Actions.js', 0, 0);
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH, AVAILABLE_ON_HOME_PORTAL, AVAILABLE_ON_APPROVAL_PORTAL) values (406,'Supply Chain Events','Credit360.Portlets.Chain.Events', EMPTY_CLOB(),'/csr/site/portal/Portlets/Chain/Events.js', 0, 0);
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (423,'Region list','Credit360.Portlets.RegionList', EMPTY_CLOB(),'/csr/site/portal/Portlets/RegionList.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (443,'Member company logo','Credit360.Portlets.CompanyLogo', EMPTY_CLOB(),'/csr/site/portal/Portlets/CompanyLogo.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (463,'Logging Form','Credit360.Portlets.LoggingForm', EMPTY_CLOB(),'/csr/site/portal/Portlets/LoggingForm.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH, AVAILABLE_ON_HOME_PORTAL, AVAILABLE_ON_APPROVAL_PORTAL) values (483,'Supply Chain Required Actions','Credit360.Portlets.Chain.RequiredActions', EMPTY_CLOB(),'/csr/site/portal/Portlets/Chain/RequiredActions.js', 0, 0);
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH, AVAILABLE_ON_HOME_PORTAL, AVAILABLE_ON_APPROVAL_PORTAL) values (484,'Supply Chain Recent Activity','Credit360.Portlets.Chain.RecentActivity', EMPTY_CLOB(),'/csr/site/portal/Portlets/Chain/RecentActivity.js', 0, 0);
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (503,'Region roles','Credit360.Portlets.RegionRoles', EMPTY_CLOB(),'/csr/site/portal/Portlets/RegionRoles.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (504,'Philips - Site ORUs','Philips.Portlets.SiteORUs', EMPTY_CLOB(),'/philips/site/portlets/SiteORUs.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH, AVAILABLE_ON_HOME_PORTAL, AVAILABLE_ON_APPROVAL_PORTAL) values (523,'Task Summary','Credit360.Portlets.Chain.TaskSummary', EMPTY_CLOB(),'/csr/site/portal/Portlets/Chain/TaskSummary.js', 0, 0);
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH, AVAILABLE_ON_HOME_PORTAL, AVAILABLE_ON_APPROVAL_PORTAL) values (543,'Maersk Invitation Summary','Clients.Maersk.Portlets.Summary', EMPTY_CLOB(),'/maersk/site/portlets/Summary.js', 0, 0);
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH, AVAILABLE_ON_HOME_PORTAL, AVAILABLE_ON_APPROVAL_PORTAL) values (563,'McDonalds-Boss Submission Summary','Clients.Mcdonalds.Portlets.SubmissionSummary', EMPTY_CLOB(),'/mcdonalds-boss/site/portlets/submissionSummary.js', 0, 0);
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (583,'Issue Dashboard','Clients.Jlp.Portlets.IssueDashboard', EMPTY_CLOB(),'/jlp/site/portlets/IssueDashboard.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (603,'Quick survey','Credit360.Portlets.QuickSurvey', EMPTY_CLOB(),'/csr/site/portal/Portlets/QuickSurvey.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (623,'My forms','Credit360.Portlets.MySheets','{"portletHeight":400}','/csr/site/portal/Portlets/MySheets.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (643,'Philips - My forms','Philips.Portlets.HsMySheets', EMPTY_CLOB(),'/philips/site/portlets/HsMySheets.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (663,'Trucost Report Summary','Credit360.Portlets.Trucost.ReportSummary','{ portletHeight: 575 }','/trucost/site/portlets/reportSummary.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH, AVAILABLE_ON_HOME_PORTAL, AVAILABLE_ON_APPROVAL_PORTAL) values (683,'ChainDemo Invitation Summary','Clients.ChainDemo.Portlets.Summary', EMPTY_CLOB(),'/chaindemo/site/portlets/Summary.js', 0, 0);
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (703,'John Lewis Partnership Legislation dashboard','Clients.Jlp.Portlets.LegislationDashboard', EMPTY_CLOB(),'/jlp/site/portlets/LegislationDashboard.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (724,'My donations','Credit360.Portlets.MyDonations','{"portletHeight":400}','/csr/site/portal/Portlets/MyDonations.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (763,'My dashboards','Credit360.Portlets.MyApprovalDashboards', EMPTY_CLOB(),'/csr/site/portal/Portlets/MyApprovalDashboards.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH, AVAILABLE_ON_HOME_PORTAL, AVAILABLE_ON_APPROVAL_PORTAL) values (783,'Rainforest Alliance To Do List','Credit360.Portlets.Chain.ToDoList', EMPTY_CLOB(),'/csr/site/portal/Portlets/Chain/ToDoList.js', 0, 0);
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH, AVAILABLE_ON_HOME_PORTAL, AVAILABLE_ON_APPROVAL_PORTAL) values (784,'Supply Chain Product Work Summary','Credit360.Portlets.Chain.ProductWorkSummary', EMPTY_CLOB(),'/csr/site/portal/Portlets/Chain/ProductWorkSummary.js', 0, 0);
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH, AVAILABLE_ON_HOME_PORTAL, AVAILABLE_ON_APPROVAL_PORTAL) values (803,'Rainforest Alliance FSC Checker','Clients.RainforestAlliance.Portlets.FscChecker', EMPTY_CLOB(),'/rainforestalliance/site/portlets/FscChecker.js', 0, 0);
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (823,'Meter list','Credit360.Portlets.MeterList', EMPTY_CLOB(),'/csr/site/portal/Portlets/MeterList.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (843,'New Issues','Credit360.Portlets.Issue2', EMPTY_CLOB(),'/csr/site/portal/portlets/issue2.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (863,'Region dropdown','Credit360.Portlets.RegionDropdown','{"portletHeight":100}','/csr/site/portal/portlets/regionDropdown.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (883,'Period dropdown','Credit360.Portlets.PeriodPicker','{"portletHeight":100}','/csr/site/portal/portlets/PeriodPicker.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (884,'Delegation period picker','Credit360.Portlets.DelegationPeriodPicker',EMPTY_CLOB(),'/csr/site/portal/portlets/DelegationPeriodPicker.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (903,'Location map','Credit360.Portlets.LocationMap', EMPTY_CLOB(),'/csr/site/portal/portlets/locationMap.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (904,'Image chart','Credit360.Portlets.ImageChart', EMPTY_CLOB(),'/csr/site/portal/portlets/imageChart.js');

Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (943,'Indicator picker','Credit360.Portlets.IndicatorPicker','{"portletHeight":100}','/csr/site/portal/portlets/IndicatorPicker.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (963,'Greenprint - My forms','Greenprint.Portlets.MySheetsWithVariance', EMPTY_CLOB(),'/greenprint/site/portlets/MySheetsWithVariance.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (983,'CT Breakdown picker','Credit360.Portlets.CarbonTrust.BreakdownPicker', EMPTY_CLOB(),'/csr/site/portal/portlets/ct/hotspot.jsi');
--Not in use: Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (984,'Fusion chart','Credit360.Portlets.FusionChart', EMPTY_CLOB(),'/csr/site/portal/portlets/FusionChart.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (985,'CT Advice','Credit360.Portlets.CarbonTrust.Advice', EMPTY_CLOB(),'/csr/site/portal/portlets/ct/hotspot.jsi');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (986,'Hotspot chart','Credit360.Portlets.CarbonTrust.HotspotChart', EMPTY_CLOB(),'/csr/site/portal/portlets/ct/hotspot.jsi');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (1004,'CT Welcome','Credit360.Portlets.CarbonTrust.Welcome', EMPTY_CLOB(),'/csr/site/portal/portlets/ct/hotspot.jsi');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (1005,'CT Chart Picker','Credit360.Portlets.CarbonTrust.ChartPicker', EMPTY_CLOB(),'/csr/site/portal/portlets/ct/hotspot.jsi');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (1025,'My surveys','Credit360.Portlets.MySurveys', EMPTY_CLOB(),'/csr/site/portal/Portlets/MySurveys.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (1026,'CT Flash Map','Credit360.Portlets.CarbonTrust.FlashMap', EMPTY_CLOB(),'/csr/site/portal/portlets/ct/FlashMap.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (1027,'CT Whats Next','Credit360.Portlets.CarbonTrust.WhatsNext', EMPTY_CLOB(),'/csr/site/portal/portlets/ct/WhatsNext.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (1028,'CT VC Before Hotspot','Credit360.Portlets.CarbonTrust.VCBeforeHotspot', EMPTY_CLOB(),'/csr/site/portal/portlets/ct/VCBeforeHotspot.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (1029,'CT VC Before Snapshot','Credit360.Portlets.CarbonTrust.VCBeforeSnapshot', EMPTY_CLOB(),'/csr/site/portal/portlets/ct/VCBeforeSnapshot.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (1030,'CT VC Before Module Configuration','Credit360.Portlets.CarbonTrust.VCBeforeModuleConfiguration', EMPTY_CLOB(),'/csr/site/portal/portlets/ct/VCBeforeModuleConfiguration.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (1031,'My jobs','Credit360.Portlets.MyBatchJobs', EMPTY_CLOB(),'/csr/site/portal/Portlets/MyBatchJobs.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (1032,'Audits','Credit360.Portlets.Audits', EMPTY_CLOB(),'/csr/site/portal/portlets/audits.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (1033,'Rich-text Notes','Credit360.Portlets.RichTextNote', EMPTY_CLOB(),'/csr/site/portal/portlets/RichTextNote.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (1034,'Issue Chart','Credit360.Portlets.IssueChart', EMPTY_CLOB(),'/csr/site/portal/portlets/IssueChart.js');
INSERT INTO csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) VALUES (1035,'Heineken SPM secondary region picker','HeinekenSpm.Portlets.SecondaryRegionPicker', EMPTY_CLOB(),'/heinekenspm/site/portal/portlets/SecondaryRegionPicker.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (1036,'Incident','Credit360.Portlets.Incident', EMPTY_CLOB(),'/csr/site/portal/portlets/incident.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (1037,'Vestas My Incidents','Vestas.Portlets.MyIncidents', EMPTY_CLOB(),'/vestas/site/portlets/MyIncidents.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (1038,'Incident Heat Map','Credit360.Portlets.IncidentHeatMap', EMPTY_CLOB(),'/csr/site/portal/portlets/IncidentHeatMap.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH, AVAILABLE_ON_HOME_PORTAL, AVAILABLE_ON_APPROVAL_PORTAL) values (1039,'Supply Chain Company filter picker','Credit360.Portlets.Chain.CompanyFilterPicker',EMPTY_CLOB(),'/csr/site/portal/portlets/chain/CompanyFilterPicker.js', 0, 0);
INSERT INTO csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (1040,'Pivot Table','Credit360.Portlets.PivotTable',EMPTY_CLOB(),'/csr/site/portal/portlets/PivotTable.js');
INSERT INTO csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH, AVAILABLE_ON_HOME_PORTAL, AVAILABLE_ON_APPROVAL_PORTAL) values (1041,'Supply Chain Questionnaires','Credit360.Portlets.Chain.Questionnaires',EMPTY_CLOB(),'/csr/site/portal/portlets/chain/Questionnaires.js', 0, 0);
INSERT INTO csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH, AVAILABLE_ON_HOME_PORTAL, AVAILABLE_ON_APPROVAL_PORTAL) values (1042,'Supply Chain Supplier Questionnaires','Credit360.Portlets.Chain.SupplierQuestionnaires',EMPTY_CLOB(),'/csr/site/portal/portlets/chain/SupplierQuestionnaires.js', 0, 0);
INSERT INTO csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH, AVAILABLE_ON_HOME_PORTAL, AVAILABLE_ON_APPROVAL_PORTAL) values (1043,'McDonalds Supplier Questionnaires','Clients.McdonaldsSC.Portlets.SupplierQuestionnaires', EMPTY_CLOB(),'/mcdonalds-supplychain/chain/portlets/SupplierQuestionnaires.js', 0, 0);
INSERT INTO csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH, AVAILABLE_ON_HOME_PORTAL, AVAILABLE_ON_APPROVAL_PORTAL) values (1044,'McDonalds Questionnaires','Clients.McdonaldsSC.Portlets.Questionnaires',EMPTY_CLOB(),'/mcdonalds-supplychain/chain/portlets/Questionnaires.js', 0, 0);
INSERT INTO csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (1045,'SBG Massnahmen','Clients.SBG.Massnahmen', EMPTY_CLOB(),'/lidl/site/initiatives/MassnahmenPortlet.js');
INSERT INTO csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH, AVAILABLE_ON_HOME_PORTAL, AVAILABLE_ON_APPROVAL_PORTAL) values (1046,'Supply Chain Activities','Credit360.Portlets.Chain.ActivitySummary',EMPTY_CLOB(),'/csr/site/portal/portlets/chain/ActivitySummary.js', 0, 0);
INSERT INTO csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (1047,'Data Submitted Gauge','Credit360.Portlets.DataSubmittedGauge', EMPTY_CLOB(),'/csr/site/portal/Portlets/DataSubmittedGauge.js');
Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (1048,'Interactive Map','Credit360.Portlets.GeoMap', EMPTY_CLOB(),'/csr/site/portal/Portlets/GeoMap.js');
INSERT INTO csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (1049,'Load saved record','Credit360.Portlets.RecordLoader',EMPTY_CLOB(),'/csr/site/portal/portlets/RecordLoader.js');
INSERT INTO CSR.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) VALUES (1050,'Button', 'Credit360.Portlets.Button',EMPTY_CLOB(),'/csr/site/portal/portlets/Button.js');
INSERT INTO csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH, AVAILABLE_ON_HOME_PORTAL, AVAILABLE_ON_APPROVAL_PORTAL) values (1051,'Supply Chain Questionnaire Summary','Credit360.Portlets.Chain.QuestionnaireSummary',EMPTY_CLOB(),'/csr/site/portal/portlets/Chain/QuestionnaireSummary.js', 0, 0);
INSERT INTO CSR.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH, AVAILABLE_ON_HOME_PORTAL, AVAILABLE_ON_CHAIN_PORTAL) VALUES (1052, 'Approval chart', 'Credit360.Portlets.ApprovalChart', EMPTY_CLOB(), '/csr/site/portal/portlets/ApprovalDashboards/approvalChart.js', 0, 0);
INSERT INTO CSR.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH, AVAILABLE_ON_HOME_PORTAL, AVAILABLE_ON_CHAIN_PORTAL) VALUES (1053, 'Approval Matrix', 'Credit360.Portlets.ApprovalMatrix', EMPTY_CLOB(), '/csr/site/portal/portlets/ApprovalDashboards/ApprovalMatrix.js', 0, 0);
INSERT INTO CSR.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) VALUES (1054,'Image Button', 'Credit360.Portlets.ImageButton',EMPTY_CLOB(),'/csr/site/portal/portlets/ImageButton.js');
INSERT INTO CSR.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH, AVAILABLE_ON_HOME_PORTAL, AVAILABLE_ON_CHAIN_PORTAL) VALUES (1055,'Approval note', 'Credit360.Portlets.ApprovalNote', EMPTY_CLOB(), '/csr/site/portal/portlets/ApprovalDashboards/ApprovalNote.js', 0, 0);
INSERT INTO CSR.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) VALUES (1056,'Training Matrix', 'Credit360.Portlets.TrainingMatrix', EMPTY_CLOB(), '/csr/site/portal/portlets/TrainingMatrix.js');
INSERT INTO CSR.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) VALUES (1057,'Role List', 'Credit360.Portlets.RoleList', EMPTY_CLOB(), '/csr/site/portal/Portlets/RoleList.js');
INSERT INTO CSR.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) VALUES (1058,'Image Upload Button', 'Credit360.Portlets.ImageUploadButton', EMPTY_CLOB(), '/csr/site/portal/Portlets/ImageUploadButton.js');
INSERT INTO CSR.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) VALUES (1060,'My approval dashboards filter','Credit360.Portlets.ApprovalDashboardFilter', EMPTY_CLOB(),'/csr/site/portal/portlets/ApprovalDashboardFilter.js');
INSERT INTO CSR.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) VALUES (1061,'Non-compliant items','Credit360.Portlets.Compliance.NonCompliantItems', EMPTY_CLOB(),'/csr/site/portal/portlets/compliance/NonCompliantItems.js');
INSERT INTO csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) VALUES (1062,'Compliance levels','Credit360.Portlets.ComplianceLevels', EMPTY_CLOB(),'/csr/site/portal/portlets/ComplianceLevels.js');
INSERT INTO csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) VALUES (1063,'Site compliance levels','Credit360.Portlets.SiteComplianceLevels', EMPTY_CLOB(),'/csr/site/portal/portlets/SiteComplianceLevels.js');
INSERT INTO CSR.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) VALUES (1064,'My survey campaigns','Credit360.Portlets.MySurveyCampaigns', EMPTY_CLOB(),'/csr/site/portal/portlets/MySurveyCampaigns.js');
INSERT INTO csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) VALUES (1065,'Non-Compliant Permit Conditions','Credit360.Portlets.Compliance.NonCompliantConditions', EMPTY_CLOB(),'/csr/site/portal/portlets/compliance/NonCompliantConditions.js');
INSERT INTO csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) VALUES (1066,'Site permit compliance levels','Credit360.Portlets.SitePermitComplianceLevels', EMPTY_CLOB(),'/csr/site/portal/portlets/SitePermitComplianceLevels.js');
INSERT INTO csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) VALUES (1067,'Active permit applications', 'Credit360.Portlets.Compliance.ActivePermitApplications', EMPTY_CLOB(), '/csr/site/portal/portlets/compliance/ActivePermitApplications.js');
INSERT INTO csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) VALUES (1068,'Applications summary', 'Credit360.Portlets.Compliance.PermitApplicationSummary', EMPTY_CLOB(), '/csr/site/portal/portlets/compliance/PermitApplicationSummary.js');
INSERT INTO csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) VALUES (1069,'Period picker','Credit360.Portlets.PeriodPicker2','{"portletHeight":75}','/csr/site/portal/portlets/PeriodPicker2.js');
INSERT INTO csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) VALUES (1070,'Indicator Map', 'Credit360.Portlets.IndicatorMap', EMPTY_CLOB(), '/csr/site/portal/portlets/IndicatorMap.js');
END;
/


BEGIN
INSERT INTO CSR.PENDING_ELEMENT_TYPE (ELEMENT_TYPE, IS_NUMBER, IS_STRING, LABEL) VALUES (1, 0, 1, 'Text entry field');
INSERT INTO CSR.PENDING_ELEMENT_TYPE (ELEMENT_TYPE, IS_NUMBER, IS_STRING, LABEL) VALUES (2, 0, 0, 'Text block');
INSERT INTO CSR.PENDING_ELEMENT_TYPE (ELEMENT_TYPE, IS_NUMBER, IS_STRING, LABEL) VALUES (3, 0, 0, 'Section');
INSERT INTO CSR.PENDING_ELEMENT_TYPE (ELEMENT_TYPE, IS_NUMBER, IS_STRING, LABEL) VALUES (4, 1, 1, 'Numeric');
INSERT INTO CSR.PENDING_ELEMENT_TYPE (ELEMENT_TYPE, IS_NUMBER, IS_STRING, LABEL) VALUES (5, 0, 0, 'Table');
INSERT INTO CSR.PENDING_ELEMENT_TYPE (ELEMENT_TYPE, IS_NUMBER, IS_STRING, LABEL) VALUES (6, 1, 0, 'Checkbox');
INSERT INTO CSR.PENDING_ELEMENT_TYPE (ELEMENT_TYPE, IS_NUMBER, IS_STRING, LABEL) VALUES (7, 1, 0, 'Radio');
INSERT INTO CSR.PENDING_ELEMENT_TYPE (ELEMENT_TYPE, IS_NUMBER, IS_STRING, LABEL) VALUES (8, 1, 1, 'Dropdown');
INSERT INTO CSR.PENDING_ELEMENT_TYPE (ELEMENT_TYPE, IS_NUMBER, IS_STRING, LABEL) VALUES (9, 1, 1, 'Hidden');
-- 10 is missing because it's Ian's cacky thing called 'when'
INSERT INTO CSR.PENDING_ELEMENT_TYPE (ELEMENT_TYPE, IS_NUMBER, IS_STRING, LABEL) VALUES (11, 1, 1, 'Grid');
INSERT INTO CSR.PENDING_ELEMENT_TYPE (ELEMENT_TYPE, IS_NUMBER, IS_STRING, LABEL) VALUES (12, 1, 1, 'Date');
INSERT INTO CSR.PENDING_ELEMENT_TYPE (ELEMENT_TYPE, IS_NUMBER, IS_STRING, LABEL) VALUES (13, 1, 1, 'Form');
INSERT INTO CSR.PENDING_ELEMENT_TYPE (ELEMENT_TYPE, IS_NUMBER, IS_STRING, LABEL) VALUES (14, 1, 1, 'File upload');
END;
/

BEGIN
INSERT INTO CSR.TPL_REGION_TYPE (TPL_REGION_TYPE_ID, LABEL) VALUES (1, 'Selected');
INSERT INTO CSR.TPL_REGION_TYPE (TPL_REGION_TYPE_ID, LABEL) VALUES (2, 'Parent of selected');
INSERT INTO CSR.TPL_REGION_TYPE (TPL_REGION_TYPE_ID, LABEL) VALUES (3, 'Top of tree');
INSERT INTO CSR.TPL_REGION_TYPE (TPL_REGION_TYPE_ID, LABEL) VALUES (4, 'One level from top');
INSERT INTO CSR.TPL_REGION_TYPE (TPL_REGION_TYPE_ID, LABEL) VALUES (5, 'Two levels from top');
INSERT INTO CSR.TPL_REGION_TYPE (TPL_REGION_TYPE_ID, LABEL) VALUES (6, 'Arbitrary');
INSERT INTO CSR.TPL_REGION_TYPE (TPL_REGION_TYPE_ID, LABEL) VALUES (7, 'Immediate children');
INSERT INTO CSR.TPL_REGION_TYPE (TPL_REGION_TYPE_ID, LABEL) VALUES (8, 'Selected region and its children');
INSERT INTO CSR.TPL_REGION_TYPE (TPL_REGION_TYPE_ID, LABEL) VALUES (9, 'Selected region, its parents and its children');
INSERT INTO CSR.TPL_REGION_TYPE (TPL_REGION_TYPE_ID, LABEL) VALUES (10, 'Lower level properties');
INSERT INTO CSR.TPL_REGION_TYPE (TPL_REGION_TYPE_ID, LABEL) VALUES (11, 'Two levels down');
INSERT INTO CSR.TPL_REGION_TYPE (TPL_REGION_TYPE_ID, LABEL) VALUES (12, 'All selected');
INSERT INTO CSR.TPL_REGION_TYPE (TPL_REGION_TYPE_ID, LABEL) VALUES (13, 'Selected regions at bottom of tree');
INSERT INTO CSR.TPL_REGION_TYPE (TPL_REGION_TYPE_ID, LABEL) VALUES (14, 'Selected regions one level from bottom');
INSERT INTO CSR.TPL_REGION_TYPE (TPL_REGION_TYPE_ID, LABEL) VALUES (15, 'Immediate children of the currently selected region');
INSERT INTO CSR.TPL_REGION_TYPE (TPL_REGION_TYPE_ID, LABEL) VALUES (16, 'Grandchildren of the currently selected region');
INSERT INTO CSR.TPL_REGION_TYPE (TPL_REGION_TYPE_ID, LABEL) VALUES (17, 'Each selected');
END;
/

BEGIN
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Allow approvers to edit submitted sheets', 1);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('View all meters', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Allow adding snapshots', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Can view account manager details', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Manage meter readings', 1);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Can edit all OWL clients', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Message users', 1, 'User Management: Turns on the ability to send messages to users on user list page');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Edit user details', 1, 'User Management: Allows editing of email/full name panel on User details page');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Edit user groups', 1, 'User Management: Allows editing of Groups section on User details page');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Edit user starting points', 1, 'User Management: Allows editing of Starting points section on User details page');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Edit user delegation cover', 1, 'User Management: Allows editing of Delegation cover section on User details page');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Edit user roles', 1, 'User Management: Allows editing of default User roles section on User details page');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('User roles admin', 1, 'User Management: Allows editing of restricted User roles section on User details page (based on which roles you have ability to grant to)');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Edit user active', 1, 'User Management: Allows editing of Active checkbox on User details page');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Edit user accessibility', 1, 'User Management: Allows editing of Accessibility section on User details page');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Edit user alerts', 1, 'User Management: Allows editing of Send alerts? checkbox on User details page');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Edit user regional settings', 1, 'User Management: Allows editing of Regional settings (language / culture) on User details page');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Edit user region association', 1, 'User Management: Allows editing of Regions with which user is associated section on User details page (Note: This field is not necessary on most new sites. It is only used with the Community involvement module.)');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Manage CT Templates', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Copy forward delegation', 1, 'Delegations: Allows a user to copy forward values from the previous sheet');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Manage text question carts', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Edit region active', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Edit region categories', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Ask for section edit message', 1);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Ask for section state change message', 1);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Save shared region sets', 0, 'Reporting: Allows user to save region sets for other users to access');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Save shared indicator sets', 0, 'Reporting: Allows user to save indicator sets for other users to access');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Allow parent sheet submission before child sheet approval', 0, 'Delegations: It''s possible in delegations to submit a parent before a child (e.g. if the person who normally enters is off on holiday). Turning this on stops this happening.');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Allow sheet to be returned once approved', 1, 'Delegations: Allows a sheet to be returned once approved');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Only allow bottom delegation to enter data', 0, 'Delegations: Only allow bottom delegation to enter data');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Highlight unmerged data', 0, 'Data Explorer: Shows the Suppress unmerged data message checkbox');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Reports', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Read Fogbugz', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Edit Region Docs', 1, 'Region Management: Show/hide ability to link documents to regions (used for CRC reporting but could be implemented more broadly)');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('View emission factors', 0, 'System Management: Allows user to view emission factors');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Admin Employee Commuting', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Admin Business Travel', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Admin Products Services', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Admin Use Phase', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Edit Employee Commuting', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Edit Business Travel', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Edit Products Services', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Edit Use Phase', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Administer Chemical module', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Logon directly', 1);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Can delete section comments', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Use section forms', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Remap Energy Star property', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Change brandings', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Lock brandings', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Subdelegation', 1, 'Delegations: Allows a user to subdelegate sheets');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Delegation reports', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Split delegations', 1, 'Delegations: Allows a user to split a delegation into separate child regions');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Manage emission factors', 0, 'System Management: Allows user to edit emission factors');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Read all OWL clients', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Can edit OWL work', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Manage Logistics', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Allow users to raise data change requests', 0, 'Delegations: Allows the user to raise a data change request for a sheet they have already submitted');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Edit personal details', 1, 'My Details: Allows user to change their full name and email address');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Run sheet export report', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Manage chain capabilities', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Can edit section tags', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Can view section tags', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Can see routed flow transitions', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('View alert bounces', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Auto Approve Valid Delegation', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Can filter section userview', 1);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Can purge initiatives', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Can import initiatives', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Hide year on chart axis labels when chart has FlyCalc', 0, 'Data Explorer: On-the-fly calculations are often used in Data Explorer to show this year versus the previous year. In this situation, showing the previous year label doesn''t really make sense, so this capability can be used to hide it.');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Edit personal delegation cover', 0, 'My Details: Show and change who is covering for you on delegation data provision');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Delete Utility Supplier', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Delete Utility Contract', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Delete Utility Invoice', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Manage import templates', 1);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Set initiative metric details', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Load models INTO the calculation engine', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Create users for approval', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Philips - View detailed BCS data', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('View user audit log', 1, 'System Management: This capability is required to view the audit log on the Indicator details, Region details, and User details pages');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('View Delegation link from Sheet', 1, 'Delegations: Shows a link to the delegation from the Sheet page');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Import surveys from Excel', 1);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Manage jobs', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Can view section history', 1);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Delete and copy values', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Activity management', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('View all avatars', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Can generate audit log reports', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Can edit transition comment', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Choose new property parent', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('System management', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Issue management', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Report publication', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Access all contracts', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Manage any portal', 0, 'Portals: Tabs (or Portal pages) can generally only be edited by the owner. This capability allows users to make changes to any tab (including adding items, editing tab settings, deleting the tab, hiding the tab or showing tabs that they have hidden) via the Options menu on their homepage.');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Allow user to share CMS filters', 1, 'CMS: Allows users to see Public filters folder in list views (ability to write to the folder is permission controlled)');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Auto show sheet value popup', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Issue type management', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Add portal tabs', 1, 'Portals: Allows user to add new portal tabs.  Also allows a user to copy a tab, hide a tab or view tabs they have hidden via the Options menu on their homepage.');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Close audits', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Can import audit non-compliances', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Suppress N\A''s in model runs', 0, 'Excel Models: Treat N/A as a blank cell value in Excel models instead of as N/A');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Can edit section docs', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Allow changing Indicator lookup keys', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Download all templated reports', 0, 'Templated Reports: View and download any templated reports, even if you didn t generate or receive them');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Automatically approve Data Change Requests', 0, 'Delegations: Data Change requests where the user''s data has been approved normally need the current owner to approve them. If enabled, the form is automatically returned to the user.');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Enable Delegation Sheet changes warning', 0, 'Delegations: Shows a message indicating there are unsaved values on a delegation form when you click away from the web page');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Can view others audits', 1);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Compare Chain Survey to previous submission', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Search all sections', 1);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Manually import automated import instances', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Edit user job functions', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Edit user relationships', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Can import users and role memberships via structure import', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Manage all templated report settings', 0, 'Templated Reports: Needed to manage advanced settings for administering templated reports e.g. "change owner"');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Can edit course details', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Can edit course schedule', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Can manage course requests', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Can edit forms before system lock date', 0, 'Delegations: Allows users to change values on delegations sheets in spite of system lock date settings');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Can edit date locked logging forms', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Can manage filter alerts', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Can export delegation summary', 0, 'Delegations: Show additional export option in sheet export toolbar item dropdown');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('View initiatives audit log', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('View user details', 0, 'User Management: Allows the display of the user fields user name, full name, friendly name, email, job title and phone number in user management');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Edit user primary region', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Can run additional automated import instances', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Can run additional automated export instances', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Can preview automated exports', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Can manage group membership list page', 1, 'User Management: Allows management of group membership from the users list page');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Can deactivate users list page', 1, 'User Management: Allows deactivation of users from the users list page');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Can import std factor set', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Can publish std factor set', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Enable Dataview Bar Variance Options', 0, 'Data Explorer: Displays checkboxes in Data Explorer allowing users to display the percentage or absolute variances between periods on charts (either between consecutive periods or between a specified baseline period and each subsequent period).');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Import core translations', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Manage compliance items', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('View user profiles', 0, 'User Management: Allows viewing of User Profile information');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Region Emission Factor Cascading', 0, 'Emission Factors: Cascade region level factors to child regions.');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Rerun Scheduled Scripts (SSPs)', 0, 'Allow user to rerun scheduled database scripts (SSPs)');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Disable Scheduled Scripts (SSPs)', 0, 'Allow user to enable and disable scheduled database scripts (SSPs)');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Quick chart management', 0, 'Allows user to manage quick chart columns and filters configuration.');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Compliance Languages', 0, 'Enable compliance languages feature.');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Can delete factor type', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Can edit cscript inds', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Can create cscript inds', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Context Sensitive Help', 1, 'Enable context sensitive help for this site.');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Context Sensitive Help Management', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Enable Delegation Plan Folders', 0, 'Delegations: Enable foldering for delegation plans in Manage Delegation Plans.');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Legacy Chart Wrappers (UD-13034)', 0, 'Legacy: Use legacy chart wrapper generation.');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Google Analytics Management', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Initiative Temp Saving Apportion', 0, 'Initiatives with temp savings should apportion over partially spanned metric Initiative period intervals.');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Enable Refresh of Finding List Plugin', 1, 'Added a function to enable users to refresh the findings on the finding list when multiple audit details are opened in different browser tabs. This ensures that the finding list displays up to date records.');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Manage the Delegation Pinboard', 0, 'Enables or disables the delegation pinboard on a delegation sheet. This feature allows for uploading attachments or notes to a delegation sheet by administrators. Other user groups can be added subsequently.');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Enable roll forward on indicators', 0, 'Enable the legacy functionality for roll forward on indicators. Do not ENABLE without reference to Product.');
INSERT INTO csr.capability (name, allow_by_default, description) VALUES ('Prioritise sheet values in sheets', 0, 'When allowed: Use and show value from sheet if available, otherwise value from scrag. When not allowed: use scrag value first, if available');
INSERT INTO csr.capability (name, allow_by_default, description) VALUES ('Can manage custom notification templates', 0, 'Allows creation and modification of notification types');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Enable Actions Bulk Update', 0, 'Enable multi select and bulk update on Actions page');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Adjust period labels to start month', 0, 'Fix period labels for default period set with non January start month');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Anonymise PII data', 1, 'When enabled, this capability will be granted to the Admin group. Subsequently, please run the existing utilscript to grant this capability to Superadmins instead.');
INSERT INTO csr.capability (name, allow_by_default, description) VALUES ('Can manage notification failures', 0, 'Enables resend or delete of failed notifications');
INSERT INTO csr.capability (name, allow_by_default, description) VALUES ('Enable Temporal Aggregation on Measure Conversion Flycalcs', 0, 'Enable Temporal Aggregation on Measure Conversion Flycalcs');
INSERT INTO csr.capability (name, allow_by_default, description) VALUES ('Enable multi frequency variance options', 0, 'Delegations:  Enables new multi frequency variance options on delegations');
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, description) VALUES ('Target Planning', 0, 'Under development, do not use: Allows user to add historical data, regions, dates and a future target. The system calculates a trendline.');
-- Note: remove description to exclude capability from Enable Cap page.
END;
/

BEGIN
-- Client-specific capabilities
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Edit user line manager', 0, 'User Management: Show / edit line-manager field in the User details page');
END;
/

BEGIN
INSERT INTO CSR.IND_ACTIVITY_TYPE (IND_ACTIVITY_TYPE_ID, LABEL, POS) VALUES (1, 'n/a', 1);
INSERT INTO CSR.IND_ACTIVITY_TYPE (IND_ACTIVITY_TYPE_ID, LABEL, POS) VALUES (2, 'Gas', 2);
INSERT INTO CSR.IND_ACTIVITY_TYPE (IND_ACTIVITY_TYPE_ID, LABEL, POS) VALUES (3, 'Electricity', 3);
END;
/

BEGIN
INSERT INTO CSR.QUESTION_TYPE(QUESTION_TYPE, LABEL, ANSWER_TYPE) VALUES ('section', 'Section', null);
INSERT INTO CSR.QUESTION_TYPE(QUESTION_TYPE, LABEL, ANSWER_TYPE) VALUES ('radio', 'Radio button', 'option');
INSERT INTO CSR.QUESTION_TYPE(QUESTION_TYPE, LABEL, ANSWER_TYPE) VALUES ('checkboxgroup', 'Checkbox group', null);
INSERT INTO CSR.QUESTION_TYPE(QUESTION_TYPE, LABEL, ANSWER_TYPE) VALUES ('checkbox', 'Checkbox item', 'val');
INSERT INTO CSR.QUESTION_TYPE(QUESTION_TYPE, LABEL, ANSWER_TYPE) VALUES ('note', 'Text', null);
INSERT INTO CSR.QUESTION_TYPE(QUESTION_TYPE, LABEL, ANSWER_TYPE) VALUES ('pagebreak', 'Page break', null);
INSERT INTO CSR.QUESTION_TYPE(QUESTION_TYPE, LABEL, ANSWER_TYPE) VALUES ('matrix', 'Matrix', null);
INSERT INTO CSR.QUESTION_TYPE(QUESTION_TYPE, LABEL, ANSWER_TYPE) VALUES ('radiorow', 'Matrix radio button row', 'option');
INSERT INTO CSR.QUESTION_TYPE(QUESTION_TYPE, LABEL, ANSWER_TYPE) VALUES ('number', 'Number', 'val');
INSERT INTO CSR.QUESTION_TYPE(QUESTION_TYPE, LABEL, ANSWER_TYPE) VALUES ('slider', 'Slider', 'val');
INSERT INTO CSR.QUESTION_TYPE(QUESTION_TYPE, LABEL, ANSWER_TYPE) VALUES ('date', 'Date', 'val');
INSERT INTO CSR.QUESTION_TYPE(QUESTION_TYPE, LABEL, ANSWER_TYPE) VALUES ('files', 'Files', null);
INSERT INTO CSR.QUESTION_TYPE(QUESTION_TYPE, LABEL, ANSWER_TYPE) VALUES ('richtext', 'Text area', null);
INSERT INTO CSR.QUESTION_TYPE(QUESTION_TYPE, LABEL, ANSWER_TYPE) VALUES ('regionpicker', 'Region picker', null);
INSERT INTO CSR.QUESTION_TYPE(QUESTION_TYPE, LABEL, ANSWER_TYPE) VALUES ('custom', 'Custom', null);
INSERT INTO CSR.QUESTION_TYPE(QUESTION_TYPE, LABEL, ANSWER_TYPE) VALUES ('rtquestion', 'Rich text question', null);
INSERT INTO CSR.QUESTION_TYPE(QUESTION_TYPE, LABEL, ANSWER_TYPE) VALUES ('noncompliances', 'Ad-hoc audit findings', null);
INSERT INTO CSR.QUESTION_TYPE(QUESTION_TYPE, LABEL, ANSWER_TYPE) VALUES ('evidence', 'Evidence question', null);
END;
/



DECLARE
	v_act				security.security_pkg.T_ACT_ID;
	v_csr_sid			security.security_pkg.T_SID_ID;
	v_csr_users_sid		security.security_pkg.T_SID_ID;
	v_superadmins_sid	security.security_pkg.T_SID_ID;
	v_help_sid			security.security_pkg.T_SID_ID;
	v_lang_id			csr.help_lang.help_lang_id%TYPE;
	v_reporting_periods_sid			security.security_pkg.T_SID_ID;
	v_region_root_sid	security.security_pkg.t_sid_id;
	v_ind_root_sid		security.security_pkg.t_sid_id;
BEGIN
	security.user_pkg.logonauthenticatedpath(0,'//builtin/administrator',500,v_act);
	security.securableobject_pkg.createSO(v_act, 0, security.security_pkg.SO_CONTAINER, 'csr',v_csr_sid);
	security.securableobject_pkg.createso(v_act, v_csr_sid, security.security_pkg.so_container, 'Regions', v_region_root_sid);
	security.securableobject_pkg.createso(v_act, v_csr_sid, security.security_pkg.so_container, 'Indicators', v_ind_root_sid);
	security.securableobject_pkg.createSO(v_act, v_csr_sid, security.security_pkg.SO_CONTAINER, 'ReportingPeriods', v_reporting_periods_sid);
	security.securableobject_pkg.createSO(v_act, v_csr_sid, security.security_pkg.SO_CONTAINER, 'Users',v_csr_users_sid);
	security.group_pkg.createGroup(v_act, v_csr_sid, security.security_pkg.GROUP_TYPE_SECURITY, 'SuperAdmins',v_superadmins_sid);

	-- grant superadmins write on csr folder
	security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_csr_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
		security.security_pkg.ACE_FLAG_DEFAULT, v_superadmins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	security.acl_pkg.PropogateACEs(v_act, v_csr_sid);

	-- boot strap the help system with a Help root node and British English language
	BEGIN
		security.securableobject_pkg.createSO(v_act, v_csr_sid, security.security_pkg.SO_CONTAINER, 'Help', v_help_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	-- this was failing to add a lang as one call - as I think the Help container may have already existed - so doing the equivalent of what was being run in 2 blocks
	BEGIN
		csr.help_pkg.AddLanguage(v_act, NULL, 'English (British)', v_lang_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	COMMIT;
END;
/

-- Insert region types
-- /csr/styles/css/treeview.css has the css in there
BEGIN
	INSERT INTO CSR.region_type (region_type, label, class_name) VALUES(0, 'Normal', 'CSRRegion');
	INSERT INTO CSR.region_type (region_type, label, class_name) VALUES(1, 'Meter', 'CSRMeterRegion');
	INSERT INTO CSR.region_type (region_type, label, class_name) VALUES(2, 'Root', 'Container');
	INSERT INTO CSR.region_type (region_type, label, class_name) VALUES(3, 'Property', 'CSRPropertyRegion');
	INSERT INTO CSR.region_type (region_type, label, class_name) VALUES(4, 'Tenant', 'CSRTenantRegion');
	INSERT INTO CSR.region_type (region_type, label, class_name) VALUES(5, 'Rate', 'CSRRateRegion');
	INSERT INTO CSR.region_type (region_type, label, class_name) VALUES(6, 'Managing agent', 'CSRAgentRegion');
	INSERT INTO CSR.region_type (region_type, label, class_name) VALUES(7, 'Supplier', 'CSRSupplierRegion');
	INSERT INTO CSR.region_type (region_type, label, class_name) VALUES(8, 'Real-time meter', 'CSRRealtimeMeterRegion');
	INSERT INTO CSR.region_type (region_type, label, class_name) VALUES(9, 'Space', 'CSRTenantRegion');
	INSERT INTO CSR.region_type (region_type, label, class_name) VALUES(10, 'Aggregate region', 'CSRAggrRegion');
END;
/

BEGIN
	INSERT INTO CSR.model_map_type (model_map_type_id, map_type) VALUES (0, 'Unknown');
	INSERT INTO CSR.model_map_type (model_map_type_id, map_type) VALUES (1, 'User Editable Field');
	INSERT INTO CSR.model_map_type (model_map_type_id, map_type) VALUES (2, 'Mapped Field');
	INSERT INTO CSR.model_map_type (model_map_type_id, map_type) VALUES (3, 'Formula Field');
	INSERT INTO CSR.model_map_type (model_map_type_id, map_type) VALUES (4, 'Comment Field');
	INSERT INTO CSR.model_map_type (model_map_type_id, map_type) VALUES (5, 'Ignore Formula'); -- deprecated?
	INSERT INTO CSR.model_map_type (model_map_type_id, map_type) VALUES (6, 'Region name');
	INSERT INTO CSR.model_map_type (model_map_type_id, map_type) VALUES (7, 'Exported Formula');
END;
/

@@factor_data_start
@@factor_data_types
-- turn off logging for massive factor inserts
spool off
@@factor_data_factors
spool buildAllDB.log append
@@factor_data_end

-- Meter monitor raw data statuses
BEGIN
	INSERT INTO CSR.meter_raw_data_status (status_id, description, needs_processing) VALUES(1, 'New', 1);
	INSERT INTO CSR.meter_raw_data_status (status_id, description, needs_processing) VALUES(2, 'Retry', 1);
	INSERT INTO CSR.meter_raw_data_status (status_id, description, needs_processing) VALUES(3, 'Processing', 0);
	INSERT INTO CSR.meter_raw_data_status (status_id, description, needs_processing) VALUES(4, 'Has errors', 0);
	INSERT INTO CSR.meter_raw_data_status (status_id, description, needs_processing) VALUES(5, 'Success', 0);
	INSERT INTO CSR.meter_raw_data_status (status_id, description, needs_processing) VALUES(6, 'Pre-processing errors', 0);
	INSERT INTO CSR.meter_raw_data_status (status_id, description, needs_processing) VALUES(7, 'Retry', 0);
	INSERT INTO csr.meter_raw_data_status (status_id, description, needs_processing) VALUES(8, 'Reverting', 0);
	INSERT INTO csr.meter_raw_data_status (status_id, description, needs_processing) VALUES(9, 'Reverted', 0);
	INSERT INTO csr.meter_raw_data_status (status_id, description, needs_processing) VALUES(10, 'Queued', 0);
	INSERT INTO csr.meter_raw_data_status (status_id, description, needs_processing) VALUES(11, 'Merging', 0);
END;
/

BEGIN
	INSERT INTO CSR.calculation_type (calculation_type_id, description) VALUES (0, 'None');
	INSERT INTO CSR.calculation_type (calculation_type_id, description) VALUES (1, 'Percentage change');
	INSERT INTO CSR.calculation_type (calculation_type_id, description) VALUES (2, 'Previous period');
	INSERT INTO CSR.calculation_type (calculation_type_id, description) VALUES (3, 'Same period previous year');
	INSERT INTO CSR.calculation_type (calculation_type_id, description) VALUES (4, 'Same period in the year before last year');
	INSERT INTO CSR.calculation_type (calculation_type_id, description) VALUES (5, 'Year to date');
	INSERT INTO CSR.calculation_type (calculation_type_id, description) VALUES (6, 'Full year equivalent');
	INSERT INTO CSR.calculation_type (calculation_type_id, description) VALUES (7, 'Rolling 12 month total');
	INSERT INTO CSR.calculation_type (calculation_type_id, description) VALUES (8, 'Percentage change from same period previous year');
	INSERT INTO CSR.calculation_type (calculation_type_id, description) VALUES (9, 'Percentage in year to date from same period previous year');
	INSERT INTO CSR.calculation_type (calculation_type_id, description) VALUES (10,'Absolute change');
	INSERT INTO CSR.calculation_type (calculation_type_id, description) VALUES (11, 'Rolling 12 month average');
	INSERT INTO CSR.calculation_type (calculation_type_id, description) VALUES (12, 'Comparative year to date');
END;
/

BEGIN
	INSERT INTO csr.location_type (location_type_id, name) VALUES (1, 'Airport');
	INSERT INTO csr.location_type (location_type_id, name) VALUES (2, 'Country');
	INSERT INTO csr.location_type (location_type_id, name) VALUES (3, 'Port');
	INSERT INTO csr.location_type (location_type_id, name) VALUES (4, 'Road');
	INSERT INTO csr.location_type (location_type_id, name) VALUES (5, 'Barge port');
	INSERT INTO csr.location_type (location_type_id, name) VALUES (6, 'Rail station');
END;
/

BEGIN
	INSERT INTO csr.logistics_processor_class (processor_class_id,label) VALUES (1,'Logistics.Modes.AirportJobProcessor');
	INSERT INTO csr.logistics_processor_class (processor_class_id,label) VALUES (2,'Logistics.Modes.AirCountryJobProcessor');
	INSERT INTO csr.logistics_processor_class (processor_class_id,label) VALUES (3,'Logistics.Modes.RoadJobProcessor');
	INSERT INTO csr.logistics_processor_class (processor_class_id,label) VALUES (4,'Logistics.Modes.SeaJobProcessor');
	INSERT INTO csr.logistics_processor_class (processor_class_id,label) VALUES (5,'Logistics.Modes.BargeJobProcessor');
	INSERT INTO csr.logistics_processor_class (processor_class_id,label) VALUES (6,'Logistics.Modes.RailJobProcessor');
END;
/

BEGIN
	INSERT INTO csr.transport_mode (transport_mode_id, label) VALUES (1, 'Air'); --csr_data_pkg.transport_mode_AIR
	INSERT INTO csr.transport_mode (transport_mode_id, label) VALUES (2, 'Sea'); --csr_data_pkg.transport_mode_SEA
	INSERT INTO csr.transport_mode (transport_mode_id, label) VALUES (3, 'Road'); --csr_data_pkg.transport_mode_ROAD
	INSERT INTO csr.transport_mode (transport_mode_id, label) VALUES (4, 'Barge'); --csr_data_pkg.transport_mode_BARGE
	INSERT INTO csr.transport_mode (transport_mode_id, label) VALUES (5, 'Rail'); --csr_data_pkg.transport_mode_RAIL
END;
/

BEGIN
	INSERT INTO CSR.ISSUE_ACTION_TYPE (ISSUE_ACTION_TYPE_ID, DESCRIPTION) VALUES (0, 'Opened');
	INSERT INTO CSR.ISSUE_ACTION_TYPE (ISSUE_ACTION_TYPE_ID, DESCRIPTION) VALUES (1, 'Assigned');
	INSERT INTO CSR.ISSUE_ACTION_TYPE (ISSUE_ACTION_TYPE_ID, DESCRIPTION) VALUES (2, 'Emailed correspondent');
	INSERT INTO CSR.ISSUE_ACTION_TYPE (ISSUE_ACTION_TYPE_ID, DESCRIPTION) VALUES (3, 'Resolved');
	INSERT INTO CSR.ISSUE_ACTION_TYPE (ISSUE_ACTION_TYPE_ID, DESCRIPTION) VALUES (4, 'Closed');
	INSERT INTO CSR.ISSUE_ACTION_TYPE (ISSUE_ACTION_TYPE_ID, DESCRIPTION) VALUES (5, 'Reopened');
	INSERT INTO CSR.ISSUE_ACTION_TYPE (ISSUE_ACTION_TYPE_ID, DESCRIPTION) VALUES (6, 'Due date changed');
	INSERT INTO CSR.ISSUE_ACTION_TYPE (ISSUE_ACTION_TYPE_ID, DESCRIPTION) VALUES (7, 'Emailed user');
	INSERT INTO CSR.ISSUE_ACTION_TYPE (ISSUE_ACTION_TYPE_ID, DESCRIPTION) VALUES (8, 'Priority changed');
	INSERT INTO CSR.ISSUE_ACTION_TYPE (ISSUE_ACTION_TYPE_ID, DESCRIPTION) VALUES (9, 'Rejected');
	INSERT INTO CSR.ISSUE_ACTION_TYPE (ISSUE_ACTION_TYPE_ID, DESCRIPTION) VALUES (10, 'Label changed');
	INSERT INTO CSR.ISSUE_ACTION_TYPE (ISSUE_ACTION_TYPE_ID, DESCRIPTION) VALUES (11, 'Emailed role');
	INSERT INTO CSR.ISSUE_ACTION_TYPE (ISSUE_ACTION_TYPE_ID, DESCRIPTION) VALUES (12, 'Email received');
	INSERT INTO CSR.ISSUE_ACTION_TYPE (ISSUE_ACTION_TYPE_ID, DESCRIPTION) VALUES (13, 'Escalated');
	INSERT INTO CSR.ISSUE_ACTION_TYPE (ISSUE_ACTION_TYPE_ID, DESCRIPTION) VALUES (14, 'Accepted');
	INSERT INTO CSR.ISSUE_ACTION_TYPE (ISSUE_ACTION_TYPE_ID, DESCRIPTION) VALUES (15, 'Returned');
	INSERT INTO CSR.ISSUE_ACTION_TYPE (ISSUE_ACTION_TYPE_ID, DESCRIPTION) VALUES (16, 'Pending assignment confirmation');
	INSERT INTO CSR.ISSUE_ACTION_TYPE (ISSUE_ACTION_TYPE_ID, DESCRIPTION) VALUES (17, 'Description changed');
	INSERT INTO CSR.ISSUE_ACTION_TYPE (ISSUE_ACTION_TYPE_ID, DESCRIPTION) VALUES (18, 'Forecast date changed');
	INSERT INTO CSR.ISSUE_ACTION_TYPE (ISSUE_ACTION_TYPE_ID, DESCRIPTION) VALUES (19, 'RAG status changed');
	INSERT INTO CSR.ISSUE_ACTION_TYPE (ISSUE_ACTION_TYPE_ID, DESCRIPTION) VALUES (20, 'Explained variance');
	INSERT INTO CSR.ISSUE_ACTION_TYPE (ISSUE_ACTION_TYPE_ID, DESCRIPTION) VALUES (21, 'Owner changed');
	INSERT INTO CSR.ISSUE_ACTION_TYPE (ISSUE_ACTION_TYPE_ID, DESCRIPTION) VALUES (22, 'Region changed');
	INSERT INTO CSR.ISSUE_ACTION_TYPE (ISSUE_ACTION_TYPE_ID, DESCRIPTION) VALUES (23, 'Critical status changed');
	INSERT INTO CSR.ISSUE_ACTION_TYPE (ISSUE_ACTION_TYPE_ID, DESCRIPTION) VALUES (24, 'Deleted');
	INSERT INTO CSR.ISSUE_ACTION_TYPE (ISSUE_ACTION_TYPE_ID, DESCRIPTION) VALUES (25, 'Public status changed');
	INSERT INTO CSR.ISSUE_ACTION_TYPE (ISSUE_ACTION_TYPE_ID, DESCRIPTION) VALUES (26, 'Involved user assigned');
	INSERT INTO CSR.ISSUE_ACTION_TYPE (ISSUE_ACTION_TYPE_ID, DESCRIPTION) VALUES (27, 'Involved user removed');
END;
/

BEGIN
  INSERT INTO CSR.help_lang (help_lang_id, base_lang_id, label, short_name) VALUES (csr.help_lang_id_seq.NEXTVAL, 1, 'English (British)', 'gb');
END;
/

BEGIN
	-- Notes:
	-- Category must be upper trimmed, and be as descriptive as possible to help uniqueness
	-- Setting must be trimmed, and EXACTLY the same case formatting that will come from the javascript
	-- Data type must be one of STRING, NUMBER or BOOLEAN
	-- Description should tell us where this is being used
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.MYSHEETS', 'activeTab', 'STRING', 'stores the last active MySheets tab');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.MYSHEETS', 'toApproveGroupBy', 'STRING', 'stores last group by combo selection on the toApprove tab');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.MYSHEETS', 'toApproveStatus', 'STRING', 'stores last status radio selection on the toApprove tab');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.MYSHEETS', 'toEnterGroupBy', 'STRING', 'stores last group by combo selection on the toEnter tab');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.MYSHEETS', 'toEnterStatus', 'STRING', 'stores last status radio selection on the toEnter tab');

	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.ISSUE2', 'all', 'BOOLEAN', 'stores the last "all" checkbox selection that was used in a search');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.ISSUE2', 'mine', 'BOOLEAN', 'stores the last "mine" checkbox selection that was used in a search');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.ISSUE2', 'myRoles', 'BOOLEAN', 'stores the last "myRoles" checkbox selection that was used in a search');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.ISSUE2', 'myStaff', 'BOOLEAN', 'stores the last "myStaff" checkbox selection that was used in a search');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.ISSUE2', 'issueType', 'NUMBER', 'stores the last selected issue type for list filtering');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.ISSUE2', 'overdue', 'BOOLEAN', 'stores the "overdue" checkbox selection in the settings panel');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.ISSUE2', 'unresolved', 'BOOLEAN', 'stores the "unresolved" checkbox selection in the settings panel');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.ISSUE2', 'resolved', 'BOOLEAN', 'stores the "resolved" checkbox selection in the settings panel');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.ISSUE2', 'closed', 'BOOLEAN', 'stores the "closed" checkbox selection in the settings panel');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.ISSUE2', 'rejected', 'BOOLEAN', 'stores the "rejected" checkbox selection in the settings panel');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.ISSUE2', 'pageSize', 'NUMBER', 'stores the "page size" field selection in the settings panel');

	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.AUDITS', 'show', 'STRING', 'Audits portlet');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.AUDITS', 'internalAuditTypeId', 'NUMBER', 'Audits portlet');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.AUDITS', 'flowStateId', 'NUMBER', 'Audits portlet');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.AUDITS', 'myAuditsOnly', 'BOOLEAN', 'Audits portlet');

	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.REGIONDROPDOWN', 'lastRegionComboValue', 'STRING', 'stores the last region selected');

	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.DELEGATIONPERIODPICKER', 'periods', 'STRING', 'Stores delegation periods');


	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CHAIN QUESTIONNAIRE INVITATION', 'ccMe', 'BOOLEAN', 'indicates that the user normally wants to be ccd when sending a questionnaire invitation');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CHAIN QUESTIONNAIRE INVITATION', 'personalMessage', 'STRING', 'the users default personal message when sending an invitation');

	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CLIENTS.MAERSK.CARDS.SUPPLIERDATA', 'country', 'STRING', 'the default for country to use when sending a maersk invitation');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CLIENTS.MAERSK.CARDS.SUPPLIERDATA', 'buId', 'NUMBER', 'the default business unit to select when sending a maersk invitation');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CLIENTS.MAERSK.CARDS.SUPPLIERDATA', 'manyBUs', 'BOOLEAN', 'indicates that this user normally invites companies on behalf of many business units');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CLIENTS.MAERSK.CARDS.SUPPLIERDATA', 'ccMe', 'BOOLEAN', 'indicates that the user normally wants to be ccd when sending a maersk specific questionnaire invitation');

	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.INCIDENT', 'show', 'STRING', 'Incidents portlet');

	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.TEAMROOM', 'activeTab', 'STRING', 'stores the last active plugin tab');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.INITIATIVE', 'activeTab', 'STRING', 'stores the last active plugin tab');

	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.INDICATORPICKER', 'selectedIndSid', 'NUMBER', 'stores the last indicator that was selected in the picker');

	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.CHAIN.ACTIVITYSUMMARY', 'mode', 'STRING', 'whether to show overdue or upcoming activities');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.CHAIN.ACTIVITYSUMMARY', 'numberOfActivities', 'NUMBER', 'The number of activities to show');
	
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.APPROVALDASHBOARDFILTER', 'usingAdvancedFilter', 'BOOLEAN', 'Using advanced filter');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.APPROVALDASHBOARDFILTER', 'includeFinalState', 'BOOLEAN', 'Advanced filter setting - Whether to include final state dashboards');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.APPROVALDASHBOARDFILTER', 'groupedBy', 'STRING', 'What the dashboards are grouped by');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.APPROVALDASHBOARDFILTER', 'textSearch', 'STRING', 'Advanced filter setting - Text search');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.APPROVALDASHBOARDFILTER', 'startDtm', 'STRING', 'Advanced filter setting - Exclude dashboards before');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.APPROVALDASHBOARDFILTER', 'endDtm', 'STRING', 'Advanced filter setting - Exclude dashboards after');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.APPROVALDASHBOARDFILTER', 'actionState', 'NUMBER', 'Advanced filter setting - The action state selection');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.APPROVALDASHBOARDFILTER', 'workflowState', 'STRING', 'Advanced filter setting - Workflow state to filter to');

	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PROPERTY', 'activeTab', 'STRING', 'Stores the last active plugin tab');    
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.METER', 'activeTab', 'STRING', 'Stores the last active plugin tab');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.COMPLIANCE.PERMIT', 'activeTab', 'STRING', 'Stores the last active plugin tab');
END;
/

BEGIN
	INSERT INTO CSR.IMP_TAG_TYPE (IMP_TAG_TYPE_ID, DESCRIPTION, MEANS_IGNORE) VALUES (0, 'Irrelevant', 1);
	INSERT INTO CSR.IMP_TAG_TYPE (IMP_TAG_TYPE_ID, DESCRIPTION, MEANS_IGNORE) VALUES (1, 'Always ignore', 1);
	INSERT INTO CSR.IMP_TAG_TYPE (IMP_TAG_TYPE_ID, DESCRIPTION, MEANS_IGNORE) VALUES (2, 'Unit', 0);
	INSERT INTO CSR.IMP_TAG_TYPE (IMP_TAG_TYPE_ID, DESCRIPTION, MEANS_IGNORE) VALUES (3, 'Date', 0);
	INSERT INTO CSR.IMP_TAG_TYPE (IMP_TAG_TYPE_ID, DESCRIPTION, MEANS_IGNORE) VALUES (4, 'Region', 0);
	INSERT INTO CSR.IMP_TAG_TYPE (IMP_TAG_TYPE_ID, DESCRIPTION, MEANS_IGNORE) VALUES (5, 'Indicator', 0);
END;
/

BEGIN
  INSERT INTO CSR.feed_type (feed_type_id, feed_type) VALUES (1, 'Default (push via HTTPS)');
  INSERT INTO CSR.feed_type (feed_type_id, feed_type) VALUES (2, 'Interval (processed automatically at a given interval)');
  INSERT INTO CSR.feed_type (feed_type_id, feed_type, is_chain) VALUES (3, 'Supply Chain (push via HTTPS)', 1);
END;
/

begin
	insert into csr.calc_job_phase (phase, description) values (0, 'Awaiting processing');
	insert into csr.calc_job_phase (phase, description) values (1, 'Fetching data');
	insert into csr.calc_job_phase (phase, description) values (2, 'Aggregating up');
	insert into csr.calc_job_phase (phase, description) values (3, 'Aggregating down');
	insert into csr.calc_job_phase (phase, description) values (4, 'Running calculations');
	insert into csr.calc_job_phase (phase, description) values (5, 'Writing data');
	insert into csr.calc_job_phase (phase, description) values (6, 'Merging data');
	insert into csr.calc_job_phase (phase, description) values (7, 'Failed - awaiting retry');
end;
/
@@create_jobs

BEGIN
	INSERT INTO CSR.WORKSHEET_TYPE (WORKSHEET_TYPE_ID, DESCRIPTION) VALUES (100, 'Products and Services');

	INSERT INTO CSR.WORKSHEET_VALUE_MAPPER (VALUE_MAPPER_ID, CLASS_TYPE, MAPPER_NAME, MAPPER_DESCRIPTION, JS_COMPONENT_PATH, JS_COMPONENT) VALUES (100, 'Credit360.CarbonTrust.Excel.CurrencyMapper', 'Currency codes', 'Map the currency codes that were found in the worksheet to currencies that the system uses', '/csr/site/ct/components/excel/CurrencyCombo.js', 'CarbonTrust.excel.CurrencyCombo');
	INSERT INTO CSR.WORKSHEET_VALUE_MAPPER (VALUE_MAPPER_ID, CLASS_TYPE, MAPPER_NAME, MAPPER_DESCRIPTION, JS_COMPONENT_PATH, JS_COMPONENT) VALUES (101, 'Credit360.CarbonTrust.Excel.RegionMapper', 'Regions', 'Map the regions that were found in the worksheet to regions that the system uses', '/csr/site/ct/components/excel/CountryCombo.js', 'CarbonTrust.excel.CountryCombo');
	INSERT INTO CSR.WORKSHEET_VALUE_MAPPER (VALUE_MAPPER_ID, CLASS_TYPE, MAPPER_NAME, MAPPER_DESCRIPTION, JS_COMPONENT_PATH, JS_COMPONENT) VALUES (102, 'Credit360.CarbonTrust.Excel.BreakdownMapper', '{breakdownTypePlural}', 'Map the {breakdownTypePlural} that were found in the worksheet to {breakdownTypePlural} that the system uses', '/csr/site/ct/components/excel/BreakdownPicker.js', 'CarbonTrust.excel.BreakdownPicker');
	INSERT INTO CSR.WORKSHEET_VALUE_MAPPER (VALUE_MAPPER_ID, CLASS_TYPE, MAPPER_NAME, MAPPER_DESCRIPTION, JS_COMPONENT_PATH, JS_COMPONENT) VALUES (103, 'Credit360.CarbonTrust.Excel.SupplierMapper', 'Suppliers', 'Map the suppliers that were found in the worksheet to suppliers that the system uses', '/csr/site/ct/components/excel/SupplierCombo.js', 'CarbonTrust.excel.SupplierCombo');

	INSERT INTO CSR.WORKSHEET_COLUMN_TYPE (COLUMN_TYPE_ID, WORKSHEET_TYPE_ID, POSITION, VALUE_MAPPER_ID, NAME, DESCRIPTION, REQUIRED) VALUES (1000, 100,  1, NULL, 'Description', 'The description of the product or service', 1);
	INSERT INTO CSR.WORKSHEET_COLUMN_TYPE (COLUMN_TYPE_ID, WORKSHEET_TYPE_ID, POSITION, VALUE_MAPPER_ID, NAME, DESCRIPTION, REQUIRED) VALUES (1001, 100,  2, NULL, 'Purchase date', 'The date when the product or service was purchased', 1);
	INSERT INTO CSR.WORKSHEET_COLUMN_TYPE (COLUMN_TYPE_ID, WORKSHEET_TYPE_ID, POSITION, VALUE_MAPPER_ID, NAME, DESCRIPTION, REQUIRED) VALUES (1002, 100,  3, NULL, 'Spend', 'Spend amount', 1);
	INSERT INTO CSR.WORKSHEET_COLUMN_TYPE (COLUMN_TYPE_ID, WORKSHEET_TYPE_ID, POSITION, VALUE_MAPPER_ID, NAME, DESCRIPTION) VALUES (1003, 100,  4, 100, 'Currency', 'The currency of purchase of the product or service');
	INSERT INTO CSR.WORKSHEET_COLUMN_TYPE (COLUMN_TYPE_ID, WORKSHEET_TYPE_ID, POSITION, VALUE_MAPPER_ID, NAME, DESCRIPTION) VALUES (1004, 100,  4, 101, 'Country of manufacture', 'Country where the product was manufactured');
	--INSERT INTO CSR.WORKSHEET_COLUMN_TYPE (COLUMN_TYPE_ID, WORKSHEET_TYPE_ID, POSITION, VALUE_MAPPER_ID, NAME, DESCRIPTION) VALUES (1005, 100,  5, 102, '{breakdownTypeSingular}', 'The {breakdownTypeSingular} that purchased the product or service');
	--INSERT INTO CSR.WORKSHEET_COLUMN_TYPE (COLUMN_TYPE_ID, WORKSHEET_TYPE_ID, POSITION, VALUE_MAPPER_ID, NAME, DESCRIPTION) VALUES (1006, 100,  6, 102, '{breakdownTypeSingular} country', 'The country of operation of the {breakdownTypeSingular} that purchased the product or service');
	INSERT INTO CSR.WORKSHEET_COLUMN_TYPE (COLUMN_TYPE_ID, WORKSHEET_TYPE_ID, POSITION, VALUE_MAPPER_ID, NAME, DESCRIPTION) VALUES (1007, 100,  7, 103, 'Supplier Id', 'User reference id for the supplier');
	INSERT INTO CSR.WORKSHEET_COLUMN_TYPE (COLUMN_TYPE_ID, WORKSHEET_TYPE_ID, POSITION, VALUE_MAPPER_ID, NAME, DESCRIPTION) VALUES (1008, 100,  8, 103, 'Supplier name', 'The name of the supplier of the product or service');
	INSERT INTO CSR.WORKSHEET_COLUMN_TYPE (COLUMN_TYPE_ID, WORKSHEET_TYPE_ID, POSITION, VALUE_MAPPER_ID, NAME, DESCRIPTION) VALUES (1009, 100,  9, NULL, 'Supplier contact name', 'The name of the contact for the supplier');
	INSERT INTO CSR.WORKSHEET_COLUMN_TYPE (COLUMN_TYPE_ID, WORKSHEET_TYPE_ID, POSITION, VALUE_MAPPER_ID, NAME, DESCRIPTION) VALUES (1010, 100, 10, NULL, 'Supplier contact email', 'The email address of the supplier contact');


	INSERT INTO CSR.WORKSHEET_TYPE (WORKSHEET_TYPE_ID, DESCRIPTION) VALUES (101, 'Business Travel');

	INSERT INTO CSR.WORKSHEET_VALUE_MAPPER (VALUE_MAPPER_ID, CLASS_TYPE, MAPPER_NAME, MAPPER_DESCRIPTION, JS_COMPONENT_PATH, JS_COMPONENT) VALUES (110, 'Credit360.CarbonTrust.Excel.DistanceMapper', 'Distance unit', 'Map the distance unit of measure found in the worksheet to types that the system uses', '/csr/site/ct/components/excel/DistanceUnitCombo.js', 'CarbonTrust.excel.DistanceUnitCombo');

	INSERT INTO CSR.WORKSHEET_COLUMN_TYPE (COLUMN_TYPE_ID, WORKSHEET_TYPE_ID, POSITION, VALUE_MAPPER_ID, NAME, DESCRIPTION, REQUIRED) VALUES (1100, 101,  1, NULL, 'Description', 'The description of the journey', 1);
	INSERT INTO CSR.WORKSHEET_COLUMN_TYPE (COLUMN_TYPE_ID, WORKSHEET_TYPE_ID, POSITION, VALUE_MAPPER_ID, NAME, DESCRIPTION) VALUES (1101, 101,  2, NULL, 'Travel date', 'The date that the journey took place');
	INSERT INTO CSR.WORKSHEET_COLUMN_TYPE (COLUMN_TYPE_ID, WORKSHEET_TYPE_ID, POSITION, VALUE_MAPPER_ID, NAME, DESCRIPTION) VALUES (1102, 101,  3, NULL, 'Transaction date', 'The date that the expense was recorded');
	INSERT INTO CSR.WORKSHEET_COLUMN_TYPE (COLUMN_TYPE_ID, WORKSHEET_TYPE_ID, POSITION, VALUE_MAPPER_ID, NAME, DESCRIPTION) VALUES (1103, 101,  4, NULL, 'Distance travelled', 'The distance that was travelled during the journey');
	INSERT INTO CSR.WORKSHEET_COLUMN_TYPE (COLUMN_TYPE_ID, WORKSHEET_TYPE_ID, POSITION, VALUE_MAPPER_ID, NAME, DESCRIPTION) VALUES (1104, 101,  5, 110, 'Distance unit', 'The unit of measure for the distance that was travelled during the journey');
	INSERT INTO CSR.WORKSHEET_COLUMN_TYPE (COLUMN_TYPE_ID, WORKSHEET_TYPE_ID, POSITION, VALUE_MAPPER_ID, NAME, DESCRIPTION) VALUES (1105, 101,  6, NULL, 'Time travelled', 'The time taken in minutes complete the journey. For trips by train or air, this should be the scheduled time.');
	INSERT INTO CSR.WORKSHEET_COLUMN_TYPE (COLUMN_TYPE_ID, WORKSHEET_TYPE_ID, POSITION, VALUE_MAPPER_ID, NAME, DESCRIPTION) VALUES (1106, 101,  7, NULL, 'Spend', 'The amount spent on the journey');
	INSERT INTO CSR.WORKSHEET_COLUMN_TYPE (COLUMN_TYPE_ID, WORKSHEET_TYPE_ID, POSITION, VALUE_MAPPER_ID, NAME, DESCRIPTION) VALUES (1107, 101,  8, 100, 'Currency', 'The currency of spend for the journey');
END;
/

BEGIN
	INSERT INTO CHAIN.CARD(CARD_ID, DESCRIPTION, CLASS_TYPE, JS_CLASS_TYPE, JS_INCLUDE) VALUES (CHAIN.CARD_ID_SEQ.NEXTVAL, 'Pick a sheet of an uploaded excel file. Provides cache uploader if no sheet is provided.', 'Credit360.Excel.Cards.ExcelUpload', 'Credit360.Excel.Cards.SheetPicker', '/csr/site/excel/cards/sheetPicker.js');
	INSERT INTO CHAIN.CARD(CARD_ID, DESCRIPTION, CLASS_TYPE, JS_CLASS_TYPE, JS_INCLUDE) VALUES (CHAIN.CARD_ID_SEQ.NEXTVAL, 'Pick the sheet header row and allows column tagging.', 'Credit360.Excel.Cards.ExcelUpload', 'Credit360.Excel.Cards.ColumnTagger', '/csr/site/excel/cards/columnTagger.js');
	INSERT INTO CHAIN.CARD(CARD_ID, DESCRIPTION, CLASS_TYPE, JS_CLASS_TYPE, JS_INCLUDE) VALUES (CHAIN.CARD_ID_SEQ.NEXTVAL, 'Maps well known columns types (value_mappers) to known types.', 'Credit360.Excel.Cards.ExcelUpload', 'Credit360.Excel.Cards.ValueMapper', '/csr/site/excel/cards/valueMapper.js');
	INSERT INTO CHAIN.CARD(CARD_ID, DESCRIPTION, CLASS_TYPE, JS_CLASS_TYPE, JS_INCLUDE) VALUES (CHAIN.CARD_ID_SEQ.NEXTVAL, 'Displays the results of the test run before the user saves.', 'Credit360.Excel.Cards.ExcelUpload', 'Credit360.Excel.Cards.TestResults', '/csr/site/excel/cards/testResults.js');
END;
/

BEGIN
	INSERT INTO CSR.USER_DIRECTORY_TYPE (USER_DIRECTORY_TYPE_ID, USER_DIRECTORY_CLASS) VALUES (1, 'Credit360.UserDirectory.CsrUserDirectory');
END;
/

begin
	insert into csr.batch_job_type (batch_job_type_id, description, in_order, plugin_name, timeout_mins)
	values (1, 'Delegation plan synchronisation', 1, 'delegation-plan', 120);
	insert into csr.batch_job_type (batch_job_type_id, description, plugin_name, timeout_mins)
	values (2, 'Excel model run', 'excel-model-run', 120);
	INSERT INTO CSR.batch_job_type (batch_job_type_id, description, plugin_name, timeout_mins)
	VALUES (3, 'Auto approve sheet', 'auto-approve-run', 120);
	insert into csr.batch_job_type (batch_job_type_id, description, plugin_name, timeout_mins)
	values (6, 'Structure Import', 'structure-import', 120);
	insert into csr.batch_job_type (batch_job_type_id, description, plugin_name, timeout_mins)
	values (7, 'CMS Import', 'cms-import', 120);
	insert into csr.batch_job_type (batch_job_type_id, description, plugin_name, file_data_sp, timeout_mins)
	values (8, 'Templated Report', 'templated-report', 'csr.templated_report_pkg.GetBatchJobReportData', 120);
	insert into csr.batch_job_type (batch_job_type_id, description, plugin_name, timeout_mins)
	values (9, 'Energy Star outstanding requests', 'energy-star-outstanding-req', 120);
	insert into csr.batch_job_type (batch_job_type_id, description, plugin_name, file_data_sp, timeout_mins)
	values (10, 'Meter extract', 'meter-extract', 'csr.utility_report_pkg.GetBatchJobReportData', 360);
	insert into csr.batch_job_type (batch_job_type_id, description, plugin_name, timeout_mins)
	values (11, 'Supply chain invitations', 'chain-invitations', 120);
	insert into csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	values (13, 'Automated import', NULL, 'automated-import', 1, NULL, 360);
	INSERT INTO CSR.BATCH_JOB_TYPE (BATCH_JOB_TYPE_ID, DESCRIPTION, PLUGIN_NAME, in_order, timeout_mins)
	VALUES (14, 'Delegation completeness calculation', 'delegation-completeness', 0, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (15, 'Approval dashboard', null, 'approval-dashboard', 0, null, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (16, 'Automated export', NULL, 'automated-export', 1, NULL , 240);
	-- 17 is CASA import, CreditAgricole specific
	-- 18 has been deleted. Was 'Sheet completeness calculation'
	insert into csr.batch_job_type (batch_job_type_id, description, sp, in_order, timeout_mins)
	values (19, 'Meter patch', 'csr.meter_patch_pkg.ProcessBatchJob', 0, 360);
	-- 20 is Hyatt Forecasting, Hyatt specific
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, in_order, notify_address, max_retries, timeout_mins)
	VALUES (21, 'Batch Property Geocode', 'batch-prop-geocode', 1, 'support@credit360.com', 3, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, in_order, timeout_mins)
	VALUES (22, 'R Reports', 'r-reports', 1, 120);

	insert into csr.batch_job_type (batch_job_type_id, description, sp, in_order, timeout_mins)
	values (23, 'Meter recompute', 'csr.meter_pkg.ProcessRecomputeBatchJob', 0, 360);
	insert into csr.batch_job_type (batch_job_type_id, description, sp, in_order, timeout_mins)
	values (24, 'Meter type change', 'csr.meter_pkg.ProcessMeterTypeChangeBatchJob', 0, 360);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (25, 'Like for like region recalc', NULL, 'like-for-like', 1, NULL, 120);
	/* BSCI now obsolete
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, in_order, notify_address, max_retries, timeout_mins)
	VALUES (26, 'BSCI audit import', 'chain-bsci-audit', 1, 'support@credit360.com', 3, 360);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, in_order, notify_address, max_retries, timeout_mins)
	VALUES (28, 'BSCI single import', 'chain-bsci-audit-single', 1, 'support@credit360.com', 3, 120);
	*/
		
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (30, 'Full user export', null, 'batch-exporter', 0, null, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (31, 'Filtered user export', null, 'batch-exporter', 0, null, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (32, 'Region list export', null, 'batch-exporter', 0, null, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (33, 'Indicator list export', null, 'batch-exporter', 0, null, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (34, 'Data export', null, 'batch-exporter', 0, null, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (35, 'Region role membership export', null, 'batch-exporter', 0, null, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (36, 'Region and meter export', null, 'batch-exporter', 0, null, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (37, 'Measure list export', null, 'batch-exporter', 0, null, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (38, 'Emission profile export', null, 'batch-exporter', 0, null, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (39, 'Factor set export', null, 'batch-exporter', 0, null, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (40, 'Indicator translations', null, 'batch-exporter', 0, null, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (41, 'Region translations', null, 'batch-exporter', 0, null, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (42, 'CMS quick chart exporter', null, 'batch-exporter', 1, null, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (43, 'CMS exporter', null, 'batch-exporter', 1, null, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (44, 'Forecasting Slot export', null, 'batch-exporter', 0, null, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (45, 'Delegation translations', null, 'batch-exporter', 0, null, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (46, 'Filter list export', null, 'batch-exporter', 1, null, 120);
	
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (47, 'Indicator translations import', null, 'batch-importer', 0, null, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (48, 'Region translations import', null, 'batch-importer', 0, null, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (49, 'Delegation translations import', null, 'batch-importer', 0, null, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (50, 'Meter readings import', null, 'batch-importer', 0, null, 360);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (51, 'Forecasting Slot import', null, 'batch-importer', 0, null, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (52, 'Factor set import', null, 'batch-importer', 0, null, 120);

	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, in_order, timeout_mins)
	VALUES (53, 'Raw meter data import revert', 'csr.meter_monitor_pkg.ProcessRawDataImportRevert', 0, 360);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, timeout_mins)
	VALUES (54, 'Eat RAM', 'eat-ram', 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (55, 'Meter and meter data matching', null, 'meter-match', 0, null, 360);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (56, 'Meter raw data import', null, 'meter-raw-data-import', 1, null, 360);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (57, 'Meter recompute buckets', 'csr.meter_monitor_pkg.ProcessRecomputeBucketsJob', null, 0, null, 360);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, timeout_mins)
	VALUES (58, 'Dedupe manual merge', 'chain.company_dedupe_pkg.ProcessUserActions', 120);
	INSERT INTO csr.batch_job_type(batch_job_type_id, description, plugin_name, timeout_mins)
	VALUES (59, 'Product Type export', 'batch-exporter,', 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (60, 'Dedupe batch job', null, 'process-dedupe-records', 0, null, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp)
	VALUES (61, 'Dedupe pending companies batch job', null, 'process-pending-company-records', 0, null);

	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (62, 'Product type translations export', null, 'batch-exporter', 0, null, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (63, 'Product type translations import', null, 'batch-importer', 0, null, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (64, 'Product description translation export', null, 'batch-exporter', 0, null, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (65, 'Product description translation import', null, 'batch-importer', 0, null, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, notify_address, max_retries, priority, timeout_mins) 
	VALUES (66, 'Permit module types import', 'batch-importer', 'support@credit360.com', 3, 1, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, notify_address, max_retries, priority, timeout_mins) 
	VALUES (67, 'Permits import', 'batch-importer', 'support@credit360.com', 3, 1, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, notify_address, max_retries, priority, timeout_mins) 
	VALUES (68, 'Conditions import', 'batch-importer', 'support@credit360.com', 3, 1, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, notify_address, max_retries, priority, timeout_mins) 
	VALUES (69, 'Category translation import', 'batch-importer', 'support@credit360.com', 3, 1, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, notify_address, max_retries, priority, timeout_mins) 
	VALUES (70, 'Tag translation import', 'batch-importer', 'support@credit360.com', 3, 1, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, notify_address, max_retries, priority, timeout_mins) 
	VALUES (71, 'Category translation export', 'batch-exporter', 'support@credit360.com', 3, 1, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, notify_address, max_retries, priority, timeout_mins) 
	VALUES (72, 'Tag translation export', 'batch-exporter', 'support@credit360.com', 3, 1, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, notify_address, max_retries, priority, timeout_mins) 
	VALUES (73, 'Tag explanation translation import', 'batch-importer', 'support@credit360.com', 3, 1, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, notify_address, max_retries, priority, timeout_mins) 
	VALUES (74, 'Tag explanation translation export', 'batch-exporter', 'support@credit360.com', 3, 1, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (75, 'Region mappings import', null, 'batch-importer', 0, null, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (76, 'Indicator mappings import', null, 'batch-importer', 0, null, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (77, 'Measure mappings import', null, 'batch-importer', 0, null, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (78, 'Region mappings export', null, 'batch-exporter', 0, null, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (79, 'Indicator mappings export', null, 'batch-exporter', 0, null, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (80, 'Measure mappings export', null, 'batch-exporter', 0, null, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, in_order, notify_address, max_retries, timeout_mins)
	VALUES (81, 'Batch Company Geocode', 'chain-company-geocode', 1, 'support@credit360.com', 3, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, in_order, notify_address, max_retries, timeout_mins)
	VALUES (82, 'Compliance item import', 'batch-importer', 0, 'support@credit360.com', 3, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (83, 'Indicator validation rules export', null, 'batch-exporter', 0, null, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (84, 'Secondary Region Tree Refresh', null, 'secondary-region-tree-refresh', 0, null, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (85, 'OSHA Export', null, 'batch-exporter', 0, null, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description,  plugin_name, in_order, notify_address, max_retries,   priority, timeout_mins)
	VALUES (86, 'OSHA Zipped Export', 'batch-exporter', 0, 'support@credit360.com', 3, 1, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description,  plugin_name, in_order, notify_address, max_retries, priority, timeout_mins)
	VALUES (87, 'Indicator selections groups translation export', 'batch-exporter', 0, 'support@credit360.com', 3, 1, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (88, 'Indicator selection groups translations import', null, 'batch-importer', 0, null, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, in_order, notify_address, max_retries, timeout_mins)
	VALUES (89, 'Compliance item variant import', 'batch-importer', 0, 'support@credit360.com', 3, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, in_order, notify_address, max_retries, timeout_mins)
	VALUES (90, 'Compliance item export', 'batch-exporter', 0, 'support@credit360.com', 3, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, in_order, notify_address, max_retries, timeout_mins)
	VALUES (91, 'Compliance item variant export', 'batch-exporter', 0, 'support@credit360.com', 3, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, in_order, notify_address, max_retries, timeout_mins)
	VALUES (92, 'Delegation Plan Status export', 'batch-exporter', 0, 'support@credit360.com', 3, 360);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp)
	VALUES (93, 'Data bucket aggregate ind group processor', NULL, 'data-bucket-agg-ind-processor', 1, NULL);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, in_order, notify_address, max_retries, timeout_mins)
	VALUES (94, 'Alert bounce export', 'batch-exporter', 0, 'support@credit360.com', 3, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, in_order, notify_address, max_retries, timeout_mins)
	VALUES (95, 'Emission Profile import', 'batch-importer', 0, 'support@credit360.com', 3, 120);
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, in_order, timeout_mins)
	VALUES (96, 'Anonymise users', 'csr.csr_user_pkg.ProcessAnonymiseUsersBatchJob', 0, 120);
END;
/


BEGIN
	INSERT INTO CSR.LOGON_TYPE (LOGON_TYPE_ID, LABEL) VALUES (0, 'Unspecified');
	INSERT INTO CSR.LOGON_TYPE (LOGON_TYPE_ID, LABEL) VALUES (1, 'Password');
	INSERT INTO CSR.LOGON_TYPE (LOGON_TYPE_ID, LABEL) VALUES (2, 'Authenticated');
	INSERT INTO CSR.LOGON_TYPE (LOGON_TYPE_ID, LABEL) VALUES (3, 'Certificate');
	INSERT INTO CSR.LOGON_TYPE (LOGON_TYPE_ID, LABEL) VALUES (4, 'Logoff'); -- to match security_pkg.LOGON_TYPE_LOGOFF
	INSERT INTO CSR.LOGON_TYPE (LOGON_TYPE_ID, LABEL) VALUES (5, 'Batch');
	INSERT INTO CSR.LOGON_TYPE (LOGON_TYPE_ID, LABEL) VALUES (100, 'SSO');  -- start at 100 for security_pkg headroom
	INSERT INTO CSR.LOGON_TYPE (LOGON_TYPE_ID, LABEL) VALUES (101, 'Super User');
END;
/

BEGIN
	INSERT INTO csr.plugin_type (plugin_type_id, description) VALUES (1, 'Property tabs');
	INSERT INTO csr.plugin_type (plugin_type_id, description) VALUES (2, 'Fund form');
	INSERT INTO csr.plugin_type (plugin_type_id, description) VALUES (3, 'Metric dashboards');
	INSERT INTO csr.plugin_type (plugin_type_id, description) VALUES (4, 'User Profile panels');
	INSERT INTO csr.plugin_type (plugin_type_id, description) VALUES (5, 'Teamroom tab');
	INSERT INTO csr.plugin_type (plugin_type_id, description) VALUES (6, 'Teamroom edit page');
	INSERT INTO csr.plugin_type (plugin_type_id, description) VALUES (7, 'Teamroom main tab');
	INSERT INTO csr.plugin_type (plugin_type_id, description) VALUES (8, 'Initiative tab');
	INSERT INTO csr.plugin_type (plugin_type_id, description) VALUES (9, 'Initiative main tab');
	INSERT INTO csr.plugin_type (plugin_type_id, description) VALUES (10, 'Chain Company Tab');
	INSERT INTO csr.plugin_type (plugin_type_id, description) VALUES (11, 'Chain Company Header');
	INSERT INTO csr.plugin_type (plugin_type_id, description) VALUES (12, 'Calendar');
	INSERT INTO csr.plugin_type (plugin_type_id, description) VALUES (13, 'Audit tab');
	INSERT INTO csr.plugin_type (plugin_type_id, description) VALUES (14, 'Audit header');
	INSERT INTO csr.plugin_type (plugin_type_id, description) VALUES (15, 'R Report');
	INSERT INTO csr.plugin_type (plugin_type_id, description) VALUES (16, 'Meter tab');
	INSERT INTO csr.plugin_type (plugin_type_id, description) VALUES (17, 'Emission factor tab');
	INSERT INTO csr.plugin_type (plugin_type_id, description) VALUES (18, 'Chain Product Header');
	INSERT INTO csr.plugin_type (plugin_type_id, description) VALUES (19, 'Chain Product Tab');
	INSERT INTO csr.plugin_type (plugin_type_id, description) VALUES (20, 'Chain Product Supplier Tab');
	INSERT INTO csr.plugin_type (plugin_type_id, description) VALUES (21, 'Permit tab');
	INSERT INTO csr.plugin_type (plugin_type_id, description) VALUES (22, 'Permit tab header');
END;
/

-- ISO4217 currencies
BEGIN
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('AED', 'UAE Dirham');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('AFN', 'Afghani');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('ALL', 'Lek');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('AMD', 'Armenian Dram');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('ANG', 'Netherlands Antillean Guilder');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('AOA', 'Kwanza');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('ARS', 'Argentine Peso');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('AUD', 'Australian Dollar');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('AWG', 'Aruban Florin');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('AZN', 'Azerbaijanian Manat');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('BAM', 'Convertible Mark');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('BBD', 'Barbados Dollar');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('BDT', 'Taka');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('BGN', 'Bulgarian Lev');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('BHD', 'Bahraini Dinar');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('BIF', 'Burundi Franc');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('BMD', 'Bermudian Dollar');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('BND', 'Brunei Dollar');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('BOB', 'Boliviano');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('BOV', 'Mvdol');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('BRL', 'Brazilian Real');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('BSD', 'Bahamian Dollar');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('BTN', 'Ngultrum');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('BWP', 'Pula');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('BYR', 'Belarussian Ruble');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('BZD', 'Belize Dollar');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('CAD', 'Canadian Dollar');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('CDF', 'Congolese Franc');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('CHE', 'WIR Euro');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('CHF', 'Swiss Franc');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('CHW', 'WIR Franc');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('CLF', 'Unidades de fomento');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('CLP', 'Chilean Peso');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('CNY', 'Yuan Renminbi');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('COP', 'Colombian Peso');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('COU', 'Unidad de Valor Real');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('CRC', 'Costa Rican Colon');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('CUP', 'Cuban Peso');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('CVE', 'Cape Verde Escudo');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('CZK', 'Czech Koruna');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('DJF', 'Djibouti Franc');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('DKK', 'Danish Krone');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('DOP', 'Dominican Peso');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('DZD', 'Algerian Dinar');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('EGP', 'Egyptian Pound');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('ERN', 'Nakfa');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('ETB', 'Ethiopian Birr');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('EUR', 'Euro');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('FJD', 'Fiji Dollar');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('FKP', 'Falkland Islands Pound');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('GBP', 'Pound Sterling');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('GEL', 'Lari');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('GHS', 'Ghana Cedi');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('GIP', 'Gibraltar Pound');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('GMD', 'Dalasi');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('GNF', 'Guinea Franc');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('GTQ', 'Quetzal');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('GYD', 'Guyana Dollar');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('HKD', 'Hong Kong Dollar');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('HNL', 'Lempira');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('HRK', 'Croatian Kuna');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('HTG', 'Gourde');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('HUF', 'Forint');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('IDR', 'Rupiah');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('ILS', 'New Israeli Sheqel');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('INR', 'Indian Rupee');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('IQD', 'Iraqi Dinar');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('IRR', 'Iranian Rial');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('ISK', 'Iceland Krona');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('JMD', 'Jamaican Dollar');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('JOD', 'Jordanian Dinar');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('JPY', 'Yen');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('KES', 'Kenyan Shilling');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('KGS', 'Som');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('KHR', 'Riel');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('KMF', 'Comoro Franc');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('KPW', 'North Korean Won');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('KRW', 'Won');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('KWD', 'Kuwaiti Dinar');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('KYD', 'Cayman Islands Dollar');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('KZT', 'Tenge');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('LAK', 'Kip');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('LBP', 'Lebanese Pound');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('LKR', 'Sri Lanka Rupee');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('LRD', 'Liberian Dollar');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('LSL', 'Loti');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('LTL', 'Lithuanian Litas');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('LVL', 'Latvian Lats');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('LYD', 'Libyan Dinar');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('MAD', 'Moroccan Dirham');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('MDL', 'Moldovan Leu');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('MGA', 'Malagasy Ariary');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('MKD', 'Denar');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('MMK', 'Kyat');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('MNT', 'Tugrik');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('MOP', 'Pataca');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('MRO', 'Ouguiya');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('MUR', 'Mauritius Rupee');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('MVR', 'Rufiyaa');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('MWK', 'Kwacha');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('MXN', 'Mexican Peso');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('MYR', 'Malaysian Ringgit');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('MZN', 'Mozambique Metical');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('NAD', 'Namibia Dollar');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('NGN', 'Naira');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('NIO', 'Cordoba Oro');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('NOK', 'Norwegian Krone');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('NPR', 'Nepalese Rupee');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('NZD', 'New Zealand Dollar');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('OMR', 'Rial Omani');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('PAB', 'Balboa');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('PEN', 'Nuevo Sol');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('PGK', 'Kina');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('PHP', 'Philippine Peso');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('PKR', 'Pakistan Rupee');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('PLN', 'Zloty');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('PYG', 'Guarani');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('QAR', 'Qatari Rial');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('RON', 'New Romanian Leu');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('RSD', 'Serbian Dinar');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('RUB', 'Russian Ruble');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('RWF', 'Rwanda Franc');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('SAR', 'Saudi Riyal');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('SBD', 'Solomon Islands Dollar');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('SCR', 'Seychelles Rupee');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('SDG', 'Sudanese Pound');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('SEK', 'Swedish Krona');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('SGD', 'Singapore Dollar');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('SHP', 'Saint Helena Pound');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('SLL', 'Leone');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('SOS', 'Somali Shilling');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('SRD', 'Surinam Dollar');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('SSP', 'South Sudanese Pound');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('STD', 'Dobra');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('SVC', 'El Salvador Colon');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('SYP', 'Syrian Pound');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('SZL', 'Lilangeni');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('THB', 'Baht');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('TJS', 'Somoni');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('TMT', 'Turkmenistan New Manat');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('TND', 'Tunisian Dinar');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('TOP', 'Pa''anga');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('TRY', 'Turkish Lira');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('TTD', 'Trinidad and Tobago Dollar');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('TWD', 'New Taiwan Dollar');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('TZS', 'Tanzanian Shilling');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('UAH', 'Hryvnia');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('UGX', 'Uganda Shilling');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('USD', 'US Dollar');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('UYU', 'Peso Uruguayo');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('UZS', 'Uzbekistan Sum');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('VEF', 'Bolivar');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('VND', 'Dong');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('VUV', 'Vatu');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('WST', 'Tala');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('XCD', 'East Caribbean Dollar');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('XSU', 'Sucre');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('YER', 'Yemeni Rial');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('ZAR', 'Rand');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('ZMW', 'Zambian Kwacha');
INSERT INTO CSR.STD_CURRENCY (CURRENCY_CODE, LABEL) VALUES ('ZWL', 'Zimbabwe Dollar');
END;
/

BEGIN
INSERT INTO CSR.USER_FEED_ACTION (USER_FEED_ACTION_ID, LABEL, ACTION_URL, ACTION_TEXT, ACTION_IMG_URL)
	VALUES (1, 'Activity Post', '/csr/site/activity/post.acds?activityid={targetActivityId}', '{actingUserFullName} posted an update on the {targetActivity} activity','/csr/site/activity/activityImage.ashx?id={targetParam1}');
INSERT INTO CSR.USER_FEED_ACTION (USER_FEED_ACTION_ID, LABEL, ACTION_URL, ACTION_TEXT, ACTION_IMG_URL)
	VALUES (2, 'Activity Like', '/csr/site/activity/activity.acds?id={targetActivityId}', '{actingUserFullName} liked the {targetActivity} activity','/csr/site/activity/activityImage.ashx?id={targetActivityId}');
INSERT INTO CSR.USER_FEED_ACTION (USER_FEED_ACTION_ID, LABEL, ACTION_URL, ACTION_TEXT, ACTION_IMG_URL)
	VALUES (3, 'Activity Follow', '/csr/site/activity/activity.acds?id={targetActivityId}', '{actingUserFullName} followed the {targetActivity} activity','/csr/site/activity/activityImage.ashx?id={targetActivityId}');

-- added document to teamroom
-- deleted document from teamroom
-- added user to teamroom
-- removed user from teamroom
-- added event to teamroom calendar
-- modified event on teamroom calendar
-- delete event on teamroom calendar
-- added action to teamroom
END;
/

BEGIN
INSERT INTO CSR.INITIATIVE_SAVING_TYPE (SAVING_TYPE_ID, lookup_key, label, is_during, is_running) VALUES(1, 'temporary', 'Temporary saving', 1, 0);
INSERT INTO CSR.INITIATIVE_SAVING_TYPE (SAVING_TYPE_ID, lookup_key, label, is_during, is_running) VALUES(2, 'ongoing', 'Ongoing saving', 0, 1);
END;
/

-- general filter conditions for quick survey
BEGIN
INSERT INTO CSR.QS_FILTER_COND_GEN_TYPE (QS_FILTER_COND_GEN_TYPE_ID, CONDITION_CLASS, QUESTION_LABEL) VALUES (1, 'generalregionpicker', 'Region');
INSERT INTO CSR.QS_FILTER_COND_GEN_TYPE (QS_FILTER_COND_GEN_TYPE_ID, CONDITION_CLASS, QUESTION_LABEL) VALUES (2, 'generalsubmissiondate', 'Submission date');
INSERT INTO CSR.QS_FILTER_COND_GEN_TYPE (QS_FILTER_COND_GEN_TYPE_ID, CONDITION_CLASS, QUESTION_LABEL) VALUES (3, 'generalsubmissionuser', 'Submitted by');
INSERT INTO CSR.QS_FILTER_COND_GEN_TYPE (QS_FILTER_COND_GEN_TYPE_ID, CONDITION_CLASS, QUESTION_LABEL) VALUES (4, 'generalcontainscomments', 'Contains comments');
INSERT INTO CSR.QS_FILTER_COND_GEN_TYPE (QS_FILTER_COND_GEN_TYPE_ID, CONDITION_CLASS, QUESTION_LABEL) VALUES (5, 'generalscore', 'Score');
INSERT INTO CSR.QS_FILTER_COND_GEN_TYPE (QS_FILTER_COND_GEN_TYPE_ID, CONDITION_CLASS, QUESTION_LABEL) VALUES (6, 'generalcontainsunansweredquestions', 'Contains unanswered questions');
END;
/


begin
INSERT INTO CSR.REGION_SELECTION_TYPE (REGION_SELECTION_TYPE_ID, LABEL) VALUES (0, 'properties');
INSERT INTO CSR.REGION_SELECTION_TYPE (REGION_SELECTION_TYPE_ID, LABEL) VALUES (1, 'meters');
INSERT INTO CSR.REGION_SELECTION_TYPE (REGION_SELECTION_TYPE_ID, LABEL) VALUES (2, 'leaf nodes');
INSERT INTO CSR.REGION_SELECTION_TYPE (REGION_SELECTION_TYPE_ID, LABEL) VALUES (3, 'children');
INSERT INTO CSR.REGION_SELECTION_TYPE (REGION_SELECTION_TYPE_ID, LABEL) VALUES (4, 'countries');
INSERT INTO CSR.REGION_SELECTION_TYPE (REGION_SELECTION_TYPE_ID, LABEL) VALUES (5, 'sites tagged');
INSERT INTO CSR.REGION_SELECTION_TYPE (REGION_SELECTION_TYPE_ID, LABEL) VALUES (6, 'selected item only');
end;
/

begin
	INSERT INTO CSR.GEO_MAP_TAB_TYPE (GEO_MAP_TAB_TYPE_ID, LABEL, JS_CLASS, MAP_BUILDER_JS_CLASS, MAP_BUILDER_CS_CLASS)
	VALUES (1, 'Property details', 'Credit360.GeoMapPopupTab.Property', 'Controls.GeoMapPopupTab.Property', 'Credit360.GeoMap.MapBuilder.PropertyTabDto');

	INSERT INTO CSR.GEO_MAP_TAB_TYPE (GEO_MAP_TAB_TYPE_ID, LABEL, JS_CLASS, MAP_BUILDER_JS_CLASS, MAP_BUILDER_CS_CLASS)
	VALUES (2, 'Chart', 'Credit360.GeoMapPopupTab.Chart', 'Controls.GeoMapPopupTab.Chart', 'Credit360.GeoMap.MapBuilder.ChartTabDto');
end;
/

-- new flow alert classes
BEGIN
INSERT INTO CSR.FLOW_ALERT_CLASS (FLOW_ALERT_CLASS, LABEL, HELPER_PKG) VALUES ('cms', 'CMS', 'CMS.TAB_PKG');
INSERT INTO CSR.FLOW_ALERT_CLASS (FLOW_ALERT_CLASS, LABEL, HELPER_PKG) VALUES ('initiatives', 'Initiatives', 'CSR.INITIATIVE_ALERT_PKG');
INSERT INTO CSR.FLOW_ALERT_CLASS (FLOW_ALERT_CLASS, LABEL, HELPER_PKG) VALUES ('property', 'Property', 'CSR.PROPERTY_PKG');
INSERT INTO CSR.FLOW_ALERT_CLASS (FLOW_ALERT_CLASS, LABEL, HELPER_PKG) VALUES ('chemical', 'Chemical', 'CHEM.SUBSTANCE_PKG');
INSERT INTO CSR.FLOW_ALERT_CLASS (FLOW_ALERT_CLASS, LABEL, HELPER_PKG, ON_SAVE_HELPER_SP) VALUES ('audit', 'Audit', 'CSR.AUDIT_PKG', 'csr.flow_pkg.OnCreateAuditFlow');
INSERT INTO CSR.FLOW_ALERT_CLASS (FLOW_ALERT_CLASS, LABEL, HELPER_PKG, ON_SAVE_HELPER_SP) VALUES ('campaign', 'Campaign', 'csr.campaign_flow_helper_pkg', 'csr.flow_pkg.OnCreateCampaignFlow');
INSERT INTO CSR.FLOW_ALERT_CLASS (FLOW_ALERT_CLASS, LABEL, HELPER_PKG, ON_SAVE_HELPER_SP) VALUES ('supplier', 'Supply chain', 'CHAIN.SUPPLIER_FLOW_PKG', 'csr.flow_pkg.OnCreateSupplierFlowHelpers');
INSERT INTO CSR.FLOW_ALERT_CLASS (FLOW_ALERT_CLASS, LABEL, HELPER_PKG) VALUES ('corpreporter', 'Framework Manager', 'CSR.SECTION_PKG');
INSERT INTO CSR.FLOW_ALERT_CLASS (FLOW_ALERT_CLASS, LABEL, HELPER_PKG) VALUES ('training', 'Training', 'CSR.TRAINING_FLOW_HELPER_PKG');
INSERT INTO CSR.FLOW_ALERT_CLASS (FLOW_ALERT_CLASS, LABEL, HELPER_PKG) VALUES ('meterreading', 'Meter reading', 'CSR.METER_PKG');
INSERT INTO CSR.FLOW_ALERT_CLASS (FLOW_ALERT_CLASS, LABEL, HELPER_PKG, ON_SAVE_HELPER_SP) VALUES('approvaldashboard', 'Approval dashboard', 'CSR.APPROVAL_DASHBOARD_PKG', 'csr.flow_pkg.OnCreateAppDashFlow');
INSERT INTO CSR.FLOW_ALERT_CLASS (FLOW_ALERT_CLASS, LABEL, helper_pkg, allow_create) VALUES ('regulation', 'Regulation', 'csr.compliance_pkg', 0);
INSERT INTO CSR.FLOW_ALERT_CLASS (FLOW_ALERT_CLASS, LABEL, helper_pkg, allow_create) VALUES ('requirement', 'Requirement', 'csr.compliance_pkg', 0);
INSERT INTO csr.flow_alert_class (flow_alert_class, label, helper_pkg, allow_create) VALUES ('permit', 'Permit', 'csr.permit_pkg', 0);
INSERT INTO csr.flow_alert_class (flow_alert_class, label, helper_pkg, allow_create) VALUES ('application', 'Application', 'csr.permit_pkg', 0);
INSERT INTO csr.flow_alert_class (flow_alert_class, label, helper_pkg, allow_create) VALUES ('condition', 'Condition', 'csr.compliance_pkg', 0);
INSERT INTO csr.flow_alert_class (flow_alert_class, label, helper_pkg) VALUES ('disclosure', 'Disclosure', 'csr.flow_helper_pkg');
INSERT INTO csr.flow_alert_class (flow_alert_class, label, helper_pkg) VALUES ('disclosureassignment', 'Disclosure assignment', 'csr.flow_helper_pkg');
END;
/

-- Flow capability types
BEGIN
	-- csr.csr_data_pkg.FLOW_CAP_AUDIT
	INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES (1, 'audit', 'Audit', 0, security.security_pkg.PERMISSION_READ);

	--csr.csr_data_pkg.FLOW_CAP_AUDIT_SURVEY
	INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES (2, 'audit', 'Survey', 0, security.security_pkg.PERMISSION_READ);

	--csr.csr_data_pkg.FLOW_CAP_AUDIT_NON_COMPL
	INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES (3, 'audit', 'Findings', 0, security.security_pkg.PERMISSION_READ);

	--csr.csr_data_pkg.FLOW_CAP_AUDIT_ADD_ACTION
	INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES (4, 'audit', 'Add actions', 1, security.security_pkg.PERMISSION_WRITE);

	--csr.csr_data_pkg.FLOW_CAP_AUDIT_DL_REPORT
	INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES (5, 'audit', 'Download report', 1, security.security_pkg.PERMISSION_WRITE);

	--csr.csr_data_pkg.FLOW_CAP_AUDIT_PINBOARD
	INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES (6, 'audit', 'Pinboard', 0, security.security_pkg.PERMISSION_READ);

	--csr.csr_data_pkg.FLOW_CAP_AUDIT_AUDIT_LOG
	INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES (7, 'audit', 'View audit log', 1, security.security_pkg.PERMISSION_WRITE);

	--csr.csr_data_pkg.FLOW_CAP_AUDIT_CLOSURE
	INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES (8, 'audit', 'Closure result', 0, security.security_pkg.PERMISSION_READ);

	--csr.csr_data_pkg.FLOW_CAP_AUDIT_COPY
	INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES (9, 'audit', 'Copy audit', 1, security.security_pkg.PERMISSION_WRITE);

	--csr.csr_data_pkg.FLOW_CAP_AUDIT_DELETE
	INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES (10, 'audit', 'Delete audit', 1, 0);

	--csr.csr_data_pkg.FLOW_CAP_AUDIT_IMPORT_NC
	INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES (11, 'audit', 'Import findings', 1, 0);

	--csr.csr_data_pkg.FLOW_CAP_AUDIT_DOCUMENTS
	INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES (12, 'audit', 'Documents', 0, security.security_pkg.PERMISSION_READ);

	----csr.csr_data_pkg.FLOW_CAP_AUDIT_SCORE
	INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES (13, 'audit', 'Audit scores', 0, 0);
	--
	--csr.csr_data_pkg.FLOW_CAP_AUDIT_EXEC_SUMMARY
	INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES (14, 'audit', 'Executive summary', 0, security.security_pkg.PERMISSION_READ);

	----csr.csr_data_pkg.FLOW_CAP_AUDIT_DRAFT_ISSUES
	--INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
	--	VALUES (15, 'audit', 'Draft issues', 1, 0);
	----csr.csr_data_pkg.FLOW_CAP_AUDIT_DRAFT_ISSUES

	INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES (16, 'audit', 'View users', 1, 0);

	--csr.csr_data_pkg.FLOW_CAP_AUDIT_FINDING_TYPE
	INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES (17, 'audit', 'Finding type', 0, 3);

	--csr.csr_data_pkg.FLOW_CAP_AUDIT_CLOSE_FINDINGS
	INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES (18, 'audit', 'Close findings', 1, 2);

	--csr.csr_data_pkg.FLOW_CAP_AUDIT_CHANGE_SURVEY
	INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES (19, 'audit', 'Change survey', 1, 0);

	--csr.csr_data_pkg.FLOW_CAP_AUDIT_AUDITEE
	INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES (20, 'audit', 'Auditee', 0, security.security_pkg.PERMISSION_READ);

	--csr_data_pkg.flow_cap_corp_rep_edit_fact
	INSERT INTO csr.flow_capability (flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES (21, 'corpreporter', 'Edit indicator mapping', 1, 0);

	--csr_data_pkg.flow_cap_corp_rep_clear_fact
	INSERT INTO csr.flow_capability (flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES (22, 'corpreporter', 'Clear indicator mapping', 1, 0); 
		
	--csr_data_pkg.flow_cap_audit_nc_tags
	INSERT INTO csr.flow_capability (flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES (23, 'audit', 'Finding tags', 0, security.security_pkg.PERMISSION_READ); 

	INSERT INTO csr.flow_capability (FLOW_CAPABILITY_ID, FLOW_ALERT_CLASS, DESCRIPTION, PERM_TYPE, DEFAULT_PERMISSION_SET)
	VALUES (2001, 'approvaldashboard', 'Refresh data', 1, 0);

	INSERT INTO csr.flow_capability (FLOW_CAPABILITY_ID, FLOW_ALERT_CLASS, DESCRIPTION, PERM_TYPE, DEFAULT_PERMISSION_SET)
	VALUES (2002, 'approvaldashboard', 'Run templated report', 1, 0);

	INSERT INTO csr.flow_capability (FLOW_CAPABILITY_ID, FLOW_ALERT_CLASS, DESCRIPTION, PERM_TYPE, DEFAULT_PERMISSION_SET)
	VALUES (2003, 'approvaldashboard', 'Edit matrix notes', 1, 0);

	/* csr_data_pkg.FLOW_CAP_CAMPAIGN_RESPONSE */
	INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES(1001 , 'campaign', 'Survey response', 0 /*Specific*/, security.security_pkg.PERMISSION_READ);

	/* csr_data_pkg.FLOW_CAP_CAMPAIGN_SHARE */
	INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES(1002, 'campaign', 'Survey share response', 1, 0);

	/* csr_data_pkg.FLOW_CAP_CAMPAIGN_ACTIONS */
	INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES(1003, 'campaign', 'Survey actions', 0 /*Specific*/, security.security_pkg.PERMISSION_READ);

	/* csr_data_pkg.FLOW_CAP_DISCLOSURE_RESPONSE */
	INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES(3001, 'disclosure', 'Disclosure response', 0 /*Specific*/, security.security_pkg.PERMISSION_READ);

	INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES(3002, 'disclosure', 'Create/Cancel assignments', 1, 0);

	INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES(4001, 'disclosureassignment', 'Disclosure assignment', 0 /*Specific*/, 1 /*READ*/);

	INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES(4002, 'disclosureassignment', 'Allow assignment completion', 1, 0);
END;
/

BEGIN
	INSERT INTO csr.calc_queue (calc_queue_id, name) VALUES (0, 'CSR.SCRAG_QUEUE');
	INSERT INTO csr.calc_queue (calc_queue_id, name) VALUES (1, 'CSR.SCRAGPP_QUEUE');
	INSERT INTO csr.calc_queue (calc_queue_id, name) VALUES (2, 'CSR.SCRAG_DEBUG_QUEUE');
END;
/

-- Module enable page
BEGIN
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (1, 'Create secondary region tree', 'CreateSecondaryRegionTree', 'Creates a secondary region hierarchy with the name specified.');
	INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
	VALUES (1, 'Secondary Tree Name', 0, 'The name you want for the secondary tree');

	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (2, 'Scorecarding', 'EnableActions', 'Enables scorecarding (formerly actions)');
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (3, 'Audit', 'EnableAudit', 'Enables audits');
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (4, 'Bounce tracking', 'EnableBounceTracking', 'Enables bounce tracking');
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (5, 'Calendar', 'EnableCalendar', 'Enables the calendar');
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (6, 'Carbon Emissions', 'EnableCarbonEmissions', 'Enables carbon emissions');
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (7, 'Corp reporter', 'EnableCorpReporter', 'Enables Framework Manager');
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (8, 'Custom issues', 'EnableCustomIssues', 'Enables custom issues');
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (9, 'Deleg plan', 'EnableDelegPlan', 'Enables delegation planner');
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (10, 'Divisions', 'EnableDivisions', 'Enables divisions');
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (11, 'Document library', 'EnableDocLib', 'Enables the document library');
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (12, 'Community', 'EnableDonations', 'Enables the community module (formerly donations)');
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (14, 'Excel models', 'EnableExcelModels', 'Enables excel models');

	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (15, 'Feeds', 'EnableFeeds', 'Enables RSS feeds');
	INSERT INTO csr.module_param (module_id, param_name, pos)
	VALUES (15, 'User name', 0);
	INSERT INTO csr.module_param (module_id, param_name, pos)
	VALUES (15, 'Password', 1);

	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (16, 'Image chart', 'EnableImageChart', 'Enables image charts');
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (17, 'Issues 2', 'EnableIssues2', 'Enables version 2 of issues');
	-- 18 not used
	-- 19 not used
	INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
	VALUES (20, 'Metering - base', 'EnableMeteringBase', 'Enables the basic metering module', 1);
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (21, 'Portal', 'EnablePortal', 'Enables portal (system default)');
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (22, 'Scenarios', 'EnableScenarios', 'Enables scenarios');
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (23, 'Scheduled actions', 'EnableScheduledTasks', 'Enables scheduled actions');
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (24, 'Sheets2', 'EnableSheets2', 'Enables version 2 of sheets (system default)');
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (25, 'Surveys', 'EnableSurveys', 'Enable surveys');
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (26, 'Templated reports', 'EnableTemplatedReports', 'Enables templated reports - word2 version');
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (27, 'Workflow', 'EnableWorkflow', 'Enables workflows');
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (28, 'Change branding', 'EnableChangeBranding', 'Enables the change branding page. Should not be run against live client sites.');
	INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
	VALUES (29, 'Frameworks', 'EnableFrameworks', 'Enable Frameworks for Core (GRI '||CHR(38)||' CDP only). Setup instructions: <a href="http://emu.helpdocsonline.com/frameworks" target="_blank">http://emu.helpdocsonline.com/frameworks</a>', 0);
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (30, 'Reporting indicators', 'EnableReportingIndicators', 'Enables reporting indicators');
	-- 31 not used
	INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
	VALUES (32, 'Automated export import framework', 'EnableAutomatedExportImport', 'Enables the automated export/import framework. Pages, menus, capabilities, etc', 0);
	-- 33-35 not used
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (36, 'Measure Conversions', 'EnableMeasureConversions', 'Enable Measure Conversions');
	-- 37-40 not used
	
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (41, 'Rest API', 'EnableRestAPI', 'Enable Rest API');
	INSERT INTO csr.module_param (module_id, param_name, param_hint, pos)
	VALUES (41, 'in_enable_guest_access', 'Guest access (y/n)', 0);
	
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (42, 'Audit filtering', 'EnableAuditFiltering', 'Enable audit/finding filtering pages');
	INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
	VALUES (43, 'Approval dashboards', 'EnableApprovalDashboards', 'Enables approval dashboards. Menus, pages and portlets. Requires scenarios.', 1);
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (44, 'Filter alerts', 'EnableFilterAlerts', 'Enables alerts based on new items matching a saved filter.');
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (45, 'Delegation summary export', 'EnableDelegationSummary', 'Enables the delegation summary export (formally annual summary) on delegation sheets, and grants the capability to registered users.');

	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (46, 'Initiatives', 'EnableInitiatives', 'Enables Initiatives module');
	INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
	VALUES (46, 'Create default initiative module projects, metrics and metric groups?', 0, '(y|n default=n)');
	INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
	VALUES (46, 'Metrics End Year', 1, '(e.g. 2030)');

	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (47, 'Initiatives Audit', 'EnableInitiativesAuditTab', 'Enables Initiatives Audit Log tab for new projects');
	INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
	VALUES (48, 'Multiple dashboards', 'EnableMultipleDashboards', 'Enables the ability to create multiple dashboards. Adds a menu item to the admin menu.', 0);
	INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
	VALUES (49, 'Delegation Reports', 'EnableDelegationReports', 'Enables delegation reporting. Adds a menu item to the admin menu.', 0);
	
	INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
	VALUES (50, 'Emission Factor Start Date', 'EnableFactorStartMonth', 'Update the Emission Factor start date to match the customer reporting period start date; existing standard factor dates will be matched to this date, custom factor dates will be unaffected.', 0);
	INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
	VALUES (50, 'Enable/Disable', 0, '0=disable, 1=enable');
	
	-- module_id 51 not used.
	INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
	VALUES (52, 'Audit log reports', 'EnableAuditLogReports', 'Enables the audit log reports page in the admin menu. NOTE - not related to the audits module. This is audit LOGS.', 0);
	INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
	-- 53 was EnableAutomatedExport, this has been decommissioned
	VALUES (54, 'Multiple audit surveys', 'EnableMultipleAuditSurveys', 'Enables multiple audit surveys.  NOTE: This is not included in the standard licence for the Audits module; a separate license is required for this feature.', 1);
	INSERT INTO CSR.MODULE(module_id, module_name, enable_sp, description, license_warning)
	VALUES (55, 'Campaigns', 'EnableCampaigns', 'Enables campaigns', 1);
	INSERT INTO CSR.MODULE(module_id, module_name, enable_sp, description, license_warning)
	VALUES (56, 'Company Self Registration', 'EnableCompanySelfReg', 'Enables chain company self registration. Chain must already be enabled.', 0);
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (57, 'Delegation status reports', 'EnableDelegationStatusReports', 'Enables delegation status reports');
	INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
	VALUES (58, 'Metering - quick charts', 'EnableMeterReporting', 'Enables meter data quick charts', 1);
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (59, 'Data change requests', 'EnableDataChangeRequests', 'Enables data change requests. Also enables the alerts and sets up their templates.');

	INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
	VALUES (60, 'Metering - Urjanet', 'EnableUrjanet', 'Enables Urjanet integration pages and settings. It needs to know the SFTP folder on our server, which should be setup before enabling this. After running this, be sure to configure the Urjanet service types (via the "Property Setup" menu)', 1);
	INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
	VALUES (60, 'The path to the client''s Urjanet folder on our SFTP server (cyanoxantha)', 0, 'client_name.urjanet');
	
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (61, 'Owl Support', 'EnableOwlSupport', 'Enables Owl Support.');
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (62, 'Owl Support: Support Cases', 'EnableFogbugz', 'Enables Support Cases. Owl Support is required.');
	INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
	VALUES (63, 'Audits on users', 'EnableAuditsOnUsers', 'Enables audits on users.', 1);
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (64, 'Properties - dashboards', 'EnablePropertyDashboards', 'Enables the Property Benchmarking and Performance dashboards');

	INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
	VALUES (65, 'Properties - GRESB', 'EnableGRESB', 'Enables GRESB integration for property module. See <a href="http://emu.helpdocsonline.com/GRESB">http://emu.helpdocsonline.com/GRESB</a> for instructions.', 1);
	INSERT INTO csr.module_param (module_id, param_name, pos, param_hint, allow_blank)
	VALUES (65, 'Use sandbox GRESB environment instead of live?', 0, '(sandbox|live)', 1);
	INSERT INTO csr.module_param (module_id, param_name, pos, param_hint, allow_blank)
	VALUES (65, 'Floor Area Measure Type', 1, '(m^2|ft^2)', 1);

	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	 VALUES (66, 'Properties - Energy Star', 'EnableEnergyStar', 'Enables Energy Star integration for property module.');
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (67, 'Country risk', 'EnableChainCountryRisk', 'Enables country risk.');
	INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
	VALUES (68, 'Metering - data feeds', 'EnableMeteringFeeds', 'Enables pages to set-up meter data feeds.', 1);
	INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
	VALUES (69, 'Metering - monitoring', 'EnableMeterMonitoring', 'Enables pages for data feeds and alarms', 1);
	INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
	VALUES (70, 'Metering - utilities', 'EnableMeterUtilities', 'Enables pages for invoices, contracts and suppliers', 1);
	INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
	VALUES (71, 'Audit log reports: Dashboards', 'EnableDashboardAuditLogReports', 'Enables the audit log reports page in the admin menu and adds dashboard report. NOTE - not related to the audits module. This is audit LOGS', 0);
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (72, 'Management company secondary tree', 'EnableManagementCompanyTree', 'Enables the management company secondary tree.');
	INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
	VALUES (73, 'Like for like', 'EnableLikeforlike', 'Consult with DEV before enable this! Enables the like for like module.', 1);

	INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
	VALUES (74, 'Degree Days.Net ', 'EnableDegreeDays', 'Enables integration with degreedays.net (<a href="http://emu.helpdocsonline.com/degreedays">setup instructions</a>).', 1);
	INSERT INTO csr.module_param (module_id, param_name, param_hint, pos)
	VALUES (74, 'account_name', 'The name of the API account to use (options: test, default)', 1);

	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (76, 'Training Module', 'EnableTraining', 'Enables the training module');
	INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
	VALUES (77, 'SSO', 'EnableSSO', 'Enables SSO', 0);	
	INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
	VALUES (78, 'Enable capabilities user list page', 'EnableCapabilitiesUserListPage', 'Allow user to perform bulk actions via the new user list page.', 0);
	
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (79, 'Compliance - base', 'EnableCompliance', 'Enables the Compliance Management module. Requires Surveys and Workflow to be enabled.');
	INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
	VALUES (79, 'Create regulation workflow?', 0, '(Y/N)');
	INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
	VALUES (79, 'Create requirement workflow?', 1, '(Y/N)');
	INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
	VALUES (79, 'Create campaign and campaign workflow?', 2, '(Y/N)');

	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (80, 'Compliance - ENHESA integration', 'EnableEnhesa', 'Enables the ENHESA integration for the compliance module.');
	INSERT INTO csr.module_param (module_id, param_name, pos)
	VALUES (80, 'ENHESA client id', 0);
	INSERT INTO csr.module_param (module_id, param_name, pos)
	VALUES (80, 'ENHESA Username', 1);
	INSERT INTO csr.module_param (module_id, param_name, pos)
	VALUES (80, 'ENHESA Password', 2);

	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (81, 'Maps in Audit List', 'EnableAuditMaps', 'Enables maps in Audit List.');
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (82, 'Maps in Supplier List', 'EnableSupplierMaps', 'Enables maps in Supplier List.');
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (83, 'Incidents', 'EnableIncidents', 'Enables the incidents module');

	INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning, warning_msg)
	VALUES (84, 'Properties - base', 'EnableProperties', 'Enables the Properties module. Cannot be undone. To manage a property, add a user to Property Manager role after enabling.', 1, 'This enables parts of the supply chain system and cannot be undone.');
	INSERT INTO csr.module_param (module_id, param_name, pos)
	VALUES (84, 'Provide name of top level company if chain is not already enabled', 0);
	INSERT INTO csr.module_param (module_id, param_name, pos)
	VALUES (84, 'Enter default property type (existing properties will be assigned this type)', 1);	

	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (85, 'Emission Factors Profiling', 'EnableEmFactorsProfileTool', 'Enables the Emission Factors Profile tool');
	INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
	VALUES (85, 'Enable/Disable', 0, '0=disable, 1=enable');
	INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
	VALUES (85, 'Menu Position', 1, '-1=end, or 1 based position');

	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (86, 'Emission Factors Classic', 'EnableEmFactorsClassicTool', 'Enables/Disables the Emission Factors Classic tool');
	INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
	VALUES (86, 'Enable/Disable', 0, '0=disable, 1=enable');
	INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
	VALUES (86, 'Menu Position', 1, '-1=end, or 1 based position, ignored if disabling');

	INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
	VALUES (87, 'Document library - document types', 'EnableDocLibDocTypes', 'Enables document types in the document library.', 0);

	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (88, 'Higg', 'EnableHigg', 'Enables Higg integration');
	INSERT INTO csr.module_param (module_id, param_name, pos)
	VALUES (88, 'The FTP profile to use. If this does not already exist, this will be set up to connect to cyanoxantha', 0);
	INSERT INTO csr.module_param (module_id, param_name, pos)
	VALUES (88, 'The folder on the FTP server containing Higg responses', 1);

	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (89, 'Forecasting', 'EnableForecasting', 'Enables Forecasting');

	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (90, 'Properties - document library', 'EnablePropertyDocLib', 'Enables the property document library and document tab.');
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (91, 'Translations import (for client admins)', 'EnableTranslationsImport', 'Enables the translations import tool for client admins. Adds the capability and adds the menu for them.');
	
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (92, 'Chain Company Dedupe', 'EnableCompanyDedupePreProc', 'Enables the preprocessing job and the registers the city substituion CMS table for Chain company deduplication.');
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (93, 'Product Compliance', 'EnableProductCompliance', 'Enables the product compliance pages. !!! This module is currently in development and this script should not be used on live client sites !!!');
	
	INSERT INTO csr.module (module_id, module_name, enable_sp, post_enable_class, description)
	VALUES (94, 'Question Library', 'EnableQuestionLibrary', 'Credit360.Enable.EnableFileSharing', 'Enables the Question Library module used in conjunction with Surveys, supporting a question bank for repeatable, reusable questions across multiple surveys and reporting periods.');
	
	INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
	VALUES (95, 'Permits', 'EnablePermits', 'Enables the Permits module.', 1);

	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (97, 'API integrations', 'EnableApiIntegrations', 'Enables API integrations . See utility script page for API user creation.');

	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (98, 'HR integration', 'EnableHrIntegration', 'Enables/disables the HR integration.');
	INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
	VALUES (98, 'Enable/Disable', 0, '0=disable, 1=enable');
	
	INSERT INTO csr.module (module_id, module_name, enable_sp, post_enable_class, description)
	VALUES (99, 'API FileSharing', 'EnableFileSharingApi', 'Credit360.Enable.EnableFileSharing', 'Enables the FileSharing Api.');
	INSERT INTO csr.module_param (module_id, param_name, pos, param_hint, allow_blank)
	VALUES (99, 'ProviderHint', 0, 'empty (default FileStore), Azure, FileStore', 1);
	INSERT INTO csr.module_param (module_id, param_name, pos, param_hint, allow_blank)
	VALUES (99, 'Force switch of provider if already exists', 1, '0=no, 1=yes', 1);
	
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (100, 'Region Emission Factor cascading', 'EnableRegionEmFactorCascading', 'Enables Region Emission Factor cascading.');
	
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (101, 'Extended region filtering', 'EnableRegionFiltering', 'Enable region filtering adapters on CMS and compliance pages, to allow filtering records by fields on a region. NOTE: This is disabled by default as it can have a significant impact on the page load times, especially for sites with large numbers of tags/tag groups.');
	
	INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
	VALUES (102, 'Chain SRM activities', 'EnableChainActivities', 'Enable SRM activities. This feature is only available for supply chain sites.', 1);

	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (103, 'API Values', 'EnableValuesApi', 'Enables the Values Api.');

	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (105, 'OSHA', 'EnableOSHAModule', 'Enables the OSHA module.');

	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (106, 'Droid API', 'EnableDroidAPI', 'Enable Droid API');
	INSERT INTO csr.module_param (module_id, param_name, param_hint, pos)
	VALUES (106, 'in_enable_guest_access', 'Guest access (y/n)', 0);
	
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (107, 'Create OWL client', 'CreateOwlClient', 'Creates the site you are logged in to as an OWL client.');
	INSERT INTO csr.module_param (module_id, param_name, param_hint, pos)
	VALUES (107, 'in_admin_access', 'Admin access (Y/N)', 0);
	INSERT INTO csr.module_param (module_id, param_name, param_hint, pos)
	VALUES (107, 'in_handling_office', 'Handling office. Must exist in owl.handling_office. Cambridge, eg.', 1);
	INSERT INTO csr.module_param (module_id, param_name, param_hint, pos)
	VALUES (107, 'in_customer_name', 'The name of the customer', 2);
	INSERT INTO csr.module_param (module_id, param_name, param_hint, pos)
	VALUES (107, 'in_parenthost', 'The parent host. Usually www.credit360.com', 3);
	
	INSERT INTO csr.module (module_id, module_name, enable_sp, enable_class, description)
	VALUES (108, 'Branding', 'EnableBranding', 'Credit360.Enable.EnableBranding', 'Enable branding tool');
	
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (109, 'Formeditor', 'EnableForms', 'Enable form editor');
	
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (110, 'Data buckets', 'EnableDataBuckets', 'Enable data buckets.');

	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (111, 'Audits API', 'EnableAuditsApi', 'Enable Audits API');
	
	INSERT INTO csr.module (module_id, module_name, enable_sp, enable_class, description, license_warning)
	VALUES (112, 'Amfori Integration', 'EnableAmforiIntegration', 'Credit360.Enable.EnableAmforiIntegration', 'Enable Amfori Integration', 1);	

	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (113, 'Credential Management', 'EnableCredentialManagement', 'Enable Credential Management page.');
	INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
	VALUES (113, 'Menu Position', 1, '-1=end, or 1 based position');
	
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (116, 'Managed Packaged Content', 'EnableManagedPackagedContent', 'Enables managed packaged content.');
	INSERT INTO csr.module_param (module_id, param_name, param_hint, pos)
	VALUES (116, 'in_package_name', 'Package name', 0);
	INSERT INTO csr.module_param (module_id, param_name, param_hint, pos)
	VALUES (116, 'in_package_ref', 'Package reference', 1);

	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (117, 'Managed Content Registry UI', 'EnableManagedContentRegistryUI', 'Enables managed content registry UI.');
	INSERT INTO csr.module (module_id, module_name, enable_sp, enable_class, description, license_warning)
	VALUES (118, 'RBA Integration', 'EnableRBAIntegration', 'Credit360.Enable.EnableRBAIntegration', 'Enable RBA Integration', 1);

	INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
	VALUES (119, 'ESG Disclosures', 'EnableFrameworkDisclosures', 'Enable the new ESG Disclosures module', 1);
	
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (120, 'CMS API', 'EnableCmsApi', 'Enable CMS API');
	
	INSERT INTO CSR.MODULE(module_id, module_name, enable_sp, description)
	VALUES (121, 'Sustainability Essentials', 'EnableSustainEssentials', 'Enables some base content for Sustainability Essentials sites. Don''t recommende enabling this on existing sites! Use in CreateSite or a recently created site.');
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (122, 'Landing Pages', 'EnableLandingPages', 'Enable Landing Pages');

	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (123, 'Consent Settings', 'EnableConsentSettings', 'Enable Consent Settings page.');
	INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
	VALUES (123, 'State', 1, '0 (disable) or 1 (enable)');
	INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
	VALUES (123, 'Menu Position', 2, '-1=end, or 1 based position');
	
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
		VALUES (124, 'Scheduled Export API', 'EnableScheduledExportApi', 'Enables/Disables Scheduled Export API');
	INSERT INTO CSR.MODULE_PARAM (MODULE_ID, PARAM_NAME, POS, PARAM_HINT)
		VALUES (124, 'Enable/Disable', 1, '0=disable, 1=enable');

	--- 125 Baseline calculations

	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (126, 'Delegation status overview', 'EnableDelegStatusOverview', 'Enables the delegation status overview page.');
	
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (127, 'Measure conversions page', 'EnableMeasureConversionsPage', 'Enable the measure conversions page.');
	
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (128, 'MaxMind Geo Location', 'EnableMaxMind', 'Enables MaxMind Geo location.');
	INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
	VALUES (128, 'Enable/Disable', 0, '0=disable, 1=enable');

	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (129, 'Target Planning', 'EnableTargetPlanning', 'Under development, do not use: Enable Target Planning module.');
	INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
	VALUES (129, 'State', 1, '0 (disable) or 1 (enable)');
	INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
	VALUES (129, 'Menu Position', 2, '-1=end, or 1 based position');
	
END;
/

--Latest 2454; Csr data import
BEGIN
	INSERT INTO CSR.AUTOMATED_IMPORT_FILE_TYPE (AUTOMATED_IMPORT_FILE_TYPE_ID, LABEL)
		VALUES (0, 'dsv');
	INSERT INTO CSR.AUTOMATED_IMPORT_FILE_TYPE (AUTOMATED_IMPORT_FILE_TYPE_ID, LABEL)
		VALUES (1, 'excel');
	INSERT INTO CSR.AUTOMATED_IMPORT_FILE_TYPE (AUTOMATED_IMPORT_FILE_TYPE_ID, LABEL)
		VALUES (2, 'xml');
	INSERT INTO CSR.AUTOMATED_IMPORT_FILE_TYPE (AUTOMATED_IMPORT_FILE_TYPE_ID, LABEL)
		VALUES (3, 'ediel');
	INSERT INTO CSR.AUTOMATED_IMPORT_FILE_TYPE (AUTOMATED_IMPORT_FILE_TYPE_ID, LABEL)
		VALUES (4, 'wi5');
		
	INSERT INTO CSR.AUTOMATED_IMPORT_RESULT (AUTOMATED_IMPORT_RESULT_ID, LABEL)
		VALUES(0, 'Success');
	INSERT INTO CSR.AUTOMATED_IMPORT_RESULT (AUTOMATED_IMPORT_RESULT_ID, LABEL)
		VALUES(1, 'Partial success');
	INSERT INTO CSR.AUTOMATED_IMPORT_RESULT (AUTOMATED_IMPORT_RESULT_ID, LABEL)
		VALUES(2, 'Fail');
	INSERT INTO CSR.AUTOMATED_IMPORT_RESULT (AUTOMATED_IMPORT_RESULT_ID, LABEL)
		VALUES(3, 'Fail (unexpected error)');
	INSERT INTO CSR.AUTOMATED_IMPORT_RESULT (AUTOMATED_IMPORT_RESULT_ID, LABEL)
		VALUES(4, 'Not attempted');
	INSERT INTO CSR.AUTOMATED_IMPORT_RESULT (AUTOMATED_IMPORT_RESULT_ID, LABEL)
		VALUES(5, 'Nothing To Do');
		
	INSERT INTO csr.auto_imp_importer_plugin (plugin_id, label, importer_assembly)
		VALUES (1, 'CMS importer',   'Credit360.ExportImport.Automated.Import.Importers.CmsExcelImpImporter');
		
	INSERT INTO csr.auto_imp_importer_plugin (plugin_id, label, importer_assembly)
		 VALUES (2, 'Meter raw data importer',   'Credit360.ExportImport.Automated.Import.Importers.MeterRawDataImporter.MeterRawDataImporter');
	
	INSERT INTO csr.auto_imp_importer_plugin (plugin_id, label, importer_assembly)
		VALUES (3, 'XML Bulk Importer', 'Credit360.ExportImport.Automated.Import.Importers.XmlBulkImporter');
	
	INSERT INTO csr.auto_imp_importer_plugin (plugin_id, label, importer_assembly) 
		VALUES (4, 'Core data importer', 'Credit360.ExportImport.Automated.Import.Importers.CoreDataImporter.CoreDataImporter');
	
	INSERT INTO csr.auto_imp_importer_plugin (plugin_id, label, importer_assembly)
		VALUES (5, 'Zip extractor', 'Credit360.ExportImport.Automated.Import.Importers.ZipExtractImporter.ZipExtractImporter');
		
	INSERT INTO csr.auto_imp_importer_plugin (plugin_id, label, importer_assembly)
		VALUES (6, 'HR profile importer', 'Credit360.ExportImport.Automated.Import.Importers.UserImporter.UserImporter');

	INSERT INTO csr.auto_imp_importer_plugin (plugin_id, label, importer_assembly)
		VALUES (7, 'Compliance product importer', 'Credit360.ExportImport.Automated.Import.Importers.ProductImporter.ProductImporter');
END;
/

BEGIN
	INSERT INTO csr.auto_imp_fileread_plugin (plugin_id, label, fileread_assembly)
		 VALUES (1, 'FTP Reader', 'Credit360.ExportImport.Automated.Import.FileReaders.FtpReader');
	INSERT INTO csr.auto_imp_fileread_plugin (plugin_id, label, fileread_assembly)
		 VALUES (2, 'Database Reader', 'Credit360.ExportImport.Automated.Import.FileReaders.DBReader');
	INSERT INTO csr.auto_imp_fileread_plugin (plugin_id, label, fileread_assembly)
		 VALUES (3, 'Manual Instance Reader', 'Credit360.ExportImport.Automated.Import.FileReaders.ManualInstanceDbReader');
	INSERT INTO csr.auto_imp_fileread_plugin (plugin_id, label, fileread_assembly)
		 VALUES (4, 'FTP Folder Reader', 'Credit360.ExportImport.Automated.Import.FileReaders.FtpFolderReader');
END;
/

BEGIN
  INSERT INTO CSR.STATUS (STATUS_ID, LABEL) VALUES (1, 'Active');
  INSERT INTO CSR.STATUS (STATUS_ID, LABEL) VALUES (2, 'Inactive');
END;
/

BEGIN
  INSERT INTO CSR.DELIVERY_METHOD (DELIVERY_METHOD_ID, LABEL) VALUES (1, 'Online');
  INSERT INTO CSR.DELIVERY_METHOD (DELIVERY_METHOD_ID, LABEL) VALUES (2, 'Face to face');
END;
/

BEGIN
  INSERT INTO CSR.PROVISION (PROVISION_ID, LABEL) VALUES (1, 'Internal');
  INSERT INTO CSR.PROVISION (PROVISION_ID, LABEL) VALUES (2, 'External');
END;
/

BEGIN
	INSERT INTO CSR.TRAINING_PRIORITY (TRAINING_PRIORITY_ID, LABEL, POS) VALUES (1, 'Recommended', 2);
	INSERT INTO CSR.TRAINING_PRIORITY (TRAINING_PRIORITY_ID, LABEL, POS) VALUES (2, 'Mandatory', 1);
END;
/

-- FB52991
BEGIN
	INSERT INTO CSR.FLOW_STATE_AUDIT_IND_TYPE (FLOW_STATE_AUDIT_IND_TYPE_ID, DESCRIPTION)
		 VALUES (1, 'Audit workflow state count');

	INSERT INTO CSR.FLOW_STATE_AUDIT_IND_TYPE (FLOW_STATE_AUDIT_IND_TYPE_ID, DESCRIPTION)
		 VALUES (2, 'Audit workflow - time spent in state');
END;
/

--Latest approval dashboard reporting
BEGIN
	INSERT INTO CSR.APP_DASH_SUP_REPORT_PORTLET (PORTLET_TYPE, MAPS_TO_TAG_TYPE)
	VALUES ('Credit360.Portlets.Chart', 3);
	INSERT INTO CSR.APP_DASH_SUP_REPORT_PORTLET (PORTLET_TYPE, MAPS_TO_TAG_TYPE)
	VALUES ('Credit360.Portlets.ApprovalChart', 101);
	INSERT INTO CSR.APP_DASH_SUP_REPORT_PORTLET (PORTLET_TYPE, MAPS_TO_TAG_TYPE)
	VALUES ('Credit360.Portlets.Table', 2);
	INSERT INTO CSR.APP_DASH_SUP_REPORT_PORTLET (PORTLET_TYPE, MAPS_TO_TAG_TYPE)
	VALUES ('Credit360.Portlets.ApprovalNote', 102);
	INSERT INTO CSR.APP_DASH_SUP_REPORT_PORTLET (PORTLET_TYPE, MAPS_TO_TAG_TYPE)
	VALUES ('Credit360.Portlets.ApprovalMatrix', 103);
END;
/

-- Automated Export Import framework
BEGIN
	INSERT INTO csr.ftp_protocol (protocol_id, label) VALUES (0, 'FTP');
	INSERT INTO csr.ftp_protocol (protocol_id, label) VALUES (1, 'FTPS');
	INSERT INTO csr.ftp_protocol (protocol_id, label) VALUES (2, 'SFTP');

	INSERT INTO csr.auto_exp_file_wrtr_plugin_type(plugin_type_id, label) VALUES (1, 'FTP');
	INSERT INTO csr.auto_exp_file_wrtr_plugin_type(plugin_type_id, label) VALUES (2, 'DB');
	INSERT INTO csr.auto_exp_file_wrtr_plugin_type(plugin_type_id, label) VALUES (3, 'Manual Download');
END;
/

BEGIN
	INSERT INTO csr.auto_exp_exporter_plugin_type(plugin_type_id, label) VALUES (1, 'DataView Exporter');
	INSERT INTO csr.auto_exp_exporter_plugin_type(plugin_type_id, label) VALUES (2, 'DataView Exporter (Xml Mappable)');
	INSERT INTO csr.auto_exp_exporter_plugin_type(plugin_type_id, label) VALUES (3, 'Batched Exporter');
	INSERT INTO csr.auto_exp_exporter_plugin_type(plugin_type_id, label) VALUES (4, 'Stored Procedure Exporter');
	INSERT INTO csr.auto_exp_exporter_plugin_type(plugin_type_id, label) VALUES (5, 'Quick Chart Exporter');
END;
/

BEGIN
INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly, dsv_outputter, plugin_type_id)
VALUES (1, 'Dataview - Dsv',	'Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.DataViewExporter', 'Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.DsvOutputter', 1, 1);
INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly, dsv_outputter, plugin_type_id)
VALUES (2, 'Dataview - Excel',	'Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.DataViewExporter', 'Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.FixedExcelOutputter', 0, 1);
INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly, dsv_outputter, plugin_type_id)
VALUES (3, 'Dataview - XML',	'Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.DataViewExporter', 'Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.XmlOutputter', 0, 1);
INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly, dsv_outputter)
VALUES (4, 'Nestle - Dsv',			'Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.DataViewExporter', 'Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.NestleDsvOutputter', 1);
INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly, dsv_outputter)
VALUES (5, 'User exporter (dsv)', 'Credit360.ExportImport.Automated.Export.Exporters.Users.UserExporter', 'Credit360.ExportImport.Automated.Export.Exporters.Users.UserDsvOutputter', 1);
INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly, dsv_outputter)
VALUES (6, 'Groups and roles exporter (dsv)', 'Credit360.ExportImport.Automated.Export.Exporters.GroupsAndRoles.GroupsAndRolesExporter', 'Credit360.ExportImport.Automated.Export.Exporters.GroupsAndRoles.GroupsAndRolesDsvOutputter', 1);
INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly, dsv_outputter)
VALUES (7, 'User exporter (dsv, Deutsche Bank)', 'Credit360.ExportImport.Automated.Export.Exporters.Users.UserExporter', 'Credit360.ExportImport.Automated.Export.Exporters.Gatekeeper.DeutscheBankUsersDsvOutputter', 1);
INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly, dsv_outputter)
VALUES (8, 'Groups and roles exporter (dsv, Deutsche Bank)', 'Credit360.ExportImport.Automated.Export.Exporters.Gatekeeper.DeutscheBankEntitlementExporter', 'Credit360.ExportImport.Automated.Export.Exporters.Gatekeeper.DeutscheBankEntitlementsDsvOutputter', 0);
INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly, dsv_outputter)
VALUES (9, 'HM Step - PU Grading', 'Credit360.ExportImport.Automated.Export.Exporters.HMStep.PuGradingExporter', 'Credit360.ExportImport.Automated.Export.Exporters.HMStep.PuGradingXmlOutputter', 0);
INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly, dsv_outputter)
VALUES (10, 'HM Step - SU Grading', 'Credit360.ExportImport.Automated.Export.Exporters.HMStep.SuGradingExporter', 'Credit360.ExportImport.Automated.Export.Exporters.HMStep.SuGradingXmlOutputter', 0);
INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly, dsv_outputter)
VALUES (11, 'HM Step - Letter of Concern', 'Credit360.ExportImport.Automated.Export.Exporters.HMStep.LetterOfConcernExporter', 'Credit360.ExportImport.Automated.Export.Exporters.HMStep.LetterOfConcernXmlOutputter', 0);
INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly, dsv_outputter)
VALUES (12, 'HM Step - Sustainability Grading', 'Credit360.ExportImport.Automated.Export.Exporters.HMStep.SustainabilityGradingExporter', 'Credit360.ExportImport.Automated.Export.Exporters.HMStep.SustainabilityGradingXmlOutputter', 0);
INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly, dsv_outputter, plugin_type_id)
VALUES (13, 'Stored Procedure - Dsv', 'Credit360.ExportImport.Automated.Export.Exporters.StoredProcedure.StoredProcedureExporter', 'Credit360.ExportImport.Automated.Export.Exporters.StoredProcedure.StoredProcedureDsvOutputter', 1, 4);
INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly, dsv_outputter)
VALUES (14, 'ABInBev - Master Data (dsv)', 'Credit360.ExportImport.Automated.Export.Exporters.AbInBev.MeanScoresDataExporter', 'Credit360.ExportImport.Automated.Export.Exporters.StoredProcedure.StoredProcedureDsvOutputter', 1);
INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly, dsv_outputter)
VALUES (15, 'ABInBev - Mean Scores (dsv)', 'Credit360.ExportImport.Automated.Export.Exporters.AbInBev.MeanScoresExporter', 'Credit360.ExportImport.Automated.Export.Exporters.StoredProcedure.StoredProcedureDsvOutputter', 1);
INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly, dsv_outputter)
VALUES (16, 'Barloworld Hyperion Excel', 'Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.DataViewExporter', 'Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.BarloworldExcelOutputter', 0);
INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly, dsv_outputter)
VALUES (17, 'Barloworld Hyperion DSV', 'Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.DataViewExporter', 'Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.BarloworldDsvOutputter', 1);
INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly, dsv_outputter)
VALUES (18, 'Heineken SPM - dataview export (excel)', 'Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.DataViewExporter', 'Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.HeinekenExcelOutputter', 0);
INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly, dsv_outputter, plugin_type_id)
VALUES (19, 'Batched exporter',	'Credit360.ExportImport.Automated.Export.Exporters.Batched.AutomatedBatchedExporter', 'Credit360.ExportImport.Automated.Export.Exporters.Batched.AutomatedBatchedOutputter', 0, 3);
INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly, dsv_outputter)
VALUES (20, 'ELC - Workmans Comp export (XML)', 'Credit360.ExportImport.Automated.Export.Exporters.ELC.IncidentExporter', 'Credit360.ExportImport.Automated.Export.Exporters.ELC.IncidentZipXmlOutputter', 0);
INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly, dsv_outputter, plugin_type_id)
VALUES (21, 'Dataview - Xml Mapped Dsv',	'Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.DataViewExporter', 'Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.XmlMappableDsvOutputter', 1, 2);
INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly, dsv_outputter, plugin_type_id)
VALUES (22, 'Dataview - Xml Mapped Excel',	'Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.DataViewExporter', 'Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.XmlMappableExcelOutputter', 0, 2);
INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly, dsv_outputter, plugin_type_id)
VALUES (23, 'Quick Chart Export', 'Credit360.ExportImport.Automated.Export.Exporters.QuickChart.QuickChartExporter', 'Credit360.ExportImport.Automated.Export.Exporters.QuickChart.QuickChartOutputter', 0, 5);
INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly, dsv_outputter, plugin_type_id)
VALUES (24, 'Dataview - JSON','Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.DataViewExporter','Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.JsonOutputter', 0, 1);
INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly, dsv_outputter, plugin_type_id)
VALUES (25, 'Quick Chart Export - JSON','Credit360.ExportImport.Automated.Export.Exporters.QuickChart.QuickChartExporter','Credit360.ExportImport.Automated.Export.Exporters.QuickChart.QuickChartJsonOutputter', 0, 5);
INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly, dsv_outputter, plugin_type_id)
VALUES (26, 'Client Termination Dsv', 'Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.TerminatedClientExporter', 'Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.TerminatedClientXmlMappableDsvOutputter', 1, 1);

INSERT INTO csr.auto_exp_file_writer_plugin (plugin_id, label, assembly, plugin_type_id) VALUES (1, 'FTP', 'Credit360.ExportImport.Automated.Export.FileWrite.FtpWriter', 1);
INSERT INTO csr.auto_exp_file_writer_plugin (plugin_id, label, assembly, plugin_type_id) VALUES (5, 'Manual download', 	'Credit360.ExportImport.Automated.Export.FileWrite.ManualDownloadWriter', 3);
INSERT INTO csr.auto_exp_file_writer_plugin (plugin_id, label, assembly, plugin_type_id) VALUES (6, 'Save to DB', 'Credit360.ExportImport.Automated.Export.FileWrite.DbWriter', 2);
INSERT INTO csr.auto_exp_file_writer_plugin (plugin_id, label, assembly, plugin_type_id) VALUES (7, 'FTP (zip extraction)', 'Credit360.ExportImport.Automated.Export.FileWrite.FtpZipExtractionWriter', 1);


INSERT INTO csr.auto_exp_imp_dsv_delimiters (delimiter_id, label) VALUES (0, 'Comma');
INSERT INTO csr.auto_exp_imp_dsv_delimiters (delimiter_id, label) VALUES (1, 'Pipe');
INSERT INTO csr.auto_exp_imp_dsv_delimiters (delimiter_id, label) VALUES (2, 'Tab');
INSERT INTO csr.period_span_pattern_type (period_span_pattern_type_id, label) VALUES (0, 'Fixed');
INSERT INTO csr.period_span_pattern_type (period_span_pattern_type_id, label) VALUES (1, 'Fixed to now');
INSERT INTO csr.period_span_pattern_type (period_span_pattern_type_id, label) VALUES (2, 'Rolling to now');
INSERT INTO csr.period_span_pattern_type (period_span_pattern_type_id, label) VALUES (3, 'Offset to now');
INSERT INTO csr.period_span_pattern_type (period_span_pattern_type_id, label) VALUES (4, 'Offset to Offset');
END;
/


-- Global meter aggregator types
INSERT INTO csr.meter_aggregator(aggregator, label, aggr_proc) VALUES ('SUM', 'Sum', 'csr.meter_aggr_pkg.Sum');
INSERT INTO csr.meter_aggregator(aggregator, label, aggr_proc) VALUES ('AVERAGE', 'Average', 'csr.meter_aggr_pkg.Average');

-- Util scripts
BEGIN
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (1, 'Create future sheets for delegation', 'Creates sheets in the future for an existing delegation. Replaces CreateDelegationSheetsFuture.sql','CreateDelegationSheetsFuture', NULL);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint , pos) VALUES (1, 'Delegation sid', 'The sid of the delegation to run against', 1);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint , pos) VALUES (1, 'Max date (YYYY-MM-DD)', 'The maximum date to create sheets for', 2);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (2, 'Recalc one', 'Queues recalc jobs for the current site/app. Replaces recalcOne.sql', 'RecalcOne', NULL);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (3, 'Create IMAP folder', 'Creates an imap folder for routing client emails. See the wiki page. Replaces EnableClientImapFolder.sql','CreateImapFolder', 'W955');
INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint , pos) VALUES (3, 'Folder name', 'IMAP folder name to create (lower-case by convention, e.g. credit360)', 1);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint , pos) VALUES (3, 'Suffixes (See wiki)', '(optionally comma-separated list) of email suffixes, e.g. credit360.com,credit360.co.uk', 2);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (4, 'Toggle multi-period delegation flag', 'Toggles the multi-period override for the specified delegation and its children. See wiki for details ("Per delegation" section)', 'ToggleDelegMultiPeriodFlag','W2324');
INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint , pos) VALUES (4, 'Delegation sid', 'The sid of the delegation to run against', 1);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (5, 'Add Indicator Quality Flags', 'Adds quality flags for indicators. See the wiki page. Replaces QualityFlagsToIndSelections.sql', 'AddQualityFlags', 'W1917');

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (6, 'Set Start Month','Sets the start month for reporting. See the wiki page. Replaces setStartMonth.sql','SetStartMonth', 'W177');
INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint , pos) VALUES (6, 'Start Month', 'The number of the new start month (For Jan: 1, Feb: 2 etc)', 0);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint , pos) VALUES (6, 'Start Year', 'first year of current reporting period (four digits)', 1);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint , pos) VALUES (6, 'End Year', 'last year of current reporting period (four digits)', 2);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (7, 'Add Missing Alert','Adds the missing standard alert with the given std_alert_type_id', 'AddMissingAlert', NULL);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint , pos) VALUES (7, 'Standard alert ID', 'The ID of the standard alert to add', 0);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (8, 'Set tolerance checker data requirement', 'Sets the tolerance checker requirement in regards to merged data. See wiki for details.','SetToleranceChkrMergedDataReq','W2405');
INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint , pos) VALUES (8, 'Setting value (0 off, 1 merged, 2 submit)', 'The (side wide) setting to use.', 0);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (9, 'Enable/Disable automatic parent-child sheet status matching', 'Updates customer.status_from_parent_on_subdeleg. See wiki for details.', 'SetAutoPCSheetStatusFlag','W2570');
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE,PARAM_HIDDEN) VALUES (9,'Setting value (0 off, 1 on)','The setting to use.',0,null,0);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (10, 'Map Survey Questions to Indicators', 'Will create indicators for anything that has single input values (Radio buttons, dropdown, matrix) under the supply Chain Questionnaires folder for the supplied survey sid', 'MapIndicatorsFromSurvey','W1915');
INSERT INTO csr.util_script_param (util_script_id, param_name, param_hint , pos) VALUES (10, 'Survey SID', 'Survey sid to map question from', 1);
INSERT INTO csr.util_script_param (util_script_id, param_name, param_hint , pos) VALUES (10, 'Score type', 'The score type of the survey (Optional, defaults to NULL)', 2);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (11, 'Enable/Disable self-registration permissions', 'Updates permissions. See wiki for details.', 'SetSelfRegistrationPermissions', 'W2592');
INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint, pos) VALUES (11, 'Setting value (0 off, 1 on)', 'The setting to use.', 0);

	
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE)
VALUES (12, 'Fix Property Company Region Tree', 'Turns supplier regions into companies and sets the new company as the management company of the child properties. Also adds users to companies based on region start points.', 'FixPropertyCompanyRegionTree', NULL);
INSERT INTO csr.util_script_param(UTIL_SCRIPT_ID, PARAM_NAME, PARAM_HINT, POS, PARAM_VALUE, PARAM_HIDDEN) VALUES (12, 'Root region sid', 'The root of the tree to run the fix for. The root region itself will not be considered, only regions underneath in the tree.', 0, NULL, 0);
	
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (13, 'Enable configurable meter page', 'Enables the meter "washing machine" page, a configurable page that replaces the existing meter page.', 'EnableMeterWashingMachine', NULL);

INSERT INTO csr.util_script (util_script_id,util_script_name,description,util_script_sp,wiki_article) VALUES (14,'Add new branding', 'Add a newly created branding folder to the avaliable list, this will still need to be add to a demo site via the change branding page', 'AddNewBranding', null );
INSERT INTO csr.util_script_param (util_script_id, param_name, param_hint, pos) VALUES (14, 'Client Folder', 'The client folder that contains the css', 0);
INSERT INTO csr.util_script_param (util_script_id, param_name, param_hint, pos) VALUES (14, 'Brand Name', 'Name of the branding - this will appear in the dropdown', 1);
INSERT INTO csr.util_script_param (util_script_id, param_name, param_hint, pos) VALUES (14, 'Author', 'Who created the branding', 2);
    
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (15, 'Allow Old Chart Engine', 'Allow (1) or disallow (0) old chart engine. Default for new clients is disallow.', 'AllowOldChartEngine', NULL);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint, pos) VALUES (15, 'Setting value (0 off, 1 on)', 'The setting to use.', 0);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (16, 'Enable audit score type aggregate types', 'Creates aggregate types for all score types used in audits. Can be re-run if additional score types are added.', 'SynchScoreTypeAggTypes', NULL);
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (17, 'Enable calculation score survey type', 'Enabled the survey type used to display the calculation summary page on submit.', 'EnableCalculationSurveyScore', NULL);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (18,'Sync Delegation Plan Names','Updates names and descriptions of children delegations to match master delegation','SyncDelegPlanNames',null);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID, PARAM_NAME, PARAM_HINT, POS) VALUES (18, 'Master Delegation SID','SID of the master delegation to update the children of',0);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (19,'Set CDN Server','Sets the domain of the CDN server. A CDN provides static content to users from a server closer to their location. Dynamic content such as data will still come from our servers.','SetCDNServer',null);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID, PARAM_NAME, PARAM_HINT, POS) VALUES (19, 'CDN Server name','Domain of the CDN server',0);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (20,'Remove CDN Server','Removes the CDN server so that all content comes from the site directly','RemoveCDNServer',null);



INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (21,'Start monitoring site in New Relic','Adds the site to those monitored by New Relic to diagnose performance problems and trends','AddNewRelicToSite',null);
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (22,'Stop monitoring site in New Relic','Disables New Relic client-side monitoring','RemoveNewRelicFromSite',null);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (23,'Create custom delegation layout','Creates delegation layout and assigns it to given delegation sid','CreateCustomDelegLayout','W1698');
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID, PARAM_NAME, PARAM_HINT, POS) VALUES (23, 'Delegation SID','SID of the delegation to set layout to',0);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (24, 'Add Missing Properties', 'Add properties from the region tree which are missing in the Properties module list. (Needed if Properties was enabled prior to October 2016.)', 'AddMissingProperties', NULL);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID, PARAM_NAME, PARAM_HINT, POS) VALUES (24, 'Property type','Enter default property type (if type does not exist, it will be created)',0);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (25,'Set extra fields for user picker','Set the extra fields (email, user_name, user_ref) to be displayed in user picker.', 'SetUserPickerExtraFields',NULL);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE,PARAM_HIDDEN) VALUES (25,'Extra fields','Comma separated list of fields. Allowed fields are email, user_name and user_ref. Enter space to clear the extra fields.',0,NULL,0);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (26, 'Add missing company folders in chain document library', 'Creates any missing company folders in the chain document library if the "Create document library folder" setting is set on the company type.', 'AddMissingCompanyDocFolders', NULL);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (27, 'Capture time in workflow states', 'Creates indicators for each state in given workflow and record the time items spend in each state.', 'RecordTimeInFlowStates', NULL);

INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE,PARAM_HIDDEN) VALUES (27, 'Workflow SID', 'System ID of a workflow. Supports Chain, Campaign and CMS workflow types only.', 0, NULL, 0);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (28, 'Clear last used measure conversions', 'Clears all last used measure conversions for the specified user. See wiki about functioning of last used measure conversion.','ClearLastUsdMeasureConversions','W1179');
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS) VALUES (28, 'User SID', 'SID', 0);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (29, 'Migrate Emission Factor tool', '** It needs to be tested against test environments before applying Live**. It migrates old emission factor settings to the new Emission Factor Profile tool.','MigrateEmissionFactorTool','W2990');
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (29, 'Profile Name', 'Profile Name', 0, 'Migrated profile');

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (30, 'Reset compliance workflows', 'Resets the requirement and regulation workflows back to the default. Can be used to get the latest updates made to the default workflow','ResyncDefaultComplianceFlows', 'W3093');

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (31, 'Modify batch job timeout', 'Changes the timeout for a batchjob type for the current app.','SetBatchJobTimeoutOverride',NULL);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (31, 'Batch job type id', 'Batch job type id', 0, NULL);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (31, 'Timeout mins', 'Minutes the job can run for before it times out.', 1, NULL);


INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (32, 'Show / Hide Delegation Plan', 'Sets the active flag on delegation plans to hide or show them in the UI.','ShowHideDelegPlan', NULL);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (32, 'Delegation plan sid', 'The sid of the delegation plan you want to show/hide', 0, 'DELEG_SID');
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (32, 'Hide/Show (0 hide, 1 show)', 'The setting to use', 1, '0');

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (33, 'Reset permit workflows', 'Resets the permit, permit application and permit condition workflows back to the default. Can be used to get the latest updates made to the default workflow','ResyncDefaultPermitFlows', 'W3092');

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (34,'Add US EGrid values','Add US EGrid values to a region and all its children','AddUSEGridValues',null);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (34, 'Region sid', 'The sid of the region to link e-grid references', 1, NULL);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (35, 'Create user profiles for CSR users', 'Creates profiles for all non super admin user accounts that don''t yet have one - User_ref must be set.', 'CreateProfilesForUsers', NULL);


INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (36,'Change Integration Api Company User Default Groups','Add or remove default groups for users created via the Integration Api Company Users','ChangeIntApiCompanyUserGroup',null);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (36, 'Group Name', 'The name of the group to add/remove', 1, NULL);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (36, 'Remove', 'Add = 0, Remove = 1', 2, 0);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP, WIKI_ARTICLE) VALUES (37, 'Enable/Disable lazy load of region role membership on user and region edit', 'Enable or disable automatic loading of region role membership for users on editing a user or a region', 'SetUserRegionRoleLazyLoad', NULL);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID, PARAM_NAME, PARAM_HINT, POS, PARAM_VALUE, PARAM_HIDDEN) VALUES (37, 'Lazy load', '1 to enable, 0 to disable lazy load', 0, NULL, 0);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (38,'API: Create API Client','Will create a user if the specified username doesn''t exist.','CreateAPIClient',null);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (38, 'User Name', 'The name of the user the integration will connect as. If the name specified doesn''t exist, it will be created (as a hidden user).', 1, NULL);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (38, 'Client Id', 'A secure string for the client ID. Generate a GUID perhaps.', 2, NULL);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (38, 'Client Secret. Akin to a password. Should be kept secure. Generate a GUID perhaps.', '', 3, NULL);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (39,'API: Update API Client secret','Update the client secret for a client id (API users).','UpdateAPIClientSecret',null);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (39, 'Client Id', 'The id of the client to update', 1, NULL);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (39, 'Client Secret', '', 2, NULL);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP, WIKI_ARTICLE) VALUES (40, 'Set calc end of time window', '[CHECK WITH DEV/INFRASTRUCTURE BEFORE USE] - Sets the number of years to bound calculation "end of time". Updates Calc End Dtm.', 'SetCalcFutureWindow', NULL);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID, PARAM_NAME, PARAM_HINT, POS, PARAM_VALUE, PARAM_HIDDEN) VALUES (40, 'Number of years', 'How far forward should calculations extend', 0, 1, 0);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP, WIKI_ARTICLE) VALUES (41, 'Set calc start of time date', '[CHECK WITH DEV/INFRASTRUCTURE BEFORE USE] - Sets the earliest date to include for calculations', 'SetCalcStartDate', NULL);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID, PARAM_NAME, PARAM_HINT, POS, PARAM_VALUE, PARAM_HIDDEN) VALUES (41, 'Calc start date (YYYY-MM-DD)', 'Date in YYYY-MM-DD format e.g.2010-01-01', 0, NULL, 0);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID, UTIL_SCRIPT_NAME, DESCRIPTION, UTIL_SCRIPT_SP, WIKI_ARTICLE) VALUES (42, 'Remove matrix layout settings from a delegation', 'Removes layout settings from a delegation. See wiki for details.', 'RemoveMatrixLayout', 'W2866');
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID, PARAM_NAME, PARAM_HINT, POS, PARAM_VALUE, PARAM_HIDDEN) VALUES (42, 'Delegation sid', 'The sid of the delegation to run against', 0, NULL, 0);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID, UTIL_SCRIPT_NAME, DESCRIPTION, UTIL_SCRIPT_SP, WIKI_ARTICLE) VALUES (43, 'Create unique copy of matrix layout for delegation', 'Creates a unique copy of a matrix layout. Use this if you have copied a delegation that has a matrix layout. See wiki for details.', 'CreateUniqueMatrixLayoutCopy', 'W2866');
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID, PARAM_NAME, PARAM_HINT, POS, PARAM_VALUE, PARAM_HIDDEN) VALUES (43, 'Delegation sid', 'The sid of the delegation to run against', 0, NULL, 0);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP, WIKI_ARTICLE) VALUES (44, 'Delete all out of scope compliance items.', 'Deletes ALL out of scope compliance items from the Compliance module.', 'DeleteOutOfScopeCompItems', NULL);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID, PARAM_NAME, PARAM_HINT, POS, PARAM_VALUE, PARAM_HIDDEN) VALUES (44, 'Include out of scope compliance items that have actions or scheduled actions? (y/n)', '(y/n)', 0, NULL, 0);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (45, 'Metering stats - same day average', 'Enable/disable the same day average meter alarm statistic feature.', 'EnableMeteringSameDayAvg', NULL);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (45, 'Enable/disable', 'Enable = 1, Disable = 0', 1, NULL);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (46, 'Metering core working hours - same day average', 'Enable/disable the same day average meter alarm statistic feature for core working hours.', 'EnableMeteringCoreSameDayAvg', NULL);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (46, 'Enable/disable', 'Enable = 1, Disable = 0', 1, NULL);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (47, 'Metering core working hours - day normalised values', 'Enable/disable the day normalised meter alarm statistics for core working hours.', 'EnableMeteringCoreDayNorm', NULL);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (47, 'Enable/disable', 'Enable = 1, Disable = 0', 1, NULL);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (48, 'Metering core working hours - extended values', 'Enable/disable the extended alarm statistics set for core working hours.', 'EnableMeteringCoreExtended', NULL);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (48, 'Enable/disable', 'Enable = 1, Disable = 0', 1, NULL);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (49, 'Metering core working hours - single day statistics', 'Enable/disable the single day alarm statistics set.', 'EnableMeteringDayStats', NULL);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (49, 'Enable/disable', 'Enable = 1, Disable = 0', 1, NULL);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP, WIKI_ARTICLE) VALUES (50, 'Set duplicated Enhesa items to out of scope.', 'Sets to out of scope all federal Enhesa requirements that have an unmerged duplicate in the local feed.', 'SetEnhesaDupesOutOfScope', NULL);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (51, 'Restart failed campaign', 'Restarts a campaign that failed with an error and therefore cannot be re-processed. Should only be ran if the issue causing the error has been resolved.', 'RestartFailedCampaign', NULL);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (51, 'Campaign SID', 'The SID of the campaign that has errored', 1, NULL);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (52, 'Geotag companies', 'Geotag all companies that have some address data besides country and do not currently have a location specified. Note this will use part of our monthly mapquest transaction allowance (even in test environments).', 'GeotagCompanies', NULL);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (53, 'Metering - Urjanet Statement ID Aggregation', 'Aggregate values from the same meter ID where the start/end dates match and the values come from the same Statement ID', 'EnableUrjanetStatementIdAggr', NULL);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (53, 'Enable/disable', 'Enable = 1, Disable = 0', 1, NULL);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (54, 'Display cookie policy', 'Show/hide the cookie policy in the website', 'EnableDisplayCookiePolicy', NULL);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (54, 'Show/hide', 'Show = 1, Hide = 0', 1, NULL);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (55, 'Metering - Urjanet Renewable Energy Columns', 'Enable or disable the Urjanet renewable energy column mappings and associated meter inputs', 'EnableUrjanetRenewEnergy', NULL);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (55, 'Enable/disable', 'Enable = 1, Disable = 0', 1, NULL);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (56, 'Validate audit workflow migration', 
	'Checks if audits on this site can be migrated to a workflow. Will complete successfully if the validation passes, otherwise will throw an error. Find error details in "csr/site/admin/auditmigration/validationfailures.acds" page', 'CanMigrateAudits', NULL);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (57, 'Enable Scrag++ test cube', 
  'Enables the Scrag++ test cube', 'EnableTestCube', NULL);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (58, 'Enable Scrag++ merged scenario', 
  'Migrates the test cube to the Scrag++ merged scenario and creates the unmerged scenario', 'EnableScragPP', NULL);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (58, 'Reference/comment', 'Reference/comment for approval of Scrag++ migration', 1, NULL);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) 
	VALUES (59, 'Migrate non-WF audits', 
  'Migrate non-WF audits to a Workflow. Migration will fail if the site doesn''t pass the validation (see "Validate audit workflow migration" util script). Use "force migration" to skip the validation', 'MigrateAudits', NULL);

INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (59, 'Force (skips validation)', 'Force = 1, Don''t force = 0', 1, 0);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) 
VALUES (60, 'Enable CC on workflow alerts', 'Allows adding CC users/roles to workflow alerts. Use with caution!', 'EnableCCOnAlerts', NULL);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) 
VALUES (61, 'Disable CC on workflow alerts', 'Turns off ability to add CC users/roles to workflow alerts.', 'DisableCCOnAlerts', NULL);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (62, 'Remove calc xml from trashed indicator', 
  'Removes calc xml from a trashed indicator where the indicator references one or more deleted indicators', 'ClearTrashedIndCalcXml', NULL);

INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (62, 'Indicator sid', 'Sid of trashed indicator from which to delete calc xml, or -1 to process all trashed inds with trashed calc ind check, or -2 to process all trashed inds.', 1, NULL);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (63, 'Set customer helper plugin', 
  'Provide name for a customer helper assembly', 'SetCustomerHelperAssembly', 'W3161');

INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (63, 'Name of assembly', 'Typically "CustomerName.Helper"', 1, NULL);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (64, 'Chart Colour Algorithm Version', 'Colour algorithm for DE charts', 'ChartColourAlgorithmVersion', NULL);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint, pos) VALUES (64, 'Version (1 (default), 2)', 'The version to use.', 0);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (65, 'Metering - Resubmit failed data', 'Resubmit raw feed data marked as HasErrors', 'ResubmitFailedRawMeterData', NULL);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint, pos) VALUES (65, 'Starting from', 'The date to start from (yyyy-mm-dd)', 0);

INSERT INTO csr.util_script(util_script_id, util_script_name, description, util_script_sp, wiki_article)
VALUES(66, 'Set CMS Forms Importer helper SP', 'Sets/updates the helper package that the CMS Forms Importer integration will call when importing responses from the Forms API.', 'SetCmsFormsImpSP', NULL);
INSERT INTO csr.util_script_param(util_script_id, param_name, param_hint, pos, param_value, param_hidden)
VALUES(66, 'Form ID', 'ID of the Form to set/update helper package', 0, NULL, 0);
INSERT INTO csr.util_script_param(util_script_id, param_name, param_hint, pos, param_value, param_hidden)
VALUES(66, 'Helper SP', 'SP called when importing responses', 1, NULL, 0);
INSERT INTO csr.util_script_param(util_script_id, param_name, param_hint, pos, param_value, param_hidden)
VALUES(66, 'Delete?', 'y/n to delete helper sp record for form', 2, 'n', 0);
INSERT INTO csr.util_script_param(util_script_id, param_name, param_hint, pos, param_value, param_hidden)
VALUES(66, 'Use new SP signature? CHECK WIKI BEFORE SETTING TO Y', 'y/n to', 3, 'n', 0);
INSERT INTO csr.util_script_param(util_script_id, param_name, param_hint, pos, param_value, param_hidden)
VALUES(66, 'Child Helper SP (Type "NULL" or whitespace if no child helper SP is needed)', 'SP called when importing child data for responses. Type "NULL" or whitespace if no child helper SP is needed', 4, NULL, 0);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID, UTIL_SCRIPT_NAME, DESCRIPTION, UTIL_SCRIPT_SP, WIKI_ARTICLE)
VALUES (67, 'Create automated export for all data', '[Read the wiki!] Creates an automated export class with all indicators set into the dataview. Useful for s++ migrations.', 'CreateAllDataExport', 'W3736');
INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint , pos)
VALUES (67, 'Export name', 'The name of the export class', 0);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint , pos)
VALUES (67, 'Dataview sid', 'The sid of the dataview to set indicators in', 1);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID, UTIL_SCRIPT_NAME, DESCRIPTION, UTIL_SCRIPT_SP, WIKI_ARTICLE)
VALUES (68, 'Set calc dependencies in dataview', 'Will insert all the dependencies of a supplied calculated indicator into the supplied dataview. Useful for s++ migrations.', 'SetCalcDependenciesInDataview', 'W3736');
INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint , pos)
VALUES (68, 'Calc ind sid', 'The sid of the calculated indicator', 0);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint , pos)
VALUES (68, 'Dataview sid', 'The sid of the dataview to set indicators in', 1);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID, UTIL_SCRIPT_NAME, DESCRIPTION, UTIL_SCRIPT_SP, WIKI_ARTICLE)
VALUES (69, 'New password hashing scheme: disable', 'Switches the users directly belonging to this site back to legacy password authenticaton.', 'DisableJavaAuth', NULL);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID, UTIL_SCRIPT_NAME, DESCRIPTION, UTIL_SCRIPT_SP, WIKI_ARTICLE)
VALUES (70, 'New password hashing scheme: enable', 'Switches the users directly belonging to this site to the new password authentication module.', 'EnableJavaAuth', NULL);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID, UTIL_SCRIPT_NAME, DESCRIPTION, UTIL_SCRIPT_SP)
VALUES (73, 'Set region lookup key', 'Sets the lookup key of a specified region.', 'SetRegionLookupKey');
INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint , pos)
VALUES (73, 'Region SID', 'The sid of the region to set the lookup key against', 0);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint , pos)
VALUES (73, 'Lookup key', 'The lookup key to set. Enter #CLEAR# to clear.', 1);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID, UTIL_SCRIPT_NAME, DESCRIPTION, UTIL_SCRIPT_SP)
VALUES (74, 'Trigger logistics recalculation', 'Trigger a recalculation by logistics service for a given transport mode', 'RecalcLogistics');
INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint, pos)
VALUES (74, 'Transport mode', '(1 Air, 2 Sea, 3 Road, 4 Barge, 5 Rail)', 0);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID, UTIL_SCRIPT_NAME, DESCRIPTION, UTIL_SCRIPT_SP)
VALUES (75, 'Toggle render charts as SVG', 'Toggles between rendering charts as SVG or PNG (Default, historic behaviour)', 'ToggleRenderChartsAsSvg');

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) 
VALUES (76, 'Block non-SSO superadmin logon', 'Block superadmin logons from login page. Use with caution!', 'BlockSaLogon', NULL);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID, PARAM_NAME, PARAM_HINT, POS, PARAM_VALUE)
VALUES (76, 'Block/unblock', '(1 block, 0 unblock)', 0, '1');

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) 
VALUES (77, 'Client Termination Export', 'Export terminating client data', 'TerminatedClientData', NULL);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID, PARAM_NAME, PARAM_HINT, POS, PARAM_VALUE)
VALUES (77, 'Setup/TearDown', '(1 Setup, 0 TearDown)', 0, '1');

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID, UTIL_SCRIPT_NAME, DESCRIPTION, UTIL_SCRIPT_SP)
VALUES (78, 'Toggle view source to deepest sheet', 'When enabled, viewing an issue source goes the to deepest sheet in the delegation hierarchy.', 'ToggleViewSourceToDeepestSheet');
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID, PARAM_NAME, PARAM_HINT, POS, PARAM_VALUE)
VALUES (78, 'Enable/Disable', 'Enable = 1, Disable = 0', 0, NULL);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE)
VALUES (79, 'Enable/Disable audit calculation changes', 'When enabled, calculation changes require a reason for the change to be entered by the user.', 'SetAuditCalcChangesFlag','');
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE,PARAM_HIDDEN)
VALUES (79,'Setting value (0 off, 1 on)','The setting to use.',0,null,0);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE)
VALUES (80, 'Enable/Disable check tolerance against zero', 'When enabled, tolerance violations are triggered when a value changes from zero.', 'SetCheckToleranceAgainstZeroFlag','');
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE,PARAM_HIDDEN)
VALUES (80,'Setting value (0 off, 1 on)','The setting to use.',0,null,0);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE)
VALUES (81, 'Reset Anonymise PII data capability permissions', 'Resets the permissions on the Anonymise PII data capability, giving permissions to only Superadmin users.', 'ResetAnonymisePiiDataPermissions','');

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE)
VALUES (82, 'Create a Chain System Administrator Role', 'A system wide administrator with permissions outside of the supply chain module for administration of the module itself.', 'CreateChainSystemAdminRole','');
INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint , pos) VALUES (82, 'Secondary Company Type Id', 'The company type id that the top company will have permissions configured against (the chain two tier default is suppliers)', 1);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE)
VALUES (83, 'Create a Chain Supplier Administrator Role', 'A supply chain administrator for top level company with access to managing all suppliers.', 'CreateSupplierAdminRole','');
INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint , pos) VALUES (83, 'Secondary Company Type Id', 'The company type id that the top company will have permissions configured against (the chain two tier default is suppliers)', 1);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE)
VALUES (84, 'Recalc one Restricted', 'Resets the calc dates and queues recalc jobs for the current site/app.', 'RecalcOneRestricted', NULL);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE,PARAM_HIDDEN)
VALUES (84, 'Start Year', 'The start year.', 0, NULL, 0);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE,PARAM_HIDDEN)
VALUES (84, 'End Year', 'The end year.', 1, NULL, 0);

END;
/

-- GRESB Property Types
INSERT INTO csr.gresb_property_type(gresb_property_type_id, name, pos) VALUES (1, 'Retail', 0);
INSERT INTO csr.gresb_property_type(gresb_property_type_id, name, pos) VALUES (2, 'Office', 1);
INSERT INTO csr.gresb_property_type(gresb_property_type_id, name, pos) VALUES (3, 'Industrial', 2);
INSERT INTO csr.gresb_property_type(gresb_property_type_id, name, pos) VALUES (4, 'Residential', 3);
INSERT INTO csr.gresb_property_type(gresb_property_type_id, name, pos) VALUES (5, 'Hotel', 4);
INSERT INTO csr.gresb_property_type(gresb_property_type_id, name, pos) VALUES (6, 'Lodging, Leisure '||CHR(38)||' Recreation', 5);
INSERT INTO csr.gresb_property_type(gresb_property_type_id, name, pos) VALUES (7, 'Education', 6);
INSERT INTO csr.gresb_property_type(gresb_property_type_id, name, pos) VALUES (8, 'Technology/Science', 7);
INSERT INTO csr.gresb_property_type(gresb_property_type_id, name, pos) VALUES (9, 'Healthcare', 8);
INSERT INTO csr.gresb_property_type(gresb_property_type_id, name, pos) VALUES (10, 'Mixed use', 9);
INSERT INTO csr.gresb_property_type(gresb_property_type_id, name, pos) VALUES (11, 'Other', 10);

INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (1, 1, 'High Street', 'REHS', 0);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (1, 2, 'Retail Centers: Shopping Center', 'RCSC', 1);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (1, 3, 'Retail Centers: Strip Mall', 'RCSM', 2);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (1, 4, 'Retail Centers: Lifestyle Center', 'RCLC', 3);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (1, 5, 'Retail Centers: Warehouse', 'RCWH', 4);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (1, 6, 'Restaurants/Bars', 'RRBA', 5);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (1, 7, 'Other', 'REOT', 6);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (2, 1, 'Corporate: Low-Rise Office', 'OCLO', 0);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (2, 2, 'Corporate: Mid-Rise Office', 'OCMI', 1);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (2, 3, 'Corporate: High-Rise Office', 'OCHI', 2);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (2, 4, 'Medical Office', 'OFMO', 3);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (2, 5, 'Business Park', 'OFBP', 4);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (2, 6, 'Other', 'OFOT', 5);

-- Removed csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (3, 1, 'Distribution Warehouse', 'INDW', 0);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (3, 2, 'Industrial Park', 'INIP', 2);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (3, 3, 'Manufacturing', 'INMA', 3);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (3, 4, 'Other', 'INOT', 4);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (3, 5, 'Refrigerated Warehouse', 'IRFW', 1);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (3, 6, 'Non-Refrigerated Warehouse', 'INRW', 0);

INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (4, 1, 'Multi-Family: Low-Rise Multi-Family', 'RMFL', 0);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (4, 2, 'Multi-Family: Mid-Rise Multi Family', 'RMFM', 1);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (4, 3, 'Multi-Family: High-Rise Multi-Family', 'RMFH', 2);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (4, 4, 'Family Homes', 'RSFH', 3);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (4, 5, 'Student Housing', 'RSSH', 4);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (4, 6, 'Retirement Living', 'RSRL', 5);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (4, 7, 'Other', 'RSOT', 6);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (5, 1, 'Hotel', 'HTL', 0);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (6, 1, 'Lodging, Leisure '||CHR(38)||' Recreation', 'LLO', 0);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (6, 2, 'Indoor Arena', 'LLIA', 1);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (6, 3, 'Fitness Center', 'LLFC', 2);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (6, 4, 'Performing Arts', 'LLPA', 3);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (6, 5, 'Swimming Center', 'LLSC', 4);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (6, 6, 'Museum/Gallery', 'LLMG', 5);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (6, 7, 'Other', 'LLOT', 6);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (7, 1, 'School', 'EDSC', 0);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (7, 2, 'University', 'EDUN', 1);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (7, 3, 'Library', 'EDLI', 2);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (7, 4, 'Other', 'EDOT', 3);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (8, 1, 'Data Center', 'TSDC', 0);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (8, 2, 'Laboratory/Life Sciences', 'TSLS', 1);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (8, 3, 'Other', 'TSOT', 2);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (9, 1, 'Healthcare Center', 'HEHC', 0);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (9, 2, 'Senior Homes', 'HESH', 1);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (9, 3, 'Other', 'HEOT', 2);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (10, 1, 'Office/Retail', 'XORE', 0);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (10, 2, 'Office/Residential', 'XORS', 1);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (10, 3, 'Office/Industrial', 'XOIN', 2);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (10, 4, 'Other', 'XOTH', 3);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (11, 1, 'Parking (Indoors)', 'OTPI', 0);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (11, 2, 'Self-Storage', 'OTSS', 1);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (11, 3, 'Other', 'OTHR', 2);

INSERT INTO csr.gresb_indicator_type(gresb_indicator_type_id, title, required, pos) VALUES (1, 'Property', 1, 0);
INSERT INTO csr.gresb_indicator_type(gresb_indicator_type_id, title, required, pos) VALUES (2, 'Energy', 1, 3);
INSERT INTO csr.gresb_indicator_type(gresb_indicator_type_id, title, required, pos) VALUES (3, 'GHG', 1, 4);
INSERT INTO csr.gresb_indicator_type(gresb_indicator_type_id, title, required, pos) VALUES (4, 'Water', 1, 5);
INSERT INTO csr.gresb_indicator_type(gresb_indicator_type_id, title, required, pos) VALUES (5, 'Waste', 1, 6);
INSERT INTO csr.gresb_indicator_type(gresb_indicator_type_id, title, required, pos) VALUES (6, 'Efficiency', 1, 1);
INSERT INTO csr.gresb_indicator_type(gresb_indicator_type_id, title, required, pos) VALUES (7, 'Reporting', 1, 2);

INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id, system_managed, sm_description)
	VALUES (1000,1,'gresb_asset_id','integer','Unique GRESB Asset ID. Generated automatically when creating a new asset. Can be uploaded into 360 for pre-existing assets.','',NULL,1,'Property''s GRESB asset id. The asset ID is recorded when a GRESB asset is created or can be uploaded for pre-existing assets. If we have an ID, we will update the specified asset, otherwise we will attempt to create it.');
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id, system_managed, sm_description)
	VALUES (1001,1,'asset_name','Text(255)','Name of the asset as displayed to the users with access to this portfolio in the Asset Portal.','',NULL,1,'Region''s description');
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1002,1,'optional_information','Text(255)','Any additional information - displayed in the Asset Portal.','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id, system_managed, sm_description)
	VALUES (1003,1,'property_type_code','Text(255)','GRESB property type classification for the asset.','',NULL,1,'Property''s GRESB property type code calculated from GRESB property sub type.');
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id, system_managed, sm_description)
	VALUES (1004,1,'country','Text(255)','ISO3166 country code.','',NULL,1,'Property''s country');
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id, system_managed, sm_description)
	VALUES (1005,1,'state_province','Text(255)','State, province, or region.','',NULL,1,'Property''s state');
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id, system_managed, sm_description)
	VALUES (1006,1,'city','Text(255)','City, town, or village.','',NULL,1,'Property''s city');
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id, system_managed, sm_description)
	VALUES (1007,1,'address','Text(255)','Physical street or postal address.','',NULL,1,'Comma seperated list using the property''s: Street address line 1, Street address line 2, City, State/Region, Zip/Postcode; skipping any blanks items');
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id, system_managed, sm_description)
	VALUES (1008,1,'lat','Decimal','Latitude.','',NULL,1,'Property''s latitude');
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id, system_managed, sm_description)
	VALUES (1009,1,'lng','Decimal','Longitude.','',NULL,1,'Property''s longitude');
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1010,1,'construction_year','Integer','Year in which the asset was completed and ready for use.','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1011,1,'asset_gav','Decimal','Gross asset value of the asset at the end of the reporting period. This is in millions of the relevant currency.','',null);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1012,1,'asset_size','Decimal','The total floor area size of the asset - without outdoor/exterior areas. Use the same area metric as reported in RC3.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1013,6,'en_emr_tba','Y/N','Has a technical building assessment to identify energy efficiency improvements been performed in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1014,6,'en_emr_amr','Y/N','Energy efficiency measure: Have automatic meter readings for energy been implemented in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1015,6,'en_emr_asur','Y/N','Energy efficiency measure: Have automation system upgrades/replacements been implemented in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1016,6,'en_emr_msur','Y/N','Energy efficiency measure: Have management system upgrades/replacements been implememted in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1017,6,'en_emr_ihee','Y/N','Energy efficiency measure: Have high-efficiency equipment and/or appliances been installed in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1018,6,'en_emr_iren','Y/N','Energy efficiency measure: Has on-site renewable energy been installed in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1019,6,'en_emr_oce','Y/N','Energy efficiency measure: Have occupier engagement/informational technology improvements been implemented in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1020,6,'en_emr_sbt','Y/N','Energy efficiency measure: Have smart grid or smart building technologies been implemented in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1021,6,'en_emr_src','Y/N','Energy efficiency measure: Has systems commissioning or retro-commissioning been implememted in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1022,6,'en_emr_wri','Y/N','Energy efficiency measure: Has the wall and/or roof insulation been replaced or modified to improve energy efficiency in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1023,6,'en_emr_wdr','Y/N','Energy efficiency measure: Have windows been replaced to improve energy efficiency in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1024,6,'wat_emr_tba','Y/N','Has a technical building assessment to identify water efficiency improvements been performed in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1025,6,'wat_emr_amr','Y/N','Water efficiency measure: Have automatic meter readings for water been implemented in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1026,6,'wat_emr_clt','Y/N','Water efficiency measure: Have cooling towers been introduced in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1027,6,'wat_emr_dsi','Y/N','Water efficiency measure: Have smart or drip irrigation methods been implemented in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1028,6,'wat_emr_dtnl','Y/N','Water efficiency measure: Has drought-tolerant and/or native landscaping been introduced in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1029,6,'wat_emr_hedf','Y/N','Water efficiency measure: Have high-efficiency and/or dry fixtures been introduced in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1030,6,'wat_emr_lds','Y/N','Water efficiency measure: Has a leak detection system been implemented in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1031,6,'wat_emr_mws','Y/N','Water efficiency measure: Has the installation of water sub-meters been implemented in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1032,6,'wat_emr_owwt','Y/N','Water efficiency measure: Has a system or process of on-site water treatment been implemented in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1033,6,'wat_emr_rsgw','Y/N','Water efficiency measure: Has a system or process to reuse storm and/or grey water been implemented in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1034,6,'was_emr_tba','Y/N','Has a technical building assessment to identify waste efficiency improvements been performed in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1035,6,'was_emr_clfw','Y/N','Waste efficiency measure: Has composting landscape and/or food waste been implemented in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1036,6,'was_emr_opm','Y/N','Waste efficiency measure: Has a system or process of ongoing monitoring of waste performance been implemented in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1037,6,'was_emr_rec','Y/N','Waste efficiency measure: Has a program for local waste recycling been implemented in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1038,6,'was_emr_wsm','Y/N','Waste efficiency measure: Has a program of waste management been implemented in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1039,6,'was_emr_wsa','Y/N','Waste efficiency measure: Has a waste stream audit been performed in the last 3 years?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1040,7,'tenant_ctrl','Y/N','Is the whole building tenant-controlled (Y) or does the landlord have at least some operational control (N)?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1041,7,'asset_vacancy','Decimal','The average percent vacancy rate.','%',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id, system_managed, sm_description)
	VALUES (1042,7,'owned_entire_period','Y/N','Has the asset been owned for the entire reporting year (Y) or was the asset purchased or sold during the reporting year (N)?','',NULL,1,'True if region aquisition date and disposal date encompass the whole year');
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id, system_managed, sm_description)
	VALUES (1043,7,'ownership_from','Date','If asset was not owned for entire reporting period, date when the asset was purchased or acquired within the reporting year.','',NULL,1,'If owned_entire_period is false then region''s aquisition date');
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id, system_managed, sm_description)
	VALUES (1044,7,'ownership_to','Date','If asset was not owned for entire reporting period, date when the asset was sold within the reporting year.','',NULL,1,'If owned_entire_period is false then region''s disposal date');
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1045,7,'ncmr_status','Text(255)','The operational status of the asset: standing investment, major renovation, or new construction, within the reporting year.','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1046,7,'ncmr_from','Date','If the asset was under major renovation or new construction, the start date of the project within the reporting year.','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1047,7,'ncmr_to','Date','If the asset was under major renovation or new construction, the end date of the project within the reporting year.','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1048,1,'whole_building','Y/N','Is the energy consumption data of the asset collected for the whole building (Y) or separately for base building and tenant space (N)?','',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1049,1,'asset_size_common','Decimal','Floor area of the common areas.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1050,1,'asset_size_shared','Decimal','Floor area of the shared spaces.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1051,1,'asset_size_tenant','Decimal','Floor area of all tenant spaces (all lettable area).','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1052,1,'asset_size_tenant_landlord','Decimal','Floor area of tenant spaces where the landlord purchases energy.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1053,1,'asset_size_tenant_tenant','Decimal','Floor area of tenant spaces where the tenant purchases energy.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id, system_managed, sm_description)
	VALUES (1054,2,'en_data_from','Date','Date within reporting year from which energy data is available.','',NULL,1,'The first date within the reporting year for which any field beginning with en_ has data');
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id, system_managed, sm_description)
	VALUES (1055,2,'en_data_to','Date','Date within reporting year to which energy data is available.','',NULL,1,'The last date within the reporting year for which any field beginning with en_ has data');
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1056,2,'en_abs_wf','Decimal','Absolute and non-normalized fuel consumption for assets reporting on whole building.','kWh',8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1057,2,'en_cov_wf','Decimal','Covered floor area where fuel consumption data is collected for assets reporting on whole building.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1058,2,'en_tot_wf','Decimal','Total floor area where fuel supply exists for assets reporting on whole building.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1059,2,'en_abs_wd','Decimal','Absolute and non-normalized district heating and cooling consumption for assets reporting on whole building.','kWh',8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1060,2,'en_cov_wd','Decimal','Covered floor area where district heating and cooling consumption data is collected for assets reporting on whole building.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1061,2,'en_tot_wd','Decimal','Total floor area where district heating and cooling supply exists for assets reporting on whole building.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1062,2,'en_abs_we','Decimal','Absolute and non-normalized electricity consumption for assets reporting on whole building.','kWh',8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1063,2,'en_cov_we','Decimal','Covered floor area where electricity consumption data is collected for assets reporting on whole building.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1064,2,'en_tot_we','Decimal','Total floor area where electricity supply exists for assets reporting on whole building.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1065,2,'en_abs_lc_bsf','Decimal','Absolute and non-normalized fuel consumption for shared services.','kWh',8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1066,2,'en_cov_lc_bsf','Decimal','Covered floor area where fuel consumption data is collected for shared services.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1067,2,'en_tot_lc_bsf','Decimal','Total floor area where fuel supply exists for shared services.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1068,2,'en_abs_lc_bsd','Decimal','Absolute and non-normalized district heating and cooling consumption for shared services.','kWh',8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1069,2,'en_cov_lc_bsd','Decimal','Covered floor area where district heating and cooling consumption data is collected for shared services.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1070,2,'en_tot_lc_bsd','Decimal','Total floor area where district heating and cooling supply exists for shared services.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1071,2,'en_abs_lc_bse','Decimal','Absolute and non-normalized electricity consumption for shared services.','kWh',8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1072,2,'en_cov_lc_bse','Decimal','Covered floor area where electricity consumption data is collected for shared services.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1073,2,'en_tot_lc_bse','Decimal','Total floor area where electricity supply exists for shared services.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1074,2,'en_abs_lc_bcf','Decimal','Absolute and non-normalized fuel consumption for common areas.','kWh',8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1075,2,'en_cov_lc_bcf','Decimal','Covered floor area where fuel consumption data is collected for common areas.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1076,2,'en_tot_lc_bcf','Decimal','Total floor area where fuel supply exists for common areas.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1077,2,'en_abs_lc_bcd','Decimal','Absolute and non-normalized district heating and cooling consumption for common areas.','kWh',8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1078,2,'en_cov_lc_bcd','Decimal','Covered floor area where district heating and cooling consumption data is collected for common areas.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1079,2,'en_tot_lc_bcd','Decimal','Total floor area where district heating and cooling supply exists for common areas.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1080,2,'en_abs_lc_bce','Decimal','Absolute and non-normalized electricity consumption for common areas.','kWh',8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1081,2,'en_cov_lc_bce','Decimal','Covered floor area where electricity consumption data is collected for common areas.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1082,2,'en_tot_lc_bce','Decimal','Total floor area where electricity supply exists for common areas.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1083,2,'en_abs_lc_tf','Decimal','Absolute and non-normalized fuel consumption for landlord-controlled tenant spaces.','kWh',8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1084,2,'en_cov_lc_tf','Decimal','Covered floor area where fuel consumption data is collected for landlord-controlled tenant spaces.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1085,2,'en_tot_lc_tf','Decimal','Total floor area where fuel supply exists for landlord-controlled tenant spaces.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1086,2,'en_abs_lc_td','Decimal','Absolute and non-normalized district heating and cooling consumption for landlord-controlled tenant spaces.','kWh',8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1087,2,'en_cov_lc_td','Decimal','Covered floor area where district heating and cooling consumption data is collected for landlord-controlled tenant spaces.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1088,2,'en_tot_lc_td','Decimal','Total floor area where district heating and cooling supply exists for landlord-controlled tenant spaces.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1089,2,'en_abs_lc_te','Decimal','Absolute and non-normalized electricity consumption for landlord-controlled tenant spaces.','kWh',8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1090,2,'en_cov_lc_te','Decimal','Covered floor area where electricity consumption data is collected for landlord-controlled tenant spaces.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1091,2,'en_tot_lc_te','Decimal','Total floor area where electricity supply exists for landlord-controlled tenant spaces.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1092,2,'en_abs_tc_tf','Decimal','Absolute and non-normalized fuel consumption for tenant-controlled tenant spaces.','kWh',8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1093,2,'en_cov_tc_tf','Decimal','Covered floor area where fuel consumption data is collected for tenant-controlled tenant spaces.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1094,2,'en_tot_tc_tf','Decimal','Total floor area where fuel supply exists for tenant-controlled tenant spaces.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1095,2,'en_abs_tc_td','Decimal','Absolute and non-normalized district heating and cooling consumption for tenant-controlled tenant spaces.','kWh',8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1096,2,'en_cov_tc_td','Decimal','Covered floor area where district heating and cooling consumption data is collected for tenant-controlled tenant spaces.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1097,2,'en_tot_tc_td','Decimal','Total floor area where district heating and cooling supply exists for tenant-controlled tenant spaces.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1098,2,'en_abs_tc_te','Decimal','Absolute and non-normalized electricity consumption for tenant-controlled tenant spaces.','kWh',8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1099,2,'en_cov_tc_te','Decimal','Covered floor area where electricity consumption data is collected for tenant-controlled tenant spaces.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1100,2,'en_tot_tc_te','Decimal','Total floor area where electricity supply exists for tenant-controlled tenant spaces.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1101,2,'en_abs_lc_of','Decimal','Absolute and non-normalized fuel consumption for landlord-controlled outdoor spaces.','kWh',8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1102,2,'en_abs_lc_oe','Decimal','Absolute and non-normalized electricity consumption for landlord-controlled outdoor spaces.','kWh',8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1103,2,'en_abs_tc_of','Decimal','Absolute and non-normalized fuel consumption for tenant-controlled outdoor spaces.','kWh',8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1104,2,'en_abs_tc_oe','Decimal','Absolute and non-normalized electricity consumption for tenant-controlled outdoor spaces.','kWh',8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1105,2,'en_ren_ons_con','Decimal','Renewable energy generated and consumed on-site by the landlord.','kWh',8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1106,2,'en_ren_ons_exp','Decimal','Renewable energy generated on-site and exported by the landlord.','kWh',8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1107,2,'en_ren_ons_tpt','Decimal','Renewable energy generated and consumed on-site by the tenant or a third party.','kWh',8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1108,2,'en_ren_ofs_pbl','Decimal','Renewable energy generated off-site and purchased by the landlord.','kWh',8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1109,2,'en_ren_ofs_pbt','Decimal','Renewable energy generated off-site and purchased by the tenant.','kWh',8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1110,3,'ghg_abs_s1_w','Decimal','GHG scope 1 emissions generated by the asset.','metric ton',4);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1111,3,'ghg_cov_s1_w','Decimal','Covered floor area where GHG scope 1 emissions data is collected.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1112,3,'ghg_tot_s1_w','Decimal','Total floor area where GHG scope 1 emissions can exist.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1113,3,'ghg_abs_s1_o','Decimal','GHG scope 1 emissions generated by the outdoor spaces associated with the asset.','metric ton',4);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1114,3,'ghg_abs_s2_lb_w','Decimal','GHG scope 2 emissions generated by the asset, calculated using the location-based method.','metric ton',4);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1115,3,'ghg_cov_s2_lb_w','Decimal','Covered floor area where GHG scope 2 emissions data is collected, calculated using the location-based method.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1116,3,'ghg_tot_s2_lb_w','Decimal','Total floor area where GHG scope 2 emissions can exist, calculated using the location-based method.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1117,3,'ghg_abs_s2_lb_o','Decimal','GHG scope 2 emissions generated by the outdoor spaces associated with the asset, calculated using the location-based method.','metric ton',4);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1118,3,'ghg_abs_s2_mb_w','Decimal','GHG scope 2 emissions generated by the asset, calculated using the market-based method.','metric ton',4);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1119,3,'ghg_abs_s2_mb_o','Decimal','GHG scope 2 emissions generated by the outdoor spaces associated with the asset, calculated using the market-based method.','metric ton',4);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1120,3,'ghg_abs_s3_w','Decimal','GHG scope 3 emissions generated by the asset.','metric ton',4);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1121,3,'ghg_cov_s3_w','Decimal','Covered floor area where GHG scope 3 emissions data is collected.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1122,3,'ghg_tot_s3_w','Decimal','Total floor area where GHG scope 3 emissions can exist.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1123,3,'ghg_abs_s3_o','Decimal','GHG scope 3 emissions generated by the outdoor spaces associated with the asset.','metric ton',4);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1124,3,'ghg_abs_offset','Decimal','GHG offsets purchased.','metric ton',4);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id, system_managed, sm_description)
	VALUES (1125,4,'wat_data_from','Date','Date within reporting year from which water data is available.','',NULL,1,'The first date within the reporting year for which any field beginning with wat_ has data');
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id, system_managed, sm_description)
	VALUES (1126,4,'wat_data_to','Date','Date within reporting year to which water data is available.','',NULL,1,'The last date within the reporting year for which any field beginning with wat_ has data');
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1127,4,'wat_abs_w','Decimal','Absolute and non-normalized water consumption for assets reporting on whole building.','m'||UNISTR('\00B3')||'',9);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1128,4,'wat_cov_w','Decimal','Covered floor area where water consumption data is collected for assets reporting on whole building.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1129,4,'wat_tot_w','Decimal','Total floor area where water supply exists for assets reporting on whole building.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1130,4,'wat_abs_lc_bs','Decimal','Absolute and non-normalized water consumption for shared services.','m'||UNISTR('\00B3')||'',9);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1131,4,'wat_cov_lc_bs','Decimal','Covered floor area where water consumption data is collected for shared services.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1132,4,'wat_tot_lc_bs','Decimal','Total floor area where water supply exists for shared services.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1133,4,'wat_abs_lc_bc','Decimal','Absolute and non-normalized water consumption for common areas.','m'||UNISTR('\00B3')||'',9);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1134,4,'wat_cov_lc_bc','Decimal','Covered floor area where water consumption data is collected for common areas.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1135,4,'wat_tot_lc_bc','Decimal','Total floor area where water supply exists for common areas.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1136,4,'wat_abs_lc_t','Decimal','Absolute and non-normalized water consumption for landlord-controlled tenant spaces.','m'||UNISTR('\00B3')||'',9);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1137,4,'wat_cov_lc_t','Decimal','Covered floor area where water consumption data is collected for landlord-controlled tenant spaces.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1138,4,'wat_tot_lc_t','Decimal','Total floor area where water supply exists for landlord-controlled tenant spaces.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1139,4,'wat_abs_tc_t','Decimal','Absolute and non-normalized water consumption for tenant-controlled tenant spaces.','m'||UNISTR('\00B3')||'',9);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1140,4,'wat_cov_tc_t','Decimal','Covered floor area where water consumption data is collected for tenant-controlled tenant spaces.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1141,4,'wat_tot_tc_t','Decimal','Total floor area where water supply exists for tenant-controlled tenant spaces.','m'||UNISTR('\00B2')||'',27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1142,4,'wat_abs_lc_o','Decimal','Absolute and non-normalized water consumption for landlord-controlled outdoor spaces.','m'||UNISTR('\00B3')||'',9);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1143,4,'wat_abs_tc_o','Decimal','Absolute and non-normalized water consumption for tenant-controlled outdoor spaces.','m'||UNISTR('\00B3')||'',9);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1144,4,'wat_rec_ons_reu','Decimal','Volume of greywater and/or blackwater reused in on-site activities.','m'||UNISTR('\00B3')||'',9);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1145,4,'wat_rec_ons_cap','Decimal','Volume of rainwater, fog, or condensate that is treated and purified for reuse and/or recycling.','m'||UNISTR('\00B3')||'',9);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1146,4,'wat_rec_ons_ext','Decimal','Volume of extracted groundwater that is treated and purified for reuse and/or recycling.','m'||UNISTR('\00B3')||'',9);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1147,4,'wat_rec_ofs_pur','Decimal','Volume of recycled water purchased from a third party.','m'||UNISTR('\00B3')||'',9);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id, system_managed, sm_description)
	VALUES (1148,5,'was_data_from','Date','Date within reporting year from which waste data is available.','',NULL,1,'The first date within the reporting year for which any field beginning with was_ has data');
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id, system_managed, sm_description)
	VALUES (1149,5,'was_data_to','Date','Date within reporting year to which waste data is available.','',NULL,1,'The last date within the reporting year for which any field beginning with was_ has data');
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1150,5,'was_abs_haz','Decimal','Absolute and non-normalized hazardous waste produced by asset.','metric ton',4);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1151,5,'was_abs_nhaz','Decimal','Absolute and non-normalized non-hazardous waste produced by asset.','metric ton',4);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1152,5,'was_pcov','Decimal','Percent coverage out of total asset size where waste data is collected.','%',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1153,5,'was_pabs_lf','Decimal','Percentage of total waste sent to landfill.','%',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1154,5,'was_pabs_in','Decimal','Percentage of total waste incinerated.','%',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1155,5,'was_pabs_ru','Decimal','Percentage of total waste reused.','%',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1156,5,'was_pabs_wte','Decimal','Percentage of total waste converted to energy.','%',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1157,5,'was_pabs_rec','Decimal','Percentage of total waste recycled.','%',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1158,5,'was_pabs_oth','Decimal','Percentage of total waste where disposal route is other or unknown.','%',NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id, system_managed, sm_description)
	VALUES (1159,1,'partners_id','integer','360 provided Asset ID to ensure correct mapping within 360.','',NULL,1,'Property''s region sid.');
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id, system_managed, sm_description)
	VALUES (1160,1,'certifications','Certifications','GRESB asset certifications.',NULL,NULL,1,'Property certifications');
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id, system_managed, sm_description)
	VALUES (1161, 1,'ratings','Ratings','GRESB asset ratings.',NULL,NULL,1,'Property ratings');
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1162,7,'asset_ownership','Decimal','Percentage of the asset owned by the reporting entity.','%',NULL);

INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('accepted', 'A boolean field must be set');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('blank', 'Cannot be blank');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('confirmation', 'Value must match {0}''s value');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('cov_lt_tot', 'Maximum Coverage must be greater than or equal to Data Coverage');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('cov_value_required', 'All fields (value, max coverage, and total coverage) must be provided if any are provided');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('empty', 'Cannot be blank or an empty collection');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('equal_to', 'Value must be exactly {0}');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('even', 'Must be even');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('exclusion', 'The value is one of the attributes excluded values');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('field_invalid', 'The field name is not valid');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('greater_than', 'Must be greater than {0}');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('greater_than_or_equal_to', 'Must be greater than or equal to {0}');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('inclusion', 'Must be one of the attributes permitted value');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('invalid', 'Is not a valid value');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('less_than', 'Must be less than {0}');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('less_than_or_equal_to', 'Must be less than or equal to {0}');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('months_in_year', 'Must be within a year (12 months)');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('not_a_number', 'Must be a number');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('not_an_integer', 'Must be an integer');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('not_negative', 'Must be negative');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('odd', 'Must be odd');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('other_than', 'The value is the wrong length. It must not be {0} characters');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('percentage_lte_100', 'Must be less than or equal to 100%');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('present', 'Must be blank');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('record_invalid', 'There is some unspecified problem with the record. More details me be present on other attributes');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('restrict_dependent_destroy', 'The record could not be deleted because a {0} depends on it');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('taken', 'The value must be unique and has already been used in this context');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('too_long', 'The value is too long. It must be at most {0} characters');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('too_short', 'The value is too short. It must be at least {0} characters');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('wrong_length', 'The value is the wrong length. It must be exactly {0} characters');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('waste_lte_100', 'Total waste disposal must be less than or equal to 100%');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('waste_alloc', 'Waste management data cannot be provided for both Managed and Indirectly Managed columns');

INSERT INTO csr.gresb_service_config (name, url, oauth_url, client_id, client_secret)
VALUES ('live', 'https://api.gresb.com', 'https://portal.gresb.com', 'KEfVI74RtLMc11jajkb_OHY7NVcYYV5S1uNv2cxG5D0', 'mfZBnzPrWbaI3SIDcKx-1ldXzIHcXS-nnIPed1SStpc');
	 
INSERT INTO csr.gresb_service_config (name, url, oauth_url, client_id, client_secret)
VALUES ('sandbox', 'https://demo-api.gresb.com', 'https://demo-portal.gresb.com', 'kmVpq1pFvf5YMoTTqPnrzWPT9T4IZ9n3nozcwB6TUZ0', '-DPrH555MjIgM2GMpIaXjq53a1rFp4X6odd26uHjDz0');
	

BEGIN
	-- SSO login URL redirect options
	INSERT INTO csr.allowed_sso_login_redirect (url, display_name, id) VALUES ('/csr/public/sso/InitiateSingleSignOn.aspx', 'Single Sign On', 0);
	INSERT INTO csr.allowed_sso_login_redirect (url, display_name, id) VALUES ('/csr/site/login.acds', 'CSR Login', 1);
	INSERT INTO csr.allowed_sso_login_redirect (url, display_name, id) VALUES ('/csr/site/chain/public/login.acds', 'Chain Login', 2);
END;
/

BEGIN
	INSERT INTO csr.degreeday_account (account_name, account_key, security_key)
	VALUES ('test', 'test-test-test', 'test-test-test-test-test-test-test-test-test-test-test-test-test');

	INSERT INTO csr.degreeday_account (account_name, account_key, security_key)
	VALUES ('default', 'fbfg-cssj-pgff', 'nspq-yg4a-c4qh-ck9n-nhnj-qx2c-jkc2-s48r-54hu-6fsj-q6mn-zzpw-ndhv');
END;
/


INSERT INTO csr.batch_job_event (event_id, label) VALUES (0, 'Abort');
INSERT INTO csr.capability (name, allow_by_default) VALUES ('Abort any batch job', 0);

BEGIN
	INSERT INTO CSR.FLOW_STATE_NATURE (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (0, 'training', 'Unscheduled');
	INSERT INTO CSR.FLOW_STATE_NATURE (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (1, 'training', 'Unapproved');
	INSERT INTO CSR.FLOW_STATE_NATURE (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (2, 'training', 'Approved / Confirmed');
	INSERT INTO CSR.FLOW_STATE_NATURE (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (3, 'training', 'Post-attendance');
	INSERT INTO CSR.FLOW_STATE_NATURE (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (4, 'training', 'Deleted');

	INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (5, 'regulation', 'New');
	INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (6, 'regulation', 'Updated');
	INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (7, 'regulation', 'Action Required');
	INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (8, 'regulation', 'Compliant');
	INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (9, 'regulation', 'Not applicable');
	INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (10, 'regulation', 'Retired');

	INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (11, 'requirement', 'New');
	INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (12, 'requirement', 'Updated');
	INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (13, 'requirement', 'Action Required');
	INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (14, 'requirement', 'Compliant');
	INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (15, 'requirement', 'Not applicable');
	INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (16, 'requirement', 'Retired');

	INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (17, 'permit', 'Not created');
	INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (18, 'permit', 'Application');
	INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (19, 'permit', 'Active');
	INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (20, 'permit', 'Surrendered');

	INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (21, 'application', 'Not created');
	INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (22, 'application', 'Pre-application');
	INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (23, 'application', 'Initial checks');
	INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (24, 'application', 'Determination');
	INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (25, 'application', 'Determined');

	INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (26, 'condition', 'Not created');
	INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (27, 'condition', 'Active');
	INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (28, 'condition', 'Inactive');
	INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (29, 'permit', 'Refused');
	INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (30, 'application', 'Withdrawn');
	INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (31, 'condition', 'Updated');
	INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (32, 'application', 'Determination paused'); 
	INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (33, 'condition', 'Compliant');
	INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (34, 'condition', 'Action required'); 
	INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (35, 'permit', 'Updated'); 
	INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (36, 'permit', 'Surrendered Acknowledged');

	INSERT INTO CSR.FLOW_STATE_NATURE (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (37, 'campaign', 'Promoted to Submission');

	INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (38, 'disclosureassignment', 'Promoted to Approved');
	INSERT INTO csr.flow_state_nature (flow_state_nature_id, flow_alert_class, label) VALUES (39, 'disclosure', 'Promoted to Submission');
END;
/

BEGIN
	INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (30, 'Full user export', 'Credit360.ExportImport.Export.Batched.Exporters.FullUserListExporter');
	INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (31, 'Filtered user export', 'Credit360.ExportImport.Export.Batched.Exporters.FilteredUserListExporter');
	INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (32, 'Region list export', 'Credit360.ExportImport.Export.Batched.Exporters.RegionListExporter');
	INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (33, 'Indicator list export', 'Credit360.ExportImport.Export.Batched.Exporters.IndicatorListExporter');
	INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (34, 'Data export', 'Credit360.ExportImport.Export.Batched.Exporters.DataExportExporter');
	INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (35, 'Region role membership export', 'Credit360.ExportImport.Export.Batched.Exporters.RegionRoleExporter');
	INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (36, 'Region and meter export', 'Credit360.ExportImport.Export.Batched.Exporters.RegionAndMeterExporter');
	INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (37, 'Measure list export', 'Credit360.ExportImport.Export.Batched.Exporters.MeasureListExporter');
	INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (38, 'Emission profile export', 'Credit360.ExportImport.Export.Batched.Exporters.EmissionProfileExporter');
	INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (39, 'Factor set export', 'Credit360.ExportImport.Export.Batched.Exporters.FactorSetExporter');
	INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (40, 'Indicator translations', 'Credit360.ExportImport.Export.Batched.Exporters.IndicatorTranslationExporter');
	INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (41, 'Region translations', 'Credit360.ExportImport.Export.Batched.Exporters.RegionTranslationExporter');
	INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (42, 'CMS quick chart exporter', 'Credit360.ExportImport.Export.Batched.Exporters.CmsQuickChartExporter');
	INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (43, 'CMS exporter', 'Credit360.ExportImport.Export.Batched.Exporters.CmsExporter');
	INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (44, 'Forecasting Slot export', 'Credit360.ExportImport.Export.Batched.Exporters.ForecastingScenarioExporter');
	INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (45, 'Delegation translations', 'Credit360.ExportImport.Export.Batched.Exporters.DelegationTranslationExporter');
	INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (46, 'Filter list export', 'Credit360.ExportImport.Export.Batched.Exporters.FilterListExcelExport');
	INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (59, 'Product Type Exporter', 'Credit360.ExportImport.Export.Batched.Exporters.ProductTypeExporter');
	INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (62, 'Product type translation export', 'Credit360.ExportImport.Export.Batched.Exporters.ProductTypeTranslationExporter');
	INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (64, 'Product description translation export', 'Credit360.ExportImport.Export.Batched.Exporters.ProductDescriptionTranslationExporter');
	INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (71, 'Category translation export', 'Credit360.ExportImport.Export.Batched.Exporters.CategoryTranslationExporter');
	INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (72, 'Tag translation export', 'Credit360.ExportImport.Export.Batched.Exporters.TagTranslationExporter');
	INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (74, 'Tag explanation translation export', 'Credit360.ExportImport.Export.Batched.Exporters.TagExplanationTranslationExporter');
	INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (78, 'Region mapping export', 'Credit360.ExportImport.Export.Batched.Exporters.Mappings.RegionMappingExporter');
	INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (79, 'Indicator mapping export', 'Credit360.ExportImport.Export.Batched.Exporters.Mappings.IndicatorMappingExporter');
	INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (80, 'Measure mapping export', 'Credit360.ExportImport.Export.Batched.Exporters.Mappings.MeasureMappingExporter');
	INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (83, 'Indicator validation rules export', 'Credit360.ExportImport.Export.Batched.Exporters.IndicatorValidationRulesExporter');
	INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (85, 'OSHA Export', 'Credit360.ExportImport.Export.Batched.Exporters.OshaBatchExporter');
	INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (86, 'OSHA Zipped Export', 'Credit360.ExportImport.Export.Batched.Exporters.OshaZippedBatchExporter');
	INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (87, 'Indicator selections translation export', 'Credit360.ExportImport.Export.Batched.Exporters.IndicatorSelectionsTranslationExporter');
	INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (90, 'Compliance item export', 'Credit360.ExportImport.Export.Batched.Exporters.ComplianceItemExporter');
	INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (91, 'Compliance item variant export', 'Credit360.ExportImport.Export.Batched.Exporters.ComplianceItemVariantExporter');
	INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (92, 'Delegation Plan Status export', 'Credit360.ExportImport.Export.Batched.Exporters.DelegPlanStatusExporter');
	INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (93, 'Reporting point export', 'Credit360.ExportImport.Export.Batched.Exporters.ReportingPointExporter');
	INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (94, 'Alert bounce export', 'Credit360.ExportImport.Export.Batched.Exporters.AlertBounceExporter');
END;
/

BEGIN
	INSERT INTO csr.batched_import_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (47, 'Indicator translations import', 'Credit360.ExportImport.Import.Batched.Importers.Translations.IndicatorTranslationImporter');
	INSERT INTO csr.batched_import_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (48, 'Region translations import', 'Credit360.ExportImport.Import.Batched.Importers.Translations.RegionTranslationImporter');
	INSERT INTO csr.batched_import_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (49, 'Delegation translations import', 'Credit360.ExportImport.Import.Batched.Importers.Translations.DelegationTranslationImporter');
	INSERT INTO csr.batched_import_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (50, 'Meter readings import', 'Credit360.ExportImport.Batched.Import.Importers.MeterReadingsImporter');
	INSERT INTO csr.batched_import_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (51, 'Forecasting Slot import', 'Credit360.ExportImport.Import.Batched.Importers.ForecastingScenarioImporter');
	INSERT INTO csr.batched_import_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (52, 'Factor set import', 'Credit360.ExportImport.Import.Batched.Importers.FactorSetImporter');
	INSERT INTO csr.batched_import_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (63, 'Product type translation import', 'Credit360.ExportImport.Import.Batched.Importers.Translations.ProductTypeTranslationImporter');
	INSERT INTO csr.batched_import_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (65, 'Product description translation import', 'Credit360.ExportImport.Import.Batched.Importers.Translations.ProductDescriptionTranslationImporter');
	INSERT INTO csr.batched_import_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (66, 'Permit module types import', 'Credit360.ExportImport.Batched.Import.Importers.PermitModuleTypesImporter');
	INSERT INTO csr.batched_import_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (67, 'Permits import', 'Credit360.ExportImport.Batched.Import.Importers.PermitsImporter');
	INSERT INTO csr.batched_import_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (68, 'Conditions import', 'Credit360.ExportImport.Batched.Import.Importers.ConditionsImporter');
	INSERT INTO csr.batched_import_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (69, 'Category translation import', 'Credit360.ExportImport.Import.Batched.Importers.Translations.CategoryTranslationImporter');
	INSERT INTO csr.batched_import_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (70, 'Tag translation import', 'Credit360.ExportImport.Import.Batched.Importers.Translations.TagTranslationImporter');
	INSERT INTO csr.batched_import_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (73, 'Tag explanation translation import', 'Credit360.ExportImport.Import.Batched.Importers.Translations.TagExplanationTranslationImporter');
	INSERT INTO csr.batched_import_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (75, 'Region mapping import', 'Credit360.ExportImport.Import.Batched.Importers.Mappings.RegionMappingImporter');
	INSERT INTO csr.batched_import_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (76, 'Indicator mapping import', 'Credit360.ExportImport.Import.Batched.Importers.Mappings.IndicatorMappingImporter');
	INSERT INTO csr.batched_import_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (77, 'Measure mapping import', 'Credit360.ExportImport.Import.Batched.Importers.Mappings.MeasureMappingImporter');
	INSERT INTO csr.batched_import_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (82, 'Compliance item import', 'Credit360.ExportImport.Batched.Import.Importers.ComplianceItemImporter');
	INSERT INTO csr.batched_import_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (88, 'Indicator selections translations import', 'Credit360.ExportImport.Import.Batched.Importers.Translations.IndicatorSelectionsTranslationImporter');
	INSERT INTO csr.batched_import_type (batch_job_type_id, label, assembly)
	VALUES (89, 'Compliance variant import', 'Credit360.ExportImport.Batched.Import.Importers.ComplianceVariantImporter');
	INSERT INTO csr.batched_import_type (batch_job_type_id, label, assembly)
	VALUES (95, 'Emission Profile import', 'Credit360.ExportImport.Import.Batched.Importers.EmissionProfileImporter');
END;
/

BEGIN
	INSERT INTO csr.country_group (country_group_id, group_name) VALUES ('ase', 'ASEAN (Association of Southeast Asian Nations)');
	INSERT INTO csr.country_group (country_group_id, group_name) VALUES ('eu', 'European Union');
	INSERT INTO csr.country_group (country_group_id, group_name) VALUES ('gcc', 'GCC (Gulf Cooperation Council)');
	INSERT INTO csr.country_group (country_group_id, group_name) VALUES ('iae', 'IAEA (International Atomic Energy Agency)');
	INSERT INTO csr.country_group (country_group_id, group_name) VALUES ('iar', 'IARC (International Agency for Research on Cancer)');
	INSERT INTO csr.country_group (country_group_id, group_name) VALUES ('ica', 'ICAO (International Civil Aviation Organization)');
	INSERT INTO csr.country_group (country_group_id, group_name) VALUES ('ifc', 'IFCS (International Finance Coroporation)');
	INSERT INTO csr.country_group (country_group_id, group_name) VALUES ('ilo', 'ILO (Internation Labour Organization)');
	INSERT INTO csr.country_group (country_group_id, group_name) VALUES ('imo', 'IMO (International Maritime Organization)');
	INSERT INTO csr.country_group (country_group_id, group_name) VALUES ('irp', 'IPPC (International Plant Protection Convention)');
	INSERT INTO csr.country_group (country_group_id, group_name) VALUES ('iso', 'ISO (International Organization for Standardization)');
	INSERT INTO csr.country_group (country_group_id, group_name) VALUES ('mer', 'Mercosur');
	INSERT INTO csr.country_group (country_group_id, group_name) VALUES ('naf', 'NAFTA (North American Free Trade Agreement)');
	INSERT INTO csr.country_group (country_group_id, group_name) VALUES ('oce', 'OECD (Organisation for Economic Co-operation and Development)');
	INSERT INTO csr.country_group (country_group_id, group_name) VALUES ('opc', 'OPCW (Organisation for the Prohibition of Chemical Weapons)');
	INSERT INTO csr.country_group (country_group_id, group_name) VALUES ('osp', 'OSPAR (Convention for the Protection of the Marine Environment of the North-East Atlantic )');
	INSERT INTO csr.country_group (country_group_id, group_name) VALUES ('oti', 'OTIF (Intergovernmental Organisation for International Carriage by Rail)');
	INSERT INTO csr.country_group (country_group_id, group_name) VALUES ('una', 'UNASUR (Union of South American Nations)');
	INSERT INTO csr.country_group (country_group_id, group_name) VALUES ('une', 'UNECE (United Nations Economic Commission for Europe)');
	INSERT INTO csr.country_group (country_group_id, group_name) VALUES ('unp', 'UNEP (United Nations Environment Programme)');
	INSERT INTO csr.country_group (country_group_id, group_name) VALUES ('unc', 'UNFCCC (United Nations Framework Convention on Climate Change)');
	INSERT INTO csr.country_group (country_group_id, group_name) VALUES ('und', 'UNIDO (United Nations Industrial Development Organization)');
	INSERT INTO csr.country_group (country_group_id, group_name) VALUES ('unt', 'UNITAR (United Nations Institute for Training and Research)');
	INSERT INTO csr.country_group (country_group_id, group_name) VALUES ('who', 'WHO (World Health Organisation)');
END;
/

BEGIN
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ase', 'bn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ase', 'id');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ase', 'kh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ase', 'la');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ase', 'mm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ase', 'my');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ase', 'ph');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ase', 'sg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ase', 'th');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ase', 'vn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'at');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'be');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'bg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'cy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'cz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'de');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'dk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'ee');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'es');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'fi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'fr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'gb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'gr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'hr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'hu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'ie');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'it');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'lt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'lu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'lv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'mt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'nl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'pl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'pt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'ro');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'se');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'si');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('eu ', 'sk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('gcc', 'ae');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('gcc', 'bh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('gcc', 'kw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('gcc', 'om');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('gcc', 'qa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('gcc', 'sa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ae');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'af');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ag');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'al');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'am');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ao');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ar');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'at');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'au');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'az');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ba');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'bb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'bd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'be');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'bf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'bg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'bh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'bi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'bj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'bn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'bo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'br');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'bs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'bw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'by');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'bz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ca');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'cd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'cf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'cg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ch');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ci');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'cl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'cm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'cn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'co');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'cr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'cu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'cy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'cz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'de');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'dj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'dk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'dm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'do');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'dz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ec');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ee');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'eg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'er');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'es');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'et');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'fi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'fj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'fr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ga');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'gb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ge');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'gh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'gr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'gt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'gy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'hn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'hr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ht');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'hu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'id');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ie');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'il');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'in');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'iq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ir');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'is');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'it');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'jm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'jo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'jp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ke');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'kg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'kh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'kr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'kw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'kz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'la');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'lb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'li');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'lk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'lr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ls');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'lt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'lu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'lv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ly');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ma');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'mc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'md');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'me');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'mg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'mh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'mk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ml');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'mm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'mn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'mr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'mt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'mu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'mw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'mx');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'my');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'mz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'na');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ne');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ng');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ni');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'nl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'no');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'np');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'nz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'om');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'pa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'pe');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'pg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ph');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'pk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'pl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'pt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'pw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'py');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'qa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ro');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'rs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ru');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'rw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'sa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'sc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'sd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'se');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'sg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'si');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'sk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'sl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'sm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'sn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'sv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'sy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'sz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'td');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'tg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'th');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'tj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'tm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'tn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'tr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'tt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'tz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ua');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ug');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'us');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'uy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'uz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'va');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 've');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'vn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'vu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'ye');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'za');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'zm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iae', 'zw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'at');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'au');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'be');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'br');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'ca');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'ch');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'de');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'dk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'es');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'fi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'fr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'gb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'ie');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'in');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'it');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'jp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'kr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'ma');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'nl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'no');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'qa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'ru');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'se');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'tr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iar', 'us');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ad');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ae');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'af');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ag');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'al');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'am');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ao');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ar');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'at');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'au');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'az');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ba');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'bb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'bd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'be');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'bf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'bg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'bh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'bi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'bj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'bn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'bo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'br');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'bs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'bt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'bw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'by');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'bz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ca');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'cd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'cf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'cg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ch');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ci');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ck');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'cl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'cm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'cn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'co');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'cr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'cu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'cv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'cy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'cz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'de');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'dj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'dk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'do');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'dz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ec');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ee');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'eg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'er');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'es');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'et');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'fi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'fj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'fm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'fr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ga');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'gb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'gd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ge');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'gh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'gm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'gn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'gq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'gr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'gt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'gw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'gy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'hn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'hr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ht');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'hu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'id');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ie');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'il');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'in');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'iq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ir');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'is');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'it');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'jm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'jo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'jp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ke');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'kg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'kh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ki');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'km');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'kn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'kp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'kr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'kw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'kz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'la');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'lb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'lc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'lk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'lr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ls');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'lt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'lu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'lv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ly');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ma');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'mc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'md');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'me');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'mg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'mh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'mk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ml');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'mm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'mn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'mr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'mt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'mu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'mv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'mw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'mx');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'my');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'mz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'na');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ne');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ng');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ni');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'nl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'no');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'np');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'nr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'nz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'om');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'pa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'pe');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'pg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ph');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'pk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'pl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'pt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'pw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'py');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'qa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ro');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'rs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ru');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'rw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'sa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'sb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'sc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'sd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'se');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'sg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'si');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'sk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'sl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'sm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'sn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'so');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'sr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ss');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'st');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'sv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'sy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'sz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'td');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'tg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'th');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'tj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'tl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'tm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'tn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'to');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'tr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'tt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'tz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ua');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ug');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'us');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'uy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'uz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'vc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 've');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'vn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'vu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ws');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'ye');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'za');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'zm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ica', 'zw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ae');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'af');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ag');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'al');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'am');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ao');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ar');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'at');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'au');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'az');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ba');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'bb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'bd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'be');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'bf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'bg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'bi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'bj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'bo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'br');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'bs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'bt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'bw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'by');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'bz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ca');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'cd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'cf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'cg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ch');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ci');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'cl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'cm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'cn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'co');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'cr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'cv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'cy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'cz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'de');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'dj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'dk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'dm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'do');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'dz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ec');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ee');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'eg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'er');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'es');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'et');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'fi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'fj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'fm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'fr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ga');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'gb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'gd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ge');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'gh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'gm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'gn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'gq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'gr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'gt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'gw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'gy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'hn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'hr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ht');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'hu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'id');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ie');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'il');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'in');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'iq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ir');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'is');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'it');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'jm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'jo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'jp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ke');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'kg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'kh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ki');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'km');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'kn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'kr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'kw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'kz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'la');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'lb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'lc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'lk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'lr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ls');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'lt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'lu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'lv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ly');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ma');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'md');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'me');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'mg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'mh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'mk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ml');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'mm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'mn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'mr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'mt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'mu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'mv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'mw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'mx');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'my');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'mz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'na');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ne');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ng');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ni');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'nl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'no');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'np');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'nz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'om');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'pa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'pe');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'pg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ph');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'pk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'pl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'pw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'py');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'qa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ro');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'rs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ru');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'rw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'sa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'sb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'sc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'sd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'se');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'sg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'si');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'sk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'sl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'sn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'so');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'sr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ss');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'st');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'sv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'sy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'sz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'td');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'tg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'th');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'tj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'tl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'tm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'tn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'to');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'tr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'tt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'tz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ua');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ug');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'us');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'uy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'uz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 've');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'vn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'vu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ws');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'xk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'ye');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'za');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'zm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ifc', 'zw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ae');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'af');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ag');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'al');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'am');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ao');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ar');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'at');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'au');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'az');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ba');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'bb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'bd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'be');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'bf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'bg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'bh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'bi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'bj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'bn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'bo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'br');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'bs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'bw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'by');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'bz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ca');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'cd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'cf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'cg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ch');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ci');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ck');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'cl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'cm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'cn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'co');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'cr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'cu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'cv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'cy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'cz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'de');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'dj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'dk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'dm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'do');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'dz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ec');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ee');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'eg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'er');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'es');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'et');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'fi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'fj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'fr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ga');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'gb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'gd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ge');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'gh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'gm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'gn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'gq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'gr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'gt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'gw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'gy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'hn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'hr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ht');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'hu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'id');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ie');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'il');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'in');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'iq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ir');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'is');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'it');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'jm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'jo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'jp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ke');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'kg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'kh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ki');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'km');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'kn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'kr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'kw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'kz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'la');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'lb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'lc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'lk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'lr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ls');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'lt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'lu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'lv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ly');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ma');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'md');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'me');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'mg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'mh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'mk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ml');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'mm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'mn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'mr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'mt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'mu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'mv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'mw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'mx');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'my');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'mz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'na');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ne');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ng');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ni');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'nl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'no');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'np');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'nz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'om');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'pa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'pe');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'pg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ph');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'pk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'pl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'pt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'pw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'py');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'qa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ro');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'rs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ru');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'rw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'sa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'sb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'sc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'sd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'se');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'sg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'si');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'sk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'sl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'sm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'sn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'so');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'sr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ss');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'st');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'sv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'sy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'sz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'td');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'tg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'th');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'tj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'tl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'tm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'tn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'to');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'tr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'tt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'tv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'tz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ua');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ug');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'us');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'uy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'uz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'vc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 've');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'vn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'vu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ws');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'ye');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'za');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'zm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('ilo', 'zw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ae');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ag');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'al');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ao');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ar');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'at');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'au');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'az');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ba');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'bb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'bd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'be');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'bg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'bh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'bj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'bn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'bo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'br');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'bs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'bz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ca');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'cd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'cg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ch');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ci');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ck');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'cl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'cm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'cn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'co');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'cr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'cu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'cv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'cy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'cz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'de');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'dj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'dk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'do');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'dz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ec');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ee');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'eg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'er');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'es');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'et');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'fi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'fj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'fr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ga');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'gb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'gd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ge');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'gh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'gm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'gn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'gq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'gr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'gt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'gw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'gy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'hn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'hr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ht');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'hu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'id');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ie');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'il');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'in');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'iq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ir');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'is');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'it');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'jm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'jo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'jp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ke');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'kh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ki');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'km');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'kn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'kp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'kr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'kw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'kz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'lb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'lc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'lk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'lr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'lt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'lu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'lv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ly');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ma');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'mc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'md');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'me');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'mg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'mh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'mk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'mm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'mn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'mr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'mt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'mu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'mv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'mw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'mx');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'my');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'mz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'na');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ng');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ni');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'nl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'no');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'np');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'nz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'om');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'pa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'pe');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'pg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ph');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'pk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'pl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'pt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'pw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'py');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'qa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ro');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'rs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ru');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'sa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'sb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'sc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'sd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'se');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'sg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'si');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'sk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'sl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'sm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'sn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'so');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'sr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'st');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'sv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'sy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'tg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'th');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'tl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'tm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'tn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'to');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'tr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'tt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'tv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'tz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ua');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ug');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'us');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'uy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'vc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 've');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'vn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'vu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ws');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'ye');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'za');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'zm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('imo', 'zw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ad');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ae');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'af');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ag');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ai');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'al');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'am');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ao');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ar');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'as');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'at');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'au');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'az');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ba');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'bb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'bd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'bf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'bg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'bh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'bi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'bj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'bm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'bn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'bo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'br');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'bs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'bt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'bw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'by');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'bz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ca');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'cd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'cf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'cg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ch');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ci');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ck');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'cl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'cm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'cn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'co');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'cr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'cu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'cv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'cy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'cz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'de');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'dj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'dk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'dm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'do');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'dz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ec');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ee');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'eg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ep');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'er');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'es');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'et');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'fi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'fj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'fm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'fr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ga');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'gb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'gd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ge');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'gf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'gg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'gh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'gm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'gn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'gp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'gq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'gr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'gt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'gu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'gw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'gy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'hn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'hr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ht');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'hu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'id');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ie');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'il');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'in');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'iq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ir');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'is');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'it');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'je');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'jm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'jo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'jp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ke');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'kg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'kh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ki');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'km');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'kn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'kp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'kr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'kw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ky');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'kz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'la');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'lb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'lc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'li');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'lk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'lr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ls');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'lt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'lu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'lv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ly');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ma');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'mc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'md');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'me');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'mg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'mh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'mk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ml');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'mm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'mn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'mp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'mq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'mr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ms');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'mt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'mu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'mv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'mw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'mx');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'my');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'mz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'na');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'nc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ne');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ng');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ni');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'nl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'no');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'np');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'nu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'nz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'om');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'pa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'pe');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'pf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'pg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ph');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'pk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'pl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'pr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'pt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'pw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'py');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'qa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 're');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ro');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'rs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ru');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'rw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'sa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'sb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'sc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'sd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'se');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'sg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'si');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'sk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'sl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'sm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'sn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'so');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'sr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ss');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'st');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'sv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'sy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'sz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'tc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'td');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'tg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'th');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'tj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'tk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'tl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'tm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'tn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'to');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'tr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'tt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'tv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'tz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ua');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ug');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'us');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'uy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'uz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'vc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 've');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'vg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'vi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'vn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'vu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ws');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'ye');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'yt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'za');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'zm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('irp', 'zw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ae');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'af');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ag');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'al');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'am');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ao');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ar');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'at');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'au');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'az');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ba');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'bb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'bd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'be');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'bf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'bg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'bh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'bi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'bj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'bn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'bo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'br');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'bs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'bt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'bw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'by');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'bz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ca');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'cd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ch');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ci');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'cl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'cm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'cn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'co');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'cr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'cu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'cy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'cz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'de');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'dk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'dm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'do');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'dz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ec');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ee');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'eg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'er');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'es');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'et');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'fi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'fj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'fr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ga');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'gb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ge');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'gh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'gm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'gr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'gt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'gy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'hk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'hn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'hr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ht');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'hu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'id');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ie');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'il');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'in');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'iq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ir');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'is');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'it');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'jm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'jo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'jp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ke');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'kg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'kh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'kn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'kp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'kr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'kw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'kz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'la');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'lb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'lc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'lk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ls');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'lt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'lu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'lv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ly');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ma');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'md');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'me');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'mg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'mk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ml');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'mm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'mn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'mo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'mr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'mt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'mu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'mw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'mx');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'my');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'mz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'na');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ne');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ng');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ni');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'nl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'no');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'np');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'nz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'om');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'pa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'pe');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'pg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ph');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'pk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'pl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'pt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'py');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'qa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ro');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'rs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ru');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'rw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'sa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'sc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'sd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'se');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'sg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'si');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'sk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'sl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'sn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'sr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'sv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'sz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'th');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'tj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'tm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'tn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'tr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'tt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'tz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ua');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ug');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'us');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'uy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'uz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'vc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'vn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'ye');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'za');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'zm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('iso', 'zw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('mer', 'ar');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('mer', 'bo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('mer', 'br');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('mer', 'cl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('mer', 'co');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('mer', 'ec');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('mer', 'mx');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('mer', 'nz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('mer', 'pe');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('mer', 'py');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('mer', 'uy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('mer', 've');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('naf', 'ca');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('naf', 'mx');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('naf', 'us');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'at');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'au');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'be');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'ca');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'ch');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'cl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'cz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'de');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'dk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'ee');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'es');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'fi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'fr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'gb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'gr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'hu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'ie');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'il');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'is');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'it');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'jp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'kr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'lu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'lv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'mx');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'nl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'no');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'nz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'pl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'pt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'se');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'si');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'sk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'tr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oce', 'us');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ad');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ae');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'af');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ag');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'al');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'am');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ao');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ar');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'at');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'au');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'az');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ba');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'bb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'bd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'be');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'bf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'bg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'bh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'bi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'bj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'bn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'bo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'br');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'bs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'bt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'bw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'by');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'bz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ca');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'cf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'cg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ch');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ci');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ck');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'cl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'cm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'cn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'co');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'cr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'cu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'cv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'cy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'cz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'de');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'dj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'dk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'dm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'do');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'dz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ec');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ee');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'er');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'es');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'et');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'fi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'fj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'fm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'fr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ga');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'gb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'gd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ge');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'gh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'gm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'gn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'gq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'gr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'gt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'gw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'gy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'hn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'hr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ht');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'hu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'id');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ie');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'in');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'iq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ir');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'is');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'it');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'jm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'jo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'jp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ke');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'kg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'kh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ki');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'km');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'kn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'kr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'kw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'kz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'la');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'lb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'lc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'li');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'lk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'lr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ls');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'lt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'lu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'lv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ly');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ma');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'mc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'md');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'me');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'mg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'mh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'mk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ml');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'mm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'mn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'mr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'mt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'mu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'mv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'mw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'mx');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'my');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'mz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'na');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ne');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ng');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ni');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'nl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'no');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'np');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'nr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'nu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'nz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'om');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'pa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'pe');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'pg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ph');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'pk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'pl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'pt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'pw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'py');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'qa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ro');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'rs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ru');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'rw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'sa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'sb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'sc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'sd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'se');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'sg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'si');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'sk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'sl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'sm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'sn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'so');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'sr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'st');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'sv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'sy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'sz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'td');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'tg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'th');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'tj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'tl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'tm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'tn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'to');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'tr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'tt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'tv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'tz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ua');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ug');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'us');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'uy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'uz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'va');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'vc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 've');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'vn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'vu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ws');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'ye');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'za');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'zm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('opc', 'zw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('osp', 'be');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('osp', 'ch');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('osp', 'de');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('osp', 'dk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('osp', 'ep');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('osp', 'es');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('osp', 'fi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('osp', 'fr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('osp', 'gb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('osp', 'ie');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('osp', 'is');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('osp', 'lu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('osp', 'nl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('osp', 'no');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('osp', 'pt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('osp', 'se');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'al');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'am');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'at');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'az');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'ba');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'be');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'bg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'ch');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'cz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'de');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'dk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'dz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'ee');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'es');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'fi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'fr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'gb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'ge');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'gr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'hr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'hu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'ie');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'iq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'ir');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'it');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'jo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'lb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'li');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'lt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'lu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'lv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'ma');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'mc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'me');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'mk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'nl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'no');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'pk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'pl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'pt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'ro');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'rs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'ru');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'se');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'si');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'sk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'sy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'tn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'tr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('oti', 'ua');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('una', 'ar');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('una', 'bo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('una', 'br');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('una', 'cl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('una', 'co');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('una', 'ec');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('una', 'gy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('una', 'mx');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('una', 'pa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('una', 'pe');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('una', 'py');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('una', 'sr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('una', 'uy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('una', 've');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ad');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ae');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'af');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ag');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'al');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'am');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ao');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ar');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'at');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'au');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'az');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ba');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'bb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'bd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'be');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'bf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'bg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'bh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'bi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'bj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'bn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'bo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'br');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'bs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'bt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'bw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'by');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'bz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ca');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'cd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'cf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'cg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ch');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ci');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ck');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'cl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'cm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'cn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'co');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'cr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'cu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'cv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'cy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'cz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'de');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'dj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'dk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'dm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'do');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'dz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ec');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ee');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'eg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ep');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'er');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'es');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'et');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'fi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'fj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'fm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'fr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ga');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'gb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'gd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ge');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'gh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'gm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'gn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'gq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'gr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'gt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'gw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'gy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'hn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'hr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ht');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'hu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'id');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ie');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'il');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'in');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'iq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ir');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'is');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'it');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'jm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'jo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'jp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ke');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'kg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'kh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ki');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'km');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'kn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'kp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'kr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'kw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'kz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'la');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'lb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'lc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'li');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'lk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'lr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ls');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'lt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'lu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'lv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ly');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ma');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'mc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'md');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'me');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'mg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'mh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'mk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ml');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'mm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'mn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'mr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'mt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'mu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'mv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'mw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'mx');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'my');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'mz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'na');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ne');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ng');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ni');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'nl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'no');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'np');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'nr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'nu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'nz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'om');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'pa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'pe');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'pg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ph');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'pk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'pl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'pt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'pw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'py');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'qa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ro');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'rs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ru');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'rw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'sa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'sb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'sc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'sd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'se');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'sg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'si');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'sk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'sl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'sm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'sn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'so');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'sr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ss');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'st');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'sv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'sy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'sz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'td');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'tg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'th');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'tj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'tl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'tm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'tn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'to');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'tr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'tt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'tv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'tz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ua');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ug');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'us');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'uy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'uz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'vc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 've');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'vn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'vu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ws');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'ye');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'za');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'zm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unc', 'zw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ae');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'af');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'al');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'am');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ao');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ar');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'at');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'az');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ba');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'bb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'bd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'bf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'bg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'bh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'bi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'bj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'bo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'br');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'bs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'bt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'bw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'by');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'bz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'cd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'cf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'cg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ch');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ci');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'cl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'cm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'cn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'co');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'cr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'cu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'cv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'cy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'cz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'de');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'dj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'dk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'dm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'do');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'dz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ec');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'eg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'er');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'es');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'et');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'fi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'fj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ga');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'gd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ge');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'gh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'gm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'gn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'gq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'gr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'gt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'gw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'gy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'hn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'hr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ht');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'hu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'id');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ie');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'il');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'in');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'iq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ir');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'it');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'jm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'jo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'jp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ke');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'kg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'kh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ki');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'km');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'kn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'kp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'kr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'kw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'kz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'la');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'lb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'lc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'lk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'lr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ls');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'lu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ly');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ma');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'mc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'md');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'me');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'mg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'mh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'mk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ml');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'mm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'mn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'mr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'mt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'mu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'mv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'mw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'mx');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'my');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'mz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'na');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ne');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ng');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ni');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'nl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'no');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'np');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'om');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'pa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'pe');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'pg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ph');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'pk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'pl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'py');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'qa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ro');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'rs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ru');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'rw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'sa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'sc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'sd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'se');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'si');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'sk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'sl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'sn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'so');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'sr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'st');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'sv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'sy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'sz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'td');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'tg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'th');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'tj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'tl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'tm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'tn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'to');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'tr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'tt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'tv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'tz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ua');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ug');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'uy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'uz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'vc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 've');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'vn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'vu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ws');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'ye');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'za');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'zm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('und', 'zw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'ad');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'al');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'am');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'at');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'az');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'ba');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'be');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'bg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'by');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'ca');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'ch');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'cy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'cz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'de');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'dk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'ee');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'es');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'fi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'fr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'gb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'ge');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'gr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'hr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'hu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'ie');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'il');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'is');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'it');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'kg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'kz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'li');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'lt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'lu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'lv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'mc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'md');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'me');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'mk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'mt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'nl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'no');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'pl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'pt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'ro');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'rs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'ru');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'se');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'si');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'sk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'sm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'tj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'tm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'tr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'ua');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'us');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('une', 'uz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ad');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ae');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'af');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ag');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'al');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'am');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ao');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ar');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'at');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'au');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'az');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ba');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'bb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'bd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'be');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'bf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'bg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'bh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'bi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'bj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'bn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'bo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'br');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'bs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'bt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'bw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'by');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'bz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ca');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'cd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'cf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'cg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ch');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ci');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'cl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'cm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'cn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'co');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'cr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'cu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'cv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'cy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'cz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'de');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'dj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'dk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'dm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'do');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'dz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ec');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ee');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'eg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'er');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'es');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'et');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'fi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'fj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'fm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'fr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ga');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'gb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'gd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ge');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'gh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'gm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'gn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'gq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'gr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'gt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'gw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'gy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'hn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'hr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ht');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'hu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'id');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ie');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'il');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'in');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'iq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ir');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'is');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'it');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'jm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'jo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'jp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ke');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'kg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'kh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ki');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'km');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'kn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'kp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'kr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'kw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'kz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'la');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'lb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'lc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'li');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'lk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'lr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ls');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'lt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'lu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'lv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ly');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ma');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'mc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'md');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'me');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'mg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'mh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'mk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ml');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'mm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'mn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'mr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'mt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'mu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'mv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'mw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'mx');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'my');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'mz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'na');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ne');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ng');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ni');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'nl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'no');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'np');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'nr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'nz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'om');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'pa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'pe');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'pg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ph');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'pk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'pl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'pt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'pw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'py');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'qa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ro');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'rs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ru');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'rw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'sa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'sb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'sc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'sd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'se');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'sg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'si');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'sk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'sl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'sm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'sn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'so');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'sr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ss');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'st');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'sv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'sy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'sz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'td');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'tg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'th');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'tj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'tl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'tm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'tn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'to');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'tr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'tt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'tv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'tz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ua');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ug');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'us');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'uy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'uz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'vc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 've');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'vn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'vu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ws');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'ye');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'za');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'zm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unp', 'zw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ad');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ae');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'af');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ag');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'al');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'am');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ao');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ar');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'at');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'au');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'az');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ba');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'bb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'bd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'be');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'bf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'bg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'bh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'bi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'bj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'bn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'bo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'br');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'bs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'bt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'bw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'by');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'bz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ca');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'cd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'cf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'cg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ch');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ci');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'cl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'cm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'cn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'co');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'cr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'cu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'cv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'cy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'cz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'de');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'dj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'dk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'dm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'do');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'dz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ec');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ee');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'eg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'er');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'es');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'et');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'fi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'fj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'fm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'fr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ga');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'gb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'gd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ge');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'gh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'gm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'gn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'gq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'gr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'gt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'gw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'gy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'hn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'hr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ht');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'hu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'id');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ie');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'il');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'in');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'iq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ir');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'is');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'it');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'jm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'jo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'jp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ke');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'kg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'kh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ki');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'km');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'kn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'kp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'kr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'kw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'kz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'la');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'lb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'lc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'li');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'lk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'lr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ls');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'lt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'lu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'lv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ly');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ma');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'mc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'md');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'me');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'mg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'mh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'mk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ml');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'mm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'mn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'mr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'mt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'mu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'mv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'mw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'mx');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'my');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'mz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'na');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ne');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ng');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ni');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'nl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'no');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'np');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'nr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'nz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'om');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'pa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'pe');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'pg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ph');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'pk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'pl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'pt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'pw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'py');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'qa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ro');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'rs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ru');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'rw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'sa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'sb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'sc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'sd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'se');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'sg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'si');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'sk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'sl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'sm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'sn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'so');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'sr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ss');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'st');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'sv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'sy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'sz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'td');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'tg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'th');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'tj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'tl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'tm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'tn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'to');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'tr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'tt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'tv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'tz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ua');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ug');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'us');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'uy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'uz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'vc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 've');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'vn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'vu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ws');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'ye');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'za');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'zm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('unt', 'zw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ad');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ae');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'af');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ag');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'al');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'am');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ao');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ar');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'at');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'au');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'az');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ba');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'bb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'bd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'be');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'bf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'bg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'bh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'bi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'bj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'bn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'bo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'br');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'bs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'bt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'bw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'by');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'bz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ca');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'cd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'cf');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'cg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ch');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ci');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ck');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'cl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'cm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'cn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'co');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'cr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'cu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'cv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'cy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'cz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'de');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'dj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'dk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'dm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'do');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'dz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ec');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ee');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'eg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'er');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'es');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'et');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'fi');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'fj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'fm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'fr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ga');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'gb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'gd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ge');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'gh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'gm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'gn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'gq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'gr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'gt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'gw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'gy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'hn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'hr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ht');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'hu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'id');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ie');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'il');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'in');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'iq');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ir');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'is');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'it');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'jm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'jo');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'jp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ke');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'kg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'kh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ki');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'km');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'kn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'kp');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'kr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'kw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'kz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'la');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'lb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'lc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'lk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'lr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ls');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'lt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'lu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'lv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ly');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ma');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'mc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'md');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'me');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'mg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'mh');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'mk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ml');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'mm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'mn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'mr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'mt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'mu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'mv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'mw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'mx');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'my');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'mz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'na');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ne');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ng');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ni');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'nl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'no');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'np');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'nr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'nu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'nz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'om');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'pa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'pe');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'pg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ph');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'pk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'pl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'pt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'pw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'py');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'qa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ro');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'rs');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ru');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'rw');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'sa');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'sb');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'sc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'sd');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'se');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'sg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'si');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'sk');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'sl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'sm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'sn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'so');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'sr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ss');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'st');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'sv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'sy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'sz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'td');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'tg');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'th');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'tj');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'tl');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'tm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'tn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'to');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'tr');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'tt');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'tv');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'tz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ua');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ug');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'us');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'uy');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'uz');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'vc');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 've');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'vn');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'vu');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ws');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'ye');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'za');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'zm');
	INSERT INTO csr.country_group_country (country_group_id, country_id) VALUES ('who', 'zw');
END;
/

BEGIN
	INSERT INTO csr.tpl_report_reg_data_type(tpl_report_reg_data_type_id, description, pos, hide_if_properties_not_enabled, hide_if_metering_not_enabled)
		 VALUES ( 1, 'Fund', 1, 1, 0);
	INSERT INTO csr.tpl_report_reg_data_type(tpl_report_reg_data_type_id, description, pos, hide_if_properties_not_enabled, hide_if_metering_not_enabled)
		 VALUES ( 2, 'Management company', 2, 1, 0);
	INSERT INTO csr.tpl_report_reg_data_type(tpl_report_reg_data_type_id, description, pos, hide_if_properties_not_enabled, hide_if_metering_not_enabled)
		 VALUES ( 3, 'Management company contact', 3, 1, 0);
	INSERT INTO csr.tpl_report_reg_data_type(tpl_report_reg_data_type_id, description, pos, hide_if_properties_not_enabled, hide_if_metering_not_enabled)
		 VALUES ( 4, 'Meter number', 4, 0, 1);
	INSERT INTO csr.tpl_report_reg_data_type(tpl_report_reg_data_type_id, description, pos, hide_if_properties_not_enabled, hide_if_metering_not_enabled)
		 VALUES ( 5, 'Meter type', 5, 0, 1);
	INSERT INTO csr.tpl_report_reg_data_type(tpl_report_reg_data_type_id, description, pos, hide_if_properties_not_enabled, hide_if_metering_not_enabled)
		 VALUES ( 6, 'Property address', 6, 1, 0);
	INSERT INTO csr.tpl_report_reg_data_type(tpl_report_reg_data_type_id, description, pos, hide_if_properties_not_enabled, hide_if_metering_not_enabled)
		 VALUES ( 7, 'Property subtype', 7, 1, 0);
	INSERT INTO csr.tpl_report_reg_data_type(tpl_report_reg_data_type_id, description, pos, hide_if_properties_not_enabled, hide_if_metering_not_enabled)
		 VALUES ( 8, 'Property type', 8, 1, 0);
	INSERT INTO csr.tpl_report_reg_data_type(tpl_report_reg_data_type_id, description, pos, hide_if_properties_not_enabled, hide_if_metering_not_enabled)
		 VALUES ( 9, 'Region image', 9, 0, 0);
	INSERT INTO csr.tpl_report_reg_data_type(tpl_report_reg_data_type_id, description, pos, hide_if_properties_not_enabled, hide_if_metering_not_enabled)
		 VALUES (10, 'Region reference', 10, 0, 0);
END;
/

BEGIN
	INSERT INTO csr.INTERNAL_AUDIT_TYPE_SOURCE (INTERNAL_AUDIT_TYPE_SOURCE_ID, INTERNAL_AUDIT_TYPE_SOURCE)
		 VALUES (1, 'Internal');

	INSERT INTO csr.INTERNAL_AUDIT_TYPE_SOURCE (INTERNAL_AUDIT_TYPE_SOURCE_ID, INTERNAL_AUDIT_TYPE_SOURCE)
		 VALUES (2, 'External');

	INSERT INTO csr.INTERNAL_AUDIT_TYPE_SOURCE (INTERNAL_AUDIT_TYPE_SOURCE_ID, INTERNAL_AUDIT_TYPE_SOURCE)
		 VALUES (3, 'Integration');
END;
/

--Latest CoreDataImporter
BEGIN
	INSERT INTO csr.auto_imp_mapping_type (mapping_type_id, name) VALUES (0, 'Sid');
	INSERT INTO csr.auto_imp_mapping_type (mapping_type_id, name) VALUES (1, 'Lookup key');
	INSERT INTO csr.auto_imp_mapping_type (mapping_type_id, name) VALUES (2, 'Mapping table');
	INSERT INTO csr.auto_imp_mapping_type (mapping_type_id, name) VALUES (3, 'Description');

	INSERT INTO csr.auto_imp_date_type (date_type_id, name) VALUES (0, 'One col, one date');
	INSERT INTO csr.auto_imp_date_type (date_type_id, name) VALUES (1, 'One col, two dates');
	INSERT INTO csr.auto_imp_date_type (date_type_id, name) VALUES (2, 'Two cols, one date');
	INSERT INTO csr.auto_imp_date_type (date_type_id, name) VALUES (3, 'Two cols, two dates');

	INSERT INTO csr.auto_imp_date_col_type (date_col_type_id, name) VALUES (0, 'Year, eg 15 or 2015');
	INSERT INTO csr.auto_imp_date_col_type (date_col_type_id, name) VALUES (1, 'Month name, eg Aug or August');
	INSERT INTO csr.auto_imp_date_col_type (date_col_type_id, name) VALUES (2, 'Month index');
	INSERT INTO csr.auto_imp_date_col_type (date_col_type_id, name) VALUES (3, 'Financial year, eg FY15 or FY2015');
	INSERT INTO csr.auto_imp_date_col_type (date_col_type_id, name) VALUES (4, 'Date string, eg .net parsable');
	INSERT INTO csr.auto_imp_date_col_type (date_col_type_id, name) VALUES (5, 'App year, eg 15 or 2015');
	INSERT INTO csr.auto_imp_date_col_type (date_col_type_id, name) VALUES (6, 'Month and year, eg Aug 2015, August 2015 (or with 15)');
END;
/

--End Latest CoreDataImporter

BEGIN
	INSERT INTO csr.duff_meter_error_type (error_type_id, label) VALUES (1 /*DUFF_METER_GENERIC*/, 'Orphan meter data');
	INSERT INTO csr.duff_meter_error_type (error_type_id, label) VALUES (2 /*DUFF_METER_MATCH_SERIAL*/, 'Failed to match meter number');
	INSERT INTO csr.duff_meter_error_type (error_type_id, label) VALUES (3 /*DUFF_METER_MATCH_UOM*/, 'Failed to match UOM');
	INSERT INTO csr.duff_meter_error_type (error_type_id, label) VALUES (4 /*DUFF_METER_OVERLAP*/, 'Data has overlaps');
	INSERT INTO csr.duff_meter_error_type (error_type_id, label) VALUES (5 /*DUFF_METER_EXISTING_MISMATCH*/, 'Meter number mismatch');
	INSERT INTO csr.duff_meter_error_type (error_type_id, label) VALUES (6 /*DUFF_METER_PARENT_NOT_FOUND*/, 'Parent region not found');
	INSERT INTO csr.duff_meter_error_type (error_type_id, label) VALUES (7 /*DUFF_METER_HOLDING_NOT_FOUND*/, 'Holding region not found');
	INSERT INTO csr.duff_meter_error_type (error_type_id, label) VALUES (8 /*DUFF_METER_SVC_TYPE_NOT_FOUND*/, 'Service type not found');
	INSERT INTO csr.duff_meter_error_type (error_type_id, label) VALUES (9 /*DUFF_METER_SVC_TYPE_MISMATCH*/, 'Service type mismatch');
	INSERT INTO csr.duff_meter_error_type (error_type_id, label) VALUES (10 /*DUFF_METER_NOT_SET_UP*/, 'System not configured');
END;
/

BEGIN
	INSERT INTO csr.compliance_item_status (compliance_item_status_id, description, pos) VALUES (1, 'Draft', 1);
	INSERT INTO csr.compliance_item_status (compliance_item_status_id, description, pos) VALUES (2, 'Published', 2);
	INSERT INTO csr.compliance_item_status (compliance_item_status_id, description, pos) VALUES (3, 'Retired', 3);
	
	INSERT INTO csr.compliance_item_source (compliance_item_source_id, description) VALUES (0, 'User-defined');
	INSERT INTO csr.compliance_item_source (compliance_item_source_id, description) VALUES (1, 'Enhesa');
	
	
	INSERT INTO csr.compliance_item_change_type (compliance_item_change_type_id, description, source, change_type_index) VALUES (2, 'New development', 0, 2);
	INSERT INTO csr.compliance_item_change_type (compliance_item_change_type_id, description, source, change_type_index) VALUES (3, 'Explicit regulatory change', 0,3);
	INSERT INTO csr.compliance_item_change_type (compliance_item_change_type_id, description, source, change_type_index) VALUES (4, 'Repealing change', 0, 4);
	INSERT INTO csr.compliance_item_change_type (compliance_item_change_type_id, description, source, change_type_index) VALUES (5, 'Implicit regulatory change', 0, 5);
	INSERT INTO csr.compliance_item_change_type (compliance_item_change_type_id, description, source, change_type_index) VALUES (6, 'Editorial change that does not impact meaning', 0, 6);
	INSERT INTO csr.compliance_item_change_type (compliance_item_change_type_id, description, source, change_type_index) VALUES (1, 'No change',0, 1 );
	INSERT INTO csr.compliance_item_change_type (compliance_item_change_type_id, description, source, change_type_index) VALUES (7, 'Improved guidance / analysis', 0, 7);
	INSERT INTO csr.compliance_item_change_type (compliance_item_change_type_id, description, source, change_type_index, enhesa_id) VALUES (8, 'No change',1, 1, 0);
	INSERT INTO csr.compliance_item_change_type (compliance_item_change_type_id, description, source, change_type_index, enhesa_id) VALUES (9, 'New development', 1, 2, 1);
	INSERT INTO csr.compliance_item_change_type (compliance_item_change_type_id, description, source, change_type_index, enhesa_id) VALUES (10, 'Explicit regulatory change', 1, 3, 3);
	INSERT INTO csr.compliance_item_change_type (compliance_item_change_type_id, description, source, change_type_index, enhesa_id) VALUES (11, 'Repealing change', 1, 4, 4);
	INSERT INTO csr.compliance_item_change_type (compliance_item_change_type_id, description, source, change_type_index, enhesa_id) VALUES (12, 'Implicit regulatory change', 1, 5, 5);
	INSERT INTO csr.compliance_item_change_type (compliance_item_change_type_id, description, source, change_type_index, enhesa_id) VALUES (13, 'Editorial change that does not impact meaning', 1, 6, 6);	
	INSERT INTO csr.compliance_item_change_type (compliance_item_change_type_id, description, source, change_type_index, enhesa_id) VALUES (14, 'Improved guidance / analysis', 1, 7, 7);
	INSERT INTO csr.compliance_item_change_type (compliance_item_change_type_id, description, source, change_type_index) VALUES (15, 'Retired', 0, 8);
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'TP', 'East Timor', NULL, NULL, 'tl', NULL);
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'XB', 'KOREA,NORTH', NULL, NULL, 'kp', NULL);
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'KO', 'Kosovo', NULL, NULL, 'xk', NULL);
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'AT', 'AUSTRIA', 'WI', 'VIENNA', 'at', '09');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'DE', 'GERMANY', 'BY', 'BAVARIA', 'de', '02');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'BE', 'BELGIUM', 'BRU', 'BRUSSELS', 'be', '11');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'ZHE', 'ZHEJIANG', 'cn', '02');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'NL', 'NETHERLANDS', 'ZH', 'ZUID-HOLLAND', 'nl', '11');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CH', 'SWITZERLAND', 'ZH', 'ZURICH', 'ch', '25');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CH', 'SWITZERLAND', 'ZG', 'ZUG', 'ch', '24');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'NL', 'NETHERLANDS', 'ZE', 'ZEELAND', 'nl', '10');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'AR', 'ARGENTINA', 'Z', 'SANTA CRUZ', 'ar', '20');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'YN', 'YUNNAN', 'cn', '29');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'XZ', 'TIBET', 'cn', '14');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'XJ', 'XINJIANG UYGHUR', 'cn', '13');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'NA', 'NAMIBIA', 'WH', 'WINDHOEK', 'na', '21');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'ZA', 'SOUTH AFRICA', 'WC', 'WESTERN CAPE', 'za', '11');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'IN', 'INDIA', 'WB', 'WEST BENGAL', 'in', '28');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'AU', 'AUSTRALIA', 'WA', 'WESTERN AUSTRALIA', 'au', '08');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'AU', 'AUSTRALIA', 'VIC', 'VICTORIA', 'au', '07');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'MX', 'MEXICO', 'VER', 'VERACRUZ', 'mx', '30');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'IT', 'ITALY', 'VEN', 'VENETO', 'it', '20');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'NL', 'NETHERLANDS', 'UT', 'UTRECHT', 'nl', '09');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'IN', 'INDIA', 'UP', 'UTTAR PRADESH', 'in', '36');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'IT', 'ITALY', 'TUS', 'TUSCANY', 'it', '16');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'IN', 'INDIA', 'TN', 'TAMIL NADU', 'in', '25');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'MX', 'MEXICO', 'TLA', 'TLAXCALA', 'mx', '29');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'TIA', 'TIANJIN', 'cn', '28');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CH', 'SWITZERLAND', 'TI', 'TICINO', 'ch', '20');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'DE', 'GERMANY', 'TH', 'THURINGIA', 'de', '15');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CH', 'SWITZERLAND', 'TG', 'THURGAU', 'ch', '19');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'AU', 'AUSTRALIA', 'TAS', 'TASMANIA', 'au', '06');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'MX', 'MEXICO', 'TAM', 'TAMAULIPAS', 'mx', '28');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'MX', 'MEXICO', 'TAB', 'TABASCO', 'mx', '27');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'DE', 'GERMANY', 'ST', 'SAXONY-ANHALT', 'de', '14');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'BA', 'BOSNIA HERCEGOVINA', 'SRP', 'SRPSKA', 'ba', '02');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'BR', 'BRAZIL', 'SP', 'S'||unistr('\00C3')||'O PAULO', 'br', '27');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'MX', 'MEXICO', 'SON', 'SONORA', 'mx', '26');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'MX', 'MEXICO', 'SLP', 'SAN LUIS POTOSI', 'mx', '24');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'DE', 'GERMANY', 'SL', 'SAARLAND', 'de', '09');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CA', 'CANADA', 'SK', 'SASKATCHEWAN', 'ca', '11');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'SHG', 'SHANGHAI', 'cn', '23');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'SHD', 'SHANDONG', 'cn', '25');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'SHA', 'SHAANXI', 'cn', '26');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'DE', 'GERMANY', 'SH', 'SCHLESWIGHOLSTEIN', 'de', '10');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'BR', 'BRAZIL', 'SG', 'SERGIPE', 'br', '28');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'RU', 'RUSSIA', 'SAK', 'SAKHALIN', 'ru', '64');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'AU', 'AUSTRALIA', 'SA', 'SOUTH AUSTRALIA', 'au', '05');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'DE', 'GERMANY', 'SA', 'SAXONY', 'de', '13');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'BR', 'BRAZIL', 'RS', 'RIO GRANDE DO SUL', 'br', '23');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'DE', 'GERMANY', 'RP', 'RHINELANDPALATINATE', 'de', '08');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'BR', 'BRAZIL', 'RDJ', 'R'||unistr('\00CD')||'O DE JANEIRO', 'br', '21');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'AE', 'UNITED ARAB EMIRATES', 'RAK', 'RAS AL KHAIMA', 'ae', '05');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'MX', 'MEXICO', 'QUE', 'QUER'||unistr('\00C9')||'TARO', 'mx', '22');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'AU', 'AUSTRALIA', 'QLD', 'QUEENSLAND', 'au', '04');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'QH', 'QINGHAI', 'cn', '06');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CA', 'CANADA', 'QC', 'QUEBEC', 'ca', '10');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'IN', 'INDIA', 'PY', 'PUDUCHERRY', 'in', '22');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'ES', 'SPAIN', 'PV', 'BASQUE COUNTRY', 'es', '59');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'MX', 'MEXICO', 'PUE', 'PUEBLA', 'mx', '21');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CA', 'CANADA', 'PE', 'PRINCE EDWARD ISLAND', 'ca', '09');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'NL', 'NETHERLANDS', 'OV', 'OVERIJSSEL', 'nl', '08');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CA', 'CANADA', 'ON', 'ONTARIO', 'ca', '08');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'NX', 'NINGXIA HUI', 'cn', '21');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'DE', 'GERMANY', 'NW', 'NORTH RHINEWESTPHALIA', 'de', '07');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'AU', 'AUSTRALIA', 'NT', 'NORTHERN TERRITORY', 'au', '03');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'AU', 'AUSTRALIA', 'NSW', 'NEW SOUTH WALES', 'au', '02');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CA', 'CANADA', 'NS', 'NOVA SCOTIA', 'ca', '07');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'NM', 'INNER MONGOLIA', 'cn', '20');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'MX', 'MEXICO', 'NLE', 'NUEVO LEON', 'mx', '19');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CA', 'CANADA', 'NL', 'NEWFOUNDLAND', 'ca', '05');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'DE', 'GERMANY', 'NI', 'LOWER SAXONY', 'de', '06');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'NL', 'NETHERLANDS', 'NH', 'NOORD-HOLLAND', 'nl', '07');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CH', 'SWITZERLAND', 'NE', 'NEUCH'||unistr('\00C2')||'TEL', 'ch', '12');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CA', 'CANADA', 'NB', 'NEW BRUNSWICK', 'ca', '04');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'NL', 'NETHERLANDS', 'NB', 'NOORD-BRABANT', 'nl', '06');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'ES', 'SPAIN', 'NA', 'NAVARRA', 'es', '32');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'DE', 'GERMANY', 'MV', 'MECKLENBURGWESTERN P', 'de', '12');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'IN', 'INDIA', 'MP', 'MADHYA PRADESH', 'in', '35');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'RU', 'RUSSIA', 'MOW', 'MOSCOW CITY', 'ru', '48');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'IN', 'INDIA', 'MMU', 'MUMBAI', 'in', '07');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'MX', 'MEXICO', 'MIC', 'MICHOAC'||unistr('\00C1')||'N', 'mx', '16');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'IN', 'INDIA', 'MH', 'MAHARASHTRA', 'in', '16');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'BR', 'BRAZIL', 'MG', 'MINAS GERIAS', 'br', '15');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'MX', 'MEXICO', 'MEX', 'MEXICO', 'mx', '15');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'ES', 'SPAIN', 'MD', 'MADRID', 'es', '29');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CA', 'CANADA', 'MB', 'MANITOBA', 'ca', '03');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'PT', 'PORTUGAL', 'MAD', 'MADEIRA', 'pt', '10');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CH', 'SWITZERLAND', 'LU', 'LUZERN', 'ch', '11');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'IT', 'ITALY', 'LOM', 'LOMBARDIA', 'it', '09');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'LIA', 'LIAONING', 'cn', '19');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'NL', 'NETHERLANDS', 'LI', 'LIMBURG', 'nl', '05');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'IN', 'INDIA', 'KA', 'KARNATAKA', 'in', '19');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'JX', 'JIANGXI', 'cn', '03');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'ID', 'INDONESIA', 'JW', 'EAST JAVA', 'id', '08');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'JIL', 'JILIN', 'cn', '05');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'ID', 'INDONESIA', 'JB', 'WEST JAVA', 'id', '30');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'MX', 'MEXICO', 'JAL', 'JALISCO', 'mx', '14');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'IN', 'INDIA', 'HP', 'HIMACHAL PRADESH', 'in', '11');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'HNN', 'HENAN', 'cn', '09');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'HN', 'HUNAN', 'cn', '11');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'HL', 'HEILONGJIANG', 'cn', '08');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'MX', 'MEXICO', 'HID', 'HIDALGO', 'mx', '13');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'HI', 'HAINAN', 'cn', '31');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'DE', 'GERMANY', 'HH', 'HANSEATIC CITY HAMBURG', 'de', '04');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'HEB', 'HEBEI', 'cn', '10');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'DE', 'GERMANY', 'HE', 'HESSEN', 'de', '05');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'HB', 'HUBEI', 'cn', '12');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'DE', 'GERMANY', 'HB', 'HANSEATIC CITY BREMEN', 'de', '03');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'GZ', 'GUIZHOU', 'cn', '18');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'GX', 'GUANGXI ZHUANG', 'cn', '16');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'GUD', 'GUANGDONG', 'cn', '30');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'MX', 'MEXICO', 'GUA', 'GUANAJUATO', 'mx', '11');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'ZA', 'SOUTH AFRICA', 'GT', 'GAUTENG', 'za', '06');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'GS', 'GANSU', 'cn', '15');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'NL', 'NETHERLANDS', 'GR', 'GRONINGEN', 'nl', '04');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'BR', 'BRAZIL', 'GO', 'GOIAS', 'br', '29');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'IN', 'INDIA', 'GJ', 'GUJARAT', 'in', '09');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'GIA', 'JIANGSU', 'cn', '04');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'NL', 'NETHERLANDS', 'GE', 'GELDERLAND', 'nl', '03');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CH', 'SWITZERLAND', 'GE', 'GENEVA', 'ch', '07');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'IN', 'INDIA', 'GA', 'GOA', 'in', '33');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'FUJ', 'FUJIAN', 'cn', '07');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'NL', 'NETHERLANDS', 'FR', 'FRIESLAND', 'nl', '02');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'NL', 'NETHERLANDS', 'FL', 'FLEVOLAND', 'nl', '16');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'BR', 'BRAZIL', 'ES', 'ESP'||unistr('\00CD')||'RITO SANTO', 'br', '08');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'IT', 'ITALY', 'EMI', 'EMILLIA ROMAGNA', 'it', '05');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'ZA', 'SOUTH AFRICA', 'EC', 'EASTERN CAPE', 'za', '05');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'MX', 'MEXICO', 'DUR', 'DURANGO', 'mx', '10');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'AE', 'UNITED ARAB EMIRATES', 'DUB', 'DUBAI', 'ae', '03');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'NL', 'NETHERLANDS', 'DR', 'DRENTHE', 'nl', '01');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'IN', 'INDIA', 'DL', 'DELHI', 'in', '07');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'MX', 'MEXICO', 'DIF', 'MEXICO CITY', 'mx', '09');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'ES', 'SPAIN', 'CT', 'CATALONIA', 'es', '56');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'CSH', 'SHANXI', 'cn', '24');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'CQ', 'CHONGQING', 'cn', '33');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'MX', 'MEXICO', 'COL', 'COLIMA', 'mx', '08');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'MX', 'MEXICO', 'COA', 'COAHUILA', 'mx', '07');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'MX', 'MEXICO', 'CHP', 'CHIAPAS', 'mx', '05');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'MX', 'MEXICO', 'CHH', 'CHIHUAHUA', 'mx', '06');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'CCH', 'SICHUAN', 'cn', '32');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'IT', 'ITALY', 'CAM', 'CAMPANIA', 'it', '04');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'MX', 'MEXICO', 'CAM', 'CAMPECHE', 'mx', '04');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'AR', 'ARGENTINA', 'C', 'CHUBUT', 'ar', '04');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'DE', 'GERMANY', 'BW', 'BADENW'||unistr('\00DC')||'RTTEMBERG', 'de', '01');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CH', 'SWITZERLAND', 'BST', 'BASEL STADT', 'ch', '04');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CO', 'COLOMBIA', 'BOG', 'BOGOTA', 'co', NULL);
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CH', 'SWITZERLAND', 'BLA', 'BASEL LANDSCHAFT', 'ch', '03');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'BA', 'BOSNIA HERCEGOVINA', 'BIH', 'FEDERATION OF BH', 'ba', '01');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CH', 'SWITZERLAND', 'BER', 'BERN', 'ch', '05');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'BEI', 'BEIJING', 'cn', '22');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'DE', 'GERMANY', 'BE', 'BERLIN', 'de', '16');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'MX', 'MEXICO', 'BCN', 'BAJA CALIFORNIA', 'mx', '02');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CA', 'CANADA', 'BC', 'BRITISH COLUMBIA', 'ca', '02');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'DE', 'GERMANY', 'BB', 'BRANDENBURG', 'de', '11');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'AR', 'ARGENTINA', 'B', 'BUENOS AIRES', 'ar', '01');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'PT', 'PORTUGAL', 'AZO', 'AZORES', 'pt', '23');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'IN', 'INDIA', 'AP', 'ANDHRA PRADESH', 'in', '02');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'ANH', 'ANHUI PROVINCE', 'cn', '01');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'MX', 'MEXICO', 'AGU', 'AGUASCALIENTES', 'mx', '01');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'AU', 'AUSTRALIA', 'ACT', 'CAPITAL TERRITORY', 'au', '01');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'AE', 'UNITED ARAB EMIRATES', 'ABU', 'ABU DHABI', 'ae', '01');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CA', 'CANADA', 'AB', 'ALBERTA', 'ca', '01');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'AR', 'ARGENTINA', 'A', 'SALTA', 'ar', '17');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'AT', 'AUSTRIA', 'NO', 'LOWER AUSTRIA', 'at', '03');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'AT', 'AUSTRIA', 'OO', 'UPPER AUSTRIA', 'at', '04');

	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'UK', 'UNITED KINGDOM', null, null, 'gb', null);
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'US', 'UNITED STATES', 'DW', 'DELAWARE', 'us', 'DE');
END;
/

BEGIN
	INSERT INTO CSR.REGION_GROUP (REGION_GROUP_ID, GROUP_NAME)
	VALUES ('ENG', 'England');

	INSERT INTO CSR.REGION_GROUP (REGION_GROUP_ID, GROUP_NAME)
	VALUES ('NI', 'Northern Ireland');

	INSERT INTO CSR.REGION_GROUP (REGION_GROUP_ID, GROUP_NAME)
	VALUES ('SCO', 'Scotland');

	INSERT INTO CSR.REGION_GROUP (REGION_GROUP_ID, GROUP_NAME)
	VALUES ('WAL', 'Wales');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', '01');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'A1');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'A2');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'A3');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'A4');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'A5');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', '03');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'A6');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'A7');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'A8');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'A9');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'B1');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'B2');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'B3');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'B4');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'B5');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'B6');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'B7');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'B8');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'B9');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'C1');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'C2');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'C3');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'C4');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', '79');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'C5');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', '07');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'C6');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'C7');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'C8');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'C9');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'D1');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'D2');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'D3');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'D4');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'D5');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'D6');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'D7');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'D8');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'D9');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'E1');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'E2');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'E3');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'E4');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'E5');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'E6');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', '17');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', '18');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'E7');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'E8');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'E9');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'F1');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'F2');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'F3');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'F4');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'F5');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'F6');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', '20');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'F7');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'F8');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'F9');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'G1');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', '22');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'G2');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'G3');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'G4');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'G5');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'G6');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'G7');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'G8');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'G9');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'H1');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'H2');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'H3');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'H4');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'H5');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'H6');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'H7');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'H8');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'H9');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'I1');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'I2');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'I3');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', '28');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'I4');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'I5');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'I6');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'I7');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'I8');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'I9');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'J2');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'J3');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'J4');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'J5');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'J7');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'J1');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'J6');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'J8');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'J9');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'K1');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'K2');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'K3');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'K4');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'K5');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'K6');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'K7');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'K8');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'K9');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'L1');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'L2');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'L3');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'L4');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'L5');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'L7');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'L8');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'L9');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'L6');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'M1');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'M2');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'M3');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'M6');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'M7');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', '37');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'M4');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'M5');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'M8');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'N1');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'M9');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'N2');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'N3');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'N4');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'N5');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'N6');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'N7');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'N8');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'N9');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'O1');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'O2');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'O3');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'O4');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'O5');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'O6');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', '41');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'O7');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'O8');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'O9');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'P1');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'P2');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'P3');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'P4');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', '43');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'P6');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', '45');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'P5');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'P7');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'P8');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'P9');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'Q1');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'Q2');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'Q3');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'Q4');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'Q5');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'Q6');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'Q7');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'Q8');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'Q9');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'R1');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'R2');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'R3');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'R4');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'R5');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'R6');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'R7');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'R8');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'S6');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'R9');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'S1');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'S2');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'S3');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'S4');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'S5');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'S7');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'S8');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'S9');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'T1');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'T2');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'T3');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'T4');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'T5');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'T6');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'T7');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'T8');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'U1');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'U2');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'U3');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'U4');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'U5');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'U6');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'U7');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'U8');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'W8');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'U9');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'V1');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'V2');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', '82');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'V3');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'V4');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', '84');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'V5');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'V6');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'V7');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'V8');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'V9');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'W1');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'W2');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'T9');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'W3');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'W4');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'W5');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'W6');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', '87');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', '88');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'W7');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'W9');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', 'X2');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', 'X3');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', 'X4');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', 'X5');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', 'X7');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', 'X6');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', '90');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', 'X8');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', 'X9');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', '91');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', 'Y1');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', '92');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', 'Y2');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', 'X1');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', 'Y3');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', '94');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', 'Y4');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', 'Y5');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', 'Y6');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', 'Y7');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', 'Y8');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', 'Y9');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', '96');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', 'Z1');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', 'Z2');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', 'Z3');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', '97');

	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', 'Z4');
END;
/

BEGIN
	INSERT INTO csr.std_compl_application_type(application_type_id, description) VALUES (1, 'Grant');
	INSERT INTO csr.std_compl_application_type(application_type_id, description) VALUES (2, 'Renewal');
	INSERT INTO csr.std_compl_application_type(application_type_id, description) VALUES (3, 'Variation');
	INSERT INTO csr.std_compl_application_type(application_type_id, description) VALUES (4, 'Transfer');
	INSERT INTO csr.std_compl_application_type(application_type_id, description) VALUES (5, 'Surrender');
END;
/

BEGIN
	INSERT INTO csr.std_compl_activity_type(activity_type_id, description) VALUES (1, 'Installation');
	INSERT INTO csr.std_compl_activity_type(activity_type_id, description) VALUES (2, 'Waste operation');
	INSERT INTO csr.std_compl_activity_type(activity_type_id, description) VALUES (3, 'Mining waste operation');
	INSERT INTO csr.std_compl_activity_type(activity_type_id, description) VALUES (4, 'Small waste incineration plant');
	INSERT INTO csr.std_compl_activity_type(activity_type_id, description) VALUES (5, 'Mobile plant');
	INSERT INTO csr.std_compl_activity_type(activity_type_id, description) VALUES (6, 'Solvent emissions');
	INSERT INTO csr.std_compl_activity_type(activity_type_id, description) VALUES (7, 'Stand-alone water discharge');
	INSERT INTO csr.std_compl_activity_type(activity_type_id, description) VALUES (8, 'Groundwater activity');
	INSERT INTO csr.std_compl_activity_type(activity_type_id, description) VALUES (9, 'Flood risk activities on or near a main river or sea defence');
	INSERT INTO csr.std_compl_activity_type(activity_type_id, description) VALUES (10, 'Radioactive substances');
	
	INSERT INTO csr.std_compl_activity_sub_type(activity_type_id, activity_sub_type_id, description) VALUES (2, 1, 'ERF');
	INSERT INTO csr.std_compl_activity_sub_type(activity_type_id, activity_sub_type_id, description) VALUES (2, 2, 'Landfill');
	INSERT INTO csr.std_compl_activity_sub_type(activity_type_id, activity_sub_type_id, description) VALUES (2, 3, 'Composting');
	INSERT INTO csr.std_compl_activity_sub_type(activity_type_id, activity_sub_type_id, description) VALUES (2, 4, 'HWRC');
	INSERT INTO csr.std_compl_activity_sub_type(activity_type_id, activity_sub_type_id, description) VALUES (2, 5, 'Transfer Station');
	INSERT INTO csr.std_compl_activity_sub_type(activity_type_id, activity_sub_type_id, description) VALUES (2, 6, 'Decommissioning');
	INSERT INTO csr.std_compl_activity_sub_type(activity_type_id, activity_sub_type_id, description) VALUES (2, 7, 'RDF');
	INSERT INTO csr.std_compl_activity_sub_type(activity_type_id, activity_sub_type_id, description) VALUES (2, 8, 'WWTW');
	INSERT INTO csr.std_compl_activity_sub_type(activity_type_id, activity_sub_type_id, description) VALUES (2, 9, 'IWMF');
END;
/

BEGIN
	INSERT INTO csr.std_compl_condition_type(condition_type_id, description) VALUES (1, 'Management');
	INSERT INTO csr.std_compl_condition_type(condition_type_id, description) VALUES (2, 'Operations');
	INSERT INTO csr.std_compl_condition_type(condition_type_id, description) VALUES (3, 'Emissions and monitoring');
	INSERT INTO csr.std_compl_condition_type(condition_type_id, description) VALUES (4, 'Information');
	
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (1, 1, 'General Management');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (1, 2, 'Finance');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (1, 3, 'Energy efficiency');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (1, 4, 'Multiple operator installations');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (1, 5, 'Efficient use of raw materials');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (1, 6, 'Avoidance, recovery and disposal of wastes');
	
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (2, 1, 'Permitted activities');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (2, 2, 'The site');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (2, 3, 'Landfill Engineering');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (2, 4, 'Waste acceptance');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (2, 5, 'Leachate levels');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (2, 6, 'Operating techniques');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (2, 7, 'Volume');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (2, 8, 'Discharge Period');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (2, 9, 'Technical Requirements');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (2, 10, 'Improvement');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (2, 11, 'Pre-operational');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (2, 12, 'Closure and aftercare');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (2, 13, 'Landfill gas management');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (2, 14, 'Pestsk');
	
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (3, 1, 'Emissions to water, air or land');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (3, 2, 'Emissions of substances not controlled by emission limits');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (3, 3, 'Monitoring');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (3, 4, 'Odour');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (3, 5, 'Noise and vibration');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (3, 6, 'Pests');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (3, 7, 'Monitoring for the purposes of the Large Combustion Plant Directive');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (3, 8, 'Air Quality Management Plan');
	
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (4, 1, 'Records');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (4, 2, 'Reporting');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (4, 3, 'Notifications');
END;
/

BEGIN
	INSERT INTO csr.std_compl_permit_type(permit_type_id, description) VALUES (1, 'SR: Biological treatment of waste');
	INSERT INTO csr.std_compl_permit_type(permit_type_id, description) VALUES (2, 'SR: Flood risk activities');
	INSERT INTO csr.std_compl_permit_type(permit_type_id, description) VALUES (3, 'SR: Installations');
	INSERT INTO csr.std_compl_permit_type(permit_type_id, description) VALUES (4, 'SR: Low impact installation');
	INSERT INTO csr.std_compl_permit_type(permit_type_id, description) VALUES (5, 'SR: Keeping/transfer of waste');
	INSERT INTO csr.std_compl_permit_type(permit_type_id, description) VALUES (6, 'SR: Metal recovery/scrap metal');
	INSERT INTO csr.std_compl_permit_type(permit_type_id, description) VALUES (7, 'SR: Materials recovery and recycling');
	INSERT INTO csr.std_compl_permit_type(permit_type_id, description) VALUES (8, 'SR: Onshore oil and gas exploration, and mining operation');
	INSERT INTO csr.std_compl_permit_type(permit_type_id, description) VALUES (9, 'SR: Radioactive substances for non-nuclear sites');
	INSERT INTO csr.std_compl_permit_type(permit_type_id, description) VALUES (10, 'SR: Recovery or use of waste on land');
	INSERT INTO csr.std_compl_permit_type(permit_type_id, description) VALUES (11, 'SR: Treatment to produce aggregate or construction materials');
	INSERT INTO csr.std_compl_permit_type(permit_type_id, description) VALUES (12, 'SR: Water discharges');
	INSERT INTO csr.std_compl_permit_type(permit_type_id, description) VALUES (13, 'Bespoke');
	INSERT INTO csr.std_compl_permit_type(permit_type_id, description) VALUES (14, 'Exemption');
	
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (1, 1, 'SR2008 No. 16 25kte and 75kte: composting in open systems (no longer available)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (1, 2, 'SR2008 No. 17 75kte: composting in closed systems (in-vessel composting)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (1, 3, 'SR2008 No. 18 75kte: non hazardous mechanical biological (aerobic) treatment facility (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (1, 4, 'SR2015 No. 12 75kte non-hazardous mechanical biological (aerobic) treatment facility');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (1, 5, 'SR2008 No. 19 75kte: non-hazardous sludge biological chemical and physical treatment site');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (1, 6, 'SR2008 No. 19 250kte: non-hazardous sludge biological chemical and physical treatment site');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (1, 7, 'SR2009 No. 4: combustion of biogas in engines at a sewage treatment works');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (1, 8, 'SR2010 No. 14 500t: composting biodegradable waste');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (1, 9, 'SR2010 No. 15: anaerobic digestion facility including use of the resultant biogas');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (1, 10, 'SR2010 No. 16: on-farm anaerobic digestion facility');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (1, 11, 'SR2010 No. 17: storage of digestate from anaerobic digestion plants');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (1, 12, 'SR2010 No. 18: storage and treatment of dredgings for recovery');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (1, 13, 'SR2011 No. 1 500t: composting biodegradable waste (in open and closed systems)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (1, 14, 'SR2012 No. 3: composting in closed systems');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (1, 15, 'SR2012 No. 7: composting in open systems');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (1, 16, 'SR2012 No. 10: on-farm anaerobic digestion facility using farm wastes only, including use of the resultant biogas');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (1, 17, 'SR2012 No. 12: anaerobic digestion facility including use of the resultant biogas (waste recovery operation)');
	
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (2, 1, 'SR2015 No. 26: temporary dewatering affecting up to 20 metres of a main river');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (2, 2, 'SR2015 No. 27: constructing an outfall pipe of 300mm to 500mm diameter');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (2, 3, 'SR2015 No. 28: installing a clear span bridge on a main river');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (2, 4, 'SR2015 No. 29: temporary storage within the flood plain of a main river');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (2, 5, 'SR2015 No. 30: temporary diversion of a main river');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (2, 6, 'SR2015 No. 31: channel habitat structure made of natural materials');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (2, 7, 'SR2015 No. 32: installing a access culvert of no more than 5 metres length');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (2, 8, 'SR2015 No. 33: repairing and protecting up to 20 metres of the bank of a main river');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (2, 9, 'SR2015 No. 34: temporary scaffolding affecting up to 20 metres length of a main river');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (2, 10, 'SR2015 No. 35: excavating a wetland or pond in a main river floodplain');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (2, 11, 'SR2015 No. 36: installing and using site investigation boreholes and temporary trial pits within a main river floodplain for a period of up to 4 weeks');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (2, 12, 'SR2015 No. 38: removing a total of 100 metres of exposed gravel from bars and shoals');
	
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (3, 1, 'SR2012 No. 4: composting in closed systems');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (3, 2, 'SR2012 No. 8: composting in open systems');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (3, 3, 'SR2012 No. 9: on-farm anaerobic digestion using farm wastes');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (3, 4, 'SR2012 No. 11: anaerobic digestion facility including use of the resultant biogas');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (3, 5, 'SR2012 No. 13: treatment of Incinerator Bottom Ash (IBA)');
	
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (4, 1, 'SR2009 No. 2: low impact part A installation');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (4, 2, 'SR2009 No. 3: low impact part A installation for the production of biodiesel');
	
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 1, 'SR2008 No. 1 75kte: household, commercial and industrial waste transfer station (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 2, 'SR2015 No. 4 75kte: household, commercial and industrial waste transfer station');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 3, 'SR2008 No. 2: household, commercial and industrial waste transfer station (no building) (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 4, 'SR2015 No. 5: household, commercial and industrial waste transfer station (no building)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 5, 'SR2008 No. 3 75kte: household, commercial and industrial waste transfer station with treatment (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 6, 'SR2015 No. 6 75kte: household, commercial and industrial waste transfer station with treatment');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 7, 'SR2008 No. 4: household, commercial and industrial waste transfer station with treatment (no building) (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 8, 'SR2015 No. 7: household, commercial and industrial waste transfer station with treatment (no building)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 9, 'SR2008 No. 5 75kte: household, commercial and industrial waste transfer station and asbestos storage (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 10, 'SR2015 No. 8 75kte: household, commercial and industrial waste transfer station with asbestos storage');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 11, 'SR2008 No. 6: household, commercial and industrial waste transfer station with asbestos storage (no building) (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 12, 'SR2015 No. 9: household, commercial and industrial waste transfer station with asbestos storage (no building)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 13, 'SR2008 No. 7 75kte: household, commercial and industrial waste transfer station with treatment and asbestos storage (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 14, 'SR2015 No. 10 75kte: household, commercial and industrial waste transfer station with treatment and asbestos storage');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 15, 'SR2008 No. 8: household, commercial and industrial waste transfer station with treatment and asbestos storage (no building) (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 16, 'SR2015 No. 11: household, commercial and industrial waste transfer station with treatment and asbestos storage (no building)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 17, 'SR2008 No. 9: asbestos waste transfer station');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 18, 'SR2008 No. 10 75kte: inert and excavation waste transfer station (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 19, 'SR2008 No. 11 75kte: inert and excavation waste transfer station with treatment (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 20, 'SR2008 No. 24 75Kte: clinical waste and healthcare waste transfer station (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 21, 'SR2008 No. 25 75kte: clinical waste and healthcare waste treatment and transfer station (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 22, 'SR2009 No. 5: inert and excavation waste transfer station below 250kte (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 23, 'SR2009 No. 6: inert and excavation waste transfer station with treatment below 250kte (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 24, 'SR2012 No. 15: storage of electrical insulating oils');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 25, 'SR2013 No. 1: treatment of 100 t/y of clinical and healthcare waste');
	
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (6, 1, 'SR2012 No. 14: metal recycling, vehicle storage, depollution and dismantling facility (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (6, 2, 'SR2015 No. 18: metal recycling, vehicle storage, depollution and dismantling facility');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (6, 3, 'SR2008 No. 20 75kte: vehicle storage, depollution and dismantling (authorised treatment) facility (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (6, 4, 'SR2015 No. 13 75kte: vehicle storage depollution and dismantling (authorised treatment) facility');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (6, 5, 'SR2011 No. 2: metal recycling site (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (6, 6, 'SR2015 No. 16: metal recycling site');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (6, 7, 'SR2008 No. 21 75kte: metal recycling site (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (6, 8, 'SR2015 No. 14 75kte: metal recycling site');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (6, 9, 'SR2009 No. 7: storage of furnace ready scrap metal for recovery');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (6, 10, 'SR2008 No. 22 75kte: storage of furnace ready scrap metal for recovery');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (6, 11, 'SR2008 No. 23 75kte: WEEE authorised treatment facility excluding ozone depleting substances (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (6, 12, 'SR2015 No. 15 75kte: WEEE authorised treatment facility excluding ozone depleting substances');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (6, 13, 'SR2015 No. 3: metal recycling and WEEE authorised treatment facility excluding ozone depleting substances');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (6, 14, 'SR2011 No. 3: vehicle storage depollution and dismantling (authorised treatment) facility (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (6, 15, 'SR2015 No. 17: vehicle storage depollution and dismantling authorised treatment facility');
	
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (7, 1, 'SR2008 No. 12 75kte: non hazardous household waste amenity site (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (7, 2, 'SR2015 No. 19 75kte: non-hazardous household waste amenity site');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (7, 3, 'SR2008 No. 13 75kte: non-hazardous and hazardous household waste amenity site (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (7, 4, 'SR2015 No. 20 75kte: non-hazardous and hazardous household waste amenity site');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (7, 5, 'SR2008 No. 14 75kte: materials recycling facility (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (7, 6, 'SR2015 No. 21 75kte: materials recycling facility');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (7, 7, 'SR2008 No. 15: materials recycling facility (no building) (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (7, 8, 'SR2015 No. 22: Materials recycling facility (no building)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (7, 9, 'SR2011 No. 4: treatment of waste wood for recovery (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (7, 10, 'SR2015 No. 23: treatment of waste wood for recovery'); 
	
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (8, 1, 'SR2009 No. 8: management of inert wastes and unpolluted soil at mines and quarries');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (8, 2, 'SR2014 No. 2: the management of extractive waste');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (8, 3, 'SR2015 No. 2: storage and handling of crude oil');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (8, 4, 'SR2015 No. 1: onshore oil exploration');
	
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (9, 1, 'SR2010 No. 1: category 5 sealed radioactive sources standard rules');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (9, 2, 'SR2014 No. 4: NORM waste from oil and gas production');
	
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (10, 1, 'SR2015 No. 39: use of waste in a deposit for recovery operation');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (10, 2, 'SR2008 No. 27: mobile plant for the treatment of soils and contaminated material, substances or products');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (10, 3, 'SR2010 No. 4: mobile plant for land-spreading');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (10, 4, 'SR2010 No. 5: mobile plant for reclamation, restoration or improvement of land');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (10, 5, 'SR2010 No. 6: mobile plant for land-spreading of sewage sludge');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (10, 6, 'SR2010 No. 7 50kte: use of waste in construction (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (10, 7, 'SR2010 No. 8: use of waste in construction (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (10, 8, 'SR2010 No. 9: use of waste for reclamation, restoration or improvement of land (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (10, 9, 'SR2010 No. 10: standard rules to operate waste for reclamation, restoration or improvement of land (existing permits)');
	
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (11, 1, 'SR2010 No. 11: mobile plant for the treatment of waste to produce soil, soil substitutes and aggregate');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (11, 2, 'SR2010 No. 12: treatment of waste to produce soil, soil substitutes and aggregate');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (11, 3, 'SR2010 No. 13: use of waste to manufacture timber or construction products');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (11, 4, 'SR2015 No. 24: use of waste to manufacture timber or construction products');
	
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (12, 1, 'SR2010 No. 2: discharge to surface water');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (12, 2, 'SR2010 No. 3: discharge to surface water');
	
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 1, 'Waste exemption: D1 depositing waste from dredging inland waters');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 2, 'Waste exemption: D2 depositing waste from a railway sanitary convenience');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 3, 'Waste exemption: D3 depositing waste from a portable sanitary convenience');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 4, 'Waste exemption: D4 depositing agricultural waste consisting of plant tissue under a Plant Health Notice');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 5, 'Waste exemption: D5 depositing waste samples for testing or analysis');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 6, 'Waste exemption: D6 disposal by incineration');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 7, 'Waste exemption: D7 burning waste in the open');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 8, 'Waste exemption: D8 burning waste at a port under a Plant Health Notice');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 9, 'Waste exemption: NWFD 2 temporary storage at the place of production');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 10, 'Waste exemption: NWFD 3 temporary storage of waste at a place controlled by the producer');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 11, 'Waste exemption: NWFD 4 temporary storage at a collection point');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 12, 'Waste exemption: S1 storing waste in secure containers');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 13, 'Waste exemption: S2 storing waste in a secure place');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 14, 'Waste exemption: S3 storing sludge');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 15, 'Waste exemption: T22 treatment of animal by-product waste at a collection centre');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 16, 'Waste exemption: T3 treatment of waste metals and metal alloys by heating for the purposes of removing grease');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 17, 'Waste exemption: T7 treatment of waste bricks, tiles and concrete by crushing, grinding or reducing in size');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 18, 'Waste exemption: U10 spreading waste to benefit agricultural land');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 19, 'Waste exemption: U11 spreading waste to benefit non-agricultural land');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 20, 'Waste exemption: U12 using mulch');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 21, 'Waste exemption: U13 spreading plant matter to provide benefits');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 22, 'Waste exemption: U14 incorporating ash into soil');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 23, 'Waste exemption: U15 pig and poultry ash');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 24, 'Waste exemption: U16 using depolluted end-of-life vehicles for parts');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 25, 'Waste exemption: U2 use of baled end-of-life tyres in construction');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 26, 'Waste exemption: U3 construction of entertainment or educational installations');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 27, 'Waste exemption: U4 burning of waste as a fuel in a small appliance');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 28, 'Waste exemption: U5 using biodiesel produced from waste as fuel');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 29, 'Waste exemption: U6 using sludge to re-seed a waste water treatment plant');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 30, 'Waste exemption: U7 using effluent to clean a highway gravel bed');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 31, 'Waste exemption: U8 using waste for a specified purpose');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 32, 'Waste exemption: U9 using waste to manufacture finished goods');	
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 33, 'Groundwater tracer');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 34, 'Groundwater remediation');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 35, 'Flood');
END;
/

BEGIN
	INSERT INTO csr.compl_permit_app_status(compl_permit_app_status_id, label, pos) VALUES (0, 'In Progress', 0);
	INSERT INTO csr.compl_permit_app_status(compl_permit_app_status_id, label, pos) VALUES (1, 'Granted', 1);
	INSERT INTO csr.compl_permit_app_status(compl_permit_app_status_id, label, pos) VALUES (2, 'Refused', 2);
END;
/

BEGIN
	INSERT INTO csr.schema_table(owner, table_name, csrimp_table_name, module_name) VALUES ('CSR', 'COMPLIANCE_ALERT', 'COMPLIANCE_ALERT', 'COMPLIANCE');
	INSERT INTO csr.schema_table(owner, table_name, csrimp_table_name, module_name) VALUES ('CSR', 'COMPLIANCE_ENHESA_MAP', 'COMPLIANCE_ENHESA_MAP', 'COMPLIANCE');
	INSERT INTO csr.schema_table(owner, table_name, csrimp_table_name, module_name) VALUES ('CSR', 'COMPLIANCE_ENHESA_MAP_ITEM', 'COMPLIANCE_ENHESA_MAP_ITEM', 'COMPLIANCE');

	INSERT INTO csr.schema_table (owner, table_name, enable_export, enable_import, csrimp_table_name, module_name)
		VALUES ('CSR', 'ENHESA_SITE_TYPE', 1, 1, 'ENHESA_SITE_TYPE', 'Enhesa');
	INSERT INTO csr.schema_column (owner, table_name, column_name, enable_export, enable_import, sequence_owner, sequence_name)
		VALUES ('CSR', 'ENHESA_SITE_TYPE', 'SITE_TYPE_ID', 1, 1, 'CSR', 'ENHESA_SITE_TYPE_ID_SEQ');

	INSERT INTO csr.schema_table (owner, table_name, enable_export, enable_import, csrimp_table_name, module_name)
		VALUES ('CSR', 'ENHESA_SITE_TYPE_HEADING', 1, 1, 'ENHESA_SITE_TYPE_HEADING', 'Enhesa');
	INSERT INTO csr.schema_column (owner, table_name, column_name, enable_export, enable_import, sequence_owner, sequence_name)
		VALUES ('CSR', 'ENHESA_SITE_TYPE_HEADING', 'SITE_TYPE_HEADING_ID', 1, 1, 'CSR', 'ENHESA_SITE_TYP_HEADING_ID_SEQ');
	INSERT INTO csr.schema_column (owner, table_name, column_name, enable_export, enable_import, sequence_owner, sequence_name, is_map_source)
		VALUES ('CSR', 'ENHESA_SITE_TYPE_HEADING', 'SITE_TYPE_ID', 1, 1, 'CSR', 'ENHESA_SITE_TYPE_ID_SEQ', 0);

	INSERT INTO csr.schema_table (module_name, owner, table_name) VALUES ('Permits', 'CSR', 'COMP_PERMIT_SCHED_ISSUE');
	INSERT INTO csr.schema_column (column_name, is_map_source, map_new_id_col, map_old_id_col, map_table, owner, table_name)
		VALUES ('FLOW_ITEM_ID', 0, 'NEW_FLOW_ITEM_ID', 'OLD_FLOW_ITEM_ID', 'MAP_FLOW_ITEM', 'CSR', 'COMP_PERMIT_SCHED_ISSUE');
	INSERT INTO csr.schema_column (column_name, is_map_source, map_new_id_col, map_old_id_col, map_table, owner, table_name)
		VALUES ('ISSUE_SCHEDULED_TASK_ID', 0, 'NEW_ISSUE_SCHEDULED_TASK_ID', 'OLD_ISSUE_SCHEDULED_TASK_ID', 'MAP_ISSUE_SCHEDULED_TASK', 'CSR', 'COMP_PERMIT_SCHED_ISSUE');

	INSERT INTO csr.schema_table (owner, table_name) VALUES ('CSR', 'AUTO_EXP_CLASS_QC_SETTINGS');
END;
/

BEGIN
	INSERT INTO CSR.OSHA_MAP_FIELD (OSHA_MAP_FIELD_ID, LABEL, POS) VALUES (1, 'Establishment name', 1);
	INSERT INTO CSR.OSHA_MAP_FIELD (OSHA_MAP_FIELD_ID, LABEL, POS) VALUES (2, 'Company name', 2);
	INSERT INTO CSR.OSHA_MAP_FIELD (OSHA_MAP_FIELD_ID, LABEL, POS) VALUES (3, 'Street', 3);
	INSERT INTO CSR.OSHA_MAP_FIELD (OSHA_MAP_FIELD_ID, LABEL, POS) VALUES (4, 'City', 4);
	INSERT INTO CSR.OSHA_MAP_FIELD (OSHA_MAP_FIELD_ID, LABEL, POS) VALUES (5, 'State', 5);
	INSERT INTO CSR.OSHA_MAP_FIELD (OSHA_MAP_FIELD_ID, LABEL, POS) VALUES (6, 'Zip', 6);
	INSERT INTO CSR.OSHA_MAP_FIELD (OSHA_MAP_FIELD_ID, LABEL, POS) VALUES (7, 'North American Industrial Classification (NAICS)', 7);
	INSERT INTO CSR.OSHA_MAP_FIELD (OSHA_MAP_FIELD_ID, LABEL, POS) VALUES (8, 'Industry description', 8);
	INSERT INTO CSR.OSHA_MAP_FIELD (OSHA_MAP_FIELD_ID, LABEL, POS) VALUES (9, 'Size', 9);
	INSERT INTO CSR.OSHA_MAP_FIELD (OSHA_MAP_FIELD_ID, LABEL, POS) VALUES (10, 'Establisment type', 10);
	INSERT INTO CSR.OSHA_MAP_FIELD (OSHA_MAP_FIELD_ID, LABEL, POS) VALUES (11, 'Year', 11);
	INSERT INTO CSR.OSHA_MAP_FIELD (OSHA_MAP_FIELD_ID, LABEL, POS) VALUES (12, 'Annual average number of employees', 12);
	INSERT INTO CSR.OSHA_MAP_FIELD (OSHA_MAP_FIELD_ID, LABEL, POS) VALUES (13, 'Total hours worked by all employees last year', 13);
	INSERT INTO CSR.OSHA_MAP_FIELD (OSHA_MAP_FIELD_ID, LABEL, POS) VALUES (14, 'Any injuries or illnesses', 14);
	INSERT INTO CSR.OSHA_MAP_FIELD (OSHA_MAP_FIELD_ID, LABEL, POS) VALUES (15, 'Case No.', 15);
	INSERT INTO CSR.OSHA_MAP_FIELD (OSHA_MAP_FIELD_ID, LABEL, POS) VALUES (16, 'Employee''s name', 16);
	INSERT INTO CSR.OSHA_MAP_FIELD (OSHA_MAP_FIELD_ID, LABEL, POS) VALUES (17, 'Job title', 17);
	INSERT INTO CSR.OSHA_MAP_FIELD (OSHA_MAP_FIELD_ID, LABEL, POS) VALUES (18, 'Date of injury or onset of illness', 18);
	INSERT INTO CSR.OSHA_MAP_FIELD (OSHA_MAP_FIELD_ID, LABEL, POS) VALUES (19, 'Where event occurred', 19);
	INSERT INTO CSR.OSHA_MAP_FIELD (OSHA_MAP_FIELD_ID, LABEL, POS) VALUES (20, 'Describe injury or illness, parts of body affected, and object/substance that directly injured or made person ill', 20);
	INSERT INTO CSR.OSHA_MAP_FIELD (OSHA_MAP_FIELD_ID, LABEL, POS) VALUES (21, 'Death', 21);
	INSERT INTO CSR.OSHA_MAP_FIELD (OSHA_MAP_FIELD_ID, LABEL, POS) VALUES (22, 'Case resulted in days away from work', 22);
	INSERT INTO CSR.OSHA_MAP_FIELD (OSHA_MAP_FIELD_ID, LABEL, POS) VALUES (23, 'Case resulted in job transfer or restriction', 23);
	INSERT INTO CSR.OSHA_MAP_FIELD (OSHA_MAP_FIELD_ID, LABEL, POS) VALUES (24, 'Other recordable case', 24);
	INSERT INTO CSR.OSHA_MAP_FIELD (OSHA_MAP_FIELD_ID, LABEL, POS) VALUES (25, 'Days away from work', 25);
	INSERT INTO CSR.OSHA_MAP_FIELD (OSHA_MAP_FIELD_ID, LABEL, POS) VALUES (26, 'Days on transfer or restricted', 26);
	INSERT INTO CSR.OSHA_MAP_FIELD (OSHA_MAP_FIELD_ID, LABEL, POS) VALUES (27, 'Injury', 27);
	INSERT INTO CSR.OSHA_MAP_FIELD (OSHA_MAP_FIELD_ID, LABEL, POS) VALUES (28, 'Skin disorder', 28);
	INSERT INTO CSR.OSHA_MAP_FIELD (OSHA_MAP_FIELD_ID, LABEL, POS) VALUES (29, 'Respiratory condition', 29);
	INSERT INTO CSR.OSHA_MAP_FIELD (OSHA_MAP_FIELD_ID, LABEL, POS) VALUES (30, 'Poisoning', 30);
	INSERT INTO CSR.OSHA_MAP_FIELD (OSHA_MAP_FIELD_ID, LABEL, POS) VALUES (31, 'Hearing loss', 31);
	INSERT INTO CSR.OSHA_MAP_FIELD (OSHA_MAP_FIELD_ID, LABEL, POS) VALUES (32, 'All other illnesses', 32);
	INSERT INTO CSR.OSHA_MAP_FIELD (OSHA_MAP_FIELD_ID, LABEL, POS) VALUES (33, 'Change reason', 33);
	INSERT INTO CSR.OSHA_MAP_FIELD (OSHA_MAP_FIELD_ID, LABEL, POS) VALUES (34, 'Standard Industrial Classification (SIC)', 34);
END;
/

BEGIN
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required, agg_type, osha_map_field_id)
		VALUES (1, 'establishment_name', 'The name of the establishment reporting data. The system matches the data in your file to existing establishments based on establishment name. <b>Each establishment MUST have a unique name.</b>', 'Character', 100, 1, 0, 1);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required, agg_type, osha_map_field_id)
		VALUES (2, 'company_name', 'The name of the company that owns the establishment.', 'Character', 100, 0, 0, 2);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required, agg_type, osha_map_field_id)
		VALUES (3, 'street_address', 'The street address of the establishment. <ul><li>Should not contain a PO Box address</li></ul>', 'Character', 100, 1, 0, 3);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required, agg_type, osha_map_field_id)
		VALUES (4, 'city', 'The city where the establishment is located.', 'Character', 100, 1, 0, 4);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required, agg_type, osha_map_field_id)
		VALUES (5, 'state', 'The state where the establishment is located. <ul><li>Enter the two character postal code for the U.S. State or Territory in which the establishment is located.</li></ul>', 'Character', 2, 1, 0, 5);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required, agg_type, osha_map_field_id)
		VALUES (6, 'zip', 'The full zip code for the establishment. <ul><li>Must be a five or nine digit number</li></ul>', 'Text', 9, 1, 0, 6);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required, agg_type, osha_map_field_id)
		VALUES (7, 'naics_code', 'The North American Industry Classification System (NAICS) code which classifies an establishment''s business. Use a 2012 code, found here: <a href="http://www.census.gov/cgi-bin/sssd/naics/naicsrch?chart=2012">http://www.census.gov/cgi-bin/sssd/naics/naicsrch?chart=2012</a><ul><li>Must be a number and be 6 digits in length</li></ul>', 'Integer', 6, 1, 0, 7);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required, agg_type, osha_map_field_id)
		VALUES (8, 'industry_description', 'Industry Description <ul><li>You may provide an industry description in addition to your NAICS code.</li></ul>', 'Character', 300, 0, 0, 8);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required, agg_type, osha_map_field_id)
		VALUES (9, 'size', 'The size of the establishment based on the maximum number of employees which worked there <b><u>at any point</u></b> in the year you are submitting data for.<ul><li>Enter 1 if the establishment has < 20 employees</li><li>Enter 2 if the establishment has 20-249 employees</li><li>Enter 3 if the establishment has 250+ employees</li></ul>', 'Integer', 1, 1, 0, 9);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required, agg_type, osha_map_field_id)
		VALUES (10, 'establishment_type', 'Identify if the establishment is part of a state or local government. <ul><li>Enter 1 if the establishment is not a government entity</li><li>Enter 2 if the establishment is a State Government entity</li><li>Enter 3 if the establishment is a Local Government entity</li></ul>', 'Integer', 1, 0, 0, 10);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required, agg_type, osha_map_field_id)
		VALUES (11, 'year_filing_for', 'The calendar year in which the injuries and illnesses being reported occurred at the establishment. <ul><li>Must be a four digit number</li><li>Cannot be earlier than 2016</li></ul>', 'Integer', 4, 1, 0, 11);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required, agg_type, osha_map_field_id)
		VALUES (12, 'annual_average_employees', 'Annual Average Number of Employees<ul><li>Must be > 0</li><li>Must be a number</li><li>Should be < 25,000</li></ul>', 'Integer', 10, 1, 0, 12);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required, agg_type, osha_map_field_id)
		VALUES (13, 'total_hours_worked', 'Total hours worked by all employees last year <ul><li>Must be > 0</li><li>Must be numeric</li><li>total_hours_worked divided by annual_average_employees  must be < 8760</li><li>total_hours_worked divided by annual_average_employees should be > 500</li></ul>', 'Integer', 10, 1, 0, 13); 
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required, agg_type, osha_map_field_id)
		VALUES (14, 'no_injuries_illnesses', 'Whether the establishment had any OSHA recordable work-related injuries or illnesses during the year.<ul><li>Enter 1 if the establishment had injuries or illnesses</li><li>Enter 2 if the establishment did not have injuries or illnesses</li></ul>', 'Integer', 1, 1, 0, 14);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required, agg_type, osha_map_field_id)
		VALUES (15, 'total_deaths', 'Total number of deaths (Form 300A Field G) <ul><li>Must be >= 0</li><li>Must be a number</li></ul>', 'Integer', 10, 1, 1, 21); 
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required, agg_type, osha_map_field_id)
		VALUES (16, 'total_dafw_cases', 'Total number of cases with days away from work (Form 300A Field H)<ul><li>Must be >= 0</li><li>Must be a number</li></ul>', 'Integer', 10, 1, 1, 22);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required, agg_type, osha_map_field_id)
		VALUES (17, 'total_djtr_cases', 'Total number of cases with job transfer or restriction (Form 300A Field I)<ul><li>Must be >= 0</li><li>Must be a number</li></ul>', 'Integer', 10, 1, 1, 23);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required, agg_type, osha_map_field_id)
		VALUES (18, 'total_other_cases', 'Total number of other recordable cases (Form 300A Field J)<ul><li>Must be >= 0</li><li>Must be a number</li></ul>', 'Integer', 10, 1, 1, 24);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required, agg_type, osha_map_field_id)
		VALUES (19, 'total_dafw_days', 'Total number of days away from work (Form 300A Field K)<ul><li>Must be >= 0</li><li>Must be a number</li></ul>', 'Integer', 10, 1, 2, 25);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required, agg_type, osha_map_field_id)
		VALUES (20, 'total_djtr_days', 'Total number of days of job transfer or restriction (Form 300A Field L)<ul><li>Must be >= 0</li><li>Must be a number</li></ul>', 'Integer', 10, 1, 2, 26);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required, agg_type, osha_map_field_id)
		VALUES (21, 'total_injuries', 'Total number of injuries (Form 300A Field M(1))<ul><li>Must be >= 0</li><li>Must be a number</li></ul>', 'Integer', 10, 1, 1, 27);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required, agg_type, osha_map_field_id)
		VALUES (22, 'total_skin_disorders', 'Total number of skin disorders (Form 300A Field M(2))<ul><li>Must be >= 0</li><li>Must be a number</li></ul>', 'Integer', 10, 1, 1, 28);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required, agg_type, osha_map_field_id)
		VALUES (23, 'total_respiratory_conditions', 'Total number of respiratory conditions (Form 300A Field M(3))<ul><li>Must be >= 0</li><li>Must be a number</li></ul>', 'Integer', 10, 1, 1, 29);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required, agg_type, osha_map_field_id)
		VALUES (24, 'total_poisonings', 'Total number of poisonings (Form 300A Field M(4))<ul><li>Must be >= 0</li><li>Must be a number</li></ul>', 'Integer', 10, 1, 1, 30);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required, agg_type, osha_map_field_id)
		VALUES (25, 'total_hearing_loss', 'Total number of hearing loss (Form 300A Field M(5))<ul><li>Must be >= 0</li><li>Must be a number</li></ul>', 'Integer', 10, 1, 1, 31);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required, agg_type, osha_map_field_id)
		VALUES (26, 'total_other_illnesses', 'Total number of all other illnesses (Form 300A Field M(6))<ul><li>Must be >= 0</li><li>Must be a number</li></ul>', 'Integer', 10, 1, 1, 32);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required, agg_type, osha_map_field_id)
		VALUES (27, 'change_reason', 'The reason why an establishment''s injury and illness summary was changed, if applicable', 'Character', 100, 0, 0, 33);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required, agg_type, osha_map_field_id)
		VALUES (28, 'sic_code', 'Standard Industrial Classification (SIC), if known (e.g., SIC 3715)', 'Integer', 4, 1, 0, 34);
END;
/

BEGIN
	INSERT INTO CSR.OSHA_MAP_TYPE (OSHA_MAP_TYPE_ID, LABEL) VALUES (1, 'CMS');
	INSERT INTO CSR.OSHA_MAP_TYPE (OSHA_MAP_TYPE_ID, LABEL) VALUES (2, 'Indicator');
	INSERT INTO CSR.OSHA_MAP_TYPE (OSHA_MAP_TYPE_ID, LABEL) VALUES (3, 'Region Attribute');
END;
/

BEGIN
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (1, 1);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (1, 2);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (1, 3);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (2, 1);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (2, 2);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (2, 3);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (3, 1);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (3, 2);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (3, 3);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (4, 1);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (4, 2);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (4, 3);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (5, 1);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (5, 2);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (5, 3);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (6, 1);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (6, 2);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (6, 3);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (7, 1);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (7, 2);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (7, 3);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (8, 1);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (8, 2);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (8, 3);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (9, 1);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (9, 2);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (9, 3);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (10, 1);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (10, 2);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (10, 3);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (11, 1);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (11, 2);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (11, 3);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (12, 1);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (12, 2);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (12, 3);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (13, 1);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (13, 2);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (13, 3);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (14, 1);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (14, 2);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (14, 3);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (15, 1);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (15, 2);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (15, 3);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (16, 1);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (16, 2);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (16, 3);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (17, 1);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (17, 2);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (17, 3);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (18, 1);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (18, 2);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (18, 3);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (19, 1);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (19, 2);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (19, 3);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (20, 1);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (20, 2);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (20, 3);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (21, 1);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (22, 1);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (23, 1);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (24, 1);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (25, 1);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (26, 1);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (27, 1);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (28, 1);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (29, 1);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (30, 1);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (31, 1);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (32, 1);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (33, 1);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (34, 1);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (34, 2);
	INSERT INTO CSR.OSHA_MAP_FIELD_TYPE (OSHA_MAP_FIELD_ID, OSHA_MAP_TYPE_ID) VALUES (34, 3);
END;
/

BEGIN
	INSERT INTO CSR.REGION_DATA_MAP (REGION_DATA_MAP_ID, DATA_ELEMENT, DESCRIPTION, IS_PROPERTY, IS_METER) VALUES (1, 'SID', 'Region id', 0, 0);
	INSERT INTO CSR.REGION_DATA_MAP (REGION_DATA_MAP_ID, DATA_ELEMENT, DESCRIPTION, IS_PROPERTY, IS_METER) VALUES (2, 'DESC', 'Region description', 0, 0);
	INSERT INTO CSR.REGION_DATA_MAP (REGION_DATA_MAP_ID, DATA_ELEMENT, DESCRIPTION, IS_PROPERTY, IS_METER) VALUES (3, 'REF', 'Region reference', 0, 0);
	INSERT INTO CSR.REGION_DATA_MAP (REGION_DATA_MAP_ID, DATA_ELEMENT, DESCRIPTION, IS_PROPERTY, IS_METER) VALUES (4, 'GEO_CITY', 'Region City', 0, 0);
	INSERT INTO CSR.REGION_DATA_MAP (REGION_DATA_MAP_ID, DATA_ELEMENT, DESCRIPTION, IS_PROPERTY, IS_METER) VALUES (5, 'GEO_ST_CODE', 'Region State Code', 0, 0);
	INSERT INTO CSR.REGION_DATA_MAP (REGION_DATA_MAP_ID, DATA_ELEMENT, DESCRIPTION, IS_PROPERTY, IS_METER) VALUES (6, 'GEO_ST_DESC', 'Region State', 0, 0);
	INSERT INTO CSR.REGION_DATA_MAP (REGION_DATA_MAP_ID, DATA_ELEMENT, DESCRIPTION, IS_PROPERTY, IS_METER) VALUES (7, 'GEO_COUNTRY_DESC', 'Region Country', 0, 0);
	INSERT INTO CSR.REGION_DATA_MAP (REGION_DATA_MAP_ID, DATA_ELEMENT, DESCRIPTION, IS_PROPERTY, IS_METER) VALUES (8, 'GEO_COUNTRY_CODE', 'Region Country Code', 0, 0);
	INSERT INTO CSR.REGION_DATA_MAP (REGION_DATA_MAP_ID, DATA_ELEMENT, DESCRIPTION, IS_PROPERTY, IS_METER) VALUES (9, 'MGNT_COMPANY', 'Management company', 1, 0);
	INSERT INTO CSR.REGION_DATA_MAP (REGION_DATA_MAP_ID, DATA_ELEMENT, DESCRIPTION, IS_PROPERTY, IS_METER) VALUES (10, 'FUND', 'Fund', 1, 0);
	INSERT INTO CSR.REGION_DATA_MAP (REGION_DATA_MAP_ID, DATA_ELEMENT, DESCRIPTION, IS_PROPERTY, IS_METER) VALUES (11, 'PROP_TYPE', 'Property type', 1, 0);
	INSERT INTO CSR.REGION_DATA_MAP (REGION_DATA_MAP_ID, DATA_ELEMENT, DESCRIPTION, IS_PROPERTY, IS_METER) VALUES (12, 'PROP_SUB_TYPE', 'Property sub type', 1, 0);
	INSERT INTO CSR.REGION_DATA_MAP (REGION_DATA_MAP_ID, DATA_ELEMENT, DESCRIPTION, IS_PROPERTY, IS_METER) VALUES (13, 'PROP_ADDR1', 'Property Address 1', 1, 0);
	INSERT INTO CSR.REGION_DATA_MAP (REGION_DATA_MAP_ID, DATA_ELEMENT, DESCRIPTION, IS_PROPERTY, IS_METER) VALUES (14, 'PROP_ADDR2', 'Property Address 2', 1, 0);
	INSERT INTO CSR.REGION_DATA_MAP (REGION_DATA_MAP_ID, DATA_ELEMENT, DESCRIPTION, IS_PROPERTY, IS_METER) VALUES (15, 'PROP_CITY', 'Property city', 1, 0);
	INSERT INTO CSR.REGION_DATA_MAP (REGION_DATA_MAP_ID, DATA_ELEMENT, DESCRIPTION, IS_PROPERTY, IS_METER) VALUES (16, 'PROP_STATE', 'Property state', 1, 0);
	INSERT INTO CSR.REGION_DATA_MAP (REGION_DATA_MAP_ID, DATA_ELEMENT, DESCRIPTION, IS_PROPERTY, IS_METER) VALUES (17, 'PROP_ZIP', 'Property zip', 1, 0);
	INSERT INTO CSR.REGION_DATA_MAP (REGION_DATA_MAP_ID, DATA_ELEMENT, DESCRIPTION, IS_PROPERTY, IS_METER) VALUES (18, 'MET_NUM', 'Meter number', 0, 1);
	INSERT INTO CSR.REGION_DATA_MAP (REGION_DATA_MAP_ID, DATA_ELEMENT, DESCRIPTION, IS_PROPERTY, IS_METER) VALUES (19, 'MET_TYPE', 'Meter type', 0, 1);
END;
/

BEGIN
	INSERT INTO csr.service_user_map(service_identifier, user_sid, full_name, can_impersonate)
		VALUES	('scheduler', 3, 'Scheduler service user', 1);	
		
	INSERT INTO csr.service_user_map(service_identifier, user_sid, full_name, can_impersonate)
		VALUES	('amfori', 3, 'Amfori Platform Service user', 1);

	INSERT INTO csr.service_user_map(service_identifier, user_sid, full_name, can_impersonate)
		VALUES	('disclosures', 3, 'Disclosures Service user', 0);
END;
/

@@basedata_energy_star

BEGIN
	INSERT INTO csr.external_target_profile_type (profile_type_id, label) VALUES (1, 'SharePoint Folder (Online)');
	INSERT INTO csr.external_target_profile_type (profile_type_id, label) VALUES (2, 'OneDrive');
	INSERT INTO csr.external_target_profile_type (profile_type_id, label) VALUES (3, 'Azure Blob Storage');
END;
/


BEGIN
	INSERT INTO CSR.AUTHENTICATION_TYPE (AUTH_TYPE_ID, AUTH_TYPE_NAME) VALUES (1, 'Azure Active Directory (User based authentication)');
	INSERT INTO CSR.AUTHENTICATION_TYPE (AUTH_TYPE_ID, AUTH_TYPE_NAME) VALUES (2, 'API Key/Access Token');
	
	INSERT INTO CSR.AUTHENTICATION_SCOPE (AUTH_SCOPE_ID, AUTH_TYPE_ID, AUTH_SCOPE_NAME, AUTH_SCOPE, HIDDEN) VALUES (1, 1, 'Legacy',
	'https://graph.microsoft.com/offline_access,https://graph.microsoft.com/openid,https://graph.microsoft.com/User.Read,https://graph.microsoft.com/Files.ReadWrite.All,https://graph.microsoft.com/Sites.ReadWrite.All', 1);
	INSERT INTO CSR.AUTHENTICATION_SCOPE (AUTH_SCOPE_ID, AUTH_TYPE_ID,  AUTH_SCOPE_NAME, AUTH_SCOPE, HIDDEN) VALUES (2, 1, 'Sharepoint',
	'https://graph.microsoft.com/offline_access,https://graph.microsoft.com/openid,https://graph.microsoft.com/User.Read,https://graph.microsoft.com/Files.ReadWrite', 0);
	INSERT INTO CSR.AUTHENTICATION_SCOPE (AUTH_SCOPE_ID, AUTH_TYPE_ID, AUTH_SCOPE_NAME, AUTH_SCOPE, HIDDEN) VALUES (3, 1, 'Onedrive',
	'https://graph.microsoft.com/offline_access,https://graph.microsoft.com/openid,https://graph.microsoft.com/User.Read,https://graph.microsoft.com/Files.ReadWrite', 0);
	INSERT INTO CSR.AUTHENTICATION_SCOPE (AUTH_SCOPE_ID, AUTH_TYPE_ID, AUTH_SCOPE_NAME, AUTH_SCOPE, HIDDEN) VALUES (4, 1, 'Azure Storage Account', 'https://storage.azure.com/user_impersonation', 0);
END;
/

BEGIN
	INSERT INTO CSR.CONTEXT_SENSITIVE_HELP_BASE (client_help_root, internal_help_root) VALUES ('http://cr360.helpdocsonline.com/', 'http://emu.helpdocsonline.com/');
END;
/

@@basedata_certificates_ratings


-- based on postcode\CountryToSqlMapper\Output\postcode_country.sql
DECLARE
PROCEDURE MergeCountry(
	in_country_code	postcode.country.country%TYPE,
	in_country_name	postcode.country.name%TYPE,
	in_iso3			postcode.country.iso3%TYPE,
	in_is_standard	NUMBER DEFAULT 1
) AS
BEGIN
	DBMS_OUTPUT.PUT_LINE('Processing country: ' || in_country_code || ', ' || in_country_name || ', ' || in_iso3);

	MERGE INTO postcode.country dest
	USING (
		SELECT  in_country_code AS country_code,
				in_country_name AS country_name,
				in_iso3 AS iso3
		  FROM DUAL
		  ) src
	ON (LOWER(TRIM(dest.country)) = LOWER(src.country_code))
	WHEN MATCHED THEN
		UPDATE SET dest.name = src.country_name, dest.iso3 = LOWER(src.iso3), dest.is_standard = in_is_standard
	WHEN NOT MATCHED THEN
		INSERT (country, name, iso3, is_standard)
		VALUES (LOWER(src.country_code), src.country_name, LOWER(src.iso3), in_is_standard);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			DBMS_OUTPUT.PUT_LINE('Error: Country Name "' || in_country_name || '" already exists.');
END;

BEGIN
	MergeCountry('ad','Andorra','AND');
	MergeCountry('ae','United Arab Emirates (the)','ARE');
	MergeCountry('af','Afghanistan','AFG');
	MergeCountry('ag','Antigua and Barbuda','ATG');
	MergeCountry('ai','Anguilla','AIA');
	MergeCountry('al','Albania','ALB');
	MergeCountry('am','Armenia','ARM');
	MergeCountry('ao','Angola','AGO');
	MergeCountry('aq','Antarctica','ATA');
	MergeCountry('ar','Argentina','ARG');
	MergeCountry('as','American Samoa','ASM');
	MergeCountry('at','Austria','AUT');
	MergeCountry('au','Australia','AUS');
	MergeCountry('aw','Aruba','ABW');
	MergeCountry('ax',''||UNISTR('\00C5')||'land Islands','ALA');
	MergeCountry('az','Azerbaijan','AZE');
	MergeCountry('ba','Bosnia and Herzegovina','BIH');
	MergeCountry('bb','Barbados','BRB');
	MergeCountry('bd','Bangladesh','BGD');
	MergeCountry('be','Belgium','BEL');
	MergeCountry('bf','Burkina Faso','BFA');
	MergeCountry('bg','Bulgaria','BGR');
	MergeCountry('bh','Bahrain','BHR');
	MergeCountry('bi','Burundi','BDI');
	MergeCountry('bj','Benin','BEN');
	MergeCountry('bl','Saint Barth'||UNISTR('\00E9')||'lemy','BLM');
	MergeCountry('bm','Bermuda','BMU');
	MergeCountry('bn','Brunei Darussalam','BRN');
	MergeCountry('bo','Bolivia (Plurinational State of)','BOL');
	MergeCountry('bq','Bonaire, Sint Eustatius and Saba','BES');
	MergeCountry('br','Brazil','BRA');
	MergeCountry('bs','Bahamas (the)','BHS');
	MergeCountry('bt','Bhutan','BTN');
	MergeCountry('bv','Bouvet Island','BVT');
	MergeCountry('bw','Botswana','BWA');
	MergeCountry('by','Belarus','BLR');
	MergeCountry('bz','Belize','BLZ');
	MergeCountry('ca','Canada','CAN');
	MergeCountry('cc','Cocos (Keeling) Islands (the)','CCK');
	MergeCountry('cd','Congo (the Democratic Republic of the)','COD');
	MergeCountry('cf','Central African Republic (the)','CAF');
	MergeCountry('cg','Congo (the)','COG');
	MergeCountry('ch','Switzerland','CHE');
	MergeCountry('ci','C'||UNISTR('\00F4')||'te d''Ivoire','CIV');
	MergeCountry('ck','Cook Islands (the)','COK');
	MergeCountry('cl','Chile','CHL');
	MergeCountry('cm','Cameroon','CMR');
	MergeCountry('cn','China','CHN');
	MergeCountry('co','Colombia','COL');
	MergeCountry('cr','Costa Rica','CRI');
	MergeCountry('cu','Cuba','CUB');
	MergeCountry('cv','Cabo Verde','CPV');
	MergeCountry('cw','Cura'||UNISTR('\00E7')||'ao','CUW');
	MergeCountry('cx','Christmas Island','CXR');
	MergeCountry('cy','Cyprus','CYP');
	MergeCountry('cz','Czechia','CZE');
	MergeCountry('de','Germany','DEU');
	MergeCountry('dj','Djibouti','DJI');
	MergeCountry('dk','Denmark','DNK');
	MergeCountry('dm','Dominica','DMA');
	MergeCountry('do','Dominican Republic (the)','DOM');
	MergeCountry('dz','Algeria','DZA');
	MergeCountry('ec','Ecuador','ECU');
	MergeCountry('ee','Estonia','EST');
	MergeCountry('eg','Egypt','EGY');
	MergeCountry('eh','Western Sahara*','ESH');
	MergeCountry('er','Eritrea','ERI');
	MergeCountry('es','Spain','ESP');
	MergeCountry('et','Ethiopia','ETH');
	MergeCountry('fi','Finland','FIN');
	MergeCountry('fj','Fiji','FJI');
	MergeCountry('fk','Falkland Islands (the) [Malvinas]','FLK');
	MergeCountry('fm','Micronesia (Federated States of)','FSM');
	MergeCountry('fo','Faroe Islands (the)','FRO');
	MergeCountry('fr','France','FRA');
	MergeCountry('ga','Gabon','GAB');
	MergeCountry('gb','United Kingdom of Great Britain and Northern Ireland (the)','GBR');
	MergeCountry('gd','Grenada','GRD');
	MergeCountry('ge','Georgia','GEO');
	MergeCountry('gf','French Guiana','GUF');
	MergeCountry('gg','Guernsey','GGY');
	MergeCountry('gh','Ghana','GHA');
	MergeCountry('gi','Gibraltar','GIB');
	MergeCountry('gl','Greenland','GRL');
	MergeCountry('gm','Gambia (the)','GMB');
	MergeCountry('gn','Guinea','GIN');
	MergeCountry('gp','Guadeloupe','GLP');
	MergeCountry('gq','Equatorial Guinea','GNQ');
	MergeCountry('gr','Greece','GRC');
	MergeCountry('gs','South Georgia and the South Sandwich Islands','SGS');
	MergeCountry('gt','Guatemala','GTM');
	MergeCountry('gu','Guam','GUM');
	MergeCountry('gw','Guinea-Bissau','GNB');
	MergeCountry('gy','Guyana','GUY');
	MergeCountry('hk','Hong Kong','HKG');
	MergeCountry('hm','Heard Island and McDonald Islands','HMD');
	MergeCountry('hn','Honduras','HND');
	MergeCountry('hr','Croatia','HRV');
	MergeCountry('ht','Haiti','HTI');
	MergeCountry('hu','Hungary','HUN');
	MergeCountry('id','Indonesia','IDN');
	MergeCountry('ie','Ireland','IRL');
	MergeCountry('il','Israel','ISR');
	MergeCountry('im','Isle of Man','IMN');
	MergeCountry('in','India','IND');
	MergeCountry('io','British Indian Ocean Territory (the)','IOT');
	MergeCountry('iq','Iraq','IRQ');
	MergeCountry('ir','Iran (Islamic Republic of)','IRN');
	MergeCountry('is','Iceland','ISL');
	MergeCountry('it','Italy','ITA');
	MergeCountry('je','Jersey','JEY');
	MergeCountry('jm','Jamaica','JAM');
	MergeCountry('jo','Jordan','JOR');
	MergeCountry('jp','Japan','JPN');
	MergeCountry('ke','Kenya','KEN');
	MergeCountry('kg','Kyrgyzstan','KGZ');
	MergeCountry('kh','Cambodia','KHM');
	MergeCountry('ki','Kiribati','KIR');
	MergeCountry('km','Comoros (the)','COM');
	MergeCountry('kn','Saint Kitts and Nevis','KNA');
	MergeCountry('kp','Korea (the Democratic People''s Republic of)','PRK');
	MergeCountry('kr','Korea (the Republic of)','KOR');
	MergeCountry('kw','Kuwait','KWT');
	MergeCountry('ky','Cayman Islands (the)','CYM');
	MergeCountry('kz','Kazakhstan','KAZ');
	MergeCountry('la','Lao People''s Democratic Republic (the)','LAO');
	MergeCountry('lb','Lebanon','LBN');
	MergeCountry('lc','Saint Lucia','LCA');
	MergeCountry('li','Liechtenstein','LIE');
	MergeCountry('lk','Sri Lanka','LKA');
	MergeCountry('lr','Liberia','LBR');
	MergeCountry('ls','Lesotho','LSO');
	MergeCountry('lt','Lithuania','LTU');
	MergeCountry('lu','Luxembourg','LUX');
	MergeCountry('lv','Latvia','LVA');
	MergeCountry('ly','Libya','LBY');
	MergeCountry('ma','Morocco','MAR');
	MergeCountry('mc','Monaco','MCO');
	MergeCountry('md','Moldova (the Republic of)','MDA');
	MergeCountry('me','Montenegro','MNE');
	MergeCountry('mf','Saint Martin (French part)','MAF');
	MergeCountry('mg','Madagascar','MDG');
	MergeCountry('mh','Marshall Islands (the)','MHL');
	MergeCountry('mk','North Macedonia','MKD');
	MergeCountry('ml','Mali','MLI');
	MergeCountry('mm','Myanmar','MMR');
	MergeCountry('mn','Mongolia','MNG');
	MergeCountry('mo','Macao','MAC');
	MergeCountry('mp','Northern Mariana Islands (the)','MNP');
	MergeCountry('mq','Martinique','MTQ');
	MergeCountry('mr','Mauritania','MRT');
	MergeCountry('ms','Montserrat','MSR');
	MergeCountry('mt','Malta','MLT');
	MergeCountry('mu','Mauritius','MUS');
	MergeCountry('mv','Maldives','MDV');
	MergeCountry('mw','Malawi','MWI');
	MergeCountry('mx','Mexico','MEX');
	MergeCountry('my','Malaysia','MYS');
	MergeCountry('mz','Mozambique','MOZ');
	MergeCountry('na','Namibia','NAM');
	MergeCountry('nc','New Caledonia','NCL');
	MergeCountry('ne','Niger (the)','NER');
	MergeCountry('nf','Norfolk Island','NFK');
	MergeCountry('ng','Nigeria','NGA');
	MergeCountry('ni','Nicaragua','NIC');
	MergeCountry('nl','Netherlands (Kingdom of the)','NLD');
	MergeCountry('no','Norway','NOR');
	MergeCountry('np','Nepal','NPL');
	MergeCountry('nr','Nauru','NRU');
	MergeCountry('nu','Niue','NIU');
	MergeCountry('nz','New Zealand','NZL');
	MergeCountry('om','Oman','OMN');
	MergeCountry('pa','Panama','PAN');
	MergeCountry('pe','Peru','PER');
	MergeCountry('pf','French Polynesia','PYF');
	MergeCountry('pg','Papua New Guinea','PNG');
	MergeCountry('ph','Philippines (the)','PHL');
	MergeCountry('pk','Pakistan','PAK');
	MergeCountry('pl','Poland','POL');
	MergeCountry('pm','Saint Pierre and Miquelon','SPM');
	MergeCountry('pn','Pitcairn','PCN');
	MergeCountry('pr','Puerto Rico','PRI');
	MergeCountry('ps','Palestine, State of','PSE');
	MergeCountry('pt','Portugal','PRT');
	MergeCountry('pw','Palau','PLW');
	MergeCountry('py','Paraguay','PRY');
	MergeCountry('qa','Qatar','QAT');
	MergeCountry('re','R'||UNISTR('\00E9')||'union','REU');
	MergeCountry('ro','Romania','ROU');
	MergeCountry('rs','Serbia','SRB');
	MergeCountry('ru','Russian Federation (the)','RUS');
	MergeCountry('rw','Rwanda','RWA');
	MergeCountry('sa','Saudi Arabia','SAU');
	MergeCountry('sb','Solomon Islands','SLB');
	MergeCountry('sc','Seychelles','SYC');
	MergeCountry('sd','Sudan (the)','SDN');
	MergeCountry('se','Sweden','SWE');
	MergeCountry('sg','Singapore','SGP');
	MergeCountry('sh','Saint Helena, Ascension and Tristan da Cunha','SHN');
	MergeCountry('si','Slovenia','SVN');
	MergeCountry('sj','Svalbard and Jan Mayen','SJM');
	MergeCountry('sk','Slovakia','SVK');
	MergeCountry('sl','Sierra Leone','SLE');
	MergeCountry('sm','San Marino','SMR');
	MergeCountry('sn','Senegal','SEN');
	MergeCountry('so','Somalia','SOM');
	MergeCountry('sr','Suriname','SUR');
	MergeCountry('ss','South Sudan','SSD');
	MergeCountry('st','Sao Tome and Principe','STP');
	MergeCountry('sv','El Salvador','SLV');
	MergeCountry('sx','Sint Maarten (Dutch part)','SXM');
	MergeCountry('sy','Syrian Arab Republic (the)','SYR');
	MergeCountry('sz','Eswatini','SWZ');
	MergeCountry('tc','Turks and Caicos Islands (the)','TCA');
	MergeCountry('td','Chad','TCD');
	MergeCountry('tf','French Southern Territories (the)','ATF');
	MergeCountry('tg','Togo','TGO');
	MergeCountry('th','Thailand','THA');
	MergeCountry('tj','Tajikistan','TJK');
	MergeCountry('tk','Tokelau','TKL');
	MergeCountry('tl','Timor-Leste','TLS');
	MergeCountry('tm','Turkmenistan','TKM');
	MergeCountry('tn','Tunisia','TUN');
	MergeCountry('to','Tonga','TON');
	MergeCountry('tr','T'||UNISTR('\00FC')||'rkiye','TUR');
	MergeCountry('tt','Trinidad and Tobago','TTO');
	MergeCountry('tv','Tuvalu','TUV');
	MergeCountry('tw','Taiwan (Province of China)','TWN');
	MergeCountry('tz','Tanzania, the United Republic of','TZA');
	MergeCountry('ua','Ukraine','UKR');
	MergeCountry('ug','Uganda','UGA');
	MergeCountry('um','United States Minor Outlying Islands (the)','UMI');
	MergeCountry('us','United States of America (the)','USA');
	MergeCountry('uy','Uruguay','URY');
	MergeCountry('uz','Uzbekistan','UZB');
	MergeCountry('va','Holy See (the)','VAT');
	MergeCountry('vc','Saint Vincent and the Grenadines','VCT');
	MergeCountry('ve','Venezuela (Bolivarian Republic of)','VEN');
	MergeCountry('vg','Virgin Islands (British)','VGB');
	MergeCountry('vi','Virgin Islands (U.S.)','VIR');
	MergeCountry('vn','Viet Nam','VNM');
	MergeCountry('vu','Vanuatu','VUT');
	MergeCountry('wf','Wallis and Futuna','WLF');
	MergeCountry('ws','Samoa','WSM');
	MergeCountry('ye','Yemen','YEM');
	MergeCountry('yt','Mayotte','MYT');
	MergeCountry('za','South Africa','ZAF');
	MergeCountry('zm','Zambia','ZMB');
	MergeCountry('zw','Zimbabwe','ZWE');


	--non standard countries
	MergeCountry('aa', 'Asia', 'asi', 0);
	MergeCountry('ac', 'Africa', 'afr', 0);
	MergeCountry('ap', 'Asia/Pacific Region', 'apc', 0);
	MergeCountry('ay', 'Asia Oceania', 'aso', 0);
	MergeCountry('ea', 'Non-OECD Europe and Eurasia', 'eua', 0);
	MergeCountry('ep', 'European Union', 'euu', 0);
	MergeCountry('eu', 'Europe', 'eur', 0);
	MergeCountry('hc', 'China (including Hong Kong)', 'chk', 0);
	MergeCountry('lm', 'Latin America', 'lta', 0);
	MergeCountry('mi', 'Middle East', 'mde', 0);
	MergeCountry('nm', 'North America', 'nra', 0);
	MergeCountry('oa', 'Other Asia', 'oas', 0);
	MergeCountry('of', 'Other Africa', 'oaf', 0);
	MergeCountry('ol', 'Other Latin America', 'ola', 0);
END;
/


COMMIT;
