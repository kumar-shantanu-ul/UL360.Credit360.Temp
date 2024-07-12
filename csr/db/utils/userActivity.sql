SELECT NAME, HOST, SUM(active_6) active_6, SUM(active_12) active_12, SUM(active_18) active_18, SUM(active_all) active_all FROM 
(
	SELECT c.HOST, c.NAME, COUNT(*) active_6, NULL active_12, NULL active_18, NULL active_all
	  FROM CUSTOMER c, CSR_USER cu, SECURITY.USER_TABLE ut
	 WHERE cu.app_sid = c.app_sid 
	   AND ut.sid_id = cu.csr_user_sid
	   AND email NOT LIKE '%credit360.com'
	   AND email NOT LIKE '%npsl.co.uk'
	   AND email NOT LIKE '%flag.co.uk'
	   AND account_enabled = 1 
	   AND last_logon > ADD_MONTHS(SYSDATE,-6)
           AND status = 2
	 GROUP BY c.HOST, c.NAME
	UNION
	SELECT c.HOST, c.NAME, NULL active_6, COUNT(*) active_12, NULL active_18, NULL active_all
	  FROM CUSTOMER c, CSR_USER cu, SECURITY.USER_TABLE ut
	 WHERE cu.app_sid = c.app_sid 
	   AND ut.sid_id = cu.csr_user_sid
	   AND email NOT LIKE '%credit360.com'
	   AND email NOT LIKE '%npsl.co.uk'
	   AND email NOT LIKE '%flag.co.uk'
	   AND account_enabled = 1 
	   AND last_logon > ADD_MONTHS(SYSDATE,-12)
           AND status = 2
	 GROUP BY c.HOST, c.NAME
	UNION 
	SELECT c.HOST, c.NAME, NULL active_6, NULL active_12, COUNT(*) active_18, NULL active_all
	  FROM CUSTOMER c, CSR_USER cu, SECURITY.USER_TABLE ut 
	 WHERE cu.app_sid = c.app_sid 
	   AND ut.sid_id = cu.csr_user_sid
	   AND email NOT LIKE '%credit360.com'
	   AND email NOT LIKE '%npsl.co.uk'
	   AND email NOT LIKE '%flag.co.uk'
	   AND account_enabled = 1 
	   AND last_logon > ADD_MONTHS(SYSDATE,-18)
           AND status = 2
	 GROUP BY c.HOST, c.NAME
        UNION
        SELECT c.HOST, c.NAME, NULL active_6, NULL active_12, NULL active_18, COUNT(*) active_all
	  FROM CUSTOMER c, CSR_USER cu, SECURITY.USER_TABLE ut
	 WHERE cu.app_sid = c.app_sid 
	   AND ut.sid_id = cu.csr_user_sid
	   AND email NOT LIKE '%credit360.com'
	   AND email NOT LIKE '%npsl.co.uk'
	   AND email NOT LIKE '%flag.co.uk'
	   AND account_enabled = 1 
           AND status = 2
	 GROUP BY c.HOST, c.NAME
) GROUP BY HOST, NAME
ORDER BY (NVL(active_6,0) + NVL(active_12,0) + NVL(active_18,0))/3 DESC;