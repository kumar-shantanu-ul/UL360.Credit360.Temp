-- Please update version.sql too -- this keeps clean builds in sync
define version=3071
define minor_version=38
@update_header

-- *** DDL ***
-- Create tables

CREATE TABLE chain.supplier_involvement_type (
	app_sid							NUMBER(10)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	flow_involvement_type_id		NUMBER(10)	NOT NULL,
	user_company_type_id			NUMBER(10)	NULL,
	page_company_type_id			NUMBER(10)	NULL,
	purchaser_type					NUMBER(2)	NOT NULL,
	restrict_to_role_sid			NUMBER(10)	NULL,
	CONSTRAINT pk_supplier_involvement_type PRIMARY KEY (app_sid, flow_involvement_type_id),
	CONSTRAINT fk_supp_inv_type_sup_rel FOREIGN KEY (app_sid, user_company_type_id, page_company_type_id)
	REFERENCES chain.company_type_relationship (app_sid, primary_company_type_id, secondary_company_type_id),
	CONSTRAINT fk_supp_inv_type_co_type_role FOREIGN KEY (app_sid, user_company_type_id, restrict_to_role_sid)
	REFERENCES chain.company_type_role (app_sid, company_type_id, role_sid),
	CONSTRAINT uk_supp_inv_type UNIQUE (app_sid, user_company_type_id, page_company_type_id, purchaser_type, restrict_to_role_sid),
	CONSTRAINT chk_supp_inv_type_pur_type CHECK (purchaser_type IN (1,2,3))
);

CREATE TABLE csrimp.chain_supplier_inv_type (
	csrimp_session_id 				NUMBER(10)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	flow_involvement_type_id		NUMBER(10)	NOT NULL,
	user_company_type_id			NUMBER(10)	NULL,
	page_company_type_id			NUMBER(10)	NULL,
	purchaser_type					NUMBER(2)	NOT NULL,
	restrict_to_role_sid			NUMBER(10)	NULL,
	CONSTRAINT pk_chain_supp_inv_type PRIMARY KEY (csrimp_session_id, flow_involvement_type_id),
	CONSTRAINT fk_chain_supp_inv_type_ses FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);

-- Alter tables

ALTER TABLE csr.flow_involvement_type
ADD lookup_key VARCHAR2(100);

ALTER TABLE csrimp.flow_involvement_type
ADD lookup_key VARCHAR2(100);

ALTER TABLE csr.flow_involvement_type
RENAME CONSTRAINT UK_LABEL TO UK_FLOW_INV_TYPE_LABEL;

CREATE UNIQUE INDEX CSR.UK_FLOW_INV_TYPE_KEY ON CSR.FLOW_INVOLVEMENT_TYPE (APP_SID, NVL(UPPER(LOOKUP_KEY), FLOW_INVOLVEMENT_TYPE_ID))
;

-- *** Grants ***
grant references on csr.flow_involvement_type to chain;
grant select, insert, update, delete on csrimp.chain_supplier_inv_type to tool_user;
grant select, insert, update on chain.supplier_involvement_type to csrimp;
grant select on chain.supplier_involvement_type to csr;

-- ** Cross schema constraints ***

ALTER TABLE chain.supplier_involvement_type 
ADD CONSTRAINT fk_supp_inv_type_inv_type FOREIGN KEY (app_sid, flow_involvement_type_id)
REFERENCES csr.flow_involvement_type (app_sid, flow_involvement_type_id);

ALTER TABLE chain.supplier_involvement_type 
ADD CONSTRAINT fk_supp_inv_type_role FOREIGN KEY (app_sid, restrict_to_role_sid)
REFERENCES csr.role(app_sid, role_sid);

CREATE INDEX chain.ix_sup_inv_t_ct_rel ON chain.supplier_involvement_type (app_sid, user_company_type_id, page_company_type_id);
CREATE INDEX chain.ix_sup_inv_t_co_type_role ON chain.supplier_involvement_type (app_sid, user_company_type_id, restrict_to_role_sid);
CREATE INDEX chain.ix_sup_inv_t_role ON chain.supplier_involvement_type (app_sid, restrict_to_role_sid);

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- /csr/db/chain/create_views.sql
CREATE OR REPLACE VIEW chain.v$all_purchaser_involvement AS
	SELECT sit.flow_involvement_type_id, sr.purchaser_company_sid, sr.supplier_company_sid,
		rrm.user_sid ct_role_user_sid
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
	  LEFT JOIN v$company_user cu -- this will do for now, but it probably performs horribly
	    ON cu.company_sid = pc.company_sid
	  LEFT JOIN csr.region_role_member rrm
	    ON rrm.region_sid = ps.region_sid
	   AND rrm.user_sid = cu.user_sid
	   AND rrm.role_sid = sit.restrict_to_role_sid
	 WHERE pc.deleted = 0
	   AND sc.deleted = 0
	   AND (sit.restrict_to_role_sid IS NULL OR rrm.user_sid IS NOT NULL);

-- /csr/db/chain/create_views.sql
CREATE OR REPLACE VIEW chain.v$purchaser_involvement AS
	SELECT flow_involvement_type_id, supplier_company_sid
	  FROM v$all_purchaser_involvement
	 WHERE purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND NVL(ct_role_user_sid, SYS_CONTEXT('SECURITY', 'SID')) = SYS_CONTEXT('SECURITY', 'SID');

-- /csr/db/chain/create_views.sql
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
	  LEFT JOIN v$purchaser_involvement inv
		ON inv.flow_involvement_type_id = fsrc.flow_involvement_type_id
	   AND inv.supplier_company_sid = sr.supplier_company_sid
	 WHERE (sr.purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			OR sr.supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'))
	   AND (inv.flow_involvement_type_id IS NOT NULL
	    OR (fsrc.flow_involvement_type_id = 1002 /*csr.csr_data_pkg.FLOW_INV_TYPE_SUPPLIER*/
			AND sr.supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'))
	    OR rrm.role_sid IS NOT NULL)
	GROUP BY sr.supplier_company_sid, fsrc.flow_capability_id;

-- *** Data changes ***
-- RLS

-- Data

DECLARE
	v_flow_involvement_type_id				NUMBER;
BEGIN
	security.user_pkg.LogonAdmin;
	
	UPDATE csr.flow_involvement_type
	   SET lookup_key = 'PURCHASER' /*PURCHASER_INV_TYPE_KEY*/
	 WHERE flow_involvement_type_id = 1001 /* csr.csr_data_pkg.FLOW_INV_TYPE_PURCHASER */;

	INSERT INTO chain.supplier_involvement_type(app_sid, flow_involvement_type_id, purchaser_type)
	SELECT app_sid, 1001, 1 /*  */
	  FROM csr.flow_involvement_type
	 WHERE flow_involvement_type_id = 1001;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@..\chain\chain_pkg
@..\chain\company_pkg
@..\chain\type_capability_pkg
@..\chain\supplier_flow_pkg
@..\flow_pkg
@..\schema_pkg

@..\flow_body
@..\enable_body
@..\chain\type_capability_body
@..\chain\company_body
@..\chain\setup_body
@..\chain\supplier_flow_body
@..\chain\test_chain_utils_body
@..\csrimp\imp_body
@..\schema_body

@update_tail
