define version=26
@update_header

PROMPT >> Dropping contraints that will change

-- drop fk's that are changing
ALTER TABLE CARD_GROUP_CARD DROP CONSTRAINT RefCAPABILITY293 ;
ALTER TABLE GROUP_CAPABILITY DROP CONSTRAINT RefCAPABILITY281;

-- Drop the capability pk
ALTER TABLE CAPABILITY DROP CONSTRAINT PK125;

-- on a clean build we need to drop the contraint, but it looks like we need to drop an index on old builds (according to betha)
BEGIN
	BEGIN
		execute immediate 'ALTER TABLE GROUP_CAPABILITY DROP CONSTRAINT UNIQUE_GROUP_CAPABILITY';
	EXCEPTION
		WHEN OTHERS THEN
			NULL;
	END;
	
	BEGIN
		execute immediate 'DROP INDEX UNIQUE_GROUP_CAPABILITY';
	EXCEPTION
		WHEN OTHERS THEN
			NULL;
	END;
END;
/

ALTER TABLE APPLIED_COMPANY_CAPABILITY DROP CONSTRAINT PK120;



PROMPT >> Creating the capability sequence
-- create the capability id seq
CREATE SEQUENCE CAPABILITY_ID_SEQ
    START WITH 1000 -- start this at 1000 so that we can put our "container" capabilities at lower numbers
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

PROMPT >> Adding new columns to capability tables
-- rename the current capability_name column and make it nullable
ALTER TABLE CAPABILITY RENAME COLUMN capability_name TO old_capability_name;
ALTER TABLE CAPABILITY MODIFY (old_capability_name NULL);

-- fix up the default value
ALTER TABLE CAPABILITY MODIFY (APP_SID DEFAULT SYS_CONTEXT('SECURITY', 'APP'));

-- add our new capability columns
ALTER TABLE CAPABILITY ADD (
    CAPABILITY_ID         NUMBER(10, 0), -- to be made not null (pk)
    CAPABILITY_NAME       VARCHAR2(100), -- to be made not null
    CAPABILITY_TYPE_ID    NUMBER(10, 0)  -- to be made not null
);

ALTER TABLE CARD_GROUP_CARD ADD (
	REQUIRED_CAPABILITY_ID      NUMBER(10, 0)
);

ALTER TABLE GROUP_CAPABILITY ADD (
	CAPABILITY_ID          NUMBER(10, 0)    -- to be made not null
);

ALTER TABLE GROUP_CAPABILITY MODIFY (
	CAPABILITY_NAME          NULL
);

ALTER TABLE APPLIED_COMPANY_CAPABILITY ADD (
	PERMISSION_SET         NUMBER(10, 0)    NOT NULL
);

ALTER TABLE CUSTOMER_OPTIONS ADD (
	TOP_COMPANY_SID         NUMBER(10, 0)
);

ALTER TABLE SUPPLIER_RELATIONSHIP ADD (
	VIRTUALLY_ACTIVE_UNTIL_DTM    TIMESTAMP(6)
);

PROMPT >> Creating new capability tables

CREATE TABLE CAPABILITY_TYPE(
    CAPABILITY_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    DESCRIPTION           VARCHAR2(100)    NOT NULL,
    CONTAINER             VARCHAR2(100),
    CONSTRAINT PK169 PRIMARY KEY (CAPABILITY_TYPE_ID)
)
;

PROMPT >> Fixing up the capability table data
-- fix up the capability table data
DECLARE
	v_id		number(10);
