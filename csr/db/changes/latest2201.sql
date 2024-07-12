define version=2201
@update_header

BEGIN
  INSERT 
    INTO CSR.flow_alert_class 
  VALUES ('corpreporter', 'Corporate reporter');
EXCEPTION  
  WHEN DUP_VAL_ON_INDEX THEN
    NULL;
END;
/

BEGIN
  security.user_pkg.LogonAdmin();
  FOR r IN (
    SELECT app_sid
      FROM CSR.flow
     WHERE flow_sid IN (SELECT flow_sid FROM CSR.section_flow)
     GROUP BY app_sid
  )
  LOOP
    security.security_pkg.SetApp(r.app_sid);
    BEGIN
      INSERT INTO CSR.customer_flow_alert_class (flow_alert_class)
      VALUES ('corpreporter');
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN
        NULL;
    END;
    security.security_pkg.SetApp(null);
  END LOOP;
END;
/

@..\flow_pkg;
@..\flow_body;
@..\section_pkg;
@..\section_body;
@..\section_body;
@..\enable_body;

@update_tail
