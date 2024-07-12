CREATE OR REPLACE PACKAGE BODY CSR.Measure_Pkg AS

PROCEDURE CreateMeasure(
	in_act_id			    		IN	security_pkg.T_ACT_ID					DEFAULT SYS_CONTEXT('SECURITY','ACT'),
	in_parent_sid_id	    		IN	security_pkg.T_SID_ID					DEFAULT NULL,
	in_app_sid 	    				IN	security_pkg.T_SID_ID					DEFAULT SYS_CONTEXT('SECURITY','APP'),
	in_name					    	IN	measure.name%TYPE,
	in_description		    		IN	measure.description%TYPE,
	in_scale			    		IN	measure.scale%TYPE						DEFAULT 0,
	in_format_mask		    		IN	measure.format_mask%TYPE				DEFAULT '#,##0',
	in_custom_field			    	IN	measure.custom_field%TYPE				DEFAULT NULL,
	in_std_measure_conversion_id	IN	measure.std_measure_conversion_id%TYPE	DEFAULT NULL,
	in_pct_ownership_applies    	IN	measure.pct_ownership_applies%TYPE		DEFAULT 1,
	in_divisibility					IN	measure.divisibility%TYPE				DEFAULT csr_data_pkg.DIVISIBILITY_DIVISIBLE,
	in_option_set_id				IN	measure.option_set_id%TYPE				DEFAULT NULL,
	in_lookup_key					IN	measure.lookup_key%TYPE					DEFAULT NULL,
	out_measure_sid			    	OUT measure.measure_sid%TYPE
) AS
	v_measure_sid_id	security_pkg.T_SID_ID;
	v_parent_sid_id		security_pkg.T_SID_ID;
BEGIN
	v_parent_sid_id := COALESCE(in_parent_sid_id, securableobject_pkg.getSidFromPath(in_act_id, in_app_sid, 'Measures'));
  
	-- Create a securable object of CSRMeasure type
	SecurableObject_pkg.CreateSO(in_act_id, v_parent_sid_id, class_pkg.GetClassID('CSRMeasure'), Replace(in_name,'/','\'), v_measure_sid_id); --'
  
	-- Add to Audit Log
	csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, in_app_sid, v_measure_sid_id, 'Created measure');
  
	-- Insert the information pertaining to the measure object
	INSERT INTO measure
		(measure_sid, name, description, scale, app_sid, format_mask, custom_field, 
		 std_measure_conversion_id, pct_ownership_applies, divisibility, option_set_id, lookup_key)
	VALUES
		(v_measure_sid_id, in_name, in_description, in_scale, in_app_sid, in_format_mask, in_custom_field, 
		 in_std_measure_conversion_id, in_pct_ownership_applies, in_divisibility, in_option_set_id, in_lookup_key);
  
	-- Return the new object to the caller
	out_measure_sid := v_measure_sid_id;
END;

PROCEDURE AmendMeasure(
	in_act_id			    		IN	security_pkg.T_ACT_ID					DEFAULT SYS_CONTEXT('SECURITY','ACT'),
	in_measure_sid_id	    		IN	security_pkg.T_SID_ID,
	in_name					    	IN	measure.name%TYPE,
	in_description		    		IN	measure.description%TYPE,
	in_scale			    		IN	measure.scale%TYPE,
	in_format_mask		    		IN	measure.format_mask%TYPE,
	in_custom_field			    	IN	measure.custom_field%TYPE,
	in_std_measure_conversion_id	IN	measure.std_measure_conversion_id%TYPE,
	in_pct_ownership_applies    	IN	measure.pct_ownership_applies%TYPE,
	in_divisibility					IN	measure.divisibility%TYPE,
	in_option_set_id				IN	measure.option_set_id%TYPE,
	in_lookup_key					IN	measure.lookup_key%TYPE
) AS
	CURSOR cv IS
		SELECT m.app_sid, m.name, m.description, m.scale, m.format_mask, m.custom_field, m.pct_ownership_applies,
			   NVL(smc.description, 'Nothing') measure_unit, m.std_measure_conversion_id, smc.std_measure_id,
			   m.divisibility, m.option_set_id, m.lookup_key
		  FROM measure m
		  LEFT JOIN std_measure_conversion smc ON m.std_measure_conversion_id = smc.std_measure_conversion_id
		 WHERE measure_sid = in_measure_sid_id;
	rv cv%ROWTYPE;
	v_change						VARCHAR2(1023);
    v_val_id        				val.val_id%TYPE;
    v_new_std_measure_conversion	std_measure_conversion.description%TYPE := 'Nothing';
    v_new_std_measure_id			std_measure.std_measure_id%TYPE;
    v_count							NUMBER;
    v_id							measure_conversion.measure_conversion_id%TYPE;
    v_recalc_all					BOOLEAN := FALSE;
BEGIN
	-- Rename the object even if it hasn't changed.  This at least checks write permissions
	-- on the object, so we can be sure that we can amend it.
	SecurableObject_Pkg.RenameSO(in_act_id, in_measure_sid_id, Replace(in_name,'/','\')); --'
	
	OPEN cv;
	FETCH cv INTO rv;
	CLOSE cv;
	
	IF in_std_measure_conversion_id IS NOT NULL THEN -- variable defaulted to 'Nothing' anyway so no need to check if null
		SELECT description, std_measure_id
		  INTO v_new_std_measure_conversion, v_new_std_measure_id
		  FROM std_measure_conversion
		 WHERE std_measure_conversion_id = in_std_measure_conversion_id;
	END IF;
	
	IF in_std_measure_conversion_id IS NULL OR -- deleting std_measure_conversion
		(rv.std_measure_id IS NOT NULL AND rv.std_measure_id != v_new_std_measure_id) THEN -- changing std_measure
		
		SELECT COUNT(*)
		  INTO v_count
		  FROM measure_conversion
		 WHERE measure_sid = in_measure_sid_id
		   AND std_measure_conversion_id IS NOT NULL;
		
		IF v_count > 0 THEN
			RAISE csr_data_pkg.STD_MEASURE_CONV_CHANGE;
		END IF;
	ELSIF rv.std_measure_id = v_new_std_measure_id THEN -- changing std_measure_conversion, but not std_measure
		SELECT COUNT(*)
		  INTO v_count
		  FROM measure_conversion
		 WHERE measure_sid = in_measure_sid_id
		   AND std_measure_conversion_id = in_std_measure_conversion_id;
		
		IF v_count > 0 THEN
			RAISE csr_data_pkg.STD_MEASURE_CONV_CHANGE;
		END IF;
	END IF;
	
	v_change := v_change||Csr_Data_Pkg.AddToAuditDescription('Description', rv.description, in_description);
	v_change := v_change||Csr_Data_Pkg.AddToAuditDescription('Scale', rv.scale, in_scale);
	v_change := v_change||Csr_Data_Pkg.AddToAuditDescription('Format mask', rv.format_mask, in_format_mask);
	v_change := v_change||Csr_Data_Pkg.AddToAuditDescription('Custom field', rv.custom_field, in_custom_field);
	v_change := v_change||Csr_Data_Pkg.AddToAuditDescription('Percent ownership applies', rv.pct_ownership_applies, in_pct_ownership_applies);
	v_change := v_change||Csr_Data_Pkg.AddToAuditDescription('Unit', rv.measure_unit, v_new_std_measure_conversion);
	v_change := v_change||Csr_Data_Pkg.AddToAuditDescription('Divisibility', rv.divisibility, in_divisibility);
	v_change := v_change||Csr_Data_Pkg.AddToAuditDescription('Option set id', rv.option_set_id, in_option_set_id);
	v_change := v_change||Csr_Data_Pkg.AddToAuditDescription('Lookup key', rv.lookup_key, in_lookup_key);

	IF v_change IS NOT NULL THEN
		csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, rv.app_sid, in_measure_sid_id, v_change);
		-- change any form / data explorer or delegation indicator names	 
    END IF;
    
	UPDATE measure 
	   SET name = in_name, description = in_description, 
	   	   scale = in_scale, format_mask = in_format_mask,
           custom_field = in_custom_field,
           std_measure_conversion_id = in_std_measure_conversion_id,
           divisibility = in_divisibility,
           option_set_id = in_option_set_id,
           lookup_key = in_lookup_key
	 WHERE measure_sid = in_measure_sid_id;
    
    IF rv.pct_ownership_applies != in_pct_ownership_applies THEN
        -- log change
        UPDATE measure 
           SET pct_ownership_applies = in_pct_ownership_applies 
         WHERE measure_sid = in_measure_sid_id;
        region_pkg.SetPctOwnershipApplies(in_act_id, in_measure_sid_id, in_pct_ownership_applies);
    END IF;
    
    IF null_pkg.ne(rv.std_measure_conversion_id, in_std_measure_conversion_id) THEN
		-- update conversions if std_measure_conversion is set
		FOR r IN (
			SELECT measure_conversion_id, std_measure_conversion_id, description
			  FROM measure_conversion
			 WHERE measure_sid = in_measure_sid_id
			   AND std_measure_conversion_id IS NOT NULL
		)
		LOOP
			SetConversion(
				in_act_id,
				r.measure_conversion_id,
				in_measure_sid_id,
				r.description,
				r.std_measure_conversion_id,
				v_id);
		END LOOP;
		v_recalc_all := TRUE;
	END IF;
	
	IF null_pkg.ne(rv.divisibility, in_divisibility) THEN
		v_recalc_all := TRUE;
	END IF;
	
	IF v_recalc_all THEN
		-- if they've changed the std_measure_conversion_id then go and recalc everything
		FOR r IN (
			SELECT ind_sid
			  FROM ind
			 WHERE measure_sid = in_measure_sid_id
		)
		LOOP
			calc_pkg.AddJobsForCalc(r.ind_sid);
			calc_pkg.AddJobsForInd(r.ind_sid);
		END LOOP;
    END IF;
    
END;

-- Securable object callbacks

PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
) AS
BEGIN
	-- We do this through the measure_pkg specific Create call
	NULL;
END;

PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
)
AS
BEGIN
	-- Update the name of the measure	
	-- when we trash stuff the SO gets renamed to NULL (to avoid dupe obj names when we
	-- move the securable object). We don't really want to rename our objects tho.
	IF in_new_name IS NOT NULL THEN
		UPDATE MEASURE SET NAME = in_new_name WHERE measure_sid = in_sid_id;
	END IF;
