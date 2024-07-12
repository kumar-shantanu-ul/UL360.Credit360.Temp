-- Please update version.sql too -- this keeps clean builds in sync
define version=63
@update_header

connect csr/csr@&_CONNECT_IDENTIFIER

BEGIN
	INSERT INTO csr.alert_type (alert_type_id, description, params_xml)
	 VALUES (2004, 'Initiative Property Manager Alert',
		'<params>' ||
			'<param name="REGION_DESC"/>' ||
			'<param name="INITIAITVE_LIST"/>' ||
		'</params>'
	);
END;
/

BEGIN
	-- Any app that has alert type 2003 shoulld also have type 2004
	INSERT INTO csr.customer_alert_type (app_sid, alert_type_id) (
		SELECT app_sid, 2004
		  FROM csr.customer_alert_type
		 WHERE alert_type_id = 2003
	);
END;
/

connect actions/actions@&_CONNECT_IDENTIFIER

@update_tail
