	CREATE OR REPLACE PACKAGE BODY CSR.Form_Pkg AS

PROCEDURE CreateObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sid_id						IN	security_pkg.T_SID_ID,
	in_class_id						IN	security_pkg.T_CLASS_ID,
	in_name							IN	security_pkg.T_SO_NAME,
	in_parent_sid_id				IN	security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE RenameObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sid_id						IN	security_pkg.T_SID_ID,
	in_new_name						IN	security_pkg.T_SO_NAME
)
AS
BEGIN
	-- when we trash stuff the SO gets renamed to NULL (to avoid dupe obj names when we
	-- move the securable object). We don't really want to rename our objects tho.
	IF in_new_name IS NOT NULL THEN
		UPDATE form
		   SET name = in_new_name
		 WHERE form_sid = in_sid_id;
	END IF;
END;

PROCEDURE DeleteObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sid_id						IN	security_pkg.T_SID_ID
)
AS
	CURSOR c IS
		SELECT form_allocation_id 
	 	  FROM form_allocation
		 WHERE form_sid = in_sid_id;
BEGIN
	DeleteAllFormAllocations(in_act_id, in_sid_id);
	SetRegions(in_act_id, in_sid_id, '');
	SetIndicators(in_act_id, in_sid_id, '');

	DELETE FROM form_comment
	 WHERE form_sid = in_sid_id;

	DELETE FROM form
	 WHERE form_sid = in_sid_id;
END;

PROCEDURE MoveObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sid_id						IN	security_pkg.T_SID_ID,
	in_new_parent_sid_id			IN	security_pkg.T_SID_ID,
	in_old_parent_sid_id			IN security_pkg.T_SID_ID
)
AS
BEGIN
	UPDATE form
	   SET parent_sid = in_new_parent_sid_id
	 WHERE form_sid = in_sid_id;
END;

PROCEDURE TrashObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sid_id						IN  security_pkg.T_SID_ID
)
AS
	v_description		form.name%TYPE;
	v_app_sid			security_pkg.T_SID_ID;
BEGIN
	-- get name and sid
	SELECT name, app_sid
	  INTO v_description, v_app_sid
	  FROM form
	 WHERE form_sid = in_sid_id;

	trash_pkg.TrashObject(in_act_id, in_sid_id,
		securableobject_pkg.GetSIDFromPath(in_act_id, v_app_sid, 'Trash'),
		v_description);
END;

/**
 * Create a new form
 *
 * @param	in_act_id				Access token
 * @param	in_parent_sid_id		Parent object
 * @param	in_name					Name
 * @param	in_start_dtm			Start date
 * @param	in_end_dtm				End date
 * @param	in_period_set_id		The period set
 * @param	in_period_interval_id	The period interval (m|q|h|y)
 * @param	in_note					Note
 * @param	out_form_sid_id			The SID of the created object
 *
 */
