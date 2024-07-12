-- Please update version.sql too -- this keeps clean builds in sync
define version=01
@update_header

connect security/security@aspen
GRANT EXECUTE ON T_SO_ROW TO PUBLIC;


connect csr/csr@aspen

ALTER TABLE CSR.DELEGATION
RENAME COLUMN OWNER_SID TO CREATED_BY_SID;

ALTER TABLE CSR.SHEET_VALUE
RENAME COLUMN IS_SUBMITTED TO STATUS;

-- changes to permissions
begin
update sheet_action_permission set can_save = 0, can_view = 1 where sheet_action_id in (0,2) and user_level = 1;
update sheet_action_permission set can_delegate = 0 where sheet_action_id = 1 and user_level = 2;
update sheet_action_permission set can_delegate = 0 where sheet_action_id = 3 and user_level = 2;
update sheet_action_permission set can_delegate = 0 where sheet_action_id = 6 and user_level = 2;
update sheet_action_permission set can_save =0 , can_submit = 0, can_delegate = 0 where sheet_action_id = 4 and user_level = 2;
update sheet_action_permission set can_save = 1, can_submit = 1, can_delegate = 1 where sheet_action_id = 9 and user_level in (1,2);
end;
/

-- fix sheet history table
alter table sheet_history add (    TO_DELEGATION_SID    NUMBER(10, 0)    DEFAULT -1 NOT NULL );
   
DECLARE
	cursor c is
		select sheet_history_id, cuf.full_name from_user, cut.full_name to_user, d.parent_sid, d.delegation_sid, 
		 	(select count(*) from delegation_user where delegation_sid = d.delegation_sid and user_sid = sh.to_user_sid) to_user_is_this_delegation,
		 	(select count(*) from delegation_user where delegation_sid = d.parent_sid and user_sid = sh.to_user_sid) to_user_is_parent_delegation
		  from sheet_history sh, csr_user cuf, csr_user cut, sheet s, delegation d
		 where sh.from_user_sid = cuf.csr_user_sid
		   and sh.to_user_sid = cut.csr_user_sid 
		   and sh.sheet_id = s.sheet_id
		   and s.delegation_sid = d.delegation_sid;
BEGIN
	FOR r IN c LOOP	
    	IF r.to_user_is_this_delegation = 1 THEN
			UPDATE sheet_history SET to_delegation_sid = r.delegation_sid where sheet_history_id = r.sheet_history_id;
        END IF;
        IF r.to_user_is_parent_delegation = 1 THEN
			UPDATE sheet_history SET to_delegation_sid = r.parent_sid where sheet_history_id = r.sheet_history_id;
        END IF;    
    END LOOP;    
END;
/

update sheet_history set to_delegation_sid = (select delegation_sid from sheet where sheet_id = sheet_history.sheet_id)
 where to_delegation_sid = -1 and note like 'Created';
 
 
ALTER TABLE SHEET_HISTORY ADD CONSTRAINT RefDELEGATION158 
    FOREIGN KEY (TO_DELEGATION_SID)
    REFERENCES DELEGATION(DELEGATION_SID);

ALTER TABLE SHEET_HISTORY DROP COLUMN TO_USER_SID;



-- delegation editable text for region/ind
alter table delegation_ind add (description varchar2(255), pos number(10) default 0 not null);

alter table delegation_region add (description varchar2(255), pos number(10) default 0 not null)

update delegation_ind set description = (select description from ind where ind_sid = delegation_ind.ind_sid);

update delegation_region set description = (select description from region where region_sid = delegation_region.region_sid);

alter table delegation_ind 	modify (description not null);

alter table delegation_region 	modify (description not null);


CREATE OR REPLACE TYPE T_SHEET_INFO AS 
  OBJECT ( 
	SHEET_ID		NUMBER(10,0),
	DELEGATION_SID		NUMBER(10,0),
	PARENT_DELEGATION_SID	NUMBER(10,0),
	NAME			VARCHAR2(255),
	CAN_SAVE		NUMBER(10,0),
	CAN_SUBMIT		NUMBER(10,0),
	CAN_ACCEPT		NUMBER(10,0),
	CAN_RETURN		NUMBER(10,0),
	CAN_DELEGATE		NUMBER(10,0),
	CAN_VIEW		NUMBER(10,0),
	LAST_ACTION_ID		NUMBER(10,0),
	START_DTM		DATE,
	END_DTM			DATE,
	INTERVAL		CHAR(1),
	GROUP_BY		VARCHAR2(128),
	PERIOD_FMT		VARCHAR2(255),	
	NOTE			CLOB,
	USER_LEVEL		NUMBER(10,0),
	IS_TOP_LEVEL		NUMBER(10,0)
  );
/



-- diddled with view
CREATE or replace VIEW SHEET_WITH_LAST_ACTION AS
SELECT SH.SHEET_ID, SH.DELEGATION_SID, SH.START_DTM, SH.END_DTM, SH.REMINDER_DTM, SH.SUBMISSION_DTM, SHE.SHEET_ACTION_ID LAST_ACTION_ID, SHE.FROM_USER_SID LAST_ACTION_FROM_USER_SID, SHE.ACTION_DTM LAST_ACTION_DTM, SHE.NOTE LAST_ACTION_NOTE, SHE.TO_DELEGATION_SID LAST_ACTION_TO_DELEGATION_SID
FROM SHEET_HISTORY SHE, SHEET SH
WHERE SH.LAST_SHEET_HISTORY_ID = SHE.SHEET_HISTORY_ID AND SHE.SHEET_ID = SH.SHEET_ID
 AND SHE.SHEET_ID = SH.SHEET_ID AND SH.LAST_SHEET_HISTORY_ID = SHE.SHEET_HISTORY_ID
