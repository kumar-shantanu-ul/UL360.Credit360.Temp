BEGIN
	security.user_pkg.logonadmin('&host');
	UPDATE csr.sheet s
	   SET automatic_approval_dtm = 
			(SELECT DECODE(daa.app_sid,/*if*/NULL,/*then*/NULL, 
									/*else*/DECODE(daa.due_date_offset, /*if*/NULL, /*then*/SYSDATE, 
												/*else*/s.submission_dtm + daa.due_date_offset)) 
			   FROM csr.delegation_automatic_approval daa
			  WHERE daa.app_sid = s.app_sid),
		   automatic_approval_status = 'P' --Pending
	 WHERE automatic_approval_status NOT IN ('Q'); --Queued 
END;
/