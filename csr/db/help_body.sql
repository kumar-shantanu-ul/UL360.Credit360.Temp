CREATE OR REPLACE PACKAGE BODY CSR.help_Pkg
IS

--
-- Useful helper functions
--

FUNCTION GetNextHelpTopicPos(
	in_parent_id		IN help_topic.help_topic_id%TYPE
) RETURN help_topic.pos%TYPE
AS
	v_parent_id		help_topic.help_topic_id%TYPE;
	v_next_pos		help_topic.pos%TYPE;	
	v_count			NUMBER(10);
BEGIN
	-- Try to find the help topic parent
	v_parent_id := NVL(in_parent_id,0);
	
	SELECT COUNT(0)
	  INTO v_count
	  FROM help_topic
	 WHERE help_topic_id = v_parent_id;
	
	IF v_count = 0 THEN
		v_parent_id := 0;
	END IF;
	
	-- Get the next positon
	SELECT NVL(MAX(pos),-1)
	  INTO v_next_pos
	  FROM help_topic
	 WHERE NVL(parent_id,0) = v_parent_id;
	 RETURN v_next_pos+1;
END;

FUNCTION ResolveLangIdForTopic(
	in_app_sid		IN security_pkg.T_SID_ID,
	in_lang_id			IN help_lang.help_lang_id%TYPE,
	in_topic_id			IN help_topic.help_topic_id%TYPE
) RETURN help_lang.help_lang_id%TYPE
AS
	v_lang				help_lang.help_lang_id%TYPE;
BEGIN
	SELECT help_lang_id
	  INTO v_lang
	  FROM (
	    SELECT htt.help_lang_id, label, rownum rn
	      FROM help_topic_text htt,  
	        (SELECT help_lang_id, label, level lvl 
	          FROM help_lang 
	         START WITH help_lang_id = in_lang_id
	         CONNECT BY PRIOR base_lang_id = help_lang_id)l  
	     WHERE htt.help_lang_id = l.help_lang_id
	       AND help_topic_id= in_topic_id
	     ORDER BY lvl
	  )
	  WHERE rn = 1;
	   
	RETURN v_lang;
END;

FUNCTION SecurableObjectChildCount(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_sid_id			IN	security_pkg.T_SID_ID
) RETURN NUMBER
AS
	v_count			NUMBER(10);
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM TABLE(securableobject_pkg.GetChildrenWithPermAsTable(in_act_id, in_sid_id, security_pkg.PERMISSION_READ));
	RETURN v_count;
END;

FUNCTION GetDefaultLangId(
	in_app_sid		IN security_pkg.T_SID_ID
) RETURN help_lang.help_lang_id%TYPE
AS
	v_lang				help_lang.help_lang_id%TYPE;
BEGIN
	SELECT help_lang_id
	  INTO v_lang
	  FROM customer_help_lang
	 WHERE app_sid = in_app_sid
	   AND NOT is_default = 0;
	RETURN v_lang;
END;

PROCEDURE ValidateLanguageIdForCustomer (
	in_act				IN security_pkg.T_ACT_ID,
	in_app_sid		IN security_pkg.T_SID_ID,
	in_lang_id			IN help_lang.help_lang_id%TYPE,
	out_lang_id			OUT help_lang.help_lang_id%TYPE
)
AS
BEGIN
	SELECT help_lang_id
	  INTO out_lang_id
	  FROM
	(SELECT c.help_lang_id, l.lvl
       FROM customer_help_lang c,
        (SELECT help_lang_id, label, level lvl 
           FROM help_lang 
        	START WITH help_lang_id = in_lang_id
         	CONNECT BY help_lang_id = PRIOR base_lang_id) l
	      WHERE c.help_lang_id = l.help_lang_id
	        AND c.app_sid = in_app_sid
	        AND ROWNUM = 1
	    UNION
	    	-- Yuck, we want the default language if noting is returned by the above 
	    	-- query and we are using the level order to get the correct result
	        SELECT GetDefaultLangId(in_app_sid) help_lang_id, 4294967295 lvl
	          FROM dual
	    ORDER BY lvl ASC
	)
	WHERE rownum = 1;
END;

--
-- Securable object callbacks
--

PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
)
AS
	v_parent_id		help_topic.help_topic_id%TYPE;
	v_count			NUMBER(10);
BEGIN
	-- Try to find the help topic parent
	v_parent_id := NVL(in_parent_sid_id,0);
	
	SELECT COUNT(0)
	  INTO v_count
	  FROM help_topic
	 WHERE help_topic_id = v_parent_id;
	
	IF v_count = 0 THEN
		v_parent_id := NULL;
	END IF;
	
	-- Create a help topic entry
	INSERT INTO help_topic
		(help_topic_id, parent_id, lookup_name, pos, hits, votes, score)
	  VALUES (in_sid_id, v_parent_id, in_name, GetNextHelpTopicPos(in_parent_sid_id), 0, 0, 0);
END;

PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
) AS
BEGIN
	UPDATE help_topic
	   SET lookup_name = in_new_name
	 WHERE help_topic_id = in_sid_id;
END;

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
)
AS
BEGIN
	-- delete file mapping
	DELETE FROM help_topic_file
		WHERE help_topic_id = in_sid_id;
	-- Delete all text relating to this topic
	DELETE FROM help_topic_text
		WHERE help_topic_id = in_sid_id;
	-- Delete the topic
	DELETE FROM help_topic
		WHERE help_topic_id = in_sid_id;
END;

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid		IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
)
AS
	v_parent_id		help_topic.help_topic_id%TYPE;
	v_count			NUMBER(10);
BEGIN
	-- Try to find the help topic parent
	v_parent_id := NVL(in_new_parent_sid,0);
	
	SELECT COUNT(0)
	  INTO v_count
	  FROM help_topic
	 WHERE help_topic_id = v_parent_id;
	
	IF v_count = 0 THEN
		v_parent_id := NULL;
	END IF;
	
	UPDATE help_topic
	   SET parent_id = v_parent_id
	 WHERE help_topic_id = in_sid_id;
END;

--
-- Language
--

PROCEDURE AddLanguage(
	in_act 				IN security_pkg.T_ACT_ID,
	in_base_id			IN help_lang.base_lang_id%TYPE,
	in_label			IN help_lang.label%TYPE,
	out_lang_id			OUT	help_lang.help_lang_id%TYPE
)
AS
BEGIN
	-- Get a new language id
	SELECT help_lang_id_seq.NEXTVAL
	  INTO out_lang_id
	  FROM dual;
	
	-- Insert language
	INSERT INTO help_lang
		(help_lang_id, base_lang_id, label)
	  VALUES(out_lang_id, in_base_id, in_label);
END;

PROCEDURE GetDefaultLanguage(
	in_act 				IN security_pkg.T_ACT_ID,
	in_app_sid		IN security_pkg.T_SID_ID,
	out_lang_id			OUT	help_lang.help_lang_id%TYPE
)
AS
BEGIN
	out_lang_id := GetDefaultLangId(in_app_sid);
END;

