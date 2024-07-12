-- Please update version.sql too -- this keeps clean builds in sync
define version=3111
define minor_version=11
@update_header

-- *** DDL ***
-- Create tables
BEGIN
	FOR r IN (
		SELECT * FROM all_indexes WHERE OWNER ='CSR' AND index_name = 'PK_ALT_TAG_GROUP'
	)
	LOOP
		EXECUTE IMMEDIATE 'DROP INDEX CSR.PK_ALT_TAG_GROUP';
	END LOOP;
END;
/



-- Alter tables

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
