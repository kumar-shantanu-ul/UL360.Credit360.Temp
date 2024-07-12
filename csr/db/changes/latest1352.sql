-- Please update version.sql too -- this keeps clean builds in sync
define version=1352
@update_header

CREATE TABLE cms.imp_ind_expressions
(
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	index_owner						VARCHAR2(30) NOT NULL,
	index_name						VARCHAR2(30) NOT NULL,
	table_owner						VARCHAR2(30) NOT NULL,
	table_name						VARCHAR2(30) NOT NULL,
	column_expression				CLOB,
	column_position					NUMBER,
    CONSTRAINT fk_cms_imp_ind_expr_csrimp_is FOREIGN KEY (csrimp_session_id)
    REFERENCES csrimp.csrimp_session (csrimp_session_id)
    	ON DELETE CASCADE
);

alter table cms.imp_indexes add index_type VARCHAR2(27);

@../../../aspen2/cms/db/tab_pkg
@../../../aspen2/cms/db/tab_body

@update_tail
