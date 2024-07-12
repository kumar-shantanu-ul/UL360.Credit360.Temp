prompt enter the host

DECLARE
	v_customer_alert_type_id	number;
BEGIN
	user_pkg.logonadmin('&&1');
	BEGIN
		INSERT INTO customer_alert_type
			(customer_alert_type_id, std_alert_type_id) 
		VALUES 
			(customer_alert_type_id_seq.nextval, 20)
		RETURNING customer_alert_type_id INTO v_customer_alert_type_id;
	EXCEPTION
		WHEN dup_val_on_index THEN
			raise_application_error(-20001, 'The generic mailout alert is already enabled');
	END;
END;
/
EXIT;