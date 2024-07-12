-- Please update version.sql too -- this keeps clean builds in sync
define version=3170
define minor_version=18
@update_header

-- *** DDL ***
-- Create tables

CREATE SEQUENCE chain.company_type_role_id_seq
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOORDER;

CREATE SEQUENCE chain.comp_tab_comp_type_role_id_seq
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOORDER;

CREATE TABLE chain.company_tab_company_type_role(
	app_sid							NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	comp_tab_comp_type_role_id		NUMBER(10, 0)	NOT NULL,
	company_tab_id					NUMBER(10, 0)	NOT NULL,
	company_group_type_id			NUMBER(10, 0),
	company_type_role_id			NUMBER(10, 0)
);

CREATE TABLE csrimp.chain_comp_tab_comp_type_role(
	csrimp_session_id				NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	comp_tab_comp_type_role_id		NUMBER(10, 0)	NOT NULL,
	company_tab_id					NUMBER(10, 0)	NOT NULL,
	company_group_type_id			NUMBER(10, 0),
	company_type_role_id			NUMBER(10, 0)
);

CREATE TABLE csrimp.map_chain_company_type_role(
	csrimp_session_id				NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_company_type_role_id		NUMBER(10, 0)	NOT NULL,
	new_company_type_role_id		NUMBER(10, 0)	NOT NULL
);

CREATE TABLE csrimp.map_chain_cmp_tab_cmp_typ_role(
	csrimp_session_id				NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_comp_tab_comp_type_role_id	NUMBER(10, 0)	NOT NULL,
	new_comp_tab_comp_type_role_id	NUMBER(10, 0)	NOT NULL
);

-- Alter tables

-- add new column company_type_role.company_type_role_id and set it PK
ALTER TABLE chain.company_type_role
  ADD company_type_role_id	NUMBER(10, 0);

UPDATE chain.company_type_role
   SET company_type_role_id = chain.company_type_role_id_seq.NEXTVAL;

ALTER TABLE chain.company_type_capability
 DROP CONSTRAINT fk_ctc_company_type_role;

ALTER TABLE chain.supplier_involvement_type
 DROP CONSTRAINT fk_supp_inv_type_co_type_role;

ALTER TABLE chain.company_type_role
 DROP CONSTRAINT pk_company_type_role;

 ALTER TABLE chain.company_type_role
MODIFY company_type_role_id	NUMBER(10, 0) NOT NULL;

ALTER TABLE chain.company_type_role ADD CONSTRAINT pk_company_type_role
	PRIMARY KEY (app_sid, company_type_role_id);

ALTER TABLE chain.company_type_role ADD CONSTRAINT uk_company_type_role
	UNIQUE (app_sid, company_type_id, role_sid) USING INDEX;
  
ALTER TABLE chain.company_type_capability ADD CONSTRAINT fk_ctc_company_type_role
	FOREIGN KEY (app_sid, primary_company_type_id, primary_company_type_role_sid)
	REFERENCES chain.company_type_role(app_sid, company_type_id, role_sid);

ALTER TABLE chain.supplier_involvement_type ADD CONSTRAINT fk_supp_inv_type_co_type_role
	FOREIGN KEY (app_sid, user_company_type_id, restrict_to_role_sid)
	REFERENCES chain.company_type_role (app_sid, company_type_id, role_sid);

-- csrimp for new column company_type_role.company_type_role_id
ALTER TABLE csrimp.chain_company_type_role
 DROP CONSTRAINT pk_chain_company_type_role;

ALTER TABLE csrimp.chain_company_type_role
  ADD company_type_role_id NUMBER(10, 0) NOT NULL;

ALTER TABLE csrimp.chain_company_type_role ADD CONSTRAINT uk_chain_company_type_role
	UNIQUE (CSRIMP_SESSION_ID, COMPANY_TYPE_ID, ROLE_SID) USING INDEX;

ALTER TABLE csrimp.chain_company_type_role ADD CONSTRAINT pk_chain_company_type_role
	PRIMARY KEY (CSRIMP_SESSION_ID, COMPANY_TYPE_ROLE_ID);

-- constraints on chain.company_tab_company_type_role
ALTER TABLE chain.company_tab_company_type_role ADD CONSTRAINT chk_company_type_role_group
	CHECK ((company_group_type_id IS NOT NULL AND company_type_role_id IS NULL) OR (company_group_type_id IS NULL AND company_type_role_id IS NOT NULL));

