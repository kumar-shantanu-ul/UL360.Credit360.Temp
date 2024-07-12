-- Please update version.sql too -- this keeps clean builds in sync
define version=3118
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

/*
CREATE OR REPLACE VIEW "CSR"."V$SS_11752037" ("DESCRIPTION", "PERIOD_LABEL", "APP_SID", "REGION_SID", "PERIOD_ID", "I$11751058", "TAG", "TAG_ID") AS 
select r.description, p.label period_label, v."APP_SID",v."REGION_SID",v."PERIOD_ID",v."I$11751058", rt.tag, rt.tag_id
  from csr.ss_11752037 v, csr.v$region r, csr.ss_11752037_period p,
	   (select rt.region_sid, t.tag_id, t.tag
		  from csr.region_tag rt, csr.tag_group_member tgm, csr.v$tag t
		 where rt.tag_id = t.tag_id and tgm.tag_id = t.tag_id and
			   rt.tag_id = tgm.tag_id and (tgm.tag_group_id = 4352)) rt
 where v.region_sid = r.region_sid
   and v.period_id = p.period_id
   and r.region_sid = rt.region_sid(+)
*/
CREATE OR REPLACE VIEW CSR.V$SS_11752037 AS SELECT 1 TEST FROM DUAL;
DROP VIEW CSR.V$SS_11752037;

/*
CREATE OR REPLACE VIEW "CSR"."V$SS_16572575" ("DESCRIPTION", "PERIOD_LABEL", "APP_SID", "REGION_SID", "PERIOD_ID", "I$16571770", "TAG", "TAG_ID") AS 
select r.description, p.label period_label, v."APP_SID",v."REGION_SID",v."PERIOD_ID",v."I$16571770", rt.tag, rt.tag_id
  from csr.ss_16572575 v, csr.v$region r, csr.ss_16572575_period p,
	   (select rt.region_sid, t.tag_id, t.tag
		  from csr.region_tag rt, csr.tag_group_member tgm, csr.v$tag t
		 where rt.tag_id = t.tag_id and tgm.tag_id = t.tag_id and 
			   rt.tag_id = tgm.tag_id and (tgm.tag_group_id = 23055)) rt
 where v.region_sid = r.region_sid
   and v.period_id = p.period_id
   and r.region_sid = rt.region_sid(+)
*/
CREATE OR REPLACE VIEW CSR.V$SS_16572575 AS SELECT 1 TEST FROM DUAL;
DROP VIEW CSR.V$SS_16572575;

/*
CREATE OR REPLACE VIEW "CSR"."V$SS_DB_ENERGY" ("DESCRIPTION", "PERIOD_LABEL", "REGION_SID", "PERIOD_ID", "I$9342385", "I$9342404", "I$9342405", "I$9342427", "I$9342428", "I$9342429", "I$9342430", "I$9342455", "I$9342456", "I$9342457", "I$9342460", "I$9342461", "I$9342462", "I$9342463", "I$9342464", "I$9434139", "I$9434140", "I$9434142", "I$9434143", "I$9434144", "I$9434145", "I$9434146", "I$9434147", "I$9434148", "I$9438227", "I$9438307", "I$9438443", "I$9471660", "I$9471661", "I$9529504", "I$9598837", "I$9598865", "TAG", "TAG_ID") AS 
select r.description, p.label period_label, v."REGION_SID",v."PERIOD_ID",v."I$9342385",v."I$9342404",v."I$9342405",v."I$9342427",v."I$9342428",v."I$9342429",v."I$9342430",v."I$9342455",v."I$9342456",v."I$9342457",v."I$9342460",v."I$9342461",v."I$9342462",v."I$9342463",v."I$9342464",v."I$9434139",v."I$9434140",v."I$9434142",v."I$9434143",v."I$9434144",v."I$9434145",v."I$9434146",v."I$9434147",v."I$9434148",v."I$9438227",v."I$9438307",v."I$9438443",v."I$9471660",v."I$9471661",v."I$9529504",v."I$9598837",v."I$9598865", rt.tag, rt.tag_id
  from csr.ss_DB_ENERGY v, csr.v$region r, csr.ss_DB_ENERGY_period p,
	   (select rt.region_sid, t.tag_id, t.tag
		  from csr.region_tag rt, csr.tag_group_member tgm, csr.v$tag t
		 where rt.tag_id = t.tag_id and tgm.tag_id = t.tag_id and
			   rt.tag_id = tgm.tag_id and (tgm.tag_group_id = 672)) rt
 where v.region_sid = r.region_sid
   and v.period_id = p.period_id
   and r.region_sid = rt.region_sid(+)
*/
CREATE OR REPLACE VIEW CSR.V$SS_DB_ENERGY AS SELECT 1 TEST FROM DUAL;
DROP VIEW CSR.V$SS_DB_ENERGY;

