define version=25
@update_header

alter table chain.customer_options add (invitation_expiration_days number default 7);

update chain.customer_options set invitation_expiration_days = 30 where site_name = 'Maersk CSR';

@../invitation_body

@update_tail
