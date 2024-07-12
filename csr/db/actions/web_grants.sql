-- select 'grant execute on actions.'||lower(object_name)||' to web_user;' from user_objects where object_type='PACKAGE' order by object_name;

grant execute on actions.aggr_dependency_pkg to web_user;
grant execute on actions.dependency_pkg to web_user;
grant execute on actions.file_upload_pkg to web_user;
grant execute on actions.gantt_pkg to web_user;
grant execute on actions.ind_template_pkg to web_user;
grant execute on actions.initiative_pkg to web_user;
grant execute on actions.initiative_reporting_pkg to web_user;
grant execute on actions.options_pkg to web_user;
grant execute on actions.project_pkg to web_user;
grant execute on actions.setup_pkg to web_user;
grant execute on actions.tag_pkg to web_user;
grant execute on actions.task_pkg to web_user;
grant execute on actions.reckoner_pkg to web_user;
grant execute on actions.periodic_alert_pkg to web_user;
grant execute on actions.importer_pkg to web_user;
grant execute on actions.role_pkg to web_user;
grant execute on actions.scenario_pkg to web_user;

