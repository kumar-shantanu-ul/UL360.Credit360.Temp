-- Please update version.sql too -- this keeps clean builds in sync
define version=544
@update_header

comment on column issue.raised_by_user_sid is 'user';
comment on column issue.resolved_by_user_sid is 'user';
comment on column issue.assigned_to_user_sid is 'user';
comment on column issue.closed_by_user_sid is 'user';

@../csr_data_pkg
@../issue_pkg
@../issue_body

@update_tail
