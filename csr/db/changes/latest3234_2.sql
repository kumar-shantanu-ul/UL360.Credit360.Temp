-- Please update version.sql too -- this keeps clean builds in sync
define version=3234
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

EXEC security.user_pkg.logonadmin('');
      
DECLARE
	v_compliance_language_id NUMBER;
BEGIN 
	FOR r IN (
		SELECT app_sid FROM csr.compliance_language WHERE lang_id=53 GROUP BY app_sid, lang_id HAVING COUNT(*) > 1
	)
	LOOP
		SELECT MIN(compliance_language_id)
		  INTO v_compliance_language_id
		  FROM csr.compliance_language 
		 WHERE app_sid = r.app_sid
		   AND lang_id = 53;

		DELETE FROM csr.compliance_language
		 WHERE app_sid = r.app_sid
		   AND lang_id = 53
		   AND compliance_language_id != v_compliance_language_id;  
	END LOOP;
END;
/ 

ALTER TABLE csr.compliance_language
ADD CONSTRAINT uk_compliance_language UNIQUE (app_sid, lang_id);
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\enable_body

@update_tail
