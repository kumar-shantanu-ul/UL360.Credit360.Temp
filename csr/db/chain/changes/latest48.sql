define version=48
@update_header

grant delete on chain.task_node_type to csr;
grant delete on chain.action_type to csr;
grant delete on chain.reason_for_action to csr;
grant delete on chain.action to csr;
grant delete on chain.alert_entry_template to csr;
grant delete on chain.company to csr;
grant delete on chain.action to csr;
grant delete on chain.applied_company_capability to csr;
grant delete on chain.product_code_type to csr;
grant delete on chain.company_metric_type to csr;
grant delete on chain.task_type to csr;
grant delete on chain.event_type to csr;
grant delete on chain.group_capability_override to csr;
grant delete on chain.questionnaire_type to csr;

@update_tail

