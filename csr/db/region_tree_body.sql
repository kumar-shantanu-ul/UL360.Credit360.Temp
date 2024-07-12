CREATE OR REPLACE PACKAGE BODY CSR.region_tree_pkg AS

-- ideas:
-- if you deactivate, then delete from any baseline region trees
-- copying a tree assumes creating a baseline?

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
)
AS
BEGIN
	NULL;
END;

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
)
AS
BEGIN
	-- clean up (we have an entry in the region table too)
	DELETE FROM REGION_DESCRIPTION
	 WHERE REGION_SID = in_sid_Id;
	
	DELETE FROM REGION
	 WHERE REGION_SID = in_sid_Id;

	DELETE FROM REGION_TREE
	 WHERE REGION_TREE_ROOT_SID = in_sid_Id;
END;


PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;


PROCEDURE INTERNAL_PropagateSecondaryTreeRoles(
	in_secondary_root_sid			IN	security_pkg.T_SID_ID,
	in_reduce_contention			IN	NUMBER DEFAULT 0
)
AS
BEGIN
	FOR r IN (
		SELECT rrm.region_sid, rrm.role_sid
		  FROM (
				SELECT app_sid, region_sid
				  FROM region
				 WHERE link_to_region_sid IS NULL
				 START WITH parent_sid = in_secondary_root_sid
			   CONNECT BY PRIOR region_sid = parent_sid
			   ) r
		  JOIN region_role_member rrm ON r.app_sid = rrm.app_sid AND r.region_sid = rrm.region_sid AND rrm.inherited_from_sid = rrm.region_sid
	)
	LOOP
		role_pkg.PropagateRoleMembership(r.role_sid, r.region_sid);
		IF in_reduce_contention <> 0 THEN
			COMMIT;
		END IF;
	END LOOP;
END;

FUNCTION GetPrimaryRegionTreeRootSid
RETURN security_pkg.T_SID_ID
AS
	v_root_sid	security_pkg.T_SID_ID;
BEGIN
	-- just returns SID so we're not doing a security check ATM
	SELECT region_tree_root_sid
	  INTO v_root_sid
	  FROM region_tree
	  WHERE app_sid = security_pkg.getApp
		AND is_primary = 1;
	RETURN v_root_sid;
END;


FUNCTION GetPrimaryRegionTreeRootSid(
	in_region_root_sid IN security_pkg.T_SID_ID
)
RETURN security_pkg.T_SID_ID
AS
	v_primary_root_sid	security_pkg.T_SID_ID;
BEGIN
	-- assumes only 1 primary tree (should be right!)

	-- just returns SID so we're not doing a security check ATM
	IF in_region_root_sid IS NULL THEN
		SELECT region_tree_root_sid
		  INTO v_primary_root_sid
		  FROM region_tree
		  WHERE app_sid = security_pkg.getApp
			AND is_primary = 1;
	ELSE
		IF IsInPrimaryTree(in_region_root_sid) = 0 THEN
			RAISE_APPLICATION_ERROR(-20001, 'Region root sid ' || in_region_root_sid || ' is not in primary tree ');
		END IF;

		v_primary_root_sid := in_region_root_sid;
	END IF;
	--dbms_output.put_line('primary is '||v_primary_root_sid);
	RETURN v_primary_root_sid;
END;

FUNCTION GetSecondaryRegionTreeRootSid (
	in_region_name			IN	region.name%TYPE
)RETURN security_pkg.T_SID_ID
AS
	v_root_sid	security_pkg.T_SID_ID;
BEGIN
	-- XXX - just returns SID so we're not doing a security check ATM
	SELECT rt.region_tree_root_sid
	  INTO v_root_sid
	  FROM region_tree rt
	  JOIN region r ON r.region_sid = rt.region_tree_root_sid AND r.app_sid = rt.app_sid
	  WHERE rt.app_sid = security_pkg.getApp
		AND rt.is_primary = 0
		AND LOWER(r.name) = LOWER(in_region_name);
	
	RETURN v_root_sid;
END;

FUNCTION IsInPrimaryTree(
	in_region_sid					IN	security_pkg.T_SID_ID
) RETURN NUMBER
AS
	v_is_in_primary_tree		region_tree.is_primary%TYPE;
BEGIN
	SELECT rt.is_primary
	  INTO v_is_in_primary_tree
	  FROM region_tree rt
	  JOIN (
		 SELECT region_sid
		   FROM region
		  START WITH region_sid = in_region_sid
		CONNECT BY PRIOR parent_sid = region_sid
	 )x ON rt.region_tree_root_sid = x.region_sid;

	RETURN v_is_in_primary_tree;
END;

FUNCTION IsInSecondaryTree(
	in_region_sid					IN	security_pkg.T_SID_ID
) RETURN NUMBER
AS
	v_is_in_primary_tree		region_tree.is_primary%TYPE;
BEGIN
	v_is_in_primary_tree := IsInPrimaryTree(in_region_sid);

	IF v_is_in_primary_tree = 0 THEN
		RETURN 1;
	ELSE
		RETURN 0;
	END IF;
END;


PROCEDURE CreateRefreshBatchJob(
	in_region_sid						IN	security_pkg.T_SID_ID,
	in_user_sid							IN	security_pkg.T_SID_ID,
	out_batch_job_id					OUT	batch_job.batch_job_id%TYPE
)
AS
BEGIN
	batch_job_pkg.Enqueue(
		in_batch_job_type_id => csr.batch_job_pkg.jt_secondary_tree_refresh,
		in_description => 'region ' || in_region_sid,
		in_total_work => 1,
		out_batch_job_id => out_batch_job_id);

	INSERT INTO batch_job_srt_refresh
		(batch_job_id, region_sid, user_sid)
	VALUES
		(out_batch_job_id, in_region_sid, in_user_sid);
END;


