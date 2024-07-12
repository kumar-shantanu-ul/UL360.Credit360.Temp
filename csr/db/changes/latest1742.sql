-- Please update version.sql too -- this keeps clean builds in sync
define version=1742
@update_header

CREATE GLOBAL TEMPORARY TABLE CHAIN.TT_CAPABILITY_SID_MAP (
	APP_SID                 NUMBER(10) NOT NULL,
	COMPANY_SID             NUMBER(10) NOT NULL,
	GROUP_SID               NUMBER(10) NOT NULL,
	COMPANY_GROUP_TYPE_ID   NUMBER(10) NOT NULL,
	CAPABILITY_SID          NUMBER(10) NOT NULL,
	CAPABILITY_ID           NUMBER(10) NOT NULL,  
	DACL_ID                 NUMBER(10) NOT NULL,
	CAPABILITY_NAME         VARCHAR2(1000) NOT NULL,
	PERM_TYPE               NUMBER(1) NOT NULL,
	CAPABILITY_TYPE_ID      NUMBER(1) NOT NULL,
	IS_SUPPLIER             NUMBER(1) NOT NULL,
	PERMISSION_SET          NUMBER(10) DEFAULT 0 NOT NULL
) ON COMMIT DELETE ROWS;

/**********************************************************************************
NOTES IF YOU HAVE ERRORS RUNNING THIS SCRIPT:

This script is designed to transition old style chain sites to company types, 
which involves:

- site configuration changes to allow the site to use type_capability checks
- company type creatation
- company type relationships
- type capability configuration **

** This is the one that may cause problems. In order to transition sites to 
capability types, we check the SO capability permissions of two companies -
one representing the TOP company, and one representing a SUPPLIER company.

** This will not process your local site if it doesn't have:
- at least a TOP company and SUPPLIER company
setup, this won't work
- a company sid in chain.customer_options.top_company_sid

You will either need to fulfil this criteria by inviting a supplier and 
rerunnning this script, or by nuking the site or chain portion of the site.

**This will either not run for select sites or fail, if your local site:
- has permissions against company SO capability containers for SIDS which are
not supported by type capabilities (e.g. site administrator)
- contains any DENY type capabilities against company SO capability containers 

In either case, you need to remove these checks, and rerun this script in order to
process the site.

FINALLY:
You can choose to skip over any sites that aren't important to you, by setting
their 'chain.customer_options.use_type_capabililties' flags to 1. This will cause
them to be ignored by this script, but it will also make them unusable.

**********************************************************************************/

DECLARE
	v_act_id					security.security_pkg.T_ACT_ID;
	v_app_sid					security.security_pkg.T_SID_ID;
	v_count						NUMBER(10);
	v_company_ca_group_type_id 	chain.company_group_type.company_group_type_id%TYPE;
	v_ca_permission_set			security.security_pkg.T_PERMISSION DEFAULT 0;
	v_out						VARCHAR2(4000);
