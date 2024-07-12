-- Please update version.sql too -- this keeps clean builds in sync
define version=3337
define minor_version=3
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
-- delete all pending menu SOs
DECLARE
	v_act 			security.security_pkg.T_ACT_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);
	
	FOR r IN (
		SELECT m.sid_id
		  FROM security.menu m
		  JOIN security.securable_object so ON so.sid_id = m.sid_id
		  JOIN csr.customer c ON c.app_sid = so.application_sid_id
		 WHERE LOWER(action) LIKE '%pending%'
	) LOOP
		security.securableobject_pkg.deleteso(v_act, r.sid_id);
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\customer_pkg
@..\issue_pkg

@..\customer_body
@..\region_body
@..\issue_body

@update_tail
