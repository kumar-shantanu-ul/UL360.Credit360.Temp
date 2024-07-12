whenever sqlerror exit failure rollback 
whenever oserror exit failure rollback

define host='&&1'
define delegation_sid='&&2'

exec security.user_pkg.logonadmin('&&host');

--Delete Sheet data
BEGIN
	FOR s IN (
		SELECT S.SHEET_ID ID
		  FROM CSR.SHEET S
		 WHERE S.DELEGATION_SID = &&delegation_sid
	)
	LOOP
		FOR v IN (
			SELECT SV.SHEET_VALUE_ID ID
			  FROM CSR.SHEET_VALUE SV
			  JOIN CSR.SHEET S ON S.SHEET_ID = SV.SHEET_ID
			 WHERE SV.SHEET_ID = s.id
		)
		LOOP	   
			FOR c IN (
				SELECT SVC.SHEET_VALUE_CHANGE_ID ID
				  FROM CSR.SHEET_VALUE_CHANGE SVC
				 WHERE SVC.SHEET_VALUE_ID = v.id
			)
			LOOP	   
				DELETE FROM CSR.SHEET_VALUE_CHANGE_FILE WHERE SHEET_VALUE_CHANGE_ID = c.id;
			END LOOP;
			
			UPDATE CSR.SHEET_VALUE SET LAST_SHEET_VALUE_CHANGE_ID = null WHERE SHEET_VALUE_ID = v.id;
			DELETE FROM CSR.SHEET_VALUE_CHANGE WHERE SHEET_VALUE_ID = v.id;
			DELETE FROM CSR.SHEET_VALUE_ACCURACY WHERE SHEET_VALUE_ID = v.id;
			DELETE FROM CSR.SHEET_VALUE_FILE WHERE SHEET_VALUE_ID = v.id;
			DELETE FROM CSR.SHEET_VALUE_FILE_HIDDEN_CACHE WHERE SHEET_VALUE_ID = v.id;
			DELETE FROM CSR.SHEET_VALUE_HIDDEN_CACHE WHERE SHEET_VALUE_ID = v.id;
			DELETE FROM CSR.SHEET_VALUE_VAR_EXPL WHERE SHEET_VALUE_ID = v.id;
            DELETE FROM CSR.SHEET_INHERITED_VALUE WHERE INHERITED_VALUE_ID = v.id;
			DELETE FROM CSR.SHEET_VALUE WHERE SHEET_VALUE_ID = v.id;
		END LOOP;
		
		UPDATE CSR.SHEET SET LAST_SHEET_HISTORY_ID = null WHERE SHEET_ID = s.id;
		DELETE FROM CSR.SHEET_HISTORY WHERE SHEET_ID = s.id;
        DELETE FROM CSR.SHEET_ALERT WHERE SHEET_ID = s.id;
		DELETE FROM CSR.SHEET WHERE SHEET_ID = s.id;
	END LOOP;
	
	--Delete delegation data
	DELETE FROM CSR.DELEGATION_COMMENT WHERE DELEGATION_SID = &&delegation_sid;
	DELETE FROM CSR.DELEGATION_IND_COND WHERE DELEGATION_SID = &&delegation_sid;
	DELETE FROM CSR.DELEGATION_IND_COND_ACTION WHERE DELEGATION_SID = &&delegation_sid;
	DELETE FROM CSR.DELEGATION_IND_DESCRIPTION WHERE DELEGATION_SID = &&delegation_sid;
	DELETE FROM CSR.DELEGATION_IND_TAG WHERE DELEGATION_SID = &&delegation_sid;
	DELETE FROM CSR.DELEGATION_IND_TAG_LIST WHERE DELEGATION_SID = &&delegation_sid;
	DELETE FROM CSR.DELEGATION_IND WHERE DELEGATION_SID = &&delegation_sid;
	DELETE FROM CSR.DELEGATION_REGION_DESCRIPTION WHERE DELEGATION_SID = &&delegation_sid;
	DELETE FROM CSR.DELEGATION_REGION WHERE DELEGATION_SID = &&delegation_sid;
	DELETE FROM CSR.DELEGATION_ROLE WHERE DELEGATION_SID = &&delegation_sid;
	DELETE FROM CSR.DELEGATION_TAG WHERE DELEGATION_SID = &&delegation_sid;
	DELETE FROM CSR.DELEGATION_USER WHERE DELEGATION_SID = &&delegation_sid;
    DELETE FROM CSR.DELEG_PLAN_DELEG_REGION_DELEG WHERE maps_to_root_deleg_sid = &&delegation_sid;
    DELETE FROM CSR.DELEGATION_USER_COVER WHERE DELEGATION_SID = &&delegation_sid;
	DELETE FROM CSR.DELEGATION WHERE DELEGATION_SID = &&delegation_sid;

	COMMIT;
END;
/