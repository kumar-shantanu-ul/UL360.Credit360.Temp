CREATE OR REPLACE PACKAGE BODY CSR.reporting_period_Pkg AS


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
  NULL;
END;


PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
) AS
BEGIN
    NULL;
END;


PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
) AS	
BEGIN
	-- TODO: clean up everything! (we probably never want to really do this?)
	DELETE FROM reporting_period
	 WHERE reporting_period_sid = in_sid_id;
END;


PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
) AS   
BEGIN	
	RAISE_APPLICATION_ERROR(-20001, 'You cannot move a reporting period');
END;

PROCEDURE GetReportingPeriods(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_current_period	security_pkg.T_SID_ID;
BEGIN
	SELECT current_reporting_period_sid INTO v_current_period
	  FROM customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	 
	OPEN out_cur FOR
		SELECT reporting_period_sid, name, start_dtm, end_dtm, CASE WHEN reporting_period_sid = v_current_period THEN 1 ELSE 0 END IS_CURRENT
		  FROM reporting_period
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') ORDER by start_dtm;
END;

PROCEDURE CreateReportingPeriod(
	in_act_id				IN  security_pkg.T_ACT_ID,
	in_app_sid 				IN  security_pkg.T_SID_ID,
	in_name					IN	reporting_period.name%TYPE,
	in_start_dtm			IN	reporting_period.start_dtm%TYPE,
	in_end_dtm				IN	reporting_period.end_dtm%TYPE,
	in_copy_deleg_forward	IN 	NUMBER,
	out_sid					OUT	security_pkg.T_SID_ID
)
AS
	v_reporting_periods_sid	security_pkg.T_SID_ID;
	v_cnt	NUMBER(10);
	v_name	reporting_period.name%TYPE;
BEGIN
	-- check for idiocies
	IF in_end_Dtm < in_start_dtm THEN
		RAISE_APPLICATION_ERROR(-20001, 'End date is before start date');
	END IF;
	
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM reporting_period
	 WHERE app_sid = in_app_sid
	   AND end_dtm > in_start_dtm
	   AND start_dtm < in_end_dtm;
	IF v_cnt > 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'The date range '||TO_CHAR(in_start_dtm, 'yyyy-mm-dd')||' to '||TO_CHAR(in_end_dtm, 'yyyy-mm-dd')||
			' conflicts with the dates of existing reporting periods');
	END IF;
	
	-- fix up name if required
	v_name := in_name;
	IF v_name IS NULL THEN
		v_name := TO_CHAR(in_start_dtm, 'Mon yyyy') || ' - ' ||TO_CHAR(in_end_dtm-1, 'Mon yyyy');
	END IF;
	
	-- create object in the right place
	v_reporting_periods_sid := securableObject_pkg.GetSIDFromPath(in_act_id, in_app_sid, 'ReportingPeriods');
	securableobject_pkg.CreateSO(in_act_id, v_reporting_periods_sid, class_pkg.GetClassId('CSRReportingPeriod'), REPLACE(in_name,'/','\'), out_sid); 

	INSERT INTO REPORTING_PERIOD
        (reporting_period_sid, app_sid, name, start_dtm, end_Dtm)
    VALUES
        (out_sid, in_app_sid, v_name, in_start_dtm, in_end_dtm);
END;

PROCEDURE AmendReportingPeriod(
	in_act_id				IN  security_pkg.T_ACT_ID,
	in_sid_id				IN	security_pkg.T_SID_ID,
	in_name					IN	reporting_period.name%TYPE,
	in_start_dtm			IN	reporting_period.start_dtm%TYPE,
	in_end_dtm				IN	reporting_period.end_dtm%TYPE
)
AS
	v_cnt	NUMBER(10);
	v_app_sid	security_pkg.T_SID_ID;
BEGIN
	-- check for idiocies
	IF in_end_Dtm < in_start_dtm THEN
		RAISE_APPLICATION_ERROR(-20001, 'End date is before start date');
	END IF;
	
	SELECT app_sid
	  INTO v_app_sid
	  FROM reporting_period
	 WHERE reporting_period_sid = in_sid_id;
	
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM reporting_period
	 WHERE app_sid = v_app_sid
	   AND end_dtm > in_start_dtm
	   AND start_dtm < in_end_dtm
	   AND reporting_period_sid != in_sid_id; -- don't include our current dates
	IF v_cnt > 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'This conflicts with the dates of existing reporting periods');
	END IF;
	
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_sid_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on reporting period sid '||in_sid_id);
	END IF;
		
	UPDATE reporting_period
	   SET name = in_name, 
		   start_dtm = in_start_dtm,
		   end_dtm = in_end_dtm
	 WHERE reporting_period_sid = in_sid_id;
END;


PROCEDURE GetCurrentPeriod(
	in_app_sid			IN		security_pkg.T_SID_ID,
	out_name			OUT		reporting_period.name%TYPE,
	out_start_dtm		OUT		reporting_period.start_dtm%TYPE,
	out_end_dtm			OUT		reporting_period.end_dtm%TYPE
)
AS
BEGIN
	SELECT rp.name, rp.start_dtm, rp.end_dtm
	  INTO out_name, out_start_dtm, out_end_dtm
	  FROM customer c, reporting_period rp
	 WHERE c.app_sid = rp.app_sid
	   AND c.current_reporting_period_sid = rp.reporting_period_sid
	   AND c.app_sid = in_app_sid;
END;

PROCEDURE GetReportingPeriod(
	in_app_sid			IN		security.security_pkg.T_SID_ID,
	in_rp_sid			IN		security.security_pkg.T_SID_ID,
	out_cur				OUT		security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT name, start_dtm, end_dtm
		FROM reporting_period
		WHERE reporting_period_sid = in_rp_sid
		AND app_sid = in_app_sid;
END;

PROCEDURE SetCurrentPeriod(
	in_reporting_period_sid	IN	security_pkg.T_SID_ID
)
AS
BEGIN
	-- maybe it would be better to check on app_sid instead of reporting_period_sid
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_reporting_period_sid	, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on reporting period sid '||in_reporting_period_sid);
	END IF;
	
	UPDATE customer 
	   SET current_reporting_period_sid = in_reporting_period_sid
	  WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;


END reporting_period_Pkg;
/
	