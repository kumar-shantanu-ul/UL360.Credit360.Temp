-- Please update version.sql too -- this keeps clean builds in sync
define version=1307
@update_header

ALTER TABLE CHAIN.GROUP_CAPABILITY RENAME CONSTRAINT UNIQUE_GROUP_CAPABILITY TO UK_GROUP_CAPABILITY;

ALTER TABLE CHAIN.INVITATION ADD (ON_BEHALF_OF_COMPANY_SID NUMBER(10, 0));

CREATE TABLE CHAIN.INTIVE_ON_BEHALF_OF(
    APP_SID                         NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COMPANY_TYPE_ID                 NUMBER(10, 0)    NOT NULL,
    ON_BEHALF_OF_COMPANY_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    CAN_INVITE_COMPANY_TYPE_ID      NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_INTIVE_ON_BEHALF_OF PRIMARY KEY (APP_SID, COMPANY_TYPE_ID, ON_BEHALF_OF_COMPANY_TYPE_ID, CAN_INVITE_COMPANY_TYPE_ID)
)
;

ALTER TABLE CHAIN.INTIVE_ON_BEHALF_OF ADD CONSTRAINT FK_INVITE_OBO_CTR_CTOBOCT 
    FOREIGN KEY (APP_SID, COMPANY_TYPE_ID, ON_BEHALF_OF_COMPANY_TYPE_ID)
    REFERENCES CHAIN.COMPANY_TYPE_RELATIONSHIP(APP_SID, COMPANY_TYPE_ID, RELATED_COMPANY_TYPE_ID)
;

ALTER TABLE CHAIN.INTIVE_ON_BEHALF_OF ADD CONSTRAINT FK_INVITE_OBO_CTR_OBOCTCICT 
    FOREIGN KEY (APP_SID, ON_BEHALF_OF_COMPANY_TYPE_ID, CAN_INVITE_COMPANY_TYPE_ID)
    REFERENCES CHAIN.COMPANY_TYPE_RELATIONSHIP(APP_SID, COMPANY_TYPE_ID, RELATED_COMPANY_TYPE_ID)
;

ALTER TABLE CHAIN.INVITATION ADD CONSTRAINT FK_INVITATION_COMPANY_OBO 
    FOREIGN KEY (APP_SID, ON_BEHALF_OF_COMPANY_SID)
    REFERENCES CHAIN.COMPANY(APP_SID, COMPANY_SID)
;

BEGIN
	FOR r IN (
		SELECT object_name, policy_name 
		  FROM all_policies 
		 WHERE function IN ('APPSIDCHECK', 'NULLABLEAPPSIDCHECK')
		   AND object_owner = 'CHAIN'
		   AND object_name = 'CAPABILITY'
	) LOOP
		dbms_rls.drop_policy(
            object_schema   => 'CHAIN',
            object_name     => r.object_name,
            policy_name     => r.policy_name
        );
    END LOOP;
END;
/


BEGIN
	INSERT INTO chain.capability 
	(capability_id, capability_name, capability_type_id, perm_type, is_supplier) 
	VALUES 
	(chain.capability_id_seq.NEXTVAL, 'Send company invitation', 0, 1, 1);
	
	INSERT INTO chain.capability 
	(capability_id, capability_name, capability_type_id, perm_type, is_supplier) 
	VALUES 
	(chain.capability_id_seq.NEXTVAL, 'Send invitation on behalf of', 0, 1, 1);
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
		'INTIVE_ON_BEHALF_OF'
	);
	for i in 1 .. v_list.count loop
		declare
			v_name varchar2(30);
			v_i pls_integer default 1;
		begin
			loop
				begin
					if v_i = 1 then
						v_name := SUBSTR(v_list(i), 1, 26)||'_POL';
					else
						v_name := SUBSTR(v_list(i), 1, 24)||'_POL_'||v_i;
					end if;
				    dbms_rls.add_policy(
				        object_schema   => 'CHAIN',
				        object_name     => v_list(i),
				        policy_name     => v_name,
				        function_schema => 'CHAIN',
				        policy_function => 'appSidCheck',
				        statement_types => 'select, insert, update, delete',
				        update_check	=> true,
				        policy_type     => dbms_rls.static );
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

@..\chain\chain_pkg

@update_tail
