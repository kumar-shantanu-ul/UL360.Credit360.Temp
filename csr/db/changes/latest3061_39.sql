-- Please update version.sql too -- this keeps clean builds in sync
define version=3061
define minor_version=39
@update_header

-- *** DDL ***
-- Create tables

CREATE SEQUENCE chain.supplier_rel_score_id_seq
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOORDER
;

CREATE TABLE chain.supplier_relationship_score(
	app_sid							NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	supplier_relationship_score_id	NUMBER(10, 0)	NOT NULL,
	purchaser_company_sid			NUMBER(10, 0)	NOT NULL,
	supplier_company_sid			NUMBER(10, 0)	NOT NULL,
	score_threshold_id				NUMBER(10, 0),
	set_dtm							DATE			DEFAULT SYSDATE NOT NULL,
	score							NUMBER(15, 5),
	changed_by_user_sid 			NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'SID'),
	score_type_id					NUMBER(10, 0)	NOT NULL,
	is_effective					NUMBER(1, 0)	DEFAULT 1 NOT NULL,
	CONSTRAINT pk_supplier_relationhsip_score PRIMARY KEY (app_sid, supplier_relationship_score_id),
	CONSTRAINT chk_is_current CHECK (is_effective IN (0,1))
);

CREATE UNIQUE INDEX chain.uk_supplier_relationship_score 
	ON chain.supplier_relationship_score(app_sid, purchaser_company_sid, supplier_company_sid, score_type_id,
		DECODE(is_effective, 1, 1, supplier_relationship_score_id + 1));

CREATE TABLE CSRIMP.CHAIN_SUPPL_RELATI_SCORE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	SUPPLIER_RELATIONSHIP_SCORE_ID NUMBER(10,0) NOT NULL,
	PURCHASER_COMPANY_SID NUMBER(10,0) NOT NULL,
	SCORE NUMBER(15,5),
	SCORE_THRESHOLD_ID NUMBER(10,0),
	SCORE_TYPE_ID NUMBER(10,0) NOT NULL,
	SET_DTM DATE NOT NULL,
	SUPPLIER_COMPANY_SID NUMBER(10,0) NOT NULL,
	CHANGED_BY_USER_SID NUMBER(10, 0) NOT NULL,
	IS_EFFECTIVE	NUMBER(1, 0) NOT NULL,
	CONSTRAINT PK_CHAIN_SUPPL_RELATI_SCORE PRIMARY KEY (CSRIMP_SESSION_ID, SUPPLIER_RELATIONSHIP_SCORE_ID),
	CONSTRAINT FK_CHAIN_SUPPL_RELATI_SCORE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

-- Map tables
CREATE TABLE CSRIMP.MAP_CHAIN_SUPP_REL_SCORE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_CHAIN_SUPPLIE_REL_SCORE_ID NUMBER(10) NOT NULL,
	NEW_CHAIN_SUPPLIE_REL_SCORE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_SUPP_REL_SCORE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_CHAIN_SUPPLIE_REL_SCORE_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_SUPP_REL_SCORE UNIQUE (CSRIMP_SESSION_ID, NEW_CHAIN_SUPPLIE_REL_SCORE_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_SUPP_REL_SCORE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

-- Alter tables
ALTER TABLE csr.score_type ADD applies_to_supp_rels NUMBER(1, 0) DEFAULT 0 NOT NULL;

ALTER TABLE csr.score_type ADD CONSTRAINT chk_score_type_appl_suprel CHECK (applies_to_supp_rels IN (0,1));

ALTER TABLE csr.score_type ADD CONSTRAINT chk_score_type_not_sup_and_sr CHECK (applies_to_supplier = 0 OR applies_to_supp_rels = 0);

ALTER TABLE csrimp.score_type ADD applies_to_supp_rels NUMBER(1, 0) NOT NULL;

ALTER TABLE csrimp.score_type ADD CONSTRAINT chk_score_type_appl_suprel CHECK (applies_to_supp_rels IN (0,1));

ALTER TABLE csrimp.score_type ADD CONSTRAINT chk_score_type_not_sup_and_sr CHECK (applies_to_supplier = 0 OR applies_to_supp_rels = 0);

ALTER TABLE chain.supplier_relationship_score ADD CONSTRAINT fk_supplier_rel_score_rel
	FOREIGN KEY (app_sid, purchaser_company_sid, supplier_company_sid)
	REFERENCES chain.supplier_relationship (app_sid, purchaser_company_sid, supplier_company_sid);
	
-- *** Grants ***
-- Package grants
grant select, insert, update, delete on csrimp.chain_suppl_relati_score to tool_user;

-- Object grants

-- grants for csrimp
grant select, insert, update on chain.supplier_relationship_score to csrimp;

grant select on chain.supplier_rel_score_id_seq to csrimp;
grant select on chain.supplier_rel_score_id_seq to CSR;

-- non csrimp grants
grant select, insert, update on chain.supplier_relationship_score to CSR;

-- ** Cross schema constraints ***

ALTER TABLE chain.supplier_relationship_score ADD CONSTRAINT fk_sup_rel_score_type 
	FOREIGN KEY (app_sid, score_type_id)
	REFERENCES csr.score_type(app_sid, score_type_id);

ALTER TABLE chain.supplier_relationship_score ADD CONSTRAINT fk_sup_rel_score_thresh_id 
	FOREIGN KEY (app_sid, score_threshold_id)
	REFERENCES csr.score_threshold(app_sid, score_threshold_id);
	
CREATE INDEX chain.ix_rel_score_purch_suppl ON chain.supplier_relationship_score (app_sid, purchaser_company_sid, supplier_company_sid);
CREATE INDEX chain.ix_rel_score_type ON chain.supplier_relationship_score (app_sid, score_type_id);
CREATE INDEX chain.ix_rel_score_threshold ON chain.supplier_relationship_score (app_sid, score_threshold_id);

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

BEGIN
	INSERT INTO csr.plugin
		(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path)
	VALUES
		(csr.plugin_id_seq.NEXTVAL, 11, 'Supplier relationship scores', '/csr/site/chain/managecompany/controls/SuppRelScoreHeader.js',
		 'Chain.ManageCompany.SuppRelScoreHeader', 'Credit360.Chain.Plugins.SuppRelScoreHeaderDto',
		 'This header shows any scores on the relationship between the company you are logged in as and the company you are viewing.',
		 '/csr/shared/plugins/screenshots/supplier_relationship_scores.png');
EXCEPTION
	WHEN dup_val_on_index THEN
		NULL;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../quick_survey_pkg
@../schema_pkg
@../chain/company_pkg

@../quick_survey_body
@../schema_body
@../supplier_body
@../chain/company_body
@../chain/company_filter_body
@../csrimp/imp_body

@update_tail