END;

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
)
AS	
	v_used	NUMBER(10);
BEGIN
	-- are any indicators bound to this measure?
	SELECT SUM(cnt)
	  INTO v_used
	  FROM (SELECT COUNT(*) cnt 
	   		  FROM ind 
	   		 WHERE measure_sid = in_sid_id
	  	 );
	  	     
	IF v_used > 0 THEN	
		RAISE_APPLICATION_ERROR(Csr_Data_Pkg.ERR_OBJECT_IN_USE, 'Cannot be deleted. Measure '||in_sid_id||' is used by '||v_used||' indicators or factor sets'); 
	END IF;
	
	-- Remove energy star dependencies not linked to indicators
	UPDATE est_attr_measure_conv
	   SET measure_sid = NULL,
	       measure_conversion_id = NULL
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND measure_sid = in_sid_id;
	
	UPDATE est_attr_measure
	   SET measure_sid = NULL
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND measure_sid = in_sid_id;
	   
	UPDATE est_conv_mapping
	   SET measure_sid = NULL,
	       measure_conversion_id = NULL
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND measure_sid = in_sid_id;

	UPDATE csr.sheet_value_hidden_cache
	   SET entry_measure_conversion_id = NULL
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND entry_measure_conversion_id = in_sid_id;
	
	DELETE FROM auto_imp_unit_map
	 WHERE measure_conversion_id IN (
		SELECT measure_conversion_id 
		  FROM measure_conversion 
		 WHERE measure_sid = in_sid_id
	);
	
	-- Delete the old measure data
	-- TODO: we should really trap Foreign Key Constraints
	UPDATE form_ind_member
	   SET measure_conversion_id = NULL
	 WHERE measure_conversion_id IN (SELECT measure_conversion_id 
	 								   FROM measure_conversion
	 								  WHERE measure_sid = in_sid_id);
	DELETE FROM measure_conversion_period 
	 WHERE measure_conversion_id IN (
		SELECT measure_conversion_id 
		  FROM measure_conversion 
		 WHERE measure_sid = in_sid_id
	);
	DELETE FROM user_measure_conversion
	 WHERE measure_sid = in_sid_id;
	DELETE FROM measure_conversion
	 WHERE measure_sid = in_sid_id;
	DELETE FROM measure
	 WHERE measure_sid = in_sid_id;	  
END;

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
)
AS
BEGIN
	-- Nothing to do
	NULL;
END;

PROCEDURE GetMeasure(
    in_act_id       				IN  security_pkg.T_ACT_ID,
	in_measure_sid					IN  security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
)
IS
BEGIN				 
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_measure_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading measure sid'||in_measure_sid);
	END IF;

	OPEN out_cur FOR
		-- Update t_measure_cur in package header if anything is added.
		SELECT m.measure_sid, m.format_mask, m.scale, m.name, m.description, m.custom_field, 
			   m.pct_ownership_applies, m.std_measure_conversion_id, m.divisibility,
			   NVL(m.factor, smc.a) factor, NVL(m.m, sm.m) m, NVL(m.kg, sm.kg) kg, 
			   NVL(m.s, sm.s) s, NVL(m.a, sm.a) a, NVL(m.k, sm.k) k, NVL(m.mol, sm.mol) mol,
			   NVL(m.cd, sm.cd) cd, smc.description std_measure_description,
			   m.option_set_id, m.lookup_key
		  FROM measure m
		  LEFT JOIN std_measure_conversion smc ON m.std_measure_conversion_id = smc.std_measure_conversion_id
		  LEFT JOIN std_measure sm ON smc.std_measure_id = sm.std_measure_id
		 WHERE measure_sid = in_measure_sid;
END;				  

-- no security check: measures are basically site user public, and all this does is let
-- you get a sid anyway
FUNCTION TryGetMeasureSIDFromKey(
	in_lookup_key					IN	ind.lookup_key%TYPE
) RETURN measure.measure_sid%TYPE
AS
    v_sid   						security_pkg.T_SID_ID;
BEGIN
    SELECT measure_sid
      INTO v_sid
      FROM measure
     WHERE UPPER(lookup_key) = UPPER(in_lookup_key);
	RETURN v_sid;
EXCEPTION
	WHEN NO_DATA_FOUND THEN
    	RETURN NULL;
END;

FUNCTION GetMeasureSIDFromKey(
	in_lookup_key					IN	ind.lookup_key%TYPE
) RETURN measure.measure_sid%TYPE
AS
    v_sid   						security_pkg.T_SID_ID;
BEGIN
	v_sid := TryGetMeasureSIDFromKey(in_lookup_key);
	IF v_sid IS NULL THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND,
        	'The measure with lookup key '||in_lookup_key||' could not be found');
	END IF;
	RETURN v_sid;
END;

FUNCTION TryGetMeasureConvIDFromKey(
	in_lookup_key					IN	measure_conversion.lookup_key%TYPE
) RETURN measure_conversion.measure_conversion_Id%TYPE
AS
    v_id   						security_pkg.T_SID_ID;
BEGIN
    SELECT measure_conversion_id
      INTO v_id
      FROM measure_conversion
     WHERE UPPER(lookup_key) = UPPER(in_lookup_key);
	RETURN v_id;
EXCEPTION
	WHEN NO_DATA_FOUND THEN
    	RETURN NULL;
END;

PROCEDURE GetAllMeasures(
    in_act_id       				IN  security_pkg.T_ACT_ID,
	in_app_sid						IN  security_pkg.T_SID_ID,
	out_measure_cur					OUT SYS_REFCURSOR
)
IS
BEGIN	
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied listing measures');
	END IF;

	OPEN out_measure_cur FOR
		SELECT m.measure_sid, m.format_mask, m.scale, m.name, m.description, m.custom_field,
			   m.pct_ownership_applies, m.std_measure_conversion_id, m.divisibility,
			   NVL(m.factor, smc.a) factor, NVL(m.m, sm.m) m, NVL(m.kg, sm.kg) kg, 
			   NVL(m.s, sm.s) s, NVL(m.a, sm.a) a, NVL(m.k, sm.k) k, NVL(m.mol, sm.mol) mol,
			   NVL(m.cd, sm.cd) cd,
			   CASE WHEN m.description IS NULL THEN '('||m.name||')' ELSE m.description END label, -- used by csr/site/schema/indRegion/editIndicator.aspx
			   m.option_set_id, smc.description std_measure_description,
			   m.lookup_key
		  FROM measure m
		  LEFT JOIN std_measure_conversion smc ON m.std_measure_conversion_id = smc.std_measure_conversion_id
		  LEFT JOIN std_measure sm ON smc.std_measure_id = sm.std_measure_id
		 ORDER BY m.description;
END;

