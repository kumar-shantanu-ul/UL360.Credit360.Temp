CREATE OR REPLACE PACKAGE BODY CHAIN.scheduled_alert_pkg
IS
/************************************************************************
	Private
************************************************************************/

/* This procedure removes entries that have not been sent from the alert_entry and scheduled_alert tables. This is needed to avoid duplicate or stale entries getting sent in alerts */
PROCEDURE CleanUpEntries
AS
	v_alert_entries_to_delete 	chain_pkg.T_NUMBERS;
BEGIN
	
	-- SELECT alert_entry_id
	  -- BULK COLLECT INTO v_alert_entries_to_delete
	  -- FROM chain.alert_entry
	 -- WHERE owner_scheduled_alert_id IS NULL
		-- OR owner_scheduled_alert_id IN (
									-- SELECT scheduled_alert_id
									  -- FROM chain.scheduled_alert
									 -- WHERE sent_dtm IS NULL )
		-- OR (owner_scheduled_alert_id IS NOT NULL AND ( 
									-- SELECT COUNT(*) 
									  -- FROM chain.scheduled_alert 
									 -- WHERE scheduled_alert_id = owner_scheduled_alert_id) 
									 -- = 0);
									 

									
	-- DELETE
	  -- FROM chain.scheduled_alert
	 -- WHERE sent_dtm IS NULL;
	 NULL;
END;


/************************************************************************
	Public
************************************************************************/

/* Misc. Chain jobs that need to be run regularly */
PROCEDURE RunChainJobs
AS
	v_act	security.security_pkg.T_ACT_ID;
BEGIN
	FOR R IN (
		SELECT c.app_sid
		  FROM csr.customer c 
		  JOIN customer_options co ON co.app_sid = c.app_sid
		 ORDER BY c.app_sid
	)
	LOOP
		security.user_pkg.logonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 600, r.app_sid, v_act);
		BEGIN
			helper_pkg.LogonUCD;

			invitation_pkg.UpdateExpirations;
			questionnaire_pkg.CheckForOverdueQuestionnaires;
			task_pkg.UpdateTasksForReview;
			
			helper_pkg.RevertLogonUCD;
			commit;
		EXCEPTION
			WHEN OTHERS THEN
			helper_pkg.RevertLogonUCD;
			
			aspen2.error_pkg.LogError('Error running RunChainJobs for app sid: '||r.app_sid||' ERR: '||SQLERRM||chr(10)||dbms_utility.format_error_backtrace);
		END;
		
		security.user_pkg.logoff(v_act);
	END LOOP;
END;

