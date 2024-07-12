-- Please update version.sql too -- this keeps clean builds in sync
define version=3203
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

CREATE OR REPLACE TYPE CSR.T_SID_AND_PATH_AND_DESC_ROW AS
  OBJECT ( 
	pos				NUMBER(10,0),
	sid_id			NUMBER(10,0),
	path			VARCHAR2(2047),
	description		VARCHAR2(2047)
  );
/
CREATE OR REPLACE TYPE CSR.T_SID_AND_PATH_AND_DESC_TABLE AS 
  TABLE OF CSR.T_SID_AND_PATH_AND_DESC_ROW;
/


-- Alter tables
ALTER TABLE csr.batch_job_srt_refresh ADD user_sid NUMBER(10) DEFAULT NVL(SYS_CONTEXT('SECURITY','SID'),3) NOT NULL;

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
@../region_tree_pkg

@../region_tree_body

@update_tail
