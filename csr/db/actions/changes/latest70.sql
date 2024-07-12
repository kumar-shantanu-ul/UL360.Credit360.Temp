-- Please update version.sql too -- this keeps clean builds in sync
define version=70
@update_header

connect security/security@&_CONNECT_IDENTIFIER
grant select on security.website to actions;
connect actions/actions@&_CONNECT_IDENTIFIER

alter table customer_options add initiatives_host varchar2(256);

----------------------
-- Note: remove for DT
----------------------
update customer_options set initiatives_host = 'rbsinitiatives.credit360.com'
where app_sid in (select app_sid from csr.customer where host = 'rbsenv.credit360.com');

@..\initiative_body
	
@update_tail
