-- Please update version.sql too -- this keeps clean builds in sync
define version=3170
define minor_version=16
@update_header

-- *** DDL ***
-- Create tables

CREATE TABLE chain.supplier_relationship_source (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	purchaser_company_sid			NUMBER(10) NOT NULL,
	supplier_company_sid			NUMBER(10) NOT NULL,
	source_type						NUMBER(2) NOT NULL,
	object_id						NUMBER(10) NULL,
	CONSTRAINT uk_supplier_relationship_src UNIQUE (app_sid, purchaser_company_sid, supplier_company_sid, source_type, object_id),
	CONSTRAINT chk_supp_rel_src_type CHECK (source_type IN (0, 1, 2)),
	CONSTRAINT fk_supp_rel_src_supp_rel FOREIGN KEY (app_sid, purchaser_company_sid, supplier_company_sid)
	REFERENCES chain.supplier_relationship (app_sid, purchaser_company_sid, supplier_company_sid) ON DELETE CASCADE
);

CREATE INDEX chain.ix_supplier_relationship_src ON chain.supplier_relationship_source(app_sid, purchaser_company_sid, supplier_company_sid);

CREATE TABLE csrimp.chain_supp_rel_source (
	csrimp_session_id				NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	purchaser_company_sid			NUMBER(10),
	supplier_company_sid			NUMBER(10),
	source_type						NUMBER(2),
	object_id						NUMBER(10),
	CONSTRAINT fk_supp_rel_src_session FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);

-- Alter tables

-- *** Grants ***
grant select, insert, update on chain.supplier_relationship_source to csrimp;
grant select,insert,update,delete on csrimp.chain_supp_rel_source to tool_user;
grant select on chain.supplier_relationship_source to csr;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

BEGIN
	security.user_pkg.LogonAdmin;
	INSERT INTO chain.supplier_relationship_source (app_sid, purchaser_company_sid, supplier_company_sid, source_type)
	SELECT app_sid, purchaser_company_sid, supplier_company_sid, 0 /* chain_pkg.AUTO_REL_SRC */
	  FROM chain.supplier_relationship
	 WHERE active = 1 AND deleted = 0;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@..\chain\chain_pkg
@..\schema_pkg

@..\chain\company_pkg

@..\chain\audit_request_body
@..\chain\business_relationship_body
@..\chain\company_body
@..\chain\company_dedupe_body
@..\chain\invitation_body
@..\chain\test_chain_utils_body
@..\chain\uninvited_body
@..\csrimp\imp_body
@..\integration_api_body
@..\schema_body

@update_tail
