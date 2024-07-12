-- Please update version.sql too -- this keeps clean builds in sync
define version=1586
@update_header

update csr.csr_user set hidden=1 where lower(user_name) ='usercreatordaemon';

@..\csr_data_body

@update_tail