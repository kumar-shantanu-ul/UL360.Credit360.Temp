-- Please update version.sql too -- this keeps clean builds in sync
define version=1080
@update_header

grant execute on csr.csr_data_pkg to ct;

@update_tail
