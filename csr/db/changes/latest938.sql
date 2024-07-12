-- Please update version.sql too -- this keeps clean builds in sync
define version=938
@update_header


-- TODO add to schema2.dm1
ALTER TABLE CSR.QUICK_SURVEY_QUESTION ADD (
	MAX_SCORE			NUMBER(10, 0),
	UPLOAD_SCORE		NUMBER(10, 0)
);

-- TODO add to schema2.dm1
ALTER TABLE CSR.QS_QUESTION_OPTION ADD (
	OPTION_ACTION		VARCHAR2(50)
);

DROP TYPE CSR.T_QS_QUESTION_TABLE;
DROP TYPE CSR.T_QS_QUESTION_OPTION_TABLE;

CREATE OR REPLACE TYPE CSR.T_QS_QUESTION_ROW AS
	OBJECT (
		QUESTION_ID		NUMBER(10),
		PARENT_ID		NUMBER(10),
		POS				NUMBER(10), 
		LABEL			VARCHAR2(4000), 
		QUESTION_TYPE	VARCHAR2(40), 
		SCORE			NUMBER(10),
		MAX_SCORE		NUMBER(10),
		UPLOAD_SCORE	NUMBER(10),
		LOOKUP_KEY		VARCHAR2(255),
		INVERT_SCORE	VARCHAR2(255)
	);
/

CREATE OR REPLACE TYPE CSR.T_QS_QUESTION_OPTION_ROW AS
	OBJECT (
		QUESTION_ID			NUMBER(10),
		QUESTION_OPTION_ID	NUMBER(10),
		POS					NUMBER(10),
		LABEL				VARCHAR2(4000), 
		SCORE				NUMBER(10),
		COLOR				NUMBER(10),
		LOOKUP_KEY			VARCHAR2(255),
		OPTION_ACTION		VARCHAR2(50)
	);
/

CREATE TYPE CSR.T_QS_QUESTION_TABLE AS
  TABLE OF CSR.T_QS_QUESTION_ROW;
/

CREATE OR REPLACE TYPE CSR.T_QS_QUESTION_OPTION_TABLE AS
  TABLE OF CSR.T_QS_QUESTION_OPTION_ROW;
/

grant select on csr.customer_alert_type to chain;

UPDATE csr.issue i SET region_sid = (SELECT region_sid
  FROM (
	SELECT i.app_sid, i.issue_id, pr.maps_to_region_sid region_sid
	  FROM csr.issue i, csr.issue_pending_Val ipv, csr.pending_region pr
	 WHERE i.issue_pending_val_id = ipv.issue_pending_val_id
	   AND ipv.pending_region_id = pr.pending_region_id
	   AND pr.maps_to_region_sid IS NOT NULL
	 UNION ALL
	SELECT i.app_sid, i.issue_id, isv.region_sid
	  FROM csr.issue i, csr.issue_sheet_value isv
	 WHERE i.issue_sheet_value_id = isv.issue_sheet_value_id
	 UNION ALL
	SELECT i.app_sid, i.issue_id, ia.region_sid
	  FROM csr.issue i 
	  JOIN csr.issue_non_compliance inc ON i.issue_non_compliance_id = inc.issue_non_compliance_id AND i.app_sid = inc.app_sid
	  JOIN csr.non_compliance nc ON inc.non_compliance_id = nc.non_compliance_id AND inc.app_sid = nc.app_sid
	  JOIN csr.internal_audit ia ON nc.internal_audit_sid = ia.internal_audit_sid AND nc.app_sid = ia.app_sid
	 UNION ALL
	SELECT i.app_sid, i.issue_id, im.region_sid
	  FROM csr.issue i, csr.issue_meter im
	 WHERE i.app_sid = im.app_sid
	   AND i.issue_meter_id = im.issue_meter_id
	 UNION ALL
	SELECT i.app_sid, i.issue_id, ima.region_sid
	  FROM csr.issue i, csr.issue_meter_alarm ima
	 WHERE i.app_sid = ima.app_sid
	   AND i.issue_meter_alarm_id = ima.issue_meter_alarm_id
	 UNION ALL
	SELECT i.app_sid, i.issue_id, rd.region_sid
	  FROM csr.issue i, csr.issue_meter_raw_data rd
	 WHERE i.app_sid = rd.app_sid
	   AND i.issue_meter_raw_data_id = rd.issue_meter_raw_data_id
	   AND rd.region_sid IS NOT NULL
) p WHERE i.app_sid = p.app_sid AND i.issue_id = p.issue_id AND i.region_sid IS NULL);

CREATE OR REPLACE VIEW csr.v$issue_log AS
	SELECT il.app_sid, il.issue_log_id, il.issue_Id, il.message, il.logged_by_user_sid, 
		   cu.user_name logged_by_user_name, cu.email logged_by_email, il.logged_dtm,
		   il.is_system_generated, param_1, param_2, param_3, sysdate now_dtm,
		   CASE WHEN il.logged_by_user_sid IS NULL THEN 0 ELSE 1 END is_user,
		   CASE WHEN il.logged_by_user_sid IS NULL THEN ilc.full_name ELSE cu.full_name END logged_by_full_name
	  FROM issue_log il
	  LEFT JOIN csr_user cu ON il.app_sid = cu.app_sid AND il.logged_by_user_sid = cu.csr_user_sid
	  LEFT JOIN correspondent ilc ON il.logged_by_correspondent_id = ilc.correspondent_id
