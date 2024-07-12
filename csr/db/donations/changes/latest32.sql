-- Please update version.sql too -- this keeps clean builds in sync
define version=32
@update_header

-- loosen up constraints etc
alter table DONATION drop constraint REFDONATION_STATUS52;
alter table LETTER_BODY_TEXT drop constraint REFDONATION_STATUS95;
alter table LETTER_BODY_REGION_GROUP drop constraint RefLETTER_BODY_TEXT93;
ALTER TABLE LETTER_BODY_REGION_GROUP DROP CONSTRAINT RefREGION_GROUP94;
alter table donation_status drop constraint ENTITY1PK;
ALTER TABLE LETTER_BODY_REGION_GROUP DROP CONSTRAINT PK62;
ALTER TABLE LETTER_BODY_TEXT DROP CONSTRAINT PK60;

drop index ENTITY1PK;
DROP index PK62;
DROP index PK60;

-- add our new sid column - we'll drop the id later
ALTER TABLE DONATION_STATUS ADD (DONATION_STATUS_SID  NUMBER(10,0));


-- add donation_status_sid columns (we'll drop the donation_status_id later if the update goes ok)
ALTER TABLE DONATION ADD (DONATION_STATUS_SID NUMBER(10,0));
ALTER TABLE LETTER_BODY_TEXT ADD (DONATION_STATUS_SID  NUMBER(10,0));
ALTER TABLE LETTER_BODY_REGION_GROUP ADD (DONATION_STATUS_SID  NUMBER(10,0));

-- more columns on donations table (nullable for now)
ALTER TABLE DONATION ADD (LAST_STATUS_CHANGED_DTM DATE);
ALTER TABLE DONATION ADD (LAST_STATUS_CHANGED_BY NUMBER(10,0));

-- extra flag on the whackily named filter_flag table
ALTER TABLE CUSTOMER_FILTER_FLAG ADD (AUTO_GEN_STATUS_TRANSITION NUMBER(1) DEFAULT 1 NOT NULL);


-- create transition table and constraints
CREATE TABLE TRANSITION(
  TRANSITION_SID    NUMBER(10,0) NOT NULL,
	FROM_DONATION_STATUS_SID 		NUMBER(10,0) NOT NULL,
	TO_DONATION_STATUS_SID 			NUMBER(10,0) NOT NULL,
	APP_SID						NUMBER(10,0) NOT NULL
);



alter table donation_status modify (donation_status_id number(10,0) null);
alter table letter_body_text modify (donation_status_id number(10,0) null);
alter table letter_body_region_group modify (donation_status_id number(10,0) null);


-- we've now made all the schema changes etc, so recompile stored procs
PROMPT enter db connection (e.g. ASPEN):
connect csr/csr@&&1
@../../csr_data_pkg
@../../csr_data_body

grant execute on csr_data_pkg to donations;

connect donations/donations@&&1

-- recompile new packages
@../sys_pkg
@../status_pkg
@../budget_pkg
@../transition_pkg
@../scheme_pkg
@../sys_body
@../status_body
@../budget_body
@../transition_body
@../scheme_body


-- rebuild everything
@\cvs\aspen2\tools\recompile_packages.sql


-- create sec obj classes
DECLARE
	v_act_id			security_pkg.T_ACT_ID;
	v_class_id		security_pkg.T_SID_ID;

BEGIN	
	-- log on
	user_pkg.LogonAuthenticatedPath(0, '//builtin/administrator', 10000, v_act_id);
	-- status sec obj
	BEGIN
		class_pkg.CreateClass(v_act_id, NULL, 'DonationsStatus', 'donations.status_pkg', NULL, v_class_id);
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			null;
	END;
	-- transition sec obj
	BEGIN	
		class_pkg.CreateClass(v_act_id, NULL, 'DonationsTransition', 'donations.transition_pkg', NULL, v_class_id);
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
            v_class_id:=class_pkg.GetClassId('DonationsTransition');
	END;
	BEGIN	
		-- Transition
		class_pkg.AddPermission(v_act_id, v_class_id, donations.SCHEME_pkg.PERMISSION_TRANSITION_ALLOWED, 'Transition is allowed');
		class_pkg.CreateMapping(v_act_id, security_pkg.SO_CONTAINER, security_pkg.PERMISSION_READ, v_class_id, donations.SCHEME_pkg.PERMISSION_TRANSITION_ALLOWED);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	commit;
END;
/


GRANT EXECUTE ON donations.status_pkg TO SECURITY;
GRANT EXECUTE ON donations.transition_pkg TO SECURITY;

-- we're now ready to fix up the data

DECLARE
	v_act_id								security_pkg.T_ACT_ID;
	v_status_class_id				security_pkg.T_SID_ID; 
	-- donation status SO
	v_parent_sid						security_pkg.T_SID_ID;
	v_statuses_sid					security_pkg.T_SID_ID;
	v_donation_status_sid 	security_pkg.T_SID_ID;
	v_donations_sid					security_pkg.T_SID_ID;
	v_transitions_sid				security_pkg.T_SID_ID;
	v_transistion_sid				security_pkg.T_SID_ID;
BEGIN
	-- log on
	user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 600, v_act_id);	

	-- get class ids
	v_status_class_id:=class_pkg.GetClassId('DonationsStatus');

 	-- convert old donation_status to SO
	FOR c IN (SELECT DISTINCT c.app_sid FROM DONATION_STATUS ds, CSR.CUSTOMER c WHERE ds.app_sid = c.app_sid ORDER BY APP_SID)
	LOOP 
		v_donations_sid := securableobject_pkg.GetSIDFromPath(v_act_id, c.app_sid, 'Donations');	
		
		-- get/create securable object Donations/Status
		BEGIN
			SecurableObject_Pkg.CreateSO(v_act_id, v_donations_sid, security_pkg.SO_CONTAINER, 'Statuses', v_statuses_sid);
		EXCEPTION
			WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
				v_statuses_sid := securableobject_pkg.GetSIDFromPath(v_act_id, c.app_sid, 'Donations/Statuses');
		END;
		
		-- get/create securable object Donations/Transitions
		BEGIN
			SecurableObject_Pkg.CreateSO(v_act_id, v_donations_sid, security_pkg.SO_CONTAINER, 'Transitions', v_transitions_sid);	
		EXCEPTION
			WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
				v_transitions_sid := securableobject_pkg.GetSIDFromPath(v_act_id, c.app_sid, 'Donations/Transitions');
		END;
		
		-- go through all statuses for current app_sid
		-- and convert current data to sids
		FOR r IN (SELECT donation_status_id, replace(description, '/', '\') description from DONATION_STATUS WHERE app_sid = c.app_sid)
		LOOP			
			-- create status/ ignore if already created
			BEGIN
				SecurableObject_Pkg.CreateSO(v_act_id, v_statuses_sid, v_status_class_id, r.description, v_donation_status_sid );
			EXCEPTION
				WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
					v_donation_status_sid := securableobject_pkg.GetSIDFromPath(v_act_id, c.app_sid, 'Donations/Statuses/' || r.description);
			END;
			-- update donation_status entry with new sid
			UPDATE DONATION_STATUS 
			   SET donation_status_sid = v_donation_status_sid 
			 WHERE donation_status_id = r.donation_status_id;
			 
			 -- update donations for new status object
			 UPDATE DONATION 
			    SET donation_status_sid = v_donation_status_sid
			   WHERE donation_status_id  = r.donation_status_id;
	
			 -- update letters for new status object	
			UPDATE LETTER_BODY_TEXT
					SET donation_status_sid = v_donation_status_sid 
				WHERE donation_status_id  = r.donation_status_id;
	
			-- update letters body region group for new status object	
			UPDATE LETTER_BODY_REGION_GROUP
					SET donation_status_sid = v_donation_status_sid 
				WHERE donation_status_id  = r.donation_status_id;
		END LOOP;
	END LOOP;
 
	-- now generate transitions for statuses
	FOR r IN (SELECT app_sid FROM CUSTOMER_FILTER_FLAG WHERE 	AUTO_GEN_STATUS_TRANSITION > 0)
	LOOP
		dbms_output.put_line('fixing app_sid '||r.app_sid);
		FOR t IN (
			select ds1.donation_status_sid from_status_sid,
					ds2.donation_status_sid to_status_sid
			  from donation_status ds1, donation_status ds2
			 where ds1.app_sid = r.app_sid
			   and ds2.app_sid = ds1.app_sid
			   and ds1.donation_status_sid != ds2.donation_Status_sid
			 minus 
			select from_donation_status_sid, to_donation_status_sid
			  from transition
		)
		LOOP
			transition_pkg.createTransition(t.from_status_sid, t.to_status_sid, r.app_sid, v_transistion_sid);			
		END LOOP;
	END LOOP;
	
	COMMIT;
END;
/

-- clean up any duff data
begin
	delete from letter_body_region_group where donation_status_sid is null;
	delete from letter_body_text where donation_status_sid is null;
	delete from donation_status where donation_status_sid is null;
	-- cleans up dupe names that aren't used	
	delete from donation_status
	 where donation_status_id in (
		select donation_status_id
		  from (
			select donation_status_id, ds.app_sid, host, description, count(*) over (partition by ds.app_sid, description) cnt
			  from donation_status ds, csr.customer c
			 where ds.app_sid = c.app_sid
		 )x
		where cnt > 1
		 and not exists (select 1 from donation d where d.donation_status_id = x.donation_status_id)
	);
	commit;
end;
/

alter table donation_status modify (donation_status_sid not null);
alter table letter_body_text modify (donation_status_sid not null);
alter table letter_body_region_group modify (donation_status_sid not null);



-- add back constraints on donation_status_sid
ALTER TABLE DONATION_STATUS ADD 
    CONSTRAINT Entity1PK PRIMARY KEY (DONATION_STATUS_SID);

-- change primary keys
ALTER TABLE LETTER_BODY_REGION_GROUP ADD
    CONSTRAINT PK62 PRIMARY KEY (REGION_GROUP_SID, LETTER_BODY_TEXT_ID, DONATION_STATUS_SID);

ALTER TABLE LETTER_BODY_TEXT ADD
    CONSTRAINT PK60 PRIMARY KEY (LETTER_BODY_TEXT_ID, DONATION_STATUS_SID);

-- add FK constraints
ALTER TABLE DONATION ADD CONSTRAINT RefDONATION_STATUS52 
    FOREIGN KEY (DONATION_STATUS_SID)
    REFERENCES DONATION_STATUS(DONATION_STATUS_SID);

ALTER TABLE LETTER_BODY_REGION_GROUP ADD CONSTRAINT RefLETTER_BODY_TEXT93 
    FOREIGN KEY (LETTER_BODY_TEXT_ID, DONATION_STATUS_SID)
    REFERENCES LETTER_BODY_TEXT(LETTER_BODY_TEXT_ID, DONATION_STATUS_SID);

ALTER TABLE LETTER_BODY_TEXT ADD CONSTRAINT RefDONATION_STATUS95 
    FOREIGN KEY (DONATION_STATUS_SID)
    REFERENCES DONATION_STATUS(DONATION_STATUS_SID);

ALTER TABLE LETTER_BODY_REGION_GROUP ADD CONSTRAINT RefREGION_GROUP94 
    FOREIGN KEY (REGION_GROUP_SID)
    REFERENCES REGION_GROUP(REGION_GROUP_SID);


ALTER TABLE TRANSITION ADD CONSTRAINT RefDONATION_STATUS129 
    FOREIGN KEY (TO_DONATION_STATUS_SID)
    REFERENCES DONATION_STATUS(DONATION_STATUS_SID);

ALTER TABLE TRANSITION ADD CONSTRAINT RefDONATION_STATUS130 
    FOREIGN KEY (FROM_DONATION_STATUS_SID)
    REFERENCES DONATION_STATUS(DONATION_STATUS_SID);



-- add some extra constraints against the CSR USER table
ALTER TABLE DONATION ADD CONSTRAINT RefCSR_USER134 
    FOREIGN KEY (LAST_STATUS_CHANGED_BY)
    REFERENCES CSR.CSR_USER(CSR_USER_SID)
;

-- hack for live data (Dickie imported o2 community against builtin/admin, so reassign to Vikki Leach)
update donation 
   set entered_by_sid = (
	select cu.csr_user_Sid from csr.csr_user cu, csr.customer c where host='telefonica.credit360.com'
	 and cu.app_sid = c.app_sid and full_name = 'Vikki Leach'
  ) where entered_by_sid = 3;

ALTER TABLE DONATION ADD CONSTRAINT RefCSR_USER135 
    FOREIGN KEY (ENTERED_BY_SID)
    REFERENCES CSR.CSR_USER(CSR_USER_SID)
;

ALTER TABLE USER_FIELDSET ADD CONSTRAINT RefCSR_USER136 
    FOREIGN KEY (CSR_USER_SID)
    REFERENCES CSR.CSR_USER(CSR_USER_SID)
;

-- don't need this any more
DROP SEQUENCE DONATION_STATUS_ID_SEQ;
ALTER TABLE DONATION DROP COLUMN DONATION_STATUS_ID;
ALTER TABLE LETTER_BODY_TEXT DROP COLUMN DONATION_STATUS_ID;
ALTER TABLE LETTER_BODY_REGION_GROUP DROP COLUMN DONATION_STATUS_ID;


-- rebuild everything
@\cvs\aspen2\tools\recompile_packages.sql


-- add flag per customer to distingish which are still on old donation version
alter table customer_filter_flag 
        add is_version_2_enabled number(1) default 1 not null ;

-- update for customers with old donations 
update customer_filter_flag 
   set is_version_2_enabled = 0 
 where app_sid in (
		select app_sid from csr.customer where host in (
			'oldmutual.credit360.com',
			'boots.credit360.com',
			'telefonica.credit360.com', 
			'mec.credit360.com',
			'produceworld.credit360.com',
			'www.sr-online.co.uk',
			'allianceboots.credit360.com',
			'bat.credit360.com',
			'lacaixa.credit360.com'
		)
);

COMMIT;


@update_tail