/*
CREATE OR REPLACE VIEW "CSR"."V$SS_DELOITTE_ENERGY" ("DESCRIPTION", "PERIOD_LABEL", "APP_SID", "REGION_SID", "PERIOD_ID", "I$10251716", "I$10251717", "I$10251733", "I$10251736", "TAG", "TAG_ID") AS 
select r.description, p.label period_label, v."APP_SID",v."REGION_SID",v."PERIOD_ID",v."I$10251716",v."I$10251717",v."I$10251733",v."I$10251736", rt.tag, rt.tag_id
  from csr.ss_DELOITTE_ENERGY v, csr.v$region r, csr.ss_DELOITTE_ENERGY_period p,
	   (select rt.region_sid, t.tag_id, t.tag
		  from csr.region_tag rt, csr.tag_group_member tgm, csr.v$tag t
		 where rt.tag_id = t.tag_id and tgm.tag_id = t.tag_id and
			   rt.tag_id = tgm.tag_id and (tgm.tag_group_id = 912)) rt
 where v.region_sid = r.region_sid
   and v.period_id = p.period_id
   and r.region_sid = rt.region_sid(+)
*/
CREATE OR REPLACE VIEW CSR.V$SS_DELOITTE_ENERGY AS SELECT 1 TEST FROM DUAL;
DROP VIEW CSR.V$SS_DELOITTE_ENERGY;


/*
CREATE OR REPLACE VIEW "CSR"."V$SS_DELOITTE_TRAVEL" ("DESCRIPTION", "PERIOD_LABEL", "APP_SID", "REGION_SID", "PERIOD_ID", "I$10251737", "I$10251739", "I$10251741", "I$10251811", "I$10251743", "TAG", "TAG_ID") AS 
select r.description, p.label period_label, v."APP_SID",v."REGION_SID",v."PERIOD_ID",v."I$10251737",v."I$10251739",v."I$10251741",v."I$10251811",v."I$10251743", rt.tag, rt.tag_id
  from csr.ss_DELOITTE_TRAVEL v, csr.v$region r, csr.ss_DELOITTE_TRAVEL_period p,
	   (select rt.region_sid, t.tag_id, t.tag
		  from csr.region_tag rt, csr.tag_group_member tgm, csr.v$tag t
		 where rt.tag_id = t.tag_id and tgm.tag_id = t.tag_id and
			   rt.tag_id = tgm.tag_id and (tgm.tag_group_id = 912)) rt
 where v.region_sid = r.region_sid
   and v.period_id = p.period_id
   and r.region_sid = rt.region_sid(+)
*/
CREATE OR REPLACE VIEW CSR.V$SS_DELOITTE_TRAVEL AS SELECT 1 TEST FROM DUAL;
DROP VIEW CSR.V$SS_DELOITTE_TRAVEL;


