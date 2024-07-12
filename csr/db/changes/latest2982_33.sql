-- Please update version.sql too -- this keeps clean builds in sync
define version=2982
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
BEGIN
    security.user_pkg.logonAdmin();

    UPDATE csr.tab_user
       SET is_hidden = 0
     WHERE (tab_id, user_sid) IN (
        SELECT tu.tab_id, tu.user_sid
          FROM csr.tab t
          JOIN csr.tab_user tu
            ON t.tab_id = tu.tab_id
         WHERE t.is_hideable = 0
           AND tu.is_hidden = 1
     );
    
    security.user_pkg.LogOff(SYS_CONTEXT('SECURITY','ACT'));
END;
/


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\portlet_body

@update_tail