BEGIN
	security.user_pkg.logonadmin;
	
 	SELECT company_group_type_id
	  INTO v_company_ca_group_type_id
	  FROM chain.company_group_type
	 WHERE name = 'Chain Administrators';
		
	FOR a IN (
		SELECT c.host 
		  FROM chain.customer_options co, csr.customer c
		 WHERE c.app_sid = co.app_sid 
		   AND co.use_type_capabilities = 0 
		   AND co.top_company_sid IS NOT NULL  -- we can't do this without a top company sid
		   AND co.app_sid IN ( -- make sure that we also have at least one other company
		   		SELECT app_sid 
		   		  FROM (
		   		  		SELECT app_sid, COUNT(*) cnt FROM chain.company WHERE deleted = 0 GROUP BY app_sid
		   		  	)
		   		 WHERE cnt > 1
		   )	
	) LOOP
		security.user_pkg.logonadmin(a.host);
		v_act_id := security.security_pkg.GetAct;
		v_app_sid := security.security_pkg.GetApp;
		
		-- enable csr manage capabilities
		DECLARE
		    v_allow_by_default      csr.capability.allow_by_default%TYPE;
			v_capability_sid		security.security_pkg.T_SID_ID;
			v_capabilities_sid		security.security_pkg.T_SID_ID;
			in_capability  			security.security_pkg.T_SO_NAME := 'Manage chain capabilities';
			in_swallow_dup_exception  NUMBER := 1;
		BEGIN
		    -- this also serves to check that the capability is valid
		    BEGIN
		        SELECT allow_by_default
		          INTO v_allow_by_default
		          FROM csr.capability
		         WHERE LOWER(name) = LOWER(in_capability);
		    EXCEPTION
		        WHEN NO_DATA_FOUND THEN
		            RAISE_APPLICATION_ERROR(-20001, 'Unknown capability "'||in_capability||'"');
			END;
		
		    -- just create a sec obj of the right type in the right place
		    BEGIN
				v_capabilities_sid := security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), '/Capabilities');
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.securableobject_pkg.CreateSO(SYS_CONTEXT('SECURITY','ACT'), 
						SYS_CONTEXT('SECURITY','APP'), 
						security.security_pkg.SO_CONTAINER,
						'Capabilities',
						v_capabilities_sid
					);
			END;
			
			BEGIN
				security.securableobject_pkg.CreateSO(SYS_CONTEXT('SECURITY','ACT'), 
					v_capabilities_sid, 
					security.class_pkg.GetClassId('CSRCapability'),
					in_capability,
					v_capability_sid
				);
			EXCEPTION
				WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
					IF in_swallow_dup_exception = 0 THEN
						RAISE_APPLICATION_ERROR(security.security_pkg.ERR_DUPLICATE_OBJECT_NAME, SQLERRM);
					END IF;
			END;
		END;
	
		-- turn on use_type_capabilities
		UPDATE chain.customer_options 
		   SET use_type_capabilities = 1 
		 WHERE app_sid = v_app_sid;

		-- setup company types
		UPDATE chain.company_type
		   SET lookup_key = 'SUPPLIER',
			   singular = 'Supplier',
			   plural = 'Suppliers',
			   position = 1
		 WHERE app_sid = v_app_sid;
	
		INSERT INTO chain.company_type
		(app_sid, company_type_id, lookup_key, singular, plural, allow_lower_case, is_top_company, position)
		VALUES
		(v_app_sid, chain.company_type_id_seq.nextval, 'TOP', 'Company', 'Companies', 1, 1, 0);
	
		-- update the company type of the top company
		UPDATE chain.company c
		   SET company_type_id = (
				SELECT company_type_id 
				  FROM chain.company_type ct 
				 WHERE ct.app_sid = c.app_sid
				   AND ct.is_top_company = 1
				)
		 WHERE c.company_sid IN (SELECT top_company_sid FROM chain.customer_options WHERE app_sid = v_app_sid);
	
		-- define the company type relationship
		INSERT INTO chain.company_type_relationship
		(app_sid, primary_company_type_id, secondary_company_type_id)
		SELECT p.app_sid, p.company_type_id, s.company_type_id
		  FROM chain.company_type p, chain.company_type s
		 WHERE p.app_sid = v_app_sid
		   AND p.app_sid = s.app_sid
		   AND p.lookup_key = 'TOP'
		   AND s.lookup_key = 'SUPPLIER'
		 MINUS
		SELECT app_sid, primary_company_type_id, secondary_company_type_id
		  FROM chain.company_type_relationship;
	
		-- setup default company capabilities
		INSERT INTO chain.company_type_capability
		(app_sid, primary_company_type_id, primary_company_group_type_id, capability_id, permission_set)
		SELECT ct.app_sid, ct.company_type_id, gc.company_group_type_id, gc.capability_id, gc.permission_set
		  FROM chain.group_capability gc, chain.capability c, chain.company_type ct
		 WHERE ct.app_sid = v_app_sid
		   AND gc.capability_id = c.capability_id
		   AND c.is_supplier = 0
		   AND (ct.app_sid, ct.company_type_id, gc.company_group_type_id, gc.capability_id) NOT IN (
				SELECT app_sid, primary_company_type_id, primary_company_group_type_id, capability_id
				  FROM chain.company_type_capability
	   		);  

		-- setup default supplier capabilities
		INSERT INTO chain.company_type_capability
		(app_sid, primary_company_type_id, secondary_company_type_id, primary_company_group_type_id, capability_id, permission_set)
		SELECT ct.app_sid, ct.company_type_id, ctr.secondary_company_type_id, gc.company_group_type_id, gc.capability_id, gc.permission_set
		  FROM chain.group_capability gc, chain.capability c, chain.company_type_relationship ctr, chain.company_type ct
		 WHERE ct.app_sid = v_app_sid
		   AND ct.app_sid = ctr.app_sid
		   AND ct.company_type_id = ctr.primary_company_type_id
		   AND gc.capability_id = c.capability_id
		   AND c.is_supplier = 1
		   AND c.capability_type_id <> 3 /*chain.chain_pkg.CT_ON_BEHALF_OF*/
		   AND (ct.app_sid, ct.company_type_id, ctr.secondary_company_type_id, gc.company_group_type_id, gc.capability_id) NOT IN (
				SELECT app_sid, primary_company_type_id, secondary_company_type_id, primary_company_group_type_id, capability_id
				  FROM chain.company_type_capability
		   ); 
