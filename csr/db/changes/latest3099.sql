-- Please update version.sql too -- this keeps clean builds in sync
define version=3099
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.
-- C:\cvs\csr\db\chain\create_view.sql
DROP VIEW chain.v$all_purchaser_involvement;

CREATE OR REPLACE VIEW chain.v$purchaser_involvement AS
	SELECT sit.flow_involvement_type_id, sr.supplier_company_sid
	  FROM supplier_relationship sr
	  JOIN company pc ON pc.company_sid = sr.purchaser_company_sid
	  LEFT JOIN csr.supplier ps ON ps.company_sid = pc.company_sid
	  JOIN company sc ON sc.company_sid = sr.supplier_company_sid
	  JOIN supplier_involvement_type sit
		ON (sit.user_company_type_id IS NULL OR sit.user_company_type_id = pc.company_type_id)
	   AND (sit.page_company_type_id IS NULL OR sit.page_company_type_id = sc.company_type_id)
	   AND (sit.purchaser_type = 1 /*chain_pkg.PURCHASER_TYPE_ANY*/
		OR (sit.purchaser_type = 2 /*chain_pkg.PURCHASER_TYPE_PRIMARY*/ AND sr.is_primary = 1)
		OR (sit.purchaser_type = 3 /*chain_pkg.PURCHASER_TYPE_OWNER*/ AND pc.company_sid = sc.parent_sid)
	   )
	  LEFT JOIN csr.region_role_member rrm
	    ON rrm.region_sid = ps.region_sid
	   AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
	   AND rrm.role_sid = sit.restrict_to_role_sid
	 WHERE pc.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND pc.deleted = 0
	   AND sc.deleted = 0
	   AND (sit.restrict_to_role_sid IS NULL OR rrm.user_sid IS NOT NULL);


-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../audit_body
@../campaign_body
@../chain/supplier_flow_body

@update_tail
