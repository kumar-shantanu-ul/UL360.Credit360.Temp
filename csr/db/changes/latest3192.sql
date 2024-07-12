-- Please update version.sql too -- this keeps clean builds in sync
define version=3192
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
     UNION ALL
    SELECT DISTINCT d.app_sid, d.delegation_sid, rrm.user_sid
      FROM csr.delegation d
      JOIN csr.delegation_role dlr ON d.delegation_sid = dlr.delegation_sid AND d.app_sid = dlr.app_sid AND dlr.inherited_from_sid = d.delegation_sid
      JOIN csr.delegation_region dr ON d.delegation_sid = dr.delegation_sid AND d.app_sid = dr.app_sid
      JOIN csr.region_role_member rrm ON rrm.region_sid = dr.region_sid AND rrm.role_sid = dlr.role_sid AND rrm.app_sid = d.app_sid
	 WHERE NOT EXISTS (
		SELECT NULL
		  FROM csr.delegation_user
		 WHERE user_sid = rrm.user_sid
		   AND delegation_sid = d.delegation_sid);

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
