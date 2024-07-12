-- Please update version.sql too -- this keeps clean builds in sync
define version=755
@update_header

ALTER TABLE csr.QUICK_SURVEY_QUESTION RENAME COLUMN IND_SID TO MAPS_TO_IND_SID;

ALTER TABLE csr.QUICK_SURVEY MODIFY CREATED_DTM DEFAULT SYSDATE NOT NULL ;

CREATE SEQUENCE csr.QS_DIMENSION_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;

CREATE TABLE QS_DIMENSION(
    APP_SID            NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    QS_DIMENSION_ID    NUMBER(10, 0)    NOT NULL,
    LABEL              VARCHAR2(255)    NOT NULL,
    IS_VISIBLE         NUMBER(1, 0)     DEFAULT 1 NOT NULL,
    CONSTRAINT CHK_QS_DIM_VISIBLE CHECK (IS_VISIBLE IN (0,1)),
    CONSTRAINT PK_QS_DIMENSION PRIMARY KEY (APP_SID, QS_DIMENSION_ID)
);


CREATE TABLE QS_DIMENSION_QUESTION(
    APP_SID            NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    QS_DIMENSION_ID    NUMBER(10, 0)    NOT NULL,
    QUESTION_ID        NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_QS_DIMENSION_QUESTION PRIMARY KEY (APP_SID, QS_DIMENSION_ID, QUESTION_ID)
);



ALTER TABLE csr.QS_QUESTION_OPTION ADD (
    MAPS_TO_IND_SID       NUMBER(10, 0)
);
 
ALTER TABLE csr.QUICK_SURVEY_RESPONSE ADD (
    QS_CAMPAIGN_SID          NUMBER(10, 0)
);

ALTER TABLE csr.QS_DIMENSION ADD CONSTRAINT RefCUSTOMER2443 
    FOREIGN KEY (APP_SID)
    REFERENCES csr.CUSTOMER(APP_SID);

ALTER TABLE csr.QS_DIMENSION_QUESTION ADD CONSTRAINT FK_DIM_DIM_QUESTION 
    FOREIGN KEY (APP_SID, QS_DIMENSION_ID)
    REFERENCES csr.QS_DIMENSION(APP_SID, QS_DIMENSION_ID);

ALTER TABLE csr.QS_DIMENSION_QUESTION ADD CONSTRAINT FK_QS_QUES_DIM_QUES 
    FOREIGN KEY (APP_SID, QUESTION_ID)
    REFERENCES csr.QUICK_SURVEY_QUESTION(APP_SID, QUESTION_ID);

 
ALTER TABLE csr.QS_QUESTION_OPTION ADD CONSTRAINT FK_IND_QS_QUESTION_OPT 
    FOREIGN KEY (APP_SID, MAPS_TO_IND_SID)
    REFERENCES csr.IND(APP_SID, IND_SID);
 
ALTER TABLE csr.QUICK_SURVEY_RESPONSE ADD CONSTRAINT FK_QS_CAMP_QS_RESPONSE 
    FOREIGN KEY (APP_SID, QS_CAMPAIGN_SID)
    REFERENCES csr.QS_CAMPAIGN(APP_SID, QS_CAMPAIGN_SID);


-- add in training/videos webresource across all CSR sites
DECLARE
	v_act	security_pkg.T_ACT_ID;
	v_sid	security_pkg.T_SID_ID;
BEGIN
	user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);
	FOR r IN (
		SELECT application_sid_id, web_root_sid_id
		  FROM security.website
		 WHERE application_sid_id in (
			SELECT app_sid FROM csr.customer
		 )
	)
	LOOP
		BEGIN
			web_pkg.CreateResource(v_act, r.web_root_sid_id, r.web_root_sid_id, 'training', v_sid);
		EXCEPTION
			WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
				v_sid := null;
		END;
		IF v_sid IS NOT NULL THEN 
			web_pkg.CreateResource(v_act, r.web_root_sid_id, v_sid, 'videos', v_sid);		
			acl_pkg.AddACE(v_act, acl_pkg.GetDACLIDForSID(v_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
				security_pkg.ACE_FLAG_DEFAULT, securableobject_pkg.getsidfrompath(v_act, r.application_sid_id, 'Groups/RegisteredUsers'), security_pkg.PERMISSION_STANDARD_READ);
		END IF;
	END LOOP;
END;
/

declare
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);

	type t_tabs is table of varchar2(30);
	v_list t_tabs;
	v_null_list t_tabs;
begin	
	v_list := t_tabs(
		'QS_DIMENSION',
		'QS_DIMENSION_QUESTION'
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


@..\quick_survey_pkg
@..\measure_pkg

@..\quick_survey_body
@..\measure_body


@update_tail
