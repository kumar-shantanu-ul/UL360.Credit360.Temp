define version=2015
@update_header

DECLARE
	v_wf_sid	NUMBER(10);
BEGIN
  FOR r IN (
    SELECT c.app_sid, w.website_name
      FROM csr.customer c, security.website w
     WHERE c.app_sid = w.application_sid_id
  ) LOOP
  	security.user_pkg.logonadmin(r.website_name);
  	BEGIN
		v_wf_sid:= security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetACT, security.security_pkg.GetAPP, 'Workflows');
		BEGIN
			INSERT INTO csr.customer_flow_alert_class (app_sid, flow_alert_class)
				VALUES (r.app_sid, 'cms');
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;
	security.user_pkg.logonadmin;
  END LOOP;
END;
/

@update_tail
