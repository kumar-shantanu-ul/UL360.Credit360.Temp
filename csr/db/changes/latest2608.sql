-- Please update version.sql too -- this keeps clean builds in sync
define version=2608
@update_header

DECLARE	
	v_customer_alert_type_id	csr.customer_alert_type.customer_alert_type_id%TYPE;
	v_af_id						csr.alert_frame.alert_frame_id%TYPE;
	v_act_id					security.security_pkg.T_ACT_ID;
BEGIN
	security.user_pkg.logonadmin;
	--get every chain site that is missing the chain company invitation alert type (5014)
	FOR r IN (
	  SELECT app_sid
		FROM chain.customer_options
	   MINUS
	  SELECT app_sid
		FROM csr.customer_alert_type
	   WHERE std_alert_type_id = 5014
	)
	LOOP
		-- add the alert type with default template
		security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, 600, r.app_sid, v_act_id);
		INSERT INTO csr.customer_alert_type 
			(app_sid, customer_alert_type_id, std_alert_type_id) 
		VALUES 
			(SYS_CONTEXT('SECURITY','APP'), csr.customer_alert_type_id_seq.nextval, 5014)
		RETURNING customer_alert_type_id INTO v_customer_alert_type_id;
	
		BEGIN
			SELECT MIN(alert_frame_id)
			  INTO v_af_id
			  FROM csr.alert_frame 
			 WHERE app_sid = SYS_CONTEXT('SECURITY','APP') 
			 GROUP BY app_sid;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				csr.alert_pkg.CreateFrame('Default', v_af_id);
		END;

		INSERT INTO csr.alert_template 
			(app_sid, customer_alert_type_id, alert_frame_id, send_type)
		VALUES
			(SYS_CONTEXT('SECURITY','APP'), v_customer_alert_type_id, v_af_id, 'automatic');
			
		security.user_pkg.logoff(v_act_id);
	END LOOP;
END;
/

@..\chain\setup_body

@update_tail