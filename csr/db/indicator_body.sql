CREATE OR REPLACE PACKAGE BODY CSR.Indicator_Pkg AS

FUNCTION INTERNAL_CheckIndExists(
	in_ind_sid						IN	security_pkg.T_SID_ID
)
RETURN BOOLEAN
AS
	v_exists						NUMBER;
BEGIN
	-- check for existence -- permission checks on non-existent object return denied, not object not found
	-- it's a bit late to change that so we'll need to check explicitly if these two cases need to be
	-- distinguished, as here
	SELECT COUNT(*)
	  INTO v_exists
	  FROM ind
	 WHERE ind_sid = in_ind_sid;
	RETURN v_exists != 0;
END;

PROCEDURE INTERNAL_EnsureIndExists(
	in_ind_sid						IN	security_pkg.T_SID_ID
)
AS
BEGIN
	IF NOT INTERNAL_CheckIndExists(in_ind_sid) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'The indicator with sid '||in_ind_sid||' does not exist');
	END IF;
END;

PROCEDURE SetGRICodes(
	in_app_sid		security_pkg.T_SID_ID,
	in_ind_sid			security_pkg.T_SID_ID,
	in_new_codes		ind.gri%TYPE
)
AS
	t_new_codes 			T_SPLIT_TABLE;
	t_old_codes 			T_SPLIT_TABLE;
	v_attachment_id			attachment.attachment_id%TYPE;
	t_sections_to_delete	security.T_SID_TABLE;
BEGIN
	t_new_codes := utils_pkg.splitstring(in_new_codes);
	-- what this indicator is currently bound to
	SELECT T_SPLIT_ROW(LOWER(ref), rn)
	 BULK COLLECT INTO t_old_codes
      FROM (
		SELECT distinct s.ref, rownum rn -- distinct as Dickie's stuff is still a mess
		  FROM attachment a, attachment_history ah, section s
		 WHERE indicator_sid = in_ind_sid
		   AND a.attachment_id = ah.attachment_id
		   AND ah.section_sid = s.section_sid
		   AND ref IS NOT NULL
	  );
	-- insert the new stuff
	INSERT INTO attachment 
		(attachment_Id, filename, mime_type, indicator_sid)
	VALUES
		(attachment_id_seq.nextval, 'indicator', 'application/indicator-sid', in_ind_sid)
	RETURNING attachment_id INTO v_attachment_id;
    -- Link the attachment data to the correct section
	INSERT INTO attachment_history (section_sid, version_number, attachment_id)
		SELECT s.section_sid, section_pkg.GetLatestVersion(s.section_sid), v_attachment_id
		  FROM section s, section_module sm
		 WHERE sm.app_sid = in_app_sid
		   AND sm.label = 'G3'
		   AND sm.module_root_Sid = s.module_root_Sid
		   AND LOWER(ref) IN (
				SELECT LOWER(trim(item))
				  FROM TABLE(t_new_codes)
				 MINUS 
	 			SELECT item
	 			  FROM TABLE(t_old_codes)
		 );
	-- delete from sections where old_codes - minus new codes
	SELECT s.section_sid
	  BULK collect into t_sections_to_delete
	  FROM section s, section_module sm
	 WHERE sm.app_sid = in_app_sid
	   AND sm.label = 'G3'
	   AND sm.module_root_Sid = s.module_root_Sid
	   AND LOWER(ref) IN (
 			SELECT item
 			  FROM TABLE(t_old_codes)
			 MINUS 
			SELECT LOWER(trim(item))
			  FROM TABLE(t_new_codes)
	 );
	DELETE FROM attachment_history 
     WHERE section_sid IN (
		SELECT column_value 
 		  FROM TABLE(t_sections_to_delete)
	);
	DELETE FROM attachment WHERE attachment_id IN (
		SELECT attachment_id 
          FROM attachment_history 
  	     WHERE section_sid in (
			SELECT column_value 
              FROM TABLE(t_sections_to_delete)
	 ));
END;

/**
 * Create a new indicator
 *
 * @param	in_act_id				Access token
 * @param	in_parent_sid_id		Parent object
 * @param   in_app_sid 		CSR Root SID
 * @param	in_name					Name
 * @param	in_description			Description
 * @param	in_active				1 or 0 (active / inactive)
 * @param	in_owner_sid			Owner SID
 * @param	in_measure_sid			The measure that this indicator is associated with.
 * @param	in_multiplier			Multiplier
 * @param	in_scale				Scale
 * @param	in_format_mask			Format mask
 * @param	in_target_direction		Target direction
 * @param	out_sid_id				The SID of the created ind
 *
 */
PROCEDURE CreateIndicator(
	in_act_id 						IN	security_pkg.T_ACT_ID				DEFAULT SYS_CONTEXT('SECURITY','ACT'),
	in_parent_sid_id				IN	security_pkg.T_SID_ID,      		
	in_app_sid 						IN	security_pkg.T_SID_ID				DEFAULT SYS_CONTEXT('SECURITY','APP'),
	in_name 						IN	ind.name%TYPE,
	in_description 					IN	ind_description.description%TYPE,
	in_active	 					IN	ind.active%TYPE 					DEFAULT 1,
	in_measure_sid					IN	security_pkg.T_SID_ID 				DEFAULT NULL,
	in_multiplier					IN	ind.multiplier%TYPE 				DEFAULT 0,
	in_scale						IN	ind.scale%TYPE 						DEFAULT NULL,
	in_format_mask					IN	ind.format_mask%TYPE				DEFAULT NULL,
	in_target_direction				IN	ind.target_direction%TYPE 			DEFAULT 1,
	in_gri							IN	ind.gri%TYPE						DEFAULT NULL,
	in_pos							IN	ind.pos%TYPE						DEFAULT NULL,
	in_info_xml						IN	ind.info_xml%TYPE					DEFAULT NULL,
	in_divisibility					IN	ind.divisibility%TYPE				DEFAULT NULL,
	in_start_month					IN	ind.start_month%TYPE				DEFAULT 1,
	in_ind_type						IN	ind.ind_type%TYPE					DEFAULT 0,
	in_aggregate					IN	ind.aggregate%TYPE					DEFAULT 'NONE',
	in_is_gas_ind					IN	NUMBER								DEFAULT 0,
	in_factor_type_id				IN	ind.factor_type_id%TYPE				DEFAULT NULL,
	in_gas_measure_sid				IN	security_pkg.T_SID_ID				DEFAULT NULL,
	in_gas_type_id					IN	ind.gas_type_id%TYPE				DEFAULT NULL,
	in_core							IN	ind.core%TYPE						DEFAULT 1,
	in_roll_forward					IN	ind.roll_forward%TYPE				DEFAULT 0,
	in_normalize					IN	ind.normalize%TYPE					DEFAULT 0,
	in_tolerance_type				IN	ind.tolerance_type%TYPE				DEFAULT 0,
	in_pct_upper_tolerance			IN	ind.pct_upper_tolerance%TYPE		DEFAULT 1,
	in_pct_lower_tolerance			IN	ind.pct_lower_tolerance%TYPE		DEFAULT 1,
	in_tolerance_number_of_periods	IN	ind.tolerance_number_of_periods%TYPE	DEFAULT NULL,
	in_tolerance_number_of_standard_deviations_from_average	IN	ind.tolerance_number_of_standard_deviations_from_average%TYPE	DEFAULT NULL,
	in_prop_down_region_tree_sid	IN	ind.prop_down_region_tree_sid%TYPE 	DEFAULT NULL,
	in_is_system_managed			IN	ind.is_system_managed%TYPE			DEFAULT 0,
	in_lookup_key					IN	ind.lookup_key%TYPE					DEFAULT NULL,
	in_calc_output_round_dp			IN	ind.calc_output_round_dp%TYPE		DEFAULT NULL,
	in_calc_description				IN	ind.calc_description%TYPE			DEFAULT NULL,
	out_sid_id						OUT security_pkg.T_SID_ID
)
AS
	v_ind_root_sid	security_pkg.T_SID_ID;
	v_parent_sid_id	security_pkg.T_SID_ID;
	v_pos			IND.pos%TYPE;
