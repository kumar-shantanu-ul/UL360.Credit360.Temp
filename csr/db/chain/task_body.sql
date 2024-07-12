CREATE OR REPLACE PACKAGE BODY CHAIN.task_pkg
IS

PROCEDURE ExecuteTaskActions (
	in_change_group_id			IN  task.change_group_id%TYPE,
	in_task_id					IN  task.task_id%TYPE,
	in_from_status_id			IN  chain_pkg.T_TASK_STATUS,
	in_to_status_id				IN  chain_pkg.T_TASK_STATUS
);

PROCEDURE ChangeTaskStatus_ (
	in_change_group_id			IN  task.change_group_id%TYPE,
	in_task_id					IN  task.task_id%TYPE,
	in_status_id				IN	task.task_status_id%TYPE,
	in_no_cascade				IN  BOOLEAN DEFAULT FALSE
);


/**********************************************************
		PRIVATE
**********************************************************/
FUNCTION GetTaskOwner (
	in_task_id					IN  task.task_id%TYPE
) RETURN security_pkg.T_SID_ID
AS
	v_oc_sid					security_pkg.T_SID_ID;
BEGIN
	SELECT MIN(owner_company_sid)
	  INTO v_oc_sid
	  FROM task
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND task_id = in_task_id;

	RETURN v_oc_sid;
END;

PROCEDURE AddTaskActions (
	in_task_type_id				IN  task_type.task_type_id%TYPE,
	in_action_list				IN  T_TASK_ACTION_LIST,
	in_invert_actions			IN  BOOLEAN
)
AS
	v_action					T_TASK_ACTION_ROW;
	v_pos						NUMBER(10);
BEGIN
	IF in_action_list IS NULL OR in_action_list.COUNT = 0 THEN
		RETURN;
	END IF;
	
	SELECT NVL(MAX(position), 0) 
	  INTO v_pos
	  FROM task_action_trigger
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND task_type_id = in_task_type_id;
	
	FOR i IN in_action_list.FIRST .. in_action_list.LAST 
	LOOP
		v_action := in_action_list(i);
		
		INSERT INTO task_action_trigger
		(task_type_id, on_task_action_id, trigger_task_action_id, trigger_task_name, position)
		VALUES
		(in_task_type_id, v_action.ON_TASK_ACTION, v_action.TRIGGER_TASK_ACTION, LOWER(v_action.TRIGGER_TASK_NAME), v_pos);
		
		v_pos := v_pos + 1;
		
		-- auto revert all actions where possible - if this breaks, it will only be on setup, and we can deal with it then
		IF in_invert_actions AND v_action.ON_TASK_ACTION < chain_pkg.REVERT_TASK_OFFSET AND v_action.TRIGGER_TASK_ACTION < chain_pkg.REVERT_TASK_OFFSET THEN
			INSERT INTO task_action_trigger
			(task_type_id, on_task_action_id, trigger_task_action_id, trigger_task_name, position)
			VALUES
			(in_task_type_id, v_action.ON_TASK_ACTION + chain_pkg.REVERT_TASK_OFFSET, v_action.TRIGGER_TASK_ACTION + chain_pkg.REVERT_TASK_OFFSET, LOWER(v_action.TRIGGER_TASK_NAME), v_pos);

			v_pos := v_pos + 1;
		END IF;

	END LOOP;
END;

FUNCTION GenerateChangeGroupId
RETURN task.change_group_id%TYPE
AS
	v_change_group_id			task.change_group_id%TYPE;
BEGIN
	SELECT task_change_group_id_seq.nextval
	  INTO v_change_group_id
	  FROM dual;
	
	RETURN v_change_group_id;
END;

PROCEDURE ExecuteTaskActions (
	in_change_group_id			IN  task.change_group_id%TYPE,
	in_task_id					IN  task.task_id%TYPE,
	in_from_status_id			IN  chain_pkg.T_TASK_STATUS,
	in_to_status_id				IN  chain_pkg.T_TASK_STATUS
)
AS
	v_owner_company_sid			security_pkg.T_SID_ID;
	v_supplier_company_sid		security_pkg.T_SID_ID;
	v_task_type_id				task_type.task_type_id%TYPE;
	v_scheme_id					task_type.task_scheme_id%TYPE;
BEGIN
	SELECT t.owner_company_sid, t.supplier_company_sid, tt.task_type_id, tt.task_scheme_id
	  INTO v_owner_company_sid, v_supplier_company_sid, v_task_type_id, v_scheme_id
	  FROM task t, task_type tt
	 WHERE t.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND t.app_sid = tt.app_sid
	   AND t.task_type_id = tt.task_type_id
	   AND t.task_id = in_task_id;
	
	--RAISE_APPLICATION_ERROR(-20001, in_from_status_id||', '||in_to_status_id||', '||v_owner_company_sid||', '||v_supplier_company_sid||', '|| v_task_type_id||', '||v_scheme_id);
	FOR r IN (
		SELECT t.task_id, tatt.to_task_status_id
		  FROM task_action_trigger tat, task_action_lookup tal, task_action_trigger_transition tatt, task_type tt, task t
		 WHERE tat.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND tat.app_sid = tt.app_sid
		   AND tat.app_sid = t.app_sid
		   AND t.owner_company_sid = v_owner_company_sid
		   AND t.supplier_company_sid = v_supplier_company_sid
		   AND tt.task_type_id = t.task_type_id
		   AND t.task_status_id = tatt.from_task_status_id
		   AND tt.task_scheme_id = v_scheme_id
		   AND tt.name = tat.trigger_task_name
		   AND tat.task_type_id = v_task_type_id
		   AND tat.on_task_action_id = tal.task_action_id
		   AND tal.from_task_status_id = in_from_status_id
		   AND tal.to_task_status_id = in_to_status_id
		   AND tat.trigger_task_action_id = tatt.task_action_id
		 ORDER BY tat.position
	) LOOP
		ChangeTaskStatus_(in_change_group_id, r.task_id, r.to_task_status_id);
	END LOOP;
END;

PROCEDURE ChangeTaskStatus_ (
	in_change_group_id			IN  task.change_group_id%TYPE,
	in_task_id					IN  task.task_id%TYPE,
	in_status_id				IN	task.task_status_id%TYPE,
	in_no_cascade				IN  BOOLEAN DEFAULT FALSE
)
AS
	v_default_status			task.task_status_id%TYPE;
	v_due_date_offset			task_type.due_in_days%TYPE;
	v_set_due_date				task.due_date%TYPE;
	v_new_status				task.task_status_id%TYPE DEFAULT in_status_id;
	v_new_last_status			task.task_status_id%TYPE;
	v_cur_status				task.task_status_id%TYPE;
	v_cur_last_status			task.task_status_id%TYPE;
	v_task_type_id				task.task_type_id%TYPE;
BEGIN
	BEGIN
		SELECT task_status_id, last_task_status_id, task_type_id
		  INTO v_cur_status, v_cur_last_status, v_task_type_id
		  FROM task
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND task_id = in_task_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Task ID: '||in_task_id);
	END;
	
	-- no status change
	IF v_cur_status = v_new_status THEN
		RETURN;
	END IF;
	
	SELECT default_task_status_id, due_in_days
	  INTO v_default_status, v_due_date_offset
	  FROM task_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND task_type_id = v_task_type_id;
	
	-- figure out if we're rolling back the status
	IF v_new_status = chain_pkg.TASK_LAST_STATUS THEN
		IF v_cur_last_status IS NULL THEN
			-- i don't think we should get this, not sure how to deal with it if we do (it would mean that there was a double rollback)
			RAISE_APPLICATION_ERROR(-20001, 'Cannot rollback status when last status is null for task ' || in_task_id);
		ELSE
			v_new_status := v_cur_last_status;
			v_new_last_status := NULL; -- don't really need this, but reminds me that this is what we want
		END IF;
	ELSIF v_new_status = chain_pkg.TASK_DEFAULT_STATUS THEN
		v_new_status := v_default_status;
		v_new_last_status := v_cur_status;
	ELSE
		v_new_last_status := v_cur_status;
	END IF;
	
	IF v_new_status = chain_pkg.TASK_OPEN AND v_new_last_status IN (v_default_status, chain_pkg.TASK_REVIEW) AND v_due_date_offset IS NOT NULL THEN
		v_set_due_date := SYSDATE + v_due_date_offset;
	END IF;
	
	-- update the data
	UPDATE task 
	   SET task_status_id = v_new_status,
	   	   last_task_status_id = v_new_last_status,
	   	   last_updated_dtm = SYSDATE,
	   	   last_updated_by_sid = SYS_CONTEXT('SECURITY','SID'),
	   	   due_date = NVL(v_set_due_date, due_date),
	   	   change_group_id = in_change_group_id
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND task_id = in_task_id;
	
	IF in_no_cascade <> TRUE THEN
		chain_link_pkg.TaskStatusChanged(in_change_group_id, in_task_id, v_new_status);

		-- TODO: I'm not sure why I have this, but seems a bit wrong as I think it prevents REVERT_REMOVE from running properly
		IF v_new_last_status IS NOT NULL THEN
			ExecuteTaskActions(in_change_group_id, in_task_id, v_new_last_status, v_new_status);
		END IF;
	END IF;
END;

FUNCTION SetTaskEntry (
	in_task_id					IN  task.task_id%TYPE,
	in_task_entry_type_id		IN  chain_pkg.T_TASK_ENTRY_TYPE,
	in_name						IN  task_entry.name%TYPE
) RETURN task_entry.task_entry_id%TYPE
AS
	v_task_entry_id				task_entry.task_entry_id%TYPE;
