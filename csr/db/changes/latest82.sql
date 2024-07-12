-- Please update version.sql too -- this keeps clean builds in sync
define version=82
@update_header

VARIABLE version NUMBER
BEGIN :version := 82; END; -- CHANGE THIS TO MATCH VERSION NUMBER
/

WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE
	v_version	version.db_version%TYPE;
BEGIN
	SELECT db_version INTO v_version FROM version;
	IF v_version >= :version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||:version||' HAS ALREADY BEEN APPLIED =======');
	END IF;
	IF v_version + 1 <> :version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||:version||' CANNOT BE APPLIED TO A DATABASE OF VERSION '||v_version||' =======');
	END IF;
END;
/

alter table approval_step_sheet add (due_dtm date);
update approval_step_sheet set due_dtm = (select due_dtm from approval_step where approval_step.approval_step_id = approval_step_sheet.approval_step_id);
alter table approval_step_sheet modify due_dtm not null;
alter table approval_step drop column due_dtm;
alter table pending_period add (default_due_dtm date);
update pending_period set default_due_dtm = end_dtm;
alter table pending_period modify default_due_dtm not null;
alter table approval_step add (working_day_offset_from_due number(10));
update approval_step set working_day_offset_from_due = (
	   select offset from (
	   	   select approval_step_id, (level-1)*5 offset from approval_step start with parent_step_id is null connect by prior approval_step_id = parent_step_id
	   )x where approval_step.approval_step_id = x.approval_step_id);
alter table approval_step modify working_day_offset_from_due not null;


UPDATE csr.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT



@update_tail
