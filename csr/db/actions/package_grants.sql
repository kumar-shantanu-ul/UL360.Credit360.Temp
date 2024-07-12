
GRANT EXECUTE ON actions.project_pkg TO SECURITY;
GRANT EXECUTE ON actions.task_pkg TO SECURITY;

GRANT EXECUTE ON actions.project_pkg TO CSR;
GRANT EXECUTE ON actions.task_pkg TO CSR;
GRANT EXECUTE ON actions.setup_pkg TO CSR;
GRANT EXECUTE ON actions.tag_pkg TO CSR;
GRANT EXECUTE ON actions.options_pkg TO CSR;
GRANT EXECUTE ON actions.dependency_pkg TO CSR;
GRANT EXECUTE ON actions.initiative_pkg TO CSR;
GRANT EXECUTE ON actions.aggr_dependency_pkg TO CSR;
GRANT EXECUTE ON actions.file_upload_pkg TO CSR;

GRANT EXECUTE ON csr.stored_calc_datasource_pkg TO actions;
GRANT EXECUTE ON csr.stragg3 to actions;

@@web_grants