ALTER TABLE chain.company_tab_company_type_role ADD CONSTRAINT fk_ctctr_company_tab
	FOREIGN KEY (app_sid, company_tab_id)
	REFERENCES chain.company_tab (app_sid, company_tab_id);

ALTER TABLE chain.company_tab_company_type_role ADD CONSTRAINT fk_ctctr_company_group_type
	FOREIGN KEY (company_group_type_id)
	REFERENCES chain.company_group_type (company_group_type_id);

ALTER TABLE chain.company_tab_company_type_role ADD CONSTRAINT fk_ctctr_company_type_role
	FOREIGN KEY (app_sid, company_type_role_id)
	REFERENCES chain.company_type_role (app_sid, company_type_role_id);

ALTER TABLE chain.company_tab_company_type_role ADD CONSTRAINT pk_comp_tab_comp_type_role
	PRIMARY KEY (app_sid, comp_tab_comp_type_role_id);

-- csrimp table for company_tab_company_type_role
ALTER TABLE csrimp.chain_comp_tab_comp_type_role ADD CONSTRAINT pk_chain_cmp_tab_cmp_type_role
	PRIMARY KEY (csrimp_session_id, comp_tab_comp_type_role_id);

ALTER TABLE csrimp.chain_comp_tab_comp_type_role ADD CONSTRAINT fk_chain_cmp_tab_type_role_is
	FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE;

-- csrimp constraints on mapping table for company_type_role.company_type_role_id
ALTER TABLE csrimp.map_chain_company_type_role ADD CONSTRAINT pk_map_chain_company_type_role
	PRIMARY KEY (csrimp_session_id, old_company_type_role_id) USING INDEX;
	
ALTER TABLE csrimp.map_chain_company_type_role ADD CONSTRAINT uk_map_chain_company_type_role
	UNIQUE (csrimp_session_id, new_company_type_role_id) USING INDEX;

ALTER TABLE csrimp.map_chain_company_type_role ADD CONSTRAINT fk_map_chain_comp_type_role_is
	FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE;

-- csrimp constraints on mapping table for company_tab_company_type_role.comp_tab_comp_type_role_id
ALTER TABLE csrimp.map_chain_cmp_tab_cmp_typ_role ADD CONSTRAINT pk_map_chain_cmp_tab_cmp_typ_r
	PRIMARY KEY (csrimp_session_id, old_comp_tab_comp_type_role_id) USING INDEX;
	
ALTER TABLE csrimp.map_chain_cmp_tab_cmp_typ_role ADD CONSTRAINT uk_map_chain_cmp_tab_cmp_typ_r
	UNIQUE (csrimp_session_id, new_comp_tab_comp_type_role_id) USING INDEX;

ALTER TABLE csrimp.map_chain_cmp_tab_cmp_typ_role ADD CONSTRAINT fk_map_chain_cmp_tab_typ_rl_is
	FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE;

-- fk indexes	
CREATE INDEX chain.ix_comp_tab_type_comp_type_rl ON chain.company_tab_company_type_role (app_sid, company_type_role_id);
CREATE INDEX chain.ix_comp_tab_type_comp_tab ON chain.company_tab_company_type_role (app_sid, company_tab_id);
CREATE INDEX chain.ix_comp_tab_type_comp_grp_type ON chain.company_tab_company_type_role (company_group_type_id);

-- *** Grants ***
GRANT SELECT, INSERT, UPDATE ON chain.company_tab_company_type_role to csr;
GRANT SELECT ON chain.company_type_role_id_seq TO csr;
GRANT SELECT ON chain.comp_tab_comp_type_role_id_seq TO csr;

GRANT SELECT ON chain.company_type_role_id_seq TO csrimp;
GRANT SELECT ON chain.comp_tab_comp_type_role_id_seq TO csrimp;
GRANT SELECT, INSERT, UPDATE ON chain.company_tab_company_type_role TO csrimp;

GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.chain_comp_tab_comp_type_role TO tool_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.flow_item_region TO tool_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../schema_pkg
@../chain/company_pkg
@../chain/plugin_pkg
@../chain/type_capability_pkg

@../schema_body
@../csrimp/imp_body
@../chain/chain_body
@../chain/company_type_body
@../chain/company_body
@../chain/plugin_body

@update_tail
