-- Please update version.sql too -- this keeps clean builds in sync
define version=3245
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***
grant select, delete on csr.tab_portlet_rss_feed to chain;
grant select, delete on csr.user_setting_entry to chain;
grant select, delete on csr.alert_batch_run to chain;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

DECLARE
	v_chain_alerts NUMBER;

FUNCTION IsChainEnabled(in_app_sid security.security_pkg.T_SID_ID)
RETURN BOOLEAN
AS
	v_count							NUMBER(10);
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM chain.implementation
	 WHERE app_sid = in_app_sid;
	 
	RETURN v_count > 0;
END;

PROCEDURE CheckAlterSchemaPermission
AS
	v_act_id 	security.security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
	v_app_sid	security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
BEGIN
	IF NOT security.security_pkg.IsAccessAllowedSID(v_act_id, v_app_sid,  csr.csr_data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Access denied altering schema');
	END IF;
END;

PROCEDURE CreateFrame(
	in_name							IN	csr.alert_frame.name%TYPE,
	out_alert_frame_id				OUT	csr.alert_frame.alert_frame_id%TYPE
)
AS
BEGIN
	CheckAlterSchemaPermission;

	INSERT INTO csr.alert_frame
		(alert_frame_id, name)
	VALUES
		(csr.alert_frame_id_seq.NEXTVAL, in_name)
	RETURNING alert_frame_id INTO out_alert_frame_id;
END;

PROCEDURE SetupCsrAlerts
AS
	v_sat_ids					chain.T_NUMBER_LIST; -- std_alert_type ids
	v_sat_to_cat_id_map			security.security_pkg.T_SID_IDS; -- maps std_alert_type_ids to customer_alert_type ids
	v_af_id						csr.alert_frame.alert_frame_id%TYPE;
	v_customer_alert_type_id	csr.customer_alert_type.customer_alert_type_id%TYPE;		
BEGIN
	v_sat_ids := chain.T_NUMBER_LIST(
		5031,
		5032
	);
	
	FOR i IN v_sat_ids.FIRST .. v_sat_ids.LAST
	LOOP
		-- delete anything we might have already
		DELETE FROM csr.alert_template_body 
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP') 
		   AND customer_alert_type_id IN (
				SELECT customer_alert_type_id FROM csr.customer_alert_type WHERE std_alert_type_id = v_sat_ids(i)
			);

		DELETE FROM csr.alert_template
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP') 
		   AND customer_alert_type_id IN (
				SELECT customer_alert_type_id FROM csr.customer_alert_type WHERE std_alert_type_id = v_sat_ids(i)
			);

		DELETE FROM csr.alert_batch_run 
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP') 
		   AND customer_alert_type_id IN (
				SELECT customer_alert_type_id FROM csr.customer_alert_type WHERE std_alert_type_id = v_sat_ids(i)
			);

		DELETE FROM csr.customer_alert_type 
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP') 
		   AND customer_alert_type_id IN (
				SELECT customer_alert_type_id FROM csr.customer_alert_type WHERE std_alert_type_id = v_sat_ids(i)
			);
	   
		-- shove in a new row
		INSERT INTO csr.customer_alert_type 
			(app_sid, customer_alert_type_id, std_alert_type_id) 
		VALUES 
			(SYS_CONTEXT('SECURITY','APP'), csr.customer_alert_type_id_seq.nextval, v_sat_ids(i))
		RETURNING customer_alert_type_id INTO v_customer_alert_type_id;
		
		v_sat_to_cat_id_map(v_sat_ids(i)) := v_customer_alert_type_id;

		BEGIN
			SELECT MIN(alert_frame_id)
			  INTO v_af_id
			  FROM csr.alert_frame 
			 WHERE app_sid = SYS_CONTEXT('SECURITY','APP') 
			 GROUP BY app_sid;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				CreateFrame('Default', v_af_id);
		END;

		INSERT INTO csr.alert_template 
			(app_sid, customer_alert_type_id, alert_frame_id, send_type)
		VALUES
			(SYS_CONTEXT('SECURITY','APP'), v_customer_alert_type_id, v_af_id, 'automatic');
		 
	END LOOP;
	
	-- set the same template values for all langs in the app
	FOR r IN (
		SELECT lang 
		  FROM aspen2.translation_set 
		 WHERE application_sid = SYS_CONTEXT('SECURITY', 'APP') 
		   AND hidden = 0
	) LOOP
		INSERT INTO csr.alert_template_body
			(app_sid, customer_alert_type_id, lang, subject, body_html, item_html)
		VALUES
			(SYS_CONTEXT('SECURITY','APP'), v_sat_to_cat_id_map(5031), r.lang,
			'<template>Company relationship request accepted</template>',
			'<template>Dear <mergefield name="TO_FRIENDLY_NAME"/>,<br/><br/>Your request for a relationship with <mergefield name="REQUESTED_COMPANY"/> from your company <mergefield name="REQUESTING_COMPANY"/> (<mergefield name="COMPANY_URL"/>) was accepted.<br/>Many thanks,<br/><mergefield name="FROM_NAME"/></template>',
			'<template />');

		INSERT INTO csr.alert_template_body
			(app_sid, customer_alert_type_id, lang, subject, body_html, item_html)
		VALUES
			(SYS_CONTEXT('SECURITY','APP'), v_sat_to_cat_id_map(5032), r.lang,
			'<template>Company relationship request refused</template>',
			'<template>Dear <mergefield name="TO_FRIENDLY_NAME"/>,<br/><br/>We have rejected your relationship request from your company <mergefield name="REQUESTING_COMPANY"/> to <mergefield name="REQUESTED_COMPANY"/>.<br/>Many thanks,<br/><mergefield name="FROM_NAME"/></template>',
			'<template />');
	END LOOP;
END;

BEGIN
	security.user_pkg.logonadmin;
	FOR r IN (Select application_sid_id app_sid, website_name host from security.website where lower(website_name) like '%.com')
	LOOP
		IF IsChainEnabled(r.app_sid) THEN
			security.user_pkg.logonadmin(r.host);
			SELECT COUNT(*)
			  INTO v_chain_alerts
			  FROM CSR.customer_alert_type
			 WHERE app_sid = r.app_sid AND std_Alert_Type_Id in (5031, 5032);
			IF v_chain_alerts = 0 THEN
				dbms_output.put_line(r.host||' updating chain alerts');
				SetupCsrAlerts;
			END IF;
			security.user_pkg.logonadmin;
		END IF;
	END LOOP;
END;
/


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\chain\setup_pkg
@..\chain\setup_body

@update_tail
