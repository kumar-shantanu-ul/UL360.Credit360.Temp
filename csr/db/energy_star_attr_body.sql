CREATE OR REPLACE PACKAGE BODY CSR.energy_star_attr_pkg IS

FUNCTION AttrMapArraysToTable(
	in_attr_names			IN	security_pkg.T_VARCHAR2_ARRAY,
	in_ind_sids				IN	security_pkg.T_SID_IDS,
	in_uoms					IN	security_pkg.T_VARCHAR2_ARRAY,
	in_convs				IN	security_pkg.T_SID_IDS,
	in_space_flags			IN	security_pkg.T_SID_IDS
) RETURN T_ENERGY_STAR_ATTR_MAP_TABLE DETERMINISTIC
AS 
	v_table 	T_ENERGY_STAR_ATTR_MAP_TABLE := T_ENERGY_STAR_ATTR_MAP_TABLE();
BEGIN
	IF in_attr_names.COUNT = 0 THEN
		RETURN v_table;
	END IF;
	
	FOR i IN in_attr_names.FIRST .. in_attr_names.LAST
	LOOP
		BEGIN
			v_table.EXTEND;
			v_table(v_table.COUNT) := T_ENERGY_STAR_ATTR_MAP_ROW(
				in_attr_names(i),
				in_ind_sids(i),
				in_uoms(i),
				in_convs(i),
				in_space_flags(i)
			);
		END;
	END LOOP;
	
	RETURN v_table;
END;


PROCEDURE SetType(
	in_type_name		IN	est_attr_type.type_name%TYPE,
	in_basic_type		IN	est_attr_type.basic_type%TYPE
)
AS
BEGIN
	BEGIN
		INSERT INTO est_attr_type (type_name, basic_type)
		VALUES (in_type_name, in_basic_type);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE est_attr_type
			   SET basic_type = in_basic_type
			 WHERE type_name = in_type_name;
	END;
END;

PROCEDURE SetBuildingAttr(
	in_attr_name		IN	est_attr_for_building.attr_name%TYPE,
	in_type_name		IN	est_attr_for_building.type_name%TYPE,
	in_is_mandatory		IN	est_attr_for_building.is_mandatory%TYPE
)
AS
BEGIN
	BEGIN
		INSERT INTO est_attr_for_building (attr_name, type_name, is_mandatory)
		VALUES (in_attr_name, in_type_name, in_is_mandatory);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE est_attr_for_building
			   SET type_name = in_type_name,
			   	   is_mandatory = in_is_mandatory
			 WHERE attr_name = in_attr_name;
	END;
END;

PROCEDURE SetSpaceAttr(
	in_attr_name		IN	est_attr_for_space.attr_name%TYPE,
	in_type_name		IN	est_attr_type.type_name%TYPE,
	in_notes			IN	est_attr_for_space.notes%TYPE
)
AS
BEGIN
	BEGIN
		INSERT INTO est_attr_for_space (attr_name, type_name, notes)
		VALUES (in_attr_name, in_type_name, in_notes);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE est_attr_for_space
			   SET type_name = in_type_name,
			   	   notes = in_notes
			 WHERE attr_name = in_attr_name;
	END;
END;

PROCEDURE SetUnit(
	in_type_name		IN	est_attr_type.type_name%TYPE,
	in_uom				IN	est_attr_unit.uom%TYPE
)
AS
BEGIN
	BEGIN
		INSERT INTO est_attr_unit (type_name, uom)
		VALUES (in_type_name, in_uom);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

PROCEDURE SetEnum(
	in_type_name		IN	est_attr_type.type_name%TYPE,
	in_enum				IN	est_attr_enum.enum%TYPE,
	in_pos				IN	est_attr_enum.pos%TYPE
)
AS
BEGIN
	BEGIN
		INSERT INTO est_attr_enum (type_name, enum, pos)
		VALUES (in_type_name, in_enum, in_pos);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE est_attr_enum
			   SET pos = in_pos
			 WHERE type_name = in_type_name
			   AND enum = in_enum;
	END;
END;