BEGIN
	IF NOT capability_pkg.CheckCapability(GetTaskOwner(in_task_id), chain_pkg.TASKS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to tasks for company with sid '||GetTaskOwner(in_task_id));
	END IF;
	
	BEGIN
		INSERT INTO task_entry
		(task_entry_id, task_id, task_entry_type_id, name)
		VALUES
		(task_entry_id_seq.NEXTVAL, in_task_id, in_task_entry_type_id, LOWER(in_name))
		RETURNING task_entry_id INTO v_task_entry_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE task_entry
			   SET last_modified_dtm = SYSDATE,
			       last_modified_by_sid = SYS_CONTEXT('SECURITY', 'SID')
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND task_entry_type_id = in_task_entry_type_id
			   AND task_id = in_task_id
			   AND (name = LOWER(in_name) OR (name IS NULL AND in_name IS NULL))
			RETURNING task_entry_id INTO v_task_entry_id;
	END;
	
	RETURN v_task_entry_id;
END;


PROCEDURE CollectTasks_ (
	in_task_ids					IN	security.T_SID_TABLE,
	out_task_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_task_entry_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_task_param_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_task_entry_ids			security.T_SID_TABLE;
BEGIN
	OPEN out_task_cur FOR
		SELECT t.task_id, t.task_status_id, t.due_date, t.next_review_date, t.last_updated_dtm, t.last_updated_by_sid, 
				t.supplier_company_sid, t.task_type_id, t.owner_company_sid, t.last_task_status_id, tt.description, SYSDATE dtm_now, CASE WHEN t.task_status_id = chain_pkg.TASK_OPEN AND t.due_date < SYSDATE THEN 1 ELSE 0 END overdue,
				tt.due_date_editable, tt.review_every_n_days, t.next_review_date, tt.mandatory, tt.name task_type_name, tt.parent_task_type_id, tt.task_scheme_id, t.skipped
		  FROM task t, task_type tt
		 WHERE t.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND t.app_sid = tt.app_sid
		   AND t.task_id IN (SELECT COLUMN_VALUE FROM TABLE(in_task_ids))
		   AND t.task_type_id = tt.task_type_id
		 ORDER BY tt.position;
		
	SELECT task_entry_id
	  BULK COLLECT INTO v_task_entry_ids
	  FROM task_entry
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND task_id IN (SELECT COLUMN_VALUE FROM TABLE(in_task_ids));
	
	IF v_task_entry_ids.COUNT = 0 THEN
		OPEN out_task_entry_cur FOR
			SELECT null task_entry_id FROM DUAL WHERE 1 = 0;
	ELSE	
		-- TODO: for performance, it's probably better to move this data to a temporary table otherwise we're forced to join on all data
		-- because we apparently can't use the TABLE(v_task_entry_ids) on the inner select
		OPEN out_task_entry_cur FOR
			SELECT te.task_entry_id, te.task_id, te.task_entry_type_id, te.name, 
					te.last_modified_dtm, te.last_modified_by_sid, tei.dtm, tei.text, 
					tei.file_upload_sid, tei.filename, tei.mime_type, tei.bytes
			  FROM task_entry te, (
						SELECT app_sid, task_entry_id, dtm, null text, null file_upload_sid, null filename, null mime_type, null bytes, null uploaded_dtm
						  FROM task_entry_date
						 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
						 UNION ALL
						SELECT app_sid, task_entry_id, null dtm, text, null file_upload_sid, null filename, null mime_type, null bytes, null uploaded_dtm
						  FROM task_entry_note
						 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
						 UNION ALL
						SELECT tef.app_sid, tef.task_entry_id, null dtm, null text, tef.file_upload_sid, fu.filename, fu.mime_type, LENGTH(fu.data) bytes, fu.last_modified_dtm uploaded_dtm
						  FROM task_entry_file tef, file_upload fu
						 WHERE tef.app_sid = SYS_CONTEXT('SECURITY', 'APP')
						   AND tef.app_sid = fu.app_sid
						   AND tef.file_upload_sid = fu.file_upload_sid
						 
					) tei
			 WHERE te.app_sid = tei.app_sid
			   AND te.task_entry_id = tei.task_entry_id
			   AND te.task_entry_id IN (SELECT COLUMN_VALUE FROM TABLE(v_task_entry_ids))
			 ORDER BY te.last_modified_dtm, tei.uploaded_dtm;
	END IF;
	
	OPEN out_task_param_cur FOR
		SELECT t.task_type_id, 'reCompanyName' param_value_name, c.name param_value, 'reCompanySid' param_key_name, c.company_sid param_key
		  FROM task t, company c
		 WHERE t.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND t.app_sid = c.app_sid
		   AND t.supplier_company_sid = c.company_sid
		   AND t.task_id IN (SELECT COLUMN_VALUE FROM TABLE(in_task_ids))
		 UNION ALL
		SELECT t.task_type_id, 'byUserFullName' param_value_name, csru.full_name param_value, 'byUserSid' param_key_name, csru.csr_user_sid param_key
		  FROM task t, csr.csr_user csru
		 WHERE t.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND t.app_sid = csru.app_sid
		   AND t.last_updated_by_sid = csru.csr_user_sid
		   AND t.task_id IN (SELECT COLUMN_VALUE FROM TABLE(in_task_ids));
END;

PROCEDURE CollectTasks_ (
	in_change_group_id			IN  task.change_group_id%TYPE,
	out_task_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_task_entry_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_task_param_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_task_ids					security.T_SID_TABLE;
BEGIN
	SELECT task_id
	  BULK COLLECT INTO v_task_ids
	  FROM task
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND change_group_id = in_change_group_id;
	
	CollectTasks_(v_task_ids, out_task_cur, out_task_entry_cur, out_task_param_cur);
END;

PROCEDURE CollectTasks (
	in_change_group_id			IN  task.change_group_id%TYPE,
	out_task_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_task_entry_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_task_param_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_dummy						security_pkg.T_SID_ID;
BEGIN
	-- make sure that the change group is a single supplier, and that it is for our company
	BEGIN
		SELECT DISTINCT supplier_company_sid
		  INTO v_dummy
		  FROM task
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND owner_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND change_group_id = in_change_group_id;
	EXCEPTION 
		WHEN NO_DATA_FOUND THEN
			
			OPEN out_task_cur FOR SELECT 1 FROM DUAL WHERE 1=0;
			OPEN out_task_entry_cur FOR SELECT 1 FROM DUAL WHERE 1=0;
			OPEN out_task_param_cur FOR SELECT 1 FROM DUAL WHERE 1=0;
			
			RETURN;
	END;
		
	IF NOT capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.TASKS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to tasks for company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;
	
	CollectTasks_(in_change_group_id, out_task_cur, out_task_entry_cur, out_task_param_cur);
END;

PROCEDURE OnTaskEntryChanged (
	in_task_id					IN  task.task_id%TYPE,
	in_task_entry_id			IN  task_entry.task_entry_id%TYPE,
	out_task_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_task_entry_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_task_param_cur			OUT security_pkg.T_OUTPUT_CUR,
	in_force_collect_task		BOOLEAN
)
AS
	v_change_group_id			task.change_group_id%TYPE DEFAULT GenerateChangeGroupId;
BEGIN

	IF in_force_collect_task THEN
		-- ensures that we collect this task even if it's status doesn't change
		UPDATE task
		   SET change_group_id = v_change_group_id
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND task_id = in_task_id;
	END IF;

	chain_link_pkg.TaskEntryChanged(v_change_group_id, in_task_entry_id);
	CollectTasks_(v_change_group_id, out_task_cur, out_task_entry_cur, out_task_param_cur);	
	
END;

/**********************************************************
		PUBLIC SETUP
**********************************************************/

PROCEDURE RegisterScheme (
	in_scheme_id				IN  task_scheme.task_scheme_id%TYPE,	
	in_description				IN  task_scheme.description%TYPE,
	in_db_class					IN  task_scheme.db_class%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'RegisterScheme can only be run as BuiltIn/Administrator');
	END IF;
	
	BEGIN
		INSERT INTO task_scheme
		(task_scheme_id, description, db_class)
		VALUES
		(in_scheme_id, in_description, in_db_class);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE task_scheme
			   SET description = in_description,
			   	   db_class = in_db_class
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND task_scheme_id = in_scheme_id;
	END;
END;

PROCEDURE RegisterTaskType (
	in_scheme_id				IN  task_type.task_scheme_id%TYPE,	
	in_name						IN  task_type.name%TYPE,
	in_parent_name				IN  task_type.name%TYPE DEFAULT NULL,
	in_description				IN  task_type.description%TYPE,
	in_default_status			IN  chain_pkg.T_TASK_STATUS DEFAULT chain_pkg.TASK_HIDDEN,
	in_db_class					IN  task_type.db_class%TYPE DEFAULT NULL,
	in_due_in_days				IN  task_type.due_in_days%TYPE DEFAULT NULL,
	in_mandatory				IN  task_type.mandatory%TYPE DEFAULT chain_pkg.ACTIVE,
	in_due_date_editable		IN  task_type.due_date_editable%TYPE DEFAULT chain_pkg.ACTIVE,
	in_review_every_n_days		IN  task_type.review_every_n_days%TYPE DEFAULT NULL,
	in_card_id					IN  task_type.card_id%TYPE DEFAULT NULL,
	in_invert_actions			IN  BOOLEAN DEFAULT TRUE,
	in_on_action				IN  T_TASK_ACTION_LIST DEFAULT NULL
)
AS
	v_task_type_id				task_type.task_type_id%TYPE DEFAULT GetTaskTypeId(in_scheme_id, in_name);
	v_parent_tt_id				task_type.task_type_id%TYPE DEFAULT GetTaskTypeId(in_scheme_id, in_parent_name);
	v_max_pos					task_type.position%TYPE;
BEGIN
	
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'RegisterTaskType can only be run as BuiltIn/Administrator');
	END IF;
	
	IF v_task_type_id IS NULL THEN
		SELECT NVL(MAX(position), 0)
		  INTO v_max_pos
		  FROM task_type
		 WHERE NVL(parent_task_type_id, -1) = NVL(v_parent_tt_id, -1);
		
		INSERT INTO task_type
		(task_type_id, task_scheme_id, name, parent_task_type_id, description, default_task_status_id, db_class, 
		due_in_days, mandatory, due_date_editable, review_every_n_days, card_id, position)
		VALUES
		(task_type_id_seq.NEXTVAL, in_scheme_id, LOWER(in_name), v_parent_tt_id, in_description, in_default_status, in_db_class,
		in_due_in_days, in_mandatory, in_due_date_editable, in_review_every_n_days, in_card_id, v_max_pos + 1)
		RETURNING task_type_id INTO v_task_type_id;
	ELSE
		UPDATE task_type
		   SET parent_task_type_id = v_parent_tt_id,
			   description = in_description,
			   default_task_status_id = in_default_status,
			   db_class = in_db_class,
			   due_in_days = in_due_in_days,
			   mandatory = in_mandatory,
			   due_date_editable = in_due_date_editable,
			   review_every_n_days = in_review_every_n_days,
			   card_id = in_card_id
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND task_type_id = v_task_type_id;
	END IF;
	
	DELETE FROM task_action_trigger
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND task_type_id = v_task_type_id;
	
	AddTaskActions(v_task_type_id, in_on_action, in_invert_actions);

END;

PROCEDURE SetChildTaskTypeOrder (
	in_scheme_id				IN  task_type.task_scheme_id%TYPE,
	in_parent_name				IN  task_type.name%TYPE,
	in_names_by_order			IN  T_STRING_LIST	
)
AS
	v_parent_tt_id				task_type.task_type_id%TYPE DEFAULT GetTaskTypeId(in_scheme_id, in_parent_name);
	v_task_type_id				task_type.task_type_id%TYPE;
	v_position					NUMBER(10) DEFAULT 1;
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'SetChildTaskTypeOrder can only be run as BuiltIn/Administrator');
	END IF;
	
	IF v_parent_tt_id IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'Could not find a task type named '||in_parent_name||' in the scheme with id '||in_scheme_id);
	END IF;
	
	-- invert them so that we know if any have been missed
	UPDATE task_type
	   SET position = (-1 * position)
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND parent_task_type_id = v_parent_tt_id;
	
	FOR i IN in_names_by_order.FIRST .. in_names_by_order.LAST
	LOOP
		v_task_type_id := GetTaskTypeId(in_scheme_id, in_names_by_order(i));
		
		IF v_task_type_id IS NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'Could not find a task type named '||in_names_by_order(i)||' and parent named '||in_parent_name||' in the scheme with id '||in_scheme_id);
		END IF;
		
		UPDATE task_type
		   SET position = v_position
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND parent_task_type_id = v_parent_tt_id
		   AND task_type_id = v_task_type_id;
		
		IF SQL%ROWCOUNT = 0 THEN
			RAISE_APPLICATION_ERROR(-20001, 'Task type named '||in_names_by_order(i)||' is not a child of parent named '||in_parent_name||' in the scheme with id '||in_scheme_id);
		END IF;
	   
		v_position := v_position + 1;
	END LOOP;
	
	FOR r IN (
		SELECT task_type_id
		  FROM task_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND parent_task_type_id = v_parent_tt_id
		   AND position < 1
		 ORDER BY position DESC
	) LOOP
		UPDATE task_type
		   SET position = v_position
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND task_type_id = r.task_type_id;

		v_position := v_position + 1;
	END LOOP;
