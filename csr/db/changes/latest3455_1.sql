-- Please update version.sql too -- this keeps clean builds in sync
define version=3455
define minor_version=1
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
	security.user_pkg.logonadmin;
    FOR r in (
        select sid_Id from security.securable_object where name = 'Enable Delegation Overlap Warning'
    )
    LOOP
        security.securableobject_pkg.deleteso(security.security_pkg.getact, r.sid_id);
    END LOOP;
    delete from csr.capability where name = 'Enable Delegation Overlap Warning';
END;
/
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@..\deleg_plan_body

@update_tail
