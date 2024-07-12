CREATE OR REPLACE PACKAGE BODY CSR.feed_pkg AS

PROC_NOT_FOUND				EXCEPTION;
PRAGMA EXCEPTION_INIT(PROC_NOT_FOUND, -06550);

PROCEDURE CallHelperPkg(
	in_procedure_name	IN	VARCHAR2,
	in_feed_sid			IN	security_pkg.T_SID_ID,
	in_feed_request_id	IN	feed_request.feed_request_id%TYPE
)
AS
	v_helper_pkg		feed.helper_pkg%TYPE;
BEGIN
	-- call helper proc if there is one
	BEGIN
		SELECT helper_pkg
		  INTO v_helper_pkg
		  FROM feed
		 WHERE app_sid = security_pkg.GetApp AND feed_sid = in_feed_sid;
	EXCEPTION
		WHEN no_data_found THEN
			null;
	END;

	IF v_helper_pkg IS NOT NULL THEN
		BEGIN
			EXECUTE IMMEDIATE 'begin '||v_helper_pkg||'.'||in_procedure_name||'(:1,:2);end;'
				USING in_feed_sid, in_feed_request_id;
		EXCEPTION
			WHEN PROC_NOT_FOUND THEN
				NULL; -- it is acceptable that it is not supported
		END;
	END IF;
END;

PROCEDURE SaveFeedSummary(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_feed_request_id	IN	feed_request.feed_request_id%TYPE,
	in_summary_xml		IN	feed_request.summary_xml%TYPE,
	in_error_data		IN	feed_request.error_data%TYPE
)
AS
	v_feed_sid	security_pkg.T_SID_ID;
BEGIN
	SELECT feed_sid INTO v_feed_sid
	  FROM feed_request
	 WHERE feed_request_id = in_feed_request_id;
	 
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_feed_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	UPDATE feed_request  
	   SET summary_xml = in_summary_xml,
		   error_data = in_error_data
	 WHERE feed_request_id = in_feed_request_id;
END;

PROCEDURE CreateFeed(
	in_act_id			IN security_pkg.T_ACT_ID, 
	in_app_sid			IN security_pkg.T_SID_ID,
	in_name				IN security_pkg.T_SO_NAME,
	in_label			IN feed.label%TYPE,
	in_xsl_doc			IN feed.xsl_doc%TYPE,
	in_response_xsl_doc	IN feed.response_xsl_doc%TYPE,
	in_mapping_xml		IN feed.mapping_xml%TYPE,
	in_feed_type_id		IN feed.feed_type_id%TYPE,
	in_url				IN feed.url%TYPE,
	in_username			IN feed.username%TYPE,
	in_protocol			IN feed.protocol%TYPE,
	in_host_key			IN feed.host_key%TYPE,
	in_interval			IN feed.interval%TYPE,
	out_feed_sid		OUT security_pkg.T_SID_ID
)
AS
	v_wwwroot			security_pkg.T_SID_ID;
	v_wwwroot_feeds		security_pkg.T_SID_ID;
	v_admins			security_pkg.T_SID_ID;
	v_zip_feed_sid		security_pkg.T_SID_ID;
	v_xml_feed_sid		security_pkg.T_SID_ID;
