-- Please update version.sql too -- this keeps clean builds in sync
define version=469
@update_header

DECLARE
	v_portlet_id	portlet.portlet_id%TYPE;
BEGIN
	-- Register the new my initiatives portlet
	INSERT INTO PORTLET 
		(PORTLET_ID, NAME, TYPE, SCRIPT_PATH) 
	VALUES 
		(portlet_id_seq.nextval, 'My initiatives', 'Credit360.Portlets.ActionsMyInitiatives', '/csr/site/portal/Portlets/ActionsMyInitiatives.js')
	RETURNING portlet_id INTO v_portlet_id;
	
	-- Any customer that has the actions tasks portlet 
	-- should get the new my initiatives portlet too
	FOR r IN (
		SELECT DISTINCT cp.app_sid
		  FROM portlet p, customer_portlet cp
		 WHERE LOWER(p.name) = 'action tasks'
		   AND cp.portlet_id = p.portlet_id
	) LOOP
		INSERT INTO customer_portlet
			(app_sid, portlet_id)
		VALUES
			(r.app_sid, v_portlet_id);
	END LOOP;
END;
/

@update_tail
