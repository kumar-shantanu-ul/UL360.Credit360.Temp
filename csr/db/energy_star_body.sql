
CREATE OR REPLACE PACKAGE BODY CSR.energy_star_pkg IS

FUNCTION AttrsToTable(
	in_names					IN	security_pkg.T_VARCHAR2_ARRAY,
	in_vals						IN	T_VAL_ARRAY,
	in_strs						IN	security_pkg.T_VARCHAR2_ARRAY
) RETURN T_EST_ATTR_TABLE
AS 
	v_table 	T_EST_ATTR_TABLE := T_EST_ATTR_TABLE();
BEGIN
    IF in_names.COUNT = 0 OR (in_names.COUNT = 1 AND in_names(in_names.FIRST) IS NULL) THEN
        -- hack for ODP.NET which doesn't support empty arrays - just return nothing
		RETURN v_table;
    END IF;

	FOR i IN in_names.FIRST .. in_names.LAST
	LOOP
		IF in_names.EXISTS(i) THEN
			v_table.extend;
			v_table(v_table.COUNT) := T_EST_ATTR_ROW(NULL, NULL, in_names(i), in_vals(i), in_strs(i), NULL, NULL, v_table.COUNT );
		END IF;
	END LOOP;
	RETURN v_table;
END;

FUNCTION AttrsToTable(
	in_names					IN	security_pkg.T_VARCHAR2_ARRAY,
	in_vals						IN	T_VAL_ARRAY,
	in_strs						IN	security_pkg.T_VARCHAR2_ARRAY,
	in_dtms						IN	T_DATE_ARRAY,
	in_uoms						IN	security_pkg.T_VARCHAR2_ARRAY
) RETURN T_EST_ATTR_TABLE
AS 
	v_table 	T_EST_ATTR_TABLE := T_EST_ATTR_TABLE();
BEGIN
    IF in_names.COUNT = 0 OR (in_names.COUNT = 1 AND in_names(in_names.FIRST) IS NULL) THEN
        -- hack for ODP.NET which doesn't support empty arrays - just return nothing
		RETURN v_table;
    END IF;

	FOR i IN in_names.FIRST .. in_names.LAST
	LOOP
		IF in_names.EXISTS(i) THEN
			v_table.extend;
			v_table(v_table.COUNT) := T_EST_ATTR_ROW(NULL, NULL, in_names(i), in_vals(i), in_strs(i), in_dtms(i), in_uoms(i), v_table.COUNT );
		END IF;
	END LOOP;
	RETURN v_table;
END;

FUNCTION AttrsToTable(
	in_ids						IN	security_pkg.T_SID_IDS,
	in_region_metric_ids		IN	security_pkg.T_SID_IDS,
	in_names					IN	security_pkg.T_VARCHAR2_ARRAY,
	in_vals						IN	T_VAL_ARRAY,
	in_strs						IN	security_pkg.T_VARCHAR2_ARRAY,
	in_dtms						IN	T_DATE_ARRAY,
	in_uoms						IN	security_pkg.T_VARCHAR2_ARRAY
) RETURN T_EST_ATTR_TABLE
AS 
	v_table 	T_EST_ATTR_TABLE := T_EST_ATTR_TABLE();
BEGIN
    IF in_ids.COUNT = 0 OR (in_ids.COUNT = 1 AND in_ids(in_ids.FIRST) IS NULL) THEN
        -- hack for ODP.NET which doesn't support empty arrays - just return nothing
		RETURN v_table;
    END IF;

	FOR i IN in_ids.FIRST .. in_ids.LAST
	LOOP
		IF in_ids.EXISTS(i) THEN
			v_table.extend;
			v_table(v_table.COUNT) := T_EST_ATTR_ROW(in_ids(i), in_region_metric_ids(i), in_names(i), in_vals(i), in_strs(i), in_dtms(i), in_uoms(i), v_table.COUNT );
		END IF;
	END LOOP;
	RETURN v_table;
END;

PROCEDURE INTERNAL_ClearMissingFlag(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_building.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_building.pm_building_id%TYPE
)
AS
	v_region_sid				security_pkg.T_SID_ID;
BEGIN
	UPDATE est_building
	   SET missing = 0
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND est_account_sid = in_est_account_sid 
	   AND pm_customer_id = in_pm_customer_id
	   AND pm_building_id = in_pm_building_id
	;
END;

PROCEDURE INTERNAL_ClearMissingFlag(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_building.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_building.pm_building_id%TYPE,
    in_pm_meter_id				IN	est_meter.pm_meter_id%TYPE
)
AS
	v_region_sid				security_pkg.T_SID_ID;
BEGIN
	UPDATE est_meter
	   SET missing = 0
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND est_account_sid = in_est_account_sid 
	   AND pm_customer_id = in_pm_customer_id
	   AND pm_building_id = in_pm_building_id
	   AND pm_meter_id = in_pm_meter_id
	;
END;

PROCEDURE INTERNAL_AddMeterError(
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_message					IN	est_error.error_message%TYPE
)
AS
	v_est_account_sid			security_pkg.T_SID_ID;
	v_pm_customer_id			est_error.pm_customer_id%TYPE;
	v_pm_building_id			est_error.pm_building_id%TYPE;
	v_pm_meter_id				est_error.pm_meter_id%TYPE;
BEGIN
	BEGIN
		SELECT est_account_sid, pm_customer_id, pm_building_id, pm_meter_id
		  INTO v_est_account_sid, v_pm_customer_id, v_pm_building_id, v_pm_meter_id
		  FROM est_meter
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND region_sid = in_region_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;

	AddError(
		in_region_sid			=> in_region_sid,
		in_est_account_sid		=> v_est_account_sid,
		in_pm_customer_id		=> v_pm_customer_id,
		in_pm_building_id		=> v_pm_building_id,
		in_pm_meter_id			=> v_pm_meter_id,
		in_error_code			=> ERR_GENERIC_METER,
		in_error_message		=> in_message
	);
END;

PROCEDURE INTERNAL_PrepConsumptionData(
	in_pm_ids					IN	security_pkg.T_SID_IDS,
	in_start_dates				IN	T_DATE_ARRAY,
	in_end_dates				IN	T_DATE_ARRAY,
	in_consumptions				IN	T_VAL_ARRAY,
	in_costs					IN	T_VAL_ARRAY,
	in_estimates				IN	security_pkg.T_SID_IDS,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_ignore_lock				IN	BOOLEAN DEFAULT FALSE
)
AS
	v_lock_end_dtm				DATE;
BEGIN
	DELETE FROM temp_meter_consumptions;
	
	IF in_consumptions.COUNT = 0 OR (in_consumptions.COUNT = 1 AND in_consumptions(in_consumptions.FIRST) IS NULL) THEN
        -- hack for ODP.NET which doesn't support empty arrays
		RETURN;
    END IF;

	SELECT lock_end_dtm
	  INTO v_lock_end_dtm
	  FROM customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	FOR i IN in_consumptions.FIRST .. in_consumptions.LAST
	LOOP
		IF in_consumptions.EXISTS(i) THEN
	
			IF in_ignore_lock = FALSE AND (in_start_dates(i) < v_lock_end_dtm OR in_end_dates(i) < v_lock_end_dtm) THEN
				INTERNAL_AddMeterError(in_region_sid, 'Meter data prior to ' || TO_CHAR(v_lock_end_dtm) || ' cannot be modified due to the system data lock');
				RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_METER_WITHIN_LOCK_PERIOD, 'Meter data prior to ' || TO_CHAR(v_lock_end_dtm) || ' cannot be modified due to the system data lock');
			END IF;
			
			INSERT INTO temp_meter_consumptions
				(id, start_dtm, end_dtm, consumption, cost, is_estimate)
			  VALUES (in_pm_ids(i), in_start_dates(i), in_end_dates(i), in_consumptions(i), in_costs(i), in_estimates(i));
		END IF;
	END LOOP;
END;

PROCEDURE Test_PrepConsumptionData(
	in_pm_ids					IN	security_pkg.T_SID_IDS,
	in_start_dates				IN	T_DATE_ARRAY,
	in_end_dates				IN	T_DATE_ARRAY,
	in_consumptions				IN	T_VAL_ARRAY,
	in_costs					IN	T_VAL_ARRAY,
	in_estimates				IN	security_pkg.T_SID_IDS,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_ignore_lock				IN	BOOLEAN DEFAULT FALSE
)
AS
BEGIN
	INTERNAL_PrepConsumptionData(in_pm_ids, in_start_dates, in_end_dates, in_consumptions, in_costs, in_estimates, in_region_sid, in_ignore_lock);
END;

PROCEDURE INTERNAL_CheckCustomerAccess(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
	in_pm_customer_id			IN	est_customer.pm_customer_id%TYPE,
	in_perms					IN	security_pkg.T_PERMISSION
)
AS
	v_customer_sid				security_pkg.T_SID_ID;
