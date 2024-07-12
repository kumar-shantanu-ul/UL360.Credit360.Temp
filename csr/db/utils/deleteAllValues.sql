DECLARE
BEGIN
    user_pkg.logonadmin('&&1', 86400);

	-- clear out any jobs in the queue -- we're about to add in all possible jobs anyway
	DELETE FROM val_change_log
	 WHERE app_sid = security_pkg.getapp;
 	
	UPDATE imp_val
	   SET set_val_id = null
	 WHERE app_sid = security_pkg.getapp;
/*
	DELETE FROM error_log
	 WHERE app_sid = security_pkg.getapp;
	UPDATE val_change
	   SET val_id = null
	 WHERE app_sid = security_pkg.getapp;
	*/ 

	DELETE FROM val_file
	 WHERE app_sid = security_pkg.getapp;

	DELETE FROM val
	 WHERE app_sid = security_pkg.getapp;
	
	COMMIT;
END;
/

exit
