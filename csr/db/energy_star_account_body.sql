CREATE OR REPLACE PACKAGE BODY CSR.energy_star_account_pkg IS

PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
)
AS
BEGIN
	-- Delete customers first
	FOR r IN (
		SELECT est_customer_sid
		  FROM est_customer
		 WHERE est_account_sid = in_sid_id
	) LOOP
		securableobject_pkg.DeleteSO(in_act_id, r.est_customer_sid);
	END LOOP;
	
	-- Delete account spacific data 
	DELETE FROM est_building_metric_mapping
	 WHERE est_account_sid = in_sid_id;
	 
	DELETE FROM est_space_attr_mapping
	 WHERE est_account_sid = in_sid_id;
	 
	DELETE FROM est_conv_mapping
	 WHERE est_account_sid = in_sid_id;

	DELETE FROM est_meter_type_mapping
	 WHERE est_account_sid = in_sid_id;
	 
	DELETE FROM est_account
	 WHERE est_account_sid = in_sid_id;
	 	
END;

END;
/
