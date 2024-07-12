/*
	This script corrects any document versions that are out of sequence e.g 1, 4, 9 to 1,2,3.
	Pass the host name to resequence all documents for that customer
*/
DECLARE
	v_host					customer.host%TYPE := '&&1';
	v_current_doc_id		doc.doc_id%TYPE;
	v_correct_version		doc_version.version%TYPE;	
	TYPE download_table IS TABLE OF doc_download%ROWTYPE;
	TYPE notification_table IS TABLE OF doc_notification%ROWTYPE;
	TYPE subscription_table IS TABLE OF doc_subscription%ROWTYPE;
	TYPE current_table IS TABLE OF doc_current%ROWTYPE;
	v_download download_table := download_table();
	v_subscription subscription_table := subscription_table();
	v_notification notification_table := notification_table();
	v_current current_table := current_table();
BEGIN
	user_pkg.logonadmin(v_host);
	v_current_doc_id := 0;
	
	FOR r IN (
		
		--get the docs in the correct order
		SELECT dv.doc_id, dv.version, CASE WHEN dc.doc_id IS NULL THEN 0 ELSE 1 END current_doc, CASE WHEN dc.version IS NULL THEN 1 ELSE 0 END pending
		  FROM doc_version dv
		  LEFT JOIN doc_current dc ON dc.doc_id = dv.doc_id AND dv.app_sid = dc.app_sid AND (dc.version = dv.version OR dc.pending_version = dv.version)
		  WHERE dv.app_sid = security_pkg.getApp
		 ORDER BY dv.doc_id, dv.changed_dtm
	)
	LOOP
		IF v_current_doc_id <> r.doc_id THEN
			v_current_doc_id := r.doc_id;
			v_correct_version := 1;
		ELSE
			v_correct_version := v_correct_version + 1;
		END IF;
		
		IF r.version <> v_correct_version THEN
			dbms_output.put_line('Incorrect version found Doc: ' || r.doc_id || ' version: ' || r.version || ' correct version: ' || v_correct_version);
			--move child versions to a temp table and delete to avoid constraints
			SELECT *
			  BULK COLLECT INTO v_download
			  FROM doc_download
			 WHERE doc_id = v_current_doc_id AND version = r.version;
			 
			DELETE FROM doc_download WHERE doc_id = v_current_doc_id AND version = r.version;
			
			SELECT *
			  BULK COLLECT INTO v_subscription
			  FROM doc_subscription
			 WHERE doc_id = v_current_doc_id;
			 
			DELETE FROM doc_subscription WHERE doc_id = v_current_doc_id;
			
			SELECT *
			  BULK COLLECT INTO v_notification
			  FROM doc_notification
			 WHERE doc_id = v_current_doc_id AND version = r.version;
			 
			DELETE FROM doc_notification WHERE doc_id = v_current_doc_id AND version = r.version;
			
			IF r.current_doc = 1 THEN
				SELECT *
				  BULK COLLECT INTO v_current
			      FROM doc_current
			     WHERE doc_id = v_current_doc_id;
			 
				DELETE FROM doc_current WHERE doc_id = v_current_doc_id;
			END IF;
			dbms_output.put_line('child tables moved');
			--amend master version
			UPDATE doc_version
			  SET version = v_correct_version
			 WHERE doc_id = v_current_doc_id AND version = r.version;
			dbms_output.put_line('version updated');
			--put the child versions back in with the correct version number
			FOR i IN 1 .. v_download.COUNT
				LOOP
					INSERT INTO doc_download (doc_id, version, downloaded_dtm, downloaded_by_sid)
					 VALUES (v_download(i).doc_id, v_correct_version, v_download(i).downloaded_dtm, v_download(i).downloaded_by_sid);
				END LOOP;
			FOR i IN 1 .. v_notification.COUNT
				LOOP
					INSERT INTO doc_notification (doc_notification_id, doc_id, version, notify_sid, sent_dtm, reason)
					 VALUES (v_notification(i).doc_notification_id, v_notification(i).doc_id, v_correct_version, v_notification(i).notify_sid, v_notification(i).sent_dtm, v_notification(i).reason);
				END LOOP;
				
			IF r.current_doc = 1 THEN
				IF r.pending = 1 THEN
					FOR i IN 1 .. v_current.COUNT
						LOOP
							INSERT INTO doc_current (doc_id, version, parent_sid, locked_by_sid, pending_version)
							 VALUES (v_current(i).doc_id, v_current(i).version, v_current(i).parent_sid, v_current(i).locked_by_sid, v_correct_version);
						END LOOP;
				ELSE
					FOR i IN 1 .. v_current.COUNT
						LOOP
							INSERT INTO doc_current (doc_id, version, parent_sid, locked_by_sid, pending_version)
							 VALUES (v_current(i).doc_id, v_correct_version, v_current(i).parent_sid, v_current(i).locked_by_sid, v_current(i).pending_version);
						END LOOP;
				END IF;
			END IF;
			
			FOR i IN 1 .. v_subscription.COUNT
				LOOP
					INSERT INTO doc_subscription (doc_id, notify_sid)
					 VALUES (v_subscription(i).doc_id, v_subscription(i).notify_sid);
				END LOOP;
			dbms_output.put_line('child tables replaced');	
			--clear temp tables if required
			IF v_download.COUNT > 0 THEN
				v_download.DELETE;
			END IF;
			IF v_notification.COUNT > 0 THEN
				v_notification.DELETE;
			END IF;
			IF v_current.COUNT > 0 THEN
				v_current.DELETE;
			END IF;
			IF v_subscription.COUNT > 0 THEN
				v_subscription.DELETE;
			END IF;
		END IF;
	END LOOP;
END;
/