-- Please update version.sql too -- this keeps clean builds in sync
define version=943
@update_header

grant execute on aspen2.form_transaction_pkg to web_user,csr;

@update_tail