/*
CREATE OR REPLACE VIEW "CSR"."V$SS_IMI_MONTHLY_HOURS" ("DESCRIPTION", "PERIOD_LABEL", "REGION_SID", "PERIOD_ID", "I$7670860", "TAG", "TAG_ID") AS 
select r.description, p.label period_label, v."REGION_SID",v."PERIOD_ID",v."I$7670860", rt.tag, rt.tag_id
  from csr.ss_IMI_MONTHLY_HOURS v, csr.v$region r, csr.ss_IMI_MONTHLY_HOURS_period p,
	   (select rt.region_sid, t.tag_id, t.tag
		  from csr.region_tag rt, csr.tag_group_member tgm, csr.v$tag t
		 where rt.tag_id = t.tag_id and tgm.tag_id = t.tag_id and
			   rt.tag_id = tgm.tag_id and (tgm.tag_group_id = 453)) rt
 where v.region_sid = r.region_sid
   and v.period_id = p.period_id
   and r.region_sid = rt.region_sid(+)
*/
CREATE OR REPLACE VIEW CSR.V$SS_IMI_MONTHLY_HOURS AS SELECT 1 TEST FROM DUAL;
DROP VIEW CSR.V$SS_IMI_MONTHLY_HOURS;


/*
CREATE OR REPLACE VIEW "CSR"."V$SS_IMI_QUARTERLY_HOURS" ("DESCRIPTION", "PERIOD_LABEL", "REGION_SID", "PERIOD_ID", "I$7670860", "TAG", "TAG_ID") AS 
select r.description, p.label period_label, v."REGION_SID",v."PERIOD_ID",v."I$7670860", rt.tag, rt.tag_id
  from csr.ss_IMI_QUARTERLY_HOURS v, csr.v$region r, csr.ss_IMI_QUARTERLY_HOURS_period p,
	   (select rt.region_sid, t.tag_id, t.tag
		  from csr.region_tag rt, csr.tag_group_member tgm, csr.v$tag t
		 where rt.tag_id = t.tag_id and tgm.tag_id = t.tag_id and
			   rt.tag_id = tgm.tag_id and (tgm.tag_group_id = 453)) rt
 where v.region_sid = r.region_sid
   and v.period_id = p.period_id
   and r.region_sid = rt.region_sid(+)
*/
CREATE OR REPLACE VIEW CSR.V$SS_IMI_QUARTERLY_HOURS AS SELECT 1 TEST FROM DUAL;
DROP VIEW CSR.V$SS_IMI_QUARTERLY_HOURS;


/*
CREATE OR REPLACE VIEW "CSR"."V$SS_KPIS_CATEGORY" ("DESCRIPTION", "PERIOD_LABEL", "REGION_SID", "PERIOD_ID", "I$7919197", "I$7919198", "I$7919239", "I$7919302", "I$7919249", "I$7919438", "TAG", "TAG_ID") AS 
select r.description, p.label period_label, v."REGION_SID",v."PERIOD_ID",v."I$7919197",v."I$7919198",v."I$7919239",v."I$7919302",v."I$7919249",v."I$7919438", rt.tag, rt.tag_id
  from csr.ss_KPIS_CATEGORY v, csr.v$region r, csr.ss_KPIS_CATEGORY_period p,
	   (select rt.region_sid, t.tag_id, t.tag
		  from csr.region_tag rt, csr.tag_group_member tgm, csr.v$tag t
		 where rt.tag_id = t.tag_id and tgm.tag_id = t.tag_id and
			   rt.tag_id = tgm.tag_id and (tgm.tag_group_id = 252)) rt
 where v.region_sid = r.region_sid
   and v.period_id = p.period_id
   and r.region_sid = rt.region_sid(+)
*/
CREATE OR REPLACE VIEW CSR.V$SS_KPIS_CATEGORY AS SELECT 1 TEST FROM DUAL;
DROP VIEW CSR.V$SS_KPIS_CATEGORY;


