-- Please update version.sql too -- this keeps clean builds in sync
define version=3047
define minor_version=16
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE chain.company_type_score_calc DROP CONSTRAINT ck_cmp_typ_scr_clc_calc;

ALTER TABLE chain.company_type_score_calc ADD (
	active_suppliers_only				NUMBER(1)
);

UPDATE chain.company_type_score_calc SET active_suppliers_only = 0 WHERE calc_type = 'supplier_scores';

ALTER TABLE chain.company_type_score_calc ADD (
	CONSTRAINT ck_cmp_typ_scr_clc_calc CHECK (
		calc_type = 'supplier_scores' AND operator_type IS NOT NULL AND supplier_score_type_id IS NOT NULL AND active_suppliers_only IN (0, 1)
	)
);

ALTER TABLE csrimp.chain_com_type_scor_calc ADD (
	active_suppliers_only				NUMBER(1)
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/company_score_pkg
@../chain/company_pkg

@../chain/company_score_body
@../chain/company_body
@../schema_body
@../csrimp/imp_body

@update_tail