BEGIN
	insert into capability_type
	(capability_type_id, description, container)
	values 
	(0, 'Common checks that are not specifically for a company or a supplier', null);
	
	insert into capability_type
	(capability_type_id, description, container)
	values 
	(1, 'Company specific capabilities', 'Company');
	
	insert into capability_type
	(capability_type_id, description, container)
	values 
	(2, 'Supplier specific capabilities', 'Suppliers');
	
	/***********************************************/
	-- define our "root" capability containers
	insert into capability (capability_id, capability_name, capability_type_id, perm_type) values (1, 'Company', 0, 0);
	
	update capability set capability_name = 'Suppliers', capability_type_id=0, capability_id=2 
	where old_capability_name = 'Suppliers';
	/***********************************************/
	
	
	/***********************************************/
	-- clean up duplicate purpose capabilities by using the same id and then deleting the dups later
	select capability_id_seq.nextval
	  into v_id from dual;
	
	insert into capability (capability_id, capability_name, capability_type_id, perm_type) values (v_id, 'Is top company', 0, 1);
		
	update capability set capability_name = 'TO BE REMOVED', capability_type_id=0, capability_id=v_id 
	where old_capability_name = 'Is RFA company user';
	
	update capability set capability_name = 'TO BE REMOVED', capability_type_id=0, capability_id=v_id
	where old_capability_name = 'Is Maersk company user';
	/***********************************************/
	
	/***********************************************/
	-- clean up unused capabilities
	update capability set capability_name = 'TO BE REMOVED', capability_type_id=0, capability_id=capability_id_seq.nextval 
	where old_capability_name = 'Edit on-boarding data';
	/***********************************************/
	
	/***********************************************/
	-- define our common capabilities
	update capability set capability_name = 'Send questionnaire invitation', capability_type_id=0, capability_id=capability_id_seq.nextval 
	where old_capability_name = 'Send questionnaire invitations';
	
	update capability set capability_name = 'Send newsflash', capability_type_id=0, capability_id=capability_id_seq.nextval 
	where old_capability_name = 'Send newsflashes';
	
	update capability set capability_name = 'Receive user-targeted newsflash', capability_type_id=0, capability_id=capability_id_seq.nextval 
	where old_capability_name = 'Receive user-targeted newflashes';
	/***********************************************/
	
	
	/***********************************************/
	-- define company and supplier level capabilities
	update capability set capability_name = 'Specify user name', capability_type_id=1, capability_id=capability_id_seq.nextval 
	where old_capability_name = 'Specify user names';
	
	insert into capability (capability_id, capability_name, capability_type_id, perm_type) values (capability_id_seq.nextval, 'Specify user name', 2, 1);
	
	update capability set capability_name = 'Questionnaire', capability_type_id=1, capability_id=capability_id_seq.nextval 
	where old_capability_name = 'Company questionnaire';
	
	insert into capability (capability_id, capability_name, capability_type_id, perm_type) values (capability_id_seq.nextval, 'Questionnaire', 2, 0);
	
	update capability set capability_name = 'Submit questionnaire', capability_type_id=1, capability_id=capability_id_seq.nextval 
	where old_capability_name = 'Submit questionnaires';
	
	insert into capability (capability_id, capability_name, capability_type_id, perm_type) values (capability_id_seq.nextval, 'Submit questionnaire', 2, 1);
	
	update capability set capability_name = 'Setup stub registration', capability_type_id=1, capability_id=capability_id_seq.nextval 
	where old_capability_name = 'Setup email stub registrations';
	
	insert into capability (capability_id, capability_name, capability_type_id, perm_type) values (capability_id_seq.nextval, 'Setup stub registration', 2, 1);
	
	update capability set capability_name = 'Reset password', capability_type_id=1, capability_id=capability_id_seq.nextval 
	where old_capability_name = 'Reset company passwords';
	
	update capability set capability_name = 'Reset password', capability_type_id=2, capability_id=capability_id_seq.nextval 
	where old_capability_name = 'Reset supplier passwords';
	
	update capability set capability_name = 'Create user', capability_type_id=1, capability_id=capability_id_seq.nextval 
	where old_capability_name = 'Create company users';
	
	insert into capability (capability_id, capability_name, capability_type_id, perm_type) values (capability_id_seq.nextval, 'Create user', 2, 1);
	/***********************************************/
END;
/

commit;

PROMPT >> Updating fk references
BEGIN
	UPDATE group_capability gc
	   SET gc.capability_id = (
	   		SELECT c.capability_id
	   		  FROM capability c
	   		 WHERE c.old_capability_name = gc.capability_name
	   	  );

	UPDATE card_group_card cgc
	   SET cgc.required_capability_id = (
	   		SELECT c.capability_id
	   		  FROM capability c
	   		 WHERE c.old_capability_name = cgc.required_capability
	   	  );
END;
/

commit;

/* -- hmm it turns out that nothing is using the capability in the end, so we'll just kill it
PROMPT >> Fixing up Maersk only capabilities that are globally available
-- 'Edit on-boarding data' should only exist in Maersk setups (booo)
DECLARE
	v_cap_id				number(10);
		
	v_new_cap_id			number(10);
	v_new_group_cap_id		number(10);
BEGIN
	-- get our existing ids
	SELECT capability_id
	  INTO v_cap_id
	  FROM capability
 	 WHERE capability_name = 'Edit on-boarding data' AND app_sid IS NULL;
 	
 	
	
	FOR co IN (
		SELECT * 
		  FROM customer_options
		 WHERE chain_implementation = 'MAERSK'
	) LOOP		
		SELECT capability_id_seq.nextval 
		  INTO v_new_cap_id FROM DUAL;
		
		INSERT INTO capability
		(app_sid, capability_id, capability_name, capability_type_id, perm_type, old_capability_name)
		SELECT co.app_sid, v_new_cap_id, capability_name, capability_type_id, perm_type, old_capability_name
		  FROM capability
		 WHERE capability_id = v_cap_id;
		
		FOR gc IN (
			SELECT *
			  FROM group_capability
			 WHERE capability_id = v_cap_id
		) LOOP

			INSERT INTO group_capability
			(group_capability_id, company_group_name, capability_id)
			VALUES
			(group_capability_id_seq.nextval, gc.company_group_name, v_new_cap_id)
			RETURNING group_capability_id INTO v_new_group_cap_id;
			
			INSERT INTO group_capability_perm
			(group_capability_id, permission_set)
			SELECT v_new_group_cap_id, permission_set
			  FROM group_capability_perm
			 WHERE group_capability_id = gc.group_capability_id;
			
			INSERT INTO group_capability_override
			(app_sid, group_capability_id, hide_group_capability, permission_set_override)
			SELECT app_sid, v_new_group_cap_id, hide_group_capability, permission_set_override
			  FROM group_capability_override
			 WHERE app_sid = co.app_sid
			   AND group_capability_id = gc.group_capability_id;
		
			INSERT INTO applied_company_capability
			(app_sid, company_sid, group_capability_id)
			SELECT app_sid, company_sid, v_new_group_cap_id
			  FROM applied_company_capability
			 WHERE app_sid = co.app_sid
			   AND group_capability_id = gc.group_capability_id;
		
		END LOOP;
		
		UPDATE card_group_card
		   SET required_capability_id = v_new_cap_id
		 WHERE required_capability_id = v_cap_id
		   AND app_sid = co.app_sid;
	
	END LOOP;
	
	DELETE FROM applied_company_capability
	 WHERE group_capability_id IN (
			SELECT group_capability_id
			  FROM group_capability
			 WHERE capability_id = v_cap_id
			);

	DELETE FROM group_capability_override
	 WHERE group_capability_id IN (
			SELECT group_capability_id
			  FROM group_capability
			 WHERE capability_id = v_cap_id
		);

	DELETE FROM group_capability_perm
	 WHERE group_capability_id IN (
			SELECT group_capability_id
			  FROM group_capability
			 WHERE capability_id = v_cap_id
		);

	DELETE FROM group_capability
	 WHERE capability_id = v_cap_id;
	
	DELETE FROM capability WHERE capability_id = v_cap_id;
END;
/
commit;
*/

