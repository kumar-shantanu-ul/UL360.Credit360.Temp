-- Please update version.sql too -- this keeps clean builds in sync
define version=1740
@update_header

grant execute on security.security_pkg to csr with grant option;

CREATE OR REPLACE VIEW csr.v$postit AS
    SELECT p.app_sid, p.postit_id, p.message, p.label, p.secured_via_sid, p.created_dtm, p.created_by_sid,
        pu.user_name created_by_user_name, pu.full_name created_by_full_name, pu.email created_by_email,
		CASE WHEN p.created_by_sid = SYS_CONTEXT('SECURITY','SID') THEN 1
			 WHEN p.created_by_sid = 3 -- 3 == security.security_pkg.SID_BUILTIN_ADMINISTRATOR, but we can't use that here
			 THEN security.security_pkg.SQL_IsAccessAllowedSID(security_pkg.getACT, p.secured_via_sid, 2) -- 2 == security.security_pkg.PERMISSION_WRITE, ditto
			 ELSE 0 END can_edit
      FROM postit p 
        JOIN csr_user pu ON p.created_by_sid = pu.csr_user_sid AND p.app_sid = pu.app_sid;

UPDATE csr.aggregate_ind_group agg
   SET name = 'QuickSurveyScores.'||(SELECT survey_sid FROM csr.quick_survey qs WHERE qs.aggregate_ind_group_id = agg.aggregate_ind_group_id)
 WHERE name = 'QuickSurveyScores';

-- Fix up any survey agg groups not properly connected to a survey (none are like this on live, but there were some on my local)
UPDATE csr.aggregate_ind_group agg
   SET name = 'QuickSurveyScores.'||agg.aggregate_ind_group_id
 WHERE name = 'QuickSurveyScores.';

ALTER TABLE CSR.AGGREGATE_IND_GROUP ADD CONSTRAINT UK_AGG_IND_GRP_NAME UNIQUE (APP_SID, NAME);

ALTER TABLE CSR.SPACE DROP CONSTRAINT FK_PROPERTY_SPACE;
	
ALTER TABLE CSR.SPACE ADD CONSTRAINT FK_PROPERTY_SPACE 
    FOREIGN KEY (APP_SID, PROPERTY_REGION_SID, PROPERTY_TYPE_ID)
    REFERENCES CSR.PROPERTY(APP_SID, REGION_SID, PROPERTY_TYPE_ID)
	DEFERRABLE INITIALLY DEFERRED;
	
CREATE TABLE CSR.PROPERTY_TAB_GROUP (
	APP_SID						NUMBER (10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	PLUGIN_ID					NUMBER (10) NOT NULL,
	GROUP_SID					NUMBER (10),
	ROLE_SID					NUMBER (10),
	CONSTRAINT PK_PROPERTY_TAB_GROUP PRIMARY KEY (APP_SID, PLUGIN_ID, GROUP_SID),
	CONSTRAINT FK_PRPTY_TAB_GROUP_PRPTY_TAB FOREIGN KEY (APP_SID, PLUGIN_ID) REFERENCES CSR.PROPERTY_TAB(APP_SID, PLUGIN_ID),
	CONSTRAINT CHK_PRPTY_TAB_GROUP_GRP_ROLE CHECK ((GROUP_SID IS NULL AND ROLE_SID IS NOT NULL) OR (GROUP_SID IS NOT NULL AND ROLE_SID IS NULL))
);

CREATE TABLE CSR.FUND_MGMT_CONTACT(
  APP_SID                   NUMBER(10,0)  DEFAULT SYS_CONTEXT('SECURITY','APP')  NOT NULL,
  FUND_ID                   NUMBER(10,0)  NOT NULL,
  MGMT_COMPANY_ID           NUMBER(10,0)  NOT NULL,
  MGMT_COMPANY_CONTACT_ID   NUMBER(10,0)  NOT NULL,
  CONSTRAINT FK_FUND_ID FOREIGN KEY (FUND_ID, APP_SID, MGMT_COMPANY_ID) REFERENCES CSR.FUND(FUND_ID, APP_SID, DEFAULT_MGMT_COMPANY_ID),
  CONSTRAINT FK_MGMT_COMPANY_CONTACT_ID FOREIGN KEY (MGMT_COMPANY_CONTACT_ID, MGMT_COMPANY_ID, APP_SID) REFERENCES CSR.MGMT_COMPANY_CONTACT(MGMT_COMPANY_CONTACT_ID, MGMT_COMPANY_ID, APP_SID)
);

declare
    policy_already_exists exception;
    pragma exception_init(policy_already_exists, -28101);

    type t_tabs is table of varchar2(30);
    v_list t_tabs;
    v_null_list t_tabs;
    v_found number;
begin   
    v_list := t_tabs(
        'PROPERTY_TAB_GROUP',
		'FUND_MGMT_CONTACT'
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
                        exit; -- don't add twice
                end;
            end loop;
        end;
    end loop;
end;
/

@..\region_metric_pkg
@..\aggregate_ind_pkg
@..\property_pkg

@..\role_body
@..\postit_body
@..\region_metric_body
@..\aggregate_ind_body
@..\property_body
@..\flow_body

@update_tail