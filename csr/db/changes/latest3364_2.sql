-- Please update version.sql too -- this keeps clean builds in sync
define version=3364
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

CREATE GLOBAL TEMPORARY TABLE CSR.TT_ISSUES_DUE (
	APP_SID					NUMBER(10)		NOT NULL,
	ISSUE_ID				NUMBER(10)		NOT NULL,
	DUE_DTM					DATE,
	EMAIL_INVOLVED_ROLES	NUMBER(1),		
	email_involved_users	NUMBER(1),		
	assigned_to_user_sid	NUMBER(10),		
	region_sid				NUMBER(10),		
	region_2_sid			NUMBER(10),		
	issue_priority_id		NUMBER(10),		
	alert_pending_due_days	NUMBER(10),		
	issue_type				VARCHAR2(255),		
	issue_label				VARCHAR2(2048),		
	issue_ref				NUMBER(10),			
	is_critical				NUMBER(1),		
	raised_dtm				DATE,		
	closed_dtm				DATE,		
	resolved_dtm			DATE,		
	rejected_dtm			DATE,		
	assigned_to_role_sid	NUMBER(10)
)ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE CSR.TT_ISSUES_OVERDUE (
	APP_SID					NUMBER(10)		NOT NULL,
	ISSUE_ID				NUMBER(10)		NOT NULL,
	DUE_DTM					DATE,
	EMAIL_INVOLVED_ROLES	NUMBER(1),		
	email_involved_users	NUMBER(1),		
	assigned_to_user_sid	NUMBER(10),		
	region_sid				NUMBER(10),		
	region_2_sid			NUMBER(10),		
	issue_priority_id		NUMBER(10),		
	alert_overdue_days		NUMBER(10),		
	issue_type				VARCHAR2(255),		
	issue_label				VARCHAR2(2048),		
	issue_ref				NUMBER(10),		
	is_critical				NUMBER(1),		
	raised_dtm				DATE,		
	closed_dtm				DATE,		
	resolved_dtm			DATE,		
	rejected_dtm			DATE,		
	assigned_to_role_sid	NUMBER(10)
)ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE CSR.TT_ISSUE_USER (
	APP_SID					NUMBER(10)		NOT NULL,
	ISSUE_ID				NUMBER(10)		NOT NULL,
	USER_SID				NUMBER(10)		NOT NULL
)ON COMMIT DELETE ROWS;


-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../issue_body

@update_tail