PROCEDURE CreateForm(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_parent_sid					IN	security_pkg.T_SID_ID,
	in_app_sid 						IN	security_pkg.T_SID_ID,
	in_name							IN	form.name%TYPE,
	in_start_dtm					IN	form.start_dtm%TYPE,
	in_end_dtm						IN	form.end_dtm%TYPE,
	in_period_set_id				IN	form.period_set_id%TYPE,
	in_period_interval_id			IN	form.period_interval_id%TYPE,
	in_note							IN	form.note%TYPE,
	in_group_by						IN	form.group_by%TYPE,
	in_tab_direction				IN	form.tab_direction%TYPE,
	out_form_sid_id					OUT	security_pkg.T_SID_ID
)
AS
BEGIN
	SecurableObject_Pkg.CreateSO(in_act_id, in_parent_sid,
		class_pkg.getClassID('CSRForm'), REPLACE(in_name,'/','\'), out_form_sid_id);
	INSERT INTO form
		(form_sid, app_sid, parent_sid, name, start_dtm, end_dtm,
		 group_by, period_set_id, period_interval_id, note, allocate_users_to, tab_direction)
	VALUES
		(out_form_sid_id, in_app_sid, in_parent_sid, in_name, trunc(in_start_dtm), trunc(in_end_dtm),
		 in_group_by, in_period_set_id, in_period_interval_id, in_note, 'region', in_tab_direction);
END;

/**
 * Update a form
 *
 * @param	in_act_id				Access token
 * @param	in_form_sid				The form to update
 * @param	in_name					Name
 * @param	in_start_dtm			Start date
 * @param	in_end_dtm				End date
 * @param	in_group_by				Group by
 * @param 	in_period_set_id		The period set
 * @param 	in_period_interval_id	The period interval (m|q|h|y)
 * @param	in_note					Note
 */
PROCEDURE AmendForm(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_form_sid						IN	security_pkg.T_SID_ID,
	in_name							IN	form.name%TYPE,
	in_start_dtm					IN	form.start_dtm%TYPE,
	in_end_dtm						IN	form.end_dtm%TYPE,
	in_period_set_id				IN	form.period_set_id%TYPE,
	in_period_interval_id			IN	form.period_interval_id%TYPE,
	in_note							IN	form.note%TYPE,
	in_group_by						IN	form.group_by%TYPE,
	in_tab_direction				IN	form.tab_direction%TYPE
)
AS
BEGIN
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_form_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	-- rename first as this will update form.name anyway via SO callback to form_pkg.RenameObject
	securableobject_pkg.RenameSO(in_act_id, in_form_sid, REPLACE(in_name,'/','\'));

	UPDATE form
	   SET start_dtm = trunc(in_start_dtm),
	   	   end_dtm = trunc(in_end_dtm),
		   period_set_id = in_period_set_id,
		   period_interval_id = in_period_interval_id,
		   note = in_note,
		   name = in_name,
		   group_by = in_group_by,
		   tab_direction = in_tab_direction
	 WHERE form_sid = in_form_sid;

END;

PROCEDURE CopyForm(
	in_act_id 						IN	security_pkg.T_ACT_ID,
	in_form_sid						IN	security_pkg.T_SID_ID,
	out_new_form_sid				OUT	security_pkg.T_SID_ID
)
AS
	v_new_form_sid	security_pkg.T_SID_ID;
	v_new_fa_id		NUMBER(10);
	v_name_count	NUMBER(10);
	v_name			security_pkg.T_SO_NAME;
	v_try_again		BOOLEAN;
	CURSOR c IS
		SELECT parent_sid, app_sid, name, start_dtm, end_dtm, period_set_id, period_interval_id,
			   note, group_by, allocate_users_to, tab_direction
		  FROM form
		 WHERE form_sid = in_form_sid;
	r	c%ROWTYPE;
	CURSOR c_alloc IS
		SELECT form_allocation_id
		  FROM form_allocation
		 WHERE form_sid = in_form_sid;
BEGIN
	OPEN c;
	FETCH c INTO r;
	v_name := r.name;
	v_name_count := 0;
	v_try_again := TRUE;
	WHILE v_try_again LOOP
		BEGIN
			v_try_again := FALSE;
			Form_Pkg.CreateForm(in_act_id, r.parent_sid, r.app_sid, v_name, r.start_dtm, r.end_dtm,
				r.period_set_id, r.period_interval_id, r.note, r.group_by, r.tab_direction,
				v_new_form_sid);
		EXCEPTION
			WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
				v_name := r.name || ' (copy)';
				v_name_count := v_name_count + 1;
				IF v_name_count > 1 THEN
					v_name := r.name||' (copy '||v_name_count||')';
				END IF;
				v_try_again := TRUE;
		END;
	END LOOP;
	Form_Pkg.AmendForm(in_act_id, v_new_form_sid, v_name, r.start_dtm, r.end_dtm, r.period_set_id,
		r.period_interval_id, r.note, r.group_by, r.tab_direction);
	Form_Pkg.SetAllocateUsersTo(in_act_id, v_new_form_sid, r.allocate_users_to);

	-- insert indicators
	INSERT INTO form_ind_member (form_sid, ind_sid, description, pos, scale,
		format_mask, measure_description, show_total, multiplier_ind_sid, measure_conversion_id)
		SELECT v_new_form_sid, ind_sid, description, pos, scale, format_mask, measure_description,
			   show_total, multiplier_ind_sid, measure_conversion_id
		  FROM form_ind_member
		 WHERE form_sid = in_form_sid;

	-- insert regions
	INSERT INTO form_region_member (form_sid, region_sid, description, pos)
		SELECT v_new_form_sid, region_sid, description, pos
		  FROM form_region_member
		 WHERE form_sid = in_form_sid;

	-- copy allocation data
	FOR r_alloc IN c_alloc LOOP
		SELECT form_allocation_id_seq.NEXTVAL INTO v_new_fa_id FROM DUAL;
		INSERT INTO form_allocation	(form_allocation_id, form_sid)
		VALUES (v_new_fa_id, v_new_form_sid);
		INSERT INTO form_allocation_item (form_allocation_id, item_sid)
			SELECT v_new_fa_id, item_sid
			  FROM form_allocation_item
			 WHERE form_allocation_id = r_alloc.form_allocation_id;
		INSERT INTO form_allocation_user (form_allocation_id, user_sid)
			SELECT v_new_fa_id, user_sid
			  FROM form_allocation_user
			 WHERE form_allocation_id = r_alloc.form_allocation_id;
	END LOOP;
	out_new_form_sid := v_new_form_sid;
END;

-- NB relies on item_sid being sorted
PROCEDURE DeleteUsersFromSOACLs(
	in_act_id			security_pkg.T_ACT_ID,
	in_cursor			SYS_REFCURSOR
)
AS
    TYPE 				T_REMOVE_TABLE IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
	t 					T_REMOVE_TABLE;
	c_acl				SYS_REFCURSOR;
	v_dacl_id			security_pkg.T_ACL_ID;
	v_acl_id			security_pkg.T_ACL_ID;
	v_acl_index			security_pkg.T_ACL_INDEX;
	v_ace_type			security_pkg.T_ACE_TYPE;
	v_ace_flags			security_pkg.T_ACE_FLAGS;
	v_sid_id			security_pkg.T_SID_ID;
	v_permission_set	security_pkg.T_PERMISSION;
	v_last_item_sid		security_pkg.T_SID_ID;
	v_in_our_table		BOOLEAN;
	v_item_sid			security_pkg.T_SID_ID;
	v_user_sid			security_pkg.T_SID_ID;
BEGIN
	IF in_cursor%ROWCOUNT = 0 THEN
		RETURN;
	END IF;
	v_last_item_sid := -1;
	LOOP
		FETCH in_cursor INTO v_item_sid, v_user_sid;
		--DBMS_OUTPUT.PUT_LINE('Fetched '||v_item_sid);
		IF in_cursor%NOTFOUND OR v_last_item_sid != v_item_sid THEN
			IF v_last_item_sid != -1 THEN
				-- get the old access control list
				acl_pkg.GetDACL(in_act_id, v_last_item_sid, c_acl);
				-- delete old aces, reinserting but skipping users in the pl/sql table
				v_dacl_id := acl_pkg.GetDACLIDForSID(v_last_item_sid);
				acl_pkg.DeleteAllACES(in_act_id, v_dacl_id);
				LOOP
					FETCH c_acl INTO v_acl_id, v_acl_index, v_ace_type, v_ace_flags, v_sid_id, v_permission_set;
					EXIT WHEN c_acl%NOTFOUND;
					v_in_our_table := TRUE;
					BEGIN
						-- if this isn't in our table then we'll get an error
						t(v_sid_id) := t(v_sid_id);
					EXCEPTION
						WHEN NO_DATA_FOUND THEN
							v_in_our_table := FALSE;
					END;
					IF NOT v_in_our_table THEN
						--DBMS_OUTPUT.PUT_LINE('Adding ACE for '|| v_sid_id);
						acl_pkg.AddACE(in_act_id, v_acl_id, security_pkg.ACL_INDEX_LAST,
							v_ace_type, v_ace_flags, v_sid_id, v_permission_set);
					--ELSE
						--DBMS_OUTPUT.PUT_LINE('Not adding ACE for user '|| v_sid_id);
					END IF;
				END LOOP;
			END IF;
			-- get ready for more work (or quit)
			EXIT WHEN in_cursor%NOTFOUND;
			v_last_item_sid := v_item_sid;
			t.DELETE;
		END IF;
		t(v_user_sid) := 1;
		--DBMS_OUTPUT.PUT_LINE('Planning to exclude user '|| v_user_sid);
	END LOOP;
END;

-- NB relies on item_sid being sorted
PROCEDURE AddUsersToSOACLs(
	in_act_id			security_pkg.T_ACT_ID,
	in_cursor			SYS_REFCURSOR,
	in_permission_set	security_pkg.T_PERMISSION
)
AS
	v_dacl_id			security_pkg.T_ACL_ID;
	v_last_item_sid		security_pkg.T_SID_ID;
	v_item_sid			security_pkg.T_SID_ID;
	v_user_sid			security_pkg.T_SID_ID;
BEGIN
	IF in_cursor%ROWCOUNT = 0 THEN
		RETURN;
	END IF;
	v_last_item_sid := -1;
	LOOP
		FETCH in_cursor INTO v_item_sid, v_user_sid;
		EXIT WHEN in_cursor%NOTFOUND;
		IF v_last_item_sid != v_item_sid THEN
			v_dacl_id := acl_pkg.GetDACLIDForSID(v_item_sid);
		END IF;
		IF v_dacl_id IS NULL THEN
			-- object not found
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'Object '||v_item_sid||' not found');
		END IF;

		-- add permission
		-- NOTE THIS IS NOT INHERITABLE
		acl_pkg.AddACE(in_act_id, v_dacl_id,
			security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
			security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_user_sid,
			in_permission_set);

		v_last_item_sid := v_item_sid;
	END LOOP;
END;

PROCEDURE SetIndicators(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_form_sid						IN	security_pkg.T_SID_ID,
	in_indicator_list				IN	VARCHAR2
)
AS
	t_items				T_SPLIT_TABLE;
	v_allocate_users_to	form.allocate_users_to%TYPE;
	v_app_sid			security_pkg.T_SID_ID;
	c_remove			SYS_REFCURSOR;
BEGIN
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_form_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	-- ok, pull what we're setting stuff to out into a table
	t_items := Utils_Pkg.SplitString(in_indicator_list, ',');

	-- get some basic info about the form
	SELECT allocate_users_to, app_sid
	  INTO v_allocate_users_to, v_app_sid
	  FROM form
	 WHERE form_sid = in_form_sid;

	-- mess around with security
	IF v_allocate_users_to = 'indicator' THEN
		-- which users have been allocated to the removed indicators, but
		-- are not allocated against these indicators elsewhere on other forms?
		OPEN c_remove FOR
			-- users that have been allocated to the removed indicators
			SELECT fai.item_sid, fau.user_sid
			  FROM form_allocation_item fai, form_allocation_user fau,
			   (SELECT ind_sid item_sid
				  FROM form_ind_member
				 WHERE form_sid = in_form_sid
				MINUS
				SELECT CAST(item AS NUMBER) item_sid
				  FROM TABLE(CAST(t_items AS T_SPLIT_TABLE))) deleted_items
			 WHERE fai.item_sid = deleted_items.item_sid
			   AND fai.form_allocation_id = fau.form_allocation_id
			  MINUS
			-- minus, users and items allocated in other forms except this one


			-- We want to get indicator member data from forms that are allocating to regions (i.e. allocating to the opposite of us)
			-- or get region member data from forms that are allocating to indicators.
			-- The first two bits of the union are there because only one will ever get used, but the data we need
			-- is in two different tables depending on the value of v_allocate_users_to
		   (SELECT frm.region_sid item_sid, fau.user_sid
		      FROM form_region_member frm, form f, form_allocation fa, form_allocation_user fau
			 WHERE frm.form_sid = f.form_sid
			   AND f.app_sid = v_app_sid
			   AND f.form_sid != in_form_sid
			   AND f.allocate_users_to = 'indicator'
			   AND fa.form_sid = f.form_sid
			   AND fau.form_allocation_id = fa.form_allocation_id
			   AND 'region' = v_allocate_users_to
		 	UNION
		    SELECT fim.ind_sid item_sid, fau.user_sid
		      FROM form_ind_member fim, form f, form_allocation fa, form_allocation_user fau
			 WHERE fim.form_sid = f.form_sid
			   AND f.app_sid = v_app_sid
			   AND f.form_sid != in_form_sid
			   AND f.allocate_users_to = 'region'
			   AND fa.form_sid = f.form_sid
			   AND fau.form_allocation_id = fa.form_allocation_id
			   AND 'indicator' = v_allocate_users_to
		 	UNION
			SELECT fai.item_sid, fau.user_sid
			  FROM form_allocation_item fai, form_allocation_user fau, form_allocation fa, form f
			 WHERE fai.form_allocation_id = fa.form_allocation_id
			   AND fau.form_allocation_id = fa.form_allocation_id
			   AND fa.form_sid = f.form_sid
			   AND f.app_sid = v_app_sid
			   AND f.form_sid != in_form_sid
			 )
			 ORDER BY item_sid;

		 -- zap 'em...
		 DeleteUsersFromSOACLs(in_act_id, c_remove);

		 -- any new indicators we don't need to worry about until
		 -- the admin person assigns users to these indicators (in setFormAllocation)
	ELSE
		-- ok, for the axis that isn't being allocated we need to
		-- remove any ACLs on now unused items
		OPEN c_remove FOR
			SELECT deleted_items.item_sid, fau.user_sid
			  FROM form_allocation fa, form_allocation_user fau,
			   (SELECT ind_sid item_sid
				  FROM form_ind_member
				 WHERE form_sid = in_form_sid
				MINUS
				SELECT CAST(item AS NUMBER) item_sid
				  FROM TABLE(CAST(t_items AS T_SPLIT_TABLE))) deleted_items
			 WHERE fa.form_allocation_id = fau.form_allocation_id
			   AND fa.form_sid = in_form_sid
			-- minus, users and items allocated in other forms except this one
			MINUS

			-- We want to get indicator member data from forms that are allocating to regions (i.e. allocating to the opposite of us)
			-- or get region member data from forms that are allocating to indicators.
			-- The first two bits of the union are there because only one will ever get used, but the data we need
			-- is in two different tables depending on the value of v_allocate_users_to
		   (SELECT frm.region_sid item_sid, fau.user_sid
		      FROM form_region_member frm, form f, form_allocation fa, form_allocation_user fau
			 WHERE frm.form_sid = f.form_sid
			   AND f.app_sid = v_app_sid
			   AND f.form_sid != in_form_sid
			   AND f.allocate_users_to = 'indicator'
			   AND fa.form_sid = f.form_sid
			   AND fau.form_allocation_id = fa.form_allocation_id
			   AND 'region' = v_allocate_users_to
		 	UNION
		    SELECT fim.ind_sid item_sid, fau.user_sid
		      FROM form_ind_member fim, form f, form_allocation fa, form_allocation_user fau
			 WHERE fim.form_sid = f.form_sid
			   AND f.app_sid = v_app_sid
			   AND f.form_sid != in_form_sid
			   AND f.allocate_users_to = 'region'
			   AND fa.form_sid = f.form_sid
			   AND fau.form_allocation_id = fa.form_allocation_id
			   AND 'indicator' = v_allocate_users_to
		 	UNION
			SELECT fai.item_sid, fau.user_sid
			  FROM form_allocation_item fai, form_allocation_user fau, form_allocation fa, form f
			 WHERE fai.form_allocation_id = fa.form_allocation_id
			   AND fau.form_allocation_id = fa.form_allocation_id
			   AND fa.form_sid = f.form_sid
			   AND f.app_sid = v_app_sid
			   AND f.form_sid != in_form_sid
			 )
			 ORDER BY item_sid;
		 -- zap 'em...
		 DeleteUsersFromSOACLs(in_act_id, c_remove);
	END IF;

	-- actually delete stuff from the form
	DELETE FROM form_ind_member
	 WHERE form_sid = in_form_sid
	   AND ind_sid NOT IN
	    (SELECT CAST(item AS NUMBER) FROM TABLE(t_items));

	-- update the sort order (pos field) for existing rows
	UPDATE form_ind_member fim
	   SET pos = (SELECT pos
				    FROM TABLE(t_items)
				   WHERE fim.ind_sid = item)
	 WHERE fim.form_sid = in_form_sid;

	-- insert any new stuff (we'll update descriptions later)
	-- NB this has to come after we update the POS field for
	-- existing rows, since we include POS in the MINUS set operation
	-- and if this wasn't updated as above, then we'd get wrong
	-- results
	INSERT INTO form_ind_member
		(form_sid, ind_sid, description, pos)
	 	SELECT in_form_sid, i.ind_sid, i.description, new_items.pos
	 	  FROM v$ind i,
	 		(SELECT CAST(item AS NUMBER) ind_sid, pos
	 		  FROM TABLE(t_items)
	 		MINUS
	 		SELECT ind_sid, pos
	 		  FROM form_ind_member
	 		 WHERE form_sid = in_form_sid) new_items
	 	 WHERE i.ind_sid = new_items.ind_sid;
END;

PROCEDURE AmendIndicator(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_form_sid				IN security_pkg.T_SID_ID,
	in_ind_sid				IN security_pkg.T_SID_ID,
	in_description			IN VARCHAR2,
	in_format_mask			IN ind.format_mask%TYPE,
	in_scale				IN ind.scale%TYPE,
	in_measure_description	IN measure.description%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_form_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Write access denied on the form with sid '||in_form_sid);
	END IF;

	UPDATE form_ind_member
	   SET description = in_description,
	   	   format_mask = in_format_mask,
	   	   scale = in_scale,
	   	   measure_description = in_measure_description
	 WHERE form_sid = in_form_sid
	   AND ind_sid = in_ind_sid;
END;


PROCEDURE SetRegions(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_form_sid						IN	security_pkg.T_SID_ID,
	in_region_list					IN	VARCHAR2
)
AS
	t_items				T_SPLIT_TABLE;
	v_allocate_users_to	form.allocate_users_to%TYPE;
	v_app_sid			security_pkg.T_SID_ID;
	c_remove			SYS_REFCURSOR;
BEGIN
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_form_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	-- ok, pull what we're setting stuff to out into a table
	t_items := Utils_Pkg.SplitString(in_region_list, ',');

	-- get some basic info about the form
	SELECT allocate_users_to, app_sid
	  INTO v_allocate_users_to, v_app_sid
	  FROM form
	 WHERE form_sid = in_form_sid;

	-- mess around with security
	IF v_allocate_users_to = 'region' THEN
		-- which users have been allocated to the removed regions, but
		-- are not allocated against these regions elsewhere on other forms?
		OPEN c_remove FOR
			-- users that have been allocated to the removed regions
			SELECT fai.item_sid, fau.user_sid
			  FROM form_allocation_item fai, form_allocation_user fau,
			   (SELECT region_sid item_sid
				  FROM form_region_member
				 WHERE form_sid = in_form_sid
				MINUS
				SELECT CAST(item AS NUMBER) item_sid
				  FROM TABLE(CAST(t_items AS T_SPLIT_TABLE))) deleted_items
			 WHERE fai.item_sid = deleted_items.item_sid
			   AND fai.form_allocation_id = fau.form_allocation_id
			  MINUS
			-- minus, users and items allocated in other forms except this one


			-- We want to get region member data from forms that are allocating to indicators (i.e. allocating to the opposite of us)
			-- or get indicator member data from forms that are allocating to regions.
			-- The first two bits of the union are there because only one will ever get used, but the data we need
			-- is in two different tables depending on the value of v_allocate_users_to
		   (SELECT frm.region_sid item_sid, fau.user_sid
		      FROM form_region_member frm, form f, form_allocation fa, form_allocation_user fau
			 WHERE frm.form_sid = f.form_sid
			   AND f.app_sid = v_app_sid
			   AND f.form_sid != in_form_sid
			   AND f.allocate_users_to = 'region'
			   AND fa.form_sid = f.form_sid
			   AND fau.form_allocation_id = fa.form_allocation_id
			   AND 'indicator' = v_allocate_users_to
		 	UNION
		    SELECT frm.region_sid item_sid, fau.user_sid
		      FROM form_region_member frm, form f, form_allocation fa, form_allocation_user fau
			 WHERE frm.form_sid = f.form_sid
			   AND f.app_sid = v_app_sid
			   AND f.form_sid != in_form_sid
			   AND f.allocate_users_to = 'indicator'
			   AND fa.form_sid = f.form_sid
			   AND fau.form_allocation_id = fa.form_allocation_id
			   AND 'region' = v_allocate_users_to
		 	UNION
			SELECT fai.item_sid, fau.user_sid
			  FROM form_allocation_item fai, form_allocation_user fau, form_allocation fa, form f
			 WHERE fai.form_allocation_id = fa.form_allocation_id
			   AND fau.form_allocation_id = fa.form_allocation_id
			   AND fa.form_sid = f.form_sid
			   AND f.app_sid = v_app_sid
			   AND f.form_sid != in_form_sid
			 )
			 ORDER BY item_sid;
		 -- zap 'em...
		 DeleteUsersFromSOACLs(in_act_id, c_remove);

		 -- any new regions we don't need to worry about until
		 -- the admin person assigns users to these regions (in setFormAllocation)
	ELSE
		-- ok, for the axis that isn't being allocated we need to
		-- remove any ACLs on now unused items
		OPEN c_remove FOR
			SELECT deleted_items.item_sid, fau.user_sid
			  FROM form_allocation fa, form_allocation_user fau,
			   (SELECT region_sid item_sid
				  FROM form_region_member
				 WHERE form_sid = in_form_sid
				MINUS
				SELECT CAST(item AS NUMBER) item_sid
				  FROM TABLE(CAST(t_items AS T_SPLIT_TABLE))) deleted_items
			 WHERE fa.form_allocation_id = fau.form_allocation_id
			   AND fa.form_sid = in_form_sid
			-- minus, users and items allocated in other forms except this one
			MINUS

			-- We want to get region member data from forms that are allocating to indicators (i.e. allocating to the opposite of us)
			-- or get indicator member data from forms that are allocating to regions.
			-- The first two bits of the union are there because only one will ever get used, but the data we need
			-- is in two different tables depending on the value of v_allocate_users_to
		   (SELECT frm.region_sid item_sid, fau.user_sid
		      FROM form_region_member frm, form f, form_allocation fa, form_allocation_user fau
			 WHERE frm.form_sid = f.form_sid
			   AND f.app_sid = v_app_sid
			   AND f.form_sid != in_form_sid
			   AND f.allocate_users_to = 'region'
			   AND fa.form_sid = f.form_sid
			   AND fau.form_allocation_id = fa.form_allocation_id
			   AND 'indicator' = v_allocate_users_to
		 	UNION
		    SELECT frm.region_sid item_sid, fau.user_sid
		      FROM form_region_member frm, form f, form_allocation fa, form_allocation_user fau
			 WHERE frm.form_sid = f.form_sid
			   AND f.app_sid = v_app_sid
			   AND f.form_sid != in_form_sid
			   AND f.allocate_users_to = 'indicator'
			   AND fa.form_sid = f.form_sid
			   AND fau.form_allocation_id = fa.form_allocation_id
			   AND 'region' = v_allocate_users_to
		 	UNION
			SELECT fai.item_sid, fau.user_sid
			  FROM form_allocation_item fai, form_allocation_user fau, form_allocation fa, form f
			 WHERE fai.form_allocation_id = fa.form_allocation_id
			   AND fau.form_allocation_id = fa.form_allocation_id
			   AND fa.form_sid = f.form_sid
			   AND f.app_sid = v_app_sid
			   AND f.form_sid != in_form_sid
			 )
			 ORDER BY item_sid;
		 -- zap 'em...
		 DeleteUsersFromSOACLs(in_act_id, c_remove);
	END IF;

	-- actually delete stuff from the form
	DELETE FROM form_region_member
	 WHERE form_sid = in_form_sid
	   AND region_sid NOT IN
	    (SELECT CAST(item AS NUMBER) FROM TABLE(t_items));

	-- update the sort order (pos field) for existing rows
	UPDATE form_region_member frm
	   SET pos = (SELECT pos
				    FROM TABLE(t_items)
				   WHERE frm.region_sid = item)
	 WHERE frm.form_sid = in_form_sid;

	-- insert any new stuff (we'll update descriptions later)
	-- NB this has to come after we update the POS field for
	-- existing rows, since we include POS in the MINUS set operation
	-- and if this wasn't updated as above, then we'd get wrong
	-- results
	INSERT INTO form_region_member
		(form_sid, region_sid, description, pos)
	 	SELECT in_form_sid, r.region_sid, r.description, new_items.pos
	 	  FROM v$region r,
	 		(SELECT CAST(item AS NUMBER) region_sid, pos
	 		  FROM TABLE(t_items)
	 		MINUS
	 		SELECT region_sid, pos
	 		  FROM form_region_member
	 		 WHERE form_sid = in_form_sid) new_items
	 	 WHERE r.region_sid = new_items.region_sid;
END;

PROCEDURE AmendRegion(
	in_act_id		IN security_pkg.T_ACT_ID,
	in_form_sid		IN security_pkg.T_SID_ID,
	in_region_sid	IN security_pkg.T_SID_ID,
	in_description	IN VARCHAR2
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_form_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Write access denied on the form with sid '||in_form_sid);
	END IF;

	UPDATE form_region_member
	   SET description = in_description
	 WHERE form_sid = in_form_sid
	   AND region_sid = in_region_sid;
END;


PROCEDURE SetAllocateUsersTo(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_form_sid						IN 	security_pkg.T_SID_ID,
	in_allocate_users_to			IN	form.allocate_users_to%TYPE
)
AS
	CURSOR c IS
		SELECT allocate_users_to FROM FORM WHERE form_sid = IN_form_sid;
	r c%ROWTYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_form_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	-- check if this has changed - if not then don't mess becauuse change
	-- means deleting stuff!
	OPEN c;
	FETCH c INTO r;
	IF r.allocate_users_to!=IN_allocate_users_to THEN
		-- delete old stuff
		DeleteAllFormAllocations(in_act_id, in_form_sid);
		UPDATE FORM
		   SET allocate_users_to = in_allocate_users_to
		 WHERE form_sid = in_form_sid;
	END IF;
END;

PROCEDURE GetForm(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_form_sid						IN	security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_form_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	-- TODO: 13p fix needed
	OPEN out_cur FOR
		SELECT name, group_by, period_set_id, period_interval_id, note, allocate_users_to,
			   start_dtm, TO_CHAR(start_dtm,'dd Mon YYYY') start_dtm_formatted,
			   end_dtm, TO_CHAR(end_dtm-1,'dd Mon YYYY') end_dtm_formatted,
			   tab_direction
		  FROM form
		 WHERE form_sid = in_form_sid;
END;

PROCEDURE GetRegions(
	in_act_id		IN 	security_pkg.T_ACT_ID,
	in_form_sid		IN 	security_pkg.T_SID_ID,
	out_cur			OUT SYS_REFCURSOR
)
AS
    CURSOR check_perm_cur IS
        SELECT region_sid
          FROM form_region_member
         WHERE form_sid = in_form_sid
           AND security_pkg.sql_IsAccessAllowedSID(in_act_id, form_sid, security_pkg.PERMISSION_READ) = 0;
    v_region_sid number(10);
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_form_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Read access denied on the form with sid '||in_form_sid);
	END IF;

    -- Check the permissions on all the regions in this range. We want to throw an exception rather
    -- than return missing regions which would only confuse the users.
    OPEN check_perm_cur;
    FETCH check_perm_cur INTO v_region_sid;
    IF check_perm_cur%FOUND THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
        	'Read access denied on the region with sid '||v_region_sid||' in the form '||in_form_sid);
    END IF;

	-- should we be checking the security on the regions?

	-- used in one place in the monolith, and then only uses two fields (sid, desc).

	OPEN out_cur FOR
		SELECT frm.region_sid, r.parent_sid, frm.pos, frm.description, r.active, r.name,
			   r.geo_latitude, r.geo_longitude, r.geo_country, r.geo_region,
			   r.geo_city_id, r.map_entity, r.egrid_ref, r.geo_type, r.region_type,
			   r.disposal_dtm, r.acquisition_dtm, r.lookup_key, r.region_ref
		  FROM form_region_member frm, region r
		 WHERE frm.region_sid = r.region_sid
		   AND frm.form_sid = in_form_sid
		 ORDER BY pos;
END;


PROCEDURE GetIndicators(
	in_act_id		IN 	security_pkg.T_ACT_ID,
	in_form_sid		IN 	security_pkg.T_SID_ID,
	out_cur			OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_form_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Read access denied on the form with sid '||in_form_sid);
	END IF;

	-- should we be checking the security on the indicators?

	-- used in one place in the monolith, and then only uses two fields (sid, desc).

	OPEN out_cur FOR
		SELECT fim.description, m.name measure_name, i.measure_sid, i.active, fim.pos,
			   NVL(fim.format_mask, NVL(i.format_mask, m.format_mask)) format_mask,
			   NVL(fim.scale, NVL(i.scale, m.scale)) scale, NVL(i.divisibility, m.divisibility) divisibility,
			   calc_start_dtm_adjustment, calc_end_dtm_adjustment, pct_lower_tolerance, pct_upper_tolerance, tolerance_type,
			   i.target_direction,	TO_CHAR(i.last_modified_dtm,'yyyy-mm-dd hh24:mi:ss') last_modified,
			   NVL(fim.measure_description, m.description) measure_description, i.ind_sid, i.name,
			   i.calc_xml, i.ind_type,
			   i.period_set_id, i.period_interval_id, i.do_temporal_aggregation, i.calc_description,
			   i.aggregate, i.parent_sid, extract(i.info_xml,'/').getClobVal() info_xml,
			   i.start_month, i.gri,
			   fim.measure_conversion_id,
			   i.factor_type_id, i.gas_measure_sid, i.gas_type_id, i.map_to_ind_sid,
			   i.ind_activity_type_id, i.core, i.roll_forward, i.normalize, i.prop_down_region_tree_sid,
			   i.is_system_managed, i.calc_fixed_start_dtm, i.calc_fixed_end_dtm, i.lookup_key,
			   i.calc_output_round_dp
		  FROM form_ind_member fim, ind i, measure m
		 WHERE fim.form_sid = in_form_sid
		   AND fim.app_sid = i.app_sid AND fim.ind_sid = i.ind_sid
		   AND i.app_sid = m.app_sid(+) AND i.measure_sid = m.measure_sid(+)
		 ORDER BY fim.pos;
END;


PROCEDURE GetFormsList(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_parent_sid					IN	security_pkg.T_SID_ID,
	in_order_by						IN	VARCHAR2,
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_parent_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT f.form_sid, f.name, f.group_by, f.period_set_id, f.period_interval_id, pint.label interval, f.note, f.allocate_users_to,
			   f.start_dtm, to_char(start_dtm,'Mon yyyy') start_dtm_formatted,
			   f.end_dtm, to_char(end_dtm,'Mon yyyy') end_dtm_formatted
		  FROM csr.form f
		  JOIN csr.period_interval pint ON f.app_sid = pint.app_sid AND f.period_set_id = pint.period_set_id AND f.period_interval_id = pint.period_interval_id
		 WHERE parent_sid = in_parent_sid
		 ORDER BY
			CASE LOWER(regexp_substr(in_order_by, '[^ ]+', 1, 2))
				WHEN 'desc'THEN 
					CASE regexp_substr(in_order_by, '[^ ]+', 1, 1)
						WHEN 'form_sid' THEN TO_CHAR(form_sid, '0000000000')
						WHEN 'name' THEN name
						WHEN 'group_by' THEN group_by
						WHEN 'note' THEN dbms_lob.substr(note, 4000, 1)
						WHEN 'allocate_users_to' THEN allocate_users_to
						WHEN 'start_dtm' THEN TO_CHAR(start_dtm, 'YYYY-MM-DD HH24:MI:SS')
						WHEN 'end_dtm' THEN TO_CHAR(end_dtm, 'YYYY-MM-DD HH24:MI:SS')
						WHEN 'interval' THEN interval
						ELSE name
					END
			END DESC,
			CASE LOWER(NVL(regexp_substr(in_order_by, '[^ ]+', 1, 2), 'ASC'))
				WHEN 'asc' THEN
					CASE regexp_substr(in_order_by, '[^ ]+', 1, 1)
						WHEN 'form_sid' THEN TO_CHAR(form_sid, '0000000000')
						WHEN 'name' THEN name
						WHEN 'group_by' THEN group_by
						WHEN 'note' THEN dbms_lob.substr(note, 4000, 1)
						WHEN 'allocate_users_to' THEN allocate_users_to
						WHEN 'start_dtm' THEN TO_CHAR(start_dtm, 'YYYY-MM-DD HH24:MI:SS')
						WHEN 'end_dtm' THEN TO_CHAR(end_dtm, 'YYYY-MM-DD HH24:MI:SS')
						WHEN 'interval' THEN interval
						ELSE name
					END
			END ASC;
END;

FUNCTION ConcatFormAllocationUsers(
	in_form_allocation_id			IN	security_pkg.T_SID_ID
) RETURN VARCHAR2
IS
	CURSOR c IS
		SELECT full_name
		  FROM form_allocation_user fau, csr_user cu, security.user_table ut
		 WHERE fau.user_sid = cu.csr_user_sid AND ut.sid_id = cu.csr_user_sid AND fau.user_sid = ut.sid_id AND
		       ut.account_enabled = 1
		   AND form_allocation_id = in_form_allocation_id
		 ORDER BY full_name;
	out_concat	VARCHAR2(1024);
	v_sep		VARCHAR2(2);
BEGIN
	v_sep := '';
	out_concat := '';
	FOR r IN c LOOP
		IF LENGTHB(out_concat || v_sep || r.full_name)<1020 THEN
			out_concat := out_concat || v_sep || r.full_name;
		ELSE
			out_concat := out_concat || '...';
			EXIT;
		END IF;
		v_sep := ', ';
	END LOOP;
	RETURN out_concat;
END;

FUNCTION ConcatFormAllocationRegions(
	in_form_allocation_id			IN	security_pkg.T_SID_ID
) RETURN VARCHAR2
IS
	CURSOR c IS
		SELECT DESCRIPTION
		  FROM FORM_ALLOCATION_ITEM FAI, v$REGION R
		 WHERE FAI.ITEM_SID = R.REGION_SID
		   AND FORM_ALLOCATION_ID = in_form_allocation_id
		 ORDER BY DESCRIPTION;
	out_concat	VARCHAR2(1024);
	v_sep		VARCHAR2(2);
BEGIN
	v_sep := '';
	out_concat := '';
	FOR r IN c LOOP
		IF LENGTHB(out_concat || v_sep || r.description)<1020 THEN
			out_concat := out_concat || v_sep || r.description;
		ELSE
			out_concat := out_concat || '...';
			EXIT;
		END IF;
		v_sep := ', ';
	END LOOP;
	RETURN out_concat;
END;

FUNCTION ConcatFormAllocationIndicators(
	in_form_allocation_id			IN	security_pkg.T_SID_ID
) RETURN VARCHAR2
IS
	CURSOR c IS
		SELECT description
		  FROM form_allocation_item fai, v$ind i
		 WHERE fai.item_sid = i.ind_sid
		   AND form_allocation_id = in_form_allocation_id
		 ORDER BY description;
	out_concat	VARCHAR2(1024);
	v_sep		VARCHAR2(2);
BEGIN
	v_sep := '';
	out_concat := '';
	FOR r IN c LOOP
		IF LENGTHB(out_concat || v_sep || r.description)<1020 THEN
			out_concat := out_concat || v_sep || r.description;
		ELSE
			out_concat := out_concat || '...';
			EXIT;
		END IF;
		v_sep := ', ';
	END LOOP;
	RETURN out_concat;
END;

PROCEDURE GetFormAllocationList(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_form_sid						IN	security_pkg.T_SID_ID,
	in_order_by						IN	VARCHAR2,
	out_cur							OUT SYS_REFCURSOR
)
AS
	v_order_by	VARCHAR2(1000);
	v_func		VARCHAR2(200);
	CURSOR c IS
		SELECT allocate_users_to FROM FORM WHERE FORM_SID = in_form_sid;
	r c%ROWTYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_form_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

    -- OrderBy Whitelist
	IF in_order_by IS NOT NULL THEN
    v_order_by :=
    CASE (LOWER(in_order_by))
      WHEN 'users asc' THEN ' ORDER BY ' || in_order_by
      WHEN 'users desc' THEN ' ORDER BY ' || in_order_by
      WHEN 'items asc' THEN ' ORDER BY ' || in_order_by
      WHEN 'items desc' THEN ' ORDER BY ' || in_order_by
    END;
	END IF;

	OPEN c;
	FETCH c INTO r;
	IF c%NOTFOUND THEN
		RAISE_APPLICATION_ERROR(-20001, 'Fatal error - form data not found');
	END IF;
	IF r.allocate_users_to = 'region' THEN
		v_func := 'ConcatFormAllocationRegions';
	ELSE
		v_func := 'ConcatFormAllocationIndicators';
	END IF;

	OPEN out_cur FOR
		'SELECT FORM_ALLOCATION_ID, form_pkg.ConcatFormAllocationUsers(form_allocation_id) users, '||
			'form_pkg.'||v_func||'(form_allocation_id) items '||
		  'FROM FORM_ALLOCATION '||
		 'WHERE form_sid = :in_form_sid'||v_order_by USING in_form_sid;
END;

PROCEDURE GetUnallocatedFormItems(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_form_sid						IN	security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
)
AS
	v_allocate_users_to 			form.allocate_users_to%TYPE;

BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_form_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	SELECT allocate_users_to INTO v_allocate_users_to FROM FORM WHERE Form_sid = in_form_sid;

	IF v_ALLOCATE_users_to = 'region' THEN
		OPEN out_cur FOR
			SELECT frm.description, frm.region_sid item_sid, frm.pos
		      FROM form_region_member frm, form f
			 WHERE frm.form_sid = f.form_sid
			   AND f.form_sid = in_form_sid
			 MINUS
			SELECT frm.description, frm.region_sid item_sid, frm.pos
		      FROM form_region_member frm, form f, form_allocation fa, form_allocation_item fai
			 WHERE frm.form_sid = f.form_sid
			   AND frm.region_sid = fai.item_sid
			   AND f.form_sid = in_form_sid
			   AND fa.form_sid = f.form_sid
			   AND fai.form_allocation_id = fa.form_allocation_id
			 ORDER BY pos;
	ELSE
		OPEN out_cur FOR
			SELECT fim.description, fim.ind_sid item_sid, fim.pos
		      FROM form_ind_member fim, form f
			 WHERE fim.form_sid = f.form_sid
			   AND f.form_sid = in_form_sid
			 MINUS
			SELECT fim.description, fim.ind_sid item_sid, fim.pos
		      FROM form_ind_member fim, form f, form_allocation fa, form_allocation_item fai
			 WHERE fim.form_sid = f.form_sid
			   AND fim.ind_sid = fai.item_sid
			   AND f.form_sid = in_form_sid
			   AND fa.form_sid = f.form_sid
			   AND fai.form_allocation_id = fa.form_allocation_id
			 ORDER BY pos;
	END IF;
END;

PROCEDURE GetAllocatedFormItems(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_form_sid						IN	security_pkg.T_SID_ID,
	in_form_allocation_id			IN	FORM_ALLOCATION.form_allocation_id%TYPE,
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_form_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
	    SELECT frm.description, frm.region_sid item_sid, fai.item_sid allocated_item_sid
	      FROM form_region_member frm, form f, form_allocation_item fai
		 WHERE frm.form_sid = f.form_sid
		   AND f.form_sid = in_form_sid
		   AND f.allocate_users_to = 'region'
		   AND fai.form_allocation_id = in_form_allocation_id
		   AND fai.item_sid(+) = frm.region_sid
	 	UNION
	    SELECT fim.description, fim.ind_sid item_sid, fai.item_sid allocated_item_sid
	      FROM form_ind_member fim, form f, form_allocation_item fai
		 WHERE fim.form_sid = f.form_sid
		   AND f.form_sid = in_form_sid
		   AND f.allocate_users_to = 'indicator'
		   AND fai.form_allocation_id = in_form_allocation_id
		   AND fai.item_sid(+) = fim.ind_sid;
END;

PROCEDURE GetAllocatedFormUsers(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_form_sid				IN	security_pkg.T_SID_ID,
	in_form_allocation_id	IN	FORM_ALLOCATION.form_allocation_id%TYPE,
	out_cur					OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_form_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	-- We do all the joins for security - we need to check the form_allocation_id
	-- passed in is actually associated with the form on which we are checking
	-- permissions
	OPEN out_cur FOR
	    SELECT cu.full_name, fau.user_sid
	      FROM csr_user cu, form_allocation_user fau, form_allocation fa, security.user_table ut
		 WHERE fa.form_sid = in_form_sid AND
		       ut.account_enabled = 1 AND
		       fa.form_allocation_id = in_form_allocation_id AND
		       fau.form_allocation_id = fa.form_allocation_id AND
		       cu.csr_user_sid = fau.user_sid AND
		       ut.sid_id = fau.user_sid AND
		       cu.csr_user_sid = ut.sid_id;
END;

-- TODO: consider workflow +
PROCEDURE SetFormAllocation(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_form_sid						IN security_pkg.T_SID_ID,
	in_form_allocation_id			IN FORM_ALLOCATION.FORM_ALLOCATION_ID%TYPE,
	in_user_list					IN VARCHAR2,
	in_item_list					IN VARCHAR2
)
AS
	v_app_sid			security_pkg.T_SID_ID;
	v_allocate_users_to		FORM.allocate_users_to%TYPE;
	v_order_by				VARCHAR2(1000);
	v_func					VARCHAR2(200);
	t_users					T_SPLIT_TABLE;
	t_items					T_SPLIT_TABLE;
	v_form_allocation_id	FORM_ALLOCATION.form_allocation_id%TYPE;
	CURSOR c_check IS
		SELECT COUNT(*) errors FROM (
			SELECT FAI.ITEM_SID FROM
			  FORM_ALLOCATION_ITEM FAI, FORM_ALLOCATION FA
			 WHERE FAI.FORM_ALLOCATION_ID = FA.FORM_ALLOCATION_ID
			   AND FA.FORM_SID = IN_form_sid
			   AND FA.FORM_ALLOCATION_ID != NVL(in_form_allocation_id,-1)
			INTERSECT
			 SELECT TO_NUMBER(ITEM)
			   FROM TABLE(t_items));
	r_check					c_check%ROWTYPE;
	c_delete 				SYS_REFCURSOR;
	c_add	 				SYS_REFCURSOR;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_form_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	-- get some basic info about the form
	SELECT allocate_users_to, app_sid
	  INTO v_allocate_users_to, v_app_sid
	  FROM FORM
	 WHERE form_sid = in_form_sid;

	--item, pos
	t_users := Utils_Pkg.splitString(in_user_list,',');
	t_items := Utils_Pkg.splitString(in_item_list,',');

	-- this item can only occur in one formallocation for this form
	OPEN c_check;
	FETCH c_check INTO r_check;
	IF r_check.errors > 0 THEN
		RAISE_APPLICATION_ERROR(Csr_Data_Pkg.ERR_OBJECT_ALREADY_ALLOCATED,
			'One or more objects is already allocated for this form');
	END IF;
	CLOSE c_check;

	-- delete these users from acls
	-- ============================
	-- Get the stuff that's set currently for this allocation
	-- and do a set-subtract of all the other allocations (+whole allocations,
	-- i.e. we are allocating for indicators, so all regions)
	OPEN c_delete FOR
		SELECT fai.item_sid, fau.user_sid
		  FROM FORM_ALLOCATION_ITEM fai, FORM_ALLOCATION_USER fau
		 WHERE fai.form_allocation_id = NVL(in_form_allocation_id,-1)
		   AND fau.form_allocation_id = NVL(in_form_allocation_id,-1)
		MINUS
		(SELECT cast(I.ITEM AS NUMBER) ITEM_SID, cast(U.ITEM AS NUMBER) USER_SID
		  FROM TABLE(CAST(t_items AS T_SPLIT_TABLE)) I,
			  TABLE(CAST(t_users AS T_SPLIT_TABLE)) U
		UNION
		 SELECT fai.item_sid, fau.user_sid
		  FROM form_allocation_item fai, form_allocation_user fau, form_allocation fa, form f
		 WHERE fai.form_allocation_id = fa.form_allocation_id
		   AND fau.form_allocation_id = fa.form_allocation_id
		   AND fa.form_allocation_id !=NVL(in_form_allocation_id,-1)
		   AND fa.form_sid = f.form_sid
		   AND f.app_sid = v_app_sid
		UNION
   	     -- We want to get indicator member data from forms that are allocating to regions (i.e. allocating to the opposite of us)
		 -- or get region member data from forms that are allocating to indicators.
		 -- The first two bits of the union are there because only one will ever get used, but the data we need
		 -- is in two different tables depending on the value of v_allocate_users_to
	    SELECT frm.region_sid item_sid, fau.user_sid
	      FROM form_region_member frm, form f, form_allocation fa, form_allocation_user fau
		 WHERE frm.form_sid = f.form_sid
		   AND f.app_sid = v_app_sid
		   AND f.form_sid != in_form_sid
		   AND f.allocate_users_to = 'indicator'
		   AND fa.form_sid = f.form_sid
		   AND fau.form_allocation_id = fa.form_allocation_id
		   AND 'region' = v_allocate_users_to
	 	UNION
	    SELECT fim.ind_sid item_sid, fau.user_sid
	      FROM form_ind_member fim, form f, form_allocation fa, form_allocation_user fau
		 WHERE fim.form_sid = f.form_sid
		   AND f.app_sid = v_app_sid
		   AND f.form_sid != in_form_sid
		   AND f.allocate_users_to = 'region'
		   AND fa.form_sid = f.form_sid
		   AND fau.form_allocation_id = fa.form_allocation_id
		   AND 'indicator' = v_allocate_users_to
		   )
		ORDER BY ITEM_SID, USER_SID;
	DeleteUsersFromSOACLs(in_act_id, c_delete);

	-- add these users to acls
	-- ============================
	-- Get the stuff that we're about to insert
	-- and do a set-subtract of all the other allocations (+whole allocations,
	-- i.e. we are allocating for indicators, so all regions)
	OPEN c_add FOR
		SELECT TO_NUMBER(i.item) item_sid, TO_NUMBER(u.item) user_sid
		  FROM TABLE(CAST(t_items AS T_SPLIT_TABLE)) I,
			  TABLE(CAST(t_users AS T_SPLIT_TABLE)) U
		MINUS
		(SELECT fai.item_sid, fau.user_sid
		  FROM form_allocation_item fai, form_allocation_user fau
		 WHERE fai.form_allocation_id = NVL(in_form_allocation_id,-1)
		   AND fau.form_allocation_id = NVL(in_form_allocation_id,-1)
		 UNION
		 SELECT fai.item_sid, fau.user_sid
		  FROM form_allocation_item fai, form_allocation_user fau, form_allocation fa, form f
		 WHERE fai.form_allocation_id = fa.form_allocation_id
		   AND fau.form_allocation_id = fa.form_allocation_id
		   AND fa.form_allocation_id != NVL(in_form_allocation_id,-1)
		   AND fa.form_sid = f.form_sid
		   AND f.app_sid = v_app_sid
  		UNION
   	     -- We want to get indicator member data from forms that are allocating to regions (i.e. allocating to the opposite of us)
		 -- or get region member data from forms that are allocating to indicators.
		 -- The first two bits of the union are there because only one will ever get used, but the data we need
		 -- is in two different tables depending on the value of v_allocate_users_to
	    SELECT frm.region_sid item_sid, fau.user_sid
	      FROM form_region_member frm, form f, form_allocation fa, form_allocation_user fau
		 WHERE frm.form_sid = f.form_sid
		   AND f.app_sid = v_app_sid
		   AND f.form_sid != in_form_sid
		   AND f.allocate_users_to = 'indicator'
		   AND fa.form_sid = f.form_sid
		   AND fau.form_allocation_id = fa.form_allocation_id
		   AND 'region' = v_allocate_users_to
	 	UNION
	    SELECT fim.ind_sid item_sid, fau.user_sid
	      FROM form_ind_member fim, form f, form_allocation fa, form_allocation_user fau
		 WHERE fim.form_sid = f.form_sid
		   AND f.app_sid = v_app_sid
		   AND f.form_sid != in_form_sid
		   AND f.allocate_users_to = 'region'
		   AND fa.form_sid = f.form_sid
		   AND fau.form_allocation_id = fa.form_allocation_id
		   AND 'indicator' = v_allocate_users_to
		   )
		 ORDER BY ITEM_SID;
	AddUsersToSOACLs(in_act_id, c_add, security_pkg.PERMISSION_STANDARD_ALL);


	-- shove stuff into tables
	IF in_form_allocation_id IS NULL THEN
		INSERT INTO FORM_ALLOCATION
			(FORM_ALLOCATION_ID, FORM_SID)
		VALUES
			(form_allocation_id_seq.NEXTVAL, in_form_sid)
		RETURNING
			form_allocation_id INTO v_form_allocation_id;
	ELSE
		v_form_allocation_id := in_form_allocation_id;
		-- clean out old data
		DELETE FROM FORM_ALLOCATION_ITEM
		 WHERE FORM_ALLOCATION_ID = in_form_allocation_id;
		DELETE FROM FORM_ALLOCATION_USER
		 WHERE FORM_ALLOCATION_ID = in_form_allocation_id;
	END IF;


	INSERT INTO FORM_ALLOCATION_ITEM
		(form_allocation_id, item_sid)
	SELECT v_form_allocation_id, ITEM
	  FROM TABLE (t_items);

	INSERT INTO FORM_ALLOCATION_USER
		(form_allocation_id, user_sid)
	SELECT v_form_allocation_id, ITEM
	  FROM TABLE (t_users);

	-- TODO: set or remove acls on the axis that is not being allocated
END;

PROCEDURE DeleteAllFormAllocations(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_form_sid	 					IN  security_pkg.T_SID_ID
)
AS
	CURSOR c IS
		SELECT FORM_ALLOCATION_ID
	 	  FROM FORM_ALLOCATION
		 WHERE FORM_SID = in_form_sid;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_form_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	DELETE FROM form_comment WHERE form_sid = in_form_sid;

	FOR r IN c LOOP
		-- we call SetFormAllocation as this will neatly clean up security
		SetFormAllocation(in_act_id, in_form_sid, r.form_allocation_id, '', '');
	END LOOP;
	DELETE FROM FORM_ALLOCATION WHERE FORM_SID = in_form_sid;
END;

PROCEDURE DeleteFormAllocation(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_form_sid	 					IN  security_pkg.T_SID_ID,
	in_form_allocation_id			IN	FORM_ALLOCATION.form_allocation_id%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_form_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	-- we call SetFormAllocation as this will neatly clean up security
	SetFormAllocation(in_act_id, in_form_sid, in_form_allocation_id, '', '');
	DELETE FROM FORM_COMMENT WHERE FORM_ALLOCATION_ID = in_form_allocation_id;
	DELETE FROM FORM_ALLOCATION WHERE FORM_ALLOCATION_ID = in_form_allocation_id;
END;

PROCEDURE GetMyForms(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_app_sid						IN 	security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
)
AS
	v_user_sid	 					security_pkg.T_SID_ID;
	v_forms_sid  					security_pkg.T_SID_ID;
BEGIN
	User_pkg.getSid(in_act_id, v_user_sid);

	v_forms_sid := securableobject_pkg.GetSidFromPath(in_act_id, in_app_sid, 'Forms');

	-- get forms for a given user
	OPEN out_cur FOR
		SELECT x.*, f.note
		  FROM (SELECT DISTINCT f.form_sid, f.name, f.group_by, f.period_set_id,
		  			   f.period_interval_id, f.allocate_users_to, f.start_dtm,
		  			   TO_CHAR(f.start_dtm,'dd Mon YYYY') start_dtm_formatted,
					   f.end_dtm,
					   TO_CHAR(f.end_dtm-1,'dd Mon YYYY') end_dtm_formatted
		  		  FROM form_allocation_user fau, form_allocation fa, form f
		 		 WHERE fau.user_sid = v_user_sid
		   		   AND f.app_sid = in_app_sid
		   		   AND f.parent_sid = v_forms_sid
		   		   AND fau.form_allocation_id = fa.form_allocation_id
		   		   AND fa.form_sid = f.form_sid) x,
		   	   form f
		 WHERE f.form_sid = x.form_sid
		 ORDER BY x.name;
END;

PROCEDURE GetMyFormRegions(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_form_sid	 					IN  security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
)
AS
	v_user_sid	 		security_pkg.T_SID_ID;
	v_allocate_users_to	FORM.allocate_users_to%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_form_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	User_pkg.getSid(in_act_id, v_user_sid);

	SELECT allocate_users_to INTO v_allocate_users_to
	  FROM form
	 WHERE form_sid = in_form_sid;

	IF v_allocate_users_to = 'region' THEN
		OPEN out_cur FOR
			SELECT frm.region_sid, frm.description, fau.read_only
			  FROM form_allocation_user fau, form_allocation_item fai, form_allocation fa, form_region_member frm
			 WHERE fau.form_allocation_id = fa.form_allocation_id
			   AND fai.form_allocation_id = fa.form_allocation_id
			   AND fa.form_sid = frm.form_sid
			   AND fai.item_sid = frm.region_sid
			   AND fau.user_sid = v_user_sid
			   AND fa.form_sid = in_form_sid
			 ORDER BY pos;
	ELSE
		OPEN out_cur FOR
			SELECT region_sid, description, null read_only
			  FROM form_region_member frm
			 WHERE form_sid = in_form_sid
			 ORDER BY pos;
	END IF;
END;

PROCEDURE FilterMyFormRegions(
	in_form_sid	 					IN  security_pkg.T_SID_ID,
	in_filter						IN	VARCHAR2,
	out_cur							OUT SYS_REFCURSOR
)
AS
	v_user_sid	 					security_pkg.T_SID_ID;
	v_allocate_users_to				form.allocate_users_to%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT(), in_form_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	v_user_sid := security_pkg.GetSID();

	SELECT allocate_users_to INTO v_allocate_users_to
	  FROM FORM WHERE FORM_SID = in_form_sid;

	IF v_allocate_users_to = 'region' THEN
		OPEN out_cur FOR
			SELECT frm.region_sid, frm.description
			  FROM form_allocation_user fau, form_allocation_item fai, form_allocation fa, form_region_member frm
			 WHERE fau.form_allocation_id = fa.form_allocation_id
			   AND fai.form_allocation_id = fa.form_allocation_id
			   AND fa.form_sid = frm.form_sid
			   AND fai.item_sid = frm.region_sid
			   AND fau.user_sid = v_user_sid
			   AND fa.form_sid = in_form_sid
			   AND LOWER(frm.description) LIKE LOWER(in_filter)||'%'
			 ORDER BY pos;
	ELSE
		OPEN out_cur FOR
			SELECT frm.region_sid, frm.description
			  FROM form_region_member frm
			 WHERE form_sid = in_form_sid
			   AND LOWER(frm.description) LIKE LOWER(in_filter)||'%'
			 ORDER BY pos;
	END IF;
END;

PROCEDURE GetMyFormMeasures(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_form_sid	 					IN  security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
)
AS
	v_user_sid	 					security_pkg.T_SID_ID;
	v_allocate_users_to				form.allocate_users_to%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_form_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	User_pkg.getSid(in_act_id, v_user_sid);

	SELECT allocate_users_to INTO v_allocate_users_to
	  FROM FORM WHERE FORM_SID = in_form_sid;

	IF v_allocate_users_to = 'indicator' THEN
		OPEN out_cur FOR
			SELECT DISTINCT i.measure_sid, mc.measure_conversion_id, mc.description conversion_description,
				   mc.a, mc.b, mc.c
			  FROM form_allocation_user fau, form_allocation_item fai,
			  	   form_allocation fa, form_ind_member fim, ind i, measure_conversion mc
			 WHERE fau.form_allocation_id = fa.form_allocation_id
			   AND fai.form_allocation_id = fa.form_allocation_id
			   AND fa.form_sid = fim.form_sid
			   AND fai.item_sid = fim.ind_sid
			   AND fau.user_sid = v_user_sid
			   AND fa.form_sid = in_form_sid
			   AND i.ind_sid = fim.ind_sid
			   AND i.measure_sid = mc.measure_sid
			 ORDER BY measure_sid, mc.description;
	ELSE
		OPEN out_cur FOR
			SELECT DISTINCT i.measure_sid, mc.measure_conversion_id, mc.description conversion_description,
				   mc.a, mc.b, mc.c
			  FROM form_ind_member fim, ind i, measure_conversion mc
			 WHERE fim.form_sid = in_form_sid
			   AND i.ind_sid = fim.ind_sid
			   AND i.measure_sid = mc.measure_sid
			 ORDER BY measure_sid, mc.description;
	END IF;
END;

PROCEDURE GetMyFormIndicators(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_form_sid	 					IN  security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
)
AS
	v_user_sid	 					security_pkg.T_SID_ID;
	v_allocate_users_to				form.allocate_users_to%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_form_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	User_pkg.getSid(in_act_id, v_user_sid);

	SELECT allocate_users_to INTO v_allocate_users_to
	  FROM FORM WHERE FORM_SID = in_form_sid;

	IF v_allocate_users_to = 'indicator' THEN
		OPEN out_cur FOR
			SELECT fim.ind_sid, fim.description, i.info_xml,
				   NVL(i.format_mask, m.format_mask) format_mask,
				   i.multiplier, i.measure_sid, i.ind_type,
				   m.description measure_description, i.active,
				   fim.show_total, fau.read_only
			  FROM form_allocation_user fau, form_allocation_item fai,
			  	   form_allocation fa, form_ind_member fim, ind i, measure m
			 WHERE fau.form_allocation_id = fa.form_allocation_id
			   AND fai.form_allocation_id = fa.form_allocation_id
			   AND fa.app_sid = fim.app_sid AND fa.form_sid = fim.form_sid
			   AND fai.item_sid = fim.ind_sid
			   AND fau.user_sid = v_user_sid
			   AND fa.form_sid = in_form_sid
			   AND i.ind_sid = fim.ind_sid
			   AND i.measure_sid = m.measure_sid(+)
			 ORDER BY fim.pos;
	ELSE
		OPEN out_cur FOR
			SELECT fim.ind_sid, fim.description, i.info_xml,
				   NVL(i.format_mask, m.format_mask) format_mask,
				   i.multiplier, i.measure_sid, i.ind_type,
				   m.description measure_description, i.active,
				   fim.show_total, null read_only
			  FROM form_ind_member fim, ind i, measure m
			 WHERE fim.form_sid = in_form_sid
			   AND i.ind_sid = fim.ind_sid
			   AND i.measure_sid = m.measure_sid(+)
			 ORDER BY fim.pos;
	END IF;
END;

PROCEDURE GetMyFormValues(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_form_sid	 					IN  security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
)
AS
	v_user_sid	 					security_pkg.T_SID_ID;
	CURSOR c IS
		SELECT start_dtm, end_dtm, allocate_users_to
		  FROM form
		 WHERE form_sid = in_form_sid;
	r c%ROWTYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_form_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	User_pkg.getSid(in_act_id, v_user_sid);

	OPEN c;
	FETCH c INTO r;
   	IF r.allocate_users_to = 'region' THEN
		OPEN out_cur FOR
			SELECT v.val_id, v.ind_sid, FAI.ITEM_SID region_sid, v.period_start_dtm, v.period_end_dtm,
				   v.val_number, -- val_converted derives val_number from entry_val_number in case of pct_ownership
				   v.alert, v.flags, v.source_id,
				   v.entry_measure_conversion_id, v.entry_val_number
			  FROM val_converted v, ind i, form_ind_member fim,
			  	   form_allocation_user fau, form_allocation_item fai, form_allocation fa
			 WHERE period_start_dtm >= r.start_dtm and period_start_dtm < r.end_dtm
			   AND v.app_sid = i.app_sid
			   AND v.app_sid = fim.app_sid
			   AND v.app_sid = fau.app_sid
			   AND v.app_sid = fa.app_sid
			   AND i.app_sid = fim.app_sid
			   AND i.app_sid = fim.app_sid
			   AND i.app_sid = fau.app_sid
			   AND i.app_sid = fa.app_sid
			   AND fim.app_sid = fau.app_sid
			   AND fim.app_sid = fai.app_sid
			   AND fim.app_Sid = fa.app_sid
			   AND fau.app_sid = fai.app_sid
			   AND fau.app_sid = fa.app_sid
			   AND fai.app_sid = fa.app_sid
			   AND v.ind_sid = i.ind_sid
			   AND i.ind_sid = fim.ind_sid
			   AND fim.form_sid = in_form_sid
			   AND v.region_sid = fai.item_sid
			   AND fau.form_allocation_id = fa.form_allocation_id
			   AND fai.form_allocation_id = fa.form_allocation_id
			   AND fau.user_sid = v_user_sid
			   AND fa.form_sid = in_form_sid
			 ORDER BY ind_sid, region_sid, period_start_dtm, period_end_dtm DESC;
	ELSE
		OPEN out_cur FOR
			SELECT v.val_id, v.ind_sid, frm.region_sid, v.period_start_dtm, v.period_end_dtm,
				   v.val_number, -- val_converted derives val_number from entry_val_number in case of pct_ownership
				   v.alert, v.flags, v.source_id,
				   v.entry_measure_conversion_id, v.entry_val_number
			  FROM val_converted v, ind i, form_region_member frm,
			  	   form_allocation_user fau, form_allocation_item fai, form_allocation fa
			 WHERE period_start_dtm >= r.start_dtm AND period_start_dtm < r.end_dtm
			   AND v.app_sid = i.app_sid
			   AND v.app_sid = frm.app_sid
			   AND v.app_sid = fau.app_sid
			   AND v.app_sid = fa.app_sid
			   AND i.app_sid = frm.app_sid
			   AND i.app_sid = frm.app_sid
			   AND i.app_sid = fau.app_sid
			   AND i.app_sid = fa.app_sid
			   AND v.ind_sid = i.ind_sid
			   AND v.region_sid = frm.region_sid
			   AND frm.form_sid = in_form_sid
			   AND i.ind_sid = fai.item_sid
			   AND fau.form_allocation_id = fa.form_allocation_id
			   AND fai.form_allocation_id = fa.form_allocation_id
			   AND fau.user_sid = v_user_sid
			   AND fa.form_sid = in_form_sid
			 ORDER BY ind_sid, region_sid, period_start_dtm, period_end_dtm DESC;
	END IF;
END;

PROCEDURE GetMyFormNotes(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_form_sid	 					IN  security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
)
AS
	v_user_sid	 					security_pkg.T_SID_ID;
	CURSOR c IS
		SELECT START_DTM, END_DTM, ALLOCATE_USERS_TO FROM FORM
		 WHERE FORM_SID = in_form_sid;
	r c%ROWTYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_form_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	User_pkg.getSid(in_act_id, v_user_sid);

	OPEN c;
	FETCH c INTO r;
   	IF r.allocate_users_to = 'region' THEN
		OPEN out_cur FOR
			SELECT val_note_id, note, ind_sid, region_sid, period_start_dtm, period_end_dtm,
				   entered_dtm, entered_by_sid, cu.full_name, cu.email
			  FROM val_note vn, csr_user cu
			 WHERE period_start_dtm >= r.start_dtm AND period_start_dtm < r.end_dtm
			   AND cu.csr_user_sid = entered_by_sid
			   AND region_sid IN
				(SELECT fai.item_sid
				  FROM form_allocation_user fau, form_allocation_item fai, form_allocation fa
				 WHERE fau.form_allocation_id = fa.form_allocation_id
				   AND fai.form_allocation_id = fa.form_allocation_id
				   AND fau.user_sid = v_user_sid
				   AND fa.form_sid = in_form_sid)
			   AND ind_sid IN
			   	(SELECT ind_sid
			   	   FROM form_ind_member
				  WHERE form_sid = in_form_sid)
			 ORDER BY val_note_id;
	ELSE
		OPEN out_cur FOR
			SELECT val_note_id, note, ind_sid, region_sid, period_start_dtm, period_end_dtm,
				entered_dtm, entered_by_sid, cu.full_name, cu.email
			  FROM val_note vn, csr_user cu
			 WHERE period_start_dtm >= r.start_dtm AND PERIOD_START_DTM < r.start_dtm
			   AND cu.csr_user_sid = entered_by_sid
			   AND ind_sid in
				(SELECT fai.item_sid
				  FROM form_allocation_user fau, form_allocation_item fai, form_allocation fa
				 WHERE fau.form_allocation_id = fa.form_allocation_id
				   AND fai.form_allocation_id = fa.form_allocation_id
				   AND fau.user_sid = v_user_sid
				   AND fa.form_sid = in_form_sid)
			   AND region_sid IN
			   	(SELECT region_sid
			   	   FROM form_region_member
				  WHERE form_sid = in_form_sid)
			 ORDER BY val_note_id;
	END IF;
END;

PROCEDURE GetMyFormComments(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_form_sid	 					IN  security_pkg.T_SID_ID,
	in_z_key						IN	form_comment.z_key%TYPE,
	out_cur							OUT SYS_REFCURSOR
)
AS
	v_user_sid	 		security_pkg.T_SID_ID;
	CURSOR c IS
		-- gets allocate_users_to and third item in group_by
		SELECT ALLOCATE_USERS_TO, SUBSTR(GROUP_BY, INSTR(GROUP_BY,',',1,2)+1) Z_AXIS
		  FROM FORM
		 WHERE FORM_SID = in_form_sid;
 	r	c%ROWTYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_form_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading form');
	END IF;

	User_pkg.getSid(in_act_id, v_user_sid);

	OPEN c;
	FETCH c INTO r;
	IF c%NOTFOUND THEN
		RAISE_APPLICATION_ERROR(-20001, 'Form data not found');
	END IF;

	IF r.allocate_users_to = r.z_axis THEN
		OPEN out_cur FOR
		SELECT fau.form_allocation_id,
			   CASE f.allocate_users_to
					WHEN 'region' THEN (SELECT description FROM form_region_member WHERE form_sid = in_form_sid AND region_sid = fai.item_sid)
					WHEN 'indicator' THEN (SELECT description FROM form_ind_member WHERE form_sid = in_form_sid AND ind_sid = fai.item_sid)
			   END allocation_list,
			   fc.form_comment, last_updated_by_sid, last_updated_dtm, cu.full_name
		  FROM form_allocation_user fau, form_allocation fa, form f, form_comment fc, csr_user cu, form_allocation_item fai
		 WHERE fau.form_allocation_id = fa.form_allocation_id
		   AND f.form_sid = fa.form_sid
		   AND fc.form_sid (+)= fa.form_sid
		   AND fai.form_allocation_id = fa.form_allocation_id
		   AND fai.item_sid = in_z_key
		   AND fc.form_allocation_id (+)= fa.form_allocation_id
		   AND fc.last_updated_by_sid = cu.csr_user_sid(+)
		   AND fc.z_key (+)= in_z_key
		   AND fau.user_sid = v_user_sid
		   AND fa.form_sid = in_form_sid;
	ELSE
		OPEN out_cur FOR
			SELECT fau.form_allocation_id,
				CASE f.allocate_users_to
					WHEN 'region' THEN Form_Pkg.ConcatFormAllocationRegions(FAU.FORM_ALLOCATION_ID)
					WHEN 'indicator' THEN Form_Pkg.ConcatFormAllocationIndicators(FAU.FORM_ALLOCATION_ID)
				END allocation_list,
				fc.form_comment, last_updated_by_sid, last_updated_dtm, cu.full_name
			  FROM form_allocation_user fau, form_allocation fa, form f, form_comment fc, csr_user cu
			 WHERE fau.form_allocation_id = fa.form_allocation_id
			   AND f.form_sid = fa.form_sid
			   AND fc.form_sid (+)= fa.form_sid
			   AND fc.form_allocation_id (+)= fa.form_allocation_id
			   AND fc.last_updated_by_sid = cu.csr_user_sid(+)
			   AND fc.z_key (+)= in_z_key
			   AND fau.user_sid = v_user_sid
			   AND fa.form_sid = in_form_sid
			 ORDER BY fau.form_allocation_id;
	END IF;
END;

PROCEDURE SetFormComment(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_form_sid	 					IN  security_pkg.T_SID_ID,
	in_z_key						IN	form_comment.z_key%TYPE,
	in_form_allocation_id			IN	form_comment.form_allocation_id%TYPE,
	in_form_comment					IN	form_comment.form_comment%TYPE
)
AS
	v_user_sid	 		security_pkg.T_SID_ID;
	CURSOR c IS
		SELECT FORM_COMMENT FROM FORM_COMMENT
		 WHERE FORM_SID = in_form_sid
	   	   AND Z_KEY = in_z_key
	       AND FORM_ALLOCATION_ID = in_form_allocation_id;
	r	c%ROWTYPE;
BEGIN
-- TODO: what permissions are really needed here??
--	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_form_sid, security_pkg.PERMISSION_WRITE) THEN
--		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied setting form comment');
--	END IF;

	User_pkg.getSid(in_act_id, v_user_sid);

	OPEN c;
	FETCH c INTO r;
	IF c%FOUND THEN
		IF r.FORM_COMMENT != in_form_comment THEN
			UPDATE FORM_COMMENT
			   SET FORM_COMMENT = in_form_comment,
			   	   LAST_UPDATED_BY_SID = v_user_sid,
				   LAST_UPDATED_DTM = SYSDATE
			 WHERE FORM_SID = in_form_sid
			   AND Z_KEY = in_z_key
			   AND FORM_ALLOCATION_ID = in_form_allocation_id;
		END IF;
	ELSIF in_form_comment IS NOT NULL THEN
		INSERT INTO FORM_COMMENT
			(FORM_SID, Z_KEY, FORM_ALLOCATION_ID, FORM_COMMENT, LAST_UPDATED_BY_SID, LAST_UPDATED_DTM)
		VALUES
			(in_form_sid, in_z_key, in_form_allocation_id, in_form_comment, v_user_sid, SYSDATE);
	END IF;
END;

PROCEDURE GetGroups(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_parent_sid					IN 	security_pkg.T_ACT_ID,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT sid_id, name
		  FROM TABLE(security.securableobject_pkg.GetDescendantsAsTable(in_act_id, in_parent_sid))
		 WHERE class_id in (security.security_pkg.SO_GROUP, security.class_pkg.GetClassId('CSRUserGroup'));
END;

END;
/
