SET VERIFY OFF;

PROMPT >> &&host
PROMPT >> default top_company_sid
PROMPT >> &&company 
PROMPT >> default any other company
PROMPT >> &&supplier 
PROMPT >> default TOP
PROMPT >> &&company_lookup_key
PROMPT >> default SUPPLIER
PROMPT >> &&supplier_lookup_key

SET TERMOUT OFF;


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

SET SERVEROUTPUT ON;
SET TERMOUT ON;

DECLARE
	v_host					csr.customer.host%TYPE DEFAULT '&&host';
	v_company				VARCHAR2(1000) DEFAULT '&&company';
	v_company_sid			security.security_pkg.T_SID_ID;
	v_supplier				VARCHAR2(1000) DEFAULT '&&supplier';
	v_supplier_sid			security.security_pkg.T_SID_ID;
	v_company_type_key		chain.company_type.lookup_key%TYPE DEFAULT NVL('&&company_lookup_key', 'TOP');
	v_supplier_type_key		chain.company_type.lookup_key%TYPE DEFAULT NVL('&&supplier_lookup_key', 'SUPPLIER');
 	v_count					NUMBER(10);
	v_out					VARCHAR2(1000);
	v_char					VARCHAR2(10);
BEGIN
	security.user_pkg.logonadmin(v_host);
	
	BEGIN
		IF v_company IS NULL THEN
			SELECT top_company_sid 
			  INTO v_company_sid
			  FROM chain.customer_options
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');		 
		ELSIF REGEXP_REPLACE(v_company, '[^0-9]+', '') = v_company THEN -- check if it's a number
			SELECT company_sid 
			  INTO v_company_sid
			  FROM chain.company
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND company_sid = TO_NUMBER(v_company);
		ELSE
			SELECT company_sid 
			  INTO v_company_sid
			  FROM chain.company
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND LOWER(name) = LOWER(v_company);
		END IF;
	EXCEPTION
		WHEN OTHERS THEN
			NULL;
	END;
	
	IF v_company_sid IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'Could not determine a company to check');
	END IF;
	
	BEGIN
		IF v_supplier IS NULL THEN
			SELECT MAX(company_sid)
			  INTO v_supplier_sid
			  FROM chain.v$company
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND company_sid <> v_company_sid;		 
		ELSIF REGEXP_REPLACE(v_supplier, '[^0-9]+', '') = v_supplier THEN -- check if it's a number
			SELECT company_sid 
			  INTO v_supplier_sid
			  FROM chain.company
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND company_sid = TO_NUMBER(v_supplier);
		ELSE
			SELECT company_sid 
			  INTO v_supplier_sid
			  FROM chain.company
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND LOWER(name) = LOWER(v_supplier);
		END IF;
	EXCEPTION
		WHEN OTHERS THEN
			NULL;
	END;
	
	IF v_supplier_sid IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'Could not determine a supplier to check');
	END IF;
	
	FOR o IN (
		SELECT v_company_sid company_sid, v_company_type_key company_type_key, v_supplier_type_key supplier_type_key FROM DUAL
		UNION
		SELECT v_supplier_sid company_sid, v_supplier_type_key company_type_key, NULL supplier_type_key FROM DUAL
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
		   AND sid_id NOT IN (
			SELECT UNIQUE group_sid
			  FROM chain.tt_capability_sid_map
			 UNION
			SELECT security.securableobject_pkg.GetSidFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Groups/Everyone') FROM dual
			 UNION
			SELECT security.securableobject_pkg.GetSidFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Groups/Chain Administrators') FROM dual
			 UNION 
			SELECT security.securableobject_pkg.GetSidFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Groups/Chain Users') FROM dual
		 );

		IF v_count <> 0 THEN
			RAISE_APPLICATION_ERROR(-20001, 'Unexpected sids attached to capability dacls');
		END IF;

		SELECT COUNT(*)
		  INTO v_count
		  FROM (SELECT UNIQUE dacl_id FROM chain.tt_capability_sid_map WHERE company_sid = o.company_sid) m, security.acl a
		 WHERE m.dacl_id = a.acl_id
		   AND a.ace_type <> security_pkg.ACE_TYPE_ALLOW;

		IF v_count <> 0 THEN
			RAISE_APPLICATION_ERROR(-20001, 'Cannot transform ace types which are not ALLOW');
		END IF;

		FOR r IN (
		SELECT UNIQUE m.capability_sid, m.group_sid, a.permission_set
		  FROM chain.tt_capability_sid_map m, security.acl a
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = o.company_sid
		   AND m.dacl_id = a.acl_id
		   AND m.group_sid = a.sid_id
		) LOOP

			UPDATE chain.tt_capability_sid_map
			   SET permission_set = security.bitwise_pkg.bitor(permission_set, r.permission_set)
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
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

		v_count := 0;
		dbms_output.put_line(chr(10));
		dbms_output.put_line('STATEMENTS FOR '||o.company_type_key);
		dbms_output.put_line(chr(10));

		FOR r IN (
			SELECT m.*, 'chain.chain_pkg.'||c.capability_constant_name capability_constant_name, 
				   'chain.chain_pkg.'||DECODE(cgt.name, 'Administrators', 'ADMIN_GROUP', 'Users', 'USER_GROUP', 'Pending Users', 'PENDING_GROUP') group_name,
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
			
				v_out := 'chain.type_capability_pkg.SetPermission(';
				v_out := v_out || '''' || o.company_type_key || '''' || ', ';

				IF r.is_supplier = 1 THEN
					v_out := v_out || '''' || o.supplier_type_key || '''' || ', ';
				END IF;

				v_out := v_out || r.group_name || ', ';
				v_out := v_out || r.capability_type || ', ';
				v_out := v_out || r.capability_constant_name || ', ';

				IF r.perm_type = chain.chain_pkg.SPECIFIC_PERMISSION THEN
					v_char := '';
					FOR p IN (
						SELECT * FROM (
							SELECT 'PERMISSION_READ' const_name, 1 const_value FROM DUAL UNION
							SELECT 'PERMISSION_WRITE' const_name, 2 const_value FROM DUAL UNION
							SELECT 'PERMISSION_DELETE' const_name, 4 const_value FROM DUAL UNION
							SELECT 'PERMISSION_CHANGE_PERMISSIONS' const_name, 8 const_value FROM DUAL UNION
							SELECT 'PERMISSION_TAKE_OWNERSHIP' const_name, 16 const_value FROM DUAL UNION
							SELECT 'PERMISSION_READ_PERMISSIONS' const_name, 32 const_value FROM DUAL UNION
							SELECT 'PERMISSION_LIST_CONTENTS' const_name, 64 const_value FROM DUAL UNION
							SELECT 'PERMISSION_READ_ATTRIBUTES' const_name, 128 const_value FROM DUAL UNION
							SELECT 'PERMISSION_WRITE_ATTRIBUTES' const_name, 256 const_value FROM DUAL UNION
							SELECT 'PERMISSION_ADD_CONTENTS' const_name, 512 const_value FROM DUAL
						) ORDER BY const_value
					) LOOP
						IF security.bitwise_pkg.bitand(p.const_value, r.permission_set) = p.const_value THEN
							v_out := v_out || v_char || 'security.security_pkg.' || p.const_name;
							v_char := ' + ';
						END IF;
					END LOOP;

					IF v_char IS NULL THEN
						v_out := v_out || '0';
					END IF;
				ELSIF r.permission_set = 0 THEN
					v_out := v_out || 'FALSE';
				ELSE
					v_out := v_out || 'TRUE';
				END IF;

				v_out := v_out || ');';

				dbms_output.put_line(v_out);
				v_count := v_count + 1;
			END IF;
		END LOOP;
	END LOOP;

	dbms_output.put_line(chr(10));

	IF v_count = 0 THEN
		dbms_output.put_line('No changes required');
	END IF;
	
END;
/
--commit;

SET TERMOUT OFF;

--DROP TABLE chain.tt_capability_sid_map;

SET TERMOUT ON;
SET VERIFY ON;

--exit
