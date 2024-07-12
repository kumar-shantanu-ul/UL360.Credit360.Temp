-- Please update version.sql too -- this keeps clean builds in sync
define version=3017
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
DECLARE v_max_is_id NUMBER;
BEGIN
	security.user_pkg.logonadmin;
	
	SELECT NVL(MAX(import_source_id), 1)
	  INTO v_max_is_id
	  FROM chain.import_source;
	
	EXECUTE IMMEDIATE 'ALTER SEQUENCE chain.import_source_id_seq INCREMENT BY ' || v_max_is_id;
	
	SELECT chain.import_source_id_seq.NEXTVAL
	  INTO v_max_is_id
	  FROM dual;
	
	EXECUTE IMMEDIATE 'ALTER SEQUENCE chain.import_source_id_seq INCREMENT BY 1';
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

@../chain/setup_body

@update_tail
