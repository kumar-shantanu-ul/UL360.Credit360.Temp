--Prerequisites: LOGON TO A HOST AND a chaincompany : use logonc.sql
/* Checks the matching between company type capabilities and SOs capabilities for a host and company*/
/* Step 1 : Inserts into TT_OLD_SO_CAPABILITIES */
/* Step 2 : Inserts into TT_NEW_TYPE_CAPABILITIES and checks if they are matched into SO */
/* Step 3 : Iterates TT_OLD_SO_CAPABILITIES and checks if they are matched agains type capabilities */

/* use: @logonc <host> <companyName> <user> <pwd>  eg: @logonc m.credit360.com maersk username pwd,  @logonc m.credit360.com supplierCompanyName username pwd*/
--@logonc.sql &host &company &user &pwd
@logonc.sql &1 &2 &3 &4  
/

DELETE FROM CHAIN.TT_OLD_SO_CAPABILITIES;
DELETE FROM CHAIN.TT_NEW_TYPE_CAPABILITIES;

@fillTTSOCapabilities;

/* Temp procedure for getting capabilities for a company type and related_company_type_id if exists
	Also checks the matching against the SOs	*/
CREATE OR REPLACE PROCEDURE chain.Temp_GetTypeCaps(
	in_company_type_id			chain.company_type.company_type_id%TYPE,
	in_lookup_key				chain.company_type.lookup_key%TYPE,
	in_related_company_type_id 	chain.company_type_capability.related_company_type_id%TYPE DEFAULT NULL,
	in_related_lookup_key		chain.company_type.lookup_key%TYPE DEFAULT NULL
)
AS
	v_so_id 	security.securable_object.sid_id%TYPE;
BEGIN
	IF in_related_company_type_id IS NULL THEN
		dbms_output.put_line('Company type: ' || in_lookup_key);
	ELSE 
		dbms_output.put_line(in_lookup_key || ' => ' || in_related_lookup_key);
	END IF;
	
	FOR r IN (
		SELECT capability_id, capability_name, perm_type, capability_type_id, is_supplier, permission_set, permission_descr, company_group_type_id, group_name
		  FROM (
			SELECT c.capability_id, c.capability_name, CASE WHEN c.perm_type = 0 THEN 'SPECIFIC' ELSE 'BOOLEAN' END perm_type, c.capability_type_id, c.is_supplier, ctc.permission_set,
				CASE WHEN c.perm_type = 1 THEN --boolean_permission
						 CASE WHEN ctc.permission_set = 0 THEN ''
							  WHEN ctc.permission_set = 2 THEN 'TRUE'
						 ELSE ''
					  END
					 WHEN c.perm_type = 0 THEN --specific_permission
						CASE WHEN ctc.permission_set = 0 THEN ''
							 WHEN ctc.permission_set = 1 THEN 'READ'
							 WHEN ctc.permission_set = 2 THEN 'WRITE'
							 WHEN ctc.permission_set = 3 THEN 'READ WRITE'
							 WHEN ctc.permission_set = 4 THEN 'DELETE'
							 WHEN ctc.permission_set = 7 THEN 'R-W-D'
						ELSE CAST(ctc.permission_set as varchar2(10))--we only resolved the most common perm sets
					  END
					 ELSE 'unknonw perm type'
				END permission_descr, 
				cgt.company_group_type_id,
				cgt.name group_name
			  FROM chain.capability c
			  JOIN chain.company_type_capability ctc ON (ctc.capability_id = c.capability_id)
			  JOIN chain.company_group_type cgt ON (cgt.company_group_type_id = ctc.company_group_type_id)
			 WHERE ctc.company_type_id = in_company_type_id 
			   AND (in_related_company_type_id IS NULL AND ctc.related_company_type_id IS NULL OR ctc.related_company_type_id = in_related_company_type_id)
			)
		 ORDER BY LOWER(capability_name)
	)
	LOOP 
		--Check capability id into TT_OLD_SO_CAPABILITES Table (i.e. check if we have given more/different type capabilities)
		v_so_id :=NULL;
		INSERT INTO CHAIN.TT_NEW_TYPE_CAPABILITIES (capability_id, capability_name, permission_set, group_name)
			VALUES (r.capability_id, r.capability_name, r.permission_set, r.group_name);
		
		IF r.permission_set != 0 THEN --no need to search for empty type capabilities
			BEGIN
				SELECT osc.SO_ID
				  INTO v_so_id
				  FROM chain.tt_old_so_capabilities osc
				 WHERE osc.capability_id = r.capability_id
				   AND osc.group_name = r.group_name
				   AND osc.permission_set = r.permission_set;
			EXCEPTION
				 WHEN NO_DATA_FOUND THEN 
					dbms_output.put_line('**ERROR** CANNOT MATCH the capability in SO ' || v_so_id || ' ' || r.capability_id || ' ' ||  rpad(r.capability_name, 30, ' ') || ' ' || rpad(r.group_name, 15, ' ')  ||  ' ' ||  rpad(r.permission_descr, 20, ' '));
				 WHEN TOO_MANY_ROWS THEN 
					dbms_output.put_line('WARNING TOO MANY ROWS for capability in SO ' || v_so_id || ' ' || r.capability_id || ' ' ||  rpad(r.capability_name, 30, ' ') || ' ' || rpad(r.group_name, 15, ' ')  ||  ' ' ||  rpad(r.permission_descr, 20, ' '));
			END;
			IF v_so_id IS NOT NULL THEN
				dbms_output.put_line('OK capability '  || v_so_id || ' ' || r.capability_id || ' ' ||  rpad(r.capability_name, 30, ' ') || ' ' || rpad(r.group_name, 15, ' ')  ||  ' ' ||  rpad(r.permission_descr, 20, ' '));
			END IF;
		END IF;
		--dbms_output.put_line(r.capability_id || ' 	' ||  rpad(r.capability_name, 20, ' ') || ' ' || rpad(r.group_name, 15, ' ')  ||  ' ' ||  rpad(r.permission_descr, 20, ' '));
		--chain.Temp_CheckOldCap(r.capability_id, r.permission_set, r.permission_descr);
	END LOOP;
	
	dbms_output.put_line('-------------------------------------------------------------------------------------------------------');
	dbms_output.put_line('');
