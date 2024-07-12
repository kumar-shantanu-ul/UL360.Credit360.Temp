CREATE OR REPLACE PACKAGE BODY CHEM.SUBSTANCE_PKG AS

PROC_NOT_FOUND				EXCEPTION;
PRAGMA EXCEPTION_INIT(PROC_NOT_FOUND, -06550);
/* this is majorly lacking in security, apart from region_sid checks.
   Plan will be to use capabilities 
   
   RK: i've started with this:
   
	IF NOT csr_data_pkg.CheckCapability('Administer Chemical module') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have permissions on the "Administer Chemical module" capability');
	END IF;
	
	
   Also:
   This kind of client specific thing needs to go -- i.e. maybe pass another param to the fn, or have a function that doesn't
   return all the region_tree_root stuff:
   REPLACE(csr.region_pkg.INTERNAL_GetRegionPathString(o.region_sid),'Regions / Main / Philips / ', '') "Site",
*/

PROCEDURE INTERNAL_CallHelperPkg(
	in_procedure_name	IN	VARCHAR2,
	in_substance_id		IN	substance.substance_id%TYPE
)
AS
	v_helper_pkg		chem_options.chem_helper_pkg%TYPE;
BEGIN
	-- call helper proc if there is one, to setup custom forms
	BEGIN
		SELECT chem_helper_pkg
		  INTO v_helper_pkg
		  FROM chem_options
		 WHERE app_sid = security_pkg.GetApp;
	EXCEPTION
		WHEN no_data_found THEN
			null;
	END;
	
	IF v_helper_pkg IS NOT NULL THEN
		BEGIN
			EXECUTE IMMEDIATE 'begin '||v_helper_pkg||'.'||in_procedure_name||'(:1);end;'
				USING in_substance_id;
		EXCEPTION
			WHEN PROC_NOT_FOUND THEN
				NULL; -- it is acceptable that it is not supported
		END;
	END IF;
END;

FUNCTION INTERNAL_AttrsToTable(
	in_cas_codes				IN	security_pkg.T_VARCHAR2_ARRAY,
	in_pct_comps				IN	security_pkg.T_DECIMAL_ARRAY
) RETURN T_CAS_COMP_TABLE
AS 
	v_table 	T_CAS_COMP_TABLE := T_CAS_COMP_TABLE();
	v_pct_comp	NUMBER(5,4);
BEGIN
    IF in_cas_codes.COUNT = 0 OR (in_cas_codes.COUNT = 1 AND in_cas_codes(in_cas_codes.FIRST) IS NULL) THEN
        -- hack for ODP.NET which doesn't support empty arrays - just return nothing
		RETURN v_table;
    END IF;

	FOR i IN in_cas_codes.FIRST .. in_cas_codes.LAST
	LOOP
		IF in_cas_codes.EXISTS(i) THEN
			v_table.extend;
			IF in_pct_comps(i) = -1 THEN
				v_pct_comp := NULL;
			ELSE
				v_pct_comp := in_pct_comps(i);
			END IF;
			v_table(v_table.COUNT) := T_CAS_COMP_ROW(in_cas_codes(i), v_pct_comp);
		END IF;
	END LOOP;
	RETURN v_table;
END;

PROCEDURE INTERNAL_UpdateCasComp(
	in_substance_id			IN	substance.substance_id%TYPE,
	in_cas_codes			IN	security_pkg.T_VARCHAR2_ARRAY,
	in_pct_comps			IN	security_pkg.T_DECIMAL_ARRAY
)
AS
	cas_codes					T_CAS_COMP_TABLE; 
BEGIN
	cas_codes := INTERNAL_AttrsToTable(
		in_cas_codes,
		in_pct_comps
	);
	
	FOR s IN (SELECT cas_code 
			    FROM substance_cas 
			   WHERE substance_id = in_substance_id 
			     AND cas_code NOT IN (
				SELECT cas_code
				  FROM TABLE(cas_codes)))
	LOOP
		DeleteSubstanceCAS(in_substance_id, s.cas_code);
	END LOOP;
		  
		  
	FOR r IN (
		SELECT cas_code, pct_composition
		  FROM TABLE(cas_codes)
	) LOOP
			AddSubstanceCAS(in_substance_id, r.cas_code, r.pct_composition);
	END LOOP;
END;

PROCEDURE INTERNAL_SetSubstance(
	in_substance_id			IN	substance.substance_id%TYPE,
	in_ref					IN	substance.ref%TYPE,
	in_description			IN	substance.description%TYPE,
	in_classification_id	IN	classification.classification_id%TYPE,
	in_manufacturer_name	IN	manufacturer.name%TYPE,
	in_region_sid			IN	substance.region_sid%TYPE,
	in_is_central			IN	substance.is_central%TYPE,
	out_substance_id		OUT	security_pkg.T_SID_ID
)
AS
	v_act_id				security_pkg.T_ACT_ID;
	v_app_sid				security_pkg.T_SID_ID;
	v_manufacturer_id		manufacturer.manufacturer_id%TYPE;
BEGIN
	v_act_id := security_pkg.GetAct;
	v_app_sid := security_pkg.GetApp;

	-- We don't know the code, because the Manufacturer has been entered by the client and doesn't exist, so just make one up using the name
	v_manufacturer_id := SetManufacturer(in_manufacturer_name);

	IF in_substance_id <> -1 THEN
		UPDATE	substance
		   SET	ref = TRIM(in_ref),
				description = in_description,
				classification_id = in_classification_id,
				manufacturer_id = v_manufacturer_id,
				is_central = DECODE(in_is_central, 1, 1, is_central) -- Only update if setting to 1 (true)
		 WHERE	substance_id = in_substance_id;
		 
		 out_substance_id := in_substance_id;
	ELSE
		INSERT INTO substance (substance_id, ref, description, classification_id, manufacturer_id, region_sid, is_central) 
			 VALUES (substance_id_seq.nextval, TRIM(in_ref), in_description, in_classification_id, v_manufacturer_id, in_region_sid, in_is_central)
			 RETURNING substance_id INTO out_substance_id;
		 
		 audit_pkg.WriteSubstanceLogEntry(out_substance_id, 'Chemical {0} created', null, null);
	END IF;
END;

PROCEDURE AddCas(
	in_cas_code			IN cas.cas_code%TYPE,
	in_name				IN cas.name%TYPE,
	in_category			IN cas.category%TYPE,
	in_is_voc			IN cas.is_voc%TYPE,
	in_unconfirmed		IN cas.unconfirmed%TYPE
)AS
BEGIN
	BEGIN
		INSERT INTO cas(cas_code, name, category, is_voc, unconfirmed)
			 VALUES (in_cas_code, in_name, in_category, in_is_voc, in_unconfirmed);
	 EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE	cas
			   SET	name = in_name,
					category = in_category,
					is_voc = in_is_voc,
					unconfirmed = in_unconfirmed
			 WHERE	cas_code = in_cas_code;
	END;	 
END;

PROCEDURE AddCas(
	in_cas_code		IN cas.cas_code%TYPE,
	in_name			IN cas.name%TYPE,
	in_unconfirmed	IN cas.unconfirmed%TYPE
)
AS
BEGIN
	BEGIN
		INSERT INTO cas(cas_code, name, unconfirmed)
			 VALUES (in_cas_code, in_name, in_unconfirmed);
	 EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE	cas
			   SET	name = in_name,
					unconfirmed = in_unconfirmed
			 WHERE	cas_code = in_cas_code;
	END;	 
END;

FUNCTION SetManufacturer(
	in_manufacturer_name	IN	manufacturer.name%TYPE
) RETURN manufacturer.manufacturer_id%TYPE
AS
	v_manufacturer_id		manufacturer.manufacturer_id%TYPE;
BEGIN
	BEGIN
		INSERT INTO manufacturer(manufacturer_id, code, name)
			 VALUES (manufacturer_id_seq.nextval, substr(in_manufacturer_name, 1, 5), in_manufacturer_name)
			 RETURNING manufacturer_id INTO v_manufacturer_id;	
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			SELECT manufacturer_id INTO v_manufacturer_id
			  FROM manufacturer
			 WHERE name = in_manufacturer_name;
	END;
	RETURN v_manufacturer_id;
END;

PROCEDURE CreateOrUpdateLocalSubstance(
	in_substance_id			IN	substance.substance_id%TYPE,
	in_local_ref			IN	substance_region.local_ref%TYPE,
	in_description			IN	substance.description%TYPE,
	in_classification_id	IN	classification.classification_id%TYPE,
	in_manufacturer_name	IN	manufacturer.name%TYPE,
	in_region_sid			IN	substance.region_sid%TYPE,
	in_cas_codes			IN	security_pkg.T_VARCHAR2_ARRAY,
	in_pct_comps			IN	security_pkg.T_DECIMAL_ARRAY,
	out_substance_id		OUT	security_pkg.T_SID_ID
)
AS
	v_reference				substance.ref%TYPE;