BEGIN
	v_wwwroot := securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid, 'wwwroot');
	BEGIN
        v_wwwroot_feeds := securableobject_pkg.GetSIDFromPath(in_act_id, v_wwwroot, 'feeds');
    EXCEPTION
        WHEN security_pkg.OBJECT_NOT_FOUND THEN
            -- feeds node doesn't exist yet
            web_pkg.CreateResource(in_act_id, v_wwwroot, v_wwwroot, 'feeds', v_wwwroot_feeds);
            -- add administrators (write)
            v_admins := securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid, 'Groups/Administrators');
            acl_pkg.AddACE(in_act_id, acl_pkg.GetDACLIDForSID(v_wwwroot_feeds), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
                security_pkg.ACE_FLAG_DEFAULT, v_admins, security_pkg.PERMISSION_STANDARD_ALL);            
    END;
    
    -- create our object as a web resource
    web_pkg.CreateResource(in_act_id, v_wwwroot, v_wwwroot_feeds, in_name, class_pkg.GetClassId('CSRFeed'), 
        '/csr/public/feed.aspx?sid={sid}', 
        out_feed_sid);
    /* deprecated because we assign permissions on the ZIP and XML nodes so that 'Everyone' doesn't have permissions on the actual feed object
       which gets used for access checks in lots of other places when actually administering feed data. Also import sessions get created under
       here I think so we don't want everyone having permissions on these 
    -- add everyone (read, NOT inherited, so that peolpe can fetch this URL) -- we would change this if they were authenticating via SSL                
	acl_pkg.AddACE(in_act_id, acl_pkg.GetDACLIDForSID(out_feed_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_INHERIT_INHERITABLE, security_pkg.SID_BUILTIN_EVERYONE, security_pkg.PERMISSION_STANDARD_READ);
    */
    -- create "zip" and "xml" children, then grant 'everyone' on these nodes instead 
    -- then add everyone (read, NOT inherited, so that peolpe can fetch this URL) 
	web_pkg.CreateResource(in_act_id, v_wwwroot, out_feed_sid, 'zip', Security_Pkg.SO_WEB_RESOURCE, 
        '/csr/public/feed.aspx?sid='||out_feed_sid||CHR(38)||'fileType=zip', 
        v_zip_feed_sid);        
	acl_pkg.AddACE(in_act_id, acl_pkg.GetDACLIDForSID(v_zip_feed_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_INHERIT_INHERITABLE, security_pkg.SID_BUILTIN_EVERYONE, security_pkg.PERMISSION_STANDARD_READ);

	web_pkg.CreateResource(in_act_id, v_wwwroot, out_feed_sid, 'xml', Security_Pkg.SO_WEB_RESOURCE, 
        '/csr/public/feed.aspx?sid='||out_feed_sid||CHR(38)||'fileType=xml', 
        v_xml_feed_sid);
    acl_pkg.AddACE(in_act_id, acl_pkg.GetDACLIDForSID(v_xml_feed_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_INHERIT_INHERITABLE, security_pkg.SID_BUILTIN_EVERYONE, security_pkg.PERMISSION_STANDARD_READ);
        
   
	INSERT INTO FEED (feed_sid, app_sid, label, xsl_doc, response_xsl_doc, mapping_xml, feed_type_id, url, username, protocol, host_key,  interval)
		VALUES (out_feed_sid, in_app_sid, in_label, in_xsl_doc, in_response_xsl_doc, in_mapping_xml, in_feed_type_id, in_url, in_username, in_protocol, in_host_key, in_interval);
END;

PROCEDURE CreateFeed(
	in_act_id			IN security_pkg.T_ACT_ID, 
	in_app_sid			IN security_pkg.T_SID_ID,
	in_name				IN security_pkg.T_SO_NAME,
	in_label			IN feed.label%TYPE,
	in_xsl_doc			IN feed.xsl_doc%TYPE,
	in_response_xsl_doc	IN feed.response_xsl_doc%TYPE,
	in_mapping_xml		IN feed.mapping_xml%TYPE,
	in_feed_type_id    	IN feed.feed_type_id%TYPE,
	out_feed_sid		OUT security_pkg.T_SID_ID
)
AS
BEGIN
  CreateFeed(in_act_id, in_app_sid, in_name, in_label, in_xsl_doc, in_response_xsl_doc, in_mapping_xml, in_feed_type_id, null, null, null, null, null, out_feed_sid);
END;

PROCEDURE AmendFeed(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_feed_sid			IN security_pkg.T_SID_ID,
	in_name				IN security_pkg.T_SO_NAME,
	in_label			IN feed.label%TYPE,
	in_xsl_doc			IN feed.xsl_doc%TYPE,
	in_response_xsl_doc	IN feed.response_xsl_doc%TYPE,
	in_mapping_xml		IN feed.mapping_xml%TYPE,
	in_feed_type_id    	IN feed.feed_type_id%TYPE
)
AS
BEGIN	   
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_feed_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	-- change the secobj name
	SecurableObject_Pkg.RenameSO(in_act_id, in_feed_sid, in_name);

	-- TODO: audit changes...
	UPDATE FEED 
	   SET label = in_label,
	   	xsl_doc = in_xsl_doc, 
		response_xsl_doc = in_response_xsl_doc,
		mapping_xml = in_mapping_xml,
		feed_type_id = in_feed_type_id
	 WHERE feed_sid = in_feed_sid;
END;

-- Securable object callbacks
PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
) AS
BEGIN
	security.web_pkg.RenameObject(in_act_id, in_sid_id, in_new_name);
END;

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
) AS	
BEGIN
	DELETE FROM FEED_REQUEST WHERE FEED_SID = in_sid_id;
	DELETE FROM FEED WHERE FEED_SID = in_sid_id;
	-- hmm - we have to manually do this
	security.web_pkg.DeleteObject(in_act_id, in_sid_id);
