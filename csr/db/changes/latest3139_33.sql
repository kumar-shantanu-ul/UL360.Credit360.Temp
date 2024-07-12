-- Please update version.sql too -- this keeps clean builds in sync
define version=3139
define minor_version=33
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

--remove old export dataviews that were not deleted by the application
BEGIN
	FOR l IN (
		SELECT host 
		  FROM csr.customer
	)
	LOOP
		security.user_pkg.logonadmin(l.host);
		FOR r IN (
			SELECT dataview_sid 
			  FROM csr.dataview
			WHERE parent_sid IN(
				SELECT sid_id
				  FROM SECURITY.SECURABLE_OBJECT 
				 WHERE name = 'BatchExportDataviews')
		)
		LOOP
			security.securableobject_pkg.DeleteSO(security.security_pkg.GetACT, r.dataview_sid);
		END LOOP;
	END LOOP;
END;
/
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