/*
CREATE OR REPLACE VIEW "CSR"."V$SS_KPIS_TYPE" ("DESCRIPTION", "PERIOD_LABEL", "REGION_SID", "PERIOD_ID", "I$7919197", "I$7919239", "I$7919302", "I$7919249", "I$7919438", "TAG", "TAG_ID") AS 
select r.description, p.label period_label, v."REGION_SID",v."PERIOD_ID",v."I$7919197",v."I$7919239",v."I$7919302",v."I$7919249",v."I$7919438", rt.tag, rt.tag_id
  from csr.ss_KPIS_TYPE v, csr.v$region r, csr.ss_KPIS_TYPE_period p,
	   (select rt.region_sid, t.tag_id, t.tag
		  from csr.region_tag rt, csr.tag_group_member tgm, csr.v$tag t
		 where rt.tag_id = t.tag_id and tgm.tag_id = t.tag_id and
			   rt.tag_id = tgm.tag_id and (tgm.tag_group_id = 247)) rt
 where v.region_sid = r.region_sid
   and v.period_id = p.period_id
   and r.region_sid = rt.region_sid(+)
*/
CREATE OR REPLACE VIEW CSR.V$SS_KPIS_TYPE AS SELECT 1 TEST FROM DUAL;
DROP VIEW CSR.V$SS_KPIS_TYPE;


/*
CREATE OR REPLACE VIEW "CSR"."V$SS_LINDE" ("DESCRIPTION", "PERIOD_LABEL", "APP_SID", "REGION_SID", "PERIOD_ID", "I$7154178", "I$7154179", "I$7154180", "I$7154198", "I$8884150", "I$7154284", "I$7154291", "I$7259030", "I$8883465", "I$7154283", "TAG", "TAG_ID") AS 
select r.description, p.label period_label, v."APP_SID",v."REGION_SID",v."PERIOD_ID",v."I$7154178",v."I$7154179",v."I$7154180",v."I$7154198",v."I$8884150",v."I$7154284",v."I$7154291",v."I$7259030",v."I$8883465",v."I$7154283", rt.tag, rt.tag_id
  from csr.ss_LINDE v, csr.v$region r, csr.ss_LINDE_period p,
	   (select rt.region_sid, t.tag_id, t.tag
		  from csr.region_tag rt, csr.tag_group_member tgm, csr.v$tag t
		 where rt.tag_id = t.tag_id and tgm.tag_id = t.tag_id and
			   rt.tag_id = tgm.tag_id and (tgm.tag_group_id = 477)) rt
 where v.region_sid = r.region_sid
   and v.period_id = p.period_id
   and r.region_sid = rt.region_sid(+)
*/
CREATE OR REPLACE VIEW CSR.V$SS_LINDE AS SELECT 1 TEST FROM DUAL;
DROP VIEW CSR.V$SS_LINDE;


/*
CREATE OR REPLACE VIEW "CSR"."V$SS_SNAPSHOT_ANNUALLY" ("DESCRIPTION", "PERIOD_LABEL", "APP_SID", "REGION_SID", "PERIOD_ID", "I$9342382", "I$10189879", "I$9342385", "I$9342404", "I$9342405", "I$9434139", "I$9434140", "I$9434142", "I$9434143", "I$9434144", "I$9434145", "I$9434146", "I$10189382", "I$10189868", "I$9342383", "TAG", "TAG_ID") AS 
select r.description, p.label period_label, v."APP_SID",v."REGION_SID",v."PERIOD_ID",v."I$9342382",v."I$10189879",v."I$9342385",v."I$9342404",v."I$9342405",v."I$9434139",v."I$9434140",v."I$9434142",v."I$9434143",v."I$9434144",v."I$9434145",v."I$9434146",v."I$10189382",v."I$10189868",v."I$9342383", rt.tag, rt.tag_id
  from csr.ss_SNAPSHOT_ANNUALLY v, csr.v$region r, csr.ss_SNAPSHOT_ANNUALLY_period p,
	   (select rt.region_sid, t.tag_id, t.tag
		  from csr.region_tag rt, csr.tag_group_member tgm, csr.v$tag t
		 where rt.tag_id = t.tag_id and tgm.tag_id = t.tag_id and 
			   rt.tag_id = tgm.tag_id and (tgm.tag_group_id = 383 OR tgm.tag_group_id = 672)) rt
 where v.region_sid = r.region_sid
   and v.period_id = p.period_id
   and r.region_sid = rt.region_sid(+)
*/
CREATE OR REPLACE VIEW CSR.V$SS_SNAPSHOT_ANNUALLY AS SELECT 1 TEST FROM DUAL;
DROP VIEW CSR.V$SS_SNAPSHOT_ANNUALLY;


