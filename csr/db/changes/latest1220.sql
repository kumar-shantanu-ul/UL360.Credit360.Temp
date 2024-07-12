-- Please update version.sql too -- this keeps clean builds in sync
define version=1220
@update_header


CREATE TABLE CT.PS_EMISSIONS (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    BREAKDOWN_ID NUMBER(10) NOT NULL,
    REGION_ID NUMBER(10) NOT NULL,
    EIO_ID NUMBER(10) NOT NULL,
    CALCULATION_SOURCE_ID NUMBER(10) NOT NULL,
    KG_CO2 NUMBER(30,10) NOT NULL,
    CONSTRAINT PK_PS_EM PRIMARY KEY (APP_SID, BREAKDOWN_ID, REGION_ID, EIO_ID, CALCULATION_SOURCE_ID)
);

ALTER TABLE CT.PS_EMISSIONS ADD CONSTRAINT CC_PS_EM_KG_CO2 
    CHECK (KG_CO2 >= 0);
	

ALTER TABLE CT.PS_EMISSIONS ADD CONSTRAINT B_R_PS_EM 
    FOREIGN KEY (APP_SID, BREAKDOWN_ID, REGION_ID) REFERENCES CT.BREAKDOWN_REGION (APP_SID,BREAKDOWN_ID,REGION_ID);

ALTER TABLE CT.PS_EMISSIONS ADD CONSTRAINT EIO_PS_EM 
    FOREIGN KEY (EIO_ID) REFERENCES CT.EIO (EIO_ID);

ALTER TABLE CT.PS_EMISSIONS ADD CONSTRAINT CALCULATION_SOURCE_PS_EM 
    FOREIGN KEY (CALCULATION_SOURCE_ID) REFERENCES CT.CALCULATION_SOURCE (CALCULATION_SOURCE_ID);

	
ALTER TABLE CT.PERIOD
 ADD (START_DATE  DATE);

ALTER TABLE CT.PERIOD
 ADD (END_DATE  DATE);
 
UPDATE CT.PERIOD SET start_date = TO_DATE('01/01/2002', 'dd/mm/yyyy'), end_date = TO_DATE('01/01/2003', 'dd/mm/yyyy') WHERE period_id = 1;
UPDATE CT.PERIOD SET start_date = TO_DATE('01/01/2003', 'dd/mm/yyyy'), end_date = TO_DATE('01/01/2004', 'dd/mm/yyyy') WHERE period_id = 2;
UPDATE CT.PERIOD SET start_date = TO_DATE('01/01/2004', 'dd/mm/yyyy'), end_date = TO_DATE('01/01/2005', 'dd/mm/yyyy') WHERE period_id = 3;
UPDATE CT.PERIOD SET start_date = TO_DATE('01/01/2005', 'dd/mm/yyyy'), end_date = TO_DATE('01/01/2006', 'dd/mm/yyyy') WHERE period_id = 4;
UPDATE CT.PERIOD SET start_date = TO_DATE('01/01/2006', 'dd/mm/yyyy'), end_date = TO_DATE('01/01/2007', 'dd/mm/yyyy') WHERE period_id = 5;
UPDATE CT.PERIOD SET start_date = TO_DATE('01/01/2007', 'dd/mm/yyyy'), end_date = TO_DATE('01/01/2008', 'dd/mm/yyyy') WHERE period_id = 6;
UPDATE CT.PERIOD SET start_date = TO_DATE('01/01/2008', 'dd/mm/yyyy'), end_date = TO_DATE('01/01/2009', 'dd/mm/yyyy') WHERE period_id = 7;
UPDATE CT.PERIOD SET start_date = TO_DATE('01/01/2009', 'dd/mm/yyyy'), end_date = TO_DATE('01/01/2010', 'dd/mm/yyyy') WHERE period_id = 8;
UPDATE CT.PERIOD SET start_date = TO_DATE('01/01/2010', 'dd/mm/yyyy'), end_date = TO_DATE('01/01/2011', 'dd/mm/yyyy') WHERE period_id = 9;
UPDATE CT.PERIOD SET start_date = TO_DATE('01/01/2011', 'dd/mm/yyyy'), end_date = TO_DATE('01/01/2012', 'dd/mm/yyyy') WHERE period_id = 10;
UPDATE CT.PERIOD SET start_date = TO_DATE('01/01/2012', 'dd/mm/yyyy'), end_date = TO_DATE('01/01/2013', 'dd/mm/yyyy') WHERE period_id = 11;
 
ALTER TABLE CT.PERIOD
MODIFY(START_DATE  NOT NULL);

ALTER TABLE CT.PERIOD
MODIFY(END_DATE  NOT NULL);

ALTER TABLE CT.PS_OPTIONS
ADD (PERIOD_ID NUMBER(10));

BEGIN

	FOR r IN (
		SELECT period_id, app_sid FROM ct.company
	)
	LOOP
		UPDATE ct.ps_options SET period_id = r.period_id WHERE app_sid = r.app_sid;
	END LOOP;

END;
/

ALTER TABLE CT.PS_OPTIONS ADD CONSTRAINT PERIOD_PS_OPT 
    FOREIGN KEY (PERIOD_ID) REFERENCES CT.PERIOD (PERIOD_ID);
 
@..\ct\ct_pkg.sql  
@..\ct\hotspot_pkg.sql  
@..\ct\breakdown_pkg.sql  
@..\ct\products_services_pkg.sql  
@..\ct\value_chain_report_pkg.sql  

@..\ct\breakdown_body.sql  
@..\ct\breakdown_type_body.sql  
@..\ct\supplier_body.sql  
@..\ct\business_travel_body.sql  
@..\ct\emp_commute_body.sql  
@..\ct\hotspot_body.sql  
@..\ct\products_services_body.sql  
@..\ct\value_chain_report_body.sql  

@..\ct\rls

	
@update_tail