PROCEDURE GetAppAlertSettings (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT site_name, support_email alert_from_email, link_host
		  FROM customer_options
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetAlertEntryTemplates (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
) 
AS
BEGIN
	OPEN out_cur FOR
		SELECT app_sid, alert_entry_type_id, template_name, template
		  FROM v$alert_entry_template
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetAlertEntryTypes (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT app_sid, alert_entry_type_id, std_alert_type_id, description, important_section_template, company_section_template,
		       user_section_template, generator_sp, schedule_xml, enabled, force_disable
		  FROM v$alert_entry_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE SetTemplate(
	in_alert_entry_type		IN chain_pkg.T_ALERT_ENTRY_TYPE,
	in_template_name		IN alert_entry_template.template_name%TYPE,
	in_template				IN alert_entry_template.template%TYPE
)
AS
BEGIN

	INSERT INTO alert_entry_template(alert_entry_type_id, template_name, template)
		 VALUES (in_alert_entry_type, in_template_name, in_template);		
	
	EXCEPTION 
		WHEN DUP_VAL_ON_INDEX THEN
		
		UPDATE alert_entry_template
		   SET template = in_template
		 WHERE alert_entry_type_id = in_alert_entry_type
		   AND template_name = in_template_name;
END;

PROCEDURE SetCustomerTemplate(
	in_alert_entry_type		IN chain_pkg.T_ALERT_ENTRY_TYPE,
	in_template_name		IN alert_entry_template.template_name%TYPE,
	in_template				IN alert_entry_template.template%TYPE
)
AS
BEGIN

	INSERT INTO customer_alert_entry_template(app_sid, alert_entry_type_id, template_name, template)
		 VALUES (SYS_CONTEXT('SECURITY', 'APP'), in_alert_entry_type, in_template_name, in_template);		
	
	EXCEPTION 
		WHEN DUP_VAL_ON_INDEX THEN
		
		UPDATE customer_alert_entry_template
		   SET template = in_template
		 WHERE alert_entry_type_id = in_alert_entry_type
		   AND template_name = in_template_name
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GenerateRecipientTable
AS
BEGIN
	DELETE FROM TT_SCHED_ALERT_RECIP_LOOKUP;
	
	/* get the alert entry types and users we should be sending to */
	INSERT INTO TT_SCHED_ALERT_RECIP_LOOKUP(ID, SID)
		 SELECT uaet.alert_entry_type_id, uaet.user_sid
		   FROM chain.v$user_alert_entry_type uaet
		  WHERE uaet.enabled = 1
		    AND (uaet.next_alert_dtm IS NULL OR uaet.next_alert_dtm <= SYSDATE);
END;

PROCEDURE GenerateAlertEntries (
	in_alert_entry_type_id	IN  chain_pkg.T_ALERT_ENTRY_TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_generator_sp			chain.alert_entry_type.generator_sp%TYPE;
	v_recipient_count		NUMBER(10);
BEGIN

--	CleanUpEntries;

	SELECT generator_sp
	  INTO v_generator_sp
	  FROM chain.v$alert_entry_type
	 WHERE alert_entry_type_id = in_alert_entry_type_id
	   AND app_sid = SYS_CONTEXT('SECURITY','APP');

	/* join with csr.temp_alert_batch_run and remove users that aren't supposed to receive their alerts yet */
	DELETE FROM TT_SCHED_ALERT_RECIP_LOOKUP
	  WHERE id = in_alert_entry_type_id
	    AND sid NOT IN ( SELECT csr_user_sid
						   FROM csr.temp_alert_batch_run
						  WHERE this_fire_time_gmt <= CURRENT_TIMESTAMP );
	
	BEGIN 	
		SELECT COUNT(sid)
		  INTO v_recipient_count
		  FROM chain.TT_SCHED_ALERT_RECIP_LOOKUP
		 GROUP BY id;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_recipient_count := 0;
	END; 
	
	/* run the generating SPs.entries; only entries for users in TT_SCHED_ALERT_RECIP_LOOKUP will be added */	
	IF v_recipient_count > 0 THEN
		EXECUTE IMMEDIATE 'begin '||v_generator_sp||'; end;';
	END IF;
	
	/* return the recipients, filtering out those that have no new entries */
	OPEN out_cur FOR
		SELECT sids.id alert_entry_type_id, sids.sid user_sid, cu.email, cu.friendly_name, cu.full_name
		  FROM chain.TT_SCHED_ALERT_RECIP_LOOKUP sids
		  JOIN chain.v$chain_user cu
			ON cu.user_sid = sids.sid
		 WHERE (
				SELECT COUNT(*) 
				  FROM chain.alert_entry 
				 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
				   AND alert_entry_type_id = sids.id
				   AND user_sid = sids.sid
				   AND owner_scheduled_alert_id IS NULL) > 0
		   AND sids.id = in_alert_entry_type_id;	
END;

PROCEDURE GetAlertSchedules (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT app_sid, scheduled_alert_intvl_minutes
		  FROM customer_options;
END;

FUNCTION SetAlertEntry(
	in_alert_entry_type		IN  chain_pkg.T_ALERT_ENTRY_TYPE,
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_template_name		IN  alert_entry.template_name%TYPE,	
	in_occurred_dtm			IN  alert_entry.occurred_dtm%TYPE,
	in_priority				IN	alert_entry.priority%TYPE DEFAULT 0,
	in_company_sid			IN  security_pkg.T_SID_ID DEFAULT NULL,
	in_message_id			IN  chain.message.message_id%TYPE DEFAULT NULL
) RETURN alert_entry.alert_entry_id%TYPE
AS
	v_alert_entry_id		alert_entry.alert_entry_id%TYPE;
	v_count 				NUMERIC(10);
BEGIN

	/* skip any entries for users that aren't supposed to receive alerts at this time */
	SELECT COUNT(*) INTO v_count FROM TT_SCHED_ALERT_RECIP_LOOKUP WHERE id = in_alert_entry_type AND sid = in_user_sid;
	IF v_count = 0 THEN
		RETURN NULL;
	END IF;

	INSERT INTO alert_entry
	(alert_entry_id, alert_entry_type_id, user_sid, occurred_dtm, template_name, priority, company_sid, message_id)
	VALUES
	(alert_entry_id_seq.nextval, in_alert_entry_type, in_user_sid, in_occurred_dtm, in_template_name, in_priority, in_company_sid, in_message_id)
	RETURNING alert_entry_id INTO v_alert_entry_id;		
	
	RETURN v_alert_entry_id;
END;

PROCEDURE SetAlertParam(
	in_alert_entry_id		IN	alert_entry.alert_entry_id%TYPE,
	in_name					IN	alert_entry_param.name%TYPE,
	in_value				IN	alert_entry_param.value%TYPE
)
AS
	v_count 				NUMERIC(10);
BEGIN
	IF in_alert_entry_id IS NULL THEN
		RETURN;
	END IF;

	SELECT COUNT(*) INTO v_count FROM alert_entry WHERE alert_entry_id = in_alert_entry_id;
	IF v_count = 0 THEN
		RETURN;
	END IF;

	INSERT INTO alert_entry_param(app_sid, alert_entry_id, name, value)
		 VALUES (SYS_CONTEXT('SECURITY', 'APP'), in_alert_entry_id, in_name, in_value);		
	
	EXCEPTION 
		WHEN DUP_VAL_ON_INDEX THEN
		
		UPDATE alert_entry_param
		   SET value = in_value 
		 WHERE alert_entry_id = in_alert_entry_id
		   AND name = in_name
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetOutstandingAlertRecipients (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN 
	 OPEN out_cur FOR
		SELECT uaet.alert_entry_type_id, uaet.user_sid, uaet.email, uaet.friendly_name
		  FROM chain.v$user_alert_entry_type uaet
		 WHERE uaet.enabled = 1
		   AND (uaet.next_alert_dtm IS NULL OR uaet.next_alert_dtm <= SYSDATE)
		   AND (
				SELECT COUNT(*) 
				  FROM chain.alert_entry 
				 WHERE app_sid = uaet.app_sid 
				   AND alert_entry_type_id = uaet.alert_entry_type_id 
				   AND user_sid = uaet.user_sid 
				   AND owner_scheduled_alert_id IS NULL) > 0;
END;

PROCEDURE MarkAlertSent (
	in_scheduled_alert_id	IN chain.scheduled_alert.scheduled_alert_id%TYPE
)
AS
BEGIN
	UPDATE scheduled_alert
	   SET sent_dtm = current_timestamp
	 WHERE scheduled_alert_id = in_scheduled_alert_id;
END;

PROCEDURE SendingScheduledAlertTo (
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_alert_entry_type_id	IN	chain.alert_entry_type.alert_entry_type_id%TYPE,
	out_scheduled_alert_id	OUT chain.scheduled_alert.scheduled_alert_id%TYPE,
	out_entries_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_params_cur			OUT security_pkg.T_OUTPUT_CUR
) 
AS
	v_sa_id					scheduled_alert.scheduled_alert_id%TYPE;
BEGIN

	INSERT INTO scheduled_alert
	(app_sid, user_sid, alert_entry_type_id, scheduled_alert_id)
	VALUES
	(SYS_CONTEXT('SECURITY','APP'), in_user_sid, in_alert_entry_type_id, scheduled_alert_id_seq.nextval)
	RETURNING scheduled_alert_id INTO v_sa_id;

	UPDATE alert_entry
	   SET owner_scheduled_alert_id = v_sa_id
	 WHERE app_sid =  SYS_CONTEXT('SECURITY', 'APP')
	   AND alert_entry_type_id = in_alert_entry_type_id
	   AND user_sid = in_user_sid
	   AND owner_scheduled_alert_id IS NULL;

	OPEN out_entries_cur FOR
		SELECT ae.*, c.name company_name
		  FROM alert_entry ae
	 LEFT JOIN company c
			ON ae.app_sid = c.app_sid
		   AND ae.company_sid = c.company_sid
		 WHERE ae.app_sid =  SYS_CONTEXT('SECURITY', 'APP')
		   AND ae.owner_scheduled_alert_id = v_sa_id;

	OPEN out_params_cur FOR
		SELECT app_sid, alert_entry_id, name, value
		  FROM alert_entry_param
		 WHERE (app_sid, alert_entry_id) IN
			   (
				SELECT app_sid, alert_entry_id
				  FROM alert_entry
				 WHERE app_sid =  SYS_CONTEXT('SECURITY', 'APP')
				   AND owner_scheduled_alert_id = v_sa_id
			   );
	
	out_scheduled_alert_id := v_sa_id;
END;


PROCEDURE UpdateUserSettings (
	in_alert_entry_type_id	IN	chain.alert_entry_type.alert_entry_type_id%TYPE,
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_enabled				IN  chain.user_alert_entry_type.enabled%TYPE DEFAULT NULL,
	in_schedule_xml			IN	chain.user_alert_entry_type.schedule_xml%TYPE DEFAULT NULL
)
AS
BEGIN
	INSERT INTO user_alert_entry_type(app_sid, alert_entry_type_id, user_sid, enabled, schedule_xml)
		 VALUES (SYS_CONTEXT('SECURITY', 'APP'), in_alert_entry_type_id, in_user_sid, in_enabled, in_schedule_xml);		
	
	EXCEPTION 
		WHEN DUP_VAL_ON_INDEX THEN
		
		UPDATE user_alert_entry_type
		   SET enabled = in_enabled,
			   schedule_xml = in_schedule_xml
		 WHERE alert_entry_type_id = in_alert_entry_type_id
		   AND user_sid = in_user_sid
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;


PROCEDURE UpdateClientSettings (
	in_alert_entry_type_id					IN	chain.alert_entry_type.alert_entry_type_id%TYPE,
	in_enabled								IN  chain.customer_alert_entry_type.enabled%TYPE DEFAULT NULL,
	in_schedule_xml							IN	chain.customer_alert_entry_type.schedule_xml%TYPE DEFAULT NULL,
	in_important_section_template			IN	chain.customer_alert_entry_type.important_section_template%TYPE DEFAULT NULL,
	in_company_section_template				IN	chain.customer_alert_entry_type.company_section_template%TYPE DEFAULT NULL,
	in_user_section_template				IN	chain.customer_alert_entry_type.user_section_template%TYPE DEFAULT NULL,
	in_generator_sp							IN	chain.customer_alert_entry_type.generator_sp%TYPE DEFAULT NULL,
	in_force_disable						IN 	chain.customer_alert_entry_type.force_disable%TYPE DEFAULT NULL
)
AS
BEGIN
	INSERT INTO customer_alert_entry_type(app_sid, alert_entry_type_id, company_section_template, user_section_template, important_section_template, generator_sp, schedule_xml, enabled, force_disable)
		 VALUES (SYS_CONTEXT('SECURITY', 'APP'), in_alert_entry_type_id, in_company_section_template, in_user_section_template, in_important_section_template, in_generator_sp, in_schedule_xml, in_enabled, in_force_disable);		
	
	EXCEPTION 
		WHEN DUP_VAL_ON_INDEX THEN
		
		UPDATE customer_alert_entry_type
		   SET enabled = in_enabled,
			   schedule_xml = in_schedule_xml,
			   important_section_template = in_important_section_template,
			   company_section_template = in_company_section_template,
			   user_section_template = in_user_section_template,
			   generator_sp = in_generator_sp,
			   force_disable = in_force_disable
		 WHERE alert_entry_type_id = in_alert_entry_type_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

/*****************************************************************************/

PROCEDURE CreateReviewAlert (
	in_to_company_sid			IN	security_pkg.T_SID_ID,
	in_from_company_sid			IN	security_pkg.T_SID_ID
)
AS
BEGIN
	FOR chk IN (
		SELECT * FROM dual WHERE EXISTS (
			SELECT * FROM review_alert
			 WHERE from_company_sid = in_from_company_sid
			   AND to_company_sid = in_to_company_sid
			   AND sent_dtm IS NULL
		)
	) LOOP
		-- If an unsent alert exists already, ignore
		RETURN;
	END LOOP;
	
	INSERT INTO review_alert (review_alert_id, from_company_sid, from_user_sid, to_company_sid, to_user_sid)
	SELECT review_alert_id_seq.NEXTVAL, in_from_company_sid, sf.user_sid, in_to_company_sid, cm.user_sid
	  FROM v$company_member cm
	  JOIN supplier_follower sf ON cm.company_sid = sf.supplier_company_sid
	 WHERE cm.company_sid = in_to_company_sid
	   AND sf.purchaser_company_sid = in_from_company_sid
	   AND sf.is_primary = 1;
END;

PROCEDURE GetReviewAlerts (
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT ra.app_sid, ra.review_alert_id, ra.from_company_sid, ra.from_user_sid,
			   ra.to_company_sid, ra.to_user_sid, tc.name to_company_name,
			   fc.name from_company_name, fu.job_title from_job_title
		  FROM review_alert ra
		  JOIN company tc ON ra.to_company_sid = tc.company_sid AND ra.app_sid = tc.app_sid
		  JOIN company fc ON ra.from_company_sid = fc.company_sid AND ra.app_sid = fc.app_sid
		  JOIN csr.csr_user fu ON ra.from_user_sid = fu.csr_user_sid AND ra.app_sid = fu.app_sid
		 WHERE sent_dtm IS NULL
		 ORDER BY ra.app_sid, ra.review_alert_id;
END;

PROCEDURE MarkReviewAlertSent (
	in_review_alert_id			IN	review_alert.review_alert_id%TYPE
)
AS
BEGIN
	UPDATE review_alert
	   SET sent_dtm = SYSDATE
	 WHERE review_alert_id = in_review_alert_id;
	
	COMMIT;
END;

/*****************************************************************************/

PROCEDURE CreateProductCompanyAlert (
	in_company_product_id		IN	security_pkg.T_SID_ID,
	in_purchaser_company_sid	IN	security_pkg.T_SID_ID,
	in_supplier_company_sid		IN	security_pkg.T_SID_ID
)
AS
BEGIN
	FOR chk IN (
		SELECT * FROM dual WHERE EXISTS (
			SELECT * FROM product_company_alert
			 WHERE company_product_id = in_company_product_id
			   AND purchaser_company_sid = in_purchaser_company_sid
			   AND supplier_company_sid = in_supplier_company_sid
			   AND sent_dtm IS NULL
		)
	) LOOP
		-- If an unsent alert exists already, ignore
		RETURN;
	END LOOP;
	
	INSERT INTO product_company_alert (alert_id, company_product_id, purchaser_company_sid, supplier_company_sid, user_sid)
	SELECT product_company_alert_id_seq.NEXTVAL, in_company_product_id, in_purchaser_company_sid, in_supplier_company_sid, sf.user_sid
	  FROM v$company_product cp
	  JOIN supplier_follower sf ON in_supplier_company_sid = sf.supplier_company_sid
	 WHERE cp.product_id = in_company_product_id;
END;

PROCEDURE GetProductCompanyAlerts (
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT a.app_sid, a.alert_id, a.purchaser_company_sid, a.supplier_company_sid, a.user_sid,
			   cp.product_id, cp.product_name,
			   pc.name purchaser_company_name,
			   sc.name supplier_company_name,
			   au.email, au.friendly_name, au.full_name
		  FROM product_company_alert a
		  JOIN v$company_product cp ON a.company_product_id = cp.product_id AND a.app_sid = cp.app_sid
		  JOIN company pc ON a.purchaser_company_sid = pc.company_sid AND a.app_sid = pc.app_sid AND pc.deleted = 0
		  JOIN company sc ON a.supplier_company_sid = sc.company_sid AND a.app_sid = sc.app_sid AND sc.deleted = 0
		  JOIN product_supplier ps ON a.company_product_id = ps.product_id AND a.supplier_company_sid = ps.supplier_company_sid AND a.app_sid = ps.app_sid
		  JOIN csr.csr_user au ON a.user_sid = au.csr_user_sid AND a.app_sid = au.app_sid
		 WHERE sent_dtm IS NULL
		 ORDER BY a.app_sid, a.alert_id;
END;

PROCEDURE MarkProductCompanyAlertSent (
	in_alert_id			IN	product_company_alert.alert_id%TYPE
)
AS
BEGIN
	UPDATE product_company_alert
	   SET sent_dtm = SYSDATE
	 WHERE alert_id = in_alert_id;
	
	COMMIT;
END;

END scheduled_alert_pkg;
/

