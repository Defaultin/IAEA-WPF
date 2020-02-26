drop database if exists IAEA;
create database IAEA;
use IAEA;
set SQL_SAFE_UPDATES = 0;

drop user if exists simple_user;
drop user if exists trusted_user;
drop user if exists administrator;
create user simple_user identified by 'simple_user';
create user trusted_user identified by 'trusted_user';
create user administrator identified by 'administrator';
grant select on IAEA.* to simple_user;
grant all privileges on IAEA.* to trusted_user;
grant all privileges on IAEA.* to administrator with grant option;
FLUSH PRIVILEGES;


# таблица стран-учасников
drop table if exists countries;
create table countries 
select Code2 as Code,Name,Continent,Region,SurfaceArea,Population,LifeExpectancy,GNP,LocalName,GovernmentForm,HeadOfState 
from world.country 
where Code2 in 
('af','ax','al','dz','as','ad','ao','ai','aq','ag','ar','am','aw','ac','au','at','az','bs','bh','bd','bb','by','be','bz','bj','bm','bt','bo','bq','ba','bw','bv','br','io','bn','bg','bf','bi','cv','kh','cm','ca','ky','cf','td','cl','cx','cp','cc','co','km','cg','cd','ck','cr','ci','hr','cu','cw','cy','cz','dk','dj','dm','do','ec','eg','sv','gq','er','ee','et','fk','fo','fj','fi','fr','gf','pf','tf','ga','gm','ge','de','gh','gi','gr','gl','gd','gp','gu','gt','gg','gn','gw','gy','ht','hm','hn','hk','hu','is','in','id','ir','iq','ie','im','il','it','jm','jp','jo','kz','ke','ki','kp','kr','xk','kw','kg','la','lv','lb','ls','lr','ly','li','lt','lu','mo','mk','mg','mw','my','mv','ml','mt','mh','mq','mr','mu','yt','mx','fm','md','mc','mn','me','ms','ma','mz','mm','na','nr','np','nl','an','nc','nz','ni','ne','ng','nu','nf','mp','no','om','pk','pw','ps','pa','pg','py','cn','pe','ph','pn','pl','pt','pr','qa','re','ro','ru','rw','bl','sh','kn','lc','mf','pm','vc','ws','sm','st','sa','sn','rs','cs','sc','sl','sg','sx','sk','si','sb','so','za','gs','ss','es','lk','sd','sr','sj','sz','se','ch','sy','tw','tj','tz','th','tl','tg','tk','to','tt','ta','tn','tr','tm','tc','tv','ug','ua','ae','gb','us','um','zz','uy','uz','vu','va','ve','vn','vg','vi','wf','eh','ye','zm','zw');

alter table countries
modify code varchar(80) not null,
add primary key (code),
add unique key idx_name (name),
add column budget float,
add column x float,
add column y float;

update countries
set x = rand()*500, y = rand()*500, budget = rand()*1000000000;

# таблица статусов ядерных электростанций
drop table if exists nuclear_plant_status;
create table nuclear_plant_status (
  plant_status_id int not null primary key,
  plant_status_type varchar(80) not null,
  unique key idx_id (plant_status_id),
  unique key idx_type (plant_status_type)
);

# таблица типов ядерных реакторов
drop table if exists nuclear_reactor_type;
create table nuclear_reactor_type (
  reactor_type_id int not null primary key,
  reactor_type_type varchar(80) not null,
  reactor_type_description varchar(80) default null,
  unique key idx_id (reactor_type_id),
  unique key idx_type (reactor_type_type)
);

