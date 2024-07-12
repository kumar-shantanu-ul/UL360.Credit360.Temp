-- Please update version.sql too -- this keeps clean builds in sync
define version=2434
@update_header

exec security.user_pkg.logonadmin;

alter table csr.role add is_hidden number(1);
update csr.role set is_hidden = 0;
alter table csr.role modify is_hidden number(1) default 0 not null;

alter table csr.role add CONSTRAINT CHK_ROLE_IS_HIDDEN CHECK (IS_HIDDEN IN (0, 1));

@../role_body

@update_tail
