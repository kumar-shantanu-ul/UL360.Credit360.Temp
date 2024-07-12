-- Please update version.sql too -- this keeps clean builds in sync
define version=3071
define minor_version=10
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
drop package csr.as2_pkg;
drop table csr.as2_inbound_receipt cascade constraints;
drop table csr.batch_job_as2_outbound_message cascade constraints;
drop table csr.batch_job_as2_outbound_receipt cascade constraints;
drop table CSR.AS2_OUTBOUND_MESSAGE cascade constraints
drop table CSR.AS2_OUTBOUND_RECEIPT
-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../batch_job_pkg

@update_tail
