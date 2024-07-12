/* It adds SOs capabilities into CHAIN.TT_OLD_SO_CAPABILITIES. 
   Used inside crossCheckCapabilities.sql but it can run independently as well */

--Temp function GetCapabilityPath. 
CREATE OR REPLACE FUNCTION chain.Temp_GetCapabilityPath (
	in_capability_id			IN  chain.capability.capability_id%TYPE
) RETURN VARCHAR2
AS
	v_capability_type		chain.chain_pkg.T_CAPABILITY_TYPE;
	v_capability			chain.chain_pkg.T_CAPABILITY;
	v_path					capability_type.container%TYPE;
BEGIN	
	SELECT capability_type_id, capability_name
	  INTO v_capability_type, v_capability
	  FROM chain.capability
	 WHERE capability_id = in_capability_id;
	
	SELECT CASE WHEN container IS NULL THEN NULL ELSE container || '/' END CASE
	  INTO v_path
	  FROM chain.capability_type
	 WHERE capability_type_id = v_capability_type;
	
	RETURN chain.chain_pkg.CAPABILITIES||'/'||v_path||v_capability;
END;
/
/* Fill TT with plain old SO capabilities*/
DECLARE
	v_sid	security.securable_object.sid_id%TYPE;
BEGIN
	
	dbms_output.put_line('Adding SOs capabilities into TT');
	dbms_output.put_line('-------------------------------');
	FOR i IN(
		SELECT c.*
		  FROM chain.capability c	
		 ORDER BY c.capability_name
	)
	LOOP
		BEGIN
			v_sid := NULL;
			v_sid := security.securableobject_pkg.GetSidFromPath(security_pkg.getAct, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.Temp_GetCapabilityPath(i.capability_id));
		EXCEPTION 
			WHEN security_pkg.ACCESS_DENIED THEN
				dbms_output.put_line('ACCESS_DENIED EXC for capability_id: ' || i.capability_id);
			WHEN security_pkg.OBJECT_NOT_FOUND THEN
				dbms_output.put_line('OBJECT_NOT_FOUND for capability_id: ' || i.capability_id);
			WHEN NO_DATA_FOUND THEN 
				dbms_output.put_line('NO_DATA_FOUND for capability_id: ' || i.capability_id);
		END;
		IF v_sid IS NOT NULL THEN
			FOR r IN (
				SELECT so2.name group_name, so.name, acl.permission_set, acl.acl_id, acl.sid_id dacl_so_id,
					CASE WHEN acl.permission_set = 0 THEN ''
						 WHEN acl.permission_set = 1 THEN 'READ'
						 WHEN acl.permission_set = 2 THEN 'WRITE'
						 WHEN acl.permission_set = 3 THEN 'READ WRITE'
						 WHEN acl.permission_set = 4 THEN 'DELETE'
						 WHEN acl.permission_set = 7 THEN 'R-W-D'
						ELSE CAST(acl.permission_set as varchar2(10))--we only resolved the most common perm sets
					END permission_desc
				  FROM security.securable_object so
				  JOIN security.acl acl ON (so.dacl_id = acl.acl_id)
				  JOIN security.securable_object so2 ON (acl.sid_id = so2.sid_id) 
				 WHERE so.sid_id = v_sid
			)
			LOOP
				INSERT INTO chain.TT_OLD_SO_CAPABILITIES (capability_id, capability_type, capability_name, so_id, dacl_id, dacl_so_id, permission_set, group_name)
					VALUES(i.capability_id, i.capability_type_id, i.capability_name, v_sid, r.acl_id, r.dacl_so_id, r.permission_set, r.group_name);
				  
				dbms_output.put_line(i.capability_id || ' ' || v_sid || ' ' || rpad (r.name, 30, ' ') || ' ' || rpad(r.group_name, 20, ' ') || ' ' || r.permission_desc);
			END LOOP;
		END IF;
	END LOOP;

END;
/

DROP FUNCTION chain.Temp_GetCapabilityPath;