PROCEDURE SetSpaceTypeAttr(
	in_est_space_type	IN	est_space_type_attr.est_space_type%TYPE,
	in_attr_name		IN	est_space_type_attr.attr_name%TYPE,
	in_is_mandatory		IN	est_space_type_attr.is_mandatory%TYPE
)
AS
BEGIN
	BEGIN
		INSERT INTO est_space_type_attr (est_space_type, attr_name, is_mandatory)
		VALUES (in_est_space_type, in_attr_name, in_is_mandatory);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE est_space_type_attr
			   SET is_mandatory = in_is_mandatory
			 WHERE est_space_type = in_est_space_type
			   AND attr_name = in_attr_name;
	END;
END;

PROCEDURE InstallPropertyTypes
AS
BEGIN
	-- Insert the simulated building metric types (same for all properties)
	
	-- gross floor area
	SetType('grossFloorAreaType', 'INT');
	SetUnit('grossFloorAreaType', 'Square Feet');
	SetUnit('grossFloorAreaType', 'Square Meters');
	SetBuildingAttr('bldgGrossFloorArea', 'grossFloorAreaType', 1);
	
	-- number of buildings
	SetType('numberOfBuildingsType', 'INT');
	SetUnit('numberOfBuildingsType', '<null>');
	SetBuildingAttr('numberOfBuildings', 'numberOfBuildingsType', 0);
	
	-- occupancy percentage
	SetType('occupancyPercentageType', 'INT');
	SetUnit('occupancyPercentageType', '<null>');
	SetBuildingAttr('occupancyPercentage', 'occupancyPercentageType', 0);
END;

PROCEDURE InstallSpaceTypes
AS
	v_space_type_id		space_type.space_type_id%TYPE;
BEGIN
	FOR st IN (
		SELECT DISTINCT est_space_type
		  FROM est_space_type_attr
 	) LOOP
 		
 		-- Create a CR360 space type
 		INSERT INTO space_type (space_type_id, label)
 		VALUES (space_type_id_seq.NEXTVAL, INITCAP(REGEXP_REPLACE(st.est_space_type, '([A-Z])', ' \1')))
 			RETURNING space_type_id INTO v_space_type_id;
 		
 		-- Insert tht CR360 -> ES mapping
 		INSERT INTO est_space_type_map (est_space_type, space_type_id)
 		VALUES(st.est_space_type, v_space_type_id);
 		
	END LOOP;
	
	-- Allow the energy star proprerty type to have all space types
	INSERT INTO property_type_space_type (property_type_id, space_type_id)
		SELECT pt.property_type_id, st.space_type_id
		  FROM property_type pt, space_type st
		 WHERE pt.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND pt.app_sid = st.app_sid
		   AND pt.label = 'Energy Star';
END;

