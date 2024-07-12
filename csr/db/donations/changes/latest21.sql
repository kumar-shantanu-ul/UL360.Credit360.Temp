VARIABLE version NUMBER
BEGIN :version := 21; END; -- CHANGE THIS TO MATCH VERSION NUMBER
/

WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE
	v_version	version.db_version%TYPE;
BEGIN
	SELECT db_version INTO v_version FROM donations.version;
	IF v_version >= :version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||:version||' HAS ALREADY BEEN APPLIED =======');
	END IF;
	IF v_version + 1 <> :version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||:version||' CANNOT BE APPLIED TO A DATABASE OF VERSION '||v_version||' =======');
	END IF;
END;
/



-- add pos column to custom field
ALTER TABLE CUSTOM_FIELD ADD (POS NUMBER(10) DEFAULT 0 NOT NULL);

-- muck around with custom fields
declare
	v_check number(10);
begin
	select count(*) 
      into v_check
	  from (
		 select app_sid, field_num
		   from (
			 select s.app_sid, cf.field_num, label, count(*)
			   from custom_field cf, scheme s
			  where cf.scheme_sid = s.scheme_sid
			  group by s.app_sid, cf.field_num, label
			  order by app_sid, cf.field_num
			)
		  group by app_sid, field_num
		 having count(*) > 1
	 );
	IF v_check > 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Scheme/custom field setup means that scheme changes will corrupt data. Ask Richard!');	
	END IF;
end;
/



-- 
-- TABLE: SCHEME_FIELD 
--

CREATE TABLE SCHEME_FIELD(
    APP_SID       NUMBER(10, 0)    NOT NULL,
    FIELD_NUM     NUMBER(2, 0)     NOT NULL,
    SCHEME_SID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK93 PRIMARY KEY (APP_SID, FIELD_NUM, SCHEME_SID)
)
;


-- move the old scheme data over
INSERT INTO SCHEME_FIELD
	(APP_SID, FIELD_NUM, SCHEME_SID)
	select s.app_sid, cf.field_num, s.scheme_sid
	  from custom_field cf, scheme s
	 where cf.scheme_sid = s.scheme_sid;	


-- alter custom fields so that they're per APP not per SCHEME

ALTER TABLE CUSTOM_FIELD DROP CONSTRAINT PK76;

DROP INDEX PK76;

DROP INDEX AK_CUSTOM_VALUE;

ALTER TABLE CUSTOM_FIELD DROP CONSTRAINT REFSCHEME107;

ALTER TABLE CUSTOM_FIELD ADD (SCHEME_SID_2 NUMBER(10) NULL);

UPDATE CUSTOM_FIELD SET SCHEME_SID_2 = SCHEME_SID;

ALTER TABLE CUSTOM_FIELD MODIFY SCHEME_SID NULL;

ALTER TABLE CUSTOM_FIELD RENAME COLUMN SCHEME_SID TO APP_SID;

UPDATE CUSTOM_FIELD CF SET APP_SID = (SELECT APP_SID FROM SCHEME S WHERE S.SCHEME_SID = CF.SCHEME_SID_2);

ALTER TABLE CUSTOM_FIELD MODIFY APP_SID NOT NULL;

ALTER TABLE CUSTOM_FIELD DROP COLUMN SCHEME_SID_2;

-- delete dupes
delete from custom_field where rowid in (
  select rid 
    from (
		select rowid rid, ROW_NUMBER() OVER (PARTITION BY app_sid, field_num ORDER BY app_sid, field_num) rn
		  from custom_field
	) 
    where rn > 1
);
	 

CREATE UNIQUE INDEX AK_CUSTOM_VALUE ON CUSTOM_FIELD(APP_SID, LOOKUP_KEY);

ALTER TABLE CUSTOM_FIELD ADD 
    CONSTRAINT PK76 PRIMARY KEY (APP_SID, FIELD_NUM);


ALTER TABLE DONATION ADD (
	CUSTOM_11 NUMBER(16,2) NULL,
	CUSTOM_12 NUMBER(16,2) NULL,
	CUSTOM_13 NUMBER(16,2) NULL,
	CUSTOM_14 NUMBER(16,2) NULL,
	CUSTOM_15 NUMBER(16,2) NULL,
	CUSTOM_16 NUMBER(16,2) NULL,
	CUSTOM_17 NUMBER(16,2) NULL,
	CUSTOM_18 NUMBER(16,2) NULL,
	CUSTOM_19 NUMBER(16,2) NULL,
	CUSTOM_20 NUMBER(16,2) NULL
);