;


-- trash
-- 
-- TABLE: TRASH 
--

CREATE TABLE TRASH(
    TRASH_SID              NUMBER(10, 0)    NOT NULL,
    TRASH_CAN_SID          NUMBER(10, 0)    NOT NULL,
    TRASHED_BY_SID         NUMBER(10, 0),
    TRASHED_DTM            DATE              DEFAULT SYSDATE NOT NULL,
    PREVIOUS_PARENT_SID    NUMBER(10, 0)    NOT NULL,
    DESCRIPTION            VARCHAR2(255)    NOT NULL,
    CONSTRAINT PK97 PRIMARY KEY (TRASH_SID)
)
;

ALTER TABLE TRASH ADD CONSTRAINT RefCSR_USER160 
    FOREIGN KEY (TRASHED_BY_SID)
    REFERENCES CSR_USER(CSR_USER_SID)
;



declare
	v_act varchar(38);
	v_sid number(36);
    v_trashId	number(10);
v_admins number(10);
    CURSOR c IS
	    select sid_id,parent_sid_id from securable_object where lower(name) = 'csr' and class_id = 277895;
begin
	v_trashId := class_pkg.GetClassId('TrashCan');
	user_pkg.logonauthenticatedpath(0,'//builtin/administrator',500,v_act);
	FOR r IN c loop
	v_admins := securableobject_pkg.GetSIDFromPath(v_act,r.parent_sid_id,'groups/administrators');
		securableobject_pkg.createSo(v_act, r.sid_id, v_trashId, 'Trash', v_sid);
	acl_pkg.AddACE(v_act, acl_pkg.GetDACLIDForSID(v_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_admins, security_pkg.PERMISSION_STANDARD_ALL + 65536);
    End Loop;
end;
/



BEGIN
UPDATE SHEET_ACTION SET DESCRIPTION= 'Data being entered' WHERE SHEET_ACTION_ID = 0; 
UPDATE SHEET_ACTION SET DESCRIPTION='Pending approval' WHERE SHEET_ACTION_ID = 1 ; 
UPDATE SHEET_ACTION SET DESCRIPTION='Returned' WHERE SHEET_ACTION_ID = 2; 
UPDATE SHEET_ACTION SET DESCRIPTION='Accepted' WHERE SHEET_ACTION_ID = 3 ; 
UPDATE SHEET_ACTION SET DESCRIPTION='Amended' WHERE SHEET_ACTION_ID = 4 ; 
UPDATE SHEET_ACTION SET DESCRIPTION= 'Rejected' WHERE SHEET_ACTION_ID = 5; 
UPDATE SHEET_ACTION SET DESCRIPTION='Accepted with modifications' WHERE SHEET_ACTION_ID = 6 ; 
UPDATE SHEET_ACTION SET DESCRIPTION='Partially submitted' WHERE SHEET_ACTION_ID = 7 ; 
UPDATE SHEET_ACTION SET DESCRIPTION='Partially authorised' WHERE SHEET_ACTION_ID = 8; 
UPDATE SHEET_ACTION SET DESCRIPTION='Merged with main database' WHERE SHEET_ACTION_ID = 9 ;
END; 
/

CREATE or replace VIEW DELEGATION_DELEGATOR AS
SELECT d.DELEGATION_SID, du.USER_SID DELEGATOR_SID
FROM delegation d, delegation_user du
WHERE d.parent_sid = du.delegation_sid
;

CREATE or replace VIEW SHEET_WITH_LAST_ACTION AS
SELECT SH.SHEET_ID, SH.DELEGATION_SID, SH.START_DTM, SH.END_DTM, SH.REMINDER_DTM, SH.SUBMISSION_DTM, SHE.SHEET_ACTION_ID LAST_ACTION_ID, SHE.FROM_USER_SID LAST_ACTION_FROM_USER_SID, SHE.ACTION_DTM LAST_ACTION_DTM, SHE.NOTE LAST_ACTION_NOTE, SHE.TO_DELEGATION_SID LAST_ACTION_TO_DELEGATION_SID
FROM SHEET_HISTORY SHE, SHEET SH
WHERE SH.LAST_SHEET_HISTORY_ID = SHE.SHEET_HISTORY_ID AND SHE.SHEET_ID = SH.SHEET_ID
 AND SHE.SHEET_ID = SH.SHEET_ID AND SH.LAST_SHEET_HISTORY_ID = SHE.SHEET_HISTORY_ID
;




-- corrects screwed up last_sheet_value_change stuff
     update sheet_value
        set last_Sheet_value_change_id = null
      where sheet_value_id in      
      (select sv.sheet_value_Id 
        from sheet_value sv, sheet_value_change svc, sheet_value svc_sv
       WHERE sv.last_sheet_value_change_id = svc.sheet_value_change_id
         and svc.sheet_value_id = svc_sv.sheet_value_id
         and svc_Sv.sheet_id != sv.sheet_id)

@update_tail