;


ALTER TABLE CSR.INTERNAL_AUDIT_TYPE ADD (
	DEFAULT_AUDITOR_ORG       VARCHAR2(50)
);

ALTER TABLE CHAIN.FILTER_VALUE ADD(
    REGION_SID         NUMBER(10, 0)
)
;

CREATE INDEX CHAIN.IX_FILTER_VALUE_REGION_SID ON CHAIN.FILTER_VALUE(APP_SID, REGION_SID)
;

GRANT SELECT, REFERENCES ON csr.region TO chain WITH GRANT OPTION;

CREATE OR REPLACE VIEW CHAIN.v$filter_value AS
	SELECT f.app_sid, f.filter_id, ff.filter_field_id, ff.name, fv.filter_value_id, fv.str_value, fv.num_value, fv.dtm_value, fv.region_sid, r.description
	  FROM filter f
	  JOIN filter_field ff ON f.app_sid = ff.app_sid AND f.filter_id = ff.filter_id
	  JOIN filter_value fv ON ff.app_sid = fv.app_sid AND ff.filter_field_id = fv.filter_field_id
	  LEFT JOIN csr.region r ON fv.region_sid = r.region_sid AND fv.app_sid = r.app_sid
	 WHERE f.app_sid = SYS_CONTEXT('SECURITY', 'APP');

grant select on chain.v$filter_value to csr;

grant execute on csr.issue_pkg to chain;

grant select, references on chain.compound_filter to csr;

delete from chain.filter;
delete from chain.compound_filter;

ALTER TABLE CHAIN.COMPOUND_FILTER RENAME COLUMN COMPOUND_FILTER_SID TO COMPOUND_FILTER_ID;
ALTER TABLE CHAIN.COMPOUND_FILTER DROP COLUMN NAME;
ALTER TABLE CHAIN.COMPOUND_FILTER ADD ACT_ID                 CHAR(36);
ALTER TABLE CHAIN.FILTER RENAME COLUMN COMPOUND_FILTER_SID TO COMPOUND_FILTER_ID;

CREATE TABLE CHAIN.SAVED_FILTER(
    APP_SID               NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    SAVED_FILTER_SID      NUMBER(10, 0)    NOT NULL,
    COMPOUND_FILTER_ID    NUMBER(10, 0)    NOT NULL,
    NAME                  VARCHAR2(255)    NOT NULL,
    CONSTRAINT PK_SAVED_FILTER PRIMARY KEY (APP_SID, SAVED_FILTER_SID)
)
;

CREATE INDEX CHAIN.IX_CMP_FIL_CRTD_BY_USR_SID ON CHAIN.COMPOUND_FILTER(CREATED_BY_USER_SID)
;

CREATE INDEX CHAIN.IX_CMP_FIL_ACT_ID ON CHAIN.COMPOUND_FILTER(ACT_ID)
;

CREATE INDEX CHAIN.IX_SAVED_FIL_CMP_FIL_ID ON CHAIN.SAVED_FILTER(APP_SID, COMPOUND_FILTER_ID)
;

ALTER TABLE CHAIN.SAVED_FILTER ADD CONSTRAINT FK_SAVED_FILTER_CMP_ID 
    FOREIGN KEY (APP_SID, COMPOUND_FILTER_ID)
    REFERENCES CHAIN.COMPOUND_FILTER(APP_SID, COMPOUND_FILTER_ID)
;


CREATE SEQUENCE CHAIN.COMPOUND_FILTER_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;


declare
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);

	type t_tabs is table of varchar2(30);
	v_list t_tabs;
	v_null_list t_tabs;
begin	
	v_list := t_tabs(
		'SAVED_FILTER'
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
				        object_schema   => 'CHAIN',
				        object_name     => v_list(i),
				        policy_name     => v_name,
				        function_schema => 'CHAIN',
				        policy_function => 'appSidCheck',
				        statement_types => 'select, insert, update, delete',
				        update_check	=> true,
				        policy_type     => dbms_rls.static);
				    -- dbms_output.put_line('done  '||v_name);
				  	exit;
				exception
					when policy_already_exists then
						v_i := v_i + 1;
				end;
			end loop;
		end;
	end loop;
end;
/

CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_DATES (
	column_value 			DATE,
	CONSTRAINT PK_TEMP_DATES PRIMARY KEY (column_value)
) ON COMMIT DELETE ROWS;

@..\chain\company_filter_pkg
@..\chain\company_pkg
@..\chain\filter_pkg
@..\chain\report_pkg
@..\audit_pkg
@..\issue_pkg
@..\quick_survey_pkg
@..\region_tree_pkg

@..\actions\initiative_body
@..\chain\company_filter_body
@..\chain\company_body
@..\chain\filter_body
@..\chain\report_body
@..\audit_body
@..\issue_body
@..\meter_alarm_body
@..\meter_monitor_body
@..\quick_survey_body
@..\region_tree_body
@..\supplier_body


@update_tail