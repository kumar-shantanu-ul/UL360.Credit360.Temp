-- Please update version.sql too -- this keeps clean builds in sync
define version=3357
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
UPDATE CSR.STD_ALERT_TYPE 
   SET SEND_TRIGGER = 
	'A sheet has not been submitted, but it is past the reminder date. Reminder notifications are grouped together and sent out in a single e-mail. At most one e-mail will be sent per day. Only reminder notifications within the last 365 days are considered.'
 WHERE STD_ALERT_TYPE_ID = 5;
 
UPDATE CSR.STD_ALERT_TYPE 
   SET SEND_TRIGGER = 
	'A sheet has not been submitted, but it is past the due date. Overdue notifications are grouped together and sent out in a single e-mail. At most one e-mail will be sent per day. Only overdue notifications within the last 365 days are considered.'
 WHERE STD_ALERT_TYPE_ID = 3;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../delegation_pkg
@../delegation_body
@../sheet_body

@update_tail
