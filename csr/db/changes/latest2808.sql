-- Please update version.sql too -- this keeps clean builds in sync
define version=2808
define minor_version=0
define is_combined=0
@update_header

ALTER TABLE csrimp.chain_saved_filter_agg_type DROP CONSTRAINT chk_svd_fil_agg_type;
ALTER TABLE csrimp.chain_saved_filter_agg_type ADD (
	initiative_metric_id	NUMBER(10),
	ind_sid					NUMBER(10),
	CONSTRAINT chk_svd_fil_agg_type
	CHECK ((aggregation_type IS NOT NULL AND cms_aggregate_type_id IS NULL AND initiative_metric_id IS NULL AND ind_sid IS NULL)
	   OR (aggregation_type IS NULL AND cms_aggregate_type_id IS NOT NULL AND initiative_metric_id IS NULL AND ind_sid IS NULL)
	   OR (aggregation_type IS NULL AND cms_aggregate_type_id IS NULL AND initiative_metric_id IS NOT NULL AND ind_sid IS NULL)
	   OR (aggregation_type IS NULL AND cms_aggregate_type_id IS NULL AND initiative_metric_id IS NULL AND ind_sid IS NOT NULL))
);

@update_tail
