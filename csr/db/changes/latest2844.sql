-- Please update version.sql too -- this keeps clean builds in sync
define version=2844
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
alter table csr.customer add include_nulls_in_ta number(1) default 0 not null;
update csr.customer set include_nulls_in_ta = 1;
alter table csr.customer add constraint ck_customer_incl_nulls_in_ta check (include_nulls_in_ta in (0,1));

alter table csrimp.customer add include_nulls_in_ta number(1) not null;
alter table csrimp.customer add constraint ck_customer_incl_nulls_in_ta check (include_nulls_in_ta in (0,1));

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
@../customer_body
@../schema_body
@../csrimp/imp_body

@update_tail
