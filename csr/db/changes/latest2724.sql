-- Please update version too -- this keeps clean builds in sync
define version=2724
@update_header

@..\imp_pkg
@..\measure_pkg
@..\templated_report_schedule_pkg
@..\training_pkg

@..\imp_body
@..\initiative_body
@..\measure_body
@..\templated_report_schedule_body
@..\training_body

@update_tail
