grant create table to chain;

/* CHAIN UPLOAD FILE INDEX */
create index chain.ix_file_upload_search on chain.file_upload(data) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

/* CHAIN ACTIVITY DESCRIPTION INDEX */
create index chain.ix_activity_desc_search on chain.activity(description) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

/* CHAIN ACTIVITY LOCATION INDEX */
create index chain.ix_activity_loc_search on chain.activity(location) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

/* CHAIN ACTIVITY OUTCOME REASON INDEX */
create index chain.ix_activity_out_search on chain.activity(outcome_reason) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

/* CHAIN ACTIVITY OUTCOME LOG MESSAGE INDEX */
create index chain.ix_activity_log_search on chain.activity_log(message) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

revoke create table from chain;

grant execute on ctx_ddl to chain;
@@create_text_indexes_jobs