PROCEDURE GetRefreshBatchJob(
	in_batch_job_id					IN	batch_job.batch_job_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT batch_job_id, region_sid, user_sid
		  FROM batch_job_srt_refresh
		 WHERE app_sid = security_pkg.getApp
		   AND batch_job_id = in_batch_job_id;
END;

-- A copy of utils_pkg.SplitString with a clob param.
FUNCTION SplitClob(
	in_string						IN CLOB,
	in_delimiter					IN VARCHAR2 DEFAULT ','
) RETURN T_SPLIT_TABLE
AS 
	v_table 	T_SPLIT_TABLE := T_SPLIT_TABLE();
	v_start 	NUMBER :=1;
	v_pos	 	NUMBER :=0;
BEGIN
			 
	-- determine first chunk of string 
	v_pos := INSTR(in_string, in_delimiter, v_start);
	IF in_string IS NOT NULL THEN
		-- while there are chunks left, loop 
		WHILE ( v_pos != 0)
		LOOP
			-- create array
			v_table.extend;
			v_table( v_table.COUNT ) := T_SPLIT_ROW( SUBSTR(in_string, v_start, v_pos-v_start), v_table.COUNT );
			v_start := v_pos + LENGTH(in_delimiter);
			v_pos := INSTR(in_string, in_delimiter, v_start);
		END LOOP;
		-- add in last item
		v_table.extend;
		v_table( v_table.COUNT ) := T_SPLIT_ROW( SUBSTR(in_string, v_start), v_table.COUNT );
	END IF;
	RETURN v_table;
END;


PROCEDURE RefreshSecondaryRegionTree(
	in_region_sid					IN	security_pkg.T_SID_ID,
	in_user_sid						IN	security_pkg.T_SID_ID
)
AS
	v_sp_name			secondary_region_tree_ctrl.sp_name%TYPE;
	v_region_root_sid	secondary_region_tree_ctrl.region_root_sid%TYPE;
	v_tag_id			secondary_region_tree_ctrl.tag_id%TYPE;
	v_tag_group_ids		secondary_region_tree_ctrl.tag_group_ids%TYPE;
	v_reduce_contention	secondary_region_tree_ctrl.reduce_contention%TYPE;
	v_apply_deleg_plans	secondary_region_tree_ctrl.apply_deleg_plans%TYPE;
	v_active_only		secondary_region_tree_ctrl.active_only%TYPE;
	v_ignore_sids		secondary_region_tree_ctrl.ignore_sids%TYPE;
	v_ignore_sids_t		security.T_SID_TABLE := security.T_SID_TABLE();
	t_ignore_sids		T_SPLIT_TABLE;
BEGIN
	SELECT sp_name, region_root_sid, tag_id, tag_group_ids,
		   reduce_contention, apply_deleg_plans, active_only, ignore_sids
	  INTO v_sp_name, v_region_root_sid, v_tag_id, v_tag_group_ids,
		   v_reduce_contention, v_apply_deleg_plans, v_active_only, v_ignore_sids
	  FROM secondary_region_tree_ctrl
	 WHERE region_sid = in_region_sid;
	
	IF v_ignore_sids IS NOT NULL AND LENGTH(TRIM(v_ignore_sids)) > 0 THEN
		t_ignore_sids	 	:= SplitClob(v_ignore_sids, ',');
		FOR r IN (SELECT * FROM TABLE(t_ignore_sids))
		LOOP
			IF LENGTH(TRIM(r.item)) > 0 THEN
				--dbms_output.put_line('ignore sid '||r.item);
				v_ignore_sids_t.extend;
				v_ignore_sids_t(v_ignore_sids_t.count) := r.item;
			END IF;
		END LOOP;
	END IF;
	
	IF v_sp_name = 'SyncSecondaryForTag' OR v_sp_name = 'SynchSecondaryForTag' THEN
		SyncSecondaryForTag(
			in_secondary_root_sid			=>	in_region_sid,
			in_region_root_sid				=>	v_region_root_sid,
			in_tag_id						=>	v_tag_id,
			in_reduce_contention			=>	v_reduce_contention,
			in_apply_deleg_plans			=>	v_apply_deleg_plans,
			in_ignore_sids					=>	v_ignore_sids_t,
			in_user_sid						=>	in_user_sid
		);
	ELSIF v_sp_name = 'SyncSecondaryForTagGroup' OR v_sp_name = 'SynchSecondaryForTagGroup' THEN
		SyncSecondaryForTagGroup(
			in_secondary_root_sid			=>	in_region_sid,
			in_region_root_sid				=>	v_region_root_sid,
			in_tag_group_id					=>	TO_NUMBER(v_tag_group_ids),
			in_reduce_contention			=>	v_reduce_contention,
			in_apply_deleg_plans			=>	v_apply_deleg_plans,
			in_ignore_sids					=>	v_ignore_sids_t,
			in_user_sid						=>	in_user_sid
		);
	ELSIF v_sp_name = 'SyncSecondaryActivePropOnly' OR v_sp_name = 'SynchSecondaryActivePropOnly' THEN
		SyncSecondaryActivePropOnly(
			in_secondary_root_sid			=>	in_region_sid,
			in_region_root_sid				=>	v_region_root_sid,
			in_reduce_contention			=>	v_reduce_contention,
			in_apply_deleg_plans			=>	v_apply_deleg_plans,
			in_ignore_sids					=>	v_ignore_sids_t,
			in_user_sid						=>	in_user_sid
		);
	ELSIF v_sp_name = 'SyncSecondaryForTagGroupList' OR v_sp_name = 'SynchSecondaryForTagGroupList' THEN
		SyncSecondaryForTagGroupList(
			in_secondary_root_sid			=>	in_region_sid,
			in_region_root_sid				=>	v_region_root_sid,
			in_tag_group_id_list			=>	v_tag_group_ids,
			in_active_only					=>	v_active_only,
			in_reduce_contention			=>	v_reduce_contention,
			in_apply_deleg_plans			=>	v_apply_deleg_plans,
			in_ignore_sids					=>	v_ignore_sids_t,
			in_user_sid						=>	in_user_sid
		);
	ELSIF v_sp_name = 'SyncSecondaryPropByFunds' OR v_sp_name = 'SynchSecondaryPropByFunds'  THEN
		SyncSecondaryPropByFunds(
			in_secondary_root_sid			=>	in_region_sid,
			in_region_root_sid				=>	v_region_root_sid,
			in_reduce_contention			=>	v_reduce_contention,
			in_apply_deleg_plans			=>	v_apply_deleg_plans,
			in_ignore_sids					=>	v_ignore_sids_t,
			in_user_sid						=>	in_user_sid
		);
	ELSIF v_sp_name = 'SyncPropTreeByMgtCompany' OR v_sp_name = 'SynchPropTreeByMgtCompany' THEN
		SyncPropTreeByMgtCompany(
			in_secondary_root_sid			=>	in_region_sid,
			in_region_root_sid				=>	v_region_root_sid,
			in_reduce_contention			=>	v_reduce_contention,
			in_apply_deleg_plans			=>	v_apply_deleg_plans,
			in_ignore_sids					=>	v_ignore_sids_t,
			in_user_sid						=>	in_user_sid
		);
	ELSIF v_sp_name = 'Custom' THEN
		RAISE_APPLICATION_ERROR(-20001, 'Cannot synchronise custom tree for ' || in_region_sid);
	ELSE
		RAISE_APPLICATION_ERROR(-20001, 'Unknown SP name for ' || in_region_sid);
	END IF;
END;

/* Legacy versions of the sync functions (used in client folders) */
/**/
PROCEDURE SynchSecondaryForTag(
	in_secondary_root_sid			IN	security_pkg.T_SID_ID,
	in_tag_id						IN	tag.tag_id%TYPE,
	in_reduce_contention			IN	BOOLEAN DEFAULT FALSE,
	in_apply_deleg_plans			IN	BOOLEAN DEFAULT TRUE,
	in_ignore_sids					IN	security.T_SID_TABLE DEFAULT NULL
)
AS
BEGIN
	SyncSecondaryForTag(
		in_secondary_root_sid			=>	in_secondary_root_sid,
		in_tag_id						=>	in_tag_id,
		in_reduce_contention			=>	CASE WHEN in_reduce_contention = FALSE THEN 0 ELSE 1 END,
		in_apply_deleg_plans			=>	CASE WHEN in_apply_deleg_plans = FALSE THEN 0 ELSE 1 END,
		in_ignore_sids					=>	in_ignore_sids
	);
END;

PROCEDURE SynchSecondaryForTagGroup(
	in_secondary_root_sid			IN	security_pkg.T_SID_ID,
	in_region_root_sid				IN	security_pkg.T_SID_ID DEFAULT NULL, -- Null means use primary. 
	in_tag_group_id					IN	tag_group.tag_group_id%TYPE,
	in_reduce_contention			IN	BOOLEAN DEFAULT FALSE,
	in_apply_deleg_plans			IN	BOOLEAN DEFAULT TRUE,
	in_ignore_sids					IN	security.T_SID_TABLE DEFAULT NULL
)
AS
BEGIN
	SyncSecondaryForTagGroup(
		in_secondary_root_sid			=>	in_secondary_root_sid,
		in_region_root_sid				=>	in_region_root_sid,
		in_tag_group_id					=>	in_tag_group_id,
		in_reduce_contention			=>	CASE WHEN in_reduce_contention = FALSE THEN 0 ELSE 1 END,
		in_apply_deleg_plans			=>	CASE WHEN in_apply_deleg_plans = FALSE THEN 0 ELSE 1 END,
		in_ignore_sids					=>	in_ignore_sids
	);
END;

PROCEDURE SynchSecondaryActivePropOnly(
	in_secondary_root_sid			IN	security_pkg.T_SID_ID,
	in_reduce_contention			IN	BOOLEAN DEFAULT FALSE,
	in_apply_deleg_plans			IN	BOOLEAN DEFAULT TRUE,
	in_ignore_sids					IN	security.T_SID_TABLE DEFAULT NULL
)
AS
BEGIN
	SyncSecondaryActivePropOnly(
		in_secondary_root_sid			=>	in_secondary_root_sid,
		in_reduce_contention			=>	CASE WHEN in_reduce_contention = FALSE THEN 0 ELSE 1 END,
		in_apply_deleg_plans			=>	CASE WHEN in_apply_deleg_plans = FALSE THEN 0 ELSE 1 END,
		in_ignore_sids					=>	in_ignore_sids
	);
END;

PROCEDURE SynchSecondaryForTagGroupList(
	in_secondary_root_sid			IN	security_pkg.T_SID_ID,
	in_tag_group_id_list			IN	VARCHAR2,
	in_active_only					IN	NUMBER DEFAULT 0,
	in_reduce_contention			IN	BOOLEAN DEFAULT FALSE,
	in_apply_deleg_plans			IN	BOOLEAN DEFAULT TRUE,
	in_ignore_sids					IN	security.T_SID_TABLE DEFAULT NULL
)
AS
BEGIN
	SyncSecondaryForTagGroupList(
		in_secondary_root_sid			=>	in_secondary_root_sid,
		in_tag_group_id_list			=>	in_tag_group_id_list,
		in_active_only					=>	in_active_only,
		in_reduce_contention			=>	CASE WHEN in_reduce_contention = FALSE THEN 0 ELSE 1 END,
		in_apply_deleg_plans			=>	CASE WHEN in_apply_deleg_plans = FALSE THEN 0 ELSE 1 END,
		in_ignore_sids					=>	in_ignore_sids
	);
END;

PROCEDURE SynchSecondaryPropByFunds(
	in_secondary_root_sid			IN	security_pkg.T_SID_ID,
	in_region_root_sid				IN  security_pkg.T_SID_ID DEFAULT NULL, -- Null means use primary. 
	in_reduce_contention			IN	BOOLEAN DEFAULT FALSE,
	in_apply_deleg_plans			IN	BOOLEAN DEFAULT TRUE,
	in_ignore_sids					IN	security.T_SID_TABLE DEFAULT NULL
)
AS
BEGIN
	SyncSecondaryPropByFunds(
		in_secondary_root_sid			=>	in_secondary_root_sid,
		in_region_root_sid				=>	in_region_root_sid,
		in_reduce_contention			=>	CASE WHEN in_reduce_contention = FALSE THEN 0 ELSE 1 END,
		in_apply_deleg_plans			=>	CASE WHEN in_apply_deleg_plans = FALSE THEN 0 ELSE 1 END,
		in_ignore_sids					=>	in_ignore_sids
	);
END;

PROCEDURE SynchPropTreeByMgtCompany(
	in_secondary_root_sid			IN	security_pkg.T_SID_ID,
	in_region_root_sid				IN  security_pkg.T_SID_ID DEFAULT NULL, -- Null means use primary. 
	in_reduce_contention			IN	BOOLEAN DEFAULT FALSE,
	in_apply_deleg_plans			IN	BOOLEAN DEFAULT TRUE,
	in_ignore_sids					IN	security.T_SID_TABLE DEFAULT NULL
)
AS
BEGIN
	SyncPropTreeByMgtCompany(
		in_secondary_root_sid			=>	in_secondary_root_sid,
		in_region_root_sid				=>	in_region_root_sid,
		in_reduce_contention			=>	CASE WHEN in_reduce_contention = FALSE THEN 0 ELSE 1 END,
		in_apply_deleg_plans			=>	CASE WHEN in_apply_deleg_plans = FALSE THEN 0 ELSE 1 END,
		in_ignore_sids					=>	in_ignore_sids
	);
END;


/*
 * Legacy version of tree sync. Should be refactored away.
 * Used by a number of client sites:
 
 GreenPrint - probably obsolete, could probably be removed or rewritten.
  C:\cvs\clients\greenprint\db\greenprint_body.sql(430):	csr.region_tree_pkg.INTERNAL_SynchTree(csr.region_tree_pkg.GetSecondaryRegionTreeRootSid('Secondary'), tbl_primary, TRUE, FALSE);
  C:\cvs\clients\greenprint\db\greenprint_body.sql(431):	csr.region_tree_pkg.INTERNAL_SynchTree(csr.region_tree_pkg.GetSecondaryRegionTreeRootSid('Secondary - By Fund'), tbl_primary, TRUE, FALSE);
  C:\cvs\clients\greenprint\db\synchFundTree.sql(12):     region_tree_pkg.INTERNAL_SynchTree(16512666, tbl_primary, TRUE, FALSE);

 Lloyds - currently doesn't compile/work and uses a missing lookup key; rewrite.
  C:\cvs\clients\lloyds\db\sync_tsb_lloyds_secondary_tree.sql(47):     region_tree_pkg.INTERNAL_SynchTree(v_secondary_root_sid, tbl_primary, false, false, in_ignore_sids);

 Lumileds - rewrite.
  C:\cvs\clients\lumileds\db\property_import_body.sql(629):	csr.region_tree_pkg.INTERNAL_SynchTree(
 Philipslighting - rewrite.
  C:\cvs\clients\philipslighting\db\property_import_body.sql(629):	csr.region_tree_pkg.INTERNAL_SynchTree(
 Philips - rewrite.
  C:\cvs\clients\philips\db\carbonNonIndustrialScripts.sql(286):     region_tree_pkg.INTERNAL_SynchTree(12452190, tbl_primary);
  C:\cvs\clients\philips\db\properties\property_import_body.sql(624):	csr.region_tree_pkg.INTERNAL_SynchTree(
  C:\cvs\clients\philips\db\properties\sectors.sql(422):	csr.region_tree_pkg.INTERNAL_SynchTree(

 Nestle - rewrite.
  C:\cvs\clients\nestle\db\tree_body.sql(234):	csr.region_tree_pkg.INTERNAL_SynchTree(
  C:\cvs\clients\shepmpp\db\tree_body.sql(234):	csr.region_tree_pkg.INTERNAL_SynchTree(
 */
 
PROCEDURE INTERNAL_SynchTree(
	in_secondary_root_sid			IN	security_pkg.T_SID_ID,
	tbl_primary						IN	OUT NOCOPY T_SID_AND_DESCRIPTION_TABLE,
	in_reduce_contention			IN	NUMBER DEFAULT 0,
	in_apply_deleg_plans			IN	NUMBER DEFAULT 1,
	in_ignore_sids					IN	security.T_SID_TABLE DEFAULT NULL
)
AS
	v_seek_parent_sid		security_pkg.T_SID_ID;
	v_region_lnk_sid		security_pkg.T_SID_ID;
	v_region_lnk_name		csr.region.name%TYPE;
	v_region_lnk_desc		csr.region_description.description%TYPE;
	v_cnt					NUMBER(10);
	v_did_something			BOOLEAN := FALSE;
	v_tbl_primary			T_SID_AND_DESCRIPTION_TABLE;
	v_tbl_secondary			T_SID_AND_DESCRIPTION_TABLE;
BEGIN
	IF in_ignore_sids IS NULL THEN
		v_tbl_primary := tbl_primary;
	ELSE
		SELECT T_SID_AND_DESCRIPTION_ROW(pos, sid_id, description)
		  BULK COLLECT INTO v_tbl_primary
		  FROM TABLE(tbl_primary)
		 WHERE sid_id NOT IN (SELECT column_value FROM TABLE(in_ignore_sids));
	END IF;

    -- delete from secondary when no longer in primary set
    FOR r IN (
            SELECT region_sid
              FROM region
             WHERE link_to_region_sid IS NOT NULL
             START WITH parent_sid = in_secondary_root_sid -- secondary
           CONNECT BY PRIOR region_sid = parent_sid
             MINUS
            SELECT region_sid
              FROM region 
             WHERE link_to_region_sid IN (
                SELECT sid_id FROM TABLE(v_tbl_primary)
             )
    )
    LOOP
        --dbms_output.put_line('deleting '||r.region_sid);
        --security_pkg.debugmsg('deleting useless region '||r.region_sid);
        securableobject_pkg.DeleteSO(security_pkg.getACT, r.region_sid);
        v_did_something := TRUE;
        IF in_reduce_contention <> 0 THEN
        	COMMIT;
        END IF;
    END LOOP;
	
	-- Have to do get the data we want to compare against in the following
	-- loop below here because of an Oracle bug (ORA-03002: operator not implemented).
	SELECT T_SID_AND_DESCRIPTION_ROW(rownum, region_sid, path)
      BULK COLLECT INTO v_tbl_secondary
      FROM (
		  SELECT region_sid, SUBSTR(rp, 0, LENGTH(rp) - LENGTH(description) - 1) path
				  FROM (
					  -- nodes that are a perfect match (i.e. in both, sharing same path) we can forget about
					  SELECT link_to_region_sid region_sid,
						   LTRIM(SYS_CONNECT_BY_PATH(REPLACE(description,CHR(1),'_'),''),'') rp,
						   description
						FROM v$region
					   WHERE link_to_region_sid IS NOT NULL
					   START WITH parent_sid = in_secondary_root_sid
					 CONNECT BY PRIOR region_sid = parent_sid
			)
		);
    
    -- create stuff that's in the primary but not the secondary
	FOR r IN (
		SELECT vtp.sid_id region_sid, vtp.description path
		  FROM TABLE(v_tbl_primary) vtp
		  LEFT JOIN TABLE(v_tbl_secondary) ltr
			ON vtp.sid_id = ltr.sid_id AND LOWER(vtp.description) = LOWER(ltr.description)
		 WHERE vtp.sid_id IS NOT NULL
		   AND ltr.sid_id IS NULL
	)
	LOOP
        -- crude but probably quite fast
        v_seek_parent_sid := in_secondary_root_sid;
        FOR s IN (
            SELECT item, pos
              FROM TABLE(utils_pkg.SplitString(r.path, ''))
             ORDER BY pos
        )
        LOOP
			IF s.item IS NULL THEN
				CONTINUE;
			END IF;
			
			BEGIN
                SELECT region_sid
                  INTO v_seek_parent_sid
                  FROM v$region
                 WHERE parent_sid = v_seek_parent_sid
                   AND LOWER(description) = LOWER(s.item);
				--security_pkg.debugmsg('descended to '||v_seek_parent_sid||' based on description '||s.item);
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    -- create
                    --security_pkg.debugmsg('creating '||s.item||' under '||v_seek_parent_sid);
                    -- TODO: copy over geo properties etc? ugh. Bit harder with my
                    -- optimisation based on the path.
                    csr.region_pkg.CreateRegion(
                        in_parent_sid 			=> v_seek_parent_sid,
                        in_name 				=> s.item,
                        in_description 			=> s.item,
                        in_apply_deleg_plans	=> 0, -- do this after synchronising the tree
                        out_region_sid 			=> v_seek_parent_sid
                    );
                    v_did_something := TRUE;
                    
                    IF in_reduce_contention <> 0 THEN
                    	COMMIT;
                    END IF;
                    --security_pkg.debugmsg('created sid '||v_seek_parent_sid);
				WHEN OTHERS THEN
					-- Throw an exception with more info so we can investigate. Most likely be caused by
					-- regions with the same description under the same parent region.
					raise_application_error(-20001, 'Error building regions of region: '||r.region_sid||'. Path: '||r.path||'. Creating region with name: '||s.item);
            END;
            -- Only leaf nodes should link to a region
            UPDATE region
			   SET link_to_region_sid = NULL
			 WHERE region_sid = v_seek_parent_sid
			   AND link_to_region_sid IS NOT NULL;
        END LOOP;
		
		-- Delete anything that links to this already
        FOR s IN (
            SELECT region_sid
              FROM region
             WHERE link_to_region_sid = r.region_sid
               AND parent_sid != v_seek_parent_sid
             START WITH parent_sid = in_secondary_root_sid -- secondary
           CONNECT BY PRIOR region_sid = parent_sid         
        )
        LOOP
            --dbms_output.put_line('deleting dupe link '||s.region_sid);
            --security_pkg.debugmsg('deleting dupe link '||s.region_sid||' to '||r.region_sid||' in tree with root '||in_secondary_root_sid);
            securableobject_pkg.DeleteSO(security_pkg.getACT, s.region_sid);
            v_did_something := TRUE;
            
            IF in_reduce_contention <> 0 THEN
            	COMMIT;
            END IF;            
        END LOOP;
		
		-- Give link region the same name + desc as the region we are linking to.
		SELECT rgn.region_sid, rgn.name, rd.description
		  INTO v_region_lnk_sid, v_region_lnk_name, v_region_lnk_desc
		  FROM region rgn
		  JOIN region_description rd
		    ON rgn.region_sid = rd.region_sid
		 WHERE rgn.region_sid = r.region_sid
		   AND rd.lang = 'en';
		
		-- Create link region.
		csr.region_pkg.CreateRegion(
			in_parent_sid			=> v_seek_parent_sid,
			in_name					=> v_region_lnk_name||v_region_lnk_sid, -- append region sid to end to make unique.
			in_description			=> v_region_lnk_desc,
			in_apply_deleg_plans	=> 0, -- do this after synchronising the tree
			out_region_sid			=> v_seek_parent_sid
		);
		
        -- Set the leaf node region link.
        --security_pkg.debugmsg('making '||r.region_sid||' into a link to '||v_seek_parent_sid);
        UPDATE region
           SET link_to_region_sid = r.region_sid
         WHERE region_sid = v_seek_parent_sid;

        v_did_something := TRUE;
        
        IF in_reduce_contention <> 0 THEN
        	COMMIT;
        END IF;        
    END LOOP;
    
    -- prune secondary tree of nodes with no links beneath them
    v_cnt := 1;
    -- can't be arsed to work out some crazy sql so just keep going until we're done
    WHILE v_cnt > 0
    LOOP
        v_cnt := 0;
        FOR r IN (
            SELECT region_sid
              FROM region
             WHERE CONNECT_BY_ISLEAF = 1
               AND link_to_region_sid IS NULL 
             START WITH parent_sid = in_secondary_root_sid
            CONNECT BY PRIOR region_sid = parent_sid
        )
        LOOP
            --security_pkg.debugmsg('pruning unlinked region '||r.region_sid+);
            securableobject_pkg.DeleteSO(security_pkg.getACT, r.region_sid);
            v_cnt := v_cnt + 1;

            IF in_reduce_contention <> 0 THEN
            	COMMIT;
            END IF;
        END LOOP;
    END LOOP;
    
    IF v_did_something THEN
        -- write some jobs if we did anything
        -- note that region_sid is irrelevant (interface needs updating)
        region_pkg.AddAggregateJobs(security_pkg.getApp, NULL);
        
        IF in_apply_deleg_plans <> 0 THEN
	        -- sync dynamic delegation plans
	        region_pkg.ApplyDynamicPlans(NULL, 'Tree synch');
		END IF;
    END IF;
	
	INTERNAL_PropagateSecondaryTreeRoles(in_secondary_root_sid, in_reduce_contention);
END;


/**/
/* End Legacy versions */

/* Sync helper functions */
PROCEDURE INT_SyncTrace(
	in_enable_trace		BOOLEAN,
	in_message			VARCHAR2
)
AS
BEGIN
	IF in_enable_trace = TRUE THEN
		dbms_output.put_line(in_message);
	END IF;
END;

PROCEDURE INT_SyncUpdateSecondaryTree(
	in_enable_trace			IN	BOOLEAN,
	in_reduce_contention	IN	NUMBER,
	in_use_tag_descriptions	IN	NUMBER,
	in_parent_sid			IN	security_pkg.T_SID_ID,
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_description			IN	VARCHAR2,
	in_sid_path				IN	VARCHAR2,
	out_leaf_sid			OUT	security_pkg.T_SID_ID,
	out_created_region		OUT	BOOLEAN
)
AS
	v_created_region		BOOLEAN := FALSE;
	v_app					security_pkg.T_SID_ID := security_pkg.getApp;
	v_act					security_pkg.T_ACT_ID := security_pkg.getACT;
	v_seek_parent_sid		security_pkg.T_SID_ID;
BEGIN
	-- crude but probably quite fast
	v_seek_parent_sid := in_parent_sid;
	FOR s IN (
		SELECT descs.pos, descs.item region_name, sids.item region_sid
		  FROM TABLE(utils_pkg.SplitString(in_description, '')) descs
		  JOIN TABLE(utils_pkg.SplitString(in_sid_path, '')) sids ON sids.pos = descs.pos
		 ORDER BY descs.pos
	)
	LOOP
		IF s.region_name IS NULL THEN
			CONTINUE;
		END IF;
		INT_SyncTrace(in_enable_trace, 'px rgn '||s.region_name||' - '||s.region_sid||' at pos '||s.pos||' seek on '||v_seek_parent_sid);
		
		BEGIN
			SELECT region_sid
			  INTO v_seek_parent_sid
			  FROM v$region
			 WHERE parent_sid = v_seek_parent_sid
			   AND LOWER(name) = LOWER(REPLACE(s.region_name, '/', '\')) --'
			   AND trash_pkg.IsInTrash(v_act, region_sid) = 0;
			INT_SyncTrace(in_enable_trace, 'descended to '||v_seek_parent_sid||' based on name '||s.region_name||' at pos '||s.pos);
			
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				-- create
				INT_SyncTrace(in_enable_trace, 'creating '||s.region_name||' under '||v_seek_parent_sid);
				-- TODO: copy over geo properties etc? ugh. Bit harder with my
				-- optimisation based on the path.
				csr.region_pkg.CreateRegion(
					in_parent_sid 			=> v_seek_parent_sid,
					in_name 				=> s.region_name,
					in_description 			=> s.region_name,
					in_apply_deleg_plans	=> 0, -- do this after synchronising the tree
					out_region_sid			=> v_seek_parent_sid
				);
				out_created_region := TRUE;
				
				IF in_reduce_contention <> 0 THEN
					COMMIT;
				END IF;
				INT_SyncTrace(in_enable_trace, 'created sid '||v_seek_parent_sid);
			WHEN OTHERS THEN
				-- Throw an exception with more info so we can investigate. Most likely be caused by
				-- regions with the same description under the same parent region.
				raise_application_error(-20001, 'Error building regions of region: '||in_region_sid||'. Path: '||in_description||'. Creating region with name: '||s.region_name||', EC:'||SQLCODE||', ERRM:'||SQLERRM);
		END;

		--update the descriptions if we got this far.
		INT_SyncTrace(in_enable_trace, 'Copy description '||s.region_name||' '||s.region_sid||' to ' || v_seek_parent_sid);

		IF s.pos = 1 THEN
			IF in_use_tag_descriptions = 0 THEN
				-- TODO - The root node is the pivot object; this ought to come from the root object type and use its lang variations too.
				UPDATE region_description
				   SET description = s.region_name
				 WHERE app_sid = v_app
				   AND region_sid = v_seek_parent_sid
				   AND description != s.region_name;
			ELSE
				FOR ur IN (
					SELECT app_sid, lang, tag
					  FROM tag_description 
					 WHERE app_sid = v_app
					   AND tag_id = s.region_sid
				)
				LOOP
					INT_SyncTrace(in_enable_trace, 'RUpdate '|| ur.lang ||' '|| ur.tag);
					UPDATE region_description
					   SET description = ur.tag
					 WHERE app_sid = ur.app_sid
					   AND region_sid = v_seek_parent_sid
					   AND lang = ur.lang
					   AND description != ur.tag;
				END LOOP;
			END IF;
		ELSE
			IF in_use_tag_descriptions = 0 THEN
				FOR ur IN (
					SELECT app_sid, lang, description
					  FROM region_description 
					 WHERE app_sid = v_app
					   AND region_sid = v_seek_parent_sid--TO_NUMBER(s.region_sid)
				)
				LOOP
					-- TODO - The tree nodes descriptions should come from the primary region and use its lang variations too.
					INT_SyncTrace(in_enable_trace, 'Update '|| ur.lang ||' '|| ur.description);
					UPDATE region_description
					   SET description = ur.description
					 WHERE app_sid = ur.app_sid
					   AND region_sid = v_seek_parent_sid
					   AND lang = ur.lang
					   AND description != ur.description;
				END LOOP;
			ELSE
				FOR ur IN (
					SELECT app_sid, lang, tag
					  FROM tag_description 
					 WHERE app_sid = v_app
					   AND tag_id = s.region_sid
				)
				LOOP
					INT_SyncTrace(in_enable_trace, 'RTUpdate '|| ur.lang ||' '|| ur.tag);
					UPDATE region_description
					   SET description = ur.tag
					 WHERE app_sid = ur.app_sid
					   AND region_sid = v_seek_parent_sid
					   AND lang = ur.lang
					   AND description != ur.tag;
				END LOOP;
			END IF;

			-- Only leaf nodes should link to a region
			UPDATE region
			   SET link_to_region_sid = NULL
			 WHERE region_sid = v_seek_parent_sid
			   AND link_to_region_sid IS NOT NULL;
		END IF;
	END LOOP;
	
	out_leaf_sid := v_seek_parent_sid;
END;

PROCEDURE INT_SyncDeleteDupeLinks(
	in_enable_trace			IN	BOOLEAN,
	in_reduce_contention	IN	NUMBER,
	in_secondary_root_sid	IN	security_pkg.T_SID_ID,
	in_parent_sid			IN	security_pkg.T_SID_ID,
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_deleted_link		OUT	BOOLEAN
)
AS
BEGIN
	FOR s IN (
		SELECT region_sid
		  FROM region
		 WHERE link_to_region_sid = in_region_sid
		   AND parent_sid != in_parent_sid
		 START WITH parent_sid = in_secondary_root_sid -- secondary
	   CONNECT BY PRIOR region_sid = parent_sid
	)
	LOOP
		INT_SyncTrace(in_enable_trace, 'deleting dupe link '||s.region_sid||' to '||in_region_sid||' in tree with root '||in_secondary_root_sid);
		securableobject_pkg.DeleteSO(security_pkg.getACT, s.region_sid);
		out_deleted_link := TRUE;
		
		IF in_reduce_contention <> 0 THEN
			COMMIT;
		END IF;
	END LOOP;
END;

PROCEDURE INT_SyncCreateLink(
	in_enable_trace				IN	BOOLEAN,
	in_reduce_contention		IN	NUMBER,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_parent_sid				IN	security_pkg.T_SID_ID,
	out_created_link_region		OUT	BOOLEAN,
	out_updated_link_region		OUT	BOOLEAN
)
AS
	v_app					security_pkg.T_SID_ID := security_pkg.getApp;
	v_new_region_sid		security_pkg.T_SID_ID;
	v_new_region_name		csr.region.name%TYPE;
	v_region_lnk_sid		security_pkg.T_SID_ID;
	v_region_lnk_name		csr.region.name%TYPE;
	v_region_lnk_desc		csr.region_description.description%TYPE;
BEGIN
	INT_SyncTrace(in_enable_trace, 'Give link region the same name + desc as the region we are linking to.');
	-- Give link region the same name + desc as the region we are linking to.
	SELECT rgn.region_sid, rgn.name, rd.description
	  INTO v_region_lnk_sid, v_region_lnk_name, v_region_lnk_desc
	  FROM region rgn
	  JOIN region_description rd
		ON rgn.region_sid = rd.region_sid
	 WHERE rgn.region_sid = in_region_sid
	   AND rd.lang = 'en';
	
	-- append region sid to name to make unique.
	v_new_region_name := v_region_lnk_name||v_region_lnk_sid;
	
	-- Check to see if it's already in existence with an old name.
	SELECT MIN(region_sid)
	  INTO v_new_region_sid
	  FROM v$region
	 WHERE name = v_region_lnk_name
	   AND parent_sid = in_parent_sid;

	IF v_new_region_sid IS NULL THEN
		-- Check to see if it's already in existence with an old name, ignoring case.
		SELECT MIN(region_sid)
		  INTO v_new_region_sid
		  FROM v$region
		 WHERE LOWER(name) = LOWER(v_region_lnk_name)
		   AND parent_sid = in_parent_sid;
	END IF;

	IF v_new_region_sid IS NULL THEN
		-- Check to see if it's already in existence with an old description.
		SELECT MIN(region_sid)
		  INTO v_new_region_sid
		  FROM v$region
		 WHERE name = v_region_lnk_desc
		   AND parent_sid = in_parent_sid;
	END IF;

	IF v_new_region_sid IS NULL THEN
		-- Check to see if it's already in existence with an old description, ignoring case.
		SELECT MIN(region_sid)
		  INTO v_new_region_sid
		  FROM v$region
		 WHERE LOWER(name) = LOWER(v_region_lnk_desc)
		   AND parent_sid = in_parent_sid;
	END IF;

	IF v_new_region_sid IS NOT NULL THEN
		INT_SyncTrace(in_enable_trace, 'Found region with old link description  n='||v_region_lnk_desc||'; p='||in_parent_sid);
		UPDATE region
		   SET name = v_new_region_name
		 WHERE region_sid = v_new_region_sid;
		
		-- Update the link description too for consistency.
		FOR ur IN (
			SELECT app_sid, lang, description
			  FROM region_description 
			 WHERE app_sid = v_app
			   AND region_sid = in_region_sid
		)
		LOOP
			UPDATE region_description
			   SET description = ur.description
			 WHERE app_sid = ur.app_sid
			   AND region_sid = v_new_region_sid
			   AND lang = ur.lang
			   AND description != ur.description;
		END LOOP;
	END IF;

	-- Check to see if it's already in existence.
	-- Don't check description though, it could have changed either end.
	INT_SyncTrace(in_enable_trace, 'Check for  n='||v_new_region_name||'; p='||in_parent_sid);
	SELECT MIN(region_sid)
	  INTO v_new_region_sid
	  FROM v$region
	 WHERE name = v_new_region_name
	   AND parent_sid = in_parent_sid;
	
	IF v_new_region_sid IS NULL THEN
		-- Create link region.
		INT_SyncTrace(in_enable_trace, 'Create link region '||v_new_region_name);
		csr.region_pkg.CreateRegion(
			in_parent_sid			=> in_parent_sid,
			in_name					=> v_new_region_name,
			in_description			=> v_region_lnk_desc,
			in_apply_deleg_plans	=> 0, -- do this after synchronising the tree
			out_region_sid			=> v_new_region_sid
		);
		out_created_link_region := TRUE;
	ELSE
		INT_SyncTrace(in_enable_trace, v_new_region_name || ' already existed; no action needed.');
		NULL;
	END IF;
	-- Set the leaf node region link.
	INT_SyncTrace(in_enable_trace, 'making '||in_region_sid||' into a link to '||in_parent_sid);
	UPDATE region
	   SET link_to_region_sid = in_region_sid
	 WHERE region_sid = v_new_region_sid;

	out_updated_link_region := TRUE;

	IF in_reduce_contention <> 0 THEN
		COMMIT;
	END IF;
END;

PROCEDURE INT_SyncPruneEmptyNodes(
	in_enable_trace			IN	BOOLEAN,
	in_reduce_contention	IN	NUMBER,
	in_parent_sid			IN	security_pkg.T_SID_ID
)
AS
	v_cnt					NUMBER(10);
BEGIN
	-- prune secondary tree of nodes with no links beneath them
	v_cnt := 1;
	-- can't be arsed to work out some crazy sql so just keep going until we're done
	WHILE v_cnt > 0
	LOOP
		v_cnt := 0;
		FOR r IN (
			SELECT region_sid
			  FROM region
			 WHERE CONNECT_BY_ISLEAF = 1
			   AND link_to_region_sid IS NULL 
			 START WITH parent_sid = in_parent_sid
			CONNECT BY PRIOR region_sid = parent_sid
		)
		LOOP
			INT_SyncTrace(in_enable_trace, 'Pruning unlinked region '||r.region_sid||' from secondary as no longer required.');
			securableobject_pkg.DeleteSO(security_pkg.getACT, r.region_sid);
			v_cnt := v_cnt + 1;
			
			IF in_reduce_contention <> 0 THEN
				COMMIT;
			END IF;
		END LOOP;
	END LOOP;
END;

/*
 * Pass this what you want your tree to look like and it'll make it look like this!
 * New version of the sync - internal only this time.
 */
PROCEDURE INTERNAL_SyncTree(
	in_secondary_root_sid			IN	security_pkg.T_SID_ID,
	tbl_primary						IN	OUT NOCOPY T_SID_AND_PATH_AND_DESC_TABLE,
	in_reduce_contention			IN	NUMBER DEFAULT 0,
	in_apply_deleg_plans			IN	NUMBER DEFAULT 1,
	in_ignore_sids					IN	security.T_SID_TABLE DEFAULT NULL,
	in_use_tag_descriptions			IN	NUMBER DEFAULT 0
)
AS
	v_app					security_pkg.T_SID_ID := security_pkg.getApp;
	v_act					security_pkg.T_ACT_ID := security_pkg.getACT;
	v_seek_parent_sid		security_pkg.T_SID_ID;
	v_tag_id				csr.region_tag.tag_id%TYPE;
	v_did_something			BOOLEAN := FALSE;
	v_created_region		BOOLEAN;
	v_deleted_link			BOOLEAN;
	v_created_link_region	BOOLEAN;
	v_updated_link_region	BOOLEAN;
	v_tbl_primary			T_SID_AND_PATH_AND_DESC_TABLE;
	v_tbl_secondary			T_SID_AND_PATH_AND_DESC_TABLE;
	
	v_enable_trace			BOOLEAN := TRUE;
BEGIN
	IF in_ignore_sids IS NULL THEN
		v_tbl_primary := tbl_primary;
	ELSE
		SELECT T_SID_AND_PATH_AND_DESC_ROW(pos, sid_id, path, description)
		  BULK COLLECT INTO v_tbl_primary
		  FROM TABLE(tbl_primary)
		 WHERE sid_id NOT IN (SELECT column_value FROM TABLE(in_ignore_sids));
	END IF;

	FOR primary IN (SELECT * FROM TABLE(v_tbl_primary))
	LOOP
		INT_SyncTrace(v_enable_trace, 'v_tbl_primary '||primary.pos||' '||primary.sid_id||' '||primary.path||' '||primary.description);
	END LOOP;
	
	-- delete from secondary when no longer in primary set
	FOR r IN (
		SELECT region_sid
		  FROM region
		 WHERE link_to_region_sid IS NOT NULL
		 START WITH parent_sid = in_secondary_root_sid -- secondary
		CONNECT BY PRIOR region_sid = parent_sid
		 MINUS
		SELECT region_sid
		  FROM region 
		 WHERE link_to_region_sid IN (
			SELECT sid_id FROM TABLE(v_tbl_primary)
		 )
	)
	LOOP
		INT_SyncTrace(v_enable_trace, 'Deleting '||r.region_sid||' from secondary as not in primary.');
		securableobject_pkg.DeleteSO(security_pkg.getACT, r.region_sid);
		v_did_something := TRUE;
		IF in_reduce_contention <> 0 THEN
			COMMIT;
		END IF;
	END LOOP;
	
	-- Have to do get the data we want to compare against in the following
	-- loop below here because of an Oracle bug (ORA-03002: operator not implemented).
	SELECT T_SID_AND_PATH_AND_DESC_ROW(rownum, region_sid, path, description)
	  BULK COLLECT INTO v_tbl_secondary
	  FROM (
		SELECT region_sid, SUBSTR(sid_path, 0, LENGTH(sid_path) - LENGTH(region_sid) - 1) path, SUBSTR(desc_path, 0, LENGTH(desc_path) - LENGTH(name) - 1) description
		  FROM (
			-- nodes that are a perfect match (i.e. in both, sharing same path) we can forget about
			SELECT link_to_region_sid region_sid, name,
			 LTRIM(SYS_CONNECT_BY_PATH(REPLACE(region_sid,CHR(1),'_'),''),'') sid_path,
			 LTRIM(SYS_CONNECT_BY_PATH(REPLACE(name,CHR(1),'_'),''),'') desc_path
			  FROM v$region
			 WHERE link_to_region_sid IS NOT NULL
			 START WITH parent_sid = in_secondary_root_sid
			CONNECT BY PRIOR region_sid = parent_sid
		)
	);
	
	FOR secondary IN (SELECT * FROM TABLE(v_tbl_secondary))
	LOOP
		INT_SyncTrace(v_enable_trace, 'v_tbl_secondary '||secondary.pos||' '||secondary.sid_id||' '||secondary.path||' '||secondary.description);
	END LOOP;
	
	INT_SyncTrace(v_enable_trace, '');


	-- create or update stuff that's in the primary
	FOR r IN (
		SELECT vtp.sid_id region_sid, vtp.path sid_path, vtp.description description
		  FROM TABLE(v_tbl_primary) vtp
		  LEFT JOIN TABLE(v_tbl_secondary) ltr
			ON vtp.sid_id = ltr.sid_id AND TRIM('' FROM LOWER(vtp.description)) != TRIM('' FROM LOWER(ltr.description))
		 WHERE vtp.sid_id IS NOT NULL
		   AND ltr.sid_id IS NULL
	)
	LOOP
		INT_SyncTrace(v_enable_trace, 'cu px desc ' || r.description ||', sidp '||r.sid_path||' for rgn  '||r.region_sid);
		v_seek_parent_sid := in_secondary_root_sid;
		
		INT_SyncUpdateSecondaryTree(
			in_enable_trace			=>	v_enable_trace,
			in_reduce_contention	=>	in_reduce_contention,
			in_use_tag_descriptions	=>	in_use_tag_descriptions,
			in_parent_sid			=>	v_seek_parent_sid,
			in_region_sid			=>	r.region_sid,
			in_description			=>	r.description,
			in_sid_path				=>	r.sid_path,
			out_leaf_sid			=>	v_seek_parent_sid,
			out_created_region		=>	v_created_region
		);
		IF v_created_region = TRUE THEN
			v_did_something := TRUE;
		END IF;
		
		-- Delete anything that links to this already
		INT_SyncDeleteDupeLinks(
			in_enable_trace			=>	v_enable_trace,
			in_reduce_contention	=>	in_reduce_contention,
			in_secondary_root_sid	=>	in_secondary_root_sid,
			in_parent_sid			=>	v_seek_parent_sid,
			in_region_sid			=>	r.region_sid,
			out_deleted_link		=>	v_deleted_link
		);
		IF v_deleted_link = TRUE THEN
			v_did_something := TRUE;
		END IF;
		
		INT_SyncCreateLink(
			in_enable_trace			=>	v_enable_trace,
			in_reduce_contention	=>	in_reduce_contention,
			in_region_sid			=>	r.region_sid,
			in_parent_sid			=>	v_seek_parent_sid,
			out_created_link_region	=>	v_created_link_region,
			out_updated_link_region	=>	v_updated_link_region
		);
		IF v_created_link_region = TRUE OR v_updated_link_region = TRUE THEN
			v_did_something := TRUE;
		END IF;
	END LOOP;

	-- find stuff that's in the primary but not the same place in the secondary
	FOR r IN (
		SELECT vtp.sid_id region_sid, vtp.path sid_path, vtp.description description
		  FROM TABLE(v_tbl_primary) vtp
		  LEFT JOIN TABLE(v_tbl_secondary) ltr
			ON vtp.sid_id = ltr.sid_id AND TRIM('' FROM LOWER(vtp.description)) = TRIM('' FROM LOWER(ltr.description))
		 WHERE vtp.sid_id IS NOT NULL
		   AND ltr.sid_id IS NULL
	)
	LOOP
		INT_SyncTrace(v_enable_trace, 'm px desc ' || r.description ||', sidp '||r.sid_path||' for rgn  '||r.region_sid);
		v_seek_parent_sid := in_secondary_root_sid;
		INT_SyncUpdateSecondaryTree(
			in_enable_trace			=>	v_enable_trace,
			in_reduce_contention	=>	in_reduce_contention,
			in_use_tag_descriptions	=>	in_use_tag_descriptions,
			in_parent_sid			=>	v_seek_parent_sid,
			in_region_sid			=>	r.region_sid,
			in_description			=>	r.description,
			in_sid_path				=>	r.sid_path,
			out_leaf_sid			=>	v_seek_parent_sid,
			out_created_region		=>	v_created_region
		);
		IF v_created_region = TRUE THEN
			v_did_something := TRUE;
		END IF;
		
		-- Delete anything that links to this already
		INT_SyncDeleteDupeLinks(
			in_enable_trace			=>	v_enable_trace,
			in_reduce_contention	=>	in_reduce_contention,
			in_secondary_root_sid	=>	in_secondary_root_sid,
			in_parent_sid			=>	v_seek_parent_sid,
			in_region_sid			=>	r.region_sid,
			out_deleted_link		=>	v_deleted_link
		);
		IF v_deleted_link = TRUE THEN
			v_did_something := TRUE;
		END IF;
		
		INT_SyncCreateLink(
			in_enable_trace			=>	v_enable_trace,
			in_reduce_contention	=>	in_reduce_contention,
			in_region_sid			=>	r.region_sid,
			in_parent_sid			=>	v_seek_parent_sid,
			out_created_link_region	=>	v_created_link_region,
			out_updated_link_region	=>	v_updated_link_region
		);
		IF v_created_link_region = TRUE OR v_updated_link_region = TRUE THEN
			v_did_something := TRUE;
		END IF;
	END LOOP;
	
	INT_SyncPruneEmptyNodes(
		in_enable_trace			=>	v_enable_trace,
		in_reduce_contention	=>	in_reduce_contention,
		in_parent_sid			=>	in_secondary_root_sid
	);
	
	IF v_did_something THEN
		-- write some jobs if we did anything
		-- note that region_sid is irrelevant (interface needs updating)
		region_pkg.AddAggregateJobs(security_pkg.getApp, NULL);
		
		IF in_apply_deleg_plans <> 0 THEN
			-- sync dynamic delegation plans
			region_pkg.ApplyDynamicPlans(NULL, 'Tree synch');
		END IF;
	END IF;
	
	INTERNAL_PropagateSecondaryTreeRoles(in_secondary_root_sid, in_reduce_contention);
END;


PROCEDURE CreateTreeReport(
	in_region_sid		IN	NUMBER,
	out_blob 			OUT	BLOB
)
AS
	v_report_lines		CLOB;
	
	v_blob				BLOB;
	v_dest_offset		INTEGER := 1;
	v_source_offset		INTEGER := 1;
	v_lang_context		INTEGER := DBMS_LOB.DEFAULT_LANG_CTX;
	v_warning			INTEGER := DBMS_LOB.WARN_INCONVERTIBLE_CHAR;
	
BEGIN
	v_report_lines := 
		'region_sid' || ',' ||
		'path' || ',' ||
		'description' || ',' ||
		'level' || ',' ||
		'lookup_key' || ',' ||
		'region_ref' || ',' ||
		'linked_sid_id' || ',' ||
		'linked_to' || ',' ||
		'active' || ',' ||
		'country' || ',' ||
		'region' || ',' ||
		'city_name' || ',' ||
		'egrid_ref' || ',' ||
		'geo_latitude' || ',' ||
		'geo_longitude' || ',' ||
		'parent_sid' || ',' ||
		'region_type_label' ||
		CHR(13) || CHR(10)
	;

	FOR r in (
		SELECT
			r.region_sid, region_pkg.INTERNAL_GetRegionPathString(r.region_sid) path,
			CASE
				WHEN r.link_to_region_sid IS NOT NULL THEN
					(SELECT description FROM csr.v$region WHERE region_sid = r.link_to_region_sid)
				ELSE r.description
				END description,
			LEVEL, r.lookup_key, r.region_ref,
			r.link_to_region_sid linked_sid_id,
			CASE
				WHEN r.link_to_Region_sid IS NOT NULL THEN 
					region_pkg.INTERNAL_GetRegionPathString(r.link_to_Region_sid)
				END linked_to,
			CASE
				WHEN r.link_to_region_sid IS NOT NULL THEN
					(SELECT active FROM csr.v$region WHERE region_sid = r.link_to_region_sid)
				ELSE r.active
				END active,
			country, region, city_name, egrid_ref, r.geo_latitude, r.geo_longitude, r.parent_sid,
			r.region_type_label
		  FROM (
			 SELECT r.parent_sid, r.region_sid, r.description, r.link_to_region_sid, r.active, r.lookup_key,r.region_ref,
					c.name country, rg.name region, cy.city_name, egrid_ref,r.geo_latitude, r.geo_longitude,
					rt.label region_type_label,
					m.meter_type_id, mi.label meter_type_label,
					m.primary_ind_sid meter_cons_ind_sid, 
					st.description meter_source_type
			   FROM v$region r
			   JOIN region_type rt ON r.region_type = rt.region_type
			   LEFT JOIN postcode.country c ON r.geo_country = c.country
			   LEFT JOIN postcode.region rg ON r.geo_country = rg.country AND r.geo_region = rg.region
			   LEFT JOIN postcode.city cy ON r.geo_city_id = cy.city_id
			   
			   LEFT JOIN v$meter m ON r.region_sid = m.region_sid
			   LEFT JOIN meter_source_type st ON st.meter_source_type_id = m.meter_source_type_id
			   LEFT JOIN v$legacy_meter_type	mi ON mi.meter_type_id = m.meter_type_id
			  WHERE r.app_sid = security_pkg.GetApp
		  ) r
		 START WITH region_sid = in_region_sid
		  CONNECT BY PRIOR nvl(link_to_region_sid, region_sid) = parent_sid
		 ORDER SIBLINGS BY 
			REGEXP_SUBSTR(LOWER(description), '^\D*') NULLS FIRST, 
			TO_NUMBER(REGEXP_SUBSTR(LOWER(description), '[0-9]+')) NULLS FIRST, 
			TO_NUMBER(CONCAT('0.', REGEXP_SUBSTR(LOWER(description), '[0-9]+', 1, 2))) NULLS FIRST,
			TO_NUMBER(CONCAT('0.', REGEXP_SUBSTR(LOWER(description), '[0-9]+', 1, 3))) NULLS FIRST,
			TO_NUMBER(CONCAT('0.', REGEXP_SUBSTR(LOWER(description), '[0-9]+', 1, 4))) NULLS FIRST,
			LOWER(description), region_sid
	)
	LOOP
		SELECT CONCAT(v_report_lines,
			r.region_sid || ',' ||
			'"' || NVL(r.path,'') || '"' || ',' ||
			NVL(r.description,'') || ',' ||
			NVL(r.level,'') || ',' ||
			NVL(r.lookup_key,'') || ',' ||
			NVL(r.region_ref,'') || ',' ||
			NVL(r.linked_sid_id,'') || ',' ||
			NVL(r.linked_to,'') || ',' ||
			NVL(r.active,'') || ',' ||
			NVL(r.country,'') || ',' ||
			NVL(r.region,'') || ',' ||
			NVL(r.city_name,'') || ',' ||
			NVL(r.egrid_ref,'') || ',' ||
			NVL(r.geo_latitude,'') || ',' ||
			NVL(r.geo_longitude,'') || ',' ||
			NVL(r.parent_sid,'') || ',' ||
			NVL(r.region_type_label,'') ||
			CHR(13) || CHR(10)
		)
		  INTO v_report_lines
		  FROM DUAL;
	END LOOP;


	DBMS_LOB.CREATETEMPORARY(v_blob, TRUE);
	DBMS_LOB.CONVERTTOBLOB (
		dest_lob	=> v_blob,
		src_clob	=> v_report_lines,
		amount		=> DBMS_LOB.LOBMAXSIZE,
		dest_offset	=> v_dest_offset,
		src_offset	=> v_source_offset,
		blob_csid	=> DBMS_LOB.DEFAULT_CSID,
		lang_context=> v_lang_context,
		warning		=> v_warning
	);

	out_blob := v_blob;
END;

PROCEDURE PreLogSync(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_user_sid				IN	security_pkg.T_SID_ID,
	in_region_root_sid		IN	NUMBER		DEFAULT NULL,
	in_tag_id				IN	NUMBER		DEFAULT NULL,
	in_tag_group_ids		IN	VARCHAR2	DEFAULT NULL,
	out_log_id				OUT	NUMBER
)
AS
	v_blob					BLOB;
BEGIN	
	SELECT scndry_region_tree_log_id_seq.nextval
	  INTO out_log_id
	  FROM DUAL;
	
	-- Create existing tree as report and store in blob.
	CreateTreeReport(in_region_sid, v_blob);
	
	INSERT INTO secondary_region_tree_log (log_id, region_sid, user_sid, log_dtm, presync_tree)
	VALUES (out_log_id, in_region_sid, in_user_sid, SYSDATE, v_blob);
END;

PROCEDURE CreateCtrlEntry(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_sp_name				IN	VARCHAR2,
	in_user_sid				IN	security_pkg.T_SID_ID,
	in_region_root_sid		IN	NUMBER		DEFAULT NULL,
	in_tag_id				IN	NUMBER		DEFAULT NULL,
	in_tag_group_ids		IN	VARCHAR2	DEFAULT NULL,
	in_active_only			IN	NUMBER		DEFAULT 0,
	in_reduce_contention	IN	NUMBER		DEFAULT 0,
	in_apply_deleg_plans	IN	NUMBER		DEFAULT 0,
	in_ignore_sids			IN	secondary_region_tree_ctrl.ignore_sids%TYPE,
	in_log_dtm				IN	DATE 		DEFAULT SYSDATE
)
AS
BEGIN
	BEGIN
		INSERT INTO secondary_region_tree_ctrl (region_sid, sp_name, user_sid, 
					region_root_sid, tag_id, tag_group_ids, active_only, reduce_contention, apply_deleg_plans, ignore_sids,
					last_run_dtm)
		VALUES (in_region_sid, in_sp_name, in_user_sid,
			in_region_root_sid, in_tag_id, in_tag_group_ids, 
			in_active_only,
			in_reduce_contention,
			in_apply_deleg_plans,
			in_ignore_sids,
			in_log_dtm);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE secondary_region_tree_ctrl
			   SET sp_name = in_sp_name,
					user_sid = in_user_sid,
					region_root_sid = in_region_root_sid,
					tag_id = in_tag_id,
					tag_group_ids = in_tag_group_ids,
					active_only = in_active_only,
					reduce_contention = in_reduce_contention,
					apply_deleg_plans = in_apply_deleg_plans,
					ignore_sids = in_ignore_sids,
					last_run_dtm = in_log_dtm
			 WHERE app_sid = security.security_pkg.GetApp
			   AND region_sid = in_region_sid;
	END;
END;

FUNCTION StringifyIgnoreSids(
	in_ignore_sids			IN	security.T_SID_TABLE DEFAULT NULL
) RETURN VARCHAR2
AS
	v_ignore_sids			secondary_region_tree_ctrl.ignore_sids%TYPE;
BEGIN
	IF in_ignore_sids IS NOT NULL AND in_ignore_sids.count > 0 THEN
		v_ignore_sids := EMPTY_CLOB();
		FOR r IN (SELECT column_value FROM TABLE(in_ignore_sids))
		LOOP
			IF LENGTH(v_ignore_sids) = 0 THEN 
				v_ignore_sids := TO_CHAR(r.column_value);
			ELSIF LENGTH(v_ignore_sids) > 0 THEN 
				dbms_lob.writeappend(v_ignore_sids, LENGTH(r.column_value) + 1, ','||TO_CHAR(r.column_value));
			END IF;
		END LOOP;
	END IF;
	RETURN v_ignore_sids;
END;

PROCEDURE LogSync(
	in_log_id				IN	NUMBER,
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_sp_name				IN	VARCHAR2,
	in_user_sid				IN	security_pkg.T_SID_ID,
	in_region_root_sid		IN	NUMBER		DEFAULT NULL,
	in_tag_id				IN	NUMBER		DEFAULT NULL,
	in_tag_group_ids		IN	VARCHAR2	DEFAULT NULL,
	in_active_only			IN	NUMBER		DEFAULT 0,
	in_reduce_contention	IN	NUMBER		DEFAULT 0,
	in_apply_deleg_plans	IN	NUMBER		DEFAULT 0,
	in_ignore_sids			IN	security.T_SID_TABLE DEFAULT NULL
)
AS
	v_blob					BLOB;
	v_ignore_sids			secondary_region_tree_ctrl.ignore_sids%TYPE;
	v_log_dtm				DATE := SYSDATE;
BEGIN
	v_ignore_sids := StringifyIgnoreSids(in_ignore_sids => in_ignore_sids);

	CreateCtrlEntry(
		in_region_sid			=> in_region_sid,
		in_sp_name				=> in_sp_name,
		in_user_sid				=> in_user_sid,
		in_region_root_sid		=> in_region_root_sid,
		in_tag_id				=> in_tag_id,
		in_tag_group_ids		=> in_tag_group_ids,
		in_active_only			=> in_active_only,
		in_reduce_contention	=> in_reduce_contention,
		in_apply_deleg_plans	=> in_apply_deleg_plans,
		in_ignore_sids			=> v_ignore_sids,
		in_log_dtm				=> v_log_dtm
	);

	-- Create new tree as report and store in blob.
	CreateTreeReport(in_region_sid, v_blob);

	BEGIN
		UPDATE secondary_region_tree_log
		   SET postsync_tree = v_blob
		 WHERE app_sid = security.security_pkg.GetApp
		   AND log_id = in_log_id
		   AND region_sid = in_region_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			INSERT INTO secondary_region_tree_log (log_id, region_sid, user_sid, log_dtm, postsync_tree)
			VALUES (scndry_region_tree_log_id_seq.nextval, in_region_sid, in_user_sid, v_log_dtm, v_blob);
	END;
END;

-- For clients doing custom sync's, we can add some logging.
PROCEDURE Custom_SyncTree(
	in_secondary_root_sid			IN	security_pkg.T_SID_ID,
	in_tbl_primary					IN	OUT NOCOPY T_SID_AND_PATH_AND_DESC_TABLE,
	in_reduce_contention			IN	NUMBER DEFAULT 0,
	in_apply_deleg_plans			IN	NUMBER DEFAULT 1,
	in_ignore_sids					IN	security.T_SID_TABLE DEFAULT NULL,
	in_no_log						IN	NUMBER DEFAULT 0
)
AS
	v_user_sid						security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'SID');
	v_log_id						NUMBER;
BEGIN
	IF in_no_log = 0 THEN
		PreLogSync(in_region_sid => in_secondary_root_sid,
			in_user_sid => v_user_sid,
			out_log_id => v_log_id
		);
	END IF;
	
	INTERNAL_SyncTree(in_secondary_root_sid, in_tbl_primary, in_reduce_contention, in_apply_deleg_plans, in_ignore_sids);
	
	IF in_no_log = 0 THEN
		LogSync(
			in_log_id => v_log_id,
			in_region_sid => in_secondary_root_sid,
			in_sp_name => 'Custom',
			in_user_sid => v_user_sid,
			in_reduce_contention => in_reduce_contention,
			in_apply_deleg_plans => in_apply_deleg_plans,
			in_ignore_sids => in_ignore_sids
		);
	END IF;
END;

PROCEDURE ValidateTagId(
	in_tag_id						IN	tag.tag_id%TYPE
)
AS
	v_tag_count				NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_tag_count
	  FROM tag
	 WHERE app_sid = security_pkg.getApp
	   AND tag_id = in_tag_id;
	
	IF v_tag_count = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Tag ' || in_tag_id || ' is not valid');
	END IF;
END;

PROCEDURE CreateSecondarySyncForTag(
	in_secondary_root_sid			IN	security_pkg.T_SID_ID,
	in_region_root_sid				IN	security_pkg.T_SID_ID DEFAULT NULL, -- Null means use primary. 
	in_tag_id						IN	tag.tag_id%TYPE,
	in_reduce_contention			IN	NUMBER DEFAULT 0,
	in_apply_deleg_plans			IN	NUMBER DEFAULT 1,
	in_ignore_sid_list				IN	security_pkg.T_SID_IDS,
	in_user_sid						IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'SID'),
	out_batch_job_id				OUT	batch_job.batch_job_id%TYPE
)
AS
	v_ignore_sids			security.T_SID_TABLE;
	v_ignore_sid_string		secondary_region_tree_ctrl.ignore_sids%TYPE;
BEGIN
	ValidateTagId(in_tag_id => in_tag_id);
	v_ignore_sids := security_pkg.SidArrayToTable(in_ignore_sid_list);
	v_ignore_sid_string := StringifyIgnoreSids(in_ignore_sids => v_ignore_sids);
	CreateCtrlEntry(
		in_region_sid			=> in_secondary_root_sid,
		in_sp_name				=> 'SyncSecondaryForTag',
		in_user_sid				=> in_user_sid,
		in_region_root_sid		=> in_region_root_sid,
		in_tag_id				=> in_tag_id,
		in_reduce_contention	=> in_reduce_contention,
		in_apply_deleg_plans	=> in_apply_deleg_plans,
		in_ignore_sids			=> v_ignore_sid_string
	);
	
	CreateRefreshBatchJob(
		in_region_sid				=> in_secondary_root_sid,
		in_user_sid					=> in_user_sid,
		out_batch_job_id			=> out_batch_job_id
	);
	
END;

-- Synchronises a secondary tree to a primary, keeping the same hierarchy, 
-- but only including regions with a specific tag_id.
--
-- This could easily be repurposed to synch trees based around other attributes
-- such as opening date (i.e. all stores opened in 2010) etc.
PROCEDURE SyncSecondaryForTag(
	in_secondary_root_sid			IN	security_pkg.T_SID_ID,
	in_region_root_sid				IN	security_pkg.T_SID_ID DEFAULT NULL, -- Null means use primary. 
	in_tag_id						IN	tag.tag_id%TYPE,
	in_reduce_contention			IN	NUMBER DEFAULT 0,
	in_apply_deleg_plans			IN	NUMBER DEFAULT 1,
	in_ignore_sids					IN	security.T_SID_TABLE DEFAULT NULL,
	in_user_sid						IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'SID')
)
AS
	v_primary_root_sid		security_pkg.T_SID_ID;
	tbl_primary				T_SID_AND_PATH_AND_DESC_TABLE;
	v_log_id				NUMBER;
