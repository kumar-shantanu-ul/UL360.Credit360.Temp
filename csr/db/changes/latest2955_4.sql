-- Please update version.sql too -- this keeps clean builds in sync
define version=2955
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- Remove duplicates before adding constraint
DELETE FROM security.user_certificates 
 WHERE rowid IN (
		SELECT MAX(ROWID) FROM security.user_certificates GROUP BY sid_id, cert_hash HAVING COUNT(*) > 1
	   );
	   
-- Add constraint
DECLARE
	v_check NUMBER(1);
BEGIN
	SELECT COUNT(constraint_name)
	  INTO v_check
	  FROM all_constraints
	 WHERE owner = 'SECURITY'
	   AND table_name = 'USER_CERTIFICATES'
	   AND constraint_name = 'PK_USER_CERTIFICATES';
	IF v_check = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE security.USER_CERTIFICATES ADD CONSTRAINT PK_USER_CERTIFICATES PRIMARY KEY (SID_ID, CERT_HASH)';
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