END;

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
) AS   
BEGIN		 
	security.web_pkg.MoveObject(in_act_id, in_sid_id, in_new_parent_sid_id, in_old_parent_sid_id);
END;

PROCEDURE GetFeed(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_feed_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_feed_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	-- response xsl and mapping_xml are supported in the backend only atm
	OPEN out_cur FOR
		SELECT feed_sid, app_sid, label, xsl_doc, feed_type_id, url, username, protocol, host_key, interval, last_good_attempt_dtm, last_attempt_dtm, response_xsl_doc, mapping_xml
		  FROM feed
		 WHERE feed_sid = in_feed_sid;
END;

PROCEDURE GetFeedList(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- check permissions on each feed
	OPEN out_cur FOR
		SELECT * 
		  FROM (
			SELECT f.feed_sid, f.label, so.name, c.host, 
				COUNT(fr.feed_sid) posts, 
				SUM(CASE fr.http_response_code WHEN 200 THEN 1 ELSE 0 END) successful_posts,
				COUNT(fr.feed_sid)  - SUM(CASE fr.http_response_code WHEN 200 THEN 1 ELSE 0 END) failed_posts,
				SUM(CASE WHEN fr.http_response_code = 200 AND imp_session_sid IS NULL THEN 1 ELSE 0 END) pending_processing, 
				MAX(fr.received_dtm) last_received_dtm,
				MAX(f.feed_type_id) feed_type_id,
				MAX(last_good_attempt_dtm) last_good_attempt_dtm,
				MAX(last_attempt_dtm) last_attempt_dtm,
				MAX(CASE
						WHEN interval = 'm' THEN TRUNC(ADD_MONTHS(last_good_attempt_dtm, 1), 'MM') + interval_offset
						WHEN interval = 'q' THEN TRUNC(ADD_MONTHS(last_good_attempt_dtm, 3), 'MM') + interval_offset
						WHEN interval = 'h' THEN TRUNC(ADD_MONTHS(last_good_attempt_dtm, 6), 'MM') + interval_offset
						WHEN interval = 'y' THEN TRUNC(ADD_MONTHS(last_good_attempt_dtm, 12), 'MM') + interval_offset
					END) next_attempt_dtm
			  FROM feed f, customer c, security.securable_object so, feed_request fr
			 WHERE f.app_sid = in_app_sid
			   AND f.feed_sid = fr.feed_sid(+)
			   AND f.feed_sid = so.sid_id
			   AND f.app_sid = c.app_sid
			 GROUP BY f.feed_sid, f.label, so.name, c.host
			)
		 WHERE security_pkg.SQL_IsAccessAllowedSID(in_act_id, feed_sid, security_pkg.PERMISSION_READ) = 1;
END;

PROCEDURE GetFeedDetails(
    in_act_id       IN	security_pkg.T_ACT_ID,
	in_feed_sid		IN	security_pkg.T_SID_ID,
    in_start_row    IN	number,
    in_end_row      IN	number,
    out_cur         OUT security_pkg.T_OUTPUT_CUR
) 
AS
BEGIN
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_feed_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading feed');
	END IF;
	
    OPEN out_cur FOR
		SELECT *
		  FROM (
			SELECT f.*, ROWNUM rn
			  FROM ( 
				SELECT feed_request_id, received_dtm, cu.user_name, cu.full_name, http_response_code, remote_addr, fr.imp_session_sid, 
					case when merged_dtm is not null and result_code = 0 then 1 else 0 end is_merged,
					COUNT(*) OVER () total_rows 
				  FROM feed_request fr, csr_user cu, imp_session im
				 WHERE feed_sid = in_feed_sid
				   AND fr.user_sid = cu.csr_user_sid
		           AND fr.imp_session_sid = im.imp_session_sid(+)
				ORDER BY received_dtm DESC
			) f
		 )
		 WHERE rn > in_start_row 
		   AND rn <= in_end_row;
END;

PROCEDURE LogRequest(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_feed_sid			IN	security_pkg.T_SID_ID,
	in_response_code	IN	feed_request.http_response_code%TYPE,
	in_remote_addr		IN	feed_request.remote_addr%TYPE,
	in_file_data		IN	feed_request.file_data%TYPE,
	in_file_type		IN	feed_request.file_type%TYPE,
	out_feed_request_id	OUT	feed_request.feed_request_id%TYPE
)
AS
	v_user_sid	security_pkg.T_SID_ID;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_feed_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on the feed with sid '||in_feed_sid);
	END IF;
	
	user_pkg.getSid(in_act_id, v_user_sid);
	
	INSERT INTO FEED_REQUEST
		(feed_request_id, feed_sid, user_sid, http_response_code, remote_addr, file_data, file_type)
	VALUES
		(feed_request_id_seq.nextval, in_feed_sid, v_user_sid, in_response_code, in_remote_addr, in_file_data, in_file_type)
	RETURNING feed_request_id INTO out_feed_request_id;	
END;

PROCEDURE UNSEC_GetAppsToProcessFeedsFor(
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- no security as this is called by batch
	OPEN out_cur FOR
		SELECT DISTINCT app_sid
		  FROM feed_request
		 WHERE imp_session_sid IS NULL;
END;


PROCEDURE UNSEC_GetAppsToProcessIntFeeds(
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- no security as this is called by batch
	OPEN out_cur FOR
		SELECT DISTINCT app_sid
		  FROM feed
		 WHERE feed_type_id = INTERVAL_FEED_TYPE
		   AND ((last_good_attempt_dtm IS NULL) OR 
				(SYSDATE > 
					CASE
						WHEN interval = 'm' THEN TRUNC(ADD_MONTHS(last_good_attempt_dtm, 1), 'MM') + interval_offset
						WHEN interval = 'q' THEN TRUNC(ADD_MONTHS(last_good_attempt_dtm, 3), 'MM') + interval_offset
						WHEN interval = 'h' THEN TRUNC(ADD_MONTHS(last_good_attempt_dtm, 6), 'MM') + interval_offset
						WHEN interval = 'y' THEN TRUNC(ADD_MONTHS(last_good_attempt_dtm, 12), 'MM') + interval_offset
					END));
END;


PROCEDURE UNSEC_GetIntervalFeedsForApp(
	in_app_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- no security as this is called by batch	
	OPEN out_cur FOR
		SELECT feed_sid
		  FROM feed 
		 WHERE feed_type_id = INTERVAL_FEED_TYPE
		   AND ((last_good_attempt_dtm IS NULL) OR 
				(SYSDATE > 
					CASE
						WHEN interval = 'm' THEN TRUNC(ADD_MONTHS(last_good_attempt_dtm, 1), 'MM') + interval_offset
						WHEN interval = 'q' THEN TRUNC(ADD_MONTHS(last_good_attempt_dtm, 3), 'MM') + interval_offset
						WHEN interval = 'h' THEN TRUNC(ADD_MONTHS(last_good_attempt_dtm, 6), 'MM') + interval_offset
						WHEN interval = 'y' THEN TRUNC(ADD_MONTHS(last_good_attempt_dtm, 12), 'MM') + interval_offset
					END))
		   AND app_sid = in_app_sid;
END;


PROCEDURE UNSEC_GetOpenRequestsForApp(
	in_app_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS	
	v_feed_sid security_pkg.T_SID_ID;
BEGIN
	-- no security as this is called by batch
	OPEN out_cur FOR
		SELECT fr.app_sid, fr.feed_request_id, fr.feed_sid, fr.received_dtm, fr.user_sid, fr.file_data, fr.file_type, fr.http_response_code, fr.remote_addr
		  FROM feed_request fr, feed f
		 WHERE fr.feed_sid = f.feed_sid 
		   AND fr.app_sid = f.app_sid
		   AND imp_session_sid IS NULL
		   AND fr.app_sid = in_app_sid
		   -- chain and logging forms feeds do not get batch processed
		   AND f.feed_type_id NOT IN(CHAIN_FEED_TYPE, LOGGING_FORMS_FEED_TYPE); 			   
END;

PROCEDURE GetFeedRequest(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_feed_request_id	IN	feed_request.feed_request_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS	
	v_feed_sid security_pkg.T_SID_ID;
BEGIN
	SELECT feed_sid INTO v_feed_sid
	  FROM feed_request 
	 WHERE feed_request_id = in_feed_request_id;
	 
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_feed_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading feed');
	END IF;
	
	OPEN out_cur FOR
		SELECT fr.feed_request_id, fr.feed_sid, fr.received_dtm, fr.user_sid, fr.xml_data, fr.http_response_code, fr.remote_addr, f.feed_type_id, fr.file_data, fr.file_type, fr.summary_xml, fr.error_data
		  FROM feed_request fr, feed f
		 WHERE fr.feed_request_id = in_feed_request_id
		   AND fr.feed_sid = f.feed_sid
		   AND fr.app_sid = f.app_sid;
END;

PROCEDURE SetFeedRequestSessionSid(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_feed_request_id	IN	feed_request.feed_request_id%TYPE,
	in_imp_session_sid	IN	security_pkg.T_SID_ID
)
AS
	v_feed_sid	security_pkg.T_SID_ID;
BEGIN
	SELECT feed_sid INTO v_feed_sid
	  FROM feed_request
	 WHERE feed_request_id = in_feed_Request_id;
	 
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_feed_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	UPDATE feed_request  
	   SET imp_session_sid = in_imp_session_sid
	 WHERE feed_request_id = in_Feed_request_id;	
END;

PROCEDURE SetFeedTimestamps(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_feed_sid	IN	feed.feed_sid%TYPE,
	in_last_good_attempt_dtm IN feed.last_good_attempt_dtm%TYPE,
	in_last_attempt_dtm IN feed.last_attempt_dtm%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_feed_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	UPDATE feed
	   SET last_good_attempt_dtm = in_last_good_attempt_dtm,
         last_attempt_dtm = in_last_attempt_dtm
   WHERE feed_sid = in_feed_sid;
END;

PROCEDURE GetFeedTypes(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_chain_enabled		feed_type.is_chain%TYPE;
BEGIN

	SELECT COUNT(*) INTO v_chain_enabled FROM chain.customer_options WHERE app_sid = security_pkg.getApp;
	
	OPEN out_cur FOR
		SELECT feed_type_id, feed_type 
		  FROM feed_type
		  WHERE ((is_chain = 0) OR (is_chain = 1 AND v_chain_enabled = 1))
		    AND feed_type_id <> INTERVAL_FEED_TYPE;
END;

PROCEDURE GetInboundFeedAccounts(
	out_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- no security as this is run from a batch job
	OPEN out_cur FOR
		SELECT c.host, a.inbox_sid
		  FROM csr.inbound_feed_account iia
			JOIN csr.customer c ON iia.app_sid = c.app_sid
			JOIN mail.account a ON iia.account_sid = a.account_sid;
END;

PROCEDURE SaveInboundFeedAttachment(
	in_mailbox_sid	IN	security_pkg.T_SID_ID, 
	in_message_uid	IN	security_pkg.T_SID_ID, 
	in_name			IN	VARCHAR2, 
	in_date			IN	DATE, 
    in_file_data	IN	BLOB
)
AS
BEGIN
	-- security check required?

	-- incoming files with the same name and date are just updated.
	BEGIN
		INSERT INTO csr.inbound_feed_attachment
		(APP_SID, ACCOUNT_SID, MESSAGE_UID, NAME, RECEIPT_DATE, PROCESSED_DATE, ATTACHMENT)
		VALUES (security_pkg.GetApp, in_mailbox_sid, in_message_uid, in_name, in_date, null, in_file_data);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE csr.inbound_feed_attachment
			   SET RECEIPT_DATE=in_date, PROCESSED_DATE=null, ATTACHMENT=in_file_data
			 WHERE APP_SID=security_pkg.GetApp 
			   AND ACCOUNT_SID=in_mailbox_sid 
			   AND MESSAGE_UID=in_message_uid
			   AND NAME=in_name;
	END;
END;

END feed_pkg;
/