BEGIN
	v_primary_root_sid := GetPrimaryRegionTreeRootSid(in_region_root_sid);

	ValidateTagId(in_tag_id => in_tag_id);
	
	-- get a list of all the relevant nodes in the primary tree (including their paths)
	SELECT T_SID_AND_PATH_AND_DESC_ROW(rownum, region_sid,
		SUBSTR(x.sid_path, 0, LENGTH(x.sid_path) - LENGTH(x.region_sid) - 1),
		SUBSTR(x.desc_path, 0, LENGTH(x.desc_path) - LENGTH(x.description) - 1))
	  BULK COLLECT INTO tbl_primary
	  FROM (
			-- this is a CHR(1) _NOT_ a space character -- leave it!
			SELECT region_sid, description, level lvl, rownum rn,
				LTRIM(SYS_CONNECT_BY_PATH(replace(region_sid,chr(1),'_'),''),'') sid_path,
				LTRIM(SYS_CONNECT_BY_PATH(replace(description,chr(1),'_'),''),'') desc_path
			  FROM v$region
			  START WITH parent_sid = v_primary_root_sid -- primary
			CONNECT BY PRIOR region_sid = parent_sid
	) x
	 WHERE x.region_sid IN (
			-- every tagged region that's in our primary tree
			SELECT r.region_sid
			  FROM region_tag rt
			  JOIN region r ON rt.region_sid = r.region_sid
			 WHERE tag_id = in_tag_id
		INTERSECT
			SELECT region_sid
			  FROM region
			 START WITH parent_sid = v_primary_root_sid -- primary
			CONNECT BY PRIOR region_sid = parent_sid
		)
	  AND trash_pkg.IsInTrash(security_pkg.getACT, x.region_sid) = 0;

	PreLogSync(in_region_sid => in_secondary_root_sid,
		in_user_sid => in_user_sid,
		in_tag_id => in_tag_id,
		out_log_id => v_log_id
	);
	INTERNAL_SyncTree(in_secondary_root_sid, tbl_primary, in_reduce_contention, in_apply_deleg_plans, in_ignore_sids);
	LogSync(
		in_log_id => v_log_id,
		in_region_sid => in_secondary_root_sid,
		in_sp_name => 'SyncSecondaryForTag',
		in_user_sid => in_user_sid,
		in_tag_id => in_tag_id,
		in_reduce_contention => in_reduce_contention,
		in_apply_deleg_plans => in_apply_deleg_plans,
		in_ignore_sids => in_ignore_sids
	);
