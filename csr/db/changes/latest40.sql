-- Please update version.sql too -- this keeps clean builds in sync
define version=40
@update_header

ALTER TABLE customer ADD (editing_url VARCHAR2(255) NULL);

-- foul but I can't remember the RANK syntax and no web connection atm!
BEGIN
	FOR r IN (
		SELECT z.editing_url, y.csr_root_sid
		 FROM
		(SELECT csr_root_sid, MAX(cnt) cnt FROM 
			(SELECT editing_url, csr_root_sid, COUNT(*) cnt
			 FROM delegation 
			GROUP BY csr_root_sid, editing_url 
			ORDER BY csr_root_sid, COUNT(*) DESC)x
		  GROUP BY csr_root_sid)y,
		  (SELECT editing_url, csr_root_sid, COUNT(*) cnt
			 FROM delegation 
			GROUP BY csr_root_sid, editing_url 
			ORDER BY csr_root_sid, COUNT(*) DESC)z
		  WHERE y.csr_root_sid = z.csr_root_Sid 
		   AND y.cnt = z.cnt)
	LOOP
		UPDATE customer SET editing_url = r.editing_url WHERE csr_root_sid = r.csr_root_sid; 
	END LOOP;          
	UPDATE customer SET editing_url = '/csr/site/delegation/sheet.acds?popup=0&' WHERE editing_url is null;
END;
/
commit;

ALTER TABLE customer MODIFY (editing_url NOT NULL);
ALTER TABLE customer MODIFY (editing_url DEFAULT '/csr/site/delegation/sheet.acds?popup=0&');


update security.securable_object_class set helper_pkg='web_pkg' where class_name ='Webresource';

commit;


begin
update sheet_action set colour ='R' where sheet_action_id = 0;
update sheet_action set colour ='O' where sheet_action_id = 1;
update sheet_action set colour ='R' where sheet_action_id = 2;
update sheet_action set colour ='G' where sheet_action_id = 3;
update sheet_action set colour ='G' where sheet_action_id = 4;
update sheet_action set colour ='-' where sheet_action_id = 5;
update sheet_action set colour ='G' where sheet_action_id = 6;
update sheet_action set colour ='-' where sheet_action_id = 7;
update sheet_action set colour ='-' where sheet_action_id = 8;
update sheet_action set colour ='G' where sheet_action_id = 9;
update sheet_action set colour ='R' where sheet_action_id = 10;
end;
/
commit;



 
CREATE OR REPLACE VIEW SHEET_WITH_LAST_ACTION AS
SELECT SH.SHEET_ID, SH.DELEGATION_SID, SH.START_DTM, SH.END_DTM, SH.REMINDER_DTM, SH.SUBMISSION_DTM, SHE.SHEET_ACTION_ID LAST_ACTION_ID, SHE.FROM_USER_SID LAST_ACTION_FROM_USER_SID, SHE.ACTION_DTM LAST_ACTION_DTM, SHE.NOTE LAST_ACTION_NOTE, SHE.TO_DELEGATION_SID LAST_ACTION_TO_DELEGATION_SID, CASE WHEN SYSDATE >= submission_dtm AND SHE.SHEET_ACTION_ID IN (0,2) THEN 1 --csr_data_pkg.ACTION_WAITING, csr_data_pkg.ACTION_RETURNED
             	 WHEN SYSDATE >= reminder_dtm AND SHE.SHEET_ACTION_ID IN (0,2) THEN 2 --csr_data_pkg.ACTION_WAITING, csr_data_pkg.ACTION_RETURNED
                 ELSE 3
            END STATUS, SH.LAST_REMINDED_DTM, SH.IS_VISIBLE, SH.LAST_SHEET_HISTORY_ID, SHA.COLOUR LAST_ACTION_COLOUR
FROM SHEET_HISTORY SHE, SHEET SH, SHEET_ACTION SHA
WHERE SH.LAST_SHEET_HISTORY_ID = SHE.SHEET_HISTORY_ID AND SHE.SHEET_ID = SH.SHEET_ID AND SHE.SHEET_ACTION_ID = SHA.SHEET_ACTION_ID;




@update_tail
