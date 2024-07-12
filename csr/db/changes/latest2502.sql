-- Please update version.sql too -- this keeps clean builds in sync
define version=2502
@update_header

grant select,insert on csr.rss_cache to csrimp;

alter table chain.customer_options add (override_manage_co_path varchar2(2000));
-- set to the existing location of the hard-coded path
update chain.customer_options set override_manage_co_path = '/csr/site/chain/supplierDetails.acds';

@../chain/helper_body

@update_tail