END;

PROCEDURE ValidateTagGroupId(
	in_tag_group_id					IN	tag_group.tag_group_id%TYPE
)
AS
	v_taggroup_count		NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_taggroup_count
	  FROM tag_group
	 WHERE app_sid = security_pkg.getApp
	   AND tag_group_id = in_tag_group_id;
	
	IF v_taggroup_count = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Tag group ' || in_tag_group_id || ' is not valid');
	END IF;
END;

PROCEDURE CreateSecondaryForTagGroup(
	in_secondary_root_sid			IN	security_pkg.T_SID_ID,
	in_region_root_sid				IN	security_pkg.T_SID_ID DEFAULT NULL, -- Null means use primary. 
	in_tag_group_id					IN	tag_group.tag_group_id%TYPE,
	in_reduce_contention			IN	NUMBER DEFAULT 0,
	in_apply_deleg_plans			IN	NUMBER DEFAULT 1,
	in_ignore_sid_list				IN	security_pkg.T_SID_IDS,
	in_user_sid						IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'SID'),
	out_batch_job_id				OUT	batch_job.batch_job_id%TYPE
)
AS
	v_ignore_sids			security.T_SID_TABLE;
	v_ignore_sid_string		secondary_region_tree_ctrl.ignore_sids%TYPE;
