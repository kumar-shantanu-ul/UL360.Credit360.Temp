-- Please update version.sql too -- this keeps clean builds in sync
define version=1546
@update_header

CREATE SEQUENCE CSR.TPL_REPORT_NON_COMPL_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;


CREATE TABLE CSR.TPL_REPORT_NON_COMPL(
    APP_SID                    NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    TPL_REPORT_NON_COMPL_ID    NUMBER(10, 0)    NOT NULL,
    TPL_REGION_TYPE_ID         NUMBER(10, 0)    NOT NULL,
    MONTH_OFFSET               NUMBER(10, 0)    NOT NULL,
    MONTH_DURATION             NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_TPL_REPORT_NON_COMPL PRIMARY KEY (APP_SID, TPL_REPORT_NON_COMPL_ID)
)
;

ALTER TABLE CSR.TPL_REPORT_TAG DROP CONSTRAINT CT_TPL_REPORT_TAG;
ALTER TABLE CSR.TPL_REPORT_TAG ADD(
    TPL_REPORT_NON_COMPL_ID           NUMBER(10, 0),
    CONSTRAINT CT_TPL_REPORT_TAG CHECK ((tag_type IN (1,4,5) AND tpl_report_tag_ind_id IS NOT NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL)
OR (tag_type = 6 AND tpl_report_tag_eval_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL)
OR (tag_type IN (2,3) AND tpl_report_tag_dataview_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL)
OR (tag_type = 7 AND tpl_report_tag_logging_form_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL)
OR (tag_type = 8 AND tpl_rep_cust_tag_type_id IS NOT NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL)
OR (tag_type = 9 AND tpl_report_tag_text_id IS NOT NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL)
OR (tag_type = -1 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL)
OR (tag_type = 10 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NOT NULL))
)
;

CREATE INDEX CSR.IX_TPL_REP_TAG_NON_COMPL ON CSR.TPL_REPORT_TAG(APP_SID, TPL_REPORT_NON_COMPL_ID)
;

ALTER TABLE CSR.TPL_REPORT_NON_COMPL ADD CONSTRAINT FK_TPL_REP_NC_REG_TYP 
    FOREIGN KEY (TPL_REGION_TYPE_ID)
    REFERENCES CSR.TPL_REGION_TYPE(TPL_REGION_TYPE_ID)
;

ALTER TABLE CSR.TPL_REPORT_NON_COMPL ADD CONSTRAINT FK_TPL_REP_NON_COMPL_APP 
    FOREIGN KEY (APP_SID)
    REFERENCES CSR.CUSTOMER(APP_SID)
;

ALTER TABLE CSR.TPL_REPORT_TAG ADD CONSTRAINT FK_TPL_REP_TAG_NON_COMPL 
    FOREIGN KEY (APP_SID, TPL_REPORT_NON_COMPL_ID)
    REFERENCES CSR.TPL_REPORT_NON_COMPL(APP_SID, TPL_REPORT_NON_COMPL_ID)  DEFERRABLE INITIALLY DEFERRED
;

declare
    policy_already_exists exception;
    pragma exception_init(policy_already_exists, -28101);

    type t_tabs is table of varchar2(30);
    v_list t_tabs;
    v_null_list t_tabs;
    v_found number;
begin   
    v_list := t_tabs(
        'TPL_REPORT_NON_COMPL'
    );
    for i in 1 .. v_list.count loop
        declare
            v_name varchar2(30);
            v_i pls_integer default 1;
        begin
            loop
                begin               
                    v_name := SUBSTR(v_list(i), 1, 23)||'_POLICY';
                    
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
                    exit;
                exception
                    when policy_already_exists then
                        NULL;
                end;
            end loop;
        end;
    end loop;
end;
/

CREATE TABLE CSRIMP.TPL_REPORT_NON_COMPL(
    CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    TPL_REPORT_NON_COMPL_ID    NUMBER(10, 0)    NOT NULL,
    TPL_REGION_TYPE_ID         NUMBER(10, 0)    NOT NULL,
    MONTH_OFFSET               NUMBER(10, 0)    NOT NULL,
    MONTH_DURATION             NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_TPL_REPORT_NON_COMPL PRIMARY KEY (CSRIMP_SESSION_ID, TPL_REPORT_NON_COMPL_ID),
    CONSTRAINT FK_TPL_RPT_NON_COMPL_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
)
;

