

-- NEW DELEG MAILS
    INSERT INTO alert (
        alert_id, notify_user_sid, alert_Type_id, app_sid, raised_by_user_sid, raised_dtm, send_after_dtm, params
     ) 
        SELECT alert_id_seq.nextval, du.user_sid delegee_user_sid, 
            2, --csr_data_pkg.ALERT_NEW_DELEGATION, 
            security_pkg.getApp, dpu.user_sid delegator_user_sid,
            SYSDATE, SYSDATE, s.sheet_id
              FROM delegation d, delegation_user dpu, sheet s, delegation_user du 
             WHERE d.parent_sid = dpu.delegation_sid
               AND d.delegation_sid = du.delegation_sid
               AND d.delegation_sid = s.delegation_sid
               AND s.start_dtm = d.start_dtm -- first sheet only
               AND d.delegation_sid IN (
				-- the delegations to process
				SELECT delegation_sid
				  FROM delegation
				 WHERE CONNECT_BY_ISLEAF = 1
				 START WITH delegation_sid IN ( 10305131
				 )
				 CONNECT BY PRIOR delegation_sid =parent_sid
            ); 



-- REMINDERS

INSERT INTO alert (
    alert_id, notify_user_sid, alert_Type_id, app_sid, raised_by_user_sid, raised_dtm, send_after_dtm, params
 ) 
    SELECT alert_Id_seq.nextval, user_sid, 
        5, -- raise reminder
        app_sid, security_pkg.getsid, SYSDATE, SYSDATE, max_sheet_history_id
     FROM (
        SELECT du.user_sid, d.app_sid, MAX(sheet_history_id) max_sheet_history_id
          FROM sheet s
            JOIN sheet_history sh ON s.sheet_id = sh.sheet_Id
            JOIN delegation d ON s.delegation_sid = d.delegation_sid
            JOIN delegation_user du ON d.delegation_sid = du.delegation_sid
         WHERE d.delegation_sid IN (
            SELECT delegation_sid
              FROM delegation
             WHERE connect_by_isleaf = 1
             START WITH parent_sid = app_sid
               AND delegation_sid > 10249592
           CONNECT BY PRIOR delegation_sid = parent_sid
         ) 
        GROUP BY du.user_sid, d.app_sid
    );    