BEGIN
	ValidateTagGroupId(in_tag_group_id => in_tag_group_id);
	v_ignore_sids := security_pkg.SidArrayToTable(in_ignore_sid_list);
	v_ignore_sid_string := StringifyIgnoreSids(in_ignore_sids => v_ignore_sids);
	CreateCtrlEntry(
		in_region_sid			=> in_secondary_root_sid,
		in_sp_name				=> 'SyncSecondaryForTagGroup',
		in_user_sid				=> in_user_sid,
		in_region_root_sid		=> in_region_root_sid,
		in_tag_group_ids 		=> in_tag_group_id,
		in_reduce_contention	=> in_reduce_contention,
		in_apply_deleg_plans	=> in_apply_deleg_plans,
		in_ignore_sids			=> v_ignore_sid_string
	);
	
	CreateRefreshBatchJob(
		in_region_sid				=> in_secondary_root_sid,
		in_user_sid					=> in_user_sid,
		out_batch_job_id			=> out_batch_job_id
	);
END;

PROCEDURE SyncSecondaryForTagGroup(
	in_secondary_root_sid			IN	security_pkg.T_SID_ID,
	in_region_root_sid				IN	security_pkg.T_SID_ID DEFAULT NULL, -- Null means use primary. 
	in_tag_group_id					IN	tag_group.tag_group_id%TYPE,
	in_reduce_contention			IN	NUMBER DEFAULT 0,
	in_apply_deleg_plans			IN	NUMBER DEFAULT 1,
	in_ignore_sids					IN	security.T_SID_TABLE DEFAULT NULL,
	in_user_sid						IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'SID')
)
AS
	v_primary_root_sid		security_pkg.T_SID_ID;
	tbl_primary				T_SID_AND_PATH_AND_DESC_TABLE;
	v_log_id				NUMBER;
