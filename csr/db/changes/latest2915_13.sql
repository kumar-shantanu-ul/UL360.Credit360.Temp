-- Please update version.sql too -- this keeps clean builds in sync
define version=2915
define minor_version=13
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
-- Schema didn't get updated until March 2016 (change made in June 2015).
DECLARE
	v_cnt	NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM all_tab_cols
	 WHERE owner = 'CSRIMP'
	   AND table_name = 'INTERNAL_AUDIT_TYPE'
	   AND column_name = 'ACTIVE';
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE '
		ALTER TABLE csrimp.internal_audit_type ADD (
			active            NUMBER(1) DEFAULT 1,
			CONSTRAINT chk_audit_type_act_1_0 CHECK (active IN (1, 0))
		)';
	END IF;
END;
/

-- Ancient CMS changes that never made it into the schema...
DECLARE
	v_cnt	NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM all_tab_columns
	 WHERE owner = 'CMS'
	   AND table_name = 'LINK_TRACK'
	   AND column_name = 'APP_SID'
	   AND nullable = 'N';

	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE cms.link_track MODIFY app_sid NOT NULL';
	END IF;
END;
/

DECLARE
	v_cnt	NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM all_tab_columns
	 WHERE owner = 'CMS'
	   AND table_name = 'LINK_TRACK'
	   AND column_name = 'COLUMN_SID'
	   AND nullable = 'N';

	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE cms.link_track MODIFY column_sid NOT NULL';
	END IF;
END;
/

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