BEGIN
    IF in_parent_sid_id IS NULL THEN
        -- default to indicators
        v_parent_sid_id := Securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid, 'Indicators');
	ELSE    
        v_parent_Sid_Id := in_parent_sid_id;
	END IF;
	-- check permission is done by create SO (checks ADD_CONTENTS). we can't check parent
	-- for ALTER_SCHEMA since parent might be a Container (Indicators)
	group_pkg.CreateGroupWithClass(in_act_id, v_parent_sid_id, security_pkg.GROUP_TYPE_SECURITY,
		Replace(in_name,'/','\'), class_pkg.getClassID('CSRIndicator'), out_sid_id); --'

	IF in_pos IS NULL THEN
		SELECT NVL(MAX(pos),0)+1 INTO v_pos FROM IND WHERE parent_sid = v_parent_sid_id;
	ELSE
		v_pos := in_pos;
	END IF;
	
	-- add object to the DACL (the indicator is a group, so it has permissions on itself)
	acl_pkg.AddACE(in_act_id, acl_pkg.GetDACLIDForSID(out_sid_id), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, out_sid_id, security_pkg.PERMISSION_STANDARD_READ);

	-- TODO: 13p fix required: consider supporting sites without calendar months?	
	INSERT INTO ind (ind_sid, parent_sid, app_sid, name, scale, format_mask,
		 measure_sid, active, target_direction, gri, info_xml, pos, divisibility,
		 multiplier, start_month, ind_type, aggregate, core, roll_forward, factor_type_id,
		 gas_measure_sid, gas_type_id, normalize,
		 tolerance_type, pct_lower_tolerance, pct_upper_tolerance,
		 tolerance_number_of_periods, tolerance_number_of_standard_deviations_from_average,
		 prop_down_region_tree_sid, is_system_managed,
		 lookup_key, calc_output_round_dp, calc_description, period_set_id, period_interval_id)
	VALUES (out_sid_id, v_parent_sid_id, in_app_sid, in_name, in_scale, in_format_mask,
		 in_measure_sid, in_active, in_target_direction, in_gri, in_info_xml, v_pos, in_divisibility,
		 in_multiplier, in_start_month, in_ind_type, in_aggregate, in_core, in_roll_forward,
		 in_factor_type_id, in_gas_measure_sid, in_gas_type_id, in_normalize,
		 in_tolerance_type, in_pct_lower_tolerance, in_pct_upper_tolerance,
		 in_tolerance_number_of_periods, in_tolerance_number_of_standard_deviations_from_average,
		 in_prop_down_region_tree_sid, in_is_system_managed, in_lookup_key,
		 in_calc_output_round_dp, in_calc_description, 1, 1);

	INSERT INTO ind_description (ind_sid, lang, description, last_changed_dtm)
		SELECT out_sid_id, lang, in_description, SYSDATE
		  FROM v$customer_lang;

	-- add recalc jobs as we could change the value of an average of children aggregate, even though we have no data
	SELECT ind_root_sid
	  INTO v_ind_root_sid
	  FROM customer
	 WHERE app_sid = in_app_sid;
	IF v_ind_root_sid != v_parent_sid_id THEN -- don't do this for top of tree
		Calc_Pkg.AddJobsForInd(out_sid_id);
	END IF;	
		
	SetGRICodes(in_app_sid, out_sid_id, in_gri);	
	
	csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, in_app_sid, out_sid_id,
		'Created "{0}"', INTERNAL_GetIndPathString(out_sid_id));
	
	IF in_is_gas_ind != 0 THEN
		CreateGasIndicators(out_sid_id);
	END IF;
END;

/**
 * Move an existing indicator
 *
 * @param	in_act_id				Access token
 * @param	in_move_ind_sid			ind to move
 * @param   in_parent_sid 			New parent object
 * @param	out_sid_id				The SID of the created ind
 *
 */
PROCEDURE MoveIndicator(
	in_act_id 				IN security_pkg.T_ACT_ID,
	in_ind_sid 				IN security_pkg.T_SID_ID,
	in_parent_sid_id 		IN security_pkg.T_SID_ID
)
AS
	v_parent_sid			security_pkg.T_SID_ID;
	v_name					security_pkg.T_SO_NAME;
BEGIN
	-- original name
    SELECT replace(name,'/','\'), parent_sid
      INTO v_name, v_parent_sid
      FROM ind 
     WHERE ind_sid = in_ind_sid;

	IF in_parent_sid_id != v_parent_sid THEN
		securableobject_pkg.RenameSO(in_act_id, in_ind_sid, null); -- rename to null so we don't get dupe object name errors
		securableobject_pkg.MoveSO(in_act_id, in_ind_sid, in_parent_sid_id);	
		utils_pkg.UniqueSORename(in_act_id, in_ind_sid, v_name); -- rename back uniquely
	END IF;
END;

PROCEDURE INTERNAL_CopyIndicatorRecursiv(
	in_act_id 				IN security_pkg.T_ACT_ID,
	in_copy_ind_sid 		IN security_pkg.T_SID_ID,
	in_parent_sid_id 		IN security_pkg.T_SID_ID,
	io_table				IN OUT T_FROM_TO_TABLE
) AS
	v_pos					ind.pos%TYPE;
	v_count					NUMBER;
    CURSOR c IS
	    SELECT app_sid, name, active, measure_sid, multiplier, scale, format_mask, target_direction, 
	    	   gri, pos, info_xml, divisibility, start_month, ind_type, aggregate, calc_xml, calc_start_dtm_adjustment, 
			   calc_end_dtm_adjustment, period_set_id, period_interval_id, do_temporal_aggregation, calc_description, 
	    	   tolerance_type, pct_lower_tolerance, pct_upper_tolerance, 
			   tolerance_number_of_periods, tolerance_number_of_standard_deviations_from_average,
	    	   ind_activity_type_id, core, roll_forward, factor_type_id, gas_type_id, gas_measure_sid,
	    	   map_to_ind_sid, prop_down_region_tree_sid, is_system_managed, calc_fixed_start_dtm, calc_fixed_end_dtm,
	    	   normalize, calc_output_round_dp
		 FROM ind
         WHERE ind_sid = in_copy_ind_sid;
    r	c%ROWTYPE;
    v_ind_root_sid			security_pkg.T_SID_ID;
	v_duplicate_count		NUMBER(10);
	v_base_name				security_pkg.T_SO_NAME;
	v_name					security_pkg.T_SO_NAME;
	v_description			ind_description.description%TYPE;
	v_try_again				BOOLEAN;
	v_new_sid_id			security_pkg.T_SID_ID;
	v_app_sid				security_pkg.T_SID_ID;
	v_is_sel_group			NUMBER(10);
	v_is_sel_group_member	NUMBER(10);
BEGIN
	-- check permission is done by create SO (checks ADD_CONTENTS). we can't check parent
	-- for ALTER_SCHEMA since parent might be a Container (Indicators)
    SELECT COUNT(*) INTO v_count
	  FROM (SELECT ind_sid FROM IND START WITH ind_sid = in_copy_ind_sid CONNECT BY PRIOR ind_sid = parent_sid)
	  WHERE ind_sid = in_parent_sid_id;
	IF v_count > 0 THEN
	    RAISE_APPLICATION_ERROR(Security_Pkg.ERR_MOVED_UNDER_SELF, 'Can''t copy an object under itself');
	END IF;

    OPEN c;
    FETCH c INTO r;

    -- unique name
    v_base_name := SUBSTR(REPLACE(r.name,'/','\'),1,240);
    v_name := v_base_name;
	v_duplicate_count := 0;
	v_try_again := TRUE;
	WHILE v_try_again LOOP
		BEGIN
			group_pkg.CreateGroupWithClass(in_act_id, in_parent_sid_id, security_pkg.GROUP_TYPE_SECURITY,
				v_name, class_pkg.getClassID('CSRIndicator'), v_new_sid_id);
			v_try_again := FALSE;
		EXCEPTION
			WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
				v_name := v_base_name || ' (copy)';
				v_duplicate_count := v_duplicate_count + 1;
				IF v_duplicate_count > 1 THEN
					v_name := v_base_name||' (copy '||v_duplicate_count||')';
				END IF;
				v_try_again := TRUE;
		END;
	END LOOP;
	
	-- add object to the DACL (the indicator is a group, so it has permissions on itself)
	acl_pkg.AddACE(in_act_id, acl_pkg.GetDACLIDForSID(v_new_sid_id), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_new_sid_id, security_pkg.PERMISSION_STANDARD_READ);

/* TODO: this doesn't translate
    -- unique description
    v_description := r.description;
	v_duplicate_count := 0;
	v_try_again := TRUE;
	WHILE v_try_again LOOP
		SELECT COUNT(*) INTO v_count
          FROM IND
         WHERE parent_sid = in_parent_sid_id
           AND LOWER(description) = LOWER(v_description);
		v_try_again := FALSE;
		IF v_count > 0 THEN
			v_description := r.description || ' (copy)';
			v_duplicate_count := v_duplicate_count + 1;
			IF v_duplicate_count > 1 THEN
				v_description := r.description||' (copy '||v_duplicate_count||')';
			END IF;
			v_try_again := TRUE;
		END IF;
	END LOOP;
*/

	SELECT NVL(MAX(pos),0)+1
	  INTO v_pos
      FROM ind
     WHERE parent_sid = in_parent_sid_id;

	INSERT INTO ind (
		ind_sid, parent_sid, app_sid, name, scale, format_mask,
		measure_sid, active, target_direction, gri, info_xml, pos, divisibility,
		multiplier, start_month, ind_type, aggregate, calc_xml, calc_start_dtm_adjustment,
		calc_end_dtm_adjustment, period_set_id, period_interval_id, do_temporal_aggregation,
		calc_description, 
		tolerance_type, pct_lower_tolerance, pct_upper_tolerance,
		tolerance_number_of_periods, tolerance_number_of_standard_deviations_from_average,
		core, roll_forward, factor_type_id, gas_type_id, gas_measure_sid,
		map_to_ind_sid, prop_down_region_tree_sid, is_system_managed,
		calc_fixed_start_dtm, calc_fixed_end_dtm, normalize, calc_output_round_dp)
	VALUES (
		v_new_sid_id, in_parent_Sid_id, r.app_sid, v_name, r.scale, r.format_mask,
		r.measure_sid, r.active, r.target_direction, r.gri, r.info_xml, v_pos, r.divisibility,
		r.multiplier, r.start_month, r.ind_type, r.aggregate, r.calc_xml, r.calc_start_dtm_adjustment,
		r.calc_end_dtm_adjustment, r.period_set_id, r.period_interval_id,
		r.do_temporal_aggregation, r.calc_description,
		r.tolerance_type, r.pct_lower_tolerance, r.pct_upper_tolerance,
		r.tolerance_number_of_periods, r.tolerance_number_of_standard_deviations_from_average,
		r.core, r.roll_forward, r.factor_type_id, r.gas_type_id, r.gas_measure_sid,
		r.map_to_ind_sid, r.prop_down_region_tree_sid, r.is_system_managed,
		r.calc_fixed_start_dtm, r.calc_fixed_end_dtm, r.normalize, r.calc_output_round_dp);
    
    INSERT INTO ind_description (ind_sid, lang, description, last_changed_dtm)
    	SELECT v_new_sid_id, lang, description, SYSDATE
    	  FROM ind_description
    	 WHERE ind_sid = in_copy_ind_sid;
    
    SetGRICodes(r.app_sid, v_new_sid_id, r.gri);
    
    -- copy ind_window (DEPRECATED)
    INSERT INTO ind_window (ind_sid, period, upper_bracket, lower_bracket)
	    SELECT v_new_sid_id, period, upper_bracket, lower_bracket
	      FROM ind_window
	     WHERE ind_sid = in_copy_ind_sid;

    -- copy ind_flags
    INSERT INTO ind_flag (ind_sid, flag, description)
	    SELECT v_new_sid_id, flag, description
	      FROM ind_flag
	     WHERE ind_sid = in_copy_ind_sid;

    -- if it's a formula, copy dependents
    INSERT INTO calc_dependency (calc_ind_sid, ind_sid, dep_type)
	    SELECT v_new_sid_id, ind_sid, dep_type
	      FROM calc_dependency
	     WHERE calc_ind_sid = in_copy_ind_sid;

    -- copy tags
    INSERT INTO ind_tag (tag_id, ind_sid)
	    SELECT tag_id, v_new_sid_id
	      FROM ind_tag
	     WHERE ind_sid = in_copy_ind_sid;
	
    -- copy validation rules
    INSERT INTO ind_validation_rule (ind_validation_rule_id, ind_sid, expr, message, position, type)
	    SELECT ind_validation_rule_id_seq.NEXTVAL, v_new_sid_id, expr, message, position, type
	      FROM ind_validation_rule
	     WHERE ind_sid = in_copy_ind_sid;
	
	-- is selection group/master indicator?
	SELECT COUNT(*)
	  INTO v_is_sel_group
	  FROM ind_selection_group
	 WHERE master_ind_sid = in_copy_ind_sid;

	IF v_is_sel_group > 0 THEN
		INSERT INTO ind_selection_group (master_ind_sid) VALUES (v_new_sid_id);
	END IF;

	-- is selection group member?
	SELECT COUNT(*)
	  INTO v_is_sel_group_member
	  FROM ind_selection_group_member
	 WHERE ind_sid = in_copy_ind_sid;

	IF v_is_sel_group_member > 0 THEN
		-- selection group member is being copied to master indicator as parent?
		SELECT COUNT(*)
		  INTO v_is_sel_group
		  FROM ind_selection_group
		 WHERE master_ind_sid = in_parent_sid_id;
		
		IF v_is_sel_group > 0 THEN
			INSERT INTO ind_selection_group_member (master_ind_sid, ind_sid, pos)
			VALUES (
						in_parent_sid_id, v_new_sid_id,(
							SELECT NVL(MAX(pos), 0)
							  FROM ind_selection_group_member
							 WHERE master_ind_sid = in_parent_sid_id
						) + 1
				   );
			INSERT INTO ind_sel_group_member_desc (ind_sid, lang, description) 
			SELECT v_new_sid_id, lang, description
			  FROM ind_sel_group_member_desc
			 WHERE app_sid = security.security_pkg.getApp 
			   AND ind_sid = in_copy_ind_sid;
		END IF;
	END IF;

	-- add jobs for copied stored calcs
	IF r.ind_type = csr_data_pkg.IND_TYPE_STORED_CALC THEN
		calc_pkg.AddJobsForCalc(v_new_sid_id);
	END IF;

	csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, in_copy_ind_sid,
		'Copied "{0}" to "{1}"', 
		INTERNAL_GetIndPathString(in_copy_ind_sid),
		INTERNAL_GetIndPathString(v_new_sid_id));

    io_table.extend;
    io_table(io_table.COUNT) := T_FROM_TO_ROW(in_copy_ind_sid, v_new_sid_id);
    
    -- copy any children...
    FOR r IN (SELECT ind_sid 
    			FROM ind 
    		   WHERE parent_sid = in_copy_ind_sid 
    		ORDER BY pos)
    LOOP
	    INTERNAL_CopyIndicatorRecursiv(in_act_id, r.ind_sid, v_new_sid_id, io_table);
    END LOOP;
END;

PROCEDURE INTERNAL_CopyIndicator(
	in_act_id 				IN security_pkg.T_ACT_ID,
	in_copy_ind_sid 		IN security_pkg.T_SID_ID,
	in_parent_sid_id 		IN security_pkg.T_SID_ID,
	io_table				IN OUT T_FROM_TO_TABLE
) AS
BEGIN
	INTERNAL_CopyIndicatorRecursiv(in_act_id, in_copy_ind_sid, in_parent_sid_id, io_table);
	
	-- Fix up map_to_ind_sid (where we copied the indicator that was being mapped to)
	-- Some C# code is used to update the calculations in the same way
	UPDATE ind i
	   SET i.map_to_ind_sid = (SELECT to_sid
	   						     FROM TABLE(io_table) t
	   						    WHERE t.from_sid = i.map_to_ind_sid),
	   	   last_modified_dtm = SYSDATE
	 WHERE i.ind_sid IN (SELECT to_sid 
	 					   FROM TABLE(io_table))
	   AND i.map_to_ind_sid IN (SELECT from_sid
	   							  FROM TABLE(io_table));
END;

/**
 * Copy an existing indicator
 *
 * @param	in_act_id				Access token
 * @param	in_copy_ind_sid			ind to copy
 * @param   in_parent_sid 			Parent object
 * @param	out_sid_id				The SID of the created ind
 *
 */
PROCEDURE CopyIndicator(
	in_act_id 				IN security_pkg.T_ACT_ID,
	in_copy_ind_sid 		IN security_pkg.T_SID_ID,
	in_parent_sid_id 		IN security_pkg.T_SID_ID,
	out_sid_id				OUT security_pkg.T_SID_ID
) AS
	v_table T_FROM_TO_TABLE := T_FROM_TO_TABLE();
BEGIN
	INTERNAL_CopyIndicator(in_act_id, in_copy_ind_sid, in_parent_sid_id, v_table);
	out_sid_id := v_table(1).to_sid; -- Oracle's varray's are 1 based!!
END;

PROCEDURE CopyIndicatorFlags(
	in_act_id 				IN security_pkg.T_ACT_ID,
	in_ind_sid_from 		IN security_pkg.T_SID_ID,
	in_ind_sid_to	 		IN security_pkg.T_SID_ID
) AS
BEGIN
    BEGIN
    INSERT INTO ind_flag (ind_sid, flag, description)
		SELECT in_ind_sid_to, flag, description
		FROM ind_flag
		WHERE ind_sid = in_ind_sid_from;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_DUPLICATE_OBJECT_NAME, 'Flags for this indicator already exist.');
	END;
END;

PROCEDURE CopyIndicatorValidationRules(
	in_act_id 				IN security_pkg.T_ACT_ID,
	in_ind_sid_from 		IN security_pkg.T_SID_ID,
	in_ind_sid_to	 		IN security_pkg.T_SID_ID
) AS
BEGIN
    BEGIN
	INSERT INTO ind_validation_rule (ind_validation_rule_id, ind_sid, expr, message, position, type)
		SELECT ind_validation_rule_id_seq.NEXTVAL, in_ind_sid_to, expr, message, position, type
		FROM ind_validation_rule
		WHERE ind_sid = in_ind_sid_from;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_DUPLICATE_OBJECT_NAME, 'Validation Rules for this indicator already exist.');
	END;
END;

PROCEDURE CopyIndicatorReturnMap(
	in_act_id 				IN security_pkg.T_ACT_ID,
	in_copy_ind_sid 		IN security_pkg.T_SID_ID,
	in_parent_sid_id 		IN security_pkg.T_SID_ID,
	out_cur					OUT SYS_REFCURSOR
) AS
	v_table T_FROM_TO_TABLE := T_FROM_TO_TABLE();
BEGIN
	INTERNAL_CopyIndicator(in_act_id, in_copy_ind_sid, in_parent_sid_id, v_table);
	OPEN out_cur FOR
		SELECT t.from_sid, t.to_sid, i.ind_type, i.calc_xml, i.period_set_id,
			   i.period_interval_id, i.do_temporal_aggregation, i.calc_description
		  FROM TABLE(v_table) t, ind i
		 WHERE t.to_sid = i.ind_sid;
END;

PROCEDURE SetGasCalc(
	in_ind_sid				IN	security_pkg.T_SID_ID,
	in_factor_type_id		IN	ind.factor_type_id%TYPE
)
AS
	v_ind_sid				security_pkg.T_SID_ID;
	v_calc_xml				ind.calc_xml%TYPE;
	v_gas_calc_xml			CLOB;
	v_path					VARCHAR2(200);
	v_factor_type_id		ind.factor_type_id%TYPE;
	v_map_to_ind_sid		ind.map_to_ind_sid%TYPE;
	v_period_set_id			ind.period_set_id%TYPE;
	v_period_interval_id	ind.period_interval_id%TYPE;
	v_do_temporal_agg		ind.do_temporal_aggregation%TYPE;
	v_stored				NUMBER;
	v_gas_type				gas_type.name%TYPE;
	v_gas_type_id			gas_type.gas_type_id%TYPE;
	v_varchar				VARCHAR2(255);
	v_sel_group_mem_cnt 	NUMBER;
	
	TYPE fn_names IS TABLE OF VARCHAR2(40);
	fns fn_names := fn_names('path', 'sum', 'average', 'min', 'max', 'previousperiod', 'periodpreviousyear', 'periodpreviousnyears',
		'fye', 'std', 'ytd', 'compareytd', 'rollingperiod', 'rollingyear',
		'rollingnintervalsavg', 'rollingnintervals',
		'percentchange', 'percentchange_periodpreviousyear_ytd', 'rank', 'round');
	v_doc					DBMS_XMLDOM.DOMDocument;
	v_nodes					DBMS_XMLDOM.DOMNodeList;
	v_node					DBMS_XMLDOM.DOMNode;
	v_element				DBMS_XMLDOM.DOMElement;
BEGIN
	SELECT i.ind_sid, i.calc_xml, i.map_to_ind_sid, gi.period_set_id, gi.period_interval_id, i.do_temporal_aggregation,
			CASE i.ind_type
				WHEN csr_data_pkg.IND_TYPE_CALC THEN 0
				ELSE 1
			END stored,
			gt.name gas_type,
			gi.gas_type_id
	  INTO v_ind_sid, v_calc_xml, v_map_to_ind_sid, v_period_set_id, v_period_interval_id, 
	  	   v_do_temporal_agg, v_stored, v_gas_type, v_gas_type_id
	  FROM ind i
	  JOIN ind gi ON i.ind_sid = gi.map_to_ind_sid
	  JOIN gas_type gt ON gi.gas_type_id = gt.gas_type_id
	 WHERE gi.ind_sid = in_ind_sid;
	
	SELECT COUNT(*)
	  INTO v_sel_group_mem_cnt
	  FROM ind_selection_group_member isgm
	 WHERE master_ind_sid = v_ind_sid;
	
	IF in_factor_type_id IS NOT NULL AND v_map_to_ind_sid IS NULL THEN
		IF v_calc_xml IS NULL OR in_factor_type_id != factor_pkg.UNSPECIFIED_FACTOR_TYPE THEN -- 'factor type is not Unspecified'
			calc_pkg.SetCalcXMLAndDeps(
				in_calc_ind_sid 			=> in_ind_sid,
				in_calc_xml 				=>
					'<multiply>' ||
						'<left>' ||
							'<path sid="' || v_ind_sid || '" />' ||
						'</left>' ||
						'<right>' ||
							'<gasfactor />' ||
						'</right>' ||
					'</multiply>',
				in_is_stored 				=> 1,
				in_period_set_id 			=> v_period_set_id,
				in_period_interval_id		=> v_period_interval_id,
				in_do_temporal_aggregation	=> 0
			);
			UPDATE ind
			   SET aggregate = 'FORCE SUM', last_modified_dtm = SYSDATE
			 WHERE ind_sid = in_ind_sid;
			 
		ELSIF v_sel_group_mem_cnt > 0 THEN
			-- Parent has DQ inds, which will have gas calcs too. Set these gas calcs to be the sum of the DQ ind gas calcs.
			dbms_lob.createTemporary(v_gas_calc_xml, TRUE, dbms_lob.call);
			dbms_lob.open(v_gas_calc_xml, DBMS_LOB.LOB_READWRITE);
		
			FOR i IN 1 .. v_sel_group_mem_cnt - 1 LOOP
				aspen2.utils_pkg.WriteAppend(v_gas_calc_xml, '<add><left>');
			END LOOP;

			FOR r IN (
				select ind_sid, rownum rn
				from csr.ind
				where gas_type_id = v_gas_type_id
				and is_system_managed = 1
				and map_to_ind_sid in (
				  select ind_sid from ind_selection_group_member where master_ind_sid = v_ind_sid
				)
			) LOOP
				v_path := '<path sid="' || r.ind_sid || '" />';
				IF r.rn = 1 THEN
					aspen2.utils_pkg.WriteAppend(v_gas_calc_xml, v_path);
				ELSE
					aspen2.utils_pkg.WriteAppend(v_gas_calc_xml, '</left><right>' || v_path || '</right></add>');
				END IF;
			END LOOP;

			calc_pkg.SetCalcXMLAndDeps(
				in_calc_ind_sid				=> in_ind_sid,
				in_calc_xml					=> v_gas_calc_xml,
				in_is_stored				=> 1,
				in_period_set_id			=> 1, -- XXX: calendar, probably need to be able to set this on the group
				in_period_interval_id		=> 1, -- annual
				in_do_temporal_aggregation	=> 0
			);
			
			dbms_lob.freeTemporary(v_gas_calc_xml);
			
		ELSE -- 'Unspecified factor type'
			v_doc := DBMS_XMLDOM.newDOMDocument(v_calc_xml);
			
			FOR i IN fns.FIRST .. fns.LAST
			LOOP
				v_nodes := DBMS_XSLPROCESSOR.selectNodes(DBMS_XMLDOM.makeNode(v_doc), '//' || fns(i));
				
				FOR idx IN 0 .. DBMS_XMLDOM.getLength(v_nodes) - 1 LOOP
					v_node := DBMS_XMLDOM.item(v_nodes, idx);
					v_element := DBMS_XMLDOM.MAKEELEMENT(v_node);
					v_varchar := DBMS_XMLDOM.GETATTRIBUTE(v_element, 'description');
					DBMS_XMLDOM.SETATTRIBUTE(v_element, 'description', v_gas_type || ' of ' || v_varchar);  -- XXX: i18n?
				END LOOP;
			END LOOP;

			dbms_lob.createTemporary(v_calc_xml, TRUE, dbms_lob.call);
			dbms_lob.open(v_calc_xml, DBMS_LOB.LOB_READWRITE);
			dbms_xmldom.writeToClob(v_doc, v_calc_xml);
						
			calc_pkg.SetCalcXMLAndDeps(
				in_calc_ind_sid				=> in_ind_sid,
				in_calc_xml					=> v_calc_xml,
				in_is_stored				=> v_stored,
				in_period_set_id			=> v_period_set_id,
				in_period_interval_id		=> v_period_interval_id,
				in_do_temporal_aggregation	=> v_do_temporal_agg
			);
			dbms_lob.freeTemporary(v_calc_xml);
		END IF;
	END IF;
END;

PROCEDURE CreateGasIndicators(
	in_ind_sid						IN	security_pkg.T_SID_ID,
	in_override_factor_type_id		IN	ind.factor_type_id%TYPE DEFAULT NULL
)
AS
	v_count					NUMBER;
	v_name					ind.name%TYPE;
	v_description			ind_description.description%TYPE;
	v_gas_measure_sid		ind.gas_measure_sid%TYPE;
	v_info_xml				ind.info_xml%TYPE;
	v_divisibility			ind.divisibility%TYPE;
	v_start_month			ind.start_month%TYPE;
	v_aggregate				ind.aggregate%TYPE;
	v_ind_type				ind.ind_type%TYPE;
	v_factor_type_id		ind.factor_type_id%TYPE;
	v_gas_ind_sid			security_pkg.T_SID_ID;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM ind
	 WHERE map_to_ind_sid = in_ind_sid;
	
	SELECT i.name, i.description, i.gas_measure_sid, i.info_xml,
		   NVL(i.divisibility, m.divisibility), i.start_month,
			CASE i.ind_type
				WHEN csr_data_pkg.IND_TYPE_CALC THEN csr_data_pkg.IND_TYPE_CALC
				ELSE csr_data_pkg.IND_TYPE_STORED_CALC
			END ind_type,
			CASE 
				-- if the ind to which we're applying this is already a calc, then we want to use the same aggregation type.
				-- If it's just a normal value, then we want to use FORCE SUM.
				WHEN i.ind_type IN (csr_data_pkg.IND_TYPE_CALC, csr_data_pkg.IND_TYPE_STORED_CALC) THEN i.aggregate
				ELSE 'FORCE SUM'
			END aggregate, 
		   i.factor_type_id
	  INTO v_name, v_description, v_gas_measure_sid, v_info_xml, v_divisibility, v_start_month, v_ind_type, v_aggregate, v_factor_type_id
	  FROM v$ind i
	  LEFT JOIN measure m ON i.measure_sid = m.measure_sid
	 WHERE i.ind_sid = in_ind_sid;
	
	IF in_override_factor_type_id IS NOT NULL THEN
		v_factor_type_id := in_override_factor_type_id;
	END IF;
	
	IF v_count = 0 THEN
		FOR r IN (SELECT name, gas_type_id 
					FROM gas_type)
		LOOP
			CreateIndicator(
				in_act_id						=> SYS_CONTEXT('SECURITY','ACT'),
				in_parent_sid_id				=> in_ind_sid,
				in_app_sid						=> SYS_CONTEXT('SECURITY','APP'),
				in_name							=> r.name || ' of ' || v_name,        -- XXX: i18n?
				in_description					=> r.name || ' of ' || v_description, -- XXX: i18n?
				in_measure_sid					=> v_gas_measure_sid,
				in_info_xml						=> v_info_xml,
				in_divisibility					=> v_divisibility,
				in_start_month					=> v_start_month,
				in_ind_type						=> v_ind_type,
				in_aggregate					=> v_aggregate,
				in_factor_type_id				=> v_factor_type_id,
				in_gas_type_id					=> null,
				in_is_system_managed			=> 1,
				in_target_direction				=> -1,
				out_sid_id						=> v_gas_ind_sid
			);
			
			UPDATE ind
			   SET map_to_ind_sid = in_ind_sid, -- no need to update last_modified_dtm since indicator is newly created
			   	   gas_type_id = r.gas_type_id
			 WHERE ind_sid = v_gas_ind_sid;
			
			SetGasCalc(v_gas_ind_sid, v_factor_type_id);
		END LOOP;
	ELSE
		FOR r IN (
			SELECT i.ind_sid, i.gas_type_id, gt.name
			  FROM ind i
			  JOIN gas_type gt ON i.gas_type_id = gt.gas_type_id
			 WHERE i.map_to_ind_sid = in_ind_sid
			   AND i.active = 1
		)
		LOOP
			--security_pkg.debugmsg('amend gas='||r.ind_sid);
			AmendIndicator(
				in_ind_sid		 				=> r.ind_sid,
				in_description 					=> r.name || ' of ' || v_description, -- XXX: i18n?
				in_measure_sid					=> v_gas_measure_sid,
				in_info_xml						=> v_info_xml,
				in_divisibility					=> v_divisibility,
				in_start_month					=> v_start_month,
				in_ind_type						=> v_ind_type,
				in_aggregate					=> v_aggregate,
				in_is_gas_ind					=> 0,
				in_factor_type_id				=> v_factor_type_id, -- XXX: not required - the C# code uses the factor_type of the parent indicator
				in_gas_measure_sid				=> NULL,
				in_gas_type_id					=> r.gas_type_id,
				in_is_system_managed			=> 1,
				in_target_direction				=> -1
				);
			SetGasCalc(r.ind_sid, v_factor_type_id);
		END LOOP;
	END IF;
END;

FUNCTION GetAggregateDirection(
	in_aggregate	ind.aggregate%TYPE
) RETURN NUMBER
AS
BEGIN
	CASE 
		WHEN in_aggregate IN ('SUM', 'FORCE SUM', 'AVERAGE', 'HIGHEST', 'FORCE HIGHEST', 'LOWEST', 'FORCE LOWEST') THEN RETURN 1;
		WHEN in_aggregate IN ('NONE') THEN RETURN 0;
		WHEN in_aggregate IN ('DOWN', 'FORCE DOWN') THEN RETURN -1;
		ELSE RAISE_APPLICATION_ERROR(-20001, 'Unknown aggregate direction');
	END CASE;
END;

FUNCTION DescribeTargetDirection(
	in_target_direction	NUMBER
) RETURN VARCHAR2
AS
BEGIN
	RETURN CASE in_target_direction WHEN 1 THEN 'More than the target is better' WHEN -1 THEN 'Less than the target is better' ELSE 'Unknown' END;
END;

FUNCTION DescribeDivisibilty(
	in_divisibility	NUMBER
) RETURN VARCHAR2
AS
BEGIN
	RETURN CASE in_divisibility 
		   WHEN 0 THEN 'Indivisible (average)'
		   WHEN 1 THEN 'Divisible'
		   WHEN 2 THEN 'Indivisible (last period)'
		   ELSE 'Unknown' END;
END;

FUNCTION DescribeMonth(
	in_month	NUMBER
) RETURN VARCHAR2
AS
BEGIN
	RETURN CASE in_month 
		   WHEN 1  THEN 'JAN'
		   WHEN 2  THEN 'FEB'
		   WHEN 3  THEN 'MAR'
		   WHEN 4  THEN 'APR'
		   WHEN 5  THEN 'MAY'
		   WHEN 6  THEN 'JUN'
		   WHEN 7  THEN 'JUL'
		   WHEN 8  THEN 'AUG'
		   WHEN 9  THEN 'SEP'
		   WHEN 10 THEN 'OCT'
		   WHEN 11 THEN 'NOV'
		   WHEN 12 THEN 'DEC'
		   ELSE 'Unknown' END;
END;

PROCEDURE ReaggregateIndicator(
	in_ind_sid						IN	ind.ind_sid%TYPE
)
AS
BEGIN
	csr_data_pkg.LockApp(csr_data_pkg.LOCK_TYPE_CALC);

	MERGE /*+ALL_ROWS*/ INTO val_change_log vcl
	USING (SELECT app_sid, ind_sid, MIN(period_start_dtm) period_start_dtm, MAX(period_end_dtm) period_end_dtm
		     FROM val
		    WHERE ind_sid = in_ind_sid
		    GROUP BY app_sid, ind_sid) v
	   ON (v.app_sid = vcl.app_sid AND v.ind_sid = vcl.ind_sid)
	 WHEN MATCHED THEN
		UPDATE 
		   SET vcl.start_dtm = LEAST(vcl.start_dtm, v.period_start_dtm),
			   vcl.end_dtm = GREATEST(vcl.end_dtm, v.period_end_dtm)
	 WHEN NOT MATCHED THEN
		INSERT (vcl.ind_sid, vcl.start_dtm, vcl.end_dtm)
		VALUES (v.ind_sid, v.period_start_dtm, v.period_end_dtm);
END;

/**
 * Amend an existing indicator
 *
 * @param	in_act_id				Access token
 * @param	in_ind_sid				The indicator's SID
 * @param	in_description			Description
 * @param	in_active				1 or 0 (active / inactive)
 * @param	in_lookup_key			Help text
 * @param	in_owner_sid			Owner SID
 * @param	in_measure_sid			The measure that this indicator is associated with.
 * @param	in_multiplier			Multiplier
 * @param	in_scale				Scale
 * @param	in_format_mask			Format mask
 * @param	in_target_direction		Target direction
 * @param	in_gri					GRI
 *
 */
PROCEDURE AmendIndicator(
	in_act_id 						IN	security_pkg.T_ACT_ID				DEFAULT SYS_CONTEXT('SECURITY','ACT'),
	in_ind_sid		 				IN	security_pkg.T_SID_ID,
	in_description 					IN	ind_description.description%TYPE,
	in_active	 					IN	ind.active%TYPE 					DEFAULT 1,
	in_measure_sid					IN	security_pkg.T_SID_ID 				DEFAULT NULL,
	in_multiplier					IN	ind.multiplier%TYPE 				DEFAULT 0,
	in_scale						IN	ind.scale%TYPE 						DEFAULT NULL,
	in_format_mask					IN	ind.format_mask%TYPE				DEFAULT NULL,
	in_target_direction				IN	ind.target_direction%TYPE 			DEFAULT 1,
	in_gri							IN	ind.gri%TYPE						DEFAULT NULL,
	in_pos							IN	ind.pos%TYPE						DEFAULT NULL,
	in_info_xml						IN	ind.info_xml%TYPE					DEFAULT NULL,
	in_divisibility					IN	ind.divisibility%TYPE				DEFAULT NULL,
	in_start_month					IN	ind.start_month%TYPE				DEFAULT 1,
	in_ind_type						IN	ind.ind_type%TYPE					DEFAULT 0,
	in_aggregate					IN	ind.aggregate%TYPE					DEFAULT 'NONE',
	in_is_gas_ind					IN	NUMBER								DEFAULT 0,
	in_factor_type_id				IN	ind.factor_type_id%TYPE				DEFAULT NULL,
	in_gas_measure_sid				IN	security_pkg.T_SID_ID				DEFAULT NULL,
	in_gas_type_id					IN	ind.gas_type_id%TYPE				DEFAULT NULL,
	in_core							IN	ind.core%TYPE						DEFAULT 1,
	in_roll_forward					IN	ind.roll_forward%TYPE				DEFAULT 0,
	in_normalize					IN	ind.normalize%TYPE					DEFAULT 0,
	in_tolerance_type				IN	ind.tolerance_type%TYPE				DEFAULT 0,
	in_pct_upper_tolerance			IN	ind.pct_upper_tolerance%TYPE		DEFAULT 1,
	in_pct_lower_tolerance			IN	ind.pct_lower_tolerance%TYPE		DEFAULT 1,
	in_tolerance_number_of_periods	IN	ind.tolerance_number_of_periods%TYPE	DEFAULT NULL,
	in_tolerance_number_of_standard_deviations_from_average	IN	ind.tolerance_number_of_standard_deviations_from_average%TYPE	DEFAULT NULL,
	in_prop_down_region_tree_sid	IN	ind.prop_down_region_tree_sid%TYPE 	DEFAULT NULL,
	in_is_system_managed			IN	ind.is_system_managed%TYPE			DEFAULT 0,
	in_lookup_key					IN	ind.lookup_key%TYPE					DEFAULT NULL,
	in_calc_output_round_dp			IN	ind.calc_output_round_dp%TYPE		DEFAULT NULL
)
AS
	CURSOR c IS
		SELECT i.description, i.active, i.measure_sid, i.multiplier, i.scale, i.format_mask, i.info_xml, i.gri,
			   i.target_direction, i.pos, i.divisibility actual_divisibility, NVL(i.divisibility, m.divisibility) divisibility, i.start_month,
			   i.ind_type, i.aggregate, i.app_sid, c.ind_info_xml_fields, 
			   NVL(m.description, 'Nothing') measure_description,
			   i.core, i.roll_forward, is_system_managed,
			   NVL(ft.name, 'Nothing') factor_type, NVL(gm.description, 'Nothing') gas_measure,
			   i.prop_down_region_tree_sid, i.factor_type_id, i.calc_output_round_dp,
			   i.tolerance_type, i.pct_upper_tolerance, i.pct_lower_tolerance,
			   i.tolerance_number_of_periods, i.tolerance_number_of_standard_deviations_from_average,
			   i.normalize, i.lookup_key
		  FROM v$ind i
		  JOIN customer c ON i.app_sid = c.app_sid
		  LEFT JOIN measure m ON i.measure_Sid = m.measure_sid
		  LEFT JOIN factor_type ft ON i.factor_type_id = ft.factor_type_id
		  LEFT JOIN measure gm ON i.gas_measure_sid = gm.measure_sid
		 WHERE ind_sid = in_ind_sid;
	r 								c%ROWTYPE;
	v_change						VARCHAR2(1023);
	v_pos							ind.pos%TYPE;
	v_ind_type						ind.ind_type%TYPE;
	v_format_mask					ind.format_mask%TYPE;
	v_scale							ind.scale%TYPE;
	v_new_aggregate_dir				NUMBER(10);
	v_old_aggregate_dir				NUMBER(10);
	v_new_measure_desc				measure.description%TYPE := 'Nothing';
	v_new_factor_type				factor_type.name%TYPE := 'Nothing';
	v_new_gas_measure_desc			measure.description%TYPE := 'Nothing';
	v_job_name						VARCHAR2(200);
	v_trashed_ind_calcs				NUMBER;
BEGIN
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_ind_sid, Csr_Data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied altering schema');
	END IF;
	-- write a log entry descriping the change...
	OPEN c;
	FETCH c INTO r;
	IF c%NOTFOUND THEN
		RETURN;
	END IF;
	
	-- if null pos is passed then keep what we had before
	IF in_pos IS NULL THEN
		v_pos := NVL(r.pos,1);
	ELSE
		v_pos := NVL(in_pos,1);
	END IF;
	
	-- get format mask and scale from measure
	-- update our stuff to NULL if we're the same as the measure (i.e. inherit from measure)
	IF in_measure_sid IS NULL THEN
		-- format mask etc should be null
		v_format_mask := null;
		v_scale := null;
	ELSE
		SELECT format_mask, scale 
		  INTO v_format_mask, v_scale
		  FROM measure
		 WHERE measure_sid = in_measure_sid;
		IF v_format_mask = in_format_mask THEN
			v_format_mask := null;
		ELSE
			v_format_mask := in_format_mask;
		END IF;
		IF v_scale = in_scale THEN
			v_scale := null;
		ELSE
			v_scale := in_scale;
		END IF;
	END IF;
	
	-- TODO: if indicator is used in calculations, then prevent user setting it to be a container (i.e. MEASURE_SID -> NULL)

	-- if the UOM has changed then fix up any data input with conversion factors associated with the old UOM
	IF r.measure_sid != in_measure_sid THEN
		UPDATE val
		   SET entry_measure_conversion_id = NULL,
		   	   entry_val_number = val_number
		 WHERE val_id IN (
			SELECT v.val_id
			  FROM val v, measure_conversion mc
			 WHERE v.entry_measure_conversion_id = mc.measure_conversion_id
			   AND v.ind_sid = in_ind_sid);
			   
		UPDATE sheet_value
		   SET entry_measure_conversion_id = null,
			   entry_val_number = val_number
		 WHERE sheet_value_id IN (
			SELECT sheet_value_id
			  FROM sheet_value sv, measure_conversion mc
			 WHERE sv.app_sid = mc.app_sid AND sv.entry_measure_conversion_id = mc.measure_conversion_id
			   AND sv.ind_sid = in_ind_sid);
		
		UPDATE dataview_ind_member 
		   SET measure_conversion_id = null
		 WHERE ind_sid = in_ind_sid
		   AND measure_conversion_id IS NOT null;
		   
		meter_pkg.IndMeasureSidChanged(in_ind_sid, in_measure_sid);
		
		UPDATE region_metric_val
		   SET entry_measure_conversion_id = NULL,
		   	   entry_val = val
		 WHERE region_metric_val_id IN (
			SELECT rmv.region_metric_val_id
			  FROM region_metric_val rmv
			  JOIN measure_conversion mc ON rmv.entry_measure_conversion_id = mc.measure_conversion_id
			 WHERE rmv.ind_sid = in_ind_sid);
			 
		UPDATE region_metric_val
		   SET measure_sid = in_measure_sid
		 WHERE ind_sid = in_ind_sid;
		 
		UPDATE region_metric
		   SET measure_sid = in_measure_sid
		 WHERE ind_sid = in_ind_sid;
	END IF;

	IF in_ind_type IS NULL THEN
		v_ind_type := r.ind_type; -- no change
	ELSE
		v_ind_type := in_ind_type;
	END IF;
	
	-- reset ind_type if removing UoM
	IF in_measure_sid IS NULL THEN
		v_ind_type := csr_data_pkg.IND_TYPE_NORMAL;
		UPDATE ind 
		   SET calc_xml = null, last_modified_dtm = SYSDATE
		 WHERE ind_sid = in_ind_sid;
	END IF;
	--security_pkg.debugmsg('setting ind type to '||in_ind_type|| ' / ' ||v_ind_type);
	
	-- if aggregation direction has changed then clear old aggregate values etc
	v_old_aggregate_dir := GetAggregateDirection(r.aggregate); -- 1, 0, -1 (up, none, down)
    v_new_aggregate_dir := GetAggregateDirection(in_aggregate); -- 1, 0, -1 (up, none, down)
    
    IF v_old_aggregate_dir != v_new_aggregate_dir THEN
    	-- delete non entered data
    	-- TODO - modify this to use the new source_id 
    	-- TODO: what about stored calculations? shouldn't we use setvalue to trigger recalcs?
    	-- sometimes these are left hooked up
    	UPDATE imp_val
    	   SET set_val_id = NULL 
    	 WHERE set_val_id IN (SELECT val_id
    					    FROM val
    					   WHERE ind_sid = in_ind_sid AND source_type_id = csr_data_pkg.SOURCE_TYPE_AGGREGATOR);
        DELETE FROM val 
         WHERE ind_sid = in_ind_sid
           AND source_type_id = csr_data_pkg.SOURCE_TYPE_AGGREGATOR;
	END IF;

	csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, 
		in_ind_sid, 'Active', r.active, in_active);
	
	IF in_measure_sid IS NOT NULL THEN -- variable defaulted to 'Nothing' anyway so no need to check if null
		SELECT description 
		  INTO v_new_measure_desc 
		  FROM measure 
		 WHERE measure_sid = in_measure_sid;
	END IF;
	
	IF in_factor_type_id IS NOT NULL THEN -- variable defaulted to 'Nothing' anyway so no need to check if null
		SELECT name
		  INTO v_new_factor_type
		  FROM factor_type
		 WHERE factor_type_id = in_factor_type_id;
	END IF;
	
	IF in_gas_measure_sid IS NOT NULL THEN -- variable defaulted to 'Nothing' anyway so no need to check if null
		SELECT description
		  INTO v_new_gas_measure_desc
		  FROM measure
		 WHERE measure_sid = in_gas_measure_sid;
	END IF;

	-- "Use for normalisation" has been deactivated, so remove the indicator from any normalisations 
	IF r.normalize = 1 AND in_normalize = 0 THEN
		UPDATE dataview_ind_member 
		   SET normalization_ind_sid = NULL 
		 WHERE app_sid = r.app_sid
		   AND normalization_ind_sid = in_ind_sid;
	END IF;
	
	csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, 
		in_ind_sid, 'Measure', r.measure_description, v_new_measure_desc);
	csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, 
		in_ind_sid, 'Multiplier', r.multiplier, in_multiplier);
	csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, 
		in_ind_sid, 'Scale', r.scale, v_scale);
	csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, 
		in_ind_sid, 'Format mask', r.format_mask, v_format_mask);
	csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, 
		in_ind_sid, 'GRI', r.gri, in_gri);
	-- No good way to translate these on the way out presently. It looks like there's no translation for the audit log at all.
	csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, 
		in_ind_sid, 'Target direction', DescribeTargetDirection(r.target_direction), DescribeTargetDirection(in_target_direction));
	csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, 
		in_ind_sid, 'Divisibility', DescribeDivisibilty(r.divisibility), DescribeDivisibilty(in_divisibility));
	csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, 
		in_ind_sid, 'Start month', DescribeMonth(r.start_month), DescribeMonth(in_start_month));
	csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, 
		in_ind_sid, 'Aggregation', r.aggregate, in_aggregate);
	csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, 
		in_ind_sid, 'Ind type', r.ind_type, v_ind_type);
	csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, 
		in_ind_sid, 'Ind core', r.core, in_core);
	csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, 
		in_ind_sid, 'Roll forward', r.roll_forward, in_roll_forward);
	csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, 
		in_ind_sid, 'Factor type', r.factor_type, v_new_factor_type);
	csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, 
		in_ind_sid, 'Gas measure', r.gas_measure, v_new_gas_measure_desc);
	csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid,
		in_ind_sid, 'Propagate down region tree sid', r.prop_down_region_tree_sid, in_prop_down_region_tree_sid);
	csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid,
		in_ind_sid, 'Calc output round dp', r.calc_output_round_dp, in_calc_output_round_dp);
	csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid,
		in_ind_sid, 'tolerance type', r.tolerance_type, in_tolerance_type);
	csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid,
		in_ind_sid, 'pct upper tolerance', r.pct_upper_tolerance, in_pct_upper_tolerance);
	csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid,
		in_ind_sid, 'pct lower tolerance', r.pct_lower_tolerance, in_pct_lower_tolerance);
	csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid,
		in_ind_sid, 'tolerance number of periods', r.tolerance_number_of_periods, in_tolerance_number_of_periods);
	csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid,
		in_ind_sid, 'tolerance number of standard deviations from average', r.tolerance_number_of_standard_deviations_from_average, in_tolerance_number_of_standard_deviations_from_average);
	csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid,
		in_ind_sid, 'lookup key', r.lookup_key, in_lookup_key);
	csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid,
		in_ind_sid, 'System Managed', r.is_system_managed, in_is_system_managed);
	csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid,
		in_ind_sid, 'Normalize', r.normalize, in_normalize);
		
	-- info xml
	csr_data_pkg.AuditInfoXmlChanges(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, 
		in_ind_sid, r.ind_info_xml_fields, r.info_xml, in_info_xml);

	IF null_pkg.ne(r.divisibility, in_divisibility) OR in_aggregate != r.aggregate OR null_pkg.ne(in_prop_down_region_tree_sid, r.prop_down_region_tree_sid) OR
	   r.calc_output_round_dp != in_calc_output_round_dp THEN
		-- grr. bung in a bunch of recalc jobs.
		-- First of all, add jobs for this indicator - if we're not a stored calculation this won't do anything
		calc_pkg.addJobsForCalc(in_ind_sid); 
		-- Now add jobs for any stored calculations that use our indicator
		Calc_Pkg.addJobsForInd(in_ind_sid);
	END IF;
		
	-- this should probably just use the description stored against the indicator
	UPDATE form_ind_member 
	   SET description = in_description 
	 WHERE ind_sid = in_ind_sid 
	   AND description = r.description;

	-- TODO: what about: 
	/*
	ALTER TABLE CSR.QUICK_SURVEY_QUESTION ADD CONSTRAINT FK_IND_QSQ 
    FOREIGN KEY (APP_SID, MAPS_TO_IND_SID, MEASURE_SID)
    REFERENCES CSR.IND(APP_SID, IND_SID, MEASURE_SID)
	*/

	-- we don't let them change the name - historical reasons - doesn't matter any more
	--security_pkg.debugmsg('setting ind type to '||in_ind_type|| ' / ' ||v_ind_type||' sid '||in_ind_sid);
	UPDATE ind
	   SET measure_sid = in_measure_sid, active = in_active,
		   info_xml = in_info_xml, scale = v_scale, format_mask = v_format_mask, divisibility = in_divisibility,
		   last_modified_dtm = SYSDATE, gri = in_gri, target_direction = in_target_direction, pos = v_pos,
		   start_month = in_start_month, ind_type = v_ind_type, aggregate = in_aggregate, core = in_core,
		   roll_forward = in_roll_forward, factor_type_id = in_factor_type_id, 
		   gas_measure_sid = in_gas_measure_sid, gas_type_id = in_gas_type_id, normalize = in_normalize,
		   tolerance_type = in_tolerance_type, pct_upper_tolerance = in_pct_upper_tolerance, pct_lower_tolerance = in_pct_lower_tolerance,
		   tolerance_number_of_periods = in_tolerance_number_of_periods,
		   tolerance_number_of_standard_deviations_from_average = in_tolerance_number_of_standard_deviations_from_average,
		   prop_down_region_tree_sid = in_prop_down_region_tree_sid, is_system_managed = in_is_system_managed, lookup_key = in_lookup_key,
		   calc_output_round_dp = in_calc_output_round_dp
 	 WHERE ind_sid = in_ind_sid;
	
	indicator_pkg.setTranslation(in_ind_sid, NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en'), in_description);

    SetGRICodes(r.app_sid, in_ind_sid, in_gri);	

	-- if we changed roll forward, then roll data forward (using a scheduled task
	-- so we don't block forever)
	IF in_roll_forward = 1 AND r.roll_forward = 0 THEN
		/* left for now as a bit fiddly to debug
		-- Note: tried this with STORED_PROCEDURE and set_job_argument_value, but it doesn't
		-- work -- claims that you can only have arguments for a program (docs ambiguous)
		v_job_name := dbms_scheduler.generate_job_name('ROLL_FORWARD_');
		dbms_scheduler.create_job(
			job_name	=> v_job_name,
			job_type	=> 'PLSQL_BLOCK',
			job_action	=> 'csr.indicator_pkg.RollForward(' || in_ind_sid ||');',
			enabled		=> TRUE
		);
		-- TODO: claims this doesn't exist, not investigated yet
		-- job_class	=> 'LOW_PRIORITY_JOB',*/
		RollForward(in_ind_sid);
	END IF;
	
	-- XXX: this seems totally the wrong place for this -- i.e. we don't want to be calling this
	-- needlessly all the time. It seems to be unnecessarily defensive i.e. it assumes stuff is likely
	-- to be screwed up. Can we not use in_factor_type_id rather than in_is_gas_ind instead?
	
	IF in_is_gas_ind != 0 THEN
		CreateGasIndicators(in_ind_sid);
	ELSE
		FOR r IN (SELECT ind_sid FROM ind where map_to_ind_sid = in_ind_sid)
		LOOP
			WITH di AS ( -- get indicator and any child indicators
				SELECT ind_sid
				  FROM csr.ind
					   START WITH ind_sid = r.ind_sid
					   CONNECT BY PRIOR ind_sid = parent_sid),
			ti AS ( -- indicators in the trash
				SELECT ind_sid
				  FROM csr.ind
					   START WITH parent_sid = (SELECT trash_sid FROM csr.customer)
					   CONNECT BY PRIOR ind_sid = parent_sid)
			SELECT COUNT(*)
				  INTO v_trashed_ind_calcs
				  FROM di
			  JOIN csr.v$calc_direct_dependency cd ON di.ind_sid = cd.ind_sid
			  JOIN ti on cd.calc_ind_sid = ti.ind_sid;
			
			IF v_trashed_ind_calcs != 0 THEN
				RAISE_APPLICATION_ERROR(Csr_Data_Pkg.ERR_OBJECT_IN_USE,
				'Cannot trash indicator '||in_ind_sid||' because it is used by a formula');
			END IF;
		
			securableobject_pkg.DeleteSO(SYS_CONTEXT('SECURITY', 'ACT'), r.ind_sid);
		END LOOP;
	END IF;
	
	-- Tell the metering module the indicator has changed (legacy crc core flag support)
	meter_pkg.IndicatorChanged(in_ind_sid);
END;

/**
 * Amend an existing aggregate indicator
 *
 * @param	in_act_id				Access token
 * @param	in_ind_sid				The indicator's SID
 * @param	in_description			Description
 * @param	in_active				1 or 0 (active / inactive)
 * @param	in_scale				Scale
 * @param	in_format_mask			Format mask
 *
 */
PROCEDURE AmendAggregateIndicator(
	in_act_id 						IN	security_pkg.T_ACT_ID				DEFAULT SYS_CONTEXT('SECURITY','ACT'),
	in_ind_sid		 				IN	security_pkg.T_SID_ID,
	in_description 					IN	ind_description.description%TYPE,
	in_active	 					IN	ind.active%TYPE 					DEFAULT 1,
	in_scale						IN	ind.scale%TYPE 						DEFAULT NULL,
	in_format_mask					IN	ind.format_mask%TYPE				DEFAULT NULL	
)
AS
	v_ind_type						ind.ind_type%type;
	v_is_system_managed				ind.is_system_managed%type;
BEGIN
	
	SELECT ind_type, is_system_managed
	  INTO v_ind_type, v_is_system_managed	
	  FROM ind
	 WHERE ind_sid = in_ind_sid;
	
	IF v_is_system_managed = 1 AND v_ind_type = csr_data_pkg.IND_TYPE_AGGREGATE THEN
		-- Why is this a loop, how can there be more than one??
		FOR r in (SELECT * from ind where ind_sid = in_ind_sid) LOOP
			indicator_pkg.AmendIndicator(
				in_ind_sid		 				=> in_ind_sid,
				in_description 					=> in_description,
				in_active	 					=> in_active,
				in_measure_sid					=> r.measure_sid,
				in_multiplier					=> r.multiplier,
				in_scale						=> in_scale,
				in_format_mask					=> in_format_mask,
				in_target_direction				=> r.target_direction,
				in_gri							=> r.gri,
				in_pos							=> r.pos,
				in_info_xml						=> r.info_xml,
				in_divisibility					=> r.divisibility,
				in_start_month					=> r.start_month,
				in_ind_type						=> r.ind_type,
				in_aggregate					=> r.aggregate,
				in_is_gas_ind					=> CASE WHEN r.factor_type_id IS NOT NULL THEN 1 ELSE 0 END,
				in_factor_type_id				=> r.factor_type_id,
				in_gas_measure_sid				=> r.gas_measure_sid,
				in_gas_type_id					=> r.gas_type_id,
				in_core							=> r.core,
				in_roll_forward					=> r.roll_forward,
				in_normalize					=> r.normalize,
				in_prop_down_region_tree_sid	=> r.prop_down_region_tree_sid,
				in_is_system_managed			=> r.is_system_managed,
				in_lookup_key					=> r.lookup_key,
				in_calc_output_round_dp			=> r.calc_output_round_dp);	
		END LOOP;
	END IF;
END;

PROCEDURE SetAggregateIndicator(
	in_act_id 						IN	security_pkg.T_ACT_ID				DEFAULT SYS_CONTEXT('SECURITY','ACT'),
	in_ind_sid		 				IN	security_pkg.T_SID_ID,
	in_is_aggregate_ind				IN  ind.is_system_managed%TYPE
)
AS
	v_ind_type	ind.ind_type%TYPE;
	CURSOR c IS
		SELECT i.description, i.active, i.measure_sid, i.multiplier, i.scale, i.format_mask, i.info_xml, i.gri,
			   i.target_direction, i.pos, NVL(i.divisibility, m.divisibility) divisibility, i.start_month,
			   i.aggregate, i.factor_type_id, i.gas_measure_sid, i.gas_type_id, i.core, i.roll_forward, i.normalize,
			   i.tolerance_type, i.pct_upper_tolerance, i.pct_lower_tolerance,
			   i.tolerance_number_of_periods, i.tolerance_number_of_standard_deviations_from_average,
			   i.prop_down_region_tree_sid, i.lookup_key, i.calc_output_round_dp
		  FROM v$ind i
		  JOIN customer c ON i.app_sid = c.app_sid
		  LEFT JOIN measure m ON i.measure_Sid = m.measure_sid
		  LEFT JOIN factor_type ft ON i.factor_type_id = ft.factor_type_id
		  LEFT JOIN measure gm ON i.gas_measure_sid = gm.measure_sid
		 WHERE ind_sid = in_ind_sid;
	r 	c%ROWTYPE;
BEGIN
	IF in_is_aggregate_ind = 0 THEN
		v_ind_type := 0;
	ELSE
		v_ind_type := 3;
	END IF;

	OPEN c;
	FETCH c INTO r;
	IF c%NOTFOUND THEN
		RETURN;
	END IF;
	
	AmendIndicator(
		in_act_id 						=> in_act_id,
		in_ind_sid		 				=> in_ind_sid,
		in_description 					=> r.description,
		in_active	 					=> r.active,
		in_measure_sid					=> r.measure_sid,
		in_multiplier					=> r.multiplier,
		in_scale						=> r.scale,
		in_format_mask					=> r.format_mask,
		in_target_direction				=> r.target_direction,
		in_gri							=> r.gri,
		in_pos							=> r.pos,
		in_info_xml						=> r.info_xml,
		in_divisibility					=> r.divisibility,
		in_start_month					=> r.start_month,
		in_ind_type						=> v_ind_type,
		in_aggregate					=> r.aggregate,
		in_factor_type_id				=> r.factor_type_id,
		in_gas_measure_sid				=> r.gas_measure_sid,
		in_gas_type_id					=> r.gas_type_id,
		in_core							=> r.core,
		in_roll_forward					=> r.roll_forward,
		in_normalize					=> r.normalize,
		in_tolerance_type				=> r.tolerance_type,
		in_pct_upper_tolerance			=> r.pct_upper_tolerance,
		in_pct_lower_tolerance			=> r.pct_lower_tolerance,
		in_tolerance_number_of_periods	=> r.tolerance_number_of_periods,
		in_tolerance_number_of_standard_deviations_from_average	=>	r.tolerance_number_of_standard_deviations_from_average,
		in_prop_down_region_tree_sid	=> r.prop_down_region_tree_sid,
		in_is_system_managed			=> in_is_aggregate_ind,
		in_lookup_key					=> r.lookup_key,
		in_calc_output_round_dp			=> r.calc_output_round_dp
	);
END;

PROCEDURE SetLookupKey(
	in_ind_sid				IN	ind.ind_sid%TYPE,
	in_new_lookup_key		IN	ind.lookup_key%TYPE
)
AS
	v_old_lookup_key			ind.lookup_key%TYPE;
BEGIN

	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_ind_sid, Csr_Data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied altering schema');
	END IF;
	
	SELECT lookup_key
	  INTO v_old_lookup_key
	  FROM ind
	 WHERE ind_sid = in_ind_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	csr_data_pkg.AuditValueChange(SYS_CONTEXT('SECURITY', 'ACT'), 
		csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, SYS_CONTEXT('SECURITY', 'APP'), in_ind_sid, 
		'lookup key', v_old_lookup_key, in_new_lookup_key);
	
	UPDATE ind
	   SET lookup_key = in_new_lookup_key
	 WHERE ind_sid = in_ind_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

-- useful for scripting purposes
PROCEDURE RenameIndicator(
	in_ind_sid		 				IN	security_pkg.T_SID_ID,
	in_description 					IN	ind_description.description%TYPE
)
AS
	CURSOR c IS
		SELECT app_sid, description
		  FROM v$ind
		 WHERE ind_sid = in_ind_sid;
	r c%ROWTYPE;
BEGIN
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_ind_sid, Csr_Data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied altering schema');
	END IF;

	-- write a log entry descriping the change...
	OPEN c;
	FETCH c INTO r;
	IF c%NOTFOUND THEN
		RETURN;
	END IF;
	
	csr_data_pkg.AuditValueChange(security_pkg.GetACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, 
		in_ind_sid, 'Description', r.description, in_description);

	UPDATE form_ind_member 
	   SET description = in_description 
	 WHERE ind_sid = in_ind_sid 
	   AND description = r.description;

	indicator_pkg.setTranslation(in_ind_sid, NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en'), in_description);
	
END;

PROCEDURE SetTranslationAndUpdateGasChildren(
	in_ind_sid		IN 	security_pkg.T_SID_ID,
	in_lang			IN	aspen2.tr_pkg.T_LANG,
	in_description	IN	VARCHAR2
)
AS
	v_gas_measure_sid	security_pkg.T_SID_ID;
BEGIN
	SELECT gas_measure_sid
	  INTO v_gas_measure_sid
	  FROM csr.ind i
	 WHERE i.ind_sid = in_ind_sid;

	SetTranslation(
		in_ind_sid		=> in_ind_sid,
		in_lang			=> in_lang,
		in_translated	=> in_description
	);

	FOR item IN (
		SELECT i.ind_sid, i.parent_sid, i.ind_type, i.gas_measure_sid, gt.name gas_type_name, d.description old_desc
		  FROM csr.ind i
		  JOIN csr.gas_type gt ON i.gas_type_id = gt.gas_type_id
		  LEFT JOIN csr.ind_description d ON i.ind_sid = d.ind_sid AND d.lang = in_lang
		 WHERE i.parent_sid = in_ind_sid
		 ORDER BY i.ind_sid)
	LOOP
		SetTranslation(
			in_ind_sid		=> item.ind_sid,
			in_lang			=> in_lang,
			in_translated	=> item.gas_type_name || ' of ' || in_description
		);
	END LOOP;
END;

PROCEDURE SetExtraInfoValue(
	in_act		IN	security_pkg.T_ACT_ID,
	in_ind_sid	IN	security_pkg.T_SID_ID,
	in_key		IN	VARCHAR2,		
	in_value	IN	VARCHAR2
)
AS
	v_path 			VARCHAR2(255) := '/fields/field[@name="'||in_key||'"]';
	v_new_node 		VARCHAR2(3000) := '<field name="'||in_key||'">'||htf.escape_sc(in_value)||'</field>';
	v_app_sid	security_pkg.T_SID_ID;
BEGIN
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(in_act, in_ind_sid, Csr_Data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied altering indicator');
	END IF;
	
	UPDATE IND
	   SET INFO_XML = 
			CASE
				WHEN info_xml IS NULL THEN
					APPENDCHILDXML(XMLType('<fields/>'), '/fields',  XmlType(v_new_node))
		    	WHEN EXISTSNODE(info_xml, v_path||'/text()') = 1 THEN
		    		UPDATEXML(info_xml, v_path||'/text()', htf.escape_sc(in_value))
		    	WHEN EXISTSNODE(info_xml, v_path) = 1 THEN
		    		UPDATEXML(info_xml, v_path, XmlType(v_new_node))
		    	ELSE
		    		APPENDCHILDXML(info_xml, '/fields', XmlType(v_new_node))
			END,
		  LAST_MODIFIED_DTM = SYSDATE
	WHERE ind_sid = in_ind_sid
	RETURNING app_sid INTO v_app_sid;
	
	csr_data_pkg.WriteAuditLogEntry(in_act, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, v_app_sid, in_ind_sid, 'Set {0} to {1}', in_key, in_value);
END;

/**
 * Bind an indicator to a measure.
 *
 * @param	in_act_id				Access token
 * @param	in_ind_sid				The indicator
 * @param	in_measure_sid			The measure that this indicator is associated with
 *
 */
PROCEDURE BindToMeasure(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_ind_sid				IN security_pkg.T_SID_ID,
	in_measure_sid			IN security_pkg.T_SID_ID
)
AS
	v_measure_sid			   security_pkg.T_SID_ID;
BEGIN
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_ind_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on the indicator with sid '||in_ind_sid);
	END IF;
	
	SELECT measure_sid
	  INTO v_measure_sid
	  FROM ind
	 WHERE ind_sid = in_ind_sid;
	
	IF v_measure_sid != in_measure_sid THEN
		UPDATE dataview_ind_member
		   SET measure_conversion_id = NULL
		 WHERE ind_sid = in_ind_sid
		   AND measure_conversion_id IS NOT null;

		UPDATE ind
		   SET measure_sid = in_measure_sid, last_modified_dtm = SYSDATE
		 WHERE ind_sid = in_ind_sid;
	END IF;
END;

-- Securable object callbacks
PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
)
AS
BEGIN
	-- Should be called via the Create method
	NULL;
END;

PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
)
AS
BEGIN
	NULL;
END;

-- no security, private function only used by this package
PROCEDURE FixStartPointsForDeletion(
	in_ind_sid						IN security_pkg.T_SID_ID
)
AS
    v_start_points					security_pkg.T_SID_IDS;	
	v_cnt							NUMBER;
BEGIN
	-- We can't delete this indicator if it's an active user's start point.
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM ind_start_point 
	 WHERE ind_sid = in_ind_sid
	   AND ind_sid IN (
			SELECT sid_id
			  FROM security.securable_object
				   START WITH parent_sid_id = (SELECT trash_sid FROM customer)
				   CONNECT BY PRIOR sid_id = parent_sid_id);
	IF v_cnt > 0 THEN
		RAISE_APPLICATION_ERROR(Csr_Data_Pkg.ERR_OBJECT_IS_MOUNT_POINT,
			'Cannot delete indicator '||in_ind_sid||' because it is used by one or more users as a start point');
	END IF;

	-- Don't allow trashed users to keep this indicator as a start point.
	FOR r IN (SELECT user_sid
				FROM ind_start_point
			   WHERE ind_sid = in_ind_sid) LOOP

		SELECT ind_sid
		  BULK COLLECT INTO v_start_points
		  FROM ind_start_point
		 WHERE user_sid = r.user_sid
		   AND ind_sid != in_ind_sid;

		csr_user_pkg.SetIndStartPoints(r.user_sid, v_start_points);
	END LOOP;
END;

PROCEDURE DeleteObject(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_sid_id						IN security_pkg.T_SID_ID
)
AS
	v_app_sid						security_pkg.T_SID_ID;
	v_mandatory						NUMBER;
	v_ind_type						ind.ind_type%TYPE;
BEGIN
	BEGIN
		SELECT ind_type
		  INTO v_ind_type
		  FROM ind
		 WHERE ind_sid = in_sid_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN NULL;
	END;

	FixStartPointsForDeletion(in_sid_id);

	-- we should probably call the nice handler thingy but this might
	-- involve a lot of calls, so just unhook stuff manually for now
	UPDATE imp_val
	   SET set_val_id = NULL
	 WHERE (app_sid, set_val_id) IN (
	 		SELECT app_sid, val_id 
	 		  FROM val 
	 		 WHERE ind_sid = in_sid_id);

	UPDATE val 
	   SET source_id = NULL
	 WHERE source_id IN (
	 		SELECT source_id 
	 		  FROM val 
	 		 WHERE ind_sid = in_sid_id);

	UPDATE imp_ind 
	   SET maps_to_ind_sid = NULL
	 WHERE maps_to_ind_sid = in_sid_id;

	IF Calc_Pkg.IsIndicatorCritical(in_sid_id) THEN
		RAISE_APPLICATION_ERROR(Csr_Data_Pkg.ERR_OBJECT_IN_USE,
		'Cannot delete indicator '||in_sid_id||' because it is used by a formula');
	ELSE
		IF v_ind_type IS NOT NULL THEN
			-- add some recalc jobs for formulae which depend on us
			Calc_Pkg.AddJobsForInd(in_sid_id);
		END IF;
	END IF;
	
	-- write to audit log
	IF v_ind_type IS NOT NULL THEN
		SELECT i.app_sid
		  INTO v_app_sid
		  FROM ind i
		 WHERE i.ind_sid = in_sid_id ;

		csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, v_app_sid, in_sid_id,
			'Deleted "{0}"', INTERNAL_GetIndPathString(in_sid_id));
	ELSE
		SELECT so.application_sid_id
		  INTO v_app_sid
		  FROM security.securable_object so
		 WHERE so.sid_id = in_sid_id ;

		csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, v_app_sid, in_sid_id,
			'Deleted SO "{0}"', securableObject_pkg.GetPathFromSid(in_act_id, in_sid_id));
	END IF;
		
	-- we need to set our audit log object_sid to null due to FK constraint
	update audit_log set object_sid = null where object_sid = in_sid_id;

	-- Meter -> ind associations
	FOR m IN (
		SELECT meter_type_id, meter_input_id, aggregator
		  FROM meter_type_input
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND ind_sid = in_sid_id
	) LOOP
		SELECT is_mandatory
		  INTO v_mandatory
		  FROM meter_input_aggregator
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND meter_input_id = m.meter_input_id
		   AND aggregator = m.aggregator;

		IF v_mandatory = 1 THEN

			-- Mandatory indicator deleted 
			FOR r IN (
				SELECT region_sid
				  FROM meter_input_aggr_ind
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND meter_input_id = m.meter_input_id
				   AND aggregator = m.aggregator
				   AND meter_type_id = m.meter_type_id
			) LOOP
				UPDATE region
				   SET region_type = csr_data_pkg.REGION_TYPE_NORMAL
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND region_sid = r.region_sid;

				UPDATE all_meter 
				   SET active = 0
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND region_sid = r.region_sid;

				DELETE FROM meter_input_aggr_ind
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND region_sid = r.region_sid;
			END LOOP;
		ELSE
			-- The indicaotr was not mandatory
			UPDATE meter_input_aggr_ind
			   SET measure_sid = NULL,
			       measure_conversion_id = NULL
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND meter_input_id = m.meter_input_id
			   AND aggregator = m.aggregator;
		END IF;
	END LOOP;

	UPDATE meter_type_input
	   SET ind_sid = NULL,
	       measure_sid = NULL
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND ind_sid = in_sid_id;

	UPDATE meter_type
	   SET days_ind_sid = NULL
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND days_ind_sid = in_sid_id;

	UPDATE meter_type
	   SET costdays_ind_sid = NULL
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND costdays_ind_sid = in_sid_id;

	-- text section thing
	DELETE FROM attachment_history 
	 WHERE attachment_id IN (
	 		SELECT attachment_id 
	 		  FROM attachment 
	 		 WHERE indicator_sid = in_sid_id);

	DELETE FROM attachment 
	 WHERE indicator_sid = in_sid_Id;

	-- watch out!! this will delete all associated values!
	UPDATE imp_ind 
	   SET maps_to_ind_sid = NULL 
	 WHERE maps_to_ind_sid = in_sid_id;

	DELETE FROM val_change_log
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND ind_sid = in_sid_id;

	DELETE FROM sheet_val_change_log 
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND ind_sid = in_sid_id;

	DELETE FROM calc_dependency 
	 WHERE ind_sid = in_sid_id;

	DELETE FROM calc_dependency 
	 WHERE calc_ind_sid = in_sid_id;

	DELETE FROM calc_tag_dependency
	 WHERE calc_ind_sid = in_sid_id;

	DELETE FROM calc_baseline_config_dependency
	 WHERE calc_ind_sid = in_sid_id;

	DELETE FROM ind_validation_rule
	 WHERE ind_sid = in_sid_id;
	 
	DELETE FROM aggregate_ind_group_member
	 WHERE ind_sid = in_sid_id;
	 
	DELETE FROM delegation_grid_aggregate_ind
	 WHERE ind_sid = in_sid_id OR aggregate_to_ind_sid = in_sid_id;

	DELETE FROM dashboard_item 
	 WHERE ind_sid = in_sid_id;
	 
	DELETE FROM target_dashboard_ind_member
	 WHERE target_ind_sid = in_sid_id OR ind_sid = in_sid_id;

	DELETE FROM target_dashboard_reg_member
	 WHERE region_sid = in_sid_id;

	DELETE FROM metric_dashboard_ind 
	 WHERE ind_sid = in_sid_id; 
	
	DELETE FROM metric_dashboard_ind 
	 WHERE inten_view_floor_area_ind_sid = in_sid_id; 
	
	DELETE FROM benchmark_dashboard_ind 
	 WHERE ind_sid = in_sid_id; 
	
	DELETE FROM benchmark_dashboard_ind 
	 WHERE floor_area_ind_sid = in_sid_id; 

	DELETE FROM benchmark_dashboard_char
	 WHERE ind_sid = in_sid_id;

	DELETE FROM form_ind_member 
	 WHERE ind_sid = in_sid_id;

	-- delegations
	FOR r IN (
		SELECT sheet_value_id FROM sheet_value WHERE ind_sid = in_sid_id
	)
	LOOP
		sheet_pkg.INTERNAL_DeleteSheetValue(r.sheet_value_id);
	END LOOP;

	DELETE FROM delegation_ind_cond_action 
	 WHERE ind_sid = in_sid_id;
	
	DELETE FROM delegation_ind_cond_action 
	 WHERE delegation_ind_cond_id IN (
		SELECT delegation_ind_cond_id 
		  FROM delegation_ind_cond
		 WHERE ind_sid = in_sid_id
	 );
	
	DELETE FROM delegation_ind_tag
	 WHERE ind_sid = in_sid_id;
	
	DELETE FROM deleg_ind_form_expr
	 WHERE ind_sid = in_sid_id;
		   
	DELETE FROM deleg_ind_group_member
	 WHERE ind_sid = in_sid_id;
	
	DELETE FROM delegation_ind_description
	 WHERE ind_sid = in_sid_id;

	DELETE FROM delegation_ind 
	 WHERE ind_sid = in_sid_id;

	DELETE FROM val_note 
	 WHERE ind_sid = in_sid_id;

	DELETE FROM val_file
	 WHERE val_id IN (
	 	SELECT val_id
	 	  FROM val
	 	 WHERE ind_sid = in_sid_id);

	DELETE FROM val 
	 WHERE ind_sid = in_sid_id;

	DELETE FROM val_change 
	 WHERE ind_sid = in_sid_id;

	DELETE FROM scenario_run_val
	 WHERE ind_sid = in_sid_id;

	DELETE FROM ind_window 
	 WHERE ind_sid = in_sid_id;

	DELETE FROM ind_start_point 
	 WHERE ind_sid = in_sid_id;

	DELETE FROM ind_flag 
	 WHERE ind_sid = in_sid_id;

	DELETE FROM ind_tag 
	 WHERE ind_sid = in_sid_id;

	DELETE FROM scenario_ind
	 WHERE ind_sid = in_sid_id;

	DELETE FROM dataview_ind_description
	 WHERE (app_sid, dataview_sid, pos) IN (
	 		SELECT app_sid, dataview_sid, pos
	 		  FROM dataview_ind_member
	 		 WHERE ind_sid = in_sid_id);

	DELETE FROM dataview_ind_member
	 WHERE ind_sid = in_sid_id;
	
	DELETE FROM delegation_grid
	 WHERE ind_sid = in_sid_id;
	 
	UPDATE issue
	   SET issue_sheet_value_id = NULL
	 WHERE issue_sheet_value_id IN (SELECT issue_sheet_value_id
	 								  FROM issue_sheet_value
	 								 WHERE ind_sid = in_sid_id);

	DELETE FROM snapshot_ind
     WHERE ind_sid = in_sid_id;
     
	DELETE FROM issue_sheet_value
	 WHERE ind_sid = in_sid_id;

	DELETE FROM img_chart_ind
	 WHERE ind_sid = in_sid_id;

	DELETE FROM calc_job_ind
	 WHERE ind_sid = in_sid_id;
	
	DELETE FROM ind_description
	 WHERE ind_sid = in_sid_id;
	
	UPDATE quick_survey
	   SET root_ind_sid = NULL
	 WHERE root_ind_sid = in_sid_id;
	 
	 UPDATE quick_survey_answer
	   SET measure_sid = NULL
	 WHERE question_id IN (
	 	SELECT question_id
	 	  FROM quick_survey_question
	 	 WHERE maps_to_ind_sid = in_sid_id
	 );
	
	UPDATE quick_survey_question
	   SET maps_to_ind_sid = NULL, measure_sid = NULL
	 WHERE maps_to_ind_sid = in_sid_id;
	
	UPDATE qs_question_option
	   SET maps_to_ind_sid = NULL
	 WHERE maps_to_ind_sid = in_sid_id;
	
	UPDATE quick_survey_score_threshold
	   SET maps_to_ind_sid = NULL
	 WHERE maps_to_ind_sid = in_sid_id;
	
	UPDATE score_threshold
	   SET supplier_score_ind_sid = NULL
	 WHERE supplier_score_ind_sid = in_sid_id;

	-- Need to update imp_val before deleting from region_metric_val
	UPDATE imp_val
	   SET set_region_metric_val_id = NULL
	 WHERE set_region_metric_val_id IN (
	 	SELECT region_metric_val_id
	 	  FROM region_metric_val
	 	 WHERE ind_sid = in_sid_id);
	
	DELETE FROM property_element_layout
	 WHERE ind_sid = in_sid_id;
	
	DELETE FROM property_character_layout
	 WHERE ind_sid = in_sid_id;
	
	DELETE FROM meter_element_layout
	 WHERE ind_sid = in_sid_id;
	
	DELETE FROM meter_header_element
	 WHERE ind_sid = in_sid_id;
	
	DELETE FROM region_metric_val
	 WHERE ind_sid = in_sid_id;
	 
	DELETE FROM region_type_metric
	 WHERE ind_sid = in_sid_id;
	 
	DELETE FROM region_metric
	 WHERE ind_sid = in_sid_id;
	
	DELETE FROM ind_set_ind
	  WHERE ind_sid = in_sid_id;

	UPDATE flow_state
	   SET ind_sid = NULL
	 WHERE ind_sid = in_sid_id;
	
	DELETE FROM target_dashboard_ind_member
	 WHERE ind_sid = in_sid_id;

	DELETE FROM imp_conflict_val
	 WHERE imp_conflict_id IN (SELECT imp_conflict_id
								 FROM imp_conflict
								WHERE ind_sid = in_sid_id);

	DELETE FROM imp_conflict
	 WHERE ind_sid = in_sid_id;
	 
	DELETE FROM dataview_zone
	 WHERE start_val_ind_sid = in_sid_id
		OR end_val_ind_sid = in_sid_id;

	DELETE FROM ind_sel_group_member_desc
	 WHERE ind_sid = in_sid_id;
		
	DELETE FROM ind_selection_group_member
	 WHERE ind_sid = in_sid_id;

	DELETE FROM ind_selection_group
	 WHERE master_ind_sid = in_sid_id;

    DELETE FROM model_instance_map
	 WHERE map_to_indicator_sid = in_sid_id;

    DELETE FROM model_map
	 WHERE map_to_indicator_sid = in_sid_id;
	
	DELETE FROM auto_imp_indicator_map
	 WHERE ind_sid = in_sid_id;
	
	UPDATE flow_state
	   SET time_spent_ind_sid = NULL
	 WHERE time_spent_ind_sid = in_sid_id;

	DELETE FROM tpl_report_tag_eval_cond
	 WHERE left_ind_sid = in_sid_id;

	DELETE FROM tpl_report_tag_eval_cond
	 WHERE right_ind_sid = in_sid_id;
	
	DELETE FROM gresb_indicator_mapping
	 WHERE ind_sid = in_sid_id;
	
	DELETE FROM csr.data_bucket_val
	 WHERE ind_sid = in_sid_id;
	
	DELETE FROM ind 
	 WHERE ind_sid = in_sid_id;
