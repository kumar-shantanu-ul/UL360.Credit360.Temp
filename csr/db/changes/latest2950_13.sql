-- Please update version.sql too -- this keeps clean builds in sync
define version=2950
define minor_version=13
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- INITIATIVE_METRIC.LOOKUP_KEY was added in latest2029 as nullable, but is not null in create_schema.
-- Fix any databases created after latest2029.
DECLARE
	v_nullable		VARCHAR2(1);
BEGIN
	SELECT nullable
	  INTO v_nullable
	  FROM all_tab_columns
	 WHERE owner = 'CSR' AND table_name = 'INITIATIVE_METRIC' AND COLUMN_NAME = 'LOOKUP_KEY';
	IF v_nullable = 'N' THEN
		EXECUTE IMMEDIATE 'ALTER TABLE csr.initiative_metric MODIFY(LOOKUP_KEY NULL)';
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

@@../initiative_metric_pkg

@@../initiative_metric_body

@update_tail
