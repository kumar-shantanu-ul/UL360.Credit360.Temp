-- Please update version.sql too -- this keeps clean builds in sync
define version=715
@update_header

CREATE SEQUENCE csr.ISSUE_METER_RAW_DATA_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

ALTER TABLE csr.ISSUE DROP CONSTRAINT CHK_ISSUE_FKS;

ALTER TABLE csr.ISSUE ADD (
	ISSUE_METER_RAW_DATA_ID    NUMBER(10, 0)
);

ALTER TABLE csr.ISSUE ADD CONSTRAINT CHK_ISSUE_FKS CHECK (
	(ISSUE_PENDING_VAL_ID IS NOT NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL AND ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_ACTION_ID IS NULL AND ISSUE_METER_ID IS NULL AND ISSUE_METER_ALARM_ID IS NULL AND ISSUE_METER_RAW_DATA_ID IS NULL)
	OR
	(ISSUE_SHEET_VALUE_ID IS NOT NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL AND ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_ACTION_ID IS NULL AND ISSUE_METER_ID IS NULL AND ISSUE_METER_ALARM_ID IS NULL AND ISSUE_METER_RAW_DATA_ID IS NULL)
	OR
	(ISSUE_SURVEY_ANSWER_ID IS NOT NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_ACTION_ID IS NULL AND ISSUE_METER_ID IS NULL AND ISSUE_METER_ALARM_ID IS NULL AND ISSUE_METER_RAW_DATA_ID IS NULL)
	OR
	(ISSUE_NON_COMPLIANCE_ID IS NOT NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL AND ISSUE_ACTION_ID IS NULL AND ISSUE_METER_ID IS NULL AND ISSUE_METER_ALARM_ID IS NULL AND ISSUE_METER_RAW_DATA_ID IS NULL)
	OR
	(ISSUE_ACTION_ID IS NOT NULL AND ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL AND ISSUE_METER_ID IS NULL AND ISSUE_METER_ALARM_ID IS NULL AND ISSUE_METER_RAW_DATA_ID IS NULL)
	OR
	(ISSUE_METER_ID IS NOT NULL AND ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL AND ISSUE_ACTION_ID IS NULL AND ISSUE_METER_ALARM_ID IS NULL AND ISSUE_METER_RAW_DATA_ID IS NULL)
	OR
	(ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_ACTION_ID IS NULL AND ISSUE_METER_ID IS NULL AND ISSUE_METER_ALARM_ID IS NULL AND ISSUE_METER_RAW_DATA_ID IS NULL)
	OR
	(ISSUE_METER_ALARM_ID IS NOT NULL AND ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL AND ISSUE_ACTION_ID IS NULL AND ISSUE_METER_ID IS NULL AND ISSUE_METER_RAW_DATA_ID IS NULL)
	OR
	(ISSUE_METER_RAW_DATA_ID IS NOT NULL AND ISSUE_NON_COMPLIANCE_ID IS NULL AND ISSUE_SHEET_VALUE_ID IS NULL AND ISSUE_PENDING_VAL_ID IS NULL AND ISSUE_SURVEY_ANSWER_ID IS NULL AND ISSUE_ACTION_ID IS NULL AND ISSUE_METER_ID IS NULL AND ISSUE_METER_ALARM_ID IS NULL)
);

CREATE TABLE csr.ISSUE_METER_RAW_DATA(
    APP_SID                    NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    ISSUE_METER_RAW_DATA_ID    NUMBER(10, 0)    NOT NULL,
    METER_RAW_DATA_ID          NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK994 PRIMARY KEY (APP_SID, ISSUE_METER_RAW_DATA_ID)
)
;

ALTER TABLE csr.ISSUE ADD CONSTRAINT RefISSUE_METER_RAW_DATA2211 
    FOREIGN KEY (APP_SID, ISSUE_METER_RAW_DATA_ID)
    REFERENCES csr.ISSUE_METER_RAW_DATA(APP_SID, ISSUE_METER_RAW_DATA_ID)
;

ALTER TABLE csr.ISSUE_METER_RAW_DATA ADD CONSTRAINT RefMETER_RAW_DATA2212 
    FOREIGN KEY (APP_SID, METER_RAW_DATA_ID)
    REFERENCES csr.METER_RAW_DATA(APP_SID, METER_RAW_DATA_ID)
;

ALTER TABLE csr.ISSUE_METER_RAW_DATA ADD CONSTRAINT RefCUSTOMER2213 
    FOREIGN KEY (APP_SID)
    REFERENCES csr.CUSTOMER(APP_SID)
;

CREATE OR REPLACE VIEW csr.v$issue AS
	SELECT i.app_sid, i.issue_id, i.label, note, i.source_label,
		   raised_by_user_sid, raised_dtm, curai.user_name raised_user_name, curai.full_name raised_full_name, curai.email raised_email,
		   resolved_by_user_sid, resolved_dtm, cures.user_name resolved_user_name, cures.full_name resolved_full_name, cures.email resolved_email,
		   closed_by_user_sid, closed_dtm, cuclo.user_name closed_user_name, cuclo.full_name closed_full_name, cuclo.email closed_email,
		   assigned_to_user_sid, cuass.user_name assigned_to_user_name, cuass.full_name assigned_to_full_name, cuass.email assigned_to_email,
		   sysdate now_dtm, due_dtm, ist.issue_type_Id, ist.label issue_type_label,
		   issue_pending_val_id, issue_sheet_value_id, issue_survey_answer_id, issue_non_compliance_Id, issue_action_id, issue_meter_id, issue_meter_alarm_id, issue_meter_raw_data_id,
		   CASE 
			WHEN closed_by_user_sid IS NULL AND resolved_by_user_sid IS NULL AND SYSDATE > due_dtm THEN 1
			ELSE 0 
		   END is_overdue
	  FROM issue i, issue_type ist, csr_user curai, csr_user cures, csr_user cuclo, csr_user cuass
	 WHERE i.app_sid = curai.app_sid AND i.raised_by_user_sid = curai.csr_user_sid
	   AND i.app_sid = ist.app_sid AND i.issue_type_Id = ist.issue_type_id
	   AND i.app_sid = cures.app_sid(+) AND i.resolved_by_user_sid = cures.csr_user_sid(+) 
	   AND i.app_sid = cuclo.app_sid(+) AND i.closed_by_user_sid = cuclo.csr_user_sid(+)
	   AND i.app_sid = cuass.app_sid(+) AND i.assigned_to_user_sid = cuass.csr_user_sid(+)
;

DECLARE
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);

	type t_tabs is table of varchar2(30);
	v_list t_tabs;
	v_null_list t_tabs;
BEGIN	
	v_list := t_tabs(
		'ISSUE_METER_RAW_DATA'
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


@update_tail
