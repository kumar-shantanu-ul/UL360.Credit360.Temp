-- Please update version.sql too -- this keeps clean builds in sync
define version=68
@update_header

ALTER TABLE TASK_STATUS ADD (
	IS_STOPPED       NUMBER(1, 0)     DEFAULT 0  NOT NULL
    CHECK (IS_STOPPED IN(0,1))
);

ALTER TABLE CUSTOMER_OPTIONS ADD (
	INITIATIVE_NEW_DAYS              NUMBER(10, 0)     DEFAULT 5 NOT NULL
);

-- Add new task status
DECLARE
	v_task_status_id	task_status.task_status_id%TYPE;
BEGIN
	FOR r IN (
		SELECT DISTINCT host
		  FROM csr.customer c, project p
		 WHERE c.app_sid = p.app_sid
		   AND p.icon IS NOT NULL
	) LOOP
		-- Logon
		user_pkg.logonadmin(r.host);
		
		-- Add new status
		BEGIN
			SELECT task_status_id
			  INTO v_task_status_id
			  FROM task_status
			 WHERE label = 'Stopped'
			   AND app_sid = security_pkg.GetAPP;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
		  		INSERT INTO task_status 
					(task_status_id, app_sid, label, is_live, is_stopped, colour, is_default) 
					VALUES (task_status_id_seq.nextval, security_pkg.GetAPP, 'Stopped', 1, 1, 16744960 /*Orange*/ , 0) 
						RETURNING task_status_id INTO v_task_status_id;
		END;
		
		-- Associate with all projects
		FOR r IN (
			SELECT project_sid
			  FROM project
			 WHERE app_sid = security_pkg.GetAPP
		) LOOP
			BEGIN
				INSERT INTO project_task_status 
					(project_sid, task_status_id) 
					VALUES (r.project_sid, v_task_status_id);
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					NULL;
			END;
		END LOOP;
		
		-- Allow people who can approve to stop
		FOR r IN (
			SELECT user_or_group_sid
			 FROM allow_task_status_change c, task_status s
			 WHERE s.label = 'Approved'
			   AND c.task_status_id = s.task_status_id
		) LOOP
			BEGIN
				INSERT INTO allow_task_status_change 
					(task_status_id, user_or_group_sid)
					VALUES (v_task_status_id, r.user_or_group_sid);
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					NULL;
			END;
		END LOOP;

 
			
		-- Logoff
		user_pkg.logonadmin(NULL);
		
	END LOOP;
END;
/

-- Switch to icon name rather than file name
BEGIN
	UPDATE project SET icon = REPLACE(icon, '.gif', '') WHERE icon like '%.gif'; 
	UPDATE project SET icon = REPLACE(icon, '.png', '') WHERE icon like '%.png'; 
END;
/

connect csr/csr@&_CONNECT_IDENTIFIER
grant select, references, update on issue to actions;
grant select, references, delete, insert, update on issue_action to actions;
grant select on issue_action_id_seq to actions;
grant execute on issue_pkg to actions;
connect actions/actions@&_CONNECT_IDENTIFIER

-- Rebuild initiative package
@../initiative_pkg
@../initiative_body
	
@update_tail
