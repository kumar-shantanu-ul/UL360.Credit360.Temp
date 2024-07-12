-- Please update version.sql too -- this keeps clean builds in sync
define version=74
@update_header

ALTER TABLE TASK_STATUS_TRANSITION ADD (
	ASK_FOR_COMMENT              NUMBER(1, 0)     DEFAULT 0 NOT NULL
								 CHECK (ASK_FOR_COMMENT IN(0,1)),
	SAVE_DATA                    NUMBER(1, 0)     DEFAULT 1 NOT NULL
                                 CHECK (SAVE_DATA IN(0,1))
);

BEGIN
	FOR r IN (
		SELECT app_sid, task_status_id, is_live, is_rejected, belongs_to_owner
		  FROM task_status
	) LOOP
		IF r.is_live = 1 OR r.is_rejected = 1 OR r.belongs_to_owner = 1 THEN
			UPDATE task_status_transition
			   SET ask_for_comment = 1
			 WHERE to_task_status_id = r.task_status_id
			   AND app_sid = r.app_sid;
		END IF;
		IF r.is_rejected = 1 THEN
			UPDATE task_status_transition
			   SET save_data = 0
			 WHERE to_task_status_id = r.task_status_id
			   AND app_sid = r.app_sid;
		END IF;
	END LOOP;
END;
/

@../initiative_pkg
@../initiative_body

@update_tail
