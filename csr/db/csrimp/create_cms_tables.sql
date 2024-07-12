CREATE TABLE cms.imp_constraints
(
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	owner							VARCHAR2(30) NOT NULL,
	table_name						VARCHAR2(30) NOT NULL,
	constraint_name					VARCHAR2(30) NOT NULL,
	constraint_type					VARCHAR2(1) NOT NULL,
	search_condition				CLOB,
	r_owner							VARCHAR2(30),
	r_constraint_name				VARCHAR2(30),
	deferrable						VARCHAR2(14) NOT NULL,
	deferred						VARCHAR2(9) NOT NULL,
	generated						VARCHAR2(14) NOT NULL,
	delete_rule						VARCHAR2(9),
	index_name						VARCHAR2(30),
	status							VARCHAR2(8) NOT NULL,
    CONSTRAINT fk_cms_imp_cons_csrimp_is FOREIGN KEY (csrimp_session_id)
    REFERENCES csrimp.csrimp_session (csrimp_session_id)
    	ON DELETE CASCADE
);

CREATE TABLE cms.imp_cons_columns
(
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	owner							VARCHAR2(30) NOT NULL,
	table_name						VARCHAR2(30) NOT NULL,
	constraint_name					VARCHAR2(30) NOT NULL,
	column_name						VARCHAR2(30) NOT NULL,
	position						NUMBER,
    CONSTRAINT fk_cms_imp_cons_col_csrimp_is FOREIGN KEY (csrimp_session_id)
    REFERENCES csrimp.csrimp_session (csrimp_session_id)
    	ON DELETE CASCADE
);

CREATE TABLE cms.imp_tables
(
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	owner							VARCHAR2(30) NOT NULL,
	table_name						VARCHAR2(30) NOT NULL,
	table_id						NUMBER NOT NULL,
    CONSTRAINT fk_cms_imp_tab_csrimp_is FOREIGN KEY (csrimp_session_id)
    REFERENCES csrimp.csrimp_session (csrimp_session_id)
    	ON DELETE CASCADE
);

CREATE TABLE cms.imp_tab_columns
(
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	owner							VARCHAR2(30) NOT NULL,
	table_name						VARCHAR2(30) NOT NULL,
	column_name						VARCHAR2(30) NOT NULL,
	data_type						VARCHAR2(106) NOT NULL,
	data_length						NUMBER,
	data_precision					NUMBER,
	data_scale						NUMBER,
	nullable						VARCHAR2(1) NOT NULL,
	column_id						NUMBER NOT NULL,
	data_default					CLOB,
    CONSTRAINT fk_cms_imp_tab_col_csrimp_is FOREIGN KEY (csrimp_session_id)
    REFERENCES csrimp.csrimp_session (csrimp_session_id)
    	ON DELETE CASCADE
);

CREATE TABLE cms.imp_indexes
(
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	owner							VARCHAR2(30) NOT NULL,
	index_name						VARCHAR2(30) NOT NULL,
	index_type						VARCHAR2(27),
	table_owner						VARCHAR2(30) NOT NULL,
	table_name						VARCHAR2(30) NOT NULL,
	generated						VARCHAR2(1) NOT NULL,
    CONSTRAINT fk_cms_imp_ind_csrimp_is FOREIGN KEY (csrimp_session_id)
    REFERENCES csrimp.csrimp_session (csrimp_session_id)
    	ON DELETE CASCADE
);

CREATE TABLE cms.imp_ind_columns
(
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	index_owner						VARCHAR2(30) NOT NULL,
	index_name						VARCHAR2(30) NOT NULL,
	table_owner						VARCHAR2(30) NOT NULL,
	table_name						VARCHAR2(30) NOT NULL,
	column_name						VARCHAR2(30) NOT NULL,
	column_position					VARCHAR2(30) NOT NULL,
	descend							VARCHAR2(4),
    CONSTRAINT fk_cms_imp_ind_col_csrimp_is FOREIGN KEY (csrimp_session_id)
    REFERENCES csrimp.csrimp_session (csrimp_session_id)
    	ON DELETE CASCADE
);

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

CREATE TABLE cms.imp_tab_privs
(
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	grantee							VARCHAR2(30) NOT NULL,
	owner							VARCHAR2(30) NOT NULL,
	table_name						VARCHAR2(30) NOT NULL,
	privilege						VARCHAR2(30) NOT NULL,
    CONSTRAINT fk_cms_imp_tab_prv_csrimp_is FOREIGN KEY (csrimp_session_id)
    REFERENCES csrimp.csrimp_session (csrimp_session_id)
    	ON DELETE CASCADE
);

CREATE TABLE cms.imp_tab_comments
(
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	owner							varchar2(30),
	table_name						varchar2(30),
	comments						varchar2(4000),
    CONSTRAINT fk_cms_imp_tab_com_csrimp_is FOREIGN KEY (csrimp_session_id)
    REFERENCES csrimp.csrimp_session (csrimp_session_id)
    	ON DELETE CASCADE
);

CREATE TABLE cms.imp_col_comments
(
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	owner							varchar2(30),
	table_name						varchar2(30),
	column_name						varchar2(30),
	comments						varchar2(4000),
    CONSTRAINT fk_cms_imp_col_com_csrimp_is FOREIGN KEY (csrimp_session_id)
    REFERENCES csrimp.csrimp_session (csrimp_session_id)
    	ON DELETE CASCADE
);

create index cms.ix_imp_col_comme_csrimp_sessio on cms.imp_col_comments (csrimp_session_id);
create index cms.ix_imp_constrain_csrimp_sessio on cms.imp_constraints (csrimp_session_id);
create index cms.ix_imp_cons_colu_csrimp_sessio on cms.imp_cons_columns (csrimp_session_id);
create index cms.ix_imp_indexes_csrimp_sessio on cms.imp_indexes (csrimp_session_id);
create index cms.ix_imp_ind_colum_csrimp_sessio on cms.imp_ind_columns (csrimp_session_id);
create index cms.ix_imp_ind_expre_csrimp_sessio on cms.imp_ind_expressions (csrimp_session_id);
create index cms.ix_imp_tables_csrimp_sessio on cms.imp_tables (csrimp_session_id);
create index cms.ix_imp_tab_colum_csrimp_sessio on cms.imp_tab_columns (csrimp_session_id);
create index cms.ix_imp_tab_comme_csrimp_sessio on cms.imp_tab_comments (csrimp_session_id);
create index cms.ix_imp_tab_privs_csrimp_sessio on cms.imp_tab_privs (csrimp_session_id);

create index cms.ix_imp_cons_cols_own_tab_col on cms.imp_cons_columns (owner, table_name, column_name);
create index cms.ix_imp_cons_own_cons on cms.imp_constraints (owner, constraint_name);
create index cms.ix_imp_cons_r_own_r_cons on cms.imp_constraints (r_owner, r_constraint_name);