PROCEDURE GetAllMeasures(
    in_act_id       				IN  security_pkg.T_ACT_ID,
	in_app_sid						IN  security_pkg.T_SID_ID,
	out_measure_cur					OUT SYS_REFCURSOR,
	out_measure_conv_cur			OUT SYS_REFCURSOR,
	out_measure_conv_date_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- The called overload of GetAllMeasures does permission checking
	GetAllMeasures(in_act_id, in_app_sid, out_measure_cur);
	
	OPEN out_measure_conv_cur FOR
		SELECT measure_conversion_id, measure_sid, std_measure_conversion_id,
			   description, a, b, c, lookup_key
		  FROM measure_conversion;
		  
	OPEN out_measure_conv_date_cur FOR
		SELECT measure_conversion_id, start_dtm, end_dtm, a, b, c
		  FROM measure_conversion_period;	
END;

PROCEDURE GetAllMeasures(
	out_measure_cur					OUT SYS_REFCURSOR,
	out_measure_conv_cur			OUT SYS_REFCURSOR,
	out_measure_conv_date_cur		OUT	SYS_REFCURSOR
)
AS
	v_act_id				security_pkg.T_ACT_ID := security_pkg.GetAct;
	v_app_sid				security_pkg.T_SID_ID := security_pkg.GetApp;
BEGIN
	-- The called overload of GetAllMeasures does permission checking
	GetAllMeasures(v_act_id, v_app_sid, out_measure_cur, out_measure_conv_cur, out_measure_conv_date_cur);
END;

FUNCTION INTERNAL_GetMeasureRefCount(
	in_measure_sid	IN  security_pkg.T_SID_ID
) RETURN NUMBER
AS
	v_cnt	NUMBER(10);
BEGIN
	SELECT SUM(cnt) cnt 
	  INTO v_cnt
      FROM ( 
		SELECT COUNT(*) cnt 
		  FROM ind 
		 WHERE measure_sid = in_measure_sid
		 UNION 
		SELECT COUNT(*) cnt 
		  FROM pending_ind
		 WHERE measure_sid = in_measure_sid
	);

	RETURN v_cnt;
END;

PROCEDURE GetMeasureList(
    in_act_id       IN  security_pkg.T_ACT_ID,
	in_app_sid 		IN  security_pkg.T_SID_ID,
	in_order_by		IN	VARCHAR2,
	out_cur			OUT SYS_REFCURSOR
)
IS		
	v_order_by	VARCHAR2(1000);
BEGIN				   		
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied listing measures');
	END IF;

	IF in_order_by IS NOT NULL THEN
		utils_pkg.ValidateOrderBy(in_order_by, 'active,format_mask,scale,name,description,references,measure_sid');
		v_order_by := ' ORDER BY ' || REPLACE(in_order_by, 'description', 'LOWER(description)');
	END IF;

	OPEN out_cur FOR
		'SELECT measure_sid, 1 active, format_mask, scale, NAME, NVL(description, ''(''||NAME||'')'') description, '||
			'measure_pkg.INTERNAL_GetMeasureRefCount(measure_sid) references '||
		  ' FROM MEASURE WHERE app_sid = :in_app_sid'||v_order_by USING in_app_sid;
END;

PROCEDURE GetMeasureFromConversion(
	in_conversion_id	IN	measure_conversion.measure_conversion_id%TYPE,
	out_measure_sid		OUT	measure.measure_sid%TYPE
)
AS
BEGIN
	BEGIN
		SELECT measure_sid 
		  INTO out_measure_sid
		  FROM measure_conversion 
		 WHERE measure_conversion_id = in_conversion_id; 
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'Measure not found for the conversion with id '||in_conversion_id);
	END;
END;

PROCEDURE GetConversion(
    in_act_id     	 	IN  security_pkg.T_ACT_ID,
	in_conversion_id	IN  measure_conversion.measure_conversion_id%TYPE,
	in_dtm				IN	DATE,
	out_cur				OUT SYS_REFCURSOR
)
IS	
	v_measure_sid	measure.measure_sid%TYPE;
BEGIN
	GetMeasureFromConversion(in_conversion_id, v_measure_sid);
	
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_measure_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading measure');
	END IF;

	OPEN out_cur FOR
 	    SELECT mc.measure_conversion_id, mc.measure_sid, mc.description conversion_description, 
			   NVL(mc.a, mcp.a) a, NVL(mc.b, mcp.b) b, NVL(mc.c, mcp.c) c,
               mc.std_measure_conversion_id, mc.a internal_a, mc.b internal_b, mc.c internal_c -- used by editMeasure.aspx
		  FROM measure_conversion mc, measure_conversion_period mcp
		 WHERE mc.measure_conversion_id = in_conversion_id
		   AND mc.measure_conversion_id = mcp.measure_conversion_id(+)  
		   AND (in_dtm >= mcp.start_dtm OR mcp.start_dtm IS NULL)
		   AND (in_dtm < mcp.end_dtm OR mcp.end_dtm IS NULL);
END;

PROCEDURE GetConvertedValue(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_val_number				IN	val.entry_val_number%TYPE,
	in_conversion_id			IN	measure_conversion.measure_conversion_id%TYPE,
	in_dtm						IN	DATE,
	out_cur						OUT	SYS_REFCURSOR
)
AS
	v_measure_sid	measure.measure_sid%TYPE;
BEGIN
	-- XXX: we have this check, but I'm not sure it's worth doing -- aren't all measures
	-- meant to be public read only?
	GetMeasureFromConversion(in_conversion_id, v_measure_sid);
	
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_measure_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading the measure with sid '||v_measure_sid);
	END IF;

	OPEN out_cur FOR
		SELECT COALESCE(mc.a, mcp.a, 1) * POWER(in_val_number, COALESCE(mc.b, mcp.b, 1)) + COALESCE(mc.c, mcp.c, 0) val_number
		  FROM measure_conversion mc, measure_conversion_period mcp
		 WHERE mc.measure_conversion_id = mcp.measure_conversion_id(+)
		   AND in_conversion_id = mc.measure_conversion_id(+)
		   AND (in_dtm >= mcp.start_dtm or mcp.start_dtm is null)
		   AND (in_dtm < mcp.end_dtm or mcp.end_dtm is null);      
END;

FUNCTION UNSEC_GetConvertedValue(
	in_val_number				IN	val.entry_val_number%TYPE,
	in_conversion_id			IN	measure_conversion.measure_conversion_id%TYPE,
	in_dtm						IN	DATE
) RETURN val.val_number%TYPE
AS
	v_val val.val_number%TYPE;
BEGIN
	IF NVL(in_conversion_Id,-1) = -1 THEN 
		RETURN in_val_number;
	END IF;
	
	BEGIN
		SELECT POWER((in_val_number - COALESCE(mc.c, mcp.c, 0)) / COALESCE(mc.a, mcp.a, 1), 1 / COALESCE(mc.b, mcp.b, 1))
		  INTO v_val
		  FROM measure_conversion mc, measure_conversion_period mcp
		 WHERE mc.measure_conversion_id = mcp.measure_conversion_id(+)
		   AND in_conversion_id = mc.measure_conversion_id(+)
		   AND (in_dtm >= mcp.start_dtm or mcp.start_dtm is null)
		   AND (in_dtm < mcp.end_dtm or mcp.end_dtm is null);     
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- we throw an exception
			RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_MEASURE_CONV_NOT_FOUND, 'Conversion factor not found for Id '||in_conversion_id||' for date '||in_dtm);
	END;
	
	RETURN v_val;
END; 

FUNCTION UNSEC_GetBaseValue(
	in_val_number				IN	val.entry_val_number%TYPE,
	in_conversion_id			IN	measure_conversion.measure_conversion_id%TYPE,
	in_dtm						IN	DATE
) RETURN val.val_number%TYPE
AS
	v_val val.val_number%TYPE;
BEGIN
	IF NVL(in_conversion_Id,-1) = -1 THEN 
		RETURN in_val_number;
	END IF;
	
	BEGIN
		SELECT COALESCE(mc.a, mcp.a, 1) * POWER(in_val_number, COALESCE(mc.b, mcp.b, 1)) + COALESCE(mc.c, mcp.c, 0)
		  INTO v_val
		  FROM measure_conversion mc, measure_conversion_period mcp
		 WHERE mc.measure_conversion_id = mcp.measure_conversion_id(+)
		   AND in_conversion_id = mc.measure_conversion_id(+)
		   AND (in_dtm >= mcp.start_dtm or mcp.start_dtm is null)
		   AND (in_dtm < mcp.end_dtm or mcp.end_dtm is null);     
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- we throw an exception -> change to some kind of recognised type?
			RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_MEASURE_CONV_NOT_FOUND, 'Conversion factor not found for Id '||in_conversion_id||' for date '||in_dtm);
	END;
	
	RETURN v_val;
END; 

PROCEDURE ApplyMeasureConversionChange(
	in_user_sid					IN	security_pkg.T_SID_ID,
	in_measure_conversion_id	IN	measure_conversion.measure_conversion_Id%TYPE,
	in_start_dtm				IN	measure_conversion_period.start_dtm%TYPE
)
AS
	v_val_id					val.val_id%TYPE;
	v_sheet_id					security_pkg.T_SID_ID;
BEGIN
    -- update all base values
    -- we have to do this after we've altered the measure or it'll base the pct_ownership calc on the old pct_ownership_applies values
    -- this will also deal with meter readings
    FOR r IN (
        SELECT val_id, v.ind_sid, region_sid, period_start_dtm, period_end_dtm, source_type_id, source_id,
               entry_measure_conversion_id, entry_val_number, note,
               v.val_number -- val_converted derives val_number from entry_val_number in case of pct_ownership
          FROM val_converted v
         WHERE source_type_id != csr_data_pkg.SOURCE_TYPE_AGGREGATOR
		   AND v.entry_measure_conversion_id = in_measure_conversion_id
		   AND (in_start_dtm IS NULL OR period_start_dtm >= in_start_dtm)
    )
    LOOP
        Indicator_Pkg.SetValueWithReasonWithSid(
			in_user_sid						=> in_user_sid,
			in_ind_sid						=> r.ind_sid,
			in_region_sid					=> r.region_sid,
			in_period_start					=> r.period_start_dtm,
			in_period_end					=> r.period_end_dtm,
			in_val_number					=> r.val_number,
			in_source_type_id				=> r.source_type_id,
			in_source_id					=> r.source_id,
			in_entry_conversion_id			=> r.entry_measure_conversion_id,
			in_entry_val_number				=> r.entry_val_number,
			in_reason						=> 'Changed measure conversion',
			in_note							=> r.note,
			out_val_id						=> v_val_id);
    END LOOP;

    -- now fix up delegation values
    -- we don't need to use a stored procedure as there are no fancy recalculations needed
    -- TODO: we could speed this up by joining directly to the pct_ownership table rather than calling the ownership function
    FOR r IN (
        SELECT sv.sheet_value_Id, sv.val_number * region_pkg.GetPctOwnership(sv.ind_sid, sv.region_sid, sv.start_dtm) val_number -- val_converted derives val_number from entry_val_number in case of pct_ownership
          FROM sheet_value_converted sv
         WHERE sv.entry_measure_conversion_id = in_measure_conversion_id
           AND (in_start_dtm IS NULL OR start_dtm >= in_start_dtm)
    )
    LOOP
		v_sheet_id := sheet_pkg.GetSheetIdForSheetValueId(r.sheet_value_id);
		IF sheet_pkg.SheetIsReadOnly(v_sheet_id) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied, sheet ' || v_sheet_id || 'is read only');
		END IF;
		
        UPDATE sheet_value
           SET val_number = r.val_number
         WHERE sheet_value_id = r.sheet_value_id; -- we can't use rowid because sheet_value_converted is not key-preseved join
    END LOOP;

    -- pending_val 
    FOR r IN (
        SELECT pv.pending_val_Id, pv.val_number -- ignore pct ownership for now as pending doesn't deal with it* region_pkg.GetPctOwnership(pv.ind_sid, pv.region_sid, pv.start_dtm) val_number -- val_converted derives val_number from entry_val_number in case of pct_ownership
          FROM pending_val_converted pv
         WHERE pv.from_measure_conversion_id = in_measure_conversion_id
           AND (in_start_dtm IS NULL OR start_dtm >= in_start_dtm)
    )
    LOOP
        UPDATE pending_val
           SET val_number = r.val_number
         WHERE pending_val_id = r.pending_val_id; -- we can't use rowid because pending_val_converted is not key-preseved join
    END LOOP;
