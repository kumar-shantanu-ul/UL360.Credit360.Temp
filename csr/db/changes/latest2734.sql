-- Please update version.sql too -- this keeps clean builds in sync
define version=2734
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.non_comp_default_folder (
	app_sid						NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	non_comp_default_folder_id	NUMBER(10)		NOT NULL,
	parent_folder_id			NUMBER(10),
	label						VARCHAR(4000)	NOT NULL,
	CONSTRAINT pk_non_comp_default_folder PRIMARY KEY (app_sid, non_comp_default_folder_id),
	CONSTRAINT fk_non_comp_def_prnt_fldr FOREIGN KEY (app_sid, parent_folder_id) REFERENCES csr.non_comp_default_folder (app_sid, non_comp_default_folder_id)
);

CREATE UNIQUE INDEX csr.uk_non_comp_def_fldr_lbl ON csr.non_comp_default_folder (app_sid, parent_folder_id, LOWER(label));

CREATE TABLE csr.non_comp_default_tag (
	app_sid						NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	non_comp_default_id			NUMBER(10)		NOT NULL,
	tag_id						NUMBER(10)		NOT NULL,
	CONSTRAINT pk_non_comp_default_tag PRIMARY KEY (app_sid, non_comp_default_id, tag_id),
	CONSTRAINT fk_non_comp_default_tag FOREIGN KEY (app_sid, tag_id) REFERENCES csr.tag(app_sid, tag_id),
	CONSTRAINT fk_non_comp_default_dnc FOREIGN KEY (app_sid, non_comp_default_id) REFERENCES csr.non_comp_default(app_sid, non_comp_default_id)
);

CREATE INDEX csr.ix_non_comp_default_tag ON csr.non_comp_default_tag(app_sid, tag_id);

CREATE SEQUENCE csr.non_comp_default_folder_id_seq
	START WITH 2
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOORDER;

CREATE TABLE CSRIMP.NON_COMP_DEFAULT_FOLDER (
	CSRIMP_SESSION_ID			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','CSRIMP_SESSION_ID') NOT NULL,
	NON_COMP_DEFAULT_FOLDER_ID	NUMBER(10)		NOT NULL,
	PARENT_FOLDER_ID			NUMBER(10),
	LABEL						VARCHAR(4000)	NOT NULL,
	CONSTRAINT PK_NON_COMP_DEFAULT_FOLDER PRIMARY KEY (CSRIMP_SESSION_ID, NON_COMP_DEFAULT_FOLDER_ID),
	CONSTRAINT PK_NON_COMP_DEFAULT_FOLDER_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.NON_COMP_DEFAULT_TAG (
	CSRIMP_SESSION_ID			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','CSRIMP_SESSION_ID') NOT NULL,
	NON_COMP_DEFAULT_ID			NUMBER(10)		NOT NULL,
	TAG_ID						NUMBER(10)		NOT NULL,
	CONSTRAINT PK_NON_COMP_DEFAULT_TAG PRIMARY KEY (CSRIMP_SESSION_ID, NON_COMP_DEFAULT_ID, TAG_ID),
	CONSTRAINT PK_NON_COMP_DEFAULT_TAG_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_non_comp_default_folder (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_non_comp_default_folder_id	NUMBER(10) NOT NULL,
	new_non_comp_default_folder_id	NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_non_comp_default_folder primary key (csrimp_session_id, old_non_comp_default_folder_id) USING INDEX,
	CONSTRAINT uk_map_non_comp_default_folder unique (csrimp_session_id, new_non_comp_default_folder_id) USING INDEX,
    CONSTRAINT FK_MAP_NON_COMP_DEFAULT_FLD_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

-- Alter tables
ALTER TABLE csr.non_comp_default ADD (
	root_cause					CLOB,
	suggested_action			CLOB,
	non_comp_default_folder_id	NUMBER(10),
	unique_reference			VARCHAR2(255),
	CONSTRAINT fk_non_comp_deflt_fldr_id FOREIGN KEY (app_sid, non_comp_default_folder_id) REFERENCES csr.non_comp_default_folder(app_sid, non_comp_default_folder_id)
);

CREATE UNIQUE INDEX csr.uk_non_comp_default_ref ON csr.non_comp_default (
	CASE WHEN unique_reference IS NULL THEN NULL ELSE app_sid END,
	UPPER(unique_reference)
);

ALTER TABLE CSR.QS_QUESTION_OPTION ADD (
	NON_COMP_ROOT_CAUSE		VARCHAR2(4000),
	NON_COMP_SUGGESTED_ACTION VARCHAR2(4000)
);

ALTER TABLE CSR.TEMP_QUESTION_OPTION ADD (
	NON_COMP_ROOT_CAUSE		VARCHAR2(4000),
	NON_COMP_SUGGESTED_ACTION VARCHAR2(4000)
);

CREATE INDEX csr.ix_non_comp_deflt_fldr_id ON csr.non_comp_default(app_sid, non_comp_default_folder_id);

ALTER TABLE csrimp.non_comp_default ADD (
	root_cause					CLOB,
	suggested_action			CLOB,
	non_comp_default_folder_id	NUMBER(10),
	unique_reference			VARCHAR2(255)
);

ALTER TABLE CSRIMP.QS_QUESTION_OPTION ADD (
	NON_COMP_ROOT_CAUSE		VARCHAR2(4000),
	NON_COMP_SUGGESTED_ACTION VARCHAR2(4000)
);

-- *** Grants ***
grant select,insert,update,delete on csrimp.non_comp_default_tag to web_user;
grant select,insert,update,delete on csrimp.non_comp_default_folder to web_user;
grant insert on csr.non_comp_default_folder to csrimp;
grant insert on csr.non_comp_default_tag to csrimp;
grant select on csr.non_comp_default_folder_id_seq to csrimp;

-- ** Cross schema constraints ***

-- *** Views ***

-- *** Data changes ***
-- RLS
DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
BEGIN
 	FOR r IN (
		SELECT c.owner, c.table_name, c.nullable, (SUBSTR(c.table_name, 1, 26) || '_POL') policy_name
		  FROM all_tables t
		  JOIN all_tab_columns c ON t.owner = c.owner AND t.table_name = c.table_name
		 WHERE t.owner IN ('CSRIMP') AND (t.dropped = 'NO' OR t.dropped IS NULL) AND c.column_name = 'CSRIMP_SESSION_ID'
		   AND t.table_name IN ('MAP_NON_COMP_DEFAULT_FOLDER', 'NON_COMP_DEFAULT_TAG', 'NON_COMP_DEFAULT_FOLDER')
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
			policy_type     => dbms_rls.context_sensitive);
	END LOOP;
EXCEPTION
	WHEN POLICY_ALREADY_EXISTS THEN
		DBMS_OUTPUT.PUT_LINE('Policy exists');
	WHEN FEATURE_NOT_ENABLED THEN
		DBMS_OUTPUT.PUT_LINE('RLS policies not applied as feature not enabled');
END;
/
-- Data

-- ** New package grants **

-- *** Packages ***
@../schema_pkg
@../audit_pkg
@../quick_survey_pkg

@../schema_body
@../audit_body
@../csr_app_body
@../quick_survey_body
@../csrimp/imp_body

@update_tail