BEGIN
	v_primary_root_sid := GetPrimaryRegionTreeRootSid(in_region_root_sid);

	ValidateTagGroupId(in_tag_group_id => in_tag_group_id);
	
	-- get a list of all the relevant nodes in the primary tree (including their paths)
	WITH tags AS (
		SELECT t.tag, t.tag_id, rt.region_sid, tgm.pos
		  FROM region_tag rt
		  JOIN v$tag t ON rt.tag_id = t.tag_id
		  JOIN tag_group_member tgm ON t.tag_id = tgm.tag_id
		 WHERE tag_group_id = in_tag_group_id
	)
	SELECT T_SID_AND_PATH_AND_DESC_ROW(rownum, region_sid, sid_path, desc_path)
	  BULK COLLECT INTO tbl_primary
	  FROM (
		-- this is a CHR(1) _NOT_ a space character -- leave it!
		SELECT r.region_sid,
			t.tag||''||SUBSTR(r.sid_path, 0, LENGTH(r.sid_path) - LENGTH(r.region_sid) - 1) sid_path,
			t.tag||''||SUBSTR(r.desc_path, 0, LENGTH(r.desc_path) - LENGTH(r.description) - 1) desc_path
		  FROM tags t 
		  JOIN (
			SELECT region_sid, description, level lvl, rownum rn,
				-- this is a CHR(1) _NOT_ a space character -- leave it!
				LTRIM(SYS_CONNECT_BY_PATH(replace(region_sid,chr(1),'_'),''),'') sid_path,
				LTRIM(SYS_CONNECT_BY_PATH(replace(description,chr(1),'_'),''),'') desc_path
			  FROM v$region
			 START WITH parent_sid = v_primary_root_sid 
			CONNECT BY PRIOR region_sid = parent_sid 
			) r ON t.region_sid = r.region_sid
	 	 WHERE trash_pkg.IsInTrash(security_pkg.getACT, r.region_sid) = 0
		 ORDER BY t.pos, r.rn
	 );

	PreLogSync(in_region_sid => in_secondary_root_sid,
		in_user_sid => in_user_sid,
		in_region_root_sid => in_region_root_sid,
		in_tag_group_ids => in_tag_group_id,
		out_log_id => v_log_id
	);
	INTERNAL_SyncTree(in_secondary_root_sid, tbl_primary, in_reduce_contention, in_apply_deleg_plans, in_ignore_sids);
	LogSync(
		in_log_id => v_log_id,
		in_region_sid => in_secondary_root_sid,
		in_sp_name => 'SyncSecondaryForTagGroup',
		in_user_sid => in_user_sid,
		in_region_root_sid => in_region_root_sid,
		in_tag_group_ids => in_tag_group_id,
		in_reduce_contention => in_reduce_contention,
		in_apply_deleg_plans => in_apply_deleg_plans,
		in_ignore_sids => in_ignore_sids
	);
END;

PROCEDURE CreateSecondaryActivePropOnly(
	in_secondary_root_sid			IN	security_pkg.T_SID_ID,
	in_region_root_sid				IN	security_pkg.T_SID_ID DEFAULT NULL, -- Null means use primary. 
	in_reduce_contention			IN	NUMBER DEFAULT 0,
	in_apply_deleg_plans			IN	NUMBER DEFAULT 1,
	in_ignore_sid_list				IN	security_pkg.T_SID_IDS,
	in_user_sid						IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'SID'),
	out_batch_job_id				OUT	batch_job.batch_job_id%TYPE
)
AS
	v_ignore_sids			security.T_SID_TABLE;
	v_ignore_sid_string		secondary_region_tree_ctrl.ignore_sids%TYPE;
BEGIN
	
	v_ignore_sids := security_pkg.SidArrayToTable(in_ignore_sid_list);
	v_ignore_sid_string := StringifyIgnoreSids(in_ignore_sids => v_ignore_sids);
	CreateCtrlEntry(
		in_region_sid			=> in_secondary_root_sid,
		in_sp_name				=> 'SyncSecondaryActivePropOnly',
		in_user_sid				=> in_user_sid,
		in_region_root_sid		=> in_region_root_sid,
		in_reduce_contention	=> in_reduce_contention,
		in_apply_deleg_plans	=> in_apply_deleg_plans,
		in_ignore_sids			=> v_ignore_sid_string
	);
	
	CreateRefreshBatchJob(
		in_region_sid				=> in_secondary_root_sid,
		in_user_sid					=> in_user_sid,
		out_batch_job_id			=> out_batch_job_id
	);
	
END;

PROCEDURE SyncSecondaryActivePropOnly(
	in_secondary_root_sid			IN	security_pkg.T_SID_ID,
	in_region_root_sid				IN	security_pkg.T_SID_ID DEFAULT NULL, -- Null means use primary. 
	in_reduce_contention			IN	NUMBER DEFAULT 0,
	in_apply_deleg_plans			IN	NUMBER DEFAULT 1,
	in_ignore_sids					IN	security.T_SID_TABLE DEFAULT NULL,
	in_user_sid						IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'SID')
)
AS
	v_primary_root_sid		security_pkg.T_SID_ID;
	tbl_primary				T_SID_AND_PATH_AND_DESC_TABLE;
	v_log_id				NUMBER;
BEGIN
	v_primary_root_sid := GetPrimaryRegionTreeRootSid(in_region_root_sid);
	
	SELECT T_SID_AND_PATH_AND_DESC_ROW(rownum, region_sid, 
		SUBSTR(sid_path, 0, LENGTH(sid_path) - LENGTH(region_sid) - 1),
		SUBSTR(desc_path, 0, LENGTH(desc_path) - LENGTH(description) - 1))
	BULK COLLECT INTO tbl_primary
	FROM (
	-- get a list of all the relevant nodes in the primary tree (including their paths)
		SELECT rownum, region_sid, description,
			-- this is a CHR(1) _NOT_ a space character -- leave it!
			LTRIM(SYS_CONNECT_BY_PATH(replace(region_sid,chr(1),'_'),''),'') sid_path,
			LTRIM(SYS_CONNECT_BY_PATH(replace(description,chr(1),'_'),''),'') desc_path
		  FROM v$region
		 WHERE active = 1
		   AND region_type = csr_data_pkg.REGION_TYPE_PROPERTY
		   AND trash_pkg.IsInTrash(security_pkg.getACT, region_sid) = 0
		 START WITH parent_sid = v_primary_root_sid
	   CONNECT BY PRIOR region_sid = parent_sid
		   AND PRIOR active = 1
		);
	
	PreLogSync(in_region_sid => in_secondary_root_sid,
		in_user_sid => in_user_sid,
		out_log_id => v_log_id
	);
	INTERNAL_SyncTree(in_secondary_root_sid, tbl_primary, in_reduce_contention, in_apply_deleg_plans, in_ignore_sids);
	LogSync(
		in_log_id => v_log_id,
		in_region_sid => in_secondary_root_sid,
		in_sp_name => 'SyncSecondaryActivePropOnly',
		in_user_sid => in_user_sid,
		in_reduce_contention => in_reduce_contention,
		in_apply_deleg_plans => in_apply_deleg_plans,
		in_ignore_sids => in_ignore_sids
	);
