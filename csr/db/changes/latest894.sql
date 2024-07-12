-- Please update version.sql too -- this keeps clean builds in sync
define version=894
@update_header

alter table csr.customer_alert_type modify std_alert_type_Id null;


CREATE SEQUENCE CSR.TPL_REPORT_TAG_TEXT_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;

ALTER TABLE CSR.APPROVAL_DASHBOARD ADD (
    TPL_REPORT_SID            NUMBER(10, 0),
    IS_MULTI_REGION           NUMBER(1, 0)     DEFAULT 1 NOT NULL,
    CONSTRAINT CHK_APPR_DASH_MULTI_REG CHECK (IS_MULTI_REGION IN (0,1)),
    CONSTRAINT UK_TPL_APPROVAL_DASHBOARD  UNIQUE (APP_SID, APPROVAL_DASHBOARD_SID, TPL_REPORT_SID),
    CONSTRAINT UK_FL_APPROVAL_DASHBOARD  UNIQUE (APP_SID, APPROVAL_DASHBOARD_SID, FLOW_SID)
);
 
CREATE TABLE CSR.APPROVAL_DASHBOARD_ALERT_TYPE(
    APP_SID                   NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    APPROVAL_DASHBOARD_SID    NUMBER(10, 0)    NOT NULL,
    CUSTOMER_ALERT_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    FLOW_SID                  NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_APPR_DASH_ALERT_TYPE PRIMARY KEY (APP_SID, APPROVAL_DASHBOARD_SID, CUSTOMER_ALERT_TYPE_ID, FLOW_SID)
);


ALTER TABLE CSR.APPROVAL_DASHBOARD_INSTANCE ADD (     
    TPL_REPORT_SID            NUMBER(10, 0),
    CONSTRAINT UK_TPL_APPR_DASHBD_INSTANCE  UNIQUE (APP_SID, DASHBOARD_INSTANCE_ID, TPL_REPORT_SID)
);

CREATE TABLE CSR.APPROVAL_DASHBOARD_TPL_TAG(
    APP_SID                  NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    DASHBOARD_INSTANCE_ID    NUMBER(10, 0)    NOT NULL,
    TPL_REPORT_SID           NUMBER(10, 0)    NOT NULL,
    TAG                      VARCHAR2(255)    NOT NULL,
    NOTE                  	 CLOB,
    CONSTRAINT PK_APPR_DASHBD_TPL_TAG PRIMARY KEY (APP_SID, DASHBOARD_INSTANCE_ID, TPL_REPORT_SID, TAG)
);

ALTER TABLE CSR.FLOW ADD (
    HELPER_PKG          VARCHAR2(255)
);

CREATE TABLE CSR.FLOW_ALERT_TYPE(
    APP_SID                   NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    CUSTOMER_ALERT_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    FLOW_SID                  NUMBER(10, 0)    NOT NULL,
    LABEL                     VARCHAR2(255)    NOT NULL,
    CONSTRAINT PK_FLOW_ALERT_TYPE PRIMARY KEY (APP_SID, CUSTOMER_ALERT_TYPE_ID),
    CONSTRAINT UK_FLOW_ALERT_TYPE  UNIQUE (APP_SID, CUSTOMER_ALERT_TYPE_ID, FLOW_SID)
);

CREATE TABLE CSR.FLOW_TRANSITION_ALERT(
    APP_SID                     NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    FLOW_STATE_TRANSITION_ID    NUMBER(10, 0)    NOT NULL,
    CUSTOMER_ALERT_TYPE_ID      NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_FLOW_TRANSITION_ALERT PRIMARY KEY (APP_SID, FLOW_STATE_TRANSITION_ID, CUSTOMER_ALERT_TYPE_ID)
);

CREATE TABLE CSR.FLOW_TRANSITION_ALERT_ROLE(
    APP_SID                     NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    FLOW_STATE_TRANSITION_ID    NUMBER(10, 0)    NOT NULL,
    CUSTOMER_ALERT_TYPE_ID      NUMBER(10, 0)    NOT NULL,
    ROLE_SID                    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_FLOW_TRANS_ALERT_ROLE PRIMARY KEY (APP_SID, FLOW_STATE_TRANSITION_ID, CUSTOMER_ALERT_TYPE_ID, ROLE_SID)
);

ALTER TABLE CSR.TPL_REPORT_TAG DROP CONSTRAINT CT_TPL_REPORT_TAG;

