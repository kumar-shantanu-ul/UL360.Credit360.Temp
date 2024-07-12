-- Please update version.sql too -- this keeps clean builds in sync
define version=2919
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE chain.company_tab ADD (
	flow_capability_id			NUMBER(10, 0)
);

ALTER TABLE csrimp.chain_company_tab ADD (
	flow_capability_id			NUMBER(10, 0)
);

ALTER TABLE csr.audit_type_tab ADD (
	flow_capability_id			NUMBER(10, 0),
	CONSTRAINT fk_att_flow_cap FOREIGN KEY (app_sid, flow_capability_id) REFERENCES csr.customer_flow_capability (app_sid, flow_capability_id)
);

ALTER TABLE csrimp.audit_type_tab ADD (
	flow_capability_id			NUMBER(10, 0)
);

-- *** Grants ***

-- ** Cross schema constraints ***
ALTER TABLE chain.company_tab ADD (
	CONSTRAINT fk_ct_flow_cap FOREIGN KEY (app_sid, flow_capability_id) REFERENCES csr.customer_flow_capability (app_sid, flow_capability_id)
);

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.
-- csr/db/chain/create_views.sql
CREATE OR REPLACE VIEW CHAIN.v$supplier_capability AS
		SELECT sr.supplier_company_sid,
			   fsrc.flow_capability_id,
			   MAX(BITAND(fsrc.permission_set, 1)) + --security_pkg.PERMISSION_READ
			   MAX(BITAND(fsrc.permission_set, 2)) permission_set --security_pkg.PERMISSION_WRITE
		  FROM v$supplier_relationship sr
		  JOIN csr.flow_item fi ON fi.flow_item_id = sr.flow_item_id
		  JOIN csr.flow_state_role_capability fsrc ON fsrc.flow_state_id = fi.current_state_id
		  JOIN csr.supplier s ON s.company_sid = sr.supplier_company_sid
		  LEFT JOIN csr.region_role_member rrm
				 ON rrm.region_sid = s.region_sid
				AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
				AND rrm.role_sid = fsrc.role_sid
		 WHERE (sr.purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			    OR sr.supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'))
		   AND ((fsrc.flow_involvement_type_id = 1001 --csr.csr_data_pkg.FLOW_INV_TYPE_PURCHASER
				  AND sr.purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'))
			 OR (fsrc.flow_involvement_type_id = 1002 --csr.csr_data_pkg.FLOW_INV_TYPE_SUPPLIER
			 	   AND sr.supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'))
			 OR rrm.role_sid IS NOT NULL)
		GROUP BY sr.supplier_company_sid, fsrc.flow_capability_id;

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../audit_pkg
@../chain/plugin_pkg

@../audit_body
@../flow_body
@../schema_body
@../chain/company_body
@../chain/plugin_body
@../csrimp/imp_body

@update_tail
