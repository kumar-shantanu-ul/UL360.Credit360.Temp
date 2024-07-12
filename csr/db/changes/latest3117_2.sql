-- Please update version.sql too -- this keeps clean builds in sync
define version=3117
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

CREATE SEQUENCE CHAIN.PRODUCT_METRIC_CALC_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

CREATE TABLE chain.product_metric_calc (
	app_sid							NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	product_metric_calc_id			NUMBER(10, 0)	NOT NULL,
	destination_ind_sid				NUMBER(10, 0)	NOT NULL,
	applies_to_companies			NUMBER(1)		DEFAULT 0 NOT NULL,
	applies_to_products				NUMBER(1)		DEFAULT 0 NOT NULL,
	applies_to_product_suppliers	NUMBER(1)		DEFAULT 0 NOT NULL,
	calc_type						NUMBER(10, 0)	NOT NULL,
	operator						VARCHAR2(10)	NOT NULL,
	source_ind_sid_1				NUMBER(10, 0)	NOT NULL,
	source_ind_sid_2				NUMBER(10, 0),
	source_argument_2				NUMBER(24, 10),	
	user_values_only				NUMBER(1),
	CONSTRAINT pk_product_metric_calc PRIMARY KEY (app_sid, product_metric_calc_id),
	CONSTRAINT fk_product_metric_calc_dest FOREIGN KEY (app_sid, destination_ind_sid) REFERENCES chain.product_metric (app_sid, ind_sid),
	CONSTRAINT fk_product_metric_calc_src1 FOREIGN KEY (app_sid, source_ind_sid_1) REFERENCES chain.product_metric (app_sid, ind_sid),
	CONSTRAINT fk_product_metric_calc_src2 FOREIGN KEY (app_sid, source_ind_sid_2) REFERENCES chain.product_metric (app_sid, ind_sid),
	CONSTRAINT ck_product_metric_calc_type CHECK (
		(calc_type = 0 AND applies_to_companies = 0)
		OR
		(calc_type = 1)
		OR
		(calc_type = 2 AND applies_to_product_suppliers = 0)
	),
	CONSTRAINT ck_product_metric_calc_ap_p CHECK (applies_to_products IN (0, 1)),
	CONSTRAINT ck_product_metric_calc_ap_ps CHECK (applies_to_product_suppliers IN (0, 1)),
	CONSTRAINT ck_product_metric_calc_appl CHECK (
		applies_to_companies = 1 OR
		applies_to_products = 1 OR
		applies_to_product_suppliers = 1
	),
	CONSTRAINT ck_product_metric_calc_oper CHECK (
		(calc_type = 0 AND (operator IN ('+', '-', '*', '/')))
		OR
		(calc_type IN (1, 2) AND (operator IN ('count', 'sum', 'min', 'max', 'avg')))
	),
	CONSTRAINT ck_product_metric_calc_source CHECK (
		(calc_type = 0 AND (source_ind_sid_1 != destination_ind_sid) AND (
			(source_ind_sid_2 IS NOT NULL AND (source_ind_sid_2 != destination_ind_sid) AND source_argument_2 IS NULL) OR
			(source_ind_sid_2 IS NULL AND source_argument_2 IS NOT NULL)
		) AND user_values_only IS NULL)
		OR
		(calc_type IN (1, 2) AND (source_ind_sid_2 IS NULL OR source_ind_sid_2 != source_ind_sid_1) AND source_argument_2 IS NULL AND user_values_only IN (0, 1))
	)
);

CREATE UNIQUE INDEX chain.ux_product_metric_calc_comps ON chain.product_metric_calc (app_sid, destination_ind_sid, CASE WHEN applies_to_companies = 1 THEN 0 ELSE product_metric_calc_id END);
CREATE UNIQUE INDEX chain.ux_product_metric_calc_prods ON chain.product_metric_calc (app_sid, destination_ind_sid, CASE WHEN applies_to_products = 1 THEN 0 ELSE product_metric_calc_id END);
CREATE UNIQUE INDEX chain.ux_product_metric_calc_prsps ON chain.product_metric_calc (app_sid, destination_ind_sid, CASE WHEN applies_to_product_suppliers = 1 THEN 0 ELSE product_metric_calc_id END);

create index chain.ix_product_metric_calc_s_ind_1 on chain.product_metric_calc (app_sid, source_ind_sid_1);
create index chain.ix_product_metric_calc_s_ind_2 on chain.product_metric_calc (app_sid, source_ind_sid_2);

-- Alter tables
ALTER TABLE chain.product_metric_val ADD (
	SOURCE_TYPE						NUMBER(10, 0) DEFAULT 0 NOT NULL
);

ALTER TABLE chain.product_supplier_metric_val ADD (
	SOURCE_TYPE						NUMBER(10, 0) DEFAULT 0 NOT NULL
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	security.user_pkg.logonadmin;

	BEGIN
		INSERT INTO CSR.SOURCE_TYPE ( SOURCE_TYPE_ID, DESCRIPTION) VALUES (18, 'Chain product metric');
		COMMIT;
	EXCEPTION
		WHEN dup_val_on_index THEN NULL;
	END;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_data_pkg
@../chain/chain_pkg
@../chain/product_metric_pkg

@../chain/company_product_body
@../chain/product_supplier_report_body
@../chain/product_metric_body
@../chain/product_metric_report_body
@../chain/prdct_supp_mtrc_report_body

@update_tail
