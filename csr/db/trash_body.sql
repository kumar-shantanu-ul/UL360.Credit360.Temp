CREATE OR REPLACE PACKAGE BODY CSR.trash_Pkg AS
-- Securable object callbacks

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
	NULL;
END;


PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
) AS
BEGIN
	DELETE FROM trash
	 WHERE trash_can_sid = in_sid_id;
END;


PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
) AS
BEGIN
	NULL;
END;

-- returns 1 or 0 
FUNCTION IsInTrash(
	in_act_id			IN	security_pkg.T_ACT_ID,
    in_object_sid		IN	security_pkg.T_SID_ID
)  RETURN NUMBER
AS
	v_found NUMBER(10);
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_object_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading the object with sid '||in_object_sid);
	END IF;	
	SELECT COUNT(*) INTO v_found
	  FROM TRASH
	 WHERE TRASH_SID = in_object_sid;
	RETURN v_found;
END;

-- returns 1 or 0 
FUNCTION IsInTrashHierarchical(
	in_act_id			IN	security_pkg.T_ACT_ID,
    in_object_sid		IN	security_pkg.T_SID_ID
)  RETURN NUMBER
AS
	v_found NUMBER(10);
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_object_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading the object with sid '||in_object_sid);
	END IF;	

	-- Is the object actually in the trash
	-- or is one of its parents in the trash
	SELECT COUNT(trash_sid) INTO v_found 
	  FROM csr.trash
	 WHERE trash_sid IN (
        SELECT sid_id
          FROM security.securable_object so
         START WITH sid_id = in_object_sid
        CONNECT BY sid_id = PRIOR parent_sid_id
			       AND application_sid_id = PRIOR application_sid_id
		);

	RETURN v_found;
END;

PROCEDURE TrashObject(
	in_act_id			IN	security_pkg.T_ACT_ID,
    in_object_sid		IN	security_pkg.T_SID_ID,
    in_trash_can_sid	IN	security_pkg.T_SID_ID,
    in_description		IN	trash.description%TYPE
)
AS
	v_user_sid		security_pkg.T_SID_ID;
    v_so			security.T_SO_ROW;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_trash_can_sid, security_pkg.PERMISSION_ADD_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to trash can');
	END IF;	
    
    -- find out about the object etc
    user_pkg.GetSid(in_act_id, v_user_sid);
    v_so := securableobject_pkg.GetSOAsRowObject(in_act_id, in_object_sid);

    INSERT INTO trash 
    	(trash_sid, trash_can_sid, trashed_by_sid, trashed_dtm, previous_parent_sid, description, so_name)
    VALUES
    	(in_object_sid, in_trash_can_sid, v_user_sid, SYSDATE, v_so.parent_sid_id, in_description, v_so.name);
        
    -- rename to null  (to avoid dupe names)
    securableobject_pkg.RenameSO(in_act_id, in_object_sid, null);      
        
    -- finally move the object
    securableobject_pkg.MoveSO(in_act_id, in_object_sid, in_trash_can_sid);     
END;

PROCEDURE RestoreObjects(
    in_object_sids					IN	security_pkg.T_SID_IDS
)
AS
	v_cnt							NUMBER;
	v_object_sids					security.T_SID_TABLE;
	v_trash_root_sid				customer.trash_sid%TYPE;
