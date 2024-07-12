CREATE OR REPLACE PACKAGE BODY CSR.Alert_Pkg AS

PROCEDURE CheckAlterSchemaPermission
AS
	v_act_id 	security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
	v_app_sid	security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(v_act_id, v_app_sid,  csr_data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied altering schema');
	END IF;
END;

PROCEDURE CheckReadPermission
AS
	v_act_id 	security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
	v_app_sid	security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(v_act_id, v_app_sid,  security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading schema');
	END IF;
END;


FUNCTION GetSystemMailbox(
	in_mailbox_name					IN	VARCHAR2
)
RETURN NUMBER
AS
	v_email	VARCHAR2(255);
BEGIN
	SELECT system_mail_address 
	  INTO v_email
	  FROM customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	 
	RETURN mail.mail_pkg.getMailboxSIDFromPath(NULL, v_email||'/'||in_mailbox_name);
END;

FUNCTION GetUserMailbox
RETURN NUMBER
AS
BEGIN
	return GetUserMailbox(SYS_CONTEXT('SECURITY','SID'));
END;

FUNCTION GetUserMailbox(
	in_user_sid						IN	csr_user.csr_user_sid%TYPE
)
RETURN NUMBER
AS
BEGIN
	RETURN GetSystemMailbox('Users/'||in_user_sid);
END;

FUNCTION GetTrackerMailbox(
	in_mailbox_name					IN	VARCHAR2
)
RETURN NUMBER
AS
	v_email	VARCHAR2(255);
BEGIN
	SELECT tracker_mail_address 
	  INTO v_email
	  FROM customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	 
	RETURN mail.mail_pkg.getMailboxSIDFromPath(NULL, v_email||'/'||in_mailbox_name);
END;

PROCEDURE CopyAlertToUser(
	in_mailbox_sid					IN	security_pkg.T_SID_ID,
	in_message_uid					IN	security_pkg.T_SID_ID,
	in_user_sid						IN 	csr_user.csr_user_sid%TYPE
)
AS
	v_mailbox_sid	NUMBER;
	v_users_sid		NUMBER;
	v_new_uid		NUMBER;
BEGIN
	-- get the mailbox for the user
	v_users_sid := GetSystemMailbox('Users');
	v_mailbox_sid := mail.mail_pkg.getMailboxSIDFromPath(v_users_sid, in_user_sid);
	
	-- copy the message
	mail.mail_pkg.copyMessage(in_mailbox_sid, in_message_uid, v_mailbox_sid, v_new_uid);
END;

PROCEDURE DeleteTemplate(
	in_customer_alert_type_id		IN	customer_alert_type.customer_alert_type_id%TYPE	
)
AS
BEGIN
	CheckAlterSchemaPermission;
	
	DELETE FROM flow_item_generated_alert
	 WHERE flow_transition_alert_id IN (
		SELECT flow_transition_alert_id FROM flow_transition_alert WHERE customer_alert_type_id = in_customer_alert_type_id
	 );
	
	DELETE FROM flow_transition_alert_role
	 WHERE flow_transition_alert_id IN (
		SELECT flow_transition_alert_id FROM flow_transition_alert WHERE customer_alert_type_id = in_customer_alert_type_id
	 );
	
	DELETE FROM flow_transition_alert_cc_role
	 WHERE flow_transition_alert_id IN (
		SELECT flow_transition_alert_id FROM flow_transition_alert WHERE customer_alert_type_id = in_customer_alert_type_id
	 );
	
	DELETE FROM flow_transition_alert
	 WHERE customer_alert_type_id = in_customer_alert_type_id;
	
	DELETE FROM alert_template_body
	 WHERE customer_alert_type_id = in_customer_alert_type_id;
	 
	DELETE FROM alert_template
	 WHERE customer_alert_type_id = in_customer_alert_type_id;
	
	DELETE FROM cms_alert_type
	 WHERE customer_alert_type_id = in_customer_alert_type_id;
	 
	DELETE FROM cms_field_change_alert
	 WHERE customer_alert_type_id = in_customer_alert_type_id;
	 
	DELETE FROM customer_alert_type_param
	 WHERE customer_alert_type_id = in_customer_alert_type_id;
	 
	DELETE FROM alert_batch_run
	 WHERE customer_alert_type_id = in_customer_alert_type_id;

	campaigns.campaign_pkg.RemoveCustomerAlertType(in_customer_alert_type_id);
	 
	DELETE FROM customer_alert_type
	 WHERE customer_alert_type_id = in_customer_alert_type_id;
END;

PROCEDURE GetTemplateForStdAlertType(
	in_std_alert_type_id			IN	std_alert_type.std_alert_type_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR,
	out_frames_cur					OUT	SYS_REFCURSOR,
	out_bodies_cur					OUT	SYS_REFCURSOR,
	out_params_cur					OUT	SYS_REFCURSOR
)
AS
	v_customer_alert_type_id	customer_alert_type.customer_alert_type_id%TYPE;
BEGIN
	BEGIN
		SELECT customer_alert_type_id 
		  INTO v_customer_alert_type_id
		  FROM customer_alert_type
		 WHERE std_alert_type_id = in_std_alert_type_id
		   AND app_sid = SYS_CONTEXT('SECURITY','APP');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- this will not find any data, i.e all but the first cursor will be empty which is the behaviour we want
			-- (ReadTemplate in AlertTemplate.cs checks for a null send_type and then sets the Exists property to false)
			v_customer_alert_type_id := -1;			
	END;
	
	GetTemplate(v_customer_alert_type_Id, out_cur, out_frames_cur, out_bodies_cur, out_params_cur);
END;


-- Apparently reading alert templates is public (e.g. reset password mail)
-- Could be finer grained, but oh well.
PROCEDURE GetTemplate(
	in_customer_alert_type_id		IN	customer_alert_type.customer_alert_type_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR,
	out_frames_cur					OUT	SYS_REFCURSOR,
	out_bodies_cur					OUT	SYS_REFCURSOR,
	out_params_cur					OUT	SYS_REFCURSOR
)
AS
	v_get_params_sp				customer_alert_type.get_params_sp%TYPE;
	v_customer_alert_type_id	customer_alert_type.customer_alert_type_id%TYPE;
	v_std_alert_type_id			std_alert_type.std_alert_type_id%TYPE;
	v_alert_frame_id			alert_template.alert_frame_id%TYPE;
	v_send_type					alert_template.send_type%TYPE;
	v_reply_to_name				alert_template.reply_to_name%TYPE;
	v_reply_to_email			alert_template.reply_to_email%TYPE;
	v_from_name					alert_template.from_name%TYPE;
	v_from_email				alert_template.from_email%TYPE;
	v_has_body					NUMBER;
	v_save_in_sent_alerts		alert_template.save_in_sent_alerts%TYPE;
BEGIN
	BEGIN
		-- Ick
		SELECT std_alert_type_id, alert_frame_id, send_type, reply_to_name, reply_to_email, customer_alert_type_id, from_name, from_email, has_body, save_in_sent_alerts
		  INTO v_std_alert_type_id, v_alert_frame_id, v_send_type, v_reply_to_name, v_reply_to_email, v_customer_alert_type_id, v_from_name, v_from_email, v_has_body, v_save_in_sent_alerts
		  FROM (SELECT x.std_alert_type_id, x.alert_frame_id, x.send_type, x.customer_alert_type_id,
		  			   x.reply_to_name, x.reply_to_email, x.from_name, x.from_email, x.has_body, x.save_in_sent_alerts
				  FROM ( -- Walk up the alert type tree from the starting point
				  		SELECT sat.std_alert_type_id, tpl.alert_frame_id, tpl.send_type, cat.customer_alert_type_id, tpl.save_in_sent_alerts,
				  			   tpl.reply_to_name, tpl.reply_to_email, tpl.from_name, tpl.from_email, rownum rn,
							   CASE WHEN EXISTS (SELECT * FROM alert_template_body WHERE customer_alert_type_id = cat.customer_alert_type_id) THEN 1 ELSE 0 END has_body
				    	  FROM customer_alert_type cat
				    	  	LEFT JOIN alert_template tpl ON cat.customer_alert_type_id = tpl.customer_alert_type_id AND tpl.app_sid = cat.app_sid
							LEFT JOIN std_alert_type sat ON cat.std_alert_type_id = sat.std_alert_type_id
				    	 WHERE cat.app_sid = SYS_CONTEXT('SECURITY', 'APP')
						 START WITH cat.customer_alert_type_id = in_customer_alert_type_id
					   CONNECT BY PRIOR sat.parent_alert_type_id = sat.std_alert_type_id
					   ) x
				 WHERE x.send_type IS NOT NULL -- filter out so we have only the configured alerts (i.e. row exists in alert_template)
				 ORDER BY x.rn -- we need to order again
			    )
		  WHERE rownum = 1; -- get the first configured alert
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- return at least the alert type (MIN forces null if it doesn't exist)
			SELECT MIN(std_alert_type_id)
			  INTO v_std_alert_type_id
			  FROM customer_alert_type
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND customer_alert_type_Id = in_customer_alert_type_Id;
			v_customer_alert_type_id := in_customer_alert_type_Id;
	END;
	
	OPEN out_cur FOR
	    SELECT v_customer_alert_type_id customer_alert_type_Id, v_std_alert_type_id std_alert_type_id, 
				v_alert_frame_id alert_frame_id, v_send_type send_type,
	    	   v_reply_to_name reply_to_name, v_reply_to_email reply_to_email,
	    	   v_from_name from_name, v_from_email from_email, v_has_body has_body, v_save_in_sent_alerts save_in_sent_alerts
		  FROM DUAL;
		  
	OPEN out_frames_cur FOR
		SELECT lang, html
		  FROM alert_frame_body
		 WHERE alert_frame_id = v_alert_frame_id;

	OPEN out_bodies_cur FOR
		SELECT cat.std_alert_type_id, lang, subject, body_html, item_html
		  FROM alert_template_body atb
		  JOIN alert_template alt ON atb.customer_alert_type_id = alt.customer_alert_type_id AND atb.app_sid = alt.app_sid
		  JOIN customer_alert_type cat ON alt.customer_alert_type_id = cat.customer_alert_type_id AND alt.app_sid = cat.app_sid
		 WHERE cat.customer_alert_type_id = v_customer_alert_type_id;

	BEGIN
		SELECT get_params_sp, std_alert_type_id 
		  INTO v_get_params_sp, v_std_alert_type_id
		  FROM customer_alert_type
		 WHERE customer_alert_type_id = v_customer_alert_type_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_get_params_sp := null;
			v_std_alert_type_id := null;
	END;
	
	/*
	-- stick this into an SP for the CMS alerts
	
    	 -- XXX: do we need to trim rather than use to_char
		 SELECT ctat.alert_type_id, tc.oracle_column, tc.description, NVL(to_char(tc.help), 'n/a'), ctat.has_repeats, pos
		  FROM cms_tab_alert_type ctat
			JOIN cms.tab_column tc ON ctat.tab_sid = tc.tab_sid AND ctat.app_sid = tc.app_sid
		 WHERE description IS NOT NULL
         ORDER BY alert_type_id, display_pos;
	*/
	
	
	IF v_get_params_sp IS NOT NULL THEN
		EXECUTE IMMEDIATE 'begin '||v_get_params_sp||'(:1,:2,:3);end;'
			USING v_std_alert_type_id, v_customer_alert_type_id, out_params_cur;
	ELSE 
		OPEN out_params_cur FOR	
			-- umm -- let's hope they haven't shoved params in both? or maybe that might come in handy?
			SELECT std_alert_type_id, field_name, description, help_text, repeats, display_pos
			  FROM std_alert_type_param
			 WHERE std_alert_type_id = v_std_alert_type_id
			 UNION 
			SELECT cat.std_alert_type_id, catp.field_name, catp.description, catp.help_text, catp.repeats, catp.display_pos
			  FROM customer_alert_type_param catp	
				JOIN customer_alert_type cat ON catp.customer_alert_type_id = cat.customer_alert_type_id AND catp.app_sid = cat.app_sid
			 WHERE cat.customer_alert_type_id = v_customer_alert_type_id
			 ORDER BY display_pos;
	END IF;
END;

PROCEDURE GetStdAlertTypeGroups(
	out_alert_group_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	CheckAlterSchemaPermission;

	OPEN out_alert_group_cur FOR
		SELECT std_alert_type_group_id, description
		  FROM std_alert_type_group
		 WHERE std_alert_type_group_id IN (
			SELECT std_alert_type_group_id
			  FROM std_alert_type sat 
			  JOIN customer_alert_type ct ON sat.std_alert_type_id = ct.std_alert_type_id
			 WHERE ct.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ) OR ( std_alert_type_group_id = csr_data_pkg.ALERT_GROUP_CMS
		  AND EXISTS (
			SELECT *
			  FROM cms_alert_type
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND include_in_alert_setup = 1
			)
		 );
END;

PROCEDURE GetStdAlertTypes(
	out_alert_cur					OUT	SYS_REFCURSOR,
	out_params_cur					OUT SYS_REFCURSOR
)
AS
BEGIN
	CheckAlterSchemaPermission;

	OPEN out_alert_cur FOR
		SELECT customer_alert_type_id, std_alert_type_id, description, send_trigger, sent_from, status, lvl, std_alert_type_group_id
		  FROM (
			SELECT ct.customer_alert_type_id, y.std_alert_type_id, y.description, y.send_trigger, y.sent_from,
					CASE 
						 WHEN NOT EXISTS (SELECT * FROM alert_template_body WHERE customer_alert_type_id = ct.customer_alert_type_id)
						   OR (t.send_type IS NULL AND y.prior_std_alert_type_id IS NULL) THEN 'unconfigured' -- not configured
						 WHEN t.send_type IS NULL AND y.prior_std_alert_type_id IS NOT NULL THEN 'inherited' -- inherits from 
						 ELSE t.send_type
					END status, y.lvl, y.std_alert_type_group_id
			  FROM customer_alert_type ct, alert_template t, (
				 SELECT std_alert_type_id, description, send_trigger, sent_from, level lvl, rownum rn,
					    PRIOR std_alert_type_id prior_std_alert_type_id, std_alert_type_group_id
				   FROM std_alert_type
				  START WITH parent_alert_type_id IS NULL
				CONNECT BY PRIOR std_alert_type_id = parent_alert_type_id
				  ORDER SIBLINGS BY std_alert_type_id
			  ) y
			 WHERE ct.std_alert_type_id = y.std_alert_type_id
			   AND ct.customer_alert_type_id = t.customer_alert_type_id(+)
			   AND ct.app_sid = t.app_sid(+)
			 ORDER BY y.rn	
		  )
		UNION
		-- include cms alert types that are configured to show on the alert setup page
		SELECT ct.customer_alert_type_id, null std_alert_type_id, cat.description, null send_trigger, null sent_from,
			   t.send_type status, 1 lvl, csr_data_pkg.ALERT_GROUP_CMS
		  FROM customer_alert_type ct
		  JOIN alert_template t ON ct.app_sid = t.app_sid AND ct.customer_alert_type_id = t.customer_alert_type_id
		  JOIN cms_alert_type cat ON ct.app_sid = cat.app_sid AND ct.customer_alert_type_id = cat.customer_alert_type_id
		 WHERE std_alert_type_id IS NULL
		   AND include_in_alert_setup = 1
		UNION
		-- include activity alert types
		SELECT ct.customer_alert_type_id, null std_alert_type_id, ata.label description, null send_trigger, null sent_from,
			   t.send_type status, 1 lvl, csr_data_pkg.ALERT_GROUP_SUPPLYCHAIN
		  FROM customer_alert_type ct
		  JOIN alert_template t ON ct.app_sid = t.app_sid AND ct.customer_alert_type_id = t.customer_alert_type_id
		  JOIN chain.activity_type_alert ata ON ct.app_sid = ata.app_sid AND ct.customer_alert_type_id = ata.customer_alert_type_id
		 WHERE std_alert_type_id IS NULL
		 ;

	-- nothing fancy here as we're just getting the std alert types
	OPEN out_params_cur FOR
		SELECT ct.customer_alert_type_id, atp.std_alert_type_id, atp.field_name, atp.description, atp.help_text, atp.repeats, display_pos
		  FROM customer_alert_type ct
		  JOIN std_alert_type_param atp ON ct.std_alert_type_id = atp.std_alert_type_id
		UNION
		-- include cms alert types that are configured to show on the alert setup page
		SELECT ct.customer_alert_type_id, null std_alert_type_id, ctp.field_name, ctp.description, ctp.help_text, ctp.repeats, ctp.display_pos
		  FROM customer_alert_type ct
		  JOIN cms_alert_type cat ON ct.app_sid = cat.app_sid AND ct.customer_alert_type_id = cat.customer_alert_type_id
		  JOIN customer_alert_type_param ctp ON cat.customer_alert_type_id = ctp.customer_alert_type_id
		 WHERE std_alert_type_id IS NULL
		   AND cat.include_in_alert_setup = 1
		UNION
		-- include activity alert types
		SELECT ctp.customer_alert_type_id, null std_alert_type_id, ctp.field_name, ctp.description, ctp.help_text, ctp.repeats, ctp.display_pos
		  FROM customer_alert_type_param ctp
		  JOIN chain.activity_type_alert ata ON ctp.app_sid = ata.app_sid AND ctp.customer_alert_type_id = ata.customer_alert_type_id
		-- order by applies to whole union  
		ORDER BY customer_alert_type_id, display_pos;
END;

PROCEDURE GetStdAlertType(
	in_std_alert_type_id			IN	std_alert_type.std_alert_type_id%TYPE,
	out_std_alert_cur	            OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_std_alert_cur FOR
		SELECT std_alert_type_id, parent_alert_type_id, description, send_trigger, sent_from, override_user_send_setting, override_template_send_type
		  FROM std_alert_type
		 WHERE std_alert_type_id = in_std_alert_type_id;
END;

PROCEDURE GetStdAlertTypesAndGroups(
	out_alert_group_cur				OUT	SYS_REFCURSOR,
	out_alert_cur					OUT	SYS_REFCURSOR,
	out_params_cur					OUT SYS_REFCURSOR
)
AS
BEGIN
	GetStdAlertTypeGroups(out_alert_group_cur);
	GetStdAlertTypes(out_alert_cur, out_params_cur);
END;

PROCEDURE GetStdAlertTypeParams(
	in_std_alert_type_id			IN	std_alert_type_param.std_alert_type_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- Restricts to the types of alert the customer has enabled, and the info is public apart from that
	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ ct.customer_alert_type_id, ct.std_alert_type_id, atp.field_name, atp.description, atp.help_text, atp.repeats
		  FROM customer_alert_type ct
			JOIN std_alert_type_param atp ON ct.std_alert_type_id = atp.std_alert_type_id
         WHERE ct.std_alert_type_id = in_std_alert_type_id;
END;

PROCEDURE GetCustomerAlertTypeParams(
	in_customer_alert_type_id		IN	customer_alert_type_param.customer_alert_type_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_get_params_sp				customer_alert_type.get_params_sp%TYPE;
	v_std_alert_type_id			customer_alert_type.std_alert_type_id%TYPE;
BEGIN
	-- Restricts to the types of alert the customer has enabled, and the info is public apart from that	
	SELECT get_params_sp, std_alert_type_id
	  INTO v_get_params_sp, v_std_alert_type_id
	  FROM customer_alert_type
	 WHERE customer_alert_type_id = in_customer_alert_type_id;
	
	IF v_get_params_sp IS NOT NULL THEN
		EXECUTE IMMEDIATE 'begin '||v_get_params_sp||'(:1,:2,:3);end;'
			USING v_std_alert_type_id, in_customer_alert_type_id, out_cur;
	ELSE 
		OPEN out_cur FOR	
			-- umm -- let's hope they haven't shoved params in both? or maybe that might come in handy?
			SELECT /*+ALL_ROWS*/ ct.customer_alert_type_id, atp.field_name, atp.description, atp.help_text, atp.repeats, atp.display_pos
			  FROM customer_alert_type ct
				JOIN std_alert_type_param atp ON ct.std_alert_type_id = atp.std_alert_type_id
			 WHERE ct.customer_alert_type_id = in_customer_alert_type_id			 
			 UNION
			SELECT /*+ALL_ROWS*/ catp.customer_alert_type_id, catp.field_name, catp.description, catp.help_text, catp.repeats, catp.display_pos
			  FROM customer_alert_type_param catp
			 WHERE customer_alert_type_id = in_customer_alert_type_id			 
			 ORDER BY display_pos;
	END IF;
END;

PROCEDURE GetFrames(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- this is overkill for viewing templates and stops the "send message" functionality
	-- on the edit users page working.
	--CheckAlterSchemaPermission;
	CheckReadPermission;

	OPEN out_cur FOR 
		SELECT alert_frame_id, name
		  FROM alert_frame;
END;

PROCEDURE CreateFrame(
	in_name							IN	alert_frame.name%TYPE,
	out_alert_frame_id				OUT	alert_frame.alert_frame_id%TYPE
)
AS
BEGIN
	CheckAlterSchemaPermission;

	INSERT INTO alert_frame
		(alert_frame_id, name)
	VALUES
		(alert_frame_id_seq.NEXTVAL, in_name)
	RETURNING alert_frame_id INTO out_alert_frame_id;
END;

PROCEDURE GetOrCreateFrame(
	in_name							IN	alert_frame.name%TYPE,
	out_alert_frame_id				OUT	alert_frame.alert_frame_id%TYPE
)
AS
BEGIN
	BEGIN
		SELECT alert_frame_id
		  INTO out_alert_frame_id
		  FROM alert_frame
		 WHERE name = in_name;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			CreateFrame(in_name, out_alert_frame_id);
	END;
END;

PROCEDURE GetFrameBody( 
	in_alert_frame_id				IN	alert_frame_body.alert_frame_id%TYPE,
	in_lang							IN	alert_frame_body.lang%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- this is overkill for viewing templates and stops the "send message" functionality
	-- on the edit users page working.
	--CheckAlterSchemaPermission;
	CheckReadPermission;

	OPEN out_cur FOR
		SELECT html
		  FROM alert_frame_body
		 WHERE alert_frame_id = in_alert_frame_id AND lang = in_lang; 
END;

PROCEDURE GetFrameBodies( 
	in_alert_frame_id				IN	alert_frame_body.alert_frame_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- this is overkill for viewing templates and stops the "send message" functionality
	-- on the edit users page working.
	--CheckAlterSchemaPermission;
	CheckReadPermission;

	OPEN out_cur FOR
		SELECT lang, html
		  FROM alert_frame_body
		 WHERE alert_frame_id = in_alert_frame_id; 
END;

PROCEDURE SaveFrameBody(
	in_alert_frame_id				IN	alert_frame_body.alert_frame_id%TYPE,
	in_lang							IN	alert_frame_body.lang%TYPE,
	in_html							IN	alert_frame_body.html%TYPE
)
AS
BEGIN
	CheckAlterSchemaPermission;

	BEGIN
		INSERT INTO alert_frame_body
			(alert_frame_id, lang, html)
		VALUES
			(in_alert_frame_id, in_lang, in_html);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE alert_frame_body
			   SET html = in_html
			 WHERE alert_frame_id = in_alert_frame_id AND lang = in_lang;
	END;
END;

PROCEDURE DeleteFrame(
	in_alert_frame_id				IN	alert_frame.alert_frame_id%TYPE
)
AS
BEGIN
	CheckAlterSchemaPermission;
	
	BEGIN
		DELETE FROM alert_frame_body
		 WHERE alert_frame_id = in_alert_frame_id;

		DELETE FROM alert_frame
		 WHERE alert_frame_id = in_alert_frame_id;
	EXCEPTION
		WHEN csr_data_pkg.CHILD_RECORD_FOUND THEN
			RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_OBJECT_IN_USE, 'The frame with id '||in_alert_frame_id||' is in use');
	END;
END;	

PROCEDURE GetTemplateAndBodyAndParams(
	in_customer_alert_type_id		IN	customer_alert_type.customer_alert_type_id%TYPE,
	in_lang							IN	alert_template_body.lang%TYPE,
	out_body_cur					OUT	SYS_REFCURSOR,
	out_params_cur					OUT SYS_REFCURSOR
)
AS
	v_get_params_sp				customer_alert_type.get_params_sp%TYPE;
	v_std_alert_type_id			std_alert_type.std_alert_type_id%TYPE;
BEGIN
	CheckAlterSchemaPermission;

	OPEN out_body_cur FOR
		SELECT cat.std_alert_type_id, at.alert_frame_id, at.send_type, at.reply_to_name, at.reply_to_email, at.save_in_sent_alerts,
			   atp.subject, atp.body_html, atp.item_html
		  FROM customer_alert_type cat
			LEFT JOIN alert_template at ON cat.customer_alert_type_id = at.customer_alert_type_id AND cat.app_sid = at.app_sid
			LEFT JOIN alert_template_body atp ON at.customer_alert_type_id = atp.customer_alert_type_id AND at.app_sid = atp.app_sid AND atp.lang = in_lang
		 WHERE cat.customer_alert_type_id = in_customer_alert_type_id;

	BEGIN
		SELECT get_params_sp, std_alert_type_id
		  INTO v_get_params_sp, v_std_alert_type_id
		  FROM customer_alert_type
		 WHERE customer_alert_type_id = in_customer_alert_type_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- not configure so just return some nulls
			v_get_params_sp := NULL;
			v_std_alert_type_id := NULL;
	END;
	
	IF v_get_params_sp IS NOT NULL THEN
		EXECUTE IMMEDIATE 'begin '||v_get_params_sp||'(:1,:2,:3);end;'
			USING v_std_alert_type_id, in_customer_alert_type_id, out_params_cur;
	ELSE 
		OPEN out_params_cur FOR	
			-- umm -- let's hope they haven't shoved params in both? or maybe that might come in handy?
			SELECT field_name, description, help_text, repeats, display_pos
			  FROM std_alert_type_param
			 WHERE std_alert_type_id = v_std_alert_type_id
			 UNION 
			SELECT catp.field_name, catp.description, catp.help_text, catp.repeats, catp.display_pos
			  FROM customer_alert_type_param catp	
				JOIN customer_alert_type cat ON catp.customer_alert_type_id = cat.customer_alert_type_id AND catp.app_sid = cat.app_sid
			 WHERE cat.customer_alert_type_id = in_customer_alert_type_id
			 ORDER BY display_pos;
	END IF;		   
END;

PROCEDURE SaveTemplateAndBody(
	in_customer_alert_type_id		IN	alert_template.customer_alert_type_id%TYPE,
	in_alert_frame_id				IN	alert_template.alert_frame_id%TYPE,
	in_send_type					IN	alert_template.send_type%TYPE,
	in_reply_to_name				IN	alert_template.reply_to_name%TYPE,
	in_reply_to_email				IN	alert_template.reply_to_email%TYPE,
	in_lang							IN	alert_template_body.lang%TYPE,
	in_subject						IN	alert_template_body.subject%TYPE,
	in_body_html					IN	alert_template_body.body_html%TYPE,
	in_item_html					IN	alert_template_body.item_html%TYPE
)
AS
	v_is_body_empty						BOOLEAN;
	v_is_subject_empty					BOOLEAN;
BEGIN
	CheckAlterSchemaPermission;

	BEGIN
		INSERT INTO alert_template
			(customer_alert_type_id, alert_frame_id, send_type, reply_to_name, reply_to_email)
		VALUES
			(in_customer_alert_type_id, in_alert_frame_id, in_send_type, in_reply_to_name, in_reply_to_email);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE alert_template
			   SET alert_frame_id = in_alert_frame_id,
			   	   send_type = in_send_type,
			   	   reply_to_name = in_reply_to_name,
			   	   reply_to_email = in_reply_to_email
			 WHERE customer_alert_type_id = in_customer_alert_type_id;
	END;
	
	v_is_body_empty := XMLTYPE(in_body_html).Extract('/template/text()') IS NULL AND XMLTYPE(in_body_html).Extract('/template/*') IS NULL;
	v_is_subject_empty := XMLTYPE(in_subject).Extract('/template/text()') IS NULL AND XMLTYPE(in_subject).Extract('/template/*') IS NULL;

	-- Delete template if both subject and body are null
	IF v_is_body_empty AND v_is_subject_empty THEN
		DELETE FROM alert_template_body
		 WHERE customer_alert_type_id = in_customer_alert_type_id AND lang = in_lang;
	ELSE
		BEGIN
			INSERT INTO alert_template_body
				(customer_alert_type_id, lang, subject, body_html, item_html)
			VALUES
				(in_customer_alert_type_id, in_lang, in_subject, in_body_html, in_item_html);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE alert_template_body
				   SET subject = in_subject,
					   body_html = in_body_html,
					   item_html = in_item_html
				 WHERE customer_alert_type_id = in_customer_alert_type_id AND lang = in_lang;
		END;
	END IF;
END;

PROCEDURE BeginStdAlertBatchRun(
	in_std_alert_type_id		IN	std_alert_type.std_alert_type_id%TYPE,
	in_alert_pivot_dtm			IN	DATE DEFAULT systimestamp
)
AS
BEGIN
	DELETE FROM temp_csr_user;
	
	INSERT INTO temp_csr_user (app_sid, csr_user_sid)
		SELECT cu.app_sid, cu.csr_user_sid
		  FROM csr_user cu
		  JOIN security.user_table ut ON ut.sid_id = cu.csr_user_sid
		 WHERE cu.app_sid IN (
					SELECT app_sid
					  FROM customer_alert_type
					 WHERE std_alert_type_id = in_std_alert_type_id
				)
		   AND cu.send_alerts = 1
		  -- AND ut.account_enabled = 1 -- we send alerts to users that have been deactivated (ALERT_USER_INACTIVE_SYSTEM)
		 MINUS
		SELECT abr.app_sid, abr.csr_user_sid
		  FROM csr.alert_batch_run abr
		  JOIN customer_alert_type cat ON abr.customer_alert_type_id = cat.customer_alert_type_id AND abr.app_sid = cat.app_sid
		 WHERE cat.std_alert_type_id = in_std_alert_type_id;		
	
	-- set default next fire times for users who have never had a batch run
	INSERT INTO alert_batch_run (app_sid, csr_user_sid, customer_alert_type_id, prev_fire_time, next_fire_time)
		SELECT /*+ALL_ROWS*/ abrt.app_sid, abrt.csr_user_sid, cat.customer_alert_type_id, null, abrt.next_fire_time_gmt
		  FROM v$alert_batch_run_time abrt
		  JOIN customer_alert_type cat ON abrt.app_sid = cat.app_sid
		 WHERE (abrt.app_sid, abrt.csr_user_sid) IN (
		 		SELECT app_sid, csr_user_sid
		  		  FROM temp_csr_user)
		  	AND cat.std_alert_type_id = in_std_alert_type_id;

	-- clean up anything left from the last run
	DELETE FROM temp_alert_batch_run 
	 WHERE std_alert_type_id = in_std_alert_type_id;

	-- save all users we need to run for this time
	INSERT INTO temp_alert_batch_run (customer_alert_type_id, std_alert_type_id, app_sid, csr_user_sid, prev_fire_time_gmt, this_fire_time, this_fire_time_gmt)
  		SELECT /*+ALL_ROWS*/ cat.customer_alert_type_id, cat.std_alert_type_id, abr.app_sid, abr.csr_user_sid, abr.prev_fire_time, abrt.prev_fire_time, abrt.prev_fire_time_gmt
		  FROM alert_batch_run abr
		  JOIN v$alert_batch_run_time abrt ON abr.app_sid = abrt.app_sid AND abr.csr_user_sid = abrt.csr_user_sid 
		  JOIN customer_alert_type cat ON abr.customer_alert_type_id = cat.customer_alert_type_id AND abr.app_sid = cat.app_sid
		 WHERE cat.std_alert_type_id = in_std_alert_type_id
		   AND in_alert_pivot_dtm >= abr.next_fire_time;
	-- we need to keep this info across transactions
	COMMIT;
END;


PROCEDURE BeginCustomerAlertBatchRun(
	in_customer_alert_type_id		IN	customer_alert_type.customer_alert_type_id%TYPE
)
AS
	v_app_sid				security_pkg.T_SID_ID;
	v_std_alert_type_id		std_alert_type.std_alert_type_id%TYPE;
BEGIN
	DELETE FROM temp_csr_user; -- XXX: do we need to stick in WHERE app_sid = ? presume not as we don't kick off loads of these in one transaction simultaneously
	
	SELECT app_sid, std_alert_type_id
	  INTO v_app_sid, v_std_alert_type_id
	  FROM customer_alert_type
	 WHERE customer_alert_type_id = in_customer_alert_type_id;
	
	INSERT INTO temp_csr_user (app_sid, csr_user_sid)
		SELECT cu.app_sid, cu.csr_user_sid
		  FROM csr_user cu
		  JOIN security.user_table ut ON ut.sid_id = cu.csr_user_sid
		 WHERE cu.app_sid = v_app_sid
		   AND cu.send_alerts = 1
		   AND ut.account_enabled = 1
		 MINUS
		SELECT app_sid, csr_user_sid
		  FROM csr.alert_batch_run
	     WHERE customer_alert_type_id = in_customer_alert_type_id;

	-- set default next fire times for users who have never had a batch run
	INSERT INTO alert_batch_run (app_sid, csr_user_sid, customer_alert_type_id, prev_fire_time, next_fire_time)
		SELECT /*+ALL_ROWS*/ abrt.app_sid, abrt.csr_user_sid, in_customer_alert_type_id, null, abrt.next_fire_time_gmt
		  FROM v$alert_batch_run_time abrt
		 WHERE (app_sid, csr_user_sid) IN (
		 		SELECT app_sid, csr_user_sid
		  		  FROM temp_csr_user);

	-- clean up anything left from the last run
	DELETE FROM temp_alert_batch_run 
	 WHERE customer_alert_type_id = in_customer_alert_type_id;

	-- save all users we need to run for this time
	INSERT INTO temp_alert_batch_run (customer_alert_type_id, std_alert_type_id, app_sid, csr_user_sid, prev_fire_time_gmt, this_fire_time, this_fire_time_gmt)
  		SELECT /*+ALL_ROWS*/ abr.customer_alert_type_id, v_std_alert_type_id, abr.app_sid, abr.csr_user_sid, abr.prev_fire_time, abrt.prev_fire_time, abrt.prev_fire_time_gmt
		  FROM alert_batch_run abr
		  JOIN v$alert_batch_run_time abrt ON abr.app_sid = abrt.app_sid AND abr.csr_user_sid = abrt.csr_user_sid 			
		 WHERE abr.customer_alert_type_id = in_customer_alert_type_id
		   AND systimestamp >= abr.next_fire_time;
	-- we need to keep this info across transactions
	COMMIT;
END;

PROCEDURE RecordUserBatchRun(
	in_customer_alert_type_id		IN	customer_alert_type.customer_alert_type_id%TYPE,
	in_csr_user_sid					IN	alert_batch_run.csr_user_sid%TYPE
)
AS
	v_app_sid	security_pkg.T_SID_ID;
BEGIN
	SELECT app_sid 
	  INTO v_app_sid
	  FROM customer_alert_type
	 WHERE customer_alert_type_id = in_customer_alert_type_id;
	 
	-- set the next batch run time for the given user / alert type	   	   					    
	UPDATE alert_batch_run
	   SET prev_fire_time = next_fire_time,
	   	   next_fire_time = (SELECT next_fire_time_gmt
	   	   					   FROM v$alert_batch_run_time
	   	   					  WHERE app_sid = v_app_sid AND csr_user_sid = in_csr_user_sid)
	 WHERE customer_alert_type_id = in_customer_alert_type_id
	   AND csr_user_sid = in_csr_user_sid;
	   
	-- we've done this user
	DELETE FROM temp_alert_batch_run
	 WHERE customer_alert_type_id = in_customer_alert_type_id
	   AND csr_user_sid = in_csr_user_sid;
	   
	-- we want to remember this
	COMMIT;
END;

PROCEDURE RecordUserBatchRun(
	in_app_sid						IN	alert_batch_run.app_sid%TYPE,
	in_csr_user_sid					IN	alert_batch_run.csr_user_sid%TYPE,
	in_std_alert_type_id			IN	std_alert_type.std_alert_type_id%TYPE
)
AS
	v_customer_alert_type_id	customer_alert_type.customer_alert_type_id%TYPE;
BEGIN
	-- this shouldn't be called when there's nothing in customer_alert_type, so 
	-- no need to trap NO_DATA_FOUND?
	SELECT customer_alert_type_id 
	  INTO v_customer_alert_type_id
	  FROM customer_alert_type 
	 WHERE std_alert_type_id = in_std_alert_type_id 
	   AND app_sid = in_app_sid;
	
	RecordUserBatchRun(v_customer_alert_type_id, in_csr_user_sid);
END;


PROCEDURE EndStdAlertBatchRun(
	in_std_alert_type_id			IN	std_alert_type.std_alert_type_id%TYPE
)
AS
BEGIN
	-- For all users that we didn't take any action for, we still need to record that we ran
	-- at the right time
	UPDATE alert_batch_run abr
	   SET prev_fire_time = next_fire_time,
	   	   next_fire_time = (SELECT next_fire_time_gmt
	   	   					   FROM v$alert_batch_run_time abrt
	   	   					  WHERE abr.app_sid = abrt.app_sid AND abr.csr_user_sid = abrt.csr_user_sid)
	 WHERE (customer_alert_type_id, app_sid, csr_user_sid)
	    IN (SELECT tabr.customer_alert_type_id, tabr.app_sid, tabr.csr_user_sid
	    	  FROM temp_alert_batch_run tabr				
	    	 WHERE std_alert_type_id = in_std_alert_type_id); 

	-- Clean up
	DELETE FROM temp_alert_batch_run 
	 WHERE std_alert_type_id = in_std_alert_type_id;
	
	-- we want to remember this
	COMMIT;
END;


PROCEDURE EndCustomerAlertBatchRun(
	in_customer_alert_type_id		IN	customer_alert_type.customer_alert_type_id%TYPE
)
AS
BEGIN
	-- For all users that we didn't take any action for, we still need to record that we ran
	-- at the right time
	UPDATE alert_batch_run abr
	   SET prev_fire_time = next_fire_time,
	   	   next_fire_time = (SELECT next_fire_time_gmt
	   	   					   FROM v$alert_batch_run_time abrt
	   	   					  WHERE abr.app_sid = abrt.app_sid AND abr.csr_user_sid = abrt.csr_user_sid)
	 WHERE (customer_alert_type_id, app_sid, csr_user_sid)
	    IN (SELECT customer_alert_type_id, app_sid, csr_user_sid
	    	  FROM temp_alert_batch_run 
	    	 WHERE customer_alert_type_id = in_customer_alert_type_id); 

	-- Clean up
	DELETE FROM temp_alert_batch_run 
	 WHERE customer_alert_type_id = in_customer_alert_type_id;
	
	-- we want to remember this
	COMMIT;
END;

PROCEDURE SetImages(
	in_image_ids					IN	security_pkg.T_SID_IDS,
	in_pass_keys					IN	security_pkg.T_VARCHAR2_ARRAY
)
AS
BEGIN
	FORALL i IN INDICES OF in_image_ids
		INSERT INTO alert_image
			(image_id, pass_key)
		VALUES
			(in_image_ids(i), in_pass_keys(i));
END;

PROCEDURE GetImage(
	in_pass_key						IN	alert_image.pass_key%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT i.data, i.mime_type
		  FROM cms.image i, alert_image ai
		 WHERE ai.pass_key = in_pass_key AND ai.image_id = i.image_id;
END;

-- no security as called from batch
PROCEDURE GetCmsAlertTypes(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT cat.app_sid, tab.oracle_schema, tab.oracle_table, cat.description, cat.customer_alert_type_id
		  FROM cms_alert_type cat
		  JOIN cms.tab ON cat.tab_sid = tab.tab_sid AND cat.app_sid = tab.app_sid
		  JOIN customer cus on cus.app_sid = tab.app_sid
		 WHERE cat.customer_alert_type_id IN (
			SELECT DISTINCT cfca.customer_alert_type_id
			  FROM cms_field_change_alert cfca
			 WHERE cfca.sent_dtm IS NULL
		 )
		   AND cus.scheduled_tasks_disabled = 0
		 ORDER BY cat.app_sid;
END;

-- no security as called from batch
PROCEDURE GetCmsFieldChangeAlerts(
	in_customer_alert_type_id		IN  cms_field_change_alert.customer_alert_type_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT cfca.cms_field_change_alert_id, cfca.user_sid, cfca.item_id, cfca.customer_alert_type_id, cfca.version_number
		  FROM cms_field_change_alert cfca
		  JOIN cms_alert_type cat ON cfca.customer_alert_type_id = cat.customer_alert_type_id AND cfca.app_sid = cat.app_sid
		  JOIN alert_template at ON at.customer_alert_type_id = cat.customer_alert_type_id
		 WHERE cfca.sent_dtm IS NULL
		   AND cfca.customer_alert_type_id = in_customer_alert_type_id
		   AND cat.is_batched = 0
		   AND cat.deleted = 0
		   AND cat.include_in_alert_setup = 1
		   AND at.send_type != 'inactive'
		 ORDER BY cfca.user_sid;
END;

-- no security as called from batch
PROCEDURE GetBatchedCmsFieldChangeAlerts(
	in_customer_alert_type_id		IN  cms_field_change_alert.customer_alert_type_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	alert_pkg.BeginCustomerAlertBatchRun(in_customer_alert_type_id);

	OPEN out_cur FOR
		SELECT /*+ALL_ROWS CARDINALITY(tabr, 1000)*/cfca.cms_field_change_alert_id, cfca.user_sid, cfca.item_id, cfca.customer_alert_type_id, 
			cfca.version_number
		  FROM cms_field_change_alert cfca
		  JOIN cms_alert_type cat ON cfca.customer_alert_type_id = cat.customer_alert_type_id AND cfca.app_sid = cat.app_sid
		  JOIN security.user_table ut ON cfca.user_sid = ut.sid_id
		  LEFT JOIN trash t on cfca.user_sid = t.trash_sid
		  JOIN temp_alert_batch_run tabr ON cfca.app_sid = tabr.app_sid 
				AND cfca.user_sid = tabr.csr_user_sid
				AND tabr.customer_alert_type_id = cfca.customer_alert_type_id 
		  JOIN alert_template at ON at.customer_alert_type_id = cat.customer_alert_type_id
		 WHERE cfca.sent_dtm IS NULL
		   AND cfca.customer_alert_type_id = in_customer_alert_type_id
		   AND cat.is_batched = 1
		   AND cat.deleted = 0
		   AND cat.include_in_alert_setup = 1
		   AND at.send_type != 'inactive'
		   AND ut.account_enabled = 1
		   AND t.trash_sid IS NULL 
		 ORDER BY cfca.user_sid, cfca.cms_field_change_alert_id;
END;

-- no security as can be called from batch
PROCEDURE MarkUnconfiguredCmsFieldChangeSent
AS
BEGIN
	UPDATE cms_field_change_alert cfca
	   SET cfca.sent_dtm = SYSDATE
	 WHERE cfca.sent_dtm IS NULL
	   AND customer_alert_type_id IN (
		SELECT cmsat.customer_alert_type_id
		  FROM cms_alert_type cmsat
		  JOIN alert_template at ON at.customer_alert_type_id = cmsat.customer_alert_type_id
		 WHERE cmsat.include_in_alert_setup = 1
		   AND at.send_type = 'inactive'
	   );
END;

-- no security as called from batch
PROCEDURE MarkBatchCmsFieldChangeSent(
	in_cms_field_change_alert_ids	IN  security_pkg.T_SID_IDS
)
AS
	t_alert_ids	security.T_SID_TABLE;
BEGIN
	t_alert_ids := security_pkg.SidArrayToTable(in_cms_field_change_alert_ids);

	UPDATE cms_field_change_alert
	   SET sent_dtm = SYSDATE
	 WHERE cms_field_change_alert_id IN (SELECT column_value FROM TABLE(t_alert_ids));
	
	COMMIT;
END;

-- no security as called from batch
PROCEDURE MarkCmsFieldChangeAlertSent(
	in_cms_field_change_alert_id	IN  cms_field_change_alert.cms_field_change_alert_id%TYPE
)
AS
BEGIN
	UPDATE cms_field_change_alert
	   SET sent_dtm = SYSDATE
	 WHERE cms_field_change_alert_id = in_cms_field_change_alert_id;
	 
	COMMIT;
END;

-- no security as called from batch
PROCEDURE GetCmsTabAlertTypes(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT ctat.app_sid, tab.oracle_schema, tab.oracle_table, tab.description, ctat.customer_alert_type_Id, ctat.has_repeats,
			ctat.filter_xml
		  FROM cms_tab_alert_type ctat
			JOIN cms.tab ON ctat.tab_sid = tab.tab_sid AND ctat.app_sid = tab.app_sid
			JOIN customer cus on ctat.app_sid = cus.app_sid
		   WHERE cus.scheduled_tasks_disabled = 0;
			
END;

PROCEDURE CopyTemplatesToDefault
AS
BEGIN
	IF csr_user_pkg.IsSuperAdmin = 0 AND NVL(SYS_CONTEXT('SECURITY', 'SID'),-1) <> security_pkg.SID_BUILTIN_ADMINISTRATOR THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You must be a superadmin user to copy alert templates to the defaults');
	END IF;

	DELETE FROM default_alert_template_body;
	DELETE FROM default_alert_template;
	DELETE FROM default_alert_frame_body;
	DELETE FROM default_alert_frame;	
	DELETE FROM temp_alert_frame;

	INSERT INTO temp_alert_frame (default_alert_frame_id, alert_frame_id)
		SELECT default_alert_frame_id_seq.NEXTVAL, alert_frame_id
		  FROM alert_frame
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	INSERT INTO default_alert_frame (default_alert_frame_id, name)
		SELECT taf.default_alert_frame_id, af.name
		  FROM temp_alert_frame taf, alert_frame af
		 WHERE af.alert_frame_id = taf.alert_frame_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	INSERT INTO default_alert_frame_body (default_alert_frame_id, lang, html)
		SELECT taf.default_alert_frame_id, afb.lang, afb.html
		  FROM temp_alert_frame taf, alert_frame_body afb
		 WHERE taf.alert_frame_id = afb.alert_frame_id
		   AND afb.app_sid = SYS_CONTEXT('SECURITY', 'APP');

	INSERT INTO default_alert_template (std_alert_type_id, default_alert_frame_id, send_type)
		SELECT cat.std_alert_type_id, taf.default_alert_frame_id, send_type
		  FROM alert_template at
		  JOIN temp_alert_frame taf ON at.alert_frame_id = taf.alert_frame_id
		  JOIN customer_alert_type cat on at.customer_alert_type_id = cat.customer_alert_type_id AND at.app_sid = cat.app_sid
		 WHERE at.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND cat.std_alert_type_id IS NOT NULL; -- just the generic ones

	INSERT INTO default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html)
		SELECT cat.std_alert_type_id, atb.lang, atb.subject, atb.body_html, atb.item_html
		  FROM alert_template_body atb
		  JOIN customer_alert_type cat on atb.customer_alert_type_id = cat.customer_alert_type_id AND atb.app_sid = cat.app_sid
		 WHERE atb.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND cat.std_alert_type_id IS NOT NULL; -- just the generic ones
END;

PROCEDURE SaveMessage(
	in_std_alert_type_id			IN	alert_mail.std_alert_type_id%TYPE,
	in_message						IN	alert_mail.message%TYPE
)
AS
BEGIN
	-- Check user has permission to send email (well, add contents on the app's outbox), as send will be done by built-in admin
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, alert_pkg.GetSystemMailbox('Outbox'), security_pkg.PERMISSION_ADD_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only administrators can save mail messages at the moment');
	END IF;
	
	INSERT INTO alert_mail (alert_mail_id, std_alert_type_id, message)
	VALUES (alert_mail_id_seq.NEXTVAL, in_std_alert_type_id, in_message);
END;

PROCEDURE DeleteMessage(
	in_alert_mail_id				IN	alert_mail.alert_mail_id%TYPE
)
AS
BEGIN
	-- These messages should only get deleted by the batch process sending them
		-- TO DO - given feeds access to this as using an "non-batch" feed - with the intention of moving it to be a feed later
	IF NOT ((security_pkg.IsAdmin(security_pkg.GetAct)) OR (security_pkg.IsAccessAllowedSID(security_pkg.GetAct, securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, security_pkg.GetApp, 'feeds'),  security_pkg.PERMISSION_WRITE))) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only administrators can delete messages');
	END IF;
	
	DELETE FROM alert_mail
	 WHERE alert_mail_id = in_alert_mail_id;
END;

PROCEDURE GetAppsWithMessages(
	in_std_alert_type_id			IN	alert_mail.std_alert_type_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- No security - batch job isn't logged in when it calls this
	OPEN out_cur FOR
		SELECT DISTINCT app_sid
		  FROM alert_mail
		 WHERE std_alert_type_id = in_std_alert_type_id;
END;

PROCEDURE GetMessages(
	in_std_alert_type_id			IN	alert_mail.std_alert_type_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- Only the batch process should call this
	-- TO DO - given feeds access to this as using an "non-batch" feed - with the intention of moving it to be a feed later
	IF NOT ((security_pkg.IsAdmin(security_pkg.GetAct)) OR (security_pkg.IsAccessAllowedSID(security_pkg.GetAct, securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, security_pkg.GetApp, 'feeds'),  security_pkg.PERMISSION_READ))) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only administrators can read messages');
	END IF;
	
	OPEN out_cur FOR
		SELECT alert_mail_id, message
		  FROM alert_mail
		 WHERE app_sid = security_pkg.GetApp
		   AND std_alert_type_id = in_std_alert_type_id;
END;

PROCEDURE RecordAlert(
	in_to_user_sid					IN	alert.to_user_sid%TYPE,
	in_to_email_address				IN	alert.to_email_address%TYPE,
	in_subject						IN	alert.subject%TYPE,
	in_message						IN	alert.message%TYPE,
	out_alert_id					OUT	alert.alert_id%TYPE
)
AS
BEGIN
	-- no security -- other permissions control alerts sending, and viewing this table
	-- is (by default) an admin only right
	INSERT INTO alert
		(alert_id, to_user_sid, to_email_address, subject, message)
	VALUES
		(user_pkg.rawact, in_to_user_sid, in_to_email_address, in_subject, in_message)
	RETURNING
		alert_id INTO out_alert_id;
END;

PROCEDURE RecordBounce(
	in_alert_id						IN	alert.alert_id%TYPE,
	in_message						IN	alert_bounce.message%TYPE
)
AS
	v_app_sid						alert.app_sid%TYPE;
BEGIN
	-- no security, only called from the mail server
	INSERT INTO alert_bounce (app_sid, alert_bounce_id, alert_id, message)
		SELECT a.app_sid, alert_bounce_id_seq.nextval, in_alert_id, in_message
		  FROM alert a
		 WHERE a.alert_id = in_alert_id;
END;

PROCEDURE CheckViewAlertBounces
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'ACT'), 'View alert bounces') THEN
		RAISE_APPLICATION_ERROR(-20001, 'Access denied on the "View alert bounces" capability');
	END IF;
END;

PROCEDURE GetBouncedAlerts(
	in_start_row					IN	NUMBER,
	in_page_size					IN	NUMBER,
	out_total						OUT	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	CheckViewAlertBounces;

	SELECT COUNT(*)
	  INTO out_total
	  FROM alert_bounce;
	  
	OPEN out_cur FOR
		SELECT *
		  FROM (SELECT a.*, rownum rn
		  	      FROM (SELECT a.alert_id, ab.alert_bounce_id, a.subject, a.to_user_sid, a.sent_dtm,
						       ab.received_dtm, cu.full_name,
							   NVL(cu.email, a.to_email_address) to_email_address,
							   ut.account_enabled to_user_active
						  FROM alert a
						  JOIN alert_bounce ab ON a.app_sid = ab.app_sid AND a.alert_id = ab.alert_id  
						  LEFT JOIN csr_user cu ON  a.app_sid = cu.app_sid AND a.to_user_sid = cu.csr_user_sid
						  LEFT JOIN security.user_table ut ON ut.sid_id = cu.csr_user_sid
						 ORDER BY ab.received_dtm DESC, ab.alert_bounce_id) a
				 WHERE rownum <= in_start_row + in_page_size)
		 WHERE rn > in_start_row;
		 				  
END;

PROCEDURE GetAllBouncedAlerts(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	CheckViewAlertBounces;
	  
	OPEN out_cur FOR
		SELECT a.alert_id, ab.alert_bounce_id, a.subject, a.to_user_sid, a.sent_dtm,
			   ab.received_dtm, cu.full_name,
			   NVL(cu.email, a.to_email_address) to_email_address,
			   ut.account_enabled to_user_active
		  FROM alert a
		  JOIN alert_bounce ab ON a.app_sid = ab.app_sid AND a.alert_id = ab.alert_id  
		  LEFT JOIN csr_user cu ON a.app_sid = cu.app_sid AND a.to_user_sid = cu.csr_user_sid
		  LEFT JOIN security.user_table ut ON ut.sid_id = cu.csr_user_sid
		 ORDER BY ab.received_dtm DESC, ab.alert_bounce_id;
		 				  
END;

PROCEDURE GetSentAlert(
	in_alert_id						IN	alert.alert_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	CheckViewAlertBounces;

	OPEN out_cur FOR
		SELECT a.alert_id, a.to_user_sid, a.to_email_address, a.sent_dtm, a.message
		  FROM alert a
		 WHERE a.alert_id = in_alert_id;
END;

PROCEDURE GetAlertBounce(
	in_alert_bounce_id				IN	alert_bounce.alert_bounce_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	CheckViewAlertBounces;

	OPEN out_cur FOR
		SELECT ab.alert_bounce_id, ab.alert_id, ab.received_dtm, ab.message
		  FROM alert_bounce ab
		 WHERE ab.alert_bounce_id = in_alert_bounce_id;
END;

PROCEDURE SetCmsAlertParams(
	in_tab_sid						IN  security.security_pkg.T_SID_ID,
	in_is_batched					IN	cms_alert_type.is_batched%TYPE,
	in_customer_alert_type_id		IN  csr.customer_alert_type.customer_alert_type_id%TYPE
)
AS
	v_pos			NUMBER(10) := 0;
	v_managed		NUMBER;
BEGIN
	DELETE FROM csr.customer_alert_type_param 
	 WHERE customer_alert_type_id = in_customer_alert_type_id;
	
	-- add the basic ones
	INSERT INTO CSR.customer_alert_type_param (customer_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (in_customer_alert_type_id, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
	INSERT INTO CSR.customer_alert_type_param (customer_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (in_customer_alert_type_id, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO CSR.customer_alert_type_param (customer_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (in_customer_alert_type_id, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
	INSERT INTO CSR.customer_alert_type_param (customer_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (in_customer_alert_type_id, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
	INSERT INTO CSR.customer_alert_type_param (customer_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (in_customer_alert_type_id, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
	
	v_pos := 6;
	
	SELECT managed
	  INTO v_managed
	  FROM cms.tab
	 WHERE tab_sid = in_tab_sid;
	
	
	FOR r IN (
		SELECT oracle_column, description
		  FROM cms.tab_column
		 WHERE tab_sid = in_tab_sid
		 ORDER BY pos
	) LOOP
		IF v_managed = 1 THEN
			INSERT INTO csr.customer_alert_type_param (customer_alert_type_id, field_name, description, help_text, repeats, display_pos)
				 VALUES (in_customer_alert_type_id, 'NEW_'||r.oracle_column, 'New '||NVL(r.description, r.oracle_column),'The new '||NVL(r.description, r.oracle_column) ||' value.', in_is_batched, v_pos);
			v_pos := v_pos +1;
				 
			INSERT INTO csr.customer_alert_type_param (customer_alert_type_id, field_name, description, help_text, repeats, display_pos)
				 VALUES (in_customer_alert_type_id, 'OLD_'||r.oracle_column, 'Old '||NVL(r.description, r.oracle_column),'The old '||NVL(r.description, r.oracle_column) ||' value.', in_is_batched, v_pos);
			v_pos := v_pos +1;
		ELSE
			INSERT INTO csr.customer_alert_type_param (customer_alert_type_id, field_name, description, help_text, repeats, display_pos)
				 VALUES (in_customer_alert_type_id, r.oracle_column, NVL(r.description, r.oracle_column),'The '||NVL(r.description, r.oracle_column) ||' value.', in_is_batched, v_pos);
			v_pos := v_pos +1;
		END IF;
	END LOOP;
END;

PROCEDURE SetCmsAlert (
	in_tab_sid						IN  security.security_pkg.T_SID_ID,
	in_lookup_key					IN  cms_alert_type.lookup_key%TYPE,
	in_description					IN  cms_alert_type.description%TYPE,
	in_subject						IN  alert_template_body.subject%TYPE,
	in_body_html					IN  alert_template_body.body_html%TYPE,
	in_is_batched					IN	cms_alert_type.is_batched%TYPE DEFAULT 0,
	out_customer_alert_type_id		OUT customer_alert_type.customer_alert_type_id%TYPE
)
AS
BEGIN
	BEGIN
		SELECT customer_alert_type_id
		  INTO out_customer_alert_type_id
		  FROM csr.cms_alert_type
		 WHERE lookup_key = in_lookup_key
		   AND tab_sid = in_tab_sid;
		 
		UPDATE csr.alert_template_body
		   SET subject = in_subject,
		       body_html = in_body_html
		 WHERE lang = 'en'
		   AND customer_alert_type_id = out_customer_alert_type_id;
		   
	EXCEPTION
		WHEN no_data_found THEN				
			INSERT INTO csr.customer_alert_type (customer_alert_type_id) 
				VALUES (csr.customer_alert_type_Id_seq.nextval) 
				RETURNING customer_alert_type_id INTO out_customer_alert_type_id;

			INSERT INTO csr.cms_alert_type(lookup_key, customer_alert_type_id, tab_sid, description, include_in_alert_setup, is_batched) 
			VALUES (in_lookup_key, out_customer_alert_type_id, in_tab_sid, in_description, 1, in_is_batched);

			INSERT INTO csr.alert_template (customer_alert_type_id, alert_frame_id, send_type, reply_to_name, reply_to_email)
				SELECT out_customer_alert_type_id, MIN(alert_frame_id), 'manual', null, null
				  FROM csr.alert_frame;

			INSERT INTO csr.alert_template_body (lang, subject, body_html, item_html, customer_alert_type_id)
				VALUES (
					'en', 
					in_subject,
					in_body_html,
					'<template></template>',
					out_customer_alert_type_id
			);
	END;
	
	SetCmsAlertParams(in_tab_sid, in_is_batched, out_customer_alert_type_id);
END;

PROCEDURE AddCmsFieldChangeAlert(
	in_lookup_key					IN  cms_alert_type.lookup_key%TYPE, 
	in_item_id						IN  cms_field_change_alert.item_id%TYPE, 	
	in_user_sid						IN  cms_field_change_alert.user_sid%TYPE, 
	in_version_number				IN  cms_field_change_alert.version_number%TYPE
)
AS
	v_customer_alert_type_id		csr.cms_alert_type.customer_alert_type_id%TYPE;
BEGIN
	SELECT customer_alert_type_id
	  INTO v_customer_alert_type_id
	  FROM csr.cms_alert_type
	 WHERE lookup_key = in_lookup_key;

	BEGIN
		INSERT INTO csr.cms_field_change_alert (cms_field_change_alert_id, item_id, customer_alert_type_id, user_sid, version_number)
	         VALUES (csr.cms_field_change_alert_id_seq.NEXTVAL, in_item_id, v_customer_alert_type_id, in_user_sid, in_version_number);
	EXCEPTION
		WHEN dup_val_on_index THEN
			-- alert already sent to this user for this record and this version. No need to send again
			NULL;
	END;
END;

FUNCTION GetCustomerAlertType(
	in_std_alert_type				IN	NUMBER
)
RETURN NUMBER
AS
	v_customer_alert_type			NUMBER;
BEGIN
	SELECT CUSTOMER_ALERT_TYPE_ID
	  INTO v_customer_alert_type
	  FROM customer_alert_type
	 WHERE std_alert_type_id = in_std_alert_type
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	RETURN v_customer_alert_type;
END;

FUNCTION IsAlertEnabled(
	in_std_alert_type				IN	std_alert_type.std_alert_type_id%TYPE,
	in_app_sid						IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP')
) RETURN BOOLEAN
AS
	v_alert_enabled					NUMBER;
BEGIN
	SELECT DECODE(COUNT(at.customer_alert_type_id), 0, 0, 1) INTO v_alert_enabled
	  FROM customer_alert_type cat
	  JOIN alert_template at ON cat.app_sid = at.app_sid AND cat.customer_alert_type_id = at.customer_alert_type_id
	 WHERE cat.std_alert_type_id = in_std_alert_type
	   AND at.send_type != 'inactive'
	   AND cat.app_sid = in_app_sid;

	RETURN v_alert_enabled = 1;
END;

FUNCTION SQL_IsAlertEnabled(
	in_std_alert_type				IN	std_alert_type.std_alert_type_id%TYPE,
	in_app_sid						IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP')
) RETURN NUMBER
AS
	v_alert_enabled					NUMBER;
BEGIN
	IF (IsAlertEnabled(in_std_alert_type, in_app_sid)) THEN
		RETURN 1;
	END IF;
	RETURN 0;
END;

FUNCTION GetAppSidsForAlert(
	in_std_alert_type				IN	std_alert_type.std_alert_type_id%TYPE
) RETURN security.T_SID_TABLE
AS
	v_app_sids						security_pkg.T_SID_IDS;
BEGIN
	SELECT app_sid 
	  BULK COLLECT INTO v_app_sids
	  FROM customer
	 WHERE ((SELECT alert_pkg.SQL_IsAlertEnabled(in_std_alert_type, app_sid) FROM DUAL) = 1);

	RETURN security_pkg.SidArrayToTable(v_app_sids);
END;

PROCEDURE GetAllAlertTemplates(
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT std_alert_type_id, send_type, reply_to_name, reply_to_email, subject,
			   body_html, item_html, lang, save_in_sent_alerts
		  FROM alert_template at
		  JOIN customer_alert_type cat ON at.customer_alert_type_id = cat.customer_alert_type_id
		  JOIN alert_template_body atb ON atb.customer_alert_type_id = at.customer_alert_type_id
		 WHERE std_alert_type_id is not null
		   AND at.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY std_alert_type_id;

END;

END Alert_Pkg;
/