ALTER TABLE CSR.TPL_REPORT_TAG ADD (
    TPL_REPORT_TAG_TEXT_ID            NUMBER(10, 0),
    CONSTRAINT CT_TPL_REPORT_TAG CHECK ((tag_type IN (1,4,5) AND tpl_report_tag_ind_id IS NOT NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL)
OR (tag_type = 6 AND tpl_report_tag_eval_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL)
OR (tag_type IN (2,3) AND tpl_report_tag_dataview_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL)
OR (tag_type = 7 AND tpl_report_tag_logging_form_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL)
OR (tag_type = 8 AND tpl_rep_cust_tag_type_id IS NOT NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_text_id IS NULL)
OR (tag_type = 9 AND tpl_report_tag_text_id IS NOT NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL))
);

CREATE TABLE CSR.TPL_REPORT_TAG_TEXT(
    APP_SID                   NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    TPL_REPORT_TAG_TEXT_ID    NUMBER(10, 0)     NOT NULL,
    LABEL                     VARCHAR2(2048)    NOT NULL,
    CONSTRAINT PK_TPL_REPORT_TAG_TEXT PRIMARY KEY (APP_SID, TPL_REPORT_TAG_TEXT_ID)
);

ALTER TABLE CSR.APPROVAL_DASHBOARD ADD CONSTRAINT FK_TPL_REPORT_APPR_DASH 
    FOREIGN KEY (APP_SID, TPL_REPORT_SID)
    REFERENCES CSR.TPL_REPORT(APP_SID, TPL_REPORT_SID);
    
ALTER TABLE CSR.APPROVAL_DASHBOARD_ALERT_TYPE ADD CONSTRAINT FK_APR_DSH_APR_DSH_AL_TYPE 
    FOREIGN KEY (APP_SID, APPROVAL_DASHBOARD_SID, FLOW_SID)
    REFERENCES CSR.APPROVAL_DASHBOARD(APP_SID, APPROVAL_DASHBOARD_SID, FLOW_SID);

ALTER TABLE CSR.APPROVAL_DASHBOARD_ALERT_TYPE ADD CONSTRAINT FK_FL_ALTY_AP_DSH_ALTY 
    FOREIGN KEY (APP_SID, CUSTOMER_ALERT_TYPE_ID, FLOW_SID)
    REFERENCES CSR.FLOW_ALERT_TYPE(APP_SID, CUSTOMER_ALERT_TYPE_ID, FLOW_SID);


ALTER TABLE CSR.APPROVAL_DASHBOARD_INSTANCE DROP CONSTRAINT FK_APP_DASH_APP_DASH_INST;

ALTER TABLE CSR.APPROVAL_DASHBOARD_INSTANCE ADD CONSTRAINT FK_APP_DASH_APP_DASH_INST 
    FOREIGN KEY (APP_SID, APPROVAL_DASHBOARD_SID, TPL_REPORT_SID)
    REFERENCES CSR.APPROVAL_DASHBOARD(APP_SID, APPROVAL_DASHBOARD_SID, TPL_REPORT_SID);


ALTER TABLE CSR.APPROVAL_DASHBOARD_TPL_TAG ADD CONSTRAINT FK_APR_DSH_INS_TPL_TAG 
    FOREIGN KEY (APP_SID, DASHBOARD_INSTANCE_ID, TPL_REPORT_SID)
    REFERENCES CSR.APPROVAL_DASHBOARD_INSTANCE(APP_SID, DASHBOARD_INSTANCE_ID, TPL_REPORT_SID);

ALTER TABLE CSR.APPROVAL_DASHBOARD_TPL_TAG ADD CONSTRAINT FK_TPL_RPT_TAG_APR_DASH 
    FOREIGN KEY (APP_SID, TPL_REPORT_SID, TAG)
    REFERENCES CSR.TPL_REPORT_TAG(APP_SID, TPL_REPORT_SID, TAG);

ALTER TABLE CSR.FLOW_ALERT_TYPE ADD CONSTRAINT FK_CAT_FL_AL_TYPE 
    FOREIGN KEY (APP_SID, CUSTOMER_ALERT_TYPE_ID)
    REFERENCES CSR.CUSTOMER_ALERT_TYPE(APP_SID, CUSTOMER_ALERT_TYPE_ID);

ALTER TABLE CSR.FLOW_ALERT_TYPE ADD CONSTRAINT FK_FLOW_FL_AL_TYPE 
    FOREIGN KEY (APP_SID, FLOW_SID)
    REFERENCES CSR.FLOW(APP_SID, FLOW_SID);