BEGIN
	SELECT trash_sid
	  INTO v_trash_root_sid
	  FROM customer;

    IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'),
    	v_trash_root_sid, csr_data_pkg.PERMISSION_RESTORE_FROM_TRASH) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied restoring from trash can');
	END IF;	

	v_object_sids := security_pkg.SidArrayToTable(in_object_sids);
	FOR r IN (
		SELECT DISTINCT column_value trash_sid
		  FROM TABLE(v_object_sids)
		 MINUS
		SELECT trash_sid
		  FROM trash
	) LOOP
    	RAISE_APPLICATION_ERROR(Security_Pkg.ERR_OBJECT_NOT_FOUND,
			'The object with SID '||r.trash_sid||' was not found');
    END LOOP;
    
	-- check parents aren't in the trash
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM (SELECT sid_id
			  FROM security.securable_object
				   START WITH sid_id = v_trash_root_sid
				   CONNECT BY PRIOR sid_id = parent_sid_id) tc,
		   TABLE(v_object_sids) r, trash t
	 WHERE r.column_value = t.trash_sid
	   AND t.previous_parent_sid = tc.sid_id;
    IF v_cnt > 0 THEN
    	RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_PREVIOUS_PARENT_TRASHED, 'Cannot restore - previous parent has been trashed too.');
	END IF;

	-- call any restore helpers
	FOR r IN (
		SELECT DISTINCT soc.class_id, soc.helper_pkg
		  FROM security.securable_object so, security.securable_object_class soc
		 WHERE so.sid_id IN (SELECT column_value FROM TABLE(v_object_sids))
		   AND so.class_id = soc.class_id
		   AND soc.helper_pkg IS NOT NULL
	) LOOP

		IF security.security_pkg.PackageHasProcedure(r.helper_pkg, 'RestoreFromTrash') THEN
			EXECUTE IMMEDIATE 'begin '||r.helper_pkg||'.RestoreFromTrash(:1); end;'
			USING v_object_sids;
		END IF;
	END LOOP;
	    
	-- restore the objects to the original location in the SO tree
	FOR r IN (
		SELECT trash_sid, previous_parent_sid, so_name
		  FROM trash
		 WHERE trash_sid IN (SELECT column_value FROM TABLE(v_object_sids))
	) LOOP
		-- finally move the object
		securableobject_pkg.MoveSO(SYS_CONTEXT('SECURITY', 'ACT'), r.trash_sid, r.previous_parent_sid);
        
		-- rename to previous name (to avoid dupe names)
		utils_pkg.UniqueSORename(SYS_CONTEXT('SECURITY', 'ACT'), r.trash_sid, r.so_name);
	END LOOP;

	-- remove from the trash
	DELETE FROM trash 
	 WHERE trash_sid IN (SELECT column_value FROM TABLE(v_object_sids));
END;

PROCEDURE GetTrashList(
    in_trash_can_sid				IN	security_pkg.T_SID_ID,
	in_class_name					IN  security_pkg.T_CLASS_NAME,
	in_order_by 					IN 	VARCHAR2,
	in_start_row					IN	NUMBER,
	in_page_size					IN	NUMBER,
	out_total_rows					OUT	NUMBER,
    out_cur							OUT	SYS_REFCURSOR
)
AS
	v_order_by						VARCHAR2(1000);
	v_sos							security.T_SO_TABLE;
	v_class_id						security_pkg.T_CLASS_ID;
BEGIN		
	-- permission check done by securableobject_Pkg.GetChildrenAsTable

	IF in_order_by IS NOT NULL THEN
		utils_pkg.ValidateOrderBy(in_order_by, 'trashed_by,class_name,description,trashed_dtm');
		v_order_by := ' ORDER BY ' || in_order_by;
	END IF;

	v_sos := security.securableobject_Pkg.GetChildrenAsTable(
		SYS_CONTEXT('SECURITY', 'ACT'), in_trash_can_sid);
		
	IF in_class_name IS NOT NULL THEN
		v_class_id := class_pkg.GetClassId(in_class_name);
	END IF;

	SELECT COUNT(*)
	  INTO out_total_rows
	  FROM trash t, TABLE(v_sos) so
	 WHERE so.class_id = NVL(v_class_id, so.class_id)
	   AND so.sid_id = t.trash_sid
	   AND t.trash_can_sid = in_trash_can_sid;
	   
	OPEN out_cur FOR
		'SELECT * '||
		  'FROM ('||
				'SELECT rownum rn, x.* '||
				  'FROM ('||
				    	'SELECT trash_sid, u.full_name trashed_by, class_name, description, '||
				    		   'previous_parent_sid, trashed_dtm, '||
								'CASE class_name '||
								'WHEN ''CSRIndicator'' THEN ''Indicator'' '||
								'WHEN ''CSRRegion'' THEN ''Region'' '||
								'WHEN ''CSRUser'' THEN ''User'' '||
								'WHEN ''CSRForm'' THEN ''Form'' '||
								'WHEN ''CSRDataView'' THEN ''DataView'' '||
								'WHEN ''Container'' THEN ''Container (Folder)'' '||
								'WHEN ''CSRQuickSurvey'' THEN ''Survey'' '||
								'ELSE class_name END friendly_class_name '||						   
						  'FROM trash t, security.securable_object_class soc, csr_user u, '||
						  	   'TABLE(:v_sos) so '||
						 'WHERE so.class_id = soc.class_id '||
						   'AND t.trashed_by_sid = u.csr_user_sid '||
						   'AND so.sid_id = t.trash_sid '||
						   'AND so.class_id = NVL(:v_class_id, so.class_id) '||
						   'AND t.trash_can_sid = :v_trash_can_sid'||
						 v_order_by ||
					   ') x '||
				 'WHERE rownum <= :v_limit'||
			    ')'||
		 'WHERE rn > :v_start_row'
	USING v_sos, v_class_id, in_trash_can_sid, in_start_row + in_page_size, in_start_row;
