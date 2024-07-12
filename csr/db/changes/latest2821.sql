-- Please update version.sql too -- this keeps clean builds in sync
define version=2821
define minor_version=0
define is_combined=1
@update_header

CREATE OR REPLACE PACKAGE CSR.csr_app_pkg AS

-- Securable object callbacks
PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
);

PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
);

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
);

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID
);

PROCEDURE DeleteApp(
	in_reduce_contention			IN	NUMBER	DEFAULT 0
);

/**
 * Add a translation for the given application
 *
 * @param in_application_sid	The application to add the translation for
 * @param in_lang_id			The lang id of the language to add a translation for
 */
PROCEDURE AddApplicationTranslation(
	in_application_sid		IN	customer.app_sid%TYPE,
	in_lang_id				IN	aspen2.lang.lang_id%TYPE
);

PROCEDURE CreateApp(
	in_app_name						IN	customer.host%TYPE,
	in_styles_path					IN	VARCHAR2,
	in_start_month					IN	customer.start_month%TYPE,
	out_app_sid						OUT	customer.app_sid%TYPE
);

PROCEDURE GetDetails(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetDetailsForASP(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE AmendDetails(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_app_sid					IN	security_pkg.T_SID_ID,
	in_name						IN	customer.name%TYPE,
	in_contact_email			IN	customer.contact_email%TYPE,	
	in_raise_reminders			IN	customer.raise_reminders%TYPE,		
	in_ind_info_xml_fields		IN	customer.ind_info_xml_fields%TYPE,		
	in_region_info_xml_fields	IN	customer.region_info_xml_fields%TYPE,		
	in_user_info_xml_fields 	IN	customer.user_info_xml_fields%TYPE
);

PROCEDURE GetMessage(
	out_cur						OUT	SYS_REFCURSOR
);

/**
 * Return the application sid for the given host
 * NOTE: No security, use only in batch applications or command line tools
 *
 * @param in_host				The host
 * @param out_app_sid			The application sid
 */
PROCEDURE GetAppSid(
	in_host							IN	customer.host%TYPE,
	out_app_sid						OUT	customer.app_sid%TYPE
);

/**
 * Return the version number of the database
 * NOTE: No security. For use by the REST API, needs to work even for guests.
 *
 * @param in_act_id				The access topen
 * @param out_db_version		The DB version
 */
PROCEDURE GetDBVersion(
	out_db_version				OUT	version.db_version%TYPE
);

/**
 * Check language settings of the site. 
 * It corrects it if necessary.
 * 
 * @param in_act_id				The access token.
 */
PROCEDURE EnsureAppLanguageIsValid(
	in_act_id				IN	security_pkg.T_ACT_ID
);

/**
 * Check language settings of the site and users.
 * It corrects them if necessary.
 * 
 * @param in_act_id				The access token.
 */

PROCEDURE EnsureLanguagesAreValid(
	in_act_id				IN	security_pkg.T_ACT_ID
);

END;
/

CREATE OR REPLACE PACKAGE BODY CSR.csr_app_pkg AS

-- Securable object callbacks
PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
)
AS
	v_class_id				security_pkg.T_CLASS_ID;
BEGIN
	v_class_id := class_pkg.getclassid('CSRUserGroup');
	aspen2.aspenapp_pkg.CreateObjectSpecificClasses(in_act_id, in_sid_id, in_class_id, in_name, in_parent_sid_id, v_class_id);	
END;

PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
) AS
BEGIN
	aspen2.aspenapp_pkg.RenameObject(in_act_id, in_sid_id, in_new_name);
END;

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
) AS
BEGIN
	aspen2.aspenapp_pkg.DeleteObject(in_act_id, in_sid_id);
END;

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID
) AS   
BEGIN
	aspen2.aspenapp_pkg.MoveObject(in_act_id, in_sid_id, in_new_parent_sid_id);
END;

PROCEDURE DeleteApp(
	in_reduce_contention			IN	NUMBER	DEFAULT 0
)
AS
	v_app_sid						security_pkg.T_SID_ID;
	v_act_id						security_pkg.T_ACT_ID;
	v_system_mail_address			VARCHAR2(1000);
	v_tracker_mail_address			VARCHAR2(1000);
	v_account_sid					security_pkg.T_SID_ID;
	v_trash_sid						security_pkg.T_SID_ID;
BEGIN
	NULL;
END;

PROCEDURE AddCalendarMonthPeriodSet
AS
BEGIN
	INSERT INTO period_set (period_set_id, annual_periods, label)
	VALUES (1, 1, 'Calendar months');
	
	INSERT INTO period (period_set_id, period_id, label, start_dtm, end_dtm)
	VALUES (1, 1, 'Jan', date '1900-01-01', date '1900-02-01');
	INSERT INTO period (period_set_id, period_id, label, start_dtm, end_dtm)
	VALUES (1, 2, 'Feb', date '1900-02-01', date '1900-03-01');
	INSERT INTO period (period_set_id, period_id, label, start_dtm, end_dtm)
	VALUES (1, 3, 'Mar', date '1900-03-01', date '1900-04-01');
	INSERT INTO period (period_set_id, period_id, label, start_dtm, end_dtm)
	VALUES (1, 4, 'Apr', date '1900-04-01', date '1900-05-01');
	INSERT INTO period (period_set_id, period_id, label, start_dtm, end_dtm)
	VALUES (1, 5, 'May', date '1900-05-01', date '1900-06-01');
	INSERT INTO period (period_set_id, period_id, label, start_dtm, end_dtm)
	VALUES (1, 6, 'Jun', date '1900-06-01', date '1900-07-01');
	INSERT INTO period (period_set_id, period_id, label, start_dtm, end_dtm)
	VALUES (1, 7, 'Jul', date '1900-07-01', date '1900-08-01');
	INSERT INTO period (period_set_id, period_id, label, start_dtm, end_dtm)
	VALUES (1, 8, 'Aug', date '1900-08-01', date '1900-09-01');
	INSERT INTO period (period_set_id, period_id, label, start_dtm, end_dtm)
	VALUES (1, 9, 'Sep', date '1900-09-01', date '1900-10-01');
	INSERT INTO period (period_set_id, period_id, label, start_dtm, end_dtm)
	VALUES (1, 10, 'Oct', date '1900-10-01', date '1900-11-01');
	INSERT INTO period (period_set_id, period_id, label, start_dtm, end_dtm)
	VALUES (1, 11, 'Nov', date '1900-11-01', date '1900-12-01');
	INSERT INTO period (period_set_id, period_id, label, start_dtm, end_dtm)
	VALUES (1, 12, 'Dec', date '1900-12-01', date '1901-01-01');
	
	-- months
	INSERT INTO period_interval (period_set_id, period_interval_id, single_interval_label, multiple_interval_label, label, single_interval_no_year_label)
	VALUES (1, 1, '{0:PL} {0:YYYY}', '{0:PL} {0:YYYY} - {1:PL} {1:YYYY}', 'Monthly', '{0:PL}');
	INSERT INTO period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (1, 1, 1, 1);
	INSERT INTO period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (1, 1, 2, 2);
	INSERT INTO period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (1, 1, 3, 3);
	INSERT INTO period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (1, 1, 4, 4);
	INSERT INTO period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (1, 1, 5, 5);
	INSERT INTO period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (1, 1, 6, 6);
	INSERT INTO period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (1, 1, 7, 7);
	INSERT INTO period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (1, 1, 8, 8);
	INSERT INTO period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (1, 1, 9, 9);
	INSERT INTO period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (1, 1, 10, 10);
	INSERT INTO period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (1, 1, 11, 11);
	INSERT INTO period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (1, 1, 12, 12);
		
	-- quarters
	INSERT INTO period_interval (period_set_id, period_interval_id, single_interval_label, multiple_interval_label, label, single_interval_no_year_label)
	VALUES (1, 2, 'Q{0:I} {0:YYYY}', 'Q{0:I} {0:YYYY} - Q{1:I} {1:YYYY}', 'Quarterly', 'Q{0:I}');
	INSERT INTO period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (1, 2, 1, 3);
	INSERT INTO period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (1, 2, 4, 6);
	INSERT INTO period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (1, 2, 7, 9);
	INSERT INTO period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (1, 2, 10, 12);
	
	-- halves
	INSERT INTO period_interval (period_set_id, period_interval_id, single_interval_label, multiple_interval_label, label, single_interval_no_year_label)
	VALUES (1, 3, 'H{0:I} {0:YYYY}', 'H{0:I} {0:YYYY} - H{1:I} {1:YYYY}', 'Half-yearly', 'H{0:I}');
	INSERT INTO period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (1, 3, 1, 6);
	INSERT INTO period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (1, 3, 7, 12);

	-- years
	INSERT INTO period_interval (period_set_id, period_interval_id, single_interval_label, multiple_interval_label, label, single_interval_no_year_label)
	VALUES (1, 4, '{0:YYYY}', '{0:YYYY} - {1:YYYY}', 'Annually', 'Year');
	INSERT INTO period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (1, 4, 1, 12);
END;

PROCEDURE AddStandardFramesAndTemplates
AS
BEGIN
	-- get languages that are configured for the site		  
	INSERT INTO temp_lang (lang)
		SELECT lang
		  FROM aspen2.translation_set
		 WHERE application_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND hidden = 0;

	-- add in the default frames
	INSERT INTO temp_alert_frame (default_alert_frame_id, alert_frame_id)
		SELECT daf.default_alert_frame_id, alert_frame_id_seq.NEXTVAL
		  FROM default_alert_frame daf, (
		  		SELECT DISTINCT default_alert_frame_id
		  		  FROM default_alert_frame_body
		  		 WHERE lang IN (SELECT lang FROM temp_lang)) dafb
		 WHERE daf.default_alert_frame_id = dafb.default_alert_frame_id;

	INSERT INTO alert_frame (alert_frame_id, name)
		SELECT taf.alert_frame_id, daf.name
		  FROM default_alert_frame daf, temp_alert_frame taf
		 WHERE daf.default_alert_frame_id = taf.default_alert_frame_id;

	INSERT INTO alert_frame_body (alert_frame_id, lang, html)
		SELECT taf.alert_frame_id, dafb.lang, dafb.html
		  FROM default_alert_frame_body dafb, temp_alert_frame taf
		 WHERE dafb.default_alert_frame_id = taf.default_alert_frame_id 
		   AND dafb.lang IN (SELECT lang FROM temp_lang);

	-- and the default templates
	INSERT INTO alert_template (customer_alert_type_id, alert_frame_id, send_type)
		SELECT cat.customer_alert_type_id, taf.alert_frame_id, 'manual' send_type
		  FROM default_alert_template dat, customer_alert_type cat, temp_alert_frame taf
		 WHERE cat.std_alert_type_id = dat.std_alert_type_id AND dat.default_alert_frame_id = taf.default_alert_frame_id
		   AND cat.app_sid = SYS_CONTEXT('SECURITY', 'APP');

	INSERT INTO alert_template_body (customer_alert_type_id, lang, subject, body_html, item_html)
		SELECT cat.customer_alert_type_id, datb.lang, datb.subject, datb.body_html, datb.item_html
		  FROM default_alert_template_body datb, customer_alert_type cat
		 WHERE cat.std_alert_type_id = datb.std_alert_type_id 
		   AND datb.lang IN (SELECT lang FROM temp_lang)
		   AND cat.app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE AddApplicationTranslation(
	in_application_sid		IN	customer.app_sid%TYPE,
	in_lang_id				IN	aspen2.lang.lang_id%TYPE
)
AS
	v_lang						aspen2.lang.lang%TYPE;
	v_alert_frame_id			alert_frame.alert_frame_id%TYPE;
	v_default_alert_frame_id	default_alert_frame.default_alert_frame_id%TYPE;
BEGIN
	aspen2.tr_pkg.AddApplicationTranslation(in_application_sid, in_lang_id);

	SELECT lang
	  INTO v_lang
	  FROM aspen2.lang
	 WHERE lang_id = in_lang_id;

	-- try and find a frame to add translations for.  if we've got no frames (weird user but possible), just add all defaults.
	BEGIN
		SELECT alert_frame_id
		  INTO v_alert_frame_id
		  FROM (SELECT alert_frame_id, rownum rn
		  		  FROM (SELECT alert_frame_id
		  				  FROM alert_frame
		 				 WHERE app_sid = in_application_sid
		 				 ORDER BY DECODE(name, 'Default', 0, 1)))
		 WHERE rn = 1;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- There are no frames, or templates, so just add the lot
			AddStandardFramesAndTemplates;
			RETURN;
	END;
		
	BEGIN
		-- try and find a default frame to copy translations from
		SELECT MIN(default_alert_frame_id)
		  INTO v_default_alert_frame_id
		  FROM default_alert_frame;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- There are no default frames, so quit
			RETURN;
	END;

	-- got a frame, add in missing translations for it
	INSERT INTO alert_frame_body (alert_frame_id, lang, html)
		SELECT v_alert_frame_id, lang, html
		  FROM default_alert_frame_body
		 WHERE default_alert_frame_id = v_default_alert_frame_id
		   AND lang = v_lang
		   AND lang NOT IN (SELECT lang
		   				 	  FROM alert_frame_body
		   				 	 WHERE alert_frame_id = v_alert_frame_id AND lang = v_lang);

	-- next add any missing templates that we have default config for in the given language
	INSERT INTO alert_template (app_sid, customer_alert_type_id, alert_frame_id, send_type)
		SELECT in_application_sid, cat.customer_alert_type_id, v_alert_frame_id, 'manual' -- always make new alerts manual send
		  FROM default_alert_template dat
			JOIN customer_alert_type cat ON dat.std_alert_type_id = cat.std_alert_type_id AND cat.app_sid = in_application_sid
		 WHERE dat.default_alert_frame_id = v_default_alert_frame_id
		   AND customer_alert_type_id NOT IN (SELECT customer_alert_type_id 
											     FROM alert_template 
												WHERE app_sid = in_application_sid)
		   AND customer_alert_type_id IN (SELECT customer_alert_type_id
										     FROM customer_alert_type
										    WHERE app_sid = in_application_sid);
		   							  
	-- and finally any missing bodies
	INSERT INTO alert_template_body (app_sid, customer_alert_type_id, lang, subject, body_html, item_html)
		SELECT in_application_sid, cat.customer_alert_type_id, datb.lang, datb.subject, datb.body_html, datb.item_html
		  FROM default_alert_template_body datb
			JOIN customer_alert_type cat ON datb.std_alert_type_id = cat.std_alert_type_id AND cat.app_sid = in_application_sid
		 WHERE datb.std_alert_type_id IN (SELECT std_alert_type_id
		 								     FROM default_alert_template
		 							        WHERE default_alert_frame_id = v_default_alert_frame_id)
		   AND (customer_alert_type_id, lang) NOT IN (SELECT customer_alert_type_id, lang
		   									              FROM alert_template_body
		   									             WHERE app_sid = in_application_sid)
		   AND customer_alert_type_id IN (SELECT customer_alert_type_id
								             FROM customer_alert_type
								            WHERE app_sid = in_application_sid)
		   AND lang = v_lang;

	-- add descriptions for inds/regions in the new language
	INSERT INTO ind_description (ind_sid, lang, description)
		SELECT ind_sid, lang, description
		  FROM (SELECT id.ind_sid, cl.lang, id.description
				  FROM v$customer_lang cl, ind_description id
				 WHERE id.lang = 'en'
				   AND NOT EXISTS (SELECT NULL 
									 FROM ind_description 
									WHERE ind_sid = id.ind_sid 
									  AND lang = cl.lang)
            );

	INSERT INTO region_description (region_sid, lang, description)
		SELECT region_sid, lang, description
		  FROM (SELECT rd.region_sid, cl.lang, rd.description
				  FROM v$customer_lang cl, region_description rd
				 WHERE rd.lang = 'en'
				   AND NOT EXISTS (SELECT NULL 
									 FROM region_description 
									WHERE region_sid = rd.region_sid 
									  AND lang = cl.lang)
            );
END;

PROCEDURE CreateApp(
	in_app_name						IN	customer.host%TYPE,
	in_styles_path					IN	VARCHAR2,
	in_start_month					IN	customer.start_month%TYPE,
	out_app_sid						OUT	customer.app_sid%TYPE
)
AS
	-- sids we create
	v_region_root_sid_id		security_pkg.T_SID_ID;
	v_ind_root_sid_id			security_pkg.T_SID_ID;
	v_new_sid_id				security_pkg.T_SID_ID;
	v_pending_sid_id			security_pkg.T_SID_ID;
	v_trash_sid_id				security_pkg.T_SID_ID;
	v_policy_sid				security_pkg.T_SID_ID;
	-- groups
	v_admins					security_pkg.T_SID_ID;
	v_reg_users					security_pkg.T_SID_ID;
	v_super_admins				security_pkg.T_SID_ID;
	v_groups					security_pkg.T_SID_ID;
	v_auditors					security_pkg.T_SID_ID;
	v_reporters					security_pkg.T_SID_ID;
	-- mail
	v_email						customer.system_mail_address%TYPE;
	v_tracker_email				customer.tracker_mail_address%TYPE;
	v_root_mailbox_sid			security_pkg.T_SID_ID;
	v_account_sid				security_pkg.T_SID_ID;
	v_outbox_mailbox_sid		security_pkg.T_SID_ID;
	v_sent_mailbox_sid			security_pkg.T_SID_ID;
	v_users_mailbox_sid			security_pkg.T_SID_ID;
	v_user_mailbox_sid			security_pkg.T_SID_ID;
	v_tracker_root_mailbox_sid	security_pkg.T_SID_ID;
	v_tracker_account_sid		security_pkg.T_SID_ID;
	-- reporting periods
	v_period_start_dtm			DATE;
	v_period_sid				security_pkg.T_SID_ID;
	-- user creator
	v_user_creator_daemon_sid   security_pkg.T_SID_ID;
	-- section stuff
	v_status_sid                security_pkg.T_SID_ID;
    v_text_sid                  security_pkg.T_SID_ID;
    v_text_statuses_sid         security_pkg.T_SID_ID;
    v_text_transitions_sid      security_pkg.T_SID_ID;
    v_deleg_plans_sid			security_pkg.T_SID_ID;
	-- en
 	v_lang_id					aspen2.lang.lang_id%TYPE;
 	-- misc
 	v_sid						security_pkg.T_SID_ID;
 	v_app_sid					security_pkg.T_SID_ID;
	-- group and role stuff
	TYPE T_ROLE_NAMES IS TABLE OF VARCHAR2(255) INDEX BY BINARY_INTEGER;
	v_role_names				T_ROLE_NAMES;
	v_role_sid					security_pkg.T_SID_ID;
	v_data_contributors			security_pkg.T_SID_ID;
	v_act_id					security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
