-- Please update version.sql too -- this keeps clean builds in sync
define version=208
@update_header

begin
	for r in (select table_name, constraint_name
				from user_constraints
			   where table_name IN (
			   		'REPORTING_PERIOD', 
			   		'CUSTOMER') 
			   	 and constraint_name in (
			   		'REFCUSTOMER659',
					'FK_CUST_REG_ROOT_REGION',
					'FK_CUST_IND_ROOT_IND',
					'REFREPORTING_PERIOD658')) loop
		execute immediate 'alter table '||r.table_name||' drop constraint '||r.constraint_name;
	end loop;
end;
/

begin
	for r in (select column_name
				from user_tab_columns
			   where table_name = 'CUSTOMER' and nullable='N' and column_name IN (
			   		'CURRENT_REPORTING_PERIOD_SID',
			   		'IND_ROOT_SID',
			   		'REGION_ROOT_SID')) loop
		execute immediate 'alter table customer modify '||r.column_name||' null';
	end loop;
end;
/

ALTER TABLE REPORTING_PERIOD ADD CONSTRAINT RefCUSTOMER659 
    FOREIGN KEY (APP_SID)
    REFERENCES CUSTOMER(APP_SID)
;

ALTER TABLE CUSTOMER ADD CONSTRAINT RefREPORTING_PERIOD658 
    FOREIGN KEY (CURRENT_REPORTING_PERIOD_SID)
    REFERENCES REPORTING_PERIOD(REPORTING_PERIOD_SID)
;

ALTER TABLE CUSTOMER ADD CONSTRAINT FK_CUST_IND_ROOT_IND 
    FOREIGN KEY (IND_ROOT_SID)
    REFERENCES IND(IND_SID)
;

ALTER TABLE CUSTOMER ADD CONSTRAINT FK_CUST_REG_ROOT_REGION 
    FOREIGN KEY (REGION_ROOT_SID)
    REFERENCES REGION(REGION_SID)
;

ALTER TABLE CUSTOMER ADD CHECK 
	(CURRENT_REPORTING_PERIOD_SID IS NOT NULL) 
	DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE CUSTOMER ADD CHECK 
	(REGION_ROOT_SID IS NOT NULL) 
	DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE CUSTOMER ADD CHECK 
	(IND_ROOT_SID IS NOT NULL) 
	DEFERRABLE INITIALLY DEFERRED;

@update_tail

