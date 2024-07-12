-- Please update version.sql too -- this keeps clean builds in sync
define version=1437
@update_header

create unique index csr.ix_superadmin_uniq_user_name on csr.superadmin (lower(user_name));

@../csr_data_body

@update_tail
	