END;

PROCEDURE CreateSecondaryForTagGroupList(
	in_secondary_root_sid			IN	security_pkg.T_SID_ID,
	in_region_root_sid				IN	security_pkg.T_SID_ID DEFAULT NULL, -- Null means use primary. 
	in_tag_group_id_list			IN	VARCHAR2,
	in_active_only					IN	NUMBER DEFAULT NULL,
	in_reduce_contention			IN	NUMBER DEFAULT 0,
	in_apply_deleg_plans			IN	NUMBER DEFAULT 1,
	in_ignore_sid_list				IN	security_pkg.T_SID_IDS,
	in_user_sid						IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'SID'),
	out_batch_job_id				OUT	batch_job.batch_job_id%TYPE
)
AS
	v_ignore_sids			security.T_SID_TABLE;
	v_ignore_sid_string		secondary_region_tree_ctrl.ignore_sids%TYPE;
BEGIN
	IF AreTagGroupsValid(in_tag_group_id_list) = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'One or more tag groups ' || in_tag_group_id_list || ' are not valid');
	END IF;

	v_ignore_sids := security_pkg.SidArrayToTable(in_ignore_sid_list);
	v_ignore_sid_string := StringifyIgnoreSids(in_ignore_sids => v_ignore_sids);
	CreateCtrlEntry(
		in_region_sid			=> in_secondary_root_sid,
		in_sp_name				=> 'SyncSecondaryForTagGroupList',
		in_user_sid				=> in_user_sid,
		in_region_root_sid		=> in_region_root_sid,
		in_tag_group_ids 		=> in_tag_group_id_list,
		in_active_only 			=> in_active_only,
		in_reduce_contention	=> in_reduce_contention,
		in_apply_deleg_plans	=> in_apply_deleg_plans,
		in_ignore_sids			=> v_ignore_sid_string
	);
	
	CreateRefreshBatchJob(
		in_region_sid				=> in_secondary_root_sid,
		in_user_sid					=> in_user_sid,
		out_batch_job_id			=> out_batch_job_id
	);
END;

PROCEDURE SyncSecondaryForTagGroupList(
	in_secondary_root_sid			IN	security_pkg.T_SID_ID,
	in_region_root_sid				IN	security_pkg.T_SID_ID DEFAULT NULL, -- Null means use primary. 
	in_tag_group_id_list			IN	VARCHAR2,
	in_active_only					IN	NUMBER DEFAULT NULL,
	in_reduce_contention			IN	NUMBER DEFAULT 0,
	in_apply_deleg_plans			IN	NUMBER DEFAULT 1,
	in_ignore_sids					IN	security.T_SID_TABLE DEFAULT NULL,
	in_user_sid						IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'SID')
)
AS
	v_primary_root_sid		security_pkg.T_SID_ID;
	tbl_primary				T_SID_AND_PATH_AND_DESC_TABLE;
	v_log_id				NUMBER;
BEGIN
	v_primary_root_sid := GetPrimaryRegionTreeRootSid(in_region_root_sid);

	IF AreTagGroupsValid(in_tag_group_id_list) = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'One or more tag groups ' || in_tag_group_id_list || ' are not valid');
	END IF;
	
	-- The intention of this code is to build a tree based on tags applied to regions
	-- The input consists of a list of tag groups -- tags from the group that apply to regions are 
	-- used to form the region hierarchy levels (with the tag name being the name of the region).
	--
	-- e.g. if we are given regions with tag groups
	-- sector: manufacturing, retail
	-- property ownership: rented, owned
	-- and we form a tag tree of sector/property, then the tree might look like:
	-- manufacturing 
	--               rented
	--                      property 1
	--               owned
	--                      property 2
	-- retail
	--               rented
	--                      property 3
	--               property 4
	--
	-- The constraints on the tag groups, which ARE NOT CHECKED are that only one tag from
	-- each group may be applied to a region, and that tags are not shared between tag groups.
	-- This may well explode if the rules are violated.
	-- 
	-- Also note that the match may be partial, e.g. in the above example property 4 has the
	-- retail tag set, but has no property ownership tag set.  In this case it is parented
	-- from the last set tag in the hierarchy.
	--
	-- Any tags that are not consecutive within the hierarchy starting with the first tag
	-- group are discarded, so if tag groups A, B, C are provided and a region has a tag
	-- from group A and group C, only the tag from group A will be used (and the region
	-- will be parented by the group A tag).  If no tags from the first group are applied
	-- then the region will not be present in the generated tree.
	
	-- This subquery forms the tag hierarchy from the given tag groups and tags that have
	-- been applied to regions.  It then collapses common paths in the hierarchy to give
	-- a single tree.
	
	-- Note that the sid_path points to tag_id's (not region_sids as in the other sync types)
	WITH tt AS (
		SELECT tag_desc_path, tag_sid_path, rownum rn
		  FROM (SELECT sid_path tag_sid_path, min(tag_path) tag_desc_path
				  FROM (SELECT
							   -- this is a CHR(1) _NOT_ a space character -- leave it!
							   LTRIM(SYS_CONNECT_BY_PATH(REPLACE(tag,chr(1),'_'),''),'') tag_path,
							   LTRIM(SYS_CONNECT_BY_PATH(REPLACE(tag_id,chr(1),'_'),''),'') sid_path
						  FROM (
								-- Here we get a table of region tags and the level in the hierarchy
								-- that the tag should appear at as specified by the order of the tag group id list
								SELECT rt.region_sid, tgo.pos, min(rt.tag_id) tag_id, min(t.tag) tag
								  FROM (SELECT region_sid
										  FROM region
										 WHERE in_active_only = 0 OR active = 1
											   START WITH region_sid = v_primary_root_sid
											   CONNECT BY PRIOR region_sid = parent_sid) r,
									   region_tag rt, tag_group_member tgm, v$tag t,
									   TABLE(utils_pkg.splitstring(in_tag_group_id_list)) tgo
								 WHERE t.tag_id = tgm.tag_id
								   AND tgm.tag_id = rt.tag_id
								   AND tgo.item = tgm.tag_group_id
								   AND r.region_sid = rt.region_sid
								 GROUP BY rt.region_sid, tgo.pos)
							   
							   -- Now we build the tag tree starting with tags in the first group
							   -- and proceeding level by level.  This ensures tags are discarded
							   -- if they don't apply from the first tag group down.
							   -- We build a path per region in this tree
							   START WITH pos = 1 
							   CONNECT BY PRIOR region_sid = region_sid AND PRIOR pos + 1 = pos)
						
						 -- Now we eliminate duplicate parts of the tree
						 GROUP BY sid_path)
		-- And to keep the tree a tree, we need to order by the path -- only the path
		-- to the tag is unique, the tags are no longer unique
		ORDER BY tag_sid_path
	),
	-- This subquery finds the deepest tag associated with a region -- i.e. the tag
	-- that will become the region's parent
	r AS (
		SELECT region_sid, 
			   MIN(id_path) KEEP (DENSE_RANK LAST ORDER BY lvl) id_path
		  FROM (SELECT region_sid, level lvl,
					   LTRIM(SYS_CONNECT_BY_PATH(REPLACE(tag_id,chr(1),'_'),''),'') id_path
				  FROM (SELECT rt.region_sid, tgo.pos, MIN(rt.tag_id) tag_id, MIN(t.tag) tag
						  FROM (SELECT region_sid
								  FROM region
								 WHERE in_active_only = 0 OR active = 1
									   START WITH region_sid = v_primary_root_sid
									   CONNECT BY PRIOR region_sid = parent_sid) r,
							   region_tag rt, tag_group_member tgm, v$tag t,
							   TABLE(utils_pkg.splitstring(in_tag_group_id_list)) tgo
						 WHERE t.tag_id = tgm.tag_id
						   AND tgm.tag_id = rt.tag_id
						   AND tgo.item = tgm.tag_group_id
						   AND r.region_sid = rt.region_sid
						 GROUP BY rt.region_sid, tgo.pos)
					   START WITH pos = 1
					   CONNECT BY PRIOR region_sid = region_sid AND PRIOR pos + 1 = pos)
		 GROUP BY region_sid
	)
	SELECT T_SID_AND_PATH_AND_DESC_ROW(rownum, region_sid, sid_path, desc_path)
	  BULK COLLECT INTO tbl_primary
	  FROM (SELECT null region_sid, tt.rn, tt.tag_desc_path desc_path, tt.tag_sid_path sid_path
			  FROM tt
			UNION ALL
			SELECT r.region_sid, tt.rn, tt.tag_desc_path desc_path, tt.tag_sid_path sid_path
			  FROM tt, r, region_description rd
			 WHERE tt.tag_sid_path = r.id_path
			   AND rd.region_sid = r.region_sid
			   AND rd.lang = 'en'
			 ORDER BY rn, region_sid NULLS FIRST);

	PreLogSync(in_region_sid => in_secondary_root_sid,
		in_user_sid => in_user_sid,
		in_tag_group_ids => in_tag_group_id_list,
		out_log_id => v_log_id
	);
	INTERNAL_SyncTree(in_secondary_root_sid, tbl_primary, in_reduce_contention, in_apply_deleg_plans, in_ignore_sids, 1);
	LogSync(
		in_log_id => v_log_id,
		in_region_sid => in_secondary_root_sid,
		in_sp_name => 'SyncSecondaryForTagGroupList',
		in_user_sid => in_user_sid,
		in_tag_group_ids => in_tag_group_id_list,
		in_active_only => in_active_only,
		in_reduce_contention => in_reduce_contention,
		in_apply_deleg_plans => in_apply_deleg_plans,
		in_ignore_sids => in_ignore_sids
	);
END;

PROCEDURE CreateSecondaryPropByFunds(
	in_secondary_root_sid			IN	security_pkg.T_SID_ID,
	in_region_root_sid				IN	security_pkg.T_SID_ID DEFAULT NULL, -- Null means use primary.
	in_reduce_contention			IN	NUMBER DEFAULT 0,
	in_apply_deleg_plans			IN	NUMBER DEFAULT 1,
	in_ignore_sid_list				IN	security_pkg.T_SID_IDS,
	in_user_sid						IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'SID'),
	out_batch_job_id				OUT	batch_job.batch_job_id%TYPE
)
AS
	v_ignore_sids			security.T_SID_TABLE;
	v_ignore_sid_string		secondary_region_tree_ctrl.ignore_sids%TYPE;
BEGIN
	v_ignore_sids := security_pkg.SidArrayToTable(in_ignore_sid_list);
	v_ignore_sid_string := StringifyIgnoreSids(in_ignore_sids => v_ignore_sids);
	CreateCtrlEntry(
		in_region_sid			=> in_secondary_root_sid,
		in_sp_name				=> 'SyncSecondaryPropByFunds',
		in_user_sid				=> in_user_sid,
		in_region_root_sid		=> in_region_root_sid,
		in_reduce_contention	=> in_reduce_contention,
		in_apply_deleg_plans	=> in_apply_deleg_plans,
		in_ignore_sids			=> v_ignore_sid_string
	);
	
	CreateRefreshBatchJob(
		in_region_sid				=> in_secondary_root_sid,
		in_user_sid					=> in_user_sid,
		out_batch_job_id			=> out_batch_job_id
	);
END;

PROCEDURE SyncSecondaryPropByFunds(
	in_secondary_root_sid			IN	security_pkg.T_SID_ID,
	in_region_root_sid				IN	security_pkg.T_SID_ID DEFAULT NULL, -- Null means use primary.
	in_reduce_contention			IN	NUMBER DEFAULT 0,
	in_apply_deleg_plans			IN	NUMBER DEFAULT 1,
	in_ignore_sids					IN	security.T_SID_TABLE DEFAULT NULL,
	in_user_sid						IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'SID')
)
AS
	v_primary_root_sid		security_pkg.T_SID_ID;
	tbl_primary				T_SID_AND_PATH_AND_DESC_TABLE;
	v_log_id				NUMBER;