BEGIN
	BEGIN
		v_reference := TRIM(in_local_ref);
		INTERNAL_SetSubstance(in_substance_id, v_reference, in_description, in_classification_id, in_manufacturer_name, in_region_sid, 0, out_substance_id);

		INTERNAL_UpdateCasComp(out_substance_id, in_cas_codes, in_pct_comps); 

		INTERNAL_CallHelperPkg('LocalSubstanceCreatedUpdated', out_substance_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			RAISE_APPLICATION_ERROR(csr.csr_data_pkg.ERR_OBJECT_ALREADY_EXISTS, 'Substance already exists');
	END;
END;

PROCEDURE CreateOrUpdateGlobalSubstance(
	in_substance_id			IN	substance.substance_id%TYPE,
	in_ref					IN	substance.ref%TYPE,
	in_description			IN	substance.description%TYPE,
	in_classification_id	IN	classification.classification_id%TYPE,
	in_manufacturer_name	IN	manufacturer.name%TYPE,
	in_cas_codes			IN	security_pkg.T_VARCHAR2_ARRAY,
	in_pct_comps			IN	security_pkg.T_DECIMAL_ARRAY,
	out_substance_id		OUT	security_pkg.T_SID_ID
)
AS
	v_manufacturer_id		manufacturer.manufacturer_id%TYPE;
	v_to_state_id			csr.flow_state.flow_state_id%TYPE;
	v_empty_array			security.security_pkg.T_VARCHAR2_ARRAY;
BEGIN
	BEGIN
		INTERNAL_SetSubstance(in_substance_id, in_ref, in_description, in_classification_id, in_manufacturer_name, null, 1, out_substance_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			SELECT substance_id
			  INTO out_substance_id
			  FROM substance
			 WHERE ref = TRIM(in_ref);
			   
			SELECT manufacturer_id
			  INTO v_manufacturer_id
			  FROM manufacturer
			 WHERE name = in_manufacturer_name
			   AND rownum <=1
			 ORDER BY 1 ASC;

			UPDATE substance
			   SET classification_id = in_classification_id,
			   	   description = in_description,
			       manufacturer_id = v_manufacturer_id,
				   is_central = 1,
				   region_sid = null
			 WHERE substance_id = out_substance_id;
			
			BEGIN
				SELECT flow_state_id
				  INTO v_to_state_id 
				  FROM csr.flow_state 
				 WHERE lookup_key = 'APPROVAL_NOT_REQUIRED';
					 
				FOR r IN (
					SELECT flow_item_id
					  FROM chem.v$substance_region sr
					  JOIN chem.substance s on sr.substance_id = s.substance_id
					 WHERE current_state_lookup_key NOT IN ('APPROVAL_NOT_REQUIRED','CHEM_REMOVED')
					   AND s.substance_id = out_substance_id
					   AND s.is_central = 1
				)
				LOOP
					csr.flow_pkg.SetItemState(
					  in_flow_item_id		=>	r.flow_item_id,
					  in_to_state_id		=>	v_to_state_id,
					  in_comment_text		=>	'',
					  in_cache_keys			=>	v_empty_array,
					  in_user_sid			=>	SYS_CONTEXT('SECURITY','SID'),
					  in_force				=>	1,
					  in_cancel_alerts		=>	1
					);
				END LOOP;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					NULL;
			END;
	END;
	INTERNAL_UpdateCasComp(out_substance_id, in_cas_codes, in_pct_comps); 
	
	INTERNAL_CallHelperPkg('GlobalSubstanceCreatedUpdated', out_substance_id);
END;

PROCEDURE UpdateSubLocalRef(
	in_substance_id			IN	substance.substance_id%TYPE,
	in_region_sid			IN	substance_region.region_sid%TYPE,
	in_local_ref			IN	substance_region.local_ref%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	IF NOT IsSubstanceAccessAllowed(SYS_CONTEXT('SECURITY','SID'), in_substance_id, in_region_sid, 0, 1) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Access denied to the substance with id '||in_substance_id||' in property with sid '||in_region_sid);
	END IF;

	
	UPDATE substance_region
	   SET local_ref = TRIM(in_local_ref)
	 WHERE region_sid = in_region_sid
	   AND substance_id = in_substance_id;
END;

PROCEDURE AddSubstanceCAS(
	in_substance_id		IN	security_pkg.T_SID_ID,
	in_cas_code			IN	cas.cas_code%TYPE,
	in_pct_comp			IN	substance_cas.pct_composition%TYPE
)
AS
	v_old_pct_comp		substance_cas.pct_composition%TYPE;
BEGIN
	-- TODO: Add capability for importing chemical information
	BEGIN
		INSERT INTO substance_cas(substance_id, cas_code, pct_composition)
			 VALUES (in_substance_id, in_cas_code, in_pct_comp);
			 
		 audit_pkg.WriteSubstanceLogEntry(in_substance_id, 'Added CAS code {1} with % composition of {2} for chemical {0}', in_cas_code, in_pct_comp * 100);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			SELECT pct_composition
			  INTO v_old_pct_comp
			  FROM substance_cas
			 WHERE cas_code = in_cas_code
			   AND substance_id = in_substance_id;
			   
			UPDATE substance_cas
			   SET pct_composition = in_pct_comp
			 WHERE substance_id = in_substance_id
			   AND cas_code = in_cas_code;
			   
			audit_pkg.CheckAndWriteSubLogEntry(in_substance_id, 'CAS % composition changed for chemical {0} from {1} to {2}', in_pct_comp * 100, v_old_pct_comp * 100);
	END;
END;

PROCEDURE DeleteSubstanceCAS(
	in_substance_id			IN	security_pkg.T_SID_ID,
	in_cas_code				IN	cas.cas_code%TYPE
)
AS
BEGIN
	DELETE FROM substance_cas
	 WHERE substance_id = in_substance_id
	   AND cas_code = in_cas_code;
		 
	audit_pkg.WriteSubstanceLogEntry(in_substance_id, 'Deleted CAS code {1} for chemical {0}', in_cas_code, null);
END;

PROCEDURE DeleteSubstanceCasCodes(
	in_substance_id			IN	security_pkg.T_SID_ID,
	in_cas_codes			IN	security_pkg.T_VARCHAR2_ARRAY
)
AS
	v_cas_code_table		security.T_VARCHAR2_TABLE;
BEGIN
	v_cas_code_table := security_pkg.Varchar2ArrayToTable(in_cas_codes);
			
	DELETE FROM substance_cas
	 WHERE substance_id = in_substance_id
	   AND cas_code IN (
		SELECT value
		  FROM TABLE(v_cas_code_table)
	);
	
	FOR cc IN (
		SELECT value FROM TABLE(v_cas_code_table)
	)
	LOOP
		audit_pkg.WriteSubstanceLogEntry(in_substance_id, 'Deleted CAS code {1} for chemical {0}', cc.value, null);
	END LOOP;

END;


-- e.g. 123-23-4=54,242-52-1=12
PROCEDURE SetSubstanceCAS(
	in_substance_id		IN	security_pkg.T_SID_ID,
    in_codes            IN	VARCHAR2,
	in_region_sid		IN	security_pkg.T_SID_ID DEFAULT NULL  -- if we know the region where the substance is being used
)
AS
    v_item              VARCHAR2(255);
    v_idx               BINARY_INTEGER := 1;    
    v_pos               BINARY_INTEGER;
    v_cas               VARCHAR2(255);
    v_pct               NUMBER(5,4);            
    v_range             VARCHAR2(255);
    v_cnt               NUMBER;
    v_min               NUMBER(5,4);
    v_max               NUMBER(5,4);
    v_sum				NUMBER(10,4) := 0;
BEGIN
    -- '123-23-4:54;242-52-1:>50;421-23-1:<42;421-23-1:>=50 <=60'
    -- ;421-23-3:>60 >80 will break
    DELETE FROM substance_cas 
     WHERE substance_id = in_substance_id;

	audit_pkg.WriteSubstanceLogEntry(in_substance_id, 'CAS codes for chemical {0} removed', null, null);
	
    WHILE TRUE
    LOOP
        -- bit of a hack but Philips love sending us stuff with Euro commas for 
        -- decimal separators. We're never going to get a thousand separator in a
        -- percentage concentration so this seems safe enough.
        v_item := RTRIM(REGEXP_SUBSTR(REPLACE(in_codes,',','.'), '\s*[^:;]*\s*:\s*[-<>= 0-9\.]*\s*;?',1,v_idx),';');
        EXIT WHEN v_item IS NULL;
        v_idx := v_idx + 1;
        v_pos := INSTR(v_item, ':');
        v_cas := SUBSTR(v_item, 1, v_pos-1);
        v_range := SUBSTR(v_item, v_pos+1);
        DBMS_OUTPUT.PUT_LINE(v_cas||' -> '||v_range);
        -- now process range
        
        v_min := 0;
        v_max := 1;
        v_pct := null;
        
        IF REGEXP_LIKE(v_range, '^\s*[0-9\.]*\s*-\s*[0-9\.]*s*$') THEN
            -- a-b range
            v_pos := INSTR(v_range, '-');
            v_min := TO_NUMBER(SUBSTR(v_range, 1, v_pos-1)) / 100;
            v_max := TO_NUMBER(SUBSTR(v_range, v_pos+1)) / 100;
        ELSE
            -- normal ac2m range >a <b
            v_item := TRIM(REGEXP_SUBSTR(v_range, '^\s*(>=|<=|>|<)?\s*[0-9\.]*\s*$',1,1));
            IF v_item IS NULL THEN
                RAISE_APPLICATION_ERROR(-20001, 'Unknown CAS concentration "'||v_item||'"');
            END IF;
            IF v_item LIKE '>%' THEN
                --DBMS_OUTPUT.PUT_LINE('  min = '||v_item);
                v_min := TO_NUMBER(regexp_replace(v_item,'(>=|<=|>|<)','')) / 100;
                -- check for a further part
                v_item := TRIM(REGEXP_SUBSTR(v_range, '\s*(>=|<=|>|<)?\s*[0-9\.]*',1,2));
                IF v_item  LIKE '>%' THEN        
                    -- double gt
                    RAISE_APPLICATION_ERROR(-20001, 'Unparsable CAS concentration "'||v_range||'"');                
                END IF;
            END IF;
            IF v_item LIKE '<%' THEN
                --DBMS_OUTPUT.PUT_LINE('  max = '||v_item);
                v_max := TO_NUMBER(regexp_replace(v_item,'(>=|<=|>|<)','')) / 100;
            ELSIF v_item IS NOT NULL THEN
                v_pct := TO_NUMBER(regexp_replace(v_item,'(>=|<=|>|<)','')) / 100;
            END IF;
        END IF;
        IF v_pct IS NULL THEN
            v_pct := (v_max + v_min) /2;
        END IF;
        --DBMS_OUTPUT.PUT_LINE(v_cas||' -> '||v_pct); 
        INSERT INTO substance_cas (substance_id, cas_code, pct_composition)
            VALUES (in_substance_id, v_cas, v_pct);
            
        audit_pkg.WriteSubstanceLogEntry(in_substance_id, 'Added CAS code {1} with % composition of {2} for chemical {0}', v_cas, v_pct);
        v_sum := v_sum + v_pct;
    END LOOP;
    
    IF v_sum > 2 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Total concentration is unreasonable (i.e. over 200%)');
    END IF;
    
	-- IF in_region_sid IS NOT NULL THEN
		-- --INTERNAL_CheckCasRestriction(in_substance_id, in_region_Sid);
	-- END IF;
END;

PROCEDURE AddCasRestriction(
	in_cas_code			IN	cas.cas_code%TYPE,
	in_root_region_sid	IN	security_pkg.T_SID_ID,
	in_start_dtm		IN	cas_restricted.start_dtm%TYPE,
	in_end_dtm			IN	cas_restricted.end_dtm%TYPE DEFAULT NULL,
	in_category			IN	cas.category%TYPE DEFAULT NULL,
	in_remarks			IN	cas_restricted.remarks%TYPE DEFAULT NULL,
	in_source			IN	cas_restricted.source%TYPE DEFAULT NULL,
	in_clp_table_3_1	IN	cas_restricted.clp_table_3_1%TYPE DEFAULT NULL,
	in_clp_table_3_2	IN	cas_restricted.clp_table_3_2%TYPE DEFAULT NULL
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_root_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

		
	BEGIN
		INSERT INTO cas_restricted (cas_code, root_region_sid, start_dtm, end_dtm, remarks, source, clp_table_3_1, clp_table_3_2)
			 VALUES (in_cas_code, in_root_region_sid, in_start_dtm, in_end_dtm, in_remarks, in_source, in_clp_table_3_1, in_clp_table_3_2);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE	cas_restricted
			   SET	start_dtm = in_start_dtm,
					end_dtm = in_end_dtm,
					remarks = in_remarks,
					source = in_source,
					clp_table_3_1 = in_clp_table_3_1,
					clp_table_3_2 = in_clp_table_3_2
			 WHERE	cas_code = in_cas_code;
	END;
	-- XXX: this is a really bad idea but I don't want to break the philips ImportSubstanceProcessUse
	-- This should be removed at some point (but only Philips currently use this anyway)
	UPDATE cas
	   SET category = in_category
	 WHERE cas_code = in_cas_code; 
END;

PROCEDURE AddToFlow(
	in_substance_id		IN	substance.substance_id%TYPE,
	in_region_sid		IN	security.security_pkg.T_SID_ID,
	out_flow_item_id	OUT	substance_region.flow_item_id%TYPE
)
AS
	v_flow_sid				security_pkg.T_SID_ID;
	v_state_id				csr.flow_state.flow_state_id%TYPE;
	v_flow_state_log_id		csr.flow_state_log.flow_state_log_id%TYPE;
BEGIN
	-- basic security check
	IF NOT security.security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Access denied to the property with sid '||in_region_sid);
	END IF;
	
	-- what if section has flow_item_id already?
	SELECT flow_item_id
	  INTO out_flow_item_id
	  FROM substance_region
	 WHERE substance_id = in_substance_id AND region_sid = in_region_sid;

	IF out_flow_item_id IS NOT NULL THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Can''t create flow item for substance '|| in_substance_id ||' at region sid ' || in_region_sid || ' because it has flow_item_id already: ' || out_flow_item_id);
	END IF;

	SELECT chemical_flow_sid
	  INTO v_flow_sid
	  FROM csr.customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP');

	IF v_flow_sid IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'Chemical workflow not configured for this customer');
	END IF;

	SELECT default_state_id
	  INTO v_state_id
	  FROM csr.flow
	 WHERE flow_sid = v_flow_sid;

	INSERT INTO csr.flow_item
		(flow_item_id, flow_sid, current_state_id)
	VALUES
		(csr.flow_item_id_seq.NEXTVAL, v_flow_sid, v_state_id)
	RETURNING
		flow_item_id INTO out_flow_item_id;

	v_flow_state_log_id := csr.flow_pkg.AddToLog(in_flow_item_id => out_flow_item_id);

	UPDATE substance_region
	   SET flow_item_id = out_flow_item_id
	 WHERE substance_id = in_substance_id AND region_sid = in_region_sid;
END;

PROCEDURE ExportSheet(
	in_sheet_Id				IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_root_delegation_sid  		security_pkg.T_SID_ID;
	v_start_dtm			   		DATE;
	v_end_dtm			   		DATE;
BEGIN
	csr.sheet_pkg.CheckSheetAccessAllowed(in_sheet_id);

	SELECT csr.delegation_pkg.getRootDelegationSid(delegation_sid), start_dtm, end_dtm
	  INTO v_root_delegation_sid, v_start_dtm, v_end_dtm
	  FROM csr.sheet
	 WHERE sheet_id = in_sheet_id;

	OPEN out_cur FOR 
		SELECT REPLACE(csr.region_pkg.INTERNAL_GetRegionPathString(spu.region_sid),'Regions / Main / Philips / ', '') "Site",
			   r.lookup_Key "Site ref",
			   spu.start_dtm "Start date", spu.end_dtm "End date", 
			   s.ref "Reference",
			   sr.local_ref "Local site code",
			   spu.mass_value "Consumption (kg)", 
			   s.description "Substance", 
			   CASE WHEN (SELECT count(*) FROM substance_cas csc JOIN cas_restricted cr ON csc.cas_code = cr.cas_code WHERE csc.substance_id = s.substance_id) > 0 THEN 'Yes' ELSE 'No' END AS Reportable,
			   CASE WHEN sr.first_used_dtm = spu.start_dtm THEN 'Yes' ELSE 'No' END "Newly added",
			   CASE WHEN spu.changed_since_prev_period = 1 THEN 'Yes' ELSE 'No' END "Changed",
			   m.name "Manufacturer", srp.label "Application area", u.description "Usage",
			   spu.note "Note", 
			   NVL(spcd.to_air_pct, 0) "% to air", 
			   NVL(spcd.to_product_pct, 0) "% to product", 
			   NVL(spcd.to_waste_pct, 0) "% to waste", 
			   NVL(spcd.to_water_pct, 0) "% to water", 
			   NVL(spcd.remaining_pct, 1 - NVL(spcd.to_air_pct, 0) - NVL(spcd.to_water_pct, 0) - NVL(spcd.to_waste_pct, 0) - NVL(spcd.to_product_pct, 0)) "% remaining", 
			   spcd.remaining_dest "Destination for remaining",
			   sc.cas_code "CAS Code", c.name "Chemical name", 
			   c.category "Category",
			   CASE WHEN c.is_voc = 1 THEN 'Yes' ELSE 'No' END "Is VOC?",
			   sc.pct_composition "% composition"
		  FROM substance_process_use spu 
		  LEFT JOIN substance_cas sc
		    ON spu.substance_id = sc.substance_id
		   AND spu.app_sid = sc.app_sid
		  LEFT JOIN substance_process_cas_dest spcd
		    ON spu.substance_process_use_id = spcd.substance_process_use_id
		   AND spu.substance_id = spcd.substance_id
		   AND spu.app_sid = spcd.app_sid
		   AND spcd.cas_code = sc.cas_code
		  JOIN substance_region_process srp
		    ON spu.substance_id = srp.substance_id
		   AND spu.region_sid = srp.region_sid
		   AND spu.app_sid = srp.app_sid
		   AND spu.process_id = srp.process_id
		  JOIN substance_region sr 
		    ON srp.substance_id = sr.substance_id 
		   AND srp.region_sid = sr.region_sid 
		   AND srp.app_sid = sr.app_sid
		  JOIN substance s 
		    ON sr.substance_id = s.substance_id 
		   AND sr.app_sid = s.app_sid
		  LEFT JOIN manufacturer m
		    ON s.manufacturer_id = m.manufacturer_id 
		   AND s.app_sid = m.app_sid
		  LEFT JOIN cas c
		    ON sc.cas_code = c.cas_code
		   AND sc.app_sid = c.app_sid
		  JOIN csr.region r ON spu.region_sid = r.region_sid AND spu.app_sid = r.app_sid
		  JOIN usage u ON srp.usage_Id = u.usage_Id AND srp.app_sid = u.app_sid
		 WHERE spu.start_dtm = v_start_dtm 
		   AND spu.end_dtm = v_end_dtm 
		   AND spu.root_delegation_sid = v_root_delegation_sid
		 ORDER BY s.description, spcd.cas_code;
END;

PROCEDURE GetSubstanceCasCodes(
	in_substance_id			IN	substance.substance_id%TYPE,
	out_cas_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- GKJ call to GetSubstance fails security tests
	--GetSubstance(in_substance_id, null, out_sub_cur, out_cas_cur, out_substance_file_cur, out_transition_cur);
	OPEN out_cas_cur FOR
		SELECT cas_code
		  FROM substance_cas
		 WHERE substance_id = in_substance_id;

END;

PROCEDURE GetSubstance(
	in_ref					IN	substance.ref%TYPE,
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_sub_cur				OUT	Security_Pkg.T_OUTPUT_CUR,
	out_cas_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_substance_file_cur	OUT	security_pkg.T_OUTPUT_CUR,
	out_transition_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_substance_id	substance.substance_id%TYPE;
BEGIN
	-- lookup the id from the ref	
	SELECT substance_id
	  INTO v_substance_id
	  FROM substance
	 WHERE ref = TRIM(in_ref); 
	 
	-- pass over to the full id lookup
	GetSubstance(v_substance_id, in_region_sid, out_sub_cur, out_cas_cur, out_substance_file_cur, out_transition_cur);
END;

PROCEDURE GetSubstance(
	in_substance_id			IN	substance.substance_id%TYPE,
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_sub_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_cas_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_substance_file_cur	OUT	security_pkg.T_OUTPUT_CUR,
	out_transition_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	IF NOT IsSubstanceAccessAllowed(SYS_CONTEXT('SECURITY','SID'), in_substance_id, in_region_sid) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Access denied to the substance with id '||in_substance_id||' in property with sid '||in_region_sid);
	END IF;

	--INTERNAL_CheckCasRestriction(in_substance_id, in_region_sid);
		
	-- return the general Substance details
	OPEN out_sub_cur FOR
		SELECT s.substance_id, ref, s.description, c.description classification, m.name manufacturer, in_region_sid region_sid,
				CASE
					WHEN EXISTS (
						SELECT * 
						  FROM substance_file sf
						 WHERE sf.substance_id = in_substance_id
					 ) THEN 1
					 ELSE 0
				END has_msds,
				sr.local_ref,
				s.classification_id,
				s.manufacturer_id
		  FROM substance s
		  JOIN classification c ON c.classification_id = s.classification_id
		  JOIN manufacturer m ON m.manufacturer_id = s.manufacturer_id
		  JOIN substance_region sr ON sr.substance_id = s.substance_id
		 WHERE s.substance_id = in_substance_id
		   AND sr.region_sid = in_region_sid;
	 
	 
	-- return MSDS file matadata
	OPEN out_substance_file_cur FOR
		SELECT substance_file_id, mime_type, filename
		  FROM substance_file
		 WHERE substance_id = in_substance_id;
		 
	GetTransitions(in_substance_id, in_region_sid, out_transition_cur);
		 
		 -- return the restricted CAS composition for the substance
	OPEN out_cas_cur FOR
		SELECT sc.cas_code, c.name, sc.pct_composition, c.is_voc,
			NVL2(c.category, 'Cat ' || c.category, null) category, cr.clp_table_3_1 clp_classification, cr.remarks,
			CASE
				WHEN c.category = '1a' THEN WAIVER_REQUIRED
				ELSE WAIVER_NOTREQUIRED
			end is_waiver_required
		  FROM substance_cas sc
		  JOIN cas c ON c.cas_code = sc.cas_code
		  LEFT JOIN (
		  	-- hmm - in theory this could return > 1 row, e.g. if at global + uk level?
		  	-- wouldn't really make sense to do this, but in theory this is possible.
		    SELECT cr.cas_code,cr.clp_table_3_1, cr.remarks
		      FROM substance_cas scr 
		      JOIN cas_restricted cr ON cr.cas_code = scr.cas_code AND cr.app_sid = scr.app_sid
		     WHERE cr.root_region_sid IN (
		        SELECT region_sid
		          FROM csr.region
		         START WITH region_sid = in_region_sid
		       CONNECT BY PRIOR parent_sid = region_sid
		    ) AND scr.substance_id = in_substance_id 
		      AND cr.start_dtm <= SYSDATE
		      AND (cr.end_dtm IS NULL OR SYSDATE < cr.end_dtm)
			  AND rownum = 1
		  )cr ON c.cas_code = cr.cas_code
		 WHERE sc.substance_id = in_substance_id
		 ORDER BY c.name;
END;

PROCEDURE GetRegisteredSubstanceList(
	in_region_sid	IN	security_pkg.T_SID_ID,
	in_approved		IN	NUMBER,
	in_start_dtm	IN	substance_process_use.start_dtm%TYPE DEFAULT NULL,
	in_end_dtm		IN	substance_process_use.end_dtm%TYPE DEFAULT NULL,
	out_sub_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN

	OPEN out_sub_cur FOR
	SELECT s.substance_id, ref, s.description description, sr.current_state_id, c.description classification,
		sr.current_state_label substance_status, srp.label application_area, m.name manufacturer, spu.mass_value consumption, msr.is_editable, s.is_central
	  FROM substance s
	  LEFT JOIN manufacturer m ON m.manufacturer_id = s.manufacturer_id
	  LEFT JOIN classification c ON c.classification_id = s.classification_id
	  JOIN v$substance_region sr ON s.substance_id = sr.substance_id
	  JOIN v$my_substance_region msr ON sr.substance_id = msr.substance_id AND sr.region_sid = msr.region_sid
	  LEFT JOIN substance_process_use spu ON spu.substance_id = sr.substance_id AND spu.region_sid = sr.region_sid
	   AND in_start_dtm IS NOT NULL AND in_end_dtm IS NOT NULL
	   AND spu.start_dtm = in_start_dtm AND spu.end_dtm = in_end_dtm
	  LEFT JOIN substance_region_process srp ON srp.process_id = spu.process_id
	 WHERE sr.region_sid = in_region_sid AND (in_approved = 0 OR IsApprovedState(sr.current_state_lookup_key) = 1);
END;

FUNCTION CanRegisterSubstance(
	in_region_sid	IN	security_pkg.T_SID_ID
) RETURN NUMBER
AS
	v_flow_sid			security_pkg.T_SID_ID;
	v_state_id			csr.flow_state.flow_state_id%TYPE;
BEGIN
	SELECT chemical_flow_sid
	  INTO v_flow_sid
	  FROM csr.customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP');

	RETURN csr.flow_pkg.CanAccessDefaultState(v_flow_sid, in_region_sid, 1);
END;

PROCEDURE RegisterSubstanceForRegion(
	in_substance_id		IN	substance.substance_id%TYPE,
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_require_approval	IN	NUMBER
)
AS
	v_flow_item_id		substance_region.flow_item_id%TYPE;
	v_flow_sid			security_pkg.T_SID_ID;
	v_state_id			csr.flow_state.flow_state_id%TYPE;
	v_empty_array		security.security_pkg.T_VARCHAR2_ARRAY;
BEGIN
	-- basic security check, TODO: add checking if user in Data provider role!!!
	
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	INSERT INTO SUBSTANCE_REGION (APP_SID, SUBSTANCE_ID, REGION_SID)
		VALUES (security.security_pkg.getApp, in_substance_id, in_region_sid);

	substance_pkg.AddToFlow(in_substance_id, in_region_sid, v_flow_item_id);
	
	IF in_require_approval = 0 THEN
		SELECT chemical_flow_sid
		  INTO v_flow_sid
		  FROM csr.customer
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP');
		
		v_state_id := csr.flow_pkg.GetStateId(v_flow_sid, 'APPROVAL_NOT_REQUIRED');
		IF v_state_id IS NULL THEN
			RAISE_APPLICATION_ERROR(security.security_pkg.ERR_OBJECT_NOT_FOUND, 'Cannot find the 12NC used state');
		END IF;

		SetFlowState(
			in_substance_id		=> in_substance_id,
			in_region_sid		=> in_region_sid,
			in_flow_item_id		=> v_flow_item_id,
			in_to_state_id		=> v_state_id,
			in_comment_text		=> '',
			in_cache_keys		=> v_empty_array
		);
	ELSE
		UPDATE substance_region
		   SET local_ref = (
			SELECT ref
			  FROM substance
			 WHERE substance_id = in_substance_id
			)
		 WHERE substance_id = in_substance_id
		   AND region_sid = in_region_sid;
	END IF;

END;

PROCEDURE GetTransitions(
	in_substance_id	IN	substance.substance_id%TYPE,
	in_region_sid		IN  security_pkg.T_SID_ID,
	out_cur 			OUT SYS_REFCURSOR
)
AS
	v_flow_item_id		substance_region.flow_item_id%TYPE;
	v_region_sids		security_pkg.T_SID_IDS;
BEGIN
	SELECT in_region_sid
	  BULK COLLECT INTO v_region_sids
	  FROM DUAL;

	SELECT flow_item_id
	  INTO v_flow_item_id
	  FROM substance_region
	 WHERE substance_id = in_substance_id AND region_sid = in_region_sid;

	csr.flow_pkg.GetFlowItemTransitions(
		in_flow_item_id		=> v_flow_item_id,
		in_region_sids		=> v_region_sids,
		out_cur 			=> out_cur
	);
END;

PROCEDURE GetConsumptionPeriods(
	in_region_sid		IN  security_pkg.T_SID_ID,
	out_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	-- basic security check
	IF NOT security.security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Access denied to the property with sid '||in_region_sid);
	END IF;

	OPEN out_cur FOR
	
	SELECT DISTINCT start_dtm, end_dtm 
	  FROM substance_process_use 
	 WHERE region_sid = in_region_sid AND app_sid = security.security_pkg.getApp 
	 ORDER BY start_dtm DESC;
END;

FUNCTION GetFlowRegionSids(
	in_flow_item_id		IN	csr.flow_item.flow_item_id%TYPE
)RETURN security.T_SID_TABLE
AS
	v_region_sids_t			security.T_SID_TABLE DEFAULT security.T_SID_TABLE();
BEGIN
	SELECT region_sid
	  BULK COLLECT INTO v_region_sids_t
	  FROM v$substance_region
	 WHERE app_sid = security_pkg.getApp
	   AND flow_item_id = in_flow_item_id;
	
	RETURN v_region_sids_t;
END;

FUNCTION FlowItemRecordExists(
	in_flow_item_id		IN	csr.flow_item.flow_item_id%TYPE
)RETURN NUMBER
AS
	v_count					NUMBER;
BEGIN
	
	SELECT DECODE(count(*), 0, 0, 1)
	  INTO v_count
	  FROM v$substance_region
	 WHERE app_sid = security_pkg.getApp
	   AND flow_item_id = in_flow_item_id;
	   
	RETURN v_count;
END;

PROCEDURE GetFlowAlerts(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT y.*, r.description region_name
		  FROM (
			SELECT x.app_sid, x.flow_state_transition_id, x.flow_item_generated_alert_id,
				   x.customer_alert_type_id, x.flow_state_log_id, x.from_state_label, x.to_state_label,
				   x.set_by_user_sid, x.set_by_email, x.set_by_full_name, x.set_by_user_name,
				   x.to_user_sid, x.flow_alert_helper, x.to_user_name, x.to_full_name, x.to_email, x.to_friendly_name,
				   x.to_initiator, x.flow_item_id, x.comment_text,
				   s.substance_id, s.description substance_name, sr.region_sid, sr.current_state_label
			  FROM csr.v$open_flow_item_gen_alert x
			  JOIN v$substance_region sr ON sr.flow_item_id = x.flow_item_id AND sr.app_sid = x.app_sid
			  JOIN substance s ON sr.substance_id = s.substance_id AND sr.app_sid = s.app_sid
		  ) y
		  LEFT JOIN csr.v$region r ON y.region_sid = r.region_sid AND y.app_sid = r.app_sid
		 	ORDER BY y.app_sid, y.customer_alert_type_id, y.to_user_sid, LOWER(y.substance_name) -- Order matters!
		;
END;

PROCEDURE SetFlowState(
	in_substance_id		IN	substance.substance_id%TYPE,
	in_region_sid		IN	security.security_pkg.T_SID_ID,
	in_flow_item_id		IN	csr.flow_item.flow_item_id%TYPE,
	in_to_state_Id		IN	csr.flow_state.flow_state_id%TYPE,
	in_comment_text		IN	csr.flow_state_log.comment_text%TYPE,
	in_cache_keys		IN	security.security_pkg.T_VARCHAR2_ARRAY
)
AS
	v_cnt 	NUMBER(10);
BEGIN
	IF NOT security.security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Access denied to the property with sid '||in_region_sid);
	END IF;

	-- just check flow item id and region match
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM substance_region sr
	  	JOIN csr.flow_item fi ON sr.flow_item_id = fi.flow_item_id
	 WHERE sr.flow_item_id = in_flow_item_id
	   AND sr.substance_id = in_substance_id
	   AND sr.region_sid = in_region_sid;

	IF v_cnt = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Mismatched substance_id, region_sid and flow_item_id');
	END IF;

	csr.flow_pkg.SetItemState(
		in_flow_item_id => in_flow_item_id,
		in_to_state_id => in_to_state_id,
		in_comment_text => in_comment_text,
		in_cache_keys => in_cache_keys
	);
END;

PROCEDURE SetFlowState(
	in_substance_id		IN	substance.substance_id%TYPE,
	in_region_sid		IN	security.security_pkg.T_SID_ID,
	in_flow_item_id		IN	csr.flow_item.flow_item_id%TYPE,
	in_to_state_Id		IN	csr.flow_state.flow_state_id%TYPE,
	in_comment_text		IN	csr.flow_state_log.comment_text%TYPE,
	in_cache_keys		IN	security.security_pkg.T_VARCHAR2_ARRAY,
	out_state 			OUT SYS_REFCURSOR, 
	out_transitions		OUT SYS_REFCURSOR
)
AS
BEGIN
	SetFlowState(in_substance_id, in_region_sid, in_flow_item_id, in_to_state_Id, in_comment_text, in_cache_keys);

	OPEN out_state FOR
		SELECT sr.current_state_id, sr.current_state_label, sr.current_state_colour, 
			sr.current_state_lookup_key, msr.is_editable
		  FROM v$substance_region sr
		  JOIN v$my_substance_region msr ON sr.substance_id = msr.substance_id and sr.region_sid = msr.region_sid
		WHERE sr.substance_id = in_substance_id AND sr.region_sid = in_region_sid;

	GetTransitions(in_substance_id, in_region_sid, out_transitions);
END;

PROCEDURE GetSubstanceList(
	in_search_phrase	IN	varchar2,
	in_fetch_limit		IN	number,
	in_region_sid		IN	security.security_pkg.T_SID_ID DEFAULT NULL, -- exclude substances registered for this region
	out_sub_cur			OUT Security_Pkg.T_OUTPUT_CUR
)
AS
	v_search_text	VARCHAR2(2048);
BEGIN
	v_search_text:= '%'||LOWER(in_search_phrase)||'%';
	
	OPEN out_sub_cur FOR
		SELECT s.substance_id, s.ref, s.description description, c.description classification, m.code manufacturer,
				ref||' - '||c.description||' '||s.description||' ('||m.code||')'
		  FROM substance s
		  JOIN classification c ON c.classification_id = s.classification_id
		  JOIN manufacturer m ON m.manufacturer_id = s.manufacturer_id
		 WHERE LOWER(ref||' - '||c.description||' '||s.description||' ('||m.code||')') LIKE v_search_text
		   AND s.is_central = 1
		   AND rownum <= in_fetch_limit AND (in_region_sid IS NULL OR NOT EXISTS(SELECT 1 
																				  FROM substance_region sr 
																				 WHERE sr.substance_id = s.substance_id AND sr.region_sid = in_region_sid));
END;

PROCEDURE GetUsagesList(
	out_usages_cur	OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_usages_cur FOR
		SELECT usage_id id, description
		  FROM usage
		 WHERE app_sid = security_pkg.getApp;
END;

PROCEDURE LookupCas(
	in_region_sid  	IN 	security_pkg.T_SID_ID,
	in_cas_code		IN	cas.cas_code%TYPE,
	out_cas_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- category 3 restrictions only need to be reported on, they do not cause waiver to be required
	OPEN out_cas_cur FOR
		SELECT c.cas_code, c.name, c.is_voc, NVL2(c.category, 'Cat ' || c.category, null)  category, cr.remarks restricted_remarks,
			  CASE WHEN c.category = '1a' THEN WAIVER_REQUIRED ELSE WAIVER_NOTREQUIRED END is_waiver_required
		  FROM cas c
		  LEFT JOIN (
		  	-- hmm - in theory this could return > 1 row, e.g. if at global + uk level?
		  	-- wouldn't really make sense to do this, but in theory this is possible.
		    SELECT cr.cas_code, cr.remarks
		      FROM cas_restricted cr
		     WHERE cr.root_region_sid IN (
		        SELECT region_sid
		          FROM csr.region
		         START WITH region_sid = in_region_sid
		       CONNECT BY PRIOR parent_sid = region_sid
		    ) AND cr.cas_code = in_cas_code
		      AND cr.start_dtm <= SYSDATE
		      AND (cr.end_dtm IS NULL OR SYSDATE < cr.end_dtm)
			  AND rownum = 1
		  )cr ON c.cas_code = cr.cas_code
		 WHERE c.cas_code = in_cas_code
		 ORDER BY c.name;
END;

PROCEDURE GetLookups(
	out_class_cur	OUT	security_pkg.T_OUTPUT_CUR,
	out_manu_cur	OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_class_cur FOR
		SELECT classification_id id, description
		  FROM classification
		 WHERE app_sid = security_pkg.getApp;

	OPEN out_manu_cur FOR
		SELECT manufacturer_id id, name name
		  FROM manufacturer
		 WHERE app_sid = security_pkg.getApp;
END;

PROCEDURE SaveSubstanceRegionProcess(
	in_ref				IN	substance.ref%TYPE,
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_label			IN	substance_region_process.label%TYPE,
	in_usage_id			IN	usage.usage_id%TYPE,
	out_process_id		OUT	substance_region_process.process_id%TYPE
)
AS
	v_substance_id	number;
BEGIN
	-- lookup the id from the ref with valid CAS data
	SELECT s.substance_id
	  INTO v_substance_id
	  FROM substance s
	 WHERE ref = TRIM(in_ref);

	-- use full save process procedure
	SaveSubstanceRegionProcess(v_substance_id, in_region_sid, in_label, in_usage_id, out_process_id);
END;

FUNCTION IsSubstanceAccessAllowed(
	in_user_sid			IN	security.security_pkg.T_SID_ID,
	in_substance_id		IN	substance.substance_id%TYPE,
	in_region_sid		IN	security.security_pkg.T_SID_ID,
	in_is_editing		IN	NUMBER DEFAULT 0,
	in_is_approved		IN NUMBER DEFAULT 0
) RETURN BOOLEAN
AS
	v_access_allowed 	NUMBER;
BEGIN
	SELECT count(1)
	  INTO v_access_allowed
	  FROM v$my_substance_region msr
	  JOIN v$substance_region sr ON msr.substance_id = sr.substance_id AND msr.region_sid = sr.region_sid
	 WHERE msr.substance_id = in_substance_id AND msr.region_sid = in_region_sid 
	   AND (in_is_editing = 0 OR msr.is_editable = 1)
	   AND (in_is_approved = 0 OR IsApprovedState(sr.CURRENT_STATE_LOOKUP_KEY) = 1);
	   
	RETURN NVL(v_access_allowed > 0 OR in_user_sid = security.security_pkg.SID_BUILTIN_ADMINISTRATOR, FALSE);
END;

FUNCTION IsApprovedState(
	in_state_lookup		IN	VARCHAR2
) RETURN NUMBER
AS
BEGIN
	IF in_state_lookup = 'CHEM_APPROVED' OR in_state_lookup = 'APPROVAL_NOT_REQUIRED' THEN
		RETURN 1;
	ELSE
		RETURN 0;
	END IF;
END;

PROCEDURE SaveSubstanceRegionProcess(
	in_substance_id		IN	substance.substance_id%TYPE,
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_label			IN	substance_region_process.label%TYPE,
	in_usage_id			IN	usage.usage_id%TYPE,
	out_process_id		OUT	substance_region_process.process_id%TYPE
)
AS
BEGIN
	-- permissions check based on the workflow
	IF NOT security.security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Access denied to the property with sid '||in_region_sid);
	END IF;

	IF NOT IsSubstanceAccessAllowed(SYS_CONTEXT('SECURITY','SID'), in_substance_id, in_region_sid, 0, 1) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Access denied to the substance with id '||in_substance_id||' in property with sid '||in_region_sid);
	END IF;

--	INTERNAL_CheckCasRestriction(in_substance_id, in_region_sid);

	BEGIN
		INSERT INTO substance_region_process (
			   process_id, substance_id, region_sid, label, usage_id, active
		)
		VALUES (
			   subst_rgn_proc_process_id_seq.NEXTVAL, in_substance_id, in_region_sid, in_label, in_usage_id, 1
		) RETURNING process_id INTO out_process_id;
		
		audit_pkg.WriteUsageLogEntry(in_substance_id, null, in_region_sid, null, null, 'Created Application Area {1} for {0}', in_label, null);
		
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			SELECT process_id
			  INTO out_process_id
			  FROM substance_region_process
			 WHERE substance_id = in_substance_id
			   AND region_sid = in_region_sid
			   AND UPPER(label) = UPPER(in_label)
			   AND active = 1;
			   
			UPDATE substance_region_process
			   SET active = 1
			 WHERE process_id = out_process_id;
	END;
END;

PROCEDURE UNSEC_DeleteSubstance(
	in_substance_id	IN	substance.substance_id%TYPE	
)
AS
BEGIN
	DELETE FROM subst_process_cas_dest_change
	 WHERE subst_proc_use_change_id IN (
		SELECT subst_proc_use_change_id
		  FROM substance_process_use_change
		 WHERE substance_id = in_substance_id
	 );
	DELETE FROM substance_process_use_file
	 WHERE substance_process_use_id IN (
		SELECT substance_process_use_id
		  FROM substance_process_use
		 WHERE substance_id = in_substance_id
	 );
	DELETE FROM substance_process_use_change
	 WHERE substance_id = in_substance_id;
	DELETE FROM substance_process_use
	 WHERE substance_id = in_substance_id;
	DELETE FROM substance_region_process
	 WHERE substance_id = in_substance_id;
	DELETE FROM substance_region
	 WHERE substance_id = in_substance_id;
	DELETE FROM substance_file
	 WHERE substance_id = in_substance_id;
	DELETE FROM substance_audit_log
	 WHERE substance_id = in_substance_id;
	DELETE FROM usage_audit_log
	 WHERE substance_id = in_substance_id;
	DELETE FROM substance_process_cas_dest
	 WHERE substance_id = in_substance_id;
	DELETE FROM substance_cas
	 WHERE substance_id = in_substance_id;
	DELETE FROM substance
	 WHERE substance_id = in_substance_id;
END;


PROCEDURE DeleteSubstanceRegionProcess (
	in_process_id		IN	substance_region_process.process_id%TYPE
)
AS
	v_substance_id		substance.substance_id%TYPE;
	v_region_sid		security_pkg.T_SID_ID;
	v_label				substance_region_process.label%TYPE;
BEGIN
	BEGIN
		SELECT substance_id, region_sid
		  INTO v_substance_id, v_region_sid
		  FROM substance_region_process
		 WHERE process_id = in_process_id;
		
		  audit_pkg.WriteUsageLogEntry(v_substance_id, null, v_region_sid, null, null, 'Removed Application Area for {0} of {1}', v_label, null);
	EXCEPTION
		WHEN OTHERS THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'Process "'||in_process_id||'" not found');
	END;
	
	UPDATE substance_region_process
	   SET active = 0
	 WHERE process_id = in_process_id;
END;

PROCEDURE AddSubstanceFile(
	in_substance_id	IN	substance.substance_id%TYPE,
	in_cache_key	IN	aspen2.filecache.cache_key%TYPE
)
AS
	v_mime_type			substance_file.mime_type%TYPE;
	v_filename			substance_file.filename%TYPE;
	v_data				substance_file.data%TYPE;
	v_substance_file_id	substance_file.substance_file_id%TYPE;
BEGIN
	BEGIN
		SELECT object, mime_type, filename
		  INTO v_data, v_mime_type, v_filename
		  FROM aspen2.filecache
		 WHERE cache_key = in_cache_key;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Cache Key "'||in_cache_key||'" not found');
	END;

	SELECT MAX(substance_file_id) 
	  INTO v_substance_file_id 
	  FROM substance_file 
	 WHERE substance_id = in_substance_id;
	
	IF v_substance_file_id IS NULL THEN
		INSERT INTO substance_file(substance_file_id, substance_id, data, uploaded_dtm, uploaded_user_sid, mime_type, filename)
			VALUES (substance_file_id_seq.nextval, in_substance_id, v_data, SYSDATE(), SYS_CONTEXT('SECURITY','SID'), v_mime_type, v_filename);
	ELSE
		UPDATE substance_file
		   SET 	data = v_data,
				uploaded_dtm = SYSDATE(),
				uploaded_user_sid = SYS_CONTEXT('SECURITY','SID'), 
				mime_type = v_mime_type, 
				filename = v_filename
		 WHERE substance_file_id = v_substance_file_id;
	END IF;
END;

PROCEDURE DeleteSubstanceProcessUse(
	in_substance_process_use_id		IN substance_process_use.substance_process_use_id%TYPE
)
AS
	v_substance_id		substance.substance_id%TYPE;
	v_region_sid 		security_pkg.T_SID_ID;
	v_root_deleg_sid	security_pkg.T_SID_ID;
	v_start_dtm			substance_process_use.start_dtm%TYPE;
	v_end_dtm			substance_process_use.end_dtm%TYPE;
	v_mass_Value		substance_process_use.mass_value%TYPE;
BEGIN
	SELECT substance_id, region_sid, root_delegation_sid, start_dtm, end_dtm, mass_Value
	  INTO v_substance_id, v_region_sid, v_root_deleg_sid, v_start_dtm, v_end_dtm, v_mass_Value
	  FROM substance_process_use
	 WHERE substance_process_use_id = in_substance_process_use_id;
	 
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	IF NOT IsSubstanceAccessAllowed(SYS_CONTEXT('SECURITY','SID'), v_substance_id, v_region_sid) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Access denied to the substance with id '||v_substance_id||' in property with sid '||v_region_sid);
	END IF;

	-- slightly crap in that it doesn't store who deleted it (that goes into the usage log thingy though)
	UPDATE substance_process_use_change  
	   SET retired_dtm = SYSDATE
	 WHERE retired_dtm IS NULL 
	   AND (substance_id, region_sid, process_id, root_delegation_sid, start_dtm, end_dtm) IN (
		SELECT substance_id, region_sid, process_id, root_delegation_sid, start_dtm, end_dtm
		  FROM substance_process_use
		 WHERE substance_process_use_id = in_substance_process_use_id
	 );	
	
	DELETE FROM substance_process_cas_dest
	 WHERE substance_process_use_id = in_substance_process_use_id;
	 
	DELETE FROM substance_process_use
	 WHERE substance_process_use_id = in_substance_process_use_id;
 	
	audit_pkg.WriteUsageLogEntry(v_substance_id, v_root_deleg_sid, v_region_sid, v_start_dtm, v_end_dtm, 'Removed chemical consumption for {0} of {1}kg', v_mass_Value, null);
END;


-- helper function to quickly add a CAS group member.
-- This will also create a new group if none exists.
PROCEDURE SetCASGroupMember(
	in_group_name		IN	cas_group.label%TYPE,
	in_cas_code			IN	cas.cas_code%TYPE
)
AS
	v_group_id		cas_group.cas_group_id%TYPE;
	v_lookup_Key	cas_group.lookup_key%TYPE;
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability('Administer Chemical module') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have permissions on the "Administer Chemical module" capability');
	END IF;
	
	v_lookup_key := UPPER(REPLACE(TRIM(in_group_name),' ','_'));
	BEGIN
		INSERT INTO cas_group (cas_group_id, parent_group_id, label, lookup_key)
			VALUES (cas_group_id_seq.nextval, null, TRIM(in_group_name), v_lookup_key)
			RETURNING cas_group_id INTO v_group_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			SELECT cas_group_id
			  INTO v_group_id
			  FROM cas_group
			 WHERE lookup_Key = v_lookup_key
			   AND app_sid = security_pkg.getApp;
	END;
	
	BEGIN
		INSERT INTO cas_group_member (cas_group_id, cas_code)
			VALUES (v_group_id, in_cas_code);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN	
			NULL;
	END;
END;

PROCEDURE ImportSubstProcessCasDest(
	in_substance_process_use_id		IN	substance_process_use.substance_process_use_id%TYPE,
	in_to_air_pct					IN	substance_process_cas_dest.to_air_pct%TYPE,
	in_to_product_pct				IN	substance_process_cas_dest.to_product_pct%TYPE,
	in_to_waste_pct					IN	substance_process_cas_dest.to_waste_pct%TYPE,
	in_to_water_pct					IN	substance_process_cas_dest.to_product_pct%TYPE,
	in_remaining_dest				IN	substance_process_cas_dest.remaining_dest%TYPE
)
AS
BEGIN
	-- assume same air/product/waste/water percentages for all CAS_CODES in substances unless it's a VOC
	-- in which case we assume it all goes to air.
	FOR r IN (
		SELECT c.cas_code
		  FROM substance_process_use spu
		  JOIN substance_cas sc ON spu.substance_id = sc.substance_id AND spu.app_sid = sc.app_sid
		  JOIN cas c ON sc.cas_code = c.cas_code
		 WHERE spu.substance_process_use_id = in_substance_process_use_id
	)
	LOOP
		substance_pkg.SetSubstProcessCasDest(
			in_substance_process_use_id		=> in_substance_process_use_id,
			in_cas_code						=> r.cas_code,
			in_to_air_pct					=> in_to_air_pct,
			in_to_product_pct				=> in_to_product_pct,
			in_to_waste_pct					=> in_to_waste_pct,
			in_to_water_pct					=> in_to_water_pct,
			in_remaining_dest				=> in_remaining_dest
		);
	END LOOP;
END;

PROCEDURE SetSubstProcessCasDest(
	in_substance_process_use_id		IN	substance_process_use.substance_process_use_id%TYPE,
	in_cas_code						IN	cas.cas_code%TYPE,
	in_to_air_pct					IN	substance_process_cas_dest.to_air_pct%TYPE,
	in_to_product_pct				IN	substance_process_cas_dest.to_product_pct%TYPE,
	in_to_waste_pct					IN	substance_process_cas_dest.to_waste_pct%TYPE,
	in_to_water_pct					IN	substance_process_cas_dest.to_product_pct%TYPE,
	in_remaining_dest				IN	substance_process_cas_dest.remaining_dest%TYPE
)
AS
	v_substance_id 				substance.substance_id%TYPE;
	v_region_sid 				security.security_pkg.T_SID_ID;
	v_process_id 				substance_region_process.process_id%TYPE;
	v_root_deleg_sid 			security.security_pkg.T_SID_ID;
	v_start_dtm					substance_process_use_change.start_dtm%TYPE;
	v_end_dtm 					substance_process_use_change.end_dtm%TYPE;
	v_subst_proc_use_change_id	substance_process_use_change.subst_proc_use_change_id%TYPE;
	v_region_desc				VARCHAR2(4000);
	v_to_air_pct				substance_process_cas_dest.to_air_pct%TYPE;
	v_to_product_pct			substance_process_cas_dest.to_product_pct%TYPE;
	v_to_waste_pct				substance_process_cas_dest.to_waste_pct%TYPE;
	v_to_water_pct				substance_process_cas_dest.to_water_pct%TYPE;
	v_remaining_pct				substance_process_cas_dest.remaining_pct%TYPE;
	v_remaining_dest			substance_process_cas_dest.remaining_dest%TYPE;
BEGIN
	-- pull out some values from the parent table
	SELECT region_sid, process_id, substance_id, root_delegation_sid, start_dtm, end_dtm
	  INTO v_region_sid, v_process_id, v_substance_id, v_root_deleg_sid, v_start_dtm, v_end_dtm
	  FROM substance_process_use
	 WHERE substance_process_use_id = in_substance_process_use_id;

	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	IF NOT IsSubstanceAccessAllowed(SYS_CONTEXT('SECURITY','SID'), v_substance_id, v_region_sid) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Access denied to the substance with id '||v_substance_id||' in property with sid '||v_region_sid);
	END IF;

--	INTERNAL_CheckCasRestriction(v_substance_id, v_region_sid);

	v_remaining_pct := 1 - (in_to_air_pct + in_to_product_pct + in_to_waste_pct + in_to_water_pct);

	-- upsert
	BEGIN
		INSERT INTO substance_process_cas_dest (
			substance_process_use_id, substance_id, cas_code,
			to_air_pct, to_product_pct, to_waste_pct, to_water_pct, 
			remaining_pct, remaining_dest
		) VALUES (
			in_substance_process_use_id, v_substance_id, in_cas_code,
			in_to_air_pct, in_to_product_pct, in_to_waste_pct, in_to_water_pct,
			v_remaining_pct, in_remaining_dest
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			-- keep track of the old values
			SELECT to_air_pct, to_product_pct, to_waste_pct, to_water_pct, remaining_dest
			  INTO v_to_air_pct, v_to_product_pct, v_to_waste_pct, v_to_water_pct, v_remaining_dest
			  FROM substance_process_cas_dest
			 WHERE substance_process_use_id= in_substance_process_use_id AND cas_code = in_cas_code;

			UPDATE substance_process_cas_dest
			   SET to_air_pct = in_to_air_pct,
				   to_product_pct = in_to_product_pct,
				   to_waste_pct = in_to_waste_pct,
				   to_water_pct = in_to_water_pct,
				   remaining_pct = v_remaining_pct,
				   remaining_dest = in_remaining_dest
			 WHERE substance_process_use_id= in_substance_process_use_id AND cas_code = in_cas_code;
			
			-- retire old, insert new. The NVL is horribly lazy but it's 8pm on Xmas Eve and I'm "on holiday"....
			IF v_to_air_pct != in_to_air_pct OR v_to_water_pct != in_to_water_pct 
				OR v_to_product_pct != in_to_product_pct OR v_to_waste_pct != in_to_waste_pct 
				OR NVL(in_remaining_dest,'empty') != NVL(v_remaining_dest,'empty') THEN

				-- if stuff has changed then fiddle with subst_process_cas_dest_change
				SELECT subst_proc_use_change_id
				  INTO v_subst_proc_use_change_id
				  FROM substance_process_use_change
				 WHERE substance_id = v_substance_id
				   AND region_sid = v_region_sid
				   AND process_Id = v_process_id
				   AND root_delegation_sid = v_root_deleg_sid
				   AND start_dtm = v_start_dtm
				   AND end_dtm = v_end_dtm
				   AND retired_dtm IS NULL;

				UPDATE subst_process_cas_dest_change
				   SET retired_dtm = SYSDATE
				 WHERE subst_proc_use_change_id = v_subst_proc_use_change_id
				   AND cas_code = in_cas_code;

				INSERT INTO subst_process_cas_dest_change (subst_proc_cas_dest_change_id, subst_proc_use_change_id, 
						cas_code, to_air_pct, to_product_pct, to_waste_pct, to_water_pct, remaining_pct, remaining_dest)
				VALUES (subst_proc_cas_dest_chg_id_seq.nextval, v_subst_proc_use_change_id, in_cas_code,
					in_to_air_pct, in_to_product_pct, in_to_waste_pct, in_to_water_pct, v_remaining_pct, in_remaining_dest);

				-- mark it up as changed
				UPDATE substance_process_use 
				   SET changed_since_prev_period = 1
				 WHERE substance_process_use_id = in_substance_process_use_id;
	
				audit_pkg.CheckAndWriteUsageLogEntry(v_substance_id, null, v_region_sid, null, null, 'To Air percentage changed for Application Area of {0} from {1}% to {2}%', v_to_air_pct * 100, in_to_air_pct * 100);
				audit_pkg.CheckAndWriteUsageLogEntry(v_substance_id, null, v_region_sid, null, null, 'To Product percentage changed for Application Area of {0} from {1}% to {2}%', v_to_product_pct * 100, in_to_product_pct * 100);
				audit_pkg.CheckAndWriteUsageLogEntry(v_substance_id, null, v_region_sid, null, null, 'To Waste percentage changed for Application Area of {0} from {1}% to {2}%', v_to_waste_pct * 100, in_to_waste_pct * 100);
				audit_pkg.CheckAndWriteUsageLogEntry(v_substance_id, null, v_region_sid, null, null, 'To Water percentage changed for Application Area of {0} from {1}% to {2}%', v_to_water_pct * 100, in_to_water_pct * 100);
				audit_pkg.CheckAndWriteUsageLogEntry(v_substance_id, null, v_region_sid, null, null, 'Remaining destination changed for Application Area of {0} from {1} to {2}', v_remaining_dest, in_remaining_dest);
			END IF;
	END;
	
	-- create/update the defaults
	BEGIN
		INSERT INTO process_cas_default (
			process_id, substance_id, region_sid, cas_code, to_air_pct, to_product_pct, to_waste_pct,
			to_water_pct, remaining_pct, remaining_dest
		) VALUES (
			v_process_id, v_substance_id, v_region_sid, in_cas_code,
			in_to_air_pct, in_to_product_pct, in_to_waste_pct, in_to_water_pct,
			v_remaining_pct, in_remaining_dest
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE process_cas_default
			   SET to_air_pct = in_to_air_pct,
				   to_product_pct = in_to_product_pct,
				   to_waste_pct = in_to_waste_pct,
				   to_water_pct = in_to_water_pct,
				   remaining_pct = v_remaining_pct,
				   remaining_dest = in_remaining_dest
			 WHERE substance_id = v_substance_id
			   AND region_sid = v_region_sid
			   AND process_id = v_process_id
			   AND cas_code = in_cas_code;
	END;
		
	--audit_pkg.WriteSubstanceLogEntry(in_substance_id, 'Created new Application Area for {0} at site {1} ({2})', v_region_desc, in_region_sid);
END;



-- takes a process name which is used for imports
PROCEDURE ImportSubstanceProcessUse(
	in_substance_ref				IN	substance.ref%TYPE,
	in_region_sid					IN	security_pkg.T_SID_ID,
	in_process_label				IN	substance_region_process.label%TYPE,
	in_usage_id						IN	usage.usage_id%TYPE,
	in_root_deleg_sid				IN	security_pkg.T_SID_ID,
	in_mass_value					IN	substance_process_use.mass_value%TYPE,
	in_note							IN	substance_process_use.note%TYPE,
	in_start_dtm					IN	substance_process_use.start_dtm%TYPE,
	in_end_dtm						IN	substance_process_use.end_dtm%TYPE,
	in_entry_mass_value 			IN	substance_process_use.entry_mass_value%TYPE,
	in_entry_std_measure_conv_id 	IN	substance_process_use.entry_std_measure_conv_id%TYPE,
	out_substance_process_use_id 	OUT	substance_process_use.substance_process_use_id%TYPE
)
AS
	v_process_id 	substance_region_process.process_id%TYPE;
	v_substance_id 	substance.substance_id%TYPE;
	v_empty_sids 	security_pkg.T_SID_IDS;
BEGIN
	-- see if we can find a local reference
	SELECT MIN(substance_id)
	  INTO v_substance_id
	  FROM substance_region
	 WHERE local_ref = in_substance_ref
	   AND region_sid = in_region_sid;

	IF v_substance_id IS NULL THEN
		-- see if we can find a global reference
		SELECT MIN(substance_id)
		  INTO v_substance_id
		  FROM substance
		 WHERE ref = in_substance_ref
		   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	END IF;

	-- we barf if we can't locate the substance
	IF v_substance_id IS NULL THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'Substance reference '||in_substance_ref||' not found');
	END IF;

	-- we need to check if the substance is registered and approved for the site and we have permission to do this:
	IF NOT IsSubstanceAccessAllowed(SYS_CONTEXT('SECURITY','SID'), v_substance_id, in_region_sid, 0, 1) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'No approved substance with id '||v_substance_id||' in property with sid '||in_region_sid || 'or access denied');
	END IF;

	-- make sure we've got a process tied down
	SaveSubstanceRegionProcess(
		in_substance_id		=> v_substance_id, 
		in_region_sid		=> in_region_sid, 
		in_label			=> in_process_label, 
		in_usage_id			=> in_usage_id, 
		out_process_id		=> v_process_id
	);

	SetSubstanceProcessUse(
		in_substance_process_use_id		=> null,
		in_substance_id					=> v_substance_id,
		in_region_sid					=> in_region_sid,
		in_process_id					=> v_process_id,
		in_root_deleg_sid				=> in_root_deleg_sid,
		in_mass_value					=> in_mass_value,
		in_note							=> in_note,
		in_start_dtm					=> in_start_dtm,
		in_end_dtm						=> in_end_dtm,
		in_entry_mass_value 			=> in_entry_mass_value,
		in_entry_std_measure_conv_id 	=> in_entry_std_measure_conv_id,
		in_local_ref					=> in_substance_ref,
		in_persist_files				=> v_empty_sids,
		out_substance_process_use_id	=> out_substance_process_use_id 
	);
END;



PROCEDURE SetSubstanceProcessUse(
	in_substance_process_use_id		IN	substance_process_use.substance_process_use_id%TYPE,
	in_substance_id					IN	substance.substance_id%TYPE,
	in_region_sid					IN	security_pkg.T_SID_ID,
	in_process_id					IN	substance_region_process.process_id%TYPE,
	in_root_deleg_sid				IN	security_pkg.T_SID_ID,
	in_mass_value					IN	substance_process_use.mass_value%TYPE,
	in_note							IN	substance_process_use.note%TYPE,
	in_start_dtm					IN	substance_process_use.start_dtm%TYPE,
	in_end_dtm						IN	substance_process_use.end_dtm%TYPE,
	in_entry_mass_value 			IN	substance_process_use.entry_mass_value%TYPE,
	in_entry_std_measure_conv_id 	IN	substance_process_use.entry_std_measure_conv_id%TYPE,
	in_local_ref					IN	substance_region.local_ref%TYPE,
	in_persist_files				IN	security_pkg.T_SID_IDS,
	out_substance_process_use_id 	OUT	substance_process_use.substance_process_use_id%TYPE
)
AS
	v_persist_files						security.T_SID_TABLE;
	v_old_mass_value					substance_process_use.mass_value%TYPE;
	v_subst_proc_use_change_id			substance_process_use_change.subst_proc_use_change_id%TYPE;
	v_previous_process_id				substance_process_use.process_id%TYPE;
	v_substance_process_use_id			substance_process_use.substance_process_use_id%TYPE;
BEGIN
	-- Only allow entering of values if the user can view the region
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	IF NOT IsSubstanceAccessAllowed(SYS_CONTEXT('SECURITY','SID'), in_substance_id, in_region_sid, 0, 1) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Access denied to the substance with id '||in_substance_id||' in property with sid '||in_region_sid);
	END IF;

	-- ok - so the code passes in the substance_process_use_id if we're doing an update because
	-- the natural key includes the process_id (you can have the same substance more than once with
	-- different processes). However, we might be changing the process_id so we need to let the code
	-- pass this through. We still do an upsert though in case the code gets called twice and with
	-- null / -1 passed in as the id by accident.
	v_substance_process_use_id := NVL(in_substance_process_use_id, -1);
	
	IF v_substance_process_use_id = -1 THEN 
		BEGIN
			-- Insert the new substance_process_use value and return the id
			INSERT INTO substance_process_use (
			   substance_process_use_id, substance_id, region_sid, process_id, root_delegation_sid, mass_value, note, 
			   start_dtm, end_dtm, entry_std_measure_conv_id, entry_mass_value
			)
			VALUES (
			   substance_process_use_id_seq.NEXTVAL, in_substance_id, in_region_sid, in_process_id, in_root_deleg_sid, in_mass_value, in_note,
			   in_start_dtm, in_end_dtm, in_entry_std_measure_conv_id, in_entry_mass_value
			) RETURNING substance_process_use_id INTO out_substance_process_use_id;
			
			audit_pkg.WriteUsageLogEntry(in_substance_id, in_root_deleg_sid, in_region_sid, in_start_dtm, in_end_dtm, 'Added consumption for {0} of {1}kg', in_mass_value, null);
			
			-- record the first time this chemical is used at this site, if it hasn't been used before
			UPDATE substance_region
			   SET first_used_dtm = TRUNC(in_start_dtm, 'MON')
			 WHERE substance_id = in_substance_id
			   AND region_sid = in_region_sid
			   AND first_used_dtm IS NULL;
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				-- eh? no matter. Pretend they're wanting an update.
				out_substance_process_use_id := null;
				SELECT substance_process_use_id
				  INTO v_substance_process_use_id
				  FROM substance_process_use
				 WHERE substance_id = in_substance_id 
				   AND region_sid = in_region_sid
				   AND process_id = in_process_id
				   AND root_delegation_sid = in_root_deleg_sid 
					AND	start_dtm = in_start_dtm 
					AND	end_dtm = in_end_dtm;
		END;
	END IF;

	-- out_substance_process_use_id will be set if we inserted successfully. Assume we didn't...
	IF out_substance_process_use_id IS NULL THEN
		SELECT process_id, mass_value
		  INTO v_previous_process_id, v_old_mass_value
		  FROM substance_process_use
		 WHERE substance_process_use_id = v_substance_process_use_id;

		UPDATE substance_process_use
		   SET mass_value = in_mass_value,
			   note = in_note,
			   start_dtm = in_start_dtm,
			   end_dtm = in_end_dtm,
			   entry_std_measure_conv_id = in_entry_std_measure_conv_id,
			   entry_mass_value = in_entry_mass_value,
			   process_id = in_process_id, -- can change the process,
			   changed_since_prev_period = (
			   		CASE
			   			WHEN changed_since_prev_period = 1 THEN 1 
			   			WHEN process_id != in_process_id THEN 1
			   			ELSE 0
			   		END 
			   	)
		 WHERE substance_process_use_id = v_substance_process_use_id;
		  
		out_substance_process_use_id := v_substance_process_use_id;
			 
		-- delete any substance_process_use_files which haven't been allow to persist
		v_persist_files := security_pkg.SidArrayToTable(in_persist_files);
		DELETE FROM substance_process_use_file
		 WHERE substance_process_use_id = out_substance_process_use_id
		   AND substance_process_use_file_id NOT IN (
			SELECT t.column_value
			  FROM TABLE(v_persist_files) T
		  );

		-- there's a weird mix of audit logging and historying going on.
		-- Probably needs unifying at some point
		audit_pkg.CheckAndWriteUsageLogEntry (
			in_substance_id, in_root_deleg_sid, in_region_sid, in_start_dtm, in_end_dtm, 'Chemical consumption changed for {0} from {1}kg to {2}kg',
			v_old_mass_value, in_mass_value
		);		
	END IF;

	-- TODO: we need to check to see if they really changed anything - -i.e. no point in copying 
	-- a load of crap if nothing material has changed.
	
	-- The natural key of SUBSTANCE_PROCESS_CAS_DEST is SUBSTANCE_ID, REGION_SID, PROCESS_ID, ROOT_DELEGATION_SID, START_DTM, END_DTM. 
	-- However, PROCESS_ID is mutable.
	-- Therefore any change to PROCESS_ID is treated as a deletion and reinsert from an audit point of view, 
	-- i.e. we set RETIRED_DTM for the row which matches the previous natural key.

	-- We can't key SUBSTANCE_PROCESS_USE_CHANGE on SUBSTANCE_PROCESS_USE_ID because in theory we could delete
	-- all the rows from SUBSTANCE_PROCESS_USE.
	
	-- retire existing row
	UPDATE substance_process_use_change
	   SET retired_dtm = SYSDATE
	 WHERE substance_id = in_substance_id
	   AND region_sid = in_region_sid
	   AND process_id = v_previous_process_id -- note the use of previous here
	   AND root_delegation_sid = in_root_deleg_sid
	   AND start_dtm = in_start_dtm
	   AND end_dtm = in_end_dtm
	   AND retired_dtm IS NULL;

	-- can't use returning with an INSERT and a SELECT
	SELECT subst_proc_use_change_id_seq.NEXTVAL
	  INTO v_subst_proc_use_change_id
	  FROM DUAL;

	-- Insert the new data into change table
	INSERT INTO substance_process_use_change (
	   subst_proc_use_change_id, substance_id, region_sid, process_id, 
	   root_delegation_sid, mass_value, note, start_dtm, end_dtm, entry_std_measure_conv_id, entry_mass_value
	)
	SELECT v_subst_proc_use_change_id, substance_id, region_sid, process_id,
		   root_delegation_sid, mass_value, note, start_dtm, end_dtm, entry_std_measure_conv_id, entry_mass_value
	  FROM substance_process_use
	 WHERE substance_process_use_id = out_substance_process_use_id;
 	
	-- copy forward any CAS data
	INSERT INTO subst_process_cas_dest_change (
		subst_proc_cas_dest_change_id, subst_proc_use_change_id, cas_code, to_air_pct, to_product_pct, to_waste_pct, to_water_pct, remaining_pct, 
			remaining_dest
	)
	SELECT subst_proc_cas_dest_chg_id_seq.nextval, v_subst_proc_use_change_id, cas_code, to_air_pct, to_product_pct, to_waste_pct, to_water_pct, remaining_pct, 
		remaining_dest
	  FROM substance_process_cas_dest
	 WHERE substance_process_use_id = out_substance_process_use_id;

	-- what if they want to clear the local_ref?
	UPDATE substance_region
	   SET local_ref = in_local_ref
	 WHERE substance_id = in_substance_id
	   AND region_sid = in_region_sid
	   AND in_local_ref IS NOT NULL;
END;

PROCEDURE AddSubstanceProcessUseFile (
	in_substance_process_use_id 		IN	substance_process_use.substance_process_use_id%TYPE,
	in_cache_key						IN	aspen2.filecache.cache_key%TYPE,
	out_subst_process_use_file_id		OUT	security_pkg.T_SID_ID
)
AS
BEGIN
	 
	SELECT subst_proc_use_file_id_seq.NEXTVAL
	  INTO out_subst_process_use_file_id
	  FROM DUAL;

	INSERT INTO substance_process_use_file (
	   substance_process_use_file_id, substance_process_use_id, 
	   data, uploaded_dtm, uploaded_user_sid, mime_type, filename
	)
	SELECT out_subst_process_use_file_id, in_substance_process_use_id, 
		   object, SYSDATE(), SYS_CONTEXT('SECURITY','SID'), mime_type, filename
	  FROM aspen2.filecache
	 WHERE cache_key = in_cache_key;

    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Cache Key "'||in_cache_key||'" not found');
    END IF;
END;

PROCEDURE DownloadProcessUseFile(
	in_subst_process_use_file_id		IN	substance_process_use_file.substance_process_use_file_id%TYPE,
	out_sub_cur							OUT	Security_Pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- wow - ton of security going on here...
	OPEN out_sub_cur FOR
		SELECT filename, mime_type, data
		  FROM substance_process_use_file
		 WHERE substance_process_use_file_id = in_subst_process_use_file_id;
END;

PROCEDURE GetSubstanceProcessUse(
	in_substance_process_use_id		IN	substance_process_use.substance_process_use_id%TYPE,
	out_proc_use_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_proc_use_file_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_proc_cas_dest_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_region_sid 	security_pkg.T_SID_ID;
BEGIN
	SELECT region_sid
	  INTO v_region_sid
	  FROM substance_process_use
	 WHERE substance_process_use_id = in_substance_process_use_id;

	IF NOT security.security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_proc_use_cur FOR
		SELECT spu.substance_process_use_id, s.substance_id, s.ref substance_ref, s.description substance_description, spu.region_sid,
			   spu.mass_value, spu.note, spu.entry_mass_value, spu.entry_std_measure_conv_id, spu.start_dtm, spu.end_dtm, sr.waiver_status_id, spu.process_id
		  FROM substance_process_use spu
		  JOIN substance s ON spu.substance_id = s.substance_id
		  JOIN substance_region sr ON sr.substance_id = spu.substance_id AND sr.region_sid = spu.region_sid
		 WHERE spu.substance_process_use_id = in_substance_process_use_id;
		 
	OPEN out_proc_use_file_cur FOR
		SELECT substance_process_use_file_id, substance_process_use_id, mime_type, filename
		  FROM substance_process_use_file
		 WHERE substance_process_use_id = in_substance_process_use_id;

	OPEN out_proc_cas_dest_cur FOR
		SELECT spu.substance_id, spu.region_sid, spu.substance_process_use_id,
			   NVL(spcd.to_air_pct, 0) to_air_pct, NVL(spcd.to_product_pct, 0) to_product_pct, 
			   NVL(spcd.to_waste_pct, 0) to_waste_pct, NVL(spcd.to_water_pct, 0) to_water_pct,
			   NVL(spcd.remaining_pct, 0) remaining_pct, 
			   spcd.remaining_dest, spu.process_id, sc.cas_code, cc.name cas_name, cc.is_voc,
			   sc.pct_composition, NVL2(cc.category, 'Cat ' || cc.category, null) category, cr.remarks restricted_remarks
		  FROM substance_process_use spu 
          JOIN substance_cas sc ON spu.substance_Id = sc.substance_id AND spu.app_sid = sc.app_sid
		  JOIN cas cc ON sc.cas_code = cc.cas_code
		  LEFT JOIN substance_process_cas_dest spcd ON spu.substance_process_use_Id = spcd.substance_process_use_id AND sc.cas_code = spcd.cas_code 
		  LEFT JOIN (
		  		SELECT cr.cas_code, cr.remarks
			      FROM cas_restricted cr
			     WHERE cr.root_region_sid IN (
			        SELECT region_sid
			          FROM csr.region
			         START WITH region_sid = v_region_sid
			       CONNECT BY PRIOR parent_sid = region_sid
			       ) 
			       AND cr.start_dtm <= SYSDATE
			       AND (cr.end_dtm IS NULL OR SYSDATE < cr.end_dtm)
				   AND rownum = 1
				 ORDER BY cr.start_dtm DESC
		  )cr ON cc.cas_code = cr.cas_code
		 WHERE spu.substance_process_use_id = in_substance_process_use_id
		 ORDER BY cc.name;
END;

PROCEDURE GetSubstanceProcessUseList(
	in_root_deleg_sid			IN	substance_process_use.root_delegation_sid%TYPE,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_start_dtm				IN	substance_process_use.start_dtm%TYPE,
	in_end_dtm					IN	substance_process_use.end_dtm%TYPE,
	in_incomplete_rows			IN	NUMBER,
	out_subst_proc_use_cur		OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_tol_type			csr.ind.tolerance_type%TYPE;
	v_neg_intol_mons	NUMBER(10);
BEGIN
	SELECT nvl(i.tolerance_type,2) 
	  INTO v_tol_type
	  FROM csr.delegation_plugin dp
	  JOIN csr.v$ind i ON dp.ind_sid = i.ind_sid
	 WHERE dp.js_class_type = 'SheetPlugin.Chem';
	 
	-- TODO: 13p fix needed
	SELECT decode(d.period_interval_id, 1, -1, 2, -3, 3, -6, 4, -12, 0)
	  INTO v_neg_intol_mons
	  FROM csr.delegation d
	 WHERE d.delegation_sid = in_root_deleg_sid;
	 
	OPEN out_subst_proc_use_cur FOR
		SELECT spu.substance_process_use_id, s.substance_id, s.ref substance_ref, s.description substance_description, spu.region_sid,
			   spu.mass_value, spup.mass_value prev_mass_value, spu.note, spup.note prev_note, spu.start_dtm, spup.start_dtm prev_start_dtm, spu.end_dtm, spup.end_dtm prev_end_dtm, sr.first_used_dtm first_used_dtm,
			   srp.first_used_dtm process_first_used_dtm, spu.changed_since_prev_period,
			   CASE WHEN EXISTS (
					SELECT null
					  FROM substance_cas sc
					  JOIN cas c on c.cas_code = sc.cas_code
					 WHERE sc.substance_id = spu.substance_id and c.category = '1a'
				) THEN 1 ELSE 0 END waiver_status,
			   CASE WHEN EXISTS (
					SELECT null
					  FROM substance_cas sc
					  JOIN cas_restricted cr ON cr.cas_code = sc.cas_code
					 WHERE sc.substance_id = spu.substance_id
				) THEN 1 ELSE 0 END is_reportable,
				msr.is_editable
		  FROM substance_process_use spu
		  JOIN substance s ON spu.substance_id = s.substance_id
		  JOIN substance_region_process srp ON spu.substance_id = srp.substance_id
										   AND spu.region_sid = srp.region_sid
										   AND spu.process_id = srp.process_id
		  JOIN v$my_substance_region msr ON srp.substance_id = msr.substance_id AND msr.region_sid = in_region_sid
		  JOIN substance_region sr ON sr.substance_id = msr.substance_id AND sr.region_sid = msr.region_sid
		  LEFT JOIN chem.substance_process_use spup ON spu.substance_id = spup.substance_id
												   AND spu.region_sid = spup.region_sid 
												   AND spu.process_id = spup.process_id
												   AND spup.start_dtm =  decode(v_tol_type, 
														csr.csr_data_pkg.TOLERANCE_TYPE_PREVIOUS_PERIOD, ADD_MONTHS(in_start_dtm, v_neg_intol_mons), 
														csr.csr_data_pkg.TOLERANCE_TYPE_PREVIOUS_YEAR, ADD_MONTHS(in_start_dtm, -12), 
														/*ELSE*/ADD_MONTHS(in_start_dtm, v_neg_intol_mons))
												   AND spup.end_dtm = decode(v_tol_type, 
														csr.csr_data_pkg.TOLERANCE_TYPE_PREVIOUS_PERIOD, ADD_MONTHS(in_end_dtm, v_neg_intol_mons), 
														csr.csr_data_pkg.TOLERANCE_TYPE_PREVIOUS_YEAR, ADD_MONTHS(in_end_dtm, -12), 
														/*ELSE*/ADD_MONTHS(in_end_dtm, v_neg_intol_mons))
		 WHERE spu.root_delegation_sid = in_root_deleg_sid
		   AND spu.region_sid = in_region_sid
		   AND spu.end_dtm = in_end_dtm
		   AND spu.start_dtm = in_start_dtm
		   AND (in_incomplete_rows = 0 OR (spu.mass_value IS NULL AND 
				EXISTS (
					SELECT null
					  FROM substance_cas sc
					  JOIN cas_restricted cr ON cr.cas_code = sc.cas_code
					 WHERE sc.substance_id = spu.substance_id
					   AND cr.start_dtm <= SYSDATE -- XXX: SYSDATE, really???
					   AND (cr.end_dtm IS NULL OR cr.end_dtm > SYSDATE)
				)
		   ))
		 ORDER BY substance_description;
END;

PROCEDURE GetSubstanceRegionProcesses(
	in_substance_id			IN	substance.substance_id%TYPE,
	in_region_sid 			IN	security_pkg.T_SID_ID,
	out_subst_rgn_proc_cur	OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	IF NOT IsSubstanceAccessAllowed(SYS_CONTEXT('SECURITY','SID'), in_substance_id, in_region_sid) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Access denied to the substance with id '||in_substance_id||' in property with sid '||in_region_sid);
	END IF;

	OPEN out_subst_rgn_proc_cur FOR
		SELECT process_id, substance_id, region_sid, label, usage_id
		  FROM substance_region_process
		 WHERE active = 1
		   AND substance_id = in_substance_id
		   AND region_sid = in_region_sid;
END;

PROCEDURE GetDefaultProcessDests(
	in_substance_id			IN	substance.substance_id%TYPE,
	in_region_sid 			IN	security_pkg.T_SID_ID,
	in_process_id			IN	substance_region_process.process_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT pcd.process_id, pcd.substance_id, pcd.region_sid, pcd.cas_code, pcd.to_air_pct, pcd.to_product_pct, 
			pcd.to_waste_pct, pcd.to_water_pct, pcd.remaining_dest, sc.pct_composition,
			c.name cas_name, c.is_voc, NVL2(c.category, 'Cat ' || c.category, null)  category, cr.remarks restricted_remarks
		  FROM process_cas_default pcd
		  JOIN substance_cas sc ON pcd.substance_id = sc.substance_id AND pcd.app_sid = sc.app_sid
		  JOIN cas c ON sc.cas_code = c.cas_code
  		  LEFT JOIN (
			  	-- hmm - in theory this could return > 1 row, e.g. if at global + uk level?
			  	-- wouldn't really make sense to do this, but in theory this is possible.
		  		SELECT cr.cas_code, cr.remarks
			      FROM cas_restricted cr
			     WHERE cr.root_region_sid IN (
			        SELECT region_sid
			          FROM csr.region
			         START WITH region_sid = in_region_sid
			       CONNECT BY PRIOR parent_sid = region_sid
			       ) 
			       AND cr.start_dtm <= SYSDATE
			       AND (cr.end_dtm IS NULL OR SYSDATE < cr.end_dtm)
				   AND rownum = 1
		  )cr ON c.cas_code = cr.cas_code
		 WHERE pcd.process_id = in_process_id
		   AND pcd.region_sid = in_region_sid
		   AND pcd.substance_id = in_substance_id
		 ORDER BY c.name;
END;

PROCEDURE GetSubstanceProcessCasDest(
	in_process_id					IN substance_region_process.process_id%TYPE,
	out_subst_proc_cas_dest_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_subst_proc_cas_dest_cur FOR
		SELECT spcd.substance_id, spu.region_sid,
			   spcd.to_air_pct, spcd.to_product_pct, spcd.to_waste_pct, spcd.to_water_pct,
			   spcd.remaining_pct, spcd.remaining_dest, u.description main_usage, u.usage_id,
			   spu.process_id, spcd.cas_code, c.name cas_name, c.is_voc, sc.pct_composition
		  FROM substance_process_cas_dest spcd
		  JOIN substance_cas sc ON spcd.substance_id = sc.substance_id AND spcd.cas_code = sc.cas_code AND spcd.app_sid = sc.app_sid
		  JOIN substance_process_use spu ON spcd.substance_process_use_id = spu.substance_process_use_id AND spcd.app_sid = spu.app_sid
		  JOIN substance_region_process srp
		    ON spu.substance_id = srp.substance_id
		   AND spu.region_sid = srp.region_sid
		   AND spu.process_id = srp.process_id
		  JOIN cas c ON spcd.cas_code = c.cas_code
		  JOIN usage u ON srp.usage_id = u.usage_id
		 WHERE spu.process_id = in_process_id;
END;

PROCEDURE LocateSubstanceProcessCasDest(
	in_ref							IN	substance.ref%TYPE,
	in_region_sid					IN	security_pkg.T_SID_ID,
	in_label						IN	substance_region_process.label%TYPE,
	out_subst_proc_cas_dest_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_substance_id	NUMBER;
	v_process_id	NUMBER;
BEGIN
	SELECT s.substance_id
	  INTO v_substance_id
	  FROM substance s
	 WHERE ref = TRIM(in_ref);
	 
	SELECT process_id
	  INTO v_process_id
	  FROM substance_region_process
	 WHERE substance_id = v_substance_id
	   AND label = in_label
	   AND region_sid = in_region_sid
	   AND active = 1;
	   
	GetSubstanceProcessCasDest(v_process_id, out_subst_proc_cas_dest_cur);
END;

PROCEDURE GetSubstanceProcessUses(
	in_process_id					IN	substance_region_process.process_id%TYPE,
	out_proc_use_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_proc_use_cur FOR
		SELECT spu.substance_process_use_id, s.substance_id, s.ref substance_ref, s.description substance_description, spu.region_sid,
			   spu.mass_value, spu.note, spu.entry_mass_value, spu.entry_std_measure_conv_id, spu.start_dtm, spu.end_dtm
		  FROM substance_process_use spu
		  JOIN substance s ON spu.substance_id = s.substance_id
		  JOIN substance_region sr ON sr.substance_id = spu.substance_id AND sr.region_sid = spu.region_sid
		 WHERE spu.process_id = in_process_id;
END;

PROCEDURE GetSubstanceProcessUseFile(
	in_substance_process_use_id				IN	substance_process_use.substance_process_use_id%TYPE,
	out_proc_use_file_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_proc_use_file_cur FOR
		SELECT	substance_process_use_file_id, substance_process_use_id, mime_type, filename
		  FROM	substance_process_use_file
		 WHERE	substance_process_use_id = in_substance_process_use_id;
END;

PROCEDURE GetSubstanceProcessUseCasDest(
	in_substance_process_use_id				IN	substance_process_use.substance_process_use_id%TYPE,
	out_proc_cas_dest_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_proc_cas_dest_cur FOR
		SELECT spcd.substance_id, spu.region_sid, 
			   spcd.to_air_pct, spcd.to_product_pct, spcd.to_waste_pct, spcd.to_water_pct,
			   spcd.remaining_pct, spcd.remaining_dest, u.description main_usage, u.usage_id,
			   spu.process_id
		  FROM substance_process_cas_dest spcd
		  JOIN substance_process_use spu ON spcd.substance_process_use_id = spu.substance_process_use_id AND spcd.app_sid = spu.app_sid
		  JOIN substance_region_process srp
		    ON spu.substance_id = srp.substance_id
		   AND spu.region_sid = srp.region_sid
		   AND spu.process_id = srp.process_id
		  JOIN usage u ON srp.usage_id = u.usage_id
		 WHERE spcd.substance_process_use_id = in_substance_process_use_id;
END;

PROCEDURE GetCasGroupAggr(
	in_aggregate_ind_group_id	IN	NUMBER,
	in_start_dtm				IN	DATE,
	in_end_dtm					IN	DATE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only administrators can run GetLWDAggregates');
	END IF;

	OPEN out_cur FOR
		WITH x AS (
			SELECT cg.lookup_key, 
				spu.start_dtm period_start_dtm, spu.end_dtm period_end_dtm, 
				spu.region_sid,
				SUM(spu.mass_value * spcd.to_air_pct * sc.pct_composition) mass_to_air, 
				SUM(spu.mass_value * spcd.to_product_pct * sc.pct_composition) mass_to_product, 
				SUM(spu.mass_value * spcd.to_waste_pct * sc.pct_composition) mass_to_waste, 
				SUM(spu.mass_value * spcd.to_water_pct * sc.pct_composition) mass_to_water, 
				SUM(spu.mass_value * spcd.remaining_pct * sc.pct_composition) mass_remaining
			  FROM cas_group cg 
			  JOIN cas_group_member cgm ON cg.cas_group_id = cgm.cas_group_id
			  JOIN cas c ON cgm.cas_code = c.cas_code
			  JOIN substance_cas sc ON c.cas_code = sc.cas_code
			  JOIN substance_process_cas_dest spcd ON sc.substance_id = spcd.substance_id AND sc.cas_code = spcd.cas_code
			  JOIN substance_process_use spu ON spcd.substance_process_use_id = spu.substance_process_use_id AND spcd.app_sid = spu.app_sid
			 GROUP BY cg.label, cg.lookup_key, spu.start_dtm, spu.end_dtm, spu.region_sid
		)
		SELECT i.ind_sid, y.region_sid, y.period_start_dtm, y.period_end_dtm,
			csr.csr_data_pkg.SOURCE_TYPE_AGGREGATE_GRP source_type_id,
			y.val_number,
			null error_code
		  FROM (
			SELECT lookup_key || '_AIR' lookup_key, region_sid, period_start_dtm, period_end_dtm, mass_to_air val_number
			  FROM x
			 UNION ALL
			SELECT lookup_key || '_PRODUCT' lookup_key, region_sid, period_start_dtm, period_end_dtm, mass_to_product val_number
			  FROM x
			 UNION ALL
			SELECT lookup_key || '_WASTE' lookup_key, region_sid, period_start_dtm, period_end_dtm, mass_to_waste val_number
			  FROM x
			 UNION ALL
			SELECT lookup_key || '_WATER' lookup_key, region_sid, period_start_dtm, period_end_dtm, mass_to_water val_number
			  FROM x
			 UNION ALL
			SELECT lookup_key || '_REMAINING' lookup_key, region_sid, period_start_dtm, period_end_dtm, mass_remaining val_number
			  FROM x
		)y JOIN csr.ind i ON y.lookup_key = i.lookup_key
		 ORDER BY i.ind_sid, y.region_sid, period_start_dtm;
		 
END;

END SUBSTANCE_PKG;
/