END;

PROCEDURE DeleteConversion(
    in_act_id     	 	IN  security_pkg.T_ACT_ID,
	in_conversion_id	IN  MEASURE_CONVERSION.MEASURE_CONVERSION_ID%TYPE
)
IS	
	v_measure_sid	measure.measure_sid%TYPE;
	v_description	measure_conversion.description%TYPE;
	v_pct_ownership NUMBER;
BEGIN
	GetMeasureFromConversion(in_conversion_id, v_measure_sid);

	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_measure_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading measure');
	END IF;

	-- update val_change
	FOR r IN (
		SELECT val_change_id, ind_sid, region_sid, period_start_dtm, val_number
		  FROM val_change
		 WHERE entry_measure_conversion_id = in_conversion_id
	) LOOP
		v_pct_ownership := region_pkg.getPctOwnership(r.ind_sid, r.region_sid, r.period_start_dtm);
		
		UPDATE val_change vc
		   SET vc.entry_measure_conversion_id = null, 
			   vc.entry_val_number = ROUND(r.val_number / v_pct_ownership, 10)
		 WHERE vc.val_change_id = r.val_change_id;
	END LOOP;
	
	-- update val, clear out any entered_as fields
	FOR r IN (
		SELECT ind_sid, region_sid, period_start_dtm, val_number, period_end_dtm
		  FROM val
		 WHERE entry_measure_conversion_id = in_conversion_id
	) LOOP
		v_pct_ownership := region_pkg.getPctOwnership(r.ind_sid, r.region_sid, r.period_start_dtm);
		
		UPDATE val v
		   SET v.entry_measure_conversion_id = null, 
			   v.entry_val_number = ROUND(r.val_number / v_pct_ownership, 10)
		 WHERE v.ind_sid = r.ind_sid
		   AND v.region_Sid = r.region_sid
		   AND v.period_start_dtm = r.period_start_dtm
		   AND v.period_end_dtm = r.period_end_dtm;
	END LOOP;
	
	-- update sheet_value_change
	FOR r IN (
		SELECT sheet_value_change_id, svc.ind_sid, svc.region_sid, s.start_dtm, svc.val_number
		  FROM sheet_value_change svc
		  JOIN sheet_value sv on svc.sheet_value_id = sv.sheet_value_id
		  JOIN sheet s on s.sheet_id = sv.sheet_id
		 WHERE svc.entry_measure_conversion_id = in_conversion_id
	) LOOP
		v_pct_ownership := region_pkg.getPctOwnership(r.ind_sid, r.region_sid, r.start_dtm);
		
		UPDATE sheet_value_change svc
		   SET svc.entry_measure_conversion_id = null, 
			   svc.entry_val_number = ROUND(r.val_number / v_pct_ownership, 10)
		 WHERE svc.sheet_value_change_id = r.sheet_value_change_id;
	END LOOP;  
	 
	-- update sheet_value
	FOR r IN (
		SELECT sheet_value_id, sv.ind_sid, sv.region_sid, s.start_dtm, sv.val_number, s.is_read_only, sv.sheet_id
		  FROM sheet_value sv
		  JOIN sheet s on s.sheet_id = sv.sheet_id
		 WHERE entry_measure_conversion_id = in_conversion_id
	) LOOP
		v_pct_ownership := region_pkg.getPctOwnership(r.ind_sid, r.region_sid, r.start_dtm);
		
		IF r.is_read_only > 0 THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied, sheet ' || r.sheet_id || 'is read only');
		END IF;
		
		UPDATE sheet_value sv
		   SET sv.entry_measure_conversion_id = null, 
			   sv.entry_val_number = ROUND(r.val_number / v_pct_ownership, 10)
		 WHERE sv.sheet_value_id = r.sheet_value_id;
	END LOOP;

	-- update sheet_value_hidden_cache
	FOR r IN (
		SELECT sheet_value_id
		  FROM sheet_value_hidden_cache svhc
		 WHERE entry_measure_conversion_id = in_conversion_id
	)
	LOOP
		UPDATE sheet_value_hidden_cache svhc
		   SET svhc.entry_measure_conversion_id = null
		 WHERE svhc.sheet_value_id = r.sheet_value_id;
	END LOOP;
	
	-- Update region_metric_val
	--We're going to have to null off the conversion where referenced
	UPDATE region_metric_val
	   SET entry_measure_conversion_id = null,
	   	   entry_val = val
	 WHERE entry_measure_conversion_id = in_conversion_id;

	UPDATE form_ind_member
	   SET measure_conversion_id = null
	 WHERE measure_conversion_id = in_conversion_id;
	
	UPDATE dataview_ind_member
	   SET measure_conversion_id = null
	 WHERE measure_conversion_id = in_conversion_id;
	
	UPDATE pending_val
	   SET from_measure_conversion_id = null
	 WHERE from_measure_conversion_id = in_conversion_id;
	
	UPDATE quick_survey_answer
	   SET measure_conversion_id = null
	 WHERE measure_conversion_id = in_conversion_id;
	
    UPDATE tpl_report_tag_ind 
       SET measure_conversion_id = NULL
     WHERE measure_conversion_id = in_conversion_id;

	DELETE FROM user_measure_conversion
	 WHERE measure_conversion_id = in_conversion_id;
	
	DELETE FROM measure_conversion_period
	 WHERE measure_conversion_id = in_conversion_id;
	 
	SELECT description
	  INTO v_description
	  FROM measure_conversion
	 WHERE measure_conversion_id = in_conversion_id;
	
	DELETE FROM managed_content_measure_conversion_map
	 WHERE conversion_id = in_conversion_id;
	
	DELETE FROM measure_conversion 
	 WHERE measure_conversion_id = in_conversion_id;
	
	csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, SYS_CONTEXT('SECURITY', 'APP'), v_measure_sid, 'Deleted "{0}"', v_description);
END;

PROCEDURE SetConversion(
    in_act_id     	 		IN  security_pkg.t_act_id,
	in_conversion_id		IN  measure_conversion.measure_conversion_id%TYPE,	   
	in_measure_sid			IN  security_pkg.t_sid_id,
	in_description			IN	measure_conversion.description%TYPE,
	in_a					IN	measure_conversion.a%TYPE,
	in_b					IN	measure_conversion.b%TYPE,
	in_c					IN	measure_conversion.c%TYPE,
	out_conversion_id		OUT	measure_conversion.measure_conversion_id%TYPE
)
IS	
	v_old_a					measure_conversion.a%TYPE;
	v_old_b					measure_conversion.a%TYPE;
	v_old_c					measure_conversion.a%TYPE;
	v_user_sid				security_pkg.T_SID_ID;
	v_description			measure_conversion.description%TYPE;
	v_done					BOOLEAN := FALSE;
BEGIN	
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_measure_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied setting measure');
	END IF;

	IF in_conversion_id IS NOT NULL THEN	
		out_conversion_id := in_conversion_id; -- return what we got in for consistency
	ELSE
		BEGIN
			INSERT INTO measure_conversion
				(measure_conversion_id, measure_sid, description, a, b, c)
			VALUES
				(measure_conversion_id_seq.NEXTVAL, in_measure_sid, in_description, in_a, in_b, in_c)
			RETURNING measure_conversion_id INTO out_conversion_id;
			
			csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, SYS_CONTEXT('SECURITY', 'APP'), in_measure_sid, 'Created "{0}" ({1})', in_description, in_a || ', ' || in_b || ', ' || in_c);
			v_done := TRUE; -- dont' do any more
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				-- we can look it up based on name
				SELECT measure_conversion_id
				  INTO out_conversion_id
				  FROM measure_conversion
				 WHERE LOWER(description) = LOWER(in_description)
				   AND measure_sid = in_measure_sid;
		END;	
	END IF;
		
	IF v_done = FALSE THEN
		-- We only need to check "a" here as due to the check constraint
		-- either a, b and c are all set, or none of them are
		SELECT a, b, c, description
		  INTO v_old_a, v_old_b, v_old_c, v_description
	      FROM measure_conversion
	     WHERE measure_conversion_id = out_conversion_id;
	     
		-- clean up measure conversion period data
		IF (v_old_a IS NULL AND in_a IS NOT NULL) OR (v_old_a IS NOT NULL AND in_a IS NULL) THEN		
			DELETE FROM measure_conversion_period 
			 WHERE measure_conversion_id = out_conversion_id;
		END IF;
		
		UPDATE measure_conversion 
		   SET description = in_description,
			   a = in_a,
			   b = in_b,
			   c = in_c,
			   std_measure_conversion_id = NULL
		 WHERE measure_conversion_id = out_conversion_id;
		
		csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_VALUE, SYS_CONTEXT('SECURITY', 'APP'), in_measure_sid, '"{0}" changed from ({1}) to ({2})', in_description, v_old_a || ', ' || v_old_b || ', ' || v_old_c, in_a || ', ' || in_b || ', ' || in_c);
		
		user_pkg.GetSid(in_act_id, v_user_sid);	 
		ApplyMeasureConversionChange(v_user_sid, out_conversion_id, NULL);
	END IF;
