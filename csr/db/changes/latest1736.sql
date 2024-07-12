-- Please update version too -- this keeps clean builds in sync
define version=1736
@update_header

insert into csr.batch_job_type (batch_job_type_id, description, plugin_name)
	values (7, 'CMS Import', 'cms-import');

@update_tail