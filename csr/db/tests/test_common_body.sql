CREATE OR REPLACE PACKAGE BODY csr.test_common_pkg AS

PROCEDURE SetupChainPropertyWorkflow
AS
	v_xml							CLOB;
	v_str 							VARCHAR2(2000);
	v_r0 							security.security_pkg.T_SID_ID;
	v_s0							security.security_pkg.T_SID_ID;
	v_s1							security.security_pkg.T_SID_ID;
BEGIN
	-- Property workflow
	BEGIN
		INSERT INTO csr.customer_flow_alert_class (flow_alert_class)
		VALUES ('property');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	flow_pkg.CreateFlow(
		'Property workflow', 
		security.securableobject_pkg.GetSidFromPath(
			security.security_pkg.GetAct, 
			security.security_pkg.GetApp, 
			'Workflows'
		), 
		'property', 
		ChainPropertyFlowSid
	);

	v_xml := '<';
	v_str := UNISTR('flow label="Property workflow" cmsTabSid="" default-state-id="$S1$"><state id="$S0$" label="Details entered" final="0" colour="" lookup-key="PROP_DETS_ENTERED"><attributes x="1078.5" y="801.5" /><role sid="$R0$" is-editable="1" /><transition to-state-id="$S1$" verb="Details required" helper-sp="" lookup-key="MARK_DETS_REQD" ask-for-comment="optional" mandatory-fields-message="" hours-before-auto-tran="" button-icon-path=""><role sid="$R0$" /></transition></state><state id="$S1$" label="Details required" final="0" colour="" lookup-key="PROP_DETS_REQD"><attributes x="726.5" y="799.5" /><role sid="$R0$" is-editable="1" /><transition to-state-id="$S0$" verb="Details entered" helper-sp="" lookup-key="MARK_DETS_ENTERED" ask-for-comment="optional" mandatory-fields-message="" hours-before-auto-tran="" button-icon-path=""><role sid="$R0$" /></transition></state></flow>');
	dbms_lob.writeappend(v_xml, LENGTH(v_str), v_str);

	role_pkg.SetRole('Property Manager', v_r0);
	v_s0 := NVL(flow_pkg.GetStateId(ChainPropertyFlowSid, 'PROP_DETS_ENTERED'), flow_pkg.GetNextStateID);
	v_s1 := NVL(flow_pkg.GetStateId(ChainPropertyFlowSid, 'PROP_DETS_REQD'), flow_pkg.GetNextStateID);
	
	v_xml := REPLACE(v_xml, '$R0$', v_r0);
	v_xml := REPLACE(v_xml, '$S0$', v_s0);
	v_xml := REPLACE(v_xml, '$S1$', v_s1);
	
	flow_pkg.SetFlowFromXml(ChainPropertyFlowSid, XMLType(v_xml));

	UPDATE customer
	   SET property_flow_sid = ChainPropertyFlowSid
	 WHERE app_sid = security.security_pkg.GetApp;
END;

PROCEDURE TeardownChainPropertyWorkflow
AS
BEGIN
	IF ChainPropertyFlowSid IS NOT NULL THEN
		UPDATE customer 
		   SET property_flow_sid = NULL 
		 WHERE property_flow_sid = ChainPropertyFlowSid;

		security.securableobject_pkg.DeleteSO(
			security.security_pkg.GetAct, 
			ChainPropertyFlowSid
		);
		ChainPropertyFlowSid := NULL;
	END IF;

	BEGIN
		DELETE FROM csr.customer_flow_alert_class
		 WHERE flow_alert_class = 'property';
	EXCEPTION
		WHEN OTHERS THEN
			NULL;
	END;
END;

PROCEDURE SetupChainProperty 
AS
BEGIN
	chain.test_chain_utils_pkg.SetupSingleTier;

	SetupChainPropertyWorkflow;

	property_pkg.SavePropertyType(
			in_property_type_id => NULL,
			in_property_type_name => 'Test Property Type',
			in_space_type_ids => NULL,
			in_gresb_prop_type => NULL,
			out_property_type_id => ChainPropertyTypeId
	);

	SELECT c.company_sid
	  INTO ChainCompanySid
	  FROM chain.company c
	  JOIN chain.company_type ct ON c.company_type_id = ct.company_type_id
	 WHERE ct.is_top_company = 1;

	property_pkg.CreateProperty(
		in_company_sid				=> ChainCompanySid,
		in_description				=> 'Test Property', 
		in_country_code				=> 'gb',
		in_property_type_id			=> ChainPropertyTypeId,
		out_region_sid				=> ChainPropertyRegionSid
	);
END;

PROCEDURE TearDownChainProperty AS
BEGIN 
	IF ChainPropertyRegionSid IS NOT NULL THEN
		security.securableobject_pkg.DeleteSO(
			security.security_pkg.GetAct, 
			ChainPropertyRegionSid
		);
		ChainPropertyRegionSid := NULL;
	END IF;

	IF ChainPropertyTypeId IS NOT NULL THEN
		property_pkg.DeletePropertyType(ChainPropertyTypeId);
		ChainPropertyTypeId := NULL;
	END IF;

	TeardownChainPropertyWorkflow;
	
	chain.test_chain_utils_pkg.TearDownSingleTier;
END;

END test_common_pkg;
/
