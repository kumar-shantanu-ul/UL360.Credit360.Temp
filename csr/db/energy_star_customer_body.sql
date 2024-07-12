CREATE OR REPLACE PACKAGE BODY CSR.energy_star_customer_pkg IS
	
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
	v_account_sid			security_pkg.T_SID_ID;
	v_pm_customer_id		est_customer.pm_customer_id%TYPE;
BEGIN
	BEGIN
		SELECT est_account_sid, pm_customer_id
		  INTO v_account_sid, v_pm_customer_id
		  FROM est_customer
		 WHERE est_customer_sid = in_sid_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN;
	END;
	
	DELETE FROM est_building_metric
	 WHERE est_account_sid = v_account_sid
	   AND pm_customer_id = v_pm_customer_id;

	DELETE FROM est_space_attr
	 WHERE est_account_sid = v_account_sid
	   AND pm_customer_id = v_pm_customer_id;

	DELETE FROM est_meter
	 WHERE est_account_sid = v_account_sid
	   AND pm_customer_id = v_pm_customer_id;

	DELETE FROM est_space
	 WHERE est_account_sid = v_account_sid
	   AND pm_customer_id = v_pm_customer_id;

	DELETE FROM est_building
	 WHERE est_account_sid = v_account_sid
	   AND pm_customer_id = v_pm_customer_id;

	DELETE FROM est_customer
	 WHERE est_account_sid = v_account_sid
	   AND pm_customer_id = v_pm_customer_id;
END;

END;
/

