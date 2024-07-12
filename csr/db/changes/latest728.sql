-- Please update version.sql too -- this keeps clean builds in sync
define version=728
@update_header


DECLARE
	v_portlet_id	portlet.portlet_id%TYPE;
BEGIN
	
	BEGIN
		SELECT portlet_id
		  INTO v_portlet_id
		  FROM csr.portlet
		 WHERE type = 'Credit360.Portlets.MyDonations';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_portlet_id := NULL;
	END;
	 
	IF v_portlet_id IS NULL THEN
		INSERT INTO csr.portlet
			(portlet_id, name, type, script_path, default_state) 
		VALUES
			(portlet_id_seq.nextval, 'My donations', 'Credit360.Portlets.MyDonations', '/csr/site/portal/Portlets/MyDonations.js', '{"portletHeight":400}')
		RETURNING
			portlet_id INTO v_portlet_id;
	ELSE
		UPDATE csr.portlet
		   SET name = 'My donations',
		       script_path = '/csr/site/portal/Portlets/MyDonations.js',
		       default_state = '{"portletHeight":400}'
		 WHERE portlet_id = v_portlet_id;
	END IF;	

	FOR r IN (
		SELECT DISTINCT app_sid
		  FROM donations.scheme
		 WHERE app_sid in (
			SELECT app_sid 
			  FROM customer
		 )
	) LOOP
		BEGIN
			INSERT INTO csr.customer_portlet (app_sid, portlet_id)
				VALUES (r.app_sid, v_portlet_id);
		EXCEPTION 
			WHEN DUP_VAL_ON_INDEX THEN
				NULL; -- Ignore if already mapped
		END;
	END LOOP;
	
END;
/
		 
@update_tail