ALTER TABLE CSRIMP.TPL_REPORT_TAG DROP CONSTRAINT CT_TPL_REPORT_TAG;
ALTER TABLE CSRIMP.TPL_REPORT_TAG ADD(
    TPL_REPORT_NON_COMPL_ID           NUMBER(10, 0),
    CONSTRAINT CT_TPL_REPORT_TAG CHECK ((tag_type IN (1,4,5) AND tpl_report_tag_ind_id IS NOT NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL)
OR (tag_type = 6 AND tpl_report_tag_eval_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL)
OR (tag_type IN (2,3) AND tpl_report_tag_dataview_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL)
OR (tag_type = 7 AND tpl_report_tag_logging_form_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL)
OR (tag_type = 8 AND tpl_rep_cust_tag_type_id IS NOT NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL)
OR (tag_type = 9 AND tpl_report_tag_text_id IS NOT NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL)
OR (tag_type = -1 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL)
OR (tag_type = 10 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NOT NULL))
)
;

CREATE TABLE csrimp.map_tpl_report_non_compl (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_tpl_report_non_compl_id	NUMBER(10)	NOT NULL,
	new_tpl_report_non_compl_id	NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_tpl_report_non_compl PRIMARY KEY (old_tpl_report_non_compl_id) USING INDEX,
	CONSTRAINT uk_map_tpl_report_non_compl UNIQUE (new_tpl_report_non_compl_id) USING INDEX,
    CONSTRAINT FK_MAP_TPL_REP_NON_COMPL_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

grant insert on csr.tpl_report_non_compl to csrimp;
grant select on csr.tpl_report_non_compl_id_seq to csrimp;
grant select,insert,update,delete on csrimp.tpl_report_non_compl to web_user;

BEGIN
	dbms_rls.add_policy(
		object_schema   => 'CSRIMP',
		object_name     => 'TPL_REPORT_NON_COMPL',
		policy_name     => 'TPL_REPORT_NON_COMPL_POL', 
		function_schema => 'CSRIMP',
		policy_function => 'SessionIDCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.static);
	dbms_rls.add_policy(
		object_schema   => 'CSRIMP',
		object_name     => 'MAP_TPL_REPORT_NON_COMPL',
		policy_name     => 'MAP_TPL_REPORT_NON_COMPL_POL', 
		function_schema => 'CSRIMP',
		policy_function => 'SessionIDCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.static);
END;
/

-- Flatten the join tables to make it easier to find delegations from a delegation plan
CREATE OR REPLACE VIEW csr.v$deleg_plan_delegs AS
	SELECT dpc.app_sid, dpc.deleg_plan_sid, dpcd.delegation_sid template_deleg_sid,
		   dpdrd.maps_to_root_deleg_sid, d.delegation_sid applied_to_delegation_sid
	  FROM deleg_plan_col dpc
	  JOIN deleg_plan_col_deleg dpcd ON dpc.deleg_plan_col_deleg_id = dpcd.deleg_plan_col_deleg_id AND dpc.app_sid = dpcd.app_sid
	  JOIN deleg_plan_deleg_region_deleg dpdrd ON dpcd.deleg_plan_col_deleg_id = dpdrd.deleg_plan_col_deleg_id AND dpcd.app_sid = dpdrd.app_sid
	  JOIN (
		SELECT CONNECT_BY_ROOT delegation_sid root_delegation_sid, delegation_sid
		  FROM delegation
		 START WITH parent_sid = app_sid
		CONNECT BY PRIOR delegation_sid = parent_sid AND PRIOR app_sid = app_sid
	  ) d ON d.root_delegation_sid = dpdrd.maps_to_root_deleg_sid;


@..\audit_pkg
@..\templated_report_pkg
@..\schema_pkg

@..\audit_body
@..\templated_report_body
@..\schema_body
@..\csrimp\imp_body


@update_tail