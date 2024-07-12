-- Please update version.sql too -- this keeps clean builds in sync
define version=3189
define minor_version=11
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
-- @BILL Took 15 minutes on impdb
ALTER TABLE csr.sheet_history ADD (
	is_system_note	NUMBER(1, 0) DEFAULT 0 NOT NULL
);

ALTER TABLE csrimp.sheet_history ADD (
	is_system_note	NUMBER (1, 0) NOT NULL
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
-- @BILL Might want to move this after package recompilations as could take a few minutes. Select count equivalent takes 1 min on live. Update took 3 mins on impdb.
-- There is no real rush it doesn't stop anything from working and thus can be run separately.  
BEGIN
FOR r IN (SELECT distinct host FROM csr.sheet_history sh JOIN csr.customer c ON sh.app_sid = c.app_sid)
LOOP
	security.user_pkg.logonadmin(r.host);
	
	UPDATE csr.sheet_history sh
	   SET is_system_note = 1 
	 WHERE note like 'Created'
		OR note like 'Set status according to parent sheet.'
		OR note like 'Automatic submission of this sheet was blocked because there are errors'
		OR note like 'Rollback requested'
		OR note like 'Automatically approved'
		OR note like 'Automatic approval failed: intolerances found'
		OR note like 'Data Change Request automatically approved and form returned to user for editing';
		
	COMMIT;
END LOOP;

END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../sheet_pkg

@../auto_approve_body
@../delegation_body
@../sheet_body
@../schema_body
@../csrimp/imp_body

@update_tail