# таблица ядерных реакторов
drop table if exists nuclear_power_plants;
create table nuclear_power_plants (
  power_plants_id int not null primary key auto_increment,
  power_plants_name varchar(80) not null,
  power_plants_latitude decimal(10,6) default 50.5,
  power_plants_longitude decimal(10,6) default 25.5,
  power_plants_country_code varchar(80) not null,
  power_plants_status_id int not null,
  power_plants_reactor_type_id int default 20,
  power_plants_reactor_model varchar(80) default 'VHL-600',
  power_plants_construction_start_at date default '2000-02-05',
  power_plants_operational_from date default '2006-05-03',
  power_plants_operational_to date default '2019-08-09',
  power_plants_capacity int default 1000,
  power_plants_source varchar(80) default 'IAEA',
  power_plants_last_updated_at datetime default now(),
  unique key idx_name (power_plants_name) using btree,
  key fk_nuclear_power_plants_countries_code (power_plants_country_code) using btree,
  key fk_nuclear_power_plants_status_type_id (power_plants_status_id),
  key fk_nuclear_power_plants_nuclear_reactor_type_id (power_plants_reactor_type_id),
  constraint fk_nuclear_power_plants_countries_code foreign key (power_plants_country_code) references countries (Code),
  constraint fk_nuclear_power_plants_nuclear_reactor_type_id foreign key (power_plants_reactor_type_id) references nuclear_reactor_type (reactor_type_id),
  constraint fk_nuclear_power_plants_status_type_id foreign key (power_plants_status_id) references nuclear_plant_status (plant_status_id)
);

# таблица крупнейших отраслевых производственных центров в каждой стране
drop table if exists largest_production_centers;
create table largest_production_centers (
	production_centers_id int not null primary key auto_increment,
    production_centers_name varchar(80) not null,
    production_centers_country_code varchar(80) not null,
    production_centers_budget float not null,
	production_centers_establishment_date date,
    production_centers_founder varchar(80),
    constraint fk_largest_production_centers_countries_code foreign key (production_centers_country_code) references countries (Code)
);

# таблица видов вооружений
drop table if exists weapons_types;
create table weapons_types (
	weapons_types_id int not null primary key auto_increment,
    weapons_types_name varchar(80) not null,
    weapons_types_type varchar(80) not null,
    weapons_types_cost float not null,
	weapons_types_action_range enum('short-range','medium-range','long-range'),
    weapons_types_threat_level enum('low','medium','high')
);

# таблица-склад вооружений, произведенных отраслевыми центрами
drop table if exists weapons_warehouse;
create table weapons_warehouse (
	weapons_warehouse_id int not null primary key auto_increment,
    weapons_warehouse_ref_production_centers int not null,
    weapons_warehouse_ref_weapons_types int not null,
    weapons_warehouse_quantity int not null,
    constraint fk_weapons_production_centers foreign key (weapons_warehouse_ref_production_centers) references largest_production_centers (production_centers_id),
    constraint fk_weapons_types foreign key (weapons_warehouse_ref_weapons_types) references weapons_types (weapons_types_id)
);

# таблица вооружений стран
drop table if exists weaponry_of_countries;
create table weaponry_of_countries (
	weaponry_of_countries_id int not null primary key auto_increment,
    weaponry_of_countries_ref_country_code varchar(80) not null,
    weaponry_of_countries_ref_weapons_types int not null,
    constraint fk_weaponry_of_countries foreign key (weaponry_of_countries_ref_country_code) references countries (code),
    constraint fk_countries_weapons_types foreign key (weaponry_of_countries_ref_weapons_types) references weapons_types (weapons_types_id)
);

# Таблица военных конфликтов
drop table if exists military_conflicts;
create table military_conflicts (
	military_conflicts_id int not null primary key auto_increment,
    military_conflicts_conflicting_party_1 varchar(80) not null,
    military_conflicts_conflicting_party_2 varchar(80) not null,
    military_conflicts_start_date date,
    military_conflicts_end_date date,
    military_conflicts_conflict_cause varchar(80),
    military_conflicts_used_weapon int not null,
    constraint fk_conflicting_party_1 foreign key (military_conflicts_conflicting_party_1) references countries (code),
    constraint fk_conflicting_party_2 foreign key (military_conflicts_conflicting_party_2) references countries (code),
    constraint fk_used_weapon foreign key (military_conflicts_used_weapon) references weapons_types (weapons_types_id)
);

