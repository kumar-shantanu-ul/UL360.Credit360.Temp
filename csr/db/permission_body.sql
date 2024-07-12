CREATE OR REPLACE PACKAGE BODY CSR.permission_pkg AS

PROCEDURE INTERNAL_AddMiscSid(
	in_sid							IN		security_pkg.T_SID_ID,
	io_sid_table					IN OUT	security.T_SID_TABLE
)
AS
BEGIN
	io_sid_table.EXTEND;
	io_sid_table(io_sid_table.COUNT) := in_sid;
END;

PROCEDURE INTERNAL_AddMiscSid(
	in_parent_sid					IN		security_pkg.T_SID_ID,
	in_path							IN		VARCHAR2,
	io_sid_table					IN OUT	security.T_SID_TABLE,
	out_sid							OUT		security_pkg.T_SID_ID
)
AS
BEGIN
	BEGIN
		out_sid := securableObject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY', 'ACT'),
			in_parent_sid, in_path);
		INTERNAL_AddMiscSid(out_sid, io_sid_table);
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;
END;

PROCEDURE GetSections(
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_act_id						security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
	v_app_sid						security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	v_sent_mail_sid					security_pkg.T_SID_ID;
	v_outbox_sid					security_pkg.T_SID_ID;
	v_wwwroot_sid					security_pkg.T_SID_ID;
	v_surveys_sid					security_pkg.T_SID_ID;
	v_question_library_sid			security_pkg.T_SID_ID;
	v_feeds_sid						security_pkg.T_SID_ID;
	v_schemes_sid					security_pkg.T_SID_ID;
	v_misc_sids						security.T_SID_TABLE := security.T_SID_TABLE();
BEGIN
	v_sent_mail_sid := alert_pkg.GetSystemMailbox('Sent');
	INTERNAL_AddMiscSid(v_sent_mail_sid, v_misc_sids);
	v_outbox_sid := alert_pkg.GetSystemMailbox('Outbox');
	INTERNAL_AddMiscSid(v_outbox_sid, v_misc_sids);
	v_wwwroot_sid := securableObject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'wwwroot');
	INTERNAL_AddMiscSid(v_wwwroot_sid, 'Surveys', v_misc_sids, v_surveys_sid);
	INTERNAL_AddMiscSid(v_app_sid, 'QuestionLibrary', v_misc_sids, v_question_library_sid);
	INTERNAL_AddMiscSid(v_wwwroot_sid, 'Feeds', v_misc_sids, v_feeds_sid);
	INTERNAL_AddMiscSid(v_app_sid, 'Donations/Schemes', v_misc_sids, v_schemes_sid);

	OPEN out_cur FOR
		SELECT so.sid_id, so.name, soc.class_name
		  FROM TABLE ( SecurableObject_pkg.GetChildrenWithPermAsTable(v_act_id, v_app_sid, security_pkg.PERMISSION_READ) ) so
		  JOIN security.securable_object_class soc ON so.class_id = soc.class_id		  
		 UNION ALL
		SELECT m.sid_id, m.name, m.class_name
		 FROM (SELECT v_sent_mail_sid sid_id, '@mailbox/Sent' name, 'CSRMailbox' class_name FROM DUAL
				UNION ALL
			   SELECT v_outbox_sid, '@mailbox/Outbox', 'CSRMailbox' FROM DUAL
				UNION ALL
			   SELECT v_schemes_sid, 'Donations/Schemes', 'Container' FROM DUAL
				UNION ALL
			   SELECT v_feeds_sid, 'wwwroot/Feeds', 'Webresource' FROM DUAL
				UNION ALL
			   SELECT v_surveys_sid, 'wwwroot/Surveys', 'Webresource' FROM DUAL) m,
			  TABLE( SecurableObject_pkg.GetSIDsWithPermAsTable(v_act_id, v_misc_sids, security_pkg.PERMISSION_READ) ) p
		WHERE p.sid_id = m.sid_id;
END;