----------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------
		-- apply differences based on the site configuration

		FOR o IN (
			SELECT top_company_sid company_sid, 'TOP' company_type_key, 'SUPPLIER' supplier_type_key 
			  FROM chain.customer_options
			 WHERE app_sid = v_app_sid
			 UNION
			SELECT MAX(company_sid) company_sid, 'SUPPLIER' company_type_key, NULL supplier_type_key 
			  FROM chain.v$company
	 		 WHERE app_sid = v_app_sid
			   AND company_sid NOT IN (SELECT top_company_sid FROM chain.customer_options WHERE app_sid = v_app_sid) 
		) LOOP

			DELETE FROM chain.tt_capability_sid_map WHERE company_sid = o.company_sid;

			INSERT INTO chain.tt_capability_sid_map
			(app_sid, company_sid, group_sid, company_group_type_id, capability_sid, capability_id, dacl_id, capability_name, perm_type, capability_type_id, is_supplier)
			SELECT cg.app_sid, cg.company_sid, cg.group_sid, cg.company_group_type_id, o.sid_id, c.capability_id, o.dacl_id, c.capability_name, c.perm_type, c.capability_type_id, c.is_supplier
			FROM security.securable_object p, chain.capability c, (
				SELECT cg.app_sid, cg.company_sid, cg.group_sid, cg.company_group_type_id 
				  FROM chain.company_group cg, chain.company_group_type cgt 
				 WHERE cg.company_sid = o.company_sid 
				   AND cgt.is_global = 0 
				   AND cg.company_group_type_id = cgt.company_group_type_id
				) cg, (
				SELECT * FROM security.securable_object
				 start with parent_sid_id = (SELECT sid_id FROM security.securable_object WHERE parent_sid_id = o.company_sid AND name = 'Capabilities')
			   connect by prior sid_id = parent_sid_id
				) o
			WHERE o.parent_sid_id = p.sid_id
			 AND c.capability_name = o.name
			 AND c.is_supplier = NVL(DECODE(p.name, 'Company', 0, 'Suppliers', 1, NULL), c.is_supplier)
			 ORDER BY capability_id, cg.company_sid;

			SELECT COUNT(*)
			  INTO v_count
			  FROM (SELECT UNIQUE dacl_id FROM chain.tt_capability_sid_map) m, security.acl a
			 WHERE m.dacl_id = a.acl_id
			   AND a.sid_id NOT IN (
				SELECT UNIQUE group_sid
				  FROM chain.tt_capability_sid_map
				 UNION
				SELECT security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups/Everyone') FROM dual
				 UNION
				SELECT security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups/Chain Administrators') FROM dual
				 UNION 
				SELECT security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups/Chain Users') FROM dual
			 );

			IF v_count <> 0 THEN
				dbms_output.put_line('FOR company_sid = '||o.company_sid);
				
				FOR z In (
					SELECT *
					  FROM (SELECT UNIQUE dacl_id FROM chain.tt_capability_sid_map) m, security.acl a
					 WHERE m.dacl_id = a.acl_id
					   AND a.sid_id NOT IN (
						SELECT UNIQUE group_sid
						  FROM chain.tt_capability_sid_map
						 UNION
						SELECT security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups/Everyone') FROM dual
						 UNION
						SELECT security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups/Chain Administrators') FROM dual
						 UNION 
						SELECT security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups/Chain Users') FROM dual
					)
				) LOOP
					dbms_output.put_line('SELECT '||z.ACL_ID||' acl_id, '||z.SID_ID||' sid_id FROM DUAL UNION');
				END LOOP;
				
				RAISE_APPLICATION_ERROR(-20001, 'Unexpected sids attached to capability dacls');
			END IF;

			SELECT COUNT(*)
			  INTO v_count
			  FROM (SELECT UNIQUE dacl_id FROM chain.tt_capability_sid_map WHERE company_sid = o.company_sid) m, security.acl a
			 WHERE m.dacl_id = a.acl_id
			   AND a.ace_type <> security.security_pkg.ACE_TYPE_ALLOW;

			IF v_count <> 0 THEN
				RAISE_APPLICATION_ERROR(-20001, 'Cannot transform ace types which are not ALLOW');
			END IF;

			FOR r IN (
				SELECT UNIQUE m.capability_sid, m.group_sid, a.permission_set
				  FROM chain.tt_capability_sid_map m, security.acl a
				 WHERE app_sid = v_app_sid
				   AND company_sid = o.company_sid
				   AND m.dacl_id = a.acl_id
				   AND m.group_sid = a.sid_id
			) LOOP

				UPDATE chain.tt_capability_sid_map
				   SET permission_set = security.bitwise_pkg.bitor(permission_set, r.permission_set)
				 WHERE app_sid = v_app_sid
				   AND company_sid = o.company_sid
				   AND capability_sid = r.capability_sid
				   AND group_sid = r.group_sid;    

			END LOOP;

			DELETE FROM chain.tt_capability_sid_map
			 WHERE company_sid = o.company_sid
			 AND (capability_id, company_group_type_id, permission_set) IN (
			  SELECT capability_id, company_group_type_id, permission_set
				FROM chain.group_capability
			   );

			DELETE FROM chain.tt_capability_sid_map
			 WHERE company_sid = o.company_sid
			 AND permission_set = 0
			 AND (capability_id, company_group_type_id) NOT IN (
			  SELECT capability_id, company_group_type_id
				FROM chain.group_capability
			   );

			FOR r IN (
				SELECT m.*, 'chain.chain_pkg.'||c.capability_constant_name capability_constant_name, cgt.name group_name,
					   'chain.chain_pkg.'||DECODE(cgt.name, 'Administrators', 'ADMIN_GROUP', 'Users', 'USER_GROUP', 'Pending Users', 'PENDING_GROUP') group_name_const,
					   'chain.chain_pkg.'||DECODE(m.capability_type_id, 0, 'CT_COMMON', 1, 'CT_COMPANY', 2, 'CT_SUPPLIERS') capability_type
				  FROM chain.tt_capability_sid_map m, chain.company_group_type cgt, (
						SELECT 'CAPABILITIES' capability_constant_name, 'Capabilities' capability_name FROM DUAL UNION
						SELECT 'COMPANY' capability_constant_name, 'Company' capability_name FROM DUAL UNION
						SELECT 'SUPPLIERS' capability_constant_name, 'Suppliers' capability_name FROM DUAL UNION
						SELECT 'SPECIFY_USER_NAME' capability_constant_name, 'Specify user name' capability_name FROM DUAL UNION
						SELECT 'QUESTIONNAIRE' capability_constant_name, 'Questionnaire' capability_name FROM DUAL UNION
						SELECT 'SUBMIT_QUESTIONNAIRE' capability_constant_name, 'Submit questionnaire' capability_name FROM DUAL UNION
						SELECT 'CREATE_QUESTIONNAIRE_TYPE' capability_constant_name, 'Create questionnaire type' capability_name FROM DUAL UNION
						SELECT 'SETUP_STUB_REGISTRATION' capability_constant_name, 'Setup stub registration' capability_name FROM DUAL UNION
						SELECT 'RESET_PASSWORD' capability_constant_name, 'Reset password' capability_name FROM DUAL UNION
						SELECT 'CREATE_USER' capability_constant_name, 'Create user' capability_name FROM DUAL UNION
						SELECT 'EVENTS' capability_constant_name, 'Events' capability_name FROM DUAL UNION
						SELECT 'ACTIONS' capability_constant_name, 'Actions' capability_name FROM DUAL UNION
						SELECT 'TASKS' capability_constant_name, 'Tasks' capability_name FROM DUAL UNION
						SELECT 'METRICS' capability_constant_name, 'Metrics' capability_name FROM DUAL UNION
						SELECT 'PRODUCTS' capability_constant_name, 'Products' capability_name FROM DUAL UNION
						SELECT 'COMPONENTS' capability_constant_name, 'Components' capability_name FROM DUAL UNION
						SELECT 'PROMOTE_USER' capability_constant_name, 'Promote user' capability_name FROM DUAL UNION
						SELECT 'PRODUCT_CODE_TYPES' capability_constant_name, 'Product code types' capability_name FROM DUAL UNION
						SELECT 'UPLOADED_FILE' capability_constant_name, 'Uploaded file' capability_name FROM DUAL UNION
						SELECT 'CT_HOTSPOTTER' capability_constant_name, 'CT Hotspotter' capability_name FROM DUAL UNION
						SELECT 'IS_TOP_COMPANY' capability_constant_name, 'Is top company' capability_name FROM DUAL UNION
						SELECT 'SEND_QUESTIONNAIRE_INVITE' capability_constant_name, 'Send questionnaire invitation' capability_name FROM DUAL UNION
						SELECT 'SEND_COMPANY_INVITE' capability_constant_name, 'Send company invitation' capability_name FROM DUAL UNION
						SELECT 'SEND_INVITE_ON_BEHALF_OF' capability_constant_name, 'Send invitation on behalf of' capability_name FROM DUAL UNION
						SELECT 'SEND_NEWSFLASH' capability_constant_name, 'Send newsflash' capability_name FROM DUAL UNION
						SELECT 'RECEIVE_USER_TARGETED_NEWS' capability_constant_name, 'Receive user-targeted newsflash' capability_name FROM DUAL UNION
						SELECT 'APPROVE_QUESTIONNAIRE' capability_constant_name, 'Approve questionnaire' capability_name FROM DUAL UNION
						SELECT 'CHANGE_SUPPLIER_FOLLOWER' capability_constant_name, 'Change supplier follower' capability_name FROM DUAL UNION
						SELECT 'CREATE_COMPANY_WITHOUT_INVIT' capability_constant_name, 'Create company without invitation' capability_name FROM DUAL UNION
						SELECT 'CREATE_USER_WITHOUT_INVITE' capability_constant_name, 'Create company user without invitation' capability_name FROM DUAL UNION
						SELECT 'CREATE_USER_WITH_INVITE' capability_constant_name, 'Create company user with invitation' capability_name FROM DUAL UNION
						SELECT 'SEND_QUEST_INV_TO_NEW_COMPANY' capability_constant_name, 'Send questionnaire invitation to new company' capability_name FROM DUAL UNION
						SELECT 'SEND_QUEST_INV_TO_EXIST_COMPAN' capability_constant_name, 'Send questionnaire invitation to existing company' capability_name FROM DUAL UNION
						SELECT 'QNR_INVITE_ON_BEHALF_OF' capability_constant_name, 'Send questionnaire invitations on behalf of' capability_name FROM DUAL
				  ) c
				 WHERE m.company_sid = o.company_sid
				   AND m.company_group_type_id = cgt.company_group_type_id
				   AND m.capability_name = c.capability_name
				 ORDER BY m.capability_id, m.company_group_type_id
			) LOOP
				IF NOT (r.is_supplier = 1 AND o.supplier_type_key IS NULL) THEN

					--BEGIN 
						IF r.is_supplier = 0 THEN
							EXECUTE IMMEDIATE '
									DELETE FROM chain.company_type_capability 
									 WHERE (app_sid, primary_company_type_id, primary_company_group_type_id, capability_id) IN (
										SELECT p.app_sid, p.company_type_id, cgt.company_group_type_id, c.capability_id
										  FROM chain.company_type p, chain.company_group_type cgt, chain.capability c
										 WHERE p.app_sid = SYS_CONTEXT(''SECURITY'', ''APP'')
										   AND p.lookup_key = :company_type_key
										   AND c.capability_name = :capability_name
										   AND cgt.name = :group_name
										)
										'
							USING o.company_type_key, r.capability_name, r.group_name;

							IF r.permission_set > 0 THEN
								EXECUTE IMMEDIATE '
										INSERT INTO chain.company_type_capability
										(app_sid, primary_company_type_id, primary_company_group_type_id, capability_id, secondary_company_type_id, tertiary_company_type_id, permission_set)
										SELECT p.app_sid, p.company_type_id, cgt.company_group_type_id, c.capability_id, NULL, NULL, :permmission_set
										  FROM chain.company_type p, chain.company_group_type cgt, chain.capability c
										 WHERE p.app_sid = SYS_CONTEXT(''SECURITY'', ''APP'')
										   AND p.lookup_key = :company_type_key
										   AND c.capability_name = :capability_name
										   AND cgt.name = :group_name
										 '
								USING r.permission_set, o.company_type_key, r.capability_name, r.group_name;

							END IF;

						ELSE
							EXECUTE IMMEDIATE '
									DELETE FROM chain.company_type_capability 
									 WHERE (app_sid, primary_company_type_id, primary_company_group_type_id, capability_id, secondary_company_type_id) IN (
										SELECT p.app_sid, p.company_type_id, cgt.company_group_type_id, c.capability_id, s.company_type_id
										  FROM chain.company_type p, chain.company_type s, chain.company_group_type cgt, chain.capability c
										 WHERE p.app_sid = SYS_CONTEXT(''SECURITY'', ''APP'')
										   AND p.app_sid = s.app_sid
										   AND p.lookup_key = :company_type_key
										   AND s.lookup_key = :supplier_type_key
										   AND c.capability_name = :capability_name
										   AND cgt.name = :group_name
										)
										'
							USING o.company_type_key, o.supplier_type_key, r.capability_name, r.group_name;

							IF r.permission_set > 0 THEN
								EXECUTE IMMEDIATE '
										INSERT INTO chain.company_type_capability
										(app_sid, primary_company_type_id, primary_company_group_type_id, capability_id, secondary_company_type_id, tertiary_company_type_id, permission_set)
										SELECT p.app_sid, p.company_type_id, cgt.company_group_type_id, c.capability_id, s.company_type_id, NULL, :permmission_set
										  FROM chain.company_type p, chain.company_type s, chain.company_group_type cgt, chain.capability c
										 WHERE p.app_sid = SYS_CONTEXT(''SECURITY'', ''APP'')
										   AND p.app_sid = s.app_sid
										   AND p.lookup_key = :company_type_key
										   AND s.lookup_key = :supplier_type_key
										   AND c.capability_name = :capability_name
										   AND cgt.name = :group_name
										  '
								USING r.permission_set, o.company_type_key, o.supplier_type_key, r.capability_name, r.group_name;

							END IF;
						END IF;
					/*EXCEPTION
						WHEN OTHERS THEN 
							dbms_output.put_line(o.company_type_key||' - '||o.supplier_type_key||' - '||r.capability_name||' - '||r.group_name);
							RAISE;
					END;*/
				END IF;

			END LOOP;
		END LOOP;

