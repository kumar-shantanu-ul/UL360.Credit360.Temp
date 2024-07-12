--Please update version.sql too -- this keeps clean builds in sync
define version=2587
@update_header

@../energy_star_helper_pkg

@../energy_star_body
@../energy_star_helper_body
@../energy_star_job_data_body

	
@update_tail