END;
/

/* For every company type whe call teh temp proc for getting the capabililites
	Also we get the capabilites for every reltionship of this company type    */
DECLARE 
	 v_company_type chain.company.company_type_id%TYPE;
	 v_count	NUMBER;
BEGIN
	IF SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'Cannot check capabilities when the company sid is not set in session');	
	END IF;
	
	SELECT company_type_id
	  INTO v_company_type
	  FROM chain.company
	 WHERE company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'); 
	
	dbms_output.put_line('');
	dbms_output.put_line('MATCH NEW TYPE CAPABILITIES AGAINST SOs');
	dbms_output.put_line('---------------------------------------');
	FOR i IN (--loop does not make sense, I keep it in case I want to check all company types
		SELECT company_type_id, lookup_key, singular, plural, allow_lower_case, is_default, is_top_company 
		  FROM chain.company_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_type_id = v_company_type
		 ORDER BY position
	)
	LOOP        
		chain.Temp_GetTypeCaps(i.company_type_id, i.lookup_key);
      
	 	FOR j IN (
			  SELECT ctr.company_type_id, ctr.related_company_type_id, r.lookup_key
				FROM chain.company_type_relationship ctr
				JOIN chain.company_type c on (ctr.company_type_id = c.company_type_id)
 				JOIN chain.company_type r on (ctr.related_company_type_id = r.company_type_id)
			   WHERE ctr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			     AND ctr.company_type_id = i.company_type_id
			   ORDER BY c.position, r.position
		)
		LOOP    
			 chain.Temp_GetTypeCaps(i.company_type_id, i.lookup_key, j.related_company_type_id, j.lookup_key);	  

		END LOOP;

    END LOOP;
	
	--Iterate old SOs TT and check with TT_NEW_TYPE_CAPABILITIES (i.e. check if we have given less/different type capabilities)
	dbms_output.put_line('');
	dbms_output.put_line('MATCH SOs AGAINST NEW TYPE CAPABILITIES');
	dbms_output.put_line('---------------------------------------');
	FOR r IN (
		SELECT *
	      FROM CHAIN.TT_OLD_SO_CAPABILITIES
		 WHERE lower(GROUP_NAME) != lower('everyone')
		 ORDER BY LOWER(capability_name), capability_id
	)
	LOOP
		
		SELECT COUNT(*)
		  INTO v_count
		  FROM chain.tt_new_type_capabilities ntc
		 WHERE ntc.capability_id = r.capability_id
		   AND ntc.group_name = r.group_name
		   AND ntc.permission_set = r.permission_set;--may use bitand for more clarity in the results (although it will act more like contains permission)
	
		 IF v_count = 0 THEN 
			dbms_output.put_line('**ERROR** CANNOT MATCH SO with the capability ' || r.so_id || ' ' || r.capability_id || ' ' ||  rpad(r.capability_name, 30, ' ') || ' ' || rpad(r.group_name, 15, ' ')  ||  ' ' ||  r.PERMISSION_SET);
		 ELSIF v_count > 1 THEN 
			dbms_output.put_line('WARNING TOO MANY ROWS for capability in TT ' || r.so_id || ' ' || r.capability_id || ' ' ||  rpad(r.capability_name, 30, ' ') || ' ' || rpad(r.group_name, 15, ' ')  ||  ' ' ||  r.PERMISSION_SET);
		 ELSE
			dbms_output.put_line('OK capability '  || r.so_id || ' ' || r.capability_id || ' ' ||  rpad(r.capability_name, 30, ' ') || ' ' || rpad(r.group_name, 15, ' ')  ||  ' ' ||  r.PERMISSION_SET);
		END IF;	
	END LOOP;
	
END;
/


DROP PROCEDURE chain.Temp_GetTypeCaps;