END;

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
)
AS
BEGIN
	-- add jobs to recompute any sum of children calcs that depend on this ind's old parent	
	Calc_Pkg.AddJobsForInd(in_sid_id);

	UPDATE ind
	   SET parent_sid = in_new_parent_sid_id, last_modified_dtm = SYSDATE
	 WHERE ind_sid = in_sid_id;
	
	-- check for circular calcs e.g. if the parent indicator is "Sum of children"
	csr.calc_pkg.CheckCircularDependencies(in_sid_id);
	 
	csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, SYS_CONTEXT('SECURITY', 'APP'), in_sid_id,
		'Moved under "{0}"', 
		INTERNAL_GetIndPathString(in_new_parent_sid_id));

	-- add jobs to recompute any sum of children calcs that depend on this ind's new parent
	Calc_Pkg.AddJobsForInd(in_sid_id);
END;

PROCEDURE GetTrashBlockers(
	in_ind_sid						IN	ind.ind_sid%TYPE,
	out_calc_cur					OUT	SYS_REFCURSOR,	
	out_user_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_ind_sid, security_pkg.PERMISSION_DELETE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on the indicator with sid '||in_ind_sid);
	END IF;

	OPEN out_calc_cur FOR
		WITH di AS ( -- indicators being deleted
			SELECT ind_sid
			  FROM csr.ind
				   START WITH ind_sid = in_ind_sid
				   CONNECT BY PRIOR ind_sid = parent_sid),
		ti AS ( -- indicators in the trash
			SELECT ind_sid
			  FROM csr.ind
			       START WITH parent_sid = (SELECT trash_sid FROM csr.customer)
				   CONNECT BY PRIOR ind_sid = parent_sid)
			SELECT ci.ind_sid calc_ind_sid, ci.description calc_ind_description,
				   i.ind_sid, i.description ind_description
			  FROM di, v$calc_direct_dependency cd, v$ind i, v$ind ci
			 WHERE di.ind_sid = cd.ind_sid -- indicators depending on the indicator to be trashed
			   AND cd.app_sid = i.app_sid AND cd.ind_sid = i.ind_sid
			   AND cd.app_sid = ci.app_sid AND cd.calc_ind_sid = ci.ind_sid
			   AND cd.calc_ind_sid NOT IN ( -- that aren't themselves being trashed or in the trash
			   		SELECT ind_sid 
			   		  FROM di 
			   		 UNION ALL 
			   		SELECT ind_sid 
			   		  FROM ti);
			   		  
	OPEN out_user_cur FOR
		SELECT isp.user_sid, cu.full_name, cu.email
		  FROM ind_start_point isp, csr_user cu
		 WHERE isp.ind_sid IN (
		 		SELECT ind_sid
		 		  FROM ind
		 		 	   START WITH ind_sid = in_ind_sid
		 		 	   CONNECT BY PRIOR ind_sid = parent_sid)
		   AND isp.user_sid NOT IN (
		   		SELECT sid_id
		   		  FROM security.securable_object
		   		  	   START WITH parent_sid_id = (SELECT trash_sid FROM customer)
		   		  	   CONNECT BY PRIOR sid_id = parent_sid_id)
		   AND isp.app_sid = cu.app_sid AND isp.user_sid = cu.csr_user_sid;
END;

PROCEDURE TrashObject(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_ind_sid						IN 	security_pkg.T_SID_ID
)
AS
	v_description					ind_description.description%TYPE;
	v_app_sid						security_pkg.T_SID_ID;
	v_cnt							NUMBER;
BEGIN
	FixStartPointsForDeletion(in_ind_sid);

	-- Check if trashing this indicator would leave any indicators in the main 
	-- tree that depend on the indicator tree we are trashing
	WITH di AS ( -- indicators being deleted
		SELECT ind_sid
		  FROM ind
			   START WITH ind_sid = in_ind_sid
			   CONNECT BY PRIOR ind_sid = parent_sid),
	ti AS ( -- indicators in the trash
		SELECT ind_sid
		  FROM ind
		       START WITH parent_sid = (SELECT trash_sid FROM customer)
			   CONNECT BY PRIOR ind_sid = parent_sid)
		SELECT COUNT(*)
		  INTO v_cnt
		  FROM di, v$calc_direct_dependency cd
		 WHERE di.ind_sid = cd.ind_sid -- indicators depending on the indicator to be trashed
		   AND cd.calc_ind_sid NOT IN ( -- that aren't themselves being trashed or in the trash
		   		SELECT ind_sid 
		   		  FROM di 
		   		 UNION ALL 
		   		SELECT ind_sid 
		   		  FROM ti)
		   AND cd.dep_type != csr_data_pkg.DEP_ON_CHILDREN; -- trashing children is ok

	IF v_cnt != 0 THEN
		RAISE_APPLICATION_ERROR(Csr_Data_Pkg.ERR_OBJECT_IN_USE,
			'Cannot trash indicator '||in_ind_sid||' because it is used by a formula');
	END IF;

	-- get name and sid
	SELECT description, app_sid
	  INTO v_description, v_app_sid
	  FROM v$ind 
	 WHERE ind_sid = in_ind_sid;

	-- Remove the indicator from any normalisations
	UPDATE dataview_ind_member 
	   SET normalization_ind_sid = NULL 
	 WHERE normalization_ind_sid IN (	
		SELECT ind_sid
		  FROM ind 
	    CONNECT BY PRIOR ind_sid = parent_sid
		 START WITH ind_sid = in_ind_sid );

	-- deactivate this and all children
	UPDATE ind
	   SET active = 0, last_modified_dtm = SYSDATE
	 WHERE ind_sid IN (
			SELECT ind_sid
	 		  FROM ind 
	 			   CONNECT BY PRIOR app_sid = app_sid AND PRIOR ind_sid = parent_sid
				   START WITH ind_sid = in_ind_sid);

	csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, v_app_sid, in_ind_sid,
		'Moved "{0}" to trash', INTERNAL_GetIndPathString(in_ind_sid));
		
	trash_pkg.TrashObject(in_act_id, in_ind_sid, 
		securableobject_pkg.GetSIDFromPath(in_act_id, v_app_sid, 'Trash'),
		v_description);
END;

PROCEDURE RestoreFromTrash(
	in_object_sids					IN	security.T_SID_TABLE
)
AS
	v_exists						NUMBER;
BEGIN
	WITH ri AS ( -- indicators being restored
		SELECT ind_sid
		  FROM ind
			   START WITH ind_sid IN (SELECT column_value FROM TABLE(in_object_sids))
			   CONNECT BY PRIOR ind_sid = parent_sid),
	ti AS ( -- indicators in the trash
		SELECT ind_sid
		  FROM ind
		       START WITH parent_sid = (SELECT trash_sid FROM customer)
			   CONNECT BY PRIOR ind_sid = parent_sid)

		-- find indicators being restored that depend on indicators in the trash
		-- that aren't themselves being restored
		SELECT COUNT(*)
		  INTO v_exists
		  FROM ri r1, v$calc_direct_dependency cd, ti
		 WHERE r1.ind_sid = cd.calc_ind_sid
		   AND cd.ind_sid = ti.ind_sid	   
		   AND cd.ind_sid NOT IN (SELECT ind_sid FROM ri);

	IF v_exists > 0 THEN
		RAISE_APPLICATION_ERROR(Csr_Data_Pkg.ERR_CALC_USING_IND_IN_TRASH,
			'Cannot restore one or more indicators because '||
			'they have formulae that rely on trashed indicators');
	END IF;
	
	-- mark the restored indicators active again
	UPDATE ind
	   SET active = 1
	 WHERE ind_sid IN (SELECT ind_sid
	 					 FROM ind
	 					 	  START WITH ind_sid IN (SELECT column_value FROM TABLE(in_object_sids))
	 					 	  CONNECT BY PRIOR ind_sid = parent_sid);
END;

-- there seem to be tons of these! this one is for UI/visual purposes
-- so returns stuff like the ind path
PROCEDURE GetDependencies(
	in_act			IN	security_pkg.T_ACT_ID,
	in_ind_sid		IN	security_pkg.T_SID_ID,
	out_calcs		OUT	SYS_REFCURSOR,
	out_delegations	OUT	SYS_REFCURSOR
)
AS
	v_some_delegs		security.T_SID_TABLE;
BEGIN
	OPEN out_calcs FOR
		SELECT ci.ind_type, ci.ind_sid, ci.description, indicator_pkg.INTERNAL_GetIndPathString(ci.ind_sid) path
		  FROM calc_dependency cd, v$ind ci
		 WHERE cd.dep_type = csr_data_pkg.DEP_ON_INDICATOR
		   AND cd.calc_ind_sid = ci.ind_sid
		   AND cd.ind_sid = in_ind_sid
		   AND ci.active = 1
		   AND security_pkg.SQL_IsAccessAllowedSID(in_act, ci.ind_sid, security_pkg.PERMISSION_READ) = 1
		 UNION
		SELECT ci.ind_type, ci.ind_sid, ci.description, indicator_pkg.INTERNAL_GetIndPathString(ci.ind_sid) path
		  FROM calc_dependency cd, v$ind ci, v$ind i
		 WHERE cd.dep_type = csr_data_pkg.DEP_ON_CHILDREN
		   AND cd.calc_ind_sid = ci.ind_sid
		   AND cd.ind_sid = i.parent_sid
		   AND i.ind_sid = in_ind_sid
		   AND ci.active = 1
		   AND ci.measure_sid IS NOT NULL -- don't fetch things if we have no unit of measure
		   AND security_pkg.SQL_IsAccessAllowedSID(in_act, ci.ind_sid, security_pkg.PERMISSION_READ) = 1;

	-- This is pretty horrible, but permission checking every delegation is too expensive (minutes if many)
	-- and this query is pretty much going to be run by an admin (since it's called from the edit schema
	-- pages), which means they likely have access to the delegations anyway.
	-- Hence, just get a few delegations then only permission check some of those.  We get more than we
	-- need in the hope of getting something to return if permission is denied.
	SELECT d.delegation_sid
	  BULK COLLECT INTO v_some_delegs
	  FROM delegation d, delegation_ind di, customer c, reporting_period rp
	 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP') 
	   AND d.app_sid = c.app_sid AND d.parent_sid = d.app_sid
	   AND d.app_sid = di.app_sid AND d.delegation_sid = di.delegation_sid
	   AND di.ind_sid = in_ind_sid
	   AND c.app_sid = d.app_sid
	   AND c.app_sid = rp.app_sid AND c.current_reporting_period_sid = rp.reporting_period_sid
	   AND d.start_dtm < rp.end_dtm
	   AND d.end_dtm > rp.start_dtm
	   AND rownum <= 300;
	   
	OPEN out_delegations FOR
		SELECT /*+ALL_ROWS*/ *
		  FROM (SELECT d.delegation_sid, d.name, d.description, d.start_dtm, d.end_dtm,
					   d.period_set_id, d.period_interval_id
				  FROM v$delegation d,
				  	   TABLE(SecurableObject_pkg.GetSIDsWithPermAsTable(in_act, v_some_delegs,
					   		 security_pkg.PERMISSION_READ)) so
				 WHERE d.delegation_sid = so.sid_id
				 ORDER BY LOWER(d.name))
		  WHERE ROWNUM <= 100;
END;


-- returns null if not found
FUNCTION GetValID(
	in_ind_sid		IN  security_pkg.T_SID_ID,
	in_region_sid	IN	security_pkg.T_SID_ID,
	in_start_dtm	IN	VAL.period_start_dtm%TYPE,
	in_end_dtm		IN	VAL.period_end_dtm%TYPE
) RETURN VAL.val_id%TYPE
AS
	CURSOR c IS
		SELECT val_id FROM VAL
		 WHERE ind_sid = in_ind_sid
		   AND region_sid = in_region_sid
		   AND period_start_dtm = in_start_dtm
		   AND period_end_dtm = in_end_dtm;
	r c%ROWTYPE;
BEGIN
	OPEN c;
	FETCH c INTO r;
	IF c%NOTFOUND THEN
		RETURN NULL;
	ELSE
		RETURN r.val_id;
	END IF;
END;


-- would this value trigger any alerts?
-- has to be based around previous value? i.e. n% upon
-- previous month / year / week etc
PROCEDURE UpdateAlerts(
	in_ind_sid		IN  security_pkg.T_SID_ID,
	in_region_sid	IN	security_pkg.T_SID_ID,
	in_val_number	IN 	val.val_number%TYPE,
	in_start_dtm	IN	val.period_start_dtm%TYPE,
	in_end_dtm		IN	val.period_end_dtm%TYPE
)
AS
	v_period	CHAR(1);
	CURSOR c_win IS
		SELECT upper_bracket, lower_bracket FROM ind_window
		 WHERE ind_sid = in_ind_sid
		   AND period = v_period;
	v_this_start_dtm	DATE;
	v_this_end_dtm		DATE;
	v_check_start_dtm	DATE;
	v_check_end_dtm		DATE;
BEGIN
	v_period := val_pkg.GetIntervalFromRange(in_start_dtm, in_end_dtm);
	IF v_period IS NULL THEN
		-- ignore this (it's some kind of calculation or aggregate -- should we be setting alerts based on these?)
		RETURN;
	END IF;
	-- round off dates appropriately for this period
	val_pkg.GetPeriod(in_start_dtm, in_end_dtm, 0, v_this_start_dtm, v_this_end_dtm);
	-- are there ANY periods that match our start_dtm -> end_dtm FOR our INDICATOR?
	FOR r_win IN c_win LOOP
		-- if so, update alerts for our PREVIOUS PERIOD....
		val_pkg.GetPeriod(in_start_dtm, in_end_dtm, -1, v_check_start_dtm, v_check_end_dtm);
		UPDATE val
		   SET alert =
		   (SELECT CASE
		   	  WHEN ABS(in_val_number) > ABS(val_number)*r_win.upper_bracket THEN
			  	'Value more than '||(r_win.upper_bracket*100)||'% of previous value'
			  WHEN ABS(in_val_number) < ABS(val_number)*r_win.lower_bracket THEN
			  	'Value less than '||(r_win.lower_bracket*100)||'% of previous value'
			  ELSE NULL END
			  FROM val_converted
			 WHERE ind_sid = in_ind_sid
			   AND region_sid = in_region_sid
			   AND period_start_dtm = v_check_start_dtm
			   AND period_end_dtm = v_check_end_dtm
		   )
		 WHERE ind_sid = in_ind_sid
		   AND region_sid = in_region_sid
		   AND period_start_dtm = in_start_dtm
		   AND period_end_dtm = in_end_dtm;
		-- and update alerts for our NEXT PERIOD
		val_pkg.GetPeriod(in_start_dtm, in_end_dtm, +1, v_check_start_dtm, v_check_end_dtm);
		-- clear old alerts
		FOR r IN (
           SELECT val_id, CASE
                  WHEN ABS(val_number) > ABS(in_val_number)*r_win.upper_bracket THEN
                    'Value more than '||(r_win.upper_bracket*100)||'% of previous value'
                  WHEN ABS(val_number) < ABS(in_val_number)*r_win.lower_bracket THEN
                    'Value less than '||(r_win.lower_bracket*100)||'% of previous value'
                  ELSE NULL END alert
              FROM val_converted
             WHERE ind_sid = in_ind_sid
               AND region_sid = in_region_sid
               AND period_start_dtm = v_check_start_dtm
               AND period_end_dtm = v_check_end_dtm
        )
        LOOP
            UPDATE val SET alert = r.alert WHERE val_id = r.val_id;
        END LOOP;
	END LOOP;
END;


PROCEDURE GetFlags(
	in_act_id			IN  security_pkg.T_ACT_ID,
	in_ind_sid			IN  security_pkg.T_SID_ID,
	out_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_ind_sid, security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied for ind '||in_ind_sid);
	END IF;
	OPEN out_cur FOR
		SELECT flag, description, requires_note 
		  FROM IND_FLAG
		 WHERE IND_SID = in_ind_sid ORDER BY flag;
END;

PROCEDURE SetFlags(
	in_act_id			IN  security_pkg.T_ACT_ID,
	in_ind_sid			IN  security_pkg.T_SID_ID,
    in_flags			IN	csr_data_pkg.T_VARCHAR_ARRAY,
    in_requires_note	IN	csr_data_pkg.T_NUMBER_ARRAY
)
AS
	v_cnt		NUMBER(10);
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_ind_sid, Csr_Data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied altering schema for ind '||in_ind_sid);
	END IF;

	IF in_flags.COUNT = 1 AND in_flags(1) IS NULL THEN
		-- hack for ODP.NET which doesn't support empty arrays - just delete everything
		BEGIN
			DELETE FROM ind_flag
			 WHERE ind_sid = in_ind_sid;
			RETURN;
		EXCEPTION
			WHEN csr_data_pkg.CHILD_RECORD_FOUND THEN
				RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_VALUES_EXIST, 
					'Values existing deleting ind_flags for the ind with sid '||in_ind_sid);
		END;
	END IF;
	
	-- sanity check
	IF in_flags.COUNT != in_requires_note.COUNT THEN
		RAISE_APPLICATION_ERROR(-20001, 'flags and require_notes parameters are arrays of different lengths');
	END IF;

	-- go through each ID that we want to set
	FOR i IN in_flags.FIRST .. in_flags.LAST
	LOOP
		BEGIN
			INSERT INTO ind_flag (
				ind_sid, flag, description, requires_note
			) VALUES (
				in_ind_sid, i, in_flags(i), in_requires_note(i)
			);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE ind_flag
				   SET description = in_flags(i),
					   requires_note = in_requires_note(i)
				 WHERE ind_sid = in_ind_sid
				   AND flag = i;
		END;
	END LOOP;

	-- delete what we don't want
	-- (pl/sql collections can't be used from sql so we need to put in_flags.COUNT in a separate variable)
	v_cnt := in_flags.COUNT;
	BEGIN
		DELETE FROM ind_flag
		 WHERE ind_sid = in_ind_sid
		   AND flag > v_cnt;
	EXCEPTION
		WHEN csr_data_pkg.CHILD_RECORD_FOUND THEN
			RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_VALUES_EXIST,
				'Values existing deleting ind_flags for the ind with sid '||in_ind_sid||' and flag > '||v_cnt);
	END;
END;

-- DEPRECATED -- DO NOT CALL THIS YOURSELF
PROCEDURE SetWindow(
	in_act_id			IN  security_pkg.T_ACT_ID,
	in_ind_sid			IN  security_pkg.T_SID_ID,
	in_period			IN	IND_WINDOW.PERIOD%TYPE,
	in_lower_bracket	IN	IND_WINDOW.lower_bracket%TYPE,
	in_upper_bracket	IN	IND_WINDOW.upper_bracket%TYPE
)
AS
	CURSOR c_old IS
		SELECT lower_bracket, upper_bracket FROM IND_WINDOW
		 WHERE IND_SID = in_ind_sid AND PERIOD=in_period;
	v_old_lower_bracket	IND_WINDOW.lower_bracket%TYPE;
	v_old_upper_bracket	IND_WINDOW.upper_bracket%TYPE;
	v_change	VARCHAR2(1023);
	v_app_sid	security_pkg.T_SID_ID;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_ind_sid, Csr_Data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied altering schema for ind '||in_ind_sid);
	END IF;

	v_old_lower_bracket := NULL;
	v_old_upper_bracket := NULL;

	BEGIN
		INSERT INTO IND_WINDOW
			(ind_sid, PERIOD, lower_bracket, upper_bracket)
		VALUES
			(in_ind_sid, in_period, in_lower_bracket, in_upper_bracket);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			-- retrive old values
			OPEN c_old;
			FETCH c_old INTO v_old_lower_bracket, v_old_upper_bracket;
			IF c_old%FOUND THEN
				UPDATE IND_WINDOW
				   SET LOWER_BRACKET = in_lower_bracket,
					   UPPER_BRACKET = in_upper_bracket
				 WHERE IND_SID = in_ind_sid
				   AND PERIOD = in_period;
			END IF;
			CLOSE c_old;
	END;
	
	-- delete if equal
	IF in_lower_bracket = in_upper_bracket THEN
		DELETE FROM ind_window
		 WHERE ind_sid = in_ind_sid
		   AND period = in_period;
	END IF;
	

	v_change := v_change||Csr_Data_Pkg.AddToAuditDescription('Lower bracket', v_old_lower_bracket, in_lower_bracket);
	v_change := v_change||Csr_Data_Pkg.AddToAuditDescription('Upper bracket', v_old_upper_bracket, in_upper_bracket);


	SELECT app_sid INTO v_app_sid FROM ind where ind_sid = in_ind_sid;
	
	-- update all alerts for this indicator
	IF v_change IS NOT NULL THEN
		FOR r IN (
		   SELECT region_sid, period_start_dtm, period_end_dtm, val_number 
		     FROM VAL_CONVERTED
            WHERE ind_sid = in_ind_sid
		)
		LOOP
			UpdateAlerts(in_ind_sid, r.region_sid, r.val_number, r.period_start_dtm, r.period_end_dtm);
		END LOOP;
		
		FOR r IN (
			SELECT ind_sid, region_sid, val_number, sv.sheet_id 
			  FROM delegation d, sheet s, sheet_value sv 
			 WHERE d.app_sid = v_app_sid 
			   AND d.delegation_sid = s.delegation_sid
			   AND sv.sheet_id = s.sheet_id
			   AND ind_sid = in_ind_sid
		) 
		LOOP
			delegation_pkg.UpdateAlerts(r.ind_sid,r.region_sid,r.val_number,r.sheet_id);
		END LOOP; 
	END IF;
END;


PROCEDURE SetTolerance(
	in_act_id			IN  security_pkg.T_ACT_ID,
	in_ind_sid			IN  security_pkg.T_SID_ID,
	in_tolerance_type	IN	ind.tolerance_type%TYPE,
	in_lower_tolerance	IN	ind.pct_lower_tolerance%TYPE,
	in_upper_tolerance	IN	ind.pct_upper_tolerance%TYPE
)
AS
	v_change	VARCHAR2(1023);
	v_version	NUMBER(10);
	CURSOR c IS
		SELECT app_sid, tolerance_type, pct_lower_tolerance, pct_upper_tolerance
		  FROM ind
		 WHERE ind_sid = in_ind_sid;
	r 			c%ROWTYPE;
BEGIN
	SELECT CASE WHEN editing_url LIKE '/csr/site/delegation/sheet2%' THEN 2 ELSE 1 END
	  INTO v_version
	  FROM customer c
		JOIN ind i ON c.app_sid = i.app_sid
	 WHERE i.ind_sid = in_ind_sid;  -- just in case we ever ran w/out RLS
	 
	IF v_version = 1 THEN
		-- if it's ye olde sheet code then call SetWindow
		SetWindow(in_act_id, in_ind_sid, 'y', in_lower_tolerance, in_upper_tolerance);
		SetWindow(in_act_id, in_ind_sid, 'h', in_lower_tolerance, in_upper_tolerance);
		SetWindow(in_act_id, in_ind_sid, 'q', in_lower_tolerance, in_upper_tolerance);
		SetWindow(in_act_id, in_ind_sid, 'm', in_lower_tolerance, in_upper_tolerance);
	ELSE
		-- the new (rather more sane) way we do this	
		IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_ind_sid, Csr_Data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied altering schema for ind '||in_ind_sid);
		END IF;
		
		-- get a cursor so we can audit this change
		OPEN c;
		FETCH c INTO r;
		CLOSE c;

		csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, 
			in_ind_sid, 'Tolerance type', r.tolerance_type, in_tolerance_type);
		csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, 
			in_ind_sid, 'Lower bracket', r.pct_lower_tolerance, in_lower_tolerance);
		csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, 
			in_ind_sid, 'Upper bracket', r.pct_upper_tolerance, in_upper_tolerance);		
	END IF;
	
	-- make sure we update the ind table correctly anyway
	UPDATE ind
	   SET pct_upper_tolerance = in_upper_tolerance,
		  pct_lower_tolerance = in_lower_tolerance,
		  tolerance_type = in_tolerance_type,
		  last_modified_dtm = SYSDATE
	  WHERE ind_sid = in_ind_sid;
