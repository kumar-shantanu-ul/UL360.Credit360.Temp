-- Please update version.sql too -- this keeps clean builds in sync
define version=363
@update_header

BEGIN
	INSERT INTO CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Issue management', 0);
	INSERT INTO CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Report publication', 0);
END;
/


BEGIN
INSERT INTO TPL_REGION_TYPE (TPL_REGION_TYPE_ID, LABEL) VALUES (1, 'Selected');
INSERT INTO TPL_REGION_TYPE (TPL_REGION_TYPE_ID, LABEL) VALUES (2, 'Parent of selected');
INSERT INTO TPL_REGION_TYPE (TPL_REGION_TYPE_ID, LABEL) VALUES (3, 'Top of tree');
INSERT INTO TPL_REGION_TYPE (TPL_REGION_TYPE_ID, LABEL) VALUES (4, 'One level from top');
INSERT INTO TPL_REGION_TYPE (TPL_REGION_TYPE_ID, LABEL) VALUES (5, 'Two levels from top');
INSERT INTO TPL_REGION_TYPE (TPL_REGION_TYPE_ID, LABEL) VALUES (6, 'Arbitrary');
END;
/

-- (started dropping this carefully then gave up and just dropped the lot)
drop table deliverable cascade constraints;

alter table milestone_issue drop constraint PK_MILESTONE_ISSUE drop index;
alter table MILESTONE_ISSUE ADD CONSTRAINT PK_MILESTONE_ISSUE PRIMARY KEY (APP_SID, MILESTONE_SID, ISSUE_ID);

ALTER TABLE MILESTONE_ISSUE drop CONSTRAINT FK_ISSUE_MILE_ISSUE ;

ALTER TABLE MILESTONE_ISSUE DROP CONSTRAINT FK_MILE_ISS_MILESTONE;

ALTER TABLE MILESTONE_ISSUE ADD CONSTRAINT FK_MILE_ISS_MILESTONE 
    FOREIGN KEY (APP_SID, MILESTONE_SID)
    REFERENCES MILESTONE(APP_SID, MILESTONE_SID)
;

alter table milestone drop constraint UK_MILESTONE_DELIVERABLE drop index;
alter table milestone_issue drop column deliverable_sid;
alter table milestone drop column deliverable_sid cascade constraints;

ALTER TABLE ISSUE DROP CONSTRAINT UK_ISSUE_DELIVERABLE drop index;
alter table issue drop column deliverable_sid cascade constraints;


drop table progression_method cascade constraints;
drop table milestone cascade constraints;
drop table milestone_issue cascade constraints;
drop table approval_step_milestone cascade constraints;

drop package csr.deliverable_pkg;
drop package csr.milestone_pkg;


DECLARE
	v_deliverable_class_id	security_pkg.T_CLASS_ID := class_pkg.GetClassID('CSRDeliverable');
	v_milestone_class_id	security_pkg.T_CLASS_ID := class_pkg.GetClassID('CSRMilestone');
	v_act	security_pkg.T_ACT_ID;
BEGIN
	user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 3600, v_act);
	update security.securable_object_class 
	    set helper_pkg = null 
	 where class_id IN (v_deliverable_class_id, v_milestone_class_id);
	-- milestones live beneath deliverables etc etc
	FOR r IN (
		SELECT sid_id, name
		  FROM security.securable_object 
		 WHERE class_id = v_deliverable_class_Id
	)
	LOOP
		dbms_output.put_line('deleting '||r.sid_id||' '||r.name);
		securableobject_pkg.deleteso(v_act, r.sid_id);
	END LOOP;
	-- goodbye!!
	class_pkg.DeleteClass(v_act, v_deliverable_class_id);
	class_pkg.DeleteClass(v_act, v_milestone_class_id);
END;
/





-- 
-- TABLE: ISSUE_SHEET_VALUE
--

CREATE TABLE ISSUE_SHEET_VALUE(
    APP_SID              NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    ISSUE_ID             NUMBER(10, 0),
    IND_SID		    	 NUMBER(10, 0)    NOT NULL,
    REGION_SID			 NUMBER(10, 0)    NOT NULL,
    START_DTM			 DATE			  NOT NULL,
    END_DTM			     DATE			  NOT NULL,
    CONSTRAINT PK_ISSUE_SHEET_VALUE PRIMARY KEY (APP_SID, IND_SID, REGION_SID, START_DTM, END_DTM)
)
;

ALTER TABLE ISSUE_SHEET_VALUE ADD CHECK 
	(ISSUE_ID IS NOT NULL) 
	DEFERRABLE INITIALLY DEFERRED;



@../create_views

@../csr_data_pkg
@../csr_data_body
@../sheet_pkg
@../sheet_body
@../issue_pkg
@../issue_body
@../pending_pkg
@../approval_Step_range_pkg
@../pending_body
@../approval_Step_range_body


@update_tail