/*
CREATE OR REPLACE VIEW "CSR"."V$SS_SNAPSHOT_HALF_YEARLY" ("DESCRIPTION", "PERIOD_LABEL", "APP_SID", "REGION_SID", "PERIOD_ID", "I$9342382", "I$10189879", "I$9342385", "I$9342404", "I$9342405", "I$9434139", "I$9434140", "I$9434142", "I$9434143", "I$9434144", "I$9434145", "I$9434146", "I$10189382", "I$10189868", "I$9342383", "TAG", "TAG_ID") AS 
select r.description, p.label period_label, v."APP_SID",v."REGION_SID",v."PERIOD_ID",v."I$9342382",v."I$10189879",v."I$9342385",v."I$9342404",v."I$9342405",v."I$9434139",v."I$9434140",v."I$9434142",v."I$9434143",v."I$9434144",v."I$9434145",v."I$9434146",v."I$10189382",v."I$10189868",v."I$9342383", rt.tag, rt.tag_id
  from csr.ss_SNAPSHOT_HALF_YEARLY v, csr.v$region r, csr.ss_SNAPSHOT_HALF_YEARLY_period p,
	   (select rt.region_sid, t.tag_id, t.tag
		  from csr.region_tag rt, csr.tag_group_member tgm, csr.v$tag t
		 where rt.tag_id = t.tag_id and tgm.tag_id = t.tag_id and 
			   rt.tag_id = tgm.tag_id and (tgm.tag_group_id = 383 OR tgm.tag_group_id = 672)) rt
 where v.region_sid = r.region_sid
   and v.period_id = p.period_id
   and r.region_sid = rt.region_sid(+)
*/
CREATE OR REPLACE VIEW CSR.V$SS_SNAPSHOT_HALF_YEARLY AS SELECT 1 TEST FROM DUAL;
DROP VIEW CSR.V$SS_SNAPSHOT_HALF_YEARLY;


/*
CREATE OR REPLACE VIEW "CSR"."V$SS_SNAPSHOT_HALFYEARLY" ("DESCRIPTION", "PERIOD_LABEL", "APP_SID", "REGION_SID", "PERIOD_ID", "I$9342382", "I$10189879", "I$9342385", "I$9342404", "I$9342405", "I$9434139", "I$9434140", "I$9434142", "I$9434143", "I$9434144", "I$9434145", "I$9434146", "I$10189382", "I$10189868", "I$9342383", "TAG", "TAG_ID") AS 
select r.description, p.label period_label, v."APP_SID",v."REGION_SID",v."PERIOD_ID",v."I$9342382",v."I$10189879",v."I$9342385",v."I$9342404",v."I$9342405",v."I$9434139",v."I$9434140",v."I$9434142",v."I$9434143",v."I$9434144",v."I$9434145",v."I$9434146",v."I$10189382",v."I$10189868",v."I$9342383", rt.tag, rt.tag_id
  from csr.ss_SNAPSHOT_HALFYEARLY v, csr.v$region r, csr.ss_SNAPSHOT_HALFYEARLY_period p,
	   (select rt.region_sid, t.tag_id, t.tag
		  from csr.region_tag rt, csr.tag_group_member tgm, csr.v$tag t
		 where rt.tag_id = t.tag_id and tgm.tag_id = t.tag_id and 
			   rt.tag_id = tgm.tag_id and (tgm.tag_group_id = 383 OR tgm.tag_group_id = 672)) rt
 where v.region_sid = r.region_sid
   and v.period_id = p.period_id
   and r.region_sid = rt.region_sid(+)
*/
CREATE OR REPLACE VIEW CSR.V$SS_SNAPSHOT_HALFYEARLY AS SELECT 1 TEST FROM DUAL;
DROP VIEW CSR.V$SS_SNAPSHOT_HALFYEARLY;


