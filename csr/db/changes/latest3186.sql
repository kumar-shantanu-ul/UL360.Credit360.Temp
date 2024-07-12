-- Please update version.sql too -- this keeps clean builds in sync
define version=3186
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
DECLARE
	v_count		NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_tab_columns
	 WHERE owner = 'CSR'
	   AND table_name = 'SCHEDULED_STORED_PROC'
	   AND column_name = 'ARGS';
	
	IF v_count = 1 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE csr.scheduled_stored_proc DROP CONSTRAINT pk_ssp DROP INDEX';
		EXECUTE IMMEDIATE 'ALTER TABLE csr.scheduled_stored_proc DROP COLUMN args';
		EXECUTE IMMEDIATE 'ALTER TABLE csr.scheduled_stored_proc ADD CONSTRAINT pk_ssp PRIMARY KEY (app_sid, sp)';
	END IF;
END;
/

-- *** Grants ***

GRANT EXECUTE ON csr.ssp_pkg TO web_user;

-- ** Cross schema constraints ***

-- *** Views ***

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***

@..\dataview_body

@update_tail