PROMPT >> Indexing chain applications

CREATE TABLE TEMP_HOST (
    APP_SID					NUMBER(10) NOT NULL,
    HOST					VARCHAR2(1000) NOT NULL,
    CHAIN_IMPLEMENTATION	VARCHAR2(1000)
)
;

BEGIN
	-- just doing this to be sure that rls doesn't mess with the cursor while we're logging on and off
	-- probably overkill, but better safe than sorry!
	INSERT INTO temp_host
	(app_sid, host, chain_implementation)
	SELECT cu.app_sid, cu.host, co.chain_implementation
	  FROM csr.customer cu, customer_options co
	 WHERE co.app_sid = cu.app_sid;
END;
/

commit;

PROMPT >> Re-jigging capability SOs, re-appling permissions
DECLARE
	v_app_sid					security_pkg.T_SID_ID;
	v_act_id					security_pkg.T_ACT_ID;
	v_chain_sid					security_pkg.T_SID_ID;
	
	v_dacl_id    				security_Pkg.T_ACL_ID;
	
	v_chain_admins				security_pkg.T_SID_ID;
	v_chain_users	 			security_pkg.T_SID_ID;
	v_everyone_sid	 			security_pkg.T_SID_ID;
	v_company_admins			security_pkg.T_SID_ID;
	v_company_users				security_pkg.T_SID_ID;
	v_company_pending_users		security_pkg.T_SID_ID;
	
	v_companies_sid				security_pkg.T_SID_ID;
	v_capabilities_sid			security_pkg.T_SID_ID;
	v_company_cap_sid			security_pkg.T_SID_ID;
	v_supplier_cap_sid			security_pkg.T_SID_ID;
	v_parent_cap_sid			security_pkg.T_SID_ID;
	v_cap_sid					security_pkg.T_SID_ID;	
