-- Please update version.sql too -- this keeps clean builds in sync
define version=2526
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
DECLARE
	v_count			number(10);
BEGIN
	SELECT COUNT(*) INTO v_count FROM all_tab_cols WHERE owner = 'CMS' AND table_name = 'TAB_COLUMN' AND column_name = 'AUTO_SEQUENCE';
	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE cms.tab_column ADD auto_sequence VARCHAR2(65)';
	ELSE
		EXECUTE IMMEDIATE 'ALTER TABLE cms.tab_column MODIFY auto_sequence VARCHAR2(65)';
	END IF;
END;
/

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***

-- *** Data changes ***
-- RLS

-- Data

-- *** Packages ***
@..\..\..\aspen2\cms\db\cms_tab_body
@..\..\..\aspen2\cms\db\tab_body

@update_tail
