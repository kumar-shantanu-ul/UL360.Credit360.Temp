PROMPT please enter: host

-- Can use this to help create lookup_key update statements on audit types
-- select cast(substr(label,1,30) as char(30)) label, cast('UPDATE internal_audit_type SET lookup_key='''' WHERE internal_audit_type_id='||internal_audit_type_id||';' as char(79)) updt_stmt  from internal_audit_type;

-- Can use this to help create lookup_key statements on non compliance tags
-- select cast(substr(t.tag,1,30) as char(30)) tag, cast('UPDATE tag SET lookup_key='''' WHERE tag_id='||t.tag_id||';' as char(60)) updt_stmt from tag t join tag_group_member tgm on t.tag_id = tgm.tag_id join tag_group tg on tgm.tag_group_id = tg.tag_group_id where tg.applies_to_non_compliances = 1;

DECLARE
	v_act_id					security.security_pkg.T_ACT_ID;
	v_app_sid					security.security_pkg.T_SID_ID;
	
	v_number_measure_sid		security.security_pkg.T_SID_ID;
	
	v_ind_root_sid				security.security_pkg.T_SID_ID;
	v_audit_root_sid			security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.logonadmin('&&1');
	
	v_app_sid := sys_context('security','app');
	v_act_id := sys_context('security','act');
	
	SELECT ind_root_sid
	  INTO v_ind_root_sid
	  FROM customer;
	
	BEGIN
		SELECT measure_sid
		  INTO v_number_measure_sid
		  FROM measure
		 WHERE name = '#';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			measure_pkg.CreateMeasure(
				in_name				=> '#',
				in_description		=> '#',
				in_scale			=> 0,
				in_format_mask		=> '#,##0',
				in_pct_ownership_applies => 0,
				out_measure_sid		=> v_number_measure_sid
			);
	END;
	
	BEGIN
		SELECT ind_sid
		  INTO v_audit_root_sid
		  FROM ind
		 WHERE lookup_key = 'AUDIT_ROOT';
	EXCEPTION
		WHEN no_data_found THEN
		BEGIN
			-- TODO: audit container ind sid may not be this close to the ind root
			v_audit_root_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_ind_root_sid, 'audits');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				indicator_pkg.CreateIndicator(
					in_parent_sid_id 		=> v_ind_root_sid,
					in_name 				=> 'audits',
					in_description 			=> 'Audits',
					in_active	 			=> 1,
					out_sid_id				=> v_audit_root_sid
				);
		END;
		
		UPDATE ind SET lookup_key = 'AUDIT_ROOT'
		 WHERE ind_sid = v_audit_root_sid;
	END;
	
	FOR atyp IN (
		SELECT t.lookup_key, MIN(t.internal_audit_type_id) internal_audit_type_id
		  FROM csr.internal_audit_type t
		 WHERE t.lookup_key IS NOT NULL
		 GROUP BY t.lookup_key
	) LOOP
		audit_pkg.CreateMappedIndicators(atyp.internal_audit_type_id, atyp.lookup_key, v_audit_root_sid, v_number_measure_sid);
	END LOOP;
	
END;
/

--exit;