END;

PROCEDURE SetParentTaskTypeOrder (
	in_scheme_id				IN  task_type.task_scheme_id%TYPE,
	in_names_by_order			IN  T_STRING_LIST	
)
AS
	v_task_type_id				task_type.task_type_id%TYPE;
	v_position					NUMBER(10) DEFAULT 1;
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'SetParentTaskTypeOrder can only be run as BuiltIn/Administrator');
	END IF;
	
	-- invert them so that we know if any have been missed
	UPDATE task_type
	   SET position = (-1 * position)
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND parent_task_type_id IS NULL
	   AND task_scheme_id = in_scheme_id;
	
	FOR i IN in_names_by_order.FIRST .. in_names_by_order.LAST
	LOOP
		v_task_type_id := GetTaskTypeId(in_scheme_id, in_names_by_order(i));

		IF v_task_type_id IS NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'Could not find a task type named '||in_names_by_order(i)||' in the scheme with id '||in_scheme_id);
		END IF;
		
		UPDATE task_type
		   SET position = v_position
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND task_scheme_id = in_scheme_id
		   AND task_type_id = v_task_type_id
		   AND parent_task_type_id IS NULL;
		
		IF SQL%ROWCOUNT = 0 THEN
			RAISE_APPLICATION_ERROR(-20001, 'Task type named '||in_names_by_order(i)||' is not a parent task in the scheme with id '||in_scheme_id);
		END IF;
	   
		v_position := v_position + 1;
	END LOOP;
END;

PROCEDURE CopyTaskTypeBranch (
	in_from_scheme_id			IN  task_type.task_scheme_id%TYPE,	
	in_to_scheme_id				IN  task_type.task_scheme_id%TYPE,	
	in_from_name				IN  task_type.name%TYPE
)
AS
	v_actions					T_TASK_ACTION_LIST;
	v_actioned					BOOLEAN DEFAULT FALSE;
	v_task_type_id				task_type.task_type_id%TYPE;
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'CopyTaskTypeBranch can only be run as BuiltIn/Administrator');
	END IF;
	
	IF in_from_scheme_id IS NULL OR in_to_scheme_id IS NULL OR in_from_name IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'Null parameter: in_from_scheme_id='||NVL(TO_CHAR(in_from_scheme_id), 'NULL')||' in_to_scheme_id='||NVL(TO_CHAR(in_to_scheme_id), 'NULL')||' in_from_name='||NVL(TO_CHAR(in_from_name), 'NULL'));
	ELSIF in_from_scheme_id = in_to_scheme_id THEN
		RAISE_APPLICATION_ERROR(-20001, 'Cannot branch from/to the same scheme id');
	END IF;
	
	FOR r IN (
		SELECT tt.*, ptt.name parent_name, level
		  FROM task_type tt, task_type ptt
		 WHERE tt.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND tt.app_sid = ptt.app_sid(+)
		   AND tt.task_scheme_id = in_from_scheme_id
		   AND tt.parent_task_type_id = ptt.task_type_id(+)
		 START WITH tt.name = LOWER(in_from_name)
	   CONNECT BY PRIOR tt.task_type_id = tt.parent_task_type_id
	     ORDER SIBLINGS BY tt.position
	) LOOP
		
		v_actioned := TRUE;
		
		SELECT T_TASK_ACTION_ROW(on_task_action_id, trigger_task_action_id, trigger_task_name)
		  BULK COLLECT INTO v_actions
		  FROM task_action_trigger
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND task_type_id = r.task_type_id;
	
		RegisterTaskType(
			in_scheme_id			=> in_to_scheme_id,
			in_name					=> r.name,
			in_parent_name			=> r.parent_name,
			in_description			=> r.description,
			in_default_status		=> r.default_task_status_id,
			in_db_class				=> r.db_class,
			in_due_in_days			=> r.due_in_days,
			in_mandatory			=> r.mandatory,
			in_due_date_editable	=> r.due_date_editable,
			in_review_every_n_days	=> r.review_every_n_days,
			in_card_id				=> r.card_id,
			in_invert_actions		=> FALSE,
			in_on_action			=> v_actions
		);
		
		-- copy the positions as well if we're not dealing with the root task type
		IF r.level > 1 THEN
			v_task_type_id := GetTaskTypeId(in_to_scheme_id, r.name);
			
			UPDATE task_type
			   SET position = r.position
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND task_type_id = v_task_type_id;
		END IF;
		
	END LOOP;
	
	IF NOT v_actioned THEN
		RAISE_APPLICATION_ERROR(-20001, 'Could not find task with name '||in_from_name||' in task scheme with id of '||in_from_scheme_id);
	END IF;
END;


/**********************************************************
		PUBLIC UTILITY
**********************************************************/

FUNCTION GetTaskTypeId (
	in_scheme_id				IN  task_type.task_scheme_id%TYPE,
	in_name						IN  task_type.name%TYPE
) RETURN task_type.task_type_id%TYPE
AS
	v_task_type_id				task_type.task_type_id%TYPE;
BEGIN
	SELECT MIN(task_type_id)
	  INTO v_task_type_id
	  FROM task_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND name = LOWER(in_name)
	   AND task_scheme_id = in_scheme_id;
	
	RETURN v_task_type_id;
END;

FUNCTION GetParentTaskTypeId (
	in_task_type_id				IN  task.task_type_id%TYPE
) RETURN task.task_type_id%TYPE
AS
	v_ptt_id					task.task_type_id%TYPE;
BEGIN
	-- no sec as it's just a task id and there's not much you can do with it
	SELECT MIN(parent_task_type_id)
	  INTO v_ptt_id
	  FROM task_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND task_type_id = in_task_type_id;
	
	RETURN v_ptt_id;
END;

FUNCTION GetParentTaskId (
	in_task_id					IN  task.task_id%TYPE
) RETURN task.task_type_id%TYPE
AS
	v_task_type_id				task.task_type_id%TYPE;
	v_supplier_company_sid		security_pkg.T_SID_ID;
BEGIN
	-- no sec as it's just a task id and there's not much you can do with it
	BEGIN
		SELECT task_type_id, supplier_company_sid
		  INTO v_task_type_id, v_supplier_company_sid
		  FROM task
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND task_id = in_task_id
		   AND owner_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN NULL;
	END;
	
	RETURN GetTaskId(v_supplier_company_sid, GetParentTaskTypeId(v_task_type_id));
END;

FUNCTION GetTaskId (
	in_task_entry_id			IN  task_entry.task_entry_id%TYPE
) RETURN task.task_id%TYPE
AS
	v_task_id						task.task_id%TYPE;
BEGIN
	SELECT MIN(task_id)
	  INTO v_task_id
	  FROM task_entry
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND task_entry_id = in_task_entry_id;
	
	RETURN v_task_id;
END;

FUNCTION GetTaskId (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_task_type_id				IN  task.task_type_id%TYPE
) RETURN task.task_id%TYPE
AS
BEGIN
	RETURN GetTaskId(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_supplier_company_sid, in_task_type_id);
END;

FUNCTION GetTaskId (
	in_owner_company_sid		IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_task_type_id				IN  task.task_type_id%TYPE
) RETURN task.task_id%TYPE
AS
	v_task_id					task.task_id%TYPE;
BEGIN
	-- no sec as it's just a task id and there's not much you can do with it
	SELECT MIN(task_id)
	  INTO v_task_id
	  FROM task
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND task_type_id = in_task_type_id
	   AND owner_company_sid = in_owner_company_sid
	   AND supplier_company_sid = in_supplier_company_sid;
	
	RETURN v_task_id;
