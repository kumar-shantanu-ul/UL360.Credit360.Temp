-- resync flow state role capabilities to add the default permission sets for any new ones
BEGIN
	-- roles
	FOR r IN (
		SELECT f.app_sid, fs.flow_state_id, fc.flow_capability_id, fsr.role_sid, fc.default_permission_set
		  FROM csr.flow f
		  JOIN csr.flow_state fs
			ON f.flow_sid = fs.flow_sid
		  JOIN csr.flow_capability fc
			ON f.flow_alert_class = fc.flow_alert_class
		  JOIN csr.flow_state_role fsr
			ON fs.flow_state_id = fsr.flow_state_id AND fs.app_sid = fsr.app_sid
		  LEFT JOIN csr.flow_state_role_capability fsrc -- exclude existing capabilities
		    ON fsrc.app_sid = f.app_sid AND fsrc.flow_state_id = fs.flow_state_id 
		   AND fsrc.flow_capability_id = fc.flow_capability_id 
		   AND fsrc.role_sid = fsr.role_sid 
		 WHERE fsrc.flow_state_rl_cap_id IS NULL
	) LOOP
		BEGIN
			INSERT INTO csr.flow_state_role_capability (app_sid, flow_state_rl_cap_id, flow_state_id, flow_capability_id, role_sid, flow_involvement_type_id, permission_set)
			   VALUES (r.app_sid, csr.flow_state_rl_cap_id_seq.NEXTVAL, r.flow_state_id, r.flow_capability_id, r.role_sid, null, r.default_permission_set);
		EXCEPTION
			WHEN dup_val_on_index THEN
				-- already an existing capability
				NULL;
		END;
	END LOOP;
	
	-- involvements
	FOR r IN (
		SELECT f.app_sid, fs.flow_state_id, fc.flow_capability_id, fsi.flow_involvement_type_id, fc.default_permission_set
		  FROM csr.flow f
		  JOIN csr.flow_state fs
			ON f.flow_sid = fs.flow_sid
		  JOIN csr.flow_capability fc
			ON f.flow_alert_class = fc.flow_alert_class
		  JOIN csr.flow_state_involvement fsi
			ON fs.flow_state_id = fsi.flow_state_id AND fs.app_sid = fsi.app_sid
		  LEFT JOIN csr.flow_state_role_capability fsrc -- exclude existing capabilities
		    ON fsrc.app_sid = f.app_sid AND fsrc.flow_state_id = fs.flow_state_id 
		   AND fsrc.flow_capability_id = fc.flow_capability_id 
		   AND fsrc.flow_involvement_type_id = fsi.flow_involvement_type_id 
		 WHERE fsrc.flow_state_rl_cap_id IS NULL
	) LOOP
		BEGIN
			INSERT INTO csr.flow_state_role_capability (app_sid, flow_state_rl_cap_id, flow_state_id, flow_capability_id, role_sid, flow_involvement_type_id, permission_set)
			   VALUES (r.app_sid, csr.flow_state_rl_cap_id_seq.NEXTVAL, r.flow_state_id, r.flow_capability_id, null, r.flow_involvement_type_id, r.default_permission_set);
		EXCEPTION
			WHEN dup_val_on_index THEN
				-- already an existing capability
				NULL;
		END;
	END LOOP;
END;
/
