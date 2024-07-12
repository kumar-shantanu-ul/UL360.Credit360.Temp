-- Please update version.sql too -- this keeps clean builds in sync
define version=3446
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
DROP TABLE CSRIMP.CHAIN_BSCI_OPTIONS;
DROP TABLE CSRIMP.CHAIN_BSCI_SUPPLIER;
DROP TABLE CSRIMP.CHAIN_BSCI_SUPPLIER_DET;
DROP TABLE CSRIMP.CHAIN_BSCI_AUDIT;
DROP TABLE CSRIMP.CHAIN_BSCI_2009_AUDIT;
DROP TABLE CSRIMP.CHAIN_BSCI_2009_A_FINDING;
DROP TABLE CSRIMP.CHAIN_BSCI_2009_A_ASSOCIATE;
DROP TABLE CSRIMP.CHAIN_BSCI_2014_AUDIT;
DROP TABLE CSRIMP.CHAIN_BSCI_2014_A_FINDING;
DROP TABLE CSRIMP.CHAIN_BSCI_2014_A_ASSOCIATE;
DROP TABLE CSRIMP.CHAIN_BSCI_EXT_AUDIT;

DROP TABLE CSRIMP.MAP_CHAIN_BSCI_SUPPLIER;
DROP TABLE CSRIMP.MAP_CHAIN_BSCI_AUDIT;
DROP TABLE CSRIMP.MAP_CHAIN_BSCI_2009_AUDIT;
DROP TABLE CSRIMP.MAP_CHAIN_BSCI_2014_AUDIT;
DROP TABLE CSRIMP.MAP_CHAIN_BSCI_EXT_AUDIT;
DROP TABLE CSRIMP.MAP_CHAIN_BSCI_2009_A_FIND;
DROP TABLE CSRIMP.MAP_CHAIN_BSCI_2009_A_ASSOC;
DROP TABLE CSRIMP.MAP_CHAIN_BSCI_2014_A_FIND;
DROP TABLE CSRIMP.MAP_CHAIN_BSCI_2014_A_ASSOC;

DROP TABLE CHAIN.BSCI_OPTIONS;


-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
declare
   job_doesnt_exist EXCEPTION;
   PRAGMA EXCEPTION_INIT( job_doesnt_exist, -27475 );
begin
   dbms_scheduler.drop_job(job_name => 'chain.BsciImport');
exception when job_doesnt_exist then
   null;
end;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/bsci_pkg
@../csrimp/imp_pkg
@../schema_pkg

@../chain/bsci_body
@../chain/chain_body
@../csrimp/imp_body
@../schema_body

@update_tail
