-- Please update version.sql too -- this keeps clean builds in sync
define version=3200
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

CREATE OR REPLACE VIEW csr.v$delegation_user AS
    SELECT app_sid, delegation_sid, user_sid
      FROM csr.delegation_user
      WHERE inherited_from_sid = delegation_sid
     UNION 
    SELECT d.app_sid, d.delegation_sid, rrm.user_sid
      FROM delegation d
        JOIN delegation_role dlr ON d.delegation_sid = dlr.delegation_sid AND d.app_sid = dlr.app_sid AND dlr.inherited_from_sid = d.delegation_sid
        JOIN delegation_region dr ON d.delegation_sid = dr.delegation_sid AND d.app_sid = dr.app_sid
        JOIN region_role_member rrm ON dr.region_sid = rrm.region_sid AND dlr.role_sid = rrm.role_sid AND dr.app_sid = rrm.app_sid AND dlr.app_sid = rrm.app_sid
        ;

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