END;

PROCEDURE SetConversion(
    in_act_id     	 				IN  security_pkg.t_act_id,
	in_conversion_id				IN  measure_conversion.measure_conversion_id%TYPE,	   
	in_measure_sid					IN  security_pkg.t_sid_id,
	in_description					IN	measure_conversion.description%TYPE,
	in_std_measure_conversion_id	IN	std_measure_conversion.std_measure_conversion_id%TYPE,
	out_conversion_id				OUT	measure_conversion.measure_conversion_id%TYPE
)
AS
	v_description					measure_conversion.description%TYPE;
	v_a								measure_conversion.a%TYPE;
	v_b								measure_conversion.b%TYPE;
	v_c								measure_conversion.c%TYPE;
	v_old_description				measure_conversion.description%TYPE;
	v_old_a							measure_conversion.a%TYPE;
	v_old_b							measure_conversion.b%TYPE;
	v_old_c							measure_conversion.c%TYPE;
	v_old_std_measure_conv_id		std_measure_conversion.std_measure_conversion_id%TYPE;
	v_user_sid						security_pkg.T_SID_ID;
BEGIN
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_measure_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied setting measure');
	END IF;
	
	SELECT NVL(in_description, smc.description)
	  INTO v_description
	  FROM std_measure_conversion smc
	 WHERE smc.std_measure_conversion_id = in_std_measure_conversion_id;
	
	GetStdMeasureConvOfConv(in_measure_sid, in_std_measure_conversion_id, v_a, v_b, v_c);
	
	IF in_conversion_id IS NULL THEN
		csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, SYS_CONTEXT('SECURITY', 'APP'), in_measure_sid, 'Created "{0}" ({1})', v_description, in_std_measure_conversion_id);
		
		INSERT INTO measure_conversion
			(measure_conversion_id, measure_sid, description, std_measure_conversion_id, a, b, c)
		VALUES
			(measure_conversion_id_seq.NEXTVAL, in_measure_sid, v_description, in_std_measure_conversion_id, v_a, v_b, v_c)
		RETURNING measure_conversion_id INTO out_conversion_id;
	ELSE
		out_conversion_id := in_conversion_id; -- return what we got in for consistency
		
		SELECT a, b, c, description, std_measure_conversion_id
		  INTO v_old_a, v_old_b, v_old_c, v_old_description, v_old_std_measure_conv_id
		  FROM measure_conversion
		 WHERE measure_conversion_id = in_conversion_id;
		
		IF v_old_std_measure_conv_id IS NOT NULL THEN
			v_old_description := v_old_description || ' (' || v_old_std_measure_conv_id || ')';
		END IF;
		
		csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_VALUE, SYS_CONTEXT('SECURITY', 'APP'), in_measure_sid, '"{0}" changed from ({1}) to ({2})', v_description, v_old_description || ', ' || v_old_a || ', ' || v_old_b || ', ' || v_old_c, v_description || ' (' || in_std_measure_conversion_id || ')');
		
		-- std measure conversion period data not supported
		DELETE FROM measure_conversion_period 
		 WHERE measure_conversion_id = in_conversion_id;
		
		UPDATE measure_conversion 
		   SET description = v_description,
				a = v_a, b = v_b, c = v_c,
				std_measure_conversion_id = in_std_measure_conversion_id
		 WHERE measure_conversion_id = in_conversion_id;
		
		user_pkg.GetSid(in_act_id, v_user_sid);
		ApplyMeasureConversionChange(v_user_sid, in_conversion_id, NULL);
	END IF;
END;

/**
 * Return a row set containing info about all measures
 *
 * @param	in_act_id		Access token
 * @param	in_measure_sid	The master measure
 * The rowset is of the fixed form:
 * measure_conversion_id, description, a, b, c
 */
PROCEDURE GetConversions(
    in_act_id       IN  security_pkg.T_ACT_ID,
	in_measure_sid	IN  security_pkg.T_SID_ID,
	out_cur			OUT SYS_REFCURSOR
)
IS
BEGIN
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_measure_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading measure');
	END IF;

	OPEN out_cur FOR
		SELECT measure_conversion_id, description, a, b, c,
			   std_measure_conversion_id
		  FROM measure_conversion 
		 WHERE measure_sid = in_measure_sid
		 ORDER BY description;	 
END;

/*
 * Handy version which takes a sid and a conversion name - helps
 * with quick Excel scripting things.
 */
PROCEDURE SetConversionPeriod(
    in_act_id     	 			IN  security_pkg.T_ACT_ID,
    in_measure_sid              IN  security_pkg.T_SID_ID,
    in_description          	IN	measure_conversion.description%TYPE,
    in_a						IN	measure_conversion.a%TYPE,
    in_b						IN	measure_conversion.b%TYPE,
    in_c						IN	measure_conversion.c%TYPE,
    in_start_dtm				IN	measure_conversion_period.start_dtm%TYPE,
    out_measure_conversion_id   OUT measure_conversion.measure_conversion_id%TYPE
)
IS
BEGIN
    BEGIN
        SELECT measure_conversion_id
          INTO out_measure_conversion_id
          FROM measure_conversion
         WHERE LOWER(description) = LOWER(in_description)
           AND measure_sid = in_measure_sid;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            INSERT INTO measure_conversion 
                (measure_conversion_id, measure_sid, description, a, b, c)
            VALUES
                (measure_conversion_id_seq.NEXTVAL, in_measure_sid, in_description, in_a, in_b, in_c)
            RETURNING measure_conversion_id INTO out_measure_conversion_id;            
    END;
    -- this will do a permission check for us
    SetConversionPeriod(in_act_id, out_measure_conversion_id, in_a, in_b, in_c, in_start_dtm);
END;

PROCEDURE UpdateConversionPeriod(
    in_act_id     	 			IN  security_pkg.T_ACT_ID,
    in_measure_conversion_id	IN	measure_conversion.measure_conversion_id%TYPE,
    in_description          	IN	measure_conversion.description%TYPE,
    in_a						IN	measure_conversion.a%TYPE,
    in_b						IN	measure_conversion.b%TYPE,
    in_c						IN	measure_conversion.c%TYPE,
    in_start_dtm				IN	measure_conversion_period.start_dtm%TYPE
)
IS
BEGIN
	UPDATE measure_conversion
		SET description = in_description
		WHERE measure_conversion_id = in_measure_conversion_id;
    -- this will do a permission check for us
    SetConversionPeriod(in_act_id, in_measure_conversion_id, in_a, in_b, in_c, in_start_dtm);
END;

-- setting to null = delete
PROCEDURE SetConversionPeriod(
    in_act_id     	 			IN  security_pkg.T_ACT_ID,	   
    in_measure_conversion_id	IN	measure_conversion.measure_conversion_id%TYPE,
    in_a						IN	measure_conversion.a%TYPE,
    in_b						IN	measure_conversion.b%TYPE,
    in_c						IN	measure_conversion.c%TYPE,
    in_start_dtm				IN	date
)
IS	    
	CURSOR c_pre IS
	   	SELECT start_dtm, end_dtm, a, b, c
		  FROM measure_conversion_period 
		 WHERE start_dtm <= in_start_dtm
           AND measure_conversion_id = in_measure_conversion_id
         ORDER BY start_dtm desc
           FOR UPDATE;
    r_pre	c_pre%ROWTYPE;
	CURSOR c_post IS
	   	SELECT start_dtm, end_dtm 
		  FROM measure_conversion_period 
		 WHERE start_dtm > in_start_dtm
           AND measure_conversion_id = in_measure_conversion_id
         ORDER BY start_dtm asc
           FOR UPDATE;
    r_post						c_post%ROWTYPE;
    v_count						NUMBER(10);
    v_end_dtm					DATE;
	v_prev_period_start_dtm		DATE;
	v_measure_sid				security_pkg.T_SID_ID;
	v_user_sid					security_pkg.T_SID_ID;
	v_description				measure_conversion.description%TYPE;