BEGIN

	FOR r IN (
		SELECT *
		  FROM temp_host
	) LOOP
		user_pkg.logonadmin(r.host);
		v_app_sid := security_pkg.GetApp;
		v_act_id := security_pkg.GetAct;
		
		v_chain_admins := securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups/Chain Administrators');
		v_chain_users := securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups/Chain Users');
		
		v_everyone_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups/Everyone');
		
		
		/********************************/
		/*** Chain Builtin Container ***/
		
		security.ACL_Pkg.GetNewID(v_dacl_id);
		acl_pkg.SetDACL(v_act_id, securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Chain/BuiltIn'), v_dacl_id);
		
		/********************************/
		/*** Chain Companies Container ***/
		v_companies_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Chain/Companies');
		security.ACL_Pkg.GetNewID(v_dacl_id);
		acl_pkg.SetDACL(v_act_id, v_companies_sid, v_dacl_id);
		
		/*****************************/
		/*** Invitation Responden ***/
		security.ACL_Pkg.GetNewID(v_dacl_id);
		acl_pkg.SetDACL(v_act_id, securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Chain/BuiltIn/Invitation Respondent'), v_dacl_id);
		
		/************************/
		/*** Chain Container ***/
		v_chain_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Chain');

		securableobject_pkg.SetFlags(v_act_id, v_chain_sid, 0);
		
		security.ACL_Pkg.GetNewID(v_dacl_id);

		acl_pkg.AddACE(v_act_id, v_dacl_id, security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
			security_pkg.ACE_FLAG_DEFAULT, v_everyone_sid, security_pkg.PERMISSION_STANDARD_READ + security_pkg.PERMISSION_ADD_CONTENTS);	
			
		acl_pkg.SetDACL(v_act_id, v_chain_sid, v_dacl_id);
		
		FOR co IN (
			SELECT company_sid
			  FROM company
			 WHERE app_sid = v_app_sid
		) LOOP
			
			/*********************************/
			/*** COMPANY Securable Object ***/
			securableobject_pkg.SetFlags(v_act_id, co.company_sid, security_pkg.SOFLAG_INHERIT_DACL);
			security.ACL_Pkg.GetNewID(v_dacl_id);
			acl_pkg.SetDACL(v_act_id, co.company_sid, v_dacl_id);			

			acl_pkg.AddACE(v_act_id, v_dacl_id, security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
				0, v_chain_admins, security_pkg.PERMISSION_WRITE);	
				
			acl_pkg.AddACE(v_act_id, v_dacl_id, security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
				0, v_chain_users, security_pkg.PERMISSION_WRITE);	
			
			-- it doesn't seem to want to propigate this in the same transaction, so we'll force it
			acl_pkg.PassACEsToChild(v_companies_sid, co.company_sid);
		
			/*************************************/
			/*** COMPANY Administrators Group ***/
			v_company_admins := securableobject_pkg.GetSIDFromPath(v_act_id, co.company_sid, 'Administrators');
			acl_pkg.SetDACL(v_act_id, v_company_admins, v_dacl_id);
			
			/****************************/
			/*** COMPANY Users Group ***/
			v_company_users := securableobject_pkg.GetSIDFromPath(v_act_id, co.company_sid, 'Users');
			acl_pkg.SetDACL(v_act_id, v_company_users, v_dacl_id);
			
			/************************************/
			/*** COMPANY Pending Users Group ***/
			v_company_pending_users := securableobject_pkg.GetSIDFromPath(v_act_id, co.company_sid, 'Pending Users');
			acl_pkg.SetDACL(v_act_id, v_company_pending_users, v_dacl_id);

			/***************************************/
			/*** COMPANY Capabilities Container ***/
			v_capabilities_sid := securableobject_pkg.GetSIDFromPath(v_act_id, co.company_sid, 'Capabilities');
			securableobject_pkg.SetFlags(v_act_id, v_capabilities_sid, 0);
			
			security.ACL_Pkg.GetNewID(v_dacl_id);

			acl_pkg.AddACE(v_act_id, v_dacl_id, security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
				0, v_everyone_sid, security_pkg.PERMISSION_STANDARD_READ + security_pkg.PERMISSION_ADD_CONTENTS);	

			acl_pkg.SetDACL(v_act_id, v_capabilities_sid, v_dacl_id);
			/***********************/
						
			v_supplier_cap_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_capabilities_sid, 'Suppliers');									
			securableobject_pkg.CreateSO(v_act_id, v_capabilities_sid, security_pkg.SO_CONTAINER, 'Company', v_company_cap_sid);
			
			FOR cap IN (
				SELECT *
				  FROM capability
				 WHERE capability_id >= 1000
				   AND NVL(app_sid, v_app_sid) = v_app_sid
				   AND capability_name NOT LIKE 'TO BE REMOVED%'
			) LOOP
				
				CASE
					WHEN cap.capability_type_id = 0 THEN -- common capabilities
						v_parent_cap_sid := v_capabilities_sid;
					WHEN cap.capability_type_id = 1 THEN -- company capability
						v_parent_cap_sid := v_company_cap_sid;
					WHEN cap.capability_type_id = 2 THEN -- supplier capability
						v_parent_cap_sid := v_supplier_cap_sid;
				END CASE;
				
				v_cap_sid := NULL;
				
				IF cap.old_capability_name IS NOT NULL THEN
					BEGIN
						v_cap_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_capabilities_sid, cap.old_capability_name);

						-- if we've succeeded (i.e. it already exists), we can move and rename
						IF v_parent_cap_sid <> v_capabilities_sid THEN
							securableobject_pkg.MoveSO(v_act_id, v_cap_sid, v_parent_cap_sid);
						END IF;

						securableobject_pkg.RenameSO(v_act_id, v_cap_sid, cap.capability_name);
					EXCEPTION 
						WHEN security_pkg.OBJECT_NOT_FOUND THEN
							NULL;
					END;
				END IF;
				
				IF v_cap_sid IS NULL THEN
					securableobject_pkg.CreateSO(v_act_id, v_parent_cap_sid, security_pkg.SO_CONTAINER, cap.capability_name, v_cap_sid);
				END IF;
			END LOOP;			
		END LOOP;
	END LOOP;
END;
/

commit;

PROMPT >> Removing redundant capabilities
DECLARE
	v_capabilities_sid			security_pkg.T_SID_ID;
	v_cap_sid					security_pkg.T_SID_ID;
	v_app_sid					security_pkg.T_SID_ID;
	v_act_id					security_pkg.T_ACT_ID;
