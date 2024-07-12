PROMPT Enter host and plan sid
begin
    user_pkg.logonadmin('&&1');
    INSERT INTO new_planned_deleg_alert (new_planned_deleg_alert_id, notify_user_sid, raised_by_user_sid, sheet_id)
		SELECT new_plandeleg_alert_id_seq.nextval, du.user_sid, SYS_CONTEXT('SECURITY', 'SID'), s.sheet_id
		  FROM sheet s
			JOIN v$delegation_user du ON s.app_sid = du.app_sid AND s.delegation_sid = du.delegation_sid
			JOIN customer_alert_type cat ON cat.app_sid = s.app_sid AND cat.std_alert_type_id = csr_data_pkg.ALERT_NEW_PLANNED_DELEG
			JOIN alert_template at ON cat.app_sid = at.app_sid AND cat.customer_alert_type_id = at.customer_alert_type_id
		 WHERE at.send_type != 'inactive' AND s.sheet_id IN (
            SELECT sheet_id
              FROM (
                SELECT sheet_id, ROW_NUMBER() OVER (PARTITION BY delegation_sid ORDER BY start_dtm DESC) rn
                  FROM sheet
                 WHERE delegation_sid IN (
                    SELECT delegation_sid
                      FROM delegation
                     WHERE CONNECT_BY_ISLEAF = 1
                     START WITH delegation_sid IN (
                        SELECT dpdrd.MAPS_TO_ROOT_DELEG_SID
                          FROM csr.V$DELEG_PLAN_DELEG_REGION  dpdr
                            JOIN deleg_plan_deleg_region_deleg dpdrd ON dpdr.deleg_plan_col_deleg_id = dpdrd.deleg_plan_col_deleg_id
                         WHERE deleg_plan_sid = &&2
                     )
                     CONNECT BY PRIOR delegation_sid = parent_sid
                 )
             )
             WHERE rn = 1                 
         );
end;
/