END;

PROCEDURE EmptyTrash(
	in_act_id				IN	security_pkg.T_ACT_ID,
    in_app_sid				IN	security_pkg.T_SID_ID,
	in_commit_every_rec		IN	NUMBER	DEFAULT 0
)
AS
	v_trash_sid Security_pkg.T_SID_ID;
	v_user_sid	security_pkg.T_SID_ID;
	v_count		NUMBER;
BEGIN
	-- find trash SID
	v_trash_sid := securableobject_pkg.GetSidFromPath(in_act_id, in_app_sid, 'trash');
	user_pkg.GetSid(in_act_id, v_user_sid);
	--dbms_output.put_line('EmptyTrash v_trash_sid='||v_trash_sid);
	--dbms_output.put_line('EmptyTrash v_user_sid='||v_user_sid);
	--dbms_output.put_line('EmptyTrash in_app_sid='||in_app_sid);
    
    IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_trash_sid, security_pkg.PERMISSION_DELETE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied emptying trash can');
	END IF;	
	
	-- fix any issues where the dependencies stop top level objects being deleted
	-- e.g.
	-- A [Sum(children)]
	-- |_B
	-- |_C
	--
	-- A can't be deleted because it tries to delete B which fails because A depends on B
	DELETE FROM calc_dependency 
	 WHERE calc_ind_sid IN (
	 	SELECT sid_id 
	 	  FROM security.securable_object 
	 	 START WITH parent_sid_id = v_trash_sid 
	   CONNECT BY PRIOR sid_id = parent_sid_id
	 	);
	IF in_commit_every_rec > 0 THEN
		--dbms_output.put_line('EmptyTrash calc_dependency commit');
		COMMIT;
	END IF;

	-- in case we're about to delete a user who has trashed something, set the 
	-- trashed user to the current user. This doesn't matter since we're about 
	-- to delete everything anyway.
	UPDATE trash 
	   SET trashed_by_sid = v_user_sid 
	 WHERE trash_can_sid = in_app_sid;
	IF in_commit_every_rec > 0 THEN
		--dbms_output.put_line('EmptyTrash trash commit');
		COMMIT;
	END IF;

	-- trash stuff
	v_count := 0;
	FOR r IN (
		SELECT sid_id 
		  FROM security.securable_object 
		 WHERE parent_sid_id = v_trash_sid
	)
	LOOP
		securableObject_pkg.DeleteSO(in_act_id, r.sid_id);
		v_count := v_count + 1;
		IF in_commit_every_rec > 0 AND 
		   v_count >= in_commit_every_rec THEN
			--dbms_output.put_line('EmptyTrash commit');
			COMMIT;
			v_count := 0;
		END IF;
	END LOOP;

	-- Finally remove everything recorded in the trash.
	DELETE FROM trash
	 WHERE app_sid = in_app_sid;
END;

PROCEDURE RemoveTagGroupFromRegion (
	in_sid						IN	NUMBER,
	in_tag_group_id				IN	NUMBER,
	out_rows_updated			OUT	NUMBER
)
AS
	v_cnt							NUMBER;
	v_is_in_trash					NUMBER;
	v_act_id 						security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
