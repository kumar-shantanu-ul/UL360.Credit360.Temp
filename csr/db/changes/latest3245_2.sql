-- Please update version.sql too -- this keeps clean builds in sync
define version=3245
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
BEGIN
	FOR r IN (
		SELECT c.app_sid, c.host, m.sid_id, m.action
		  FROM security.menu m
		  JOIN security.securable_object so ON m.sid_id = so.sid_id
		  JOIN csr.customer c ON so.application_sid_id = c.app_sid
		 WHERE action LIKE '/training%'
		 ORDER BY host ASC, sid_id DESC
	)
	LOOP
		BEGIN
			security.user_pkg.logonadmin(r.host);
			security.securableobject_pkg.deleteSO(security.security_pkg.getact, r.sid_id);
			security.user_pkg.logonadmin();
		EXCEPTION
			WHEN OTHERS THEN NULL;
		END;
	END LOOP;
END;
/

BEGIN
	FOR r IN (
		SELECT wr.sid_id, c.host
		  FROM security.web_resource wr
		  JOIN security.securable_object so ON wr.sid_id = so.sid_id
		  JOIN csr.customer c ON so.application_sid_id = c.app_sid
		 WHERE path = '/training/videos'
		 ORDER BY host ASC
	)
	LOOP
		BEGIN
			security.user_pkg.logonadmin(r.host);
			security.securableobject_pkg.deleteSO(security.security_pkg.getact, r.sid_id);
			security.user_pkg.logonadmin();
		EXCEPTION
			WHEN OTHERS THEN NULL;
		END;
	END LOOP;
END;
/

BEGIN
	FOR r IN (
		SELECT so.sid_id, c.host
		 FROM security.securable_object so
		  JOIN csr.customer c ON so.application_sid_id = c.app_sid
		 WHERE so.name = 'Training Material'
		   AND so.class_id = (SELECT class_id FROM security.securable_object_class WHERE class_name = 'CSRUserGroup')
)
	LOOP
		BEGIN
			security.user_pkg.logonadmin(r.host);
			security.securableobject_pkg.deleteSO(security.security_pkg.getact, r.sid_id);
			security.user_pkg.logonadmin();
		EXCEPTION
			WHEN OTHERS THEN NULL;
		END;
	END LOOP;
END;
/


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