PROCEDURE GetTreeWithDepth(
	in_parent_sid					IN	security.security_pkg.T_SID_ID,
	in_fetch_depth					IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN     
    OPEN out_cur FOR
		SELECT so.sid_id, so.parent_sid_id, NVL(m.description, NVL(df.translated, so.name)) name, so.so_level,
			   so.is_leaf, 1 is_match, soc.class_name
    	  FROM (SELECT so.*, ROWNUM rn
    	  		  FROM TABLE(SecurableObject_pkg.GetTreeWithPermAsTable(SYS_CONTEXT('SECURITY', 'ACT'),
    					in_parent_sid, security.security_pkg.PERMISSION_READ, in_fetch_depth, null, 1)) so) so
		  JOIN security.securable_object_class soc ON so.class_id = soc.class_id
		  LEFT JOIN security.menu m ON so.sid_id = m.sid_id
		  LEFT JOIN v$doc_folder df ON so.sid_id = df.doc_folder_sid
		 ORDER BY so.rn;
END;

PROCEDURE GetTreeTextFiltered(
	in_parent_sid					IN	security.security_pkg.T_SID_ID,
	in_search_phrase				IN	VARCHAR2,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT t.sid_id, t.parent_sid_id, NVL(m.description, NVL(df.translated, t.name)) name, t.so_level,
			   t.is_leaf, NVL(mt.is_match, 0) is_match, soc.class_name
		  FROM (SELECT rownum rn, so.sid_id, so.parent_sid_id, so.name, so.so_level, so.is_leaf, so.class_id
		  	  	  FROM TABLE(SecurableObject_pkg.GetTreeWithPermAsTable(SYS_CONTEXT('SECURITY', 'ACT'),
						in_parent_sid, security.security_pkg.PERMISSION_READ, null, null, 1)) so) t
		  JOIN security.securable_object_class soc ON t.class_id = soc.class_id
		  JOIN (SELECT DISTINCT sid_id
				  FROM security.securable_object
					   START WITH sid_id IN (
					   	   SELECT so2.sid_id
				      		 FROM security.securable_object so2
				      		 LEFT JOIN security.menu m ON so2.sid_id = m.sid_id
							 LEFT JOIN v$doc_folder df ON so2.sid_id = df.doc_folder_sid
							WHERE LOWER(NVL(m.description, NVL(df.translated, so2.name))) LIKE '%'||LOWER(in_search_phrase)||'%'
								  START WITH so2.sid_id = in_parent_sid
								  CONNECT BY PRIOR so2.sid_id = so2.parent_sid_id)
				       CONNECT BY PRIOR parent_sid_id = sid_id) ti
			 ON t.sid_id = ti.sid_id
	 	  LEFT JOIN (SELECT so3.sid_id, 1 is_match
		      		   FROM security.securable_object so3
		      		   LEFT JOIN security.menu m ON so3.sid_id = m.sid_id
					   LEFT JOIN v$doc_folder df ON so3.sid_id = df.doc_folder_sid
					  WHERE LOWER(NVL(m.description, NVL(df.translated, so3.name))) LIKE '%'||LOWER(in_search_phrase)||'%'
							START WITH so3.sid_id = in_parent_sid
							CONNECT BY PRIOR so3.sid_id = so3.parent_sid_id) mt
			 ON t.sid_id = mt.sid_id
		  LEFT JOIN security.menu m ON t.sid_id = m.sid_id
		  LEFT JOIN v$doc_folder df ON t.sid_id = df.doc_folder_sid
     ORDER BY t.rn;
END;


PROCEDURE GetTreeWithSelect(
	in_parent_sid					IN	security.security_pkg.T_SID_ID,
	in_select_sid					IN	security.security_pkg.T_SID_ID,
	in_fetch_depth					IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur for
		SELECT so.sid_id, so.parent_sid_id, NVL(m.description, NVL(df.translated, so.name)) name, so.so_level,
			   so.is_leaf, 1 is_match, soc.class_name
		  FROM (SELECT so.*, ROWNUM rn
		  		  FROM TABLE(SecurableObject_pkg.GetTreeWithPermAsTable(SYS_CONTEXT('SECURITY', 'ACT'),
		  				in_parent_sid, security.security_pkg.PERMISSION_READ, null, null, 1)) so) so
		  JOIN security.securable_object_class soc ON so.class_id = soc.class_id
		  LEFT JOIN security.menu m ON so.sid_id = m.sid_id
		  LEFT JOIN v$doc_folder df ON so.sid_id = df.doc_folder_sid
		 WHERE 
		   (
				so.so_level <= in_fetch_depth 
				OR so.sid_id IN (
					SELECT sid_id
					  FROM security.securable_object
						   START WITH sid_id = in_select_sid
						   CONNECT BY PRIOR parent_sid_id = sid_id
				)
				OR so.parent_sid_id IN (
					SELECT sid_id
					  FROM security.securable_object
						   START WITH sid_id = in_select_sid
						   CONNECT BY PRIOR parent_sid_id = sid_id
				)
			)
		 ORDER BY so.rn;
END;


PROCEDURE GetList(
	in_parent_sid					IN	security.security_pkg.T_SID_ID,
	in_limit						IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN	
	OPEN out_cur FOR
		SELECT *
		  FROM (SELECT so.*, 1 is_match, soc.class_name
				  FROM (SELECT so.sid_id, so.parent_sid_id, so.dacl_id, so.class_id,
							   NVL(m.description, NVL(df.translated, so.name)) name, so.flags, so.owner,
							   ROWNUM rn, level so_level, CONNECT_BY_ISLEAF is_leaf,
							   SUBSTR(SYS_CONNECT_BY_PATH(NVL(m.description, NVL(df.translated, so.name)), '/'), 2) path
						  FROM security.securable_object so
						  LEFT JOIN security.menu m ON so.sid_id = m.sid_id
						  LEFT JOIN v$doc_folder df ON so.sid_id = df.doc_folder_sid
							   START WITH so.parent_sid_id = in_parent_sid
							   CONNECT BY PRIOR NVL(so.link_sid_id, so.sid_id) = so.parent_sid_id
							   ORDER SIBLINGS BY LOWER(NVL(m.description, NVL(df.translated, so.name)))) so
				  JOIN security.securable_object_class soc ON so.class_id = soc.class_id
				  JOIN TABLE(SecurableObject_pkg.GetDescendantsWithPermAsTable(SYS_CONTEXT('SECURITY', 'ACT'),
						in_parent_sid, security.security_pkg.PERMISSION_READ)) sop
					ON sop.sid_id = so.sid_id
				 ORDER BY so.rn)
		  WHERE rownum <= in_limit;
END;

PROCEDURE GetListTextFiltered(
	in_parent_sid					IN	security.security_pkg.T_SID_ID,
	in_search_term					IN	VARCHAR2,
	in_limit						IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT *
		  FROM (SELECT so.*, 1 is_match, soc.class_name
				  FROM (SELECT so.sid_id, so.parent_sid_id, so.dacl_id, so.class_id,
							   NVL(m.description, NVL(df.translated, so.name)) name, so.flags, so.owner,
							   ROWNUM rn, level so_level, CONNECT_BY_ISLEAF is_leaf,
							   SUBSTR(SYS_CONNECT_BY_PATH(NVL(m.description, NVL(df.translated, so.name)), '/'), 2) path
						  FROM security.securable_object so
						  LEFT JOIN security.menu m ON so.sid_id = m.sid_id
						  LEFT JOIN v$doc_folder df ON so.sid_id = df.doc_folder_sid
							   START WITH so.parent_sid_id = in_parent_sid
							   CONNECT BY PRIOR NVL(so.link_sid_id, so.sid_id) = so.parent_sid_id
							   ORDER SIBLINGS BY LOWER(NVL(m.description, NVL(df.translated, so.name)))) so
				  JOIN security.securable_object_class soc ON so.class_id = soc.class_id
				  JOIN TABLE(SecurableObject_pkg.GetDescendantsWithPermAsTable(SYS_CONTEXT('SECURITY', 'ACT'),
						in_parent_sid, security.security_pkg.PERMISSION_READ)) sop
					ON sop.sid_id = so.sid_id
				 WHERE LOWER(so.name) LIKE '%'||LOWER(in_search_term)||'%'
				 ORDER BY so.rn)
		  WHERE rownum <= in_limit;
END;

END;
/