BEGIN
	SELECT measure_sid, description
	  INTO v_measure_Sid, v_description
      FROM measure_conversion
     WHERE measure_conversion_id = in_measure_conversion_id;

	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_measure_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading measure');
	END IF;
    
    v_end_dtm := null;
	OPEN c_pre;
   	FETCH c_pre INTO r_pre;
	IF c_pre%FOUND THEN
    	IF r_pre.start_dtm = in_start_dtm THEN
        	DELETE FROM measure_conversion_period
             WHERE CURRENT OF c_pre;
            
            csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, SYS_CONTEXT('SECURITY', 'APP'), v_measure_sid, 'Deleted conversion factor for "{0}" starting from {1}: ({2})', v_description, in_start_dtm, r_pre.a || ', ' || r_pre.b || ', ' || r_pre.c);
        ELSE
	    	UPDATE measure_conversion_period
	           SET end_dtm = in_start_dtm 
	         WHERE CURRENT OF c_pre;
        END IF;
    END IF;
    CLOSE c_pre;
    
	OPEN c_post;
   	FETCH c_post INTO r_post;
	IF c_post%FOUND THEN	
        v_end_dtm := r_post.start_dtm;
    END IF; 
 	CLOSE c_post;
 
    IF in_a IS NULL THEN
		-- Null means delete
		BEGIN
			-- Get the previous periods if it exists
			SELECT start_dtm
			  INTO v_prev_period_start_dtm
			  FROM (
				SELECT start_dtm, rownum rn
				  FROM measure_conversion_period
				 WHERE start_dtm <= in_start_dtm
				   AND measure_conversion_id = in_measure_conversion_id
				 ORDER BY start_dtm DESC
			)
			WHERE rn = 1;
		EXCEPTION 
			WHEN NO_DATA_FOUND THEN NULL;
		END;
		
		-- Update the previous period by extending its end date to include this removed period
    	UPDATE measure_conversion_period
           SET end_dtm = v_end_dtm
         WHERE start_dtm = v_prev_period_start_dtm
           AND measure_conversion_id = in_measure_conversion_id;
        
        SELECT COUNT(*) INTO v_count
          FROM measure_conversion_period
         WHERE measure_conversion_id = in_measure_conversion_id;

        IF v_count = 0 THEN
        	DELETE FROM measure_conversion
             WHERE measure_conversion_id = in_measure_conversion_id;
            
            csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, SYS_CONTEXT('SECURITY', 'APP'), v_measure_sid, 'Deleted "{0}"', v_description);
        END IF;
    ELSE
	    INSERT INTO measure_conversion_period
	    	(measure_conversion_id, start_dtm, end_dtm, a, b, c)
	    VALUES	
	    	(in_measure_conversion_id, in_start_dtm, v_end_dtm, in_a, in_b, in_c);
	    
	    csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, SYS_CONTEXT('SECURITY', 'APP'), v_measure_sid, 'Created conversion factor for "{0}" starting from {1}: ({2})', v_description, in_start_dtm, in_a || ', ' || in_b || ', ' || in_c);

        UPDATE measure_conversion
           SET a = NULL,
           	   b = NULL,
           	   c = NULL
         WHERE measure_conversion_id = in_measure_conversion_id;
    END IF;
  
    user_pkg.GetSid(in_act_id, v_user_Sid);
	ApplyMeasureConversionChange(v_user_sid, in_measure_conversion_id, in_start_dtm);
END;

PROCEDURE GetConversionPeriods(
    in_act_id       			IN  security_pkg.T_ACT_ID,
    in_measure_conversion_id	IN	measure_conversion.measure_conversion_id%TYPE,
	out_cur						OUT SYS_REFCURSOR
)
IS
	v_measure_sid				security_pkg.T_SID_ID;
BEGIN
	GetMeasureFromConversion(in_measure_conversion_id, v_measure_sid);
	
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_measure_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading measure');
	END IF;

	OPEN out_cur FOR
    	SELECT start_dtm, TO_CHAR(start_dtm, 'dd Mon yyyy') start_dtm_fmt,
        	   end_dtm, TO_CHAR(end_dtm-1, 'dd Mon yyyy') end_dtm_fmt,
               a, b, c
          FROM measure_conversion_period
         WHERE measure_conversion_id = in_measure_conversion_id;
END;

PROCEDURE GetMeasureConversionPeriods(
    in_act_id					IN  security_pkg.T_ACT_ID,
    in_measure_conversion_id	IN	measure_conversion.measure_conversion_id%TYPE,
	out_cur						OUT SYS_REFCURSOR
)
IS
	v_total_rows				INTEGER;
BEGIN
	GetMeasureConversionPeriods(
		in_act_id					=> in_act_id,
		in_measure_conversion_id	=> in_measure_conversion_id,
		in_start_row				=> NO_PAGING,
		in_row_count				=> NO_PAGING,
		out_total_rows				=> v_total_rows,
		in_filter_text				=> NULL,
		out_cur						=> out_cur
	);
END;

PROCEDURE GetMeasureConversionPeriods(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_measure_conversion_id	IN	measure_conversion.measure_conversion_id%TYPE,
	in_start_row				IN	INTEGER,
	in_row_count				IN	INTEGER,
	in_order_by					IN	VARCHAR2,
	in_order_dir				IN	VARCHAR2,
	in_filter_text				IN	VARCHAR2,
	out_total_rows				OUT	INTEGER,
	out_cur						OUT SYS_REFCURSOR
)
IS
	v_measure_sid				security_pkg.T_SID_ID;
	v_start_row					INTEGER := NO_PAGING;
	v_in_row_count				INTEGER;
	v_order_by					VARCHAR2(50);
	v_order_dir					VARCHAR2(50);
BEGIN
	v_order_by := NVL(in_order_by, DEFAULT_ORDER_BY);
	v_order_dir := NVL(in_order_dir, DEFAULT_ORDER_DIR);

	utils_pkg.ValidateOrderBy(v_order_by, 'measure_description,description,start_dtm,end_dtm');
	utils_pkg.ValidateOrderBy(v_order_dir, 'ASC,DESC');

	SELECT COUNT(*)
	  INTO out_total_rows
	  FROM csr.measure_conversion 
	  JOIN csr.measure_conversion_period
		ON measure_conversion_period.measure_conversion_id = measure_conversion.measure_conversion_id;

	IF in_start_row >= MIN_ROW_START AND in_row_count >= MIN_PAGE_SIZE THEN
		v_start_row := in_start_row;
		v_in_row_count := in_row_count;
	ELSE
		v_in_row_count := out_total_rows;
		v_start_row := 0;
	END IF;

	IF in_measure_conversion_id > 0 THEN
		GetMeasureFromConversion(in_measure_conversion_id, v_measure_sid);

		-- check permission....
		IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_measure_sid, security_pkg.PERMISSION_READ) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading measure');
		END IF;
	END IF;

	OPEN out_cur FOR
		SELECT *
		  FROM(
			SELECT ROWNUM rn, x.*
			  FROM (
				SELECT measure_conversion.measure_sid, measure_conversion.measure_conversion_id, measure_conversion.description description,
					   measure_conversion_period.start_dtm, TO_CHAR(measure_conversion_period.start_dtm, 'dd Mon yyyy') start_dtm_fmt,
					   measure_conversion_period.end_dtm, TO_CHAR(measure_conversion_period.end_dtm-1, 'dd Mon yyyy') end_dtm_fmt,
					   measure_conversion_period.a, measure_conversion_period.b, measure.description measure_description 
				  FROM csr.measure_conversion
				  JOIN csr.measure_conversion_period
					ON measure_conversion_period.measure_conversion_id = measure_conversion.measure_conversion_id
				  JOIN csr.measure
					ON measure_conversion.measure_sid = measure.measure_sid
				 WHERE ( in_measure_conversion_id <= 0 OR measure_conversion.measure_conversion_id = in_measure_conversion_id )
				   AND ( in_filter_text IS NULL OR LOWER(measure.description) LIKE '%'||in_filter_text||'%'
						OR LOWER(measure_conversion.description) LIKE '%'||in_filter_text||'%')
				 ORDER BY 
					CASE WHEN v_order_dir = 'ASC' THEN
						CASE (LOWER(v_order_by))
							WHEN 'measure_description' THEN measure_description
							WHEN 'description' THEN description
							WHEN 'start_dtm' THEN TO_CHAR(start_dtm, 'YYYYMMDD')
							WHEN 'end_dtm' THEN TO_CHAR(end_dtm, 'YYYYMMDD')
						END
					END ASC,
					CASE WHEN v_order_dir = 'DESC' THEN
						CASE (LOWER(v_order_by))
							WHEN 'measure_description' THEN measure_description
							WHEN 'description' THEN description
							WHEN 'start_dtm' THEN TO_CHAR(start_dtm, 'YYYYMMDD')
							WHEN 'end_dtm' THEN TO_CHAR(end_dtm, 'YYYYMMDD')
						END
					END DESC) x)
		 WHERE rn > v_start_row
		   AND rn <= v_start_row + v_in_row_count;
END;

FUNCTION INTERNAL_GetConversionRefCount(
	in_measure_conversion_id	IN  measure_conversion.measure_conversion_id%TYPE
) RETURN NUMBER
AS
	v_cnt	NUMBER(10);