BEGIN
	-- Create the app object
	securableObject_pkg.CreateSO(
		v_act_id,
		security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY', 'ACT'), security.security_pkg.SID_ROOT, '//aspen/applications'),
		class_pkg.GetClassID('CSRApp'),
		in_app_name,
		v_app_sid);

	/*** default to English **/
	SELECT lang_id
	  INTO v_lang_id
	  FROM aspen2.lang
	 WHERE lang = 'en';
	
	-- use english as the base for the site (rather than en-gb)
	aspen2.tr_pkg.SetBaseLang(SYS_CONTEXT('SECURITY', 'APP'), 'en');
	aspen2.tr_pkg.AddApplicationTranslation(SYS_CONTEXT('SECURITY', 'APP'), v_lang_id);

	/*** GROUPS ***/
	v_groups := securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups');
	v_admins := securableobject_pkg.GetSIDFromPath(v_act_id, v_groups, 'Administrators');
	v_reg_users := securableobject_pkg.GetSIDFromPath(v_act_id, v_groups, 'RegisteredUsers');
	
	-- make superadmins members of both RegisteredUsers and Administrators
	v_super_admins := securableobject_pkg.GetSIDFromPath(v_act_id, 0, 'csr/SuperAdmins');
	group_pkg.AddMember(v_act_id, v_super_admins, v_admins);
	group_pkg.AddMember(v_act_id, v_super_admins, v_reg_users);
	-- give superadmins logon as any user on RegisteredUsers
	acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_reg_users), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_super_admins, security_pkg.PERMISSION_STANDARD_ALL+csr_data_pkg.PERMISSION_LOGON_AS_USER);
	
	-- create a data providers group
	group_pkg.CreateGroupWithClass(
		v_act_id, 
		v_groups, 
		security_pkg.GROUP_TYPE_SECURITY, 
		'Data Contributors', 
		class_pkg.getclassid('CSRUserGroup'), 
		v_data_contributors
	);
	
	-- create auditors group
	group_pkg.CreateGroupWithClass(
		v_act_id, 
		v_groups, 
		security_pkg.GROUP_TYPE_SECURITY, 
		'Auditors', 
		class_pkg.getclassid('CSRUserGroup'), 
		v_auditors
	);
	
	-- create reporters group
	group_pkg.CreateGroupWithClass(
		v_act_id, 
		v_groups, 
		security_pkg.GROUP_TYPE_SECURITY, 
		'Reporters', 
		class_pkg.getclassid('CSRUserGroup'), 
		v_reporters
	);
	
	/*** CSR ***/
	-- grant admins ALL permissions on the app 
	acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_app_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_admins, security_pkg.PERMISSION_STANDARD_ALL);
	-- grant admins 'alter schema' on the app node (not inheritable)
	acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_app_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_admins, security_pkg.PERMISSION_STANDARD_ALL+csr_data_pkg.PERMISSION_ALTER_SCHEMA);
	
	/*** INDICATORS ***/	
	-- create as a group so we can add members (for permissions)
	group_pkg.CreateGroupWithClass(v_act_id, v_app_sid, security_pkg.GROUP_TYPE_SECURITY, 'Indicators',
		security_pkg.SO_CONTAINER, v_ind_root_sid_id);
	-- add object to the DACL (the container is a group, so it has permissions on itself)
	acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_ind_root_sid_id), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_ind_root_sid_id, security_pkg.PERMISSION_STANDARD_READ);
	
	/*** REGIONS ***/
	-- create as a group so we can add members (for permissions)
	group_pkg.CreateGroupWithClass(v_act_id, v_app_sid, security_pkg.GROUP_TYPE_SECURITY, 'Regions',
		security_pkg.SO_CONTAINER, v_region_root_sid_id);
	-- add object to the DACL (the container is a group, so it has permissions on itself)
	acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_region_root_sid_id), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_region_root_sid_id, security_pkg.PERMISSION_STANDARD_READ);
	
	/*** MEASURES ***/
	SecurableObject_pkg.CreateSO(v_act_id, v_app_sid, security_pkg.SO_CONTAINER, 'Measures', v_new_sid_id);
	-- grant registered users READ on measures (inheritable)
	acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_new_sid_id), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_reg_users, security_pkg.PERMISSION_STANDARD_READ);
				
	/*** DATAVIEWS ***/
	SecurableObject_pkg.CreateSO(v_act_id, v_app_sid, security_pkg.SO_CONTAINER, 'Dataviews', v_new_sid_id);
	-- grant RegisteredUsers READ on Dataviews
	acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_new_sid_id), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_reg_users, security_pkg.PERMISSION_STANDARD_READ);
	
	/*** PIVOT TABLES ***/
	SecurableObject_pkg.CreateSO(v_act_id, v_app_sid, security_pkg.SO_CONTAINER, 'Pivot tables', v_new_sid_id);
	-- grant RegisteredUsers READ on pivot tables
	acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_new_sid_id), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_reg_users, security_pkg.PERMISSION_STANDARD_READ);

	/*** DASHBOARDS ***/
	SecurableObject_pkg.CreateSO(v_act_id, v_app_sid, security_pkg.SO_CONTAINER, 'Dashboards', v_new_sid_id);
	-- grant RegisteredUsers READ on Dashboards
	acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_new_sid_id), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_reg_users, security_pkg.PERMISSION_STANDARD_READ);

	/*** IMPORTS ***/
	SecurableObject_pkg.CreateSO(v_act_id, v_app_sid, security_pkg.SO_CONTAINER, 'Imports', v_new_sid_id);
	-- grant Auditors READ on Imports (inheritable)
	acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_new_sid_id), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_auditors, security_pkg.PERMISSION_STANDARD_READ);
	-- grant Contributors READ / WRITE on Imports (inheritable)
	acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_new_sid_id), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_data_contributors, security_pkg.PERMISSION_STANDARD_ALL);
		
	/*** FORMS ***/
	SecurableObject_pkg.CreateSO(v_act_id, v_app_sid, security_pkg.SO_CONTAINER, 'Forms', v_new_sid_id);
	-- grant Auditors + Data Contributors READ on Forms (inheritable)
	acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_new_sid_id), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_data_contributors, security_pkg.PERMISSION_STANDARD_READ);
	acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_new_sid_id), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_auditors, security_pkg.PERMISSION_STANDARD_READ);
		
	/*** DELEGATIONS ***/
	SecurableObject_pkg.CreateSO(v_act_id, v_app_sid, security_pkg.SO_CONTAINER, 'Delegations', v_new_sid_id);
	-- grant auditors
	acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_new_sid_id), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_auditors, security_pkg.PERMISSION_STANDARD_READ);
	
	SecurableObject_pkg.CreateSO(v_act_id, v_app_sid, security_pkg.SO_CONTAINER, 'DelegationPlans', v_deleg_plans_sid);	
	
	/*** PENDING FORMS ***/
	SecurableObject_pkg.CreateSO(v_act_id, v_app_sid, security_pkg.SO_CONTAINER, 'Pending', v_pending_sid_id);
	SecurableObject_pkg.CreateSO(v_act_id, v_pending_sid_id, security_pkg.SO_CONTAINER, 'Forms', v_new_sid_id);
	SecurableObject_pkg.CreateSO(v_act_id, v_pending_sid_id, security_pkg.SO_CONTAINER, 'Datasets', v_new_sid_id);
	
	/*** TRASH ***/
	-- create trash 
	SecurableObject_pkg.CreateSO(v_act_id, v_app_sid, class_pkg.GetClassId('TrashCan'), 'Trash', v_trash_sid_id);
	-- grant admins RESTORE FROM TRASH permissions
	acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_trash_sid_id), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_admins, security_pkg.PERMISSION_STANDARD_ALL + csr_data_pkg.PERMISSION_RESTORE_FROM_TRASH);
		
	/*** ACCOUNT POLICY ***/
	-- create an account policy with no options set
	-- give admins write access on it
	security.accountPolicy_pkg.CreatePolicy(v_act_id, v_app_sid, 'AccountPolicy', null, null, null, null, null, 1, v_policy_sid);
	acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_policy_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_admins, security_pkg.PERMISSION_STANDARD_ALL);
	
	/*** MAIL ***/
	-- create system mail account and add an Outbox (foo.credit360.com -> foo@credit360.com)
	-- .credit360.com = 14 chars
	IF LOWER(SUBSTR(in_app_name, LENGTH(in_app_name) - 13, 14)) = '.credit360.com' THEN
		-- a standard foo.credit360.com
		v_email := SUBSTR(in_app_name, 1, LENGTH(in_app_name)-14)||'@credit360.com';
		v_tracker_email := SUBSTR(in_app_name, 1, LENGTH(in_app_name)-14)||'_tracker@credit360.com';
	ELSE
		-- not a standard foo.credit360.com, so... www.foo.com@credit360.com
		v_email := in_app_name||'@credit360.com';
		v_tracker_email := in_app_name||'_tracker@credit360.com';
	END IF;

	-- If you get an error here, it's probably because you dropped/recreated the site
	-- You will have to clean up the mailbox manually
	-- This is DELIBERATELY not re-using the mailbox to avoid cross-site mail leaks
	mail.mail_pkg.createAccount(v_email, NULL, 'System mail account for '||in_app_name, v_account_sid, v_root_mailbox_sid);
	-- let admins poke the mailboxes
	acl_pkg.AddACE(SYS_CONTEXT('SECURITY', 'ACT'), acl_pkg.GetDACLIDForSID(v_root_mailbox_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_admins, security_pkg.PERMISSION_STANDARD_ALL);

	-- create sent/outbox and grant registered users add contents permission so they can be sent alerts
	mail.mail_pkg.createMailbox(v_root_mailbox_sid, 'Sent', v_sent_mailbox_sid);
	acl_pkg.AddACE(SYS_CONTEXT('SECURITY', 'ACT'), acl_pkg.GetDACLIDForSID(v_sent_mailbox_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_reg_users, security_pkg.PERMISSION_ADD_CONTENTS);
	mail.mail_pkg.createMailbox(v_root_mailbox_sid, 'Outbox', v_outbox_mailbox_sid);	
	acl_pkg.AddACE(SYS_CONTEXT('SECURITY', 'ACT'), acl_pkg.GetDACLIDForSID(v_outbox_mailbox_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_reg_users, security_pkg.PERMISSION_ADD_CONTENTS);
	
	-- create a container for per user mailboxes
	mail.mail_pkg.createMailbox(v_root_mailbox_sid, 'Users', v_users_mailbox_sid);

	-- create the tracker account
	mail.mail_pkg.createAccount(v_tracker_email, NULL, 'Tracker mail account for '||in_app_name, v_tracker_account_sid, v_tracker_root_mailbox_sid);
	-- let admins poke the mailboxes
	acl_pkg.AddACE(SYS_CONTEXT('SECURITY', 'ACT'), acl_pkg.GetDACLIDForSID(v_tracker_root_mailbox_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_admins, security_pkg.PERMISSION_STANDARD_ALL);
		
	/*** REPORTING PERIODS ***/
	SecurableObject_pkg.CreateSO(v_act_id, v_app_sid, security_pkg.SO_CONTAINER, 'ReportingPeriods', v_new_sid_id);
	-- grant registered users READ on reporting periods (inheritable)
	acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_new_sid_id), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_reg_users, security_pkg.PERMISSION_STANDARD_READ);

	/*** GENERAL CUSTOMER ATTRIBUTES ***/
	-- insert into customer
	INSERT INTO customer (
		app_sid, name, host, system_mail_address, tracker_mail_address, alert_mail_address, alert_mail_name,
		editing_url, account_policy_sid, current_reporting_period_sid, 
		ind_info_xml_fields, 
		ind_root_sid, region_root_sid, trash_sid,
		start_month, default_admin_css
	) VALUES (
		v_app_sid, in_app_name, in_app_name, v_email, v_tracker_email, 'support@credit360.com', 'Credit360 support team',
		'/csr/site/delegation/sheet.acds?', v_policy_sid, null,
		XMLType('<ind-metadata><field name="definition" label="Detailed info"/></ind-metadata>'),
		null, null, v_trash_sid_id, in_start_month, in_styles_path || '/includes/credit.css'
	);
	
	UPDATE aspen2.application
	   SET default_url = '/csr/site/delegation/myDelegations.acds',
	   	   menu_path = '//aspen/applications/' || in_app_name || '/menu',	   	   
	   	   metadata_connection_string = 'Provider=NPSLMDSQL.MDSQL.1;User ID=mtdata;Password=mtdata;Persist Security Info=True;initial catalog=//aspen/applications/' || in_app_name || '/metadata;DATA SOURCE=aspen;',
		   logon_url = '/csr/site/login.acds',
		   default_stylesheet = in_styles_path || '/generic.xsl',
		   commerce_store_path = '//aspen/applications/' || in_app_name || '/store',
		   edit_css = in_styles_path || '/includes/page.css',
		   default_css = in_styles_path || '/includes/all.cssx'
	 WHERE app_sid = v_app_sid;
	
	-- locks
	INSERT INTO app_lock
		(app_sid, lock_type)
	VALUES
		(v_app_sid, csr_data_pkg.LOCK_TYPE_CALC);
	INSERT INTO app_lock
		(app_sid, lock_type)
	VALUES
		(v_app_sid, csr_data_pkg.LOCK_TYPE_SHEET_CALC);

	-- clone all superadmins for the new app
	INSERT INTO csr_user (app_sid, csr_user_sid, user_name, full_name, email, friendly_name, guid)
		SELECT v_app_sid, s.csr_user_sid, s.user_name, s.full_name, s.email, s.friendly_name, s.guid
          FROM superadmin s
         INNER JOIN security.securable_object so ON s.csr_user_sid = so.sid_id;

	-- sometimes we record audit log entries against builtin/administrator and guest
	-- we hard-coded the GUIDs so csrexp will move them nicely
	INSERT INTO csr_user
		(app_sid, csr_user_sid, user_name, full_name, friendly_name, email, guid, hidden)
	VALUES 
		(v_app_sid, security_pkg.SID_BUILTIN_ADMINISTRATOR, 'builtinadministrator', 'Builtin Administrator', 
		 'Builtin Administrator', 'support@credit360.com', 'A3B4FB4B-BC13-53A3-8714-95640E79CA8A', 1);
	INSERT INTO csr_user
		(app_sid, csr_user_sid, user_name, full_name, friendly_name, email, guid, hidden)
	VALUES 
		(v_app_sid, security_pkg.SID_BUILTIN_GUEST, 'guest', 'Guest', 
		 'Guest', 'support@credit360.com', '77646D7A-A70E-E923-2FF6-2FD960873984', 1); 

	-- create a default reporting period
	v_period_start_dtm := TO_DATE('1/'||in_start_month||'/'||EXTRACT(Year FROM SYSDATE),'DD/MM/yyyy');
	reporting_period_pkg.CreateReportingPeriod(v_act_id, v_app_sid, EXTRACT(Year FROM SYSDATE), v_period_start_dtm, ADD_MONTHS(v_period_start_dtm, 12), 0, v_period_sid); 	
	UPDATE customer
 	   SET current_reporting_period_sid = v_period_sid
 	 WHERE app_sid = v_app_sid;

	/*** BOOTSTRAP INDICATORS AND REGIONS ***/
	-- we have to do this once we've put data into the customer table due to FK constraints on APP_SID
	-- Add standard region types to the customer_region_type table for this app
	INSERT INTO customer_region_type (app_sid, region_type) VALUES (v_app_sid, csr_data_pkg.REGION_TYPE_NORMAL);
	INSERT INTO customer_region_type (app_sid, region_type) VALUES (v_app_sid, csr_data_pkg.REGION_TYPE_ROOT);
	INSERT INTO customer_region_type (app_sid, region_type) VALUES (v_app_sid, csr_data_pkg.REGION_TYPE_PROPERTY);
	INSERT INTO customer_region_type (app_sid, region_type) VALUES (v_app_sid, csr_data_pkg.REGION_TYPE_TENANT);
	-- add region root
	INSERT INTO REGION_TREE (
		REGION_TREE_ROOT_SID, app_sid, LAST_RECALC_DTM, IS_PRIMARY
	) VALUES (
		v_region_root_sid_id, v_app_sid, NULL, 1
	);		
	-- insert regions sid (for user start points)
	INSERT INTO region (
		region_sid, parent_sid, app_sid, name, active, pos, info_xml, link_to_region_sid, region_type
	) VALUES (
		v_region_root_sid_id, v_app_sid, v_app_sid, 'regions', 1, 1, null, null, csr_data_pkg.REGION_TYPE_ROOT
	);
	INSERT INTO region_description
		(region_sid, lang, description)
	VALUES
		(v_region_root_sid_id, 'en', 'Regions');
		
	AddCalendarMonthPeriodSet;
	
	INSERT INTO ind (
		ind_sid, parent_sid, name, app_sid, period_set_id, period_interval_id
	) VALUES (
		v_ind_root_sid_id, v_app_sid, 'indicators', v_app_sid, 1, 1
	);
	INSERT INTO ind_description
		(ind_sid, lang, description)
	VALUES
		(v_ind_root_sid_id, 'en', 'Indicators');

	-- make Indicators and Regions members of themselves 
	group_pkg.AddMember(v_act_id, v_ind_root_sid_id, v_ind_root_sid_id);
	group_pkg.AddMember(v_act_id, v_region_root_sid_id, v_region_root_sid_id);
	
	UPDATE customer
	   SET ind_root_sid = v_ind_root_sid_id, 
	   	   region_root_sid = v_region_root_sid_id
	 WHERE app_sid = v_app_sid;

    -- fiddle with UserCreatorDaemon    
    v_user_creator_daemon_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Users/UserCreatorDaemon');
    
    INSERT INTO csr_user
        (csr_user_sid, email, guid, region_mount_point_sid, app_sid,
        full_name, user_name, friendly_name, info_xml, send_alerts, show_portal_help, hidden)
        SELECT v_user_creator_daemon_sid , 'support@credit360.com',  user_pkg.GenerateACT, c.region_root_sid,  
               c.app_sid, 'Automatic User Creator', 'UserCreatorDaemon', 'Automatic User Creator', null, 0, 0, 1
          FROM customer c
         WHERE c.app_sid = v_app_sid;

	-- Grant UserCreatorDaemon add contents permission on the users mailbox folder (non-inheritable)
	acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_users_mailbox_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		0, v_user_creator_daemon_sid, security_pkg.PERMISSION_ADD_CONTENTS);
	
	-- Grant UserCreatorDaemon all permissions on delegations for when delegation plans roll out
	acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Delegations')), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_user_creator_daemon_sid, security_pkg.PERMISSION_STANDARD_ALL + csr_data_pkg.PERMISSION_ALTER_SCHEMA);
	
	-- Grant UserCreatorDaemon read permissions on delegation plans for when delegation plans roll out
	acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_deleg_plans_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_user_creator_daemon_sid, security_pkg.PERMISSION_READ);

	-- add UCD to Regions, with write permissions (so they can set region start points, e.g. when self-registering users)
	acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_region_root_sid_id), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_user_creator_daemon_sid, security_pkg.PERMISSION_STANDARD_ALL);
		
	-- Make them a member of registered users
	security.group_pkg.AddMember(SYS_CONTEXT('SECURITY', 'ACT'), v_user_creator_daemon_sid, v_reg_users);

    -- add start point for superadmins
    INSERT INTO ind_start_point (ind_sid, user_sid)
        SELECT v_ind_root_sid_id, s.csr_user_sid
          FROM superadmin s
          JOIN security.securable_object so ON s.csr_user_sid = so.sid_id;

	-- add a mailbox for each user, granting them full control over it
	-- and giving other registered users add contents permission
	FOR r IN (SELECT csr_user_sid
				FROM csr_user
			   WHERE app_sid = v_app_sid
	) LOOP
		mail.mail_pkg.createMailbox(v_users_mailbox_sid, r.csr_user_sid, v_user_mailbox_sid);
		acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_user_mailbox_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
			security_pkg.ACE_FLAG_DEFAULT, v_reg_users, security_pkg.PERMISSION_ADD_CONTENTS);
		acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_user_mailbox_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
			security_pkg.ACE_FLAG_DEFAULT, r.csr_user_sid, security_pkg.PERMISSION_STANDARD_ALL);
	END LOOP;

	/*** SECTIONS ***/
	securableobject_pkg.CreateSO(v_act_id, v_app_sid, security_pkg.SO_CONTAINER, 'Text', v_text_sid);
    securableobject_pkg.CreateSO(v_act_id, v_text_sid, security_pkg.SO_CONTAINER, 'Statuses', v_text_statuses_sid);
    securableobject_pkg.CreateSO(v_act_id, v_text_sid, security_pkg.SO_CONTAINER, 'Transitions', v_text_transitions_sid);
    -- make default status (red)
    section_status_pkg.CreateSectionStatus('Editing', 15728640, 0, v_status_sid);

	-- section root relies on a row in the customer table so we create it down here
	securableobject_pkg.CreateSO(v_act_id, v_app_sid, class_pkg.GetClassID('CSRSectionRoot'), 'Sections', v_new_sid_id);
	-- Give the administrators group ALL and CHANGE_TITLE permimssions on it (inheritable)
	-- (We have to do this as the change title permission is unique to a CSRSectionRoot or CSRSection object and so is 
	-- not inherited from the parent)
	acl_pkg.RemoveACEsForSid(v_act_id, acl_pkg.GetDACLIDForSID(v_new_sid_id), v_admins);
	acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_new_sid_id), 
		security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, 
		v_admins, security_pkg.PERMISSION_STANDARD_ALL + csr_data_pkg.PERMISSION_CHANGE_TITLE + csr_data_pkg.PERMISSION_EDIT_SECTION_MODULE);
	
	-- Add default roles (moved down as roles have dependencies on customer table)
	v_role_names(1) := 'Data Providers';
	v_role_names(2) := 'Data Approvers';
	FOR i IN v_role_names.FIRST..v_role_names.LAST
	LOOP	
		role_pkg.SetRole(v_role_names(i), v_role_sid);
		-- make the role a member of the Data Contributors groups
		security.group_pkg.AddMember(security_pkg.getact, v_role_sid, v_data_contributors);
	END LOOP;
	
	-- add Subdelegation capability and other common bits
	csr_data_pkg.enablecapability('Subdelegation');
	csr_data_pkg.enablecapability('System management');
	csr_data_pkg.enablecapability('Issue management');
	csr_data_pkg.enablecapability('Report publication');
	csr_data_pkg.enablecapability('Manage any portal');
	csr_data_pkg.enablecapability('Create users for approval');
	csr_data_pkg.enablecapability('Use gauge-style charts');
	csr_data_pkg.enablecapability('Add portal tabs');
	csr_data_pkg.enablecapability('View Delegation link from Sheet');
	csr_data_pkg.enablecapability('Manage jobs');
	csr_data_pkg.enablecapability('Enable Delegation Sheet changes warning');
	csr_data_pkg.enablecapability('Save shared indicator sets');
	csr_data_pkg.enablecapability('Save shared region sets');
	csr_data_pkg.enablecapability('Can import users and role memberships via structure import');
	csr_data_pkg.enablecapability('Can manage filter alerts');
	csr_data_pkg.enablecapability('Run sheet export report');
	
	csr_data_pkg.enablecapability('Import surveys from Excel');
	acl_pkg.AddACE(
		v_act_id,
		Acl_pkg.GetDACLIDForSID(securableobject_pkg.GetSIDFromPath(v_act_id, security_pkg.GetApp, 'Capabilities/Import surveys from Excel')),
		security_pkg.ACL_INDEX_LAST,
		security_pkg.ACE_TYPE_ALLOW,
		0,
		securableobject_pkg.GetSIDFromPath(v_act_id, security_pkg.GetApp, 'Groups/Everyone'),
		security_pkg.PERMISSION_READ+security_pkg.PERMISSION_WRITE+security_pkg.PERMISSION_READ_PERMISSIONS+security_pkg.PERMISSION_LIST_CONTENTS+security_pkg.PERMISSION_READ_ATTRIBUTES+security_pkg.PERMISSION_WRITE_ATTRIBUTES);

	/*** HELP **/
	-- insert the first help_lang_id for this customer
	INSERT INTO customer_help_lang (app_sid, help_lang_id, is_default)
		SELECT v_app_sid, MIN(help_lang_id), 1 
		  FROM help_lang;	
	
	region_pkg.createregion(
		in_parent_sid => v_deleg_plans_sid,
		in_name => 'DelegPlansRegion',
		in_description => 'DelegPlansRegion',
		in_geo_type => region_pkg.REGION_GEO_TYPE_OTHER,
		out_region_sid => v_new_sid_id
	);	  
	
	/*** ISSUE BITS ***/
	INSERT INTO issue_type (app_sid, issue_type_Id, label)
	VALUES (v_app_sid, 1, 'Data entry form');
	
	/*** ALERTS AND ALERT TEMPLATES ***/	

	-- now add in standard alerts for all csr customers (1 -> 5) + bulk mailout (20) + password reminder etc (21 -> 26)
	INSERT INTO customer_alert_type (app_sid, customer_alert_type_id, std_alert_type_id)
		SELECT v_app_sid, customer_alert_type_id_seq.nextval, std_alert_type_id
		  FROM std_alert_type 
		 WHERE std_alert_type_id IN (
				csr_data_pkg.ALERT_NEW_USER, 
				csr_data_pkg.ALERT_NEW_DELEGATION,
				csr_data_pkg.ALERT_OVERDUE_SHEET,
				csr_data_pkg.ALERT_SHEET_CHANGED,
				csr_data_pkg.ALERT_REMINDER_SHEET,
				csr_data_pkg.ALERT_DELEG_TERMINATED,
				csr_data_pkg.ALERT_GENERIC_MAILOUT,
				csr_data_pkg.ALERT_SELFREG_VALIDATE,
				csr_data_pkg.ALERT_SELFREG_NOTIFY,
				csr_data_pkg.ALERT_SELFREG_APPROVAL,
				csr_data_pkg.ALERT_SELFREG_REJECT,
				csr_data_pkg.ALERT_PASSWORD_RESET,
				csr_data_pkg.ALERT_ACCOUNT_DISABLED, 
				csr_data_pkg.ALERT_USER_COVER_STARTED,
				csr_data_pkg.ALERT_BATCH_JOB_COMPLETED,
				csr_data_pkg.ALERT_UPDATED_PLANNED_DELEG,
				csr_data_pkg.ALERT_NEW_PLANNED_DELEG,
				csr_data_pkg.ALERT_SHEET_RETURNED,
				csr_data_pkg.ALERT_USER_INACTIVE_REMINDER,
				csr_data_pkg.ALERT_USER_INACTIVE_SYSTEM,
				csr_data_pkg.ALERT_USER_INACTIVE_MANUAL
				);
		 
	AddStandardFramesAndTemplates;
	
	-- some basic units
	measure_pkg.createMeasure(
		in_name 					=> 'fileupload',
		in_description 				=> 'File upload',
		in_custom_field 			=> CHR(38),
		in_pct_ownership_applies	=> 0,
		in_divisibility				=> csr_data_pkg.DIVISIBILITY_LAST_PERIOD,
		out_measure_sid				=> v_sid
	);
	measure_pkg.createMeasure(
		in_name 					=> 'text',
		in_description 				=> 'Text',
		in_custom_field 			=> '|',
		in_pct_ownership_applies	=> 0,
		in_divisibility				=> csr_data_pkg.DIVISIBILITY_LAST_PERIOD,
		out_measure_sid				=> v_sid
	);
	measure_pkg.createMeasure(
		in_name 					=> 'date',
		in_description 				=> 'Date',
		in_custom_field 			=> '$',
		in_pct_ownership_applies	=> 0,
		in_divisibility				=> csr_data_pkg.DIVISIBILITY_LAST_PERIOD,
		out_measure_sid				=> v_sid
	);
		 
	-- delegation submission report
	sqlreport_pkg.EnableReport('csr.delegation_pkg.GetReportSubmissionPromptness');
	sqlreport_pkg.EnableReport('csr.delegation_pkg.GetReportDelegationBlockers');
	
	-- set default filters
	chain.card_pkg.SetGroupCards('Issues Filter', chain.T_STRING_LIST('Credit360.Filters.Issues.StandardIssuesFilter', 'Credit360.Filters.Issues.IssuesCustomFieldsFilter', 'Credit360.Filters.Issues.IssuesFilterAdapter'));
	chain.card_pkg.SetGroupCards('Cms Filter', chain.T_STRING_LIST('NPSL.Cms.Filters.CmsFilter'));

	out_app_sid := v_app_sid;
