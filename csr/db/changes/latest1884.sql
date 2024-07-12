-- Please update version.sql too -- this keeps clean builds in sync
define version=1884
@update_header

-- XXX: Pevent this from running on live save taking down the sites!
--@../csr_data_pkg
--@../issue_pkg
--@../issue_body

@update_tail
