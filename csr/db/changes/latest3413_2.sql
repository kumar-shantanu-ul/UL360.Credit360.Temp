-- Please update version.sql too -- this keeps clean builds in sync
define version=3413
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables
CREATE OR REPLACE TYPE CSR.T_FIRST_SHEET_ACTION_DTM AS
	OBJECT (
		app_sid 				NUMBER(10),
		sheet_id 				NUMBER(10),
		first_action_dtm 		DATE
	);
/

CREATE OR REPLACE TYPE CSR.T_FIRST_SHEET_ACTION_DTM_TABLE AS
	TABLE OF CSR.T_FIRST_SHEET_ACTION_DTM;
/

DROP TABLE csr.temp_first_sheet_action_dtm;

CREATE OR REPLACE TYPE CSR.T_DELEGATION_DETAIL AS
	OBJECT (
		sheet_id						number(10),
		parent_sheet_id					number(10),
		delegation_sid					number(10),
		parent_delegation_sid			number(10),
		is_visible						number(1),
		name							varchar2(1023),
		start_dtm						date,
		end_dtm							date,
		period_set_id					number(10),
		period_interval_id				number(10),
		delegation_start_dtm			date,
		delegation_end_dtm				date,
		submission_dtm					date,
		status							number(10),
		sheet_action_description		varchar2(255),
		sheet_action_downstream			varchar2(255),
		fully_delegated					number(1),
		editing_url						varchar2(255),
		last_action_id					number(10),
		is_top_level					number(1),
		approve_dtm						date,
		delegated_by_user				number(1),
		percent_complete				number(10,0),
		rid								number(10),
		root_delegation_sid				number(10),
		parent_sid						number(10)
	);
/

CREATE OR REPLACE TYPE CSR.T_DELEGATION_DETAIL_TABLE AS
	TABLE OF CSR.T_DELEGATION_DETAIL;
/

CREATE OR REPLACE TYPE CSR.T_DELEGATION_USER AS
	OBJECT (
		delegation_sid 					NUMBER(10),
		user_sid 						NUMBER(10)
	);
/

CREATE OR REPLACE TYPE CSR.T_DELEGATION_USER_TABLE AS
	TABLE OF CSR.T_DELEGATION_USER;
/


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
@../delegation_pkg

@../delegation_body

@update_tail