END;

PROCEDURE GetDetails(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	OPEN out_cur FOR
		SELECT c.name, c.host, c.system_mail_address, c.tracker_mail_address, c.alert_mail_address,
			   c.contact_email, c.raise_reminders, c.ind_info_xml_fields, c.region_info_xml_fields,
			   c.user_info_xml_fields, c.account_policy_sid, c.app_sid, c.current_reporting_period_sid,
			   c.region_root_sid, c.ind_root_sid, c.reporting_ind_root_sid,
			   c.helper_assembly, c.use_tracker, c.audit_calc_changes,
			   c.use_user_sheets, c.aggregation_engine_version, c.allow_val_edit, c.calc_sum_zero_fill,
			   c.equality_epsilon, NVL(ws.secure_only, 0) host_secure, c.alert_mail_name, c.editing_url, 
			   c.target_line_col_from_gradient, c.use_carbon_emission, c.create_sheets_at_period_end, c.allow_deleg_plan,
			   c.allow_make_editable, c.merged_scenario_run_sid, c.unmerged_scenario_run_sid, c.issue_editor_url, 
			   c.alert_uri_format, c.ind_selections_enabled, c.check_tolerance_against_zero, c.oracle_schema,
			   c.scenarios_enabled, c.use_var_expl_groups, c.apply_factors_to_child_regions, c.user_directory_type_id,
			   c.bounce_tracking_enabled, c.issue_escalation_enabled, c.property_flow_sid, c.chemical_flow_sid, c.incl_inactive_regions,
			   c.allow_section_in_many_carts, c.check_divisibility, c.lock_prevents_editing, c.lock_end_dtm, c.translation_checkbox,
			   c.trash_sid, c.allow_multiperiod_forms, c.start_month, c.chart_xsl, c.show_region_disposal_date,
			   c.data_explorer_show_markers, c.show_all_sheets_for_rep_prd, c.deleg_browser_show_rag,
			   c.tgtdash_ignore_estimated, c.tgtdash_hide_totals, c.tgtdash_show_chg_from_last_yr,
			   c.tgtdash_show_last_year, c.tgtdash_colour_text, c.tgtdash_show_target_first,
			   c.tgtdash_show_flash, c.use_region_events, c.metering_enabled, c.crc_metering_enabled,
			   c.crc_metering_ind_core, c.crc_metering_auto_core, c.iss_view_src_to_deepest_sheet,
			   c.delegs_always_show_adv_opts, c.default_admin_css, c.default_country, c.data_explorer_show_ranking,
			   c.data_explorer_show_trends, c.data_explorer_show_scatter, c.data_explorer_show_radar, c.data_explorer_show_gauge,
			   c.data_explorer_show_waterfall, c.multiple_audit_surveys, c.legacy_period_formatting
		  FROM customer c, security.website ws
		 WHERE c.app_sid = in_app_sid
		   AND c.host = ws.website_name(+);
END;

-- legacy version of the above that avoids fetching XMLTYPE columns
PROCEDURE GetDetailsForASP(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT c.start_month, c.delegs_always_show_adv_opts, c.default_admin_css
		  FROM customer c
		 WHERE c.app_sid = in_app_sid;
END;

PROCEDURE AmendDetails(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_app_sid					IN	security_pkg.T_SID_ID,
	in_name						IN	customer.name%TYPE,
	in_contact_email			IN	customer.contact_email%TYPE,	
	in_raise_reminders			IN	customer.raise_reminders%TYPE,		
	in_ind_info_xml_fields		IN	customer.ind_info_xml_fields%TYPE,		
	in_region_info_xml_fields	IN	customer.region_info_xml_fields%TYPE,		
	in_user_info_xml_fields 	IN	customer.user_info_xml_fields%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid, csr_data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	UPDATE customer
	   SET name = in_name,
	   	   contact_email = in_contact_email,
	   	   raise_reminders = in_raise_reminders,
	   	   ind_info_xml_fields = in_ind_info_xml_fields,
	   	   region_info_xml_fields = in_region_info_xml_fields,
	   	   user_info_xml_fields = in_user_info_xml_fields
	 WHERE app_sid = in_app_sid;
END;

PROCEDURE GetMessage(
	out_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT message
		  FROM customer
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetAppSid(
	in_host							IN	customer.host%TYPE,
	out_app_sid						OUT	customer.app_sid%TYPE
)
AS
BEGIN
	-- No security, use only in batch applications or command line tools
	-- If there isn't an entry in csr.customer then look for an alias in security.website
	SELECT NVL(
		(
			SELECT app_sid
			  FROM csr.customer
			 WHERE LOWER(host) = LOWER(in_host)
		),
		(
			SELECT application_sid_id
			  FROM security.website
			 WHERE LOWER(website_name) = LOWER(in_host)
		)
	) app_sid
	  INTO out_app_sid
	  FROM DUAL;
END;

PROCEDURE GetDBVersion(
	out_db_version				OUT	version.db_version%TYPE
)
AS
BEGIN
	SELECT db_version
	  INTO out_db_version
	  FROM version;
END;

PROCEDURE EnsureAppLanguageIsValid(
	in_act_id				IN	security_pkg.T_ACT_ID
)
AS
	v_count					NUMBER;
	v_app_sid				security_pkg.T_SID_ID;
	v_app_lang				security.user_table.language%TYPE;
	v_culture				security.user_table.culture%TYPE;
	v_timezone				security.user_table.timezone%TYPE;
BEGIN
	v_app_sid := security.security_pkg.GetApp;
	IF NOT Security_Pkg.IsAccessAllowedSID(in_act_id, v_app_sid, Security_Pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 'You do not have write permission on the application with sid '||v_app_sid);
	END IF;

	security.web_pkg.GetLocalisationSettings(in_act_id, v_app_sid, v_app_lang, v_culture, v_timezone);

	SELECT COUNT(*)
	  INTO v_count
	  FROM aspen2.translation_set
	 WHERE application_sid = v_app_sid
	   AND hidden = 0
	   AND lang = v_app_lang;

	IF (v_count = 0) THEN
		--set the default language of the app to null.
		security.web_pkg.SetLocalisationSettings(in_act_id, v_app_sid, NULL, v_culture, v_timezone);
	END IF;
END;

PROCEDURE EnsureLanguagesAreValid(
	in_act_id				IN	security_pkg.T_ACT_ID
)
AS
BEGIN
	EnsureAppLanguageIsValid(in_act_id);
	csr_user_pkg.EnsureUserLanguagesAreValid(in_act_id);
END;

END;
/

-- *** DDL ***
-- Create tables
-- csrimp.map_plugin_type was missing from csr/db/csrimp/map_tables.sql
DECLARE
	v_count			NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_tables
	 WHERE UPPER(owner) = 'CSRIMP'
	   AND UPPER(table_name) = 'MAP_PLUGIN_TYPE';
	
	IF v_count = 0 THEN
		EXECUTE IMMEDIATE
			'CREATE TABLE csrimp.map_plugin_type ('||
			'    CSRIMP_SESSION_ID		NUMBER(10) DEFAULT SYS_CONTEXT(''SECURITY'', ''CSRIMP_SESSION_ID'') NOT NULL,'||
			'    old_plugin_type_id		NUMBER(10) NOT NULL,'||
			'    new_plugin_type_id		NUMBER(10) NOT NULL,'||
			'    CONSTRAINT pk_map_plugin_type_id PRIMARY KEY (csrimp_session_id, old_plugin_type_id) USING INDEX,'||
			'    CONSTRAINT uk_map_plugin_type_id UNIQUE (csrimp_session_id, new_plugin_type_id) USING INDEX,'||
			'    CONSTRAINT fk_map_plugin_type_is FOREIGN KEY'||
			'        (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)'||
			'        ON DELETE CASCADE'||
			')';
	ELSE
		EXECUTE IMMEDIATE 'ALTER TABLE CSRIMP.MAP_PLUGIN_TYPE DROP constraint PK_MAP_PLUGIN_TYPE_ID DROP INDEX';
		EXECUTE IMMEDIATE 'ALTER TABLE CSRIMP.MAP_PLUGIN_TYPE ADD constraint PK_MAP_PLUGIN_TYPE_ID PRIMARY KEY (CSRIMP_SESSION_ID,OLD_PLUGIN_TYPE_ID)';
		EXECUTE IMMEDIATE 'ALTER TABLE CSRIMP.MAP_PLUGIN_TYPE DROP constraint UK_MAP_PLUGIN_TYPE_ID DROP INDEX';
		EXECUTE IMMEDIATE 'ALTER TABLE CSRIMP.MAP_PLUGIN_TYPE ADD constraint UK_MAP_PLUGIN_TYPE_ID UNIQUE (CSRIMP_SESSION_ID,NEW_PLUGIN_TYPE_ID)';
	END IF;
END;
/

CREATE TABLE CSRIMP.PORTAL_DASHBOARD(
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    PORTAL_SID              NUMBER(10, 0)    NOT NULL,
    PORTAL_GROUP            VARCHAR2(50)     NOT NULL,
    MENU_SID                NUMBER(10, 0),
    MESSAGE                 VARCHAR2(2048),
    CONSTRAINT PK_PORTAL_DASHBOARD PRIMARY KEY (CSRIMP_SESSION_ID, PORTAL_SID),
    CONSTRAINT FK_PORTAL_DASHBOARD_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE SEQUENCE chain.filter_page_ind_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;
	

CREATE SEQUENCE chain.filter_page_ind_intrval_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;
	
CREATE SEQUENCE chain.customer_aggregate_type_id_seq
    START WITH 10000
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;

-- Create tables
CREATE TABLE chain.filter_page_ind (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	filter_page_ind_id				NUMBER(10) NOT NULL,
	card_group_id					NUMBER(10) NOT NULL,
	ind_sid							NUMBER(10) NOT NULL,
	period_set_id					NUMBER(10) NOT NULL,
	period_interval_id				NUMBER(10) NOT NULL,
	start_dtm						DATE,
	end_dtm							DATE,
	previous_n_intervals			NUMBER(10),
	include_in_list					NUMBER(1) DEFAULT 1 NOT NULL,
	include_in_filter				NUMBER(1) DEFAULT 1 NOT NULL,
	include_in_aggregates			NUMBER(1) DEFAULT 0 NOT NULL,
	include_in_breakdown			NUMBER(1) DEFAULT 0 NOT NULL,
	show_measure_in_description		NUMBER(1) DEFAULT 1 NOT NULL,
	show_interval_in_description	NUMBER(1) DEFAULT 1 NOT NULL,
	description_override			VARCHAR2(1023),
	CONSTRAINT pk_filter_page_ind PRIMARY KEY (app_sid, filter_page_ind_id),	
	CONSTRAINT chk_fltr_pg_ind_dtm_or_intrvl CHECK (
		(start_dtm IS NOT NULL AND end_dtm IS NOT NULL AND previous_n_intervals IS NULL) OR 
		(start_dtm IS NULL AND end_dtm IS NULL AND previous_n_intervals IS NOT NULL)),	
	CONSTRAINT chk_fltr_pg_ind_intrvl_gt_0 CHECK (previous_n_intervals IS NULL OR previous_n_intervals > 0),
	CONSTRAINT chk_fltr_pg_ind_inc_list_1_0 CHECK (include_in_list IN (1,0)),
	CONSTRAINT chk_fltr_pg_ind_inc_fltr_1_0 CHECK (include_in_filter IN (1,0)),
	CONSTRAINT chk_fltr_pg_ind_inc_agg_1_0 CHECK (include_in_aggregates IN (1,0)),
	CONSTRAINT chk_fltr_pg_ind_inc_brkdwn_1_0 CHECK (include_in_breakdown IN (1,0)),
	CONSTRAINT chk_fltr_pg_ind_shw_msre_1_0 CHECK (show_measure_in_description IN (1,0)),
	CONSTRAINT chk_fltr_pg_ind_shw_intrvl_1_0 CHECK (show_interval_in_description IN (1,0)),
	CONSTRAINT fk_filter_page_ind_card_group FOREIGN KEY (card_group_id)
		REFERENCES chain.card_group (card_group_id),
	CONSTRAINT fk_filter_page_ind_ind FOREIGN KEY (app_sid, ind_sid)
		REFERENCES csr.ind (app_sid, ind_sid),
	CONSTRAINT fk_filter_page_ind_prd_inrtvl FOREIGN KEY (app_sid, period_set_id, period_interval_id)
		REFERENCES csr.period_interval (app_sid, period_set_id, period_interval_id)
);

CREATE INDEX chain.ix_filter_page_ind_card_group ON chain.filter_page_ind (app_sid, card_group_id);

CREATE UNIQUE INDEX chain.uk_filter_page_ind ON chain.filter_page_ind (
		app_sid, card_group_id, ind_sid, period_set_id, period_interval_id, 
		start_dtm, end_dtm, previous_n_intervals);
		
CREATE TABLE chain.filter_page_ind_interval (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	filter_page_ind_interval_id		NUMBER(10) NOT NULL,
	filter_page_ind_id				NUMBER(10) NOT NULL,
	start_dtm						DATE,
	current_interval_offset			NUMBER(10),
	CONSTRAINT pk_filter_page_ind_interval PRIMARY KEY (app_sid, filter_page_ind_interval_id),	
	CONSTRAINT chk_fltr_pg_i_itvl_dtm_or_itvl CHECK (
		(start_dtm IS NOT NULL AND current_interval_offset IS NULL) OR 
		(start_dtm IS NULL AND current_interval_offset IS NOT NULL)),
	CONSTRAINT fk_ftr_pg_ind_intvl_ftr_pg_ind FOREIGN KEY (app_sid, filter_page_ind_id)
		REFERENCES chain.filter_page_ind (app_sid, filter_page_ind_id)
);

CREATE UNIQUE INDEX chain.uk_filter_page_ind_interval ON chain.filter_page_ind_interval (
		app_sid, filter_page_ind_id, start_dtm, current_interval_offset);

CREATE GLOBAL TEMPORARY TABLE chain.tt_filter_ind_val (
	filter_page_ind_interval_id	NUMBER(10,0) NOT NULL,
	region_sid			NUMBER(10,0) NOT NULL,
	ind_sid				NUMBER(10,0) NOT NULL,
	period_start_dtm	DATE NOT NULL,
	period_end_dtm		DATE NOT NULL,
	val_number			NUMBER(24,10),
	error_code			NUMBER(10,0),
	note				CLOB
) ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE chain.tt_filter_id (
	ID							NUMBER(10) NOT NULL
)
ON COMMIT DELETE ROWS;

CREATE TABLE chain.customer_aggregate_type (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	card_group_id					NUMBER(10) NOT NULL,
	customer_aggregate_type_id		NUMBER(10) NOT NULL,
	cms_aggregate_type_id			NUMBER(10),
	initiative_metric_id			NUMBER(10),
	ind_sid							NUMBER(10),
	filter_page_ind_interval_id		NUMBER(10),
	CONSTRAINT pk_customer_aggregate_type PRIMARY KEY (app_sid, customer_aggregate_type_id),
	CONSTRAINT fk_custom_agg_type_card_group FOREIGN KEY (card_group_id)
		REFERENCES chain.card_group (card_group_id),
	CONSTRAINT fk_custom_agg_type_cms_agg_typ FOREIGN KEY (app_sid, cms_aggregate_type_id)
		REFERENCES cms.cms_aggregate_type(app_sid, cms_aggregate_type_id)
		ON DELETE CASCADE,
	CONSTRAINT  fk_custom_agg_type_init_metric FOREIGN KEY (app_sid, initiative_metric_id)
		REFERENCES csr.initiative_metric(app_sid, initiative_metric_id)
		ON DELETE CASCADE,
	CONSTRAINT fk_custom_agg_type_ind FOREIGN KEY (app_sid, ind_sid)
		REFERENCES csr.ind(app_sid, ind_sid)
		ON DELETE CASCADE,
	CONSTRAINT fk_cstm_agg_typ_fltr_pg_i_itvl FOREIGN KEY (app_sid, filter_page_ind_interval_id)
		REFERENCES chain.filter_page_ind_interval (app_sid, filter_page_ind_interval_id)
		ON DELETE CASCADE,
	CONSTRAINT chk_customer_aggregate_type
	CHECK ((cms_aggregate_type_id IS NOT NULL AND initiative_metric_id IS NULL AND ind_sid IS NULL AND filter_page_ind_interval_id IS NULL)
	   OR (cms_aggregate_type_id IS NULL AND initiative_metric_id IS NOT NULL AND ind_sid IS NULL AND filter_page_ind_interval_id IS NULL)
	   OR (cms_aggregate_type_id IS NULL AND initiative_metric_id IS NULL AND ind_sid IS NOT NULL AND filter_page_ind_interval_id IS NULL)
	   OR (cms_aggregate_type_id IS NULL AND initiative_metric_id IS NULL AND ind_sid IS NULL AND filter_page_ind_interval_id IS NOT NULL))
);

CREATE UNIQUE INDEX chain.uk_customer_aggregate_type ON chain.customer_aggregate_type (
		app_sid, card_group_id, cms_aggregate_type_id, initiative_metric_id, ind_sid, filter_page_ind_interval_id);

CREATE TABLE csrimp.chain_filter_page_ind (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	filter_page_ind_id				NUMBER(10) NOT NULL,
	card_group_id					NUMBER(10) NOT NULL,
	ind_sid							NUMBER(10) NOT NULL,
	period_set_id					NUMBER(10) NOT NULL,
	period_interval_id				NUMBER(10) NOT NULL,
	start_dtm						DATE,
	end_dtm							DATE,
	previous_n_intervals			NUMBER(10),
	include_in_list					NUMBER(1) NOT NULL,
	include_in_filter				NUMBER(1) NOT NULL,
	include_in_aggregates			NUMBER(1) NOT NULL,
	include_in_breakdown			NUMBER(1) NOT NULL,
	show_measure_in_description		NUMBER(1) NOT NULL,
	show_interval_in_description	NUMBER(1) NOT NULL,
	description_override			VARCHAR2(1023),
	CONSTRAINT pk_filter_page_ind PRIMARY KEY (csrimp_session_id, filter_page_ind_id),	
	CONSTRAINT chk_fltr_pg_ind_dtm_or_intrvl CHECK (
		(start_dtm IS NOT NULL AND end_dtm IS NOT NULL AND previous_n_intervals IS NULL) OR 
		(start_dtm IS NULL AND end_dtm IS NULL AND previous_n_intervals IS NOT NULL)),	
	CONSTRAINT chk_fltr_pg_ind_intrvl_gt_0 CHECK (previous_n_intervals IS NULL OR previous_n_intervals > 0),
	CONSTRAINT chk_fltr_pg_ind_inc_list_1_0 CHECK (include_in_list IN (1,0)),
	CONSTRAINT chk_fltr_pg_ind_inc_fltr_1_0 CHECK (include_in_filter IN (1,0)),
	CONSTRAINT chk_fltr_pg_ind_inc_agg_1_0 CHECK (include_in_aggregates IN (1,0)),
	CONSTRAINT chk_fltr_pg_ind_inc_brkdwn_1_0 CHECK (include_in_breakdown IN (1,0)),
	CONSTRAINT chk_fltr_pg_ind_shw_msre_1_0 CHECK (show_measure_in_description IN (1,0)),
	CONSTRAINT chk_fltr_pg_ind_shw_intrvl_1_0 CHECK (show_interval_in_description IN (1,0)),
	CONSTRAINT fk_chain_filter_page_ind_is FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);

CREATE UNIQUE INDEX csrimp.uk_chain_filter_page_ind ON csrimp.chain_filter_page_ind (
		csrimp_session_id, card_group_id, ind_sid, period_set_id, period_interval_id, 
		start_dtm, end_dtm, previous_n_intervals);
		
CREATE TABLE csrimp.chain_filter_page_ind_interval (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	filter_page_ind_interval_id		NUMBER(10) NOT NULL,
	filter_page_ind_id				NUMBER(10) NOT NULL,
	start_dtm						DATE,
	current_interval_offset			NUMBER(10),
	CONSTRAINT pk_filter_page_ind_interval PRIMARY KEY (csrimp_session_id, filter_page_ind_interval_id),	
	CONSTRAINT chk_fltr_pg_i_itvl_dtm_or_itvl CHECK (
		(start_dtm IS NOT NULL AND current_interval_offset IS NULL) OR 
		(start_dtm IS NULL AND current_interval_offset IS NOT NULL)),
	CONSTRAINT fk_chain_fltr_page_ind_itvl_is FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);

CREATE UNIQUE INDEX csrimp.uk_chain_filter_page_ind_itvl ON csrimp.chain_filter_page_ind_interval (
		csrimp_session_id, filter_page_ind_id, start_dtm, current_interval_offset);
		
CREATE TABLE csrimp.chain_customer_aggregate_type (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	card_group_id					NUMBER(10) NOT NULL,
	customer_aggregate_type_id		NUMBER(10) NOT NULL,
	cms_aggregate_type_id			NUMBER(10),
	initiative_metric_id			NUMBER(10),
	ind_sid							NUMBER(10),
	filter_page_ind_interval_id		NUMBER(10),
	CONSTRAINT pk_customer_aggregate_type PRIMARY KEY (csrimp_session_id, customer_aggregate_type_id),
	CONSTRAINT chk_customer_aggregate_type
	CHECK ((cms_aggregate_type_id IS NOT NULL AND initiative_metric_id IS NULL AND ind_sid IS NULL AND filter_page_ind_interval_id IS NULL)
	   OR (cms_aggregate_type_id IS NULL AND initiative_metric_id IS NOT NULL AND ind_sid IS NULL AND filter_page_ind_interval_id IS NULL)
	   OR (cms_aggregate_type_id IS NULL AND initiative_metric_id IS NULL AND ind_sid IS NOT NULL AND filter_page_ind_interval_id IS NULL)
	   OR (cms_aggregate_type_id IS NULL AND initiative_metric_id IS NULL AND ind_sid IS NULL AND filter_page_ind_interval_id IS NOT NULL))
);

CREATE UNIQUE INDEX csrimp.uk_customer_aggregate_type ON csrimp.chain_customer_aggregate_type (
		csrimp_session_id, card_group_id, cms_aggregate_type_id, initiative_metric_id, ind_sid, filter_page_ind_interval_id);
		
CREATE TABLE CSRIMP.MAP_CHAIN_FILTER_PAGE_IND (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_FILTER_PAGE_IND_ID NUMBER(10) NOT NULL,
	NEW_FILTER_PAGE_IND_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_FILTER_PAGE_IND PRIMARY KEY (CSRIMP_SESSION_ID, OLD_FILTER_PAGE_IND_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_FILTER_PAGE_IND UNIQUE (CSRIMP_SESSION_ID, NEW_FILTER_PAGE_IND_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_FLTR_PAGE_IND_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_FLTR_PAGE_IND_INTRVL (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_FILTER_PAGE_IND_INTRVL_ID NUMBER(10) NOT NULL,
	NEW_FILTER_PAGE_IND_INTRVL_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_FLTR_PG_IND_INTVL PRIMARY KEY (CSRIMP_SESSION_ID, OLD_FILTER_PAGE_IND_INTRVL_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_FLTR_PG_IND_INTVL UNIQUE (CSRIMP_SESSION_ID, NEW_FILTER_PAGE_IND_INTRVL_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_FLTR_PG_IND_I_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_CUSTOM_AGG_TYPE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_CUSTOMER_AGGREGATE_TYPE_ID NUMBER(10) NOT NULL,
	NEW_CUSTOMER_AGGREGATE_TYPE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_CUSTOM_AGG_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_CUSTOMER_AGGREGATE_TYPE_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_CUSTOM_AGG_TYPE UNIQUE (CSRIMP_SESSION_ID, NEW_CUSTOMER_AGGREGATE_TYPE_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_CUSTOM_AGG_TYP_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

-- Alter tables
ALTER TABLE csr.import_protocol
RENAME TO file_io_protocol;
ALTER TABLE csr.file_io_protocol
RENAME COLUMN import_protocol_id TO file_io_protocol_id;

ALTER TABLE csr.cms_imp_class_step
RENAME COLUMN cms_imp_protocol_id TO file_io_protocol_id;
ALTER TABLE csr.cms_imp_class_step
RENAME CONSTRAINT fk_cms_imp_prt_imp_cls_stp TO fk_cms_imp_file_io_proto_id;


-- Move over to plugin pattern used in Export
ALTER TABLE csr.cms_imp_class
RENAME TO automated_import_class;
ALTER TABLE csr.automated_import_class
RENAME COLUMN cms_imp_class_sid to automated_import_class_sid;

ALTER TABLE csr.cms_imp_class_step
RENAME TO automated_import_class_step;
ALTER TABLE csr.automated_import_class_step
RENAME COLUMN cms_imp_class_sid to automated_import_class_sid;

ALTER TABLE csr.cms_imp_instance
RENAME TO automated_import_instance;
ALTER TABLE csr.automated_import_instance
RENAME COLUMN cms_imp_instance_id TO automated_import_instance_id;
ALTER TABLE csr.automated_import_instance
RENAME COLUMN cms_imp_class_sid to automated_import_class_sid;

ALTER TABLE csr.cms_imp_file_type
RENAME COLUMN cms_imp_file_type_id to automated_import_file_type_id;
ALTER TABLE csr.cms_imp_file_type
RENAME TO automated_import_file_type;
ALTER TABLE csr.cms_imp_instance_step
RENAME COLUMN cms_imp_instance_step_id TO auto_import_instance_step_id;
ALTER TABLE csr.cms_imp_instance_step
RENAME COLUMN cms_imp_instance_id TO automated_import_instance_id;
ALTER TABLE csr.cms_imp_instance_step
RENAME COLUMN cms_imp_class_sid TO automated_import_class_sid;
ALTER TABLE csr.cms_imp_instance_step
RENAME TO automated_import_instance_step;
ALTER TABLE csr.cms_imp_manual_file
RENAME COLUMN cms_imp_instance_id to automated_import_instance_id;
ALTER TABLE csr.cms_imp_manual_file
RENAME TO automated_import_manual_file;
ALTER TABLE csr.cms_imp_result
RENAME COLUMN cms_imp_result_id TO automated_import_result_id;
ALTER TABLE csr.cms_imp_result
RENAME TO automated_import_result;

-- Rename the sequences. Unfortunately, that means dropping and creating
DECLARE
		v_seq_start INTEGER;
BEGIN
	SELECT csr.cms_imp_instance_id_seq.nextval
	  INTO v_seq_start
	  FROM dual;

	EXECUTE IMMEDIATE 'Create sequence csr.auto_imp_instance_id_seq
						start with ' || v_seq_start || ' increment by 1 NOMINVALUE NOMAXVALUE CACHE 20 NOORDER';

	SELECT csr.cms_imp_instance_step_id_seq.nextval
	  INTO v_seq_start
	  FROM dual;

	EXECUTE IMMEDIATE 'Create sequence csr.auto_imp_instance_step_id_seq
						start with ' || v_seq_start || ' increment by 1 NOMINVALUE NOMAXVALUE CACHE 20 NOORDER';
END;
/
DROP SEQUENCE csr.cms_imp_instance_id_seq;
DROP SEQUENCE csr.cms_imp_instance_step_id_seq;

-- IMPORT PLUGINS
CREATE TABLE csr.auto_imp_importer_plugin (
	plugin_id					NUMBER NOT NULL,
	label						VARCHAR2(128) NOT NULL,
	importer_assembly			VARCHAR2(255) NOT NULL,
	CONSTRAINT pk_auto_imp_importer_plugin_id PRIMARY KEY (plugin_id),
	CONSTRAINT uk_auto_imp_imprtr_plgn_label UNIQUE (label),
	CONSTRAINT uk_auto_imp_imprtr_plgn_assmb UNIQUE (importer_assembly)	
);


INSERT INTO csr.auto_imp_importer_plugin (plugin_id, label, importer_assembly)
VALUES (1, 'CMS importer',   'Credit360.AutomatedExportImport.Import.Importers.CmsExcelImpImporter');

ALTER TABLE csr.automated_import_class_step
ADD importer_plugin_id NUMBER DEFAULT 1 NOT NULL;

ALTER TABLE csr.automated_import_class_step
ADD CONSTRAINT fk_auto_imp_cls_stp_imp_plgn FOREIGN KEY (importer_plugin_id) REFERENCES csr.auto_imp_importer_plugin(plugin_id);

-- CMS IMPORTER
CREATE TABLE csr.auto_imp_importer_cms (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	auto_imp_importer_cms_id		NUMBER(10) NOT NULL,
	tab_sid							NUMBER(10) NOT NULL,
	mapping_xml						SYS.XMLTYPE NOT NULL,
	cms_imp_file_type_id			NUMBER(10) NOT NULL,
	dsv_separator					VARCHAR2(32),
	dsv_quotes_as_literals			NUMBER(1),
	excel_worksheet_index			NUMBER(10),
	all_or_nothing					NUMBER(1),
	CONSTRAINT pk_auto_imp_importer_cms PRIMARY KEY (app_sid, auto_imp_importer_cms_id),
	CONSTRAINT ck_auto_imp_importer_sep CHECK (dsv_separator IN ('PIPE','TAB','COMMA', 'SEMICOLON') OR dsv_separator IS NULL),
	CONSTRAINT ck_auto_imp_importer_quo CHECK (dsv_quotes_as_literals IN (0,1) OR dsv_quotes_as_literals IS NULL),
	CONSTRAINT ck_auto_imp_importer_allorno CHECK (all_or_nothing IN (0,1) OR all_or_nothing IS NULL),
	CONSTRAINT fk_auto_imp_imprtr_filetype FOREIGN KEY (cms_imp_file_type_id) REFERENCES csr.automated_import_file_type(automated_import_file_type_id)
);

CREATE SEQUENCE csr.auto_imp_importer_cms_id_seq
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20;
	
ALTER TABLE csr.automated_import_class_step
ADD auto_imp_importer_cms_id NUMBER(10);

DECLARE
	v_cms_id	NUMBER;
BEGIN
	FOR r IN (
		SELECT aics.app_sid, aic.automated_import_class_sid, aics.step_number, tab_sid, mapping_xml, cms_imp_file_type_id, dsv_separator, dsv_quotes_as_literals, 
			   excel_worksheet_index, all_or_nothing
		  FROM csr.automated_import_class_step aics
		  JOIN csr.automated_import_class aic ON aics.automated_import_class_sid = aic.automated_import_class_sid
	)
	LOOP
		SELECT csr.auto_imp_importer_cms_id_seq.nextval
		  INTO v_cms_id
		  FROM dual;
			
		-- Create the new profile
		INSERT INTO csr.auto_imp_importer_cms 
			(app_sid, auto_imp_importer_cms_id, tab_sid, mapping_xml, cms_imp_file_type_id, dsv_separator, dsv_quotes_as_literals, excel_worksheet_index, all_or_nothing)
		VALUES
			(r.app_sid, v_cms_id, r.tab_sid, r.mapping_xml, r.cms_imp_file_type_id, r.dsv_separator, r.dsv_quotes_as_literals, r.excel_worksheet_index, r.all_or_nothing);

		-- Update the record
		UPDATE csr.automated_import_class_step
		   SET auto_imp_importer_cms_id		= v_cms_id
		 WHERE automated_import_class_sid	= r.automated_import_class_sid
		   AND step_number					= r.step_number;
	END LOOP;
END;
/

ALTER TABLE csr.automated_import_class_step DROP COLUMN tab_sid;
ALTER TABLE csr.automated_import_class_step DROP COLUMN mapping_xml;
ALTER TABLE csr.automated_import_class_step DROP COLUMN cms_imp_file_type_id;
ALTER TABLE csr.automated_import_class_step DROP COLUMN dsv_separator;
ALTER TABLE csr.automated_import_class_step DROP COLUMN dsv_quotes_as_literals;
ALTER TABLE csr.automated_import_class_step DROP COLUMN excel_worksheet_index;
ALTER TABLE csr.automated_import_class_step DROP COLUMN all_or_nothing;



-- READER PLUGINS
CREATE TABLE csr.auto_imp_fileread_plugin (
	plugin_id						NUMBER NOT NULL,
	label							VARCHAR2(128) NOT NULL,
	fileread_assembly				VARCHAR2(255) NOT NULL,
	CONSTRAINT pk_auto_imp_fileread_plugin_id PRIMARY KEY (plugin_id),
	CONSTRAINT uk_auto_imp_fileread_label UNIQUE (label),
	CONSTRAINT uk_auto_imp_fileread_assembly UNIQUE (fileread_assembly)	
);

INSERT INTO csr.auto_imp_fileread_plugin (plugin_id, label, fileread_assembly)
VALUES (1, 'FTP Reader', 'Credit360.AutomatedExportImport.Import.FileReaders.FtpReader');
INSERT INTO csr.auto_imp_fileread_plugin (plugin_id, label, fileread_assembly)
VALUES (2, 'Database Reader', 'Credit360.AutomatedExportImport.Import.FileReaders.DBReader');

ALTER TABLE csr.automated_import_class_step
ADD fileread_plugin_id NUMBER;

--Update existing entries
UPDATE csr.automated_import_class_step
   SET fileread_plugin_id = 1 
 WHERE file_io_protocol_id = 0;
UPDATE csr.automated_import_class_step
   SET fileread_plugin_id = 2 
 WHERE file_io_protocol_id = 1;

ALTER TABLE csr.automated_import_class_step
ADD CONSTRAINT fk_auto_imp_cls_file_plugin FOREIGN KEY (fileread_plugin_id) REFERENCES csr.auto_imp_fileread_plugin(plugin_id);

-- FTP Reader
CREATE TABLE csr.auto_imp_fileread_ftp (
	app_sid								NUMBER(10) DEFAULT SYS_CONTEXT('security', 'app') NOT NULL,
	auto_imp_fileread_ftp_id			NUMBER(10) NOT NULL,
	ftp_profile_id						NUMBER(10) NOT NULL,
	payload_path						VARCHAR2(255) NOT NULL,
	file_mask							VARCHAR2(255),
	sort_by								VARCHAR2(10),
	sort_by_direction					VARCHAR2(10),
	move_to_path_on_success				VARCHAR2(1024),
	move_to_path_on_error				VARCHAR2(1024),
	delete_on_success					NUMBER(1) DEFAULT 0 NOT NULL,
	delete_on_error						NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT pk_auto_imp_fileread_ftp 		PRIMARY KEY (app_sid, auto_imp_fileread_ftp_id),
	CONSTRAINT fk_auto_imp_fileread_ftp_prof 	FOREIGN KEY (app_sid, ftp_profile_id) REFERENCES csr.ftp_profile(app_sid, ftp_profile_id),
	CONSTRAINT ck_auto_IMP_fileread_ftp_sort 	CHECK (SORT_BY IN ('DATE','FILENAME') OR SORT_BY IS NULL),
	CONSTRAINT ck_auto_imp_fileread_ftp_dir 	CHECK (sort_by_direction IN ('ASC','DESC') OR sort_by_direction IS NULL),
	CONSTRAINT ck_auto_imp_fileread_ftp_dlsuc 	CHECK (delete_on_success IN (0, 1)),
	CONSTRAINT ck_auto_imp_fileread_ftp_dlerr 	CHECK (delete_on_error IN (0, 1))
);

CREATE SEQUENCE csr.auto_imp_fileread_ftp_id_seq
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20;

ALTER TABLE csr.automated_import_class_step
ADD auto_imp_fileread_ftp_id NUMBER(10);

-- Move the contents of the existing steps to FTP settings table
DECLARE
	v_auto_imp_fileread_ftp_id	NUMBER;
BEGIN
	FOR r IN (
		SELECT cics.app_sid, cic.automated_import_class_sid, cics.step_number, payload_path, file_mask, sort_by, sort_by_direction, ftp_profile_id, move_to_path_on_success,
			   move_to_path_on_error, NVL(delete_on_success, 0) delete_on_success, NVL(delete_on_error, 0) delete_on_error
		  FROM csr.automated_import_class_step cics
		  JOIN csr.automated_import_class cic ON cics.automated_import_class_sid = cic.automated_import_class_sid
		 WHERE file_io_protocol_id = 0
		   AND cics.ftp_profile_id IS NOT NULL
	)
	LOOP
		SELECT csr.auto_imp_fileread_ftp_id_seq.nextval
		  INTO v_auto_imp_fileread_ftp_id
		  FROM dual;
			
		-- Create the new profile
		INSERT INTO csr.auto_imp_fileread_ftp 
			(app_sid, auto_imp_fileread_ftp_id, ftp_profile_id, payload_path, file_mask, sort_by, sort_by_direction, move_to_path_on_success, move_to_path_on_error, delete_on_success, delete_on_error)
		VALUES
			(r.app_sid, v_auto_imp_fileread_ftp_id, r.ftp_profile_id, r.payload_path, r.file_mask, r.sort_by, r.sort_by_direction, r.move_to_path_on_success, r.move_to_path_on_error, r.delete_on_success, r.delete_on_error);
		
		-- Update the record
		UPDATE csr.automated_import_class_step
		   SET auto_imp_fileread_ftp_id		= v_auto_imp_fileread_ftp_id
		 WHERE automated_import_class_sid	= r.automated_import_class_sid
		   AND step_number					= r.step_number;
		
	END LOOP;
END;
/

ALTER TABLE csr.automated_import_class_step
DROP CONSTRAINT fk_cms_imp_file_io_proto_id;
DROP TABLE csr.file_io_protocol;
ALTER TABLE CSR.automated_import_class_step
DROP COLUMN file_io_protocol_id CASCADE CONSTRAINTS;

ALTER TABLE csr.automated_import_class_step
ADD CONSTRAINT fk_auto_imp_proto_ftp_id FOREIGN KEY (app_sid, auto_imp_fileread_ftp_id) REFERENCES csr.auto_imp_fileread_ftp(app_sid, auto_imp_fileread_ftp_id);

-- DB reader
CREATE TABLE csr.auto_imp_fileread_db (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	auto_imp_fileread_db_id			NUMBER(10) NOT NULL,
	filedata_sp						VARCHAR(255),
	CONSTRAINT pk_auto_imp_fileread_db PRIMARY KEY (app_sid, auto_imp_fileread_db_id)
);

CREATE SEQUENCE csr.auto_imp_fileread_db_id_seq
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20;

ALTER TABLE csr.automated_import_class_step
ADD auto_imp_fileread_db_id NUMBER(10);

-- Move the contents of the existing steps to FTP settings table
DECLARE
	v_auto_imp_fileread_db_id	NUMBER;
BEGIN
	FOR r IN (
		SELECT cics.app_sid, cic.automated_import_class_sid, cics.step_number, filedata_sp
		  FROM csr.automated_import_class_step cics
		  JOIN csr.automated_import_class cic ON cics.automated_import_class_sid = cic.automated_import_class_sid
		 WHERE filedata_sp IS NOT NULL
	)
	LOOP
		SELECT csr.auto_imp_fileread_db_id_seq.nextval
		  INTO v_auto_imp_fileread_db_id
		  FROM dual;
			
		-- Create the new profile
		INSERT INTO csr.auto_imp_fileread_db
			(app_sid, auto_imp_fileread_db_id, filedata_sp)
		VALUES
			(r.app_sid, v_auto_imp_fileread_db_id, r.filedata_sp);
		
		-- Update the record
		UPDATE csr.AUTOMATED_IMPORT_CLASS_step
		   SET auto_imp_fileread_db_id 		= v_auto_imp_fileread_db_id
		 WHERE automated_import_class_sid 	= r.automated_import_class_sid
		   AND step_number			= r.step_number;
		
	END LOOP;
END;
/

ALTER TABLE csr.automated_import_class_step
ADD CONSTRAINT fk_auto_imp_proto_db_id FOREIGN KEY (app_sid, auto_imp_fileread_db_id) REFERENCES csr.auto_imp_fileread_db(app_sid, auto_imp_fileread_db_id);


-- Drop all the old columns
ALTER TABLE csr.automated_import_class_step DROP COLUMN payload_path;
ALTER TABLE csr.automated_import_class_step DROP COLUMN ftp_url;
ALTER TABLE csr.automated_import_class_step DROP COLUMN ftp_secure_creds;
ALTER TABLE csr.automated_import_class_step DROP COLUMN ftp_fingerprint;
ALTER TABLE csr.automated_import_class_step DROP COLUMN ftp_username;
ALTER TABLE csr.automated_import_class_step DROP COLUMN ftp_password;
ALTER TABLE csr.automated_import_class_step DROP COLUMN ftp_port_number;
ALTER TABLE csr.automated_import_class_step DROP COLUMN file_mask;
ALTER TABLE csr.automated_import_class_step DROP COLUMN sort_by;
ALTER TABLE csr.automated_import_class_step DROP COLUMN sort_by_direction;
ALTER TABLE csr.automated_import_class_step DROP COLUMN ftp_profile_id CASCADE CONSTRAINTS;
ALTER TABLE csr.automated_import_class_step DROP COLUMN move_to_path_on_success CASCADE CONSTRAINTS;
ALTER TABLE csr.automated_import_class_step DROP COLUMN move_to_path_on_error CASCADE CONSTRAINTS;
ALTER TABLE csr.automated_import_class_step DROP COLUMN delete_on_success CASCADE CONSTRAINTS;
ALTER TABLE csr.automated_import_class_step DROP COLUMN delete_on_error CASCADE CONSTRAINTS;
ALTER TABLE csr.automated_import_class_step DROP COLUMN filedata_sp CASCADE CONSTRAINTS;

--Put check constraints in so that relevant settings entry exists for chosen filereader
ALTER TABLE csr.automated_import_class_step
ADD CONSTRAINT ck_auto_imp_fileread_ftp_id CHECK (fileread_plugin_id != 1 OR auto_imp_fileread_ftp_id IS NOT NULL);
ALTER TABLE csr.automated_import_class_step
ADD CONSTRAINT ck_auto_imp_fileread_db_id CHECK (fileread_plugin_id != 2 OR auto_imp_fileread_db_id IS NOT NULL);

-- Drop unused column
ALTER TABLE csr.automated_import_class
DROP COLUMN helper_pkg;

-- Update the plugin
UPDATE csr.batch_job_type
   SET description = 'Automated import',
       plugin_name = 'automated-import'
 WHERE batch_job_type_id = 13;
 
-- Time stamp log messages
ALTER TABLE csr.auto_impexp_instance_msg
ADD msg_dtm DATE;

-- Time stamp existing messages with the start dtm of the instance they apply to
UPDATE csr.auto_impexp_instance_msg msg
   SET msg_dtm = (
		SELECT bj.requested_dtm
		  FROM csr.auto_import_message_map mm
		  JOIN csr.automated_import_instance i ON mm.import_instance_id = i.automated_import_instance_id
		  JOIN csr.batch_job bj ON bj.batch_job_id = i.batch_job_id
		 WHERE mm.message_id = msg.message_id
   )
 WHERE EXISTS ( 
	SELECT 1 
	  FROM CSR.auto_import_message_map mm
	 WHERE mm.message_id = msg.message_id
);
UPDATE csr.auto_impexp_instance_msg msg
   SET msg_dtm = (
      SELECT bj.requested_dtm
        FROM csr.auto_export_message_map mm
        JOIN csr.automated_export_instance e on mm.export_instance_id = e.automated_export_instance_id
        JOIN csr.batch_job bj on bj.batch_job_id = e.batch_job_id
       WHERE mm.message_id = msg.message_id
   )
 WHERE EXISTS ( 
	SELECT 1 
	  FROM CSR.auto_export_message_map mm
	 WHERE mm.message_id = msg.message_id
);
-- Just in case; Use a random Dtm, so we can make the column nullable. Utlimately anything being updated here
-- can't have a matching instance and therefore isn't accessible anyway...
UPDATE CSR.auto_impexp_instance_msg
   SET msg_dtm = DATE '1970-01-01'
 WHERE msg_dtm IS NULL;
 
ALTER TABLE csr.auto_impexp_instance_msg
MODIFY msg_dtm NOT NULL;

-- Update the securable object classes
UPDATE security.securable_object_class
   SET class_name = 'CSRAutomatedImport',
       helper_pkg = 'crs.automated_import_pkg'
 WHERE class_name = 'CSRCmsDataImport';
 
UPDATE security.securable_object_class
   SET class_name = 'CSRAutomatedExport',
       helper_pkg = 'crs.automated_export_pkg'
 WHERE class_name = 'AutomatedExport';

-- Alter the DB scheduler

-- Drop the old jobs. Try and drop in both csr and UPD because of issues with the latest scripts. Live should both be in csr, but local, etc..
BEGIN
  DBMS_SCHEDULER.DROP_JOB (job_name => 'csr.CMSDATAIMPORT');
EXCEPTION
  when OTHERS then
    null;
END;
/
BEGIN
  DBMS_SCHEDULER.DROP_JOB (job_name => 'upd.CMSDATAIMPORT');
EXCEPTION
  when OTHERS then
    null;
END;
/
BEGIN
  DBMS_SCHEDULER.DROP_JOB (job_name => 'csr.AUTOMATEDEXPORT');
EXCEPTION
  when OTHERS then
    null;
END;
/
BEGIN
  DBMS_SCHEDULER.DROP_JOB (job_name => 'upd.AUTOMATEDEXPORT');
EXCEPTION
  when OTHERS then
    null;
END;
/

BEGIN

  DBMS_SCHEDULER.CREATE_JOB (
    job_name        => 'csr.AutomatedExportImport',
    job_type        => 'PLSQL_BLOCK',
    job_action      => '   
          BEGIN
          security.user_pkg.logonadmin();
          csr.automated_export_import_pkg.ScheduleRun();
          commit;
          END;
    ',
	job_class       => 'low_priority_job',
	start_date      => to_timestamp_tz('2015/02/24 00:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
	repeat_interval => 'FREQ=HOURLY',
	enabled         => TRUE,
	auto_drop       => FALSE,
	comments        => 'Schedule for automated export import framework. Check for new imports and exports to queue in batch jobs.');
END;
/

-- Change the menus and web resources
BEGIN
	FOR r IN (
		SELECT m.sid_id, m.description, m.action, c.host
		  FROM security.menu m
		  JOIN security.securable_object so ON m.sid_id = so.sid_id
		  JOIN csr.customer c on c.app_sid = so.application_sid_id
		 WHERE lower(action) like '/csr/site/cmsdataimp%'
	)
	LOOP
		security.user_pkg.logonadmin(r.host);
		DBMS_OUTPUT.PUT_LINE('CHANGING ACTION ON '||r.description||' on '||r.host||' sid '||r.sid_id);
		security.menu_pkg.SetMenuAction(SYS_CONTEXT('SECURITY', 'ACT'), r.sid_id, REPLACE(LOWER(r.action), '/csr/site/cmsdataimp', '/csr/site/automatedExportImport'));
		-- Change the description too, but only if the client hasn't done so already
		IF lower(r.description) = 'scheduled imports' THEN
		  security.menu_pkg.SetMenuDescription(SYS_CONTEXT('SECURITY', 'ACT'), r.sid_id, 'Scheduled exports and imports');
		  DBMS_OUTPUT.PUT_LINE('ALSO CHANGING DESC');
		END IF;
	END LOOP;
	security.user_pkg.logonadmin();
END;
/
BEGIN
	FOR r IN (
		SELECT wr.sid_id, wr.path, c.host
		  FROM security.web_resource wr
		  JOIN security.securable_object so ON wr.sid_id = so.sid_id
		  JOIN csr.customer c on c.app_sid = so.application_sid_id
		 WHERE lower(wr.path) = '/csr/site/cmsdataimp'
	)
	LOOP
		security.user_pkg.logonadmin(r.host);
		DBMS_OUTPUT.PUT_LINE('RENAMING '||r.path||' on '||r.host||' sid '||r.sid_id);
		security.securableobject_pkg.RenameSO(SYS_CONTEXT('SECURITY', 'ACT'), r.sid_id, 'automatedExportImport');
	END LOOP;
	security.user_pkg.logonadmin();
END;
/
BEGIN
	FOR r IN (
		SELECT so.sid_id, so.name, c.host
		  FROM security.securable_object so
		  JOIN csr.customer c on c.app_sid = so.application_sid_id
		 WHERE so.CLASS_ID 		= 4
		   AND LOWER(so.name) 	= 'cmsdataimports'
		   AND so.parent_sid_id	= application_sid_id --security.security_pkg.SO_CONTAINER
	)
	LOOP
		security.user_pkg.logonadmin(r.host);
		DBMS_OUTPUT.PUT_LINE('RENAMING '||r.name||' on '||r.host);
		security.securableobject_pkg.RenameSO(SYS_CONTEXT('SECURITY', 'ACT'), r.sid_id, 'AutomatedImports');
	END LOOP;
	security.user_pkg.logonadmin();
END;
/
-- Update the enables
UPDATE csr.module 
   SET 	module_name	= 'Automated export import framework',
		enable_sp 	= 'EnableAutomatedExportImport',
		description = 'Enables the automated export/import framework. Pages, menus, capabilities, etc'
 WHERE LOWER(module_name) = 'cms data import';

DELETE FROM csr.module
WHERE LOWER(module_name) = 'automated exports';

-- Old, unneeded tables
DROP TABLE CSR.automated_export_alias;
DROP TABLE CSR.automated_export_ind_columns;
DROP TABLE CSR.automated_export_ind_member;
DROP TABLE CSR.automated_export_inst_files;
DROP TABLE CSR.automated_export_region_member;
DROP TABLE CSR.automated_export_ind_conf;

-- New payload handling for exports
ALTER TABLE csr.automated_export_instance
ADD payload blob;
ALTER TABLE csr.automated_export_instance
ADD payload_filename varchar2(1024);


ALTER TABLE CSR.EXPORT_FEED ADD (ALERT_RECIPIENTS VARCHAR(1024));

ALTER TABLE chain.company ADD (
	DEACTIVATED_DTM					DATE
);

ALTER TABLE csr.qs_campaign ADD (
  SEND_ALERT NUMBER(1) DEFAULT 1 NOT NULL,
  DYNAMIC NUMBER(1) DEFAULT 0 NOT NULL,
  RESEND NUMBER(1) DEFAULT 0 NOT NULL
);

alter table csrimp.ASPEN2_TRANSLATED drop constraint PK_ASPEN2_TRANSLATED;
alter table csrimp.ASPEN2_TRANSLATED add constraint PK_ASPEN2_TRANSLATED  PRIMARY KEY (CSRIMP_SESSION_ID, LANG, ORIGINAL_HASH);

alter table csrimp.ASPEN2_TRANSLATION drop constraint PK_ASPEN2_TRANSLATION;
alter table csrimp.ASPEN2_TRANSLATION add constraint PK_ASPEN2_TRANSLATION  PRIMARY KEY (CSRIMP_SESSION_ID, ORIGINAL_HASH);

alter table csrimp.ASPEN2_TRANSLATION_SET drop constraint PK_ASPEN2_TRANSLATION_SET;
alter table csrimp.ASPEN2_TRANSLATION_SET add constraint PK_ASPEN2_TRANSLATION_SET PRIMARY KEY (CSRIMP_SESSION_ID, LANG);

alter table csrimp.ASPEN2_TRANSLATION_SET_INCL drop constraint PK_ASPEN2_TRANS_SET_INCL;
alter table csrimp.ASPEN2_TRANSLATION_SET_INCL add constraint PK_ASPEN2_TRANS_SET_INCL PRIMARY KEY (CSRIMP_SESSION_ID, LANG, POS);

alter table csrimp.ROUTE add (
	COMPLETED_DTM DATE
);

ALTER TABLE csr.section ADD (
	disable_general_attachments	NUMBER(1, 0)	DEFAULT 0 NOT NULL
);

ALTER TABLE csrimp.section ADD (
	disable_general_attachments	NUMBER(1, 0)	NULL
);

UPDATE csrimp.section SET disable_general_attachments = 0;

ALTER TABLE csrimp.section MODIFY disable_general_attachments NOT NULL;

CREATE INDEX csr.ix_ind_lookup_key ON csr.ind(app_sid, lookup_key);

BEGIN
	FOR chk IN (
		SELECT * FROM dual WHERE NOT EXISTS (
			SELECT * FROM all_indexes WHERE owner='CSR' AND index_name = 'IDX_NON_COMP_REGION'
		)
	) LOOP
		EXECUTE IMMEDIATE 'create index csr.idx_non_comp_region on csr.NON_COMPLIANCE(APP_SID, REGION_SID)';
	END LOOP;
END;
/

ALTER TABLE csr.customer ADD tplreportperiodextension NUMBER(2) DEFAULT 1 NOT NULL;
ALTER TABLE csrimp.customer ADD tplreportperiodextension NUMBER(2)  DEFAULT 1 NOT NULL;

ALTER TABLE CSRIMP.EXPORT_FEED ADD (ALERT_RECIPIENTS VARCHAR(1024));

ALTER TABLE aspen2.page_error_log_detail ADD (
	FORM				CLOB,
	JSON				CLOB,
	NPSL_SESSION		CLOB);

DROP INDEX CSR.UK_QS_EXPR;
CREATE UNIQUE INDEX CSR.UK_QS_EXPR ON CSR.QUICK_SURVEY_EXPR(APP_SID, SURVEY_SID, SURVEY_VERSION, EXPR_ID);

ALTER TABLE CSR.QUICK_SURVEY_EXPR_ACTION
DROP CONSTRAINT CHK_QS_EXPR_ACTION_TYPE_FK;

ALTER TABLE CSR.QUICK_SURVEY_EXPR DROP COLUMN NAME;
ALTER TABLE CSR.QUICK_SURVEY_EXPR DROP COLUMN DESCRIPTION;

ALTER TABLE CSRIMP.QUICK_SURVEY_EXPR DROP COLUMN NAME;
ALTER TABLE CSRIMP.QUICK_SURVEY_EXPR DROP COLUMN DESCRIPTION;

ALTER TABLE CSRIMP.QUICK_SURVEY_EXPR_ACTION ADD MANDATORY_QUESTION_ID NUMBER(10) NULL;
ALTER TABLE CSRIMP.QUICK_SURVEY_EXPR_ACTION ADD SHOW_PAGE_ID NUMBER(10) NULL;

ALTER TABLE CSR.QUICK_SURVEY_EXPR_ACTION ADD SHOW_PAGE_ID  NUMBER(10) NULL;
ALTER TABLE CSR.QUICK_SURVEY_EXPR_ACTION ADD CONSTRAINT QS_EA_SHOW_PAGE_QUESTION 
    FOREIGN KEY (APP_SID, SHOW_PAGE_ID, SURVEY_VERSION) REFERENCES CSR.QUICK_SURVEY_QUESTION (APP_SID, QUESTION_ID, SURVEY_VERSION);


ALTER TABLE CSR.QUICK_SURVEY_EXPR_ACTION
ADD CONSTRAINT CHK_QS_EXPR_ACTION_TYPE_FK CHECK (
	(ACTION_TYPE = 'nc' AND QS_EXPR_NON_COMPL_ACTION_ID IS NOT NULL
	  AND QS_EXPR_MSG_ACTION_ID IS NULL AND SHOW_QUESTION_ID IS NULL
	  AND MANDATORY_QUESTION_ID IS NULL AND SHOW_PAGE_ID IS NULL)
	OR
	(ACTION_TYPE = 'msg' AND QS_EXPR_NON_COMPL_ACTION_ID IS NULL
	  AND QS_EXPR_MSG_ACTION_ID IS NOT NULL AND SHOW_QUESTION_ID IS NULL
	  AND MANDATORY_QUESTION_ID IS NULL AND SHOW_PAGE_ID IS NULL)
	OR
	(ACTION_TYPE = 'show_q' AND QS_EXPR_NON_COMPL_ACTION_ID IS NULL
	  AND QS_EXPR_MSG_ACTION_ID IS NULL AND SHOW_QUESTION_ID IS NOT NULL
	  AND MANDATORY_QUESTION_ID IS NULL AND SHOW_PAGE_ID IS NULL)
	OR
	(ACTION_TYPE = 'mand_q' AND QS_EXPR_NON_COMPL_ACTION_ID IS NULL
	  AND QS_EXPR_MSG_ACTION_ID IS NULL AND SHOW_QUESTION_ID IS NULL
	  AND MANDATORY_QUESTION_ID IS NOT NULL AND SHOW_PAGE_ID IS NULL)
	OR
	(ACTION_TYPE = 'show_p' AND QS_EXPR_NON_COMPL_ACTION_ID IS NULL
	  AND QS_EXPR_MSG_ACTION_ID IS NULL AND SHOW_QUESTION_ID IS NULL
	  AND MANDATORY_QUESTION_ID IS NULL AND SHOW_PAGE_ID IS NOT NULL)
  );

ALTER TABLE chain.saved_filter_aggregation_type ADD (
	customer_aggregate_type_id		NUMBER(10),
	CONSTRAINT fk_svd_fil_agg_typ_cus_agg_typ FOREIGN KEY (app_sid, customer_aggregate_type_id)
		REFERENCES chain.customer_aggregate_type (app_sid, customer_aggregate_type_id)
);

-- create entries for all current agg types
BEGIN
	security.user_pkg.LogonAdmin;	
	
	-- cms agg types
	INSERT INTO chain.customer_aggregate_type (app_sid, card_group_id, customer_aggregate_type_id, cms_aggregate_type_id)
		 SELECT app_sid, 43, chain.customer_aggregate_type_id_seq.NEXTVAL, cms_aggregate_type_id
		   FROM cms.cms_aggregate_type;
		   
	-- numeric region metrics
	INSERT INTO chain.customer_aggregate_type (app_sid, card_group_id, customer_aggregate_type_id, ind_sid)
		 SELECT rtm.app_sid, 44, chain.customer_aggregate_type_id_seq.NEXTVAL, rtm.ind_sid
		   FROM csr.region_type_metric rtm
		   JOIN csr.ind i ON rtm.app_sid = i.app_sid AND rtm.ind_sid = i.ind_sid
		   JOIN csr.measure m ON i.app_sid = m.app_sid AND i.measure_sid = m.measure_sid
		  WHERE m.custom_field IS NULL
		    AND rtm.region_type = 3;
		   
	-- initiative metrics
	INSERT INTO chain.customer_aggregate_type (app_sid, card_group_id, customer_aggregate_type_id, initiative_metric_id)
		 SELECT app_sid, 45, chain.customer_aggregate_type_id_seq.NEXTVAL, initiative_metric_id
		   FROM csr.initiative_metric;
		   
	UPDATE chain.saved_filter_aggregation_type sfag
	   SET customer_aggregate_type_id = (
		SELECT customer_aggregate_type_id
		  FROM chain.customer_aggregate_type cat
		 WHERE sfag.app_sid = cat.app_sid
		   AND (sfag.cms_aggregate_type_id = cat.cms_aggregate_type_id
		    OR sfag.initiative_metric_id = cat.initiative_metric_id
			OR sfag.ind_sid = cat.ind_sid)
	  )
	 WHERE aggregation_type IS NULL;
END;
/

BEGIN
	FOR r IN (
		SELECT constraint_name 
		  FROM all_constraints 
		 WHERE owner='CHAIN' 
		   AND constraint_name='CHK_SVD_FIL_AGG_TYPE' 
		   AND table_name='SAVED_FILTER_AGGREGATION_TYPE'
	) LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE chain.saved_filter_aggregation_type DROP CONSTRAINT chk_svd_fil_agg_type';
	END LOOP;
END;
/
ALTER TABLE chain.saved_filter_aggregation_type ADD CONSTRAINT chk_svd_fil_agg_type
	CHECK ((aggregation_type IS NOT NULL AND customer_aggregate_type_id IS NULL)
	   OR (aggregation_type IS NULL AND customer_aggregate_type_id IS NOT NULL));
	   

ALTER TABLE chain.saved_filter_aggregation_type DROP CONSTRAINT UK_SAVED_FIL_AGGREGATION_TYP;
ALTER TABLE CHAIN.SAVED_FILTER_AGGREGATION_TYPE ADD CONSTRAINT UK_SAVED_FIL_AGGREGATION_TYP
	UNIQUE (APP_SID, SAVED_FILTER_SID, AGGREGATION_TYPE, CUSTOMER_AGGREGATE_TYPE_ID)
;

ALTER TABLE chain.saved_filter_aggregation_type DROP CONSTRAINT fk_svd_fil_agg_typ_cms_agg_typ;
ALTER TABLE chain.saved_filter_aggregation_type DROP CONSTRAINT fk_svd_fil_agg_typ_ind;
ALTER TABLE chain.saved_filter_aggregation_type DROP CONSTRAINT fk_svd_fil_agg_typ_init_metric;
ALTER TABLE chain.saved_filter_aggregation_type DROP COLUMN cms_aggregate_type_id;
ALTER TABLE chain.saved_filter_aggregation_type DROP COLUMN ind_sid;
ALTER TABLE chain.saved_filter_aggregation_type DROP COLUMN initiative_metric_id;


ALTER TABLE csrimp.chain_saved_filter_agg_type ADD (
	customer_aggregate_type_id		NUMBER(10)
);

ALTER TABLE csrimp.chain_saved_filter_agg_type DROP CONSTRAINT chk_svd_fil_agg_type;
ALTER TABLE csrimp.chain_saved_filter_agg_type ADD CONSTRAINT chk_svd_fil_agg_type
	CHECK ((aggregation_type IS NOT NULL AND customer_aggregate_type_id IS NULL)
	   OR (aggregation_type IS NULL AND customer_aggregate_type_id IS NOT NULL));
	   

ALTER TABLE csrimp.chain_saved_filter_agg_type DROP CONSTRAINT UK_CHAIN_SAVED_FIL_AGG_TYP;
ALTER TABLE csrimp.chain_saved_filter_agg_type ADD CONSTRAINT UK_CHAIN_SAVED_FIL_AGG_TYP
	UNIQUE (CSRIMP_SESSION_ID, SAVED_FILTER_SID, AGGREGATION_TYPE, CUSTOMER_AGGREGATE_TYPE_ID)
;

ALTER TABLE csrimp.chain_saved_filter_agg_type DROP COLUMN cms_aggregate_type_id;
ALTER TABLE csrimp.chain_saved_filter_agg_type DROP COLUMN initiative_metric_id;
ALTER TABLE csrimp.chain_saved_filter_agg_type DROP COLUMN ind_sid;

CREATE OR REPLACE TYPE CHAIN.T_FILTER_AGG_TYPE_ROW AS 
	 OBJECT ( 
		CARD_GROUP_ID				NUMBER(10),
		AGGREGATE_TYPE_ID			NUMBER(10),	
		DESCRIPTION 				VARCHAR2(1023),
		FORMAT_MASK					VARCHAR2(255),
		FILTER_PAGE_IND_INTERVAL_ID	NUMBER(10)
	 ); 
/

CREATE OR REPLACE TYPE CHAIN.T_FILTER_AGG_TYPE_TABLE AS 
	TABLE OF CHAIN.T_FILTER_AGG_TYPE_ROW;
/

CREATE OR REPLACE TYPE CHAIN.T_FILTER_AGG_TYPE_THRES_ROW AS 
	 OBJECT ( 
		AGGREGATE_TYPE_ID				NUMBER(10),
		MAX_VALUE						NUMBER(15, 5),	
		LABEL 							VARCHAR2(255),
		ICON_URL						VARCHAR2(255),
		ICON_DATA						BLOB,
		TEXT_COLOUR						NUMBER(10),
		BACKGROUND_COLOUR				NUMBER(10),
		BAR_COLOUR						NUMBER(10)
	 ); 
/

CREATE OR REPLACE TYPE CHAIN.T_FILTER_AGG_TYPE_THRES_TABLE AS 
	TABLE OF CHAIN.T_FILTER_AGG_TYPE_THRES_ROW;
/

DROP INDEX CSR.UK_QS_EXPR;

ALTER TABLE CSRIMP.CHAIN_BU_REL_TIE_COM_TYP DROP COLUMN BUSINESS_RELATIONSHIP_TYPE_ID;

ALTER TABLE cms.debug_ddl_log ADD csrimp_session_id	NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID'); 
ALTER TABLE cms.debug_ddl_log ADD processed_dtm	DATE; 
ALTER TABLE cms.debug_ddl_log ADD CONSTRAINT fk_debug_ddl_log FOREIGN KEY (csrimp_session_id)
	REFERENCES csrimp.csrimp_session (csrimp_session_id)
	ON DELETE CASCADE;

--(auto-gen)add CSRIMP_SESSION_ID tp PK/UC
ALTER TABLE CSRIMP.ASPEN2_TRANSLATED DROP constraint PK_ASPEN2_TRANSLATED DROP INDEX;
ALTER TABLE CSRIMP.ASPEN2_TRANSLATED ADD constraint PK_ASPEN2_TRANSLATED PRIMARY KEY (CSRIMP_SESSION_ID,LANG,ORIGINAL_HASH);
ALTER TABLE CSRIMP.ASPEN2_TRANSLATION DROP constraint PK_ASPEN2_TRANSLATION DROP INDEX;
ALTER TABLE CSRIMP.ASPEN2_TRANSLATION ADD constraint PK_ASPEN2_TRANSLATION PRIMARY KEY (CSRIMP_SESSION_ID,ORIGINAL_HASH);
ALTER TABLE CSRIMP.ASPEN2_TRANSLATION_SET DROP constraint PK_ASPEN2_TRANSLATION_SET DROP INDEX;
ALTER TABLE CSRIMP.ASPEN2_TRANSLATION_SET ADD constraint PK_ASPEN2_TRANSLATION_SET PRIMARY KEY (CSRIMP_SESSION_ID,LANG);
ALTER TABLE CSRIMP.ASPEN2_TRANSLATION_SET_INCL DROP constraint PK_ASPEN2_TRANS_SET_INCL DROP INDEX;
ALTER TABLE CSRIMP.ASPEN2_TRANSLATION_SET_INCL ADD constraint PK_ASPEN2_TRANS_SET_INCL PRIMARY KEY (CSRIMP_SESSION_ID,LANG,POS);
ALTER TABLE CSRIMP.MAP_CHAIN_BUSINE_RELATIO DROP constraint PK_MAP_CHAIN_BUSINE_RELATIO DROP INDEX;
ALTER TABLE CSRIMP.MAP_CHAIN_BUSINE_RELATIO ADD constraint PK_MAP_CHAIN_BUSINE_RELATIO PRIMARY KEY (CSRIMP_SESSION_ID,OLD_BUSINESS_RELATIONSHIP_ID);
ALTER TABLE CSRIMP.MAP_CHAIN_BUSINE_RELATIO DROP constraint UK_MAP_CHAIN_BUSINE_RELATIO DROP INDEX;
ALTER TABLE CSRIMP.MAP_CHAIN_BUSINE_RELATIO ADD constraint UK_MAP_CHAIN_BUSINE_RELATIO UNIQUE (CSRIMP_SESSION_ID,NEW_BUSINESS_RELATIONSHIP_ID);
ALTER TABLE CSRIMP.MAP_CHAIN_BUSIN_REL_TIER DROP constraint PK_MAP_CHAIN_BUSIN_REL_TIER DROP INDEX;
ALTER TABLE CSRIMP.MAP_CHAIN_BUSIN_REL_TIER ADD constraint PK_MAP_CHAIN_BUSIN_REL_TIER PRIMARY KEY (CSRIMP_SESSION_ID,OLD_BUSINESS_REL_TIER_ID);
ALTER TABLE CSRIMP.MAP_CHAIN_BUSIN_REL_TIER DROP constraint UK_MAP_CHAIN_BUSIN_REL_TIER DROP INDEX;
ALTER TABLE CSRIMP.MAP_CHAIN_BUSIN_REL_TIER ADD constraint UK_MAP_CHAIN_BUSIN_REL_TIER UNIQUE (CSRIMP_SESSION_ID,NEW_BUSINESS_REL_TIER_ID);
ALTER TABLE CSRIMP.MAP_CHAIN_BUSIN_REL_TYPE DROP constraint PK_MAP_CHAIN_BUSIN_REL_TYPE DROP INDEX;
ALTER TABLE CSRIMP.MAP_CHAIN_BUSIN_REL_TYPE ADD constraint PK_MAP_CHAIN_BUSIN_REL_TYPE PRIMARY KEY (CSRIMP_SESSION_ID,OLD_BUSINESS_REL_TYPE_ID);
ALTER TABLE CSRIMP.MAP_CHAIN_BUSIN_REL_TYPE DROP constraint UK_MAP_CHAIN_BUSIN_REL_TYPE DROP INDEX;
ALTER TABLE CSRIMP.MAP_CHAIN_BUSIN_REL_TYPE ADD constraint UK_MAP_CHAIN_BUSIN_REL_TYPE UNIQUE (CSRIMP_SESSION_ID,NEW_BUSINESS_REL_TYPE_ID);
ALTER TABLE CSRIMP.MAP_CHAIN_PRODUCT_TYPE DROP constraint PK_MAP_CHAIN_PRODUCT_TYPE DROP INDEX;
ALTER TABLE CSRIMP.MAP_CHAIN_PRODUCT_TYPE ADD constraint PK_MAP_CHAIN_PRODUCT_TYPE PRIMARY KEY (CSRIMP_SESSION_ID,OLD_PRODUCT_TYPE_ID);
ALTER TABLE CSRIMP.MAP_CHAIN_PRODUCT_TYPE DROP constraint UK_MAP_CHAIN_PRODUCT_TYPE DROP INDEX;
ALTER TABLE CSRIMP.MAP_CHAIN_PRODUCT_TYPE ADD constraint UK_MAP_CHAIN_PRODUCT_TYPE UNIQUE (CSRIMP_SESSION_ID,NEW_PRODUCT_TYPE_ID);
ALTER TABLE CSRIMP.MAP_CHEM_CAS_GROUP DROP constraint PK_MAP_CHEM_CAS_GROUP DROP INDEX;
ALTER TABLE CSRIMP.MAP_CHEM_CAS_GROUP ADD constraint PK_MAP_CHEM_CAS_GROUP PRIMARY KEY (CSRIMP_SESSION_ID,OLD_CAS_GROUP_ID);
ALTER TABLE CSRIMP.MAP_CHEM_CAS_GROUP DROP constraint UK_MAP_CHEM_CAS_GROUP DROP INDEX;
ALTER TABLE CSRIMP.MAP_CHEM_CAS_GROUP ADD constraint UK_MAP_CHEM_CAS_GROUP UNIQUE (CSRIMP_SESSION_ID,NEW_CAS_GROUP_ID);
ALTER TABLE CSRIMP.MAP_CHEM_CLASSIFICATION DROP constraint PK_MAP_CHEM_CLASSIFICATION DROP INDEX;
ALTER TABLE CSRIMP.MAP_CHEM_CLASSIFICATION ADD constraint PK_MAP_CHEM_CLASSIFICATION PRIMARY KEY (CSRIMP_SESSION_ID,OLD_CLASSIFICATION_ID);
ALTER TABLE CSRIMP.MAP_CHEM_CLASSIFICATION DROP constraint UK_MAP_CHEM_CLASSIFICATION DROP INDEX;
ALTER TABLE CSRIMP.MAP_CHEM_CLASSIFICATION ADD constraint UK_MAP_CHEM_CLASSIFICATION UNIQUE (CSRIMP_SESSION_ID,NEW_CLASSIFICATION_ID);
ALTER TABLE CSRIMP.MAP_CHEM_MANUFACTURER DROP constraint PK_MAP_CHEM_MANUFACTURER DROP INDEX;
ALTER TABLE CSRIMP.MAP_CHEM_MANUFACTURER ADD constraint PK_MAP_CHEM_MANUFACTURER PRIMARY KEY (CSRIMP_SESSION_ID,OLD_MANUFACTURER_ID);
ALTER TABLE CSRIMP.MAP_CHEM_MANUFACTURER DROP constraint UK_MAP_CHEM_MANUFACTURER DROP INDEX;
ALTER TABLE CSRIMP.MAP_CHEM_MANUFACTURER ADD constraint UK_MAP_CHEM_MANUFACTURER UNIQUE (CSRIMP_SESSION_ID,NEW_MANUFACTURER_ID);
ALTER TABLE CSRIMP.MAP_CHEM_SUBSTANCE DROP constraint PK_MAP_CHEM_SUBSTANCE DROP INDEX;
ALTER TABLE CSRIMP.MAP_CHEM_SUBSTANCE ADD constraint PK_MAP_CHEM_SUBSTANCE PRIMARY KEY (CSRIMP_SESSION_ID,OLD_SUBSTANCE_ID);
ALTER TABLE CSRIMP.MAP_CHEM_SUBSTANCE DROP constraint UK_MAP_CHEM_SUBSTANCE DROP INDEX;
ALTER TABLE CSRIMP.MAP_CHEM_SUBSTANCE ADD constraint UK_MAP_CHEM_SUBSTANCE UNIQUE (CSRIMP_SESSION_ID,NEW_SUBSTANCE_ID);
ALTER TABLE CSRIMP.MAP_CHEM_SUBSTANCE_FILE DROP constraint PK_MAP_CHEM_SUBSTANCE_FILE DROP INDEX;
ALTER TABLE CSRIMP.MAP_CHEM_SUBSTANCE_FILE ADD constraint PK_MAP_CHEM_SUBSTANCE_FILE PRIMARY KEY (CSRIMP_SESSION_ID,OLD_SUBSTANCE_FILE_ID);
ALTER TABLE CSRIMP.MAP_CHEM_SUBSTANCE_FILE DROP constraint UK_MAP_CHEM_SUBSTANCE_FILE DROP INDEX;
ALTER TABLE CSRIMP.MAP_CHEM_SUBSTANCE_FILE ADD constraint UK_MAP_CHEM_SUBSTANCE_FILE UNIQUE (CSRIMP_SESSION_ID,NEW_SUBSTANCE_FILE_ID);
ALTER TABLE CSRIMP.MAP_CHEM_SUBST_PROCE_USE DROP constraint PK_MAP_CHEM_SUBST_PROCE_USE DROP INDEX;
ALTER TABLE CSRIMP.MAP_CHEM_SUBST_PROCE_USE ADD constraint PK_MAP_CHEM_SUBST_PROCE_USE PRIMARY KEY (CSRIMP_SESSION_ID,OLD_SUBSTANCE_PROCESS_USE_ID);
ALTER TABLE CSRIMP.MAP_CHEM_SUBST_PROCE_USE DROP constraint UK_MAP_CHEM_SUBST_PROCE_USE DROP INDEX;
ALTER TABLE CSRIMP.MAP_CHEM_SUBST_PROCE_USE ADD constraint UK_MAP_CHEM_SUBST_PROCE_USE UNIQUE (CSRIMP_SESSION_ID,NEW_SUBSTANCE_PROCESS_USE_ID);
ALTER TABLE CSRIMP.MAP_CHEM_SUB_AUDIT_LOG DROP constraint PK_MAP_CHEM_SUB_AUDIT_LOG DROP INDEX;
ALTER TABLE CSRIMP.MAP_CHEM_SUB_AUDIT_LOG ADD constraint PK_MAP_CHEM_SUB_AUDIT_LOG PRIMARY KEY (CSRIMP_SESSION_ID,OLD_SUB_AUDIT_LOG_ID);
ALTER TABLE CSRIMP.MAP_CHEM_SUB_AUDIT_LOG DROP constraint UK_MAP_CHEM_SUB_AUDIT_LOG DROP INDEX;
ALTER TABLE CSRIMP.MAP_CHEM_SUB_AUDIT_LOG ADD constraint UK_MAP_CHEM_SUB_AUDIT_LOG UNIQUE (CSRIMP_SESSION_ID,NEW_SUB_AUDIT_LOG_ID);
ALTER TABLE CSRIMP.MAP_CHEM_SUB_PRO_USE_CHA DROP constraint PK_MAP_CHEM_SUB_PRO_USE_CHA DROP INDEX;
ALTER TABLE CSRIMP.MAP_CHEM_SUB_PRO_USE_CHA ADD constraint PK_MAP_CHEM_SUB_PRO_USE_CHA PRIMARY KEY (CSRIMP_SESSION_ID,OLD_SUBST_PROC_USE_CHANGE_ID);
ALTER TABLE CSRIMP.MAP_CHEM_SUB_PRO_USE_CHA DROP constraint UK_MAP_CHEM_SUB_PRO_USE_CHA DROP INDEX;
ALTER TABLE CSRIMP.MAP_CHEM_SUB_PRO_USE_CHA ADD constraint UK_MAP_CHEM_SUB_PRO_USE_CHA UNIQUE (CSRIMP_SESSION_ID,NEW_SUBST_PROC_USE_CHANGE_ID);
ALTER TABLE CSRIMP.MAP_CHEM_SUB_PRO_USE_FIL DROP constraint PK_MAP_CHEM_SUB_PRO_USE_FIL DROP INDEX;
ALTER TABLE CSRIMP.MAP_CHEM_SUB_PRO_USE_FIL ADD constraint PK_MAP_CHEM_SUB_PRO_USE_FIL PRIMARY KEY (CSRIMP_SESSION_ID,OLD_SUBST_PROC_USE_FILE_ID);
ALTER TABLE CSRIMP.MAP_CHEM_SUB_PRO_USE_FIL DROP constraint UK_MAP_CHEM_SUB_PRO_USE_FIL DROP INDEX;
ALTER TABLE CSRIMP.MAP_CHEM_SUB_PRO_USE_FIL ADD constraint UK_MAP_CHEM_SUB_PRO_USE_FIL UNIQUE (CSRIMP_SESSION_ID,NEW_SUBST_PROC_USE_FILE_ID);
ALTER TABLE CSRIMP.MAP_CHEM_SUB_RGN_PRO_PRO DROP constraint PK_MAP_CHEM_SUB_RGN_PRO_PRO DROP INDEX;
ALTER TABLE CSRIMP.MAP_CHEM_SUB_RGN_PRO_PRO ADD constraint PK_MAP_CHEM_SUB_RGN_PRO_PRO PRIMARY KEY (CSRIMP_SESSION_ID,OLD_SUBST_RGN_PROC_PROCESS_ID);
ALTER TABLE CSRIMP.MAP_CHEM_SUB_RGN_PRO_PRO DROP constraint UK_MAP_CHEM_SUB_RGN_PRO_PRO DROP INDEX;
ALTER TABLE CSRIMP.MAP_CHEM_SUB_RGN_PRO_PRO ADD constraint UK_MAP_CHEM_SUB_RGN_PRO_PRO UNIQUE (CSRIMP_SESSION_ID,NEW_SUBST_RGN_PROC_PROCESS_ID);
ALTER TABLE CSRIMP.MAP_CHEM_SU_PR_CA_DE_CHG DROP constraint PK_MAP_CHEM_SU_PR_CA_DE_CHG DROP INDEX;
ALTER TABLE CSRIMP.MAP_CHEM_SU_PR_CA_DE_CHG ADD constraint PK_MAP_CHEM_SU_PR_CA_DE_CHG PRIMARY KEY (CSRIMP_SESSION_ID,OLD_SUBST_PROC_CAS_DEST_CHG_ID);
ALTER TABLE CSRIMP.MAP_CHEM_SU_PR_CA_DE_CHG DROP constraint UK_MAP_CHEM_SU_PR_CA_DE_CHG DROP INDEX;
ALTER TABLE CSRIMP.MAP_CHEM_SU_PR_CA_DE_CHG ADD constraint UK_MAP_CHEM_SU_PR_CA_DE_CHG UNIQUE (CSRIMP_SESSION_ID,NEW_SUBST_PROC_CAS_DEST_CHG_ID);
ALTER TABLE CSRIMP.MAP_CHEM_USAGE DROP constraint PK_MAP_CHEM_USAGE DROP INDEX;
ALTER TABLE CSRIMP.MAP_CHEM_USAGE ADD constraint PK_MAP_CHEM_USAGE PRIMARY KEY (CSRIMP_SESSION_ID,OLD_USAGE_ID);
ALTER TABLE CSRIMP.MAP_CHEM_USAGE DROP constraint UK_MAP_CHEM_USAGE DROP INDEX;
ALTER TABLE CSRIMP.MAP_CHEM_USAGE ADD constraint UK_MAP_CHEM_USAGE UNIQUE (CSRIMP_SESSION_ID,NEW_USAGE_ID);
ALTER TABLE CSRIMP.MAP_CHEM_USAGE_AUDIT_LOG DROP constraint PK_MAP_CHEM_USAGE_AUDIT_LOG DROP INDEX;
ALTER TABLE CSRIMP.MAP_CHEM_USAGE_AUDIT_LOG ADD constraint PK_MAP_CHEM_USAGE_AUDIT_LOG PRIMARY KEY (CSRIMP_SESSION_ID,OLD_USAGE_AUDIT_LOG_ID);
ALTER TABLE CSRIMP.MAP_CHEM_USAGE_AUDIT_LOG DROP constraint UK_MAP_CHEM_USAGE_AUDIT_LOG DROP INDEX;
ALTER TABLE CSRIMP.MAP_CHEM_USAGE_AUDIT_LOG ADD constraint UK_MAP_CHEM_USAGE_AUDIT_LOG UNIQUE (CSRIMP_SESSION_ID,NEW_USAGE_AUDIT_LOG_ID);
ALTER TABLE CSRIMP.MAP_CT_BREAKDOWN DROP constraint PK_MAP_CT_BREAKDOWN DROP INDEX;
ALTER TABLE CSRIMP.MAP_CT_BREAKDOWN ADD constraint PK_MAP_CT_BREAKDOWN PRIMARY KEY (CSRIMP_SESSION_ID,OLD_BREAKDOWN_ID);
ALTER TABLE CSRIMP.MAP_CT_BREAKDOWN DROP constraint UK_MAP_CT_BREAKDOWN DROP INDEX;
ALTER TABLE CSRIMP.MAP_CT_BREAKDOWN ADD constraint UK_MAP_CT_BREAKDOWN UNIQUE (CSRIMP_SESSION_ID,NEW_BREAKDOWN_ID);
ALTER TABLE CSRIMP.MAP_CT_BREAKDOWN_GROUP DROP constraint PK_MAP_CT_BREAKDOWN_GROUP DROP INDEX;
ALTER TABLE CSRIMP.MAP_CT_BREAKDOWN_GROUP ADD constraint PK_MAP_CT_BREAKDOWN_GROUP PRIMARY KEY (CSRIMP_SESSION_ID,OLD_BREAKDOWN_GROUP_ID);
ALTER TABLE CSRIMP.MAP_CT_BREAKDOWN_GROUP DROP constraint UK_MAP_CT_BREAKDOWN_GROUP DROP INDEX;
ALTER TABLE CSRIMP.MAP_CT_BREAKDOWN_GROUP ADD constraint UK_MAP_CT_BREAKDOWN_GROUP UNIQUE (CSRIMP_SESSION_ID,NEW_BREAKDOWN_GROUP_ID);
ALTER TABLE CSRIMP.MAP_CT_BREAKDOWN_TYPE DROP constraint PK_MAP_CT_BREAKDOWN_TYPE DROP INDEX;
ALTER TABLE CSRIMP.MAP_CT_BREAKDOWN_TYPE ADD constraint PK_MAP_CT_BREAKDOWN_TYPE PRIMARY KEY (CSRIMP_SESSION_ID,OLD_BREAKDOWN_TYPE_ID);
ALTER TABLE CSRIMP.MAP_CT_BREAKDOWN_TYPE DROP constraint UK_MAP_CT_BREAKDOWN_TYPE DROP INDEX;
ALTER TABLE CSRIMP.MAP_CT_BREAKDOWN_TYPE ADD constraint UK_MAP_CT_BREAKDOWN_TYPE UNIQUE (CSRIMP_SESSION_ID,NEW_BREAKDOWN_TYPE_ID);
ALTER TABLE CSRIMP.MAP_CT_BT_TRIP_ENTRY DROP constraint PK_MAP_CT_BT_TRIP_ENTRY DROP INDEX;
ALTER TABLE CSRIMP.MAP_CT_BT_TRIP_ENTRY ADD constraint PK_MAP_CT_BT_TRIP_ENTRY PRIMARY KEY (CSRIMP_SESSION_ID,OLD_BT_TRIP_ENTRY_ID);
ALTER TABLE CSRIMP.MAP_CT_BT_TRIP_ENTRY DROP constraint UK_MAP_CT_BT_TRIP_ENTRY DROP INDEX;
ALTER TABLE CSRIMP.MAP_CT_BT_TRIP_ENTRY ADD constraint UK_MAP_CT_BT_TRIP_ENTRY UNIQUE (CSRIMP_SESSION_ID,NEW_BT_TRIP_ENTRY_ID);
ALTER TABLE CSRIMP.MAP_CT_EC_QUESTIONNAIRE DROP constraint PK_MAP_CT_EC_QUESTIONNAIRE DROP INDEX;
ALTER TABLE CSRIMP.MAP_CT_EC_QUESTIONNAIRE ADD constraint PK_MAP_CT_EC_QUESTIONNAIRE PRIMARY KEY (CSRIMP_SESSION_ID,OLD_EC_QUESTIONNAIRE_ID);
ALTER TABLE CSRIMP.MAP_CT_EC_QUESTIONNAIRE DROP constraint UK_MAP_CT_EC_QUESTIONNAIRE DROP INDEX;
ALTER TABLE CSRIMP.MAP_CT_EC_QUESTIONNAIRE ADD constraint UK_MAP_CT_EC_QUESTIONNAIRE UNIQUE (CSRIMP_SESSION_ID,NEW_EC_QUESTIONNAIRE_ID);
ALTER TABLE CSRIMP.MAP_CT_EC_QUESTIONNA_ANS DROP constraint PK_MAP_CT_EC_QUESTIONNA_ANS DROP INDEX;
ALTER TABLE CSRIMP.MAP_CT_EC_QUESTIONNA_ANS ADD constraint PK_MAP_CT_EC_QUESTIONNA_ANS PRIMARY KEY (CSRIMP_SESSION_ID,OLD_EC_QUESTIONNAIRE_ANS_ID);
ALTER TABLE CSRIMP.MAP_CT_EC_QUESTIONNA_ANS DROP constraint UK_MAP_CT_EC_QUESTIONNA_ANS DROP INDEX;
ALTER TABLE CSRIMP.MAP_CT_EC_QUESTIONNA_ANS ADD constraint UK_MAP_CT_EC_QUESTIONNA_ANS UNIQUE (CSRIMP_SESSION_ID,NEW_EC_QUESTIONNAIRE_ANS_ID);
ALTER TABLE CSRIMP.MAP_CT_PS_ITEM DROP constraint PK_MAP_CT_PS_ITEM DROP INDEX;
ALTER TABLE CSRIMP.MAP_CT_PS_ITEM ADD constraint PK_MAP_CT_PS_ITEM PRIMARY KEY (CSRIMP_SESSION_ID,OLD_PS_ITEM_ID);
ALTER TABLE CSRIMP.MAP_CT_PS_ITEM DROP constraint UK_MAP_CT_PS_ITEM DROP INDEX;
ALTER TABLE CSRIMP.MAP_CT_PS_ITEM ADD constraint UK_MAP_CT_PS_ITEM UNIQUE (CSRIMP_SESSION_ID,NEW_PS_ITEM_ID);
ALTER TABLE CSRIMP.MAP_CT_SUPPLIER DROP constraint PK_MAP_CT_SUPPLIER DROP INDEX;
ALTER TABLE CSRIMP.MAP_CT_SUPPLIER ADD constraint PK_MAP_CT_SUPPLIER PRIMARY KEY (CSRIMP_SESSION_ID,OLD_SUPPLIER_ID);
ALTER TABLE CSRIMP.MAP_CT_SUPPLIER DROP constraint UK_MAP_CT_SUPPLIER DROP INDEX;
ALTER TABLE CSRIMP.MAP_CT_SUPPLIER ADD constraint UK_MAP_CT_SUPPLIER UNIQUE (CSRIMP_SESSION_ID,NEW_SUPPLIER_ID);
ALTER TABLE CSRIMP.MAP_CT_SUPPLIER_CONTACT DROP constraint PK_MAP_CT_SUPPLIER_CONTACT DROP INDEX;
ALTER TABLE CSRIMP.MAP_CT_SUPPLIER_CONTACT ADD constraint PK_MAP_CT_SUPPLIER_CONTACT PRIMARY KEY (CSRIMP_SESSION_ID,OLD_SUPPLIER_CONTACT_ID);
ALTER TABLE CSRIMP.MAP_CT_SUPPLIER_CONTACT DROP constraint UK_MAP_CT_SUPPLIER_CONTACT DROP INDEX;
ALTER TABLE CSRIMP.MAP_CT_SUPPLIER_CONTACT ADD constraint UK_MAP_CT_SUPPLIER_CONTACT UNIQUE (CSRIMP_SESSION_ID,NEW_SUPPLIER_CONTACT_ID);
ALTER TABLE CSRIMP.MAP_CUSTOMER_FLOW_CAP DROP constraint PK_MAP_CUSTOMER_FLOW_CAP DROP INDEX;
ALTER TABLE CSRIMP.MAP_CUSTOMER_FLOW_CAP ADD constraint PK_MAP_CUSTOMER_FLOW_CAP PRIMARY KEY (CSRIMP_SESSION_ID,OLD_CUSTOMER_FLOW_CAP_ID);
ALTER TABLE CSRIMP.MAP_CUSTOMER_FLOW_CAP DROP constraint UK_MAP_CUSTOMER_FLOW_CAP DROP INDEX;
ALTER TABLE CSRIMP.MAP_CUSTOMER_FLOW_CAP ADD constraint UK_MAP_CUSTOMER_FLOW_CAP UNIQUE (CSRIMP_SESSION_ID,NEW_CUSTOMER_FLOW_CAP_ID);
ALTER TABLE CSRIMP.MAP_DELEGATION_LAYOUT DROP constraint PK_MAP_DELEGATION_LAYOUT DROP INDEX;
ALTER TABLE CSRIMP.MAP_DELEGATION_LAYOUT ADD constraint PK_MAP_DELEGATION_LAYOUT PRIMARY KEY (CSRIMP_SESSION_ID,OLD_DELEGATION_LAYOUT_ID);
ALTER TABLE CSRIMP.MAP_DELEGATION_LAYOUT DROP constraint UK_MAP_DELEGATION_LAYOUT DROP INDEX;
ALTER TABLE CSRIMP.MAP_DELEGATION_LAYOUT ADD constraint UK_MAP_DELEGATION_LAYOUT UNIQUE (CSRIMP_SESSION_ID,NEW_DELEGATION_LAYOUT_ID);
ALTER TABLE CSRIMP.MAP_IA_TYPE_SURVEY DROP constraint PK_MAP_IA_TYPE_SURVEY DROP INDEX;
ALTER TABLE CSRIMP.MAP_IA_TYPE_SURVEY ADD constraint PK_MAP_IA_TYPE_SURVEY PRIMARY KEY (CSRIMP_SESSION_ID,OLD_IA_TYPE_SURVEY_ID);
ALTER TABLE CSRIMP.MAP_IA_TYPE_SURVEY DROP constraint UK_MAP_IA_TYPE_SURVEY DROP INDEX;
ALTER TABLE CSRIMP.MAP_IA_TYPE_SURVEY ADD constraint UK_MAP_IA_TYPE_SURVEY UNIQUE (CSRIMP_SESSION_ID,NEW_IA_TYPE_SURVEY_ID);
ALTER TABLE CSRIMP.MAP_IA_TYPE_SURVEY_GROUP DROP constraint PK_MAP_IA_TYPE_SURVEY_GROUP DROP INDEX;
ALTER TABLE CSRIMP.MAP_IA_TYPE_SURVEY_GROUP ADD constraint PK_MAP_IA_TYPE_SURVEY_GROUP PRIMARY KEY (CSRIMP_SESSION_ID,OLD_IA_TYPE_SURVEY_GROUP_ID);
ALTER TABLE CSRIMP.MAP_IA_TYPE_SURVEY_GROUP DROP constraint UK_MAP_IA_TYPE_SURVEY_GROUP DROP INDEX;
ALTER TABLE CSRIMP.MAP_IA_TYPE_SURVEY_GROUP ADD constraint UK_MAP_IA_TYPE_SURVEY_GROUP UNIQUE (CSRIMP_SESSION_ID,NEW_IA_TYPE_SURVEY_GROUP_ID);
ALTER TABLE CSRIMP.MAP_PLUGIN_TYPE DROP constraint PK_MAP_PLUGIN_TYPE_ID DROP INDEX;
ALTER TABLE CSRIMP.MAP_PLUGIN_TYPE ADD constraint PK_MAP_PLUGIN_TYPE_ID PRIMARY KEY (CSRIMP_SESSION_ID,OLD_PLUGIN_TYPE_ID);
ALTER TABLE CSRIMP.MAP_PLUGIN_TYPE DROP constraint UK_MAP_PLUGIN_TYPE_ID DROP INDEX;
ALTER TABLE CSRIMP.MAP_PLUGIN_TYPE ADD constraint UK_MAP_PLUGIN_TYPE_ID UNIQUE (CSRIMP_SESSION_ID,NEW_PLUGIN_TYPE_ID);

DROP FUNCTION aspen2.to_string;

-- *** Grants ***
grant select, insert on csr.portal_dashboard to csrimp;
-- adding grant for update on menu to csrimp as we're updating sids on multiple_portal menu items
grant insert, update on security.menu to csrimp;
grant insert,select,update,delete on csrimp.portal_dashboard to web_user;
GRANT SELECT ON chain.tt_filter_ind_val TO csr;
GRANT SELECT ON chain.filter_page_ind TO csr;
GRANT SELECT ON chain.filter_page_ind_interval TO csr;
GRANT SELECT ON chain.tt_filter_id TO csr;
GRANT SELECT, REFERENCES ON csr.measure TO chain;
GRANT EXECUTE ON csr.utils_pkg TO chain;
GRANT EXECUTE ON csr.t_split_table TO chain;
grant select, insert, update on chain.filter_page_ind to csrimp;
grant select, insert, update on chain.filter_page_ind_interval to csrimp;
grant select, insert, update on chain.customer_aggregate_type to csrimp;
grant select on chain.filter_page_ind_id_seq to csrimp;
grant select on chain.filter_page_ind_intrval_id_seq to csrimp;
grant select on chain.customer_aggregate_type_id_seq to csrimp;
grant select, insert, update, delete on csrimp.chain_filter_page_ind to web_user;
grant select, insert, update, delete on csrimp.chain_filter_page_ind_interval to web_user;
grant select, insert, update, delete on csrimp.chain_customer_aggregate_type to web_user;
grant select on chain.customer_aggregate_type to cms;
grant select on chain.customer_aggregate_type to csr;

grant execute on chain.t_filter_agg_type_table TO csr;
grant execute on chain.t_filter_agg_type_row TO csr;
grant execute on chain.t_filter_agg_type_thres_table TO csr;
grant execute on chain.t_filter_agg_type_thres_row TO csr;
grant execute on chain.t_filter_agg_type_table TO cms;
grant execute on chain.t_filter_agg_type_row TO cms;
grant execute on chain.t_filter_agg_type_thres_table TO cms;
grant execute on chain.t_filter_agg_type_thres_row TO cms;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.
CREATE OR REPLACE VIEW CHAIN.v$company AS
	SELECT c.app_sid, c.company_sid, c.created_dtm, c.name, c.active, c.activated_dtm, c.deactivated_dtm,
		   c.address_1, c.address_2, c.address_3, c.address_4, c.town, c.state, 
		   NVL(pr.name, c.state) state_name, c.state_id, c.city, NVL(pc.city_name, c.city) city_name,
		   c.city_id, c.postcode, c.country_code,
		   c.phone, c.fax, c.website, c.email, c.deleted, c.details_confirmed, c.stub_registration_guid, 
		   c.allow_stub_registration, c.approve_stub_registration, c.mapping_approval_required, 
		   c.user_level_messaging, c.sector_id,
		   cou.name country_name, s.description sector_description, c.can_see_all_companies, c.company_type_id,
		   ct.lookup_key company_type_lookup, ct.singular company_type_description, c.supp_rel_code_label, c.supp_rel_code_label_mand,
		   c.parent_sid, p.name parent_name, p.country_code parent_country_code, pcou.name parent_country_name,
		   c.country_is_hidden, cs.region_sid
	  FROM company c
	  JOIN customer_options co ON co.app_sid = c.app_sid
	  LEFT JOIN v$country cou ON c.country_code = cou.country_code
	  LEFT JOIN sector s ON c.sector_id = s.sector_id AND c.app_sid = s.app_sid
	  LEFT JOIN company_type ct ON c.company_type_id = ct.company_type_id
	  LEFT JOIN company p ON c.parent_sid = p.company_sid AND c.app_sid = p.app_sid
	  LEFT JOIN v$country pcou ON p.country_code = pcou.country_code
	  LEFT JOIN csr.supplier cs ON cs.company_sid = c.company_sid AND cs.app_sid = c.app_sid
	  LEFT JOIN postcode.city pc ON c.city_id = pc.city_id AND c.country_code = pc.country
	  LEFT JOIN postcode.region pr ON c.state_id = pr.region AND c.country_code = pr.country
	 WHERE c.deleted = 0
;

-- *** Data changes ***
-- RLS
DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
BEGIN
 	FOR r IN (
		SELECT c.owner, c.table_name, c.nullable, (SUBSTR(c.table_name, 1, 26) || '_POL') policy_name
		  FROM all_tables t
		  JOIN all_tab_columns c ON t.owner = c.owner AND t.table_name = c.table_name
		 WHERE t.owner IN ('CSRIMP') AND (t.dropped = 'NO' OR t.dropped IS NULL) AND c.column_name = 'CSRIMP_SESSION_ID'
		   AND t.table_name IN ('CHAIN_FILTER_PAGE_IND', 'CHAIN_FILTER_PAGE_IND_INTERVAL', 'MAP_CHAIN_FILTER_PAGE_IND', 
		   'MAP_CHAIN_FLTR_PAGE_IND_INTRVL', 'MAP_CHAIN_CUSTOM_AGG_TYPE', 'CHAIN_CUSTOMER_AGGREGATE_TYPE')
 	)
 	LOOP
		dbms_output.put_line('Writing policy '||r.policy_name);
		dbms_rls.add_policy(
			object_schema   => r.owner,
			object_name     => r.table_name,
			policy_name     => r.policy_name, 
			function_schema => 'CSRIMP',
			policy_function => 'SessionIDCheck',
			statement_types => 'select, insert, update, delete',
			update_check	=> true,
			policy_type     => dbms_rls.context_sensitive);
	END LOOP;
EXCEPTION
	WHEN POLICY_ALREADY_EXISTS THEN
		DBMS_OUTPUT.PUT_LINE('Policy exists');
	WHEN FEATURE_NOT_ENABLED THEN
		DBMS_OUTPUT.PUT_LINE('RLS policies not applied as feature not enabled');
END;
/

DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
	POLICY_ALREADY_EXISTS EXCEPTION;
	PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
    TYPE T_TABS IS TABLE OF VARCHAR2(30);
    v_list T_TABS;
BEGIN
    v_list := t_tabs(
		'FILTER_PAGE_IND',
		'FILTER_PAGE_IND_INTERVAL',
		'CUSTOMER_AGGREGATE_TYPE'
    );
    FOR I IN 1 .. v_list.count
 	LOOP
		BEGIN
			dbms_rls.add_policy(
				object_schema   => 'CHAIN',
				object_name     => v_list(i),
				policy_name     => SUBSTR(v_list(i), 1, 23) || '_POLICY', 
				function_schema => 'CHAIN',
				policy_function => 'appSidCheck',
				statement_types => 'select, insert, update, delete',
				update_check	=> true,
				policy_type     => dbms_rls.context_sensitive);
		EXCEPTION WHEN POLICY_ALREADY_EXISTS THEN
			DBMS_OUTPUT.PUT_LINE('Policy exists for '||v_list(i));
		END;
	END LOOP;
EXCEPTION
	WHEN FEATURE_NOT_ENABLED THEN
		DBMS_OUTPUT.PUT_LINE('RLS policies not applied as feature not enabled');	
END;
/

DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
BEGIN
 	FOR r IN (
		SELECT c.owner, c.table_name, c.nullable, (SUBSTR(c.table_name, 1, 26) || '_POL') policy_name
		  FROM all_tables t
		  JOIN all_tab_columns c ON t.owner = c.owner AND t.table_name = c.table_name
		 WHERE t.owner IN ('CMS') AND (t.dropped = 'NO' OR t.dropped IS NULL) AND c.column_name = 'CSRIMP_SESSION_ID'
		   AND t.table_name IN (
				'DEBUG_DDL_LOG'
		   )
 	)
 	LOOP
		dbms_output.put_line('Writing policy '||r.policy_name);
		dbms_rls.add_policy(
			object_schema   => r.owner,
			object_name     => r.table_name,
			policy_name     => r.policy_name, 
			function_schema => 'CMS',
			policy_function => 'SessionIDCheck',
			statement_types => 'select, insert, update, delete',
			update_check	=> true,
			policy_type     => dbms_rls.context_sensitive);
	END LOOP;
EXCEPTION
	WHEN POLICY_ALREADY_EXISTS THEN
		DBMS_OUTPUT.PUT_LINE('Policy exists');
	WHEN FEATURE_NOT_ENABLED THEN
		DBMS_OUTPUT.PUT_LINE('RLS policies not applied as feature not enabled');
END;
/

DECLARE v_count NUMBER;
BEGIN	
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_policies 
	 WHERE object_owner = 'CMS'
	   AND policy_name = 'DEBUG_DDL_LOG_POL'
	   AND object_name = 'DEBUG_DDL_LOG';
	   
	IF v_count > 0 THEN
		dbms_output.put_line('Dropping policy DEBUG_DDL_LOG_POL');
		dbms_rls.drop_policy(
			object_schema	=>'CMS',
			object_name  	=>'DEBUG_DDL_LOG',
			policy_name  	=>'DEBUG_DDL_LOG_POL'
		);
	END IF;
END;
/

DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
BEGIN
	dbms_output.put_line('Writing policy DEBUG_DDL_LOG_POL');
	dbms_rls.add_policy(
		object_schema   => 'CMS',
		object_name     => 'DEBUG_DDL_LOG',
		policy_name     => 'DEBUG_DDL_LOG_POL', 
		function_schema => 'CSRIMP',
		policy_function => 'SessionIDCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive
	);
EXCEPTION
	WHEN POLICY_ALREADY_EXISTS THEN
		DBMS_OUTPUT.PUT_LINE('Policy exists');
	WHEN FEATURE_NOT_ENABLED THEN
		DBMS_OUTPUT.PUT_LINE('RLS policies not applied as feature not enabled');
END;
/

-- Data
UPDATE csr.std_alert_type
   SET description = REGEXP_REPLACE(description, 'Corporate Reporter', 'Framework Manager')
 WHERE description LIKE 'Corporate Reporter%';
 
UPDATE csr.std_alert_type_group
   SET description = 'Framework Manager'
 WHERE description = 'Corporate Reporter';

CREATE OR REPLACE PROCEDURE chain.temp_RegisterCapability (
	in_capability_type			IN  NUMBER,
	in_capability				IN  VARCHAR2,
	in_perm_type				IN  NUMBER,
	in_is_supplier				IN  NUMBER
)
AS
	v_count						NUMBER(10);
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM capability
	 WHERE capability_name = in_capability
	   AND capability_type_id = in_capability_type
	   AND perm_type = in_perm_type;

	IF v_count > 0 THEN
		-- this is already registered
		RETURN;
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM capability
	 WHERE capability_name = in_capability
	   AND perm_type <> in_perm_type;

	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' already exists using a different permission type');
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM capability
	 WHERE capability_name = in_capability
	   AND (
				(capability_type_id = 0 /*chain_pkg.CT_COMMON*/ AND (in_capability_type = 1 /*chain_pkg.CT_COMPANY*/ OR in_capability_type = 2 /*chain_pkg.CT_SUPPLIERS*/))
			 OR (in_capability_type = 0 /*chain_pkg.CT_COMMON*/ AND (capability_type_id = 1 /*chain_pkg.CT_COMPANY*/ OR capability_type_id = 2 /*chain_pkg.CT_SUPPLIERS*/))
		   );

	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' is already registered as a different capability type');
	END IF;

	INSERT INTO capability 
	(capability_id, capability_name, capability_type_id, perm_type, is_supplier) 
	VALUES 
	(capability_id_seq.NEXTVAL, in_capability, in_capability_type, in_perm_type, in_is_supplier);

END;
/
-- New chain capabilities
BEGIN
	chain.temp_RegisterCapability(0 /*chain.chain_pkg.CT_COMMON*/, 'Deactivate company' /*chain.chain_pkg.DEACTIVATE_COMPANY*/, 1 /*chain.chain_pkg.BOOLEAN_PERMISSION*/, 1 /*chain.chain_pkg.IS_SUPPLIER_CAPABILITY*/);
END;
/

DROP PROCEDURE chain.temp_RegisterCapability;

INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (18, 1, 'ISSUE_REF', 'Issue Ref', 'The issue reference', 20);

DECLARE
    job BINARY_INTEGER;
BEGIN
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'csr.optimize_all_indexes',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'ctx_ddl.optimize_index(''ix_doc_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_doc_desc_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_file_upload_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_sh_val_note_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_help_body_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_qs_response_file_srch'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_qs_ans_ans_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_issue_log_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_issue_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_issue_desc_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_audit_label_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_audit_notes_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_non_comp_label_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_non_comp_detail_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_non_comp_rt_cse_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_section_body_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_section_title_search'', ctx_ddl.OPTLEVEL_FULL);',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2015/01/03 01:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=WEEKLY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Synchronise all CSR text indexes');
       COMMIT;
END;
/

-- optimise job -- run weekly (at the weekend)
-- do one job for all so they aren't running at the same time
DECLARE
    job BINARY_INTEGER;
BEGIN
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'chain.optimize_all_indexes',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'ctx_ddl.optimize_index(''ix_file_upload_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_activity_desc_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_activity_loc_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_activity_out_search'', ctx_ddl.OPTLEVEL_FULL);
								ctx_ddl.optimize_index(''ix_activity_log_search'', ctx_ddl.OPTLEVEL_FULL);',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2015/01/03 01:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=WEEKLY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Synchronise all CHAIN text indexes');
       COMMIT;
END;
/

UPDATE csr.customer
   SET TPLREPORTPERIODEXTENSION = 5
 WHERE name='hyatt.credit360.com';
 
UPDATE security.securable_object_class
   SET helper_pkg = 'csr.automated_import_pkg'
 WHERE class_name = 'CSRAutomatedImport';

UPDATE security.securable_object_class
   SET helper_pkg = 'csr.automated_export_pkg'       
 WHERE class_name = 'CSRAutomatedExport';
 
-- ** New package grants **
create or replace package csr.automated_import_pkg as
procedure dummy;
end;
/
create or replace package body csr.automated_import_pkg as
procedure dummy
as
begin
	null;
end;
end;
/

create or replace package csr.automated_export_pkg as
procedure dummy;
end;
/
create or replace package body csr.automated_export_pkg as
procedure dummy
as
begin
	null;
end;
end;
/

GRANT EXECUTE ON csr.automated_import_pkg TO web_user;
GRANT EXECUTE ON csr.automated_export_pkg TO web_user;
DROP PACKAGE csr.cms_data_imp_pkg;

create or replace package csr.customer_pkg as
procedure dummy;
end;
/
create or replace package body csr.customer_pkg as
procedure dummy
as
begin
	null;
end;
end;
/

grant execute on csr.customer_pkg to web_user;

create or replace package aspen2.timezone_pkg as end;
/
grant execute on aspen2.timezone_pkg to csr, web_user;

-- *** Packages ***
@../export_feed_pkg
@../section_root_pkg
@../csr_data_pkg
@../automated_export_import_pkg
@../batch_job_pkg
@../automated_export_pkg
@../automated_import_pkg
@../enable_pkg
@../delegation_pkg
@../chain/business_relationship_pkg
@../chain/chain_pkg
@../chain/chain_link_pkg
@../chain/company_pkg
@../chain/company_type_pkg
@../region_pkg
@../supplier_pkg
@..\campaign_pkg
@../schema_pkg
@../csrimp/imp_pkg
@../section_pkg
@..\deleg_plan_pkg
@..\..\..\aspen2\db\error_pkg
@..\role_pkg
@../quick_survey_pkg
@../audit_report_pkg
@../chain/company_filter_pkg
@../chain/filter_pkg
@../initiative_report_pkg
@../initiative_metric_pkg
@../issue_report_pkg
@../non_compliance_report_pkg
@../property_report_pkg
@..\customer_pkg
@..\csr_app_pkg
@../../../aspen2/db/timezone_pkg
@../folderlib_pkg
@../dataview_pkg
@../../../aspen2/cms/db/filter_pkg

@../../../aspen2/cms/db/tab_body
@../csrimp/imp_body
@../folderlib_body
@../dataview_body
@../trash_body
@../../../aspen2/db/timezone_body
@..\customer_body
@..\csr_app_body
@../audit_report_body
@../chain/chain_body
@../chain/company_filter_body
@../chain/filter_body
@../initiative_report_body
@../initiative_metric_body
@../issue_report_body
@../non_compliance_report_body
@../property_report_body
@../region_metric_body
@../schema_body
@../../../aspen2/cms/db/filter_body
@../quick_survey_body
@..\role_body
@..\..\..\aspen2\db\error_body
@..\deleg_plan_body
@..\issue_body
@../audit_body
@../section_body
@../region_picker_body
@..\region_body
@..\campaign_body
@..\region_tree_body
@..\property_body
@..\supplier_body
@..\tag_body
@../chain/activity_body
@../chain/business_relationship_body
@../chain/chain_link_body
@../chain/company_body
@../chain/company_type_body
@../delegation_body
@../export_feed_body
@../section_root_body
@../automated_export_import_body
@../automated_export_body
@../automated_import_body
@../enable_body

BEGIN
	-- Log out of any specific app from previous blocks
	security.user_pkg.LogonAdmin;
	
	-- add group membership for any users in rrm but not in the group
	-- expected time to run on live: 27s for 657 rows
	INSERT INTO security.group_members (group_sid_id, member_sid_id)
	SELECT role_sid, user_sid
	  FROM (
		SELECT role_sid, user_sid
		  FROM (
			SELECT DISTINCT role_sid, user_sid
			  FROM csr.region_role_member rrm
			  JOIN security.group_table gt ON rrm.role_sid = gt.sid_id
			)
		 MINUS
		SELECT group_sid_id, member_sid_id
		  FROM security.group_members
		);
	
END;
/

@update_tail