BEGIN
	v_primary_root_sid := GetPrimaryRegionTreeRootSid(in_region_root_sid);

	-- get a list of all the relevant nodes in the primary tree (including their paths)
	SELECT T_SID_AND_PATH_AND_DESC_ROW(rownum, region_sid, sid_path, desc_path)
	  BULK COLLECT INTO tbl_primary
	  FROM (
		-- this is a CHR(1) _NOT_ a space character -- leave it!
		SELECT p.region_sid,
			p.fund_id||'-'||f.name||''||SUBSTR(r.sid_path, 0, LENGTH(r.sid_path) - LENGTH(r.region_sid) - 1) sid_path,
			p.fund_id||'-'||f.name||''||SUBSTR(r.desc_path, 0, LENGTH(r.desc_path) - LENGTH(r.description) - 1) desc_path
		  FROM
		  v$property p
		  JOIN fund f ON p.fund_id=f.fund_id
		  JOIN (
			SELECT region_sid, description, level lvl, rownum rn,
				   -- this is a CHR(1) _NOT_ a space character -- leave it!
				   LTRIM(SYS_CONNECT_BY_PATH(replace(region_sid,chr(1),'_'),''),'') sid_path,
				   LTRIM(SYS_CONNECT_BY_PATH(replace(description,chr(1),'_'),''),'') desc_path
			  FROM v$region
			 WHERE trash_pkg.IsInTrash(security_pkg.getACT, region_sid) = 0
			 START WITH parent_sid = v_primary_root_sid
			CONNECT BY PRIOR region_sid = parent_sid
		 )r ON p.region_sid = r.region_sid
		ORDER BY r.rn
	);

	PreLogSync(in_region_sid => in_secondary_root_sid,
		in_user_sid => in_user_sid,
		in_region_root_sid => in_region_root_sid,
		out_log_id => v_log_id
	);
	INTERNAL_SyncTree(in_secondary_root_sid, tbl_primary, in_reduce_contention, in_apply_deleg_plans, in_ignore_sids);
	LogSync(
		in_log_id => v_log_id,
		in_region_sid => in_secondary_root_sid,
		in_sp_name => 'SyncSecondaryPropByFunds',
		in_user_sid => in_user_sid,
		in_region_root_sid => in_region_root_sid,
		in_reduce_contention => in_reduce_contention,
		in_apply_deleg_plans => in_apply_deleg_plans,
		in_ignore_sids => in_ignore_sids
	);
END;

PROCEDURE CreatePropTreeByMgtCompany(
	in_secondary_root_sid			IN	security_pkg.T_SID_ID,
	in_region_root_sid				IN	security_pkg.T_SID_ID DEFAULT NULL, -- Null means use primary. 
	in_reduce_contention			IN	NUMBER DEFAULT 0,
	in_apply_deleg_plans			IN	NUMBER DEFAULT 1,
	in_ignore_sid_list				IN	security_pkg.T_SID_IDS,
	in_user_sid						IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'SID'),
	out_batch_job_id				OUT	batch_job.batch_job_id%TYPE
)
AS
	v_ignore_sids			security.T_SID_TABLE;
	v_ignore_sid_string		secondary_region_tree_ctrl.ignore_sids%TYPE;
BEGIN
	v_ignore_sids := security_pkg.SidArrayToTable(in_ignore_sid_list);
	v_ignore_sid_string := StringifyIgnoreSids(in_ignore_sids => v_ignore_sids);
	CreateCtrlEntry(
		in_region_sid			=> in_secondary_root_sid,
		in_sp_name				=> 'SyncPropTreeByMgtCompany',
		in_user_sid				=> in_user_sid,
		in_region_root_sid		=> in_region_root_sid,
		in_reduce_contention	=> in_reduce_contention,
		in_apply_deleg_plans	=> in_apply_deleg_plans,
		in_ignore_sids			=> v_ignore_sid_string
	);
	
	CreateRefreshBatchJob(
		in_region_sid				=> in_secondary_root_sid,
		in_user_sid					=> in_user_sid,
		out_batch_job_id			=> out_batch_job_id
	);
END;

PROCEDURE SyncPropTreeByMgtCompany(
	in_secondary_root_sid			IN	security_pkg.T_SID_ID,
	in_region_root_sid				IN	security_pkg.T_SID_ID DEFAULT NULL, -- Null means use primary. 
	in_reduce_contention			IN	NUMBER DEFAULT 0,
	in_apply_deleg_plans			IN	NUMBER DEFAULT 1,
	in_ignore_sids					IN	security.T_SID_TABLE DEFAULT NULL,
	in_user_sid						IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'SID')
)
AS
	v_primary_root_sid		security_pkg.T_SID_ID;
	tbl_primary				T_SID_AND_PATH_AND_DESC_TABLE;
	v_log_id				NUMBER;
BEGIN
	v_primary_root_sid := GetPrimaryRegionTreeRootSid(in_region_root_sid);

	-- get a list of all the relevant nodes in the primary tree (including their paths)
	SELECT T_SID_AND_PATH_AND_DESC_ROW(rownum, region_sid, sid_path, desc_path)
	  BULK COLLECT INTO tbl_primary
	  FROM (
		-- this is a CHR(1) _NOT_ a space character -- leave it!
		SELECT p.region_sid,
			NVL(m.name,'Other')||''||SUBSTR(r.sid_path, 0, LENGTH(r.sid_path) - LENGTH(r.region_sid) - 1) sid_path,
			NVL(m.name,'Other')||''||SUBSTR(r.desc_path, 0, LENGTH(r.desc_path) - LENGTH(r.description) - 1) desc_path
		  FROM 
		  property p
		  JOIN (
			SELECT region_sid, description, level lvl, rownum rn,
				   -- this is a CHR(1) _NOT_ a space character -- leave it!
				   LTRIM(SYS_CONNECT_BY_PATH(replace(region_sid,chr(1),'_'),''),'') sid_path,
				   LTRIM(SYS_CONNECT_BY_PATH(replace(description,chr(1),'_'),''),'') desc_path
			  FROM v$region
			 WHERE trash_pkg.IsInTrash(security_pkg.getACT, region_sid) = 0
			 START WITH parent_sid = v_primary_root_sid
			CONNECT BY PRIOR region_sid = parent_sid
		)r ON p.region_sid = r.region_sid
		LEFT JOIN mgmt_company m ON p.mgmt_company_id=m.mgmt_company_id
		ORDER BY  r.rn
	);

	PreLogSync(in_region_sid => in_secondary_root_sid,
		in_user_sid => in_user_sid,
		in_region_root_sid => in_region_root_sid,
		out_log_id => v_log_id
	);
	INTERNAL_SyncTree(in_secondary_root_sid, tbl_primary, in_reduce_contention, in_apply_deleg_plans, in_ignore_sids);
	LogSync(
		in_log_id => v_log_id,
		in_region_sid => in_secondary_root_sid,
		in_sp_name => 'SyncPropTreeByMgtCompany',
		in_user_sid => in_user_sid,
		in_region_root_sid => in_region_root_sid,
		in_reduce_contention => in_reduce_contention,
		in_apply_deleg_plans => in_apply_deleg_plans,
		in_ignore_sids => in_ignore_sids
	);
END;

PROCEDURE TriggerRegionTreeSyncJobs
AS
BEGIN
	user_pkg.LogonAdmin(timeout => 86400);

	FOR r IN (SELECT app_sid, tree_root_sid FROM mgt_company_tree_sync_job)
	LOOP
		security_pkg.SetApp(r.app_sid);
		SyncPropTreeByMgtCompany(in_secondary_root_sid => r.tree_root_sid);
		security_pkg.SetApp(null);
		COMMIT;
	END LOOP;
	
	user_pkg.LogOff(security_pkg.GetAct);
END;

FUNCTION GetTagGroupNames(in_tag_group_ids	IN	VARCHAR2)
RETURN VARCHAR2
AS
	v_names VARCHAR2(1024);
	v_separator VARCHAR2(1) := '';
BEGIN
	FOR r IN (
		SELECT tgid, NVL(tg.name,'Unknown Tag Group') name FROM
			(SELECT item tgid
			  FROM TABLE(csr.utils_pkg.splitstring(in_tag_group_ids)))
		LEFT JOIN csr.v$tag_group tg ON tg.tag_group_id = tgid
	) LOOP
		IF LENGTH(v_names) > 0 THEN 
			v_separator := ',';
		END IF;
		IF (LENGTH(v_names) + LENGTH(v_separator) + LENGTH(r.name)) > 1024 THEN
			RETURN v_names || '...';
		END IF;
		v_names := v_names || v_separator || r.name;
	END LOOP;
	RETURN v_names;
END;

FUNCTION AreTagGroupsValid(in_tag_group_ids	IN	VARCHAR2)
RETURN NUMBER
AS
	v_valid		NUMBER := 1;
	v_separator	VARCHAR2(1) := '';
BEGIN
	FOR r IN (
		SELECT tgid, tg.name name FROM
			(SELECT item tgid
			  FROM TABLE(csr.utils_pkg.splitstring(in_tag_group_ids)))
		LEFT JOIN csr.v$tag_group tg ON tg.tag_group_id = tgid
	) LOOP
		IF r.name IS NULL THEN 
			v_valid := 0;
		END IF;
	END LOOP;
	RETURN v_valid;
END;

PROCEDURE GetSecondaryRegionTrees(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR 
		SELECT r.region_sid, r.description, srtc.sp_name, 
			srtc.region_root_sid, rr.description root_description, 
			srtc.tag_id, CASE WHEN srtc.tag_id IS NOT NULL AND t.tag IS NULL THEN 'Unknown Tag' ELSE t.tag END tag,
			CASE WHEN srtc.tag_id IS NOT NULL AND t.tag IS NULL THEN 0 ELSE 1 END tag_valid,
			srtc.tag_group_ids, GetTagGroupNames(srtc.tag_group_ids) tag_group_names,
			AreTagGroupsValid(srtc.tag_group_ids) tag_groups_valid,
			srtc.active_only, srtc.reduce_contention, srtc.apply_deleg_plans,
			srtc.ignore_sids,
			cu.full_name last_run_user, srtc.last_run_dtm
		  FROM secondary_region_tree_ctrl srtc
		  LEFT JOIN v$region r ON r.region_sid = srtc.region_sid
		  LEFT JOIN v$region rr ON rr.region_sid = srtc.region_root_sid
		  LEFT JOIN v$tag t ON t.tag_id = srtc.tag_id
		  LEFT JOIN csr_user cu ON cu.csr_user_sid = srtc.user_sid
		 WHERE srtc.app_sid = security_pkg.GetApp
		 ORDER BY description;
END;

PROCEDURE GetSecondaryRegionTreeLogs(
	in_region_sid					IN  security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT srtl.log_id, srtl.region_sid,
			cu.full_name "user", srtl.log_dtm
		  FROM secondary_region_tree_log srtl
		  LEFT JOIN csr_user cu ON cu.csr_user_sid = srtl.user_sid
		 WHERE srtl.app_sid = security_pkg.GetApp
		   AND srtl.region_sid = in_region_sid
		 ORDER BY srtl.log_id desc;
END;

PROCEDURE GetSecondaryRegionTreeLog(
	in_log_id						IN  NUMBER,
	in_region_sid					IN  security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT srtl.presync_tree, srtl.postsync_tree
		  FROM secondary_region_tree_log srtl
		 WHERE srtl.app_sid = security_pkg.GetApp
		   AND srtl.log_id = in_log_id
		   AND srtl.region_sid = in_region_sid;
END;

PROCEDURE DeleteSecondaryTree(
	in_secondary_root_sid			IN	security_pkg.T_SID_ID
)
AS
BEGIN
	FOR r IN (
		SELECT region_sid
		  FROM region
		 START WITH parent_sid = in_secondary_root_sid -- secondary
		CONNECT BY PRIOR region_sid = parent_sid
	)
	LOOP
		--dbms_output.put_line('Deleting '||r.region_sid||' from secondary tree '|| in_secondary_root_sid);
		securableobject_pkg.DeleteSO(security_pkg.getACT, r.region_sid);
	END LOOP;
END;

PROCEDURE GetAllSecondaryTreeRoots(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT r.region_sid, r.description, CASE (SELECT COUNT(*) FROM region WHERE parent_sid = rt.region_tree_root_sid) WHEN 0 THEN 1 ELSE 0 END is_empty, is_system_managed
		  FROM csr.region_tree rt
		  JOIN v$region r ON rt.region_tree_root_sid = r.region_sid
		 WHERE rt.is_primary = 0
		   AND rt.app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

PROCEDURE DeleteEmptySecondaryTree(
	in_region_sid		IN	security_pkg.T_SID_ID
)
AS
	v_is_primary	NUMBER;
	v_is_empty		NUMBER;
	v_so_exists		NUMBER;
BEGIN
	
	BEGIN
		SELECT is_primary, CASE (SELECT COUNT(*) FROM region WHERE parent_sid = region_tree_root_sid) WHEN 0 THEN 1 ELSE 0 END is_empty
		  INTO v_is_primary, v_is_empty
		  FROM region_tree
		 WHERE region_tree_root_sid = in_region_sid
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'Could not find region tree with sid '||in_region_sid);
	END;
	IF v_is_primary = 1 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Unable to delete tree with sid '||in_region_sid||' because it is a primary tree');
	END IF;
	IF v_is_empty = 0 THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_OBJECT_IN_USE, 'Unable to delete tree with sid '||in_region_sid||' because it is not empty');
	END IF;
	
	csr.region_pkg.DeleteObject(
		in_act_id => security.security_pkg.GetAct,
		in_sid_id => in_region_sid);

	DELETE FROM csr.region_tree
	 WHERE region_tree_root_sid = in_region_sid;

	-- DeleteSO will throw an access denied if the SO doesn't exist
	SELECT CASE (SELECT COUNT(*) 
				   FROM security.securable_object 
				  WHERE sid_id = in_region_sid
				    AND application_sid_id = SYS_CONTEXT('SECURITY', 'APP')
			) WHEN 0 THEN 0 ELSE 1 END is_present
	  INTO v_so_exists
	  FROM DUAL;
	IF v_so_exists = 1 THEN
		security.securableObject_pkg.DeleteSO(
			in_act_id => security.security_pkg.GetAct,
			in_sid_id => in_region_sid);
	END IF;
END;


PROCEDURE SaveSecondaryTree(
	in_region_sid					IN  security_pkg.T_SID_ID,
	in_description					IN  region_description.description%TYPE,
	in_is_system_managed			IN  region_tree.is_system_managed%TYPE
)
AS
BEGIN
	UPDATE csr.region_description
		SET description = in_description
	WHERE region_sid = in_region_sid;

	UPDATE csr.region_tree
		SET is_system_managed = in_is_system_managed
	WHERE region_tree_root_sid = in_region_sid;
END;

END;
/
