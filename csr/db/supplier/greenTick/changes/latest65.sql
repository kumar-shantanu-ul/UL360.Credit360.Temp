-- Please update version.sql too -- this keeps clean builds in sync
define version=65
@update_header


ALTER TABLE
   gt_scores_gift
RENAME TO
   gt_scores_combined;

@..\build.sql


@update_tail