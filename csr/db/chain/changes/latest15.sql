define version=15
@update_header

alter table chain.customer_options add (link_host varchar2(100));

@..\chain_pkg
@..\chain_body

@update_tail