END;

FUNCTION GetTaskId (
	in_owner_company_sid		IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_scheme_id				IN  task_type.task_scheme_id%TYPE,
	in_name						IN  task_type.name%TYPE
) RETURN task.task_id%TYPE
AS
BEGIN
	RETURN GetTaskId(in_owner_company_sid, in_supplier_company_sid, GetTaskTypeId(in_scheme_id, in_name));
END;

FUNCTION GetTaskName (
	in_task_id					IN  task.task_id%TYPE
) RETURN task_type.name%TYPE
AS
	v_name						task_type.name%TYPE;
BEGIN
	SELECT MIN(tt.name)
	  INTO v_name
	  FROM task t, task_type tt
	 WHERE t.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND t.app_sid = tt.app_sid
	   AND t.task_id = in_task_id
	   AND t.task_type_id = tt.task_type_id;
	
	RETURN v_name;
END;

FUNCTION GetTaskEntryName (
	in_task_entry_id			IN  task_entry.task_entry_id%TYPE
) RETURN task_type.name%TYPE
AS
	v_name						task_type.name%TYPE;
BEGIN
	SELECT MIN(name)
	  INTO v_name
	  FROM task_entry
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND task_entry_id = in_task_entry_id;
	
	RETURN v_name;
END;

/**********************************************************
		PUBLIC OLD TASK METHODS
**********************************************************/

-- DEPRICATED
FUNCTION AddSimpleTask (
	in_supplier_company_sid		IN	security_pkg.T_SID_ID,
	in_task_type_id				IN	task.task_type_id%TYPE,
	in_task_status				IN	task.task_status_id%TYPE
) RETURN task.task_id%TYPE
AS
	v_task_id					task.task_id%TYPE;
	v_due_date					task.due_date%TYPE;
