CREATE OR REPLACE PACKAGE BODY CSR.model_pkg
IS

-- Securable object callbacks
PROCEDURE CreateObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name						IN security_pkg.T_SO_NAME,
	in_parent_sid_id	 IN security_pkg.T_SID_ID
)
AS
	v_model_class_id				security_pkg.T_CLASS_ID;
	v_instance_sid					security_pkg.T_SID_ID;
BEGIN
	v_model_class_id := class_pkg.GetClassID('CSRModel');

	IF in_class_id = v_model_class_id THEN
		-- create an instances container
		SecurableObject_pkg.CreateSO(
			security_pkg.GetACT,
			in_sid_id,
			security_pkg.SO_CONTAINER,
			'Instances',
			v_instance_sid
		);
		-- add suitable permissions
		acl_pkg.AddACE(security_pkg.GetACT, acl_pkg.GetDACLIDForSID(v_instance_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
			security_pkg.ACE_FLAG_INHERITABLE + security_pkg.ACE_FLAG_INHERIT_INHERITABLE,
			securableobject_pkg.GetSIDFromPath(security_pkg.GetACT, security_pkg.GetApp, 'Groups/Model Users'),
			security_pkg.PERMISSION_ADD_CONTENTS + security_pkg.PERMISSION_WRITE);
	END IF;
END;

PROCEDURE RenameObject(
	in_act_id		 IN security_pkg.T_ACT_ID,
	in_sid_id		 IN security_pkg.T_SID_ID,
	in_new_name	 IN security_pkg.T_SO_NAME
)
AS
BEGIN
	NULL;
END;

PROCEDURE DeleteObject(
	in_act_id 						IN	security_pkg.T_ACT_ID, 
	in_sid_id						IN	security_pkg.T_SID_ID
)
AS
	v_delete	NUMBER;
BEGIN
	SELECT COUNT(*) INTO v_delete
	  FROM dual
	 WHERE EXISTS (
		SELECT 1
		  FROM ind
		 WHERE ind_sid = in_sid_id);

	IF v_delete = 1 THEN	 
		-- delete the surrogate model indicator, if the model was at some point loaded into the calculation engine
		indicator_pkg.DeleteObject(in_act_id, in_sid_id);
	END IF;
	
	-- bit of a hack: enabled us to use the same package for CSRModel and CSRModelInstance

	DELETE FROM model_instance_chart
	 WHERE model_instance_sid = in_sid_id;
	 
	DELETE FROM model_instance_map
	 WHERE model_instance_sid = in_sid_id;

	DELETE FROM model_instance_region
	 WHERE model_instance_sid = in_sid_id;
	 
	DELETE FROM model_instance_sheet
	 WHERE model_instance_sid = in_sid_id;
	 
	DELETE FROM model_instance
	 WHERE model_instance_sid = in_sid_id;

	DELETE FROM model_validation
	 WHERE model_sid = in_sid_id;

	DELETE FROM model_map
	 WHERE model_sid = in_sid_id;

	DELETE FROM model_range_cell
	 WHERE model_sid = in_sid_id;

	DELETE FROM model_region_range
	 WHERE model_sid = in_sid_id;
	 
	DELETE FROM model_range
	 WHERE model_sid = in_sid_id;
	 
	DELETE FROM model_sheet
	 WHERE model_sid = in_sid_id;
	 
	DELETE FROM model
	 WHERE model_sid = in_sid_id;
END;

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

-------------

FUNCTION GetBaseModelSid(
	in_model_sid IN security_pkg.T_SID_ID
) RETURN security_pkg.T_SID_ID
AS
	CURSOR c_base_model IS
		SELECT base_model_sid
		  FROM MODEL_INSTANCE
		 WHERE model_instance_sid = in_model_sid AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	v_model_sid		 security_pkg.T_SID_ID;
BEGIN
	OPEN c_base_model;
	FETCH c_base_model INTO v_model_sid;

	IF c_base_model%NOTFOUND THEN
		v_model_sid := in_model_sid;
	END IF;

	CLOSE c_base_model;
	RETURN v_model_sid;
END;

PROCEDURE EnsureModelNotInCalcEngine(
	in_model_sid		IN	model.model_sid%TYPE
)
AS
BEGIN
	FOR r IN (SELECT null FROM model WHERE model_sid = in_model_sid AND load_state = 'L')
	LOOP
		RAISE_APPLICATION_ERROR(-20001, 'Prevented manipulation of model ' || in_model_sid || ', because it is currently loaded into the calculation engine');
	END LOOP;
END;

FUNCTION GetSidFromLookupKey(
	in_lookup_key	IN   model.lookup_key%TYPE
) RETURN security_pkg.T_SID_ID
AS
	v_sid   security_pkg.T_SID_ID;
BEGIN
	BEGIN
		SELECT model_sid
	 	  INTO v_sid
	 	  FROM model
	 	 WHERE UPPER(lookup_key) = UPPER(in_lookup_key);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'Model not found with lookup key "'||in_lookup_key||'"');
	END;
	
	RETURN v_sid;
END;