BEGIN
	SELECT SUM(cnt) cnt 
	  INTO v_cnt
      FROM ( 
		SELECT COUNT(*) cnt 
		  FROM sheet_value sv 
		 WHERE entry_measure_conversion_Id = in_measure_conversion_id
		 UNION 
		SELECT COUNT(*) cnt 
		  FROM val 
		 WHERE entry_measure_conversion_Id = in_measure_conversion_id
		 UNION 
		SELECT COUNT(*) cnt 
		  FROM pending_val 
		 WHERE FROM_MEASURE_CONVERSION_ID = in_measure_conversion_id
		 UNION 
		SELECT COUNT(*) cnt 
		  FROM form_ind_member rim 
		 WHERE rim.measure_conversion_Id = in_measure_conversion_id
         UNION
        SELECT COUNT(*) cnt
          FROM tpl_report_tag_ind trti
         WHERE trti.measure_conversion_id = in_measure_conversion_id
	);
	RETURN v_cnt;
END;

PROCEDURE GetConversionList(
    in_act_id       IN  security_pkg.T_ACT_ID,
	in_measure_sid	IN  security_pkg.T_SID_ID,
	in_order_by		IN	VARCHAR2,
	out_cur			OUT SYS_REFCURSOR
)
IS		
	v_order_by	VARCHAR2(1000);
BEGIN				   		
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_measure_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading measure');
	END IF;

	IF in_order_by IS NOT NULL THEN
		utils_pkg.ValidateOrderBy(in_order_by, 'measure_conversion_id,description,a,b,c,references');
		v_order_by := ' ORDER BY ' || in_order_by;
	END IF;

	OPEN out_cur FOR
		'SELECT measure_conversion_id, description, a, b, c, '||
			  ' measure_pkg.INTERNAL_GetConversionRefCount(measure_conversion_id) references '||
	     ' FROM measure_conversion mc '||
		 'WHERE measure_sid = :measure_sid'||
			v_order_by USING in_measure_sid;		  				 
END;

/* quickly create an option set and bind to a measure */
PROCEDURE SetOptionItems(
	in_act_id			IN  security_pkg.T_ACT_ID,  
	in_measure_sid		IN  security_pkg.T_SID_ID,			
    in_options			IN	VARCHAR2,
    out_option_set_id	OUT	option_set.option_set_id%TYPE
)  
AS		 
    t_options		T_SPLIT_TABLE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_measure_sid, Csr_Data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied altering schema for measure '||in_measure_sid);
	END IF;

	t_options := Utils_Pkg.splitString(in_options,',');
    
    IF in_options IS NULL THEN
	    UPDATE MEASURE 
	       SET OPTION_SET_ID = null
	     WHERE MEASURE_SID = in_measure_sid;     	
   	END IF;

 	INSERT INTO option_set (option_set_id) VALUES (option_set_id_seq.nextval)
      RETURNING option_set_id into out_option_set_id;

    -- insert new items
	INSERT INTO option_item
	   	(option_Set_id, pos, value, description)
	  	SELECT out_option_Set_id,pos, pos, item         
	      FROM TABLE(t_options);
	         
    UPDATE MEASURE 
       SET OPTION_SET_ID = out_option_set_id
     WHERE MEASURE_SID = in_measure_sid; 
END;

PROCEDURE GetOptionItems(
	in_act_id			IN  security_pkg.T_ACT_ID,  
	in_measure_sid		IN  security_pkg.T_SID_ID,			
	out_cur				OUT SYS_REFCURSOR
)
AS
BEGIN	
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_measure_sid, Csr_Data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied altering schema for measure '||in_measure_sid);
	END IF;

	OPEN out_cur FOR
		SELECT oi.option_set_id, oi.value, oi.description 
		  FROM option_item oi, measure m
		 WHERE oi.option_set_id = m.option_set_id
		   AND m.measure_sid = in_measure_sid
		 ORDER BY oi.pos;
END;

PROCEDURE SetTranslation(
	in_measure_sid		IN 	security_pkg.T_SID_ID,
	in_lang				IN	aspen2.tr_pkg.T_LANG,
	in_translated		IN	VARCHAR2
)
AS
	v_act			security_pkg.T_ACT_ID;
	v_description	measure.description%TYPE;
	v_base		 	measure.description%TYPE;
	v_app_sid		security_pkg.T_SID_ID;
