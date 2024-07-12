-- Set an existing alert to say "Not configured" on the Alert Setup page.
PROMPT Enter host and std_alert_type_id to unconfigure.

SET SERVEROUTPUT ON;

PROMPT Enter the host and the id of the alert (std_alert) to unconfigure.
DECLARE
	v_host		 				VARCHAR2(32767);
	v_std_alert_type_id			NUMBER;

	v_customer_alert_type_id	NUMBER;
BEGIN

	v_host:='&&1';
	v_std_alert_type_id:=&&2;

	security.user_pkg.logonadmin(v_host);

   SELECT customer_alert_type_id INTO v_customer_alert_type_id
     FROM csr.customer_alert_type 
    WHERE std_alert_type_id = v_std_alert_type_id;
  
    dbms_output.put_line('Delete templates for each lang on site');
    DELETE FROM csr.alert_template_body 
     WHERE customer_alert_type_id = v_customer_alert_type_id;

    DELETE FROM csr.alert_template 
     WHERE customer_alert_type_id = v_customer_alert_type_id;

END;
/

COMMIT;

SET SERVEROUTPUT OFF;

EXIT


