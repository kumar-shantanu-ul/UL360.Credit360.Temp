define version=22
@update_header

alter table customer_options add login_page_message varchar2(4000);

@../chain_pkg
@../chain_body

@update_tail
