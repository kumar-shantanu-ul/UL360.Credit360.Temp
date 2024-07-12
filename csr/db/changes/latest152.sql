-- Please update version.sql too -- this keeps clean builds in sync
define version=152
@update_header

-- add fk constraints to customer_alert_type
/*
ALTER TABLE CUSTOMER_ALERT_TYPE ADD CONSTRAINT RefALERT_TYPE647 
    FOREIGN KEY (ALERT_TYPE_ID)
    REFERENCES ALERT_TYPE(ALERT_TYPE_ID)
;

ALTER TABLE CUSTOMER_ALERT_TYPE ADD CONSTRAINT RefCUSTOMER648 
    FOREIGN KEY (CSR_ROOT_SID)
    REFERENCES CUSTOMER(CSR_ROOT_SID)
;
*/
-- drop existing constraints on alert_template
alter table alert_template drop constraint REFALERT_TYPE188;
alter table alert_template drop constraint REFCUSTOMER308;

-- clear out junk data, and add in data that will match that required by the new RI constraints
delete from customer_alert_type;

insert into customer_alert_type (csr_root_sid, alert_type_id)
 select distinct csr_root_sid, alert_type_id
   from alert_template;

ALTER TABLE ALERT_TEMPLATE ADD CONSTRAINT RefCUSTOMER_ALERT_TYPE645 
    FOREIGN KEY (CSR_ROOT_SID, ALERT_TYPE_ID)
    REFERENCES CUSTOMER_ALERT_TYPE(CSR_ROOT_SID, ALERT_TYPE_ID)
;

-- now add in standard alerts for all csr customers (1 -> 5)
INSERT INTO customer_alert_type (csr_root_sid, alert_type_id)
	SELECT distinct csr_root_Sid, alert_type_id 
	  FROM customer, alert_type 
	 WHERE alert_type_id BETWEEN 1 AND 5
	 MINUS 
	SELECT csr_Root_sid, alert_type_id
	  FROM customer_alert_type;

-- add in alerts for people on pending delegations (9 -> 17)
INSERT INTO customer_alert_type (csr_root_sid, alert_type_id)
	SELECT distinct csr_root_Sid, alert_type_id 
	  FROM pending_Dataset, alert_type 
	 WHERE alert_type_id BETWEEN 9 AND 17
	 MINUS 
	SELECT csr_Root_sid, alert_type_id
	  FROM customer_alert_type;


-- add in alerts for document library customers (19)
INSERT INTO customer_alert_type (csr_root_sid, alert_type_id)
	SELECT distinct csr_root_Sid, alert_type_id 
	  FROM doc_library, alert_type 
	 WHERE alert_type_id = 19
	 MINUS 
	SELECT csr_Root_sid, alert_type_id
	  FROM customer_alert_type;
	  
	  
-- add in alerts for supplier module customers (1000 -> 1003)
INSERT INTO customer_alert_type (csr_root_sid, alert_type_id)
	SELECT distinct csr_root_Sid, alert_type_id 
	  FROM supplier.all_company, alert_type
	 WHERE alert_type_id BETWEEN 1000 AND 1003
	 MINUS 
	SELECT csr_Root_sid, alert_type_id
	  FROM customer_alert_type;

-- some other random changes
begin
--INSERT INTO SOURCE_TYPE ( SOURCE_TYPE_ID, DESCRIPTION) VALUES (7, 'New delegations');
INSERT INTO SOURCE_TYPE ( SOURCE_TYPE_ID, DESCRIPTION) VALUES (8, 'Meter');
end;
/

commit;

@..\alert_body
@..\csr_data_pkg
@..\csr_data_body
@..\meter_pkg
@..\meter_body
@..\..\..\aspen2\tools\recompile_packages.sql

	  
	  
@update_tail