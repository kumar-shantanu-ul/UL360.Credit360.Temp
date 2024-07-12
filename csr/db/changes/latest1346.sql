-- Please update version.sql too -- this keeps clean builds in sync
define version=1346
@update_header

DROP TABLE cms.imp_constraints;
DROP TABLE cms.imp_cons_columns;
DROP TABLE cms.imp_tables;
DROP TABLE cms.imp_tab_columns;
DROP TABLE cms.imp_indexes;
DROP TABLE cms.imp_ind_columns;
DROP TABLE cms.imp_tab_privs;
DROP TABLE cms.imp_tab_comments;
DROP TABLE cms.imp_col_comments;

grant references on csrimp.csrimp_session to cms;

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

grant select,insert,update,delete on cms.imp_col_comments to web_user;
grant select,insert,update,delete on cms.imp_constraints to web_user;
grant select,insert,update,delete on cms.imp_cons_columns to web_user;
grant select,insert,update,delete on cms.imp_tables to web_user;
grant select,insert,update,delete on cms.imp_tab_columns to web_user;
grant select,insert,update,delete on cms.imp_indexes to web_user;
grant select,insert,update,delete on cms.imp_ind_columns to web_user;
grant select,insert,update,delete on cms.imp_tab_comments to web_user;
grant select,insert,update,delete on cms.imp_tab_privs to web_user;

BEGIN
 	FOR r IN (
		SELECT c.owner, c.table_name, c.nullable, (SUBSTR(c.table_name, 1, 26) || '_POL') policy_name
		  FROM all_tables t
		  JOIN all_tab_columns c ON t.owner = c.owner AND t.table_name = c.table_name
		 WHERE t.owner IN ('CMS') AND (t.dropped = 'NO' OR t.dropped IS NULL) AND c.column_name = 'CSRIMP_SESSION_ID'
 	)
 	LOOP
		dbms_output.put_line('Writing policy '||r.policy_name);
		dbms_rls.add_policy(
			object_schema   => r.owner,
			object_name     => r.table_name,
			policy_name     => r.policy_name, 
			function_schema => 'CSRIMP',
			policy_function => 'SessionIDCheck',
			statement_types => 'select, insert, update, delete',
			update_check	=> true,
			policy_type     => dbms_rls.static);
	END LOOP;
	
END;
/

@update_tail