BEGIN

	FOR r IN (
		SELECT *
		  FROM temp_host
	) LOOP
		user_pkg.logonadmin(r.host);
		v_app_sid := security_pkg.GetApp;
		v_act_id := security_pkg.GetAct;
		
		FOR co IN (
			SELECT company_sid
			  FROM company
			 WHERE app_sid = v_app_sid
		) LOOP
			v_capabilities_sid := securableobject_pkg.GetSIDFromPath(v_act_id, co.company_sid, 'Capabilities');
			
			FOR cap IN (
				SELECT *
				  FROM capability
				 WHERE capability_id >= 1000
				   AND NVL(app_sid, v_app_sid) = v_app_sid
				   AND capability_name LIKE 'TO BE REMOVED%'
			) LOOP
				BEGIN
					v_cap_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_capabilities_sid, cap.old_capability_name);
				EXCEPTION 
					WHEN security_pkg.OBJECT_NOT_FOUND THEN
						v_cap_sid := NULL;
				END;
				
				IF v_cap_sid IS NOT NULL THEN
					securableobject_pkg.DeleteSO(v_act_id, v_cap_sid);
				END IF;
			END LOOP;
		END LOOP;
		user_pkg.Logoff(security_pkg.GetAct);
	END LOOP;
	
	DELETE FROM capability WHERE capability_name LIKE 'TO BE REMOVED%';
END;
/

commit;

PROMPT >> Applying not nullable column contraints

ALTER TABLE GROUP_CAPABILITY MODIFY (
	CAPABILITY_ID          NOT NULL
);


ALTER TABLE CAPABILITY MODIFY (
    CAPABILITY_ID         NOT NULL,
    CAPABILITY_NAME       NOT NULL,
    CAPABILITY_TYPE_ID    NOT NULL
);

PROMPT >> Re-applying contraints
-- primary key
ALTER TABLE CAPABILITY ADD CONSTRAINT PK125 PRIMARY KEY (CAPABILITY_ID);

ALTER TABLE APPLIED_COMPANY_CAPABILITY ADD CONSTRAINT PK120 PRIMARY KEY (APP_SID, COMPANY_SID, GROUP_CAPABILITY_ID, PERMISSION_SET);

-- unique key
CREATE UNIQUE INDEX UK_CAP_NAME_TYPE ON CAPABILITY(CAPABILITY_TYPE_ID, CAPABILITY_NAME, APP_SID);
CREATE UNIQUE INDEX UNIQUE_GROUP_CAPABILITY ON GROUP_CAPABILITY(COMPANY_GROUP_NAME, CAPABILITY_ID);

-- foreign keys
ALTER TABLE CAPABILITY ADD CONSTRAINT RefCAPABILITY_TYPE380 
    FOREIGN KEY (CAPABILITY_TYPE_ID)
    REFERENCES CAPABILITY_TYPE(CAPABILITY_TYPE_ID)
;

ALTER TABLE CARD_GROUP_CARD ADD CONSTRAINT RefCAPABILITY293 
    FOREIGN KEY (REQUIRED_CAPABILITY_ID)
    REFERENCES CAPABILITY(CAPABILITY_ID)
;

ALTER TABLE GROUP_CAPABILITY ADD CONSTRAINT RefCAPABILITY281 
    FOREIGN KEY (CAPABILITY_ID)
    REFERENCES CAPABILITY(CAPABILITY_ID)
;


PROMPT >> Dropping unused security functions
DROP FUNCTION IsAdmin;
DROP PROCEDURE CheckCompanyPermission;
DROP PROCEDURE CompanyReadCheck;
DROP PROCEDURE CompanyWriteCheck;

DROP PACKAGE example_answers_pkg;

CONNECT security/security@&_CONNECT_IDENTIFIER;
grant all on group_members to chain;

CONNECT chain/chain@&_CONNECT_IDENTIFIER;

PROMPT >> Recompiling views
@..\create_views

PROMPT Compiling chain_pkg
@..\chain_pkg
PROMPT Compiling card_pkg
@..\card_pkg
PROMPT Compiling company_pkg
@..\company_pkg
PROMPT Compiling company_user_pkg
@..\company_user_pkg
PROMPT Compiling invitation_pkg
@..\invitation_pkg
PROMPT Compiling dev_pkg
@..\dev_pkg
PROMPT Compiling action_pkg
@..\action_pkg
PROMPT Compiling event_pkg
@..\event_pkg
PROMPT Compiling task_pkg
@..\task_pkg
PROMPT Compiling questionnaire_pkg
@..\questionnaire_pkg
PROMPT Compiling dashboard_pkg
@..\dashboard_pkg
PROMPT Compiling metric_pkg
@..\metric_pkg
PROMPT Compiling capability_pkg
@..\capability_pkg
PROMPT Compiling newsflash_pkg
@..\newsflash_pkg
PROMPT Compiling scheduled_alert_pkg
@..\scheduled_alert_pkg
PROMPT Compiling chain_link_pkg
@..\chain_link_pkg

