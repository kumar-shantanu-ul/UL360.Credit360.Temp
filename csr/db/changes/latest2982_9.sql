-- Please update version.sql too -- this keeps clean builds in sync
define version=2982
define minor_version=9
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.initiative_user DROP CONSTRAINT fk_init_init_user;

BEGIN
	security.user_pkg.LogonAdmin;

	FOR r IN (
		SELECT iu.app_sid, iu.initiative_sid, iu.project_sid old_project_sid, i.project_sid new_project_sid
		  FROM csr.initiative_user iu
		  JOIN csr.initiative i ON iu.app_sid = i.app_sid AND iu.initiative_sid = i.initiative_sid
		 WHERE (iu.app_sid, iu.initiative_sid, iu.project_sid) NOT IN (
			SELECT app_sid, initiative_sid, project_sid 
			  FROM csr.initiative
		 )
	) LOOP
		UPDATE csr.initiative_user
		   SET project_sid = r.new_project_sid
		 WHERE app_sid = r.app_sid
		   AND initiative_sid = r.initiative_sid
		   AND project_sid = r.old_project_sid;
	END LOOP;
END;
/

ALTER TABLE csr.initiative_user ADD CONSTRAINT fk_init_init_user
    FOREIGN KEY (app_sid, initiative_sid, project_sid)
    REFERENCES csr.initiative(app_sid, initiative_sid, project_sid) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
;
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
@../initiative_body

@update_tail
