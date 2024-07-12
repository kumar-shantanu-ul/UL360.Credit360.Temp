define version=23
@update_header

alter table customer_options add INVITE_FROM_NAME_ADDENDUM varchar2(4000);

@../chain_pkg
@../chain_body

@update_tail