/*
CREATE OR REPLACE VIEW "CSR"."V$SS_SNAPSHOT_QUARTERLY" ("DESCRIPTION", "PERIOD_LABEL", "APP_SID", "REGION_SID", "PERIOD_ID", "I$9342382", "I$10189879", "I$9342385", "I$9342404", "I$9342405", "I$9434139", "I$9434140", "I$9434142", "I$9434143", "I$9434144", "I$9434145", "I$9434146", "I$10189382", "I$10189868", "I$9342383", "TAG", "TAG_ID") AS 
select r.description, p.label period_label, v."APP_SID",v."REGION_SID",v."PERIOD_ID",v."I$9342382",v."I$10189879",v."I$9342385",v."I$9342404",v."I$9342405",v."I$9434139",v."I$9434140",v."I$9434142",v."I$9434143",v."I$9434144",v."I$9434145",v."I$9434146",v."I$10189382",v."I$10189868",v."I$9342383", rt.tag, rt.tag_id
  from csr.ss_SNAPSHOT_QUARTERLY v, csr.$region r, csr.ss_SNAPSHOT_QUARTERLY_period p,
	   (select rt.region_sid, t.tag_id, t.tag
		  from csr.region_tag rt, csr.tag_group_member tgm, csr.v$tag t
		 where rt.tag_id = t.tag_id and tgm.tag_id = t.tag_id and 
			   rt.tag_id = tgm.tag_id and (tgm.tag_group_id = 383 OR tgm.tag_group_id = 672)) rt
 where v.region_sid = r.region_sid
   and v.period_id = p.period_id
   and r.region_sid = rt.region_sid(+)
*/
CREATE OR REPLACE VIEW CSR.V$SS_SNAPSHOT_QUARTERLY AS SELECT 1 TEST FROM DUAL;
DROP VIEW CSR.V$SS_SNAPSHOT_QUARTERLY;


/*
CREATE OR REPLACE VIEW "CSR"."V$SS_SR_ENERGY" ("DESCRIPTION", "PERIOD_LABEL", "REGION_SID", "PERIOD_ID", "I$9554358", "I$9553895", "I$9553898", "I$9553897", "TAG", "TAG_ID") AS 
select r.description, p.label period_label, v."REGION_SID",v."PERIOD_ID",v."I$9554358",v."I$9553895",v."I$9553898",v."I$9553897", rt.tag, rt.tag_id
  from csr.ss_SR_ENERGY v, csr.v$region r, csr.ss_SR_ENERGY_period p,
	   (select rt.region_sid, t.tag_id, t.tag
		  from csr.region_tag rt, csr.tag_group_member tgm, csr.v$tag t
		 where rt.tag_id = t.tag_id and tgm.tag_id = t.tag_id and
			   rt.tag_id = tgm.tag_id and (tgm.tag_group_id = 422)) rt
 where v.region_sid = r.region_sid
   and v.period_id = p.period_id
   and r.region_sid = rt.region_sid(+)
*/
CREATE OR REPLACE VIEW CSR.V$SS_SR_ENERGY AS SELECT 1 TEST FROM DUAL;
DROP VIEW CSR.V$SS_SR_ENERGY;

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
