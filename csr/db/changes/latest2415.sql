-- -- Please update version.sql too -- this keeps clean builds in sync
define version=2415
@update_header

ALTER TABLE csr.ALL_METER
ADD (
  lower_threshold_percentage NUMBER(10,2),
  upper_threshold_percentage NUMBER(10,2)
);

@update_tail