BEGIN

	SELECT COUNT(*)
	  INTO v_cnt
	  FROM region
	 WHERE region_sid = in_sid;
	
	IF v_cnt = 0 THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_OBJECT_NOT_FOUND, 'The object with SID '||in_sid||' is not a region or does not exist.');
	END IF;

	v_is_in_trash := trash_pkg.IsInTrashHierarchical(
		in_act_id		=> v_act_id,
		in_object_sid	=> in_sid
	);
	
	IF v_is_in_trash = 0 THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_OBJECT_NOT_FOUND, 'The object with SID '||in_sid||' was not found in the trash.');
	END IF;
	
	tag_pkg.RemoveRegionTagGroup(
		in_act_id				=> v_act_id,
		in_region_sid			=> in_sid,
		in_tag_group_id			=> in_tag_group_id,
		in_apply_dynamic_plans	=> 0,
		out_rows_updated		=> out_rows_updated
	);
END;

PROCEDURE RemoveTagGroupFromRegions (
	in_tag_group_id				IN	NUMBER,
	out_rows_updated			OUT	NUMBER
)
AS
	v_trash_root_sid				customer.trash_sid%TYPE;
	v_act_id 						security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
	v_rows_updated					NUMBER;
	v_class_id						NUMBER := class_pkg.getClassID('CSRRegion');
BEGIN
	SELECT trash_sid
	  INTO v_trash_root_sid
	  FROM customer;
	
	out_rows_updated := 0;
	FOR r IN (
		SELECT sid_id
		  FROM SECURITY.SECURABLE_OBJECT SO
		 WHERE class_id IN (v_class_id)
		 START WITH so.sid_id = v_trash_root_sid
	   CONNECT BY PRIOR so.sid_id = so.parent_sid_id
	)
	LOOP
		tag_pkg.RemoveRegionTagGroup(
			in_act_id				=> v_act_id,
			in_region_sid			=> r.sid_id,
			in_tag_group_id			=> in_tag_group_id,
			in_apply_dynamic_plans	=> 0,
			out_rows_updated		=> v_rows_updated
		);
		out_rows_updated := out_rows_updated + v_rows_updated;
	END LOOP;
END;

PROCEDURE RemoveTagFromRegion (
	in_sid						IN	NUMBER,
	in_tag_group_id				IN	NUMBER,
	in_tag_id					IN	NUMBER,
	out_rows_updated			OUT	NUMBER
)
AS
	v_cnt							NUMBER;
	v_is_in_trash					NUMBER;
	v_act_id 						security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
BEGIN

	SELECT COUNT(*)
	  INTO v_cnt
	  FROM region
	 WHERE region_sid = in_sid;
	
	IF v_cnt = 0 THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_OBJECT_NOT_FOUND, 'The object with SID '||in_sid||' is not a region or does not exist.');
	END IF;

	v_is_in_trash := trash_pkg.IsInTrashHierarchical(
		in_act_id		=> v_act_id,
		in_object_sid	=> in_sid
	);
	
	IF v_is_in_trash = 0 THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_OBJECT_NOT_FOUND, 'The object with SID '||in_sid||' was not found in the trash.');
	END IF;
	
	-- Validate tag group and ID combo
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM tag_group_member
	 WHERE tag_id = in_tag_id
	   AND tag_group_id = in_tag_group_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	IF v_cnt = 0 THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_OBJECT_NOT_FOUND, 'The tag with id '||in_tag_id||' was not found found, or is not in group '||in_tag_group_id);
	END IF;
	
	tag_pkg.RemoveRegionTag(
		in_act_id				=> v_act_id,
		in_region_sid			=> in_sid,
		in_tag_id				=> in_tag_id,
		in_apply_dynamic_plans	=> 0,
		out_rows_updated		=> out_rows_updated
	);
END;

PROCEDURE RemoveTagFromRegions (
	in_tag_group_id				IN	NUMBER,
	in_tag_id					IN	NUMBER,
	out_rows_updated			OUT	NUMBER
)
AS
	v_cnt							NUMBER;
	v_trash_root_sid				customer.trash_sid%TYPE;
	v_act_id 						security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
	v_rows_updated					NUMBER;
	v_class_id						NUMBER := class_pkg.getClassID('CSRRegion');