ALTER TABLE CSR.FLOW_TRANSITION_ALERT ADD CONSTRAINT FK_FL_AL_TYPE_FTA 
    FOREIGN KEY (APP_SID, CUSTOMER_ALERT_TYPE_ID)
    REFERENCES CSR.FLOW_ALERT_TYPE(APP_SID, CUSTOMER_ALERT_TYPE_ID);

ALTER TABLE CSR.FLOW_TRANSITION_ALERT ADD CONSTRAINT FK_FST_FL_TR_ALERT 
    FOREIGN KEY (APP_SID, FLOW_STATE_TRANSITION_ID)
    REFERENCES CSR.FLOW_STATE_TRANSITION(APP_SID, FLOW_STATE_TRANSITION_ID);

ALTER TABLE CSR.FLOW_TRANSITION_ALERT_ROLE ADD CONSTRAINT FK_FL_TR_ALRT_ALRT_ROLE 
    FOREIGN KEY (APP_SID, FLOW_STATE_TRANSITION_ID, CUSTOMER_ALERT_TYPE_ID)
    REFERENCES CSR.FLOW_TRANSITION_ALERT(APP_SID, FLOW_STATE_TRANSITION_ID, CUSTOMER_ALERT_TYPE_ID);

ALTER TABLE CSR.FLOW_TRANSITION_ALERT_ROLE ADD CONSTRAINT FK_ROLE_FL_TR_AL_ROLE 
    FOREIGN KEY (APP_SID, ROLE_SID)
    REFERENCES CSR.ROLE(APP_SID, ROLE_SID);

ALTER TABLE CSR.TPL_REPORT_TAG ADD CONSTRAINT FK_TPL_RPT_TAG_TXT_TRT 
    FOREIGN KEY (APP_SID, TPL_REPORT_TAG_TEXT_ID)
    REFERENCES CSR.TPL_REPORT_TAG_TEXT(APP_SID, TPL_REPORT_TAG_TEXT_ID);

ALTER TABLE CSR.TPL_REPORT_TAG_TEXT ADD CONSTRAINT FK_CUS_TPL_RPT_TAG_TEXT 
    FOREIGN KEY (APP_SID)
    REFERENCES CSR.CUSTOMER(APP_SID);

CREATE SEQUENCE CSR.FLOW_ITEM_ALERT_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;


ALTER TABLE CSR.FLOW_STATE_LOG ADD (
    CONSTRAINT UK_FLOW_STATE_LOG  UNIQUE (APP_SID, FLOW_STATE_LOG_ID, FLOW_ITEM_ID)
);

-- no rls on this
CREATE TABLE CSR.FLOW_ITEM_ALERT(
	APP_SID                     NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    FLOW_ITEM_ALERT_ID          NUMBER(10, 0)    NOT NULL,
    FLOW_ITEM_ID                NUMBER(10, 0)    NOT NULL,
    FLOW_STATE_LOG_ID           NUMBER(10, 0)    NOT NULL,
    FLOW_STATE_TRANSITION_ID    NUMBER(10, 0)    NOT NULL,
    CUSTOMER_ALERT_TYPE_ID      NUMBER(10, 0)    NOT NULL,
    PROCESSED_DTM               DATE,
    CONSTRAINT PK_FLOW_ITEM_ALERT PRIMARY KEY (APP_SID, FLOW_ITEM_ALERT_ID)
);

ALTER TABLE CSR.FLOW_ITEM_ALERT ADD CONSTRAINT FK_CUS_FLOW_ITEM_ALERT 
    FOREIGN KEY (APP_SID)
    REFERENCES CSR.CUSTOMER(APP_SID);

ALTER TABLE CSR.FLOW_ITEM_ALERT ADD CONSTRAINT FK_FL_TR_ALRT_ITEM_ALRT 
    FOREIGN KEY (APP_SID, FLOW_STATE_TRANSITION_ID, CUSTOMER_ALERT_TYPE_ID)
    REFERENCES CSR.FLOW_TRANSITION_ALERT(APP_SID, FLOW_STATE_TRANSITION_ID, CUSTOMER_ALERT_TYPE_ID);

ALTER TABLE CSR.FLOW_ITEM_ALERT ADD CONSTRAINT FK_FL_ST_LOG_FL_ITEM_ALRT 
    FOREIGN KEY (APP_SID, FLOW_STATE_LOG_ID, FLOW_ITEM_ID)
    REFERENCES CSR.FLOW_STATE_LOG(APP_SID, FLOW_STATE_LOG_ID, FLOW_ITEM_ID);

