-- Please update version.sql too -- this keeps clean builds in sync
define version=2130
@update_header

ALTER TABLE chain.customer_options ADD show_invitation_preview NUMBER(1, 0);
update chain.customer_options set show_invitation_preview=0;
alter table chain.customer_options modify show_invitation_preview default 0 not null;
alter table chain.customer_options add CONSTRAINT chk_show_invitation_preview CHECK (show_invitation_preview IN (0, 1))


@../alert_body
@../alert_pkg
@../chain/helper_body


@update_tail