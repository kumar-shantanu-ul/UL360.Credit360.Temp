define version=2073
@update_header

BEGIN
	FOR r IN (
		SELECT c.app_sid
		  FROM csr.customer c
		  JOIN security.securable_object so ON c.app_sid = so.parent_sid_id AND c.app_sid = so.application_sid_id
		 WHERE so.name = 'Audits'
	) LOOP
		BEGIN
			INSERT INTO csr.customer_flow_alert_class (app_sid, flow_alert_class)
			VALUES (r.app_sid, 'audit');
		EXCEPTION WHEN dup_val_on_index THEN
			NULL;
		END;
	END LOOP;
END;
/

@update_tail
