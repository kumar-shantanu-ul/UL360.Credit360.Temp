SET SERVEROUTPUT ON
BEGIN
	security.user_pkg.logonadmin('&&host');

	--clearing sheet history changes
	dbms_output.put_line('SHEET HISTORY CHANGES: ');
	FOR r IN (
		SELECT sheet_history_id, note
		  FROM csr.sheet_history
		 WHERE app_sid = security.security_pkg.getapp())
	LOOP
		IF r.note IS NOT NULL THEN
			UPDATE csr.sheet_history
			   SET note = NULL
			 WHERE sheet_history_id = r.sheet_history_id
			   AND app_sid = security.security_pkg.getapp();

			dbms_output.put_line('cleared sheet_history_id: ' || r.sheet_history_id || ' old value: ' || r.note);

		END IF;
	END LOOP;

	--clearing sheet value changes
	dbms_output.put_line('SHEET VALUE CHANGES: ');
	FOR r IN (
		SELECT sheet_value_id, note
		  FROM csr.sheet_value
		 WHERE app_sid = security.security_pkg.getapp())
	LOOP
		IF r.note IS NOT NULL THEN
			UPDATE csr.sheet_value
			   SET note = NULL
			 WHERE sheet_value_id = r.sheet_value_id
			   AND app_sid = security.security_pkg.getapp();

			dbms_output.put_line('cleared sheet_value_id: ' || r.sheet_value_id || ' old value: ' || r.note);

		END IF;
	END LOOP;

	--clearing postits
	dbms_output.put_line('POSTIT CHANGES: ');
	FOR r IN (
		SELECT postit_id, message
		  FROM csr.postit
		 WHERE app_sid = security.security_pkg.getapp())
	LOOP
		IF r.message IS NOT NULL THEN
			UPDATE csr.postit
			   SET message = null
			 WHERE postit_id = r.postit_id
			   AND app_sid = security.security_pkg.getapp();

			dbms_output.put_line('cleared postit_id: ' || r.postit_id || ' old value: ' || r.message);

		END IF;
	END LOOP;

	--clearing sheet value change notes
	dbms_output.put_line('SHEET VALUE CHANGE NOTES CHANGES: ');
	FOR r IN (
		SELECT sheet_value_change_id, note
		  FROM csr.sheet_value_change
		 WHERE app_sid = security.security_pkg.getapp())
	LOOP
		IF r.note IS NOT NULL THEN
			UPDATE csr.sheet_value_change
			   SET note = null
			 WHERE sheet_value_change_id = r.sheet_value_change_id
			   AND app_sid = security.security_pkg.getapp();

			dbms_output.put_line('cleared sheet_value_change_id: ' || r.sheet_value_change_id || ' old value: ' || r.note);

		END IF;
	END LOOP;
END;
/
