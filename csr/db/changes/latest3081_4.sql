-- Please update version.sql too -- this keeps clean builds in sync
define version=3081
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

BEGIN
  FOR r IN (SELECT p.app_sid, p.profile_id, p.name FROM CSR.EMISSION_FACTOR_PROFILE p
			  JOIN CSR.EMISSION_FACTOR_PROFILE s ON p.app_sid = s.app_sid AND p.name = s.name AND s.profile_id != p.profile_id
			 ORDER BY p.app_sid)
	LOOP
		UPDATE CSR.EMISSION_FACTOR_PROFILE
		   SET name = r.name||'('||r.profile_id||')'
		 WHERE app_sid = r.app_sid
		   AND profile_id = r.profile_id;
	END LOOP;
END;
/

ALTER TABLE CSR.EMISSION_FACTOR_PROFILE ADD CONSTRAINT UK_EMISSION_FACTOR_PROFILE UNIQUE (APP_SID, NAME);

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