END;


PROCEDURE SetTolerance(
	in_act_id			IN  security_pkg.T_ACT_ID,
	in_ind_sid			IN  security_pkg.T_SID_ID,
	in_tolerance_type	IN	ind.tolerance_type%TYPE,
	in_lower_tolerance	IN	ind.pct_lower_tolerance%TYPE,
	in_upper_tolerance	IN	ind.pct_upper_tolerance%TYPE,
	in_tolerance_number_of_periods	IN	ind.tolerance_number_of_periods%TYPE,
	in_tolerance_number_of_standard_deviations_from_average	IN	ind.tolerance_number_of_standard_deviations_from_average%TYPE
)
AS
	v_change	VARCHAR2(1023);
	v_version	NUMBER(10);
	CURSOR c IS
		SELECT app_sid, tolerance_type, pct_lower_tolerance, pct_upper_tolerance,
			   tolerance_number_of_periods, tolerance_number_of_standard_deviations_from_average
		  FROM ind
		 WHERE ind_sid = in_ind_sid;
	r 			c%ROWTYPE;
BEGIN
	SELECT CASE WHEN editing_url LIKE '/csr/site/delegation/sheet2%' THEN 2 ELSE 1 END
	  INTO v_version
	  FROM customer c
		JOIN ind i ON c.app_sid = i.app_sid
	 WHERE i.ind_sid = in_ind_sid;  -- just in case we ever ran w/out RLS
	 
	IF v_version = 1 THEN
		-- if it's ye olde sheet code then call SetWindow
		SetWindow(in_act_id, in_ind_sid, 'y', in_lower_tolerance, in_upper_tolerance);
		SetWindow(in_act_id, in_ind_sid, 'h', in_lower_tolerance, in_upper_tolerance);
		SetWindow(in_act_id, in_ind_sid, 'q', in_lower_tolerance, in_upper_tolerance);
		SetWindow(in_act_id, in_ind_sid, 'm', in_lower_tolerance, in_upper_tolerance);
	ELSE
		-- the new (rather more sane) way we do this	
		IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_ind_sid, Csr_Data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied altering schema for ind '||in_ind_sid);
		END IF;
		
		-- get a cursor so we can audit this change
		OPEN c;
		FETCH c INTO r;
		CLOSE c;

		csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, 
			in_ind_sid, 'Tolerance type', r.tolerance_type, in_tolerance_type);
		csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, 
			in_ind_sid, 'Lower bracket', r.pct_lower_tolerance, in_lower_tolerance);
		csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, 
			in_ind_sid, 'Upper bracket', r.pct_upper_tolerance, in_upper_tolerance);		
		csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, 
			in_ind_sid, 'Number of periods', r.tolerance_number_of_periods, in_tolerance_number_of_periods);		
		csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, 
			in_ind_sid, 'Number of Standard Deviations from average', r.tolerance_number_of_standard_deviations_from_average, in_tolerance_number_of_standard_deviations_from_average);		
	END IF;
	
	-- make sure we update the ind table correctly anyway
	UPDATE ind
	   SET tolerance_type = in_tolerance_type,
		   pct_upper_tolerance = in_upper_tolerance,
		   pct_lower_tolerance = in_lower_tolerance,
		   tolerance_number_of_periods = in_tolerance_number_of_periods,
		   tolerance_number_of_standard_deviations_from_average = in_tolerance_number_of_standard_deviations_from_average,
		   last_modified_dtm = SYSDATE
	  WHERE ind_sid = in_ind_sid;
END;

PROCEDURE DeleteVal(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_val_id						IN	val.val_id%TYPE,
	in_reason						IN	VARCHAR2
)
AS
BEGIN
	csr_data_pkg.LockApp(csr_data_pkg.LOCK_TYPE_CALC);

	-- record the change so we know who deleted this
	INSERT INTO val_change (
		val_change_id, reason, changed_by_sid, changed_dtm, source_type_id,
		val_number, ind_sid, region_sid, period_start_dtm, period_end_dtm,
		entry_val_number, entry_measure_conversion_id, note, source_id
	)
		SELECT val_change_id_seq.NEXTVAL, in_reason, SYS_CONTEXT('SECURITY', 'SID'), SYSDATE, v.source_type_id,
			   null, v.ind_sid, v.region_sid, v.period_start_dtm, v.period_end_dtm, null, null, null, null
		  FROM val v
		 WHERE val_id = in_val_id;

	MERGE /*+ALL_ROWS*/ INTO val_change_log vcl
	USING (SELECT app_sid, ind_sid, period_start_dtm, period_end_dtm
			 FROM val
			WHERE val_id = in_val_id) v
	   ON (v.app_sid = vcl.app_sid AND v.ind_sid = vcl.ind_sid)
	 WHEN MATCHED THEN
		UPDATE SET vcl.start_dtm = LEAST(vcl.start_dtm, v.period_start_dtm),
				   vcl.end_dtm = GREATEST(vcl.end_dtm, v.period_end_dtm)
	 WHEN NOT MATCHED THEN
		INSERT (vcl.ind_sid, vcl.start_dtm, vcl.end_dtm)
		VALUES (v.ind_sid, v.period_start_dtm, v.period_end_dtm);
	
	UPDATE imp_val
	   SET set_val_id = null
	 WHERE set_val_id = in_val_id;
	
	DELETE FROM val_file
	 WHERE val_id = in_val_id;
	 
	DELETE FROM val
	 WHERE val_id = in_val_id;
END;		

-- A wrapper that doesn't poke file uploads for old code.
-- If this was removed direct value editing, rollback, etc. would clear file uploads.  We have to 
-- pass a flag to say if we have supplied file uploads to the main function since security_pkg.T_SID_IDS
-- cannot be null.
PROCEDURE SetValueWithReasonWithSid(
	in_user_sid				IN	security_pkg.T_SID_ID,
	in_ind_sid				IN	security_pkg.T_SID_ID,
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_period_start			IN	val.period_start_dtm%TYPE,
	in_period_end			IN	val.period_end_dtm%TYPE,
	in_val_number			IN	val.val_number%TYPE,
	in_flags				IN	val.flags%TYPE DEFAULT 0,
	in_source_type_id		IN	val.source_type_id%TYPE DEFAULT 0,
	in_source_id			IN	val.source_id%TYPE DEFAULT NULL,
	in_entry_conversion_id	IN	val.entry_measure_conversion_id%TYPE DEFAULT NULL,
	in_entry_val_number		IN	val.entry_val_number%TYPE DEFAULT NULL,
	in_error_code			IN	val.error_code%TYPE DEFAULT NULL,
	in_update_flags			IN	NUMBER DEFAULT 0, -- misc flags incl do we allow recalc jobs to be written and override locks
	in_reason				IN	val_change.reason%TYPE,
	in_note					IN	val.note%TYPE DEFAULT NULL,
	out_val_id				OUT	val.val_id%TYPE
)
AS
	v_file_uploads			security_pkg.T_SID_IDS; -- empty
BEGIN
	SetValueWithReasonWithSid(in_user_sid, in_ind_sid, in_region_sid, in_period_start, in_period_end,
		in_val_number, in_flags, in_source_type_id, in_source_id, in_entry_conversion_id, in_entry_val_number,
		in_error_code, in_update_flags, in_reason, in_note, 0, v_file_uploads, out_val_id);
END;

PROCEDURE SetValueWithReasonWithSid(
	in_user_sid						IN	security_pkg.T_SID_ID,
	in_ind_sid						IN	security_pkg.T_SID_ID,
	in_region_sid					IN	security_pkg.T_SID_ID,
	in_period_start					IN	val.period_start_dtm%TYPE,
	in_period_end					IN	val.period_end_dtm%TYPE,
	in_val_number					IN	val.val_number%TYPE,
	in_flags						IN	val.flags%TYPE DEFAULT 0,
	in_source_type_id				IN	val.source_type_id%TYPE DEFAULT 0,
	in_source_id					IN	val.source_id%TYPE DEFAULT NULL,
	in_entry_conversion_id			IN	val.entry_measure_conversion_id%TYPE DEFAULT NULL,
	in_entry_val_number				IN	val.entry_val_number%TYPE DEFAULT NULL,
	in_error_code					IN	val.error_code%TYPE DEFAULT NULL,
	in_update_flags					IN	NUMBER DEFAULT 0, -- misc flags incl do we allow recalc jobs to be written and override locks
	in_reason						IN	val_change.reason%TYPE,
	in_note							IN	val.note%TYPE DEFAULT NULL,
	in_have_file_uploads			IN	NUMBER,
	in_file_uploads					IN	security_pkg.T_SID_IDS,
	out_val_id						OUT	val.val_id%TYPE
)
AS
	CURSOR c_indicator IS
		SELECT m.scale, i.app_sid, i.ind_type, i.factor_type_id,
			   NVL(i.divisibility, m.divisibility) divisibility
		  FROM ind i, measure m
		 WHERE i.ind_sid = in_ind_sid AND i.measure_sid = m.measure_sid;
	r_indicator 	c_indicator%ROWTYPE;
	CURSOR c_update(v_region_sid security_pkg.T_SID_ID) IS
		SELECT val_id, val_number, flags, source_id, source_type_id, error_code, entry_measure_conversion_id, entry_val_number, note
		  FROM val
		 WHERE ind_sid = in_ind_sid
		   AND region_sid = v_region_sid
		   AND period_start_dtm = in_period_start
		   AND period_end_dtm = in_period_end
           FOR UPDATE;
	r_update 						c_update%ROWTYPE;
	v_change_period_start			val.period_start_dtm%TYPE := in_period_start;
	v_change_period_end				val.period_end_dtm%TYPE := in_period_end;
	v_helper_pkg					source_type.helper_pkg%TYPE;
	v_is_changed_value 	 			BOOLEAN;
	c								SYS_REFCURSOR;
	v_rounded_in_val_number			val.val_number%TYPE;
	v_entry_val_number  			val.entry_val_number%TYPE;
	v_is_new_value					BOOLEAN DEFAULT FALSE;
	v_is_changed_detail				BOOLEAN;
	v_is_changed_note				BOOLEAN;
	v_file_changes					NUMBER(10);
	v_file_uploads					security.T_SID_TABLE;
	v_pct_ownership					NUMBER;
	v_scaled_val_number				val.val_number%TYPE;
	v_scaled_entry_val_number		val.entry_val_number%TYPE;
BEGIN
	--security_pkg.debugmsg('set ind='||in_ind_sid||', region='||in_region_sid||', start='||in_period_start||
	--	', end='||in_period_end||', val='||in_val_number||', update_flags='||in_update_flags);
	OPEN c_indicator;
	FETCH c_indicator INTO r_indicator;
	IF c_indicator%NOTFOUND THEN	
		RAISE_APPLICATION_ERROR(-20001, 'cannot find indicator '||in_ind_sid);
	END IF;
	CLOSE c_indicator;

	-- If the period is locked (unless we have special capability), disallow writing, except for things from scrag which indicate a recalc of some 
	-- type has taken place -- we'd otherwise lose the values.
	-- Region Metrics (and Energy Star) update values when the calculation window is extended this could be a value starting in a locked period. 
	IF in_source_type_id NOT IN (csr_data_pkg.SOURCE_TYPE_AGGREGATOR, csr_data_pkg.SOURCE_TYPE_STORED_CALC, csr_data_pkg.SOURCE_TYPE_ENERGY_STAR, csr_data_pkg.SOURCE_TYPE_REGION_METRIC) AND 
	   NOT csr_data_pkg.CheckCapability(security_pkg.GetAct, 'Can edit forms before system lock date') AND
	   csr_data_pkg.IsPeriodLocked(r_indicator.app_sid, in_period_start, in_period_end) = 1 THEN
		-- TODO: log that we tried to write to a historic value
		out_val_id := -1; -- -1 means we didn't do anything
        RETURN;	
    END IF;

	-- round it as we'll put it in the database, and apply pctOwnership so long
	-- as we're not aggregating
	IF in_source_type_id IN (csr_data_pkg.SOURCE_TYPE_AGGREGATOR, csr_data_pkg.SOURCE_TYPE_STORED_CALC) AND bitand(in_update_flags, IND_CASCADE_PCT_OWNERSHIP) = 0 THEN
        v_rounded_in_val_number := ROUND(in_val_number, 10);
	ELSE
		v_pct_ownership := region_pkg.getPctOwnership(in_ind_sid, in_region_sid, in_period_start);
        v_rounded_in_val_number := ROUND(in_val_number * v_pct_ownership, 10);
    END IF;

    -- this is a bit of a hack for existing code that calls this.
    -- It supports calling in with in_entry_val_number IS NULL and in_entry_conversion_id IS NULL and v_entry_val_number IS NOT NULL
    -- if in_entry_conversion_id is null then put our number into v_entry_val_number since this is the number actually entered (we might have modified val_number for pct ownership)
    IF in_entry_conversion_id IS NULL THEN
        v_entry_val_number := in_val_number;
    ELSE
        v_entry_val_number := in_entry_val_number;
    END IF;
    
    -- clear or scale any overlapping values (we scale for stored calcs / aggregates, but clear for other value types)
    -- there are multiple cases, but basically it boils down to having a non-overlapping left/right portion or the value being completely covered
    -- for the left/right cases we either scale according to divisibility or create NULLs covering the non-overlapping portion 
    -- (to clear aggregates up the tree in those time periods)
    -- for the complete coverage case the old value simply needs to be removed (but any value with the exact period is simply updated in place)
    --security_pkg.debugmsg('adding value for ind='||in_ind_sid||', region='||in_region_sid||',period='||in_period_start||' -> '||in_period_end);    
    FOR r IN (SELECT val_id, period_start_dtm, period_end_dtm, val_number, error_code, entry_val_number, source_type_id
    			FROM val
		       WHERE ind_sid = in_ind_sid
			     AND region_sid = in_region_sid
			     AND period_end_dtm > in_period_start
			     AND period_start_dtm < in_period_end
			     AND NOT (period_start_dtm = in_period_start AND period_end_dtm = in_period_end)
			     	 FOR UPDATE) LOOP
		v_change_period_start := LEAST(v_change_period_start, r.period_start_dtm);
		v_change_period_end := GREATEST(v_change_period_end, r.period_end_dtm);
		
		-- non-overlapping portion on the left
		IF r.period_start_dtm < in_period_start THEN
			IF r.source_type_id IN (csr_data_pkg.SOURCE_TYPE_AGGREGATOR, csr_data_pkg.SOURCE_TYPE_STORED_CALC, csr_data_pkg.SOURCE_TYPE_AGGREGATE_GRP) THEN
				IF r_indicator.divisibility = csr_data_pkg.DIVISIBILITY_DIVISIBLE THEN
					v_scaled_val_number := (r.val_number * (in_period_start - r.period_start_dtm)) / (r.period_end_dtm - r.period_start_dtm);
					v_scaled_entry_val_number := (r.entry_val_number * (in_period_start - r.period_start_dtm)) / (r.period_end_dtm - r.period_start_dtm);
				ELSE
					v_scaled_val_number := r.val_number;
					v_scaled_entry_val_number := r.entry_val_number;
				END IF;

				--security_pkg.debugmsg('adding left value from '||r.period_start_dtm||' to '||in_period_start||' scaled to '||v_scaled_val_number||' ('||v_scaled_entry_val_number||')');				
				INSERT INTO val
					(val_id, ind_sid, region_sid, period_start_dtm, period_end_dtm, val_number, error_code, entry_val_number, source_type_id)
				VALUES
					(val_id_seq.NEXTVAL, in_ind_sid, in_region_sid, r.period_start_dtm, in_period_start, v_scaled_val_number, 
					 r.error_code, v_scaled_entry_val_number, r.source_type_id);
			END IF;			
		END IF;

		-- non-overlapping portion on the right
		IF r.period_end_dtm > in_period_end THEN
			
			IF r.source_type_id IN (csr_data_pkg.SOURCE_TYPE_AGGREGATOR, csr_data_pkg.SOURCE_TYPE_STORED_CALC, csr_data_pkg.SOURCE_TYPE_AGGREGATE_GRP) THEN
				IF r_indicator.divisibility = csr_data_pkg.DIVISIBILITY_DIVISIBLE THEN
					v_scaled_val_number := (r.val_number * (in_period_start - r.period_start_dtm)) / (r.period_end_dtm - r.period_start_dtm);
					v_scaled_entry_val_number := (r.entry_val_number * (in_period_start - r.period_start_dtm)) / (r.period_end_dtm - r.period_start_dtm);
				ELSE
					v_scaled_val_number := r.val_number;
					v_scaled_entry_val_number := r.entry_val_number;
				END IF;

				--security_pkg.debugmsg('adding right value from '||in_period_end||' to '||r.period_end_dtm||' scaled to '||v_scaled_val_number||' ('||v_scaled_entry_val_number||')');
				INSERT INTO val
					(val_id, ind_sid, region_sid, period_start_dtm, period_end_dtm, val_number, error_code, entry_val_number, source_type_id)
				VALUES
					(val_id_seq.NEXTVAL, in_ind_sid, in_region_sid, in_period_end, r.period_end_dtm, v_scaled_val_number, 
					 r.error_code, v_scaled_entry_val_number, r.source_type_id);
			END IF;
		END IF;
		
		-- remove the overlapping value
		--security_pkg.debugmsg('clearing overlapping value '||r.val_id||' (period '||r.period_start_dtm||' -> '||r.period_end_dtm||'), source='||r.source_type_id||', val='||r.val_number);
		UPDATE imp_val
		   SET set_val_id = NULL 
		 WHERE set_val_id = r.val_id;
		 
		DELETE FROM val_file
		 WHERE val_id = r.val_id;

		DELETE FROM val
		 WHERE val_id = r.val_id;
	END LOOP;
			  
    -- upsert (there are constraints on val which will throw DUP_VAL_ON_INDEX if this should be an update)
    BEGIN
        INSERT INTO val (val_id, ind_sid, region_sid, period_start_dtm,
            period_end_dtm,  val_number, flags, source_id, source_type_id,
            entry_measure_conversion_id, entry_val_number, note, error_code)
        VALUES (val_id_seq.NEXTVAL, in_ind_sid, in_region_sid, in_period_start,
            in_period_end,  v_rounded_in_val_number, in_flags, in_source_id, in_source_type_id, 
            in_entry_conversion_id, v_entry_val_number, in_note, in_error_code)
        RETURNING val_id INTO out_val_id;
        v_is_new_value := true;
        -- only mark this down as a change if we're really entering a value / error (nulls don't count as no row effectively means null)
		IF v_rounded_in_val_number IS NOT NULL OR in_error_code IS NOT NULL THEN
        	v_is_changed_value := true;
    	END IF;
    	IF in_note IS NOT NULL THEN
	        v_is_changed_note := true;
    	END IF;		
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            -- do we really need to update?
            OPEN c_update(in_region_sid);
            FETCH c_update INTO r_update;
            IF c_update%NOTFOUND THEN
                RAISE_APPLICATION_ERROR(-20001,'Constraint violated but no value found ');
            END IF;

            out_val_id := r_update.val_id;
                    
            v_is_changed_value := NVL(r_update.val_number != v_rounded_in_val_number
                OR (r_update.val_number IS NULL AND v_rounded_in_val_number IS NOT NULL)
                OR (r_update.val_number IS NOT NULL AND v_rounded_in_val_number IS NULL)
               	OR r_update.error_code != in_error_code
                OR (r_update.error_code IS NULL AND in_error_code IS NOT NULL)
                OR (r_update.error_code IS NOT NULL AND in_error_code IS NULL), FALSE);

            v_is_changed_note := NVL(dbms_lob.compare(r_update.note, in_note), -1) != 0;

            -- check for details changing -- we still want to write rows to val_change
            -- if that is the case (but not to trigger recalcs)
        	v_is_changed_detail :=
			   null_pkg.ne(r_update.source_type_id, in_source_type_id) OR
        	   null_pkg.ne(r_update.source_id, in_source_id) OR
        	   null_pkg.ne(r_update.entry_measure_conversion_id, in_entry_conversion_id) OR 
        	   null_pkg.ne(r_update.entry_val_number, v_entry_val_number) OR
        	   null_pkg.ne(r_update.flags, in_flags) OR
        	   v_is_changed_note;

			-- check files using the SIDs (if supplied)
			IF NOT v_is_changed_detail AND in_have_file_uploads = 1 THEN
				v_file_uploads := security_pkg.SidArrayToTable(in_file_uploads);

				SELECT COUNT(*)
				  INTO v_file_changes
				  FROM (SELECT file_upload_sid
						  FROM val_file
						 WHERE val_id = r_update.val_id
						 MINUS
						SELECT column_value
						  FROM TABLE(v_file_uploads)
						 UNION
						SELECT column_value
						  FROM TABLE(v_file_uploads)
						 MINUS
						SELECT file_upload_sid
						  FROM val_file
						 WHERE val_id = r_update.val_id);

				v_is_changed_detail := v_file_changes > 0;
			END IF;
            
            -- check for INSERT_ONLY - this means that we never update values
            -- this is useful if we want to ask users to explain their changes
            IF bitand(in_update_flags, Indicator_Pkg.IND_INSERT_ONLY) > 0 AND v_is_changed_value THEN
                -- check for INSERT_ONLY AND a change in value (including old value is NOT null and our new value IS a NULL)
                -- IND_INSERT_ONLY is used when we don't want to amend changed rows, i.e. we want to force the
                -- user to explain any changes we detect. This is a pretty horrible mechanism - i.e. these
                -- are really two separate jobs and should be split into separate stored procedures I think
                out_val_id := -r_update.val_id; 
                -- return without updating
                RETURN;
            END IF;
            
            -- what is IND_OVERRIDE_LOCKS for?
            --IF bitand(in_update_flags, Indicator_Pkg.IND_OVERRIDE_LOCKS) > 0
            IF bitand(in_update_flags, Indicator_Pkg.IND_INSERT_ONLY) = 0 THEN
            
                IF v_is_changed_value THEN
                    -- unhook any linked value (import / delegation etc)
                    SELECT helper_pkg 
                      INTO v_helper_pkg 
                      FROM source_type
                     WHERE source_type_id = r_update.source_type_id;
                     
                    IF v_helper_pkg IS NOT NULL THEN
                        -- call helper_pkg to unhook any val_id pointers they keep 
                        EXECUTE IMMEDIATE 'begin '||v_helper_pkg||'.OnValChange(:1,:2);end;'
                            USING r_update.val_id, r_update.source_id;
                    END IF;
                END IF;
                
                UPDATE val
                   SET val_number = v_rounded_in_val_number, 
	                   flags = in_flags,
	                   source_id = in_source_id, 
	                   source_type_id = in_source_type_id,
	                   entry_measure_conversion_id = in_entry_conversion_id,
	                   entry_val_number = v_entry_val_number, 
	                   note = in_note,
	                   error_code = in_error_code,
					   changed_by_sid = in_user_sid,
					   changed_dtm = SYSDATE
                 WHERE CURRENT OF c_update;
            END IF; 
    
            CLOSE c_update;
    END;

	IF (v_is_changed_value OR v_is_new_value OR v_is_changed_detail) AND in_source_type_id NOT IN (csr_data_pkg.SOURCE_TYPE_AGGREGATOR, csr_data_pkg.SOURCE_TYPE_STORED_CALC) THEN
		INSERT INTO val_change (
			val_change_id, reason, changed_by_sid, changed_dtm, source_type_id,
			val_number, ind_sid, region_sid, period_start_dtm, period_end_dtm,
			entry_val_number, entry_measure_conversion_id, note, source_id
		) VALUES (
			val_change_id_seq.NEXTVAL, in_reason, in_user_sid, SYSDATE, in_source_type_id,
			v_rounded_in_val_number, in_ind_sid, in_region_sid, in_period_start, in_period_end,
			v_entry_val_number, in_entry_conversion_id, null, in_source_id
		);
	END IF;

	-- splodge files in
	IF in_have_file_uploads = 1 THEN
		IF v_file_uploads IS NULL THEN -- we might have done this above
			v_file_uploads := security_pkg.SidArrayToTable(in_file_uploads);
		END IF;

		DELETE FROM val_file
		 WHERE val_id = out_val_id
		   AND file_upload_sid NOT IN (
		   		SELECT column_value
		   		  FROM TABLE(v_file_uploads));
	
		INSERT INTO val_file (val_id, file_upload_sid)
			SELECT out_val_id, column_value
			  FROM TABLE(v_file_uploads)
			 MINUS
			SELECT out_val_id, file_upload_sid
			  FROM val_file
			 WHERE val_id = out_val_id;
	END IF;
	
	-- add some recalc jobs for formulae which depend on this indicator or region if changed
	-- XXX: we only really need to add jobs for note only changes for scrag++
	-- there's no good way of doing that at present though so recomputing old style
	-- scenarios and merged data on note changes too
	IF v_is_changed_value OR v_is_changed_note THEN
		IF bitand(in_update_flags, Indicator_pkg.IND_DISALLOW_RECALC) = 0 OR
		   bitand(in_update_flags, Indicator_pkg.IND_DISALLOW_AGGREGATION) = 0 THEN
			Calc_Pkg.addJobsForVal(in_ind_sid, in_region_sid, v_change_period_start, v_change_period_end);

			-- Create actions update jobs
			actions.dependency_pkg.CreateJobsFromInd(r_indicator.app_sid, in_ind_sid, in_region_sid, in_period_start);
		END IF;		
			
		IF bitand(in_update_flags, Indicator_Pkg.IND_SKIP_UPDATE_ALERTS) = 0 THEN
			updateAlerts(in_ind_sid, in_region_sid, in_val_number, in_period_start, in_period_end);
		END IF;
	END IF;
	
	out_val_id := NVL(out_val_id, -1); -- we can't return nulls in an output parameter via ADO :(
END;


/*
- IDEA FOR IMPROVING TRACKING OF CHANGES:

- Every change will have a unique ID allocated to it (the "change ID").
  The date/time and user initiating the change will be stored alongside the
  change ID.

- Recalculations will be logged against the change ID thus grouping all changes
  to the initiating change.

*/

/**
 * Set a value
 *
 * @param	in_act_id				Access token
 * @param	in_indicator_sid		The indicator
 * @param	in_region_sid			The region
 * @param	in_period_start			The start date
 * @param	in_period_end			The end date
 * @param	in_val_number			The value
 * @param	in_flags				Flags
 * @param	out_val_id				The ID of the inserted value
 *
 */
PROCEDURE SetValueWithReason(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_ind_sid				IN security_pkg.T_SID_ID,
	in_region_sid			IN security_pkg.T_SID_ID,
	in_period_start			IN VAL.period_start_dtm%TYPE,
	in_period_end			IN VAL.period_end_dtm%TYPE,
	in_val_number			IN VAL.val_number%TYPE,
	in_flags				IN VAL.flags%TYPE,
	in_source_type_id		IN VAL.source_type_id%TYPE DEFAULT 0,
	in_source_id			IN VAL.source_id%TYPE DEFAULT NULL,
	in_entry_conversion_id	IN VAL.entry_measure_conversion_id%TYPE DEFAULT NULL,
	in_entry_val_number		IN VAL.entry_val_number%TYPE DEFAULT NULL,
	in_update_flags			IN NUMBER DEFAULT 0, -- misc flags incl do we allow recalc jobs to be written and override locks
	in_reason				IN VAL_CHANGE.REASON%TYPE,
	in_note					IN VAL.NOTE%TYPE,
	out_val_id				OUT VAL.val_id%TYPE
)
AS
	v_user_sid		security_pkg.T_SID_ID;
BEGIN
	-- do we have permission on this indicator and this region?
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_ind_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to ind '||in_ind_sid);
	END IF;
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to region '||in_region_sid);
	END IF;
	
	user_pkg.getsid(in_act_id, v_user_sid);
    SetValueWithReasonWithSid(v_user_sid, in_ind_sid, in_region_sid, in_period_start, in_period_end, in_val_number, in_flags,
        in_source_type_id, in_source_id, in_entry_conversion_id, in_entry_val_number, null, in_update_flags, 
        in_reason, in_note, out_val_id);
END;


PROCEDURE SetValue(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_ind_sid				IN security_pkg.T_SID_ID,
	in_region_sid			IN security_pkg.T_SID_ID,
	in_period_start			IN VAL.period_start_dtm%TYPE,
	in_period_end			IN VAL.period_end_dtm%TYPE,
	in_val_number			IN VAL.val_number%TYPE,
	in_flags				IN VAL.flags%TYPE,
	in_source_type_id		IN VAL.source_type_id%TYPE DEFAULT 0,
	in_source_id			IN VAL.source_id%TYPE DEFAULT NULL,
	in_entry_conversion_id	IN VAL.entry_measure_conversion_id%TYPE DEFAULT NULL,
	in_entry_val_number		IN VAL.entry_val_number%TYPE DEFAULT NULL,
	in_update_flags			IN NUMBER DEFAULT 0, -- misc flags incl do we allow recalc jobs to be written and override locks
	in_note					IN VAL.NOTE%TYPE,
	out_val_id				OUT VAL.val_id%TYPE
)
AS
BEGIN
	setValueWithReason(in_act_id, in_ind_sid, in_region_sid, in_period_start, in_period_end, in_val_number, in_flags,
		in_source_type_id, in_source_id, in_entry_conversion_id, in_entry_val_number, in_update_flags, 'New value', 
		in_note, out_val_id);
END;


-- called by myform when initially setting a value
-- returns a cursor if value is not 
PROCEDURE SetNewValueOnly(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_ind_sid				IN security_pkg.T_SID_ID,
	in_region_sid			IN security_pkg.T_SID_ID,
	in_period_start			IN VAL.period_start_dtm%TYPE,
	in_period_end			IN VAL.period_end_dtm%TYPE,
	in_val_number			IN VAL.val_number%TYPE,
	in_flags				IN VAL.flags%TYPE,
	in_source_type_id		IN VAL.source_type_id%TYPE DEFAULT 0,
	in_source_id			IN VAL.source_id%TYPE DEFAULT NULL,
	in_entry_conversion_id	IN VAL.entry_measure_conversion_id%TYPE DEFAULT NULL,
	in_entry_val_number		IN VAL.entry_val_number%TYPE DEFAULT NULL,
	in_update_flags			IN NUMBER DEFAULT 0, -- misc flags incl do we allow recalc jobs to be written and override locks
	in_note					IN VAL.NOTE%TYPE,
	out_cur					OUT SYS_REFCURSOR
)
AS
	v_val_id				VAL.val_id%TYPE;
	v_ind_type				IND.IND_TYPE%TYPE;
	v_measure_sid			security_pkg.T_SID_ID;
BEGIN
	SELECT IND_TYPE, MEASURE_SID
	  INTO v_ind_type, v_measure_sid
	  FROM IND
	 WHERE IND_SID = in_ind_sid;

	IF v_ind_type IN (csr_data_pkg.IND_TYPE_NORMAL) AND v_measure_sid IS NOT NULL THEN
		setValue(in_act_id, in_ind_sid, in_region_sid, in_period_start, in_period_end, in_val_number, 
			in_flags, in_source_type_id, in_source_id, in_entry_conversion_id, in_entry_val_number, 
			bitwise_pkg.bitor(in_update_flags, Indicator_Pkg.IND_INSERT_ONLY), in_note, v_val_id);

		IF v_val_id < -1 THEN
			OPEN out_cur FOR
                -- return random bunch of data about the number they tried to save and what's there already
                SELECT val_id, entry_val_number, entry_measure_conversion_id, i.description ind_description, r.description region_description, 
                        NVL(mc.description, m.description) entry_measure_description, 
                        NVL((SELECT description FROM MEASURE_CONVERSION WHERE measure_conversion_id = in_entry_conversion_id), m.description) saved_measure_description
                  FROM val v, v$ind i, v$region r, measure_conversion mc, measure m
                 WHERE val_id = -v_val_id
                   AND i.ind_sid = v.ind_sid
                   AND i.measure_Sid = m.measure_sid
                   AND r.region_sid = v.region_sid
                   AND v.entry_measure_conversion_id = mc.measure_conversion_id(+);
			RETURN;
		END IF;
	END IF;
	-- return empty recordset
	OPEN out_cur FOR
		SELECT 0 val_id, 0 entry_val_number, 0 entry_measure_conversion_id, NULL ind_description, NULL region_description, NULL entry_measure_description,
            NULL saved_measure_description 
          FROM VAL WHERE 1=0;
END;

PROCEDURE RollbackToDate(
	in_act_id			security_pkg.T_ACT_ID,
	in_ind_sid			security_pkg.T_SID_ID,
	in_period_start_dtm	val.period_start_dtm%TYPE,
	in_period_end_dtm	val.period_end_dtm%TYPE,
	in_dtm				DATE
)
AS
	v_user_sid		security_pkg.T_SID_ID;
    v_app_sid	security_pkg.T_SID_ID;
    v_val_id		VAL.val_id%TYPE;	
BEGIN
	-- get user sid
	user_pkg.getsid(in_act_id, v_user_sid);
    -- get app_sid
    SELECT app_sid
      INTO v_app_sid
      FROM IND
     WHERE ind_sid = in_ind_sid;
	-- delete everything from val for this indicator (unhooking from source type etc first)
	FOR r IN (
		SELECT st.helper_pkg, v.val_id, v.region_sid, v.period_start_dtm, v.period_end_dtm, v.source_id
	      FROM SOURCE_TYPE st, VAL v
	     WHERE v.source_type_id = st.source_type_id
		   AND ind_sid = in_ind_sid
		   AND period_start_dtm >=in_period_Start_dtm
		   AND period_end_dtm <= in_period_end_dtm
	)
	LOOP     
		-- unhook any linked value (import / delegation etc) 
		IF r.helper_pkg IS NOT NULL THEN
			-- call helper_pkg to unhook any val_id pointers they keep 
		    EXECUTE IMMEDIATE 'begin '||r.helper_pkg||'.OnValChange(:1,:2);end;'
				USING r.val_id, r.source_id;
		END IF;

        -- history the deletion
		INSERT INTO val_change
			(val_change_id, reason, changed_by_sid, changed_dtm, source_type_id,
			 val_number, ind_sid, region_sid, period_start_dtm, period_end_dtm,
			 entry_val_number, entry_measure_conversion_id, note, source_id)
		VALUES
			(val_change_id_seq.NEXTVAL, 'Rollback', v_user_sid, SYSDATE, csr_data_pkg.SOURCE_TYPE_DIRECT,
			NULL, in_ind_sid, r.region_sid, r.period_start_dtm, r.period_end_dtm,
			NULL, NULL, NULL, NULL);
			
		-- nuke the value
	    DELETE FROM VAL_FILE
	  	 WHERE val_id = r.val_id;

	    DELETE FROM VAL
	  	 WHERE val_id = r.val_id;
	END LOOP; 
	--
	FOR r IN (
		SELECT region_sid, period_start_dtm, period_end_dtm, val_number, NOTE, 
	    	source_id, source_type_id, entry_measure_conversion_id, entry_val_number
		  FROM (
			SELECT region_sid, period_start_dtm, period_end_dtm, val_number, NOTE, 
	        	source_id, source_type_id, entry_measure_conversion_id, entry_val_number,
			 ROW_NUMBER() OVER (PARTITION BY region_sid, period_start_dtm ORDER BY changed_dtm DESC) seq 
			  FROM val_change 
			 WHERE changed_dtm < in_dtm
			   AND ind_sid = in_ind_sid
			   AND source_type_id NOT IN csr_data_pkg.SOURCE_TYPE_AGGREGATOR
			   AND period_start_dtm >=in_period_start_dtm
			   AND period_end_dtm <= in_period_end_dtm   
		 )
		 WHERE seq = 1
		   AND val_number IS NOT NULL
	)
	LOOP
		Indicator_Pkg.SetValue(in_act_id, in_ind_sid, r.region_sid, r.period_start_dtm, r.period_end_dtm, r.val_number,
			0, r.source_type_id, r.source_id, r.entry_measure_conversion_id, r.entry_val_number, 
			0, r.note, v_val_id);
	END LOOP;   

	-- write a recalc job
	ReaggregateIndicator(in_ind_sid);
END;	

PROCEDURE AddNote(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_ind_sid				IN	security_pkg.T_SID_ID,
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_period_start_dtm		IN	VAL_NOTE.period_start_dtm%TYPE,
	in_period_end_dtm		IN	VAL_NOTE.period_end_dtm%TYPE,
	in_note					IN 	VAL_NOTE.NOTE%TYPE,
	out_val_note_id			OUT	VAL_NOTE.val_note_id%TYPE
)
AS
	v_user_sid		SECURITY_PKG.T_SID_ID;