PROCEDURE GetAttributeData(
	in_est_account_sid	IN	security_pkg.T_SID_ID,
	out_attrs			OUT	security_pkg.T_OUTPUT_CUR,
	out_types			OUT	security_pkg.T_OUTPUT_CUR,
	out_enums			OUT	security_pkg.T_OUTPUT_CUR,
	out_units			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_est_account_sid	security_pkg.T_SID_ID;
BEGIN
	v_est_account_sid := in_est_account_sid;
	IF v_est_account_sid IS NULL THEN
		SELECT default_account_sid
		  INTO v_est_account_sid
		  FROM est_options
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	END IF;
	
	OPEN out_attrs FOR
		SELECT * FROM (
			SELECT attr_name, type_name, uom, ind_sid, ind_desc, measure_sid, measure_conversion_id, measure_conv_desc, has_data, 1 is_space, null label
			  FROM (
				WITH attr_data AS (
					SELECT attr_name, uom 
					  FROM est_space_attr 
					 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
					   AND est_account_sid = v_est_account_sid
					 GROUP BY attr_name, uom -- Distinct
				)
				SELECT a.attr_name, a.type_name, u.uom, sam.ind_sid, i.description ind_desc, i.measure_sid, sam.measure_conversion_id, 
					NVL(c.description, m.description) measure_conv_desc, DECODE(sa.attr_name, NULL, 0, 1) has_data
				  FROM est_attr_for_space a
				  JOIN est_attr_unit u ON u.type_name = a.type_name
				  LEFT JOIN est_space_attr_mapping sam ON sam.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND sam.est_account_sid = v_est_account_sid AND sam.attr_name = a.attr_name AND sam.uom = u.uom
				  LEFT JOIN v$ind i ON i.app_sid = sam.app_sid AND i.ind_sid = sam.ind_sid
				  LEFT JOIN measure m ON m.app_sid = i.app_sid AND m.measure_sid = i.measure_sid
				  LEFT JOIN measure_conversion c ON c.app_sid = m.app_sid AND c.measure_sid = m.measure_sid AND c.measure_conversion_id = sam.measure_conversion_id
				  LEFT JOIN attr_data sa ON sa.attr_name = a.attr_name AND NVL(sa.uom, '<null>') = u.uom
			)
			UNION
			SELECT attr_name, type_name, uom, ind_sid, ind_desc, measure_sid, measure_conversion_id, measure_conv_desc, has_data, 0 is_space, label
			  FROM (
				WITH metric_data AS (
					SELECT metric_name, uom 
					  FROM est_building_metric
					 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
					   AND est_account_sid = v_est_account_sid
					 GROUP BY metric_name, uom -- Distinct
				)
				SELECT a.attr_name, a.type_name, u.uom, bmm.ind_sid, i.description ind_desc, i.measure_sid, bmm.measure_conversion_id, 
					NVL(c.description, m.description) measure_conv_desc, DECODE(md.metric_name, NULL, 0, 1) has_data, a.label
				  FROM est_attr_for_building a
				  JOIN est_attr_unit u ON u.type_name = a.type_name
				  LEFT JOIN est_building_metric_mapping bmm ON bmm.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND bmm.est_account_sid = v_est_account_sid 
				  		AND bmm.metric_name = a.attr_name AND bmm.uom = DECODE(bmm.read_only, 1, bmm.uom, u.uom)
				  LEFT JOIN v$ind i ON i.app_sid = bmm.app_sid AND i.ind_sid = bmm.ind_sid
				  LEFT JOIN measure m ON m.app_sid = i.app_sid AND m.measure_sid = i.measure_sid
				  LEFT JOIN measure_conversion c ON c.app_sid = m.app_sid AND c.measure_sid = m.measure_sid AND c.measure_conversion_id = bmm.measure_conversion_id
				  LEFT JOIN metric_data md ON md.metric_name = a.attr_name AND DECODE(NVL(bmm.read_only, 1), 1, u.uom, NVL(md.uom, '<null>')) = u.uom
			)
		) ORDER BY is_space, LOWER(attr_name), LOWER(uom);
	
	OPEN out_types FOR
		SELECT at.type_name, at.basic_type, am.measure_sid, m.description measure_desc
		  FROM est_attr_type at
		  LEFT JOIN est_attr_measure am ON am.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND am.type_name = at.type_name
		  LEFT JOIN measure m ON m.app_sid = am.app_sid AND m.measure_sid = am.measure_sid
		 	ORDER BY LOWER(type_name);

		 
	OPEN out_enums FOR
		SELECT type_name, enum, pos
		  FROM est_attr_enum
		 	ORDER BY pos, LOWER(type_name);
	
	OPEN out_units FOR
		SELECT eu.type_name, DECODE(eu.uom, '<null>', NULL, eu.uom) uom,
			am.measure_sid, amc.measure_conversion_id
		  FROM est_attr_unit eu
		  LEFT JOIN est_attr_measure am ON am.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND am.type_name = eu.type_name
		  LEFT JOIN est_attr_measure_conv amc ON amc.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND amc.type_name = eu.type_name AND amc.uom = eu.uom AND amc.measure_sid = am.measure_sid
		 	ORDER BY LOWER(type_name);
END;

PROCEDURE SetMeasure(
	in_type_name		IN	est_attr_type.type_name%TYPE,
	in_measure_sid		IN	security_pkg.T_SID_ID,
	in_uoms				IN	security_pkg.T_VARCHAR2_ARRAY,
	in_conv_ids			IN	security_pkg.T_SID_IDS
)
AS
BEGIN
	BEGIN
		INSERT INTO est_attr_measure (type_name, measure_sid)
		VALUES (in_type_name, in_measure_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE est_attr_measure
			   SET measure_sid = in_measure_sid
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND type_name = in_type_name;
	END;
	
	-- Remove existing conversions (replaced by new values)
	DELETE FROM est_attr_measure_conv
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND type_name = in_type_name;
	
	IF in_uoms.COUNT = 0 OR (in_uoms.COUNT = 1 AND in_uoms(in_uoms.FIRST) IS NULL) THEN
        -- No conversions (just add the default '<null>' conversion)
        BEGIN
			INSERT INTO est_attr_measure_conv (type_name, uom, measure_conversion_id, measure_sid)
			VALUES (in_type_name, '<null>', NULL, in_measure_sid);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE est_attr_measure_conv
				   SET uom = '<null>',
				       measure_conversion_id = NULL,
				       measure_sid = measure_sid
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND type_name = in_type_name;
		END;
		RETURN;
	END IF;
    
	-- Add conversions
	FOR i IN in_uoms.FIRST .. in_uoms.LAST
	LOOP
		IF in_uoms.EXISTS(i) AND in_conv_ids.EXISTS(i) THEN
			BEGIN
				INSERT INTO est_attr_measure_conv (type_name, uom, measure_conversion_id, measure_sid)
				VALUES (in_type_name, NVL(in_uoms(i), '<null>'), DECODE(in_conv_ids(i), -1, NULL, in_conv_ids(i)), in_measure_sid);
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					UPDATE est_attr_measure_conv
					   SET uom = in_uoms(i),
					       measure_conversion_id = DECODE(in_conv_ids(i), -1, NULL, in_conv_ids(i)),
					       measure_sid = in_measure_sid
					 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
					   AND type_name = in_type_name;
			END;
		END IF;
	END LOOP;
    
END;

PROCEDURE GetIndicators(
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT ind_sid, description, REPLACE(SUBSTR(path, 0, LENGTH(path) - 10), '~~~~~~~~~~', '/') path FROM (
			SELECT CONNECT_BY_ROOT(ind_sid) ind_sid, CONNECT_BY_ROOT(description) description, 
				CONNECT_BY_ISLEAF leaf, REVERSE(SYS_CONNECT_BY_PATH(REVERSE(description), '~~~~~~~~~~')) path
			  FROM v$ind
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND active = 1
				START WITH ind_sid IN (
					SELECT i.ind_sid
					  FROM ind i
					  JOIN est_attr_measure am ON i.app_sid = am.app_sid
					 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
					   AND i.measure_sid = am.measure_sid
				)
				CONNECT BY PRIOR parent_sid = ind_sid
			) WHERE leaf = 1;
END;

PROCEDURE CreateIndicator(
	in_attr_name		IN	est_attr_for_space.attr_name%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_root_sid			security_pkg.T_SID_ID;
	v_parent_sid		security_pkg.T_SID_ID;
	v_parent_name		ind.name%TYPE := 'createdForEnergyStar';
	v_parent_desc		v$ind.description%TYPE := 'Created for Energy Star';
	v_measure_sid		security_pkg.T_SID_ID;
	v_aggregate			ind.aggregate%TYPE;
	v_created_sid		security_pkg.T_SID_ID;
BEGIN
	SELECT ind_root_sid
	  INTO v_root_sid
	  FROM customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND ind_root_sid IS NOT NULL;
	   
	BEGIN
		SELECT ind_sid
		  INTO v_parent_sid
		  FROM ind
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND parent_sid = v_root_sid
		   AND name = v_parent_name;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			indicator_pkg.CreateIndicator(
				in_parent_sid_id	=> v_root_sid,
				in_name				=> v_parent_name,
				in_description		=> v_parent_desc,
				out_sid_id			=> v_parent_sid
			);
	END;
	
	SELECT measure_sid
	  INTO v_measure_sid
	  FROM (
		SELECT m.measure_sid
	  	  FROM est_attr_measure m
	  	  JOIN est_attr_for_space a ON a.type_name = m.type_name AND a.attr_name = in_attr_name
	  	 WHERE m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	  	UNION
	  	SELECT m.measure_sid
	  	  FROM est_attr_measure m
	  	  JOIN est_attr_for_building a ON a.type_name = m.type_name AND a.attr_name = in_attr_name
	  	 WHERE m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	  );
	   
	SELECT measure_sid
	  INTO v_measure_sid
	  FROM (
	  	SELECT m.measure_sid
	  	  FROM est_attr_measure m
		  JOIN est_attr_for_space a ON m.type_name = a.type_name
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND a.attr_name = in_attr_name
		UNION
		SELECT m.measure_sid
	  	  FROM est_attr_measure m
		  JOIN est_attr_for_building a ON m.type_name = a.type_name
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND a.attr_name = in_attr_name
	  );
	
	v_aggregate := 'NONE';
	FOR m IN (
		SELECT format_mask, custom_field
		  FROM measure
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND measure_sid = v_measure_sid
	) LOOP
		IF m.custom_field IS NULL THEN
			IF INSTR(m.format_mask, '%') > 0 THEN
				v_aggregate := 'AVERAGE';
			ELSE
				v_aggregate := 'SUM';
			END IF;
		END IF;
	END LOOP;
	
	indicator_pkg.CreateIndicator(
		in_parent_sid_id	=> v_parent_sid,
		in_name				=> in_attr_name,
		in_description		=> INITCAP(REGEXP_REPLACE(in_attr_name, '([A-Z])', ' \1')),
		in_measure_sid		=> v_measure_sid,
		in_aggregate		=> v_aggregate,
		out_sid_id			=> v_created_sid
	);
	
	MapIndicator(
		in_attr_name,
		v_created_sid,
		out_cur
	);
	
END;

PROCEDURE MapIndicator(
	in_attr_name		IN	est_attr_for_space.attr_name%TYPE,	
	in_ind_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_measure_sid		security_pkg.T_SID_ID;
	v_type_name			est_attr_type.type_name%TYPE;
	v_divisor			est_space_attr_mapping.divisor%TYPE;
	v_auto_space_type	est_options.auto_create_space_type%TYPE;
BEGIN
	
	SELECT measure_sid, type_name
	  INTO v_measure_sid, v_type_name
	  FROM (
	  	SELECT m.measure_sid, m.type_name
	  	  FROM est_attr_measure m
		  JOIN est_attr_for_space a ON m.type_name = a.type_name
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND a.attr_name = in_attr_name
		UNION
		SELECT m.measure_sid, m.type_name
	  	  FROM est_attr_measure m
		  JOIN est_attr_for_building a ON m.type_name = a.type_name
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND a.attr_name = in_attr_name
	  );
	
	v_divisor := 1;
	FOR m IN (
		SELECT format_mask, custom_field
		  FROM measure
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND measure_sid = v_measure_sid
	) LOOP
		IF m.custom_field IS NULL AND
		   INSTR(m.format_mask, '%') > 0 THEN
			v_divisor := 100;
		END IF;
	END LOOP;
	
	FOR c IN (
		SELECT mc.type_name, mc.uom, mc.measure_conversion_id, a.est_account_sid
		  FROM est_attr_measure_conv mc
		  JOIN est_account a ON a.app_sid = mc.app_sid
		 WHERE mc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND mc.type_name = v_type_name
	) LOOP
		-- Space attribute mapping
		FOR a IN (
			SELECT 1
			  FROM est_attr_for_space
			 WHERE attr_name = in_attr_name
		) LOOP
			BEGIN
				INSERT INTO est_space_attr_mapping (est_account_sid, attr_name, uom, ind_sid, measure_conversion_id, divisor)
				VALUES (c.est_account_sid, in_attr_name, c.uom, in_ind_sid, c.measure_conversion_id, v_divisor);
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					UPDATE est_space_attr_mapping
					   SET ind_sid = in_ind_sid,
					       measure_conversion_id = c.measure_conversion_id,
					       divisor = v_divisor
					 WHERE est_account_sid = c.est_account_sid
					   AND attr_name = in_attr_name
					   AND uom = c.uom;
			END;
		END LOOP;
		
		-- Building attribute mapping
		FOR a IN (
			SELECT 1
			  FROM est_attr_for_building
			 WHERE attr_name = in_attr_name
		) LOOP
			BEGIN
				INSERT INTO est_building_metric_mapping (est_account_sid, metric_name, uom, ind_sid, measure_conversion_id, simulated, read_only, divisor)
				VALUES (c.est_account_sid, in_attr_name, c.uom, in_ind_sid, c.measure_conversion_id, 1, 0, v_divisor);
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					UPDATE est_building_metric_mapping
					   SET ind_sid = in_ind_sid,
					       measure_conversion_id = c.measure_conversion_id,
					       divisor = v_divisor
					 WHERE est_account_sid = c.est_account_sid
					   AND metric_name = in_attr_name
					   AND uom = c.uom;
			END;
		END LOOP;
	END LOOP;
	
	-- Get auto mapping (auto create) option
	SELECT auto_create_space_type
	  INTO v_auto_space_type
	  FROM est_options
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	-- If we're auto mapping then ensure all space types with data 
	-- of this data type have a space type -> regon metric entry.
	IF v_auto_space_type != 0 THEN
		FOR i IN (
			SELECT DISTINCT m.space_type_id
			  FROM est_space_attr a
			  JOIN est_space s ON s.app_sid = a.app_sid AND s.est_account_sid = a.est_account_sid 
				  	AND s.pm_customer_id = a.pm_customer_id AND s.pm_building_id = a.pm_building_id AND s.pm_space_id = a.pm_space_id
			  JOIN est_space_type_map m ON m.app_sid = s.app_sid AND m.est_space_type = s.space_type
			 WHERE a.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND a.attr_name = in_attr_name
		) LOOP
			region_metric_pkg.SetMetric(in_ind_sid);
			BEGIN
				INSERT INTO region_type_metric (region_type, ind_sid)
				VALUES (csr_data_pkg.REGION_TYPE_SPACE, in_ind_sid);
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					NULL; -- Ignore dupes
			END;
			BEGIN
				INSERT INTO space_type_region_metric (space_type_id, ind_sid, region_type)
				VALUES (i.space_type_id, in_ind_sid, csr_data_pkg.REGION_TYPE_SPACE);
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					NULL; -- Ignore dupes
			END;
		END LOOP;
	END IF;
	
	
	OPEN out_cur FOR
		SELECT ind_sid, description ind_desc
		  FROM v$ind
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND ind_sid = in_ind_sid;
END;

PROCEDURE SetAttributeMappings(
	in_est_account_sid		IN	security_pkg.T_SID_ID,
	in_attr_names			IN	security_pkg.T_VARCHAR2_ARRAY,
	in_ind_sids				IN	security_pkg.T_SID_IDS,
	in_uoms					IN	security_pkg.T_VARCHAR2_ARRAY,
	in_convs				IN	security_pkg.T_SID_IDS,
	in_space_flags			IN	security_pkg.T_SID_IDS
)
AS
	v_est_account_sid		security_pkg.T_SID_ID;
	v_auto_space_type		NUMBER;
	v_tbl					T_ENERGY_STAR_ATTR_MAP_TABLE;
BEGIN
	
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can add/update mappings.');
	END IF;
	
	v_est_account_sid := in_est_account_sid;
	
	IF v_est_account_sid IS NULL THEN
		SELECT default_account_sid
		  INTO v_est_account_sid
		  FROM est_options
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	END IF;

	-- Get auto mapping (auto create) option
	SELECT auto_create_space_type
	  INTO v_auto_space_type
	  FROM est_options
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	v_tbl := AttrMapArraysToTable(in_attr_names, in_ind_sids, in_uoms, in_convs, in_space_flags);

	-- Add new mappings for properties
	FOR r IN (
		SELECT t.attr_name, t.ind_sid,
			DECODE(t.uom, NULL, '<null>', t.uom) uom, 
			DECODE(t.measure_conversion_id, -1, NULL, t.measure_conversion_id) measure_conversion_id, 
			DECODE(INSTR(m.format_mask, '%'), 0, 1, 100) divisor,
			CASE
				WHEN t.attr_name = 'bldgGrossFloorArea' THEN 1
				WHEN t.attr_name = 'occupancyPercentage' THEN 1
				WHEN t.attr_name = 'numberOfBuildings' THEN 1
				ELSE 0
			END simulated,
			CASE
				WHEN t.attr_name = 'bldgGrossFloorArea' THEN 0
				WHEN t.attr_name = 'occupancyPercentage' THEN 0
				WHEN t.attr_name = 'numberOfBuildings' THEN 0
				ELSE 1
			END read_only
		  FROM TABLE(v_tbl) t
		  JOIN ind i ON i.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND i.ind_sid = t.ind_sid
		  JOIN measure m ON m.app_sid = i.app_sid AND m.measure_sid = i.measure_sid
		  JOIN est_attr_for_building afb ON afb.attr_name = t.attr_name
		 WHERE t.is_space = 0
	) LOOP
		BEGIN
			INSERT INTO est_building_metric_mapping (est_account_sid, metric_name, uom, ind_sid, measure_conversion_id, divisor, simulated, read_only)
			VALUES (v_est_account_sid, r.attr_name, r.uom, r.ind_sid, r.measure_conversion_id, r.divisor, r.simulated, r.read_only);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE est_building_metric_mapping
				  SET ind_sid = r.ind_sid,
				      measure_conversion_id = r.measure_conversion_id,
				      divisor = r.divisor,
				      simulated = r.simulated,
				      read_only = r.read_only
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND est_account_sid = v_est_account_sid
				   AND metric_name = r.attr_name
				   AND uom = r.uom;
		END;
	END LOOP;

	-- Delete anything that has been removed (for properties)
	DELETE FROM est_building_metric_mapping m
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND est_account_sid = v_est_account_sid
	   AND NOT EXISTS (
	 	SELECT 1
	 	  FROM TABLE(v_tbl) t
	 	 WHERE t.attr_name = m.metric_name
	 	   AND t.ind_sid = m.ind_sid
	 	   AND NVL(t.uom, '<null>') = m.uom
	 	   AND NVL(t.measure_conversion_id, -1) = NVL(m.measure_conversion_id, -1)
	 	   AND t.is_space = 0
	);

	-- Add new mappings for spaces
	FOR r IN (
		SELECT t.attr_name, t.ind_sid,
			DECODE(t.uom, NULL, '<null>', t.uom) uom, 
			DECODE(t.measure_conversion_id, -1, NULL, t.measure_conversion_id) measure_conversion_id, 
			DECODE(INSTR(m.format_mask, '%'), 0, 1, 100) divisor
		  FROM TABLE(v_tbl) t
		  JOIN ind i ON i.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND i.ind_sid = t.ind_sid
		  JOIN measure m ON m.app_sid = i.app_sid AND m.measure_sid = i.measure_sid
		  JOIN est_attr_for_space afs ON afs.attr_name = t.attr_name
		 WHERE t.is_space = 1
	) LOOP
		BEGIN
			INSERT INTO est_space_attr_mapping (est_account_sid, attr_name, uom, ind_sid, measure_conversion_id, divisor)
			VALUES (v_est_account_sid, r.attr_name, r.uom, r.ind_sid, r.measure_conversion_id, r.divisor);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE est_space_attr_mapping
				  SET ind_sid = r.ind_sid,
				      measure_conversion_id = r.measure_conversion_id,
				      divisor = r.divisor
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND est_account_sid = v_est_account_sid
				   AND attr_name = r.attr_name
				   AND uom = r.uom;
		END;

		-- If we're auto mapping then ensure all space types with data 
		-- of this data type have a space type -> regon metric entry.
		IF v_auto_space_type != 0 THEN
			FOR i IN (
				SELECT DISTINCT m.space_type_id
				  FROM est_space_attr a
				  JOIN est_space s ON s.app_sid = a.app_sid AND s.est_account_sid = a.est_account_sid 
					  	AND s.pm_customer_id = a.pm_customer_id AND s.pm_building_id = a.pm_building_id AND s.pm_space_id = a.pm_space_id
				  JOIN est_space_type_map m ON m.app_sid = s.app_sid AND m.est_space_type = s.space_type
				 WHERE a.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND a.attr_name = r.attr_name
			) LOOP
				region_metric_pkg.SetMetric(r.ind_sid);
				BEGIN
					INSERT INTO region_type_metric (region_type, ind_sid)
					VALUES (csr_data_pkg.REGION_TYPE_SPACE, r.ind_sid);
				EXCEPTION
					WHEN DUP_VAL_ON_INDEX THEN
						NULL; -- Ignore dupes
				END;
				BEGIN
					INSERT INTO space_type_region_metric (space_type_id, ind_sid, region_type)
					VALUES (i.space_type_id, r.ind_sid, csr_data_pkg.REGION_TYPE_SPACE);
				EXCEPTION
					WHEN DUP_VAL_ON_INDEX THEN
						NULL; -- Ignore dupes
				END;
			END LOOP;
		END IF;
		
	END LOOP;

	-- Delete anything that has been removed (for spaces)
	DELETE FROM est_space_attr_mapping m
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND est_account_sid = v_est_account_sid
	   AND NOT EXISTS (
	 	SELECT 1
	 	  FROM TABLE(v_tbl) t
	 	 WHERE t.attr_name = m.attr_name
	 	   AND t.ind_sid = m.ind_sid
	 	   AND NVL(t.uom, '<null>') = m.uom
	 	   AND NVL(t.measure_conversion_id, -1) = NVL(m.measure_conversion_id, -1)
	 	   AND t.is_space = 1
	);
END;


PROCEDURE GetMeterTypes(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT mi.meter_type_id, mi.label, mi.consumption_ind_sid, mi.cost_ind_sid, 
			mi.days_ind_sid, mi.costdays_ind_sid, mi.group_key,
			i.measure_sid consumption_measure_sid
		  FROM v$legacy_meter_type mi
		  JOIN ind i ON i.app_sid = mi.app_sid AND i.ind_sid = mi.consumption_ind_sid
		 WHERE mi.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY LOWER(mi.label);
END;

PROCEDURE GetEnergyStarMeterTypes(
	in_est_account_sid		IN	security_pkg.T_SID_ID,
	out_types				OUT	security_pkg.T_OUTPUT_CUR,
	out_convs				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_est_account_sid		security_pkg.T_SID_ID;
BEGIN
	v_est_account_sid := in_est_account_sid;
	IF v_est_account_sid IS NULL THEN
		SELECT default_account_sid
		  INTO v_est_account_sid
		  FROM est_options
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	END IF;
	
	OPEN out_types FOR
		SELECT DISTINCT t.est_account_sid, t.meter_type, t.meter_type_id,
			DECODE(m.meter_type, NULL, 0, 1) has_meters
		  FROM v$est_meter_type_mapping t
		  LEFT JOIN est_meter m ON m.app_sid = t.app_sid AND m.est_account_sid = t.est_account_sid AND m.meter_type = t.meter_type
		 WHERE t.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND t.est_account_sid = v_est_account_sid
		 ORDER BY LOWER(t.meter_type);
		   
	OPEN out_convs FOR
		SELECT est_account_sid, meter_type, uom, measure_sid, measure_conversion_id
		  FROM v$est_conv_mapping
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND est_account_sid = v_est_account_sid
		 ORDER BY LOWER(meter_type), LOWER(uom);
END;

PROCEDURE SetMeterType(
	in_est_account_sid		IN	security_pkg.T_SID_ID,
	in_meter_type			IN	est_meter_type_mapping.meter_type%TYPE,
	in_meter_type_id		IN	meter_type.meter_type_id%TYPE,
	in_uoms					IN	security_pkg.T_VARCHAR2_ARRAY,
	in_convs				IN	security_pkg.T_SID_IDS
)
AS
	v_est_account_sid		security_pkg.T_SID_ID;
	v_measure_sid			security_pkg.T_SID_ID;
BEGIN
	
	v_est_account_sid := in_est_account_sid;
	IF v_est_account_sid IS NULL THEN
		SELECT default_account_sid
		  INTO v_est_account_sid
		  FROM est_options
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	END IF;
	
	SELECT i.measure_sid
	  INTO v_measure_sid
	  FROM v$legacy_meter_type mi
	  JOIN ind i ON i.app_sid = mi.app_sid AND i.ind_sid = mi.consumption_ind_sid
	 WHERE mi.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND mi.meter_type_id = in_meter_type_id;
	   
	BEGIN
		INSERT INTO est_meter_type_mapping
			(est_account_sid, meter_type, meter_type_id)
		VALUES (v_est_account_sid, in_meter_type, in_meter_type_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE est_meter_type_mapping
			   SET meter_type_id = in_meter_type_id
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND est_account_sid = v_est_account_sid
			   AND meter_type = in_meter_type;
	END;
	
	IF in_uoms.COUNT = 0 OR (in_uoms.COUNT = 1 AND in_uoms(in_uoms.FIRST) IS NULL) THEN
        -- hack for ODP.NET which doesn't support empty arrays
        RETURN;
    END IF;
		
	FOR i IN in_uoms.FIRST .. in_uoms.LAST
	LOOP
		BEGIN
			INSERT INTO est_conv_mapping
				(est_account_sid, meter_type, uom, measure_sid, measure_conversion_id)
			VALUES (v_est_account_sid, in_meter_type, in_uoms(i), v_measure_sid, DECODE(in_convs(i), -1, NULL, in_convs(i)));
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE est_conv_mapping
				   SET measure_sid = v_measure_sid, 
				       measure_conversion_id = DECODE(in_convs(i), -1, NULL, in_convs(i))
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND est_account_sid = v_est_account_sid
				   AND meter_type = in_meter_type
				   AND uom = in_uoms(i);
		END;
	END LOOP;
	
END;

END;
/