-- insert into custom_field table
begin
	UPDATE DONATION SET 
		CUSTOM_11 = CASH_VALUE,
		CUSTOM_12 = TIME_STAFF_QTY,
		CUSTOM_13 = TIME_HOURS,
		CUSTOM_14 = TIME_VALUE,
		CUSTOM_15 = IN_KIND_VALUE,
		CUSTOM_16 = LEVERAGE_VALUE;
	UPDATE CUSTOM_FIELD SET POS = 7; -- make sure the old static fields appear first
	INSERT INTO CUSTOM_FIELD (APP_SID, FIELD_NUM, LABEL, EXPR, IS_MANDATORY, NOTE, LOOKUP_KEY, IS_CURRENCY, DETAILED_NOTE, SECTION, POS)
	select app_sid, 11, 'Cash value', null, 1, null, 'cash_value', 1, null, 'cash', 1 from (select distinct app_sid from scheme where show_cash = 1);
	INSERT INTO CUSTOM_FIELD (APP_SID, FIELD_NUM, LABEL, EXPR, IS_MANDATORY, NOTE, LOOKUP_KEY, IS_CURRENCY, DETAILED_NOTE, SECTION, POS)
	select app_sid, 12, 'Number of staff', null, 0, null, 'staff_qty', 0, null, 'time', 2 from (select distinct app_sid from scheme where show_time = 1);
	INSERT INTO CUSTOM_FIELD (APP_SID, FIELD_NUM, LABEL, EXPR, IS_MANDATORY, NOTE, LOOKUP_KEY, IS_CURRENCY, DETAILED_NOTE, SECTION, POS)
	select app_sid, 13, 'Total hours', null, 0, null, 'time_hours', 0, null, 'time',3  from (select distinct app_sid from scheme where show_time = 1);
	INSERT INTO CUSTOM_FIELD (APP_SID, FIELD_NUM, LABEL, EXPR, IS_MANDATORY, NOTE, LOOKUP_KEY, IS_CURRENCY, DETAILED_NOTE, SECTION, POS)
	select app_sid, 14, 'Value of staff time', null, 0, null, 'time_value', 1, null, 'time', 4 from (select distinct app_sid from scheme where show_time = 1);
	INSERT INTO CUSTOM_FIELD (APP_SID, FIELD_NUM, LABEL, EXPR, IS_MANDATORY, NOTE, LOOKUP_KEY, IS_CURRENCY, DETAILED_NOTE, SECTION, POS)
	select app_sid, 15, 'Value of in-kind', null, 0, null, 'inkind_value', 1, null, 'inkind', 5 from (select distinct app_sid from scheme where show_in_kind = 1);
	INSERT INTO CUSTOM_FIELD (APP_SID, FIELD_NUM, LABEL, EXPR, IS_MANDATORY, NOTE, LOOKUP_KEY, IS_CURRENCY, DETAILED_NOTE, SECTION, POS)
	select app_sid, 16, 'Leverage value', null, 0, null, 'leverage_value', 1, null, 'leverage', 6 from (select distinct app_sid from scheme where show_leverage = 1);
end;
/


-- 
-- TABLE: SCHEME_FIELD 
--

ALTER TABLE SCHEME_FIELD ADD CONSTRAINT RefSCHEME125 
    FOREIGN KEY (SCHEME_SID)
    REFERENCES SCHEME(SCHEME_SID)
;


ALTER TABLE SCHEME_FIELD ADD CONSTRAINT RefCUSTOM_FIELD126 
    FOREIGN KEY (APP_SID, FIELD_NUM)
    REFERENCES CUSTOM_FIELD(APP_SID, FIELD_NUM)
;

