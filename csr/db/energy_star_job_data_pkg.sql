CREATE OR REPLACE PACKAGE CSR.energy_star_job_data_pkg IS

PROCEDURE GetBuildingAndMetricsForJob(
	in_job_id					IN	est_job.est_job_id%TYPE,
    out_building				OUT	security_pkg.T_OUTPUT_CUR,
    out_metrics					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetBuildingForJob(
	in_job_id					IN	est_job.est_job_id%TYPE,
    out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetBuildingMetricsForJob(
	in_job_id					IN	est_job.est_job_id%TYPE,
    out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSpaceAndAttrsForJob(
	in_job_id					IN	est_job.est_job_id%TYPE,
    out_space					OUT	security_pkg.T_OUTPUT_CUR,
    out_attrs					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSpaceForJob(
	in_job_id					IN	est_job.est_job_id%TYPE,
    out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSpaceAttrsForJob(
	in_job_id					IN	est_job.est_job_id%TYPE,
    out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetMeterForJob(
	in_job_id					IN	est_job.est_job_id%TYPE,
    out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetMeterReadingsForJob(
    in_job_id					IN	est_job.est_job_id%TYPE,
    out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

END;
/

