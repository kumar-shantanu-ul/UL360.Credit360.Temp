define version=1974
@update_header

CREATE TABLE CSR.TERM_COND_DOC(
    APP_SID							NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COMPANY_TYPE_ID					NUMBER(10, 0)     NOT NULL,
    DOC_ID							NUMBER(10, 0)     NOT NULL,
    CONSTRAINT PK_TERM_COND_DOC PRIMARY KEY (APP_SID, COMPANY_TYPE_ID, DOC_ID),
	CONSTRAINT FK_TERM_COND_DOC FOREIGN KEY 
		(APP_SID, DOC_ID) REFERENCES CSR.DOC(APP_SID, DOC_ID) 
		ON DELETE CASCADE	
);

CREATE TABLE CSR.TERM_COND_DOC_LOG(
    APP_SID							NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	USER_SID						NUMBER(10, 0)     NOT NULL,
    COMPANY_TYPE_ID					NUMBER(10, 0)     NOT NULL,
    DOC_ID							NUMBER(10, 0)     NOT NULL,
	DOC_VERSION						NUMBER(10, 0)     NOT NULL,
	ACCEPTED_DTM					DATE		      DEFAULT SYSDATE NOT NULL,
    CONSTRAINT PK_TERM_COND_DOC_LOG PRIMARY KEY (APP_SID, USER_SID, COMPANY_TYPE_ID, DOC_ID, DOC_VERSION),
	CONSTRAINT FK_TERM_COND_DOC_LOG_USER FOREIGN KEY 
		(APP_SID, USER_SID) REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID) 
		ON DELETE CASCADE,
	CONSTRAINT FK_TERM_COND_DOC_LOG FOREIGN KEY 
		(APP_SID, DOC_ID) REFERENCES CSR.DOC(APP_SID, DOC_ID) 
		ON DELETE CASCADE,
	CONSTRAINT FK_TERM_COND_DOC_LOG_VERSION FOREIGN KEY 
		(APP_SID, DOC_ID, DOC_VERSION) REFERENCES CSR.DOC_VERSION(APP_SID, DOC_ID, VERSION) 
		ON DELETE CASCADE
);
	
CREATE TABLE CSRIMP.TERM_COND_DOC(
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    COMPANY_TYPE_ID					NUMBER(10, 0)     NOT NULL,
    DOC_ID							NUMBER(10, 0)     NOT NULL,
    CONSTRAINT PK_TERM_COND_DOC PRIMARY KEY (CSRIMP_SESSION_ID, COMPANY_TYPE_ID, DOC_ID),
	CONSTRAINT FK_TERM_COND_DOC_IS FOREIGN KEY 
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE	
);

CREATE TABLE CSRIMP.TERM_COND_DOC_LOG(
    CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	USER_SID						NUMBER(10, 0)     NOT NULL,
    COMPANY_TYPE_ID					NUMBER(10, 0)     NOT NULL,
    DOC_ID							NUMBER(10, 0)     NOT NULL,
	DOC_VERSION						NUMBER(10, 0)     NOT NULL,
	ACCEPTED_DTM					DATE		      DEFAULT SYSDATE NOT NULL,
    CONSTRAINT PK_TERM_COND_DOC_LOG PRIMARY KEY (CSRIMP_SESSION_ID, COMPANY_TYPE_ID, USER_SID, DOC_ID, DOC_VERSION),
	CONSTRAINT FK_TERM_COND_DOC_LOG_IS FOREIGN KEY 
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE	
);

GRANT INSERT ON csr.term_cond_doc TO csrimp;
GRANT INSERT ON csr.term_cond_doc_log TO csrimp;

GRANT SELECT, INSERT, DELETE, UPDATE ON csr.term_cond_doc TO web_user;
GRANT SELECT, INSERT, DELETE, UPDATE ON csr.term_cond_doc_log TO web_user;
GRANT SELECT, INSERT, DELETE, UPDATE ON csrimp.term_cond_doc TO web_user;
GRANT SELECT, INSERT, DELETE, UPDATE ON csrimp.term_cond_doc_log TO web_user;

GRANT SELECT, INSERT, DELETE, UPDATE ON csr.term_cond_doc TO chain;
GRANT SELECT, INSERT, DELETE, UPDATE ON csr.term_cond_doc_log TO chain;
GRANT SELECT ON csr.doc_version TO chain;
GRANT EXECUTE ON csr.doc_pkg TO chain;

GRANT SELECT ON chain.company_type TO csr;
GRANT SELECT ON chain.v$company_member TO csr;
GRANT SELECT ON chain.v$chain_user TO csr;

DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);
	type t_tabs is table of varchar2(30);
	v_list t_tabs;
	v_null_list t_tabs;
	v_found number;
begin	
	v_list := t_tabs(
        'TERM_COND_DOC',
		'TERM_COND_DOC_LOG'
	);
	for i in 1 .. v_list.count loop
		declare
			v_name varchar2(30);
			v_i pls_integer default 1;
		begin
			loop
				begin
					
					-- verify that the table has an app_sid column (dev helper)
					select count(*) 
					  into v_found
					  from all_tab_columns 
					 where owner = 'CSR' 
					   and table_name = UPPER(v_list(i))
					   and column_name = 'APP_SID';
					
					if v_found = 0 then
						raise_application_error(-20001, 'CSR.'||v_list(i)||' does not have an app_sid column');
					end if;
					
					if v_i = 1 then
						v_name := SUBSTR(v_list(i), 1, 23)||'_POLICY';
					else
						v_name := SUBSTR(v_list(i), 1, 21)||'_POLICY_'||v_i;
					end if;
					dbms_output.put_line('doing '||v_name);
				    dbms_rls.add_policy(
				        object_schema   => 'CSR',
				        object_name     => v_list(i),
				        policy_name     => v_name,
				        function_schema => 'CSR',
				        policy_function => 'appSidCheck',
				        statement_types => 'select, insert, update, delete',
				        update_check	=> true,
				        policy_type     => dbms_rls.context_sensitive );
				    -- dbms_output.put_line('done  '||v_name);
				  	exit;
				exception
					when policy_already_exists then
						v_i := v_i + 1;
					WHEN FEATURE_NOT_ENABLED THEN
						DBMS_OUTPUT.PUT_LINE('RLS policy '||v_name||' not applied as feature not enabled');
						exit;
				end;
			end loop;
		end;
	end loop;
end;
/

CREATE OR REPLACE VIEW csr.v$term_cond_doc AS
	SELECT DISTINCT tcd.doc_id, dv.filename, dbms_lob.substr(dv.description) AS description, dv.version, tcd.company_type_id
	  FROM csr.term_cond_doc tcd
	  JOIN csr.doc_current dc ON dc.app_sid = security_pkg.GetApp AND dc.doc_id = tcd.doc_id
	  JOIN csr.doc_version dv ON dv.app_sid = security_pkg.GetApp AND dv.doc_id = tcd.doc_id AND dv.version = dc.version
	 WHERE tcd.app_sid = security_pkg.GetApp
	   AND dbms_lob.substr(dv.change_description) <> 'Deleted';

@..\doc_pkg
@..\doc_body
@update_tail
