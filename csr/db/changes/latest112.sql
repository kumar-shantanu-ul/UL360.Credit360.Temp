-- Please update version.sql too -- this keeps clean builds in sync
define version=112
@update_header

VARIABLE version NUMBER
BEGIN :version := 112; END; -- CHANGE THIS TO MATCH VERSION NUMBER
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


--TODO: can the current-year sec obj attribute (future objective!!)

ALTER TABLE CUSTOMER ADD (
    CURRENT_REPORTING_PERIOD_SID    NUMBER(10, 0)    
);

ALTER TABLE REPORTING_PERIOD ADD (
    CSR_ROOT_SID            NUMBER(10, 0) ,
    NAME                    VARCHAR2(255),
    START_DTM               DATE,    
    END_DTM                 DATE             
);


@\cvs\csr\db\reporting_period_pkg.sql
@\cvs\csr\db\reporting_period_body.sql

-- set start, end dates for existing reporting_periods / create reportingperiods sec obj container for each csrapp / create default reporting period
declare
	v_act					security_pkg.T_ACT_ID;
	v_reporting_periods_sid	security_pkg.T_SID_ID;
	v_sid					security_pkg.T_SID_ID;
	v_cnt					NUMBER(10);
begin
	user_pkg.LogonAuthenticatedPath(0, '//builtin/administrator', 10000, v_act);
	-- set the csr_root_sid, name, and dates for existing reporting period sids (there are very few of these on live - tough luck for other developers...!)
	for r in (
		select * from reporting_period
	)
	loop
		update reporting_period
	  	   set csr_root_sid = securableobject_pkg.GetParent(v_act, (securableobject_pkg.GetParent(v_act, r.reporting_period_sid))),
				name = securableobject_pkg.GetName(v_act, r.reporting_period_sid), start_dtm = '1 jan 2007', end_dtm = '1 jan 2008'
	 	 where reporting_period_sid = r.reporting_period_sid;
	end loop;
	-- now create ReportingPeriods objects
	for r in (
		select csr_root_sid,
			TO_DATE('01/'||
				LPAD(NVL(
					NVL(securableobject_pkg.GetNamedNumberAttribute(v_act, csr_root_sid, 'start-month'),
						TO_NUMBER(securableobject_pkg.GetNamedStringAttribute(v_act, csr_root_sid, 'start-month'))
					),1),2,'0')||'/'||
					NVL(securableobject_pkg.GetNamedNumberAttribute(v_act, csr_root_sid, 'current-year'),
						NVL(TO_NUMBER(securableobject_pkg.GetNamedStringAttribute(v_act, csr_root_sid, 'current-year'))
						,2008))
					,'DD/MM/yyyy') dtm
		from customer 
	)
	loop		
		begin
			v_reporting_periods_sid := securableobject_pkg.GetSIDFromPath(v_act, r.csr_root_sid, 'ReportingPeriods');
		exception
			when security_pkg.OBJECT_NOT_FOUND then
				-- create
				securableobject_pkg.createso(v_act, r.csr_root_sid, security_pkg.SO_CONTAINER, 'ReportingPeriods', v_reporting_periods_sid);
		end;			
		-- are there any reporting periods here?
		select count(*)
		  into v_cnt
		  from reporting_period
		 where csr_root_sid = r.csr_root_sid;
		if v_cnt = 0 then
			reporting_period_pkg.CreateReportingPeriod(v_act, r.csr_root_sid, '2008', r.dtm, add_months(r.dtm,12), v_sid);
		end if;
	end loop;
	-- now set the current_reporting_period_sid
	update customer 
       set current_reporting_period_sid = (
		select first_value (reporting_period_sid) over (partition by csr_root_sid order by start_dtm desc) 
		  from reporting_period rp
         where rp.csr_root_sid = customer.csr_root_sid
	 );
end;
/

-- shove on some constraints
ALTER TABLE CUSTOMER ADD CONSTRAINT RefREPORTING_PERIOD658 
    FOREIGN KEY (CURRENT_REPORTING_PERIOD_SID)
    REFERENCES REPORTING_PERIOD(REPORTING_PERIOD_SID)
	DEFERRABLE INITIALLY DEFERRED;


ALTER TABLE CUSTOMER MODIFY CURRENT_REPORTING_PERIOD_SID NOT NULL;

-- add our new show-all-sheets-for-current-reporting-period attributes
DECLARE
	v_act 			security_pkg.T_ACT_ID;
	v_attribute_id	security_pkg.T_ATTRIBUTE_ID;
BEGIN
	user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_ACT);
	-- do show-all-sheets-for-current-reporting-period	
	Attribute_Pkg.CreateDefinition(v_act, class_pkg.GetClassId('csrdata'), 'show-all-sheets-for-current-reporting-period', 0, NULL, v_attribute_id);
	FOR r IN (
		SELECT csr_root_Sid 
		  FROM customer
		 WHERE host IN ('sky.credit360.com')
	)
	LOOP
		Securableobject_Pkg.SetNamedNumberAttribute(v_act, r.csr_root_sid, 'show-all-sheets-for-current-reporting-period', 1);
	END LOOP;		
	-- now do dataexplorer-show-markers
	Attribute_Pkg.CreateDefinition(v_act, class_pkg.GetClassId('csrdata'), 'dataexplorer-show-markers', 0, NULL, v_attribute_id);
	FOR r IN (
		SELECT csr_root_Sid 
		  FROM customer
		 WHERE host IN ('hsbctest.credit360.com','rbsfm.credit360.com','mcdonalds.credit360.com','test.credit360.com','hsbc.credit360.com')
	)
	LOOP
		Securableobject_Pkg.SetNamedNumberAttribute(v_act, r.csr_root_sid, 'dataexplorer-show-markers', 1);
	END LOOP;		
END;
/

-- just in case - when I ran on live it had created a reporting period for "builtin"
delete from reporting_period where csr_root_Sid is null;

ALTER TABLE REPORTING_PERIOD MODIFY CSR_ROOT_SID NOT NULL;
ALTER TABLE REPORTING_PERIOD MODIFY NAME NOT NULL;
ALTER TABLE REPORTING_PERIOD MODIFY START_DTM NOT NULL;
ALTER TABLE REPORTING_PERIOD MODIFY END_DTM NOT NULL;

UPDATE csr.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT



@update_tail
