-- Please update version.sql too -- this keeps clean builds in sync
define version=1830
@update_header


CREATE TABLE CHAIN.CUSTOMER_OPTIONS_COLUMNS(
    COLUMN_NAME           VARCHAR2(100)     NOT NULL,
    DESCRIPTION           VARCHAR2(4000),
    SHOW_IN_ADMIN_PAGE    NUMBER(1, 0)      DEFAULT 1 NOT NULL,
    CHECK (SHOW_IN_ADMIN_PAGE IN (1,0)),
    CONSTRAINT PK_CUST_OPT_COL PRIMARY KEY (COLUMN_NAME)
);

INSERT INTO CHAIN.CUSTOMER_OPTIONS_COLUMNS (column_name, description, show_in_admin_page) 
	SELECT column_name, 'Description of ' || column_name description, 1 show_in_admin_page FROM all_tab_columns WHERE table_name = 'CUSTOMER_OPTIONS' AND owner = 'CHAIN';

ALTER TABLE CHAIN.TT_NAMED_PARAM 
MODIFY(VALUE VARCHAR2(4000));

@../chain/admin_helper_pkg
@../chain/admin_helper_body

		
		
@update_tail