PROMPT Compiling chain_body
@..\chain_body
PROMPT Compiling card_body
@..\card_body
PROMPT Compiling company_body
@..\company_body
PROMPT Compiling company_user_body
@..\company_user_body
PROMPT Compiling invitation_body
@..\invitation_body
PROMPT Compiling dev_body
@..\dev_body
PROMPT Compiling action_body
@..\action_body
PROMPT Compiling event_body
@..\event_body
PROMPT Compiling task_body
@..\task_body
PROMPT Compiling questionnaire_body
@..\questionnaire_body
PROMPT Compiling dashboard_body
@..\dashboard_body
PROMPT Compiling metric_body
@..\metric_body
PROMPT Compiling capability_body
@..\capability_body
PROMPT Compiling newsflash_body
@..\newsflash_body
PROMPT Compiling scheduled_alert_body
@..\scheduled_alert_body
PROMPT Compiling chain_link_body
@..\chain_link_body

PROMPT >> Applying grants
@..\grants



PROMPT >> Adding grants for new capabilities,
BEGIN
	user_pkg.logonadmin;
	
	capability_pkg.RegisterCapability(chain_pkg.CT_COMMON, chain_pkg.APPROVE_QUESTIONNAIRE, chain_pkg.BOOLEAN_PERMISSION);
	capability_pkg.GrantCapability(chain_pkg.APPROVE_QUESTIONNAIRE, chain_pkg.ADMIN_GROUP);
	capability_pkg.GrantCapability(chain_pkg.APPROVE_QUESTIONNAIRE, chain_pkg.USER_GROUP);
	
	capability_pkg.RegisterCapability(chain_pkg.CT_COMPANIES, chain_pkg.EVENTS, chain_pkg.SPECIFIC_PERMISSION);
	capability_pkg.GrantCapability(chain_pkg.CT_COMPANY, chain_pkg.EVENTS, chain_pkg.ADMIN_GROUP, security_pkg.PERMISSION_READ + security_pkg.PERMISSION_WRITE);
	capability_pkg.GrantCapability(chain_pkg.CT_COMPANY, chain_pkg.EVENTS, chain_pkg.USER_GROUP, security_pkg.PERMISSION_READ + security_pkg.PERMISSION_WRITE);
	capability_pkg.GrantCapability(chain_pkg.CT_SUPPLIERS, chain_pkg.EVENTS, chain_pkg.ADMIN_GROUP, security_pkg.PERMISSION_WRITE);
	capability_pkg.GrantCapability(chain_pkg.CT_SUPPLIERS, chain_pkg.EVENTS, chain_pkg.USER_GROUP, security_pkg.PERMISSION_WRITE);
	
	capability_pkg.RegisterCapability(chain_pkg.CT_COMPANIES, chain_pkg.ACTIONS, chain_pkg.SPECIFIC_PERMISSION);
	capability_pkg.GrantCapability(chain_pkg.CT_COMPANY, chain_pkg.ACTIONS, chain_pkg.ADMIN_GROUP, security_pkg.PERMISSION_READ + security_pkg.PERMISSION_WRITE);
	capability_pkg.GrantCapability(chain_pkg.CT_COMPANY, chain_pkg.ACTIONS, chain_pkg.USER_GROUP, security_pkg.PERMISSION_READ + security_pkg.PERMISSION_WRITE);
	capability_pkg.GrantCapability(chain_pkg.CT_SUPPLIERS, chain_pkg.ACTIONS, chain_pkg.ADMIN_GROUP, security_pkg.PERMISSION_WRITE);
	capability_pkg.GrantCapability(chain_pkg.CT_SUPPLIERS, chain_pkg.ACTIONS, chain_pkg.USER_GROUP, security_pkg.PERMISSION_WRITE);
	
	capability_pkg.RegisterCapability(chain_pkg.CT_COMPANIES, chain_pkg.TASKS, chain_pkg.SPECIFIC_PERMISSION);
	capability_pkg.GrantCapability(chain_pkg.CT_COMPANY, chain_pkg.TASKS, chain_pkg.ADMIN_GROUP, security_pkg.PERMISSION_READ + security_pkg.PERMISSION_WRITE);
	capability_pkg.GrantCapability(chain_pkg.CT_COMPANY, chain_pkg.TASKS, chain_pkg.USER_GROUP, security_pkg.PERMISSION_READ + security_pkg.PERMISSION_WRITE);
	capability_pkg.GrantCapability(chain_pkg.CT_SUPPLIERS, chain_pkg.TASKS, chain_pkg.ADMIN_GROUP, security_pkg.PERMISSION_WRITE);
	capability_pkg.GrantCapability(chain_pkg.CT_SUPPLIERS, chain_pkg.TASKS, chain_pkg.USER_GROUP, security_pkg.PERMISSION_WRITE);

	capability_pkg.RegisterCapability(chain_pkg.CT_COMPANIES, chain_pkg.METRICS, chain_pkg.SPECIFIC_PERMISSION);
	capability_pkg.GrantCapability(chain_pkg.CT_COMPANY, chain_pkg.METRICS, chain_pkg.ADMIN_GROUP, security_pkg.PERMISSION_READ + security_pkg.PERMISSION_WRITE);
	capability_pkg.GrantCapability(chain_pkg.CT_COMPANY, chain_pkg.METRICS, chain_pkg.USER_GROUP, security_pkg.PERMISSION_READ + security_pkg.PERMISSION_WRITE);
	capability_pkg.GrantCapability(chain_pkg.CT_SUPPLIERS, chain_pkg.METRICS, chain_pkg.ADMIN_GROUP, security_pkg.PERMISSION_WRITE);
	capability_pkg.GrantCapability(chain_pkg.CT_SUPPLIERS, chain_pkg.METRICS, chain_pkg.USER_GROUP, security_pkg.PERMISSION_WRITE);
	
	capability_pkg.GrantCapability(chain_pkg.COMPANY, chain_pkg.ADMIN_GROUP, security_pkg.PERMISSION_READ + security_pkg.PERMISSION_WRITE);
	capability_pkg.GrantCapability(chain_pkg.COMPANY, chain_pkg.USER_GROUP, security_pkg.PERMISSION_READ);
	capability_pkg.GrantCapability(chain_pkg.COMPANY, chain_pkg.PENDING_GROUP, security_pkg.PERMISSION_READ);
	
	capability_pkg.GrantCapability(chain_pkg.CT_SUPPLIERS, chain_pkg.QUESTIONNAIRE, chain_pkg.ADMIN_GROUP, security_pkg.PERMISSION_READ);
	capability_pkg.GrantCapability(chain_pkg.CT_SUPPLIERS, chain_pkg.QUESTIONNAIRE, chain_pkg.USER_GROUP, security_pkg.PERMISSION_READ);
	
	capability_pkg.RegisterCapability(chain_pkg.CT_COMPANIES, chain_pkg.PROMOTE_USER, chain_pkg.BOOLEAN_PERMISSION);
	capability_pkg.GrantCapability(chain_pkg.CT_COMPANY, chain_pkg.PROMOTE_USER, chain_pkg.ADMIN_GROUP);
