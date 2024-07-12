CREATE OR REPLACE PACKAGE nn_man_site_pkg
IS
	
PART_MAN_SITE_CLASS_NAME		CONSTANT VARCHAR2(255) := 'NN_PART_MANUFACTURING_SITE';

TYPE T_SITE_IDS        			IS TABLE OF nn_manufacturing_site.company_part_id%TYPE INDEX BY PLS_INTEGER;

PROCEDURE GetManufacturingSite(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_site_id						IN NN_MANUFACTURING_SITE.COMPANY_PART_ID%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE CreateManufacturingSite(
	in_act_id								IN security_pkg.T_ACT_ID,
	in_company_sid					IN security_pkg.T_SID_ID,
	in_parent_part_id				IN company_part.parent_id%TYPE,
	in_manufacturer_name		IN nn_manufacturing_site.manufacturer_name%TYPE,
	in_address							IN nn_manufacturing_site.site_address%TYPE,
	in_contact_name					IN nn_manufacturing_site.site_contact_name%TYPE,
	in_contact_number				IN nn_manufacturing_site.site_contact_number%TYPE,
	in_country_code					IN nn_manufacturing_site.country_code%TYPE,
	in_employees_at_site		IN nn_manufacturing_site.employees_at_site%TYPE,
	in_processes_at_site		IN nn_manufacturing_site.processes_at_site%TYPE,
	out_manufacturing_site_id		OUT nn_manufacturing_site.company_part_id%TYPE
);

PROCEDURE UpdateManufacturingSite(
	in_act_id								IN security_pkg.T_ACT_ID,
	in_site_id							IN nn_manufacturing_site.company_part_id%TYPE,
	in_manufacturer_name		IN nn_manufacturing_site.manufacturer_name%TYPE,
	in_address							IN nn_manufacturing_site.site_address%TYPE,
	in_contact_name					IN nn_manufacturing_site.site_contact_name%TYPE,
	in_contact_number				IN nn_manufacturing_site.site_contact_number%TYPE,
	in_country_code					IN nn_manufacturing_site.country_code%TYPE,
	in_employees_at_site		IN nn_manufacturing_site.employees_at_site%TYPE,
	in_processes_at_site		IN nn_manufacturing_site.processes_at_site%TYPE
);

PROCEDURE DeleteManufacturingSite(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_site_id					IN company_part.company_part_id%TYPE
);

PROCEDURE GetCountryList(
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeleteAbsentSites(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_company_sid			IN security_pkg.T_SID_ID,
	in_site_ids				IN T_SITE_IDS
);
END nn_man_site_pkg;
/