BEGIN
	-- do we have permission on this indicator and this region?
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_ind_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to ind '||in_ind_sid);
	END IF;

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to region '||in_region_sid);
	END IF;

	user_pkg.GetSid(in_act_id, v_user_sid);
	INSERT INTO VAL_NOTE
		(val_note_id, ind_sid, region_sid, period_start_dtm, period_end_dtm,
		 NOTE, entered_by_sid, entered_dtm)
	VALUES
		(val_note_id_seq.NEXTVAL, in_ind_sid, in_region_sid, in_period_start_dtm, in_period_end_dtm,
		 in_note, v_user_sid, SYSDATE)
	RETURNING val_note_id INTO out_val_note_id;
END;

PROCEDURE UpdateNote(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_val_note_id			IN	VAL_NOTE.val_note_id%TYPE,
	in_note					IN 	VAL_NOTE.NOTE%TYPE
)
AS
	v_user_sid		SECURITY_PKG.T_SID_ID;
	v_ind_sid		SECURITY_PKG.T_SID_ID;
	v_region_sid	SECURITY_PKG.T_SID_ID;
	v_old_note		val_note.NOTE%TYPE;
	CURSOR c IS
		SELECT ind_sid, region_sid, note
		  FROM VAL_NOTE vn
		 WHERE vn.VAL_note_ID = in_val_note_id;
BEGIN
	OPEN c;
	FETCH c INTO v_ind_sid, v_region_sid, v_old_note;
	-- bail out if nothing's changed
	IF v_old_note = in_note THEN
		RETURN;
	END IF;
	
	-- do we have permission on this indicator and this region?
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_ind_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to ind '||v_ind_sid);
	END IF;

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to region '||v_region_sid);
	END IF;

	user_pkg.GetSid(in_act_id, v_user_sid);
	
	UPDATE VAL_NOTE
	   SET NOTE = in_note,
	  		entered_by_sid = v_user_sid,
			entered_dtm = SYSDATE
	 WHERE VAL_NOTE_ID = in_val_note_id;
END;

PROCEDURE DeleteNote(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_val_note_id			IN	VAL_NOTE.val_note_id%TYPE
)
AS
	v_ind_sid		SECURITY_PKG.T_SID_ID;
	v_region_sid	SECURITY_PKG.T_SID_ID;
	CURSOR c IS
		SELECT ind_sid, region_sid
		  FROM VAL_NOTE vn
		 WHERE vn.VAL_note_ID = in_val_note_id;
BEGIN
	OPEN c;
	FETCH c INTO v_ind_sid, v_region_sid;
	-- do we have permission on this indicator and this region?
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_ind_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to ind '||v_ind_sid);
	END IF;

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to region '||v_region_sid);
	END IF;

	DELETE FROM VAL_NOTE
	 WHERE VAL_NOTE_ID = in_val_note_id;
END;

PROCEDURE GetValChangeList(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_val_id			IN security_pkg.T_SID_ID,
	in_order_by			IN	VARCHAR2, -- not used
	out_cur				OUT SYS_REFCURSOR
)
AS
	CURSOR c IS
    	SELECT ind_sid, region_sid, period_start_dtm, period_end_dtm FROM val WHERE val_id = in_val_id;
    r	c%ROWTYPE;
BEGIN
	IF in_val_id = 0 THEN
    	OPEN out_cur FOR
	        SELECT null val_change_id, null changed_dtm, null changed_dtm_fmt, null changed_by_sid, null full_name,
            	   null reason, null val_number, null uom, null entry_val_number, null entry_uom, null format_mask
              FROM DUAL
             WHERE 0=1; -- return blank recordset
        RETURN;
    END IF;

	OPEN c;
    FETCH c INTO r;

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, r.ind_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, r.region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ val_change_id, changed_dtm, TO_CHAR(changed_dtm,'dd Mon yyyy hh24:mi')||' GMT' changed_dtm_fmt, 
			   changed_by_sid, NVL(cu.full_name, 'System Administrator') full_name, 
		       reason, val_number, m.description uom, entry_val_number, mc.description entry_uom,
		       NVL(i.format_mask, m.format_mask) format_mask
		  FROM val_change vc
			JOIN ind i ON vc.ind_sid = i.ind_sid AND vc.app_sid = i.app_sid
			JOIN csr_user cu ON vc.changed_by_sid = cu.csr_user_sid AND vc.app_sid = cu.app_sid
			JOIN measure m ON i.measure_sid = m.measure_sid AND i.app_sid = m.app_sid
			LEFT JOIN measure_conversion mc ON vc.entry_measure_conversion_Id = mc.measure_conversion_id
		 WHERE vc.ind_sid = r.ind_sid
		   AND vc.region_sid = r.region_sid
		   AND vc.period_Start_dtm = r.period_start_dtm
		   AND vc.period_end_dtm = r.period_end_dtm
		 ORDER BY val_change_id;
END;

PROCEDURE UNSEC_GetValEnteredAsInfo(
	in_val_ids			IN	security_pkg.T_SID_IDS,
	out_cur				OUT SYS_REFCURSOR
)
AS
	v_val_ids			security.T_SID_TABLE := security_pkg.SidArrayToTable(in_val_ids);
BEGIN
	OPEN out_cur FOR
		SELECT val_id, ind_sid, region_sid, val_number, entry_measure_conversion_id, entry_val_number
		  FROM val v
	 LEFT JOIN measure_conversion mc ON mc.measure_conversion_id = v.entry_measure_conversion_id
		 WHERE val_id IN (SELECT column_value FROM TABLE(v_val_ids))
		   AND v.app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE INTERNAL_GetValues(
	in_act_id			    IN	security_pkg.T_ACT_ID,
	in_ind_sid			    IN	security_pkg.T_SID_ID,
	in_region_sid		    IN	security_pkg.T_SID_ID,
	in_period_start_dtm     IN	DATE,
	in_period_end_dtm 	    IN	DATE,
	in_interval			    IN	CHAR,
	in_ignore_pct_ownership IN  NUMBER,
	v_table				    IN	OUT	T_VAL_TABLE
)
AS
	v_app_sid					security_pkg.T_SID_ID	DEFAULT SYS_CONTEXT('SECURITY', 'APP');
    v_interval_months			NUMBER(10);
    v_seek_period_start_dtm	 	DATE;
	v_seek_period_end_dtm		DATE;
    v_this_duration				NUMBER(10);
	v_this_val_number			VAL.VAL_NUMBER%TYPE;
	v_this_is_estimated 		NUMBER(10);
    v_this_val_flags 			NUMBER(10);
    v_this_val_is_null 			NUMBER(10);
    v_start_dtm					DATE;
	v_end_dtm					DATE;
	v_val_number				VAL.VAL_NUMBER%TYPE;
	v_duration 					NUMBER(10);
    v_data_duration  			NUMBER(10);
	v_ids_used					VARCHAR2(2000);
	v_most_recent_change_dtm	DATE;
	CURSOR c_i IS
		SELECT NVL(i.divisibility, m.divisibility) divisibility
		  FROM ind i
		  LEFT JOIN measure m ON i.measure_sid = m.measure_sid
		 WHERE i.ind_sid = in_ind_sid;
	r_i		c_i%ROWTYPE;
	CURSOR c_empty IS -- used as a template for c_type
 		SELECT val_id, period_start_dtm, period_end_dtm, val_number, flags, SYSDATE changed_dtm
 		  FROM val
 		 WHERE 1 = 0;
	TYPE c_type IS REF CURSOR RETURN c_empty%ROWTYPE;
	c   c_type;
	r						c%ROWTYPE;
	r_check					c%ROWTYPE;
BEGIN
	-- turn interval into a number of months - if we need more granularity
	-- this could easily be added in future
	IF in_interval = 'm' THEN
		v_interval_months := 1;
	ELSIF in_interval = 'q' THEN
		v_interval_months := 3;
	ELSIF in_interval = 'h' THEN
		v_interval_months := 6;
	ELSIF in_interval = 'y' THEN
		v_interval_months := 12;
	ELSE
		RAISE_APPLICATION_ERROR(-20001, 'Interval not known');
	END IF;
	-- read in divisibility of indicator
	OPEN c_i;
	FETCH c_i INTO r_i;
	CLOSE c_i;
	-- open up data loop
	IF in_ignore_pct_ownership = 1 THEN
        OPEN c FOR
            SELECT v.val_id, v.period_start_dtm, v.period_end_dtm, v.val_number, v.flags, v.changed_dtm
              FROM val_converted v
             WHERE v.app_sid = v_app_sid
               AND v.region_sid = in_region_sid
               AND v.ind_sid = in_ind_sid
               AND v.period_end_dtm > in_period_start_dtm -- looks perverse but this gets fragments on boundaries too
               AND v.period_start_dtm < in_period_end_dtm
               AND v.val_number IS NOT NULL -- ignore null values
          ORDER BY v.period_start_dtm, v.period_end_dtm DESC;
	ELSE
        OPEN c FOR
            SELECT v.val_id, v.period_start_dtm, v.period_end_dtm, v.val_number, v.flags, v.changed_dtm
              FROM val v
             WHERE v.app_sid = v_app_sid
               AND v.region_sid = in_region_sid 
               AND v.ind_sid = in_ind_sid
               AND v.period_end_dtm > in_period_start_dtm -- looks perverse but this gets fragments on boundaries too
               AND v.period_start_dtm < in_period_end_dtm
               AND v.val_number IS NOT NULL -- ignore null values
          ORDER BY v.period_start_dtm, v.period_end_dtm DESC;
	END IF;
	
	FETCH c INTO r;
	-- set up the seek_period variables which determine which period we are
	-- getting data for
    v_seek_period_start_dtm := in_period_start_dtm;
    v_seek_period_end_dtm := ADD_MONTHS(v_seek_period_start_dtm, v_interval_months);
    -- go through each period in turn, interval by interval
	<<each_period>>
	WHILE v_seek_period_start_dtm < in_period_end_dtm
	LOOP
        -- if the data starts and ends before our period then eat more of it until it fits
		<<eat_irrelevant_historic_data>>
		WHILE r.period_end_dtm <= v_seek_period_start_dtm AND NOT c%NOTFOUND
		LOOP
			FETCH c INTO r;
        END LOOP eat_irrelevant_historic_data;
		-- set basic values about this period to initial state
        v_this_duration := 0;
        v_this_is_estimated := 0;
        v_this_val_number := 0;
        v_this_val_is_null := 1;
		v_this_val_flags := 0;
		v_most_recent_change_dtm := NULL;
		v_ids_used := NULL;
        IF NOT c%NOTFOUND THEN
            -- ASSUMPTION: data ends after our seek period start
			<<aggregate_data_for_period>>
            WHILE r.period_start_dtm < v_seek_period_end_dtm AND NOT c%NOTFOUND
			LOOP
                -- crop date off either side of our period
				v_start_dtm := GREATEST(v_seek_period_start_dtm, r.period_start_dtm);
                v_end_dtm := LEAST(v_seek_period_end_dtm, r.period_end_dtm);     
                -- get duration in days
                v_duration := v_end_dtm - v_start_dtm;
				-- set the actual value
                IF r_i.divisibility = csr_data_pkg.DIVISIBILITY_DIVISIBLE THEN
                    -- if divisble, then get a proportional value for this period
                    v_data_duration := r.period_end_dtm - r.period_start_dtm;
					-- for val
                    v_val_number := r.val_number * v_duration / (r.period_end_dtm - r.period_start_dtm);
                    v_this_val_number := v_this_val_number + v_val_number;
					-- is this estimated?
                    IF v_duration <> v_data_duration THEN
						v_this_is_estimated := 1;
					END IF;
                ELSIF r_i.divisibility = csr_data_pkg.DIVISIBILITY_AVERAGE THEN
                    -- if not divisible, then average this out over differing periods for val
                    v_val_number := r.val_number;
                    v_this_val_number := (v_this_val_number * v_this_duration + v_val_number * v_duration) / (v_this_duration + v_duration);
					-- is this estimated?
                    IF v_this_duration <> 0 THEN
						v_this_is_estimated := 1;
					END IF;
                    v_this_duration := v_this_duration + v_duration;                    
                ELSIF r_i.divisibility = csr_data_pkg.DIVISIBILITY_LAST_PERIOD THEN
                	-- if using last period, just keep track of that
                	v_val_number := r.val_number;
                    v_this_val_number := v_val_number;
                    v_ids_used := NULL; -- we'll set this in a minute
                END IF;
				-- OR flags together
				v_this_val_flags := bitwise_pkg.bitor(v_this_val_flags, r.flags);
				-- mark as not null
                v_this_val_is_null := 0;
				-- record which id was used
				IF v_ids_used IS NULL THEN
					v_ids_used := r.val_id;
				ELSE
					v_ids_used := v_ids_used || ',' || r.val_id;
				END IF;
				-- figure out most recent change (i.e. for things like 'show me stuff that has changed since...')				
				-- we wrap with NVL, so if it's the first one we use it
                v_most_recent_change_dtm := GREATEST(NVL(v_most_recent_change_dtm,r.changed_dtm), r.changed_dtm);
				-- what next? shove this value in DB, or get more data?
                IF v_seek_period_end_dtm <= r.period_end_dtm THEN
                    -- no need for new numbers, we're busy enough with this one
                    EXIT aggregate_data_for_period;
                ELSE
                    /* get some more data, but swallow anything which starts before the end of the
                       last data we shoved into our overall value for this period.
                       e.g.
                       J  F  M  A  M  J  J  A  (seek period is Jan -> end June)
                       |--------|        |     (used)
                       |     |-----|     |     (discarded)
                       |        |--------|--|  (used - both parts)
                       |              |--|     (discarded)
					*/
					<<eat_intermediate_data>>
                    WHILE NOT c%NOTFOUND
					LOOP
                        FETCH c INTO r_check;
                        IF r_check.period_start_dtm >= r.period_end_dtm THEN
                            r := r_check;
                            EXIT eat_intermediate_data;
                        END IF;
                    END LOOP eat_intermediate_data;
                END IF;
            END LOOP aggregate_data_for_period;
        END IF;
		-- store data
	    v_table.extend;
	    v_table ( v_table.COUNT ) := T_VAL_ROW (v_seek_period_start_dtm, v_seek_period_end_dtm,
			v_this_val_number, v_this_val_is_null,
			v_this_is_estimated, v_ids_used, in_region_sid, v_this_val_flags, v_most_recent_change_dtm);
        -- move to next seek period
        v_seek_period_start_dtm := v_seek_period_end_dtm;
	    v_seek_period_end_dtm := ADD_MONTHS(v_seek_period_start_dtm, v_interval_months);
    END LOOP each_period;
END;

FUNCTION GetValuesAsTable(
	in_act_id			    IN	security_pkg.T_ACT_ID,
	in_ind_sid			    IN	security_pkg.T_SID_ID,
	in_region_sid		    IN	security_pkg.T_SID_ID,
	in_period_start_dtm  	IN  DATE,
	in_period_end_dtm 		IN  DATE,
	in_interval			    IN	CHAR,
	in_ignore_pct_ownership IN  NUMBER
) RETURN T_VAL_TABLE
AS
	v_table					T_VAL_TABLE := T_VAL_TABLE();
BEGIN
	INTERNAL_GetValues(in_act_id, in_ind_sid, in_region_sid,
		in_period_start_dtm, in_period_end_dtm, in_interval, in_ignore_pct_ownership, v_table);
	-- return table
	RETURN v_table;
END;

PROCEDURE GetValues(
	in_act_id			    IN	security_pkg.T_ACT_ID,
	in_ind_sid			    IN	security_pkg.T_SID_ID,
	in_region_sid		    IN	security_pkg.T_SID_ID,
	in_start_dtm		    IN	DATE,
	in_end_dtm			    IN	DATE,
	in_interval			    IN	CHAR,
	in_ignore_pct_ownership IN  NUMBER,
	out_cur			    	OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT period_start_dtm, period_end_dtm, val_number, val_null,
			estimated, val_ids_used, region_sid, flags, most_recent_change_dtm
		  FROM TABLE(Indicator_Pkg.getValuesAsTable(in_act_id, in_ind_sid,
		  	in_region_sid, in_start_dtm, in_end_dtm, in_interval, in_ignore_pct_ownership))
		 ORDER BY period_start_dtm;
END;

PROCEDURE GetValuesForRegionList(
	in_act_id			    IN	security_pkg.T_ACT_ID,
	in_ind_sid			    IN	security_pkg.T_SID_ID,
	in_start_dtm		    IN	DATE,
	in_end_dtm			    IN	DATE,
	in_interval			    IN	CHAR,
	in_ignore_pct_ownership IN  NUMBER,
	out_cur				    OUT SYS_REFCURSOR
)
AS
	v_table					T_VAL_TABLE := T_VAL_TABLE();
BEGIN
	FOR r IN (SELECT region_sid FROM region_list) LOOP
		INTERNAL_GetValues(in_act_id, in_ind_sid, r.region_sid,
			in_start_dtm, in_end_dtm, in_interval, in_ignore_pct_ownership, v_table);
	END LOOP;

	OPEN out_cur FOR
		SELECT in_ind_sid ind_sid, period_start_dtm, period_end_dtm, val_number, val_null, flags,
			estimated, val_ids_used, region_sid, most_recent_change_dtm
		  FROM TABLE(v_table)
		 ORDER BY region_sid, period_start_dtm;
END;

PROCEDURE GetIndicatorFromKey(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_app_sid			IN security_pkg.T_SID_ID,
	in_lookup_key		IN ind.lookup_key%TYPE,
	out_cur				OUT SYS_REFCURSOR
)
AS
    v_sid   security_pkg.T_SID_ID;
BEGIN
    BEGIN
        SELECT ind_sid
          INTO v_sid
          FROM ind
         WHERE UPPER(lookup_key) = UPPER(in_lookup_key)
           AND app_sid = in_app_sid;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'Indicator not found with key '||in_lookup_key);
    END;
    -- GetIndicator will do our security checking...
    GetIndicator(in_act_id, v_sid, out_cur);
END;

