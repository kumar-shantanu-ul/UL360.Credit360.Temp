-- Please update version.sql too -- this keeps clean builds in sync
define version=2352
@update_header

--New capability to allow a user to download all templatde reports generated in their app
INSERT INTO csr.capability (name, allow_by_default) VALUES ('Download all templated reports', 0);


@../templated_report_pkg
@../templated_report_body

@update_tail
