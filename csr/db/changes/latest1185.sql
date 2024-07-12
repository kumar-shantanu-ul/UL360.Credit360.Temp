-- Please update version.sql too -- this keeps clean builds in sync
define version=1185
@update_header

declare
	v_exists number;
begin
	select count(*)
	  into v_exists
	  from all_tables
	 where owner='SUPPLIER' and table_name='GT_PRODUCT_USER';
	 
	if v_exists = 0 then
		execute immediate '
CREATE TABLE SUPPLIER.GT_PRODUCT_USER (
  app_sid       NUMBER(10,0) DEFAULT SYS_CONTEXT(''SECURITY'', ''APP'') NOT NULL,
  product_id     NUMBER(10,0) NOT NULL,
  user_sid       NUMBER(10,0) NOT NULL,
  company_sid	 NUMBER(10,0),
  started		 NUMBER(1, 0) DEFAULT 1 NOT NULL,
  CONSTRAINT PK_GT_PRODUCT_USER PRIMARY KEY(product_id, user_sid)
)';
	end if;

	select count(*)
	  into v_exists
	  from all_tables
	 where owner='SUPPLIER' and table_name='GT_PRODUCT_TYPE';
	if v_exists = 0 then
		execute immediate '
CREATE TABLE SUPPLIER.GT_PRODUCT_TYPE(
    GT_PRODUCT_TYPE_ID          NUMBER(10, 0)     NOT NULL,
    GT_PRODUCT_TYPE_GROUP_ID    NUMBER(10, 0)     NOT NULL,
    DESCRIPTION                 VARCHAR2(1024)    NOT NULL,
    AV_WATER_CONTENT_PCT        NUMBER(6, 3)      NOT NULL,
    GT_WATER_USE_TYPE_ID        NUMBER(10, 0)     NOT NULL,
    WATER_USAGE_FACTOR          NUMBER(10, 2)     NOT NULL,
    MNFCT_ENERGY_SCORE          NUMBER(10, 2)     NOT NULL,
    USE_ENERGY_SCORE            NUMBER(10, 2)     NOT NULL,
    GT_PRODUCT_CLASS_ID         NUMBER(10, 0)     NOT NULL,
    GT_ACCESS_VISC_TYPE_ID      NUMBER(10, 0)     DEFAULT 1 NOT NULL,
    UNIT                        VARCHAR2(20)      DEFAULT ''g'' NOT NULL,
    MAINS_POWERED               NUMBER(1, 0)      DEFAULT 0 NOT NULL,
    HRS_USED_PER_MONTH          NUMBER(10, 0)     DEFAULT -1 NOT NULL,
    MNFCT_WATER_SCORE           NUMBER(10, 2)     DEFAULT 1 NOT NULL,
    WATER_IN_PROD_PD            NUMBER(10, 2)     DEFAULT 1 NOT NULL,
    ENERGY_IN_DIST_SCORE        NUMBER(10, 2)     DEFAULT 1 NOT NULL,
    CONSTRAINT PK207 PRIMARY KEY (GT_PRODUCT_TYPE_ID)
)';
	end if;

	select count(*)
	  into v_exists
	  from all_tables
	 where owner='SUPPLIER' and table_name='GT_TAG_PRODUCT_TYPE';
	 
	if v_exists = 0 then
		execute immediate '
CREATE TABLE SUPPLIER.GT_TAG_PRODUCT_TYPE(
    GT_PRODUCT_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    TAG_ID                NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK323 PRIMARY KEY (GT_PRODUCT_TYPE_ID, TAG_ID)
)';
	end if;
	
	select count(*)
	  into v_exists
	  from all_views
	 where owner='SUPPLIER' and view_name='GT_PRODUCT';

	if v_exists = 0 then
		execute immediate '
CREATE OR REPLACE VIEW SUPPLIER.GT_PRODUCT AS 
SELECT p.*, gtp.gt_product_type_id, gtp.gt_product_type_group_id, 
       gt_water_use_type_id, water_usage_factor, mnfct_energy_score, gt_product_class_id, gt_access_visc_type_id, unit, hrs_used_per_month, mains_powered
  FROM product p, product_tag pt, gt_tag_product_type gtpt, gt_product_type gtp
 WHERE p.product_id = pt.product_id
   AND pt.tag_id = gtpt.tag_id
   AND gtpt.gt_product_type_id = gtp.gt_product_type_id
';
	end if;
	
end;
/

@update_tail