END;
/

commit;

PROMPT >> Refreshing all capabilities
BEGIN
	
	-- refresh all capabilities
	FOR r IN (
		SELECT *
		  FROM temp_host
	) LOOP
		user_pkg.logonadmin(r.host);
		
		FOR cmp IN (
			SELECT company_sid
			  FROM company
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		) LOOP
			capability_pkg.RefreshCompanyCapabilities(cmp.company_sid);
		END LOOP;
		
		user_pkg.Logoff(security_pkg.GetAct);
	END LOOP;
END;
/
commit;

PROMPT >> Applying application specific capability permissions
DECLARE
	v_company_sid				security_pkg.T_SID_ID;
BEGIN
	
	-- apply application specific capabilities
	FOR r IN (
			SELECT *
			  FROM temp_host
			 WHERE chain_implementation = 'MAERSK'
		) LOOP
			user_pkg.logonadmin(r.host);
			
			v_company_sid := NULL;
	
			BEGIN
				SELECT company_sid 
				  INTO v_company_sid
				  FROM company
				 WHERE UPPER(name) = 'MAERSK'
				   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					NULL;
			END;
	
			IF v_company_sid IS NOT NULL THEN
				UPDATE customer_options SET top_company_sid = v_company_sid;
	
				
				capability_pkg.SetCapabilityPermission(v_company_sid, chain_pkg.ADMIN_GROUP, chain_pkg.CT_SUPPLIERS, chain_pkg.EVENTS, security_pkg.PERMISSION_READ);
				capability_pkg.SetCapabilityPermission(v_company_sid, chain_pkg.USER_GROUP, chain_pkg.CT_SUPPLIERS, chain_pkg.EVENTS, security_pkg.PERMISSION_READ);
				
				capability_pkg.SetCapabilityPermission(v_company_sid, chain_pkg.USER_GROUP, chain_pkg.CT_SUPPLIERS, chain_pkg.ACTIONS, security_pkg.PERMISSION_READ);
				capability_pkg.SetCapabilityPermission(v_company_sid, chain_pkg.ADMIN_GROUP, chain_pkg.CT_SUPPLIERS, chain_pkg.ACTIONS, security_pkg.PERMISSION_READ);
				
				capability_pkg.SetCapabilityPermission(v_company_sid, chain_pkg.USER_GROUP, chain_pkg.TASKS, security_pkg.PERMISSION_READ);	
				capability_pkg.SetCapabilityPermission(v_company_sid, chain_pkg.ADMIN_GROUP, chain_pkg.TASKS, security_pkg.PERMISSION_READ);
				
				capability_pkg.SetCapabilityPermission(v_company_sid, chain_pkg.USER_GROUP, chain_pkg.METRICS, security_pkg.PERMISSION_READ);
				capability_pkg.SetCapabilityPermission(v_company_sid, chain_pkg.ADMIN_GROUP, chain_pkg.METRICS, security_pkg.PERMISSION_READ);
				
				capability_pkg.SetCapabilityPermission(v_company_sid, chain_pkg.USER_GROUP, chain_pkg.CT_SUPPLIERS, chain_pkg.QUESTIONNAIRE, security_pkg.PERMISSION_WRITE);
				capability_pkg.SetCapabilityPermission(v_company_sid, chain_pkg.ADMIN_GROUP, chain_pkg.CT_SUPPLIERS, chain_pkg.QUESTIONNAIRE, security_pkg.PERMISSION_WRITE);
				
				capability_pkg.SetCapabilityPermission(v_company_sid, chain_pkg.ADMIN_GROUP, chain_pkg.CT_SUPPLIERS, chain_pkg.PROMOTE_USER);
				capability_pkg.SetCapabilityPermission(v_company_sid, chain_pkg.USER_GROUP, chain_pkg.CT_SUPPLIERS, chain_pkg.PROMOTE_USER);
			END IF;
	
			user_pkg.Logoff(security_pkg.GetAct);
	END LOOP;
