-- create new tables  (Scheme_field and donation_doc)

-- 


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
	(APP_SID, FIELD_NUM_SCHEME_SID)
	select s.app_sid, cf.field_num, s.scheme_sid
	  from custom_field cf, scheme s
	 where cf.scheme_sid = s.scheme_sid;	

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
	select app_sid, 11, 'Cash', null, 1, null, 'cash_value', 1, null, 'cash', 1 from (select distinct app_sid from scheme where show_cash = 1);
	INSERT INTO CUSTOM_FIELD (APP_SID, FIELD_NUM, LABEL, EXPR, IS_MANDATORY, NOTE, LOOKUP_KEY, IS_CURRENCY, DETAILED_NOTE, SECTION, POS)
	select app_sid, 12, 'Number of staff', null, 0, null, 'staff_qty', 0, null, 'time', 2 from (select distinct app_sid from scheme where show_time = 1);
	INSERT INTO CUSTOM_FIELD (APP_SID, FIELD_NUM, LABEL, EXPR, IS_MANDATORY, NOTE, LOOKUP_KEY, IS_CURRENCY, DETAILED_NOTE, SECTION, POS)
	select app_sid, 13, 'Total hours', null, 0, null, 'time_hours', 0, null, 'time',3  from (select distinct app_sid from scheme where show_time = 1);
	INSERT INTO CUSTOM_FIELD (APP_SID, FIELD_NUM, LABEL, EXPR, IS_MANDATORY, NOTE, LOOKUP_KEY, IS_CURRENCY, DETAILED_NOTE, SECTION, POS)
	select app_sid, 14, 'Value of staff time', null, 0, null, 'time_value', 1, null, 'time', 4 from (select distinct app_sid from scheme where show_time = 1);
	INSERT INTO CUSTOM_FIELD (APP_SID, FIELD_NUM, LABEL, EXPR, IS_MANDATORY, NOTE, LOOKUP_KEY, IS_CURRENCY, DETAILED_NOTE, SECTION, POS)
	select app_sid, 15, 'Value of in-kind"', null, 0, null, 'inkind_value', 1, null, 'inkind', 5 from (select distinct app_sid from scheme where show_in_kind = 1);
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