PROCEDURE GetIndicator_INSECURE(
	in_ind_sid			IN security_pkg.T_SID_ID,
	out_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT i.ind_sid, i.NAME, i.description, i.lookup_key, m.NAME measure_name, m.description measure_description,m.measure_sid,
			   i.gri, i.multiplier,	NVL(i.scale,m.scale) scale, NVL(i.format_mask, m.format_mask) format_mask, i.active,
			   i.scale actual_scale, i.format_mask actual_format_mask, i.calc_xml,
			   NVL(i.divisibility, m.divisibility) divisibility, i.divisibility actual_divisibility, i.start_month,
			   CASE
					WHEN i.measure_sid IS NULL THEN 'Category'
					WHEN i.ind_type = Csr_Data_Pkg.IND_TYPE_CALC THEN 'Calculation'
					WHEN i.ind_type = Csr_Data_Pkg.IND_TYPE_STORED_CALC THEN 'Stored calculation'
					ELSE 'Indicator'
			   END node_type, i.ind_type, i.calc_start_dtm_adjustment, i.calc_end_dtm_adjustment,
			   i.period_set_id, i.period_interval_id, i.do_temporal_aggregation, i.calc_description, 
			   i.target_direction, i.last_modified_dtm,  extract(i.info_xml,'/').getClobVal() info_xml, i.parent_sid, i.pos, i.aggregate, 
			   i.tolerance_type, i.pct_lower_tolerance, i.pct_upper_tolerance,
			   i.tolerance_number_of_periods, i.tolerance_number_of_standard_deviations_from_average,
			   i.factor_type_id, i.ind_activity_type_id, 
			   i.gas_measure_sid, i.gas_type_id, i.map_to_ind_sid, ft.name factor_type_name, i.normalize,
			   i.core, i.roll_forward, i.prop_down_region_tree_sid, i.is_system_managed, i.calc_fixed_start_dtm, i.calc_fixed_end_dtm,
			   i.calc_output_round_dp,
			   (SELECT STRAGG(label) label -- should never be > 1 row but...
			   	  FROM aggregate_ind_group aig 
			   	  JOIN aggregate_ind_group_member aigm ON aig.aggregate_ind_group_Id = aigm.aggregate_ind_group_id
			   	 WHERE aigm.ind_sid = in_ind_sid
			   ) aggregate_ind_group,
			   (SELECT COUNT(*) FROM (SELECT 1 FROM DUAL WHERE EXISTS (SELECT null FROM val WHERE ind_sid = in_ind_sid))) has_values,
			   CASE WHEN rm.ind_sid IS NOT NULL THEN 1 ELSE 0 END is_region_metric,
			   (SELECT COUNT(*) FROM (SELECT 1 FROM DUAL WHERE EXISTS (SELECT null FROM region_metric_val WHERE ind_sid = in_ind_sid))) has_region_metric_values,
			   ft.name factor_type_description
		  FROM v$ind i
		  LEFT JOIN factor_type ft ON i.factor_type_id = ft.factor_type_id
		  LEFT JOIN measure m ON i.measure_sid = m.measure_sid
		  LEFT JOIN region_metric rm ON i.ind_sid = rm.ind_sid
		 WHERE i.ind_sid = in_ind_sid;
END;

PROCEDURE GetIndicator(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_ind_sid						IN	security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
)
AS                      			
BEGIN
	INTERNAL_EnsureIndExists(in_ind_sid);	
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_ind_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on indicator '||in_ind_sid);
	END IF;
	GetIndicator_INSECURE(in_ind_sid, out_cur);
END;

PROCEDURE GetIndicators(
	in_ind_sids						IN	security_pkg.T_SID_IDS,
	in_skip_missing					IN	NUMBER DEFAULT 0,
	in_skip_denied					IN	NUMBER DEFAULT 0,
	out_ind_cur						OUT	SYS_REFCURSOR,
	out_tag_cur						OUT	SYS_REFCURSOR
)
AS
	v_cur							SYS_REFCURSOR;
BEGIN
	GetIndicators(in_ind_sids, in_skip_missing, in_skip_denied, 0, out_ind_cur, out_tag_cur, v_cur);
END;


PROCEDURE GetIndicators(
	in_ind_sids						IN	security_pkg.T_SID_IDS,
	in_skip_missing					IN	NUMBER DEFAULT 0,
	in_skip_denied					IN	NUMBER DEFAULT 0,
	in_ignore_trashed				IN	NUMBER DEFAULT 0,
	out_ind_cur						OUT	SYS_REFCURSOR,
	out_tag_cur						OUT	SYS_REFCURSOR,
	out_trashed_inds				OUT SYS_REFCURSOR
)
AS
	v_ind_sids						security.T_ORDERED_SID_TABLE;
	v_ordered_ind_sids				security.T_ORDERED_SID_TABLE;
	v_allowed_ind_sids				security.T_SO_TABLE;
	v_first_sid						ind.ind_sid%TYPE;
	v_act							security_pkg.T_ACT_ID;
BEGIN
	v_act := SYS_CONTEXT('SECURITY', 'ACT');

	-- Check the permissions / existence of indicator sids as directed
	v_ordered_ind_sids := security_pkg.SidArrayToOrderedTable(in_ind_sids);
	v_allowed_ind_sids := securableObject_pkg.GetSIDsWithPermAsTable(
		v_act, 
		security_pkg.SidArrayToTable(in_ind_sids), 
		security_pkg.PERMISSION_READ
	);

	-- skipping missing and denied can be done in one step
	-- paths: skip missing=M, skip denied=D MD; cases 00, 01, 10, 11
	IF in_skip_missing = 1 AND in_skip_denied = 1 THEN -- 11
		SELECT security.T_ORDERED_SID_ROW(rp.sid_id, rp.pos)
		  BULK COLLECT INTO v_ind_sids
		  FROM ind r,
		  	   TABLE(v_ordered_ind_sids) rp,
		  	   TABLE(v_allowed_ind_sids) ar
		 WHERE r.ind_sid = rp.sid_id
		   AND ar.sid_id = r.ind_sid
		   AND ar.sid_id = rp.sid_id;
		   
	-- otherwise check separately, according to preferences
	ELSE
		IF in_skip_missing = 1 THEN -- 10 (M=1 and D!=1 by first if statement)
			SELECT security.T_ORDERED_SID_ROW(rp.sid_id, rp.pos)
			  BULK COLLECT INTO v_ind_sids
			  FROM ind r,
			  	   TABLE(v_ordered_ind_sids) rp
			 WHERE r.ind_sid = rp.sid_id;
			 
			v_ordered_ind_sids := v_ind_sids;
		ELSE -- 00 or 01
			-- report missing, if any
			SELECT MIN(ii.sid_id)
			  INTO v_first_sid
			  FROM TABLE(v_ordered_ind_sids) ii
			  LEFT JOIN ind i
			    ON i.ind_sid = ii.sid_id
			 WHERE i.ind_sid IS NULL;

			IF v_first_sid IS NOT NULL THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND,
					'The indicator with sid '||v_first_sid||' does not exist');			
			END IF;
		END IF;
		
		IF in_skip_denied = 1 THEN -- 01 (D=1 and M!=0 by first if statement)
			SELECT security.T_ORDERED_SID_ROW(rp.sid_id, rp.pos)
			  BULK COLLECT INTO v_ind_sids
			  FROM TABLE(v_allowed_ind_sids) ar
			  JOIN TABLE(v_ordered_ind_sids) rp
			    ON ar.sid_id = rp.sid_id;
		ELSE -- 00 or 10
			SELECT MIN(sid_id)
			  INTO v_first_sid
			  FROM TABLE(v_ordered_ind_sids) rp
			 WHERE sid_id NOT IN (
			 		SELECT sid_id
			 		  FROM TABLE(v_allowed_ind_sids))
			   AND (in_ignore_trashed = 0 OR sid_id NOT IN (SELECT trash_sid FROM csr.trash));
			  
			IF v_first_sid IS NOT NULL THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
					'Read permission denied on the ind with sid '||v_first_sid||' and skip trashed is '||in_ignore_trashed);
			END IF;
			
			-- 00 => no ind sids set, use input
			IF in_skip_missing = 0 THEN
				v_ind_sids := v_ordered_ind_sids;
			END IF;
		END IF;
	END IF;
	
	OPEN out_ind_cur FOR
		SELECT i.ind_sid, i.NAME, i.description, i.lookup_key, m.NAME measure_name, m.description measure_description,m.measure_sid,
			   i.gri, i.multiplier,	NVL(i.scale,m.scale) scale, NVL(i.format_mask, m.format_mask) format_mask, i.active,
			   i.scale actual_scale, i.format_mask actual_format_mask, i.calc_xml,
			   NVL(i.divisibility, m.divisibility) divisibility, i.divisibility actual_divisibility, i.start_month,
			   CASE
					WHEN i.measure_sid IS NULL THEN 'Category'
					WHEN i.ind_type = Csr_Data_Pkg.IND_TYPE_CALC THEN 'Calculation'
					WHEN i.ind_type = Csr_Data_Pkg.IND_TYPE_STORED_CALC THEN 'Stored calculation'
					ELSE 'Indicator'
			   END node_type, i.ind_type, i.calc_start_dtm_adjustment, i.calc_end_dtm_adjustment,
			   i.period_set_id, i.period_interval_id, i.do_temporal_aggregation, i.calc_description, 
			   i.target_direction, i.last_modified_dtm,  extract(i.info_xml,'/').getClobVal() info_xml, i.parent_sid, i.pos, i.aggregate, 
			   i.tolerance_type, i.pct_lower_tolerance, i.pct_upper_tolerance,
			   i.tolerance_number_of_periods, i.tolerance_number_of_standard_deviations_from_average,
			   i.factor_type_id, i.ind_activity_type_id, 
			   i.gas_measure_sid, i.gas_type_id, i.map_to_ind_sid, ft.name factor_type_name, i.normalize,
			   i.core, i.roll_forward, i.prop_down_region_tree_sid, i.is_system_managed, i.calc_fixed_start_dtm, i.calc_fixed_end_dtm,
			   i.calc_output_round_dp, INTERNAL_GetIndPathString(i.ind_sid) path, CASE
					WHEN i.measure_sid IS NULL THEN 'CSRCategory'
					WHEN i.ind_type = Csr_Data_Pkg.IND_TYPE_CALC THEN 'CSRCalculation'
					WHEN i.ind_type = Csr_Data_Pkg.IND_TYPE_STORED_CALC THEN 'CSRStoredCalc'
					ELSE 'CSRIndicator'
			   END class_name
		  FROM TABLE(v_ind_sids) s
		  JOIN v$ind i ON s.sid_id = i.ind_sid
		  LEFT JOIN factor_type ft ON i.factor_type_id = ft.factor_type_id
		  LEFT JOIN measure m ON i.measure_sid = m.measure_sid
		 WHERE (in_ignore_trashed = 0 OR i.ind_sid NOT IN (SELECT trash_sid FROM csr.trash))
		 ORDER BY s.pos;

	OPEN out_tag_cur FOR
		SELECT itg.ind_sid, itg.tag_id
		  FROM TABLE(v_ind_sids) s, ind_tag itg
		 WHERE itg.ind_sid = s.sid_id
		 ORDER BY itg.ind_sid, itg.tag_id;
	
	OPEN out_trashed_inds FOR
		SELECT sid_id ind_sid
		  FROM TABLE(v_ordered_ind_sids) i
		  JOIN trash t ON i.sid_id = t.trash_sid AND t.app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetIndicatorAccuracyTypes(
	in_act_id	IN	security_pkg.T_ACT_ID,
	in_ind_sid	IN	security_pkg.T_SID_ID,
	out_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_ind_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on indicator '||in_ind_sid);
	END IF;

	OPEN out_cur FOR
		SELECT accuracy_type_id FROM ind_accuracy_type
		 WHERE ind_sid = in_ind_sid;
END;

PROCEDURE GetIndicatorsForList(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_indicator_list	IN	VARCHAR2,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT i.ind_sid, i.NAME, i.description, i.lookup_key, m.name measure_name, m.description measure_description,m.measure_sid,
			   i.gri, multiplier,	NVL(i.scale,m.scale) scale, NVL(i.format_mask, m.format_mask) format_mask, active,
			   i.scale actual_scale, i.format_mask actual_format_mask, i.calc_xml,
			   NVL(i.divisibility, m.divisibility) divisibility, i.divisibility actual_divisibility, i.start_month,
			   CASE
					WHEN i.measure_sid IS NULL THEN 'Category'
					WHEN i.ind_type=Csr_Data_Pkg.IND_TYPE_CALC THEN 'Calculation'
					WHEN i.ind_type=Csr_Data_Pkg.IND_TYPE_STORED_CALC THEN 'Stored calculation'
					ELSE 'Indicator'
			   END node_type, ind_type, calc_start_dtm_adjustment, calc_end_dtm_adjustment,
			   target_direction , last_modified_dtm, extract(info_xml,'/').getClobVal() info_xml, i.parent_sid, i.pos, 
			   tolerance_type, pct_lower_tolerance, pct_upper_tolerance,
			   tolerance_number_of_periods, tolerance_number_of_standard_deviations_from_average,
			   i.ind_activity_type_id, i.core, i.roll_forward
		  FROM v$ind i, measure m, TABLE(Utils_Pkg.SplitString(in_indicator_list,','))l
		 WHERE i.measure_sid = m.measure_sid(+)
		   AND l.item = i.ind_sid
		   AND security_pkg.SQL_IsAccessAllowedSID(in_act_id, l.item, security_pkg.PERMISSION_READ)=1
		 ORDER BY l.pos;
END;

PROCEDURE GetIndicatorChildren_INSECURE(
	in_parent_sid		IN security_pkg.T_SID_ID,
	out_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT i.ind_sid, i.NAME, i.description, i.lookup_key, m.NAME measure_name, m.description measure_description,m.measure_sid,
			   i.gri, multiplier, NVL(i.scale,m.scale) scale, NVL(i.format_mask, m.format_mask) format_mask, active,
			   i.scale actual_scale, i.format_mask actual_format_mask, i.calc_xml, 
			   NVL(i.divisibility, m.divisibility) divisibility, i.divisibility actual_divisibility, i.start_month,
			   CASE
					WHEN i.measure_sid IS NULL THEN 'Category'
					WHEN i.ind_type = Csr_Data_Pkg.IND_TYPE_CALC THEN 'Calculation'
					WHEN i.ind_type = Csr_Data_Pkg.IND_TYPE_STORED_CALC THEN 'Stored calculation'
					ELSE 'Indicator'
				END node_type, i.ind_type, i.calc_start_dtm_adjustment, i.calc_end_dtm_adjustment,
				i.period_set_id, i.period_interval_id, 
				i.do_temporal_aggregation, i.calc_description,
				i.target_direction, i.last_modified_dtm, extract(i.info_xml,'/').getClobVal() info_xml, i.parent_sid, i.pos, i.aggregate, 
				i.tolerance_type, i.pct_lower_tolerance, i.pct_upper_tolerance, 
				i.tolerance_number_of_periods, i.tolerance_number_of_standard_deviations_from_average,
				i.ind_activity_type_id, 
				i.core, i.roll_forward, i.gas_measure_sid, i.gas_type_id, i.map_to_ind_sid, i.factor_type_id, i.normalize, i.prop_down_region_tree_sid, i.is_system_managed
		   FROM v$ind i, measure m
		  WHERE i.measure_sid = m.measure_sid(+)
		    AND i.parent_sid = in_parent_sid;
END;

PROCEDURE GetIndicatorChildren(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_parent_sid		IN security_pkg.T_SID_ID,
	out_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_parent_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	GetIndicatorChildren_INSECURE(in_parent_sid, out_cur);
END;

-- internal func so doesn't check security - assumes caller will
FUNCTION INTERNAL_GetIndPathString(
	in_ind_sid			IN security_pkg.T_SID_ID
) RETURN VARCHAR2
AS
	v_s	VARCHAR2(4095);
BEGIN
	v_s := NULL;
	FOR r IN (
		SELECT ind_sid, description
		  FROM v$ind
		 START WITH ind_sid = in_ind_sid 
		 CONNECT BY NOCYCLE PRIOR parent_sid = ind_sid
		 ORDER BY LEVEL DESC
		 )
	LOOP
		IF v_s IS NOT NULL THEN
			v_s := v_s || ' / ';
		END IF;
		v_s := v_s || r.description;
	END LOOP;
	RETURN v_s;
END;

PROCEDURE GetIndicatorPath(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_ind_sid			IN security_pkg.T_SID_ID,
	out_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_ind_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT ind_sid, description
		  FROM v$ind
		 START WITH ind_sid = in_ind_sid CONNECT BY PRIOR parent_sid = ind_sid
		 ORDER BY LEVEL DESC;
END;

PROCEDURE GetIndicatorDescriptions(
	in_ind_sids			IN security_pkg.T_SID_IDS,
	out_ind_desc_cur	OUT SYS_REFCURSOR
)
AS
	v_ind_sid_table			security.T_SID_TABLE := security_pkg.SidArrayToTable(in_ind_sids);
	v_ind_sid_table_allowed	security.T_SID_TABLE := security.T_SID_TABLE();
	v_ind_sid_list_allowed	security_pkg.T_SID_IDS;
BEGIN
	FOR r IN (
		SELECT column_value
		  FROM TABLE(v_ind_sid_table)
	)
	LOOP
		IF security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), r.column_value, security_pkg.PERMISSION_READ) THEN
			v_ind_sid_table_allowed.extend();
			v_ind_sid_table_allowed(v_ind_sid_table_allowed.COUNT) := r.column_value;
		END IF;
	END LOOP;

	SELECT column_value
	  BULK COLLECT INTO v_ind_sid_list_allowed
	  FROM TABLE(v_ind_sid_table_allowed);

	GetIndicatorDescriptions_UNSEC(v_ind_sid_list_allowed, out_ind_desc_cur);
END;

PROCEDURE GetIndicatorDescriptions_UNSEC(
	in_ind_sids			IN security_pkg.T_SID_IDS,
	out_ind_desc_cur	OUT SYS_REFCURSOR
)
AS
	v_ind_sid_table		security.T_SID_TABLE := security_pkg.SidArrayToTable(in_ind_sids);
BEGIN
	OPEN out_ind_desc_cur FOR
		SELECT vi.ind_sid, vi.description
		  FROM v$ind vi
		  JOIN TABLE(v_ind_sid_table) ist
		    ON vi.ind_sid = ist.column_value;
END;

/**
 * Sets XML and optionally removes rows from the calc dependency table
 *
 * @param	in_act_id			Access token
 * @param	in_calc_ind_sid		The indicator
 * @param	in_calc_xml			The xml
 * @param	in_ind_type			The type of indicator
 * @param	in_remove_deps		Whether to remove dependencies or not
 *
 * See also calc_pkg.SetCalcXML and calc_pkg.SetCalcXMLAndDeps
 */
PROCEDURE SetCalcXML(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_calc_ind_sid			IN security_pkg.T_SID_ID,
	in_calc_xml				IN IND.calc_xml%TYPE,
	in_ind_type				IN ind.ind_type%TYPE DEFAULT Csr_Data_Pkg.IND_TYPE_CALC,
	in_remove_deps			IN NUMBER DEFAULT 1
)
AS
	v_ind_type				ind.ind_type%TYPE;
BEGIN
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_calc_ind_sid, Csr_Data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied altering schema');
	END IF;

	SELECT ind_type
	  INTO v_ind_type
	  FROM ind
	 WHERE ind_sid = in_calc_ind_sid;

	IF v_ind_type = csr_data_pkg.IND_TYPE_AGGREGATE OR in_ind_type = csr_data_pkg.IND_TYPE_AGGREGATE THEN
		RAISE_APPLICATION_ERROR(-20001, 'System calculated indicators can not have a calc_xml.');
	END IF;

	UPDATE ind
	   SET calc_xml = in_calc_xml, ind_type = in_ind_type, last_modified_dtm = SYSDATE
	 WHERE ind_sid = in_calc_ind_sid;

	IF in_remove_deps = 1 THEN
		DELETE FROM calc_dependency 
		 WHERE calc_ind_sid = in_calc_ind_sid;
	END IF;
END;

PROCEDURE GetDataOverviewIndicators(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_root_indicator_sids	IN security_pkg.T_SID_IDS,
	in_app_sid				IN security_pkg.T_SID_ID,
	out_cur					OUT SYS_REFCURSOR,
	out_tag_groups_cur		OUT SYS_REFCURSOR,
	out_ind_tag_cur			OUT SYS_REFCURSOR,
	out_flags_cur			OUT	SYS_REFCURSOR,
	out_ind_baseline_cur	OUT SYS_REFCURSOR
) IS
    t security.T_SID_TABLE;
BEGIN
    t := security_pkg.SidArrayToTable(in_root_indicator_sids);

	-- Check that the user has list contents permission on this object
	FOR r IN (
        SELECT column_value ind_sid
          FROM TABLE(t)
    )
    LOOP
        IF NOT Security_Pkg.IsAccessAllowedSID(in_act_id, r.ind_sid, Security_Pkg.PERMISSION_LIST_CONTENTS) THEN
            RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 
                'Permission denied listing contents on the object with sid '||r.ind_sid);
        END IF;
    END LOOP;
    
	OPEN out_cur FOR
		SELECT i.ind_sid, i.description, i.measure_sid, i.calc_xml,
			   m.description measure_description, i.ind_type, lvl so_level,  extract(i.info_xml,'/').getclobval() info_xml, m.custom_field,
			   i.aggregate, nvl(i.format_mask, m.format_mask) format_mask, 
			   i.tolerance_type, i.pct_upper_tolerance, i.pct_lower_tolerance,
			   i.tolerance_number_of_periods, i.tolerance_number_of_standard_deviations_from_average,
			   nvl(i.scale, m.scale) scale, NVL(i.divisibility, m.divisibility) divisibility, i.active, i.roll_forward, i.calc_description, 
			   i.do_temporal_aggregation, i.period_set_id, i.period_interval_id, ft.name factor_name, gt.name gas_name, 
			   em.description gas_measure_description, 
			   i.target_direction, i.normalize, i.start_month, i.lookup_key,
			   CASE WHEN rm.ind_sid IS NOT NULL THEN 1 ELSE 0 END is_region_metric, i.parent_sid
		  FROM measure m, v$ind i, measure em, gas_type gt, factor_type ft, region_metric rm, (
			SELECT ind_sid, rownum rn, level lvl
			  FROM v$ind
			 --WHERE active = 1 -- THIS IS WRONG - SHOULD BE IN THE CONNECT BY?
			 START WITH ind_sid IN (
                   SELECT column_value FROM TABLE(t)
             )
		   CONNECT BY PRIOR ind_sid = parent_sid
			 ORDER SIBLINGS BY 
				REGEXP_SUBSTR(LOWER(description), '^\D*') NULLS FIRST, 
				TO_NUMBER(REGEXP_SUBSTR(LOWER(description), '[0-9]+')) NULLS FIRST, 
				TO_NUMBER(CONCAT('0.', REGEXP_SUBSTR(LOWER(description), '[0-9]+', 1, 2))) NULLS FIRST,
				TO_NUMBER(CONCAT('0.', REGEXP_SUBSTR(LOWER(description), '[0-9]+', 1, 3))) NULLS FIRST,
				TO_NUMBER(CONCAT('0.', REGEXP_SUBSTR(LOWER(description), '[0-9]+', 1, 4))) NULLS FIRST,
				LOWER(description), ind_sid
			 ) t
		 WHERE i.measure_sid = M.measure_sid(+) 
		   AND i.factor_type_id = ft.factor_type_id(+)
		   AND i.gas_type_id = gt.gas_type_id(+)
		   AND i.gas_measure_sid = em.measure_sid(+)
		   AND i.ind_sid = rm.ind_sid(+)
		   AND t.ind_sid = i.ind_sid
		 ORDER BY rn;
		 
	OPEN out_flags_cur FOR
		SELECT i.IND_SID, iqf.DESCRIPTION FLAG
		  FROM IND i, IND_FLAG iqf
		 WHERE i.IND_SID=iqf.IND_SID
		 ORDER BY i.IND_SID;
		 
	OPEN out_tag_groups_cur FOR
		SELECT tag_group_id, name,
			NVL((
				SELECT MAX(COUNT(*))
				  FROM ind_tag it
				 WHERE it.tag_id IN (
						SELECT tag_id
						  FROM tag_group_member
						 WHERE tag_group_id = tg.tag_group_id
					)
				 GROUP BY ind_sid
			 ),0) tags_count -- rather grim! analytic instead I'd have thought....
		   FROM v$tag_group tg
		  WHERE app_sid = in_app_sid
		    AND applies_to_inds = 1 ; 
		
	OPEN out_ind_tag_cur FOR -- equally grim!!
		SELECT it.tag_id, (
				SELECT tag_group_id
				  FROM tag_group_member tgm
				 WHERE tgm.tag_id = it.tag_id
			) tag_group_id, (
				SELECT tag
				  FROM v$tag t
				 WHERE t.tag_id = it.tag_id
			 ) tag_name,
			 ind_sid
		  FROM ind_tag it
		 WHERE tag_id IN (
			SELECT tag_id
			  FROM tag_group_member
			 WHERE tag_group_id IN (
					SELECT tag_group_id
					  FROM tag_group
					 WHERE app_sid = in_app_sid
					   AND applies_to_inds = 1
			   )
			)
		   AND it.ind_sid IN (
            SELECT ind_sid 
              FROM ind 
             WHERE app_sid = in_app_sid 
           )
		 ORDER BY ind_sid,tag_group_id;

	OPEN out_ind_baseline_cur FOR
		SELECT bcd.calc_ind_sid, bcd.baseline_config_id, bc.baseline_name
		  FROM csr.calc_baseline_config_dependency bcd
		 INNER JOIN csr.baseline_config bc
			ON bcd.baseline_config_id = bc.baseline_config_id
		 WHERE bcd.app_sid = in_app_sid;
	
END;

PROCEDURE SetTranslation(
	in_ind_sid			IN 	security_pkg.T_SID_ID,
	in_lang				IN	aspen2.tr_pkg.T_LANG,
	in_translated		IN	VARCHAR2
)
AS
	v_act			security_pkg.T_ACT_ID;
	v_description	ind_description.description%TYPE;
	v_app_sid		security_pkg.T_SID_ID;
BEGIN
	-- NB region_description must have descriptions for ALL customer languages
	v_act := security_pkg.GetACT();
	IF NOT Security_pkg.IsAccessAllowedSID(v_act, in_ind_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied updating translations for the indicator with sid ' ||in_ind_sid);
	END IF;

	BEGIN
		SELECT NVL(description, '')
		  INTO v_description
		  FROM ind_description
		 WHERE ind_sid = in_ind_sid
		   AND lang = in_lang;
	EXCEPTION 
		WHEN NO_DATA_FOUND THEN
			v_description := '';
	END;
	
	-- Despite the above comment, description CAN sometimes be missing for some languages, eg, if you enable a language
	-- after creating the indicator/region. So, we need to do an upsert to ensure we actually set the language.
	BEGIN
		INSERT INTO ind_description
			(ind_sid, lang, description)
		VALUES
			(in_ind_sid, in_lang, in_translated);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE ind_description
			   SET description = in_translated
			 WHERE ind_sid = in_ind_sid 
			   AND lang = in_lang;
	END;
	
	IF v_description != in_translated THEN
		csr_data_pkg.AuditValueChange(v_act, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, SYS_CONTEXT('SECURITY', 'APP'), 
			in_ind_sid, 'Description ('||in_lang||')', v_description, in_translated);
		UPDATE ind_description
		   SET last_changed_dtm = SYSDATE
		 WHERE ind_sid = in_ind_sid 
		   AND lang = in_lang;
	END IF;
END;

PROCEDURE SetInfoXmlTranslation(
	in_ind_sid			IN 	security_pkg.T_SID_ID,
	in_node             IN  VARCHAR2,
	in_lang				IN	aspen2.tr_pkg.T_LANG,
	in_translated		IN  VARCHAR2
)
AS
    v_act               security_pkg.T_ACT_ID;
	v_app_sid		    security_pkg.T_SID_ID;
	v_original          VARCHAR2(4000);
BEGIN
	v_act := security_pkg.GetACT();
	IF NOT Security_pkg.IsAccessAllowedSID(v_act, in_ind_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied updating translations for the indicator with sid ' ||in_ind_sid);
	END IF;
		
	SELECT app_sid, REGEXP_REPLACE(EXTRACT(VALUE(x), 'field/text()').getClobVal(), '^<!\[CDATA\[(.*)\]\]>$','\1',1,0,'n') 
	  INTO v_app_sid, v_original
	  FROM ind i, TABLE(
			XMLSEQUENCE(EXTRACT(i.info_xml, '/fields/field'))
	      )x
	 WHERE ind_sid = in_ind_sid
       AND EXTRACT(VALUE(x), 'field/@name').getStringVal() = in_node;
	
	-- Update the string by hash
	IF v_original IS NOT NULL THEN
    	aspen2.tr_pkg.SetTranslationInsecure(v_app_sid, in_lang, v_original, in_translated);
    END IF;
END;

PROCEDURE GetTranslations(
	in_ind_sid			IN 	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT Security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_ind_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied updating translations for the indicator with sid ' ||in_ind_sid);
	END IF;
	
	-- Get the description (thing to be translated), and application the region object belongs to
	OPEN out_cur FOR
		SELECT lang, description translated
		  FROM ind_description
	 	 WHERE ind_sid = in_ind_sid;
END;

PROCEDURE GetTranslations(
	in_ind_sid			IN 	security_pkg.T_SID_ID,
	out_tr_description	OUT	SYS_REFCURSOR,
	out_tr_info_xml     OUT SYS_REFCURSOR,
	out_tr_flags	    OUT SYS_REFCURSOR
)
AS
BEGIN
	-- Fetches indicator translations, and also checks for read permissions
	GetTranslations(in_ind_sid, out_tr_description);
	
	-- Now get all the info_xml bits
	OPEN out_tr_info_xml FOR
        SELECT f.node_key, t.lang, t.translated, t.translated_id
          FROM (SELECT app_sid, EXTRACT(VALUE(x), 'field/@name').getStringVal() node_key,
					  REGEXP_REPLACE(EXTRACT(VALUE(x), 'field/text()').getStringVal(), '^<!\[CDATA\[(.*)\]\]>$','\1',1,0,'n') node_value
                 FROM ind i, TABLE(
					  XMLSEQUENCE(EXTRACT(i.info_xml, '/fields/field'))
                  )x
           WHERE ind_sid = in_ind_sid
        ) f, aspen2.translated t
         WHERE f.app_sid = t.application_sid
           AND original_hash = CASE WHEN node_value IS NULL THEN NULL ELSE dbms_crypto.hash(to_clob(node_value), dbms_crypto.hash_sh1) END;
           
	OPEN out_tr_flags FOR
		SELECT inf.ind_sid, inf.flag, t.lang, t.translated, t.translated_id
		  FROM ind_flag inf, aspen2.translated t
		 WHERE ind_sid = in_ind_sid
		   AND inf.app_sid = t.application_sid
		   AND original_hash = 	dbms_crypto.hash(utl_raw.cast_to_raw(inf.description), dbms_crypto.hash_sh1); 
	
END;

FUNCTION ProcessStartPoints(
	in_act_id   					IN  security_pkg.T_ACT_ID,
	in_parent_sids					IN	security_pkg.T_SID_IDS
)
RETURN security.T_SID_TABLE
AS
BEGIN
	-- Check permissions and indicator existence
	FOR i IN in_parent_sids.FIRST .. in_parent_sids.LAST
	LOOP
		INTERNAL_EnsureIndExists(in_parent_sids(i));
		IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_parent_sids(i), security_pkg.PERMISSION_READ) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the indicator with sid '||in_parent_sids(i));
		END IF;		
	END LOOP;
	RETURN security_pkg.SidArrayToTable(in_parent_sids);
END;	

PROCEDURE GetTreeSinceDate(
	in_act_id   					IN  security_pkg.T_ACT_ID,
	in_parent_sids					IN	security_pkg.T_SID_IDS,
	in_include_root					IN	NUMBER,
	in_modified_since_dtm			IN	audit_log.audit_date%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	t		 						security.T_SID_TABLE;
BEGIN
	t := ProcessStartPoints(in_act_id, in_parent_sids);

	OPEN out_cur FOR
		SELECT * FROM (
			SELECT i.ind_sid sid_id, i.parent_sid parent_sid_id, i.description, i.ind_type, i.measure_sid, LEVEL lvl, i.active,
				   CONNECT_BY_ISLEAF is_leaf, 'CSRIndicator' class_name, i.target_direction,
				   i.tolerance_type, i.pct_lower_tolerance, i.pct_upper_tolerance,
				   --i.tolerance_number_of_periods, i.tolerance_number_of_standard_deviations_from_average,
				   i.ind_activity_type_id, i.core, i.roll_forward, i.last_modified_dtm,
				   NVL(i.format_mask, m.format_mask) format_mask, m.description measure_description,
				   umc.measure_conversion_id
			  FROM v$ind i
			  LEFT JOIN measure m ON i.measure_sid = m.measure_sid
			  LEFT JOIN user_measure_conversion umc ON i.measure_sid = umc.measure_sid AND umc.csr_user_sid = SYS_CONTEXT('SECURITY', 'SID')
				START WITH (in_include_root = 0 AND i.parent_sid IN (SELECT column_value from TABLE(t))) OR 
			 			   (in_include_root = 1 AND i.ind_sid in (SELECT column_value from TABLE(t)))
				CONNECT BY PRIOR i.ind_sid = i.parent_sid ) i
		WHERE i.last_modified_dtm >= in_modified_since_dtm;
END;

PROCEDURE GetTreeWithDepth(
	in_act_id   					IN  security_pkg.T_ACT_ID,
	in_parent_sids					IN	security_pkg.T_SID_IDS,
	in_include_root					IN	NUMBER,
	in_fetch_depth					IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	t		 						security.T_SID_TABLE;
BEGIN
	t := ProcessStartPoints(in_act_id, in_parent_sids);

	OPEN out_cur FOR
		SELECT i.ind_sid sid_id, i.ind_sid,i.parent_sid parent_sid_id,i.parent_sid, i.description, i.ind_type, i.measure_sid, LEVEL lvl, i.active,
			   CONNECT_BY_ISLEAF is_leaf, 'CSRIndicator' class_name, i.target_direction,
			   i.tolerance_type, i.pct_lower_tolerance, i.pct_upper_tolerance,
			   --i.tolerance_number_of_periods, i.tolerance_number_of_standard_deviations_from_average,
			   i.ind_activity_type_id, i.core, i.roll_forward,
			   NVL(i.format_mask, m.format_mask) format_mask, m.description measure_description,
			   umc.measure_conversion_id
		  FROM v$ind i
		  LEFT JOIN measure m ON i.measure_sid = m.measure_sid
		  LEFT JOIN user_measure_conversion umc ON i.measure_sid = umc.measure_sid AND umc.csr_user_sid = SYS_CONTEXT('SECURITY', 'SID')
		 WHERE level <= in_fetch_depth
		    START WITH (in_include_root = 0 AND i.parent_sid IN (SELECT column_value from TABLE(t))) OR 
			 		   (in_include_root = 1 AND i.ind_sid in (SELECT column_value from TABLE(t)))
			CONNECT BY PRIOR i.ind_sid = i.parent_sid
			ORDER SIBLINGS BY
				REGEXP_SUBSTR(LOWER(i.description), '^\D*') NULLS FIRST, 
				TO_NUMBER(REGEXP_SUBSTR(LOWER(i.description), '[0-9]+')) NULLS FIRST, 
				TO_NUMBER(CONCAT('0.', REGEXP_SUBSTR(LOWER(i.description), '[0-9]+', 1, 2))) NULLS FIRST,
				TO_NUMBER(CONCAT('0.', REGEXP_SUBSTR(LOWER(i.description), '[0-9]+', 1, 3))) NULLS FIRST,
				TO_NUMBER(CONCAT('0.', REGEXP_SUBSTR(LOWER(i.description), '[0-9]+', 1, 4))) NULLS FIRST,
				LOWER(i.description), i.ind_sid;
				
END;

PROCEDURE GetTreeWithSelect(
	in_act_id   					IN  security_pkg.T_ACT_ID,
	in_parent_sids					IN	security_pkg.T_SID_IDS,
	in_include_root					IN	NUMBER,
	in_select_sid					IN	security_pkg.T_SID_ID,
	in_fetch_depth					IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	t		 						security.T_SID_TABLE;
BEGIN
	t := ProcessStartPoints(in_act_id, in_parent_sids);
	
	OPEN out_cur FOR
		SELECT sid_id, description, 'CSRIndicator' class_name, ind_type, measure_sid, lvl, is_leaf, active, pct_lower_tolerance, pct_upper_tolerance, tolerance_type,
				format_mask, measure_description, measure_conversion_id
		  FROM (
		  	SELECT i.ind_sid sid_id, LEVEL lvl, i.description, i.measure_sid, i.ind_type, CONNECT_BY_ISLEAF is_leaf, i.parent_sid, i.active,
				   i.tolerance_type, i.pct_lower_tolerance, i.pct_upper_tolerance,
				   --i.tolerance_number_of_periods, i.tolerance_number_of_standard_deviations_from_average,
				   NVL(i.format_mask, m.format_mask) format_mask, m.description measure_description,
				   umc.measure_conversion_id
			  FROM v$ind i
			  LEFT JOIN measure m ON i.measure_sid = m.measure_sid
			  LEFT JOIN user_measure_conversion umc ON i.measure_sid = umc.measure_sid AND umc.csr_user_sid = SYS_CONTEXT('SECURITY', 'SID')
			    START WITH (in_include_root = 0 AND parent_sid IN (SELECT column_value from TABLE(t))) OR 
			 			   (in_include_root = 1 AND ind_sid IN (SELECT column_value from TABLE(t)))
				CONNECT BY PRIOR ind_sid = parent_sid 
					ORDER SIBLINGS BY i.description, i.ind_sid
		 )
		 WHERE lvl <= in_fetch_depth 
		 	OR sid_id IN (
				SELECT ind_sid
		 		  FROM ind 
		 			START WITH ind_sid = in_select_sid
		 			CONNECT BY PRIOR parent_sid = ind_sid
		 	)
		 	OR parent_sid IN (
				SELECT ind_sid
		 		  FROM ind 
		 			START WITH ind_sid = in_select_sid
		 			CONNECT BY PRIOR parent_sid = ind_sid
		 	);
END;

PROCEDURE GetTreeTextFiltered(
	in_act_id   					IN  security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_parent_sids					IN	security_pkg.T_SID_IDS,
	in_include_root					IN	NUMBER,
	in_search_phrase				IN	VARCHAR2,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	t		 						security.T_SID_TABLE;
BEGIN
	t := ProcessStartPoints(in_act_id, in_parent_sids);
	
	OPEN out_cur FOR
		SELECT i.sid_id, i.parent_sid_id, i.class_name, i.description, i.ind_type, i.measure_sid, i.lvl, i.is_leaf, active,
			   i.tolerance_type, i.pct_lower_tolerance, i.pct_upper_tolerance,
			   --i.tolerance_number_of_periods, i.tolerance_number_of_standard_deviations_from_average,
			   i.format_mask, i.measure_description, i.target_direction, i.measure_conversion_id
		  FROM ( 
			SELECT i.ind_sid sid_id, i.parent_sid parent_sid_id, i.description, i.ind_type, i.measure_sid, i.active,
				CONNECT_BY_ISLEAF is_leaf, LEVEL lvl, ROWNUM rn, 'CSRIndicator' class_name, i.target_direction,
				i.tolerance_type, i.pct_lower_tolerance, i.pct_upper_tolerance,
				--i.tolerance_number_of_periods, i.tolerance_number_of_standard_deviations_from_average,
				NVL(i.format_mask, m.format_mask) format_mask, m.description measure_description,
				umc.measure_conversion_id
			  FROM v$ind i
			  LEFT JOIN measure m ON i.measure_sid = m.measure_sid
			  LEFT JOIN user_measure_conversion umc ON i.measure_sid = umc.measure_sid AND umc.csr_user_sid = SYS_CONTEXT('SECURITY', 'SID')
			  START WITH (in_include_root = 0 AND parent_sid IN (SELECT column_value from TABLE(t))) OR 
			 			  (in_include_root = 1 AND ind_sid IN (SELECT column_value from TABLE(t)))
				CONNECT BY PRIOR ind_sid = parent_sid
					ORDER SIBLINGS BY i.description, i.ind_sid
		)i, (
			SELECT DISTINCT ind_sid sid_id
			  FROM ind
			 	START WITH ind_sid IN ( 
			 		SELECT ind_sid 
			 		  FROM ind_description
			 		 WHERE app_sid = in_app_sid
			 		   AND lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
			 		   AND (LOWER(description) LIKE '%'||LOWER(in_search_phrase)||'%' 
                  )--OR contains(info_xml, '$('||in_search_phrase||') INPATH(fields/field)') > 0) -- TODO: escape 'in_search_phrase'
			 	)
			 	CONNECT BY PRIOR parent_sid = ind_sid 
		)ti 
		WHERE i.sid_id = ti.sid_id 
		ORDER BY i.rn;
END;

PROCEDURE GetTreeTagFiltered(
	in_act_id   					IN  security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_parent_sids					IN	security_pkg.T_SID_IDS,
	in_include_root					IN	NUMBER,
	in_search_phrase				IN	VARCHAR2,
	in_tag_group_count				IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	t		 						security.T_SID_TABLE;
BEGIN
	t := ProcessStartPoints(in_act_id, in_parent_sids);
	
	OPEN out_cur FOR
		SELECT i.sid_id, i.parent_sid_id, i.class_name, i.description, i.ind_type, i.measure_sid, i.lvl, i.is_leaf, active,
			   i.tolerance_type, i.pct_lower_tolerance, i.pct_upper_tolerance,
			   --i.tolerance_number_of_periods, i.tolerance_number_of_standard_deviations_from_average,
		       i.format_mask, i.measure_description, i.target_direction, i.measure_conversion_id
		  FROM ( 
			SELECT i.ind_sid sid_id, i.parent_sid parent_sid_id, i.description, i.ind_type, i.measure_sid, i.active, 
		 		CONNECT_BY_ISLEAF is_leaf, LEVEL lvl, ROWNUM rn, 'CSRIndicator' class_name, i.target_direction,
				i.tolerance_type, i.pct_lower_tolerance, i.pct_upper_tolerance,
				--i.tolerance_number_of_periods, i.tolerance_number_of_standard_deviations_from_average,
				NVL(i.format_mask, m.format_mask) format_mask, m.description measure_description,
				umc.measure_conversion_id
			  FROM v$ind i
			  LEFT JOIN measure m ON i.measure_sid = m.measure_sid
			  LEFT JOIN user_measure_conversion umc ON i.measure_sid = umc.measure_sid AND umc.csr_user_sid = SYS_CONTEXT('SECURITY', 'SID')
			    START WITH (in_include_root = 0 AND parent_sid IN (SELECT column_value from TABLE(t))) OR 
			 	 		   (in_include_root = 1 AND ind_sid IN (SELECT column_value from TABLE(t)))
				CONNECT BY PRIOR ind_sid = parent_sid
					ORDER SIBLINGS BY i.description, i.ind_sid
		)i, ( 
			SELECT DISTINCT ind_sid sid_id 
			  FROM ind
			 	START WITH ind_sid IN (
	                  SELECT ind_sid
	                    FROM (
	                    	SELECT ind_sid, set_id
	                      	  FROM search_tag st, ind_tag it
	                     	 WHERE st.tag_id = it.tag_id
	                      GROUP BY ind_sid, set_id
	                   )
	                  GROUP BY ind_sid
	                  HAVING count(*) = in_tag_group_count
		        )
			 	AND ind_sid IN ( 
			 		SELECT ind_sid 
			 		  FROM ind_description
			 		 WHERE app_sid = in_app_sid
			 		   AND lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
					   AND (LOWER(description) LIKE '%'||LOWER(in_search_phrase)||'%'
					 	)--OR contains(info_xml, '$('||in_search_phrase||') INPATH(fields/field)') > 0) -- TODO: escape 'in_search_phrase'
			 	)
			 	CONNECT BY PRIOR parent_sid = ind_sid
		)ti 
		WHERE i.sid_id = ti.sid_id 
		ORDER BY i.rn;
END;

PROCEDURE GetListTextFiltered(
	in_act_id   					IN  security_pkg.T_ACT_ID,
	in_parent_sids					IN	security_pkg.T_SID_IDS,
	in_include_root					IN	NUMBER,
	in_show_inactive				IN  NUMBER,
	in_search_phrase				IN	VARCHAR2,
	in_fetch_limit					IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	t		 						security.T_SID_TABLE;
BEGIN
	t := ProcessStartPoints(in_act_id, in_parent_sids);
	
	OPEN out_cur FOR
		SELECT *
		  -- ************* N.B. that's a literal 0x1 character in there, not a space **************
		  FROM (SELECT i.ind_sid sid_id, 'CSRIndicator' class_name, i.description, i.ind_type, i.measure_sid, LEVEL lvl, CONNECT_BY_ISLEAF is_leaf,
					   NVL(i.format_mask, m.format_mask) format_mask, m.description measure_description,
					   i.tolerance_type, i.pct_lower_tolerance, i.pct_upper_tolerance,
					   --i.tolerance_number_of_periods, i.tolerance_number_of_standard_deviations_from_average,
					   REPLACE(SUBSTR(SYS_CONNECT_BY_PATH(REPLACE(i.description, CHR(1), '_'), ''), 3 + LENGTH(CONNECT_BY_ROOT i.description)), '', '/') path,
					   i.active, umc.measure_conversion_id
				  FROM v$ind i
				  LEFT JOIN measure m ON i.measure_sid = m.measure_sid
				  LEFT JOIN user_measure_conversion umc ON i.measure_sid = umc.measure_sid AND umc.csr_user_sid = SYS_CONTEXT('SECURITY', 'SID')
				 WHERE (in_search_phrase IS NULL OR LOWER(i.description) LIKE '%'||LOWER(in_search_phrase)||'%'
						OR LOWER(i.lookup_Key) LIKE '%'||LOWER(in_search_phrase)||'%'
				        OR (REGEXP_LIKE(in_search_phrase, '^[0-9]+$') AND i.ind_sid = TO_NUMBER(in_search_phrase))
				 )
					   START WITH (in_include_root = 0 AND parent_sid IN (SELECT column_value from TABLE(t))) OR 
					 			  (in_include_root = 1 AND ind_sid IN (SELECT column_value from TABLE(t)))
					 	AND (in_show_inactive = 1 OR active = 1)
					   CONNECT BY PRIOR ind_sid = parent_sid
					   AND (in_show_inactive = 1 OR active = 1)
				 ORDER SIBLINGS BY 
					REGEXP_SUBSTR(LOWER(i.description), '^\D*') NULLS FIRST, 
					TO_NUMBER(REGEXP_SUBSTR(LOWER(i.description), '[0-9]+')) NULLS FIRST, 
					TO_NUMBER(CONCAT('0.', REGEXP_SUBSTR(LOWER(i.description), '[0-9]+', 1, 2))) NULLS FIRST,
					TO_NUMBER(CONCAT('0.', REGEXP_SUBSTR(LOWER(i.description), '[0-9]+', 1, 3))) NULLS FIRST,
					TO_NUMBER(CONCAT('0.', REGEXP_SUBSTR(LOWER(i.description), '[0-9]+', 1, 4))) NULLS FIRST,
					LOWER(i.description), i.ind_sid)
		 WHERE rownum <= in_fetch_limit;
END;

PROCEDURE GetListTagFiltered(
	in_act_id   					IN  security_pkg.T_ACT_ID,
	in_parent_sids					IN	security_pkg.T_SID_IDS,
	in_include_root					IN	NUMBER,
	in_show_inactive				IN 	NUMBER,
	in_search_phrase				IN	VARCHAR2,
	in_tag_group_count				IN	NUMBER,
	in_fetch_limit					IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	t		 						security.T_SID_TABLE;
BEGIN
	t := ProcessStartPoints(in_act_id, in_parent_sids);
	
	-- ************* N.B. that's a literal 0x1 character in there, not a space **************
	OPEN out_cur FOR
		SELECT *
		  FROM (
			SELECT *
			  FROM (SELECT i.ind_sid sid_id, 'CSRIndicator' class_name, i.description, i.ind_type, i.measure_sid, LEVEL lvl, CONNECT_BY_ISLEAF is_leaf,
						   NVL(i.format_mask, m.format_mask) format_mask, m.description measure_description,
						   i.tolerance_type, i.pct_lower_tolerance, i.pct_upper_tolerance,
						   --i.tolerance_number_of_periods, i.tolerance_number_of_standard_deviations_from_average,
						   REPLACE(SUBSTR(SYS_CONNECT_BY_PATH(REPLACE(i.description, CHR(1), '_'), ''), 3 + LENGTH(CONNECT_BY_ROOT i.description)), '', '/') path,
						   i.active, rownum rn, umc.measure_conversion_id
					  FROM v$ind i
					  LEFT JOIN measure m ON i.measure_sid = m.measure_sid
					  LEFT JOIN user_measure_conversion umc ON i.measure_sid = umc.measure_sid AND umc.csr_user_sid = SYS_CONTEXT('SECURITY', 'SID')
					 WHERE (in_search_phrase IS NULL OR LOWER(i.description) LIKE '%'||LOWER(in_search_phrase)||'%')
						   START WITH (in_include_root = 0 AND parent_sid IN (SELECT column_value from TABLE(t))) OR 
						 			  (in_include_root = 1 AND ind_sid IN (SELECT column_value from TABLE(t)))
						 		  AND (in_show_inactive = 1 OR active = 1)
						   CONNECT BY PRIOR ind_sid = parent_sid
						   AND (in_show_inactive = 1 OR active = 1)
					 ORDER SIBLINGS BY 
						REGEXP_SUBSTR(LOWER(i.description), '^\D*') NULLS FIRST, 
						TO_NUMBER(REGEXP_SUBSTR(LOWER(i.description), '[0-9]+')) NULLS FIRST, 
						TO_NUMBER(CONCAT('0.', REGEXP_SUBSTR(LOWER(i.description), '[0-9]+', 1, 2))) NULLS FIRST,
						TO_NUMBER(CONCAT('0.', REGEXP_SUBSTR(LOWER(i.description), '[0-9]+', 1, 3))) NULLS FIRST,
						TO_NUMBER(CONCAT('0.', REGEXP_SUBSTR(LOWER(i.description), '[0-9]+', 1, 4))) NULLS FIRST,
						LOWER(i.description), i.ind_sid)
			 WHERE sid_id IN (
	               SELECT ind_sid
	                 FROM (SELECT ind_sid, set_id
	                   	     FROM search_tag st, ind_tag it
	                 	    WHERE st.tag_id = it.tag_id
	                     GROUP BY ind_sid, set_id)
	                GROUP BY ind_sid
	               HAVING count(*) = in_tag_group_count)
	      ORDER BY rn)
		 WHERE rownum <= in_fetch_limit;
END;

PROCEDURE SetActivityType(
	in_ind_sid				IN	security_pkg.T_SID_ID,
	in_activity_type_id		IN	ind_activity_type.ind_activity_type_id%TYPE
)
AS
	v_tag_group_id			tag_group.tag_group_id%TYPE;
	v_tag_group_name		tag_group_description.name%TYPE;
	v_tag_id				tag.tag_id%TYPE;
	v_tag_match_id			tag.tag_id%TYPE;
	v_count					NUMBER;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_ind_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to indicator with sid '||in_ind_sid);
	END IF;

	-- Update the indicator
	UPDATE ind 
	   SET ind_activity_type_id = in_activity_type_id, last_modified_dtm = SYSDATE
	 WHERE ind_sid = in_ind_sid;
	
	-- Create tag group?
	v_tag_group_name := 'Activity Type';
	BEGIN	
		SELECT tag_group_id
			INTO v_tag_group_id
			FROM v$tag_group
			WHERE name = v_tag_group_name;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- Try to create tag group
			INSERT INTO tag_group
				(tag_group_id, multi_select, mandatory, applies_to_inds, applies_to_regions)
			VALUES (tag_group_id_seq.nextval, 0, 0, 1, 0)
			RETURNING tag_group_id INTO v_tag_group_id;
			
			INSERT INTO tag_group_description
				(tag_group_id, lang, name)
			VALUES (v_tag_group_id, 'en', v_tag_group_name);
	END;
	
	-- Ok this is a new tag group, create tags and insert members (from the ind_activity_type table)
	-- We use a loop because the memebr list may have changed, we're only going to add new tags that we find
	v_tag_match_id := NULL;
	IF in_activity_type_id IS NOT NULL THEN
		FOR r IN (
			SELECT ind_activity_type_id, label, pos
			  FROM ind_activity_type
			  	ORDER BY pos ASC
		) LOOP
			-- Does the tag already exist?
			SELECT COUNT(*)
			  INTO v_count
			  FROM v$tag t, tag_group_member m
			 WHERE m.tag_group_id = v_tag_group_id
			   AND m.tag_id = t.tag_id
			   AND t.tag = r.label;
			-- Create if not found
			IF v_count = 0 THEN
				INSERT INTO tag
					(tag_id)
				  VALUES (tag_id_seq.NEXTVAL)
				 RETURNING tag_id INTO v_tag_id;

				INSERT INTO tag_description
					(tag_id, lang, tag, explanation)
				  VALUES (v_tag_id, 'en', r.label, r.label);
				 
				 -- Add to group
				INSERT INTO tag_group_member
					(tag_group_id, tag_id, pos)
				  VALUES (v_tag_group_id, v_tag_id, r.pos);
			END IF;
			-- Store the id of the matched tag
			IF r.ind_activity_type_id = in_activity_type_id THEN
				SELECT t.tag_id
				  INTO v_tag_match_id
				  FROM v$tag t, tag_group_member m
				 WHERE m.tag_group_id = v_tag_group_id
				   AND m.tag_id = t.tag_id
				   AND t.tag = r.label;
			END IF;
		END LOOP;
	END IF;
	
	-- Delete old ind/tag association
	DELETE FROM ind_tag
	 WHERE ind_sid = in_ind_sid
	   AND tag_id IN (
	   		SELECT tag_id
	   		  FROM tag_group_member
	   		 WHERE tag_group_id = v_tag_group_id
	 );
	 
	 -- Insert new association
	 IF v_tag_match_id IS NOT NULL THEN
	 	INSERT INTO ind_tag
	 		(tag_id, ind_sid)
	 	  VALUES (v_tag_match_id, in_ind_sid);
	 END IF;
	 
	 -- TODO: Tag for core?
END;

-- Rolls forward an indicator, or all indicators if in_ind_sid is null
-- there is no security here as it's either called from a scheduled task
-- or from AmendIndicator (which does check security)
PROCEDURE RollForward(
	in_ind_sid				IN	ind.ind_sid%TYPE
)
AS
	v_this_month	DATE DEFAULT TRUNC(SYSDATE, 'MON');
	v_period		NUMBER;
	v_start_dtm		DATE;
	v_end_dtm		DATE;
	v_file_uploads	security_pkg.T_SID_IDS;
	v_val_id		val.val_id%TYPE;
BEGIN
	FOR r IN (
		SELECT val_id, ind_sid, region_sid, period_start_dtm, period_end_dtm, 
  			   val_number, entry_measure_conversion_id, entry_val_number,
  			   error_code, note, source_type_id, flags, divisibility,
			   NVL(rf_start_dtm, rf_start_dtm_2) rf_start_dtm,
			   NVL(rf_end_dtm, rf_end_dtm_2) rf_end_dtm
		  FROM (SELECT v.val_id, v.ind_sid, v.region_sid, v.period_start_dtm, v.period_end_dtm, 
		  			   v.val_number, v.entry_measure_conversion_id, v.entry_val_number,
		  			   v.error_code, v.note, v.source_type_id, v.flags,
		  			   NVL(i.divisibility, m.divisibility) divisibility,
					   ROW_NUMBER() OVER (PARTITION BY v.ind_sid, v.region_sid ORDER BY v.period_end_dtm DESC) rn,
					   -- find the previous row that wasn't rolled forward to take the period length off (x2 for start, end)
					   LAST_VALUE(CASE WHEN source_Type_id = csr_data_pkg.SOURCE_TYPE_ROLLED_FORWARD 
					   				   THEN NULL 
					   				   ELSE v.period_start_dtm END IGNORE NULLS) 
					   OVER (PARTITION BY v.ind_sid, v.region_sid ORDER BY v.period_end_dtm ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) rf_start_dtm,
					   LAST_VALUE(CASE WHEN source_Type_id = csr_data_pkg.SOURCE_TYPE_ROLLED_FORWARD 
					   				   THEN NULL 
					   				   ELSE v.period_end_dtm END IGNORE NULLS) 
					   OVER (PARTITION BY v.ind_sid, v.region_sid ORDER BY v.period_end_dtm ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) rf_end_dtm,
					   -- do it again in case the source value is missing
					   LAST_VALUE(v.period_start_dtm) 
					   OVER (PARTITION BY v.ind_sid, v.region_sid ORDER BY v.period_end_dtm ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) rf_start_dtm_2,
					   LAST_VALUE(v.period_end_dtm) 
					   OVER (PARTITION BY v.ind_sid, v.region_sid ORDER BY v.period_end_dtm ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) rf_end_dtm_2
				  FROM ind i
				  JOIN val v ON i.app_sid = v.app_sid AND i.ind_sid = v.ind_sid
				  LEFT JOIN measure m ON m.measure_sid = i.measure_sid
				 WHERE i.roll_forward = 1
				   AND (in_ind_sid IS NULL OR i.ind_sid = in_ind_sid)
				   AND (v.val_number IS NOT NULL 							-- ignore nulls, these get saved by normal forms sometimes
						OR (m.custom_field = '|' AND v.note IS NOT NULL)	-- include not null text indicators						
				   )
			)
		 WHERE rn = 1
		   AND period_end_dtm <= v_this_month) LOOP
		  	
		-- Only roll forward specific types
		-- We don't filter them in the query since we want to consider, e.g. an
		-- aggregate as a blocker to rolling forward
		IF r.source_type_id IN (
			csr_data_pkg.SOURCE_TYPE_DIRECT,
			csr_data_pkg.SOURCE_TYPE_DELEGATION,
			csr_data_pkg.SOURCE_TYPE_IMPORT,
			csr_data_pkg.SOURCE_TYPE_LOGGING,
			csr_data_pkg.SOURCE_TYPE_PENDING,
			csr_data_pkg.SOURCE_TYPE_METER,
			csr_data_pkg.SOURCE_TYPE_ENERGY_STAR,
			csr_data_pkg.SOURCE_TYPE_ROLLED_FORWARD) THEN
				
			-- create as many values as are needed to have one that covers the current period
			-- note we are using months_between instead of "-" as otherwise there's some lack of
			-- precision that means that values aren't aligned at the month starts/end and fail
			-- the check constraint ck_val_Dates
			v_period := MONTHS_BETWEEN(r.period_end_dtm, r.period_start_dtm);
			v_start_dtm := r.period_end_dtm;
			v_val_id := NULL;
			
			-- We can do a short cut with indivisible or 0 values that are being rolling forward
			-- by simply creating a value that covers the desired time period.  If there is an
			-- existing rolled forward value then we simply adjust the end date.
			-- The same applies to stuff from energy star.
			IF r.source_type_id = csr_data_pkg.SOURCE_TYPE_ROLLED_FORWARD AND
			   (r.divisibility != csr_data_pkg.DIVISIBILITY_DIVISIBLE OR r.val_number = 0 OR r.error_code IS NOT NULL) THEN
			   	-- add one period where the period comes from the original value
			   	v_end_dtm := ADD_MONTHS(r.period_end_dtm, MONTHS_BETWEEN(r.rf_end_dtm, r.rf_start_dtm));
			   	--security_pkg.debugmsg('extend val '||r.val_id||', ind '||r.ind_sid||', region '||r.region_sid||' from ' ||r.period_start_dtm||' to ' ||v_end_dtm||' rf from '||r.rf_start_dtm||' to '||r.rf_end_dtm);
				UPDATE val
				   SET period_end_dtm = v_end_dtm
				 WHERE val_id = r.val_id;
				calc_pkg.AddJobsForVal(r.ind_sid, r.region_sid, r.period_end_dtm, v_end_dtm);
			ELSE	
				SELECT file_upload_sid
				  BULK COLLECT INTO v_file_uploads
				  FROM val_file
				 WHERE val_id = r.val_id;
				
				LOOP
					-- if we're inserting a new value if it's zero or the indicator is indivisible
					-- it can cover the whole of the desired period
					IF r.divisibility != csr_data_pkg.DIVISIBILITY_DIVISIBLE OR r.val_number = 0 OR r.error_code IS NOT NULL THEN
						v_end_dtm := ADD_MONTHS(v_start_dtm, (FLOOR(MONTHS_BETWEEN(v_this_month, v_start_dtm) / v_period) + 1) * v_period);
					ELSE
						v_end_dtm := ADD_MONTHS(v_start_dtm, v_period);
					END IF;
					
					-- security_pkg.debugmsg(' ind '||r.ind_sid||', region '||r.region_sid||' from ' ||v_start_dtm||' to ' ||v_end_dtm||' rf from '||r.period_start_dtm||' to '||r.period_end_dtm);
					SetValueWithReasonWithSid(
						in_user_sid				=> SYS_CONTEXT('SECURITY', 'SID'), -- user sid
						in_ind_sid				=> r.ind_sid,
						in_region_sid			=> r.region_sid,
						in_period_start			=> v_start_dtm,
						in_period_end			=> v_end_dtm,
						in_val_number			=> r.val_number,
						in_flags				=> r.flags,
						in_source_type_id		=> csr_data_pkg.SOURCE_TYPE_ROLLED_FORWARD,
						in_source_id			=> NVL(v_val_id, r.val_id), -- source id
						in_entry_conversion_id	=> r.entry_measure_conversion_id,
						in_entry_val_number		=> r.entry_val_number,
						in_error_code			=> r.error_code,
						in_reason				=> 'Rolled forward', -- reason
						in_note					=> r.note,
						in_have_file_uploads	=> 1,
						in_file_uploads			=> v_file_uploads,
						out_val_id				=> v_val_id);

					v_start_dtm := v_end_dtm;
					EXIT WHEN v_start_dtm + v_period > v_this_month;
				END LOOP;
			END IF;
		END IF;
	END LOOP;
END;

-- Called from a scheduled job to roll forward each month
-- We exclude sites where we copy values to new sheets as the code for
-- copying sheets forward for these sites does a rollforward anyway and that
-- job runs on the same frequency as this one. 
PROCEDURE RollForward
AS
BEGIN
	user_pkg.LogonAdmin(timeout => 86400);	
	FOR r IN (SELECT app_sid
				FROM ind
			   WHERE roll_forward = 1
			   GROUP BY app_sid
			    INTERSECT
			   SELECT app_sid
			     FROM customer
			    WHERE copy_vals_to_new_sheets = 0
			     ) LOOP
		security_pkg.SetApp(r.app_sid);
		RollForward(null);
		security_pkg.SetApp(null);
		COMMIT;
	END LOOP;
	user_pkg.LogOff(security_pkg.GetAct);
END;

/*
 *
 * Find an indicator based on its description, optionally filtered by ancestor descriptions.
 * 
 * Returns -1 if no matching indicator is found and throws too_many_rows if the search criteria are ambiguous.
 * 
 * e.g. /Indicators/Managed Properties/KPIs/My indicator description
 * 
 * can be found via
 * 
 * declare
 * v_sid security_pkg.T_SID_ID;
 * v_a security_pkg.T_VARCHAR2_ARRAY;
 * begin
 * v_a(0) := 'Indicators';
 * v_a(1) := 'KPIs';
 * indicator_pkg.LookupIndicator('My indicator description', v_a, v_sid);
 * dbms_output.put_line(v_sid);
 * end;
 * /
 * 
 * Note that ancestors can be used to resolve ambiguities: they must be found in the IND tree in order (root to leaf),
 * but not every parent indicator must be provided. (In the above example, "Managed Properties" is missed out of the
 * filter and the searched-for indicator is still found.)
 * 
 * There are some structures that this algorithm cannot unambiguously match.
 *
 * e.g. Given the indicator tree
 *
 *	A/B/C
 *	A/C
 *
 * A/C cannot be matched. (Both C and A/C also match A/B/C.)
 *
 */

PROCEDURE LookupIndicator(
	in_text			IN	ind_description.description%TYPE,
	in_ancestors	IN	security_pkg.T_VARCHAR2_ARRAY,
	out_ind_sid		OUT	security_pkg.T_SID_ID
)
AS
	v_text ind_description.description%TYPE;
	v_ancestors security.T_VARCHAR2_TABLE;
	v_first_ancestor NUMBER;
	v_last_ancestor NUMBER;
	v_ancestor_count NUMBER;
BEGIN
	v_text := LOWER(in_text);
	v_ancestors := security_pkg.Varchar2ArrayToTable(in_ancestors);
	v_first_ancestor := in_ancestors.FIRST;
	v_last_ancestor := in_ancestors.LAST;
	
	-- We can't rely on in_ancestors.COUNT becasue of the ODP.NET hack where we pass an array with a single NULL element rather than an empty array.
	
	SELECT COUNT(*) INTO v_ancestor_count FROM TABLE(v_ancestors);

	BEGIN
		WITH ind_hierarchy AS
		(
			 SELECT CONNECT_BY_ROOT ind.ind_sid root_ind_sid, ind.ind_sid, LEVEL ind_level, CASE WHEN filter.pos IS NULL AND LEVEL = 1 THEN v_last_ancestor + 1 ELSE filter.pos END filter_pos
			   FROM v$ind ind
			   LEFT JOIN TABLE(v_ancestors) filter
				 ON filter.value = ind.description
			  WHERE ind.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			  START WITH LOWER(ind.description) = v_text
			CONNECT BY ind.ind_sid = PRIOR ind.parent_sid
				AND ind.app_sid = PRIOR ind.app_sid
		)
		 SELECT ind_sid INTO out_ind_sid
		   FROM ind_hierarchy
		  WHERE (v_ancestor_count = 0 AND ind_level = 1)
		     OR filter_pos = v_last_ancestor + 1
		  START WITH v_ancestor_count = 0
		     OR (filter_pos = v_first_ancestor AND ind_level > 1)
		CONNECT BY root_ind_sid = PRIOR root_ind_sid
			AND filter_pos = PRIOR filter_pos + 1
			AND ind_level < PRIOR ind_level;
	EXCEPTION
		WHEN no_data_found THEN
			out_ind_sid := -1;
	END;
END;

-- This is a clone from region_pkg.FindRegionPath
PROCEDURE FindIndicatorByPath(
	in_path				IN	VARCHAR2,
	in_separator		IN	VARCHAR2 DEFAULT '/',
	out_cur				OUT	SYS_REFCURSOR
)
AS
	TYPE T_PATH IS TABLE OF VARCHAR2(1024) INDEX BY BINARY_INTEGER;
	v_path_parts 			T_PATH;
	v_parents				security.T_SID_TABLE;
	v_new_parents			security.T_SID_TABLE;
	v_indicators_folder		security_pkg.T_SID_ID;
BEGIN

	v_indicators_folder := securableobject_pkg.GetSIDFromPath(security_pkg.getAct, security_pkg.getApp, 'indicators');

	SELECT LOWER(TRIM(item)) 
	  BULK COLLECT INTO v_path_parts 
	  FROM table(utils_pkg.SplitString(in_path, in_separator));

	-- Populate possible parents with the first part of the path
	BEGIN
		SELECT ind_sid
		  BULK COLLECT INTO v_parents
		  FROM v$ind
		 WHERE LOWER(description) = v_path_parts(1)
		   AND app_sid = security_pkg.getApp
		   AND active = 1
		   AND ind_sid IN (
				SELECT ind_sid
				  FROM ind
				 START WITH ind_sid = v_indicators_folder
			   CONNECT BY PRIOR ind_sid = parent_sid);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			OPEN out_cur FOR
				SELECT ind_sid, description
				  FROM v$ind
				 WHERE 1 = 0;
			RETURN;
	END;

	-- Now check each part of the rest of the path
	FOR i IN 2 .. v_path_parts.LAST
	LOOP
		-- Select everything that matches into a set of possible parents
		SELECT ind_sid 
		  BULK COLLECT INTO v_new_parents
		  FROM v$ind
		 WHERE LOWER(description) = TRIM(v_path_parts(i))
		   AND active = 1
		   AND parent_sid IN (SELECT COLUMN_VALUE FROM TABLE(v_parents));

		-- We have to select into a different collection, so copy back on top
		v_parents := v_new_parents;
		IF v_parents.COUNT = 0 THEN
			EXIT;
		END IF;
	END LOOP;

	-- Return the stuff we've found
	OPEN out_cur FOR
		SELECT ind_sid, description
		  FROM v$ind
		 WHERE ind_sid IN (SELECT column_value FROM TABLE(v_parents))
		   AND measure_sid IS NOT NULL
		   AND ind_type = csr_data_pkg.IND_TYPE_NORMAL
		   AND security_pkg.SQL_IsAccessAllowedSID(security_pkg.getAct, ind_sid, security_pkg.PERMISSION_READ) = 1;
END;

PROCEDURE GetNormalizationInds(
	out_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	-- XXX: should this have some more security?
	OPEN out_cur FOR
		SELECT ind_sid, description
		  FROM v$ind
		 WHERE normalize = 1
		   AND active = 1
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

-- XXX: add a "check for overlaps" flag?
PROCEDURE CopyValues(
	in_from_ind_sid		IN	security_pkg.T_SID_ID,
	in_new_ind_sid		IN	security_pkg.T_SID_ID,
	in_period_start_dtm	IN	DATE 			DEFAULT NULL,
	in_period_end_dtm	IN	DATE 			DEFAULT NULL,
	in_reason			IN	VARCHAR2		DEFAULT NULL,
	in_move				IN	NUMBER			DEFAULT 0
)
AS
	v_val_id			val.val_id%TYPE;
	v_file_uploads		security_pkg.T_SID_IDS;
	v_cnt				NUMBER(10) := 0;
	v_reason			VARCHAR2(1000);
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_from_ind_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading the ind with sid '||in_from_ind_sid);
	END IF;
	
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_new_ind_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to the ind with sid '||in_new_ind_sid);
	END IF;
	
	-- TODO: Check units of measure -- maybe convert if that's sane?
	
	IF in_reason IS NULL THEN 
		IF in_move = 1 THEN 
			v_reason := 'Moved';
		ELSE
			v_reason := 'Copied';
		END IF;
	ELSE
		v_reason := in_reason;
	END IF;
	FOR r IN (
		SELECT v.changed_by_sid user_sid, in_new_ind_sid ind_sid, v.region_sid, v.period_start_dtm, v.period_end_dtm,
			   v.val_number, v.flags, v.source_type_id, v.source_id, v.entry_measure_conversion_id,
			   v.entry_val_number, v.error_code, v.note, v.val_id
		  FROM val_converted v
		 WHERE v.ind_sid = in_from_ind_sid
		   AND v.source_type_id != 5
           AND (in_period_start_dtm IS NULL OR v.period_start_dtm >= in_period_start_dtm) 
           AND (in_period_end_dtm IS NULL OR v.period_end_dtm <= in_period_end_dtm)
	)
	LOOP	
		v_cnt := v_cnt + 1;
        v_file_uploads.delete;
        
        SELECT file_upload_sid
          BULK COLLECT INTO v_file_uploads
          FROM val_file
         WHERE val_id = r.val_id;
		
		indicator_pkg.SetValueWithReasonWithSid(r.user_sid, r.ind_sid, r.region_sid, r.period_start_dtm, r.period_end_dtm, 
			  r.val_number, r.flags, r.source_type_id, r.source_id, r.entry_measure_conversion_id,
			  r.entry_val_number, r.error_code, 0, v_reason, r.note, 1, v_file_uploads, v_val_id);
		
		IF in_move = 1 THEN
			indicator_pkg.DeleteVal(SYS_CONTEXT('SECURITY','ACT'), r.val_id, v_reason);
		END IF;
	END LOOP;
END;
/**
*Check if indicator is used the system returns 1 (for true) if found or 0 (for false if not used)
*Used numbers for use in RUNSF where BOOLEAN cannot be used
*/
FUNCTION IsIndicatorUsed(
	in_ind_sid		IN	security_pkg.T_SID_ID
)RETURN NUMBER
AS
BEGIN		
	IF sheet_pkg.IsIndicatorUsed(in_ind_sid)
		OR calc_pkg.IsIndicatorUsed(in_ind_sid)
		OR val_pkg.IsIndicatorUsed(in_ind_sid)
		OR delegation_pkg.IsIndicatorUsed(in_ind_sid)
	THEN
		RETURN 1;
	END IF;
	
	RETURN 0;
END;

PROCEDURE RemoveUnusedValidationRules (
	in_ind_sid			IN  security_pkg.T_SID_ID,
	in_used_rule_ids	IN  security_pkg.T_SID_IDS
)
AS
	v_rules_to_keep		security.T_SID_TABLE DEFAULT security_pkg.SidArrayToTable(in_used_rule_ids);
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_ind_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing the ind with sid '||in_ind_sid);
	END IF;

	DELETE FROM ind_validation_rule
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND ind_sid = in_ind_sid
	   AND ind_validation_rule_id NOT IN (
			SELECT column_value FROM TABLE(v_rules_to_keep)
		);
END;

PROCEDURE RemoveValidationRule (
	in_ind_sid			IN  security_pkg.T_SID_ID,
	in_rule_id			IN  security_pkg.T_SID_ID
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_ind_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing the ind with sid '||in_ind_sid);
	END IF;

	DELETE FROM ind_validation_rule
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND ind_sid = in_ind_sid
	   AND ind_validation_rule_id = in_rule_id;
	
	-- Shuffle the positions down, or do we not care?
END;

PROCEDURE SaveValidationRule (
	in_ind_sid			IN  security_pkg.T_SID_ID,
	in_validation_id	IN  ind_validation_rule.ind_validation_rule_id%TYPE,
	in_expr				IN  ind_validation_rule.expr%TYPE,
	in_message			IN  ind_validation_rule.message%TYPE,
	in_type				IN  ind_validation_rule.type%TYPE,
	out_validation_id   OUT ind_validation_rule.ind_validation_rule_id%TYPE
)
AS
	v_position			ind_validation_rule.position%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_ind_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing the ind with sid '||in_ind_sid);
	END IF;

	-- why would code ever pass in 0 - smacks of overly defensive programming?
	IF NVL(in_validation_id, 0) = 0 THEN
		SELECT MAX(position)
		  INTO v_position
		  FROM ind_validation_rule
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND ind_sid = in_ind_sid;
		
		INSERT INTO ind_validation_rule
			(ind_sid, ind_validation_rule_id, expr, message, position, type)
		VALUES
			(in_ind_sid, ind_validation_rule_id_seq.NEXTVAL, in_expr, in_message, NVL(v_position, 0) + 1, in_type)
		RETURNING ind_validation_rule_id INTO out_validation_id;
	ELSE
		UPDATE ind_validation_rule
		   SET expr = in_expr,
		   	   message = in_message,
		   	   type = in_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND ind_sid = in_ind_sid
		   AND ind_validation_rule_id = in_validation_id;   
		
		IF SQL%ROWCOUNT > 0 THEN
			out_validation_id := in_validation_id;
		END IF;
	END IF;
END;

-- Distinct from SaveValidationRule because it will ONLY edit and NVLs any incoming nulls
PROCEDURE EditValidationRule (
	in_ind_sid			IN  security_pkg.T_SID_ID,
	in_validation_id	IN  ind_validation_rule.ind_validation_rule_id%TYPE,
	in_expr				IN  ind_validation_rule.expr%TYPE,
	in_message			IN  ind_validation_rule.message%TYPE,
	in_type				IN  ind_validation_rule.type%TYPE
)
AS
	v_expr				ind_validation_rule.expr%TYPE;
	v_message			ind_validation_rule.message%TYPE;
	v_type				ind_validation_rule.type%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_ind_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing the ind with sid '||in_ind_sid);
	END IF;

	SELECT NVL(in_expr, expr), NVL(in_message, message), NVL(in_type, type)
	  INTO v_expr, v_message, v_type
	  FROM ind_validation_rule
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND ind_sid = in_ind_sid
	   AND ind_validation_rule_id = in_validation_id;
	
	UPDATE ind_validation_rule
	   SET expr = v_expr,
		   message = v_message,
		   type = v_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND ind_sid = in_ind_sid
	   AND ind_validation_rule_id = in_validation_id;
END;

PROCEDURE GetValidationRules (
	in_ind_sid			IN  security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_ind_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading the ind with sid '||in_ind_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT ind_sid, ind_validation_rule_id, expr, message, type, position
		  FROM ind_validation_rule
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND ind_sid = in_ind_sid
		 ORDER BY position;   
END;

PROCEDURE GetAllValidationRulesBasic(
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT ind_sid, ind_validation_rule_id
		  FROM ind_validation_rule
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY ind_sid, position;

END;

PROCEDURE GetValidationRulesFrom (
	in_root_indicator_sids	IN 	security_pkg.T_SID_IDS,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	t							security.T_SID_TABLE;
BEGIN
	t := security_pkg.SidArrayToTable(in_root_indicator_sids);
	
	OPEN out_cur FOR
		WITH indicator AS (
			SELECT app_sid, ind_sid, measure_sid, lookup_key, active, lvl, ROWNUM rn
			  FROM (
				SELECT i.app_sid, i.ind_sid, i.measure_sid, i.lookup_key, i.active, LEVEL lvl
				  FROM ind i
				  JOIN (
					SELECT app_sid, ind_sid, description
					  FROM ind_description
					 WHERE app_sid = SYS_CONTEXT('security', 'app')
					   AND lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
				)id ON i.app_sid = id.app_sid AND i.ind_sid = id.ind_sid
				 WHERE i.app_sid = SYS_CONTEXT('security', 'app')
				 START WITH i.ind_sid IN (SELECT column_value from TABLE(t))
			   CONNECT BY PRIOR i.ind_sid = i.parent_sid
				 ORDER SIBLINGS BY 
					   REGEXP_SUBSTR(LOWER(id.description), '^\D*') NULLS FIRST, 
					   TO_NUMBER(REGEXP_SUBSTR(LOWER(id.description), '[0-9]+')) NULLS FIRST, 
					   TO_NUMBER(CONCAT('0.', REGEXP_SUBSTR(LOWER(id.description), '[0-9]+', 1, 2))) NULLS FIRST,
					   TO_NUMBER(CONCAT('0.', REGEXP_SUBSTR(LOWER(id.description), '[0-9]+', 1, 3))) NULLS FIRST,
					   TO_NUMBER(CONCAT('0.', REGEXP_SUBSTR(LOWER(id.description), '[0-9]+', 1, 4))) NULLS FIRST,
					   LOWER(id.description), i.ind_sid
			)
		)
		SELECT i.ind_sid, id.description ind_description, m.description measure_description, i.lookup_key, i.active,
			   r.ind_validation_rule_id, r.expr, r.message, r.type
		  FROM indicator i
		  LEFT JOIN ind_description id ON i.app_sid = id.app_sid 
									  AND i.ind_sid = id.ind_sid 
									  AND id.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
		  JOIN ind_validation_rule r ON r.ind_sid = i.ind_sid
		  JOIN measure m ON i.measure_sid = m.measure_sid
		 ORDER BY rn, r.position;
END;

PROCEDURE GetAllIndSelectionGroupInds(
	in_app_sid			IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP'),
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT isgm.ind_sid, isgm.master_ind_sid, isgm.pos
		  FROM ind_selection_group_member isgm, ind i
		 WHERE isgm.app_sid = in_app_sid
		   AND isgm.app_sid = i.app_sid
		   AND isgm.ind_sid = i.ind_sid
		   AND i.active = 1
		 ORDER BY isgm.master_ind_sid, isgm.pos;
END;

PROCEDURE GetIndSelections(
	in_ind_sid						IN	ind.ind_sid%TYPE,
	out_sel_ind_cur					OUT	SYS_REFCURSOR,
	out_sel_tr_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT Security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_ind_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied updating translations for the indicator with sid ' ||in_ind_sid);
	END IF;
	
	OPEN out_sel_ind_cur FOR
		SELECT isgm.ind_sid, i.active
		  FROM ind_selection_group_member isgm, ind i
		 WHERE isgm.master_ind_sid = in_ind_sid
		   AND isgm.app_sid = i.app_sid AND isgm.ind_sid = i.ind_sid
		 ORDER BY isgm.pos;

	OPEN out_sel_tr_cur FOR
		SELECT isgm.ind_sid, isgmd.lang, isgmd.description
		  FROM ind_selection_group_member isgm, ind_sel_group_member_desc isgmd
		 WHERE isgm.master_ind_sid = in_ind_sid
		   AND isgm.app_sid = isgmd.app_sid
		   AND isgm.ind_sid = isgmd.ind_sid
		 ORDER BY isgm.pos;
END;

PROCEDURE SetIndSelections(
	in_ind_sid						IN	ind.ind_sid%TYPE,
	in_selection_sids				IN	security_pkg.T_SID_IDS,
	in_selection_names				IN	security_pkg.T_VARCHAR2_ARRAY,
	in_active						IN	security_pkg.T_SID_IDS,
	in_langs						IN	security_pkg.T_VARCHAR2_ARRAY,
	in_selection_translations		IN	security_pkg.T_VARCHAR2_ARRAY,
	out_removals_skipped			OUT	NUMBER
)
AS
	v_base_name						security_pkg.T_SO_NAME;
	v_name							security_pkg.T_SO_NAME;
	v_duplicate_count				NUMBER;
	v_selection_sid					security_pkg.T_SID_ID;
	v_selection_sids				security_pkg.T_SID_IDS;
	v_try_again						BOOLEAN;
	v_description					ind_description.description%TYPE;
	v_xml							CLOB;
	CURSOR c_ind IS
		SELECT description, active, measure_sid, scale, format_mask, target_direction, gri, info_xml, divisibility, 
			   start_month, aggregate, factor_type_id, gas_measure_sid, core, roll_forward, normalize, 
			   prop_down_region_tree_sid, multiplier, period_set_id, period_interval_id, gas_type_id, 
			   pos, calc_output_round_dp
		  FROM v$ind
		 WHERE ind_sid = in_ind_sid;
	r_ind				 			c_ind%ROWTYPE;
	v_cnt							NUMBER;
	v_path							VARCHAR2(200);
	v_selection_sids_table			security.T_SID_TABLE;
	v_translation					VARCHAR2(4000);
	v_sel_description				VARCHAR2(4000);
	v_in_use						NUMBER;
	v_active						NUMBER;
	v_lookup_key					ind.lookup_key%TYPE;
BEGIN
	out_removals_skipped := 0;
	
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_ind_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied setting selections for the ind with sid '||in_ind_sid);
	END IF;
	
	-- check for a no-op -- no ind selections to set and none set
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM ind_selection_group_member
	 WHERE master_ind_sid = in_ind_sid;
	IF v_cnt = 0 AND (in_selection_sids.COUNT = 0 OR (in_selection_sids.COUNT = 1 AND in_selection_sids(1) IS NULL)) THEN
		RETURN;
	END IF;

	OPEN c_ind;
	FETCH c_ind INTO r_ind;
	IF c_ind%NOTFOUND THEN
		RAISE_APPLICATION_ERROR(-20001, 'The indicator with sid '||in_ind_sid||' does not exist');
	END IF;
	CLOSE c_ind;
	
	BEGIN
		INSERT INTO ind_selection_group
			(master_ind_sid)
		VALUES
			(in_ind_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	IF NOT (in_selection_sids.COUNT = 0 OR (in_selection_sids.COUNT = 1 AND in_selection_sids(1) IS NULL)) THEN
		v_cnt := in_selection_sids.COUNT;
	
		FOR i IN 1 .. in_selection_sids.COUNT LOOP
			v_active := CASE WHEN r_ind.active = 0 THEN 0 ELSE in_active(i) END;
			IF NVL(in_selection_sids(i), 0) = 0 THEN
			    -- unique name
			    v_base_name := SUBSTR(REPLACE(in_selection_names(i), '/', '\'), 1, 240);
			    v_name := v_base_name;
				v_duplicate_count := 1;
				v_try_again := TRUE;
				WHILE v_try_again LOOP
					BEGIN
						indicator_pkg.CreateIndicator(
							in_parent_sid_id				=> in_ind_sid,
							in_name							=> v_name,
							in_description 					=> r_ind.description || ' - ' || in_selection_names(i),
							in_active						=> v_active,
							in_measure_sid					=> r_ind.measure_sid,
							in_scale						=> r_ind.scale,
							in_format_mask					=> r_ind.format_mask,
							in_target_direction				=> r_ind.target_direction,
							in_gri							=> r_ind.gri,
							in_pos							=> i,
							in_info_xml						=> r_ind.info_xml,
							in_divisibility					=> r_ind.divisibility,
							in_start_month					=> r_ind.start_month,
							in_aggregate					=> r_ind.aggregate,
							in_is_gas_ind					=> CASE WHEN r_ind.factor_type_id IS NOT NULL THEN 1 ELSE 0 END,
							in_factor_type_id				=> r_ind.factor_type_id,
							in_gas_measure_sid				=> r_ind.gas_measure_sid,
							in_core							=> r_ind.core,
							in_roll_forward					=> r_ind.roll_forward,
							in_normalize					=> r_ind.normalize,
							in_prop_down_region_tree_sid	=> r_ind.prop_down_region_tree_sid,
							in_is_system_managed			=> 1,
							in_calc_output_round_dp			=> r_ind.calc_output_round_dp,
							out_sid_id						=> v_selection_sid);
						v_try_again := FALSE;
						
						INSERT INTO ind_selection_group_member 
							(master_ind_sid, ind_sid, pos)
						VALUES 
							(in_ind_sid, v_selection_sid, i);
						
						INSERT INTO ind_sel_group_member_desc (ind_sid, lang, description)
							SELECT v_selection_sid, cl.lang, in_selection_names(i)
							  FROM v$customer_lang cl;

						v_selection_sids(i) := v_selection_sid;
					EXCEPTION
						WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
							v_duplicate_count := v_duplicate_count + 1;
							v_name := v_base_name || '_' || v_duplicate_count;
					END;
				END LOOP;

				-- add the new selection to any existing delegations
				INSERT INTO delegation_ind (delegation_sid, ind_sid, pos, visibility)
					SELECT delegation_sid, v_selection_sid, 0, 'HIDE'
					  FROM delegation_ind di
					 WHERE di.ind_sid = in_ind_sid;				
			ELSE
				-- keep same lookup key
				SELECT lookup_key
				  INTO v_lookup_key
				  FROM ind
				 WHERE ind_sid = in_selection_sids(i);

				indicator_pkg.AmendIndicator(
					in_ind_sid		 				=> in_selection_sids(i),
					in_description 					=> r_ind.description || ' - ' || in_selection_names(i),
					in_active	 					=> v_active,
					in_measure_sid					=> r_ind.measure_sid,
					in_multiplier					=> r_ind.multiplier,
					in_scale						=> r_ind.scale,
					in_format_mask					=> r_ind.format_mask,
					in_target_direction				=> r_ind.target_direction,
					in_gri							=> r_ind.gri,
					in_pos							=> i,
					in_info_xml						=> r_ind.info_xml,
					in_divisibility					=> r_ind.divisibility,
					in_start_month					=> r_ind.start_month,
					in_ind_type						=> csr_data_pkg.IND_TYPE_NORMAL,
					in_aggregate					=> r_ind.aggregate,
					in_is_gas_ind					=> CASE WHEN r_ind.factor_type_id IS NOT NULL THEN 1 ELSE 0 END,
					in_factor_type_id				=> r_ind.factor_type_id,
					in_gas_measure_sid				=> r_ind.gas_measure_sid,
					in_gas_type_id					=> r_ind.gas_type_id,
					in_core							=> r_ind.core,
					in_roll_forward					=> r_ind.roll_forward,
					in_normalize					=> r_ind.normalize,
					in_prop_down_region_tree_sid	=> r_ind.prop_down_region_tree_sid,
					in_is_system_managed			=> 1,
					in_lookup_key					=> v_lookup_key,
					in_calc_output_round_dp			=> r_ind.calc_output_round_dp
				);

				UPDATE ind_selection_group_member
				   SET pos = i
				 WHERE master_ind_sid = in_ind_sid
				   AND ind_sid = in_selection_sids(i);

				UPDATE ind_sel_group_member_desc
				   SET description = in_selection_names(i)
				 WHERE lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
				   AND ind_sid = in_selection_sids(i);

				 v_selection_sids(i) := in_selection_sids(i);
			END IF;
		END LOOP;
	ELSE
		v_cnt := 0; -- XXX? what?
	END IF;

	/* Construct the calc, which will be:
		<add>
			<left>
				<add>
x N - 1
					<left>
						<add>
							<left>

								<path sid=/>
x1
							</left>							
							<right>
								<path sid=/>
							</right>
						</add>
x N - 1						
					</left>
					<right>
						<path sid=/>
					</right>
				</add>
			</left>
			<right>
				<path sid=/>
			</right>
		</add>
	*/

	dbms_lob.createTemporary(v_xml, TRUE, dbms_lob.call);
	dbms_lob.open(v_xml, DBMS_LOB.LOB_READWRITE);

	IF v_selection_sids.COUNT = 0 THEN
		aspen2.utils_pkg.WriteAppend(v_xml, '<nop/>');	
	ELSE
		FOR i IN 1 .. v_cnt - 1 LOOP
			aspen2.utils_pkg.WriteAppend(v_xml, '<add><left>');
		END LOOP;
		
		FOR i IN 1 .. v_selection_sids.COUNT LOOP
			v_path := '<path sid="' || v_selection_sids(i) || '" />';
			IF i = 1 THEN
				aspen2.utils_pkg.WriteAppend(v_xml, v_path);
			ELSE
				aspen2.utils_pkg.WriteAppend(v_xml, '</left><right>' || v_path || '</right></add>');
			END IF;
		END LOOP;
	END IF;

	calc_pkg.SetCalcXMLAndDeps(
		in_calc_ind_sid						=> in_ind_sid,
		in_calc_xml							=> v_xml,
		in_is_stored						=> 0,
		in_period_set_id					=> r_ind.period_set_id,
		in_period_interval_id				=> r_ind.period_interval_id,
		in_do_temporal_aggregation			=> 0,
		in_calc_description					=> NULL
	);	
	dbms_lob.close(v_xml);

	-- after changing the calc, we need to fix up calcs for any co2 indicators
	IF r_ind.factor_type_id IS NOT NULL THEN
		-- we want this to the kind of co2 calc that shadows the actual calcs -- i.e.
		-- adds up each of the ind selection co2 calcs rather than doing a stored FA
		-- you can't currently do this with the UI, but it would be possible to have different
		-- factor types for different data quality flags
		indicator_pkg.CreateGasIndicators(in_ind_sid, factor_pkg.UNSPECIFIED_FACTOR_TYPE);
	END IF;
	
	-- if we have removed indicators from a selection group, then decide what to do with them
	v_selection_sids_table := security_pkg.SidArrayToTable(v_selection_sids);
	FOR r IN (SELECT ind_sid
				FROM ind_selection_group_member
			   WHERE master_ind_sid = in_ind_sid
			   MINUS
			  SELECT column_value
			    FROM TABLE(v_selection_sids_table)) LOOP
			    	
		-- see if the indicator is in use
		SELECT COUNT(*)
		  INTO v_in_use
		  FROM dual 
		 WHERE EXISTS (SELECT 1 
		 				 FROM sheet_value 
		 				WHERE ind_sid = r.ind_sid)
		    OR EXISTS (SELECT 1 
		    			 FROM val 
		    			WHERE ind_sid = r.ind_sid)
			OR EXISTS (SELECT 1 
						 FROM calc_dependency
						WHERE ind_sid = r.ind_sid
						  AND calc_ind_sid != in_ind_sid);
		
		IF v_in_use = 0 THEN
			-- no, so remove it from the selection group and any delegations it is in, then trash it
			DELETE FROM ind_sel_group_member_desc
			 WHERE ind_sid = r.ind_sid;

			DELETE FROM ind_selection_group_member
			 WHERE ind_sid = r.ind_sid;
			
			DELETE FROM deleg_ind_form_expr
			 WHERE ind_sid = r.ind_sid;
				   
			DELETE FROM deleg_ind_group_member
			 WHERE ind_sid = r.ind_sid;
			
			DELETE FROM delegation_ind_description
			 WHERE ind_sid = r.ind_sid;

			DELETE FROM delegation_ind
			 WHERE ind_sid = r.ind_sid;
			   
			TrashObject(SYS_CONTEXT('SECURITY', 'ACT'), r.ind_sid);
		ELSE
			-- yes, so mark it inactive
			UPDATE ind
			   SET active = 0, last_modified_dtm = SYSDATE
			 WHERE ind_sid = r.ind_sid;
			 
			out_removals_skipped := 1;
		END IF;
	END LOOP;
	
	-- set any translations
	IF NOT (in_langs.COUNT = 0 OR (in_langs.COUNT = 1 AND in_langs(1) IS NULL)) AND
	   NOT (in_selection_names.COUNT = 0 OR (in_selection_names.COUNT = 1 AND in_selection_names(1) IS NULL)) THEN
		FOR i IN 1 .. in_selection_names.COUNT LOOP
			FOR j IN 1 .. in_langs.COUNT LOOP
				-- the description is "foo - bar" so get the current description in the appropriate language
				BEGIN
					SELECT description
					  INTO v_description
					  FROM ind_description
					 WHERE ind_sid = in_ind_sid
					   AND lang = in_langs(j);
				EXCEPTION
					WHEN NO_DATA_FOUND THEN
						SELECT description
						  INTO v_description
						  FROM ind_description
						 WHERE ind_sid = in_ind_sid
						   AND lang = 'en'; -- en must exist
				END;
				 
				v_sel_description := in_selection_translations((i - 1) * in_langs.COUNT + j);
				BEGIN
					INSERT INTO ind_sel_group_member_desc
						(ind_sid, lang, description)
					VALUES
						(v_selection_sids(i), in_langs(j), v_sel_description);
				EXCEPTION
					WHEN DUP_VAL_ON_INDEX THEN
						UPDATE ind_sel_group_member_desc
						   SET description = v_sel_description
						 WHERE ind_sid = v_selection_sids(i)
						   AND lang = in_langs(j);
				END;

				v_translation := v_description || ' - ' || v_sel_description;
				BEGIN
					INSERT INTO ind_description
						(ind_sid, lang, description)
					VALUES
						(v_selection_sids(i), in_langs(j), v_translation);
				EXCEPTION
					WHEN DUP_VAL_ON_INDEX THEN
						UPDATE ind_description
						   SET description = v_translation
						 WHERE ind_sid = v_selection_sids(i)
						   AND lang = in_langs(j);
				END;				
			END LOOP;
		END LOOP;
	END IF;

	-- if there are no selections left the selection group can be removed
	SELECT COUNT(*)
	  INTO v_in_use
	  FROM DUAL
	 WHERE EXISTS (SELECT 1
	  				 FROM ind_selection_group_member
				    WHERE master_ind_sid = in_ind_sid);				    
	IF v_in_use = 0 THEN
		DELETE FROM ind_selection_group
		 WHERE master_ind_sid = in_ind_sid;
	END IF;
END;

FUNCTION IsSystemManaged(
	in_ind_sid						IN	ind.ind_sid%TYPE
)
RETURN NUMBER
AS
	v_is_system_managed				ind.is_system_managed%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_ind_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading the ind with sid '||in_ind_sid);
	END IF;
	
	SELECT is_system_managed
	  INTO v_is_system_managed
	  FROM ind
	 WHERE ind_sid = in_ind_sid;
	 
	RETURN v_is_system_managed;
END;

PROCEDURE GetIndicatorsForList(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_indicator_list	IN	security_pkg.T_SID_IDS,
	out_cur				OUT	SYS_REFCURSOR
)
AS
	v_indicator_table		security.T_ORDERED_SID_TABLE;
BEGIN
	v_indicator_table := security_pkg.SidArrayToOrderedTable(in_indicator_list);
	OPEN out_cur FOR
		SELECT i.ind_sid, i.NAME, i.description, i.lookup_key, m.name measure_name, m.description measure_description,m.measure_sid,
			   i.gri, multiplier,	NVL(i.scale,m.scale) scale, NVL(i.format_mask, m.format_mask) format_mask, active,
			   i.scale actual_scale, i.format_mask actual_format_mask, i.calc_xml,
			   NVL(i.divisibility, m.divisibility) divisibility, i.divisibility actual_divisibility, i.start_month,
			   CASE
					WHEN i.measure_sid IS NULL THEN 'Category'
					WHEN i.ind_type=Csr_Data_Pkg.IND_TYPE_CALC THEN 'Calculation'
					WHEN i.ind_type=Csr_Data_Pkg.IND_TYPE_STORED_CALC THEN 'Stored calculation'
					ELSE 'Indicator'
			   END node_type, ind_type, calc_start_dtm_adjustment, calc_end_dtm_adjustment,
			   target_direction, last_modified_dtm, extract(info_xml,'/').getClobVal() info_xml, i.parent_sid, i.pos, 
			   i.tolerance_type, i.pct_lower_tolerance, i.pct_upper_tolerance,
			   --i.tolerance_number_of_periods, i.tolerance_number_of_standard_deviations_from_average,
			   i.ind_activity_type_id, i.core, i.roll_forward
		  FROM v$ind i, measure m, TABLE(v_indicator_table)l
		 WHERE i.measure_sid = m.measure_sid(+)
		   AND l.sid_id = i.ind_sid
		   AND security_pkg.SQL_IsAccessAllowedSID(in_act_id, l.sid_id, security_pkg.PERMISSION_READ) = 1
		 ORDER BY l.pos;
END;

PROCEDURE EnableIndicator(
	in_ind_sid			IN	security_pkg.T_SID_ID
)
AS
	v_app_sid  		security_pkg.T_SID_ID;
	v_act_id  		security_pkg.T_ACT_ID;
	v_active		ind.active%TYPE;
BEGIN
	v_app_sid := security_pkg.getapp();
	v_act_id := security_pkg.getact();
	
	IF NOT security_pkg.IsAccessAllowedSID(v_act_id, in_ind_sid, Csr_Data_Pkg.PERMISSION_ALTER_SCHEMA) AND NOT csr_data_pkg.CheckCapability('System management') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied altering schema');
	END IF;

	SELECT active INTO v_active FROM ind WHERE ind_sid = in_ind_sid;
	
	IF v_active <> 1 THEN
		csr_data_pkg.AuditValueChange(v_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, v_app_sid, 
									  in_ind_sid, 'Active', v_active, 1);
		
		UPDATE ind
		   SET active = 1
		 WHERE ind_sid = in_ind_sid;
	END IF;
END;

PROCEDURE EnableChildIndicators(
	in_ind_sid  IN	security_pkg.T_SID_ID
)
AS
	v_act_id  		security_pkg.T_ACT_ID;
BEGIN
	v_act_id := security_pkg.getact();

	FOR r IN (SELECT ind_sid, active, app_sid
				FROM ind
			   START WITH ind_sid = in_ind_sid 
	         CONNECT BY PRIOR ind_sid = parent_sid
	)
	LOOP
	
		-- check permission....
		IF NOT security_pkg.IsAccessAllowedSID(v_act_id, in_ind_sid, Csr_Data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied altering schema');
		END IF;
	
		csr_data_pkg.AuditValueChange(v_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, 
									  r.ind_sid, 'Active', r.active, 1);
		
		UPDATE ind
		   SET active = 1
		 WHERE ind_sid = r.ind_sid;
		
	END LOOP;
END;

PROCEDURE DisableChildIndicators(
	in_ind_sid  IN	security_pkg.T_SID_ID
)
AS
	v_act_id  		security_pkg.T_ACT_ID;
BEGIN
	v_act_id := security_pkg.getact();

	FOR r IN (SELECT ind_sid, active, app_sid
				FROM ind
			   START WITH ind_sid = in_ind_sid 
	         CONNECT BY PRIOR ind_sid = parent_sid
	)
	LOOP
	
		-- check permission....
		IF NOT security_pkg.IsAccessAllowedSID(v_act_id, in_ind_sid, Csr_Data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied altering schema');
		END IF;
	
		csr_data_pkg.AuditValueChange(v_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, 
									  r.ind_sid, 'Active', r.active, 0);
		
		UPDATE ind
		   SET active = 0
		 WHERE ind_sid = r.ind_sid;
		
	END LOOP;
END;

FUNCTION IsInReportingIndTree(
	in_ind_sid						IN	ind.ind_sid%TYPE
)
RETURN NUMBER
AS
	v_reporting_ind_root_sid		customer.reporting_ind_root_sid%TYPE;
	v_reporting_root_on_path		NUMBER;
BEGIN
	SELECT reporting_ind_root_sid
	  INTO v_reporting_ind_root_sid
	  FROM customer;
	  
	IF v_reporting_ind_root_sid IS NULL THEN
		RETURN 0;
	END IF;

	SELECT COUNT(*)
	  INTO v_reporting_root_on_path
	  FROM ind
	 WHERE ind_sid = v_reporting_ind_root_sid
	  	   START WITH ind_sid = in_ind_sid 
	  	   CONNECT BY app_sid = PRIOR app_sid AND ind_sid = PRIOR parent_sid;

	--security_pkg.debugmsg('is '||in_ind_sid||' in rep tree = '||v_reporting_root_on_path);
	RETURN CASE WHEN v_reporting_root_on_path = 0 THEN 0 ELSE 1 END;
END;

PROCEDURE GetAllTranslations(
	in_root_indicator_sids	IN 	security_pkg.T_SID_IDS,
	in_validation_lang		IN	region_description.lang%TYPE,
	in_changed_since		IN	DATE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_app_sid					security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	t							security.T_SID_TABLE;
BEGIN
	t := security_pkg.SidArrayToTable(in_root_indicator_sids);

	OPEN out_cur FOR
		WITH indicator AS (
			SELECT app_sid, ind_sid, active, lvl, ROWNUM rn
			  FROM (
				SELECT i.app_sid, i.ind_sid, i.active, LEVEL lvl
				  FROM ind i
				  JOIN (
					SELECT app_sid, ind_sid, description
					  FROM ind_description
					 WHERE app_sid = v_app_sid
					   AND lang = NVL(in_validation_lang, 'en')
				)id ON i.app_sid = id.app_sid AND i.ind_sid = id.ind_sid
				 WHERE i.app_sid = v_app_sid
				 START WITH i.ind_sid IN (SELECT column_value from TABLE(t))
			   CONNECT BY PRIOR i.ind_sid = i.parent_sid
				 ORDER SIBLINGS BY 
					   REGEXP_SUBSTR(LOWER(id.description), '^\D*') NULLS FIRST, 
					   TO_NUMBER(REGEXP_SUBSTR(LOWER(id.description), '[0-9]+')) NULLS FIRST, 
					   TO_NUMBER(CONCAT('0.', REGEXP_SUBSTR(LOWER(id.description), '[0-9]+', 1, 2))) NULLS FIRST,
					   TO_NUMBER(CONCAT('0.', REGEXP_SUBSTR(LOWER(id.description), '[0-9]+', 1, 3))) NULLS FIRST,
					   TO_NUMBER(CONCAT('0.', REGEXP_SUBSTR(LOWER(id.description), '[0-9]+', 1, 4))) NULLS FIRST,
					   LOWER(id.description), i.ind_sid
			)
		)
		SELECT i.ind_sid sid, i.active, id.description, id.lang, i.lvl so_level,
			   CASE WHEN id.last_changed_dtm > in_changed_since THEN 1 ELSE 0 END has_changed
		  FROM indicator i
		  JOIN aspen2.translation_set ts ON i.app_sid = ts.application_sid
		  LEFT JOIN ind_description id ON i.app_sid = id.app_sid AND i.ind_sid = id.ind_sid AND ts.lang = id.lang
		 ORDER BY rn,
			   CASE WHEN ts.lang = NVL(in_validation_lang, 'en') THEN 0 ELSE 1 END,
			   LOWER(ts.lang);
END;

PROCEDURE ValidateTranslations(
	in_ind_sids				IN	security.security_pkg.T_SID_IDS,
	in_descriptions			IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_validation_lang		IN	region_description.lang%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_act						security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
	v_ind_sid_desc_tbl			T_SID_AND_DESCRIPTION_TABLE := T_SID_AND_DESCRIPTION_TABLE();
BEGIN
	IF in_ind_sids.COUNT != in_descriptions.COUNT THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_ARRAY_SIZE_MISMATCH, 'Number of ind sids do not match number of descriptions.');
	END IF;
	
	IF in_ind_sids.COUNT = 0 THEN
		RETURN;
	END IF;

	v_ind_sid_desc_tbl.EXTEND(in_ind_sids.COUNT);

	FOR i IN 1..in_ind_sids.COUNT
	LOOP
		v_ind_sid_desc_tbl(i) := T_SID_AND_DESCRIPTION_ROW(i, in_ind_sids(i), in_descriptions(i));
	END LOOP;

	OPEN out_cur FOR
		SELECT id.ind_sid sid,
			   CASE id.description WHEN idt.description THEN 0 ELSE 1 END has_changed,
			   security.security_pkg.SQL_IsAccessAllowedSID(v_act, id.ind_sid, security_pkg.PERMISSION_WRITE) can_write
		  FROM ind_description id
		  JOIN TABLE(v_ind_sid_desc_tbl) idt ON id.ind_sid = idt.sid_id
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND lang = in_validation_lang;
END;

PROCEDURE GetAllSelectionGrpTranslations(
	in_root_indicator_sids	IN 	security_pkg.T_SID_IDS,
	in_validation_lang		IN	region_description.lang%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_app_sid					security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	t							security.T_SID_TABLE;
BEGIN
	t := security_pkg.SidArrayToTable(in_root_indicator_sids);

	OPEN out_cur FOR
		SELECT mem.ind_sid member_ind_sid, mem.master_ind_sid, id.description group_description, memdesc.lang lang, memdesc.description description, i.active
		  FROM ind_selection_group_member mem
		  JOIN ind_description id on mem.master_ind_sid = id.ind_sid
		  JOIN ind_sel_group_member_desc memdesc on memdesc.ind_sid = mem.ind_sid
		  JOIN ind i on i.ind_sid = mem.ind_sid
		 WHERE id.lang = in_validation_lang
		 ORDER BY mem.master_ind_sid, mem.ind_sid;

	OPEN out_cur FOR
		WITH indicator AS (
			SELECT app_sid, ind_sid, active, ROWNUM rn
			  FROM (
				SELECT i.app_sid, i.ind_sid, i.active
				  FROM ind i
				  JOIN (
					SELECT app_sid, ind_sid, description
					  FROM ind_description
					 WHERE app_sid = v_app_sid
					   AND lang = NVL(in_validation_lang, 'en')
				)id ON i.app_sid = id.app_sid AND i.ind_sid = id.ind_sid
				 WHERE i.app_sid = v_app_sid
				 START WITH i.ind_sid IN (SELECT column_value from TABLE(t))
			   CONNECT BY PRIOR i.ind_sid = i.parent_sid
				 ORDER SIBLINGS BY 
					   REGEXP_SUBSTR(LOWER(id.description), '^\D*') NULLS FIRST, 
					   TO_NUMBER(REGEXP_SUBSTR(LOWER(id.description), '[0-9]+')) NULLS FIRST, 
					   TO_NUMBER(CONCAT('0.', REGEXP_SUBSTR(LOWER(id.description), '[0-9]+', 1, 2))) NULLS FIRST,
					   TO_NUMBER(CONCAT('0.', REGEXP_SUBSTR(LOWER(id.description), '[0-9]+', 1, 3))) NULLS FIRST,
					   TO_NUMBER(CONCAT('0.', REGEXP_SUBSTR(LOWER(id.description), '[0-9]+', 1, 4))) NULLS FIRST,
					   LOWER(id.description), i.ind_sid
			)
		)
		SELECT mem.ind_sid member_ind_sid, mem.master_ind_sid, id.description group_description, memdesc.lang lang, memdesc.description description, i.active
		  FROM ind_selection_group_member mem
		  JOIN ind_description id on mem.master_ind_sid = id.ind_sid
		  JOIN ind_sel_group_member_desc memdesc on memdesc.ind_sid = mem.ind_sid
		  JOIN indicator i on i.ind_sid = mem.ind_sid
		  JOIN aspen2.translation_set ts ON i.app_sid = ts.application_sid
		 WHERE id.lang = NVL(in_validation_lang, 'en')
		 ORDER BY rn, mem.ind_sid,
			   CASE WHEN ts.lang = NVL(in_validation_lang, 'en') THEN 0 ELSE 1 END,
			   LOWER(ts.lang);
END;

PROCEDURE ValidateSelectGrpTranslations(
	in_ind_sids				IN	security.security_pkg.T_SID_IDS,
	in_descriptions			IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_validation_lang		IN	region_description.lang%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_act						security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
	v_ind_sid_desc_tbl			T_SID_AND_DESCRIPTION_TABLE := T_SID_AND_DESCRIPTION_TABLE();
BEGIN
	IF in_ind_sids.COUNT != in_descriptions.COUNT THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_ARRAY_SIZE_MISMATCH, 'Number of ind sids do not match number of descriptions.');
	END IF;
	
	IF in_ind_sids.COUNT = 0 THEN
		RETURN;
	END IF;

	v_ind_sid_desc_tbl.EXTEND(in_ind_sids.COUNT);

	FOR i IN 1..in_ind_sids.COUNT
	LOOP
		v_ind_sid_desc_tbl(i) := T_SID_AND_DESCRIPTION_ROW(i, in_ind_sids(i), in_descriptions(i));
	END LOOP;

	OPEN out_cur FOR
		SELECT id.ind_sid sid,
			   CASE id.description WHEN idt.description THEN 0 ELSE 1 END has_changed,
			   security.security_pkg.SQL_IsAccessAllowedSID(v_act, id.ind_sid, security_pkg.PERMISSION_WRITE) can_write
		  FROM ind_sel_group_member_desc id
		  JOIN TABLE(v_ind_sid_desc_tbl) idt ON id.ind_sid = idt.sid_id
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND lang = in_validation_lang;
END;

PROCEDURE SetIndSelectGrpTranslation(
	in_ind_sid			IN 	security_pkg.T_SID_ID,
	in_lang				IN	aspen2.tr_pkg.T_LANG,
	in_translated		IN	VARCHAR2
)
AS
	v_act				security_pkg.T_ACT_ID;
	v_description		ind_description.description%TYPE;
	v_group_description	ind_description.description%TYPE;
	v_app_sid			security_pkg.T_SID_ID;
BEGIN
	-- NB ind_sel_group_member_desc must have descriptions for ALL customer languages
	v_act := security_pkg.GetACT();
	IF NOT Security_pkg.IsAccessAllowedSID(v_act, in_ind_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied updating selection group translations for the indicator with sid ' ||in_ind_sid);
	END IF;

	SELECT NVL(description, '')
	  INTO v_description
	  FROM ind_sel_group_member_desc
	 WHERE ind_sid = in_ind_sid
	   AND lang = in_lang;
	   
	-- Despite the above comment, description CAN sometimes be missing for some languages, eg, if you enable a language
	-- after creating the indicator/region. So, we need to do an upsert to ensure we actually set the language.
	BEGIN
		INSERT INTO ind_sel_group_member_desc
			(ind_sid, lang, description)
		VALUES
			(in_ind_sid, in_lang, in_translated);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE ind_sel_group_member_desc
			   SET description = in_translated
			 WHERE ind_sid = in_ind_sid 
			   AND lang = in_lang;
	END;
	
	-- Now propagate the selection description to the actual indicator
	SELECT id.description
	  INTO v_group_description
	  FROM ind_selection_group_member mem
	  JOIN ind_description id ON mem.master_ind_sid = id.ind_sid
	 WHERE mem.ind_sid = in_ind_sid
	   AND lang = in_lang
	   AND mem.app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	SetTranslation(
		in_ind_sid			=> in_ind_sid,
		in_lang				=> in_lang,
		in_translated		=> v_group_description || ' - ' || in_translated
	);
	
	IF v_description != in_translated THEN
		csr_data_pkg.AuditValueChange(v_act, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, SYS_CONTEXT('SECURITY', 'APP'), 
			in_ind_sid, 'Selection description ('||in_lang||')', v_description, in_translated);
	END IF;
END;

PROCEDURE GetScragIndicators(
	in_ind_sids				IN	security.security_pkg.T_SID_IDS,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	t							security.T_SID_TABLE;
BEGIN
	t := security_pkg.SidArrayToTable(in_ind_sids);
	
	OPEN out_cur FOR
		SELECT ind_sid, ind_type, NVL(i.divisibility, m.divisibility) divisibility, period_set_id, period_interval_id, start_month, pct_ownership_applies, do_temporal_aggregation, 
			   target_direction, calc_xml, m.factor, m.m, m.kg, m.s, m.a, m.k, m.mol, m.cd
		  FROM ind i
		  JOIN measure m on i.measure_sid = m.measure_sid
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND ind_sid IN (SELECT column_value FROM TABLE(t));
END;

FUNCTION GetTrashedIndSids
RETURN security.T_SID_TABLE
AS
	v_trashed_ind_sids		security.T_SID_TABLE;
BEGIN
	SELECT ind_sid
	  BULK COLLECT INTO v_trashed_ind_sids
	  FROM (
			SELECT ind_sid
			  FROM ind 
			START WITH parent_sid IN (SELECT trash_sid FROM customer WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP'))
			CONNECT BY PRIOR ind_sid = parent_sid
		);
	RETURN v_trashed_ind_sids;
END;

PROCEDURE INTERNAL_GetCoreIndsBySids(
	in_ind_sids					IN	security.T_SID_TABLE,
	out_ind_cur					OUT	SYS_REFCURSOR,
	out_description_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_ind_cur FOR
		SELECT i.ind_sid AS ind_id, i.parent_sid AS parent_id, i.ind_type, i.measure_sid AS measure_id, m.description AS measure_description, i.lookup_key
		  FROM ind i
		  LEFT JOIN csr.measure m ON i.measure_sid = m.measure_sid AND i.app_sid = m.app_sid
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.ind_sid IN (SELECT column_value FROM TABLE(in_ind_sids))
		ORDER BY i.ind_sid;

	OPEN out_description_cur FOR
		SELECT i.ind_sid AS ind_id, d.lang AS "language", d.description
		  FROM ind i
		  JOIN ind_description d ON i.ind_sid = d.ind_sid AND  i.app_sid = d.app_sid
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.ind_sid IN (SELECT column_value FROM TABLE(in_ind_sids))
		ORDER BY i.ind_sid;
END;

PROCEDURE INTERNAL_GetCoreIndicators(
	in_include_all				IN	NUMBER,
	in_include_null_lookup_keys	IN	NUMBER,
	in_lookup_keys				IN	security.T_VARCHAR2_TABLE,
	in_skip						IN	NUMBER,
	in_take						IN	NUMBER,
	out_ind_cur					OUT	SYS_REFCURSOR,
	out_description_cur			OUT	SYS_REFCURSOR,
	out_total_rows_cur			OUT	SYS_REFCURSOR
)
AS
	v_lookup_keys				security.T_VARCHAR2_TABLE;
	v_ind_sids					security.T_SID_TABLE;
	v_trashed_ind_sids			security.T_SID_TABLE;
BEGIN
	v_lookup_keys := in_lookup_keys;
	v_trashed_ind_sids := GetTrashedIndSids();
			
	SELECT ind_sid
	  BULK COLLECT INTO v_ind_sids
	  FROM (
		SELECT ind_sid, rownum rn
		  FROM (
				SELECT i.ind_sid
				  FROM ind i
				 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND (in_include_all = 1 OR (LOWER(i.lookup_key) IN (SELECT LOWER(x.value) FROM TABLE(v_lookup_keys) x)) OR (i.lookup_key IS NULL AND in_include_null_lookup_keys = 1))
				   AND i.ind_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_ind_sids))
				ORDER BY i.ind_sid
				)
			)
		WHERE rn > in_skip
		  AND rn < in_skip + in_take + 1;

	OPEN out_total_rows_cur FOR
		SELECT COUNT(i.ind_sid) total_rows
		  FROM ind i
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND (in_include_all = 1 OR (LOWER(i.lookup_key) IN (SELECT LOWER(x.value) FROM TABLE(v_lookup_keys) x)) OR (i.lookup_key IS NULL AND in_include_null_lookup_keys = 1))
		   AND i.ind_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_ind_sids));
		
		INTERNAL_GetCoreIndsBySids(
		in_ind_sids				=>	v_ind_sids,
		out_ind_cur				=>	out_ind_cur,
		out_description_cur		=>	out_description_cur
	);
END;

PROCEDURE GetCoreIndicators(
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	out_ind_cur				OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_total_rows_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN
	INTERNAL_GetCoreIndicators(
		in_include_all				=> 1,
		in_include_null_lookup_keys	=> 0,
		in_lookup_keys				=> security.T_VARCHAR2_TABLE(),
		in_skip						=> in_skip,
		in_take						=> in_take,
		out_ind_cur					=> out_ind_cur,
		out_description_cur			=> out_description_cur,
		out_total_rows_cur			=> out_total_rows_cur
	);	
END;

PROCEDURE GetCoreIndicatorsByLookupKey(
	in_lookup_keys			IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	out_ind_cur				OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_total_rows_cur		OUT	SYS_REFCURSOR
)
AS
	v_lookup_keys				security.T_VARCHAR2_TABLE;
	v_lookup_keys_count			NUMBER;
	v_lookup_contains_null		NUMBER(1) := 0;
BEGIN	
	v_lookup_keys := security_pkg.Varchar2ArrayToTable(in_lookup_keys);
	SELECT COUNT(*)
	  INTO v_lookup_keys_count
	  FROM TABLE(v_lookup_keys);
	
	IF in_lookup_keys.COUNT = 1 AND v_lookup_keys_count = 0 THEN
		-- Single null key in the params doesn't turn into a single null table entry for some reason.
		v_lookup_contains_null := 1;
	END IF;
	
	FOR r IN (SELECT value FROM TABLE(v_lookup_keys))
	LOOP
		IF r.value IS NULL OR LENGTH(r.value) = 0 THEN
			v_lookup_contains_null := 1;
			EXIT;
		END IF;
	END LOOP;
	
	INTERNAL_GetCoreIndicators(
		in_include_all				=> 0,
		in_include_null_lookup_keys	=> v_lookup_contains_null,
		in_lookup_keys				=> v_lookup_keys,
		in_skip						=> in_skip,
		in_take						=> in_take,
		out_ind_cur					=> out_ind_cur,
		out_description_cur			=> out_description_cur,
		out_total_rows_cur			=> out_total_rows_cur
	);
END;

PROCEDURE UNSEC_GetCoreIndsByDescription(
	in_description			IN	ind_description.description%TYPE,
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	out_ind_cur				OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_total_rows_cur		OUT	SYS_REFCURSOR
)
AS
	v_ind_sids				security.T_SID_TABLE;
	v_trashed_ind_sids		security.T_SID_TABLE;
BEGIN
	v_trashed_ind_sids := GetTrashedIndSids();

	SELECT ind_sid
	  BULK COLLECT INTO v_ind_sids
	  FROM (
		SELECT ind_sid, rownum rn
		  FROM (
			SELECT DISTINCT i.ind_sid
			  FROM ind i
			  JOIN ind_description d ON i.ind_sid = d.ind_sid AND  i.app_sid = d.app_sid
			 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND d.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
			   AND LOWER(d.description) = LOWER(in_description)
			   AND i.ind_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_ind_sids))
			ORDER BY i.ind_sid
				)
			)
		 WHERE rn > in_skip
		  AND rn < in_skip + in_take + 1;

	OPEN out_total_rows_cur FOR
		SELECT COUNT(DISTINCT(i.ind_sid)) total_rows
		  FROM ind i
		  JOIN ind_description d ON i.ind_sid = d.ind_sid AND  i.app_sid = d.app_sid
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND LOWER(d.description) = LOWER(in_description)
		   AND i.ind_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_ind_sids));

	INTERNAL_GetCoreIndsBySids(
		in_ind_sids				=>	v_ind_sids,
		out_ind_cur				=>	out_ind_cur,
		out_description_cur		=>	out_description_cur
	);
END;

PROCEDURE UNSEC_GetCoreIndsByMeasureSid(
	in_measure_sid			IN	ind.measure_sid%TYPE,
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	out_ind_cur				OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_total_rows_cur		OUT	SYS_REFCURSOR
)
AS
	v_ind_sids				security.T_SID_TABLE;
	v_trashed_ind_sids		security.T_SID_TABLE;
BEGIN
	v_trashed_ind_sids := GetTrashedIndSids();

	SELECT ind_sid
	  BULK COLLECT INTO v_ind_sids
	  FROM (
		SELECT ind_sid, rownum rn
		  FROM (
			SELECT DISTINCT i.ind_sid
			  FROM ind i
			 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND i.measure_sid = in_measure_sid
			   AND i.ind_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_ind_sids))
			ORDER BY i.ind_sid
				)
			)
		 WHERE rn > in_skip
		  AND rn < in_skip + in_take + 1;

	OPEN out_total_rows_cur FOR
		SELECT COUNT(DISTINCT(i.ind_sid)) total_rows
		  FROM ind i
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.measure_sid = in_measure_sid
		   AND i.ind_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_ind_sids));

	INTERNAL_GetCoreIndsBySids(
		in_ind_sids				=>	v_ind_sids,
		out_ind_cur				=>	out_ind_cur,
		out_description_cur		=>	out_description_cur
	);
END;

PROCEDURE FindCoreIndicatorByPath(
	in_path				IN	VARCHAR2,
	in_separator		IN	VARCHAR2 DEFAULT '/',
	out_cur				OUT	SYS_REFCURSOR
)
AS
	TYPE T_PATH IS TABLE OF VARCHAR2(1024) INDEX BY BINARY_INTEGER;
	v_path_parts 			T_PATH;
	v_parents				security.T_SID_TABLE;
	v_new_parents			security.T_SID_TABLE;
	v_indicators_folder		security_pkg.T_SID_ID;
	v_trashed_ind_sids		security.T_SID_TABLE;
BEGIN

	v_indicators_folder := securableobject_pkg.GetSIDFromPath(security_pkg.getAct, security_pkg.getApp, 'indicators');
	v_trashed_ind_sids := GetTrashedIndSids();

	SELECT LOWER(TRIM(item)) 
	  BULK COLLECT INTO v_path_parts 
	  FROM table(utils_pkg.SplitString(in_path, in_separator));

	-- Populate possible parents with the first part of the path
	BEGIN
		SELECT ind_sid
		  BULK COLLECT INTO v_parents
		  FROM v$ind
		 WHERE LOWER(description) = v_path_parts(1)
		   AND app_sid = security_pkg.getApp
		   AND active = 1
		   AND ind_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_ind_sids))
		   AND ind_sid IN (
				SELECT ind_sid
				  FROM ind
				 START WITH ind_sid = v_indicators_folder
			   CONNECT BY PRIOR ind_sid = parent_sid);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			OPEN out_cur FOR
				SELECT ind_sid, description
				  FROM v$ind
				 WHERE 1 = 0;
			RETURN;
	END;

	-- Now check each part of the rest of the path
	FOR i IN 2 .. v_path_parts.LAST
	LOOP
		-- Select everything that matches into a set of possible parents
		SELECT ind_sid 
		  BULK COLLECT INTO v_new_parents
		  FROM v$ind
		 WHERE LOWER(description) = TRIM(v_path_parts(i))
		   AND active = 1
		   AND parent_sid IN (SELECT COLUMN_VALUE FROM TABLE(v_parents));

		-- We have to select into a different collection, so copy back on top
		v_parents := v_new_parents;
		IF v_parents.COUNT = 0 THEN
			EXIT;
		END IF;
	END LOOP;

	-- Return the stuff we've found
	OPEN out_cur FOR
		SELECT ind_sid
		  FROM v$ind
		 WHERE ind_sid IN (SELECT column_value FROM TABLE(v_parents))
		   AND measure_sid IS NOT NULL
		   AND ind_type = csr_data_pkg.IND_TYPE_NORMAL
		   AND security_pkg.SQL_IsAccessAllowedSID(security_pkg.getAct, ind_sid, security_pkg.PERMISSION_READ) = 1;
END;

PROCEDURE UNSEC_GetCoreIndBySid(
	in_sid					IN	ind.ind_sid%TYPE,
	out_ind_cur				OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_ind_cur FOR
		SELECT DISTINCT i.ind_sid AS ind_id, i.parent_sid AS parent_id, i.ind_type, i.measure_sid AS measure_id, m.description AS measure_description, i.lookup_key
		  FROM ind i
		  LEFT JOIN csr.measure m ON i.measure_sid = m.measure_sid AND i.app_sid = m.app_sid
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.ind_sid = in_sid;

	OPEN out_description_cur FOR
		SELECT DISTINCT i.ind_sid as ind_id, d.lang AS "language", d.description
		  FROM ind i
		  JOIN ind_description d ON i.ind_sid = d.ind_sid AND  i.app_sid = d.app_sid
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.ind_sid = in_sid;
END;

PROCEDURE UNSEC_GetCoreIndByPath(
	in_path					IN	VARCHAR2,
	out_ind_cur				OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR
)
AS
	v_ind_sid					security_pkg.T_SID_ID;
	path_cur 					SYS_REFCURSOR;
BEGIN
	FindCoreIndicatorByPath(
		in_path				=> LOWER(in_path),
		in_separator		=> '/',
		out_cur				=> path_cur
	);

	LOOP
		FETCH path_cur INTO v_ind_sid;
		 EXIT WHEN path_cur%notfound;
	END LOOP;
	CLOSE path_cur;

	OPEN out_ind_cur FOR
		SELECT DISTINCT i.ind_sid AS ind_id, i.parent_sid AS parent_id, i.ind_type, i.measure_sid AS measure_id, m.description AS measure_description, i.lookup_key
		  FROM ind i
		  LEFT JOIN csr.measure m ON i.measure_sid = m.measure_sid AND i.app_sid = m.app_sid
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.ind_sid = v_ind_sid;

	OPEN out_description_cur FOR
		SELECT DISTINCT i.ind_sid AS ind_id, d.lang AS "language", d.description
		  FROM ind i
		  JOIN ind_description d ON i.ind_sid = d.ind_sid AND  i.app_sid = d.app_sid
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.ind_sid = v_ind_sid;
END;


PROCEDURE GetIndicatorScripts(
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT i.ind_sid, i.description, i.calc_xml AS script
		  FROM v$ind i
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.calc_xml like '<script>%';
END;

PROCEDURE GetIndicatorScript(
	in_ind_sid				IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT i.ind_sid, i.description, i.calc_xml AS script
		  FROM v$ind i
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.ind_sid = in_ind_sid;
END;

PROCEDURE UpdateIndicatorScript(
	in_ind_sid				IN	security_pkg.T_SID_ID,
	in_script				IN	VARCHAR2
)
AS
	v_calc_xml	ind.calc_xml%type;
	v_ind_type	ind.ind_type%type;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_ind_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on the indicator with sid '||in_ind_sid);
	END IF;
	
	IF INSTR(LOWER(in_script), '<script>') != 1
	THEN
		RAISE_APPLICATION_ERROR(-20001, 'Invalid script for '||in_ind_sid);
	END IF;

	SELECT calc_xml, ind_type
	  INTO v_calc_xml, v_ind_type
	  FROM ind
	 WHERE ind_sid = in_ind_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	   
	IF v_calc_xml LIKE '<script%' THEN
		IF NOT csr_data_pkg.CheckCapability('Can edit cscript inds') THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Insufficient capabilities to edit script for '||in_ind_sid);
		END IF;
	ELSE 
		IF NOT csr_data_pkg.CheckCapability('Can create cscript inds') THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Insufficient capabilities to create script for '||in_ind_sid);
		END IF;
	END IF;

	IF v_ind_type = Csr_Data_Pkg.IND_TYPE_NORMAL THEN
		v_ind_type := Csr_Data_Pkg.IND_TYPE_CALC;
	END IF;

	UPDATE ind
	   SET calc_xml = in_script, ind_type = v_ind_type, last_modified_dtm = SYSDATE, is_system_managed = 1
	 WHERE ind_sid = in_ind_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	-- First of all, add jobs for this indicator - if we're not a stored calculation this won't do anything
	calc_pkg.addJobsForCalc(in_ind_sid); 
	-- Now add jobs for any stored calculations that use our indicator
	calc_Pkg.addJobsForInd(in_ind_sid);

	csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, SYS_CONTEXT('SECURITY', 'APP'), in_ind_sid,
		'Modified cscript, from "{0}" to "{1}"', v_calc_xml, in_script);
END;

PROCEDURE ClearIndicatorScript(
	in_ind_sid				IN	security_pkg.T_SID_ID
)
AS
	v_calc_xml	ind.calc_xml%type;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_ind_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on the indicator with sid '||in_ind_sid);
	END IF;
	
	IF NOT csr_data_pkg.CheckCapability('Can edit cscript inds') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Unsufficient capabilities to reset script for '||in_ind_sid);
	END IF;
	
	SELECT calc_xml
	  INTO v_calc_xml
	  FROM ind
	 WHERE ind_sid = in_ind_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	UPDATE ind
	   SET calc_xml = NULL, ind_type = Csr_Data_Pkg.IND_TYPE_NORMAL, last_modified_dtm = SYSDATE, is_system_managed = 0
	 WHERE ind_sid = in_ind_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	-- First of all, add jobs for this indicator - if we're not a stored calculation this won't do anything
	calc_pkg.addJobsForCalc(in_ind_sid); 
	-- Now add jobs for any stored calculations that use our indicator
	calc_Pkg.addJobsForInd(in_ind_sid);

	csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, SYS_CONTEXT('SECURITY', 'APP'), in_ind_sid,
		'Clear cscript, from "{0}"', v_calc_xml);
END;

PROCEDURE GetIndicators(
	in_indicator_sids				IN	security.security_pkg.T_SID_IDS,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_allowed_ind_sids_t			security.T_SO_TABLE := security.securableObject_pkg.GetSIDsWithPermAsTable(SYS_CONTEXT('SECURITY', 'ACT'), security.security_pkg.SidArrayToTable(in_indicator_sids), security_pkg.PERMISSION_READ);
BEGIN

	OPEN out_cur FOR
		SELECT i.ind_sid sid, i.parent_sid, i.description, i.active is_active, i.ind_type indicator_type, i.lookup_key, i.measure_sid
		  FROM v$ind i
		  JOIN TABLE(v_allowed_ind_sids_t) t ON t.sid_id = i.ind_sid;
END;

PROCEDURE GetIndicatorFactor(
	in_ind_sid						IN security.security_pkg.T_SID_ID,
	out_factor_set				OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_factor_set FOR
		SELECT  i.ind_sid,ft.name factor_type_name,NVL(f.note, cf.note) factor_note
		 FROM v$ind i
		 JOIN factor f on f.factor_type_id = i.factor_type_id
		 JOIN factor_type ft ON ft.factor_type_id = f.factor_type_id
		 JOIN custom_factor cf ON cf.factor_type_id = i.factor_type_id
		 WHERE i.ind_sid = in_ind_sid;
END;

END Indicator_Pkg;
/