PROCEDURE GetLookupKeyFromSid(
	in_model_sid	IN   security_pkg.T_SID_ID,
	out_lookup_key	OUT  model.lookup_key%TYPE 
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(
		 SYS_CONTEXT('SECURITY', 'ACT'),
		 in_model_sid,
		 security_pkg.PERMISSION_READ
	 ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading model_sid '||in_model_sid);
	END IF;

	SELECT NVL(UPPER(lookup_key),'none') lookup_key -- ugh
 	  INTO out_lookup_key
 	  FROM model
 	 WHERE model_sid = in_model_sid;	
END;

PROCEDURE GetModelList(
	out_cur OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_models_sid		 security_pkg.T_SID_ID;
BEGIN
	v_models_sid :=
		SecurableObject_pkg.GetSIDFromPath(
			SYS_CONTEXT('SECURITY', 'ACT'),
			SYS_CONTEXT('SECURITY', 'APP'),
			'/Models'
		);

	IF NOT security_pkg.IsAccessAllowedSID(
		 SYS_CONTEXT('SECURITY', 'ACT'),
		 v_models_sid,
		 security_pkg.PERMISSION_LIST_CONTENTS
	 ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied viewing models under sid '||v_models_sid);
	END IF;

	OPEN out_cur FOR
		SELECT model_sid,
			   file_name,
			   name,
			   description,
			   CASE WHEN thumb_img IS NOT NULL THEN 1 ELSE 0 END has_thumb,
			   (
					SELECT COUNT(DISTINCT map_to_indicator_sid)
					  FROM model_map
					 WHERE model_map.app_sid = model.app_sid AND model_map.model_sid = model.model_sid AND model_map_type_id = model_pkg.FIELD_TYPE_MAP
			   ) import_count,
			   (
					SELECT COUNT(DISTINCT map_to_indicator_sid)
					  FROM model_map
					 WHERE model_map.app_sid = model.app_sid AND model_map.model_sid = model.model_sid AND model_map_type_id = model_pkg.FIELD_TYPE_EXPORTED_FORMULA
			   ) export_count,
			   load_state,
			   CASE load_state WHEN 'L' THEN (
					SELECT COUNT(DISTINCT ind_sid) FROM ind
					  JOIN model_map ON ind.app_sid = model_map.app_sid AND ind.ind_sid = model_map.map_to_indicator_sid
					 WHERE model_map.model_sid = model.model_sid
					   AND model_map_type_id = model_pkg.FIELD_TYPE_EXPORTED_FORMULA
					   AND EXTRACTVALUE(xmltype(ind.calc_xml), '//model[1]/@sid') = model.model_sid
			   ) ELSE
					0
			   END load_count
		  FROM model
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY name ASC;
END;

PROCEDURE GetModelInstanceList(
	in_model_sid		IN	model.model_sid%TYPE,
	out_instance_cur	OUT	security_pkg.T_OUTPUT_CUR,
	out_region_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_models_sid		 security_pkg.T_SID_ID;
BEGIN
	v_models_sid :=
		SecurableObject_pkg.GetSIDFromPath(
			SYS_CONTEXT('SECURITY', 'ACT'),
		in_model_sid,
			'Instances'
		);

	IF NOT security_pkg.IsAccessAllowedSID(
					 SYS_CONTEXT('SECURITY', 'ACT'),
					 v_models_sid,
					 security_pkg.PERMISSION_LIST_CONTENTS
				 ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied viewing models under sid '||v_models_sid);
	END IF;

	OPEN out_instance_cur FOR
		SELECT model_instance_sid,
					 base_model_sid,
					 description,
					 start_dtm,
					 end_dtm,
					 owner_sid,
					 created_dtm
		  FROM csr.model_instance
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND base_model_sid = in_model_sid
		 ORDER BY model_instance_sid;
		   
	OPEN out_region_cur FOR
		SELECT model_instance_sid, region_sid
		  FROM csr.model_instance_region
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND model_instance_sid IN (SELECT model_instance_sid FROM csr.model_instance WHERE base_model_sid = in_model_sid)
		 ORDER BY model_instance_sid, pos;
END;

FUNCTION CreateModel(
	in_model_name IN MODEL.NAME%TYPE
) RETURN NUMBER
AS
	v_model_sid			 security_pkg.T_SID_ID;
	out_model_sid		 security_pkg.T_SID_ID;
BEGIN
	v_model_sid :=
		SecurableObject_pkg.GetSIDFromPath(
			SYS_CONTEXT('SECURITY', 'ACT'),
			SYS_CONTEXT('SECURITY', 'APP'),
			'/Models'
		);
	SecurableObject_pkg.CreateSO(
		SYS_CONTEXT('SECURITY', 'ACT'),
		v_model_sid,
		class_pkg.GetClassID('CSRModel'),
		NULL,
		out_model_sid
	);

	INSERT INTO csr.model(
		model_sid, name, app_sid
	) VALUES (
		out_model_sid, in_model_name, SYS_CONTEXT('SECURITY', 'APP')
	 );

	RETURN out_model_sid;
END;

PROCEDURE SaveModelThumbnail(
	in_model_sid			IN	security_pkg.T_SID_ID, 
	out_data				OUT	MODEL.thumb_img%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(
		 SYS_CONTEXT('SECURITY', 'ACT'),
		 in_model_sid,
		 security_pkg.PERMISSION_WRITE
	 ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied changing model_sid '||in_model_sid);
	END IF;

	UPDATE csr.MODEL
	   SET thumb_img = EMPTY_BLOB()
	 WHERE model_sid = in_model_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
 RETURNING thumb_img INTO out_data;
END;

PROCEDURE SaveModelExcel(
    in_model_sid            IN security_pkg.T_SID_ID,
    in_file_name			IN model.file_name%TYPE,
    in_data                 IN model.excel_doc%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(
		 SYS_CONTEXT('SECURITY', 'ACT'),
		 in_model_sid,
		 security_pkg.PERMISSION_WRITE
	 ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied changing model_sid '||in_model_sid);
	END IF;
	
	EnsureModelNotInCalcEngine(in_model_sid);

	UPDATE model
	   SET excel_doc = in_data, file_name = in_file_name
	 WHERE model_sid = in_model_sid 
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	   
	UPDATE model_instance
	   SET excel_doc = in_data
	 WHERE model_instance_sid = in_model_sid 
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetExcel(
	in_model_sid		IN	model.model_sid%TYPE,
	out_model_data		OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_model_sid security_pkg.T_SID_ID;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(
		 SYS_CONTEXT('SECURITY', 'ACT'),
		 in_model_sid,
		 security_pkg.PERMISSION_READ
	 ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading model_sid '||in_model_sid);
	END IF;

	v_model_sid := GetBaseModelSid(in_model_sid);

	OPEN out_model_data FOR
		SELECT NVL(model_instance.excel_doc, model.excel_doc) excel
		  FROM model
		  LEFT JOIN model_instance ON model.app_sid = model_instance.app_sid
		   AND model.model_sid = model_instance.base_model_sid 
		   AND model_instance.model_instance_sid = in_model_sid
		 WHERE model.model_sid = v_model_sid
		   AND model.app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetThumbnail(
	in_model_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(
		 SYS_CONTEXT('SECURITY', 'ACT'),
		 in_model_sid,
		 security_pkg.PERMISSION_READ
	 ) THEN
		RAISE_APPLICATION_ERROR(
			security_pkg.ERR_ACCESS_DENIED,
			'Access denied getting model thumbnail.'
		);
	END IF;

	OPEN out_cur FOR
		SELECT thumb_img
		 FROM MODEL
		WHERE model_sid = in_model_sid 
		  AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE SaveModel(
	in_model_sid					IN	security_pkg.T_SID_ID,
	in_name							IN	model.name%TYPE,
	in_description					IN	model.description%TYPE,
	in_revision						IN	model.revision%TYPE,
	in_scenario_run_sid				IN	model.scenario_run_sid%TYPE,
	out_model_sid					OUT	model.model_sid%TYPE
)
AS
	v_model_sid		 security_pkg.T_SID_ID;
BEGIN
	v_model_sid := in_model_sid;
	
	IF NVL(v_model_sid, -1) = -1 THEN
		v_model_sid := CreateModel(in_name);
	END IF;
	
	IF NOT security_pkg.IsAccessAllowedSID(
					 SYS_CONTEXT('SECURITY', 'ACT'),
					 v_model_sid,
					 security_pkg.PERMISSION_WRITE
				 ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied saving model_sid '||v_model_sid);
	END IF;

	EnsureModelNotInCalcEngine(in_model_sid);

	UPDATE model
	   SET name = in_name,
	   	   description = in_description,
	   	   revision = in_revision,
	   	   scenario_run_type = LEAST(2, in_scenario_run_sid),
	   	   scenario_run_sid = CASE WHEN in_scenario_run_sid < 2 THEN NULL ELSE in_scenario_run_sid END,
	   	   temp_only_boo = 0
	 WHERE model_sid = v_model_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	out_model_sid := v_model_sid;
END;

PROCEDURE SetFieldMapping(
	in_model_sid			IN security_pkg.T_SID_ID,
	in_sheet_id				IN model_map.sheet_id%TYPE,
	in_cell_name			IN model_map.cell_name%TYPE,
	in_map_type_id			IN model_map.model_map_type_id%TYPE,
	in_map_to_indicator_sid	IN security_pkg.T_SID_ID
)
AS
	v_base_model_sid		security_pkg.T_SID_ID;
	v_indicator_sid			security_pkg.T_SID_ID;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(
		 SYS_CONTEXT('SECURITY', 'ACT'),
		 in_model_sid,
		 security_pkg.PERMISSION_WRITE
	 ) THEN
		RAISE_APPLICATION_ERROR(
			security_pkg.ERR_ACCESS_DENIED,
			'Access denied adjusting mapped fields for model_sid '||in_model_sid
		);
	END IF;

	v_base_model_sid := GetBaseModelSid(in_model_sid);

	v_indicator_sid := NULL;

	IF NVL(in_map_to_indicator_sid, 0) <> 0 THEN
		v_indicator_sid := in_map_to_indicator_sid;
	END IF;
	
	IF in_map_type_id = 0 THEN
		DELETE FROM model_map
		 WHERE model_sid = in_model_sid
		   AND sheet_id = in_sheet_id
		   AND cell_name = in_cell_name;
	ELSE
		BEGIN
			INSERT INTO model_map (
				 model_sid,
				 sheet_id,
				 cell_name,
				 model_map_type_id,
				 map_to_indicator_sid
			) VALUES (
				in_model_sid,
				in_sheet_id,
				in_cell_name,
				in_map_type_id,
				v_indicator_sid
			 );
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE model_map 
				   SET map_to_indicator_sid = v_indicator_sid,
					   model_map_type_id = in_map_type_id
				 WHERE model_sid = in_model_sid
				   AND sheet_id = in_sheet_id
				   AND cell_name = in_cell_name;
		END;
	END IF;
END;

PROCEDURE SetEditField(
	in_model_sid			 IN	security_pkg.T_SID_ID,
	in_sheet_id				 IN	model_map.sheet_id%TYPE,
	in_cell_name			 IN	model_map.cell_name%TYPE,
	in_previous_cell_name	 IN	model_map.cell_name%TYPE,
	in_validation			 IN	T_VALIDATION
)
AS
	v_valid_seq			 integer;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(
		 SYS_CONTEXT('SECURITY', 'ACT'),
		 in_model_sid,
		 security_pkg.PERMISSION_WRITE
	 ) THEN
		RAISE_APPLICATION_ERROR(
			security_pkg.ERR_ACCESS_DENIED,
			'Access denied adjusting edit fields for model_sid '||in_model_sid
		);
	END IF;

	IF NVL(in_previous_cell_name, in_cell_name) <> in_cell_name THEN

		-- create a new temporary mapping for the cell that may be about to be replaced
		INSERT INTO model_map(
			app_sid, model_sid, sheet_id, cell_name,
			model_map_type_id, map_to_indicator_sid, cell_comment,
			is_temp)							
			SELECT	app_sid, model_sid, sheet_id, cell_name || '#OLD',
				model_map_type_id, map_to_indicator_sid, cell_comment,
				1
			  FROM MODEL_MAP
			 WHERE	model_sid = in_model_sid 
			   AND sheet_id = in_sheet_id
			   AND cell_name = in_cell_name;
		
		-- update all existing saved data to point to the new instance
--		UPDATE model_instance_field 
--		   SET cell_name = in_cell_name || '#OLD#'
--		 WHERE base_model_sid = in_model_sid
--		   AND sheet_id = in_sheet_id
--		   AND cell_name = in_cell_name;

		-- move any data validation across too
		UPDATE model_validation
		   SET cell_name = in_cell_name || '#OLD#'
		 WHERE model_sid = in_model_sid
		   AND sheet_id = in_sheet_id
		   AND cell_name = in_cell_name;

		-- remove existing entry completely(good double-check of integrity)
		DELETE FROM model_validation 
		 WHERE model_sid = in_model_sid 
		   AND sheet_id = in_sheet_id
		   AND cell_name = in_cell_name; 

		DELETE FROM model_map
		 WHERE model_sid = in_model_sid 
		   AND sheet_id = in_sheet_id
		   AND cell_name = in_cell_name; 

		INSERT INTO model_map(
			app_sid, model_sid, 
			sheet_id, cell_name,
			model_map_type_id, is_temp
		) VALUES (
			SYS_CONTEXT('SECURITY', 'APP'), in_model_sid, 
			in_sheet_id, in_cell_name,
			model_pkg.FIELD_TYPE_EDIT, 0
		); 

		-- update saved data for new cell
		-- try #OLD# first, in case we've been replaced too
--		UPDATE model_instance_field 
--		   SET cell_name = in_cell_name 
--		 WHERE base_model_sid = in_model_sid
--		   AND sheet_id = in_sheet_id
--		   AND cell_name = in_previous_cell_name || '#OLD#';

		-- if this doesn't result in any rows being moved
		-- then we know we weren't replaced and can use
		-- the existing data to move across
--		IF SQL%ROWCOUNT = 0 THEN
--			UPDATE model_instance_field 
--			   SET cell_name = in_cell_name 
--			 WHERE base_model_sid = in_model_sid
--			   AND sheet_id = in_sheet_id
--			   AND cell_name = in_previous_cell_name;
--		END IF;

	ELSE
		BEGIN
			INSERT INTO model_map(
				app_sid, model_sid, 
				sheet_id, cell_name,
				model_map_type_id, is_temp
			) VALUES(
				SYS_CONTEXT('SECURITY', 'APP'), in_model_sid, 
				in_sheet_id, in_cell_name,
				model_pkg.FIELD_TYPE_EDIT, 0
			); 
		EXCEPTION 
			WHEN dup_val_on_index THEN
				UPDATE model_map
				   SET is_temp = 0,
					  model_map_type_id = model_pkg.FIELD_TYPE_EDIT
				 WHERE model_sid = in_model_sid 
				   AND sheet_id = in_sheet_id
				   AND cell_name = in_cell_name; 
		END;
		
	END IF;

	DELETE FROM model_validation 
	 WHERE model_sid = in_model_sid 
	   AND sheet_id = in_sheet_id
	   AND cell_name = in_cell_name; 

	v_valid_seq := in_validation.FIRST;

	LOOP
		EXIT WHEN v_valid_seq IS NULL OR in_validation(v_valid_seq) IS NULL;

		INSERT INTO model_validation (
			 model_sid,
			 sheet_id,
			 cell_name,
			 display_seq,
			 validation_text
		) VALUES (
			in_model_sid,
			in_sheet_id,
			in_cell_name,
			v_valid_seq,
			in_validation(v_valid_seq)
		);
		v_valid_seq := in_validation.NEXT(v_valid_seq);
	END LOOP;
END;

PROCEDURE SaveModelInstance(
	in_model_instance_sid	IN	security_pkg.T_SID_ID,
	in_description			IN	model_instance.description%TYPE
)
AS
BEGIN
	UPDATE model_instance
	   SET description = in_description
	 WHERE model_instance_sid = in_model_instance_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetValidation(
	in_model_sid			IN	security_pkg.T_SID_ID,
	in_sheet_id				IN	model_map.sheet_id%TYPE,
	in_cell_name			IN	model_map.cell_name%TYPE,
	out_validation			OUT	security_pkg.t_output_cur
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(
		 SYS_CONTEXT('SECURITY', 'ACT'),
		 in_model_sid,
		 security_pkg.PERMISSION_READ
	 ) THEN
		RAISE_APPLICATION_ERROR(
			security_pkg.ERR_ACCESS_DENIED,
			'Access denied reading field validation for model_sid '||in_model_sid
		);
	END IF;

	OPEN out_validation FOR 
		SELECT validation_text
		  FROM model_validation
		 WHERE model_sid = in_model_sid
		   AND sheet_id = in_sheet_id
		   AND cell_name = in_cell_name
		 ORDER BY display_seq ASC;
END;

PROCEDURE ClearFields(
	in_model_sid	IN security_pkg.T_SID_ID,
	in_sheet_id		IN model_map.sheet_id%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(
		 SYS_CONTEXT('SECURITY', 'ACT'),
		 in_model_sid,
		 security_pkg.PERMISSION_WRITE
	 ) THEN
		RAISE_APPLICATION_ERROR(
			security_pkg.ERR_ACCESS_DENIED,
			'Access denied adjusting mapped fields for model_sid '||in_model_sid
		);
	END IF;
	
--	DELETE FROM model_instance_field -- EEK!
--	 WHERE base_model_sid = in_model_sid
--	   AND sheet_id = in_sheet_id
--	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	   
	DELETE FROM model_map
	 WHERE model_sid = in_model_sid
	   AND sheet_id = in_sheet_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE PrepareForBulkFieldSet(
    in_model_sid            IN	security_pkg.T_SID_ID,
    in_sheet_id				IN  model_map.sheet_id%TYPE,
    in_purge				IN	NUMBER DEFAULT(0)
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(
		 SYS_CONTEXT('SECURITY', 'ACT'),
		 in_model_sid,
		 security_pkg.PERMISSION_WRITE
	 ) THEN
		RAISE_APPLICATION_ERROR(
			security_pkg.ERR_ACCESS_DENIED,
			'Access denied adjusting mapped fields for model_sid '||in_model_sid
		);
	END IF;
	
	m_bulk_field_set_base_sid := GetBaseModelSid(in_model_sid);
	m_bulk_field_set_model_sid := in_model_sid;
	m_bulk_field_set_sheet_id := in_sheet_id;
	
	INSERT INTO model_temp_map (model_instance_sid, sheet_id, source_cell_name, cell_name, cell_value)
	SELECT model_instance_sid, sheet_id, source_cell_name, cell_name, cell_value
	  FROM model_instance_map
	 WHERE base_model_sid = m_bulk_field_set_model_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	  
	IF in_purge <> 0 THEN
		DELETE FROM model_instance_map
		 WHERE model_instance_sid = in_model_sid
		   AND sheet_id = in_sheet_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
		   
		DELETE FROM model_map
		 WHERE model_sid = in_model_sid
		   AND sheet_id = in_sheet_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	END IF;
END;

PROCEDURE CompleteBulkFieldSet(
    in_model_sid            IN	security_pkg.T_SID_ID
)
AS
BEGIN
	-- It shouldn't be possible to edit a model while it's loaded into the calculation engine, so we don't need to consider load_state = 'L' here.
	UPDATE model
	   SET load_state = CASE WHEN (SELECT COUNT(map_to_indicator_sid) FROM model_map WHERE model_sid = in_model_sid AND model_map_type_id = model_pkg.FIELD_TYPE_EXPORTED_FORMULA) = 0 THEN 'N' ELSE 'U' END
	 WHERE model_sid = in_model_sid;
END;

PROCEDURE BulkSetBasicField(
    in_cell_name			IN	model_map.cell_name%TYPE
)
AS
BEGIN
	DELETE FROM model_validation
	 WHERE model_sid = m_bulk_field_set_model_sid
	   AND sheet_id = m_bulk_field_set_sheet_id
	   AND cell_name = in_cell_name;

	DELETE FROM model_instance_map
	 WHERE base_model_sid = m_bulk_field_set_model_sid
	   AND sheet_id = m_bulk_field_set_sheet_id
	   AND source_cell_name = in_cell_name;
	   
	DELETE FROM model_map
	 WHERE model_sid = m_bulk_field_set_model_sid
	   AND sheet_id = m_bulk_field_set_sheet_id
	   AND cell_name = in_cell_name;
END;

PROCEDURE BulkSetInstanceBasicField(
    in_cell_name			IN	model_map.cell_name%TYPE
)
AS
BEGIN
	DELETE FROM model_instance_map
	 WHERE model_instance_sid = m_bulk_field_set_model_sid
	   AND base_model_sid = m_bulk_field_set_base_sid
	   AND sheet_id = m_bulk_field_set_sheet_id
	   AND cell_name = in_cell_name;
END;

PROCEDURE BulkSetMappedField(
    in_cell_name			IN	model_map.cell_name%TYPE,
    in_indicator_sid		IN	model_map.map_to_indicator_sid%TYPE,
	in_region_type_offset	IN	model_map.region_type_offset%TYPE,
	in_region_offset_tag_id	IN	model_map.region_offset_tag_id%TYPE,
	in_period_offset		IN	model_map.period_offset%TYPE,
	in_period_year_offset	IN	model_map.period_year_offset%TYPE
)
AS
	v_region_type_offset NUMBER;
	v_region_offset_tag_id NUMBER;
BEGIN
	IF in_region_offset_tag_id = -1 THEN
		v_region_offset_tag_id := NULL;
	ELSE
		v_region_offset_tag_id := in_region_offset_tag_id;
	END IF;
	
	IF in_region_type_offset = -1 THEN
		v_region_type_offset := NULL;
	ELSE
		v_region_type_offset := in_region_type_offset;
	END IF;
	
	IF m_bulk_field_set_base_sid = m_bulk_field_set_model_sid THEN
		BEGIN
			INSERT INTO model_map(
				model_sid,
				sheet_id,
				cell_name,
				model_map_type_id,
				map_to_indicator_sid,
				region_type_offset,
				region_offset_tag_id,
				period_offset,
				period_year_offset
			) VALUES (
				m_bulk_field_set_model_sid,
				m_bulk_field_set_sheet_id,
				in_cell_name,
				model_pkg.FIELD_TYPE_MAP,
				in_indicator_sid,
				v_region_type_offset,
				v_region_offset_tag_id,
				in_period_offset,
				in_period_year_offset
			);
		EXCEPTION
			WHEN dup_val_on_index THEN
				UPDATE model_map
				   SET model_map_type_id = model_pkg.FIELD_TYPE_MAP,
				       map_to_indicator_sid = in_indicator_sid,
				       region_type_offset = v_region_type_offset,
				       region_offset_tag_id = v_region_offset_tag_id,
				       period_offset = in_period_offset,
				       period_year_offset = in_period_year_offset
				 WHERE model_sid = m_bulk_field_set_model_sid
				   AND sheet_id = m_bulk_field_set_sheet_id
				   AND cell_name = in_cell_name;
			WHEN integrity_violation THEN
				INSERT INTO model_map(
					model_sid,
					sheet_id,
					cell_name,
					model_map_type_id,
					map_to_indicator_sid,
					region_type_offset,
					region_offset_tag_id
				) VALUES (
					m_bulk_field_set_model_sid,
					m_bulk_field_set_sheet_id,
					in_cell_name,
					model_pkg.FIELD_TYPE_MAP,
					NULL, -- Indicates failed indicator import.
					v_region_type_offset,
					v_region_offset_tag_id
				);
		END;
	ELSE
		BEGIN
			INSERT INTO model_instance_map( /* redundant */
				 model_instance_sid,
				 base_model_sid,
				 sheet_id,
				 source_cell_name,
				 cell_name,
				 cell_value
			) VALUES (
				m_bulk_field_set_model_sid,
				m_bulk_field_set_base_sid,
				m_bulk_field_set_sheet_id,
				in_cell_name,
				in_cell_name,
				NULL
			);
		EXCEPTION
			WHEN dup_val_on_index THEN
				NULL;
		END;
	END IF;
END;

PROCEDURE BulkSetInstanceMappedField(
    in_cell_name			IN	model_map.cell_name%TYPE,
    in_source_cell_name		IN	model_map.cell_name%TYPE,
	in_map_to_indicator_sid	IN	model_instance_map.map_to_indicator_sid%TYPE,
	in_map_to_region_sid	IN	model_instance_map.map_to_region_sid%TYPE,
	in_period_offset		IN	model_instance_map.period_offset%TYPE,
	in_period_year_offset	IN	model_instance_map.period_year_offset%TYPE,
    in_cell_value			IN	model_instance_map.cell_value%TYPE
)
AS
BEGIN
	BEGIN
		INSERT INTO model_instance_map(
			model_instance_sid,
			base_model_sid,
			sheet_id,
			cell_name,
			source_cell_name,
			map_to_indicator_sid,
			map_to_region_sid,
			period_offset,
			period_year_offset,
			cell_value
		) VALUES (
			m_bulk_field_set_model_sid,
			m_bulk_field_set_base_sid,
			m_bulk_field_set_sheet_id,
			in_cell_name,
			in_source_cell_name,
			in_map_to_indicator_sid,
			in_map_to_region_sid,
			in_period_offset,
			in_period_year_offset,
			in_cell_value
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE model_instance_map
			   SET source_cell_name = in_source_cell_name,
				   map_to_indicator_sid = in_map_to_indicator_sid,
				   map_to_region_sid = in_map_to_region_sid,
			       period_offset = in_period_offset,
			       period_year_offset = in_period_year_offset,
				   cell_value = in_cell_value
			 WHERE model_instance_sid = m_bulk_field_set_model_sid
			   AND base_model_sid = m_bulk_field_set_base_sid
			   AND sheet_id = m_bulk_field_set_sheet_id
			   AND cell_name = in_cell_name
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	END;
END;

PROCEDURE BulkSetFormulaField(
    in_cell_name			IN	model_map.cell_name%TYPE,
    in_indicator_sid		IN	model_map.map_to_indicator_sid%TYPE
)
AS
BEGIN
	BEGIN
		INSERT INTO model_map(
			 model_sid,
			 sheet_id,
			 cell_name,
			 model_map_type_id,
			 map_to_indicator_sid
		) VALUES (
			m_bulk_field_set_model_sid,
			m_bulk_field_set_sheet_id,
			in_cell_name,
			DECODE(in_indicator_sid, 0, model_pkg.FIELD_TYPE_FORMULA, model_pkg.FIELD_TYPE_EXPORTED_FORMULA),
			DECODE(in_indicator_sid, 0, NULL, in_indicator_sid)
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
		UPDATE model_map
		   SET model_map_type_id = model_pkg.FIELD_TYPE_FORMULA
		 WHERE model_sid = m_bulk_field_set_model_sid
		   AND sheet_id = m_bulk_field_set_sheet_id
		   AND cell_name = in_cell_name;
	END;
END;

PROCEDURE BulkSetInstanceFormulaField(
    in_cell_name			IN	model_map.cell_name%TYPE,
    in_indicator_sid		IN	model_map.map_to_indicator_sid%TYPE,
    in_source_cell_name		IN	model_map.cell_name%TYPE,
    in_cell_value			IN	model_instance_map.cell_value%TYPE
)
AS
BEGIN
	BEGIN
		INSERT INTO model_instance_map(
			 model_instance_sid,
			 base_model_sid,
			 sheet_id,
			 cell_name,
			 source_cell_name,
			 cell_value,
			 map_to_indicator_sid
		) VALUES (
			m_bulk_field_set_model_sid,
			m_bulk_field_set_base_sid,
			m_bulk_field_set_sheet_id,
			in_cell_name,
			in_source_cell_name,
			in_cell_value,
			DECODE(in_indicator_sid, 0, NULL, in_indicator_sid)
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE model_instance_map
			   SET source_cell_name = in_source_cell_name,
				   cell_value = in_cell_value
			 WHERE model_instance_sid = m_bulk_field_set_model_sid
			   AND base_model_sid = m_bulk_field_set_base_sid
			   AND sheet_id = m_bulk_field_set_sheet_id
			   AND cell_name = in_cell_name
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	END;
END;

FUNCTION ColumnDelta(
	in_cell_name			IN	model_map.cell_name%TYPE,
	in_previous_cell_name	IN	model_map.cell_name%TYPE
)
RETURN NUMBER
AS
BEGIN
	RETURN 0;
END;

FUNCTION RowDelta(
	in_cell_name			IN	model_map.cell_name%TYPE,
	in_previous_cell_name	IN	model_map.cell_name%TYPE
)
RETURN NUMBER
AS
BEGIN
	RETURN 0;
END;

FUNCTION ShiftCellName(
	in_cell_name			IN	model_map.cell_name%TYPE,
	in_column_delta			IN	NUMBER,
	in_row_delta			IN	NUMBER
)
RETURN VARCHAR2
AS
BEGIN
	RETURN in_cell_name;
END;

PROCEDURE BulkSetVariableField(
    in_cell_name			IN	model_map.cell_name%TYPE,
    in_previous_sheet_id	IN	model_map.sheet_id%TYPE,
    in_previous_cell_name	IN	model_map.cell_name%TYPE
)
AS
/*	v_column_delta	NUMBER;
	v_row_delta NUMBER;*/
BEGIN
	BEGIN
		INSERT INTO model_map(
			 model_sid,
			 sheet_id,
			 cell_name,
			 model_map_type_id
		) VALUES (
			m_bulk_field_set_model_sid,
			m_bulk_field_set_sheet_id,
			in_cell_name,
			model_pkg.FIELD_TYPE_EDIT
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
		UPDATE model_map
		   SET model_map_type_id = model_pkg.FIELD_TYPE_EDIT
		 WHERE model_sid = m_bulk_field_set_model_sid
		   AND sheet_id = m_bulk_field_set_sheet_id
		   AND cell_name = in_cell_name;
	END;
	
	DELETE FROM model_validation
	 WHERE model_sid = m_bulk_field_set_model_sid
	   AND sheet_id = m_bulk_field_set_sheet_id
	   AND cell_name = in_cell_name;
/*	
	v_validation := in_validation.FIRST();
	
	LOOP
		EXIT WHEN v_validation IS NULL OR in_validation(v_validation) IS NULL;
		
		INSERT INTO model_validation(
			 model_sid,
			 sheet_id,
			 cell_name,
			 display_seq,
			 validation_text
		) VALUES (
			m_bulk_field_set_model_sid,
			m_bulk_field_set_sheet_id,
			in_cell_name,
			v_validation,
			in_validation(v_validation)
		);
		
		v_validation := in_validation.NEXT(v_validation);
	END LOOP;
*/
/*	
	v_column_delta := ColumnDelta(in_cell_name, in_previous_cell_name);
	v_row_delta := RowDelta(in_cell_name, in_previous_cell_name);
	
	INSERT INTO model_instance_map (model_instance_sid, base_model_sid, sheet_id, source_cell_name, cell_name, cell_value)
	SELECT model_instance_sid, m_bulk_field_set_model_sid, m_bulk_field_set_sheet_id, in_cell_name, model_pkg.ShiftCellName(cell_name, v_column_delta, v_row_delta), cell_value
	  FROM model_temp_map
	 WHERE sheet_id = in_previous_sheet_id
	   AND source_cell_name = in_previous_cell_name;
*/
END;

PROCEDURE BulkSetVariableFieldValidation(
    in_cell_name			IN	model_map.cell_name%TYPE,
    in_index				IN	model_validation.display_seq%TYPE,
    in_option				IN	model_validation.validation_text%TYPE
)
AS
BEGIN
	INSERT INTO model_validation(
		 model_sid,
		 sheet_id,
		 cell_name,
		 display_seq,
		 validation_text
	) VALUES (
		m_bulk_field_set_model_sid,
		m_bulk_field_set_sheet_id,
		in_cell_name,
		in_index,
		in_option
	);
END;

PROCEDURE BulkSetInstanceVariableField(
    in_cell_name			IN	model_map.cell_name%TYPE,
    in_source_cell_name		IN	model_map.cell_name%TYPE,
    in_cell_value			IN	model_instance_map.cell_value%TYPE
)
AS
	v_column_delta	NUMBER;
	v_row_delta NUMBER;
BEGIN
	BEGIN
		INSERT INTO model_instance_map(
			 model_instance_sid,
			 base_model_sid,
			 sheet_id,
			 cell_name,
			 source_cell_name,
			 cell_value
		) VALUES (
			m_bulk_field_set_model_sid,
			m_bulk_field_set_base_sid,
			m_bulk_field_set_sheet_id,
			in_cell_name,
			in_source_cell_name,
			in_cell_value
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE model_instance_map
			   SET source_cell_name = in_source_cell_name, cell_value = in_cell_value
			 WHERE model_instance_sid = m_bulk_field_set_model_sid
			   AND sheet_id = m_bulk_field_set_sheet_id
			   AND cell_name = in_cell_name;
	END;
END;

PROCEDURE BulkSetRegionField(
    in_cell_name			IN	model_map.cell_name%TYPE,
	in_region_type_offset	IN	model_map.region_type_offset%TYPE,
	in_region_offset_tag_id	IN	model_map.region_offset_tag_id%TYPE
)
AS
	v_region_type_offset NUMBER;
	v_region_offset_tag_id NUMBER;
BEGIN
	IF in_region_offset_tag_id = -1 THEN
		v_region_offset_tag_id := NULL;
	ELSE
		v_region_offset_tag_id := in_region_offset_tag_id;
	END IF;
	
	IF in_region_type_offset = -1 THEN
		v_region_type_offset := NULL;
	ELSE
		v_region_type_offset := in_region_type_offset;
	END IF;
	
	BEGIN
		INSERT INTO model_map(
			 model_sid,
			 sheet_id,
			 cell_name,
			 model_map_type_id,
			 region_type_offset,
			 region_offset_tag_id
		) VALUES (
			m_bulk_field_set_model_sid,
			m_bulk_field_set_sheet_id,
			in_cell_name,
			model_pkg.FIELD_TYPE_REGION,
			v_region_type_offset,
			v_region_offset_tag_id
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
		UPDATE model_map
		   SET model_map_type_id = model_pkg.FIELD_TYPE_REGION,
		       region_type_offset = v_region_type_offset,
		       region_offset_tag_id = v_region_offset_tag_id
		 WHERE model_sid = m_bulk_field_set_model_sid
		   AND sheet_id = m_bulk_field_set_sheet_id
		   AND cell_name = in_cell_name;
	END;
END;

PROCEDURE BulkSetInstanceRegionField(
    in_cell_name			IN	model_map.cell_name%TYPE,
    in_source_cell_name		IN	model_map.cell_name%TYPE,
	in_map_to_region_sid	IN	model_instance_map.map_to_region_sid%TYPE
)
AS
BEGIN
	BEGIN
		INSERT INTO model_instance_map(
			 model_instance_sid,
			 base_model_sid,
			 sheet_id,
			 cell_name,
			 source_cell_name,
			 map_to_region_sid
		) VALUES (
			m_bulk_field_set_model_sid,
			m_bulk_field_set_base_sid,
			m_bulk_field_set_sheet_id,
			in_cell_name,
			in_source_cell_name,
			in_map_to_region_sid
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE model_instance_map
			   SET source_cell_name = in_source_cell_name,
				   map_to_region_sid = in_map_to_region_sid
			 WHERE model_instance_sid = m_bulk_field_set_model_sid
			   AND base_model_sid = m_bulk_field_set_base_sid
			   AND sheet_id = m_bulk_field_set_sheet_id
			   AND cell_name = in_cell_name
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	END;
END;

PROCEDURE SetFieldComment(
	in_model_sid		IN security_pkg.T_SID_ID,
	in_sheet_id			IN model_map.sheet_id%TYPE,
	in_cell_name		IN model_map.cell_name%TYPE,
	in_comment			IN model_map.cell_comment%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(
		 SYS_CONTEXT('SECURITY', 'ACT'),
		 in_model_sid,
		 security_pkg.PERMISSION_WRITE
	 ) THEN
		RAISE_APPLICATION_ERROR(
			security_pkg.ERR_ACCESS_DENIED,
			'Access denied setting field comment for model_sid '||in_model_Sid
		);
	END IF;

	-- we may have a comment attached to any old field to try an insert first...
	BEGIN
		INSERT INTO model_map(
			 model_sid,
			 sheet_id,
			 cell_name,
			 model_map_type_id,
			 cell_comment
		)		
		VALUES (
			in_model_sid,
			in_sheet_id,
			in_cell_name,
			FIELD_TYPE_UNKNOWN,
			in_comment
		 );
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE model_map
			   SET cell_comment = in_comment
			 WHERE model_sid = in_model_sid
			   AND sheet_id = in_sheet_id
			   AND cell_name = in_cell_name
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	END;
END;

PROCEDURE ClearInstanceData(in_model_sid IN security_pkg.T_SID_ID)
IS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(
		 SYS_CONTEXT('SECURITY', 'ACT'),
		 in_model_sid,
		 security_pkg.PERMISSION_WRITE
	 ) THEN
		RAISE_APPLICATION_ERROR(
			security_pkg.ERR_ACCESS_DENIED,
			'Access denied writing to model_sid '||in_model_sid
		);
	END IF;

--	DELETE FROM model_instance_field
--	 WHERE model_instance_sid = in_model_sid 
--	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE UpdateInstanceFields(
	in_model_sid		IN security_pkg.T_SID_ID,
	in_sheet_id			IN model_map.sheet_id%TYPE,
	in_cell_name		IN model_map.cell_name%TYPE,
	in_cell_value		IN model_instance_map.cell_value%TYPE
)
IS
	v_base_model_sid		 security_pkg.t_sid_id;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(
		 SYS_CONTEXT('SECURITY', 'ACT'),
		 in_model_sid,
		 security_pkg.PERMISSION_WRITE
	 ) THEN
		RAISE_APPLICATION_ERROR(
			security_pkg.ERR_ACCESS_DENIED,
			'Access denied writing to model sid '||in_model_sid
		);
	END IF;

	SELECT base_model_sid
	  INTO v_base_model_sid
	  FROM model_instance
	 WHERE model_instance_sid = in_model_sid 
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	INSERT INTO model_instance_map(
		model_instance_sid,
		base_model_sid,
		sheet_id,
		source_cell_name,
		cell_name,
		cell_value
	) VALUES (
		in_model_sid,
		v_base_model_sid,
		in_sheet_id,
		in_cell_name,
		in_cell_name,
		in_cell_value
	);
END;

PROCEDURE PurgeSheets(in_model_sid IN security_pkg.T_SID_ID, in_sheets IN T_SHEETS)
AS
	v_sheet		 model_sheet.sheet_id%TYPE;
	v_del		 BOOLEAN;
BEGIN
	-- loop through all of the existing sheets and compare to list of sheets
	-- remove any in the DB that are no longer in the current list
	-- this allows us to preseve mappings across new uploads of an excel model

	IF NOT security_pkg.IsAccessAllowedSID(
		 SYS_CONTEXT('SECURITY', 'ACT'),
		 in_model_sid,
		 security_pkg.PERMISSION_WRITE
	 ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied purging sheets for model_Sid '||in_model_sid);
	END IF;

	IF in_sheets IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'No sheets passed into PurgeSheets()');
	END IF;

	FOR r_sheets IN ( 
		SELECT sheet_id, sheet_name
		  FROM model_sheet
		 WHERE model_sid = in_model_sid
	)
	LOOP
		-- TODO nasty performance bottleneck this? Any way to do it more sensibly?
		-- shouldn't be too bad as the number of mapped fields should be low
		v_del := TRUE;
		v_sheet := in_sheets.FIRST;
		
		LOOP
			EXIT WHEN v_sheet IS NULL;

			IF in_sheets(v_sheet) = r_sheets.sheet_name THEN
				v_del := FALSE;
				EXIT;
			END IF;

			v_sheet := in_sheets.NEXT(v_sheet);
		END LOOP;

		IF v_del = TRUE THEN
			DELETE FROM model_instance_map
			 WHERE base_model_sid = in_model_sid
			   AND sheet_id = r_sheets.sheet_id
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
							
			DELETE FROM model_map
			 WHERE model_sid = in_model_sid
			   AND sheet_id = r_sheets.sheet_id
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

			DELETE FROM model_sheet
			 WHERE model_sid = in_model_sid
			   AND sheet_id = r_sheets.sheet_id
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
		END IF;
	END LOOP;
END;

PROCEDURE BeginUpload(
	in_model_sid						IN	security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE UploadCompleted(
	in_model_sid						IN	security_pkg.T_SID_ID
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(
		 SYS_CONTEXT('SECURITY', 'ACT'),
		 in_model_sid,
		 security_pkg.PERMISSION_WRITE
	 ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied completing update for model_sid '||in_model_sid);
	END IF;
	DELETE FROM model_map WHERE model_sid=in_model_sid AND is_temp=1;
END;

PROCEDURE UpdateSheet(
    in_model_sid            IN  security_pkg.T_SID_ID,
    in_sheet_id             IN  model_map.sheet_id%TYPE,
    in_sheet_index          IN  model_sheet.sheet_index%TYPE,
    in_sheet_name			IN  model_sheet.sheet_name%TYPE,
    in_user_editable        IN  model_sheet.user_editable_boo%TYPE,
    in_display_charts       IN  model_sheet.display_charts_boo%TYPE,
    in_chart_count          IN  model_sheet.chart_count%TYPE,        
	in_structure			IN	CLOB,
	out_sheet_id			OUT	model_map.sheet_id%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(
		 SYS_CONTEXT('SECURITY', 'ACT'),
		 in_model_sid,
		 security_pkg.PERMISSION_WRITE
	 ) THEN
		RAISE_APPLICATION_ERROR(
			security_pkg.ERR_ACCESS_DENIED,
			'Access denied adjusting updating sheets for model_sid '||in_model_sid
		);
	END IF;

	out_sheet_id := in_sheet_id;
		
	IF out_sheet_id IS NULL THEN
		BEGIN
			SELECT sheet_id INTO out_sheet_id
			  FROM model_sheet
			 WHERE model_sid = in_model_sid
			   AND sheet_name = in_sheet_name
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
		EXCEPTION
			WHEN no_data_found THEN
				NULL;
		END;
	END IF;
	
	IF out_sheet_id IS NULL THEN
		INSERT INTO model_sheet(
			 model_sid,
			 sheet_id,
			 sheet_index,
			 sheet_name,
			 user_editable_boo,
			 display_charts_boo,
			 chart_count,
			structure
		) VALUES (
			in_model_sid,
			model_sheet_id_seq.NEXTVAL,
			in_sheet_index,
			in_sheet_name,
			in_user_editable,
			in_display_charts,
			in_chart_count,
			XMLTYPE(in_structure)
		)
		RETURNING sheet_id INTO out_sheet_id;
	ELSE		
		UPDATE model_sheet
		   SET user_editable_boo = in_user_editable,
			   display_charts_boo = in_display_charts,
			   chart_count = in_chart_count,
			   sheet_index = in_sheet_index,
			   sheet_name = in_sheet_name,
			   structure = XMLTYPE(in_structure)
		 WHERE model_sid = in_model_sid
		   AND sheet_id = out_sheet_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	END IF;
END;

PROCEDURE UpdateInstanceSheet(
    in_base_model_sid       IN  security_pkg.T_SID_ID,
    in_model_instance_sid	IN  security_pkg.T_SID_ID,
    in_sheet_id             IN  model_map.sheet_id%TYPE,
	in_structure			IN	CLOB
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(
		 SYS_CONTEXT('SECURITY', 'ACT'),
		 in_model_instance_sid,
		 security_pkg.PERMISSION_WRITE
	 ) THEN
		RAISE_APPLICATION_ERROR(
			security_pkg.ERR_ACCESS_DENIED,
			'Access denied adjusting updating sheets for model_instance_sid '||in_model_instance_sid
		);
	END IF;

	BEGIN
		INSERT INTO model_instance_sheet(
			model_instance_sid,
			base_model_sid,
			sheet_id,
			structure
		) VALUES (
			in_model_instance_sid,
			in_base_model_sid,
			in_sheet_id,
			XMLTYPE(in_structure)
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE model_instance_sheet
			   SET structure = XMLTYPE(in_structure)
			 WHERE model_instance_sid = in_model_instance_sid
			   AND base_model_sid = in_base_model_sid
			   AND sheet_id = in_sheet_id
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	END;
END;

PROCEDURE UpdateSheetDetails(
	in_model_sid				IN security_pkg.T_SID_ID,
	in_sheet_id			 IN model_map.sheet_id%TYPE,
	in_user_editable		IN model_sheet.user_editable_boo%TYPE,
	in_display_charts	 IN model_sheet.display_charts_boo%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(
		 SYS_CONTEXT('SECURITY', 'ACT'),
		 in_model_sid,
		 security_pkg.PERMISSION_WRITE
	 ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied adjusting updating sheets for model_sid '||in_model_sid);
	END IF;

	UPDATE model_sheet
	   SET user_editable_boo = in_user_editable, display_charts_boo = in_display_charts
	 WHERE model_sid = in_model_sid
	   AND sheet_id = in_sheet_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE LoadModel(
	in_model_sid			IN	security_pkg.T_SID_ID,
    in_load_definition      IN  NUMBER,
    in_instance_run			IN	NUMBER,
	out_model_info			OUT	security_pkg.T_OUTPUT_CUR,
	out_sheet_info			OUT	security_pkg.T_OUTPUT_CUR,
	out_cell_info			OUT	security_pkg.T_OUTPUT_CUR,
	out_range_info			OUT	security_pkg.T_OUTPUT_CUR,
	out_region_range_info	OUT	security_pkg.T_OUTPUT_CUR,
	out_validation_info		OUT	security_pkg.T_OUTPUT_CUR,
	out_charts				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_base_model_sid security_pkg.T_SID_ID;
BEGIN
	v_base_model_sid := GetBaseModelSid(in_model_sid);

	IF NOT security_pkg.IsAccessAllowedSID(
		 SYS_CONTEXT('SECURITY', 'ACT'),
		 v_base_model_sid,
		 security_pkg.PERMISSION_READ
	 ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading model sid '||v_base_model_sid);
	END IF;

	OPEN out_model_info FOR
		SELECT m.model_sid, m.name, m.description, m.file_name, m.revision, 
			   CASE WHEN m.scenario_run_type < 2 THEN m.scenario_run_type ELSE m.scenario_run_sid END scenario_run_sid,
			   m.load_state, bjem.batch_job_id
		  FROM model m
		  LEFT JOIN model_instance mi ON in_model_sid = mi.model_instance_sid AND m.app_sid = mi.app_sid
		  LEFT JOIN batch_job_excel_model bjem ON mi.model_instance_sid = bjem.model_instance_sid AND mi.app_sid = bjem.app_sid AND bjem.instance_run = in_instance_run
		 WHERE m.model_sid = v_base_model_sid AND m.app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_sheet_info FOR
		SELECT model_sheet.sheet_id, model_sheet.sheet_name, model_sheet.sheet_index, model_sheet.user_editable_boo, model_sheet.display_charts_boo, model_sheet.chart_count, CASE in_load_definition WHEN 0 THEN NULL ELSE NVL(model_instance_sheet.structure, model_sheet.structure) END structure
		  FROM model_sheet
		  LEFT JOIN model_instance_sheet ON model_sheet.app_sid = model_instance_sheet.app_sid AND model_instance_sheet.base_model_sid = model_sheet.model_sid AND model_instance_sheet.model_instance_sid = in_model_sid AND model_instance_sheet.sheet_id = model_sheet.sheet_id
		 WHERE model_sheet.model_sid = v_base_model_sid AND model_sheet.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY model_sheet.sheet_index ASC;

	IF in_load_definition = 1 THEN
		IF v_base_model_sid = in_model_sid THEN	
			OPEN out_cell_info FOR
				SELECT (SELECT sheet_index FROM model_sheet WHERE app_sid = mm.app_sid AND model_sid = mm.model_sid AND sheet_id = mm.sheet_id) sheet_index,
					   mm.cell_name,
					   mm.model_map_type_id,
					   mm.map_to_indicator_sid,
					   mm.region_type_offset,
					   mm.region_offset_tag_id,
					   mm.period_offset,
					   mm.period_year_offset,
					   cell_comment,
					   NULL cell_value,
					   NVL(i.description, i.NAME) AS map_to_indicator_name,
						(
							SELECT CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END
							  FROM model_validation mv
							 WHERE mv.model_sid = mm.model_sid
							   AND mv.sheet_id = mm.sheet_id
							   AND mv.cell_name = mm.cell_name
							) AS has_validation
						  FROM model_map mm, v$ind i
				 WHERE mm.model_sid = v_base_model_sid
				   AND i.ind_sid(+) = mm.map_to_indicator_sid
				   AND mm.app_sid = SYS_CONTEXT('SECURITY', 'APP');
		ELSE
			OPEN out_cell_info FOR
				SELECT (SELECT sheet_index FROM model_sheet WHERE app_sid = mim.app_sid AND model_sid = mim.base_model_sid AND sheet_id = mim.sheet_id) sheet_index,
					   mim.cell_name,
					   mm.model_map_type_id,
					   mim.source_cell_name,
					   mim.map_to_indicator_sid,
					   mim.map_to_region_sid,
					   mm.region_type_offset,
					   mm.region_offset_tag_id,
					   mm.period_offset,
					   mm.period_year_offset,
					   NVL(i.description, i.NAME) AS map_to_indicator_name,
					   NVL(r.description, r.NAME) AS map_to_region_name,
					   mim.cell_value
				  FROM model_instance_map mim
				  JOIN model_map mm ON mm.app_sid = mim.app_sid AND mm.model_sid = mim.base_model_sid AND mm.sheet_id = mim.sheet_id AND mm.cell_name = mim.source_cell_name
				  LEFT JOIN v$ind i ON i.app_sid = mim.app_sid AND i.ind_sid = mim.map_to_indicator_sid
				  LEFT JOIN v$region r ON r.app_sid = mim.app_sid AND r.region_sid = mim.map_to_region_sid
				 WHERE mim.model_instance_sid = in_model_sid
				   AND mim.app_sid = SYS_CONTEXT('SECURITY', 'APP');
		END IF;
		   
		OPEN out_range_info FOR
			SELECT model_range.range_id, model_sheet.sheet_index, model_range_cell.cell_name
			  FROM model_range
			  JOIN model_range_cell ON model_range.model_sid = model_range_cell.model_sid AND model_range.range_id = model_range_cell.range_id
			  JOIN model_sheet ON model_range.model_sid = model_sheet.model_sid AND model_range.sheet_id = model_sheet.sheet_id AND model_range.app_sid = model_sheet.app_sid
			 WHERE model_range.model_sid = v_base_model_sid AND model_range.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	and exists (select * from model_region_range where range_id = model_range.range_id) -- TODO tmp until we fix range delete
			 ORDER BY sheet_index, cell_name;
			 
		OPEN out_region_range_info FOR
			SELECT model_sheet.sheet_index, model_region_range.range_id, model_region_range.region_repeat_id
			  FROM model_region_range
			  JOIN model_range ON model_range.model_sid = model_region_range.model_sid AND model_range.range_id = model_region_range.range_id
			  JOIN model_sheet ON model_range.model_sid = model_sheet.model_sid AND model_range.sheet_id = model_sheet.sheet_id AND model_range.app_sid = model_sheet.app_sid
			 WHERE model_region_range.model_sid = v_base_model_sid AND model_region_range.app_sid = SYS_CONTEXT('SECURITY', 'APP');
			 
		OPEN out_validation_info FOR
			SELECT model_sheet.sheet_index, model_validation.cell_name, model_validation.display_seq, model_validation.validation_text
			  FROM model_validation
			  JOIN model_sheet ON model_sheet.model_sid = model_validation.model_sid AND model_sheet.sheet_id = model_validation.sheet_id AND model_sheet.app_sid = model_validation.app_sid
			 WHERE model_validation.model_sid = v_base_model_sid
			   AND model_validation.app_sid = SYS_CONTEXT('SECURITY', 'APP');
	END IF;
		 
	OPEN out_charts FOR
		SELECT ms.sheet_id, ms.sheet_index, mic.chart_index, mic.top, mic.left, mic.width, mic.height, mic.source_data
		  FROM model_sheet ms
		  JOIN model_instance_chart mic ON ms.model_sid = mic.base_model_sid AND ms.sheet_id = mic.sheet_id AND ms.app_sid = mic.app_sid
		 WHERE mic.model_instance_sid = in_model_sid
		   AND ms.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY ms.sheet_index, mic.chart_index;
END;

PROCEDURE GetModelInstance(
	in_base_model_sid	IN	security_pkg.T_SID_ID,
    in_description		IN	VARCHAR2,
	in_region_sids		IN	security_pkg.T_SID_IDS,
	in_period_start		IN	DATE,
	in_period_end		IN	DATE,
	out_model_sid		OUT	security_pkg.T_SID_ID
)
AS
	v_region				security.T_ORDERED_SID_TABLE;
	v_model_instances_sid	security_pkg.T_SID_ID;
	
	CURSOR c_model IS
		SELECT mi.model_instance_sid
		  FROM model_instance_region mir
		  LEFT JOIN TABLE(v_region) t_region
                ON t_region.sid_id = mir.region_sid
		       AND mir.pos = t_region.pos
		  JOIN model_instance mi
                ON mi.model_instance_sid = mir.model_instance_sid
		 WHERE mi.base_model_sid = in_base_model_sid
		   AND mi.start_dtm = in_period_start
		   AND mi.end_dtm = in_period_end
		GROUP BY mi.model_instance_sid
		HAVING COUNT(t_region.sid_id) = (SELECT COUNT(*) FROM TABLE(v_region))
		AND COUNT(t_region.sid_id) = COUNT(mir.region_sid);		
BEGIN
	v_region := security_pkg.SidArrayToOrderedTable(in_region_sids);
	
	IF NOT security_pkg.IsAccessAllowedSID(
		 SYS_CONTEXT('SECURITY', 'ACT'),
		 in_base_model_sid,
		 security_pkg.PERMISSION_READ
	 ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading model_sid '||in_base_model_sid);
	END IF;

	OPEN c_model;
	FETCH c_model INTO out_model_sid;

	IF c_model%NOTFOUND THEN
		v_model_instances_sid :=
			SecurableObject_pkg.GetSIDFromPath(
				SYS_CONTEXT('SECURITY', 'ACT'),
				in_base_model_sid,
				'/Instances'
			);

		IF NOT security_pkg.IsAccessAllowedSID(
			 SYS_CONTEXT('SECURITY', 'ACT'),
			 v_model_instances_sid,
			 security_pkg.PERMISSION_WRITE
		 ) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write Access denied on model_instance_sid '||v_model_instances_sid);
		END IF;

		SecurableObject_pkg.CreateSO(
			SYS_CONTEXT('SECURITY', 'ACT'),
			v_model_instances_sid,
			class_pkg.GetClassID('CSRModelInstance'),
			NULL,
			out_model_sid
		);

		INSERT INTO model_instance(
			model_instance_sid,
			base_model_sid,
			owner_sid,
			start_dtm,
			end_dtm,
			created_dtm,
			description
		) VALUES (
			out_model_sid,
			in_base_model_sid,
			security_pkg.GetSid,
			in_period_start,
			in_period_end,
			SYSDATE,
			in_description
		);
		 
		INSERT INTO model_instance_region
		(
			model_instance_sid,
			base_model_sid,
			region_sid,
			pos
		)
		SELECT
			out_model_sid,
			in_base_model_sid,
			t_region.sid_id,
			rownum
		  FROM TABLE(v_region) t_region;
	ELSIF in_description IS NOT NULL THEN
		UPDATE model_instance
		   SET description = in_description
		 WHERE model_instance_sid = out_model_sid;
	END IF;
	
	CLOSE c_model;
END;

PROCEDURE UpdateRunState(
    in_model_instance_sid	IN	security_pkg.T_SID_ID,
	in_run_state			IN	VARCHAR2
)
AS
BEGIN
	UPDATE model_instance
	   SET run_state = in_run_state
	 WHERE model_instance_sid = in_model_instance_sid;
END;

PROCEDURE LoadInstance(
    in_model_instance_sid	IN	security_pkg.T_SID_ID,
	out_instance_info		OUT	security_pkg.T_OUTPUT_CUR,
	out_regions				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_base_sid		 security_pkg.T_SID_ID;
BEGIN
	v_base_sid := GetBaseModelSid(in_model_instance_sid);

	IF v_base_sid = in_model_instance_sid THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Please submit an instance sid');
	END IF;

	IF NOT security_pkg.IsAccessAllowedSID(
		 SYS_CONTEXT('SECURITY', 'ACT'),
		 in_model_instance_sid,
		 security_pkg.PERMISSION_READ
	 ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading model_instance_sid '||in_model_instance_sid);
	END IF;

	OPEN out_instance_info FOR
		SELECT base_model_sid, owner_sid, description, start_dtm, end_dtm, created_dtm, CASE WHEN excel_doc IS NULL THEN 0 ELSE 1 END has_excel, run_state
		  FROM model_instance
		 WHERE model_instance_sid = in_model_instance_sid
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
		   
	OPEN out_regions FOR
		SELECT region_sid
		  FROM model_instance_region
		 WHERE model_instance_sid = in_model_instance_sid
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY pos;
END;

PROCEDURE DeleteModel(in_model_sid IN security_pkg.T_SID_ID)
IS
BEGIN
	securableobject_pkg.DeleteSO(SYS_CONTEXT('SECURITY', 'ACT'), in_model_sid);
END;

PROCEDURE ClearRanges(
	in_model_sid			IN	security_pkg.T_SID_ID
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_model_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied changing model_sid '||in_model_sid);
	END IF;
	
	DELETE FROM model_range_cell
	 WHERE model_sid = in_model_sid;
	DELETE FROM model_region_range
	 WHERE model_sid = in_model_sid;
	DELETE FROM model_range
	 WHERE model_sid = in_model_sid;
END;

PROCEDURE CreateRangeWithSecurityCheck(
	in_model_sid			IN	security_pkg.T_SID_ID,
	in_sheet_id				IN	model_map.sheet_id%TYPE,
	in_cells				IN	T_CELLS,
	out_range_id			OUT	model_range.range_id%TYPE
)
AS
	v_cell	INTEGER;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_model_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied changing model_sid '||in_model_sid);
	END IF;
	
	INSERT INTO model_range(
		model_sid,
		range_id,
		sheet_id
	) VALUES (
		in_model_sid,
		model_range_id_seq.NEXTVAL,
		in_sheet_id
	)
	RETURNING range_id INTO out_range_id;
	
	v_cell := in_cells.FIRST;

	LOOP
		EXIT WHEN v_cell IS NULL;

		INSERT INTO model_range_cell(
			model_sid,
			range_id,
			cell_name
		) VALUES (
			in_model_sid,
			out_range_id,
			in_cells(v_cell)
		);
		
		v_cell := in_cells.NEXT(v_cell);
	END LOOP;
END;

PROCEDURE CreateRegionRange(
	in_model_sid			IN	security_pkg.T_SID_ID,
	in_sheet_id				IN	model_map.sheet_id%TYPE,
	in_cells				IN	T_CELLS,
	in_region_repeat_id		IN	model_region_range.region_repeat_id%TYPE,
	out_range_id			OUT	model_range.range_id%TYPE
)
AS
BEGIN
	CreateRangeWithSecurityCheck(in_model_sid, in_sheet_id, in_cells, out_range_id);
	
	INSERT INTO model_region_range(
		model_sid,
		range_id,
		region_repeat_id
	) VALUES (
		in_model_sid,
		out_range_id,
		in_region_repeat_id
	);
END;

PROCEDURE RemoveRegionRange(
	in_model_sid			IN	security_pkg.T_SID_ID,
	in_sheet_id				IN	model_map.sheet_id%TYPE,
	in_anchor				IN	model_map.cell_name%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(
		 SYS_CONTEXT('SECURITY', 'ACT'),
		 in_model_sid,
		 security_pkg.PERMISSION_WRITE
	 ) THEN
		RAISE_APPLICATION_ERROR(
			security_pkg.ERR_ACCESS_DENIED,
			'Access denied adjusting region range for model_sid '||in_model_sid
		);
	END IF;
	
	FOR r IN (SELECT range_id FROM model_range_cell WHERE model_sid = in_model_sid AND cell_name = in_anchor)
	LOOP
		DELETE FROM model_region_range
		 WHERE model_sid = in_model_sid
		   AND range_id = r.range_id;

		BEGIN
			DELETE FROM model_range_cell
			 WHERE model_sid = in_model_sid
			   AND range_id = r.range_id;
			   
			DELETE FROM model_range
			 WHERE model_sid = in_model_sid
			   AND range_id = r.range_id;
		EXCEPTION
			WHEN integrity_violation THEN
				NULL; -- The range is being used for something else.
		END;
	END LOOP;
END;

PROCEDURE UpdateInstanceStructure(
	in_base_model_sid		IN	security_pkg.T_SID_ID,
	in_model_instance_sid	IN	security_pkg.T_SID_ID,
	in_sheet_id				IN	model_map.sheet_id%TYPE,
	in_structure			IN	XMLTYPE
)
AS
BEGIN
	BEGIN
		INSERT INTO model_instance_sheet (model_instance_sid, base_model_sid, sheet_id, structure)
		VALUES (in_model_instance_sid, in_base_model_sid, in_sheet_id, in_structure);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE model_instance_sheet
			   SET structure = in_structure
			 WHERE model_instance_sid = in_model_instance_sid
			   AND base_model_sid = in_base_model_sid
			   AND sheet_id = in_sheet_id
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	END;
END;

PROCEDURE ResetInstance(
	in_base_model_sid		IN	security_pkg.T_SID_ID,
	in_model_instance_sid	IN	security_pkg.T_SID_ID
)
AS
BEGIN
	UPDATE model_instance
	   SET run_state = 'R'
	 WHERE model_instance_sid = in_model_instance_sid
	   AND base_model_sid = in_base_model_sid;
	   
	DELETE FROM model_instance_chart
	 WHERE model_instance_sid = in_model_instance_sid
	   AND base_model_sid = in_base_model_sid;
END;

PROCEDURE UpdateInstanceChart(
	in_base_model_sid		IN	security_pkg.T_SID_ID,
	in_model_instance_sid	IN	security_pkg.T_SID_ID,
	in_sheet_id				IN	model_map.sheet_id%TYPE,
	in_chart_index			IN	model_instance_chart.chart_index%TYPE,
	in_top					IN	model_instance_chart.top%TYPE,
	in_left					IN	model_instance_chart.left%TYPE,
	in_width				IN	model_instance_chart.width%TYPE,
	in_height				IN	model_instance_chart.height%TYPE,
	in_source_data			IN	model_instance_chart.source_data%TYPE
)
AS
BEGIN
	BEGIN
		INSERT INTO model_instance_chart (model_instance_sid, base_model_sid, sheet_id, chart_index, top, left, width, height, source_data)
		VALUES (in_model_instance_sid, in_base_model_sid, in_sheet_id, in_chart_index, in_top, in_left, in_width, in_height, in_source_data);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE model_instance_chart
			   SET top = in_top, left = in_left, width = in_width, height = in_height, source_data = in_source_data
			 WHERE model_instance_sid = in_model_instance_sid
			   AND base_model_sid = in_base_model_sid
			   AND sheet_id = in_sheet_id
			   AND chart_index = in_chart_index
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	END;
END;

PROCEDURE GetRegionTags(
	out_tag_groups	OUT	security_pkg.T_OUTPUT_CUR,
	out_tags		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_tag_groups FOR
		SELECT tag_group_id, name
		  FROM v$tag_group
		 WHERE applies_to_regions = 1
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY name;
		
	OPEN out_tags FOR
		SELECT tag_group.tag_group_id, tag.tag_id, tag.tag
		  FROM v$tag tag
		  JOIN tag_group_member ON tag_group_member.tag_id = tag.tag_id AND tag_group_member.app_sid = tag.app_sid
		  JOIN tag_group ON tag_group.tag_group_id = tag_group_member.tag_group_id AND tag_group.app_sid = tag_group_member.app_sid
		 WHERE tag_group.applies_to_regions = 1
		 ORDER BY tag.tag;
END;

PROCEDURE GetRegionTypes(
	out_region_types	OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_region_types FOR
		SELECT region_type, region_pkg.GetRegionTypeName(region_type) name
		  FROM (
					SELECT DISTINCT region_type
					  FROM region
					 WHERE app_sid = SYS_CONTEXT('security', 'app')
		       );
END;

PROCEDURE LookupRegionOffsets(
	in_region_sids		IN	security_pkg.T_SID_IDS,
	in_tag_ids			IN	security_pkg.T_SID_IDS,
	out_region_offsets	OUT security_pkg.T_OUTPUT_CUR
)
AS
	t_region_sids security.T_SID_TABLE;
	t_tag_ids security.T_SID_TABLE;
BEGIN
	t_region_sids := security_pkg.SidArrayToTable(in_region_sids);
	t_tag_ids := security_pkg.SidArrayToTable(in_tag_ids);
	
	OPEN out_region_offsets FOR
		SELECT root_region_sid, tag_id, maps_to_region_sid
		  FROM ( SELECT root_region_sid, maps_to_region_sid, tag_id, region_level, min_level
		           FROM ( SELECT root_region_sid, maps_to_region_sid, tag_id, region_level, MIN(region_level) OVER (PARTITION BY root_region_sid) min_level
		                    FROM ( SELECT connect_by_root region.region_sid root_region_sid, region_tag.region_sid maps_to_region_sid, region_tag.tag_id, LEVEL region_level
					                 FROM region
		                             LEFT JOIN region_tag ON region_tag.region_sid = region.region_sid AND region_tag.app_sid = region.app_sid
					                WHERE region_tag.tag_id IN (SELECT column_value FROM TABLE(t_tag_ids))
					                START WITH region.region_sid IN (SELECT column_value FROM TABLE(t_region_sids))
					              CONNECT BY region.region_sid = PRIOR region.parent_sid AND region.app_sid = PRIOR region.app_sid
					             )
					    )
		       )
		 WHERE min_level = region_level;
END;

PROCEDURE LookupRegionTypeOffsets(
	in_region_sids		IN	security_pkg.T_SID_IDS,
	in_region_type_ids	IN	security_pkg.T_SID_IDS,
	out_region_offsets	OUT security_pkg.T_OUTPUT_CUR
)
AS
	t_region_sids security.T_SID_TABLE;
	t_region_type_ids security.T_SID_TABLE;
BEGIN
	t_region_sids := security_pkg.SidArrayToTable(in_region_sids);
	t_region_type_ids := security_pkg.SidArrayToTable(in_region_type_ids);
	
	OPEN out_region_offsets FOR
		SELECT root_region_sid, region_type, maps_to_region_sid
		  FROM ( SELECT root_region_sid, maps_to_region_sid, region_type, region_level, min_level
		           FROM ( SELECT root_region_sid, maps_to_region_sid, region_type, region_level, MIN(region_level) OVER (PARTITION BY root_region_sid) min_level
		                    FROM ( SELECT CONNECT_BY_ROOT region_sid root_region_sid, region_sid maps_to_region_sid, region_type, LEVEL region_level
					                 FROM region
					                WHERE region_type IN (SELECT column_value FROM TABLE(t_region_type_ids))
					                START WITH region.region_sid IN (SELECT column_value FROM TABLE(t_region_sids))
					              CONNECT BY region_sid = PRIOR parent_sid AND app_sid = PRIOR app_sid
					             )
					    )
		       )
		 WHERE min_level = region_level;
END;

PROCEDURE LoadIntoCalculationEngine(
	in_model_sid					IN	security_pkg.T_SID_ID,
	in_period_set_id				IN	period_set.period_set_id%TYPE,
	in_period_interval_id			IN	period_interval.period_interval_id%TYPE
)
AS
	v_calc_xml						VARCHAR(2000);
	v_interval_months				NUMBER;
	v_start_dtm_adjustment			NUMBER;
	v_end_dtm_adjustment			NUMBER;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(
		 SYS_CONTEXT('SECURITY', 'ACT'),
		 in_model_sid,
		 security_pkg.PERMISSION_WRITE
	 ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied loading model_sid ' || in_model_sid);
	END IF;
	
	-- TODO: 13p fix needed
	SELECT DECODE(in_period_interval_id, 4, 12, 3, 6, 2, 3, 1, 1)
	  INTO v_interval_months
	  FROM DUAL;

	-- Figure out the start / end date adjustments (the amount of historic/future data referenced by the model)
	SELECT LEAST(0, NVL(MIN(period_offset) * v_interval_months, 0), NVL(MIN(period_year_offset) * 12, 0)),
		   GREATEST(0, NVL(MAX(period_offset) * v_interval_months, 0), NVL(MAX(period_year_offset) * 12, 0))
	  INTO v_start_dtm_adjustment, v_end_dtm_adjustment
	  FROM model_map
	 WHERE model_sid = in_model_sid
	   AND model_map_type_id = model_pkg.FIELD_TYPE_MAP;
	  
	-- Create a surrogate indicator for the model (if it doesn't already exist) so that we can define dependencies between input and output indicators
	-- using the standard calc_dependency table.	
	BEGIN
		INSERT INTO ind (ind_sid, parent_sid, app_sid, name, scale, format_mask, measure_sid, active, target_direction, gri, info_xml, pos, multiplier,
						 start_month, ind_type, aggregate, core, roll_forward, factor_type_id, gas_measure_sid, gas_type_id, normalize, calc_xml, calc_start_dtm_adjustment,
						 calc_end_dtm_adjustment, period_set_id, period_interval_id)
		VALUES (in_model_sid, in_model_sid, security_pkg.GetApp, 'model_surrogate', null, 1, null, 1, 0, null, null, 0, 0,
				1, csr_data_pkg.IND_TYPE_STORED_CALC, 'NONE', 1, 0, null, null, null, 0, '<modelrun/>', v_start_dtm_adjustment, v_end_dtm_adjustment,
				in_period_set_id, in_period_interval_id);
				
		INSERT INTO ind_description (ind_sid, lang, description)
			SELECT in_model_sid, lang, 'Model surrogate'
			  FROM v$customer_lang;				
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE ind
			   SET calc_start_dtm_adjustment = v_start_dtm_adjustment,
			   	   calc_end_dtm_adjustment = v_end_dtm_adjustment,
			   	   period_set_id = in_period_set_id,
			   	   period_interval_id = in_period_interval_id
			 WHERE ind_sid = in_model_sid;
	END;

	-- Make the model depend upon the indicators it pulls from as inputs.
	BEGIN
		INSERT INTO calc_dependency (calc_ind_sid, ind_sid, dep_type)
		VALUES (in_model_sid, in_model_sid, csr_data_pkg.DEP_ON_MODEL);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	-- Enumerate exported formulae (i.e. model outputs).
		
	FOR r IN (SELECT map_to_indicator_sid, sheet_id, cell_name 
				FROM model_map 
			   WHERE model_sid = in_model_sid 
			     AND model_map_type_id = model_pkg.FIELD_TYPE_EXPORTED_FORMULA 
			     AND map_to_indicator_sid IS NOT NULL)
	LOOP
		-- Make the exported indicator pull from the model.
		
		v_calc_xml := '<model sid="' || in_model_sid || '" sheet="' || r.sheet_id || '" cell="' || r.cell_name || '" description=""/>'; -- TODO description; pull formula from Excel when adding rows to model_map?
		
		-- Note that the XPath expression assumes that we'll never have more than one <model/> element per calc_xml, which is the current design. We'll hijack indicators
		-- that are not currently pulling from any model, but we'll leave indicators that are already pulling from another model alone. The idea is that if there's a conflict,
		-- you'll see after loading a model that the model exports x calculations but only y are loaded. If we hijacked indicators that are already pulling from a model, then
		-- if won't be as obvious that you've just effectively partially unloaded some other model.
		
		UPDATE ind
		   SET calc_xml =
		   		CASE
		   			WHEN calc_xml IS NULL THEN TO_CLOB(v_calc_xml)
		   			ELSE EXTRACT(UPDATEXML(XMLTYPE(calc_xml), '/*[not(//model)]|//model[1][not(@sid)]', v_calc_xml), '/').getClobVal()
		   		END,
		   	   ind_type = csr_data_pkg.IND_TYPE_STORED_CALC
		 WHERE ind_sid = r.map_to_indicator_sid
		   AND ind_type IN (csr_data_pkg.IND_TYPE_STORED_CALC, csr_data_pkg.IND_TYPE_CALC);
		 
		-- Make the exported indicator depend upon the model (if it doesn't already).

		BEGIN		 
			INSERT INTO calc_dependency (calc_ind_sid, ind_sid, dep_type)
			VALUES (r.map_to_indicator_sid, in_model_sid, csr_data_pkg.DEP_ON_INDICATOR);
		EXCEPTION
			WHEN dup_val_on_index THEN
				NULL;
		END;
	END LOOP;
	
	-- Mark the model as loaded into the calculation engine.
	
	UPDATE model
	   SET load_state = 'L'
	 WHERE model_sid = in_model_sid;
	 
	-- Rerun calcs for the model

	calc_pkg.AddJobsForInd(in_model_sid);
END;

PROCEDURE UnloadFromCalculationEngine(
	in_model_sid		IN	security_pkg.T_SID_ID
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(
		 SYS_CONTEXT('SECURITY', 'ACT'),
		 in_model_sid,
		 security_pkg.PERMISSION_WRITE
	 ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied unloading model_sid ' || in_model_sid);
	END IF;
	
	-- Break all the links between the formulae exported from the model and any calculation indicators that use the model.
	
	UPDATE ind
	   SET calc_xml = EXTRACT(UPDATEXML(XMLTYPE(calc_xml), '//model[1][@sid]', '<model/>'), '/').getClobVal()
	 WHERE calc_xml IS NOT NULL
	   AND EXISTSNODE(xmltype(calc_xml), '//model[1][@sid="' || in_model_sid || '"]') = 1;
	
	-- Remove all dependencies to do with the model.
	
	DELETE FROM calc_dependency
	 WHERE ind_sid = in_model_sid;
	 
	-- Mark the model as unloaded from the calculation engine.
	
	UPDATE model
	   SET load_state = 'U'
	 WHERE model_sid = in_model_sid;

	-- We need to clean out data generated from the model, so add recompute jobs for the output indicators

	FOR r IN (SELECT map_to_indicator_sid
				FROM model_map 
			   WHERE model_sid = in_model_sid 
			     AND model_map_type_id = model_pkg.FIELD_TYPE_EXPORTED_FORMULA 
			     AND map_to_indicator_sid IS NOT NULL) LOOP
		calc_pkg.AddJobsForInd(r.map_to_indicator_sid);
	END LOOP;
END;

PROCEDURE QueueModelRun(
    in_model_instance_sid	IN	security_pkg.T_SID_ID,
    in_instance_run			IN	NUMBER,
    out_batch_job_id		OUT	batch_job.batch_job_id%TYPE
)
AS
	v_batch_job_id			batch_job.batch_job_id%TYPE;
	v_base_model_sid		security_pkg.T_SID_ID;
	v_model_description		VARCHAR2(500);
	v_instance_description	VARCHAR2(500);
	v_description			VARCHAR2(500);
BEGIN
	SELECT SUBSTR(CASE WHEN m.description IS NULL THEN m.file_name ELSE m.description END, 1, 500), SUBSTR(mi.description, 1, 500), mi.base_model_sid
	  INTO v_model_description, v_instance_description, v_base_model_sid
	  FROM model m
	  JOIN model_instance mi ON m.model_sid = mi.base_model_sid
	 WHERE mi.model_instance_sid = in_model_instance_sid;
	 
	IF LENGTH(v_model_description) > 490 THEN
		v_description := SUBSTR(v_model_description, 1, 497) || '...';
	ELSE
		v_description := v_model_description;
		
		IF LENGTH(v_description) > 0 AND LENGTH(v_instance_description) > 0 THEN
			v_description := v_description || ' / ';
		END IF;
		
		IF LENGTH(v_description) + LENGTH(v_instance_description) > 497 THEN
			v_description := v_description || SUBSTR(v_instance_description, 1, 497 - LENGTH(v_description)) || '...';
		ELSE
			v_description := v_description || v_instance_description;
		END IF;
	END IF;
	
	batch_job_pkg.Enqueue(
		in_batch_job_type_id => batch_job_pkg.JT_EXCEL_MODEL_RUN,
		in_description => v_description,
		out_batch_job_id => v_batch_job_id);
		
	INSERT INTO batch_job_excel_model (batch_job_id, model_instance_sid, base_model_sid, instance_run)
	VALUES (v_batch_job_id, in_model_instance_sid, v_base_model_sid, in_instance_run);

	out_batch_job_id := v_batch_job_id;
END;

PROCEDURE GetBatchJobDetails(
	in_batch_job_id		IN	batch_job.batch_job_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT model_instance_sid, instance_run
		  FROM batch_job_excel_model
		 WHERE batch_job_id = in_batch_job_id;
END;

PROCEDURE GetModelForImport(
	in_model_sid 		IN   security_pkg.T_SID_ID,
	out_cur  			OUT  SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_model_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading model_sid ' || in_model_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT ms.sheet_name, ms.sheet_index, mm.cell_name, i.ind_sid
		  FROM model_map mm
		  JOIN model_sheet ms ON mm.model_sid = ms.model_sid AND mm.sheet_id = ms.sheet_id
		  JOIN model m ON ms.model_sid = m.model_sid
		  JOIN ind i ON mm.map_to_indicator_sid = i.ind_sid
		 WHERE mm.model_map_type_id = model_pkg.FIELD_TYPE_MAP
		   AND mm.model_sid = in_model_sid
		   AND mm.period_offset = 0 AND mm.period_year_offset = 0; -- just current periods... XXX: and regions?
END;

-- TODO: period?
-- TODO: how do we do security better?
PROCEDURE GetModelAndSheetsForImport(
	in_model_sid 		IN   security_pkg.T_SID_ID,
	in_region_sid  		IN   security_pkg.T_SID_ID,
	in_period_offset	IN   NUMBER, -- null means take first sheet
	out_cur  			OUT  SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_model_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading model_sid ' || in_model_sid);
	END IF;
	
	-- TODO: gets muddled if > 1 delegation in chain added to model_deleg_import
	-- alter to import to lowest level?
	-- what about the year we're importing for?
	OPEN out_cur FOR
  		SELECT ms.sheet_name, ms.sheet_index, mm.cell_name, i.ind_sid, d.delegation_sid, s.sheet_id
		  FROM model_map mm
		  JOIN model_sheet ms ON mm.model_sid = ms.model_sid AND mm.sheet_id = ms.sheet_id
		  JOIN model m ON ms.model_sid = m.model_sid
		  JOIN ind i ON mm.map_to_indicator_sid = i.ind_sid
          JOIN model_deleg_import mdi ON m.model_sid = mdi.model_sid AND m.app_sid = mdi.app_sid
          JOIN delegation d ON mdi.delegation_sid = d.delegation_sid AND mdi.app_sid = d.app_sid
          JOIN delegation_ind di ON i.ind_sid = di.ind_sid AND i.app_sid = di.app_sid 
            AND d.delegation_sid = di.delegation_sid AND d.app_sid = di.app_sid
          JOIN delegation_region dr ON d.delegation_sid = dr.delegation_sid AND d.app_sid = dr.app_sid
            AND dr.region_sid = in_region_sid
		  JOIN sheet s ON d.delegation_sid = s.delegation_sid AND d.app_sid = s.app_sid
            AND s.start_dtm = ADD_MONTHS(d.start_dtm, NVL(in_period_offset,0)) -- always pick first period in deleg if null passed
		 WHERE mm.model_map_type_id = model_pkg.FIELD_TYPE_MAP
		   AND mm.model_sid = in_model_sid
		   AND i.ind_type = csr_data_pkg.IND_TYPE_NORMAL -- exclude calcs / other guff
		   AND mm.period_offset = 0 AND mm.period_year_offset = 0; -- just current periods... XXX: and regions?
END;


-- TODO: period?
-- TODO: how do we do security better?
PROCEDURE GetModelSheetStatus(
	in_model_sid		IN 	security_pkg.T_SID_ID,
	in_region_sid		IN 	security_pkg.T_SID_ID,
	out_cur 			OUT SYS_REFCURSOR
)
AS
BEGIN
	-- check permissions
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_model_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading model_sid ' || in_model_sid);
	END IF;

	OPEN out_cur FOR
	    WITH rt AS (
            SELECT d.delegation_sid
              FROM csr.model m
              JOIN csr.model_deleg_import mdi ON m.model_sid = mdi.model_sid AND m.app_sid = mdi.app_sid
              JOIN csr.delegation d ON mdi.delegation_sid = d.delegation_sid AND mdi.app_sid = d.app_sid
              JOIN csr.delegation_region dr ON d.delegation_sid = dr.delegation_sid AND d.app_sid = dr.app_sid
               AND dr.region_sid = in_region_sid
             WHERE m.model_sid = in_model_sid
         )
         SELECT x.delegation_sid, 
				x.root_delegation_sid deleg_plan_col_id,  -- faked up deleg_plan_id as we reuse C# code
				x.root_delegation_name label,
				x.lvl, 
				x.period_set_id, x.period_interval_id,
				sla.sheet_id, sla.start_dtm, sla.end_dtm, sla.reminder_dtm, sla.submission_dtm, sla.last_action_id, 
				sla.last_action_dtm, sla.last_action_from_user_sid, sla.last_action_note, sla.status, sla.last_action_desc,
				sla.percent_complete
		  FROM (
			SELECT app_sid, delegation_sid, level lvl, rownum rn,
				   period_set_id, period_interval_id,
				   CONNECT_BY_ROOT delegation_sid root_delegation_sid,
				   CONNECT_BY_ROOT name root_delegation_name
			  FROM delegation
		      START WITH delegation_sid in (
					SELECT delegation_sid
					  FROM rt
			   )
			  CONNECT BY PRIOR delegation_sid = parent_sid
		  )x 
		  JOIN sheet_with_last_action sla ON x.delegation_sid = sla.delegation_sid AND x.app_sid = sla.app_sid
		 WHERE sla.is_visible = 1 
		 ORDER BY x.rn, sla.start_dtm;
END;

PROCEDURE GetDelegationImport(
	in_delegation_sid   IN  security_pkg.T_SID_ID,
	out_cur 			OUT SYS_REFCURSOR
)
AS
BEGIN
	-- no point securing this as it doesn't leak anything of interest
	OPEN out_cur FOR
		SELECT model_sid 
		  FROM model_deleg_import
		 WHERE delegation_sid = delegation_pkg.GetRootDelegationSid(in_delegation_sid);
END;

PROCEDURE GetDelegationModels(
	out_cur 			OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT * 
		   FROM (
			SELECT DISTINCT m.name, m.description, m.model_sid
			  FROM model_deleg_import mdi
			  JOIN model m ON mdi.model_sid = m.model_sid AND mdi.app_sid = m.app_sid
		 )
		 WHERE security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), model_sid, security_pkg.PERMISSION_READ) = 1;
END;

END model_pkg;
/