BEGIN
	BEGIN
		SELECT est_customer_sid
		  INTO v_customer_sid
		  FROM est_customer
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND est_account_sid = in_est_account_sid
		   AND pm_customer_id = in_pm_customer_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN   
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on energy star customer '''||in_pm_customer_id||'');
	END;
	
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, v_customer_sid, in_perms) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on energy star customer '''||in_pm_customer_id||''' with sid '||v_customer_sid);
	END IF;
END;

FUNCTION INTERNAL_CheckBuildingError(
	in_region_sid				IN security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
	v_region_sid				security_pkg.T_SID_ID;
BEGIN
	BEGIN
		SELECT region_sid
		  INTO v_region_sid
		  FROM property
		 WHERE region_sid = in_region_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN TRUE; -- ERROR
	END;
	RETURN FALSE; -- No error
END;

PROCEDURE INTERNAL_AddBuildingError(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_building.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_building.pm_building_id%TYPE,
	in_message					IN	est_error.error_message%TYPE
)
AS
	v_region_sid				security_pkg.T_SID_ID;
BEGIN
	BEGIN
		SELECT region_sid
		  INTO v_region_sid
		  FROM est_building
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND est_account_sid = in_est_account_sid
		   AND pm_customer_id = in_pm_customer_id
		   AND pm_building_id = in_pm_building_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;
	
	AddError(
		in_region_sid		=> v_region_sid,
		in_est_account_sid	=> in_est_account_sid,
		in_pm_customer_id	=> in_pm_customer_id,
		in_pm_building_id	=> in_pm_building_id,
		in_error_code		=> ERR_GENERIC_BUILDING,
		in_error_message	=> in_message
	);
END;

-- PROCEDURE UNSEC_AddAccount(
	-- in_user_name				IN	est_account_global.user_name%TYPE,
	-- in_base_url					IN	est_account_global.base_url%TYPE DEFAULT 'https://portfoliomanager.energystar.gov/ws/',
	-- out_account_id				OUT	est_account_global.est_account_id%TYPE
-- )
-- AS
-- BEGIN
	-- INSERT INTO est_account_global
		-- (est_account_id, user_name, base_url)
	  -- VALUES (est_account_id_seq.NEXTVAL, in_user_name, in_base_url);
-- END;

PROCEDURE GetOptions(
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT default_account_sid, default_customer_id, 
			auto_create_prop_type, auto_create_space_type, show_compat_icons,
			trash_when_sharing, trash_when_polling
		  FROM est_options
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE SetOptions(
	in_default_account_sid		IN	est_options.default_account_sid%TYPE,
	in_default_customer_id		IN	est_options.default_customer_id%TYPE,
	in_auto_create_prop_type	IN	est_options.auto_create_prop_type%TYPE,
	in_auto_create_space_type	IN	est_options.auto_create_space_type%TYPE,
	in_show_compat_icons		IN	est_options.show_compat_icons%TYPE,
	in_trash_when_sharing		IN	est_options.trash_when_sharing%TYPE,
	in_trash_when_polling		IN	est_options.trash_when_polling%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, 
		securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, security_pkg.GetApp, 'EnergyStar') , security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on Energy Star securable object');
	END IF;

	BEGIN
		INSERT INTO est_options (default_account_sid, default_customer_id, auto_create_prop_type, auto_create_space_type, show_compat_icons, trash_when_sharing, trash_when_polling)
		VALUES (in_default_account_sid, in_default_customer_id, in_auto_create_prop_type, in_auto_create_space_type, in_show_compat_icons, in_trash_when_sharing, in_trash_when_polling);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE est_options
			   SET default_account_sid = in_default_account_sid,
			       default_customer_id = in_default_customer_id,
			       auto_create_prop_type = in_auto_create_prop_type,
			       auto_create_space_type = in_auto_create_space_type,
			       show_compat_icons = in_show_compat_icons,
			       trash_when_sharing = in_trash_when_sharing,
			       trash_when_polling = in_trash_when_polling
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	END;
END;

-- Map an account to the logged on app
PROCEDURE MapAccount(
	in_account_id				IN	est_account_global.est_account_id%TYPE,
	out_account_Sid				OUT	security_pkg.T_SID_ID
)
AS
	v_esfolder_sid				security_pkg.T_SID_ID;
	v_user_name					VARCHAR2(255) := 'credit360_energystar';
BEGIN
	v_esfolder_sid := securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, security_pkg.GetApp, 'EnergyStar');
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, v_esfolder_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing account to EnergyStar folder');
	END IF;

	
	-- Create securable object for energy star account
	BEGIN
		SecurableObject_Pkg.CreateSO(
			security_pkg.GetACT, 
			v_esfolder_sid, 
			class_pkg.getClassID('EnergyStarAccount'), 
			SUBSTR(REPLACE(v_user_name,'/','\\'), 0, 255), 
			out_account_sid
		);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			out_account_sid := security.securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, v_esfolder_sid, SUBSTR(REPLACE(v_user_name,'/','\\'), 0, 255));
	END;

	BEGIN
		INSERT INTO est_account (est_account_sid, est_account_id)
		     VALUES (out_account_sid, in_account_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

PROCEDURE GetAccounts(
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN	
	OPEN out_cur FOR
		SELECT est_account_sid, account_customer_id, auto_map_customer, 
			   allow_delete, share_job_interval, last_share_job_dtm, 
			   building_job_interval, meter_job_interval, est_account_id
		  FROM v$est_account
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), est_account_sid, security_pkg.PERMISSION_READ) = 1;
END;

PROCEDURE GetAccount(
	in_account_sid				IN	security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_account_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading account with sid '||in_account_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT est_account_sid, account_customer_id, auto_map_customer, 
			   allow_delete, share_job_interval, last_share_job_dtm, 
			   building_job_interval, meter_job_interval, est_account_id
		  FROM v$est_account
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND est_account_sid = in_account_sid;
END;

PROCEDURE GetCustomer(
	in_account_sid				IN	security_pkg.T_SID_ID,	
	in_pm_customer_id			IN	est_customer.pm_customer_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	INTERNAL_CheckCustomerAccess(in_account_sid, in_pm_customer_id, security_pkg.PERMISSION_READ);
	
	OPEN out_cur FOR
		SELECT est_account_sid, pm_customer_id, est_customer_sid, org_name, email
		  FROM est_customer
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND est_account_sid = in_account_sid
		   AND pm_customer_id = in_pm_customer_id;
END;

-- Get the customers associated with this app/account
PROCEDURE GetCustomers(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_est_account_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on energy star account with sid '||in_est_account_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT est_account_sid, pm_customer_id, est_customer_sid, org_name, email
		  FROM est_customer
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND est_account_sid = in_est_account_sid;
END;

PROCEDURE UNSEC_GetAllCustomers(
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT est_account_sid, pm_customer_id, est_customer_sid, org_name, email
		  FROM est_customer
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE UNSEC_GetUnmappedCustomers(
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT g.pm_customer_id, g.org_name, g.email
		  FROM est_customer_global g
		 WHERE NOT EXISTS (
		 	SELECT 1
		 	  FROM est_customer c
		 	 WHERE c.pm_customer_id = g.pm_customer_id
		 );
END;

PROCEDURE UNSEC_SetCustomer(
	in_pm_customer_id			IN	est_customer_global.pm_customer_id%TYPE,
	in_org_name					IN	est_customer_global.org_name%TYPE,
	in_email					IN	est_customer_global.email%TYPE
)
AS
BEGIN
	-- Attempt an update of already mapped customer
	UPDATE est_customer
	   SET org_name = in_org_name,
	       email = in_email
	 WHERE pm_customer_id = in_pm_customer_id;

	-- If there was no mapped row to update then insert/update on the global table
	IF SQL%ROWCOUNT = 0 THEN
		BEGIN
			-- Try to insert the customer
			INSERT INTO est_customer_global
				(pm_customer_id, org_name, email)
			  VALUES (in_pm_customer_id, in_org_name, in_email); 
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				-- Customer exists, update
				UPDATE est_customer_global
				   SET org_name = in_org_name,
				   	   email = in_email
				 WHERE pm_customer_id = in_pm_customer_id;
		END;
	END IF;
END;

PROCEDURE SetCustomer(
	in_pm_customer_id			IN	est_customer_global.pm_customer_id%TYPE,
	in_org_name					IN	est_customer_global.org_name%TYPE,
	in_email					IN	est_customer_global.email%TYPE
)
AS
BEGIN
	IF security.user_pkg.IsSuperAdmin != 1 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only available to superadmins');
	END IF;

	UNSEC_SetCustomer(
		in_pm_customer_id		=> in_pm_customer_id,
		in_org_name				=> in_org_name,
		in_email				=> in_email
	);
END;
	
PROCEDURE INTERNAL_SetOtherValue(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
	in_mapping_name				IN	est_other_mapping.mapping_name%TYPE,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_dtm						IN	DATE,
	in_val						IN	NUMBER,
	in_str						IN	VARCHAR2
)
AS
	v_val_id					val.val_id%TYPE;
BEGIN	
	FOR r IN (
		SELECT om.ind_sid, om.measure_conversion_id, om.helper
		  FROM est_other_mapping om
		 WHERE om.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND om.est_account_sid = in_est_account_sid
		   AND om.mapping_name = in_mapping_name
		   AND om.ind_sid IS NOT NULL
	) LOOP 
		IF r.helper IS NOT NULL THEN
			-- Call the helper procedure
			EXECUTE IMMEDIATE 'BEGIN '||r.helper||'(:1,:2,:3,:4,:5,:6,:7,:8);END;'
				USING in_est_account_sid, in_mapping_name, in_region_sid, r.ind_sid, r.measure_conversion_id, in_dtm, in_val, in_str;
		ELSE
			IF in_val IS NOT NULL OR in_str IS NOT NULL THEN
				-- This will ensure the region metric is set-up correctly
				region_metric_pkg.SetMetric(r.ind_sid);
				-- Set the region metric 
				-- TOOD: Check if the value changed!
				region_metric_pkg.SetMetricValue(
					in_region_sid,
					r.ind_sid,
					in_dtm,
					in_val,
					NULL,
					NULL,
					r.measure_conversion_id,
					csr_data_pkg.SOURCE_TYPE_ENERGY_STAR,
					v_val_id
				);
				
				-- TOTO: Store region metric val id somewhere!?
				
			END IF;
		END IF;
	END LOOP;
END;
	

PROCEDURE MapCustomer(
	in_account_sid				IN	security_pkg.T_SID_ID,
	in_pm_customer_id			IN	est_customer.pm_customer_id%TYPE,
	out_customer_sid			OUT	security_pkg.T_SID_ID
)
AS
	v_org_name					est_customer_global.org_name%TYPE;
	v_email						est_customer_global.email%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_account_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing account with sid '||in_account_sid);
	END IF;
	
	BEGIN
		SELECT est_customer_sid, org_name, email
		  INTO out_customer_sid, v_org_name, v_email
		  FROM est_customer
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND est_account_sid = in_account_sid
		   AND pm_customer_id = in_pm_customer_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			SELECT org_name, email
			  INTO v_org_name, v_email
			  FROM est_customer_global
			 WHERE pm_customer_id = in_pm_customer_id;
			 out_customer_sid := NULL;
	END;
	
	-- Already mapped if sid is set
	IF out_customer_sid IS NOT NULL THEN
		RETURN;
	END IF;
	
	-- Create a new customer object
	SecurableObject_Pkg.CreateSO(
		security_pkg.GetACT, 
		in_account_sid, 
		class_pkg.getClassID('EnergyStarCustomer'), 
		SUBSTR(REPLACE(in_pm_customer_id,'/','\'), 0, 255),
		out_customer_sid
	);
	
	-- Insert the customer entry for this app/account
	INSERT INTO est_customer (est_account_sid, pm_customer_id, est_customer_sid, org_name, email)
	VALUES (in_account_sid, in_pm_customer_id, out_customer_sid, v_org_name, v_email);
	
	-- Clear the customer record from the est_customer_global table, as it has been mapped
	DELETE FROM est_customer_global WHERE pm_customer_id = in_pm_customer_id;
END;

PROCEDURE UnmapCustomer(
	in_account_sid				IN	security_pkg.T_SID_ID,
	in_pm_customer_id			IN	est_customer.pm_customer_id%TYPE,
	out_customer_sid			OUT	security_pkg.T_SID_ID
)
AS
	v_org_name					est_customer_global.org_name%TYPE;
	v_email						est_customer_global.email%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_account_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing account with sid '||in_account_sid);
	END IF;

	BEGIN
		SELECT est_customer_sid, org_name, email
		  INTO out_customer_sid, v_org_name, v_email
		  FROM est_customer
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND est_account_sid = in_account_sid
		   AND pm_customer_id = in_pm_customer_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Unable to find energy star customer details for the customer_id and account_sid provided.');
	END;

	-- Already mapped if sid is set, delete the so and insert the customer record back to global
	IF out_customer_sid IS NOT NULL THEN
		-- Create a new customer object
		SecurableObject_Pkg.DeleteSO(
			security_pkg.GetACT, 
			out_customer_sid
		);

		INSERT INTO est_customer_global (pm_customer_id, org_name, email)
		VALUES (in_pm_customer_id, v_org_name, v_email);
	END IF;

END;

PROCEDURE INTERNAL_UpdateBuildingMetrics(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_building.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_building.pm_building_id%TYPE,
    in_region_sid				IN	security_pkg.T_SID_ID,
    in_read_only				IN	NUMBER
)
AS
	v_current_rm_dtm			region_Metric_val.effective_dtm%TYPE;
	v_current_rm_val			region_metric_val.val%TYPE;
	v_current_rm_note			region_metric_val.note%TYPE;
	v_val_id					csr.val.val_id%TYPE;
	v_update					BOOLEAN;
BEGIN
	FOR i IN (
		SELECT map.ind_sid, map.measure_conversion_id, map.divisor, map.metric_name, map.uom, map.read_only
		  FROM est_building_metric_mapping map
		 WHERE map.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND map.est_account_sid = in_est_account_sid
		   AND map.read_only = DECODE(in_read_only, 0, map.read_only, 1)
		   AND EXISTS (
		   		SELECT 1
		   		  FROM est_building_metric bm
		   		 WHERE bm.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   	   AND bm.est_account_sid = in_est_account_sid
			   	   AND bm.pm_customer_id = in_pm_customer_id
			   	   AND bm.pm_building_id = in_pm_building_id
			   	   AND bm.metric_name = map.metric_name
			   	   -- Grr - Energy Star don't always provide the uom with the computed metrics 
			   	   -- so we don't bother to store it, this causes the mappings not to match.
			   	   -- We can safely ignore the UOM in the mapping for the read-only metrics
			   	   -- as we only ever request (and therefore map) them in one uom 
			   	   -- (the using the metric rahter than imperial system).
		   		   AND DECODE(map.read_only, 1, map.uom, NVL(bm.uom, '<null>')) = map.uom
		   )
	) LOOP
		-- This will ensure the region metric is set-up correctly
		region_metric_pkg.SetMetric(i.ind_sid);

		-- Delete any region metric vlaues no longer 
		-- present in the est_building_metric table
		FOR r IN (
			SELECT v.region_metric_val_id
			  FROM region_metric_val v
			 WHERE v.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND v.region_sid = in_region_sid
			   AND v.ind_sid = i.ind_sid
			   AND NOT EXISTS (
			   		SELECT 1
			   		  FROM est_building_metric bm
			   		 WHERE bm.app_sid = SYS_CONTEXT('SECURITY', 'APP')
					   AND bm.est_account_sid = in_est_account_sid
					   AND bm.pm_customer_id = in_pm_customer_id
					   AND bm.pm_building_id = in_pm_building_id
					   AND bm.metric_name = i.metric_name
					   AND DECODE(i.read_only, 1, i.uom, NVL(bm.uom, '<null>')) = i.uom
					   AND (bm.val IS NOT NULL OR bm.str IS NOT NULL)
					   AND bm.period_end_dtm = v.effective_dtm
			   )
			   	ORDER BY v.effective_dtm
		) LOOP
			region_metric_pkg.DeleteMetricValue(r.region_metric_val_id);
		END LOOP;
		
		FOR r IN (
			SELECT bm.period_end_dtm, bm.str,
				bm.val / i.divisor val -- Divide value by divisor (useful for dealing with energy star percentages etc.)
			  FROM est_building_metric bm
			 WHERE bm.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND bm.est_account_sid = in_est_account_sid
			   AND bm.pm_customer_id = in_pm_customer_id
			   AND bm.pm_building_id = in_pm_building_id
			   AND bm.metric_name = i.metric_name
			   AND DECODE(i.read_only, 1, i.uom, NVL(bm.uom, '<null>')) = i.uom
			   -- These are computed values in ES and can be null either at the beginning or in later months if there's 
			   -- not enough overlappping source data for ES to compute them, there shouldn't be any null data within 
			   -- the valid data range, for this reason we're going to ignore null values when writing the region metrics.
			   AND (bm.val IS NOT NULL OR bm.str IS NOT NULL)
		) LOOP
			BEGIN
				-- Get the current region metric value
				SELECT effective_dtm, val, note
				  INTO v_current_rm_dtm, v_current_rm_val, v_current_rm_note
				  FROM region_metric_val
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND ind_sid = i.ind_sid
				   AND region_sid = in_region_sid
				   AND effective_dtm = r.period_end_dtm;
				
				-- Check to see if we need to update the existing value
				v_update := FALSE;
				IF TRUNC(v_current_rm_dtm, 'MONTH') != TRUNC(r.period_end_dtm, 'MONTH') THEN
					-- Dates differ
					v_update := TRUE;
				ELSE
					-- Test val
					v_update := CASE
						WHEN v_current_rm_val IS NULL THEN TRUE
						WHEN v_current_rm_val != r.val THEN TRUE
						-- Equal
						ELSE FALSE
					END;
					
					IF NOT v_update THEN
						-- No change in val, test note
						v_update := CASE
							WHEN r.str IS NULL THEN FALSE
							WHEN v_current_rm_note IS NULL THEN TRUE
							WHEN v_current_rm_note != r.str THEN TRUE
							-- Equal
							ELSE FALSE
						END;
					END IF;
				END IF;
			
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					-- New value (no current region metric value)
					v_update := TRUE;
			END;
				
			-- Set the region metric if required
			IF v_update THEN
				region_metric_pkg.SetMetricValue(
					in_region_sid,
					i.ind_sid,
					r.period_end_dtm,
					r.val,
					r.str,
					NULL,
					i.measure_conversion_id,
					csr_data_pkg.SOURCE_TYPE_ENERGY_STAR,
					v_val_id
				);
			END IF;
			
		END lOOP;
	END LOOP;
END;

PROCEDURE INTERNAL_UpdateBuildingRegion(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_building.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_building.pm_building_id%TYPE,
    in_region_sid				IN	security_pkg.T_SID_ID
)
AS
	v_year_built				est_building.year_built%TYPE;
	v_start_dtm					DATE;
	v_auto_prop_type			est_options.auto_create_prop_type%TYPE;
	v_primary_function			est_building.primary_function%TYPE;
	v_prop_type_id				property.property_type_id%TYPE;
BEGIN	

	-- Get some building info
	SELECT year_built, TRUNC(TO_DATE(year_built, 'YYYY'), 'YEAR')
	  INTO v_year_built, v_start_dtm
	  FROM est_building	
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND est_account_sid = in_est_account_sid
	   AND pm_customer_id = in_pm_customer_id
	   AND pm_building_id = in_pm_building_id;

	-- Update the property table
	BEGIN
		UPDATE property SET (street_addr_1, street_addr_2, city, state, postcode) = (
			SELECT NVL(b.address, p.street_addr_1), NVL(b.address2, p.street_addr_2), NVL(b.city, p.city), NVL(b.state, p.state), NVL(b.zip_code, p.postcode)
			  FROM est_building b, property p
			 WHERE b.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND b.region_sid = in_region_sid
			   AND p.region_sid = b.region_sid
		) WHERE region_sid = in_region_sid;
	EXCEPTION
		-- XXX: We can get multiple rows where the region sid
		-- has been mapped to more than one property.
		WHEN SUBQUERY_CARDINALITY THEN
			INTERNAL_AddBuildingError(
				in_est_account_sid,
				in_pm_customer_id,
				in_pm_building_id,
				'More than one Energy Star building has been mapped to the same region (region sid = '||in_region_sid||').'	
			);
			RETURN;
	END;
	
	-- Check to see if we need to create the property type
	SELECT auto_create_prop_type
	  INTO v_auto_prop_type
	  FROM est_options
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	 
	IF v_auto_prop_type != 0 THEN
		SELECT b.primary_function, m.property_type_id
		  INTO v_primary_function, v_prop_type_id
		  FROM est_building b
		  LEFT JOIN est_property_type_map m ON m.app_sid = b.app_sid AND m.est_property_type = b.primary_function
		 WHERE b.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND b.region_sid = in_region_sid;
		
		-- If it's not mapped then create it and map it
		IF v_prop_type_id IS NULL THEN
			-- create
			property_pkg.SavePropertyType(
				NULL,
				v_primary_function,
				'',
				NULL,
				v_prop_type_id
			);
			-- map
			INSERT INTO est_property_type_map 
				(property_type_id, est_property_type)
			VALUES (v_prop_type_id, v_primary_function);
		END IF;
	END IF;
	
	-- Set/update the property type if mapped
	FOR r IN (
		SELECT m.property_type_id
		  FROM est_building b
		  JOIN est_property_type_map m ON m.app_sid = b.app_sid AND m.est_property_type = b.primary_function
		 WHERE b.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND b.region_sid = in_region_sid
	) LOOP
		-- SetPropertyType will not change the property sub-type (to null) unless the property type has actually changed
		property_pkg.SetPropertyType(
			in_region_sid	=>	in_region_sid,
			in_prop_type_id	=>	r.property_type_id
		);
	END LOOP;
	
	-- Set the year built (it's in an indicator)
	INTERNAL_SetOtherValue(
		in_est_account_sid, 
		'yearBuilt',
		in_region_sid,
		v_start_dtm,
		v_year_built,
		NULL
	);
END;

PROCEDURE GetBuilding (
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_building.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_building.pm_building_id%TYPE,
    out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	INTERNAL_CheckCustomerAccess(in_est_account_sid, in_pm_customer_id, security_pkg.PERMISSION_READ);
	
	OPEN out_cur FOR
		SELECT b.est_account_sid, b.pm_customer_id, b.pm_building_id, b.region_sid,
			b.building_name, b.address, b.address2, b.city, b.state, b.other_state, b.zip_code, b.zip_code_ext, b.country,
			b.year_built, primary_function, construction_status, notes,
			federal_owner, federal_agency, federal_agency_region, federal_campus,
			b.import_dtm, last_poll_dtm, last_job_dtm, b.write_access, b.source_pm_customer_id, b.ignored
		  FROM est_building b
		 WHERE b.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND b.est_account_sid = in_est_account_sid 
		   AND b.pm_customer_id = in_pm_customer_id
		   AND b.pm_building_id = in_pm_building_id;
END;

PROCEDURE GetBuildingMetrics(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_building.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_building.pm_building_id%TYPE,
    out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	INTERNAL_CheckCustomerAccess(in_est_account_sid, in_pm_customer_id, security_pkg.PERMISSION_READ);
	
	OPEN out_cur FOR
		SELECT est_account_sid, pm_customer_id, pm_building_id, metric_name, period_end_dtm, val, str, uom
		  FROM est_building_metric
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND est_account_sid = in_est_account_sid 
		   AND pm_customer_id = in_pm_customer_id
		   AND pm_building_id = in_pm_building_id;
END;

PROCEDURE GetBuildingAndMetrics (
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_building.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_building.pm_building_id%TYPE,
    out_building				OUT	security_pkg.T_OUTPUT_CUR,
    out_metrics					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetBuilding(
		in_est_account_sid,
    	in_pm_customer_id,
    	in_pm_building_id,
    	out_building
	);
	GetBuildingMetrics(
		in_est_account_sid,
    	in_pm_customer_id,
    	in_pm_building_id,
    	out_metrics
	);	
END;

PROCEDURE INTERNAL_UpdateCustomerId(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_building.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_building.pm_building_id%TYPE
)
AS
BEGIN
	
	FOR b IN (
		SELECT pm_customer_id old_customer_id
		  FROM est_building
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND est_account_sid = in_est_account_sid 
		   AND pm_customer_id != in_pm_customer_id
		   AND pm_building_id = in_pm_building_id
	) LOOP
		UPDATE est_space
		   SET pm_customer_id = in_pm_customer_id
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND est_account_sid = in_est_account_sid 
		   AND pm_customer_id = b.old_customer_id
		   AND pm_building_id = in_pm_building_id;
		   
		UPDATE est_meter
		   SET pm_customer_id = in_pm_customer_id
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND est_account_sid = in_est_account_sid 
		   AND pm_customer_id = b.old_customer_id
		   AND pm_building_id = in_pm_building_id;
		
		UPDATE est_building_metric
		   SET pm_customer_id = in_pm_customer_id
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND est_account_sid = in_est_account_sid 
		   AND pm_customer_id = b.old_customer_id
		   AND pm_building_id = in_pm_building_id;
		   
		UPDATE est_space_attr
		   SET pm_customer_id = in_pm_customer_id
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND est_account_sid = in_est_account_sid 
		   AND pm_customer_id = b.old_customer_id
		   AND pm_building_id = in_pm_building_id;
		    
		UPDATE est_building
		   SET pm_customer_id = in_pm_customer_id
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND est_account_sid = in_est_account_sid 
		   AND pm_customer_id = b.old_customer_id
		   AND pm_building_id = in_pm_building_id;
		   
		UPDATE est_error
		   SET pm_customer_id = in_pm_customer_id
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND est_account_sid = in_est_account_sid 
		   AND pm_customer_id = b.old_customer_id
		   AND pm_building_id = in_pm_building_id;
	END LOOP;
END;

PROCEDURE SetBuilding(
    in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_building.pm_customer_id%TYPE,
    in_source_pm_customer_id	IN	est_building.source_pm_customer_id%TYPE,
    in_pm_building_id			IN	est_building.pm_building_id%TYPE,
    in_region_sid				IN	security_pkg.T_SID_ID,
    in_building_name			IN	est_building.building_name%TYPE,
    in_address					IN	est_building.address%TYPE,
    in_address2					IN	est_building.address2%TYPE,
    in_city						IN	est_building.city%TYPE,
    in_state					IN	est_building.state%TYPE,
    in_zip_code					IN	est_building.zip_code%TYPE,
    in_country					IN	est_building.country%TYPE,
    in_year_built				IN	est_building.year_built%TYPE,
    in_primary_function			IN	est_building.primary_function%TYPE,
    in_construction_status		IN	est_building.construction_status%TYPE,
    in_notes					IN	est_building.notes%TYPE,
    in_write_access				IN	est_building.write_access%TYPE,
    -- Federap property
    in_is_federal_property		IN	est_building.is_federal_property%TYPE,
    in_federal_owner			IN	est_building.federal_owner%TYPE,
    in_federal_agency			IN	est_building.federal_agency%TYPE,
    in_federal_agency_region	IN	est_building.federal_agency_region%TYPE,
    in_federal_campus			IN	est_building.federal_campus%TYPE,
	-- Building metrics
	in_metric_names				IN	security_pkg.T_VARCHAR2_ARRAY,
	in_metric_vals				IN	T_VAL_ARRAY,
	in_metric_strs				IN	security_pkg.T_VARCHAR2_ARRAY,
	in_metric_end_dtms			IN	T_DATE_ARRAY,
	in_metric_uoms				IN	security_pkg.T_VARCHAR2_ARRAY
)
AS
BEGIN
	
	INTERNAL_CheckCustomerAccess(in_est_account_sid, in_pm_customer_id, security_pkg.PERMISSION_WRITE);
	
	-- If building exists but not for the given customer then 
	-- switch the customer id (nasty new Energy Star behaviouor)!
	INTERNAL_UpdateCustomerId(in_est_account_sid, in_pm_customer_id, in_pm_building_id);
	
	BEGIN
		INSERT INTO est_building
			(est_account_sid, pm_customer_id, pm_building_id, region_sid, 
				building_name, address, address2, city, state, zip_code, country, 
				year_built, primary_function, construction_status, notes, write_access,
				is_federal_property, federal_owner, federal_agency, federal_agency_region, federal_campus,
				source_pm_customer_id)
		  VALUES (in_est_account_sid, in_pm_customer_id, in_pm_building_id, in_region_sid,
		  			in_building_name,  in_address, in_address2, in_city, in_state, in_zip_code, in_country, 
					in_year_built, in_primary_function, in_construction_status, in_notes, in_write_access,
					in_is_federal_property, in_federal_owner, in_federal_agency, in_federal_agency_region, in_federal_campus,
					in_source_pm_customer_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE est_building
			   SET region_sid = NVL(in_region_sid, region_sid),
			   	   building_name = in_building_name, 
				   address = in_address, 
				   city = in_city, 
				   state = in_state, 
				   zip_code = in_zip_code, 
				   country = in_country,
				   year_built = in_year_built,
				   primary_function = in_primary_function,
				   construction_status = in_construction_status,
				   notes = in_notes,
				   write_access = in_write_access,
				   is_federal_property = in_is_federal_property,
				   federal_owner = in_federal_owner,
				   federal_agency= in_federal_agency,
				   federal_agency_region = in_federal_agency_region,
				   federal_campus = in_federal_campus,
				   source_pm_customer_id = NVL(in_source_pm_customer_id, source_pm_customer_id),
				   missing = 0
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND est_account_sid = in_est_account_sid 
			   AND pm_customer_id = in_pm_customer_id
			   AND pm_building_id = in_pm_building_id
			;
	END;

	-- Try and update the property table
	IF in_region_sid IS NOT NULL AND in_pm_building_id IS NOT NULL THEN
		UPDATE property
		   SET pm_building_id = in_pm_building_id
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND region_sid = in_region_sid;
	END IF;
	
	-- Building metrics
	SetBuildingMetrics(
		in_est_account_sid,
	    in_pm_customer_id,
	    in_pm_building_id,
		in_metric_names,
		in_metric_vals,
		in_metric_strs,
		in_metric_end_dtms,
		in_metric_uoms
	);
	
END;

PROCEDURE INTERNAL_UpsertMetricVal(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_building.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_building.pm_building_id%TYPE,
	in_metric_name				IN	est_building_metric.metric_name%TYPE,
	in_metric_end_dtm			IN	est_building_metric.period_end_dtm%TYPE,
	in_metric_val				IN	est_building_metric.val%TYPE,
	in_metric_str				IN	est_building_metric.str%TYPE,
	in_metric_uom				IN	est_building_metric.uom%TYPE
)
AS
BEGIN
	BEGIN
		INSERT INTO est_building_metric
			(est_account_sid, pm_customer_id, pm_building_id, metric_name, period_end_dtm, val, str, uom)
		  VALUES (in_est_account_sid, in_pm_customer_id, in_pm_building_id, in_metric_name, in_metric_end_dtm, in_metric_val, in_metric_str, in_metric_uom);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE est_building_metric
			   SET val = in_metric_val,
			       str = in_metric_str,
			       uom = in_metric_uom
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND est_account_sid = in_est_account_sid 
			   AND pm_customer_id = in_pm_customer_id
			   AND pm_building_id = in_pm_building_id
			   AND metric_name = in_metric_name
			   AND period_end_dtm = in_metric_end_dtm;
	END;
END;

PROCEDURE SetBuildingMetrics(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_building.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_building.pm_building_id%TYPE,
	in_metric_names				IN	security_pkg.T_VARCHAR2_ARRAY,
	in_metric_vals				IN	T_VAL_ARRAY,
	in_metric_strs				IN	security_pkg.T_VARCHAR2_ARRAY,
	in_metric_end_dtms			IN	T_DATE_ARRAY,
	in_metric_uoms				IN	security_pkg.T_VARCHAR2_ARRAY
)
AS
	v_region_sid				security_pkg.T_SID_ID;
	v_year_built				est_building.year_built%TYPE;
	t_metrics					T_EST_ATTR_TABLE;
	v_energy_star_push			property.energy_star_push%TYPE;
BEGIN
	
	SELECT year_built
	  INTO v_year_built
	  FROM est_building
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND est_account_sid = in_est_account_sid 
	   AND pm_customer_id = in_pm_customer_id
	   AND pm_building_id = in_pm_building_id;
	
	-- Building metrics
	t_metrics := AttrsToTable(
		in_metric_names,
		in_metric_vals,
		in_metric_strs,
		in_metric_end_dtms,
		in_metric_uoms
	);
	
	FOR r IN (
		SELECT name, val, str, dtm, uom
		  FROM TABLE(t_metrics)
		 		ORDER BY pos
	) LOOP
		-- Upsert the metric value, null date means use current month
		INTERNAL_UpsertMetricVal(
			in_est_account_sid,
			in_pm_customer_id,
			in_pm_building_id,
			r.name,
			NVL(r.dtm, TRUNC(SYSDATE, 'MONTH')),
			r.val,
			r.str, 
			r.uom
		);
		
		-- If the date is null and the year built is available 
		-- then also add an entry for 1 Jan for that year
		IF r.dtm IS NULL AND v_year_built IS NOT NULL THEN
			INTERNAL_UpsertMetricVal(
				in_est_account_sid,
				in_pm_customer_id,
				in_pm_building_id,
				r.name,
				TRUNC(TO_DATE(v_year_built, 'YYYY'), 'YEAR'),
				r.val,
				r.str, 
				r.uom
			);
		END IF;
	END LOOP;
	
	SELECT b.region_sid, NVL(p.energy_star_push, 0)
	  INTO v_region_sid, v_energy_star_push
	  FROM est_building b
	  LEFT JOIN property p ON b.app_sid = p.app_sid AND b.region_sid = p.region_sid
	 WHERE b.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND b.est_account_sid = in_est_account_sid
	   AND b.pm_customer_id = in_pm_customer_id
	   AND b.pm_building_id = in_pm_building_id;
	   
	-- Update region information if mapped
	IF v_region_sid IS NOT NULL THEN
		IF v_energy_star_push = 0 THEN
			-- Update region information
			INTERNAL_UpdateBuildingRegion(
				in_est_account_sid, 
				in_pm_customer_id,
				in_pm_building_id,
				v_region_sid
			);
			-- Update the metrics
			INTERNAL_UpdateBuildingMetrics(
				in_est_account_sid,
				in_pm_customer_id,
				in_pm_building_id,
				v_region_sid,
				0 -- Everyting, not just read-only
			);
		ELSE
			-- Update read-only metrics
			INTERNAL_UpdateBuildingMetrics(
				in_est_account_sid,
				in_pm_customer_id,
				in_pm_building_id,
				v_region_sid,
				1 --Just read-only
			);
		END IF;
	END IF;
END;

-- Does not create a region, the building level region must already exist to be mapped
PROCEDURE MapBuilding(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_building.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_building.pm_building_id%TYPE,
    out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_count						NUMBER;
	v_region_sid				security_pkg.T_SID_ID;
	v_building_name				est_building.building_name%TYPE;
	v_energy_star_push			property.energy_star_push%TYPE;
BEGIN
	INTERNAL_CheckCustomerAccess(in_est_account_sid, in_pm_customer_id, security_pkg.PERMISSION_WRITE);
		
	SELECT region_sid, building_name
	  INTO v_region_sid, v_building_name
	  FROM est_building
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND est_account_sid = in_est_account_sid 
	   AND pm_customer_id = in_pm_customer_id
	   AND pm_building_id = in_pm_building_id;
	
	-- Already mapped (check region sid)?
	IF v_region_sid IS NOT NULL THEN
		GetBuilding(
			in_est_account_sid,
		    in_pm_customer_id,
		    in_pm_building_id,
		    out_cur
		);
		
		INTERNAL_ClearMissingFlag(
			in_est_account_sid,
		    in_pm_customer_id,
		    in_pm_building_id
		);
		
		RETURN;
	END IF;
		
	-- Region must exist in the property table, try and map 
	BEGIN
		-- "protfolio manager id" -> "property table pm id"
		SELECT region_sid, energy_star_push
		  INTO v_region_sid, v_energy_star_push
		  FROM property
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND energy_star_sync = 1 -- Sync must be switched on for the property
		   AND TRIM(pm_building_id) = TRIM(in_pm_building_id);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN	
			INTERNAL_AddBuildingError(
				in_est_account_sid,
				in_pm_customer_id,
				in_pm_building_id,
				'Property mapping: No active property region could be found matching the building ID.'
			);
			
		WHEN TOO_MANY_ROWS THEN
			INTERNAL_AddBuildingError(
				in_est_account_sid,
				in_pm_customer_id,
				in_pm_building_id,
				'Property mapping: More than one property region matched the protfolio manager ID.'
			);
	END;
	
	-- Found a matching region?
	IF v_region_sid IS NOT NULL THEN
		
		--Update the est_building table
		BEGIN
			UPDATE est_building
			   SET region_sid = v_region_sid,
			   	   last_poll_dtm = NULL,
			   	   missing = 0
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND est_account_sid = in_est_account_sid 
			   AND pm_customer_id = in_pm_customer_id
			   AND pm_building_id = in_pm_building_id;

			-- Don't update the region data for properties set to push
			IF v_energy_star_push = 0 THEN   
				-- Update the region information
				INTERNAL_UpdateBuildingRegion(
					in_est_account_sid, 
					in_pm_customer_id,
					in_pm_building_id,
					v_region_sid
				);
				-- Update the metrics
				INTERNAL_UpdateBuildingMetrics(
					in_est_account_sid,
					in_pm_customer_id,
					in_pm_building_id,
					v_region_sid,
					0 -- Everyting, not just read-only
				);
			ELSE
				-- Update read-only metrics
				INTERNAL_UpdateBuildingMetrics(
					in_est_account_sid,
					in_pm_customer_id,
					in_pm_building_id,
					v_region_sid,
					1 -- Just read-only
				);
			END IF;
			
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				INTERNAL_AddBuildingError(
					in_est_account_sid,
					in_pm_customer_id,
					in_pm_building_id,
					'Property mapping: More than one region has been mapped to the same Energy Star property.'
				);		
		END; 
	END IF;
	
	GetBuilding(
		in_est_account_sid,
	    in_pm_customer_id,
	    in_pm_building_id,
	    out_cur
	);
END;

PROCEDURE AssocSpaceTypeRgnMetrics(
	in_space_type_id			IN	space_type.space_type_id%TYPE,
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_space.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_space.pm_building_id%TYPE,
    in_pm_space_id				IN	est_space.pm_space_id%TYPE
)
AS
BEGIN
	INTERNAL_CheckCustomerAccess(in_est_account_sid, in_pm_customer_id, security_pkg.PERMISSION_WRITE);
	
	-- Associate region metrics for any attributes this space has where those attributes are mapped
	FOR i IN (
		SELECT DISTINCT m.ind_sid
		  FROM est_space_attr a
		  JOIN est_space_attr_mapping m ON a.app_sid = m.app_sid AND a.est_account_sid = m.est_account_sid AND a.attr_name = m.attr_name
		 WHERE a.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND a.est_account_sid = in_est_account_sid
		   AND a.pm_customer_id = in_pm_customer_id
		   AND a.pm_building_id = in_pm_building_id
		   AND a.pm_space_id = in_pm_space_id
	) LOOP
		region_metric_pkg.SetMetric(i.ind_sid);
		BEGIN
			INSERT INTO region_type_metric (region_type, ind_sid)
			VALUES (csr_data_pkg.REGION_TYPE_SPACE, i.ind_sid);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL; -- Ignore dupes
		END;
		BEGIN
			INSERT INTO space_type_region_metric (space_type_id, ind_sid, region_type)
			VALUES (in_space_type_id, i.ind_sid, csr_data_pkg.REGION_TYPE_SPACE);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL; -- Ignore dupes
		END;
	END LOOP;
END;


PROCEDURE CreateAndAssocSpaceType(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_space.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_space.pm_building_id%TYPE,
    in_pm_space_id				IN	est_space.pm_space_id%TYPE,
    out_space_type_id			OUT	space_type.space_type_id%TYPE
)
AS
	v_space_type				est_space.space_type%TYPE;
	v_property_type_id			property.property_type_id%TYPE;
BEGIN
	
	INTERNAL_CheckCustomerAccess(in_est_account_sid, in_pm_customer_id, security_pkg.PERMISSION_WRITE);
	
	-- Fetcch space/property information
	SELECT s.space_type, p.property_type_id
	  INTO v_space_type, v_property_type_id
	  FROM est_space s
	  JOIN est_building b ON s.app_sid = b.app_sid AND s.est_account_sid = b.est_account_sid AND s.pm_customer_id = b.pm_customer_id AND s.pm_building_id = b.pm_building_id
	  JOIN property p ON b.app_sid = p.app_sid AND b.region_sid = p.region_sid
	 WHERE s.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND s.est_account_sid = in_est_account_sid
	   AND s.pm_customer_id = in_pm_customer_id
	   AND s.pm_building_id = in_pm_building_id
	   AND s.pm_space_id = in_pm_space_id;
	
	-- Create a new space type
	BEGIN
		property_pkg.SaveSpaceType(
			NULL,
			v_space_type,
			0,
			out_space_type_id
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			-- An existing space type label must have matched
			SELECT space_type_id
			  INTO out_space_type_id
			  FROM space_type
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND UPPER(v_space_type) = UPPER(label);
	END;
	
	-- Ensure the property type -> space type relatonship is valid
	BEGIN
		INSERT INTO property_type_space_type (property_type_id, space_type_id, is_hidden)
			VALUES (v_property_type_id, out_space_type_id, 0);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	-- Add the new space type to the mapping
	INSERT INTO est_space_type_map (est_space_type, space_type_id)
	VAlUES (v_space_type, out_space_type_id);
END;


PROCEDURE INTERNAL_UpdateSpaceRegion(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_space.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_space.pm_building_id%TYPE,
    in_pm_space_id				IN	est_space.pm_space_id%TYPE,
 	in_region_sid				IN	security_pkg.T_SID_ID
)
AS
	v_year_built				DATE;
	v_val_id					csr.val.val_id%TYPE;
	v_building_region_sid		security_pkg.T_SID_ID;
	v_space_type_id				space_type.space_type_id%TYPE;
	v_prop_type_id				property.property_type_id%TYPE;
	v_auto_space_type			est_options.auto_create_space_type%TYPE;
	v_update					BOOLEAN;
	v_attr_val					est_space_attr.val%TYPE;
	v_current_rm_dtm			region_Metric_val.effective_dtm%TYPE;
	v_current_rm_val			region_metric_val.val%TYPE;
	v_current_rm_note			region_metric_val.note%TYPE;
BEGIN
	
	-- Get auto create option
	SELECT auto_create_space_type
	  INTO v_auto_space_type
	  FROM est_options
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	-- Get some building info
	SELECT TRUNC(TO_DATE(year_built, 'YYYY'), 'YEAR'), b.region_sid
	  INTO v_year_built, v_building_region_sid
	  FROM est_building b
	 WHERE b.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND est_account_sid = in_est_account_sid
	   AND pm_customer_id = in_pm_customer_id
	   AND pm_building_id = in_pm_building_id;
	
	-- Get the space type id
	BEGIN
		SELECT st.space_type_id
		  INTO v_space_type_id
		  FROM est_space es, space_type st, est_space_type_map m
		 WHERE es.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND st.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND es.region_sid = in_region_sid
		   AND m.est_space_type = es.space_type
		   AND st.space_type_id = m.space_type_id
		 ;
	EXCEPTION 
		WHEN NO_DATA_FOUND THEN
			-- Space type not mapped
			IF v_auto_space_type = 0 THEN
				RAISE_APPLICATION_ERROR(-20001, 'Failed to map space type for space with pm_space_id '||in_pm_space_id);
			ELSE
				CreateAndAssocSpaceType(
					in_est_account_sid,
					in_pm_customer_id,
					in_pm_building_id,
					in_pm_space_id,
					v_space_type_id
				);
			END IF;
	END;
	
	-- Update the property space table
	BEGIN
		SELECT p.property_type_id
		  INTO v_prop_type_id
		  FROM est_building b, property p
		 WHERE b.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND b.est_account_sid = in_est_account_sid
		   AND b.pm_customer_id = in_pm_customer_id
		   AND b.pm_building_id = in_pm_building_id
		   AND p.region_sid = b.region_sid;
		
		-- Ensure the property type space type combination is allowd.
		-- If we add it here then make it hidden from the UI unless auto_create_space_type is set in est_options
		BEGIN
			INSERT INTO property_type_space_type (property_type_id, space_type_id, is_hidden)
				VALUES (v_prop_type_id, v_space_type_id, DECODE(v_auto_space_type, 1, 0, 1));
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
		
		-- Assocaite the property type with the space
		BEGIN
			INSERT INTO space (region_sid, space_type_id, property_region_sid, property_type_id)
			  VALUES (in_region_sid, v_space_type_id, v_building_region_sid, v_prop_type_id);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE space
				   SET space_type_id = v_space_type_id,
				       property_region_sid = v_building_region_sid,
				       property_type_id = v_prop_type_id
				 WHERE region_sid = in_region_sid;
		END;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			INTERNAL_AddBuildingError(
				in_est_account_sid,
				in_pm_customer_id,
				in_pm_building_id,
				'Mapped building is not in the property table, building region_sid = '||in_region_sid||' (INTERNAL_UpdateSpaceRegion).'
			);
	END;
	
	-- If the auto flag is set then also associate any new attributes 
	-- with region metrics where there is an available mapping.
	IF v_auto_space_type != 0 THEN
		AssocSpaceTypeRgnMetrics(
			v_space_type_id,
			in_est_account_sid,
			in_pm_customer_id,
			in_pm_building_id,
			in_pm_space_id
		);
	END IF;

	-- Delete any region metric values not linked to the est_space_attr table
	FOR r IN (
		SELECT DISTINCT v.region_metric_val_id
		  FROM est_space_attr_mapping map, est_space s, region_metric_val v
		 WHERE map.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND map.est_account_sid = in_est_account_sid
		   AND s.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND s.est_account_sid = in_est_account_sid
	   	   AND s.pm_customer_id = in_pm_customer_id
	   	   AND s.pm_building_id = in_pm_building_id
	   	   AND s.pm_space_id = in_pm_space_id
		   AND v.ind_sid = map.ind_sid
		   AND v.region_sid = s.region_sid
		   AND NOT EXISTS (
		   	SELECT 1
			  FROM est_space_attr sa
			 WHERE sa.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND sa.region_metric_val_id = v.region_metric_val_id
		)
	) LOOP
		region_metric_pkg.DeleteMetricValue(r.region_metric_val_id);
	END LOOP;

		
	-- For each mapping...
	FOR i IN (
		SELECT map.ind_sid, map.measure_conversion_id, map.applies_to_building, 
				map.divisor, map.attr_name, map.uom, m.custom_field
		  FROM est_space_attr_mapping map
		  JOIN ind i ON map.app_sid = i.app_sid AND map.ind_sid = i.ind_sid
		  JOIN measure m ON i.app_sid = m.app_sid AND i.measure_sid = m.measure_sid
		 WHERE map.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND map.est_account_sid = in_est_account_sid
		   AND EXISTS (
		   		SELECT 1
		   		  FROM est_space_attr sa
		   		 WHERE sa.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   	   AND sa.est_account_sid = in_est_account_sid
			   	   AND sa.pm_customer_id = in_pm_customer_id
			   	   AND sa.pm_building_id = in_pm_building_id
			   	   AND sa.pm_space_id = in_pm_space_id
			   	   AND sa.attr_name = map.attr_name
		   		   AND NVL(sa.uom, '<null>') = map.uom
		   )
	) LOOP
	
		-- Ensure the region metric is set-up correctly
		region_metric_pkg.SetMetric(i.ind_sid);
		
		-- Set metric values...
		FOR r IN (
			SELECT sa.attr_name, sa.pm_val_id, rmv.region_metric_val_id, sa.val, sa.str, sa.effective_date start_dtm,
				sa.val / i.divisor val_result -- Divide value by divisor (useful for dealing with energy star percentages etc.)
			  FROM est_space_attr sa
			  JOIN est_space s
			    ON s.app_sid = sa.app_sid
			   AND s.est_account_sid = sa.est_account_sid
			   AND s.pm_customer_id = sa.pm_customer_id
			   AND s.pm_building_id = sa.pm_building_id
			   AND s.pm_space_id = sa.pm_space_id
			  LEFT JOIN region_metric_val rmv
			    ON rmv.app_sid = sa.app_sid
			   AND rmv.region_metric_val_id = sa.region_metric_val_id
			   AND rmv.region_sid = s.region_sid
			 WHERE sa.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND sa.est_account_sid = in_est_account_sid
			   AND sa.pm_customer_id = in_pm_customer_id
			   AND sa.pm_building_id = in_pm_building_id
			   AND sa.pm_space_id = in_pm_space_id
			   AND sa.attr_name = i.attr_name
			   AND NVL(sa.uom, '<null>') = i.uom
			   AND (sa.val IS NOT NULL OR sa.str IS NOT NULL)
			   	ORDER BY sa.attr_name, sa.effective_date
		) LOOP
		
			IF r.region_metric_val_id IS NOT NULL THEN
				
				-- Get the current value
				SELECT effective_dtm, val, note
				  INTO v_current_rm_dtm, v_current_rm_val, v_current_rm_note
				  FROM region_metric_val
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND region_metric_val_id = r.region_metric_val_id;
				
				-- Check to see if we need to update the existing value
				v_update := FALSE;
				IF v_current_rm_dtm != r.start_dtm THEN
					-- Dates differ
					v_update := TRUE;
				ELSE
					-- Get normal val
					v_attr_val := CASE 
						WHEN i.custom_field IS NULL THEN r.val_result 
						ELSE energy_star_helper_pkg.UNSEC_ValFromCustom(i.ind_sid, NVL(r.str, TO_CHAR(r.val)))
					END;
					
					-- Test val
					v_update := CASE
						WHEN v_current_rm_val IS NULL AND v_attr_val IS NULL THEN FALSE
						WHEN v_current_rm_val IS NOT NULL AND v_attr_val IS NULL THEN TRUE
						WHEN v_current_rm_val IS NULL AND v_attr_val IS NOT NULL THEN TRUE
						WHEN v_current_rm_val != v_attr_val THEN TRUE
						-- Equal
						ELSE FALSE
					END;
					IF NOT v_update AND i.custom_field IS NULL THEN
						-- Test note
						v_update := CASE
							WHEN v_current_rm_note IS NULL AND r.str IS NULL THEN FALSE
							WHEN v_current_rm_note IS NOT NULL AND r.str IS NULL THEN TRUE
							WHEN v_current_rm_note IS NULL AND r.str IS NOT NULL THEN TRUE
							WHEN v_current_rm_note != r.str THEN TRUE
							-- Equal
							ELSE FALSE
						END;
					END IF;
				END IF;
				
				-- Update the existing metric value if required
				IF v_update THEN
					region_metric_pkg.SetMetricValue(
						r.region_metric_val_id,
						r.start_dtm,
						CASE WHEN i.custom_field IS NULL THEN r.val_result ELSE energy_star_helper_pkg.UNSEC_ValFromCustom(i.ind_sid, NVL(r.str, TO_CHAR(r.val))) END,
						CASE WHEN i.custom_field IS NULL THEN r.str ELSE NULL END,
						i.measure_conversion_id,
						csr_data_pkg.SOURCE_TYPE_ENERGY_STAR
					);					
				END IF;
			ELSE
				-- Set a new metric value
				region_metric_pkg.SetMetricValue(
					CASE WHEN i.applies_to_building = 0 THEN in_region_sid ELSE v_building_region_sid END,
					i.ind_sid,
					r.start_dtm,
					CASE WHEN i.custom_field IS NULL THEN r.val_result ELSE energy_star_helper_pkg.UNSEC_ValFromCustom(i.ind_sid, NVL(r.str, TO_CHAR(r.val))) END,
					CASE WHEN i.custom_field IS NULL THEN r.str ELSE NULL END,
					NULL,
					i.measure_conversion_id,
					csr_data_pkg.SOURCE_TYPE_ENERGY_STAR,
					v_val_id
				);
				
				-- Associate the new metric value with the space attribute
				UPDATE est_space_attr
				   SET region_metric_val_id = v_val_id
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND pm_val_id = r.pm_val_id;
				   
			END IF;
		END LOOP;
	END LOOP;
	

	-- Deal with any *other* mapppings
	IF in_region_sid IS NOT NULL THEN	
		FOR r IN (
			SELECT mapping_name
			  FROM est_other_mapping
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND est_account_sid = in_est_account_sid
		) LOOP
			INTERNAL_SetOtherValue(
				in_est_account_sid, 
				r.mapping_name,
				in_region_sid,
				NULL,
				NULL,
				NULL
			);
		END LOOP;
	END IF;
	
END;

PROCEDURE GetSpace(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_space.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_space.pm_building_id%TYPE,
    in_pm_space_id				IN	est_space.pm_space_id%TYPE,
    out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	INTERNAL_CheckCustomerAccess(in_est_account_sid, in_pm_customer_id, security_pkg.PERMISSION_READ);
	
	OPEN out_cur FOR
		SELECT est_account_sid, pm_customer_id, pm_building_id, pm_space_id, region_sid, space_name, space_type
		  FROM est_space
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND est_account_sid = in_est_account_sid 
		   AND pm_customer_id = in_pm_customer_id
		   AND pm_building_id = in_pm_building_id
		   AND pm_space_id = in_pm_space_id;
END;

PROCEDURE GetSpaceAttrs(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_space.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_space.pm_building_id%TYPE,
    in_pm_space_id				IN	est_space.pm_space_id%TYPE,
    out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	INTERNAL_CheckCustomerAccess(in_est_account_sid, in_pm_customer_id, security_pkg.PERMISSION_READ);
	
	OPEN out_cur FOR
		SELECT pm_val_id, est_account_sid, pm_customer_id, pm_building_id, pm_space_id, region_metric_val_id, attr_name, effective_date, val, str, uom, is_default
		  FROM est_space_attr
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND est_account_sid = in_est_account_sid 
		   AND pm_customer_id = in_pm_customer_id
		   AND pm_building_id = in_pm_building_id
		   AND pm_space_id = in_pm_space_id;
END;

PROCEDURE GetSpaceAndAttrs(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_space.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_space.pm_building_id%TYPE,
    in_pm_space_id				IN	est_space.pm_space_id%TYPE,
    out_space					OUT	security_pkg.T_OUTPUT_CUR,
    out_attrs					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetSpace(
		in_est_account_sid,
	    in_pm_customer_id,
	    in_pm_building_id,
	    in_pm_space_id,
	    out_space
	);
	GetSpaceAttrs(
		in_est_account_sid,
	    in_pm_customer_id,
	    in_pm_building_id,
	    in_pm_space_id,
	    out_attrs
	);
END;

-- Set/create space information in energy star schema
PROCEDURE SetSpace(
    in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_space.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_space.pm_building_id%TYPE,
    in_pm_space_id				IN	est_space.pm_space_id%TYPE,
    in_region_sid				IN	security_pkg.T_SID_ID,
    in_space_name				IN	est_space.space_name%TYPE,
    in_space_type				IN	est_space.space_type%TYPE,
    -- Space attributes
    in_attr_ids					IN	security_pkg.T_SID_IDS,
    in_region_metric_ids		IN	security_pkg.T_SID_IDS,
	in_attr_names				IN	security_pkg.T_VARCHAR2_ARRAY,
	in_attr_vals				IN	T_VAL_ARRAY,
	in_attr_strs				IN	security_pkg.T_VARCHAR2_ARRAY,
	in_attr_dtms				IN	T_DATE_ARRAY,
	in_attr_uoms				IN	security_pkg.T_VARCHAR2_ARRAY
)
AS
	v_region_sid				security_pkg.T_SID_ID;
	v_old_space_name			est_space.space_name%TYPE;
	t_attrs						T_EST_ATTR_TABLE;
	v_push						property.energy_star_push%TYPE;
	v_update_by_date			BOOLEAN;
BEGIN
	
	INTERNAL_CheckCustomerAccess(in_est_account_sid, in_pm_customer_id, security_pkg.PERMISSION_WRITE);

	BEGIN
		INSERT INTO est_space
			(est_account_sid, pm_customer_id, pm_building_id, pm_space_id, region_sid, space_name, space_type)
		  VALUES (in_est_account_sid, in_pm_customer_id, in_pm_building_id, in_pm_space_id, in_region_sid, in_space_name, in_space_type);
		-- Space is new and will not need renaming
		v_old_space_name := in_space_name;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
		
			-- get the old name (in case it's changed)
			SELECT space_name
			  INTO v_old_space_name
			  FROM est_space
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND est_account_sid = in_est_account_sid 
			   AND pm_customer_id = in_pm_customer_id
			   AND pm_building_id = in_pm_building_id
			   AND pm_space_id = in_pm_space_id;
		
			-- update the sapace
			UPDATE est_space
			   SET region_sid = NVL(in_region_sid, region_sid),
			       space_name = in_space_name,
			       space_type = in_space_type
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND est_account_sid = in_est_account_sid 
			   AND pm_customer_id = in_pm_customer_id
			   AND pm_building_id = in_pm_building_id
			   AND pm_space_id = in_pm_space_id;
	END;
	
	-- Space attributes
	t_attrs := AttrsToTable(
		in_attr_ids,
		in_region_metric_ids,
		in_attr_names,
		in_attr_vals,
		in_attr_strs,
		in_attr_dtms,
		in_attr_uoms
	);
	
	-- Remove anything not present in the new list
	DELETE FROM est_space_attr sa
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND est_account_sid = in_est_account_sid 
	   AND pm_customer_id = in_pm_customer_id
	   AND pm_building_id = in_pm_building_id
	   AND pm_space_id = in_pm_space_id
	   AND NOT EXISTS (
	   	SELECT 1
	   	  FROM TABLE(t_attrs) t
	   	 WHERE t.id = sa.pm_val_id
	   );

	-- Add/update new values
	FOR r IN (
		SELECT id, region_metric_id, name, val, str, dtm, uom
		  FROM TABLE(t_attrs)
		 WHERE id IS NOT NULL
		 ORDER BY pos
	) LOOP
		v_update_by_date := FALSE;
		BEGIN
			-- Try to insert...
			INSERT INTO est_space_attr
				(pm_val_id, region_metric_val_id, est_account_sid, pm_customer_id, pm_building_id, pm_space_id, attr_name, effective_date, val, str, uom)
			  VALUES (r.id, r.region_metric_id, in_est_account_sid, in_pm_customer_id, in_pm_building_id, in_pm_space_id, r.name, r.dtm, r.val, r.str, r.uom);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				BEGIN
					-- A matching record already exists, try replacing by id.
					UPDATE est_space_attr
				   	   SET region_metric_val_id = NVL(r.region_metric_id, region_metric_val_id),
				   	   	   est_account_sid = in_est_account_sid,
				   	   	   pm_customer_id = in_pm_customer_id,
				   	   	   pm_building_id = in_pm_building_id,
				   	   	   pm_space_id = in_pm_space_id,
				   	   	   attr_name = r.name,
				   	   	   effective_date = r.dtm,
				   	   	   val = r.val,
				       	   str = r.str,
				       	   uom = r.uom
					 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
					   AND pm_val_id = r.id;
					
					IF SQL%ROWCOUNT = 0 THEN
						-- The insert failed the unique check constraint on the 
						-- name/date not the primary key constraint on the id
						v_update_by_date := TRUE;
					END IF;
						
				EXCEPTION
					WHEN DUP_VAL_ON_INDEX THEN
						-- A record for this space already has the name and 
						-- date we're trying to enter but with a different id.
						v_update_by_date := TRUE;
				END;
		END;
		
		-- If the above failed to update the value then try to 
		-- update the attribute with the matching name/date
		WHILE v_update_by_date
		LOOP
			BEGIN
				-- Try and update
				UPDATE est_space_attr
				   SET pm_val_id = r.id, 
				   	   region_metric_val_id = r.region_metric_id,
				   	   val = r.val,
				       str = r.str,
				       uom = r.uom
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND est_account_sid = in_est_account_sid 
				   AND pm_customer_id = in_pm_customer_id
				   AND pm_building_id = in_pm_building_id
				   AND pm_space_id = in_pm_space_id
				   AND attr_name = r.name
				   AND effective_date = r.dtm;
				   
				-- Allow the loop to exit
				v_update_by_date := FALSE;
				
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					-- We might need to remove a row with the existing ID if the name/date 
					-- changed and the name/date already match another row with a different ID.
					DELETE FROM est_space_attr
					 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
					   AND pm_val_id = r.id;
			END;
		END LOOP;
		
	END LOOP;
	
	-- Get region/property info
	SELECT s.region_sid, NVL(p.energy_star_push, 0)
	  INTO v_region_sid, v_push
	  FROM est_space s
	  JOIN est_building b ON s.app_sid = b.app_sid AND s.est_account_sid = b.est_account_sid 
		  	AND s.pm_customer_id = b.pm_customer_id AND s.pm_building_id = b.pm_building_id
	  LEFT JOIN property p ON s.app_sid = p.app_sid AND p.region_sid = b.region_sid
	 WHERE s.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND s.est_account_sid = in_est_account_sid 
	   AND s.pm_customer_id = in_pm_customer_id
	   AND s.pm_building_id = in_pm_building_id
	   AND s.pm_space_id = in_pm_space_id;
	
	-- Update region if mapped *unless* the property is set to "push"
	IF v_region_sid IS NOT NULL AND v_push = 0 THEN
		
		-- Check for renaming and rename the region if required
		IF in_space_name != v_old_space_name THEN
			region_pkg.RenameRegion(v_region_sid, in_space_name);
		END IF;
		
		-- Update space data
		INTERNAL_UpdateSpaceRegion(
			in_est_account_sid,
		    in_pm_customer_id,
		    in_pm_building_id,
		    in_pm_space_id,
		    v_region_sid
		);
	END IF;
	
END;

-- This creates spaces and returns the region sid for the new space unless the space 
-- is already mapped to a region sid in which case it returns that region sid
PROCEDURE MapSpace(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_space.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_space.pm_building_id%TYPE,
    in_pm_space_id				IN	est_space.pm_space_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_region_sid				security_pkg.T_SID_ID;
	v_space_name				est_space.space_name%TYPE;
	v_parent_region_sid			security_pkg.T_SID_ID;
	v_count						NUMBER;
BEGIN
	INTERNAL_CheckCustomerAccess(in_est_account_sid, in_pm_customer_id, security_pkg.PERMISSION_WRITE);
	
	SELECT region_sid, space_name
	  INTO v_region_sid, v_space_name
	  FROM est_space
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND est_account_sid = in_est_account_sid 
	   AND pm_customer_id = in_pm_customer_id
	   AND pm_building_id = in_pm_building_id
	   AND pm_space_id = in_pm_space_id;

	-- Already mapped (check region mapping exists)?
	IF v_region_sid IS NOT NULL THEN
		-- Return space info
		GetSpace(
			in_est_account_sid,
		    in_pm_customer_id,
		    in_pm_building_id,
		    in_pm_space_id,
		    out_cur
   		);
		RETURN;
	END IF;
	
	-- Find the parent building region
	BEGIN
		SELECT region_sid
		  INTO v_parent_region_sid
		  FROM est_building
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND est_account_sid = in_est_account_sid 
		   AND pm_customer_id = in_pm_customer_id
		   AND pm_building_id = in_pm_building_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_parent_region_sid := NULL;
	END;		
	
	IF v_parent_region_sid IS NULL THEN
		-- Return space info
		GetSpace(
			in_est_account_sid,
		    in_pm_customer_id,
		    in_pm_building_id,
		    in_pm_space_id,
		    out_cur
   		);
		RETURN;
	END IF;	
	
	IF INTERNAL_CheckBuildingError(v_parent_region_sid) THEN
		-- Add error to building
		INTERNAL_AddBuildingError(
			in_est_account_sid,
			in_pm_customer_id,
			in_pm_building_id,
			'Space mapping: Mapped building is not in the property table.'
		);
		-- Return space info
		GetSpace(
			in_est_account_sid,
		    in_pm_customer_id,
		    in_pm_building_id,
		    in_pm_space_id,
		    out_cur
   		);
		RETURN;
	END IF;
	
	-- Ok, create a new region
	BEGIN
		region_pkg.CreateRegion(	
			in_parent_sid		=>	v_parent_region_sid,
			in_name				=>	v_space_name,
			in_description		=>	v_space_name,
			in_acquisition_dtm 	=> 	NULL,
			in_region_type		=>  csr_data_pkg.REGION_TYPE_SPACE,
			out_region_sid		=>	v_region_sid
		);
	EXCEPTION
		-- Space names within a building don't have to be unique in Energy Star
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_space_name := v_space_name||' ('||in_pm_space_id||')';
			
			BEGIN
				region_pkg.CreateRegion(	
					in_parent_sid		=>	v_parent_region_sid,
					in_name				=>	v_space_name,
					in_description		=>	v_space_name,
					in_acquisition_dtm 	=> 	NULL,
					in_region_type		=>  csr_data_pkg.REGION_TYPE_SPACE,
					out_region_sid		=>	v_region_sid
				);
			EXCEPTION
				WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
					SELECT region_sid
					  INTO v_region_sid
					  FROM region
					 WHERE parent_sid = v_parent_region_sid
					   AND name = v_space_name;
			END;
	END;
	
	UPDATE est_space
	   SET region_sid = v_region_sid
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND est_account_sid = in_est_account_sid 
	   AND pm_customer_id = in_pm_customer_id
	   AND pm_building_id = in_pm_building_id
	   AND pm_space_id = in_pm_space_id;
	   
	-- Update region data for mapped region
	INTERNAL_UpdateSpaceRegion(
		in_est_account_sid,
	    in_pm_customer_id,
	    in_pm_building_id,
	    in_pm_space_id,
	    v_region_sid
	);
	
	-- Return space info
	GetSpace(
		in_est_account_sid,
	    in_pm_customer_id,
	    in_pm_building_id,
	    in_pm_space_id,
	    out_cur
	);
	
END;

PROCEDURE INTERNAL_AddMeterError(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_meter.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_meter.pm_building_id%TYPE,
    in_pm_meter_id				IN	est_meter.pm_meter_id%TYPE,
	in_message					IN	est_error.error_message%TYPE
)
AS
	v_region_sid				security_pkg.T_SID_ID;
BEGIN
	BEGIN
		SELECT region_sid
		  INTO v_region_sid
		  FROM est_meter
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND est_account_sid = in_est_account_sid
		   AND pm_customer_id = in_pm_customer_id
		   AND pm_building_id = in_pm_building_id
		   AND pm_meter_id = in_pm_meter_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;
	
	AddError(
		in_region_sid			=> v_region_sid,
		in_est_account_sid		=> in_est_account_sid,
		in_pm_customer_id		=> in_pm_customer_id,
		in_pm_building_id		=> in_pm_building_id,
		in_pm_meter_id			=> in_pm_meter_id,
		in_error_code			=> ERR_GENERIC_METER,
		in_error_message		=> in_message
	);
END;

PROCEDURE INTERNAL_LookupMeterType(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_meter.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_meter.pm_building_id%TYPE,
    in_pm_meter_id				IN	est_meter.pm_meter_id%TYPE,
    out_meter_type_id			OUT	meter_type.meter_type_id%TYPE,
    out_measure_sid				OUT	security_pkg.T_SID_ID,
	out_conversion_id			OUT	measure_conversion.measure_conversion_id%TYPE
)
AS
	v_type						est_meter.meter_type%TYPE;
	v_uom						est_meter.uom%TYPE;
BEGIN
	-- Get some information about the meter
	SELECT meter_type, uom
	  INTO v_type, v_uom
	  FROM est_meter
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND est_account_sid = in_est_account_sid 
	   AND pm_customer_id = in_pm_customer_id
	   AND pm_building_id = in_pm_building_id
	   AND pm_meter_id = in_pm_meter_id;
	
	-- Try to find the correct meter indicator mapping
	BEGIN
		SELECT e.meter_type_id
		  INTO out_meter_type_id
		  FROM est_meter_type_mapping e
		 WHERE e.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND e.est_account_sid = in_est_account_sid
		   AND LOWER(e.meter_type) = LOWER(v_type);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			out_meter_type_id := NULL;
	END;
	
	-- Try to match the uom to a known mapping
	BEGIN
		SELECT measure_sid, measure_conversion_id
		  INTO out_measure_sid, out_conversion_id
		  FROM est_conv_mapping
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND est_account_sid = in_est_account_sid
		   AND LOWER(meter_type) = LOWER(v_type)
		   AND LOWER(uom) = LOWER(v_uom);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- Meter UOM does not match any known mapping
			out_measure_sid := NULL;
			out_conversion_id := NULL;
	END;
END;

PROCEDURE INTERNAL_UpdateMeterRgn(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_meter.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_meter.pm_building_id%TYPE,
    in_pm_meter_id				IN	est_meter.pm_meter_id%TYPE,
    in_region_sid				IN	security_pkg.T_SID_ID,
    in_meter_type_id			IN	meter_type.meter_type_id%TYPE,
    in_conversion_id			IN	measure_conversion.measure_conversion_id%TYPE
)
AS
	v_meter_name				est_meter.meter_name%TYPE;
	v_other_desc				est_meter.other_desc%TYPE;
	v_empty_ids					security_pkg.T_SID_IDS;
	v_source_type_id			meter_source_type.meter_source_type_id%TYPE;
	v_start_dtm					DATE;
	v_val_id					val.val_id%TYPE;

	v_active					est_meter.active%TYPE;
	v_inactive_dtm				est_meter.inactive_dtm%TYPE;
	v_first_bill_dtm			est_meter.first_bill_dtm%TYPE;
	v_amend_region				BOOLEAN;
	
	CURSOR c IS
		SELECT m.region_sid, m.note, meter_source_type_id, m.reference, m.crc_meter, m.is_core, 
			m.meter_type_id, m.urjanet_meter_id, r.active, r.disposal_dtm, r.acquisition_dtm,
			m.manual_data_entry
		  FROM all_meter m
		  JOIN region r ON r.app_sid = m.app_sid AND r.region_sid = m.region_sid
		 WHERE m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND m.region_sid = in_region_sid
		 ;
	existing c%ROWTYPE;
BEGIN
	-- Update the meter region if possible
	IF in_meter_type_id IS NOT NULL THEN
	
		SELECT meter_name, other_desc
		  INTO v_meter_name, v_other_desc
		  FROM est_meter
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND est_account_sid = in_est_account_sid 
		   AND pm_customer_id = in_pm_customer_id
		   AND pm_building_id = in_pm_building_id
		   AND pm_meter_id = in_pm_meter_id;
		
		OPEN c;
		FETCH c INTO existing;
		IF c%NOTFOUND THEN 	
		
			-- Fetch the source type for an arbitrary period meter
			SELECT meter_source_type_id
			  INTO v_source_type_id
			  FROM meter_source_type
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND arbitrary_period = 1
			   AND allow_null_start_dtm = 0;
			
			-- Create a new meter
			meter_pkg.LegacyMakeMeter(
				in_act_id					=> security_pkg.GetACT,
				in_region_sid				=> in_region_sid,
				in_meter_type_id			=> in_meter_type_id,
				in_note						=> 'Created by Energy Star mapping process',
				in_primary_conversion_id	=> in_conversion_id,
				in_cost_conversion_id		=> NULL,
				in_source_type_id			=> v_source_type_id,
				in_manual_data_entry		=> 1,
				in_reference				=> v_meter_name,
				in_contract_ids				=> v_empty_ids,
				in_active_contract_id		=> NULL
			);
		
		ELSE
		-- XXX: Actually, we don't want to update the indicator or meter_type_id on an existing 
		-- meter as the user may have changed the purchase type, which is also refected in the meter_type, 
		-- we don't know what the pruchase type is at this point because we don't get it from Energy Star 
		-- so we can't know which meter ind and so which indicator we should be using.
		
			-- Update an existing meter
			meter_pkg.LegacyMakeMeter(
				in_act_id					=> security_pkg.GetACT,
				in_region_sid				=> in_region_sid,
				in_meter_type_id			=> existing.meter_type_id,
				in_note						=> existing.note,
				in_primary_conversion_id	=> in_conversion_id,
				in_cost_conversion_id		=> NULL,
				in_source_type_id			=> existing.meter_source_type_id,
				in_manual_data_entry		=> existing.manual_data_entry,
				in_reference				=> v_meter_name,
				in_contract_ids				=> v_empty_ids,
				in_active_contract_id		=> NULL,
				in_crc_meter				=> existing.crc_meter,
				in_is_core					=> existing.is_core,
				in_urjanet_meter_id			=> existing.urjanet_meter_id
			);

		END IF;

		-- Deal with active/inactive and disposal date
		v_amend_region := FALSE;

		-- Collect some useful info
		SELECT active, inactive_dtm, CASE WHEN first_bill_dtm < TO_DATE('01-01-1900', 'DD-MM-YYYY') THEN NULL ELSE first_bill_dtm END
		  INTO v_active, v_inactive_dtm, v_first_bill_dtm
		  FROM est_meter
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND est_account_sid = in_est_account_sid
		   AND pm_customer_id = in_pm_customer_id
		   AND pm_building_id = in_pm_building_id
		   AND pm_meter_id = in_pm_meter_id;

		-- See if we need to updae the acquisition date
		IF existing.acquisition_dtm != v_first_bill_dtm OR
			(existing.acquisition_dtm IS NULL AND v_first_bill_dtm IS NOT NULL) OR
			(existing.acquisition_dtm IS NOT NULL AND v_first_bill_dtm IS NULL) THEN

			-- Set the acquisition dtm
			UPDATE region
			   SET acquisition_dtm = v_first_bill_dtm
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND region_sid = in_region_sid;
			-- Flag for later use
			v_amend_region := TRUE;
		END IF;

		IF existing.active != v_active THEN
			IF v_active = 0 THEN
				-- Set the disposal date
				UPDATE region
				   SET disposal_dtm = v_inactive_dtm
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND region_sid = in_region_sid;
				-- Flag for later use
				v_amend_region := TRUE;
			ELSE
				-- Clear the disposal date
				UPDATE region
				   SET disposal_dtm = NULL
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND region_sid = in_region_sid;
				-- Flag for later use
				v_amend_region := TRUE;
			END IF;

		ELSIF v_active = 0 AND existing.disposal_dtm != v_inactive_dtm THEN
			-- Set the new disposal date
			UPDATE region
			   SET disposal_dtm = v_inactive_dtm
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND region_sid = in_region_sid;
			-- Flag for later use
			v_amend_region := TRUE;
		END IF;

		-- If we changed anything then get the region_pkg to do it's stuff
		IF v_amend_region THEN
			region_pkg.UNSEC_AmendRegionActive(
				security_pkg.GetACT,
				in_region_sid,
				v_active, 					-- This is set buy the call
				existing.acquisition_dtm,	-- This is used by the call to determine if the exsting valur in the region table changed.
				existing.disposal_dtm,		-- This is used by the call to determine if the exsting valur in the region table changed.
				0 							-- Full update (recompute meter data etc.)
			);
		END IF;

		CLOSE c;
	END IF;
END;

PROCEDURE GetMeterAndSiblings(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_meter.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_meter.pm_building_id%TYPE,
    in_pm_meter_id				IN	est_meter.pm_meter_id%TYPE,
    out_meter					OUT	security_pkg.T_OUTPUT_CUR,
    out_siblings				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetMeter(
		in_est_account_sid,
		in_pm_customer_id,
		in_pm_building_id,
		in_pm_meter_id,
		out_meter
	);
	
	GetMeterSiblings(
		in_est_account_sid,
		in_pm_customer_id,
		in_pm_building_id,
		in_pm_meter_id,
		out_siblings
	);
END;

PROCEDURE GetMeterSiblings(
	in_region_sid				IN	security_pkg.T_SID_ID,
    out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading region with SID '||in_region_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT am.region_sid, em.pm_meter_id, em.meter_type
		  FROM region mr
		  JOIN region pr ON mr.app_sid = pr.app_sid AND mr.parent_sid = pr.region_sid
		  JOIN region cr ON pr.app_sid = cr.app_sid AND pr.region_sid = cr.parent_sid
		  JOIN all_meter am ON cr.app_sid = am.app_sid AND cr.region_sid = am.region_sid
		  JOIN est_meter em ON am.app_sid = em.app_sid AND am.region_sid = em.region_sid
		 WHERE mr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND mr.region_sid = in_region_sid;
END;

PROCEDURE GetMeterSiblings(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_meter.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_meter.pm_building_id%TYPE,
    in_pm_meter_id				IN	est_meter.pm_meter_id%TYPE,
    out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_region_sid				security_pkg.T_SID_ID;
BEGIN	
	SELECT em.region_sid
	  INTO v_region_sid
	  FROM est_meter em
	 WHERE em.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND em.est_account_sid = in_est_account_sid
	   AND em.pm_customer_id = in_pm_customer_id
	   AND em.pm_building_id = in_pm_building_id
	   AND em.pm_meter_id = in_pm_meter_id;
	
	GetMeterSiblings(
		v_region_sid,
		out_cur
	);
	
END;

PROCEDURE GetMeter(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_meter.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_meter.pm_building_id%TYPE,
    in_pm_meter_id				IN	est_meter.pm_meter_id%TYPE,
    out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	INTERNAL_CheckCustomerAccess(in_est_account_sid, in_pm_customer_id, security_pkg.PERMISSION_READ);
	
	OPEN out_cur FOR
		SELECT m.est_account_sid, m.pm_customer_id, m.pm_building_id, m.pm_meter_id, m.pm_space_id, 
			m.region_sid, m.meter_name, m.meter_type, m.uom, m.add_to_total, m.write_access, 
			m.other_desc, m.last_entry_date, m.sellback, m.enviro_attr_owned, source_pm_customer_id, 
			m.active, m.inactive_dtm, m.first_bill_dtm
		  FROM est_meter m
		  -- if the meter was deleted or trashed then the region sid will have been nulled out
		  LEFT JOIN region r ON r.app_sid = m.app_sid AND r.region_sid = m.region_sid
		 WHERE m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND m.est_account_sid = in_est_account_sid 
		   AND m.pm_customer_id = in_pm_customer_id
		   AND m.pm_building_id = in_pm_building_id
		   AND m.pm_meter_id = in_pm_meter_id
		;
END;

-- Set/create meter information in energy star schema
PROCEDURE SetMeter(
    in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_meter.pm_customer_id%TYPE,
    in_source_pm_customer_id	IN	est_building.source_pm_customer_id%TYPE,
    in_pm_building_id			IN	est_meter.pm_building_id%TYPE,
    in_pm_meter_id				IN	est_meter.pm_meter_id%TYPE,
    in_pm_space_id				IN	est_meter.pm_space_id%TYPE,
    in_region_sid				IN	security_pkg.T_SID_ID,
    in_meter_name				IN	est_meter.meter_name%TYPE,
    in_meter_type				IN	est_meter.meter_type%TYPE,
    in_uom						IN	est_meter.uom%TYPE,
    in_active					IN	est_meter.active%TYPE,
    in_inactive_dtm				IN	est_meter.inactive_dtm%TYPE,
    in_add_to_total				IN	est_meter.add_to_total%TYPE,
    in_first_bill_dtm			IN	est_meter.first_bill_dtm%TYPE,
    in_last_entry_date			IN	est_meter.last_entry_date%TYPE,
    in_write_access				IN	est_meter.write_access%TYPE,
    in_other_desc				IN	est_meter.other_desc%TYPE
)
AS
	v_region_sid				security_pkg.T_SID_ID;
	v_meter_type_id				meter_type.meter_type_id%TYPE;
	v_measure_sid				security_pkg.T_SID_ID;
	v_conversion_id				measure_conversion.measure_conversion_id%TYPE;
	v_old_meter_name			est_meter.meter_name%TYPE;
	v_push						property.energy_star_push%TYPE;
BEGIN
	INTERNAL_CheckCustomerAccess(in_est_account_sid, in_pm_customer_id, security_pkg.PERMISSION_WRITE);
	
	BEGIN
		INSERT INTO est_meter
			(est_account_sid, pm_customer_id, pm_building_id, pm_meter_id, pm_space_id, region_sid,
			    meter_name, meter_type, uom, active, inactive_dtm, add_to_total,
			    last_entry_date, first_bill_dtm, write_access, other_desc,
			    source_pm_customer_id)
		  VALUES(in_est_account_sid, in_pm_customer_id, in_pm_building_id, in_pm_meter_id, in_pm_space_id, in_region_sid,
			    in_meter_name, in_meter_type, in_uom, in_active, in_inactive_dtm, in_add_to_total,
			    in_last_entry_date, in_first_bill_dtm, in_write_access, in_other_desc,
			    in_source_pm_customer_id);
		-- Meter is new and will not need renaming
		v_old_meter_name := in_meter_name;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			-- get the old meter name (in case it's changed)
			SELECT meter_name
			  INTO v_old_meter_name
			  FROM est_meter
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND est_account_sid = in_est_account_sid 
			   AND pm_customer_id = in_pm_customer_id
			   AND pm_building_id = in_pm_building_id
			   AND pm_meter_id = in_pm_meter_id;
		
			-- update the meter
			UPDATE est_meter
			   SET pm_space_id = in_pm_space_id,
			   	   region_sid = NVL(in_region_sid, region_sid),
			       meter_name = in_meter_name,
			       meter_type = in_meter_type, 
			       uom = in_uom, 
			       active = in_active, 
			       inactive_dtm = in_inactive_dtm,
			       add_to_total = in_add_to_total,
			       first_bill_dtm = in_first_bill_dtm,
			       last_entry_date = in_last_entry_date, 
			       write_access = in_write_access,
			       other_desc = in_other_desc,
			       source_pm_customer_id = NVL(in_source_pm_customer_id, source_pm_customer_id)
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND est_account_sid = in_est_account_sid 
			   AND pm_customer_id = in_pm_customer_id
			   AND pm_building_id = in_pm_building_id
			   AND pm_meter_id = in_pm_meter_id;
	END;
	
	SELECT region_sid
	  INTO v_region_sid
	  FROM est_meter
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND est_account_sid = in_est_account_sid 
	   AND pm_customer_id = in_pm_customer_id
	   AND pm_building_id = in_pm_building_id
	   AND pm_meter_id = in_pm_meter_id;
	  
	-- Is the region mapped
	IF v_region_sid IS NULL THEN
		RETURN;
	END IF;
	
	-- Don't update the region if it's set to "push"
	BEGIN
		-- Get the push flag from the property table, find the 
		-- meter's parent property using the est_building table
		SELECT p.energy_star_push
		  INTO v_push
		  FROM est_meter m
		  JOIN est_building b ON m.app_sid = b.app_sid AND m.est_account_sid = b.est_account_sid 
		  		AND m.pm_customer_id = b.pm_customer_id AND m.pm_building_id = b.pm_building_id
		  JOIN property p ON b.app_sid = p.app_sid AND b.region_sid = p.region_sid
		 WHERE m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND m.est_account_sid = in_est_account_sid 
		   AND m.pm_customer_id = in_pm_customer_id
		   AND m.pm_building_id = in_pm_building_id
		   AND m.pm_meter_id = in_pm_meter_id;
		-- If it's "push" just return
		IF v_push = 1 THEN
			RETURN;
		END IF;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- Not in property table, can't be "push" then
			NULL;
	END;
	
	-- Check for renaming and rename the region if required
	IF in_meter_name != v_old_meter_name THEN
		region_pkg.RenameRegion(v_region_sid, in_meter_name);
	END IF;
	
	INTERNAL_LookupMeterType(
		in_est_account_sid,
	    in_pm_customer_id,
	    in_pm_building_id,
	    in_pm_meter_id,
	    v_meter_type_id,
	    v_measure_sid,
	    v_conversion_id
	);
	
	IF v_meter_type_id IS NOT NULL AND
	   v_measure_sid IS NOT NULL THEN
		INTERNAL_UpdateMeterRgn(
			in_est_account_sid,
		    in_pm_customer_id,
		    in_pm_building_id,
		    in_pm_meter_id,
		    v_region_sid,
		    v_meter_type_id,
		    v_conversion_id
		);
	END IF;
	
END;

-- Try to create a meter and return the region sid, the meter 
-- type to indicator mapping must be valid for this to succeed
PROCEDURE MapMeter(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_meter.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_meter.pm_building_id%TYPE,
    in_pm_meter_id				IN	est_meter.pm_meter_id%TYPE,
    in_pm_space_id				IN	est_meter.pm_space_id%TYPE,
    out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_region_sid				security_pkg.T_SID_ID;
	v_parent_region_sid			security_pkg.T_SID_ID;
	v_meter_type_id				meter_type.meter_type_id%TYPE;
    v_measure_sid				security_pkg.T_SID_ID;
    v_conversion_id				measure_conversion.measure_conversion_id%TYPE;
	v_parent_building_id		est_meter.pm_building_id%TYPE;
	v_parent_space_id			est_meter.pm_space_id%TYPE;
	v_meter_name				est_meter.meter_name%TYPE;
	v_meter_uom					est_meter.uom%TYPE;
	v_count						NUMBER;
	v_energy_star_push			property.energy_star_push%TYPE;
	v_created					BOOLEAN;
BEGIN
	INTERNAL_CheckCustomerAccess(in_est_account_sid, in_pm_customer_id, security_pkg.PERMISSION_WRITE);
	
	SELECT region_sid, meter_name||' ('||pm_meter_id||')', uom
	  INTO v_region_sid, v_meter_name, v_meter_uom
	  FROM est_meter
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND est_account_sid = in_est_account_sid 
	   AND pm_customer_id = in_pm_customer_id
	   AND pm_building_id = in_pm_building_id
	   AND pm_meter_id = in_pm_meter_id;
	
	-- Already mapped (check region sid)?
	IF v_region_sid IS NOT NULL THEN
		-- Return meter info
		GetMeter(
			in_est_account_sid,
		    in_pm_customer_id,
		    in_pm_building_id,
		    in_pm_meter_id,
		    out_cur
		);
		
		INTERNAL_ClearMissingFlag(
			in_est_account_sid,
		    in_pm_customer_id,
		    in_pm_building_id,
		    in_pm_meter_id
		);
		
		RETURN;
	END IF;
	
	-- Try to find the parent region
	SELECT pm_building_id, pm_space_id
	  INTO v_parent_building_id, v_parent_space_id
	  FROM est_meter
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND est_account_sid = in_est_account_sid 
	   AND pm_customer_id = in_pm_customer_id
	   AND pm_building_id = in_pm_building_id
	   AND pm_meter_id = in_pm_meter_id;
	
	IF v_parent_space_id IS NOT NULL THEN
		SELECT region_sid
		  INTO v_parent_region_sid
		  FROM est_space
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND est_account_sid = in_est_account_sid 
		   AND pm_customer_id = in_pm_customer_id
		   AND pm_building_id = in_pm_building_id
		   AND pm_space_id = v_parent_space_id;
	ELSIF v_parent_building_id IS NOT NULL THEN
		SELECT region_sid
		  INTO v_parent_region_sid
		  FROM est_building
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND est_account_sid = in_est_account_sid 
		   AND pm_customer_id = in_pm_customer_id
		   AND pm_building_id = in_pm_building_id;
	END IF;
	
	IF v_parent_region_sid IS NULL THEN
		INTERNAL_AddMeterError(
			in_est_account_sid,
			in_pm_customer_id,
			in_pm_building_id,
			in_pm_meter_id,
			'Meter mapping: A parent property or space region could not be found for the meter.'
		);
		-- Return meter info
		GetMeter(
			in_est_account_sid,
		    in_pm_customer_id,
		    in_pm_building_id,
		    in_pm_meter_id,
		    out_cur
		);
		RETURN;
	END IF;
	
	INTERNAL_LookupMeterType(
		in_est_account_sid,
	    in_pm_customer_id,
	    in_pm_building_id,
	    in_pm_meter_id,
	    v_meter_type_id,
	    v_measure_sid,
	    v_conversion_id
	);
	
	IF v_meter_type_id IS NOT NULL AND
	   v_measure_sid IS NOT NULL THEN
	   		   	
		-- Ok, create a new region
		v_created := FALSE;
		BEGIN
			region_pkg.CreateRegion(		
				in_parent_sid		=>	v_parent_region_sid,
				in_name				=>	v_meter_name,
				in_description		=>	v_meter_name,
				in_acquisition_dtm 	=> 	NULL,
				out_region_sid		=>	v_region_sid
			);
			v_created := TRUE;
		EXCEPTION
			WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
				SELECT region_sid
				  INTO v_region_sid
				  FROM region
				 WHERE parent_sid = v_parent_region_sid
				   AND name = REPLACE(v_meter_name, '/', '\');
		END;
		
		-- Update est schema mapping
		UPDATE est_meter
		   SET region_sid = v_region_sid,
		   	   missing = 0
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND est_account_sid = in_est_account_sid 
		   AND pm_customer_id = in_pm_customer_id
		   AND pm_building_id = in_pm_building_id
		   AND pm_meter_id = in_pm_meter_id;
		
		-- Is the property set to push?
		BEGIN			   		   	
			SELECT energy_star_push
			  INTO v_energy_star_push
			  FROM est_building b
			  JOIN property p ON p.app_sid = b.app_sid AND p.region_sid = b.region_sid
			 WHERE b.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND b.est_account_sid = in_est_account_sid 
			   AND b.pm_customer_id = in_pm_customer_id
			   AND b.pm_building_id = in_pm_building_id;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_energy_star_push := 0;
		END;
			   	
	   	-- Update the region (make it a meter etc.)
	   	-- (if the property is set to push then only update if a new meter was created)
	   	IF v_energy_star_push = 0 OR v_created THEN
			INTERNAL_UpdateMeterRgn(
				in_est_account_sid,
			    in_pm_customer_id,
			    in_pm_building_id,
			    in_pm_meter_id,
			    v_region_sid,
			    v_meter_type_id,
			    v_conversion_id
			);
		END IF;
		
	ELSE
		IF v_meter_type_id IS NULL THEN
			INTERNAL_AddMeterError(
				in_est_account_sid,
				in_pm_customer_id,
				in_pm_building_id,
				in_pm_meter_id,
				'Meter mapping: An indicator cound not be mapped to the meter.'
			);
		ELSIF v_measure_sid IS NULL THEN
			INTERNAL_AddMeterError(
				in_est_account_sid,
				in_pm_customer_id,
				in_pm_building_id,
				in_pm_meter_id,
				'Meter mapping: A unit of measure could not be mapped to the meter ('||v_meter_uom||').'
			);
		END IF;
	END IF;
	
	-- Return meter info
	GetMeter(
		in_est_account_sid,
	    in_pm_customer_id,
	    in_pm_building_id,
	    in_pm_meter_id,
	    out_cur
	);
	
END;

PROCEDURE UpdateMeterReadings(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
	in_pm_customer_id			IN	est_customer.pm_customer_id%TYPE,
	in_pm_building_id			IN	est_building.pm_building_id%TYPE,
	in_pm_meter_id				IN	est_meter.pm_meter_id%TYPE,
	in_pm_ids					IN	security_pkg.T_SID_IDS,
	in_start_dates				IN	T_DATE_ARRAY,
	in_end_dates				IN	T_DATE_ARRAY,
	in_consumptions				IN	T_VAL_ARRAY,
	in_costs					IN	T_VAL_ARRAY,
	in_estimates				IN	security_pkg.T_SID_IDS
)
AS
	v_region_sid				security_pkg.T_SID_ID;
	v_step_min_dtm				DATE;
	v_step_max_dtm				DATE;
	v_min_dtm					DATE;
	v_max_dtm					DATE;
	v_overlaps					VARCHAR2(4000);
	v_invalid_period			VARCHAR2(4000);
	v_source					meter_reading.meter_source_type_id%TYPE;
	v_reading_changed			BOOLEAN;
BEGIN	
	-- Try and get the region sid of the meter
	BEGIN
	  	SELECT em.region_sid
	  	  INTO v_region_sid
	  	  FROM est_meter em, all_meter am
	  	 WHERE em.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	  	   AND em.est_account_sid = in_est_account_sid
	  	   AND em.pm_customer_id = in_pm_customer_id
	  	   AND em.pm_building_id = in_pm_building_id
	  	   AND em.pm_meter_id = in_pm_meter_id
	  	   AND am.app_sid = em.app_sid
	   	   AND am.region_sid = em.region_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN;
	END;
	
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, v_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to region with sid '||v_region_sid);
	END IF;
	
	IF (in_consumptions.COUNT = 0 OR (in_consumptions.COUNT = 1 AND in_consumptions(1) IS NULL)) THEN
		-- nothing more to do
		RETURN;
	END IF;
	
	-- Get readings into temp table.
	-- Ignore the system lock in case the integration needed to update data outside of the client site lock period.
	INTERNAL_PrepConsumptionData(
		in_pm_ids					=> in_pm_ids,
		in_start_dates				=> in_start_dates,
		in_end_dates				=> in_end_dates,
		in_consumptions				=> in_consumptions,
		in_costs					=> in_costs,
		in_estimates				=> in_estimates,
		in_region_sid				=> v_region_sid,
		in_ignore_lock				=> TRUE
	);
	
	-- Detect overlaps
	v_overlaps := NULL;
	FOR r IN (
		SELECT DISTINCT start_dtm
		  FROM (
		  	SELECT start_dtm, end_dtm, LEAD(start_dtm) OVER (ORDER BY start_dtm) next_start_dtm
		  	  FROM temp_meter_consumptions
		  )
		 WHERE end_dtm > next_start_dtm
	) LOOP
		IF v_overlaps IS NOT NULL THEN
			v_overlaps := v_overlaps || ', ';
		END IF;
		v_overlaps := v_overlaps || TO_CHAR(r.start_dtm, 'DD FMMONTH YYYY');
	END LOOP;
	
	IF v_overlaps IS NOT NULL THEN
		-- We can do no more, raise an error
	 	INTERNAL_AddMeterError(v_region_sid, 'Meter data contains overlapping periods near: '|| v_overlaps);
	 	RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_METER_PERIOD_OVERLAP, 'Meter data contains overlapping periods');	
	END IF;
	
	-- If there's exactly a one day gap between the last end date and the 
	-- current start date then it's likely that the data ought to be contiguous 
	-- the data in the array may not be in date order though as there's no 
	-- guarantee form the data source so we need to get the data into a table 
	-- and pull it ordered by start_dtm so we can do this
	MERGE INTO temp_meter_consumptions t
	USING (
	    SELECT start_dtm, end_dtm, 
	    	LEAD(start_dtm) OVER (ORDER BY start_dtm) next_start_dtm,
	    	LEAD(start_dtm) OVER (ORDER BY start_dtm) - end_dtm gap_days
		  FROM temp_meter_consumptions
	  ) x
	  ON (t.start_dtm = x.start_dtm AND gap_days = 1)
	  WHEN MATCHED THEN
	    UPDATE SET t.end_dtm = x.next_start_dtm
	;
	
	-- Detect invalid periods
	FOR r IN (
		SELECT DISTINCT start_dtm
		  FROM (
		  	SELECT start_dtm, end_dtm
		  	  FROM temp_meter_consumptions
		  )
		 WHERE start_dtm >= end_dtm
	) LOOP
		IF v_invalid_period IS NOT NULL THEN
			v_invalid_period := v_invalid_period || ', ';
		END IF;
		v_invalid_period := v_invalid_period || TO_CHAR(r.start_dtm, 'DD FMMONTH YYYY');
	END LOOP;

	IF v_invalid_period IS NOT NULL THEN
		-- We can do no more, raise an error
	 	INTERNAL_AddMeterError(v_region_sid, 'Meter data contains invalid periods: '|| v_invalid_period);
	 	RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_METER_PERIOD_INVALID, 'Meter data contains invalid periods');	
	END IF;
	
	-- Fetch the meter's source type id
	SELECT meter_source_type_id
	  INTO v_source
	  FROM all_meter
	 WHERE region_sid = v_region_sid; 

	-- NEW SANE METHOD:
	v_reading_changed := FALSE;
	v_min_dtm := NULL;
	v_max_dtm := NULL;
	
	-- Remove anything without a PM_READING_ID
	BEGIN
		-- Capture min/max affected dates
		SELECT MIN(start_dtm), MAX(NVL(end_dtm, start_dtm))
		  INTO v_step_min_dtm, v_step_max_dtm
		  FROM meter_reading
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND meter_source_type_id = v_source
		   AND region_sid = v_region_sid
		   AND pm_reading_id IS NULL;
		
		-- Delete
		DELETE FROM meter_reading
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND meter_source_type_id = v_source
		   AND region_sid = v_region_sid
		   AND pm_reading_id IS NULL;
		
		IF SQL%ROWCOUNT > 0 THEN
			v_min_dtm := LEAST(NVL(v_min_dtm, v_step_min_dtm), NVL(v_step_min_dtm, v_min_dtm));
			v_max_dtm := GREATEST(NVL(v_max_dtm, v_step_max_dtm), NVL(v_step_max_dtm, v_max_dtm));
			v_reading_changed := TRUE;
		END IF;
		   
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;
	
	-- Remove anything where the PM_READING_ID is in
	-- V$METER_READING but not in TEMP_METER_CONSUMPTIONS 
	BEGIN
		-- Capture min/max affected dates
		SELECT MIN(start_dtm), MAX(NVL(end_dtm, start_dtm))
		  INTO v_step_min_dtm, v_step_max_dtm
		  FROM meter_reading mr, (
			  	SELECT pm_reading_id
			  	  FROM meter_reading
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND meter_source_type_id = v_source
				   AND region_sid = v_region_sid
				   AND pm_reading_id IS NOT NULL
				MINUS
				SELECT id pm_reading_id
				  FROM temp_meter_consumptions
		 ) x
		 WHERE mr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND mr.meter_source_type_id = v_source
		   AND mr.region_sid = v_region_sid
		   AND mr.pm_reading_id = x.pm_reading_id;
		
		-- Delete
		DELETE FROM meter_reading
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND meter_source_type_id = v_source
		   AND region_sid = v_region_sid
		   AND pm_reading_id IN (
			   	SELECT pm_reading_id
			  	  FROM meter_reading
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND meter_source_type_id = v_source
				   AND region_sid = v_region_sid
				   AND pm_reading_id IS NOT NULL
				MINUS
				SELECT id m_reading_id
				  FROM temp_meter_consumptions
		 );
		   
		IF SQL%ROWCOUNT > 0 THEN
			v_min_dtm := LEAST(NVL(v_min_dtm, v_step_min_dtm), NVL(v_step_min_dtm, v_min_dtm));
			v_max_dtm := GREATEST(NVL(v_max_dtm, v_step_max_dtm), NVL(v_step_max_dtm, v_max_dtm));
			v_reading_changed := TRUE;
		END IF;
		 
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;
	
	-- Modify anything where the PM_READING_ID exists in
	-- both TEMP_METER_CONSUMPTIONS and V$METER_READING
	-- And the date range, consumption or cost have changed
	FOR r IN (
		SELECT mr.meter_reading_id, mr.pm_reading_id, t.start_dtm, t.end_dtm, t.consumption, t.cost, t.is_estimate
		  FROM meter_reading mr, temp_meter_consumptions t
		 WHERE mr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND mr.meter_source_type_id = v_source
		   AND mr.region_sid = v_region_sid
		   AND mr.pm_reading_id = t.id
		   AND (
           	   mr.start_dtm != t.start_dtm
        	OR NVL(mr.end_dtm, mr.start_dtm) != NVL(t.end_dtm, t.start_dtm)
        	-- Consumption is mandatory (not null)
		   	OR mr.val_number != t.consumption
		   	-- Cost can be null
		    OR mr.cost != t.cost
		    OR (mr.cost IS NULL AND t.cost IS NOT NULL)
		    OR (mr.cost IS NOT NULL AND t.cost IS NULL)
		    OR mr.is_estimate != t.is_estimate
		   )
	) LOOP
		-- Capture min/max affected dates
		v_min_dtm := LEAST(NVL(v_min_dtm, r.start_dtm), r.start_dtm);
		v_max_dtm := GREATEST(NVL(v_max_dtm, NVL(r.end_dtm, r.start_dtm)), NVL(r.end_dtm, r.start_dtm));
		
		-- Update
		UPDATE meter_reading
		   SET start_dtm = r.start_dtm,
		   	   end_dtm = r.end_dtm,
		   	   val_number = r.consumption,
		   	   cost = r.cost,
		   	   is_estimate = r.is_estimate,
		   	   entered_by_user_sid = security_pkg.GetSID, 
		   	   entered_dtm = TRUNC(SYSDATE, 'DD')
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND meter_reading_id = r.meter_reading_id;
		   
		v_reading_changed := TRUE;
		
	END LOOP;
	
	-- Add anything where the PM_READING_ID is in 
	-- TEMP_METER_CONSUMPTIONS net not in V$METER_READING
	BEGIN
		-- Capture min/max affected dates
		SELECT MIN(start_dtm), MAX(NVL(end_dtm, start_dtm))
		  INTO v_step_min_dtm, v_step_max_dtm
	      FROM temp_meter_consumptions
	   	 WHERE id IN (
	   		SELECT id pm_reading_id
	   		  FROM temp_meter_consumptions
	   		MINUS
	   		SELECT pm_reading_id
	   		  FROM meter_reading
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND meter_source_type_id = v_source
			   AND region_sid = v_region_sid
			   AND pm_reading_id IS NOT NULL
	   );

		-- Insert
		INSERT INTO meter_reading
			(meter_reading_id, region_sid, start_dtm, end_dtm, val_number, cost, is_estimate, entered_by_user_sid, entered_dtm, meter_source_type_id, pm_reading_id)
		  SELECT meter_reading_id_seq.NEXTVAL, v_region_sid, start_dtm, end_dtm, consumption, cost, is_estimate, security_pkg.GetSID, TRUNC(SYSDATE, 'DD'), v_source, id
		    FROM temp_meter_consumptions
		   WHERE id IN (
		   		SELECT id pm_reading_id
		   		  FROM temp_meter_consumptions
		   		MINUS
		   		SELECT pm_reading_id
		   		  FROM meter_reading
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND meter_source_type_id = v_source
				   AND region_sid = v_region_sid
				   AND pm_reading_id IS NOT NULL
		   );
		   
		IF SQL%ROWCOUNT > 0 THEN
			v_min_dtm := LEAST(NVL(v_min_dtm, v_step_min_dtm), NVL(v_step_min_dtm, v_min_dtm));
			v_max_dtm := GREATEST(NVL(v_max_dtm, v_step_max_dtm), NVL(v_step_max_dtm, v_max_dtm));
			v_reading_changed := TRUE;
		END IF;
	
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;
	
	-- If a reading was updated then 
	-- recompute system indicator data
	IF v_reading_changed THEN
		-- Get min and max dates for computation of system values
		SELECT GREATEST(NVL(v_min_dtm, min_reading_dtm), min_reading_dtm),
			   LEAST(v_max_dtm, max_reading_dtm)
		  INTO v_min_dtm, v_max_dtm 
		  FROM (
			SELECT MIN(start_dtm) min_reading_dtm, NVL(MAX(end_dtm), MAX(start_dtm)) max_reading_dtm
			  FROM v$meter_reading
			 WHERE region_sid = v_region_sid
		);
		
		-- Recompute system values between captured min/max dates
		security_pkg.DebugMsg('v_min_dtm = '||v_min_dtm||', v_max_dtm = '||v_max_dtm);
		meter_pkg.SetValTableForPeriod(v_region_sid, NULL, v_min_dtm, v_max_dtm);
	END IF;
	
END;


PROCEDURE OnDeleteRegion(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
)
AS
BEGIN
	-- unmap (null out the region_sid) 
	-- any items mapped to this region sid
		
	UPDATE est_building
	   SET region_sid = NULL
	 WHERE region_sid = in_sid_id;
	
	UPDATE est_space
	   SET region_sid = NULL
	 WHERE region_sid = in_sid_id;
	
	UPDATE est_meter
	   SET region_sid = NULL
	 WHERE region_sid = in_sid_id;
END;

PROCEDURE GetBuildingMappings(
	in_include_mapped				IN	NUMBER,
	in_include_ignored				IN	NUMBER,
	in_first						IN	NUMBER,
	in_count						IN	NUMBER,
	out_total						OUT NUMBER,
    out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR 
			csr_data_pkg.CheckCapability('System management')) THEN
		
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can query buildings');
	END IF;

	SELECT COUNT(*) 
	  INTO out_total
	  FROM est_building b
	 WHERE (NVL(in_include_mapped, 1) = 1 OR b.region_sid IS NULL)
	   AND (NVL(in_include_ignored, 1) = 1 OR b.ignored = 0);

	OPEN out_cur FOR
		SELECT * 
		  FROM (SELECT b.*, ROWNUM rn 
				  FROM (SELECT b.est_account_sid, b.pm_customer_id, b.pm_building_id, b.building_name,
							   p.region_sid, r.description region_description, b.ignored, c.org_name,
							   p.energy_star_sync, p.energy_star_push
						  FROM est_building b
						  LEFT JOIN property p 
								 ON p.app_sid = b.app_sid
								AND p.pm_building_id = b.pm_building_id
						  LEFT JOIN v$region r 
								 ON p.region_sid = r.region_sid 
								AND b.app_sid = r.app_sid
						  LEFT JOIN est_customer c 
								 ON b.app_sid = c.app_sid
								AND b.est_account_sid = c.est_account_sid
								AND b.pm_customer_id = c.pm_customer_id
						 WHERE (NVL(in_include_mapped, 1) = 1 OR p.region_sid IS NULL)
						   AND (NVL(in_include_ignored, 1) = 1 OR b.ignored = 0)
						 ORDER BY b.app_sid, b.est_account_sid, b.pm_customer_id, b.pm_building_id
					   ) b
				 WHERE in_count IS NULL 
					OR ROWNUM < NVL(in_first, 1) + in_count
			   ) b
		 WHERE rn >= NVL(in_first, 1);
END;

PROCEDURE GetBuildingMappingReport(
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- Allow report to be generated by Administrators only
	IF NOT sqlreport_pkg.CheckAccess('csr.energy_star_pkg.GetBuildingMappingReport') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied creating report.');
	END IF;
	
	OPEN out_cur FOR
		SELECT
			cu.pm_customer_id "PM customer ID", 
			cu.org_name "Organisation name",
		    b.pm_building_id "PM building ID",
		    b.region_sid "Region SID", 
		    b.building_name "Building name",
		    b.city "City",
		    b.zip_code "ZIP code",
		    b.state "State",
		    b.import_dtm "Imported on",
		    r.description "Region description",
		    DECODE(b.region_sid, NULL, 'NO', 'YES') "Is mapped",
		    e.error_message "Error message",
		    DECODE(b.missing, 1, 'ACCESS DENIED', '') "Access"
		  FROM v$est_account ac, est_customer cu, est_building b, v$region r, (
		  		-- Select out last active error only
		  		SELECT app_sid, est_account_sid, pm_customer_id, pm_building_id, pm_meter_id, error_message, est_error_id
		  		  FROM (
			  		SELECT e.app_sid, e.est_account_sid, e.pm_customer_id, e.pm_building_id, e.pm_meter_id, e.error_message, e.est_error_id,
			  			ROW_NUMBER() OVER (PARTITION BY e.pm_building_id ORDER BY e.error_dtm DESC) rn
					  FROM v$est_error e
					  JOIN est_building b 
		                ON b.app_sid = e.app_sid 
		               AND b.est_account_sid = e.est_account_sid 
		               AND b.pm_customer_id = e.pm_customer_id 
		               AND b.pm_building_id = e.pm_building_id 
					 WHERE e.pm_space_id IS NULL
					   AND e.pm_meter_id IS NULL
				)
		  		WHERE rn = 1
			) e
		 WHERE ac.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND cu.est_account_sid = ac.est_account_sid
		   AND b.est_account_sid = cu.est_account_sid
		   AND b.pm_customer_id = cu.pm_customer_id
		   AND r.region_sid(+) = b.region_sid
		   AND security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), ac.est_account_sid, security_pkg.PERMISSION_READ) = 1
		   AND security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), cu.est_customer_sid, security_pkg.PERMISSION_READ) = 1
		   AND e.app_sid(+) = b.app_sid
		   AND e.est_account_sid(+) = b.est_account_sid
		   AND e.pm_customer_id(+) = b.pm_customer_id
		   AND e.pm_building_id(+) = b.pm_building_id
		    ORDER BY LOWER(cu.org_name), LOWER(b.building_name)
		;
END;

PROCEDURE GetMeterErrorsReport(
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- Allow report to be generated by Administrators only
	IF NOT sqlreport_pkg.CheckAccess('csr.energy_star_pkg.GetMeterErrorsReport') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied creating report.');
	END IF;
	
	OPEN out_cur FOR
		SELECT 
			cu.pm_customer_id "PM customer ID", 
			cu.org_name "Organisation name",
		    b.pm_building_id "PM building ID",
		    b.region_sid "Building region SID",
		    b.building_name "Building name",
		    m.pm_meter_id "PM meter ID",
		    m.region_sid "Meter region SID",
		    m.meter_name "Meter name",
		    m.meter_type "Meter type",
		    m.meter_use_type "Use type",
		    m.uom "Unit",
		    m.mapping_error "Error message"
		  FROM v$est_account ac, est_customer cu, est_building b, (
			SELECT m.est_account_sid, m.pm_customer_id, m.pm_building_id, m.pm_meter_id, m.region_sid, 
					m.meter_name, 'Energy' meter_type, m.meter_type meter_use_type, m.uom, e.error_message mapping_error
			  FROM est_meter m
			  JOIN (
					-- Select out last active error only
					SELECT app_sid, est_account_sid, pm_customer_id, pm_building_id, pm_meter_id, error_message, est_error_id
					  FROM (
						SELECT e.app_sid, e.est_account_sid, e.pm_customer_id, e.pm_building_id, e.pm_meter_id, e.error_message, e.est_error_id,
						ROW_NUMBER() OVER (PARTITION BY e.pm_meter_id ORDER BY e.error_dtm DESC) rn
						FROM v$est_error e
						JOIN est_meter m 
						ON m.app_sid = e.app_sid 
						AND m.est_account_sid = e.est_account_sid 
						AND m.pm_customer_id = e.pm_customer_id 
						AND m.pm_building_id = e.pm_building_id 
						AND m.pm_meter_id = e.pm_meter_id
					)
					WHERE rn = 1
				) e
				 ON e.app_sid = m.app_sid
				AND e.est_account_sid = m.est_account_sid
				AND e.pm_customer_id = m.pm_customer_id
				AND e.pm_building_id = m.pm_building_id
				AND e.pm_meter_id = m.pm_meter_id
			  WHERE m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		  ) m
		 WHERE ac.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND cu.est_account_sid = ac.est_account_sid
		   AND b.est_account_sid = cu.est_account_sid
		   AND b.pm_customer_id = cu.pm_customer_id
		   AND m.est_account_sid = b.est_account_sid
		   AND m.pm_customer_id = b.pm_customer_id
		   AND m.pm_building_id = b.pm_building_id
		   AND security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), ac.est_account_sid, security_pkg.PERMISSION_READ) = 1
		   AND security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), cu.est_customer_sid, security_pkg.PERMISSION_READ) = 1
		    ORDER BY LOWER(cu.org_name), LOWER(b.building_name), LOWER(m.meter_name)
		;
END;

PROCEDURE GetBuildingsNoMetersReport(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- Allow report to be generated by Administrators only
	IF NOT sqlreport_pkg.CheckAccess('csr.energy_star_pkg.GetMeterErrorsReport') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied creating report.');
	END IF;
	
	OPEN out_cur FOR
		SELECT cu.pm_customer_id "PM customer ID", 
			cu.org_name "Organisation name",
		    b.pm_building_id "PM building ID",
		    b.region_sid "Region SID", 
		    b.building_name "Building name",
		    b.city "City",
		    b.zip_code "ZIP code",
		    b.state "State",
		    b.import_dtm "Imported on",
		    r.description "Region description"
		  FROM v$est_account ac, est_customer cu, est_building b, v$region r
		 WHERE ac.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND cu.est_account_sid = ac.est_account_sid
		   AND b.est_account_sid = cu.est_account_sid
		   AND b.pm_customer_id = cu.pm_customer_id
		   AND r.region_sid = b.region_sid
		   AND security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), ac.est_account_sid, security_pkg.PERMISSION_READ) = 1
		   AND security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), cu.est_customer_sid, security_pkg.PERMISSION_READ) = 1
		   AND b.pm_building_id IN (
		   		 SELECT pm_building_id 
		   		   FROM est_building
				 MINUS
				 SELECT pm_building_id 
				   FROM est_meter
			)
		    ORDER BY LOWER(cu.org_name), LOWER(b.building_name)
		;
END;

PROCEDURE DisposeBuilding(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_building.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_building.pm_building_id%TYPE
)
AS
	v_region_sid				security_pkg.T_SID_ID;
BEGIN
	FOR r IN (
		SELECT region_sid
		  FROM est_building
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND est_account_sid = in_est_account_sid 
		   AND pm_customer_id = in_pm_customer_id
		   AND pm_building_id = in_pm_building_id
	) LOOP
		region_pkg.DisposeRegion(r.region_sid);
	END LOOP; 
END;

PROCEDURE FlagMissingBuilding(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_building.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_building.pm_building_id%TYPE
)
AS
	v_region_sid				security_pkg.T_SID_ID;
BEGIN
	UPDATE est_building
	   SET missing = 1
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND est_account_sid = in_est_account_sid 
	   AND pm_customer_id = in_pm_customer_id
	   AND pm_building_id = in_pm_building_id
	;
END;

PROCEDURE FlagIgnoredBuilding(
	in_est_account_sid				IN	security_pkg.T_SID_ID,
    in_pm_customer_id				IN	est_building.pm_customer_id%TYPE,
    in_pm_building_id				IN	est_building.pm_building_id%TYPE,
	in_ignore						IN	NUMBER
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR 
			csr_data_pkg.CheckCapability('System management')) THEN
		
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can mark buildings as ignored');
	END IF;

	UPDATE est_building
	   SET ignored = in_ignore
	 WHERE est_account_sid = in_est_account_sid 
	   AND pm_customer_id = in_pm_customer_id
	   AND pm_building_id = in_pm_building_id;
END;

PROCEDURE TrashDeadChildObjects(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_building.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_building.pm_building_id%TYPE,
	in_live_space_pmids			IN	security_pkg.T_VARCHAR2_ARRAY,
	in_live_meter_pmids			IN	security_pkg.T_VARCHAR2_ARRAY
)
AS
	v_trash_sid				security_pkg.T_SID_ID;
	t_space_pmids			security.T_VARCHAR2_TABLE;
	t_meter_pmids			security.T_VARCHAR2_TABLE;
	v_region_sids			security_pkg.T_SID_IDS;
BEGIN
	
	v_trash_sid := securableobject_pkg.GetSIDFromPath(security_pkg.getACT, security_pkg.GetAPP, 'Trash');
	t_space_pmids := security_pkg.Varchar2ArrayToTable(in_live_space_pmids);
	t_meter_pmids := security_pkg.Varchar2ArrayToTable(in_live_meter_pmids);
	
	-- Pull the building details we need
	FOR b IN (
		SELECT est_account_sid, pm_customer_id, pm_building_id, region_sid
		  FROM est_building
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND est_account_sid = in_est_account_sid 
		   AND pm_customer_id = in_pm_customer_id
		   AND pm_building_id = in_pm_building_id
	) LOOP
		
		-- SPACES:
		-- Trash anything that's missing from t_space_pmids
		FOR s IN (
			SELECT sp.pm_space_id, sp.region_sid, r.description, tr.trash_sid
			  FROM est_space sp, v$region r, trash tr, (
				SELECT pm_space_id
				  FROM est_space sp
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND est_account_sid = b.est_account_sid
				   AND pm_customer_id = b.pm_customer_id
				   AND pm_building_id = b.pm_building_id
				MINUS
				SELECT value pm_space_id
				  FROM TABLE(t_space_pmids)
			 ) x 
			 WHERE sp.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND sp.est_account_sid = b.est_account_sid
			   AND sp.pm_customer_id = b.pm_customer_id
			   AND sp.pm_building_id = b.pm_building_id
			   AND sp.pm_space_id = x.pm_space_id
			   AND r.region_sid(+) = sp.region_sid
			   AND tr.trash_sid(+) = sp.region_sid
		) LOOP
			IF s.trash_sid IS NULL AND s.region_sid IS NOT NULL THEN
				trash_pkg.TrashObject(security_pkg.getACT, s.region_sid, v_trash_sid, s.description);
			END IF;
			-- Set missing flag
			UPDATE est_space
			   SET missing = 1
			 WHERE pm_space_id = s.pm_space_id;
		END LOOP;
		
		-- Restore from trash anything that has re-appeared (same pm_space_id)
		FOR s IN (
			SELECT sp.pm_space_id, sp.region_sid, r.description, tr.trash_sid
			  FROM est_space sp, v$region r, trash tr, (
				SELECT pm_space_id
				  FROM est_space sp
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND est_account_sid = b.est_account_sid
				   AND pm_customer_id = b.pm_customer_id
				   AND pm_building_id = b.pm_building_id
				INTERSECT
				SELECT value pm_space_id
				  FROM TABLE(t_space_pmids)				
			 ) x 
			 WHERE sp.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND sp.est_account_sid = b.est_account_sid
			   AND sp.pm_customer_id = b.pm_customer_id
			   AND sp.pm_building_id = b.pm_building_id
			   AND sp.pm_space_id = x.pm_space_id
			   AND r.region_sid(+) = sp.region_sid
			   AND tr.trash_sid(+) = sp.region_sid
		) LOOP
			IF s.trash_sid IS NOT NULL AND s.region_sid IS NOT NULL THEN
				v_region_sids(1) := s.region_sid;
				trash_pkg.RestoreObjects(v_region_sids);
			END IF;
			-- Clear missing flag
			UPDATE est_space
			   SET missing = 0
			 WHERE pm_space_id = s.pm_space_id;
		END LOOP;
		
		-- METERS:
		-- Trash anything that's missing from t_meter_pmids
		FOR m IN (
			SELECT em.pm_meter_id pm_id, em.region_sid, r.description, tr.trash_sid
			  FROM est_meter em, v$region r, trash tr, (
				SELECT pm_meter_id pm_id
				  FROM est_meter sp
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND est_account_sid = b.est_account_sid
				   AND pm_customer_id = b.pm_customer_id
				   AND pm_building_id = b.pm_building_id
				MINUS
				SELECT value pm_id
				  FROM TABLE(t_meter_pmids)
			 ) x 
			 WHERE em.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND em.est_account_sid = b.est_account_sid
			   AND em.pm_customer_id = b.pm_customer_id
			   AND em.pm_building_id = b.pm_building_id
			   AND em.pm_meter_id = x.pm_id
			   AND r.region_sid(+) = em.region_sid
			   AND tr.trash_sid(+) = em.region_sid
		) LOOP
			IF m.trash_sid IS NULL AND m.region_sid IS NOT NULL THEN
				trash_pkg.TrashObject(security_pkg.getACT, m.region_sid, v_trash_sid, m.description);
			END IF;
			-- Set missing flag
			UPDATE est_meter 
			   SET missing = 1
			 WHERE pm_meter_id = m.pm_id;
		END LOOP;
		
		-- Restore from trash anything that has re-appeared (same pm_meter_id)
		FOR m IN (
			SELECT em.pm_meter_id pm_id, em.region_sid, r.description, tr.trash_sid
			  FROM est_meter em, v$region r, trash tr, (
				SELECT pm_meter_id pm_id
				  FROM est_meter sp
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND est_account_sid = b.est_account_sid
				   AND pm_customer_id = b.pm_customer_id
				   AND pm_building_id = b.pm_building_id
				INTERSECT
				SELECT value pm_id
				  FROM TABLE(t_meter_pmids)
			 ) x 
			 WHERE em.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND em.est_account_sid = b.est_account_sid
			   AND em.pm_customer_id = b.pm_customer_id
			   AND em.pm_building_id = b.pm_building_id
			   AND em.pm_meter_id = x.pm_id
			   AND r.region_sid(+) = em.region_sid
			   AND tr.trash_sid(+) = em.region_sid
		) LOOP
			IF m.trash_sid IS NOT NULL AND m.region_sid IS NOT NULL THEN
				v_region_sids(1) := m.region_sid;
				trash_pkg.RestoreObjects(v_region_sids);
			END IF;
			-- Clear missing flag
			UPDATE est_meter 
			   SET missing = 0 
			 WHERE pm_meter_id = m.pm_id 
			   AND region_sid = m.region_sid;
		END LOOP;
		
	END LOOP;
END;

PROCEDURE TrashOrphanObjects(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_building.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_building.pm_building_id%TYPE
)
AS
	v_trash_sid				security_pkg.T_SID_ID;
BEGIN
	v_trash_sid := securableobject_pkg.GetSIDFromPath(security_pkg.getACT, security_pkg.GetAPP, 'Trash');
	
	FOR bld IN (
		SELECT est_account_sid, pm_customer_id, pm_building_id, region_sid
		  FROM est_building
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND est_account_sid = in_est_account_sid 
		   AND pm_customer_id = in_pm_customer_id
		   AND pm_building_id = in_pm_building_id
	) LOOP
		-- Select all spaces that are under the building where 
		-- the space is *not* shared through EnergyStar
		FOR r IN (
			SELECT r.region_sid, r.parent_sid, r.description
			  FROM v$region r, (
				SELECT s.region_sid 
				  FROM region p, (
				  	-- Deal with nodes that are not direct children of the property
				  	SELECT CONNECT_BY_ROOT(parent_sid) fragemnt_parent_sid, region_sid, region_type
				  	  FROM region
						START WITH parent_sid = bld.region_sid
						CONNECT BY PRIOR region_sid = parent_sid
				  ) s
				 WHERE p.region_sid = bld.region_sid
				   AND p.region_sid = s.fragemnt_parent_sid
				   AND p.region_type = csr_data_pkg.REGION_TYPE_PROPERTY
				   AND s.region_type IN (
					   	csr_data_pkg.REGION_TYPE_NORMAL,
					   	csr_data_pkg.REGION_TYPE_PROPERTY,
					   	csr_data_pkg.REGION_TYPE_SPACE
				   )
				MINUS
				SELECT s.region_sid 
				  FROM est_space s
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND est_account_sid = bld.est_account_sid
				   AND pm_customer_id = bld.pm_customer_id
				   AND pm_building_id = bld.pm_building_id
			) x
			WHERE r.region_sid = x.region_sid
				ORDER BY parent_sid, region_sid
		) LOOP
			trash_pkg.TrashObject(security_pkg.getACT, r.region_sid, v_trash_sid, r.description);	
		END LOOP;
		
		-- Select all meters that are under the building where 
		-- the meter is *not* shared through EnergyStar
		FOR r IN (
			SELECT r.region_sid, r.parent_sid, r.description
			  FROM v$region r, (
				SELECT s.region_sid 
				  FROM region p, (
				  	-- Deal with nodes that are not direct children of the property
				  	SELECT CONNECT_BY_ROOT(parent_sid) fragemnt_parent_sid, region_sid, region_type
				  	  FROM region
						START WITH parent_sid = bld.region_sid
						CONNECT BY PRIOR region_sid = parent_sid
				  ) s
				 WHERE p.region_sid = bld.region_sid
				   AND p.region_sid = s.fragemnt_parent_sid
				   AND p.region_type = csr_data_pkg.REGION_TYPE_PROPERTY
				   AND s.region_type = csr_data_pkg.REGION_TYPE_METER
				MINUS
				SELECT s.region_sid 
				  FROM est_meter s
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND est_account_sid = bld.est_account_sid
				   AND pm_customer_id = bld.pm_customer_id
				   AND pm_building_id = bld.pm_building_id
			) x
			WHERE r.region_sid = x.region_sid
				ORDER BY parent_sid, region_sid
		) LOOP
			trash_pkg.TrashObject(security_pkg.getACT, r.region_sid, v_trash_sid, r.description);	
		END LOOP;
		
	END LOOP;
END;


PROCEDURE GetBuildingRatingReport(
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- Allow report to be generated by Administrators only
	IF NOT sqlreport_pkg.CheckAccess('csr.energy_star_pkg.GetBuildingRatingReport') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied creating report.');
	END IF;
	
	OPEN out_cur FOR
		SELECT b.pm_customer_id "PM customer ID", 
			   b.pm_building_id "PM building ID", 
			   b.building_name "Energy Star name", 
			   b.region_sid "Region SID", 
			   r.description "Credit360 name", 
			   period_end_dtm "Period", 
			   val "Rating"
		  FROM est_building_metric bm, est_building b, v$region r
		 WHERE b.pm_customer_id = bm.pm_customer_id
		   AND b.pm_building_id = bm.pm_building_id
		   AND r.region_sid(+) = b.region_sid
		   AND bm.metric_name = 'rating' 
		   AND bm.period_end_dtm >= DATE '2012-01-01'
		   AND bm.period_end_dtm < DATE '2013-01-01'
		   AND bm.val is not NULL
		    ORDER BY bm.pm_customer_id, bm.pm_building_id, period_end_dtm
	;
	
END;

PROCEDURE MapNewBrSpaces(
	in_account_sid				IN	security_pkg.T_SID_ID,
	in_pm_customer_id			IN	est_building.pm_customer_id%TYPE,
	in_pm_building_id			IN	est_building.pm_building_id%TYPE
)
AS
	v_cur						security_pkg.T_OUTPUT_CUR;
BEGIN
	-- Select any space which has a null region sid but
	-- only if the parent building has a non-null region sid
	FOR r IN (
		SELECT s.est_account_sid, s.pm_customer_id, s.pm_building_id, s.pm_space_id
		  FROM est_building b, est_space s
		 WHERE b.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND s.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND b.est_account_sid = in_account_sid
		   AND b.pm_customer_id = in_pm_customer_id
		   AND b.pm_building_id = in_pm_building_id
		   AND s.est_account_sid = in_account_sid
		   AND s.pm_customer_id = in_pm_customer_id
		   AND s.pm_building_id = in_pm_building_id
		   AND b.region_sid IS NOT NULL
		   AND s.region_sid IS NULL
	) LOOP
		MapSpace(
			r.est_account_sid,
			r.pm_customer_id,
			r.pm_building_id,
			r.pm_space_id,
			v_cur
		);
	END LOOP;
END;

-----

PROCEDURE GetMetricsToRequest(
	in_est_account_sid		IN	security_pkg.T_SID_ID,
	in_read_only			IN	est_building_metric_mapping.read_only%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_start_dtm				DATE;
	v_end_dtm				DATE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_est_account_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading account with SID '||in_est_account_sid);
	END IF;
	
	-- XXX: We should be able to confiigure the date range somehow
	v_start_dtm := TO_DATE('2012-01-01', 'YYYY-mm-dd');
	v_end_dtm := TRUNC(SYSDATE, 'MONTH');
	
	OPEN out_cur FOR
		SELECT DISTINCT m.metric_name, x.dtm period_end_dtm
		  FROM est_building_metric_mapping m, (
		  	SELECT ADD_MONTHS(v_start_dtm, rownum - 1) dtm
			  FROM DUAL
			    CONNECT BY ADD_MONTHS(v_start_dtm, rownum - 1) <= v_end_dtm
    	  ) x
		 WHERE m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND m.est_account_sid = in_est_account_sid
		   AND m.simulated = 0
		   AND m.read_only = DECODE(in_read_only, 0, m.read_only, 1)
		   	ORDER BY x.dtm;
END;

PROCEDURE UnmapMeter(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_meter.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_meter.pm_building_id%TYPE,
    in_pm_meter_id				IN	est_meter.pm_meter_id%TYPE
)
AS
	v_region_sid				security_pkg.T_SID_ID;
BEGIN
	INTERNAL_CheckCustomerAccess(in_est_account_sid, in_pm_customer_id, security_pkg.PERMISSION_WRITE);
	
	-- Clear down the pm_reading_id from the meter reading table
	BEGIN
		SELECT region_sid
		  INTO v_region_sid
		  FROM est_meter
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND est_account_sid = in_est_account_sid 
		   AND pm_customer_id = in_pm_customer_id
		   AND pm_building_id = in_pm_building_id
		   AND pm_meter_id = in_pm_meter_id;

		UPDATE meter_reading
		   SET pm_reading_id = NULL
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND region_sid = v_region_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL; -- Ignore
	END;

	-- Unmap the meter
	UPDATE est_meter
	   SET region_sid = NULL,
	       last_poll_dtm = NULL,
	       last_job_dtm = NULL
	 WHERE est_account_sid = in_est_account_sid 
	   AND pm_customer_id = in_pm_customer_id
	   AND pm_building_id = in_pm_building_id
	   AND pm_meter_id = in_pm_meter_id;
END;

PROCEDURE UnmapSpace(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_space.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_space.pm_building_id%TYPE,
    in_pm_space_id				IN	est_space.pm_space_id%TYPE
)
AS
BEGIN
	INTERNAL_CheckCustomerAccess(in_est_account_sid, in_pm_customer_id, security_pkg.PERMISSION_WRITE);

	-- Clear out region_metric_val_id from the est_space_attr table
	UPDATE est_space_attr
	   SET region_metric_val_id = NULL
	 WHERE est_account_sid = in_est_account_sid 
	   AND pm_customer_id = in_pm_customer_id
	   AND pm_building_id = in_pm_building_id
	   AND pm_space_id = in_pm_space_id;

	-- Unmap the space
	UPDATE est_space
	   SET region_sid = NULL
	 WHERE est_account_sid = in_est_account_sid 
	   AND pm_customer_id = in_pm_customer_id
	   AND pm_building_id = in_pm_building_id
	   AND pm_space_id = in_pm_space_id;
END;


PROCEDURE UnmapBuilding(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_building.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_building.pm_building_id%TYPE
)
AS
	v_region_sid				security_pkg.T_SID_ID;
BEGIN
	INTERNAL_CheckCustomerAccess(in_est_account_sid, in_pm_customer_id, security_pkg.PERMISSION_WRITE);

	BEGIN	
		SELECT region_sid
		  INTO v_region_sid
		  FROM est_building
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND est_account_sid = in_est_account_sid 
		   AND pm_customer_id = in_pm_customer_id
		   AND pm_building_id = in_pm_building_id;
	EXCEPTION 
		WHEN NO_DATA_FOUND THEN
			v_region_sid := NULL;
	END;
	
	IF v_region_sid IS NOT NULL THEN
	
		-- Unmap child spaces
		FOR r IN (
			SELECT pm_space_id
			  FROM est_space
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND est_account_sid = in_est_account_sid 
			   AND pm_customer_id = in_pm_customer_id
			   AND pm_building_id = in_pm_building_id
		) LOOP
			UnmapSpace(
				in_est_account_sid ,
				in_pm_customer_id,
				in_pm_building_id,
				r.pm_space_id
			);
		END LOOP;
		
		-- Unmap child meters
		FOR r IN (
			SELECT pm_meter_id pm_meter_id
			  FROM est_meter
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND est_account_sid = in_est_account_sid 
			   AND pm_customer_id = in_pm_customer_id
			   AND pm_building_id = in_pm_building_id
		) LOOP
			UnmapMeter(
				in_est_account_sid ,
				in_pm_customer_id,
				in_pm_building_id,
				r.pm_meter_id
			);
		END LOOP;
	END IF; 

	-- Unmap building
	UPDATE est_building
	   SET region_sid = NULL,
	   	   last_poll_dtm = NULL,
	   	   last_job_dtm = NULL
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND est_account_sid = in_est_account_sid 
	   AND pm_customer_id = in_pm_customer_id
	   AND pm_building_id = in_pm_building_id;
END;

PROCEDURE MappingHelper (
	in_est_account_sid		security_pkg.T_SID_ID,
	in_region_sid			security_pkg.T_SID_ID,
	in_pm_building_id		est_building.pm_building_id%TYPE,
	in_trash_orphans		NUMBER DEFAULT 1
)
AS
	v_pm_customer_id		est_building.pm_customer_id%TYPE;
	v_pm_building_id		est_building.pm_building_id%TYPE;
	v_cur					security.security_pkg.T_OUTPUT_CUR;
	v_timestamp				DATE;
BEGIN

	-- Check that the region is in the property table (error otherwise).
	SELECT pm_building_id, SYSDATE
	  INTO v_pm_building_id, v_timestamp
	  FROM property
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND region_sid = in_region_sid;
	   
	-- Get the customer ID for this building
	-- The building might not be shared yet
	BEGIN
		SELECT pm_customer_id
		  INTO v_pm_customer_id
		  FROM est_building
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		    AND est_account_sid = in_est_account_sid
		  	AND pm_building_id = in_pm_building_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_pm_customer_id := NULL;
	END;
	  	
	-- Clear any existing mappings for this region where
	-- the building is different to that specified
	FOR r IN (
		SELECT est_account_sid, pm_customer_id, pm_building_id
		  FROM csr.est_building
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	  	   AND est_account_sid = in_est_account_sid
	  	   AND region_sid = in_region_sid
	  	   AND pm_building_id != NVL(in_pm_building_id, -1) -- Exclude if it's already mapped correctly
	) LOOP
		UnmapBuilding(r.est_account_sid, r.pm_customer_id, r.pm_building_id);
	END LOOP;
	
	-- Clear any existing mappings for this building where 
	-- the region sid is different to that specified 
	FOR r IN (
		SELECT est_account_sid, pm_customer_id, pm_building_id
		  FROM csr.est_building
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	  	   AND est_account_sid = in_est_account_sid
	  	   AND pm_building_id = in_pm_building_id
	  	   AND region_sid != in_region_sid -- Exclude if it's already mapped correctly
	) LOOP
		UnmapBuilding(r.est_account_sid, r.pm_customer_id, r.pm_building_id);
	END LOOP;
	
	-- Clear any existing property table mappings to this building id
	UPDATE csr.property
	   SET pm_building_id = NULL
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND pm_building_id = in_pm_building_id;
	   
	-- Set the id on the single property
	UPDATE csr.property
	   SET pm_building_id = in_pm_building_id
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND region_sid = in_region_sid;
	
	
	-- If the pm customer id is null then the building is not shared yet.
	-- We can only map if the building has been shared.
	IF v_pm_customer_id IS NOT NULL THEN
		
		-- Map the building
		MapBuilding(in_est_account_sid, v_pm_customer_id, in_pm_building_id, v_cur);
		MarkErrorsInactive(v_timestamp, in_est_account_sid, v_pm_customer_id, in_pm_building_id);
		
		-- Map child spaces
		FOR s IN (
			SELECT pm_space_id
			  FROM csr.est_space
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND est_account_sid = in_est_account_sid
			   AND pm_customer_id = v_pm_customer_id
			   AND pm_building_id = in_pm_building_id
		) LOOP
			csr.energy_star_pkg.MapSpace(in_est_account_sid, v_pm_customer_id, in_pm_building_id, s.pm_space_id, v_cur);
			MarkErrorsInactive(v_timestamp, in_est_account_sid, v_pm_customer_id, in_pm_building_id, s.pm_space_id);
		END LOOP;
		
		-- Map energy meters
		FOR m IN (
			SELECT pm_meter_id
			  FROM csr.est_meter
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND est_account_sid = in_est_account_sid
			   AND pm_customer_id = v_pm_customer_id
			   AND pm_building_id = in_pm_building_id
		) LOOP
			csr.energy_star_pkg.MapMeter(in_est_account_sid, v_pm_customer_id, in_pm_building_id, m.pm_meter_id, NULL, v_cur);
			MarkErrorsInactive(v_timestamp, in_est_account_sid, v_pm_customer_id, in_pm_building_id, NULL, m.pm_meter_id);
		END LOOP;
		
		-- Trash any orphan objects in the region tree (spaces and meters)
		IF in_trash_orphans != 0 THEN
			csr.energy_star_pkg.TrashOrphanObjects(in_est_account_sid, v_pm_customer_id, in_pm_building_id);
		END IF;
	END IF;

END;

PROCEDURE CreateOutstandingReqJob(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_batch_job_id				batch_job.batch_job_id%TYPE;
	v_account_name				VARCHAR2(255) := 'credit360_energystar';
BEGIN
	
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_est_account_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the account with sid '||in_est_account_sid);
	END IF;

	batch_job_pkg.Enqueue(
	    in_batch_job_type_id            => batch_job_pkg.JT_ENERGY_STAR_SHARING_REQ,
	    in_description                  => 'Outstanding requests for account ' || v_account_name,
	    in_email_on_completion          => 0, -- We want to send the alert ourselves so we can add the attachment (bit of a hack)
	    out_batch_job_id                => v_batch_job_id
	);
	
	INSERT INTO outstanding_requests_job (est_account_sid, batch_job_id)
	     VALUES (in_est_account_sid, v_batch_job_id);
	
	OPEN out_cur FOR
		SELECT j.batch_job_id, j.est_account_sid, v_account_name as user_name
		  FROM outstanding_requests_job j, v$est_account a
		 WHERE j.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND j.batch_job_id = v_batch_job_id
		   AND j.est_account_sid = in_est_account_sid
		   AND a.app_sid = j.app_sid
		   AND a.est_account_sid = j.est_account_sid;
END;

PROCEDURE GetOutstandingReqJob(
	in_batch_job_id				IN	batch_job.batch_job_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT aj.app_sid, aj.est_account_sid, aj.batch_job_id,
			   bj.requested_by_user_sid, bj.email_on_completion, bjt.sp, bj.description,
			   bjt.batch_job_type_id, bjt.description batch_job_type_description, bjt.plugin_name
		  FROM outstanding_requests_job aj, batch_job bj, batch_job_type bjt
		 WHERE aj.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND aj.batch_job_id = in_batch_job_id
		   AND bj.app_sid = aj.app_sid
		   AND bj.batch_job_id = aj.batch_job_id
		   AND bj.batch_job_type_id = bjt.batch_job_type_id;
END;

PROCEDURE GetMeterReadings(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
    in_pm_customer_id			IN	est_meter.pm_customer_id%TYPE,
    in_pm_building_id			IN	est_meter.pm_building_id%TYPE,
    in_pm_meter_id				IN	est_meter.pm_meter_id%TYPE,
    out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_region_sid				security_pkg.T_SID_ID;
BEGIN
	SELECT region_sid
	  INTO v_region_sid
	  FROM est_meter
	 WHERE est_account_sid = in_est_account_sid
	   AND pm_customer_id = in_pm_customer_id
	   AND pm_building_id = in_pm_building_id
	   AND pm_meter_id = in_pm_meter_id;
	
	GetMeterReadings(
		v_region_sid,
		out_cur
	);
	
END;	

PROCEDURE GetMeterReadings(
    in_region_sid				IN	security_pkg.T_SID_ID,
    out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_arbitrary_period			meter_source_type.arbitrary_period%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to region with sid '||in_region_sid);
	END IF;
	
	SELECT st.arbitrary_period
	  INTO v_arbitrary_period
	  FROM all_meter m
	  JOIN meter_source_type st ON m.app_sid = st.app_sid AND m.meter_source_type_id = st.meter_source_type_id
	 WHERE m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND m.region_sid = in_region_sid;
	
	IF v_arbitrary_period = 0 THEN
		OPEN out_cur FOR
			SELECT mr.meter_reading_id, mr.start_dtm,  NULL end_dtm, NULL cost, mr.pm_reading_id, 0 is_deleted,
				mr.val_number - LAG(mr.val_number) OVER (ORDER BY mr.start_dtm) val_number
			  FROM v$meter_reading mr
			 WHERE mr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND mr.region_sid = in_region_sid;
	ELSE
		OPEN out_cur FOR
			SELECT mr.meter_reading_id, mr.start_dtm, mr.end_dtm, mr.cost, mr.pm_reading_id, 0 is_deleted,
				mr.val_number
			  FROM v$meter_reading mr
			 WHERE mr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND mr.region_sid = in_region_sid;
	END IF;
END;

PROCEDURE UpdatePmReadingIds(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
	in_pm_customer_id			IN	est_customer.pm_customer_id%TYPE,
	in_pm_building_id			IN	est_building.pm_building_id%TYPE,
	in_pm_meter_id				IN	est_meter.pm_meter_id%TYPE,
	in_reading_ids				IN	security_pkg.T_SID_IDS,
	in_pm_ids					IN	security_pkg.T_SID_IDS
)
AS
	v_region_sid				security_pkg.T_SID_ID;
BEGIN
	IF (in_reading_ids.COUNT = 0 OR (in_reading_ids.COUNT = 1 AND in_reading_ids(1) IS NULL)) THEN
		RETURN; -- Means nothing in the list
	END IF;
	
	-- Get the region sid of the meter
	SELECT region_sid
	  INTO v_region_sid
	  FROM est_meter
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND est_account_sid = in_est_account_sid
	   AND pm_customer_id = in_pm_customer_id
	   AND pm_building_id = in_pm_building_id
	   AND pm_meter_id = in_pm_meter_id;
	
	-- Update the pm ids for the meter readings
	FOR i IN in_reading_ids.FIRST .. in_reading_ids.LAST
	LOOP
		IF in_reading_ids.EXISTS(i) THEN
			UPDATE meter_reading
			   SET pm_reading_id = in_pm_ids(i)
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND region_sid = v_region_sid
			   AND meter_reading_id = in_reading_ids(i);
		END IF;
	END LOOP;
END;

PROCEDURE DeleteBuilding(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
	in_pm_customer_id			IN	est_customer.pm_customer_id%TYPE,
	in_pm_building_id			IN	est_building.pm_building_id%TYPE
)
AS
BEGIN
	INTERNAL_CheckCustomerAccess(in_est_account_sid, in_pm_customer_id, security_pkg.PERMISSION_WRITE);
	
	-- We need to remove any associated change logs too
	-- (this will lock the app for energy star)
	energy_star_job_pkg.DeleteChangeLogs(
		in_est_account_sid	=> in_est_account_sid,
		in_pm_customer_id	=> in_pm_customer_id,
		in_pm_building_id	=> in_pm_building_id
	);
	
	DELETE FROM est_space_attr
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND est_account_sid = in_est_account_sid
	   AND pm_customer_id = in_pm_customer_id
	   AND pm_building_id = in_pm_customer_id;
	
	DELETE FROM est_space
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND est_account_sid = in_est_account_sid
	   AND pm_customer_id = in_pm_customer_id
	   AND pm_building_id = in_pm_building_id;
	   
	DELETE FROM est_meter
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND est_account_sid = in_est_account_sid
	   AND pm_customer_id = in_pm_customer_id
	   AND pm_building_id = in_pm_building_id;
	
	DELETE FROM est_building_metric
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND est_account_sid = in_est_account_sid
	   AND pm_customer_id = in_pm_customer_id
	   AND pm_building_id = in_pm_building_id;
	   
	DELETE FROM est_building
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND est_account_sid = in_est_account_sid
	   AND pm_customer_id = in_pm_customer_id
	   AND pm_building_id = in_pm_building_id;
END;


PROCEDURE DeleteSpace(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
	in_pm_customer_id			IN	est_customer.pm_customer_id%TYPE,
	in_pm_building_id			IN	est_building.pm_building_id%TYPE,
	in_pm_space_id				IN	est_space.pm_space_id%TYPE
)
AS
BEGIN
	INTERNAL_CheckCustomerAccess(in_est_account_sid, in_pm_customer_id, security_pkg.PERMISSION_WRITE);
	
	-- We need to remove any associated change logs too
	-- (this will lock the app for energy star)
	energy_star_job_pkg.DeleteChangeLogs(
		in_est_account_sid	=> in_est_account_sid,
		in_pm_customer_id	=> in_pm_customer_id,
		in_pm_building_id	=> in_pm_building_id,
		in_pm_space_id		=> in_pm_space_id
	);
	
	UPDATE est_meter
	   SET pm_space_id = NULL
	 WHERE est_account_sid = in_est_account_sid
	   AND pm_customer_id = in_pm_customer_id
	   AND pm_building_id = in_pm_building_id
	   AND pm_space_id = in_pm_space_id;
		
	DELETE FROM est_space_attr
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND est_account_sid = in_est_account_sid
	   AND pm_customer_id = in_pm_customer_id
	   AND pm_building_id = in_pm_building_id
	   AND pm_space_id = in_pm_space_id;
	
	DELETE FROM est_space
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND est_account_sid = in_est_account_sid
	   AND pm_customer_id = in_pm_customer_id
	   AND pm_building_id = in_pm_building_id
	   AND pm_space_id = in_pm_space_id;
END;


PROCEDURE DeleteMeter(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
	in_pm_customer_id			IN	est_customer.pm_customer_id%TYPE,
	in_pm_building_id			IN	est_building.pm_building_id%TYPE,
	in_pm_meter_id				IN	est_meter.pm_meter_id%TYPE
)
AS
BEGIN
	INTERNAL_CheckCustomerAccess(in_est_account_sid, in_pm_customer_id, security_pkg.PERMISSION_WRITE);
	
	-- We need to remove any associated change logs too
	-- (this will lock the app for energy star)
	energy_star_job_pkg.DeleteChangeLogs(
		in_est_account_sid	=> in_est_account_sid,
		in_pm_customer_id	=> in_pm_customer_id,
		in_pm_building_id	=> in_pm_building_id,
		in_pm_meter_id		=> in_pm_meter_id
	);
	
	DELETE FROM est_meter
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND est_account_sid = in_est_account_sid
	   AND pm_customer_id = in_pm_customer_id
	   AND pm_building_id = in_pm_building_id
	   AND pm_meter_id = in_pm_meter_id;
END;

PROCEDURE AddError(
	in_app_sid					IN	security_pkg.T_SID_ID			DEFAULT SYS_CONTEXT('SECURITY', 'APP'),
	in_region_sid				IN	security_pkg.T_SID_ID			DEFAULT NULL,
	in_est_account_sid			IN	security_pkg.T_SID_ID			DEFAULT NULL,
	in_pm_customer_id			IN	est_error.pm_customer_id%TYPE	DEFAULT NULL,
	in_pm_building_id			IN	est_error.pm_building_id%TYPE	DEFAULT NULL,
	in_pm_space_id				IN	est_error.pm_space_id%TYPE		DEFAULT NULL,
	in_pm_meter_id				IN	est_error.pm_meter_id%TYPE		DEFAULT NULL,
	in_error_level				IN	est_error.error_level%TYPE		DEFAULT 0,
	in_error_code				IN	est_error.error_code%TYPE,
	in_error_message			IN	est_error.error_message%TYPE,
	in_request_url				IN	est_error.request_url%TYPE		DEFAULT NULL,
	in_request_header			IN	est_error.request_header%TYPE	DEFAULT NULL,
	in_request_body				IN	est_error.request_body%TYPE		DEFAULT NULL,
	in_response					IN	est_error.response%TYPE			DEFAULT NULL
)
AS
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN

	-- Try and update an existing error which is "caused by the same issue"
	UPDATE est_error
	   SET error_level = in_error_level,
	       error_code = in_error_code,
	       request_header = in_request_header,
	       request_body = in_request_body,
	       response = in_response,
	       active = 1,
	       error_dtm = SYSDATE
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND NVL(region_sid, -1) = NVL(in_region_sid, -1)
	   AND NVL(est_account_sid, -1) = NVL(in_est_account_sid, -1)
	   AND NVL(pm_customer_id, 'x') = NVL(in_pm_customer_id, 'x')
	   AND NVL(pm_building_id, 'x') = NVL(in_pm_building_id, 'x')
	   AND NVL(pm_space_id, 'x') = NVL(in_pm_space_id, 'x')
	   AND NVL(pm_meter_id, 'x') = NVL(in_pm_meter_id, 'x')
	   AND error_message = in_error_message
	   AND NVL(request_url, 'x') = NVL(in_request_url, 'x')
	;

	-- If there was nothing to update then insert a new error row
	IF SQL%ROWCOUNT = 0 THEN
		INSERT INTO est_error (app_sid, est_error_id, region_sid, est_account_sid, pm_customer_id, pm_building_id, pm_space_id, pm_meter_id,
				error_level, error_code, error_message, request_url, request_header, request_body, response, error_dtm, active)
		VALUES (in_app_sid, est_error_id_seq.NEXTVAL, in_region_sid, in_est_account_sid, in_pm_customer_id, in_pm_building_id, in_pm_space_id, in_pm_meter_id,
				in_error_level, in_error_code, in_error_message, in_request_url, in_request_header, in_request_body, in_response, SYSDATE, 1);
	END IF;

	COMMIT;
END;

PROCEDURE GetDbTimestamp(
	-- We don't have a RunSP/RunSF return date
	out_cur						OUT security_pkg.T_OUTPUT_CUR 
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT SYSDATE db_timestamp
		  FROM DUAL;
END;

PROCEDURE MarkErrorsInactive(
	in_before_dtm				IN	DATE,
	in_est_account_sid			IN	security_pkg.T_SID_ID,
	in_pm_customer_id			IN	est_error.pm_customer_id%TYPE,
	in_pm_building_id			IN	est_error.pm_building_id%TYPE,
	in_pm_space_id				IN	est_error.pm_space_id%TYPE		DEFAULT NULL,
	in_pm_meter_id				IN	est_error.pm_meter_id%TYPE		DEFAULT NULL
)
AS
	v_region_sid				security_pkg.T_SID_ID;
BEGIN
	INTERNAL_CheckCustomerAccess(in_est_account_sid, in_pm_customer_id, security_pkg.PERMISSION_WRITE);
	
	-- Deactivate errors based on the pm id 
	UPDATE est_error
	   SET active = 0
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND est_account_sid = in_est_account_sid
	   AND pm_customer_id = in_pm_customer_id
	   AND pm_building_id = in_pm_building_id
	   -- Buildings and spaces are intrinsically linked
	   AND NVL(pm_space_id, -1) = NVL(DECODE(in_pm_space_id, NULL, pm_space_id, in_pm_space_id), -1)
	   -- Meters behave more like separate entities
	   AND NVL(pm_meter_id, -1) = NVL(in_pm_meter_id, -1)
	   AND active = 1
	   AND error_dtm < in_before_dtm
	;

	-- Deactivate any errors linked directly to the associated region
	-- (jobs with a region sid don't specify the pm ids)
	BEGIN
		SELECT region_sid
		  INTO v_region_sid
		  FROM (
			SELECT region_sid
			  FROM est_building
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND est_account_sid = in_est_account_sid
			   AND pm_customer_id = in_pm_customer_id
			   AND pm_building_id = in_pm_building_id
			   AND in_pm_space_id IS NULL
			   AND in_pm_meter_id IS NULL
			UNION
			SELECT region_sid
			  FROM est_space
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND est_account_sid = in_est_account_sid
			   AND pm_customer_id = in_pm_customer_id
			   AND pm_building_id = in_pm_building_id
			   AND pm_space_id = in_pm_space_id
			   AND in_pm_meter_id IS NULL
			UNION
			SELECT region_sid
			  FROM est_meter
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND est_account_sid = in_est_account_sid
			   AND pm_customer_id = in_pm_customer_id
			   AND pm_building_id = in_pm_building_id
			   AND pm_meter_id = in_pm_meter_id
		);
		-- Deactivate using the region sid
		IF v_region_sid IS NOT NULL THEN
			MarkErrorsInactive(in_before_dtm, v_region_sid);
		END IF;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL; -- Ignore
	END;
END;

PROCEDURE MarkErrorsInactive(
	in_before_dtm				IN	DATE,
	in_region_sid				IN	security_pkg.T_SID_ID
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to region with sid '||in_region_sid);
	END IF;
	
	UPDATE est_error
	   SET active = 0
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND region_sid = in_region_sid
	   AND active = 1
	   AND error_dtm < in_before_dtm
	;
END;

PROCEDURE MarkErrorInactive(
	in_error_id					IN	est_error.est_error_id%TYPE,
	in_property_region_sid		IN	security_pkg.T_SID_ID -- For the code below to work the region sid should be a property, just making that clearer in the code.
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_property_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to region with sid '||in_property_region_sid);
	END IF;
	
	-- Match the error on error_id and region_sid 
	UPDATE est_error
	   SET active = 0
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND est_error_id = in_error_id
	   AND active = 1
	   AND region_sid IN (
			-- The region_sid in the error could be for a child space or child meter
			SELECT region_sid
			  FROM region
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			 START WITH region_sid = in_property_region_sid
			 CONNECT BY PRIOR region_sid = parent_sid
	   );

	-- Match the error on error_id and pm_building_id
	-- Note: This will only work if the input region_sid is for a property (building)
	UPDATE est_error
	   SET active = 0
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND est_error_id = in_error_id
	   AND active = 1
	   AND pm_building_id IN (
			-- Map the property region_sid to a pm_building_id:
			-- If the PM ID is specified, even for a space or a meter,
			-- then the pm_building_id is always available in the error.
			SELECT pm_building_id
			  FROM est_building
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND region_sid = in_property_region_sid
	   );
END;

PROCEDURE PurgeInactiveErrors
AS
	v_months_old			NUMBER := 1;
BEGIN
	-- Purge any inactive errors over a month old
	-- (no FKs to worry about)
	DELETE FROM est_error
	 WHERE active = 0
	   AND ADD_MONTHS(error_dtm, v_months_old) < SYSDATE;
END;

PROCEDURE GetError (
	in_est_error_id				IN	security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, securableobject_pkg.GetSIDFromPath(security_pkg.GetACT, security_pkg.GetAPP, 'EnergyStar'), security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on energy star node');
	END IF;
	
	OPEN out_cur FOR
		SELECT e.est_error_id, e.region_sid, e.est_account_sid, e.pm_customer_id, e.pm_building_id, e.pm_space_id, e.pm_meter_id,
			e.error_level, e.error_dtm, e.error_code,
			e.request_url, e.request_header, e.request_body, e.response,
			e.active,
			r.description region_desc,
			e.error_message raw_message,
			NVL(ed.help_text, e.error_message) error_message,
			NVL(b1.building_name, b2.building_name) est_building_name,
			NVL(s1.space_name, s2.space_name) est_space_name,
			NVL(m1.meter_name, m2.meter_name) est_meter_name
		  FROM est_error e
		  LEFT JOIN est_building b1 ON b1.app_sid = e.app_sid AND b1.region_sid = e.region_sid
		  LEFT JOIN est_building b2 ON b2.app_sid = e.app_sid AND b2.est_account_sid = e.est_account_sid AND b2.pm_customer_id = e.pm_customer_id AND b2.pm_building_id = e.pm_building_id 
		  LEFT JOIN est_space s1 ON b1.app_sid = e.app_sid AND s1.region_sid = e.region_sid
		  LEFT JOIN est_space s2 ON b2.app_sid = e.app_sid AND s2.est_account_sid = e.est_account_sid AND s2.pm_customer_id = e.pm_customer_id AND s2.pm_building_id = e.pm_building_id AND s2.pm_space_id = e.pm_space_id
		  LEFT JOIN est_meter m1 ON b1.app_sid = e.app_sid AND m1.region_sid = e.region_sid
		  LEFT JOIN est_meter m2 ON b2.app_sid = e.app_sid AND m2.est_account_sid = e.est_account_sid AND m2.pm_customer_id = e.pm_customer_id AND m2.pm_building_id = e.pm_building_id AND m2.pm_meter_id = e.pm_meter_id
		  LEFT JOIN v$region r ON r.app_sid = e.app_sid AND r.region_sid = COALESCE(e.region_sid, b1.region_sid, b2.region_sid, s1.region_sid, s2.region_sid, m1.region_sid, m2.region_sid)
		  LEFT JOIN v$est_error_description ed ON ed.est_error_id = e.est_error_id
		 WHERE e.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND e.est_error_id = in_est_error_id;
END;

PROCEDURE GetErrorsForProperty (
	in_region_sid				IN	security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetErrorsForProperty(in_region_sid, 0, out_cur);
END;

PROCEDURE GetErrorsForProperty (
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_include_inactive			IN	NUMBER	DEFAULT 0,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to property with sid '||in_region_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT e.est_error_id, e.region_sid, e.est_account_sid, e.pm_customer_id, e.pm_building_id, e.pm_space_id, e.pm_meter_id,
			e.error_level, e.error_dtm, e.error_code, e.error_message raw_message,
			e.request_url, e.request_header, e.request_body, e.response, e.active,
			x.region_desc, x.est_building_name, NULL est_space_name, NULL est_meter_name,
			NVL(ed.help_text, e.error_message) error_message
		  FROM (
			SELECT e.app_sid, e.est_error_id, 
				MAX(e.region_desc) region_desc, 
				MAX(e.est_building_name) est_building_name
			  FROM (
				-- Match by region sid
				SELECT e.app_sid, e.est_error_id,
					r.description region_desc, b.building_name est_building_name
				  FROM est_error e
				  JOIN v$region r ON r.app_sid = e.app_sid AND r.region_sid = e.region_sid
				  LEFT JOIN est_building b ON b.app_sid = e.app_sid AND b.region_sid = e.region_sid
				  LEFT JOIN est_space s ON s.app_sid = e.app_sid AND s.region_sid = e.region_sid
				  LEFT JOIN est_meter m ON m.app_sid = e.app_sid AND m.region_sid = e.region_sid
				 WHERE e.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND e.active = DECODE(in_include_inactive, 0, 1, e.active)
				   AND e.region_sid = in_region_sid
				UNION
				-- Match by pm building id
				SELECT e.app_sid, e.est_error_id,
					r.description region_desc, b.building_name est_building_name
				  FROM est_error e
				  JOIN est_building b ON b.app_sid = e.app_sid AND b.pm_building_id = e.pm_building_id
				  LEFT JOIN v$region r ON r.app_sid = e.app_sid AND r.region_sid = NVL(e.region_sid, b.region_sid)
				 WHERE e.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND e.active = DECODE(in_include_inactive, 0, 1, e.active)
				   AND b.region_sid = in_region_sid
			) e
			GROUP BY e.app_sid, e.est_error_id
		) x
		JOIN est_error e ON e.app_sid = x.app_sid AND e.est_error_id = x.est_error_id
		LEFT JOIN v$est_error_description ed ON ed.est_error_id = e.est_error_id
		ORDER BY error_dtm DESC;
END;

PROCEDURE GetErrsForPropertyAndChildren (
	in_region_sid				IN	security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetErrsForPropertyAndChildren(in_region_sid, 0, out_cur);
END;


PROCEDURE GetErrsForPropertyAndChildren (
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_include_inactive			IN	NUMBER DEFAULT 0,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to property with sid '||in_region_sid);
	END IF;
	   
	OPEN out_cur FOR
		SELECT e.est_error_id, e.region_sid, e.est_account_sid, e.pm_customer_id, e.pm_building_id, e.pm_space_id, e.pm_meter_id,
			e.error_level, e.error_dtm, e.error_code, e.error_message raw_message,
			e.request_url, e.request_header, e.request_body, e.response, e.active,
			x.region_desc, x.est_building_name, x.est_space_name, x.est_meter_name,
			NVL(ed.help_text, e.error_message) error_message
      	  FROM (
      	  	SELECT e.app_sid, e.est_error_id, 
		        MAX(e.region_desc) region_desc, 
		        MAX(e.est_building_name) est_building_name, 
		        MAX(e.est_space_name) est_space_name, 
		        MAX(e.est_meter_name) est_meter_name
      	  	  FROM (
				-- Match by region sid
				SELECT e.app_sid, e.est_error_id,
					r.description region_desc, b.building_name est_building_name,
					s.space_name est_space_name, m.meter_name est_meter_name
				  FROM est_error e
				  JOIN v$region r ON r.app_sid = e.app_sid AND r.region_sid = e.region_sid
				  LEFT JOIN est_building b ON b.app_sid = e.app_sid AND b.region_sid = e.region_sid
				  LEFT JOIN est_space s ON s.app_sid = e.app_sid AND s.region_sid = e.region_sid
				  LEFT JOIN est_meter m ON m.app_sid = e.app_sid AND m.region_sid = e.region_sid
				 WHERE e.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND e.active = DECODE(in_include_inactive, 0, 1, e.active)
				   AND e.region_sid IN (
				   	-- links within a property, unlikely.
				   	SELECT region_sid
				   	  FROM region
				   	 START WITH region_sid = in_region_sid
				   	 CONNECT BY PRIOR region_sid = parent_sid
				 )
				UNION
				-- Match by pm building id
				SELECT e.app_sid, e.est_error_id,
					r.description region_desc, b.building_name est_building_name,
					s.space_name est_space_name, m.meter_name est_meter_name
				  FROM est_error e
				  JOIN est_building b ON b.app_sid = e.app_sid AND b.pm_building_id = e.pm_building_id
				  LEFT JOIN est_space s ON s.app_sid = e.app_sid AND s.pm_building_id = e.pm_building_id AND s.pm_space_id = e.pm_space_id
				  LEFT JOIN est_meter m ON m.app_sid = e.app_sid AND m.pm_building_id = e.pm_building_id AND m.pm_meter_id = e.pm_meter_id
				  LEFT JOIN v$region r ON r.app_sid = e.app_sid AND r.region_sid = NVL(m.region_sid, NVL(s.region_sid, b.region_sid))
				 WHERE e.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND e.active = DECODE(in_include_inactive, 0, 1, e.active)
	         	   AND b.region_sid = in_region_sid
	        ) e
			GROUP BY e.app_sid, e.est_error_id
		) x
	    JOIN est_error e ON e.app_sid = x.app_sid AND e.est_error_id = x.est_error_id
		LEFT JOIN v$est_error_description ed ON ed.est_error_id = e.est_error_id
	    ORDER BY error_dtm DESC;
END;

PROCEDURE GetAllErrors (
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, securableobject_pkg.GetSIDFromPath(security_pkg.GetACT, security_pkg.GetAPP, 'EnergyStar'), security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on energy star node');
	END IF;
	
	OPEN out_cur FOR
		SELECT e.est_error_id, e.region_sid, e.est_account_sid, e.pm_customer_id, e.pm_building_id, e.pm_space_id, e.pm_meter_id,
			e.error_level, e.error_dtm, e.error_code, e.error_message raw_message,
			e.request_url, e.request_header, e.request_body, e.response,
			r.description region_desc, 
			NVL(b1.building_name, b2.building_name) est_building_name,
			NVL(s1.space_name, s2.space_name) est_space_name,
			NVL(m1.meter_name, m2.meter_name) est_meter_name,
			NVL(ed.help_text, e.error_message) error_message
		  FROM v$est_error e
		  LEFT JOIN v$region r ON r.app_sid = e.app_sid AND r.region_sid = e.region_sid
		  LEFT JOIN est_building b1 ON b1.app_sid = e.app_sid AND b1.region_sid = e.region_sid
		  LEFT JOIN est_building b2 ON b2.app_sid = e.app_sid AND b2.est_account_sid = e.est_account_sid AND b2.pm_customer_id = e.pm_customer_id AND b2.pm_building_id = e.pm_building_id 
		  LEFT JOIN est_space s1 ON b1.app_sid = e.app_sid AND s1.region_sid = e.region_sid
		  LEFT JOIN est_space s2 ON b2.app_sid = e.app_sid AND s2.est_account_sid = e.est_account_sid AND s2.pm_customer_id = e.pm_customer_id AND s2.pm_building_id = e.pm_building_id AND s2.pm_space_id = e.pm_space_id
		  LEFT JOIN est_meter m1 ON b1.app_sid = e.app_sid AND m1.region_sid = e.region_sid
		  LEFT JOIN est_meter m2 ON b2.app_sid = e.app_sid AND m2.est_account_sid = e.est_account_sid AND m2.pm_customer_id = e.pm_customer_id AND m2.pm_building_id = e.pm_building_id AND m2.pm_meter_id = e.pm_meter_id
		LEFT JOIN v$est_error_description ed ON ed.est_error_id = e.est_error_id
		 WHERE e.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 	ORDER BY error_dtm DESC;
END;

PROCEDURE GetPropertySettings (
	in_region_sid				IN	security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_super_admin						NUMBER(1) := 0;
	v_remap_capability					NUMBER(1) := 0;
	v_system_management_capability		NUMBER(1) := 0;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to property with sid '||in_region_sid);
	END IF;
	
	v_super_admin := security.user_pkg.IsSuperAdmin;

	IF csr.csr_data_pkg.CheckCapability('Remap Energy Star property') THEN
		v_remap_capability := 1;
	END IF;

	IF csr.csr_data_pkg.CheckCapability('System management') THEN
		v_system_management_capability := 1;
	END IF;
	
	OPEN out_cur FOR
		SELECT p.region_sid, NVL(b.pm_building_id, p.pm_building_id) pm_building_id, 
			p.energy_star_sync, p.energy_star_push, b.last_poll_dtm, b.last_job_dtm,
			v_super_admin is_super_admin,
			v_remap_capability remap_capability,
			v_system_management_capability system_management_capability
		  FROM property p
		  LEFT JOIN est_building b ON b.app_sid = p.app_sid AND b.region_sid = p.region_sid
		 WHERE p.region_sid = in_region_sid;
END;

PROCEDURE GetPropertySettingsAndErrors (
	in_region_sid				IN	security_pkg.T_SID_ID,
	out_settings				OUT	security_pkg.T_OUTPUT_CUR,
	out_errors					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetPropertySettings(in_region_sid, out_settings);
	GetErrsForPropertyAndChildren(in_region_sid, out_errors);
END;

PROCEDURE GetUnmappedCustomers (
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF security.user_pkg.IsSuperAdmin != 1 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only available to superadmins');
	END IF;

	OPEN out_cur FOR 
		SELECT pm_customer_id, org_name, email
		  FROM est_customer_global
		 WHERE REGEXP_LIKE(pm_customer_id, '^[[:digit:]]+$');
		 -- regex to filter out invalid non numeric PM_CUSTOMER_IDs
END;

PROCEDURE GetMappedCustomers (
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF security.user_pkg.IsSuperAdmin != 1 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only available to superadmins');
	END IF;

	OPEN out_cur FOR
		SELECT est_account_sid, pm_customer_id, org_name, email, DECODE((
			SELECT COUNT(*) 
			  FROM csr.est_building eb 
			 WHERE eb.pm_customer_id = ec.pm_customer_id), 0, 0, 1) in_use
		  FROM est_customer ec
		 WHERE REGEXP_LIKE(pm_customer_id, '^[[:digit:]]+$');
		 -- regex to filter out invalid non numeric PM_CUSTOMER_IDs
END;

PROCEDURE GetSpaceTypeMappings (
	out_space_type_mappings		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- No security check required as it's just basedata.
	OPEN out_space_type_mappings FOR
		SELECT est_space_type, space_type_id
		  FROM est_space_type_map
		 WHERE app_sid = security.security_pkg.GetApp;
END;

PROCEDURE SaveSpaceTypeMappings (
	in_es_space_type_names		IN	security_pkg.T_VARCHAR2_ARRAY,
	in_space_type_ids			IN	security_pkg.T_SID_IDS
)
AS
	v_es_space_types			security.T_VARCHAR2_TABLE;
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can add/update mappings.');
	END IF;
	
	v_es_space_types := security_pkg.Varchar2ArrayToTable(in_es_space_type_names);
	
	IF NOT (in_es_space_type_names.COUNT = 0 OR (in_es_space_type_names.COUNT = 1 AND in_es_space_type_names(1) IS NULL)) THEN
		FOR i IN 1 .. in_es_space_type_names.COUNT LOOP
			BEGIN
				INSERT INTO est_space_type_map (est_space_type, space_type_id)
				VALUES (in_es_space_type_names(i), in_space_type_ids(i));
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					UPDATE est_space_type_map
					   SET space_type_id = in_space_type_ids(i)
					 WHERE est_space_type = in_es_space_type_names(i);
			END;
		END LOOP;
	END IF;
	
	-- Clear up any space types that weren't in our list.
	DELETE FROM est_space_type_map
	 WHERE app_sid = security_pkg.GetApp
	   AND est_space_type NOT IN (
		SELECT s.value FROM TABLE(v_es_space_types) s
	);
END;

PROCEDURE GetESSpaceTypes(
	out_space_types				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- No security as it's just basedata.
	
	OPEN out_space_types FOR
		SELECT est.est_space_type, est.label, DECODE(es.space_type, NULL, 0, 1) has_data
		  FROM est_space_type est
		  LEFT JOIN est_space es
		    ON es.space_type = est.est_space_type
		 ORDER BY est.label ASC;
END;

PROCEDURE GetPropertyTypeMappings (
	out_prop_type_mappings		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- No security check required as it's just basedata.
	OPEN out_prop_type_mappings FOR
		SELECT est_property_type, property_type_id
		  FROM est_property_type_map
		 WHERE app_sid = security.security_pkg.GetApp;
END;

PROCEDURE SavePropertyTypeMappings (
	in_es_prop_type_names		IN	security_pkg.T_VARCHAR2_ARRAY,
	in_prop_type_ids			IN	security_pkg.T_SID_IDS
)
AS
	v_es_prop_type_names			security.T_VARCHAR2_TABLE;
	v_prop_type_ids					security.T_ORDERED_SID_TABLE;
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can add/update mappings.');
	END IF;
	
	v_es_prop_type_names := security_pkg.Varchar2ArrayToTable(in_es_prop_type_names);
	v_prop_type_ids := security_pkg.SidArrayToOrderedTable(in_prop_type_ids);
	
	IF NOT (in_prop_type_ids.COUNT = 0 OR (in_prop_type_ids.COUNT = 1 AND in_prop_type_ids(1) IS NULL)) THEN
		FOR i IN 1 .. in_prop_type_ids.COUNT LOOP
			BEGIN
				INSERT INTO est_property_type_map (est_property_type, property_type_id)
				VALUES (in_es_prop_type_names(i), in_prop_type_ids(i));
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					NULL;
			END;
		END LOOP;
	END IF;
	
	DELETE FROM est_property_type_map
	 WHERE (est_property_type, property_type_id) NOT IN (
		SELECT espt.value, pt.sid_id
		  FROM TABLE(v_es_prop_type_names) espt
		  JOIN TABLE(v_prop_type_ids) pt
		    ON espt.pos = pt.pos
	);
END;

PROCEDURE GetESPropertyTypes(
	out_prop_types				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- No security as it's just basedata.
	
	OPEN out_prop_types FOR
		SELECT ept.est_property_type label, DECODE(eb.primary_function, NULL, 0, 1) has_data
		  FROM est_property_type ept
		  LEFT JOIN est_building eb
		    ON eb.primary_function = ept.est_property_type
		 ORDER BY ept.est_property_type ASC;
END;

PROCEDURE GetEnergyStarErrors (
	in_start_row				IN	NUMBER,
	in_limit					IN	NUMBER,
	in_search_term				IN	VARCHAR2,
	out_cur_total				OUT	SYS_REFCURSOR,
	out_cur_props				OUT	SYS_REFCURSOR,
	out_cur_props_errors		OUT	SYS_REFCURSOR
)
AS
	v_id_list						T_VARCHAR2_TABLE := T_VARCHAR2_TABLE();
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin OR a user with system management capability can view Energystar errors.');
	END IF;

	INSERT INTO temp_est_error_info (
		error_count, error_id, 
		region_sid, prop_region_sid, 
		est_account_sid, pm_customer_id, 
		pm_building_id, pm_space_id, pm_meter_id,
		building_name, space_name, meter_name, 
		error_dtm, error_code, error_message
	)
	SELECT 
		x.error_count, x.max_error_id,
		x.region_sid, x.prop_region_sid, 
		NVL(x.est_account_sid, o.default_account_sid) est_account_sid,
		NVL(x.pm_customer_id, o.default_customer_id) pm_customer_id,
		x.pm_building_id, x.pm_space_id, x.pm_meter_id,
		x.building_name, x.space_name, x.meter_name,
		e.error_dtm latest_error_dtm, e.error_code, 
		NVL(ed.help_text, e.error_message) error_message
	  FROM (
		SELECT 
			COUNT(*) error_count, MAX(x.est_error_id) max_error_id,
			x.region_sid, x.prop_region_sid, 
			x.est_account_sid, x.pm_customer_id,
			NVL(x.pm_building_id, pb.pm_building_id) pm_building_id, 
			x.pm_space_id, x.pm_meter_id,
			NVL(x.building_name, rp.description) building_name, 
			x.space_name, x.meter_name
		  FROM (
		  	-- Include all regions which are children of properties set to sync
			SELECT r.region_sid, CONNECT_BY_ROOT(r.region_sid) prop_region_sid, 
				COALESCE(m.est_account_sid, s.est_account_sid, b.est_account_sid) est_account_sid, 
				COALESCE(m.pm_customer_id, s.pm_customer_id, b.pm_customer_id) pm_customer_id, 
				COALESCE(m.pm_building_id, s.pm_building_id, b.pm_building_id) pm_building_id,
				NVL(m.pm_space_id, s.pm_space_id) pm_space_id, m.pm_meter_id, 
				DECODE(r.region_type, csr_data_pkg.REGION_TYPE_PROPERTY, r.description, NULL) building_name,
				DECODE(r.region_type, csr_data_pkg.REGION_TYPE_SPACE, r.description, NULL) space_name,
				DECODE(r.region_type, csr_data_pkg.REGION_TYPE_METER, r.description, NULL) meter_name,
				e.est_error_id
			  FROM v$region r
			  LEFT JOIN v$est_error e on e.region_sid = r.region_sid
			  LEFT JOIN est_building b on b.region_sid = r.region_sid
			  LEFT JOIN est_space s on s.region_sid = r.region_sid
			  LEFT JOIN est_meter m on m.region_sid = r.region_sid
			 WHERE r.region_type IN (
			 	csr_data_pkg.REGION_TYPE_PROPERTY,
			 	csr_data_pkg.REGION_TYPE_SPACE,
			 	csr_data_pkg.REGION_TYPE_METER
			 )
			 START WITH r.region_sid IN (
			 	SELECT region_sid 
			 	  FROM property 
			 	 WHERE energy_star_sync = 1
			 )
			 CONNECT BY PRIOR r.region_sid = r.parent_sid
			UNION
			-- Include buildings that have not mapped to a region yet
			SELECT b.region_sid, b.region_sid prop_region_sid, b.est_account_sid, b.pm_customer_id, b.pm_building_id, 
				NULL pm_space_id, NULL pm_meter_id, b.building_name, NULL space_name, NULL meter_name, e.est_error_id
			  FROM est_building b
			  JOIN v$est_error e on e.pm_building_id = b.pm_building_id AND pm_space_id IS NULL AND pm_meter_id IS NULL
			 WHERE b.region_sid is NULL
			UNION
			-- Include spaces that have not mapped to a region yet
			SELECT s.region_sid, b.region_sid prop_region_sid, s.est_account_sid, s.pm_customer_id, s.pm_building_id, 
				s.pm_space_id, NULL pm_meter_id, b.building_name, s.space_name, NULL meter_name, e.est_error_id
			  FROM est_space s
			  JOIN est_building b on b.pm_building_id = s.pm_building_id
			  JOIN v$est_error e on e.pm_building_id = s.pm_building_id AND e.pm_space_id = s.pm_space_id AND e.pm_meter_id is NULL
			 WHERE s.region_sid is NULL
			UNION
			-- Include meters that have not mapped to a region yet
			SELECT m.region_sid, b.region_sid prop_region_sid, m.est_account_sid, m.pm_customer_id, m.pm_building_id, 
				m.pm_space_id, m.pm_meter_id, b.building_name, NULL space_name, m.meter_name, e.est_error_id
			  FROM est_meter m
			  JOIN est_building b ON b.pm_building_id = m.pm_building_id
			  JOIN v$est_error e ON e.pm_building_id = m.pm_building_id AND e.pm_meter_id = m.pm_meter_id
			 WHERE m.region_sid IS NULL
		  ) x
		  LEFT JOIN v$region rp ON rp.region_sid = x.prop_region_sid
		  LEFT JOIN est_building pb ON pb.region_sid = x.prop_region_sid
		 GROUP BY 
		 	x.region_sid, x.prop_region_sid, 
			x.est_account_sid, x.pm_customer_id,
			NVL(x.pm_building_id, pb.pm_building_id), 
			x.pm_space_id, x.pm_meter_id,
			NVL(x.building_name, rp.description), x.space_name, x.meter_name
	  ) x
	  JOIN est_options o on o.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	  JOIN v$est_error e on e.est_error_id = x.max_error_id
	  LEFT JOIN v$est_error_description ed ON ed.est_error_id = e.est_error_id
	 WHERE e.error_code != ERR_GENERIC_BUILDING
	   AND (in_search_term IS NULL
			OR x.prop_region_sid LIKE in_search_term
			OR x.pm_building_id LIKE in_search_term
			OR LOWER(x.building_name) LIKE LOWER('%' || in_search_term || '%'))
	;

	-- Collect unique property "id" for paging
	SELECT prop_region_sid||pm_building_id
	  BULK COLLECT INTO v_id_list
	  FROM (
	  	SELECT ROWNUM - 1 rn, x.*
	  	  FROM (
		  	SELECT DISTINCT prop_region_sid, pm_building_id, building_name
			  FROM temp_est_error_info
			 ORDER BY LOWER(building_name)
		) x
	  )
	 WHERE rn >= in_start_row
	   AND rn < in_start_row + in_limit
	;

	OPEN out_cur_props FOR 
		SELECT DISTINCT t.est_account_sid, t.pm_customer_id, t.pm_building_id, t.prop_region_sid region_sid, t.building_name
		  FROM temp_est_error_info t
		  JOIN TABLE(v_id_list) id ON id.column_value = prop_region_sid||pm_building_id -- Only return stuff on the requested page
		 ORDER BY LOWER(building_name);

	OPEN out_cur_props_errors FOR
		SELECT error_count, error_id, 
			pm_building_id, prop_region_sid, building_name,
			space_name, DECODE(space_name, NULL, NULL, region_sid) space_region_sid, 
			meter_name, DECODE(meter_name, NULL, NULL, region_sid) meter_region_sid,
			error_dtm latest_error_dtm, error_code, error_message
		  FROM temp_est_error_info
		  JOIN TABLE(v_id_list) id ON id.column_value = prop_region_sid||pm_building_id -- Only return stuff for properties on the requested page
		 ORDER BY error_id DESC;
		  
	OPEN out_cur_total FOR 
		SELECT COUNT(DISTINCT prop_region_sid||pm_building_id) total
		  FROM temp_est_error_info;
END;

END;
/
