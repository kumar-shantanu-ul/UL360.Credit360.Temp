-- Please update version.sql too -- this keeps clean builds in sync
define version=822
@update_header

alter table csr.ind add prop_down_region_tree_sid number(10);
ALTER TABLE CSR.IND ADD CONSTRAINT FK_IND_REGION_TREE
    FOREIGN KEY (APP_SID, PROP_DOWN_REGION_TREE_SID)
    REFERENCES CSR.REGION_TREE(APP_SID, REGION_TREE_ROOT_SID)
;
create index csr.ix_ind_prop_down_region_sid on csr.ind (app_sid, prop_down_region_tree_sid);
alter table csrimp.ind add prop_down_region_tree_sid number(10);

@../indicator_pkg
@../region_pkg
@../stored_calc_datasource_pkg
@../val_datasource_pkg
@../dataview_body 
@../vb_legacy_body
@../pending_datasource_body
@../region_body
@../actions/task_body
@../delegation_body
@../csrimp/imp_body
@../stored_calc_datasource_body
@../pending_body
@../datasource_body
@../range_body
@../val_datasource_body
@../schema_body
@../indicator_body

@update_tail