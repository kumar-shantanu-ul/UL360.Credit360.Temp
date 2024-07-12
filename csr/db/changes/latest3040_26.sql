-- Please update version.sql too -- this keeps clean builds in sync
define version=3040
define minor_version=26
@update_header

-- *** DDL ***
-- Create tables

CREATE TABLE chain.company_type_score_calc (
    app_sid								NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	company_type_id						NUMBER(10, 0) NOT NULL,
	score_type_id						NUMBER(10, 0) NOT NULL,
	calc_type							VARCHAR2(50) NOT NULL,
	operator_type						VARCHAR2(10),
	supplier_score_type_id				NUMBER(10, 0),
    CONSTRAINT pk_cmp_typ_scr_clc PRIMARY KEY (app_sid, company_type_id, score_type_id),
	CONSTRAINT fk_cmp_typ_scr_clc_cmp_typ FOREIGN KEY (app_sid, company_type_id) REFERENCES chain.company_type (app_sid, company_type_id),
	CONSTRAINT ck_cmp_typ_scr_clc_opr_typ CHECK (operator_type IS NULL OR operator_type IN ('sum', 'avg', 'max', 'min')),
	CONSTRAINT ck_cmp_typ_scr_clc_calc CHECK (
		calc_type = 'supplier_scores' AND operator_type IS NOT NULL AND supplier_score_type_id IS NOT NULL
	)
);

CREATE INDEX chain.ix_cmp_typ_scr_clc_cmp_typ ON chain.company_type_score_calc (app_sid, company_type_id);

CREATE TABLE chain.comp_type_score_calc_comp_type (
    app_sid								NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	company_type_id						NUMBER(10, 0) NOT NULL,
	score_type_id						NUMBER(10, 0) NOT NULL,
	supplier_company_type_id			NUMBER(10, 0) NOT NULL,
    CONSTRAINT pk_cmp_typ_scr_clc_cmp_typ PRIMARY KEY (app_sid, company_type_id, score_type_id, supplier_company_type_id),
	CONSTRAINT fk_cmp_typ_scr_clc_ct_parent FOREIGN KEY (app_sid, company_type_id, score_type_id) REFERENCES chain.company_type_score_calc (app_sid, company_type_id, score_type_id),
	CONSTRAINT fk_cmp_typ_scr_clc_ct_ct FOREIGN KEY (app_sid, company_type_id) REFERENCES chain.company_type (app_sid, company_type_id),
	CONSTRAINT fk_cmp_typ_scr_clc_ct_sct FOREIGN KEY (app_sid, supplier_company_type_id) REFERENCES chain.company_type (app_sid, company_type_id)
);

CREATE INDEX chain.ix_cmp_typ_scr_clc_ct_parent ON chain.comp_type_score_calc_comp_type (app_sid, company_type_id, score_type_id);
CREATE INDEX chain.ix_cmp_typ_scr_clc_ct_ct ON chain.comp_type_score_calc_comp_type (app_sid, company_type_id);
CREATE INDEX chain.ix_cmp_typ_scr_clc_ct_sct ON chain.comp_type_score_calc_comp_type (app_sid, supplier_company_type_id);

CREATE TABLE CSRIMP.CHAIN_COM_TYPE_SCOR_CALC (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	COMPANY_TYPE_ID NUMBER(10,0) NOT NULL,
	SCORE_TYPE_ID NUMBER(10,0) NOT NULL,
	CALC_TYPE VARCHAR2(50) NOT NULL,
	OPERATOR_TYPE VARCHAR2(10),
	SUPPLIER_SCORE_TYPE_ID NUMBER(10,0),
	CONSTRAINT PK_CHAIN_COM_TYPE_SCOR_CALC PRIMARY KEY (CSRIMP_SESSION_ID, COMPANY_TYPE_ID, SCORE_TYPE_ID),
	CONSTRAINT FK_CHAIN_COM_TYPE_SCOR_CALC_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.CHAIN_CO_TY_SC_CAL_CO_TY (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	COMPANY_TYPE_ID NUMBER(10,0) NOT NULL,
	SCORE_TYPE_ID NUMBER(10,0) NOT NULL,
	SUPPLIER_COMPANY_TYPE_ID NUMBER(10,0) NOT NULL,
	CONSTRAINT PK_CHAIN_CO_TY_SC_CAL_CO_TY PRIMARY KEY (CSRIMP_SESSION_ID, COMPANY_TYPE_ID, SCORE_TYPE_ID, SUPPLIER_COMPANY_TYPE_ID),
	CONSTRAINT FK_CHAIN_CO_TY_SC_CAL_CO_TY_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

-- Alter tables

-- *** Grants ***
GRANT select, references ON csr.current_supplier_score TO chain;
grant select, insert, update, delete on csrimp.chain_com_type_scor_calc to tool_user;
grant select, insert, update, delete on csrimp.chain_co_ty_sc_cal_co_ty to tool_user;
grant select, insert, update on chain.company_type_score_calc to csrimp;
grant select, insert, update on chain.comp_type_score_calc_comp_type to csrimp;
grant select, insert, update on chain.company_type_score_calc to CSR;
grant select, insert, update on chain.comp_type_score_calc_comp_type to CSR;

-- ** Cross schema constraints ***
ALTER TABLE chain.company_type_score_calc
ADD CONSTRAINT fk_cmp_typ_scr_clc_scr_typ
FOREIGN KEY (app_sid, score_type_id)
REFERENCES csr.score_type (app_sid, score_type_id);

CREATE INDEX chain.ix_cmp_typ_scr_clc_scr_typ
ON chain.company_type_score_calc (app_sid, score_type_id);

ALTER TABLE chain.company_type_score_calc
ADD CONSTRAINT fk_cmp_typ_scr_clc_sup_st
FOREIGN KEY (app_sid, supplier_score_type_id)
REFERENCES csr.score_type (app_sid, score_type_id);

CREATE INDEX chain.ix_cmp_typ_scr_clc_sup_st
ON chain.company_type_score_calc (app_sid, supplier_score_type_id);

ALTER TABLE chain.comp_type_score_calc_comp_type
ADD CONSTRAINT fk_cmp_typ_scr_clc_ct_st
FOREIGN KEY (app_sid, score_type_id)
REFERENCES csr.score_type (app_sid, score_type_id);

CREATE INDEX chain.ix_cmp_typ_scr_clc_ct_st
ON chain.comp_type_score_calc_comp_type (app_sid, score_type_id);

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **
CREATE OR REPLACE PACKAGE chain.company_score_pkg AS END;
/

GRANT execute ON chain.company_score_pkg TO csr;
GRANT execute ON chain.company_score_pkg TO web_user;

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/company_score_pkg
@../chain/company_type_pkg
@../csr_data_pkg
@../schema_pkg
@../supplier_pkg
@../csrimp/imp_pkg

@../chain/company_score_body
@../chain/company_type_body
@../schema_body
@../supplier_body
@../csrimp/imp_body

@update_tail
