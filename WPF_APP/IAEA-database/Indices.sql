use IAEA;

drop index ind_country_name on countries;
create fulltext index ind_country_name on countries(name);

drop index ind_power_plants_name on nuclear_power_plants;
create fulltext index ind_power_plants_name on nuclear_power_plants(power_plants_name);

drop index ind_production_centers on largest_production_centers;
create fulltext index ind_production_centers on largest_production_centers(production_centers_name);

drop index ind_weapons_types on weapons_types;
create fulltext index ind_weapons_types on weapons_types(weapons_types_name);


select * from countries
where match(name) against ('*Ru*' in boolean mode);

select * from nuclear_power_plants
where match(power_plants_name) against ('*Aka*' in boolean mode);

select * from largest_production_centers
where match(production_centers_name) against ('*Em*' in boolean mode);

select * from weapons_types
where match(weapons_types_name) against ('*Dec*' in boolean mode);