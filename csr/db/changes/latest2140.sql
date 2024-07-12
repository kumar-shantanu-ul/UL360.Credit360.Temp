-- Please update version.sql too -- this keeps clean builds in sync
define version=2140
@update_header


CREATE TABLE CSR.OUTSTANDING_REQUESTS_JOB(
    APP_SID            NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    EST_ACCOUNT_SID    NUMBER(10, 0)    NOT NULL,
    BATCH_JOB_ID       NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_OUTSTANDING_REQUESTS_JOB PRIMARY KEY (APP_SID, EST_ACCOUNT_SID, BATCH_JOB_ID)
);


ALTER TABLE CSR.OUTSTANDING_REQUESTS_JOB ADD CONSTRAINT FK_ACC_OUTS_REQ_JOB 
    FOREIGN KEY (APP_SID, EST_ACCOUNT_SID)
    REFERENCES CSR.EST_ACCOUNT(APP_SID, EST_ACCOUNT_SID)
;

ALTER TABLE CSR.OUTSTANDING_REQUESTS_JOB ADD CONSTRAINT FK_BJOB_OUTS_REQ_JOB 
    FOREIGN KEY (APP_SID, BATCH_JOB_ID)
    REFERENCES CSR.BATCH_JOB(APP_SID, BATCH_JOB_ID)
;

CREATE INDEX CSR.IX_ACC_OUTS_REQ_JOB ON CSR.OUTSTANDING_REQUESTS_JOB(APP_SID, EST_ACCOUNT_SID);
CREATE INDEX CSR.IX_BJOB_OUTS_REQ_JOB ON CSR.OUTSTANDING_REQUESTS_JOB(APP_SID, BATCH_JOB_ID);

BEGIN
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name)
	VALUES (9, 'Energy Star outstanding requests', 'energy-star-outstanding-req');
END;
/

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
        'OUTSTANDING_REQUESTS_JOB'
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
                        update_check    => true,
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

@../batch_job_pkg
@../energy_star_pkg
@../energy_star_body

@update_tail