# Таблица незаконного обогащения ядерного топлива предпреятиями
drop table if exists fuel_enrichment;
create table fuel_enrichment (
	fuel_enrichment_id int not null primary key auto_increment,
    fuel_enrichment_enterprise int not null,
    fuel_enrichment_fuel_amount float not null,
    fuel_enrichment_time_since_start datetime,
    fuel_enrichment_fuel_type enum('metal','oxide','carbide','nitride','mixed'),
    constraint fk_enterprise foreign key (fuel_enrichment_enterprise) references largest_production_centers (production_centers_id)
);

# Таблица проверок предприятий (заполнение процедурой для выявления неполадок и небезопасных предприятий)
drop table if exists enterprise_audit_results;
create table enterprise_audit_results (
	audit_results_id int not null primary key auto_increment,
    audit_results_enterprise int not null,
    audit_results_audit_date date,
	audit_results_malfunctions_number int,
    audit_results_conclusion enum('safe', 'unsafe'),
    constraint fk_enterprise_audit foreign key (audit_results_enterprise) references largest_production_centers (production_centers_id)
);

# Таблица мероприятий и различных коммуникативных активностей стран
drop table if exists activities;
create table activities (
	activities_id int not null primary key auto_increment,
    activities_start_time datetime,
    activities_end_time datetime,
    activities_subjects varchar(80) not null,
    activities_speaker varchar(80) not null
);

# Таблица посещаемости мероприятий странами
drop table if exists activities_attendance;
create table activities_attendance (
	attendance_id int not null primary key auto_increment,
    attendance_event int not null,
    attendance_countrie varchar(80) not null,
    constraint fk_countries_attendance foreign key (attendance_countrie) references countries (code),
    constraint fk_event_attendance foreign key (attendance_event) references activities (activities_id)
);

# Таблица радиактивных отходов стран
drop table if exists nuclear_waste;
create table nuclear_waste (
	nuclear_waste_id int not null primary key auto_increment,
    nuclear_waste_country varchar(80) not null,
    nuclear_waste_volume float,
    constraint fk_countries_nuclear_waste foreign key (nuclear_waste_country) references countries (code)
);

# Таблица финансовой истории стран (заполнение процедурно при покупке или продаже вооружений)
drop table if exists financial_countries_history;
create table financial_countries_history (
	history_id int not null primary key auto_increment,
    history_purchase int not null,
    history_customer varchar(80) not null,
    history_seller int not null,
    history_order_date datetime not null,
    constraint fk_history_purchase foreign key (history_purchase) references weapons_types (weapons_types_id),
    constraint fk_history_customer foreign key (history_customer) references countries (code),
    constraint fk_history_seller foreign key (history_seller) references largest_production_centers (production_centers_id)
);

# Таблица истории инвестиций
drop table if exists investments_history;
create table investments_history (
	investments_id int not null primary key auto_increment,
    investments_value int not null,
    investments_sender varchar(80) not null,
    investments_receiver int not null,
    investments_date datetime not null,
    constraint fk_investments_receiver foreign key (investments_sender) references countries (code),
    constraint fk_investments_sender foreign key (investments_receiver) references largest_production_centers (production_centers_id)
);

# Таблица налоговой истории
drop table if exists tax_history;
create table tax_history (
	tax_id int not null primary key auto_increment,
    tax_value int not null,
    tax_sender int not null,
    tax_receiver varchar(80) not null,
    tax_date datetime not null,
    constraint fk_tax_receiver foreign key (tax_sender) references largest_production_centers (production_centers_id),
    constraint fk_tax_sender foreign key (tax_receiver) references countries (code)
);


select * from countries;
select * from nuclear_plant_status;
select * from nuclear_reactor_type;
select * from nuclear_power_plants;
select * from largest_production_centers;
select * from weapons_types;
select * from weapons_warehouse;
select * from weaponry_of_countries;
select * from military_conflicts;
select * from fuel_enrichment;
select * from enterprise_audit_results;
select * from activities;
select * from activities_attendance;
select * from nuclear_waste;
select * from financial_countries_history;
select * from investments_history;
select * from tax_history;