-- insert into scheme_field table
begin
	INSERT INTO SCHEME_FIELD
		(app_sid, scheme_sid, field_num)
		SELECT app_sid, scheme_sid, 11 FROM scheme WHERE show_cash = 1;	
	INSERT INTO SCHEME_FIELD
		(app_sid, scheme_sid, field_num)
		SELECT app_sid, scheme_sid, 12 FROM scheme WHERE show_time = 1;
	INSERT INTO SCHEME_FIELD
		(app_sid, scheme_sid, field_num)
		SELECT app_sid, scheme_sid, 13 FROM scheme WHERE show_time = 1;
	INSERT INTO SCHEME_FIELD
		(app_sid, scheme_sid, field_num)
		SELECT app_sid, scheme_sid, 14 FROM scheme WHERE show_time = 1;
	INSERT INTO SCHEME_FIELD
		(app_sid, scheme_sid, field_num)
		SELECT app_sid, scheme_sid, 15 FROM scheme WHERE show_in_kind = 1;
	INSERT INTO SCHEME_FIELD
		(app_sid, scheme_sid, field_num)
		SELECT app_sid, scheme_sid, 16 FROM scheme WHERE show_leverage = 1;
end;
/

begin
	update custom_field 
	   set note = 'Include additional costs associated with a project, such as payments for materials used in volunteering, paying third party people to provide assistance. ONLY INCLUDE cash contributions from Virgin Media',
		detailed_note = 'Cash amounts may include direct donations to national or local appeals and sponsorship of causes or events'
	 where field_num = (
		select field_num from custom_field cf, csr.customer c where cf.app_sid  = c.app_sid and c.host='virginmedia.credit360.com' and  lookup_key = 'cash_value'
	) and app_sid =3534362;
	update custom_field 
	   set note = 'DO NOT INCLUDE outsourced employees'', temps'' or contractors'' time',
		detailed_note = 'nter the number of staff who have participated in the activity during work time.'
	 where field_num = (
		select field_num from custom_field cf, csr.customer c where cf.app_sid  = c.app_sid and c.host='virginmedia.credit360.com' and  lookup_key = 'staff_qty'
	) and app_sid =3534362;
	update custom_field 
	   set note = 'DO NOT INCLUDE outsourced employees'', temps'' or contractors'' time',
		detailed_note = 'Enter the total number of hours volunteered by staff during work time.'
	 where field_num = (
		select field_num from custom_field cf, csr.customer c where cf.app_sid  = c.app_sid and c.host='virginmedia.credit360.com' and  lookup_key = 'time_hours'
	) and app_sid =3534362;
	update custom_field 
	   set detailed_note = 'Approximate value of in-kind contributions (given to the charity by the company - NOT STAFF.'
	 where field_num = (
		select field_num from custom_field cf, csr.customer c where cf.app_sid  = c.app_sid and c.host='virginmedia.credit360.com' and  lookup_key = 'inkind_value'
	) and app_sid =3534362;
end;
/


begin
update custom_field set label='Cash contribution from company' where app_sid = 3534362 and field_num = 11;
update custom_field set label='Number of staff involved during company time' where app_sid = 3534362 and field_num = 12;
update custom_field set label='Total hours volunteered in company time' where app_sid = 3534362 and field_num = 13;
update custom_field set label='Value of time given' where app_sid = 3534362 and field_num = 14;
update custom_field set label='Approximate value of in-kind contributions' where app_sid = 3534362 and field_num = 15;
delete from scheme_field where field_num in (14,16) and scheme_sid = 4533133;
update custom_field set pos = 7+field_num where field_num in (1,2,3,4,6,7,8) and app_sid = 3534362;
end;
/

commit;

/*
ALTER TABLE DONATION DROP COLUMN CASH_VALUE;
ALTER TABLE DONATION DROP COLUMN IN_KIND_VALUE;
ALTER TABLE DONATION DROP COLUMN LEVERAGE_VALUE;
ALTER TABLE DONATION DROP COLUMN TIME_VALUE;
ALTER TABLE DONATION DROP COLUMN TIME_STAFF_QTY;
ALTER TABLE DONATION DROP COLUMN TIME_HOURS;

ALTER TABLE SCHEME DROP COLUMN SHOW_CASH;
ALTER TABLE SCHEME DROP COLUMN SHOW_TIME;
ALTER TABLE SCHEME DROP COLUMN SHOW_IN_KIND;
ALTER TABLE SCHEME DROP COLUMN SHOW_LEVERAGE;
*/



UPDATE donations.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT


