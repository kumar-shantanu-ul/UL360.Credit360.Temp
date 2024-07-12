create index chem.ix_substance_region_sid on chem.substance (app_sid, region_sid);
create index chem.ix_substance_reg_flow_item_id on chem.substance_region (app_sid, flow_item_id);