BEGIN
	
	IF NOT capability_pkg.CheckCapability(chain_pkg.TASKS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to tasks for company with sid '||company_pkg.GetCompany);
	END IF;
	
	SELECT CASE WHEN due_in_days IS NULL THEN NULL ELSE SYSDATE + due_in_days END
	  INTO v_due_date
 	  FROM task_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND task_type_id = in_task_type_id;
	
	INSERT INTO task
	(task_id, task_type_id, owner_company_sid, supplier_company_sid, task_status_id, due_date)
	VALUES
	(task_id_seq.NEXTVAL, in_task_type_id, company_pkg.GetCompany, in_supplier_company_sid, in_task_status, v_due_date)
	RETURNING task_id INTO v_task_id;
	
	RETURN v_task_id;	   
END;


-- DEPRICATED
PROCEDURE ProcessTasks (
	in_supplier_company_sid		IN	security_pkg.T_SID_ID,
	in_questionnaire_class		IN	questionnaire_type.CLASS%TYPE
)
AS
	v_class						questionnaire_type.db_class%TYPE;
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.TASKS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to tasks for company with sid '||company_pkg.GetCompany);
	END IF;
	
	SELECT MIN(db_class)
	  INTO v_class 
	  FROM questionnaire_type 
	 WHERE class = in_questionnaire_class;
	
	IF v_class IS NOT NULL THEN
		-- it is intentional that this will fail if the method doesn't exit
		EXECUTE IMMEDIATE 'BEGIN ' || v_class || '.UpdateTasksForCompany(:companySid);' || ' END;' USING in_supplier_company_sid;
	END IF;
END;

-- DEPRICATED
PROCEDURE ProcessTaskScheme (
	in_supplier_company_sid		IN	security_pkg.T_SID_ID,
	in_scheme_id			IN	task_type.task_scheme_id%TYPE
)
AS
	v_class		QUESTIONNAIRE_TYPE.DB_CLASS%TYPE;
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.TASKS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to tasks for company with sid '||company_pkg.GetCompany);
	END IF;

	SELECT MIN(db_class)
	  INTO v_class 
	  FROM task_scheme 
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND task_scheme_id = in_scheme_id;

	IF v_class IS NOT NULL THEN
		-- it is intentional that this will fail if the method doesn't exit
		EXECUTE IMMEDIATE 'BEGIN ' || v_class || '.UpdateTasksForCompany(:companySid);' || ' END;' USING in_supplier_company_sid;
	END IF;
END;

-- DEPRICATED
PROCEDURE UpdateTask (
	in_task_id					IN	task.task_id%TYPE,
	in_status_id				IN	task.task_status_id%TYPE,
	in_next_review_date			IN	date,
	in_due_date					IN	date
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.TASKS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to tasks for company with sid '||company_pkg.GetCompany);
	END IF;
	
	UPDATE task 
	   SET 	task_status_id = in_status_id, 
	   		next_review_date = in_next_review_date,
			due_date = in_due_date
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND task_id = in_task_id
	   AND owner_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');	
END;

PROCEDURE GetFlattenedTasks (
	in_supplier_company_sid		IN	security_pkg.T_SID_ID,
	in_scheme_id				IN	task_type.task_scheme_id%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.TASKS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to tasks for company with sid '||company_pkg.GetCompany);
	END IF;

	OPEN out_cur FOR
		SELECT t.task_id, t.task_status_id, t.due_date, t.next_review_date, 
				t.last_updated_dtm, t.last_updated_by_sid, t.supplier_company_sid, t.task_type_id, t.owner_company_sid, 
				tt.task_scheme_id, tt.description, tt.due_in_days, tt.mandatory, tt.due_date_editable, tt.review_every_n_days
		  FROM task t, task_type tt
		 WHERE t.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND t.app_sid = tt.app_sid
		   AND t.task_type_id = tt.task_type_id
		   AND tt.task_scheme_id = NVL(in_scheme_id, tt.task_scheme_id)
		   AND t.owner_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND t.supplier_company_sid = in_supplier_company_sid
		   AND tt.parent_task_type_id IS NULL
		 ORDER BY tt.position ASC;
END;

/**********************************************************
		PUBLIC TASK METHODS
**********************************************************/

PROCEDURE RefreshScheme (
	in_scheme_id				IN	task_type.task_scheme_id%TYPE
)
AS
BEGIN
	FOR r IN (
		SELECT DISTINCT t.owner_company_sid, t.supplier_company_sid
		  FROM task t, task_type tt
		 WHERE tt.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND tt.app_sid = t.app_sid
		   AND tt.task_type_id = t.task_type_id
		   AND tt.task_scheme_id = in_scheme_id
	) LOOP
		StartScheme(in_scheme_id, r.owner_company_sid, r.supplier_company_sid);
	END LOOP;
END;

PROCEDURE StartScheme (
	in_scheme_id				IN	task_type.task_scheme_id%TYPE,
	in_owner_company_sid		IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_task_type_name			IN  task_type.name%TYPE DEFAULT NULL
)
AS
	v_tt_name					task_type.name%TYPE DEFAULT LOWER(in_task_type_name);
	v_open_task_id				task.task_id%TYPE;
BEGIN
	-- no sec check here as we're just creating the basic task structure
	
	FOR r IN (
		SELECT *
		  FROM task_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND task_scheme_id = in_scheme_id
	) LOOP
		BEGIN
			INSERT INTO task
			(task_id, task_type_id, owner_company_sid, supplier_company_sid, task_status_id)
			VALUES
			(task_id_seq.NEXTVAL, r.task_type_id, in_owner_company_sid, in_supplier_company_sid, r.default_task_status_id);
			
			IF r.name = v_tt_name THEN
				SELECT task_id_seq.CURRVAL INTO v_open_task_id FROM DUAL;
			END IF;
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;
	
	IF v_open_task_id IS NOT NULL THEN
		ChangeTaskStatus(v_open_task_id, chain_pkg.TASK_OPEN);
	END IF;
END;

PROCEDURE ChangeTaskStatus (
	in_task_id					IN  task.task_id%TYPE,
	in_status_id				IN	task.task_status_id%TYPE
)
AS
	v_owner_company_sid			security_pkg.T_SID_ID DEFAULT GetTaskOwner(in_task_id);
BEGIN	
	IF NOT capability_pkg.CheckCapability(v_owner_company_sid, chain_pkg.TASKS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to tasks for company with sid '||v_owner_company_sid);
	END IF;
	
	ChangeTaskStatus_(GenerateChangeGroupId, in_task_id, in_status_id);
END;

PROCEDURE ChangeTaskStatus (
	in_task_id					IN  task.task_id%TYPE,
	in_status_id				IN	task.task_status_id%TYPE,
	out_task_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_task_entry_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_task_param_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_change_group_id			task.change_group_id%TYPE DEFAULT GenerateChangeGroupId;
BEGIN
	ChangeTaskStatus(v_change_group_id, in_task_id, in_status_id);
	CollectTasks_(v_change_group_id, out_task_cur, out_task_entry_cur, out_task_param_cur);
END;

PROCEDURE ChangeTaskStatus (
	in_change_group_id			IN  task.change_group_id%TYPE,
	in_task_id					IN  task.task_id%TYPE,
	in_status_id				IN	task.task_status_id%TYPE
)
AS
	v_owner_company_sid			security_pkg.T_SID_ID DEFAULT GetTaskOwner(in_task_id);
BEGIN
	IF NOT capability_pkg.CheckCapability(v_owner_company_sid, chain_pkg.TASKS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to tasks for company with sid '||v_owner_company_sid);
	END IF;
	
	ChangeTaskStatus_(in_change_group_id, in_task_id, in_status_id);
END;

PROCEDURE ChangeTaskStatusNoCascade (
	in_change_group_id			IN  task.change_group_id%TYPE,
	in_task_id					IN  task.task_id%TYPE,
	in_status_id				IN	task.task_status_id%TYPE
)
AS
	v_owner_company_sid			security_pkg.T_SID_ID DEFAULT GetTaskOwner(in_task_id);
BEGIN
	IF NOT capability_pkg.CheckCapability(v_owner_company_sid, chain_pkg.TASKS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to tasks for company with sid '||v_owner_company_sid);
	END IF;
		
	ChangeTaskStatus_(in_change_group_id, in_task_id, in_status_id, TRUE);
END;


FUNCTION GetTaskStatus (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_scheme_id				IN  task_type.task_scheme_id%TYPE,
	in_task_type_name			IN  task_type.name%TYPE
) RETURN task.task_status_id%TYPE
AS
BEGIN
	RETURN GetTaskStatus(GetTaskId(in_supplier_company_sid, GetTaskTypeId(in_scheme_id, in_task_type_name)));
END;

FUNCTION GetTaskStatus (
	in_task_id					IN	task.task_id%TYPE
) RETURN task.task_status_id%TYPE
AS
	v_status_id					task.task_status_id%TYPE;
	v_owner_company_sid			security_pkg.T_SID_ID;
BEGIN
	SELECT owner_company_sid, task_status_id
	  INTO v_owner_company_sid, v_status_id
	  FROM task
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND task_id = in_task_id;
	
	IF NOT capability_pkg.CheckCapability(v_owner_company_sid, chain_pkg.TASKS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to tasks for company with sid '||v_owner_company_sid);
	END IF;
	   
	RETURN v_status_id;
END;


PROCEDURE SetTaskDueDate (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_scheme_id				IN  task_type.task_scheme_id%TYPE,
	in_task_type_name			IN  task_type.name%TYPE,
	in_due_date					IN	task.due_date%TYPE,
	in_overwrite				IN	NUMBER
) 
AS
BEGIN
	SetTaskDueDate(GetTaskId(in_supplier_company_sid, GetTaskTypeId(in_scheme_id, in_task_type_name)), in_due_date, in_overwrite);
END;

PROCEDURE SetTaskDueDate (
	in_task_id					IN	task.task_id%TYPE,
	in_due_date					IN	task.due_date%TYPE,
	in_overwrite				IN	NUMBER
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.TASKS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to tasks for company with sid '||company_pkg.GetCompany);
	END IF;
	
	UPDATE task 
	   SET due_date = in_due_date
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND task_id = in_task_id
	   AND (NVL(in_overwrite, 0) <> 0 OR due_date IS NULL)
	   AND owner_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
END;

PROCEDURE PopulateTTTaskSummary_(
	in_task_scheme_id			IN	task_scheme.task_scheme_id%TYPE DEFAULT NULL,
	in_my_companies				security.T_SID_TABLE
)
AS
	v_inv_description			task_type.description%TYPE;  --default invitation task type name
	v_inv_task_type_id 			task_type.task_type_id%TYPE; --default invitation task type id
	v_inv_position 				task_type.position%TYPE;	 --default invitation task type position
BEGIN
	--Set default values (task_type_id, task_name, position) for invitation card
	SELECT description, task_type_id, position
	  INTO v_inv_description, v_inv_task_type_id, v_inv_position
	  FROM task_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND parent_task_type_id IS NULL
	   AND (in_task_scheme_id IS NULL OR task_scheme_id = in_task_scheme_id)
	   AND name = 'invitationcard';
		
	--TT_SUMMARY_TASKS will hold the tasks before the clearing of NOT ACTION companies
	DELETE FROM tt_summary_tasks;
	
	INSERT INTO tt_summary_tasks 
	SELECT tt.description Task_Name, tt.Task_Type_Id Task_Type_Id, pt.supplier_company_sid company_sid, (tt.position * 10) + ctt.position position, -- position calculated by using parent and then child position together
		   CASE WHEN pt.task_status_id IN (chain_pkg.TASK_OPEN) AND ct.task_status_id IN (chain_pkg.TASK_OPEN) AND ct.skipped = 0 AND pt.skipped = 0 AND ct.due_date between sysdate-7 AND sysdate		THEN my.column_value ELSE NULL END Due_Now,
		   CASE WHEN pt.task_status_id IN (chain_pkg.TASK_OPEN) AND ct.task_status_id IN (chain_pkg.TASK_OPEN) AND ct.skipped = 0 AND pt.skipped = 0 AND ct.due_date between sysdate-14 AND sysdate-7	THEN my.column_value ELSE NULL END Over_Due,
		   CASE WHEN pt.task_status_id IN (chain_pkg.TASK_OPEN) AND ct.task_status_id IN (chain_pkg.TASK_OPEN) AND ct.skipped = 0 AND pt.skipped = 0 AND ct.due_date < sysdate-14						THEN my.column_value ELSE NULL END Really_Over_Due,
		   CASE WHEN pt.task_status_id IN (chain_pkg.TASK_OPEN) AND ct.task_status_id IN (chain_pkg.TASK_OPEN) AND ct.skipped = 0 AND pt.skipped = 0 AND ct.due_date between sysdate AND sysdate+7		THEN my.column_value ELSE NULL END Due_Soon,
		   CASE WHEN pt.task_status_id IN (chain_pkg.TASK_OPEN) AND ct.task_status_id IN (chain_pkg.TASK_OPEN) AND ct.skipped = 0 AND pt.skipped = 0 AND (ct.due_date IS NULL OR ct.due_date > sysdate+7)	THEN my.column_value ELSE NULL END Due_Later, --ct.due_date IS NULL handles tasks without due date
		   ct.due_date Due_Date	
	  FROM task_type tt
	  LEFT JOIN task_type ctt ON tt.app_sid = ctt.app_sid AND tt.task_type_id = ctt.parent_task_type_id
	  JOIN task pt ON pt.task_type_id = tt.task_type_id AND pt.app_sid = tt.app_sid
	  JOIN task ct ON  ct.task_type_id = ctt.task_type_id AND ct.app_sid = ctt.app_sid AND pt.supplier_company_sid = ct.supplier_company_sid
	  LEFT JOIN TABLE(in_my_companies) my ON pt.supplier_company_sid=my.column_value
	 WHERE tt.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND tt.parent_task_type_id IS NULL
	   AND (in_task_scheme_id IS NULL OR tt.task_scheme_id = in_task_scheme_id)
	   AND tt.Task_Type_Id <> v_inv_task_type_id
		   
		   -- we handle diffent aggregation for invitation compared to other task types
	UNION  -- (Tasks except Invitation) UNION (Invitation)
		 
	--we aggregate only the last invitation record per company when the status Active or Expired
	SELECT v_inv_description task_name, v_inv_task_type_id task_type_id, inv.to_company_sid company_sid, v_inv_position position,
		   CASE WHEN inv.Invitation_Status_Id in (chain_pkg.EXPIRED) AND inv.Expiration_Dtm between sysdate-7 AND sysdate		THEN inv.To_Company_Sid ELSE NULL END Due_Now,
		   CASE WHEN inv.Invitation_Status_Id in (chain_pkg.EXPIRED) AND inv.Expiration_Dtm between sysdate-14 AND sysdate-7	THEN inv.To_Company_Sid ELSE NULL END Over_Due,
		   CASE WHEN inv.Invitation_Status_Id in (chain_pkg.EXPIRED) AND inv.Expiration_Dtm < sysdate-14						THEN inv.To_Company_Sid ELSE NULL END Really_Over_Due,
		   CASE WHEN inv.Invitation_Status_Id in (chain_pkg.ACTIVE)  AND inv.Expiration_Dtm between sysdate AND sysdate+7		THEN inv.To_Company_Sid ELSE NULL END Due_Soon,
		   CASE WHEN inv.Invitation_Status_Id in (chain_pkg.ACTIVE)  AND inv.Expiration_Dtm > sysdate+7							THEN inv.To_Company_Sid ELSE NULL END Due_Later,
		   inv.Expiration_Dtm Due_Date
		   FROM (
			SELECT i.expiration_dtm,  i.invitation_id, i.to_company_sid, i.invitation_status_id,
				   RANK( ) OVER (PARTITION BY i.to_company_sid ORDER BY i.invitation_id DESC) Ord --this should give us the latest invitation state and only one row per supplier company
			  FROM supplier_relationship sr
			  JOIN invitation i ON (i.from_company_sid = sr.purchaser_company_sid AND i.to_company_sid = sr.supplier_company_sid)
			  JOIN TABLE(in_my_companies) my ON i.to_company_sid = my.column_value
			 WHERE sr.active = 0 -- only take inactive relationships as this means that the supplier is new and has never previously accepted an invitation
			   AND sr.Deleted = 0 -- and the supplier has not rejected an invitation
			)inv
	   WHERE inv.Ord = 1
	   
	UNION
		--in case no invitation task is added to the result set
		SELECT v_inv_description task_name, v_inv_task_type_id task_type_id, NULL company_sid, v_inv_position position, NULL Due_Now, NULL Over_Due, NULL Really_Over_Due, NULL Due_Soon, NULL Due_Later, NULL Due_Date
		  FROM DUAL
		 WHERE EXISTS (--no need adding invitation when no companies
			SELECT 1 
			FROM TABLE(in_my_companies)
		  );			
					
	chain_link_pkg.FilterTasksAgainstMetricType; --Clear out NOT ACTION companies that belong to 1-6 task (i.e. apart from amendContractCard)
	
	-- Keeps in TT the first open task per supplier. 
	-- Calculating the first one: check parent position then check child position, see above
    -- (Supplier company could have more than 1 open child task.)
	chain_link_pkg.ClearDuplicatesForTaskSummary; 
	
END;

PROCEDURE GetTaskSummary (
	in_task_scheme_id			IN	task_scheme.task_scheme_id%TYPE DEFAULT NULL,
	out_cur						OUT security_pkg.T_OUTPUT_CUR,
	out_suppl_relationship_cur	OUT security_pkg.T_OUTPUT_CUR --returns a [company_sid, suppl_relationship_is_active] structure
)
AS
	v_user_sid					security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'SID');
	v_my_companies				security.T_SID_TABLE;
	v_temp						security.T_SID_TABLE;
	v_company_sid				security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
BEGIN
	
	company_pkg.GetFollowingSupplierSids(v_user_sid, TRUE, v_my_companies);
	
	chain_link_pkg.FilterCompaniesForTaskSummary(v_my_companies, v_temp);
	v_my_companies := v_temp;
	
	--Prepare and clear out temp table(Task_Name, Task_Type_Id, company_sid, position)
	PopulateTTTaskSummary_(in_task_scheme_id, v_my_companies);
	
	OPEN out_cur FOR
		SELECT sub.*,
			    c1.name due_now_company_name,
			    c2.name over_due_company_name,
			    c3.name really_over_due_company_name,
			    c4.name due_soon_company_name,
				c5.name due_later_company_name
		  FROM (
			SELECT MIN(Task_Name) Task_Name, Task_Type_Id, MIN(position) position,
				    COUNT(DISTINCT Due_Now) Due_Now, COUNT(DISTINCT Over_Due) Over_Due,
				    COUNT(DISTINCT Really_Over_Due) Really_Over_Due, COUNT(DISTINCT Due_Soon) Due_Soon, COUNT(DISTINCT Due_Later) Due_Later,
				    MIN(Due_Now) due_now_company_sid, MIN(Over_Due) over_due_company_sid,--in case of more than one supplier_company_sid, it returns the MIN(over_due_company_sid)
				    MIN(Really_Over_Due) really_over_due_company_sid, MIN(Due_Soon) due_soon_company_sid,  MIN(Due_Later) due_later_company_sid
			  FROM (
				SELECT task_name, task_type_id, company_sid, position, due_now,	over_due, really_over_due, due_soon, due_later		
				  FROM tt_summary_tasks				
			  ) sub2
			 GROUP BY task_type_id 
		  ) sub
		  LEFT JOIN company c1 ON sub.due_now=1 AND sub.due_now_company_sid = c1.company_sid AND c1.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		  LEFT JOIN company c2 ON sub.over_due=1 AND sub.over_due_company_sid = c2.company_sid AND c2.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		  LEFT JOIN company c3 ON sub.really_over_due=1 AND sub.really_over_due_company_sid = c3.company_sid AND c3.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		  LEFT JOIN company c4 ON sub.due_soon=1 AND sub.due_soon_company_sid = c4.company_sid AND c4.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		  LEFT JOIN company c5 ON sub.due_later=1 AND sub.due_later_company_sid = c5.company_sid AND c5.app_sid = SYS_CONTEXT('SECURITY', 'APP')--tricky: left join here returns the c5.Name only if the COUNT(DISTINCT Due_Later)=1 otherwise name will be null
		 ORDER BY position;
	
	OPEN out_suppl_relationship_cur FOR
		SELECT sr.supplier_company_sid company_sid, sr.active
		  FROM supplier_relationship sr
		  JOIN TABLE(v_my_companies) my ON sr.supplier_company_sid = my.column_value 
		 WHERE sr.purchaser_company_sid = v_company_sid;
	
END;

PROCEDURE GetMyActiveCompaniesByTaskType (
	in_task_scheme_id			IN task_scheme.task_scheme_id%TYPE DEFAULT NULL,
	in_task_type_id				IN task_type.task_type_id%TYPE,
	in_duedate_fragment			IN NUMBER,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_user_sid			security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'SID');
	v_my_companies		security.T_SID_TABLE;
	v_company_sid		security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_temp				security.T_SID_TABLE;
BEGIN
	IF NOT capability_pkg.CheckCapability(v_company_sid, chain_pkg.TASKS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to tasks for company with sid '||v_company_sid);
	END IF;

	company_pkg.GetFollowingSupplierSids(v_user_sid, TRUE, v_my_companies);
	
	chain_link_pkg.FilterCompaniesForTaskSummary(v_my_companies, v_temp);
	v_my_companies := v_temp;
	
	--Prepare and clear out temp table(Task_Name, Task_Type_Id, company_sid, position, due_fragments)
	PopulateTTTaskSummary_(in_task_scheme_id, v_my_companies);
	
	--due_fragments of Temp Table (Due_Now, Due_Later etc) hold either the company_sid or null
	OPEN out_cur FOR
		SELECT DISTINCT ttst.company_sid, c.name, sr.active
		  FROM tt_summary_tasks	ttst	
		  JOIN v$company c ON (c.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND ttst.company_sid = c.company_sid)
		  JOIN supplier_relationship sr ON (sr.supplier_company_sid = c.company_sid AND sr.purchaser_company_sid = v_company_sid)
		 WHERE ttst.task_type_id = in_task_type_id
		   AND (
				   (ttst.Due_Now = c.company_sid         AND in_duedate_fragment = TS_FRAGMENT_DUE_NOW)
				OR (ttst.Over_Due = c.company_sid        AND in_duedate_fragment = TS_FRAGMENT_OVERDUE)
				OR (ttst.Really_Over_Due = c.company_sid AND in_duedate_fragment = TS_FRAGMENT_REALLY_OVERDUE)
				OR (ttst.Due_Soon = c.company_sid        AND in_duedate_fragment = TS_FRAGMENT_DUE_SOON)
				OR (ttst.Due_Later = c.company_sid       AND in_duedate_fragment = TS_FRAGMENT_DUE_LATER)
			)
		ORDER BY c.name;
		
END;

PROCEDURE GetActiveTasksForUser (
	in_user_sid					IN 	security_pkg.T_SID_ID,
	in_task_scheme_ids			IN	helper_pkg.T_NUMBER_ARRAY,
	in_start					IN	NUMBER,
	in_page_size				IN	NUMBER,
	in_sort_by					IN	VARCHAR2,
	in_sort_dir					IN	VARCHAR2,
	out_count					OUT	NUMBER,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_my_companies		security.T_SID_TABLE;
	v_company_sid		security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_all_task_schemes	INTEGER DEFAULT 0;
	v_task_scheme_ids	T_NUMERIC_TABLE;
BEGIN
	IF NOT capability_pkg.CheckCapability(v_company_sid, chain_pkg.TASKS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to tasks for company with sid '||v_company_sid);
	END IF;
	
	company_pkg.GetFollowingSupplierSids(in_user_sid, TRUE, v_my_companies);
	
	v_all_task_schemes := helper_pkg.NumericArrayEmpty(in_task_scheme_ids);
	IF v_all_task_schemes = 1 THEN
		v_task_scheme_ids := T_NUMERIC_TABLE(T_NUMERIC_ROW(-1,1));
	ELSE
		v_task_scheme_ids := helper_pkg.NumericArrayToTable(in_task_scheme_ids);
	END IF;
	
	SELECT COUNT(*)
	  INTO out_count
	  FROM task t
	  JOIN task_type tt ON t.app_sid = tt.app_sid AND t.task_type_id = tt.task_type_id
	  JOIN TABLE(v_my_companies) my ON t.supplier_company_sid = my.column_value
	 WHERE t.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND t.task_status_id IN (chain_pkg.TASK_OPEN)
	   AND tt.parent_task_type_id IS NOT NULL
	   AND (v_all_task_schemes=1 OR tt.task_scheme_id IN (SELECT item FROM TABLE(v_task_scheme_ids)));
	
	INSERT INTO tt_user_tasks (supplier_name, supplier_sid, task_type_description, parent_task_type_description, due_date, rn)
		SELECT * FROM (
				SELECT inr1.*, ROWNUM rn FROM (
					SELECT c.name supplier_name, c.company_sid supplier_sid, tt.description task_type_description,
							ptt.description parent_task_type_description, due_date
					  FROM task t
					  JOIN task_type tt ON t.task_type_id = tt.task_type_id AND t.app_sid = tt.app_sid
					  JOIN task_type ptt ON tt.parent_task_type_id = ptt.task_type_id AND tt.app_sid = ptt.app_sid
					  JOIN v$company c ON t.supplier_company_sid = c.company_sid AND t.app_sid = c.app_sid
					  JOIN TABLE(v_my_companies) my ON c.company_sid = my.column_value
					 WHERE t.app_sid = SYS_CONTEXT('SECURITY', 'APP')
					   AND t.task_status_id IN (chain_pkg.TASK_OPEN)
					   AND (v_all_task_schemes=1 OR tt.task_scheme_id IN (SELECT item FROM TABLE(v_task_scheme_ids)))
					 ORDER BY due_date
							, ptt.position, tt.position
					) inr1
				 WHERE ROWNUM <=in_start+in_page_size
				) inr2
			 WHERE rn > in_start;
	
	UPDATE tt_user_tasks paged
	   SET (re_questionnaire, re_user, message_definition_id) = 
	   (
		SELECT qt.name re_questionnaire, u.full_name re_user, msg.message_definition_id
		  FROM (
			SELECT m.re_company_sid, re_questionnaire_type_id, re_user_sid, re_component_id, message_definition_id,
					ROW_NUMBER() OVER (PARTITION BY m.re_company_sid ORDER BY last_refreshed_dtm DESC) mrn
			  FROM v$message_recipient m
			 WHERE m.re_company_sid IS NOT NULL
			   AND m.message_definition_id in (select message_definition_id from v$message_definition where completion_type_id=0)
			   AND (m.to_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'))
		  ) msg
		  LEFT JOIN questionnaire_type qt ON qt.questionnaire_type_id = msg.re_questionnaire_type_id AND qt.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		  LEFT JOIN csr.csr_user u ON msg.re_user_sid = u.csr_user_sid
		 WHERE mrn=1
		   AND msg.re_company_sid = paged.supplier_sid
	   );
	
	OPEN out_cur FOR
		SELECT t.supplier_name,
				t.supplier_sid,
				t.task_type_description,
				t.parent_task_type_description,
				t.due_date,
				t.re_questionnaire,
				t.re_user,
				df.message_template
		  FROM tt_user_tasks t
		  JOIN v$message_definition df ON t.message_definition_id = df.message_definition_id;
END;


/**********************************************************
		PUBLIC TASK ENTRY METHODS
**********************************************************/

PROCEDURE SaveTaskDate (
	in_task_id					IN  task.task_id%TYPE,
	in_name						IN  task_entry.name%TYPE,
	in_date						IN  task_entry_date.dtm%TYPE
)
AS
	v_task_cur					security_pkg.T_OUTPUT_CUR;
	v_task_entry_cur			security_pkg.T_OUTPUT_CUR;
	v_task_param_cur			security_pkg.T_OUTPUT_CUR;
BEGIN
	SaveTaskDate(in_task_id, in_name, in_date, v_task_cur, v_task_entry_cur, v_task_param_cur);
END;

PROCEDURE SaveTaskDate (
	in_task_id					IN  task.task_id%TYPE,
	in_name						IN  task_entry.name%TYPE,
	in_date						IN  task_entry_date.dtm%TYPE,
	out_task_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_task_entry_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_task_param_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_task_entry_id				task_entry.task_entry_id%TYPE DEFAULT SetTaskEntry(in_task_id, chain_pkg.TASK_DATE, in_name);
BEGIN
	BEGIN
		INSERT INTO task_entry_date
		(task_entry_id, dtm)
		VALUES
		(v_task_entry_id, in_date);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE task_entry_date
			   SET dtm = in_date
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND task_entry_id = v_task_entry_id;
	END;
	
	OnTaskEntryChanged(in_task_id, v_task_entry_id, out_task_cur, out_task_entry_cur, out_task_param_cur, FALSE);
END;

PROCEDURE SaveTaskNote (
	in_task_id					IN  task.task_id%TYPE,
	in_name						IN  task_entry.name%TYPE,
	in_note						IN  task_entry_note.text%TYPE
)
AS
	v_task_cur					security_pkg.T_OUTPUT_CUR;
	v_task_entry_cur			security_pkg.T_OUTPUT_CUR;
	v_task_param_cur			security_pkg.T_OUTPUT_CUR;
BEGIN
	SaveTaskNote(in_task_id, in_name, in_note, v_task_cur, v_task_entry_cur, v_task_param_cur);
END;

PROCEDURE SaveTaskNote (
	in_task_id					IN  task.task_id%TYPE,
	in_name						IN  task_entry.name%TYPE,
	in_note						IN  task_entry_note.text%TYPE,
	out_task_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_task_entry_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_task_param_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_task_entry_id				task_entry.task_entry_id%TYPE DEFAULT SetTaskEntry(in_task_id, chain_pkg.TASK_NOTE, in_name);
BEGIN
	BEGIN
		INSERT INTO task_entry_note
		(task_entry_id, text)
		VALUES
		(v_task_entry_id, in_note);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE task_entry_note
			   SET text = in_note
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND task_entry_id = v_task_entry_id;
	END;
	
	OnTaskEntryChanged(in_task_id, v_task_entry_id, out_task_cur, out_task_entry_cur, out_task_param_cur, FALSE);
END;

PROCEDURE SaveTaskFile (
	in_task_id					IN  task.task_id%TYPE,
	in_name						IN  task_entry.name%TYPE,
	in_file_sid					IN  security_pkg.T_SID_ID
)
AS
	v_task_cur					security_pkg.T_OUTPUT_CUR;
	v_task_entry_cur			security_pkg.T_OUTPUT_CUR;
	v_task_param_cur			security_pkg.T_OUTPUT_CUR;
BEGIN
	SaveTaskFile(in_task_id, in_name, in_file_sid, v_task_cur, v_task_entry_cur, v_task_param_cur);
END;

PROCEDURE SaveTaskFile (
	in_task_id					IN  task.task_id%TYPE,
	in_name						IN  task_entry.name%TYPE,
	in_file_sid					IN  security_pkg.T_SID_ID,
	out_task_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_task_entry_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_task_param_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_task_entry_id				task_entry.task_entry_id%TYPE DEFAULT SetTaskEntry(in_task_id, chain_pkg.TASK_FILE, in_name);
BEGIN
	BEGIN
		INSERT INTO task_entry_file
		(task_entry_id, file_upload_sid)
		VALUES
		(v_task_entry_id, in_file_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;	
	
	OnTaskEntryChanged(in_task_id, v_task_entry_id, out_task_cur, out_task_entry_cur, out_task_param_cur, TRUE);
END;

PROCEDURE DeleteTaskFile (
	in_file_sid					IN  security_pkg.T_SID_ID,
	out_task_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_task_entry_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_task_param_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_task_id					task.task_id%TYPE;
	v_task_entry_id				task_entry.task_entry_id%TYPE;
	v_name						task_entry.name%TYPE;
BEGIN
	SELECT te.task_id, te.name
	  INTO v_task_id, v_name
	  FROM task_entry_file tef, task_entry te
	 WHERE te.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND te.app_sid = tef.app_sid
	   AND te.task_entry_id = tef.task_entry_id
	   AND tef.file_upload_sid = in_file_sid;
	
	v_task_entry_id := SetTaskEntry(v_task_id, chain_pkg.TASK_FILE, v_name);

	DELETE FROM task_entry_file
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND task_entry_id = v_task_entry_id
	   AND file_upload_sid = in_file_sid;
	
	upload_pkg.DeleteFile(in_file_sid);
	
	OnTaskEntryChanged(v_task_id, v_task_entry_id, out_task_cur, out_task_entry_cur, out_task_param_cur, TRUE);	
END;

FUNCTION HasEntry (
	in_task_id					IN  task.task_id%TYPE,
	in_entry_name				IN  task_entry.name%TYPE
) RETURN BOOLEAN
AS
BEGIN
	RETURN HasEntries(in_task_id, T_STRING_LIST(in_entry_name));
END;

FUNCTION HasEntries (
	in_task_id					IN  task.task_id%TYPE,
	in_entry_name_one			IN  task_entry.name%TYPE,
	in_entry_name_two			IN  task_entry.name%TYPE
) RETURN BOOLEAN
AS
BEGIN
	RETURN HasEntries(in_task_id, T_STRING_LIST(in_entry_name_one, in_entry_name_two));
END;

FUNCTION HasEntries (
	in_task_id					IN  task.task_id%TYPE,
	in_entry_name_one			IN  task_entry.name%TYPE,
	in_entry_name_two			IN  task_entry.name%TYPE,
	in_entry_name_three			IN  task_entry.name%TYPE
) RETURN BOOLEAN
AS
BEGIN
	RETURN HasEntries(in_task_id, T_STRING_LIST(in_entry_name_one, in_entry_name_two, in_entry_name_three));
END;

FUNCTION HasEntries (
	in_task_id					IN  task.task_id%TYPE,
	in_entry_names				IN  T_STRING_LIST
) RETURN BOOLEAN
AS
	v_task_entry_id				task_entry.task_entry_id%TYPE;
	v_task_entry_type_id		task_entry.task_entry_type_id%TYPE;
	v_count						NUMBER(10);
BEGIN
	FOR i IN in_entry_names.FIRST .. in_entry_names.LAST
	LOOP
		BEGIN
			SELECT task_entry_id, task_entry_type_id
			  INTO v_task_entry_id, v_task_entry_type_id
			  FROM task_entry
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND task_id = in_task_id
			   AND name = LOWER(in_entry_names(i));
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RETURN FALSE;
		END;
		
		IF v_task_entry_type_id = chain_pkg.TASK_DATE THEN

			SELECT COUNT(*)
			  INTO v_count
			  FROM task_entry_date
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND task_entry_id = v_task_entry_id
			   AND dtm IS NOT NULL;
			
			IF v_count = 0 THEN
				RETURN FALSE;
			END IF;			

		ELSIF v_task_entry_type_id = chain_pkg.TASK_NOTE THEN
		
			SELECT COUNT(*)
			  INTO v_count
			  FROM task_entry_note
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND task_entry_id = v_task_entry_id
			   AND text IS NOT NULL;
			
			IF v_count = 0 THEN
				RETURN FALSE;
			END IF;			

		ELSIF v_task_entry_type_id = chain_pkg.TASK_FILE THEN
		
			SELECT COUNT(*)
			  INTO v_count
			  FROM task_entry_file
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND task_entry_id = v_task_entry_id;
			
			IF v_count = 0 THEN
				RETURN FALSE;
			END IF;			

		ELSE
			RAISE_APPLICATION_ERROR(-20001, 'Unknown task_entry_type '||v_task_entry_type_id);
		END IF;
		
	END LOOP;
	
	RETURN TRUE;
END;

PROCEDURE ToggleSkipTask (
	in_task_id					IN  task.task_id%TYPE,
	in_change_group_id			IN	task.change_group_id%TYPE
)
AS
	v_cur_skipped				task.skipped%TYPE;
	v_next_task_id				task.task_id%TYPE;
	v_next_task_status_id		task.task_id%TYPE;
	v_to_skipped				task.skipped%TYPE DEFAULT chain_pkg.ACTIVE;
BEGIN
	
	-- we'll action the next task when we toggle skip
	SELECT skipped, next_task_id, next_task_status_id
	  INTO v_cur_skipped, v_next_task_id, v_next_task_status_id
	  FROM (
		SELECT x.*, 
				LEAD(task_id, 1) OVER (ORDER BY position) AS next_task_id,
				LEAD(task_status_id, 1) OVER (ORDER BY position) AS next_task_status_id
		  FROM (
			SELECT t.task_id, t.skipped, tt.position, t.task_status_id
			  FROM task t, task_type tt
			 WHERE t.app_sid = tt.app_sid
			   AND t.task_type_id = tt.task_type_id
			   AND (t.app_sid, tt.task_scheme_id, t.owner_company_sid, t.supplier_company_sid, NVL(tt.parent_task_type_id, -1)) IN (
					SELECT t.app_sid, tt.task_scheme_id, t.owner_company_sid, t.supplier_company_sid, NVL(tt.parent_task_type_id, -1)
					  FROM task t, task_type tt
					 WHERE t.app_sid = SYS_CONTEXT('SECURITY', 'APP')
					   AND t.app_sid = tt.app_sid
					   AND t.task_id = in_task_id
					   AND t.task_type_id = tt.task_type_id
					   AND tt.mandatory = chain_pkg.INACTIVE
				)
			) x 
		)
	 WHERE task_id = in_task_id;
	
	IF v_cur_skipped = chain_pkg.ACTIVE THEN
		v_to_skipped := chain_pkg.INACTIVE;
	END IF;
	
	IF v_next_task_id IS NOT NULL THEN
		IF v_to_skipped = chain_pkg.ACTIVE AND v_next_task_status_id IN (chain_pkg.TASK_HIDDEN, chain_pkg.TASK_PENDING) THEN
			ChangeTaskStatus_(in_change_group_id, v_next_task_id, chain_pkg.TASK_OPEN);
		END IF;
	END IF;
	   
	UPDATE task
	   SET skipped = v_to_skipped,
		   change_group_id = in_change_group_id
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND task_id = in_task_id;
END;

PROCEDURE ToggleSkipTask (
	in_task_id					IN  task.task_id%TYPE,
	out_task_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_task_entry_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_task_param_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_change_group_id			task.change_group_id%TYPE DEFAULT GenerateChangeGroupId;
BEGIN
	ToggleSkipTask(in_task_id, v_change_group_id);
	
	CollectTasks_(v_change_group_id, out_task_cur, out_task_entry_cur, out_task_param_cur);	
END;


PROCEDURE GetTaskCardManagerData (
	in_card_group_id			IN  card_group.card_group_id%TYPE,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	out_manager_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_card_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_progression_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_task_type_card_cur		OUT security_pkg.T_OUTPUT_CUR,
	out_task_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_task_entry_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_task_param_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_card_ids									security.T_SID_TABLE;
	v_task_ids									security.T_SID_TABLE;
	v_scheme_id								task_scheme.task_scheme_id%TYPE;
	v_avr_key									supplier_relationship.virtually_active_key%TYPE;
	v_task_card_init_param_cur	security_pkg.T_OUTPUT_CUR;
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.TASKS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to tasks for company with sid '||company_pkg.GetCompany);
	END IF;

	company_pkg.ActivateVirtualRelationship(company_pkg.GetCompany, in_supplier_company_sid, v_avr_key);

	v_scheme_id := chain_link_pkg.GetTaskSchemeId(company_pkg.GetCompany, in_supplier_company_sid);
	
	IF v_scheme_id IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'Could not get a scheme id');
	END IF;
	
	INSERT INTO tt_id (id, position)
	SELECT card_id, position
	  FROM task_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND task_scheme_id = v_scheme_id
	   AND card_id IS NOT NULL;
	
	chain_link_pkg.FilterTaskCards(in_card_group_id, in_supplier_company_sid);
	
	SELECT id
	  BULK COLLECT INTO v_card_ids
	  FROM tt_id
	 ORDER BY position;
	 
	card_pkg.CollectManagerData(in_card_group_id, v_card_ids, out_manager_cur, out_card_cur, out_progression_cur, v_task_card_init_param_cur);
	
	SELECT t.task_id
	  BULK COLLECT INTO v_task_ids
	  FROM task t, (
		SELECT task_type_id
		  FROM task_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND task_scheme_id = v_scheme_id
		 START WITH card_id IS NOT NULL
	   CONNECT BY PRIOR task_type_id = parent_task_type_id
	   ) tt
	 WHERE t.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND t.task_type_id = tt.task_type_id
	   AND t.owner_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND t.supplier_company_sid = in_supplier_company_sid;	

	CollectTasks_(v_task_ids, out_task_cur, out_task_entry_cur, out_task_param_cur);
	
	OPEN out_task_type_card_cur FOR
		SELECT tt.task_type_id, c.class_type
		  FROM task_type tt, card c
		 WHERE tt.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	       AND tt.card_id = c.card_id
	       AND tt.card_id IN (SELECT COLUMN_VALUE FROM TABLE(v_card_ids))
	       AND tt.task_scheme_id = v_scheme_id;
	
	company_pkg.DeactivateVirtualRelationship(v_avr_key);
END;

PROCEDURE MapTaskInvitationQnrType (
	in_scheme_id				IN  task_scheme.task_scheme_id%TYPE,
	in_task_type_name			IN  task_type.name%TYPE,
	in_invitation_id			IN  invitation.invitation_id%TYPE,
	in_questionnaire_type_id	IN  questionnaire_type.questionnaire_type_id%TYPE,
	in_include_children			IN  NUMBER
)
AS
	v_owner_company_sid			security_pkg.T_SID_ID;
	v_supplier_company_sid		security_pkg.T_SID_ID;
	v_task_type_id				task.task_type_id%TYPE DEFAULT GetTaskTypeId(in_scheme_id, in_task_type_name);
	v_task_type_ids				security.T_SID_TABLE;
BEGIN
	SELECT i.from_company_sid, i.to_company_sid
	  INTO v_owner_company_sid, v_supplier_company_sid
	  FROM invitation i, invitation_qnr_type iqt
	 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND i.app_sid = iqt.app_sid
	   AND i.invitation_id = in_invitation_id
	   AND i.invitation_id = iqt.invitation_id
	   AND iqt.questionnaire_type_id = in_questionnaire_type_id;
	   
	IF in_include_children <> chain_pkg.INACTIVE THEN
		SELECT task_type_id
		  BULK COLLECT INTO v_task_type_ids
		  FROM task_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 START WITH task_type_id = v_task_type_id
	   CONNECT BY PRIOR task_type_id = parent_task_type_id;
	ELSE
		v_task_type_ids(0) := v_task_type_id;
	END IF;

	
	FOR r IN (
		SELECT task_id
		  FROM task
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND owner_company_sid = v_owner_company_sid
		   AND supplier_company_sid = v_supplier_company_sid
		   AND task_type_id IN (SELECT COLUMN_VALUE FROM TABLE(v_task_type_ids))
	) LOOP
		BEGIN
			INSERT INTO task_invitation_qnr_type
			(task_id, invitation_id, questionnaire_type_id)
			VALUES
			(r.task_id, in_invitation_id, in_questionnaire_type_id);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE task_invitation_qnr_type
				   SET invitation_id = in_invitation_id,
					   questionnaire_type_id = in_questionnaire_type_id
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND task_id = r.task_id;
		END;
	
	END LOOP;
END;

PROCEDURE GetInvitationTaskCardData (
	in_task_id				IN  task.task_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.TASKS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to tasks for company with sid '||company_pkg.GetCompany);
	END IF;

	OPEN out_cur FOR
		SELECT qt.name questionnaire_type_name,
			   qt.view_url questionnaire_type_view_url,
		        fc.company_sid from_company_sid, fc.name from_company_name, 
				tc.company_sid to_company_sid, tc.name to_company_name, 
				fu.csr_user_sid from_user_sid, fu.full_name from_user_full_name,
				tu.csr_user_sid to_user_sid, tu.full_name to_user_full_name
		   FROM task_invitation_qnr_type tiqt, task t, invitation i, questionnaire_type qt, company fc, company tc, csr.csr_user fu, csr.csr_user tu
		  WHERE tiqt.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		    AND tiqt.app_sid = t.app_sid
			AND tiqt.app_sid = i.app_sid
			AND tiqt.app_sid = qt.app_sid
			AND tiqt.app_sid = fc.app_sid
			AND tiqt.app_sid = tc.app_sid
			AND tiqt.app_sid = fu.app_sid
			AND tiqt.app_sid = tu.app_sid
			AND tiqt.task_id = t.task_id
			AND t.task_id = in_task_id
			AND t.owner_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			AND tiqt.invitation_id = i.invitation_id
			AND tiqt.questionnaire_type_id = qt.questionnaire_type_id
			AND i.from_company_sid = fc.company_sid
			AND i.from_user_sid = fu.csr_user_sid
			AND i.to_company_sid = tc.company_sid
			AND i.to_user_sid = tu.csr_user_sid;
		  
END;

PROCEDURE UpdateTasksForReview
AS
	v_change_group_id			task.change_group_id%TYPE DEFAULT GenerateChangeGroupId;
BEGIN
	FOR r IN (
		SELECT task_id
		  FROM (
			-- get the qualifying tasks (that are in TASK_REVIEW status, and have valid offset dates)
			SELECT t.task_id, t.last_updated_dtm, tt.review_every_n_days
			  FROM task t, task_type tt
			 WHERE t.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND t.app_sid = tt.app_sid
			   AND t.task_type_id = tt.task_type_id  
			   AND t.task_status_id = chain_pkg.TASK_REVIEW
			   AND tt.review_every_n_days IS NOT NULL
			)	
		 WHERE last_updated_dtm + review_every_n_days < SYSDATE
	) LOOP
		-- don't update tasks that have changed in this change group (not sure why, just think it might go sideways)
		FOR t IN (
			SELECT task_id
			  FROM task
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND task_id = r.task_id
			   AND (change_group_id IS NULL OR change_group_id <> v_change_group_id)
		) LOOP
			-- set them to open if they're ready for review
			ChangeTaskStatus_(v_change_group_id, t.task_id, chain_pkg.TASK_OPEN);
		END LOOP;
	END LOOP;
END;

PROCEDURE GetTaskTypesForAdminPage(
	out_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_parent_actions_cur	OUT security_pkg.T_OUTPUT_CUR,
	out_task_scheme_cur		OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	/* gets all the child tasks, their parents and their actions */
	OPEN out_cur FOR
		SELECT 
			ptt.task_type_id parent_id,
			ptt.name parent_task_type_name, 
			ptt.description parent_task_description,
			ctt.task_type_id id,
			ctt.name name, 
			ctt.description description,
			ctt.task_scheme_id, 
			ctt.position, 
			tat.trigger_task_name trigger_task_name, 
			ota.description on_task_action, 
			tta.description trigger_task_action
		  FROM chain.task_type ptt 
		  JOIN chain.task_type ctt ON ptt.task_type_id = ctt.parent_task_type_id
		  JOIN chain.task_action_trigger tat ON ctt.task_type_id = tat.task_type_id
		  JOIN chain.task_action ota ON tat.on_task_action_id = ota.task_action_id
		  JOIN chain.task_action tta ON tat.trigger_task_action_id = tta.task_action_id
		 ORDER BY ptt.position, ctt.position, tat.position;
	
	/* gets all the parent tasks and their actions */
	OPEN out_parent_actions_cur FOR
		SELECT ptt.task_type_id parent_id, tat.trigger_task_name trigger_task_name, ota.description on_task_action, tta.description trigger_task_action
		  FROM chain.task_type ptt
		  JOIN chain.task_action_trigger tat ON ptt.task_type_id = tat.task_type_id
		  JOIN chain.task_action ota ON tat.on_task_action_id = ota.task_action_id
		  JOIN chain.task_action tta ON tat.trigger_task_action_id = tta.task_action_id
		 WHERE parent_task_type_id IS NULL; --only parent tasks
	
	/* gets the schemes*/	
	OPEN out_task_scheme_cur FOR
		SELECT task_scheme_id, description task_scheme_description
		  FROM task_scheme;
		  

END;

END task_pkg;
/
