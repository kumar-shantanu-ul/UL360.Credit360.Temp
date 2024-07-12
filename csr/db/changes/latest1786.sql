-- Please update version.sql too -- this keeps clean builds in sync
define version=1786
@update_header

ALTER TABLE csrimp.issue_type MODIFY (allow_pending_assignment DEFAULT 0);
ALTER TABLE csrimp.issue MODIFY (is_pending_assignment DEFAULT 0);
ALTER TABLE csrimp.map_cms_schema DROP CONSTRAINT pk_map_cms_schema;
ALTER TABLE csrimp.map_cms_schema ADD CONSTRAINT  pk_map_cms_schema PRIMARY KEY(csrimp_session_id,old_oracle_schema);          
ALTER TABLE csrimp.map_cms_schema DROP CONSTRAINT uk_map_cms_schema;
ALTER TABLE csrimp.map_cms_schema ADD CONSTRAINT  uk_map_cms_schema UNIQUE(csrimp_session_id,new_oracle_schema);
ALTER TABLE csrimp.map_sid DROP CONSTRAINT pk_map_sid;
ALTER TABLE csrimp.map_sid ADD CONSTRAINT  pk_map_sid PRIMARY KEY(csrimp_session_id,old_sid);
ALTER TABLE csrimp.map_sid DROP CONSTRAINT uk_map_sid;
ALTER TABLE csrimp.map_sid ADD CONSTRAINT uk_map_sid UNIQUE(csrimp_session_id,new_sid);

@update_tail
