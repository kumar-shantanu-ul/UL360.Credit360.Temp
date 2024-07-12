-- run once a week
-- this just does 2004/05
INSERT INTO OBJECTIVE_STATUS  
	(OBJECTIVE_SID, START_DTM, END_DTM, SCORE, STATUS_DESCRIPTION, STATUS_XML, LAST_UPDATED_DTM, UPDATED_BY_SID, ROLLED_FORWARD)                        
	SELECT os.objective_sid, end_dtm start_dtm, ADD_MONTHS(end_dtm, MONTHS_BETWEEN(end_dtm, start_dtm)) end_dtm, 0, 
		status_description,	status_xml, last_updated_dtm, updated_by_sid, 1 rolled_forward
	  FROM OBJECTIVE_STATUS os,
		(SELECT objective_sid, MAX(end_dtm) max_end_dtm
		  FROM OBJECTIVE_STATUS
		 GROUP BY objective_sid
		HAVING MAX(end_dtm) < SYSDATE)x
	 WHERE x.objective_sid = os.objective_sid
	   AND x.max_end_dtm = os.END_DTM
       AND os.objective_sid in 
       (SELECT sid_id FROM security.securable_object
		CONNECT BY PRIOR sid_id = parent_sid_id
		START WITH sid_id=1505067)  

