grant select, references on csr.csr_user to supplier;
grant select, references on csr.customer to supplier;
grant select, references on csr.audit_log to supplier;
grant select, references on csr.audit_type to supplier;
grant select, references on csr.quick_survey to supplier;

grant select, references on security.group_members to supplier;
grant select, references on security.securable_object to supplier;
grant select, references on security.user_table to supplier;
grant select, references on security.group_table to supplier;

grant select, references, insert on aspen2.filecache to supplier;