----------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------
		 
		-- fix up chain admin permissions
		INSERT INTO chain.company_type_capability
		(app_sid, primary_company_type_id, primary_company_group_type_id, capability_id, secondary_company_type_id, tertiary_company_type_id)
		SELECT app_sid, primary_company_type_id, v_company_ca_group_type_id, capability_id, secondary_company_type_id, tertiary_company_type_id
		  FROM (
			SELECT UNIQUE app_sid, primary_company_type_id, capability_id, secondary_company_type_id, tertiary_company_type_id
			  FROM chain.company_type_capability
			 WHERE app_sid = v_app_sid
			)
		MINUS
		SELECT app_sid, primary_company_type_id, primary_company_group_type_id, capability_id, secondary_company_type_id, tertiary_company_type_id
		  FROM chain.company_type_capability
		 WHERE app_sid = v_app_sid
		   AND primary_company_group_type_id = v_company_ca_group_type_id;

		-- fix up chain admin permissions
		FOR r IN (
			SELECT app_sid, primary_company_type_id, primary_company_group_type_id, capability_id, secondary_company_type_id, tertiary_company_type_id
			  FROM chain.company_type_capability
			 WHERE app_sid = v_app_sid
			   AND primary_company_group_type_id = v_company_ca_group_type_id
		) LOOP
			v_ca_permission_set := 0;

			FOR p IN (
				SELECT ctc.permission_set
				  FROM chain.company_type_capability ctc, chain.company_group_type cgt
				 WHERE ctc.app_sid = r.app_sid
				   AND ctc.primary_company_type_id = r.primary_company_type_id
				   AND ctc.capability_id = r.capability_id
				   AND ctc.primary_company_group_type_id = cgt.company_group_type_id
				   AND NVL(secondary_company_type_id, 0) = NVL(r.secondary_company_type_id, 0)
				   AND NVL(tertiary_company_type_id, 0) = NVL(r.tertiary_company_type_id, 0)
				   AND cgt.is_global = 0
			) LOOP
				v_ca_permission_set := security.bitwise_pkg.bitor(v_ca_permission_set, p.permission_set);	
			END LOOP;

			-- update the chain admin permission set
			UPDATE chain.company_type_capability
			   SET permission_set = v_ca_permission_set
			 WHERE app_sid = r.app_sid
			   AND primary_company_type_id = r.primary_company_type_id
			   AND primary_company_group_type_id = r.primary_company_group_type_id
			   AND NVL(secondary_company_type_id, 0) = NVL(r.secondary_company_type_id, 0)
			   AND NVL(tertiary_company_type_id, 0) = NVL(r.tertiary_company_type_id, 0)
			   AND capability_id = r.capability_id;
		END LOOP;
	END LOOP;
END;
/

COMMIT;

DROP TABLE CHAIN.TT_CAPABILITY_SID_MAP;

--/*
-- comment this block out if it's causing problems on non-development or non-production systems
DECLARE
	v_count		NUMBER(10);
BEGIN
	security.user_pkg.logonadmin;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM chain.customer_options 
	 WHERE app_sid NOT IN (SELECT app_sid FROM chain.implementation WHERE name = 'RFA')
	   AND use_type_capabilities = 0;
	
	IF v_count <> 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'The script completed successfully where possible, but some sites have not been converted. See the notes at the top of this file for more information.');
	END IF;
END;
/
--*/

@update_tail