END;
/

commit;

PROMPT >> Cleaning duplicate permissions from all capabilities
DECLARE
	v_app_sid					security_pkg.T_SID_ID;
	v_act_id					security_pkg.T_ACT_ID;
	v_cap_sid					security_pkg.T_SID_ID;
	v_dacl_id    				security_Pkg.T_ACL_ID;
	v_new_dacl_id				security_Pkg.T_ACL_ID;
	v_count						NUMBER(10);
	v_acl_index					security_Pkg.T_ACL_INDEX;
BEGIN
	
	-- clean up duplicate permissions (we've probably made a few now as there was a minor error in the capabilities code before)
	FOR r IN (
		SELECT *
		  FROM temp_host
	) LOOP
		user_pkg.logonadmin(r.host);
		v_app_sid := security_pkg.GetApp;
		v_act_id := security_pkg.GetAct;

		FOR cmp IN (
			SELECT company_sid
			  FROM company
			 WHERE app_sid = v_app_sid
		) LOOP
						
			FOR cap IN (
				SELECT CASE WHEN ct.container IS NULL THEN NULL ELSE ct.container || '/' END path, c.capability_name
				  FROM v$capability c, capability_type ct
				 WHERE c.capability_type_id = ct.capability_type_id
				 ORDER BY c.capability_id
			) LOOP
				v_cap_sid := securableobject_pkg.GetSIDFromPath(v_act_id, cmp.company_sid, chain_pkg.CAPABILITIES || '/' || cap.path || cap.capability_name);
				v_dacl_id := acl_pkg.GetDACLIDForSID(v_cap_sid);
			
				SELECT COUNT(*) 
				  INTO v_count
				  FROM (
					SELECT COUNT(*) cnt, acl.ace_type, acl.ace_flags, acl.sid_id, acl.permission_set
					  FROM security.acl
					 WHERE acl_id = v_dacl_id
					 GROUP BY acl.ace_type, acl.ace_flags, acl.sid_id, acl.permission_set
				) WHERE cnt > 1;

				IF v_count > 0 THEN
					security.ACL_Pkg.GetNewID(v_new_dacl_id);
					v_acl_index := 1;
					
					FOR acls IN (
						SELECT * FROM (
							SELECT MIN(acl_index) acl_index, ace_type, ace_flags, sid_id, permission_set
							  FROM security.acl
							 WHERE acl_id = v_dacl_id
							 GROUP BY ace_type, ace_flags, sid_id, permission_set
						      )
						 ORDER BY acl_index
					) LOOP
					
						INSERT INTO security.acl 
						(acl_id, acl_index, ace_type, ace_flags, sid_id, permission_set)
						VALUES 
						(v_new_dacl_id, v_acl_index, acls.ace_type, acls.ace_flags, acls.sid_id, acls.permission_set);
						
						v_acl_index := v_acl_index + 1;
					
					END LOOP;
					 
					acl_pkg.SetDACL(v_act_id, v_cap_sid, v_new_dacl_id);				
				END IF;			
			END LOOP;		
		END LOOP;
		
		user_pkg.Logoff(security_pkg.GetAct);
	END LOOP;
END;
/

commit;

PROMPT >> Dropping temp table and retired columns 
DROP TABLE TEMP_HOST;
ALTER TABLE CAPABILITY DROP (old_capability_name);
ALTER TABLE GROUP_CAPABILITY DROP (capability_name);
ALTER TABLE CARD_GROUP_CARD DROP (required_capability);

PROMPT >> Dropping UNIQUE_NAME and CONFIG columns from CARD Table
BEGIN
	UPDATE card 
	   SET js_class_type = 'Maersk.Cards.LeanBusinessUnit' 
	 WHERE unique_name = 'Maersk.Cards.BusinessUnit.LeanOnboard';
	
	UPDATE card 
	   SET js_class_type = 'Soliver.Cards.LeanBusinessUnit' 
	 WHERE unique_name = 'Soliver.Cards.BusinessUnit.LeanOnboard';
END;
/

ALTER TABLE CARD DROP (CONFIG, UNIQUE_NAME);

@update_tail