-- Please update version.sql too -- this keeps clean builds in sync
define version=3359
define minor_version=11
@update_header

-- *** DDL ***
-- Create tables
CREATE OR REPLACE TYPE CSR.T_SHEET_INFO AS
  OBJECT (
	SHEET_ID						NUMBER(10,0),
	DELEGATION_SID					NUMBER(10,0),
	PARENT_DELEGATION_SID			NUMBER(10,0),
	NAME							VARCHAR2(1023),
	CAN_SAVE						NUMBER(10,0),
	CAN_SUBMIT						NUMBER(10,0),
	CAN_ACCEPT						NUMBER(10,0),
	CAN_RETURN						NUMBER(10,0),
	CAN_DELEGATE					NUMBER(10,0),
	CAN_VIEW						NUMBER(10,0),
	CAN_OVERRIDE_DELEGATOR			NUMBER(10,0),
	CAN_COPY_FORWARD				NUMBER(10,0),
	LAST_ACTION_ID					NUMBER(10,0),
	START_DTM						DATE,
	END_DTM							DATE,
	PERIOD_SET_ID					NUMBER(10),
	PERIOD_INTERVAL_ID				NUMBER(10),
	GROUP_BY						VARCHAR2(128),
	NOTE							CLOB,
	USER_LEVEL						NUMBER(10,0),
	IS_TOP_LEVEL					NUMBER(10,0),
	IS_READ_ONLY					NUMBER(1),
	CAN_EXPLAIN						NUMBER(1)
  );
/

-- Alter tables
alter table csr.temp_delegation_detail modify name varchar2(1023);
alter table csr.temp_delegation_for_region modify name varchar2(1023);

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

@update_tail