BEGIN
	-- XXX: is this the correct permission?
	v_act := security_pkg.GetACT();
	IF NOT Security_pkg.IsAccessAllowedSID(v_act, in_measure_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied updating translations for the measure with sid ' ||in_measure_sid);
	END IF;

	v_description := trim(in_translated);
	IF LENGTH(v_description) > 0 THEN
		-- Get the description (thing to be translated), and application the measure object belongs to
		SELECT m.description, c.app_sid
		  INTO v_base, v_app_sid
		  FROM measure m, customer c
		 WHERE m.measure_sid = in_measure_sid AND c.app_sid = m.app_sid;
		
		-- Update the string by hash
		aspen2.tr_pkg.SetTranslationInsecure(v_app_sid, in_lang, v_base, v_description);
	END IF;
END;

PROCEDURE GetTranslations(
	in_measure_sid		IN 	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
)
AS
	v_act			security_pkg.T_ACT_ID;
	v_description	measure.description%TYPE;
	v_hash			aspen2.tr_pkg.T_HASH;
	v_app_sid		security_pkg.T_SID_ID;
BEGIN
	-- XXX: is this the correct permission?
	v_act := security_pkg.GetACT();
	IF NOT Security_pkg.IsAccessAllowedSID(v_act, in_measure_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied updating translations for the measure with sid ' ||in_measure_sid);
	END IF;
	
	-- Get the description (thing to be translated), and application the measure object belongs to
	SELECT description, app_sid
	  INTO v_description, v_app_sid
	  FROM measure
	 WHERE measure_sid = in_measure_sid;
	
	-- Get the strings by hash
	v_hash := dbms_crypto.hash(utl_raw.cast_to_raw(v_description), dbms_crypto.hash_sh1);
	aspen2.tr_pkg.GetTranslationsOf(v_app_sid, v_hash, out_cur);
END;

PROCEDURE GetStdMeasureConversions(
	out_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	-- No security as this information is public
	OPEN out_cur FOR
		SELECT std_measure_conversion_id, std_measure_id, description, a, b, c, divisible
		  FROM std_measure_conversion
		 ORDER BY std_measure_id, description;
END;

PROCEDURE GetStdMeasureConversion(
	in_std_measure_conversion_id	IN security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- No security as this information is public
	OPEN out_cur FOR
		SELECT smc.std_measure_conversion_id, smc.std_measure_id, smc.description,
			   smc.a, smc.b, smc.c, smc.divisible
		  FROM std_measure_conversion smc
	     WHERE std_measure_conversion_id = in_std_measure_conversion_id;
END;

PROCEDURE GetStdMeasureConversion(
	in_m							IN std_measure.m%TYPE,
	in_kg							IN std_measure.kg%TYPE,
	in_s							IN std_measure.s%TYPE,
	in_a							IN std_measure.a%TYPE,
	in_k							IN std_measure.k%TYPE,
	in_mol							IN std_measure.mol%TYPE,
	in_cd							IN std_measure.cd%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- No security as this information is public
	OPEN out_cur FOR
		SELECT smc.description, smc.std_measure_conversion_id, smc.divisible
		  FROM std_measure_conversion smc
		  JOIN std_measure sm ON smc.std_measure_id = sm.std_measure_id
		 WHERE sm.m = in_m
		   AND sm.kg = in_kg
		   AND sm.s = in_s
		   AND sm.a = in_a
		   AND sm.k = in_k
		   AND sm.mol = in_mol
		   AND sm.cd = in_cd
	  ORDER BY upper(description);
END;

PROCEDURE GetStdMeasureConvOfConv(
	in_measure_sid		IN security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT smc2.std_measure_conversion_id, smc2.description, smc2.divisible
		  FROM measure m
		  JOIN std_measure_conversion smc ON m.std_measure_conversion_id = smc.std_measure_conversion_id
		  JOIN std_measure sm ON smc.std_measure_id = sm.std_measure_id
		  JOIN std_measure_conversion smc2 ON sm.std_measure_id = smc2.std_measure_id
		 WHERE m.measure_sid = in_measure_sid
		   AND smc.std_measure_conversion_id != smc2.std_measure_conversion_id
		   AND (smc.c = smc2.c OR smc2.b = 1) -- other cases not supported
		 ORDER BY description;
END;

PROCEDURE GetStdMeasureConvOfConv(
	in_measure_sid					IN security_pkg.T_SID_ID,
	in_std_measure_conversion_id	IN std_measure_conversion.std_measure_conversion_id%TYPE,
	out_a							OUT measure_conversion.a%TYPE,
	out_b							OUT measure_conversion.b%TYPE,
	out_c							OUT measure_conversion.c%TYPE
)
AS
BEGIN
	SELECT a, b, c
	  INTO out_a, out_b, out_c
	  FROM (
			SELECT POWER(smc.a / smc2.a, 1 / smc2.b) a, smc.b / smc2.b b, 0 c
			  FROM measure m
			  JOIN std_measure_conversion smc ON m.std_measure_conversion_id = smc.std_measure_conversion_id
			  JOIN std_measure sm ON smc.std_measure_id = sm.std_measure_id
			  JOIN std_measure_conversion smc2 ON sm.std_measure_id = smc2.std_measure_id
			 WHERE m.measure_sid = in_measure_sid
			   AND smc.c = smc2.c
			   AND smc2.std_measure_conversion_id = in_std_measure_conversion_id
			 UNION
			SELECT smc.a / smc2.a a, smc.b b, ((smc.c / smc.a) - (smc2.c / smc2.a)) * smc.a c
			  FROM measure m
			  JOIN std_measure_conversion smc ON m.std_measure_conversion_id = smc.std_measure_conversion_id
			  JOIN std_measure sm ON smc.std_measure_id = sm.std_measure_id
			  JOIN std_measure_conversion smc2 ON sm.std_measure_id = smc2.std_measure_id
			 WHERE m.measure_sid = in_measure_sid
			   AND smc2.std_measure_conversion_id = in_std_measure_conversion_id
			   AND smc2.b = 1
	);
	
	-- other cases not supported
END;

PROCEDURE GetOtherStdMeasureConversions(
	out_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	-- No security as this information is public
	OPEN out_cur FOR
		SELECT smc.description, smc.std_measure_conversion_id, smc.divisible
		  FROM std_measure_conversion smc
		  JOIN std_measure sm ON smc.std_measure_id = sm.std_measure_id
		 WHERE NOT (
				(sm.m = 0 AND sm.kg = 0 AND sm.s = 0 AND sm.a = 0 AND sm.k = 0 AND sm.mol = 0 AND sm.cd = 0)
				OR (sm.m = 1 AND sm.kg = 0 AND sm.s = 0 AND sm.a = 0 AND sm.k = 0 AND sm.mol = 0 AND sm.cd = 0)
				OR (sm.m = 2 AND sm.kg = 0 AND sm.s = 0 AND sm.a = 0 AND sm.k = 0 AND sm.mol = 0 AND sm.cd = 0)
				OR (sm.m = 3 AND sm.kg = 0 AND sm.s = 0 AND sm.a = 0 AND sm.k = 0 AND sm.mol = 0 AND sm.cd = 0)
				OR (sm.m = 0 AND sm.kg = 1 AND sm.s = 0 AND sm.a = 0 AND sm.k = 0 AND sm.mol = 0 AND sm.cd = 0)
				OR (sm.m = 2 AND sm.kg = 1 AND sm.s = -2 AND sm.a = 0 AND sm.k = 0 AND sm.mol = 0 AND sm.cd = 0)
				OR (sm.m = 0 AND sm.kg = 0 AND sm.s = 0 AND sm.a = 0 AND sm.k = 0 AND sm.mol = 1 AND sm.cd = 0)
				OR (sm.m = 0 AND sm.kg = 0 AND sm.s = 1 AND sm.a = 0 AND sm.k = 0 AND sm.mol = 0 AND sm.cd = 0)
				OR (sm.m = 0 AND sm.kg = 0 AND sm.s = 0 AND sm.a = 0 AND sm.k = 1 AND sm.mol = 0 AND sm.cd = 0)
		)
		 ORDER BY upper(description);
END;

-- converts between std measures
FUNCTION ConvertValue(
	in_val			IN	NUMBER,
	in_from			IN	vARCHAR2,
	in_to			IN	vARCHAR2
) RETURN csr_data_pkg.T_DOTNET_NUMBER
AS
	v_val					NUMBER;
	v_from_std_measure_id	std_measure.std_measure_id%TYPE;
	v_to_std_measure_id		std_measure.std_measure_id%TYPE;
	v_a						std_measure_conversion.a%TYPE;
	v_b						std_measure_conversion.b%TYPE;
	v_c						std_measure_conversion.c%TYPE;
BEGIN
	BEGIN
		SELECT std_measure_id, a, b, c 
		  INTO v_from_std_measure_id, v_a, v_b, v_c
		  FROM std_measure_conversion
		 WHERE LOWER(description) = LOWER(in_from);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'Unit '||in_from||' not found');
	END;
	
	-- convert to the base 
	v_val := POWER((in_val - v_c) / v_a, 1 / v_b);
	
	BEGIN
		SELECT std_measure_id, a, b, c 
		  INTO v_to_std_measure_id, v_a, v_b, v_c
		  FROM std_measure_conversion
		 WHERE LOWER(description) = LOWER(in_to);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'Unit '||in_to||' not found');
	END;
	
	IF v_from_std_measure_id != v_to_std_measure_id THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'Mixed SI units');
	END IF;
	
	-- 
	
	SELECT CAST((v_a * POWER(v_val, v_b) + v_c) AS NUMBER(24,10))
	INTO v_val
	FROM dual;
	
	-- convert back out
	RETURN v_val;
END;

FUNCTION MeasureConversionsExist
RETURN NUMBER
AS
	v_exist	NUMBER(1);
BEGIN
	SELECT DECODE(COUNT(measure_conversion_id), 0, 0, 1)
	  INTO v_exist
	  FROM measure_conversion
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	RETURN v_exist;
END;

PROCEDURE GetLastUsedMeasureConv(
	in_sheet_id		IN	sheet.sheet_id%TYPE,
	out_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT DISTINCT lumc.measure_sid, lumc.measure_conversion_id
		  FROM sheet s
		  JOIN delegation d ON s.delegation_sid = d.delegation_sid
		  JOIN delegation_ind di ON d.delegation_sid = di.delegation_sid
		  JOIN ind i ON di.ind_sid = i.ind_sid
		  JOIN user_measure_conversion lumc ON i.measure_sid = lumc.measure_sid
		 WHERE s.sheet_id = in_sheet_id
		   AND lumc.csr_user_sid = security_pkg.GetSID;
END;

PROCEDURE GetLastUsedMeasureConv(
	in_ind_sid		IN	security_pkg.T_SID_ID,
	out_id			OUT	measure_conversion.measure_conversion_id%TYPE
)
AS
BEGIN
	BEGIN
		SELECT NVL(lumc.measure_conversion_id, 0)
		  INTO out_id
		  FROM ind i
		  JOIN user_measure_conversion lumc ON i.measure_sid = lumc.measure_sid
		 WHERE i.ind_sid = in_ind_sid
		   AND lumc.csr_user_sid = security_pkg.GetSID;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			out_id := 0;
	END;
END;

PROCEDURE GetUserMeasureConversions(
	in_start_row		IN	NUMBER,
	in_page_size		IN	NUMBER,
	out_total			OUT	NUMBER,
	out_measures_cur	OUT SYS_REFCURSOR,
	out_conversions_cur	OUT SYS_REFCURSOR
)
AS
	v_app_sid	security_pkg.T_SID_ID := SYS_CONTEXT('security', 'app');
	v_table	T_GENERIC_SO_TABLE := T_GENERIC_SO_TABLE();
BEGIN
	-- check permission...
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('security', 'act'), v_app_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied listing measures');
	END IF;

	SELECT COUNT(DISTINCT measure_sid)
	  INTO out_total
	  FROM measure_conversion
	 WHERE app_sid = v_app_sid;

	SELECT T_GENERIC_SO_ROW(sid_id, description, position)
	BULK COLLECT INTO v_table
	  FROM (
			SELECT measure_sid sid_id, description, rownum position
			  FROM (
					SELECT m.measure_sid, m.description
					  FROM measure m
					  JOIN measure_conversion c 
							 ON m.app_sid = c.app_sid
							AND m.measure_sid = c.measure_sid
					 WHERE m.app_sid = v_app_sid
					 GROUP BY m.measure_sid, m.description
					 ORDER BY description
					)
			)
	 WHERE position >= in_start_row
	   AND position < (in_start_row + in_page_size)
	 ORDER BY position;

	-- All measures and user's preferred conversion ID
	OPEN out_measures_cur FOR
		SELECT m.sid_id measure_sid, m.description, l.measure_conversion_id
		  FROM TABLE (v_table) m
		  LEFT JOIN user_measure_conversion l
					 ON l.measure_sid = m.sid_id
					AND l.csr_user_sid = SYS_CONTEXT('security', 'sid')
		 ORDER BY m.position;

	-- All conversions for these measures
	OPEN out_conversions_cur FOR
		SELECT c.measure_sid, c.measure_conversion_id, c.description
		  FROM TABLE (v_table) m
		  JOIN measure_conversion c ON m.sid_id = c.measure_sid
		 ORDER BY c.description;
END;

PROCEDURE SetUserMeasureConversion(
	in_measure_sid		IN security_pkg.T_SID_ID,
	in_conversion_id	IN measure_conversion.measure_conversion_id%TYPE
)
AS
BEGIN
	IF in_conversion_id IS NULL THEN
		DELETE FROM user_measure_conversion
		 WHERE measure_sid  = in_measure_sid
		   AND app_sid = SYS_CONTEXT('security', 'app')
		   AND csr_user_sid = SYS_CONTEXT('security', 'sid');
	ELSE
		BEGIN
			INSERT INTO user_measure_conversion (csr_user_sid, measure_sid, measure_conversion_id)
				VALUES (SYS_CONTEXT('security', 'sid'), in_measure_sid, in_conversion_id);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE user_measure_conversion
				   SET measure_conversion_id = in_conversion_id
				 WHERE app_sid = SYS_CONTEXT('security', 'app')
				   AND csr_user_sid = SYS_CONTEXT('security', 'sid')
				   AND measure_sid = in_measure_sid;
		END;
	END IF;
END;

PROCEDURE GetMeasureConversions(
	out_measure_conv_cur			OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_measure_conv_cur FOR
		SELECT measure_conversion_id, measure_sid, description, a, b, c, std_measure_conversion_id, lookup_key
		  FROM measure_conversion;
END;

PROCEDURE GetStdMeasures(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- No security as this information is public
	OPEN out_cur FOR
		SELECT sm.std_measure_id, sm.description
		  FROM std_measure sm;
END;

END;
/
