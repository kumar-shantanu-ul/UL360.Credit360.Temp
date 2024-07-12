-- Please update version.sql too -- this keeps clean builds in sync
define version=434
@update_header

create global temporary table approval_step_stats
(
approval_step_id number(10),
ind_count number(10),
region_count number(10),
period_count number(10),
constraint pk_approval_step_stats primary key (approval_step_id)
);

create global temporary table approval_step_summary
(
approval_step_id number(10),
parent_step_id number(10),
sheet_key varchar2(255),
sheet_label varchar2(1204),
pending_period_id number(10),
pending_region_id number(10),
pending_ind_id number(10),
due_dtm date,
approver_response_due_dtm date,
max_ind_count number(10),
max_region_count number(10),
max_period_count number(10),
delegated_val_count number(10),
submitted_val_count number(10),
constraint pk_approval_step_summary primary key (approval_step_id, sheet_key)
);

create global temporary table approval_step_hierarchy
(
ancestor_step_id number(10),
approval_step_id number(10),
constraint pk_approval_step_hierarchy primary key (ancestor_step_id, approval_step_id)
);

create index idx_approval_step_hierarchy on approval_step_hierarchy (approval_step_id);

create global temporary table pending_region_descendants
(
ancestor_region_id number(10),
pending_region_id number(10),
constraint pk_pending_region_stats primary key (ancestor_region_id, pending_region_id)
);

create global temporary table approval_step_val
(
approval_step_id number(10),
pending_period_id number(10),
pending_region_id number(10),
pending_ind_id number(10),
constraint pk_approval_step_val primary key (approval_step_id, pending_period_id, pending_region_id, pending_ind_id)
);

@..\pending_body.sql

@update_tail