/* you need to join this to something else, for example
	SELECT DISTINCT x.app_sid, x.region_sid, x.user_sid, x.flow_state_transition_id, x.flow_item_alert_id,
		customer_alert_type_id, x.flow_state_log_id, x.from_state_label, x.to_state_label, 
		x.set_by_user_sid, x.set_by_email, x.set_by_full_name, x.set_by_user_name,
		x.to_user_sid, to_email, to_full_name, to_friendly_name, to_user_name,
		ad.label dashboard_label, adi.start_dtm, adi.end_dtm, adi.approval_dashboard_sid
	  FROM v$open_flow_item_alert x
		JOIN approval_dashboard_instance adi 
			ON adi.dashboard_instance_Id = x.dashboard_instance_id
			AND x.region_sid = adi.region_sid 
			AND x.app_sid = adi.app_sid
		JOIN approval_dashboard ad 
			ON adi.approval_dashboard_sid = ad.approval_dashboard_sid
			AND adi.app_sid = ad.app_sid
*/
CREATE OR REPLACE VIEW csr.v$open_flow_item_alert AS
     SELECT fia.flow_item_alert_id, rrm.region_sid, rrm.user_sid, fta.flow_state_transition_id,
        fia.customer_alert_type_id, flsf.label from_state_label, flst.label to_state_label, 
        fsl.flow_state_log_Id, fsl.set_dtm, 
        fsl.set_by_user_sid, cusb.full_name set_by_full_name, cusb.email set_by_email, cusb.user_name set_by_user_name, 
        cut.csr_user_sid to_user_sid, cut.full_name to_full_name, cut.email to_email, cut.user_name to_user_name, cut.friendly_name to_friendly_name,
        fi.*
       FROM flow_item_alert fia 
        JOIN flow_state_log fsl ON fia.flow_state_log_id = fsl.flow_state_log_id AND fia.app_sid = fsl.app_sid
        JOIN csr_user cusb ON fsl.set_by_user_sid = cusb.csr_user_sid AND fsl.app_sid = cusb.app_sid
        JOIN flow_item fi ON fia.flow_item_id = fi.flow_item_id AND fia.app_sid = fi.app_sid
        JOIN flow_state_transition fst ON fia.flow_state_transition_id = fst.flow_state_transition_id AND fia.app_sid = fst.app_sid
        JOIN flow_state flsf ON fst.from_state_id = flsf.flow_state_id AND fst.app_sid = flsf.app_sid
        JOIN flow_state flst ON fst.to_state_id = flst.flow_state_id AND fst.app_sid = flst.app_sid         
        JOIN flow_transition_alert fta 
            ON fia.flow_state_transition_id = fta.flow_state_transition_id 
            AND fia.customer_alert_type_id = fta.customer_alert_type_id
            AND fia.app_sid = fta.app_sid
        JOIN flow_transition_alert_role ftar 
            ON fta.flow_state_transition_id = ftar.flow_state_transition_id 
            AND fta.customer_alert_type_id = ftar.customer_alert_type_id
            AND fta.app_sid = ftar.app_sid
        JOIN role ro ON ftar.role_sid = ro.role_sid AND ftar.app_sid = ro.app_sid
        JOIN region_role_member rrm ON ro.role_sid = rrm.role_sid AND ro.app_sid = rrm.app_sid
        JOIN csr_user cut ON rrm.user_sid = cut.csr_user_sid AND rrm.app_sid = cut.app_sid
      WHERE fia.processed_dtm IS NULL;


DECLARE
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);

	type t_tabs is table of varchar2(30);
	v_list t_tabs;
	v_null_list t_tabs;
BEGIN	
	v_list := t_tabs(
		'APPROVAL_DASHBOARD_TPL_TAG',
		'APPROVAL_DASHBOARD_ALERT_TYPE',  
		'FLOW_ALERT_TYPE',
		'FLOW_TRANSITION_ALERT',
		'FLOW_ITEM_ALERT',
		'FLOW_TRANSITION_ALERT_ROLE',
		'TPL_REPORT_TAG_TEXT'
	);
	for i in 1 .. v_list.count loop
		declare
			v_name varchar2(30);
			v_i pls_integer default 1;
		begin
			loop
				begin
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
				  	exit;
				exception
					when policy_already_exists then
						v_i := v_i + 1;
				end;
			end loop;
		end;
	end loop;
END;
/


@..\templated_report_pkg
@..\flow_pkg
@..\approval_dashboard_pkg

@..\templated_report_body
@..\flow_body
@..\templated_report_body
 

@update_tail
