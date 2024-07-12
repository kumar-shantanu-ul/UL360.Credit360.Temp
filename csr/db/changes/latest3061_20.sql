-- Please update version.sql too -- this keeps clean builds in sync
define version=3061
define minor_version=20
@update_header

-- *** DDL ***
-- Create tables

CREATE SEQUENCE chain.customer_filter_column_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

CREATE TABLE chain.customer_filter_column (
	app_sid						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	customer_filter_column_id	NUMBER(10, 0)	NOT NULL,
	card_group_id				NUMBER(10, 0)	NOT NULL,
	column_name					VARCHAR2(255)	NOT NULL,
	session_prefix 				VARCHAR2(255),
	label						VARCHAR2(1024)	NOT NULL,
	width						NUMBER(10, 0)	NOT NULL,
	fixed_width					NUMBER(1, 0)	NOT NULL,
	sortable					NUMBER(1, 0)	NOT NULL,
	CONSTRAINT pk_cust_filt_col PRIMARY KEY (app_sid, customer_filter_column_id),
	CONSTRAINT fk_cust_filt_col_card_grp FOREIGN KEY (card_group_id) REFERENCES chain.card_group (card_group_id),
	CONSTRAINT ck_cust_filt_col_fixed_width CHECK (fixed_width IN (1, 0)),
	CONSTRAINT ck_cust_filt_col_sortable CHECK (sortable IN (1, 0))
);

CREATE UNIQUE INDEX chain.uk_customer_filter_column ON chain.customer_filter_column(app_sid, card_group_id, column_name, session_prefix);

CREATE SEQUENCE chain.customer_filter_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

CREATE TABLE chain.customer_filter_item (
	app_sid						NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	customer_filter_item_id		NUMBER(10, 0) NOT NULL,
	card_group_id				NUMBER(10, 0) NOT NULL,
	item_name					VARCHAR2(255) NOT NULL,
	session_prefix 				VARCHAR2(255),
	label						VARCHAR2(1024)	NOT NULL,
	can_breakdown				NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT pk_cust_filt_item PRIMARY KEY (app_sid, customer_filter_item_id),
	CONSTRAINT fk_cust_filt_item_card_grp FOREIGN KEY (card_group_id) REFERENCES chain.card_group (card_group_id),
	CONSTRAINT ck_cust_filt_item_can_brkdn CHECK (can_breakdown IN (1, 0))
);

CREATE UNIQUE INDEX chain.uk_customer_filter_item ON chain.customer_filter_item(app_sid, card_group_id, item_name, session_prefix);

CREATE SEQUENCE chain.cust_filt_item_agg_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

CREATE TABLE chain.cust_filt_item_agg_type (
	app_sid						NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	cust_filt_item_agg_type_id	NUMBER(10, 0) NOT NULL,
	customer_filter_item_id		NUMBER(10, 0) NOT NULL,
	analytic_function			NUMBER(10, 0) NOT NULL,
	CONSTRAINT pk_cust_filt_item_agg_type PRIMARY KEY (app_sid, cust_filt_item_agg_type_id),
	CONSTRAINT fk_cust_filt_item_agg_type FOREIGN KEY (app_sid, customer_filter_item_id) REFERENCES chain.customer_filter_item (app_sid, customer_filter_item_id)
);

CREATE UNIQUE INDEX chain.uk_cust_filt_item_agg_type ON chain.cust_filt_item_agg_type(app_sid, customer_filter_item_id, analytic_function);

CREATE OR REPLACE TYPE csr.t_qs_response_perm_row AS
	OBJECT (
		survey_response_id			NUMBER(10),
		object_id					NUMBER(10),
		can_see_response			NUMBER(1),
		can_see_scores				NUMBER(1),
		MAP MEMBER FUNCTION MAP
			RETURN VARCHAR2
	);
/