BEGIN
	SELECT trash_sid
	  INTO v_trash_root_sid
	  FROM customer;
	
	-- Validate tag group and ID combo
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM tag_group_member
	 WHERE tag_id = in_tag_id
	   AND tag_group_id = in_tag_group_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	IF v_cnt = 0 THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_OBJECT_NOT_FOUND, 'The tag with id '||in_tag_id||' was not found found, or is not in group '||in_tag_group_id);
	END IF;
	
	out_rows_updated := 0;
	
	FOR r IN (
		SELECT sid_id
		  FROM SECURITY.SECURABLE_OBJECT SO
		 WHERE class_id IN (v_class_id)
		 START WITH so.sid_id = v_trash_root_sid
	   CONNECT BY PRIOR so.sid_id = so.parent_sid_id
	)
	LOOP
		tag_pkg.RemoveRegionTag(
			in_act_id				=> v_act_id,
			in_region_sid			=> r.sid_id,
			in_tag_id				=> in_tag_id,
			in_apply_dynamic_plans	=> 0,
			out_rows_updated		=> v_rows_updated
		);
		out_rows_updated := out_rows_updated + v_rows_updated;
	END LOOP;
END;

PROCEDURE RemoveLookupKeyFromRegions (
	in_lookup_key			IN	region.lookup_key%TYPE,
	out_rows_updated		OUT	NUMBER
)
AS
	v_trash_root_sid				customer.trash_sid%TYPE;
	
BEGIN

	SELECT trash_sid
	  INTO v_trash_root_sid
	  FROM customer;

	UPDATE region
	   SET lookup_key = null
	 WHERE region_sid in (
		SELECT region_sid
		  FROM csr.region r
		 WHERE lookup_key = in_lookup_key
		 START WITH r.parent_sid = v_trash_root_sid
	   CONNECT BY PRIOR r.REGION_SID = r.PARENT_SID);

	out_rows_updated := SQL%ROWCOUNT;

END;

PROCEDURE RemoveTagGroupFromIndicator (
	in_sid						IN	NUMBER,
	in_tag_group_id				IN	NUMBER,
	out_rows_updated			OUT	NUMBER
)
AS
	v_cnt							NUMBER;
	v_is_in_trash					NUMBER;
	v_act_id 						security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
BEGIN

	SELECT COUNT(*)
	  INTO v_cnt
	  FROM ind
	 WHERE ind_sid = in_sid;
	
	IF v_cnt = 0 THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_OBJECT_NOT_FOUND, 'The object with SID '||in_sid||' is not an indicator or does not exist.');
	END IF;

	v_is_in_trash := trash_pkg.IsInTrashHierarchical(
		in_act_id		=> v_act_id,
		in_object_sid	=> in_sid
	);
	
	IF v_is_in_trash = 0 THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_OBJECT_NOT_FOUND, 'The object with SID '||in_sid||' was not found in the trash.');
	END IF;
	
	tag_pkg.RemoveIndicatorTagGroup(
		in_act_id			=> v_act_id,
		in_ind_sid			=> in_sid,
		in_tag_group_id		=> in_tag_group_id,
		out_rows_updated	=> out_rows_updated
	);
END;

PROCEDURE RemoveTagGroupFromIndicators (
	in_tag_group_id				IN	NUMBER,
	out_rows_updated			OUT	NUMBER
)
AS
	v_trash_root_sid				customer.trash_sid%TYPE;
	v_act_id 						security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
	v_rows_updated					NUMBER;
	v_class_id						NUMBER := class_pkg.getClassID('CSRIndicator');
BEGIN
	SELECT trash_sid
	  INTO v_trash_root_sid
	  FROM customer;
	
	out_rows_updated := 0;
	FOR r IN (
		SELECT sid_id
		  FROM SECURITY.SECURABLE_OBJECT SO
		 WHERE class_id IN (v_class_id)
		 START WITH so.sid_id = v_trash_root_sid
	   CONNECT BY PRIOR so.sid_id = so.parent_sid_id
	)
	LOOP
		tag_pkg.RemoveIndicatorTagGroup(
			in_act_id			=> v_act_id,
			in_ind_sid			=> r.sid_id,
			in_tag_group_id		=> in_tag_group_id,
			out_rows_updated	=> v_rows_updated
		);
		out_rows_updated := out_rows_updated + v_rows_updated;
	END LOOP;