PROCEDURE GetLanguages(
	in_act 				IN security_pkg.T_ACT_ID,
	in_app_sid		IN security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_super_admin_sid	security_pkg.T_SID_ID;
BEGIN
	-- Super admins see all languages
	v_super_admin_sid := securableobject_pkg.GetSIDFromPath(in_act, 0, 'csr/SuperAdmins');
	IF 1 = 0 THEN --user_pkg.IsUserInGroup(in_act, v_super_admin_sid) != 0 THEN
		OPEN out_cur FOR
			SELECT DISTINCT c.help_lang_id, l.label
			  FROM customer_help_lang c, help_lang l
			 WHERE l.help_lang_id = c.help_lang_id
				ORDER BY c.help_lang_id ASC;
	ELSE
		OPEN out_cur FOR
			SELECT c.help_lang_id, l.label
			  FROM customer_help_lang c, help_lang l
			 WHERE c.app_sid = in_app_sid
			   AND l.help_lang_id = c.help_lang_id
				ORDER BY c.is_default DESC, l.label ASC;
	END IF;
END;

--
-- Topic
--

PROCEDURE AddTopic_Deprecate(
	in_act 				IN security_pkg.T_ACT_ID,
	in_app_sid		IN security_pkg.T_SID_ID,
	in_parent_id		IN security_pkg.T_SID_ID,
	in_lookup_name		IN help_topic.lookup_name%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_parent_id			security_pkg.T_SID_ID;
	v_topic_id			security_pkg.T_SID_ID;
	v_actual_name		help_topic.lookup_name%TYPE;
	v_lookup_name_base	help_topic.lookup_name%TYPE;
	v_default_lang		help_lang.help_lang_id%TYPE;
	v_working			NUMBER(10);
BEGIN
	-- if parent_sid_id is null, then create under <csr-root>/Help
	v_parent_id := COALESCE(in_parent_id, securableobject_pkg.GetSIDFromPath(in_act, 0, 'csr/Help'));

	-- Remove '/' from the name
	v_lookup_name_base := replace(in_lookup_name,'/','\');
	v_actual_name := v_lookup_name_base;

	-- CreateSO will call helper in this package
	v_working := 1;
	WHILE v_working != 0 LOOP
		BEGIN
			v_working := v_working + 1;
			securableobject_pkg.CreateSO(in_act, v_parent_id, 
				class_pkg.getClassID('CSRHelpTopic'), v_actual_name, v_topic_id);
			v_working := 0;
		EXCEPTION
			WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
				v_actual_name := v_lookup_name_base || ' (' || v_working || ')';
			WHEN DUP_VAL_ON_INDEX THEN
				v_actual_name := v_lookup_name_base || ' (' || v_working || ')';
		END;
	END LOOP;
	
	-- Create an empty topic content entry in the default language
	GetDefaultLanguage(in_act, in_app_sid, v_default_lang);
	SetTopicContent(in_act, in_app_sid, v_topic_id, v_default_lang, v_actual_name, '');
	
	OPEN out_cur FOR
		SELECT v_topic_id topic_id, v_actual_name actual_name
		FROM dual;
END;

PROCEDURE AddTopic(
	in_act 				IN security_pkg.T_ACT_ID,
	in_app_sid		IN security_pkg.T_SID_ID,
	in_parent_id		IN security_pkg.T_SID_ID,
	in_lookup_name		IN help_topic.lookup_name%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_parent_id			security_pkg.T_SID_ID;
	v_topic_id			security_pkg.T_SID_ID;
	v_actual_name		help_topic.lookup_name%TYPE;
	v_lookup_name_base	help_topic.lookup_name%TYPE;
	v_default_lang		help_lang.help_lang_id%TYPE;
	v_working			NUMBER(10);
BEGIN
	v_parent_id := COALESCE(in_parent_id, securableobject_pkg.GetSIDFromPath(in_act, 0, 'csr/Help'));
	
	-- Remove '/' from the name
	v_lookup_name_base := replace(in_lookup_name,'/','\');
	v_actual_name := v_lookup_name_base;

	-- CreateSO will call helper in this package
	v_working := 1;
	WHILE v_working != 0 LOOP
		BEGIN
			v_working := v_working + 1;
			securableobject_pkg.CreateSO(in_act, v_parent_id, 
				class_pkg.getClassID('CSRHelpTopic'), v_actual_name, v_topic_id);
			v_working := 0;
		EXCEPTION
			WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
				v_actual_name := v_lookup_name_base || ' (' || v_working || ')';
			WHEN DUP_VAL_ON_INDEX THEN
				v_actual_name := v_lookup_name_base || ' (' || v_working || ')';
		END;
	END LOOP;
	
	-- Create an empty topic content entry in the default language
	GetDefaultLanguage(in_act, in_app_sid, v_default_lang);
	
	IF v_default_lang = 1 AND csr_user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You must be a superadmin user to add a topic for all clients');
	END IF;
	
	SetTopicContent(in_act, in_app_sid, v_topic_id, v_default_lang, v_actual_name, '');
	
	OPEN out_cur FOR
		SELECT v_topic_id help_topic_id, v_actual_name title
		FROM dual;
END;

PROCEDURE RemoveTopic(
	in_act 				IN security_pkg.T_ACT_ID,
	in_topic_id			IN security_pkg.T_SID_ID
)
AS
BEGIN
	-- DeleteSO will call helper in this package
	securableobject_pkg.DeleteSO(in_act, in_topic_id);
END;

PROCEDURE RemoveTopicContent(
	in_act 				IN security_pkg.T_ACT_ID,
	in_app_sid		IN security_pkg.T_SID_ID,
	in_topic_id			IN security_pkg.T_SID_ID,
	in_lang_id			IN help_lang.help_lang_id%TYPE
)
AS
	v_count				NUMBER(10);
BEGIN
	-- Check this user's rights on this topic in this language
	CheckEditAccessRights(in_act, in_app_sid, in_topic_id, in_lang_id);
	
	-- Remove references to file attachments
	FOR r_file IN (
		SELECT help_file_id
		  FROM help_topic_file
		 WHERE help_topic_id = in_topic_id
		   AND help_lang_id = in_lang_id) LOOP
		RemoveHelpFileReference(in_act, in_app_sid, in_topic_id, in_lang_id, r_file.help_file_id);
	END LOOP;
	
	-- Remove the topic in specified language
	DELETE FROM help_topic_text
		WHERE help_topic_id = in_topic_id
		  AND help_lang_id = in_lang_id;
		  
	-- Was this the last language entry for this topic
	SELECT COUNT(0)
	  INTO v_count
	  FROM help_topic_text
	 WHERE help_topic_id = in_topic_id;
	 
	-- If last reference then delete
	IF v_count = 0 THEN
		RemoveTopic(in_act, in_topic_id);
	END IF;
END;

PROCEDURE SetLookupName(
	in_act 				IN security_pkg.T_ACT_ID,
	in_topic_id			IN security_pkg.T_SID_ID,
	in_lookup_name		IN help_topic.lookup_name%TYPE,
	out_actual_name		OUT help_topic.lookup_name%TYPE
)
AS
	v_lookup_name_base	help_topic.lookup_name%TYPE;
	v_working			NUMBER(10);
BEGIN	
	-- Remove '/' from the name
	SELECT replace(in_lookup_name,'/','\') 
	  INTO v_lookup_name_base
	  FROM dual;
	
	SELECT COUNT(0)
	  INTO v_working
	  FROM help_topic
	 WHERE LOWER(LOOKUP_NAME) = LOWER(v_lookup_name_base);
	
	v_working := v_working + 1;
	out_actual_name := v_lookup_name_base;
	WHILE v_working != 0 LOOP
		BEGIN
			v_working := v_working + 1;
			securableobject_pkg.RenameSO(in_act, in_topic_id, out_actual_name);
			v_working := 0;
		EXCEPTION
			WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
				out_actual_name := v_lookup_name_base || ' (' || v_working || ')';
			WHEN DUP_VAL_ON_INDEX THEN
				out_actual_name := v_lookup_name_base || ' (' || v_working || ')';
		END;
	END LOOP;
END;

PROCEDURE CheckEditAccessRights(
	in_act 				IN security_pkg.T_ACT_ID,
	in_app_sid		IN security_pkg.T_SID_ID,
	in_topic_id			IN security_pkg.T_SID_ID,
	in_lang_id			IN help_lang.help_lang_id%TYPE
)
AS
	v_count				NUMBER(10);
	v_super_admin_sid	security_pkg.T_SID_ID;
BEGIN
	-- Check security access to topic
	IF NOT security_pkg.IsAccessAllowedSID(in_act, in_topic_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on help topic object with sid '||in_topic_id);
	END IF;
	
	-- Check if the user is a super admin (hmm, special case)
	v_super_admin_sid := securableobject_pkg.GetSIDFromPath(in_act, 0, 'csr/SuperAdmins');
	IF user_pkg.IsUserInGroup(in_act, v_super_admin_sid) != 0 THEN
		RETURN;
	END IF;
	
	-- Check the customer has the specified language entry
	v_count := 0;
	SELECT COUNT(0)
	  INTO v_count
	  FROM customer_help_lang
	 WHERE app_sid = in_app_sid
	   AND help_lang_id = in_lang_id;
	
	IF v_count = 0 THEN
		RAISE_APPLICATION_ERROR(ERR_EDIT_LANGUAGE_DENIED, 'Write access denied on help topic with id '||in_topic_id||' in laguage with id '||in_lang_id);
	END IF;	
END;

PROCEDURE SetTopicContent(
	in_act 				IN security_pkg.T_ACT_ID,
	in_app_sid		IN security_pkg.T_SID_ID,
	in_topic_id			IN security_pkg.T_SID_ID,
	in_lang_id			IN help_lang.help_lang_id%TYPE,
	in_title			IN help_topic_text.title%TYPE,
	in_body				IN help_topic_text.body%TYPE
)
AS
	v_count				NUMBER(10);
BEGIN
	-- Check this user's rights on this topic in this language
	CheckEditAccessRights(in_act, in_app_sid, in_topic_id, in_lang_id);
	
	-- Check for valid language id
	v_count := 0;
	IF in_lang_id IS NOT NULL THEN
		SELECT COUNT(0)
		  INTO v_count
		  FROM help_lang
		 WHERE help_lang_id = in_lang_id;
	END IF;
	
	IF v_count = 0 THEN
		RAISE_APPLICATION_ERROR(ERR_INVALID_LANG, 'Language with id '||in_lang_id||', was not found.');
	END IF;
	
	BEGIN
		-- Insert the content
		INSERT INTO help_topic_text
			(help_topic_id, help_lang_id, title, body)
		  VALUES(in_topic_id, in_lang_id, in_title, in_body);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			-- Update the content
			UPDATE help_topic_text
			   SET title = in_title, body = in_body, last_updated_dtm = SYSDATE
			 WHERE help_topic_id = in_topic_id
		   	   AND help_lang_id = in_lang_id;
	END;
END;

PROCEDURE GetTopicContent(
	in_act 				IN security_pkg.T_ACT_ID,
	in_app_sid		IN security_pkg.T_SID_ID,
	in_topic_id			IN security_pkg.T_SID_ID,
	in_lang_id			IN help_lang.help_lang_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act, in_topic_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on help topic object with sid '||in_topic_id);
	END IF;

	-- OK, return the content!
	OPEN out_cur FOR
		SELECT t.help_topic_id, t.help_lang_id, t.title, t.body, t.last_updated_dtm, h.lookup_name, l.short_name language_class
		  FROM help_topic_text t, help_topic h, help_lang l
		 WHERE t.help_topic_id = in_topic_id
		   AND h.help_topic_id = t.help_topic_id
		   AND t.help_lang_id = ResolveLangIdForTopic(in_app_sid, in_lang_id, in_topic_id)
		   AND l.help_lang_id = t.help_lang_id;
END;

PROCEDURE GetTopicIdFromLookup(
	in_act 				IN security_pkg.T_ACT_ID,
	in_app_sid		IN security_pkg.T_SID_ID,
	in_lookup_name		IN help_topic.lookup_name%TYPE,
	out_topic_id		OUT	help_topic.help_topic_id%TYPE
)
AS
	v_count				NUMBER(10);
BEGIN
	SELECT COUNT(0)
	  INTO v_count
	  FROM help_topic
	 WHERE LOWER(lookup_name) = LOWER(in_lookup_name);

	out_topic_id := NULL;
	IF v_count != 0 THEN
		SELECT help_topic_id
		  INTO out_topic_id
		  FROM help_topic
		 WHERE LOWER(lookup_name) = LOWER(in_lookup_name);
	END IF;
	 
	IF out_topic_id IS NULL THEN
		RAISE_APPLICATION_ERROR(ERR_INVALID_LOOKUP_NAME, 'Topic with lookup name "'||in_lookup_name||'" could not be found');
	END IF;
END;

--
-- File (attachment)
--

PROCEDURE AddHelpFileReference(
	in_act 				IN security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_topic_id			IN security_pkg.T_SID_ID,
	in_lang_id			IN help_lang.help_lang_id%TYPE,
	in_file_id			IN help_file.help_file_id%TYPE
)
AS
BEGIN
	-- Check this user's rights on this topic in this language
	CheckEditAccessRights(in_act, in_app_sid, in_topic_id, in_lang_id);
	
	BEGIN
		-- Link up the topic, language and file
	   	INSERT INTO help_topic_file
	   		(help_topic_id, help_lang_id, help_file_id)
	   	VALUES
	   		(in_topic_id, in_lang_id, in_file_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

PROCEDURE RemoveHelpFileReference(
	in_act 				IN security_pkg.T_ACT_ID,
	in_app_sid		IN security_pkg.T_SID_ID,
	in_topic_id			IN security_pkg.T_SID_ID,
	in_lang_id			IN help_lang.help_lang_id%TYPE,
	in_file_id			IN help_file.help_file_id%TYPE
)
AS
	v_count				NUMBER(10);
BEGIN
	-- Check this user's rights on this topic in this language
	CheckEditAccessRights(in_act, in_app_sid, in_topic_id, in_lang_id);
	
	-- Remove the reference
	DELETE FROM help_topic_file
	 WHERE help_topic_id = in_topic_id
	   AND help_lang_id = in_lang_id
	   AND help_file_id = in_file_id;
	   
	-- if this was the last reference then remove the file entry
	SELECT COUNT(0)
	  INTO v_count
	  FROM help_topic_file
	 WHERE help_file_id = in_file_id;
	 
	 IF v_count = 0 THEN
	 	DELETE FROM help_file
	 	 WHERE help_file_id = in_file_id;
	 END IF;
END;

PROCEDURE GetHelpFileReferences(
	in_act 				IN security_pkg.T_ACT_ID,
	in_app_sid		IN security_pkg.T_SID_ID,
	in_topic_id			IN security_pkg.T_SID_ID,
	in_lang_id			IN help_lang.help_lang_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT help_topic_id, help_lang_id, help_file_id
		  FROM help_topic_file
		 WHERE help_topic_id = in_topic_id
		   AND help_lang_id = in_lang_id;
END;

PROCEDURE CreateHelpFileFromCache(		  
	in_act				IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_topic_id			IN	security_pkg.T_SID_ID,
	in_lang_id			IN	help_lang.help_lang_id%TYPE,
    in_cache_key		IN	aspen2.filecache.cache_key%TYPE,
	out_file_id			OUT	help_file.help_file_id%TYPE
)
AS
BEGIN
	-- Check this user's rights on this topic in this language
	CheckEditAccessRights(in_act, in_app_sid, in_topic_id, in_lang_id);
	
	-- Get a new file id
	SELECT HELP_FILE_ID_SEQ.NEXTVAL
	  INTO out_file_id
	  FROM dual;
	
	-- Get the data from the cache and put it into the help file table
	INSERT INTO help_file
		(HELP_FILE_ID, DATA, MIME_TYPE, LABEL, DATA_HASH) 
    	SELECT out_file_id, object, mime_type, filename, dbms_crypto.HASH(object, dbms_crypto.hash_sh1)
          FROM aspen2.filecache 
         WHERE cache_key = in_cache_key;
    
    IF SQL%ROWCOUNT = 0 THEN
    	-- pah! not found
        RAISE_APPLICATION_ERROR(-20001, 'Cache Key "'||in_cache_key||'" not found');
    END IF;
END;

PROCEDURE GetHelpFileData(		  
	in_act				IN security_pkg.T_ACT_ID,
	in_file_id			IN help_file.help_file_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT help_file_id, data, mime_type, last_updated_dtm, label
		  FROM help_file
		 WHERE help_file_id = in_file_id;
END;

--
-- Navigation
--

PROCEDURE GetBreadcrumbTrail(
	in_act 				IN security_pkg.T_ACT_ID,
	in_app_sid		IN security_pkg.T_SID_ID,
	in_lang_id			IN help_lang.help_lang_id%TYPE,
	in_topic_id			IN help_topic.help_topic_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT h.help_topic_id, t.help_lang_id, h.parent_id, t.title, LEVEL 
		  FROM help_topic h, help_topic_text t
			START WITH h.help_topic_id = in_topic_id
				AND t.help_topic_id = h.help_topic_id
				AND t.help_lang_id = ResolveLangIdForTopic(in_app_sid, in_lang_id, t.help_topic_id)
			CONNECT BY PRIOR h.parent_id = h.help_topic_id
				AND t.help_topic_id = h.help_topic_id
				AND t.help_lang_id = ResolveLangIdForTopic(in_app_sid, in_lang_id, t.help_topic_id)
		ORDER BY level DESC;
END;

PROCEDURE GetTreeNodeChildren(
	in_act 				IN security_pkg.T_ACT_ID,
	in_app_sid		IN security_pkg.T_SID_ID,
	in_lang_id			IN help_lang.help_lang_id%TYPE,
	in_parent_id 		IN security_pkg.T_SID_ID,
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- TODO: need to associate topic tree with csr root sid

	OPEN out_cur FOR
		SELECT h.help_topic_id, h.parent_id, t.help_lang_id, h.pos, t.title, 
			l.short_name language_class, SecurableObjectChildCount(in_act, h.help_topic_id) has_children
		  FROM help_topic h, help_topic_text t, help_lang l
		 WHERE NVL(h.parent_id,0) = NVL(in_parent_id,0)
		   AND t.help_topic_id = h.help_topic_id
		   AND t.help_lang_id = ResolveLangIdForTopic(in_app_sid, in_lang_id, h.help_topic_id)
		   AND l.help_lang_id = t.help_lang_id
		   	ORDER BY h.pos ASC;
END;

PROCEDURE GetPathDownTopics(
	in_act 				IN security_pkg.T_ACT_ID,
	in_app_sid		IN security_pkg.T_SID_ID,
	in_lang_id			IN help_lang.help_lang_id%TYPE,
	in_start_id 		IN security_pkg.T_SID_ID,
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF in_start_id IS NULL THEN
		OPEN out_cur FOR
			SELECT h.help_topic_id, h.parent_id, t.title, t.body, LEVEL
			FROM help_topic h, help_topic_text t
			START WITH h.parent_id IS NULL -- gets everything under the root
			    AND t.help_topic_id = h.help_topic_id 
			    AND t.help_lang_id = ResolveLangIdForTopic(in_app_sid, in_lang_id, h.help_topic_id)
			CONNECT BY PRIOR h.help_topic_id = parent_id
			    AND t.help_topic_id = h.help_topic_id
			    AND t.help_lang_id = ResolveLangIdForTopic(in_app_sid, in_lang_id, h.help_topic_id)
			ORDER BY LEVEL ASC, pos ASC;
	ELSE
		OPEN out_cur FOR
			SELECT h.help_topic_id, h.parent_id, t.title, t.body, LEVEL
			FROM help_topic h, help_topic_text t
			START WITH h.help_topic_id = in_start_id -- gets this node and its descendents
			    AND t.help_topic_id = h.help_topic_id
			    AND t.help_lang_id = ResolveLangIdForTopic(in_app_sid, in_lang_id, h.help_topic_id)
			CONNECT BY PRIOR h.help_topic_id = parent_id
			    AND t.help_topic_id = h.help_topic_id
			    AND t.help_lang_id = ResolveLangIdForTopic(in_app_sid, in_lang_id, h.help_topic_id)
			ORDER BY LEVEL ASC, pos ASC;
	END IF;
END;

PROCEDURE ExportHelp(
	out_cur_lang		OUT	security_pkg.T_OUTPUT_CUR,
	out_cur_topics		OUT	security_pkg.T_OUTPUT_CUR,
	out_cur_files		OUT	security_pkg.T_OUTPUT_CUR,
	out_cur_topic_files	OUT	security_pkg.T_OUTPUT_CUR,
	out_cur_topic_text	OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_topic_sids	security.T_SID_TABLE;
BEGIN
	-- gets all the relevant IDs -- i.e. doesn't take topics where the help language
	-- is not relevant for the current customer (e.g. won't take specific topics for
	-- another customer's 'language').
	SELECT x.help_topic_id
       BULK COLLECT INTO v_topic_sids
	  FROM (
		 SELECT help_topic_id, rownum rn
		   FROM help_topic
		  START WITH parent_id IS NULL
		CONNECT BY PRIOR help_topic_id = parent_id
	  )x, (
		 SELECT help_topic_id
		   FROM help_topic_text htt, help_lang hl, customer_help_lang chl
		  WHERE htt.help_lang_id = hl.help_lang_id
			AND hl.help_lang_id = chl.help_lang_id
		    AND chl.app_sid = security_pkg.GetApp
		  UNION
		 SELECT help_topic_id
		   FROM help_topic_file htf, help_lang hl, customer_help_lang chl
		  WHERE htf.help_lang_id = hl.help_lang_id
			AND hl.help_lang_id = chl.help_lang_id
		    AND chl.app_sid = security_pkg.GetApp
	  ) htx
	WHERE x.help_topic_id = htx.help_topic_id
	ORDER BY x.rn;
		
	OPEN out_cur_lang FOR
		SELECT hl.help_Lang_id, hl.base_lang_id, hl.label, hl.short_name
		  FROM customer_help_lang chl, help_lang hl
		 WHERE chl.help_Lang_id = hl.help_lang_id
		   AND chl.app_sid = security_pkg.GetApp
		 START WITH hl.base_lang_id IS NULL
		CONNECT BY PRIOR hl.help_lang_id = hl.base_lang_id;
	
	OPEN out_cur_topics FOR
		-- we reexecute this so that we preserve the order
		SELECT ht.*
		   FROM (
			 SELECT help_topic_id, parent_id, lookup_name, pos, hits, votes, score, rownum rn
			   FROM help_topic
			  START WITH parent_id IS NULL
			CONNECT BY PRIOR help_topic_id = parent_id
		  )ht
		 WHERE help_topic_id IN (
			SELECT column_value FROM TABLE(v_topic_sids)
		 )
		 ORDER BY rn; 

	OPEN out_cur_files FOR
		 SELECT help_file_id, data, last_updated_dtm, mime_type, label, data_hash
		   FROM help_file
		  WHERE help_file_id IN (
			SELECT help_file_id
	  	      FROM help_topic_file
		  	 WHERE help_topic_id IN (
		  	 	SELECT column_value FROM TABLE(v_topic_sids)
		  	 )
		  );
   
	OPEN out_cur_topic_files FOR
		 SELECT help_topic_id, help_lang_id, help_file_id
		   FROM help_topic_file
		  WHERE help_topic_id IN (
		  	SELECT column_value FROM TABLE(v_topic_sids)
		  ) AND help_lang_id IN (
			SELECT help_lang_id FROM customer_help_lang WHERE app_sid = security_pkg.GetApp
		  );

    OPEN out_cur_topic_text FOR
		 SELECT help_topic_id, help_lang_id, title, body, last_updated_dtm
		   FROM help_topic_text
		  WHERE help_topic_id IN (
		  	SELECT column_value FROM TABLE(v_topic_sids)
		  ) AND help_lang_id IN (
			SELECT help_lang_id FROM customer_help_lang WHERE app_sid = security_pkg.GetApp
		  ); 
END;

PROCEDURE ImportLanguage(
	in_base_lang_Id		IN	help_lang.base_Lang_id%TYPE,
	in_label			IN	help_lang.label%TYPE,
	in_short_name		IN	help_Lang.short_name%TYPE,
	out_help_lang_id	OUT	help_lang.help_lang_id%TYPE
)
AS
BEGIN
	-- hmm - no PK on HELP_LANG.LABEL - we rely on the label being unique for the current app under the specified base lang id. Ick.
	BEGIN
		SELECT hl.help_Lang_id
		  INTO out_help_lang_id
		  FROM customer_help_lang chl, help_lang hl
		 WHERE chl.help_Lang_id = hl.help_lang_id
		   AND chl.app_sid = security_pkg.GetApp
		   AND LOWER(label) = LOWER(in_label)
		   AND (base_lang_id = in_base_lang_id OR (base_lang_Id IS NULL AND in_base_lang_id IS NULL));
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			AddLanguage(security_pkg.GetACT, in_base_lang_id, in_label, out_help_lang_id);
			INSERT INTO CUSTOMER_HELP_LANG (
				app_sid, help_lang_id, is_default
			) VALUES (
				security_pkg.GetApp, out_help_lang_id, 0
			);
	END;
END;

PROCEDURE ImportTopic(
	in_parent_id		IN	security_pkg.T_SID_ID,
	in_lookup_name		IN	help_topic.lookup_name%TYPE,
	in_pos				IN	help_topic.pos%TYPE,
	in_hits				IN	help_topic.hits%TYPE,
	in_votes			IN	help_topic.votes%TYPE,
	in_score			IN	help_topic.score%TYPE,
	out_topic_Id		OUT	security_pkg.T_SID_ID
)
AS
	v_parent_id			security_pkg.T_SID_ID;
	v_topic_id			security_pkg.T_SID_ID;
BEGIN
	v_parent_id := COALESCE(in_parent_id, securableobject_pkg.GetSIDFromPath(security_pkg.GetACT, 0, 'csr/Help'));

	-- CreateSO will call helper in this package
	BEGIN
		securableobject_pkg.CreateSO(security_pkg.GetACT, v_parent_id, 
			class_pkg.getClassID('CSRHelpTopic'), in_lookup_name, v_topic_id);
		-- bit naughty but we don't want any RLS applied to this
		UPDATE security.securable_object 
		   SET application_sid_id = NULL
		 WHERE sid_id = v_topic_id;
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			v_topic_Id := securableobject_pkg.GetSIDFromPath(security_pkg.GetACT, v_parent_id, in_lookup_name);
	END;
	
	UPDATE help_topic
	   SET pos = in_pos, hits = in_hits, votes = in_votes, score = in_score
	 WHERE help_topic_id = v_topic_id;
	
	out_topic_id := v_topic_id;
END;

PROCEDURE ImportFile(
	in_hash				IN	help_file.data_hash%TYPE,
	in_last_updated_dtm	IN	help_file.last_updated_dtm%TYPE,
	in_mime_type		IN	help_file.mime_type%TYPE,
	in_label			IN	help_file.label%TYPE,
	out_file_Id			OUT	help_file.help_file_id%TYPE,
	out_data			OUT	help_file.data%TYPE
)
AS
BEGIN
	-- we added the hashes later so it's possible there are multiple rows with the same hash (might fix this later by exporting/reimporting)
	-- for now assume the worst!
	BEGIN
		SELECT help_file_id 
		  INTO out_file_Id
		  FROM (
		   SELECT help_file_id, rownum rn
			 FROM help_file
			WHERE data_hash = in_hash
		 )
		 WHERE rn = 1;
		 out_data := null;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- TODO: hmm -- what if this is an update and it already exists --it'll blow up?
			INSERT INTO HELP_FILE (
				help_file_id, data, last_updated_dtm, mime_type, label, data_hash
			) VALUES (
				help_file_id_seq.nextval, EMPTY_BLOB(), in_last_updated_dtm, in_mime_type, in_label, in_hash
			) RETURNING help_file_id, data INTO out_file_id, out_data;
	END;
END;

PROCEDURE ImportTopicFileLink(
	in_help_topic_id	IN	help_topic_file.help_topic_id%TYPE, 
	in_help_Lang_id 	IN  help_topic_file.help_Lang_id%TYPE,
	in_help_file_id		IN	help_topic_file.help_file_id%TYPE
)
AS
BEGIN
	BEGIN
		INSERT INTO help_topic_file (
			help_topic_id, help_lang_id, help_file_Id
		) VALUES (
			in_help_topic_id, in_help_Lang_id, in_help_file_id
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL; -- ignore if already in there
	END;
END;

PROCEDURE ImportText(
	in_topic_id			IN	help_topic_text.help_topic_id%TYPE,
	in_help_Lang_id 	IN  help_topic_text.help_Lang_id%TYPE,
	in_title			IN	help_topic_text.title%TYPE,
	in_last_updated_dtm	IN	help_topic_text.last_updated_dtm%TYPE,
	out_body			OUT	help_topic_text.body%TYPE
)
AS
BEGIN
	BEGIN
		INSERT INTO help_topic_text (
			help_topic_id, help_lang_id, title, last_updated_dtm, body
		) VALUES (
			in_topic_id, in_help_lang_id, in_title, in_last_updated_dtm, EMPTY_CLOB()
		) RETURNING body INTO out_body;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE help_topic_text
			   SET title = in_title,
				last_updated_dtm = in_last_updated_dtm
			 WHERE help_topic_id = in_topic_id
			   AND help_lang_id = in_help_lang_id
			RETURNING body INTO out_body;
	END;
END;

PROCEDURE GetHelpTopic(
	in_act 				IN security_pkg.T_ACT_ID,
	in_app_sid			IN security_pkg.T_SID_ID,
	in_topic_id			IN	help_topic_text.help_topic_id%TYPE,
	in_help_lang_id		IN  help_topic_text.help_Lang_id%TYPE,
	out_topic_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_file_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act, in_topic_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on help topic object with sid '||in_topic_id);
	END IF;
	
	OPEN out_topic_cur FOR
		SELECT *
		  FROM (
				SELECT htt.help_topic_id, htt.title, htt.body, htt.last_updated_dtm, ht.lookup_name, hl.help_lang_id, hl.short_name language_class, ROW_NUMBER() OVER (PARTITION BY htt.help_topic_id ORDER BY hl.lang_priority) lang_priority_rn
				  FROM help_topic_text htt
				  JOIN help_topic ht
				    ON htt.help_topic_id = ht.help_topic_id
				  JOIN (
						SELECT level lang_priority, help_lang_id, short_name
						  FROM help_lang
						 START WITH help_lang_id = in_help_lang_id
						CONNECT BY PRIOR base_lang_id = help_lang_id
				) hl
				    ON htt.help_lang_id = hl.help_lang_id
				 WHERE htt.help_topic_id = in_topic_id
		)
		 WHERE lang_priority_rn = 1;
		 
	OPEN out_file_cur FOR
		SELECT htf.help_file_id, hf.label file_name, hf.mime_type
		  FROM (
				SELECT hl.help_lang_id, ROW_NUMBER() OVER (PARTITION BY htt.help_topic_id ORDER BY hl.lang_priority) lang_priority_rn
				  FROM help_topic_text htt
				  JOIN (
						SELECT level lang_priority, help_lang_id, short_name
						  FROM help_lang
						 START WITH help_lang_id = in_help_lang_id
						CONNECT BY PRIOR base_lang_id = help_lang_id
				) hl
				    ON htt.help_lang_id = hl.help_lang_id
				 WHERE htt.help_topic_id = in_topic_id
		) hl
		  JOIN help_topic_file htf
		    ON htf.help_topic_id = in_topic_id
		   AND htf.help_lang_id = hl.help_lang_id
		  JOIN help_file hf
		    ON htf.help_file_id = hf.help_file_id
		 WHERE lang_priority_rn = 1;
END;

PROCEDURE GetHelpTopicWithTrail(
	in_act 				IN security_pkg.T_ACT_ID,
	in_app_sid			IN security_pkg.T_SID_ID,
	in_topic_id			IN	help_topic_text.help_topic_id%TYPE,
	in_help_lang_id		IN  help_topic_text.help_Lang_id%TYPE,
	out_topic_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_file_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_trail_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act, in_topic_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on help topic object with sid '||in_topic_id);
	END IF;
	
	OPEN out_topic_cur FOR
		SELECT *
		  FROM (
				SELECT htt.help_topic_id, htt.title, htt.body, hl.help_lang_id, ROW_NUMBER() OVER (PARTITION BY htt.help_topic_id ORDER BY hl.lang_priority) lang_priority_rn
				  FROM help_topic_text htt
				  JOIN help_topic ht
				    ON htt.help_topic_id = ht.help_topic_id
				  JOIN (
						SELECT level lang_priority, help_lang_id, short_name
						  FROM help_lang
						 START WITH help_lang_id = in_help_lang_id
						CONNECT BY PRIOR base_lang_id = help_lang_id
				) hl
				    ON htt.help_lang_id = hl.help_lang_id
				 WHERE htt.help_topic_id = in_topic_id
		)
		 WHERE lang_priority_rn = 1;
		 
	OPEN out_file_cur FOR
		SELECT htf.help_file_id, hf.label file_name, hf.mime_type
		  FROM (
				SELECT hl.help_lang_id, ROW_NUMBER() OVER (PARTITION BY htt.help_topic_id ORDER BY hl.lang_priority) lang_priority_rn
				  FROM help_topic_text htt
				  JOIN (
						SELECT level lang_priority, help_lang_id, short_name
						  FROM help_lang
						 START WITH help_lang_id = in_help_lang_id
						CONNECT BY PRIOR base_lang_id = help_lang_id
				) hl
				    ON htt.help_lang_id = hl.help_lang_id
				 WHERE htt.help_topic_id = in_topic_id
		) hl
		  JOIN help_topic_file htf
		    ON htf.help_topic_id = in_topic_id
		   AND htf.help_lang_id = hl.help_lang_id
		  JOIN help_file hf
		    ON htf.help_file_id = hf.help_file_id
		 WHERE lang_priority_rn = 1;
	
	OPEN out_trail_cur FOR	
		SELECT *
		  FROM (
				SELECT htt.title, htt.help_topic_id, ht.l, ROW_NUMBER() OVER (PARTITION BY htt.help_topic_id ORDER BY hl.language_priority) language_priority_rn
				  FROM help_topic_text htt
				  JOIN (
						SELECT LEVEL l, help_topic_id
						  FROM help_topic 
						 START WITH help_topic_id = in_topic_id
						CONNECT BY PRIOR parent_id = help_topic_id
				) ht
				    ON ht.help_topic_id = htt.help_topic_id
				  JOIN (
						SELECT level language_priority, help_lang_id
						  FROM help_lang
						 START WITH help_lang_id = in_help_lang_id
						CONNECT BY PRIOR base_lang_id = help_lang_id
				) hl
				    ON hl.help_lang_id = htt.help_lang_id
		)
		 WHERE language_priority_rn = 1
		 ORDER BY l DESC;
END;

PROCEDURE SearchTopicTitle(
	in_topic_title		IN	VARCHAR2,
	in_help_lang_id		IN  help_topic_text.help_Lang_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT title, help_topic_id
		  FROM (
				SELECT htt.title, htt.help_topic_id, ROW_NUMBER() OVER (PARTITION BY htt.help_topic_id ORDER BY hl.lang_priority) lang_priority_rn
				  FROM help_topic_text htt
				  JOIN (
						SELECT level lang_priority, help_lang_id
						  FROM help_lang
						 START WITH help_lang_id = in_help_lang_id
						CONNECT BY PRIOR base_lang_id = help_lang_id
				) hl
					ON htt.help_lang_id = hl.help_lang_id
		)
		 WHERE title
		  LIKE '%' || in_topic_title || '%'
		   AND lang_priority_rn = 1;
END;

PROCEDURE SearchTopicText(
	in_topic_text		IN	VARCHAR2,
	in_help_lang_id		IN  help_topic_text.help_Lang_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_act_id	security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
	v_app_sid	security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(v_act_id, v_app_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	ctx_doc.set_key_type('ROWID');
	
	OPEN out_cur FOR
		SELECT title, help_topic_id, ctx_doc.snippet('ix_help_body_search', rid, in_topic_text) text
		  FROM (
				-- NOTE: There is a bug in Oracle 11g (BUG: 9149005/14113225) using CONTAINS with ANSI joins, the workaround is to use oracle style joins
				SELECT htt.rowid rid, htt.title, htt.help_topic_id, ROW_NUMBER() OVER (PARTITION BY htt.help_topic_id ORDER BY hl.lang_priority) lang_priority_rn
				  FROM help_topic_text htt, (
						SELECT level lang_priority, help_lang_id
						  FROM help_lang
						 START WITH help_lang_id = in_help_lang_id
						CONNECT BY PRIOR base_lang_id = help_lang_id
				       ) hl
				 WHERE htt.help_lang_id = hl.help_lang_id
				   AND contains(htt.body, in_topic_text, 1) > 0
		) 
		 WHERE lang_priority_rn = 1;
END;

PROCEDURE GetPath(
	in_topic_id			IN	help_topic_text.help_topic_id%TYPE,
	in_help_lang_id		IN  help_topic_text.help_Lang_id%TYPE,
	out_path			OUT	VARCHAR
)
AS
BEGIN
	SELECT REPLACE(title_path, '', ' / ') 
	  INTO out_path
	  FROM (
			SELECT title_path, ROW_NUMBER() OVER (PARTITION BY help_topic_id ORDER BY node_order DESC) node_root_rn
			  FROM (
					SELECT LEVEL node_order, help_topic_id,
							SYS_CONNECT_BY_PATH((
								SELECT title
								  FROM (
										SELECT htt.title, htt.help_topic_id, ROW_NUMBER() OVER (PARTITION BY htt.help_topic_id ORDER BY hl.lang_priority) lang_priority_rn
										  FROM help_topic_text htt
										  JOIN (
												SELECT level lang_priority, help_lang_id
												  FROM help_lang
												 START WITH help_lang_id = in_help_lang_id
												CONNECT BY PRIOR base_lang_id = help_lang_id
										) hl
										    ON htt.help_lang_id = hl.help_lang_id
								)
								 WHERE lang_priority_rn = 1
								   AND help_topic_id = ht.help_topic_id
							), '') title_path
					  FROM help_topic ht
					 START WITH parent_id IS NULL
					CONNECT BY PRIOR help_topic_id = parent_id
			)
			 WHERE help_topic_id = in_topic_id
	)
	 WHERE node_root_rn = 1;
END;

PROCEDURE GetIdPath(
	in_topic_id			IN	help_topic_text.help_topic_id%TYPE,
	out_path			OUT	VARCHAR
)
AS
BEGIN
	SELECT id_path
	  INTO out_path
	  FROM (
			SELECT help_topic_id, SYS_CONNECT_BY_PATH((help_topic_id), '/') id_path
			  FROM help_topic ht
			 START WITH parent_id IS NULL
			CONNECT BY PRIOR help_topic_id = parent_id
	)
	 WHERE help_topic_id = in_topic_id;
END;

PROCEDURE GetItemsUsingImage(
	in_image_id			IN  help_image.image_id%TYPE,
	out_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT hti.help_topic_id, hti.help_lang_id
		  FROM help_topic_image hti
		 WHERE hti.help_image_id = in_image_id;
END;

PROCEDURE AttachFile(
	in_act 				IN security_pkg.T_ACT_ID,
	in_app_sid			IN security_pkg.T_SID_ID,
	in_topic_id			IN	help_topic_text.help_topic_id%TYPE,
	in_help_lang_id		IN  help_topic_text.help_Lang_id%TYPE,
	in_filename			IN 	file_upload.filename%TYPE,
	in_mime_type		IN	file_upload.mime_type%type,
	in_data				IN	file_upload.data%TYPE,
	out_help_file_id	OUT	security_pkg.T_SID_ID
)
AS
BEGIN
	CheckEditAccessRights(in_act, in_app_sid, in_topic_id, in_help_lang_id);
	
	INSERT INTO help_file
		(help_file_id, data, mime_type, label, data_hash)
	VALUES
		(help_file_id_seq.NEXTVAL, in_data, in_mime_type, in_filename,
		 dbms_crypto.hash(in_data, dbms_crypto.hash_sh1))
	RETURNING help_file_id INTO out_help_file_id;
	
	INSERT INTO help_topic_file
		(help_topic_id, help_lang_id, help_file_id)
	VALUES
		(in_topic_id, in_help_lang_id, out_help_file_id);
END;

PROCEDURE DownloadFile(
	in_act 				IN security_pkg.T_ACT_ID,
	in_topic_id			IN security_pkg.T_SID_ID,
	in_help_file_id		IN security_pkg.T_SID_ID,
	out_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act, in_topic_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on help topic object with sid '||in_topic_id);
	END IF;
	
	OPEN out_cur FOR
		SELECT hf.data, hf.mime_type, hf.label
		  FROM help_file hf
		 WHERE hf.help_file_id = in_help_file_id;
END;

PROCEDURE RemoveFile(
	in_act 				IN security_pkg.T_ACT_ID,
	in_app_sid			IN security_pkg.T_SID_ID,
	in_topic_id			IN	help_topic_text.help_topic_id%TYPE,
	in_help_lang_id		IN  help_topic_text.help_Lang_id%TYPE,
	in_help_file_id		IN	security_pkg.T_SID_ID
)
AS
	v_count			NUMBER(10);
BEGIN
	CheckEditAccessRights(in_act, in_app_sid, in_topic_id, in_help_lang_id);
	
	DELETE FROM help_topic_file htf
	 WHERE htf.help_topic_id = in_topic_id
	   AND htf.help_lang_id = in_help_lang_id
	   AND htf.help_file_id = in_help_file_id;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM help_topic_file htf
	 WHERE htf.help_file_id = in_help_file_id;
	 
	IF v_count = 0 THEN
		DELETE FROM help_file hf
		 WHERE hf.help_file_id = in_help_file_id;
	END IF;
END;

PROCEDURE CopyTopic(
	in_act 				IN security_pkg.T_ACT_ID,
	in_app_sid			IN security_pkg.T_SID_ID,
	in_topic_id			IN security_pkg.T_SID_ID,
	in_lang_id			IN help_lang.help_lang_id%TYPE
)
AS
	v_count				NUMBER(10);
	v_lang_id			NUMBER(10);
BEGIN
	-- Check this user's rights on this topic in this language
	CheckEditAccessRights(in_act, in_app_sid, in_topic_id, in_lang_id);
	
	-- Check for valid language id
	v_count := 0;
	IF in_lang_id IS NOT NULL THEN
		SELECT COUNT(0)
		  INTO v_count
		  FROM help_lang
		 WHERE help_lang_id = in_lang_id;
	END IF;
	
	IF v_count = 0 THEN
		RAISE_APPLICATION_ERROR(ERR_INVALID_LANG, 'Language with id '||in_lang_id||', was not found.');
	END IF;
	
	SELECT COUNT(0)
	  INTO v_count
	  FROM help_topic_text
	 WHERE help_topic_id = in_topic_id
	   AND help_lang_id = in_lang_id;
	   
	-- Copy topic if not already exist
	If v_count = 0 THEN
		SELECT help_lang_id
		  INTO v_lang_id
		  FROM (
				SELECT hl.help_lang_id, ROW_NUMBER() OVER (PARTITION BY htt.help_topic_id ORDER BY hl.lang_priority) lang_priority_rn
				  FROM help_topic_text htt
				  JOIN (
						SELECT level lang_priority, help_lang_id
						  FROM help_lang
						 START WITH help_lang_id = in_lang_id
						CONNECT BY PRIOR base_lang_id = help_lang_id
						) hl
					ON htt.help_lang_id = hl.help_lang_id
				 WHERE htt.help_topic_id = in_topic_id
		)
		 WHERE lang_priority_rn = 1;
	
		INSERT INTO help_topic_text
			(help_topic_id, help_lang_id, title, body)
		SELECT in_topic_id, in_lang_id, title, body
		  FROM help_topic_text htt
		 WHERE htt.help_topic_id = in_topic_id
		   AND htt.help_lang_id = v_lang_id;
		
		INSERT INTO help_topic_file
			(help_topic_id, help_lang_id, help_file_id)
		SELECT in_topic_id, in_lang_id, help_file_id
		  FROM help_topic_file htf
		 WHERE htf.help_topic_id = in_topic_id
		   AND htf.help_lang_id = v_lang_id;
	END IF;
END;

PROCEDURE ValidateTopicId(
	in_topic_id			IN security_pkg.T_SID_ID,
	out_topic_id		OUT security_pkg.T_SID_ID
)
AS
BEGIN
	SELECT help_topic_id
	  INTO out_topic_id
	  FROM (
			SELECT help_topic_id, ROW_NUMBER() OVER (ORDER BY row_number) row_number
			  FROM (
					SELECT help_topic_id, 0 row_number
					  FROM help_topic
					 WHERE help_topic_id = in_topic_id
					 UNION
					SELECT help_topic_id, ROW_NUMBER() OVER (ORDER BY pos) row_number
					  FROM help_topic
					 WHERE parent_id IS NULL
			)
	)
	 WHERE row_number = 1;
END;

PROCEDURE GetTopicChildren(
	in_act 				IN security_pkg.T_ACT_ID,
	in_app_sid			IN security_pkg.T_SID_ID,	
	in_parent_id 		IN security_pkg.T_SID_ID,
	in_lang_id			IN help_lang.help_lang_id%TYPE,
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act, in_parent_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on help topic object with sid '||in_parent_id);
	END IF;

	OPEN out_cur FOR
		SELECT *
		  FROM (
				SELECT ht.help_topic_id, ht.parent_id, ht.pos, htt.title, htt.help_lang_id, hl.short_name language_class,
						SecurableObjectChildCount(in_act, ht.help_topic_id) has_children, ROW_NUMBER() OVER (PARTITION BY htt.help_topic_id ORDER BY hl.lang_priority) lang_priority_rn
				  FROM help_topic_text htt
				  JOIN help_topic ht
				    ON htt.help_topic_id = ht.help_topic_id
				  JOIN (
						SELECT level lang_priority, help_lang_id, short_name
						  FROM help_lang
						 START WITH help_lang_id = in_lang_id
						CONNECT BY PRIOR base_lang_id = help_lang_id
				) hl
				    ON htt.help_lang_id = hl.help_lang_id
				  WHERE NVL(ht.parent_id, 0) = NVL(in_parent_id, 0)
				 ORDER BY ht.pos ASC
		)
		 WHERE lang_priority_rn = 1;
END;

PROCEDURE SetTopicImage(
	in_act 				IN security_pkg.T_ACT_ID,
	in_app_sid			IN security_pkg.T_SID_ID,
	in_topic_id			IN security_pkg.T_SID_ID,
	in_lang_id			IN help_lang.help_lang_id%TYPE,
	in_image_ids		IN security_pkg.T_SID_IDS
)
IS
	t security.T_SID_TABLE;
BEGIN
	-- Check this user's rights on this topic in this language
	CheckEditAccessRights(in_act, in_app_sid, in_topic_id, in_lang_id);
	
	t := security_pkg.SidArrayToTable(in_image_ids);
	
	DELETE FROM help_topic_image hti
	 WHERE hti.help_topic_id = in_topic_id
	   AND hti.help_lang_id = in_lang_id;
	   
	INSERT INTO help_topic_image (help_topic_id, help_lang_id, help_image_id)
	SELECT in_topic_id, in_lang_id, image_id
	  FROM (
			SELECT column_value image_id
			  FROM TABLE(t)
	);
END;

PROCEDURE SetTopicParent(
	in_act 				IN security_pkg.T_ACT_ID,
	in_app_sid			IN security_pkg.T_SID_ID,
	in_topic_id			IN security_pkg.T_SID_ID,
	in_parent_id		IN security_pkg.T_SID_ID,
	in_lang_id			IN help_lang.help_lang_id%TYPE
)
AS
	v_parent_id			security_pkg.T_SID_ID;
BEGIN
	v_parent_id := COALESCE(in_parent_id, securableobject_pkg.GetSIDFromPath(in_act, 0, 'csr/Help'));

	-- Check this user's rights on this topic in this language
	CheckEditAccessRights(in_act, in_app_sid, in_topic_id, in_lang_id);
	CheckEditAccessRights(in_act, in_app_sid, v_parent_id, in_lang_id);
	
	securableobject_pkg.MoveSO(in_act, in_topic_id, v_parent_id);
	
	 UPDATE help_topic
	    SET parent_id = in_parent_id
	  WHERE help_topic_id = in_topic_id;
END;

PROCEDURE GetTopicPath(
	in_act 				IN security_pkg.T_ACT_ID,
	in_app_sid			IN security_pkg.T_SID_ID,
	in_topic_id			IN security_pkg.T_SID_ID,
	out_cur				OUT VARCHAR2
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act, in_topic_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on help topic object with sid '||in_topic_id);
	END IF;
	
	SELECT path
	  INTO out_cur
	  FROM (
			SELECT path, ROW_NUMBER() OVER (ORDER BY node_order DESC) row_number
			  FROM (
					SELECT LEVEL node_order, SYS_CONNECT_BY_PATH(help_topic_id, '/') path
					  FROM help_topic
					 START WITH help_topic_id = in_topic_id
					CONNECT BY PRIOR parent_id = help_topic_id
			)
	)
	 WHERE row_number = 1;
END;

END help_Pkg;
/