CREATE OR REPLACE TYPE BODY csr.t_qs_response_perm_row AS
	MAP MEMBER FUNCTION MAP
		RETURN VARCHAR2
	IS
	BEGIN
		RETURN survey_response_id || ',' || object_id;
	END;
END;
/

CREATE OR REPLACE TYPE csr.t_qs_response_perm_table AS
	TABLE OF csr.t_qs_response_perm_row;
/

CREATE TABLE CSRIMP.CHAIN_CUST_FILTER_COLUMN (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	CUSTOMER_FILTER_COLUMN_ID NUMBER(10,0) NOT NULL,
	CARD_GROUP_ID NUMBER(10,0) NOT NULL,
	COLUMN_NAME VARCHAR2(255) NOT NULL,
	FIXED_WIDTH NUMBER(1,0) NOT NULL,
	LABEL VARCHAR2(1024) NOT NULL,
	SESSION_PREFIX VARCHAR2(255),
	SORTABLE NUMBER(1,0) NOT NULL,
	WIDTH NUMBER(10,0) NOT NULL,
	CONSTRAINT PK_CHAIN_CUST_FILTER_COLUMN PRIMARY KEY (CSRIMP_SESSION_ID, CUSTOMER_FILTER_COLUMN_ID),
	CONSTRAINT FK_CHAIN_CUST_FILTER_COLUMN_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.CHAIN_CUSTOM_FILTER_ITEM (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	CUSTOMER_FILTER_ITEM_ID NUMBER(10,0) NOT NULL,
	CAN_BREAKDOWN NUMBER(1,0) NOT NULL,
	CARD_GROUP_ID NUMBER(10,0) NOT NULL,
	ITEM_NAME VARCHAR2(255) NOT NULL,
	LABEL VARCHAR2(1024) NOT NULL,
	SESSION_PREFIX VARCHAR2(255),
	CONSTRAINT PK_CHAIN_CUSTOM_FILTER_ITEM PRIMARY KEY (CSRIMP_SESSION_ID, CUSTOMER_FILTER_ITEM_ID),
	CONSTRAINT FK_CHAIN_CUSTOM_FILTER_ITEM_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.CHAIN_CU_FIL_ITE_AGG_TYP (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	CUST_FILT_ITEM_AGG_TYPE_ID NUMBER(10,0) NOT NULL,
	ANALYTIC_FUNCTION NUMBER(10,0) NOT NULL,
	CUSTOMER_FILTER_ITEM_ID NUMBER(10,0) NOT NULL,
	CONSTRAINT PK_CHAIN_CU_FIL_ITE_AGG_TYP PRIMARY KEY (CSRIMP_SESSION_ID, CUST_FILT_ITEM_AGG_TYPE_ID),
	CONSTRAINT FK_CHAIN_CU_FIL_ITE_AGG_TYP_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_CUST_FILT_COL (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_CHAIN_CUST_FILTER_COLUM_ID NUMBER(10) NOT NULL,
	NEW_CHAIN_CUST_FILTER_COLUM_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_CUST_FILT_COL PRIMARY KEY (CSRIMP_SESSION_ID, OLD_CHAIN_CUST_FILTER_COLUM_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_CUST_FILT_COL UNIQUE (CSRIMP_SESSION_ID, NEW_CHAIN_CUST_FILTER_COLUM_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_CUST_FILT_COL_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_CUST_FILT_ITEM (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_CHAIN_CUST_FILTER_ITEM_ID NUMBER(10) NOT NULL,
	NEW_CHAIN_CUST_FILTER_ITEM_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_CUST_FILT_ITEM PRIMARY KEY (CSRIMP_SESSION_ID, OLD_CHAIN_CUST_FILTER_ITEM_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_CUST_FILT_ITEM UNIQUE (CSRIMP_SESSION_ID, NEW_CHAIN_CUST_FILTER_ITEM_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_CUST_FILT_ITEM_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_CU_FI_IT_AG_TY (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_CHAIN_CU_FI_ITE_AGG_TYP_ID NUMBER(10) NOT NULL,
	NEW_CHAIN_CU_FI_ITE_AGG_TYP_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_CU_FI_IT_AG_TY PRIMARY KEY (CSRIMP_SESSION_ID, OLD_CHAIN_CU_FI_ITE_AGG_TYP_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_CU_FI_IT_AG_TY UNIQUE (CSRIMP_SESSION_ID, NEW_CHAIN_CU_FI_ITE_AGG_TYP_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_CU_FI_IT_AG_TY_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

-- Alter tables
ALTER TABLE chain.customer_aggregate_type DROP CONSTRAINT chk_customer_aggregate_type;
DROP INDEX chain.uk_customer_aggregate_type;

ALTER TABLE chain.customer_aggregate_type ADD (
	cust_filt_item_agg_type_id		NUMBER(10, 0),
	CONSTRAINT fk_cust_agg_typ_cust_filt_item FOREIGN KEY (app_sid, cust_filt_item_agg_type_id) REFERENCES chain.cust_filt_item_agg_type (app_sid, cust_filt_item_agg_type_id),
	CONSTRAINT chk_customer_aggregate_type 
	CHECK ((
		CASE WHEN cms_aggregate_type_id			IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN initiative_metric_id			IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ind_sid						IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN filter_page_ind_interval_id	IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN meter_aggregate_type_id		IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN score_type_agg_type_id		IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN cust_filt_item_agg_type_id	IS NOT NULL THEN 1 ELSE 0 END
	) = 1)
);

CREATE UNIQUE INDEX chain.uk_customer_aggregate_type ON chain.customer_aggregate_type (
		app_sid, card_group_id, cms_aggregate_type_id, initiative_metric_id, ind_sid, filter_page_ind_interval_id, meter_aggregate_type_id, score_type_agg_type_id, cust_filt_item_agg_type_id)
;

ALTER TABLE csrimp.chain_customer_aggregate_type DROP CONSTRAINT chk_customer_aggregate_type;
DROP INDEX csrimp.uk_customer_aggregate_type;

ALTER TABLE csrimp.chain_customer_aggregate_type ADD (
	cust_filt_item_agg_type_id		NUMBER(10, 0)
);

create index chain.ix_customer_aggr_cust_filt_ite on chain.customer_aggregate_type (app_sid, cust_filt_item_agg_type_id);
create index chain.ix_cust_filt_col_card_group_id on chain.customer_filter_column (card_group_id);
create index chain.ix_cust_filt_itm_card_group_id on chain.customer_filter_item (card_group_id);

-- *** Grants ***
grant select, insert, update, delete on csrimp.chain_cust_filter_column to tool_user;
grant select, insert, update, delete on csrimp.chain_custom_filter_item to tool_user;
grant select, insert, update, delete on csrimp.chain_cu_fil_ite_agg_typ to tool_user;

grant select, insert, update on chain.customer_filter_column to CSR;
grant select, insert, update on chain.customer_filter_item to CSR;
grant select, insert, update on chain.cust_filt_item_agg_type to CSR;

grant select on chain.customer_filter_column_id_seq to CSR;
grant select on chain.customer_filter_item_id_seq to CSR;
grant select on chain.cust_filt_item_agg_type_id_seq to CSR;

grant select, insert, update on chain.customer_filter_column to csrimp;
grant select, insert, update on chain.customer_filter_item to csrimp;
grant select, insert, update on chain.cust_filt_item_agg_type to csrimp;

grant select on chain.customer_filter_column_id_seq to csrimp;
grant select on chain.customer_filter_item_id_seq to csrimp;
grant select on chain.cust_filt_item_agg_type_id_seq to csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/filter_pkg
@../quick_survey_pkg
@../quick_survey_report_pkg
@../schema_pkg

@../chain/filter_body
@../quick_survey_body
@../quick_survey_report_body
@../schema_body
@../csrimp/imp_body
@../enable_body

@update_tail