END;

PROCEDURE RemoveTagFromIndicator (
	in_sid						IN	NUMBER,
	in_tag_group_id				IN	NUMBER,
	in_tag_id					IN	NUMBER,
	out_rows_updated			OUT	NUMBER
)
AS
	v_cnt							NUMBER;
	v_is_in_trash					NUMBER;
	v_act_id 						security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
BEGIN

	SELECT COUNT(*)
	  INTO v_cnt
	  FROM ind
	 WHERE ind_sid = in_sid;
	
	IF v_cnt = 0 THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_OBJECT_NOT_FOUND, 'The object with SID '||in_sid||' is not an indicator or does not exist.');
	END IF;

	v_is_in_trash := trash_pkg.IsInTrashHierarchical(
		in_act_id		=> v_act_id,
		in_object_sid	=> in_sid
	);
	
	IF v_is_in_trash = 0 THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_OBJECT_NOT_FOUND, 'The object with SID '||in_sid||' was not found in the trash.');
	END IF;
	
	-- Validate tag group and ID combo
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM tag_group_member
	 WHERE tag_id = in_tag_id
	   AND tag_group_id = in_tag_group_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	IF v_cnt = 0 THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_OBJECT_NOT_FOUND, 'The tag with id '||in_tag_id||' was not found found, or is not in group '||in_tag_group_id);
	END IF;
	
	tag_pkg.RemoveIndicatorTag(
		in_act_id			=> v_act_id,
		in_ind_sid			=> in_sid,
		in_tag_id			=> in_tag_id,
		out_rows_updated	=> out_rows_updated
	);
END;

PROCEDURE RemoveTagFromIndicators (
	in_tag_group_id				IN	NUMBER,
	in_tag_id					IN	NUMBER,
	out_rows_updated			OUT	NUMBER
)
AS
	v_cnt							NUMBER;
	v_trash_root_sid				customer.trash_sid%TYPE;
	v_act_id 						security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
	v_rows_updated					NUMBER;
	v_class_id						NUMBER := class_pkg.getClassID('CSRIndicator');
BEGIN
	SELECT trash_sid
	  INTO v_trash_root_sid
	  FROM customer;
	
	-- Validate tag group and ID combo
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM tag_group_member
	 WHERE tag_id = in_tag_id
	   AND tag_group_id = in_tag_group_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	IF v_cnt = 0 THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_OBJECT_NOT_FOUND, 'The tag with id '||in_tag_id||' was not found found, or is not in group '||in_tag_group_id);
	END IF;
	
	out_rows_updated := 0;
	
	FOR r IN (
		SELECT sid_id
		  FROM SECURITY.SECURABLE_OBJECT SO
		 WHERE class_id IN (v_class_id)
		 START WITH so.sid_id = v_trash_root_sid
	   CONNECT BY PRIOR so.sid_id = so.parent_sid_id
	)
	LOOP
		tag_pkg.RemoveIndicatorTag(
			in_act_id			=> v_act_id,
			in_ind_sid			=> r.sid_id,
			in_tag_id			=> in_tag_id,
			out_rows_updated	=> v_rows_updated
		);
		out_rows_updated := out_rows_updated + v_rows_updated;
	END LOOP;
END;

PROCEDURE RemoveLookupKeyFromIndicators (
	in_lookup_key			IN	ind.lookup_key%TYPE,
	out_rows_updated		OUT	NUMBER
)
AS
	v_trash_root_sid				customer.trash_sid%TYPE;
	
BEGIN

	SELECT trash_sid
	  INTO v_trash_root_sid
	  FROM customer;

	UPDATE ind
	   SET lookup_key = null
	 WHERE ind_sid in (
		SELECT ind_sid
		  FROM csr.ind i
		 WHERE lookup_key = in_lookup_key
		 START WITH i.parent_sid = v_trash_root_sid
	   CONNECT BY PRIOR i.ind_sid = i.parent_sid);

	out_rows_updated := SQL%ROWCOUNT;

END;

END;
/
