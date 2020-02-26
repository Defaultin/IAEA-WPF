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

insert into nuclear_plant_status(plant_status_id, plant_status_type) values
('0', 'Unknown'),
('1', 'Planned'),
('2', 'Under Construction'),
('3', 'Operational'),
('4', 'Suspended Operation'),
('5', 'Shutdown'),
('6', 'Unfinished'),
('7', 'Never Built'),
('8', 'Suspended Construction'),
('9', 'Cancelled Construction');

insert into nuclear_reactor_type(reactor_type_id,reactor_type_type,reactor_type_description) values
('1', 'ABWR', 'Advanced Boiling Water Reactor'),
('2', 'APR', 'Advanced Power Reactor'),
('3', 'APWR', 'Advanced Pressurised Water Reactor'),
('4', 'AGR', 'Advanced Gas-cooled Reactor'),
('5', 'BWR', 'Boiling Water Reactor'),
('6', 'EPR', 'Evolutionary Power Reactor'),
('7', 'FBR', 'Fast Breeder Reactor'),
('8', 'GCR', 'Gas-Cooled Reactor'),
('9', 'HTGR', 'High-Temperature Gas-cooled Reactor'),
('10', 'HTR-PM', 'High Temperature Reactor - Pebble Module'),
('11', 'HWGCR', 'Heavy Water Gas Cooled Reactor'),
('12', 'HWLWR', 'Heavy Water Light Water Reactor'),
('13', 'HWOCR', 'Heavy Water Organic Cooled Reactor'),
('14', 'LFR', 'Lead-cooled Fast Reactor'),
('15', 'LMFBR', 'Liquid Metal Fast Breeder Reactor'),
('16', 'LMFR', 'Liquid Metal Fast Reactor'),
('17', 'LWGR', 'Light Water Graphite Reactor'),
('18', 'MSR', 'Molten Salt Reactor'),
('19', 'OCR', 'Organic Cooled Reactor'),
('20', 'PHWR', 'Pressurised Heavy Water Reactor'),
('21', 'PWR', 'Pressurised Water Reactor'),
('22', 'RBMK', 'High Power Channel-Type Reactor (Reaktor Bolshoy Moshchnosti Kanalniy)'),
('23', 'SGR', 'Sodium-Graphite Reactor'),
('24', 'SGHWR', 'Steam Generating Heavy Water Reactor'),
('25', 'TWR', 'Traveling-Wave Reactor');

insert into nuclear_power_plants values
('1', 'Ågesta', '59.206000', '18.082900', 'SE', '5', '20', default, '1957-12-01', '1964-05-01', '1974-06-02', '9', 'WNA/IAEA', '2015-05-24 04:51:37'),
('2', 'Akademik Lomonosov-1 (Vilyuchinsk)', '59.919000', '30.261000', 'RU', '2', '21', 'KLT-40S \'Floating\'', '2007-04-15', default, default, '32', 'WNA/IAEA', '2015-05-24 04:54:13'),
('3', 'Akademik Lomonosov-2 (Vilyuchinsk)', '59.919000', '30.261000', 'RU', '2', '21', 'KLT-40S \'Floating\'', '2007-04-15', default, default, '32', 'WNA/IAEA', '2015-05-24 04:54:13'),
('4', 'Akhvaz-1', default, default, 'IR', '1', default, default, default, default, default, default, 'WNA', default),
('5', 'Akhvaz-2', default, default, 'IR', '1', default, default, default, default, default, default, 'WNA', default),
('6', 'Akkuyu-1', '36.144444', '33.541111', 'TR', '2', '21', 'VVER V-509', '2018-04-03', default, default, '1114', 'WNA/wikipedia/IAEA', '2018-07-01 01:21:08'),
('7', 'Akkuyu-2', '36.144444', '33.541111', 'TR', '1', '21', default, default, default, default, default, 'wikipedia', default),
('8', 'Akkuyu-3', '36.144444', '33.541111', 'TR', '1', '21', default, default, default, default, default, 'wikipedia', default),
('9', 'Akkuyu-4', '36.144444', '33.541111', 'TR', '1', '21', default, default, default, default, default, 'wikipedia', default),
('10', 'Aktau (Shevchenko)', '43.607000', '51.283000', 'KZ', '5', '7', 'BN-350', '1964-10-01', '1973-07-16', '1999-04-22', '135', 'WNA/IAEA', '2015-05-24 04:51:31'),
('11', 'Almaraz-1', '39.807000', '-5.698000', 'ES', '3', '21', 'WH 3LP', '1973-07-03', '1983-09-01', default, '900', 'WNA/IAEA', '2017-02-10 23:56:15'),
('12', 'Almaraz-2', '39.807000', '-5.698000', 'ES', '3', '21', 'WH 3LP', '1973-07-03', '1984-07-01', default, '900', 'WNA/IAEA', '2019-06-02 20:17:55'),
('13', 'Angra-1', '-23.008000', '-44.457000', 'BR', '3', '21', 'WH 2LP', '1971-05-01', '1985-01-01', default, '626', 'WNA/IAEA', '2017-02-10 23:55:45'),
('14', 'Angra-2', '-23.008000', '-44.457000', 'BR', '3', '21', 'PRE KONVOI', '1976-01-01', '2001-02-01', default, '1245', 'WNA/IAEA', '2015-05-24 04:50:19'),
('15', 'Angra-3', '-23.010000', '-44.470000', 'BR', '2', '21', 'PRE KONVOI', '2010-06-01', default, default, '1340', 'WNA/IAEA', '2018-07-01 01:21:29'),
('16', 'APS-1 Obninsk', '55.084000', '36.570000', 'RU', '5', '17', 'AM-1', '1951-01-01', '1954-12-01', '2002-04-29', '5', 'WNA/IAEA', '2015-05-24 04:51:32'),
('17', 'Arkansas Nuclear One-1 (ANO-1)', '35.310000', '-93.230000', 'US', '3', '21', 'B&W LLP (DRYAMB)', '1968-10-01', '1974-12-19', default, '850', 'WNA/IAEA', '2017-02-10 23:58:30'),
('18', 'Arkansas Nuclear One-2 (ANO-2)', '35.310000', '-93.229000', 'US', '3', '21', 'CE 2LP (DRYAMB)', '1968-12-06', '1980-03-26', default, '912', 'WNA/IAEA', '2017-02-10 23:58:53'),
('19', 'Armenia-1 (Armenian-1 / Metsamor)', '40.182000', '44.147000', 'AM', '5', '21', 'VVER V-270', '1969-07-01', '1977-10-06', '1989-02-25', '376', 'WNA/IAEA', '2015-05-24 04:48:59'),
('20', 'Armenia-2 (Armenian-2 / Metsamor)', '40.182000', '44.147000', 'AM', '3', '21', 'VVER V-270', '1975-07-01', '1980-05-03', default, '375', 'WNA/IAEA', '2015-05-24 04:49:43'),
('21', 'Armenia-3 (Armenian-3 / Metsamor)', '40.180800', '44.147200', 'AM', '1', '21', default, default, default, default, default, 'WNA', default),
('22', 'Asco-1', '41.202000', '0.571000', 'ES', '3', '21', 'WH 3LP', '1974-05-16', '1984-12-10', default, '888', 'WNA/IAEA', '2017-02-10 23:56:18'),
('23', 'Asco-2', '41.202000', '0.571000', 'ES', '3', '21', 'WH 3LP', '1975-03-07', '1986-03-31', default, '888', 'WNA/IAEA', '2017-02-10 23:56:18'),
('24', 'Atucha-1', '-33.967000', '-59.209000', 'AR', '3', '20', 'PHWR KWU', '1968-06-01', '1974-06-24', default, '319', 'WNA/IAEA', '2015-05-24 04:50:04'),
('25', 'Atucha-2', '-33.967000', '-59.209000', 'AR', '3', '20', 'PHWR KWU', '1981-07-14', '2016-05-26', default, '692', 'WNA/IAEA', '2017-09-25 03:19:13'),
('26', 'Balakovo-1', '52.092000', '47.952000', 'RU', '3', '21', 'VVER V-320', '1980-12-01', '1986-05-23', default, '950', 'WNA/IAEA', '2015-05-24 04:51:36'),
('27', 'Balakovo-2', '52.092000', '47.952000', 'RU', '3', '21', 'VVER V-320', '1981-08-01', '1988-01-18', default, '950', 'WNA/IAEA', '2015-05-24 04:51:36'),
('28', 'Balakovo-3', '52.092000', '47.952000', 'RU', '3', '21', 'VVER V-320', '1982-11-01', '1989-04-08', default, '950', 'WNA/IAEA', '2015-05-24 04:51:36'),
('29', 'Balakovo-4', '52.092000', '47.952000', 'RU', '3', '21', 'VVER V-320', '1984-04-01', '1993-12-22', default, '950', 'WNA/IAEA', '2015-05-24 04:51:36'),
('30', 'Baltic-1', '54.939000', '22.162000', 'RU', '2', '21', 'VVER V-491', '2012-02-22', default, default, '1109', 'WNA/IAEA', '2015-05-24 04:51:57'),
('31', 'Barakah-1 (Braka)', '23.952748', '52.193298', 'AE', '2', '21', 'APR-1400', '2012-07-19', default, default, '1345', 'WNA/IAEA', '2015-12-27 17:05:51'),
('32', 'Barakah-2 (Braka)', '23.952748', '52.193298', 'AE', '2', '21', 'APR-1400', '2013-04-16', default, default, '1345', 'WNA/IAEA', '2015-12-27 17:05:52'),
('33', 'Barakah-3 (Braka)', '23.952748', '52.203298', 'AE', '2', '21', 'APR-1400', '2014-09-24', default, default, '1345', 'WNA/IAEA', '2015-05-24 04:51:58'),
('34', 'Bargi-1 (Chutka-1)', default, default, 'IN', '1', '20', default, default, default, default, default, 'WNA', default),
('35', 'Bargi-2 (Chutka-2)', default, default, 'IN', '1', '20', default, default, default, default, default, 'WNA', default),
('36', 'Barseback-1', '55.745000', '12.926000', 'SE', '5', '5', 'AA-II', '1971-02-01', '1975-07-01', '1999-11-30', '570', 'WNA/IAEA', '2018-03-10 14:52:00'),
('37', 'Barseback-2', '55.745000', '12.926000', 'SE', '5', '5', 'AA-II', '1973-01-01', '1977-07-01', '2005-05-31', '570', 'WNA/IAEA', '2018-03-10 14:52:02'),
('38', 'Beaver Valley-1', '40.624000', '-80.432000', 'US', '3', '21', 'WH 3LP (DRYSUB)', '1970-06-26', '1976-10-01', default, '835', 'WNA/IAEA', '2017-02-10 23:58:44'),
('39', 'Beaver Valley-2', '40.624000', '-80.432000', 'US', '3', '21', 'WH 3LP (DRYSUB)', '1974-05-03', '1987-11-17', default, '836', 'WNA/IAEA', '2017-02-10 23:58:59'),
('40', 'Belarusian-1', '54.766667', '26.116667', 'BY', '2', '21', 'VVER V-491', '2013-11-08', default, default, '1110', 'IAEA', '2018-03-10 14:54:38'),
('41', 'Belarusian-2', '54.766667', '26.116667', 'BY', '2', '21', 'VVER V-491', '2014-04-27', default, default, '1110', 'IAEA', '2018-03-10 14:54:39'),
('42', 'Belene-1', '43.624530', '25.186750', 'BG', '9', '21', default, default, default, default, '953', 'WNA/IAEA', '2018-03-10 13:41:44'),
('43', 'Belene-2', '43.624530', '25.186500', 'BG', '9', '21', default, default, default, default, '953', 'WNA/IAEA', '2018-03-10 13:41:49'),
('44', 'Belleville-1', '47.511000', '2.871000', 'FR', '3', '21', 'P4 REP 1300', '1980-05-01', '1988-06-01', default, '1310', 'WNA/IAEA', '2015-05-24 04:51:02'),
('45', 'Belleville-2', '47.511000', '2.871000', 'FR', '3', '21', 'P4 REP 1300', '1980-08-01', '1989-01-01', default, '1310', 'WNA/IAEA', '2015-05-24 04:51:02'),
('46', 'Beloyarsk-1', '56.842000', '61.321000', 'RU', '5', '17', 'AMB-100', '1958-06-01', '1964-04-26', '1983-01-01', '102', 'WNA/IAEA', '2015-05-24 04:51:34'),
('47', 'Beloyarsk-2', '56.842000', '61.321000', 'RU', '5', '17', 'AMB-200', '1962-01-01', '1969-12-01', '1990-01-01', '146', 'WNA/IAEA', '2015-05-24 04:51:35'),
('48', 'Beloyarsk-3', '56.842000', '61.321000', 'RU', '3', '7', 'BN-600', '1969-01-01', '1981-11-01', default, '560', 'WNA/IAEA', '2015-05-24 04:51:34'),
('49', 'Beloyarsk-4', '56.842000', '61.321000', 'RU', '3', '7', 'BN-800', '2006-07-18', '2016-10-31', default, '820', 'WNA/IAEA', '2017-09-25 03:19:53'),
('50', 'Beloyarsk-5', '56.842000', '61.321000', 'RU', '1', '7', 'BN-1200', default, default, default, default, 'WNA/wikipedia', default),
('51', 'Berkeley-1', '51.692000', '-2.494000', 'GB', '5', '8', 'MAGNOX', '1957-01-01', '1962-06-12', '1989-03-31', '138', 'WNA/IAEA', '2015-05-24 04:51:19'),
('52', 'Berkeley-2', '51.692000', '-2.494000', 'GB', '5', '8', 'MAGNOX', '1957-01-01', '1962-10-20', '1988-10-26', '138', 'WNA/IAEA', '2015-05-24 04:51:19'),
('53', 'Beznau-1', '47.552000', '8.229000', 'CH', '3', '21', 'WH 2LP', '1965-09-01', '1969-12-09', default, '350', 'WNA/IAEA', '2017-02-10 23:55:57'),
('54', 'Beznau-2', '47.552000', '8.229000', 'CH', '3', '21', 'WH 2LP', '1968-01-01', '1972-03-04', default, '350', 'WNA/IAEA', '2017-02-10 23:56:05'),
('55', 'Biblis-A', '49.709000', '8.415000', 'DE', '5', '21', 'PWR', '1970-01-01', '1975-02-26', '2011-08-06', '1146', 'WNA/IAEA', '2015-05-24 04:50:42'),
('56', 'Biblis-B', '49.709000', '8.415000', 'DE', '5', '21', 'PWR', '1972-02-01', '1977-01-31', '2011-08-06', '1178', 'WNA/IAEA', '2015-05-24 04:50:42'),
('57', 'Big Rock Point', '45.359000', '-85.195000', 'US', '5', '5', default, '1960-05-01', '1963-03-29', '1997-08-29', '72', 'WNA/IAEA', '2015-05-24 04:51:41'),
('58', 'Bilibino-1', '68.059000', '166.492000', 'RU', '5', '17', 'EGP-6', '1970-01-01', '1974-04-01', '2019-01-14', '11', 'WNA/IAEA', '2019-06-02 20:18:07'),
('59', 'Bilibino-2', '68.059000', '166.492000', 'RU', '3', '17', 'EGP-6', '1970-01-01', '1975-02-01', default, '11', 'WNA/IAEA', '2015-05-24 04:51:32'),
('60', 'Bilibino-3', '68.059000', '166.492000', 'RU', '3', '17', 'EGP-6', '1970-01-01', '1976-02-01', default, '11', 'WNA/IAEA', '2015-05-24 04:51:32'),
('61', 'Bilibino-4', '68.059000', '166.492000', 'RU', '3', '17', 'EGP-6', '1970-01-01', '1977-01-01', default, '11', 'WNA/IAEA', '2015-05-24 04:51:33'),
('62', 'Blayais-1', '45.256000', '-0.691000', 'FR', '3', '21', 'CP1', '1977-01-01', '1981-12-01', default, '910', 'WNA/IAEA', '2015-05-24 04:50:53'),
('63', 'Blayais-2', '45.256000', '-0.691000', 'FR', '3', '21', 'CP1', '1977-01-01', '1983-02-01', default, '910', 'WNA/IAEA', '2015-05-24 04:50:54'),
('64', 'Blayais-3', '45.256000', '-0.691000', 'FR', '3', '21', 'CP1', '1978-04-01', '1983-11-14', default, '910', 'WNA/IAEA', '2015-05-24 04:50:54'),
('65', 'Blayais-4', '45.256000', '-0.691000', 'FR', '3', '21', 'CP1', '1978-04-01', '1983-10-01', default, '910', 'WNA/IAEA', '2015-05-24 04:50:54'),
('66', 'Bohunice-1', '48.494000', '17.687000', 'SK', '5', '21', 'VVER V-230', '1972-04-24', '1980-04-01', '2006-12-31', '408', 'WNA/IAEA', '2015-05-24 04:51:38'),
('67', 'Bohunice-2', '48.494000', '17.687000', 'SK', '5', '21', 'VVER V-230', '1972-04-24', '1981-01-01', '2008-12-31', '408', 'WNA/IAEA', '2015-05-24 04:51:38'),
('68', 'Bohunice-3', '48.494000', '17.687000', 'SK', '3', '21', 'VVER V-213', '1976-12-01', '1985-02-14', default, '408', 'WNA/IAEA', '2015-05-24 04:51:38'),
('69', 'Bohunice-4', '48.494000', '17.687000', 'SK', '3', '21', 'VVER V-213', '1976-12-01', '1985-12-18', default, '408', 'WNA/IAEA', '2015-05-24 04:51:38'),
('70', 'Bohunice-A1', '48.494000', '17.687000', 'SK', '5', '11', 'KS 150', '1958-08-01', '1972-12-25', '1977-02-22', '110', 'WNA/IAEA', '2015-05-24 04:51:38'),
('71', 'Bonus', '18.365000', '-67.268000', 'US', '5', '5', 'Superheater', '1960-01-01', '1965-09-01', '1968-06-01', '17', 'WNA/IAEA', '2015-05-24 04:51:48'),
('72', 'Borssele', '51.431000', '3.719000', 'NL', '3', '21', 'KWU 2LP', '1969-07-01', '1973-10-26', default, '495', 'WNA/IAEA', '2017-02-10 23:57:03'),
('73', 'BR-3', '51.217000', '5.099000', 'BE', '5', '21', 'Prototype', '1957-11-01', '1962-10-10', '1987-06-30', '11', 'WNA/IAEA', '2015-05-24 04:50:07'),
('74', 'Bradwell-1', '51.742000', '0.899000', 'GB', '5', '8', 'MAGNOX', '1957-01-01', '1962-07-01', '2002-03-31', '150', 'WNA/IAEA', '2015-05-24 04:51:19'),
('75', 'Bradwell-2', '51.742000', '0.899000', 'GB', '5', '8', 'MAGNOX', '1957-01-01', '1962-11-12', '2002-03-30', '150', 'WNA/IAEA', '2015-05-24 04:51:19'),
('76', 'Braidwood-1', '41.247000', '-88.230000', 'US', '3', '21', 'WH 4LP (DRYAMB)', '1975-08-01', '1988-07-29', default, '1120', 'WNA/IAEA', '2017-02-10 23:59:18'),
('77', 'Braidwood-2', '41.247000', '-88.230000', 'US', '3', '21', 'WH 4LP (DRYAMB)', '1975-08-01', '1988-10-17', default, '1120', 'WNA/IAEA', '2017-02-10 23:59:19'),
('78', 'Braka-4', '23.952748', '52.208298', 'AE', '1', '21', default, default, default, default, default, 'WNA', default),
('79', 'Brokdorf', '53.850000', '9.345000', 'DE', '3', '21', 'PWR', '1976-01-01', '1986-12-22', default, '1307', 'WNA/IAEA', '2015-05-24 04:50:46'),
('80', 'Browns Ferry-1', '34.704000', '-87.119000', 'US', '3', '5', 'BWR-4 (Mark 1)', '1967-05-01', '1974-08-01', default, '1065', 'WNA/IAEA', '2015-05-24 04:51:42'),
('81', 'Browns Ferry-2', '34.704000', '-87.119000', 'US', '3', '5', 'BWR-4 (Mark 1)', '1967-05-01', '1975-03-01', default, '1065', 'WNA/IAEA', '2015-05-24 04:51:42'),
('82', 'Browns Ferry-3', '34.704000', '-87.119000', 'US', '3', '5', 'BWR-4 (Mark 1)', '1968-07-01', '1977-03-01', default, '1065', 'WNA/IAEA', '2015-05-24 04:51:43'),
('83', 'Bruce-1', '44.341000', '-81.572000', 'CA', '3', '20', 'CANDU 791', '1971-06-01', '1977-09-01', default, '732', 'WNA/IAEA', '2015-05-24 04:50:37'),
('84', 'Bruce-2', '44.341000', '-81.572000', 'CA', '3', '20', 'CANDU 791', '1970-12-01', '1977-09-01', default, '732', 'WNA/IAEA', '2017-09-25 03:19:26'),
('85', 'Bruce-3', '44.341000', '-81.572000', 'CA', '3', '20', 'CANDU 750A', '1972-07-01', '1978-02-01', default, '750', 'WNA/IAEA', '2015-05-24 04:50:21'),
('86', 'Bruce-4', '44.341000', '-81.572000', 'CA', '3', '20', 'CANDU 750A', '1972-09-01', '1979-01-18', default, '750', 'WNA/IAEA', '2015-05-24 04:50:21'),
('87', 'Bruce-5', '44.341000', '-81.572000', 'CA', '3', '20', 'CANDU 750B', '1978-06-01', '1985-03-01', default, '822', 'WNA/IAEA', '2015-05-24 04:50:24'),
('88', 'Bruce-6', '44.341000', '-81.572000', 'CA', '3', '20', 'CANDU 750B', '1978-01-01', '1984-09-14', default, '822', 'WNA/IAEA', '2015-05-24 04:50:24'),
('89', 'Bruce-7', '44.341000', '-81.572000', 'CA', '3', '20', 'CANDU 750B', '1979-05-01', '1986-04-10', default, '822', 'WNA/IAEA', '2015-05-24 04:50:24'),
('90', 'Bruce-8', '44.341000', '-81.572000', 'CA', '3', '20', 'CANDU 750B', '1979-08-01', '1987-05-22', default, '795', 'WNA/IAEA', '2015-05-24 04:50:25'),
('91', 'Brunsbuettel', '53.891000', '9.202000', 'DE', '5', '5', 'BWR-69', '1970-04-15', '1977-02-09', '2011-08-06', '770', 'WNA/IAEA', '2015-05-24 04:50:42'),
('92', 'Brunswick-1', '33.958000', '-78.007000', 'US', '3', '5', 'BWR-4 (Mark 1)', '1970-02-07', '1977-03-18', default, '821', 'WNA/IAEA', '2015-05-24 04:51:46'),
('93', 'Brunswick-2', '33.958000', '-78.007000', 'US', '3', '5', 'BWR-4 (Mark 1)', '1970-02-07', '1975-11-03', default, '821', 'WNA/IAEA', '2015-05-24 04:51:46'),
('94', 'Bugey-1', '45.796000', '5.268000', 'FR', '5', '8', 'UNGG', '1965-12-01', '1972-07-01', '1994-05-27', '540', 'WNA/IAEA', '2015-05-24 04:51:08'),
('95', 'Bugey-2', '45.796000', '5.268000', 'FR', '3', '21', 'CP0', '1972-11-01', '1979-03-01', default, '920', 'WNA/IAEA', '2015-05-24 04:50:51'),
('96', 'Bugey-3', '45.798000', '5.268000', 'FR', '3', '21', 'CP0', '1973-09-01', '1979-03-01', default, '920', 'WNA/IAEA', '2015-05-24 04:50:51'),
('97', 'Bugey-4', '45.800000', '5.267000', 'FR', '3', '21', 'CP0', '1974-06-01', '1979-07-01', default, '900', 'WNA/IAEA', '2015-05-24 04:50:51'),
('98', 'Bugey-5', '45.800000', '5.267000', 'FR', '3', '21', 'CP0', '1974-07-01', '1980-01-03', default, '900', 'WNA/IAEA', '2015-05-24 04:50:51'),
('99', 'Bushehr-1', '28.831000', '50.887000', 'IR', '3', '21', 'VVER V-446', '1975-05-01', '2013-09-23', default, '915', 'WNA/IAEA', '2015-05-24 04:51:26'),
('100', 'Bushehr-2', '28.828700', '50.889500', 'IR', '1', '21', 'VVER', default, default, default, default, 'WNA', default),
('101', 'Bushehr-3', '28.830500', '50.887200', 'IR', '1', default, default, default, default, default, default, 'WNA', default),
('102', 'Bushehr-4', '28.830500', '50.887200', 'IR', '1', default, default, default, default, default, default, 'WNA', default),
('103', 'Byron-1', '42.074000', '-89.277000', 'US', '3', '21', 'WH 4LP (DRYAMB)', '1975-04-01', '1985-09-16', default, '1120', 'WNA/IAEA', '2017-02-10 23:59:17'),
('104', 'Byron-2', '42.074000', '-89.277000', 'US', '3', '21', 'WH 4LP (DRYAMB)', '1975-04-01', '1987-08-02', default, '1120', 'WNA/IAEA', '2017-02-10 23:59:18'),
('105', 'Calder Hall-1', '54.420000', '-3.491000', 'GB', '5', '8', 'MAGNOX', '1953-08-01', '1956-10-01', '2003-03-31', '35', 'WNA/IAEA', '2015-05-24 04:51:09'),
('106', 'Calder Hall-2', '54.420000', '-3.491000', 'GB', '5', '8', 'MAGNOX', '1953-08-01', '1957-02-01', '2003-03-31', '35', 'WNA/IAEA', '2015-05-24 04:51:09'),
('107', 'Calder Hall-3', '54.420000', '-3.491000', 'GB', '5', '8', 'MAGNOX', '1955-08-01', '1958-05-01', '2003-03-31', '35', 'WNA/IAEA', '2015-05-24 04:51:10'),
('108', 'Calder Hall-4', '54.420000', '-3.491000', 'GB', '5', '8', 'MAGNOX', '1955-08-01', '1959-04-01', '2003-03-31', '35', 'WNA/IAEA', '2015-05-24 04:51:10'),
('109', 'Callaway-1', '38.763000', '-91.781000', 'US', '3', '21', 'WH 4LP (DRYAMB)', '1975-09-01', '1984-12-19', default, '1171', 'WNA/IAEA', '2017-02-10 23:59:20'),
('110', 'Calvert Cliffs-1', '38.435000', '-76.439000', 'US', '3', '21', 'CE 2LP (DRYAMB)', '1968-06-01', '1975-05-08', default, '845', 'WNA/IAEA', '2017-02-10 23:58:35'),
('111', 'Calvert Cliffs-2', '38.435000', '-76.439000', 'US', '3', '21', 'CE 2LP (DRYAMB)', '1968-06-01', '1977-04-01', default, '845', 'WNA/IAEA', '2017-02-10 23:58:36'),
('112', 'Caorso', '45.072000', '9.872000', 'IT', '5', '5', 'BWR-4 (Mark 2)', '1970-01-01', '1981-12-01', '1990-07-01', '840', 'WNA/IAEA', '2015-05-24 04:51:26'),
('113', 'CAREM25', '-33.966667', '-59.211111', 'AR', '2', '21', 'CAREM Prototype (Integrated-PWR)', '2014-02-08', default, default, '25', 'IAEA', '2015-05-24 04:54:13'),
('114', 'Carolinas CVTR', '34.263000', '-81.330000', 'US', '5', '20', 'Prototype', '1960-01-01', '1963-12-18', '1967-01-10', '17', 'WNA/IAEA', '2017-02-10 23:57:39'),
('115', 'Catawba-1', '35.053000', '-81.071000', 'US', '3', '21', 'WH 4LP (ICECND)', '1974-05-01', '1985-06-29', default, '1145', 'WNA/IAEA', '2017-02-10 23:59:13'),
('116', 'Catawba-2', '35.053000', '-81.071000', 'US', '3', '21', 'WH 4LP (ICECND)', '1974-05-01', '1986-08-19', default, '1145', 'WNA/IAEA', '2017-02-10 23:59:14'),
('117', 'Cattenom-1', '49.416000', '6.217000', 'FR', '3', '21', 'P4 REP 1300', '1979-10-29', '1987-04-01', default, '1300', 'WNA/IAEA', '2015-05-24 04:51:01'),
('118', 'Cattenom-2', '49.416000', '6.217000', 'FR', '3', '21', 'P4 REP 1300', '1980-07-28', '1988-02-01', default, '1300', 'WNA/IAEA', '2015-05-24 04:51:02'),
('119', 'Cattenom-3', '49.416000', '6.217000', 'FR', '3', '21', 'P4 REP 1300', '1982-06-15', '1991-02-01', default, '1300', 'WNA/IAEA', '2015-05-24 04:51:04'),
('120', 'Cattenom-4', '49.416000', '6.217000', 'FR', '3', '21', 'P4 REP 1300', '1983-09-28', '1992-01-01', default, '1300', 'WNA/IAEA', '2015-05-24 04:51:06'),
('121', 'CEFR (Chinese Experimental Fast Reactor)', '39.739000', '116.030000', 'CN', '3', '7', 'BN-20', '2000-05-10', default, default, '20', 'WNA/IAEA', '2015-05-24 04:51:58'),
('122', 'Cernavoda-1', '44.322000', '28.061000', 'RO', '3', '20', 'CANDU 6', '1982-07-01', '1996-12-02', default, '650', 'WNA/IAEA', '2015-05-24 04:51:31'),
('123', 'Cernavoda-2', '44.322000', '28.061000', 'RO', '3', '20', 'CANDU 6', '1983-07-01', '2007-11-01', default, '650', 'WNA/IAEA', '2019-06-02 20:18:16'),
('124', 'Cernavoda-3', '44.324300', '28.057800', 'RO', '1', '20', default, default, default, default, default, 'WNA', default),
('125', 'Changjiang-1', '19.446000', '108.799000', 'CN', '3', '21', 'CNP-600', '2010-04-25', '2015-12-25', default, '601', 'WNA/IAEA', '2017-09-25 03:20:42'),
('126', 'Changjiang-2', '19.446000', '108.799000', 'CN', '3', '21', 'CNP-600', '2010-11-21', '2016-08-12', default, '601', 'WNA/IAEA', '2017-09-25 03:20:43'),
('127', 'Chapelcross-1', '55.014000', '-3.223000', 'GB', '5', '8', 'MAGNOX', '1955-10-01', '1959-03-01', '2004-06-29', '35', 'WNA/IAEA', '2015-05-24 04:51:17'),
('128', 'Chapelcross-2', '55.014000', '-3.223000', 'GB', '5', '8', 'MAGNOX', '1955-10-01', '1959-08-01', '2004-06-29', '35', 'WNA/IAEA', '2015-05-24 04:51:18'),
('129', 'Chapelcross-3', '55.014000', '-3.223000', 'GB', '5', '8', 'MAGNOX', '1955-10-01', '1959-12-01', '2004-06-29', '35', 'WNA/IAEA', '2015-05-24 04:51:18'),
('130', 'Chapelcross-4', '55.014000', '-3.223000', 'GB', '5', '8', 'MAGNOX', '1955-10-01', '1960-03-01', '2004-06-29', '35', 'WNA/IAEA', '2015-05-24 04:51:18'),
('131', 'Chasma-1 (Chasnupp-1)', '32.392000', '71.463000', 'PK', '3', '21', 'CNP-300', '1993-08-01', '2000-09-15', default, '300', 'WNA/IAEA', '2015-05-24 04:51:31'),
('132', 'Chasma-2 (Chasnupp-2)', '32.392000', '71.463000', 'PK', '3', '21', 'CNP-300', '2005-12-28', '2011-05-18', default, '300', 'WNA/IAEA', '2015-05-24 04:51:31'),
('133', 'Chasma-3 (Chasnupp-3)', '32.392000', '71.465000', 'PK', '3', '21', 'CNP-300', '2011-05-28', '2016-12-01', default, '315', 'WNA/IAEA', '2017-09-25 03:20:45'),
('134', 'Chasma-4 (Chasnupp-4)', '32.391944', '71.461667', 'PK', '3', '21', 'CNP-300', '2011-12-18', '2017-09-19', default, '313', 'IAEA', '2018-03-10 14:53:16'),
('135', 'Chernobyl-1', '51.389000', '30.103000', 'UA', '5', '17', 'RBMK', '1970-03-01', '1978-05-27', '1996-11-30', '925', 'WNA/IAEA', '2015-05-24 04:51:39'),
('136', 'Chernobyl-2', '51.389000', '30.103000', 'UA', '5', '17', 'RBMK', '1973-02-01', '1979-05-28', '1991-10-11', '925', 'WNA/IAEA', '2015-05-24 04:51:39'),
('137', 'Chernobyl-3', '51.389000', '30.103000', 'UA', '5', '17', 'RBMK', '1976-03-01', '1982-06-08', '2000-12-15', '925', 'WNA/IAEA', '2015-05-24 04:51:40'),
('138', 'Chernobyl-4', '51.389000', '30.103000', 'UA', '5', '17', 'RBMK', '1979-04-01', '1984-03-26', '1986-04-26', '925', 'WNA/IAEA', '2015-05-24 04:51:40'),
('139', 'Chin Shan-1', '25.292000', '121.567000', 'TW', '5', '5', 'BWR-4 (Mark 1)', '1972-06-02', '1978-12-10', '2018-12-06', '604', 'WNA/IAEA', '2019-06-02 20:18:27'),
('140', 'Chin Shan-2', '25.292000', '121.567000', 'TW', '3', '5', 'BWR-4 (Mark 1)', '1973-12-07', '1979-07-15', default, '604', 'WNA/IAEA', '2019-06-02 20:18:31'),
('141', 'Chinon-A1', '47.232000', '0.167000', 'FR', '5', '8', 'UNGG', '1957-02-01', '1964-02-01', '1973-04-16', '68', 'WNA/IAEA', '2015-05-24 04:50:52'),
('142', 'Chinon-A2', '47.232000', '0.167000', 'FR', '5', '8', 'UNGG', '1959-08-01', '1965-02-24', '1985-06-14', '170', 'WNA/IAEA', '2015-05-24 04:50:53'),
('143', 'Chinon-A3', '47.232000', '0.167000', 'FR', '5', '8', 'UNGG', '1961-03-01', '1966-08-04', '1990-06-15', '480', 'WNA/IAEA', '2015-05-24 04:50:58'),
('144', 'Chinon-B1', '47.232000', '0.167000', 'FR', '3', '21', 'CP2', '1977-03-01', '1984-02-01', default, '870', 'WNA/IAEA', '2015-05-24 04:50:58'),
('145', 'Chinon-B2', '47.232000', '0.167000', 'FR', '3', '21', 'CP2', '1977-03-01', '1984-08-01', default, '870', 'WNA/IAEA', '2015-05-24 04:50:59'),
('146', 'Chinon-B3', '47.232000', '0.167000', 'FR', '3', '21', 'CP2', '1980-10-01', '1987-03-04', default, '905', 'WNA/IAEA', '2015-05-24 04:51:03'),
('147', 'Chinon-B4', '47.232000', '0.167000', 'FR', '3', '21', 'CP2', '1981-02-01', '1988-04-01', default, '905', 'WNA/IAEA', '2015-05-24 04:51:03'),
('148', 'Chooz-A', '50.086000', '4.792000', 'FR', '5', '21', 'CHOOZ-A', '1962-01-01', '1967-04-15', '1991-10-30', '280', 'WNA/IAEA', '2015-05-24 04:51:01'),
('149', 'Chooz-B1', '50.086000', '4.792000', 'FR', '3', '21', 'N4 REP 1450', '1984-01-01', '2000-05-15', default, '1455', 'WNA/IAEA', '2015-05-24 04:51:04'),
('150', 'Chooz-B2', '50.086000', '4.792000', 'FR', '3', '21', 'N4 REP 1450', '1985-12-31', '2000-09-29', default, '1455', 'WNA/IAEA', '2015-05-24 04:51:06'),
('151', 'Civaux-1', '46.457000', '0.654000', 'FR', '3', '21', 'N4 REP 1450', '1988-10-15', '2002-01-29', default, '1450', 'WNA/IAEA', '2015-05-24 04:51:07'),
('152', 'Civaux-2', '46.457000', '0.654000', 'FR', '3', '21', 'N4 REP 1450', '1991-04-01', '2002-04-23', default, '1450', 'WNA/IAEA', '2015-05-24 04:51:07'),
('153', 'Clinton-1', '40.172000', '-88.834000', 'US', '3', '5', 'BWR-6 (Mark 3)', '1975-10-01', '1987-11-24', default, '950', 'WNA/IAEA', '2015-05-24 04:51:49'),
('154', 'Cofrentes', '39.216000', '-1.051000', 'ES', '3', '5', 'BWR-6 (Mark 3)', '1975-09-09', '1985-03-11', default, '939', 'WNA/IAEA', '2017-02-10 23:56:09'),
('155', 'Columbia (WNP-2)', '46.471000', '-119.333000', 'US', '3', '5', 'BWR-5 (Mark 2)', '1972-08-01', '1984-12-13', default, '1100', 'WNA/IAEA', '2015-05-24 04:51:48'),
('156', 'Comanche Peak-1', '32.301000', '-97.787000', 'US', '3', '21', 'WH 4LP (DRYAMB)', '1974-12-19', '1990-08-13', default, '1150', 'WNA/IAEA', '2017-02-10 23:59:17'),
('157', 'Comanche Peak-2', '32.301000', '-97.787000', 'US', '3', '21', 'WH 4LP (DRYAMB)', '1974-12-19', '1993-08-03', default, '1150', 'WNA/IAEA', '2017-02-10 23:59:17'),
('158', 'Cooper', '40.361000', '-95.643000', 'US', '3', '5', 'BWR-4 (Mark 1)', '1968-06-01', '1974-07-01', default, '778', 'WNA/IAEA', '2015-05-24 04:51:43'),
('159', 'Cruas-1', '44.634000', '4.757000', 'FR', '3', '21', 'CP2', '1978-08-01', '1984-04-02', default, '880', 'WNA/IAEA', '2015-05-24 04:50:59'),
('160', 'Cruas-2', '44.634000', '4.757000', 'FR', '3', '21', 'CP2', '1978-11-15', '1985-04-01', default, '915', 'WNA/IAEA', '2015-05-24 04:50:59'),
('161', 'Cruas-3', '44.634000', '4.757000', 'FR', '3', '21', 'CP2', '1979-04-15', '1984-09-10', default, '880', 'WNA/IAEA', '2015-05-24 04:50:59'),
('162', 'Cruas-4', '44.634000', '4.757000', 'FR', '3', '21', 'CP2', '1979-10-01', '1985-02-11', default, '880', 'WNA/IAEA', '2015-05-24 04:51:00'),
('163', 'Crystal River-3', '28.966000', '-82.697000', 'US', '5', '21', 'B&W LLP (DRYAMB)', '1968-09-25', '1977-03-13', '2013-02-05', '825', 'WNA/IAEA', '2017-02-10 23:58:22'),
('164', 'Dampierre-1', '47.732000', '2.513000', 'FR', '3', '21', 'CP1', '1975-02-01', '1980-09-10', default, '890', 'WNA/IAEA', '2015-05-24 04:50:53'),
('165', 'Dampierre-2', '47.732000', '2.513000', 'FR', '3', '21', 'CP1', '1975-04-01', '1981-02-16', default, '890', 'WNA/IAEA', '2015-05-24 04:50:53'),
('166', 'Dampierre-3', '47.732000', '2.513000', 'FR', '3', '21', 'CP1', '1975-09-01', '1981-05-27', default, '890', 'WNA/IAEA', '2015-05-24 04:50:53'),
('167', 'Dampierre-4', '47.732000', '2.513000', 'FR', '3', '21', 'CP1', '1975-12-01', '1981-11-20', default, '890', 'WNA/IAEA', '2015-05-24 04:50:53'),
('168', 'Darkhovin', '30.707778', '48.380000', 'IR', '2', '21', default, default, default, default, default, 'wikipedia', default),
('169', 'Darlington-1', '43.867000', '-78.724000', 'CA', '3', '20', 'CANDU 850', '1982-04-01', '1992-11-14', default, '881', 'WNA/IAEA', '2015-05-24 04:50:25'),
('170', 'Darlington-2', '43.867000', '-78.724000', 'CA', '3', '20', 'CANDU 850', '1981-09-01', '1990-10-09', default, '881', 'WNA/IAEA', '2015-05-24 04:50:26'),
('171', 'Darlington-3', '43.867000', '-78.724000', 'CA', '3', '20', 'CANDU 850', '1984-09-01', '1993-02-14', default, '881', 'WNA/IAEA', '2015-05-24 04:50:26'),
('172', 'Darlington-4', '43.867000', '-78.724000', 'CA', '3', '20', 'CANDU 850', '1985-07-01', '1993-06-14', default, '881', 'WNA/IAEA', '2015-05-24 04:50:26'),
('173', 'Darlington-5', '43.864400', '-78.724400', 'CA', '1', '20', default, default, default, default, default, 'WNA', default),
('174', 'Darlington-6', '43.863300', '-78.724400', 'CA', '1', '20', default, default, default, default, default, 'WNA', default),
('175', 'Davis Besse-1', '41.597000', '-83.092000', 'US', '3', '21', 'B&W RLP (DRYAMB)', '1970-09-01', '1978-07-31', default, '906', 'WNA/IAEA', '2017-02-10 23:58:51'),
('176', 'Daya Bay-1 (Guangdong-1)', '22.599000', '114.544000', 'CN', '3', '21', 'M310', '1987-08-07', '1994-02-01', default, '930', 'WNA/IAEA', '2015-05-24 04:50:39'),
('177', 'Daya Bay-2 (Guangdong-2)', '22.599000', '114.544000', 'CN', '3', '21', 'M310', '1988-04-07', '1994-05-06', default, '930', 'WNA/IAEA', '2015-05-24 04:50:39'),
('178', 'Diablo Canyon-1', '35.212000', '-120.854000', 'US', '3', '21', 'WH 4LP (DRYAMB)', '1968-04-23', '1985-05-07', default, '1084', 'WNA/IAEA', '2017-02-10 23:58:09'),
('179', 'Diablo Canyon-2', '35.212000', '-120.854000', 'US', '3', '21', 'WH 4LP (DRYAMB)', '1970-12-09', '1986-03-13', default, '1106', 'WNA/IAEA', '2017-02-10 23:58:39'),
('180', 'Doel-1', '51.323000', '4.259000', 'BE', '3', '21', 'WH 2LP', '1969-07-01', '1975-02-15', default, '392', 'WNA/IAEA', '2017-02-10 23:55:14'),
('181', 'Doel-2', '51.323000', '4.259000', 'BE', '3', '21', 'WH 2LP', '1971-09-01', '1975-12-01', default, '392', 'WNA/IAEA', '2017-02-10 23:55:28'),
('182', 'Doel-3', '51.323000', '4.259000', 'BE', '3', '21', 'WH 3LP', '1975-01-01', '1982-10-01', default, '890', 'WNA/IAEA', '2017-02-10 23:55:35'),
('183', 'Doel-4', '51.323000', '4.259000', 'BE', '3', '21', 'WH 3LP', '1978-12-01', '1985-07-01', default, '1000', 'WNA/IAEA', '2017-02-10 23:55:43'),
('184', 'Donald Cook-1', '41.975000', '-86.564000', 'US', '3', '21', 'WH 4LP (ICECDN)', '1969-03-25', '1975-08-28', default, '1030', 'WNA/IAEA', '2017-02-10 23:58:31'),
('185', 'Donald Cook-2', '41.975000', '-86.564000', 'US', '3', '21', 'WH 4LP (ICECDN)', '1969-03-25', '1978-07-01', default, '1100', 'WNA/IAEA', '2017-02-10 23:58:33'),
('186', 'Douglas Point', '44.326000', '-81.601000', 'CA', '5', '20', 'CANDU 200', '1960-02-01', '1968-09-26', '1984-05-04', '203', 'WNA/IAEA', '2015-05-24 04:50:24'),
('187', 'Dounreay DFR', '58.577000', '-3.745000', 'GB', '5', '7', default, '1955-03-01', '1962-10-01', '1977-03-01', '14', 'WNA/IAEA', '2015-05-24 04:51:14'),
('188', 'Dounreay PFR', '58.577000', '-3.745000', 'GB', '5', '7', default, '1966-01-01', '1976-07-01', '1994-03-31', '234', 'WNA/IAEA', '2015-05-24 04:51:14'),
('189', 'Dresden-1', '41.353000', '-88.349000', 'US', '5', '5', default, '1956-05-01', '1960-07-04', '1978-10-31', '192', 'WNA/IAEA', '2015-05-24 04:51:40'),
('190', 'Dresden-2', '41.353000', '-88.349000', 'US', '3', '5', 'BWR-3 (Mark 1)', '1966-01-10', '1970-06-09', default, '794', 'WNA/IAEA', '2015-05-24 04:51:41'),
('191', 'Dresden-3', '41.353000', '-88.349000', 'US', '3', '5', 'BWR-3 (Mark 1)', '1966-10-14', '1971-11-16', default, '794', 'WNA/IAEA', '2015-05-24 04:51:41'),
('192', 'Duane Arnold-1', '42.101000', '-91.776000', 'US', '3', '5', 'BWR-4 (Mark 1)', '1970-06-22', '1975-02-01', default, '538', 'WNA/IAEA', '2015-05-24 04:51:47'),
('193', 'Dukovany-1', '49.089000', '16.149000', 'CZ', '3', '21', 'VVER V-213', '1979-01-01', '1985-05-03', default, '420', 'WNA/IAEA', '2015-05-24 04:50:41'),
('194', 'Dukovany-2', '49.089000', '16.149000', 'CZ', '3', '21', 'VVER V-213', '1979-01-01', '1986-03-21', default, '420', 'WNA/IAEA', '2015-05-24 04:50:42'),
('195', 'Dukovany-3', '49.089000', '16.149000', 'CZ', '3', '21', 'VVER V-213', '1979-03-01', '1986-12-20', default, '420', 'WNA/IAEA', '2015-05-24 04:50:42'),
('196', 'Dukovany-4', '49.089000', '16.149000', 'CZ', '3', '21', 'VVER V-213', '1979-03-01', '1987-07-19', default, '420', 'WNA/IAEA', '2015-05-24 04:50:42'),
('197', 'Dungeness-A1', '50.914000', '0.962000', 'GB', '5', '8', 'MAGNOX', '1960-07-01', '1965-10-28', '2006-12-31', '275', 'WNA/IAEA', '2015-05-24 04:51:20'),
('198', 'Dungeness-A2', '50.914000', '0.962000', 'GB', '5', '8', 'MAGNOX', '1960-07-01', '1965-12-30', '2006-12-31', '275', 'WNA/IAEA', '2015-05-24 04:51:20'),
('199', 'Dungeness-B1', '50.914000', '0.962000', 'GB', '3', '8', 'AGR', '1965-10-01', '1985-04-01', default, '607', 'WNA/IAEA', '2015-05-24 04:51:16'),
('200', 'Dungeness-B2', '50.914000', '0.962000', 'GB', '3', '8', 'AGR', '1965-10-01', '1989-04-01', default, '607', 'WNA/IAEA', '2015-05-24 04:51:16'),
('201', 'El Dabaa-1', '31.033333', '28.433333', 'EG', '1', default, default, default, default, default, default, 'WNA', default),
('202', 'EL-4 (Monts D\'Arree)', '48.350000', '-3.866667', 'FR', '5', '11', 'Monts-D\'Arree', '1962-07-01', '1968-06-01', '1985-07-31', '70', 'IAEA', '2015-05-24 05:20:27'),
('203', 'Elk River', '45.297000', '-93.557000', 'US', '5', '5', default, '1959-01-01', '1964-07-01', '1968-02-01', '22', 'WNA/IAEA', '2015-05-24 04:51:40'),
('204', 'Embalse', '-32.232000', '-64.442000', 'AR', '3', '20', 'CANDU 6', '1974-04-01', '1984-01-20', default, '600', 'WNA/IAEA', '2015-05-24 04:50:06'),
('205', 'Emsland', '52.471000', '7.322000', 'DE', '3', '21', 'Konvoi', '1982-08-10', '1988-06-20', default, '1242', 'WNA/IAEA', '2015-05-24 04:50:46'),
('206', 'Enrico Fermi', '45.183333', '8.283333', 'IT', '5', '21', 'WH 4LP', '1961-07-01', '1965-01-01', '1990-07-01', '247', 'IAEA', '2017-02-10 23:56:19'),
('207', 'Enrico Fermi-1', '41.960000', '-83.257000', 'US', '5', '7', 'Liquid Metal FBR', '1956-08-08', '1966-08-07', '1972-11-29', '60', 'WNA/IAEA', '2017-02-10 23:57:45'),
('208', 'Enrico Fermi-2', '41.960000', '-83.257000', 'US', '3', '5', 'BWR-4 (Mark 1)', '1972-09-26', '1988-01-23', default, '1093', 'WNA/IAEA', '2015-05-24 04:51:47'),
('209', 'Fangchenggang-1 ', '21.600000', '108.300000', 'CN', '3', '21', 'CPR-1000', '2010-07-30', '2016-01-01', default, '1000', 'WNA/IAEA', '2016-03-09 18:44:12'),
('210', 'Fangchenggang-2', '21.600000', '108.300000', 'CN', '3', '21', 'CPR-1000', '2010-12-23', '2016-10-01', default, '1000', 'WNA/IAEA', '2017-02-10 23:59:36'),
('211', 'Fangjiashan-1', '30.416000', '120.951000', 'CN', '3', '21', 'CPR-1000', '2008-12-26', '2014-12-15', default, '1000', 'WNA/IAEA', '2015-05-24 04:51:56'),
('212', 'Fangjiashan-2', '30.416000', '120.951000', 'CN', '3', '21', 'CPR-1000', '2009-07-17', '2015-02-12', default, '1000', 'WNA/IAEA', '2015-05-24 04:51:56'),
('213', 'Farley-1', '31.223000', '-85.115000', 'US', '3', '21', 'WH 3LP (DRYAMB)', '1970-10-01', '1977-12-01', default, '829', 'WNA/IAEA', '2017-02-10 23:58:52'),
('214', 'Farley-2', '31.223000', '-85.115000', 'US', '3', '21', 'WH 3LP (DRYAMB)', '1970-10-01', '1981-07-30', default, '829', 'WNA/IAEA', '2017-02-10 23:58:53'),
('215', 'Fessenheim-1', '47.903000', '7.564000', 'FR', '3', '21', 'CP0', '1971-09-01', '1978-01-01', default, '880', 'WNA/IAEA', '2015-05-24 04:50:51'),
('216', 'Fessenheim-2', '47.903000', '7.564000', 'FR', '3', '21', 'CP0', '1972-02-01', '1978-04-01', default, '880', 'WNA/IAEA', '2015-05-24 04:50:51'),
('217', 'FitzPatrick', '43.521000', '-76.403000', 'US', '3', '5', 'BWR-4 (Mark 1)', '1968-09-01', '1975-07-28', default, '821', 'WNA/IAEA', '2015-05-24 04:51:47'),
('218', 'Flamanville-1', '49.537000', '-1.881000', 'FR', '3', '21', 'P4 REP 1300', '1979-12-01', '1986-12-01', default, '1330', 'WNA/IAEA', '2015-05-24 04:51:00'),
('219', 'Flamanville-2', '49.537000', '-1.881000', 'FR', '3', '21', 'P4 REP 1300', '1980-05-01', '1987-03-09', default, '1330', 'WNA/IAEA', '2015-05-24 04:51:00'),
('220', 'Flamanville-3', '49.537000', '-1.881000', 'FR', '2', '21', 'EPR', '2007-12-03', default, default, '1630', 'WNA/IAEA', '2015-05-24 04:51:51'),
('221', 'Forsmark-1', '60.405000', '18.168000', 'SE', '3', '5', 'AA-III, BWR-2500', '1973-06-01', '1980-12-10', default, '900', 'WNA/IAEA', '2018-03-10 14:52:03'),
('222', 'Forsmark-2', '60.405000', '18.168000', 'SE', '3', '5', 'AA-III, BWR-2500', '1975-01-01', '1981-07-07', default, '900', 'WNA/IAEA', '2018-03-10 14:51:47'),
('223', 'Forsmark-3', '60.405000', '18.168000', 'SE', '3', '5', 'AA-IV, BWR-3000', '1979-01-01', '1985-08-18', default, '1050', 'WNA/IAEA', '2018-03-10 14:51:53'),
('224', 'Fort Calhoun-1', '41.520000', '-96.076000', 'US', '5', '21', 'CE 2LP', '1968-06-07', '1973-09-26', '2016-10-24', '478', 'WNA/IAEA', '2017-02-10 23:58:13'),
('225', 'Fort St. Vrain', '40.244000', '-104.874000', 'US', '5', '9', default, '1968-09-01', '1979-07-01', '1989-08-29', '330', 'WNA/IAEA', '2015-05-24 04:51:42'),
('226', 'Fugen ATR', '35.751000', '136.020000', 'JP', '5', '12', 'ATR', '1972-05-10', '1979-03-20', '2003-03-29', '148', 'WNA/IAEA', '2015-05-24 04:51:28'),
('227', 'Fukushima-Daiichi-1', '37.423000', '141.032000', 'JP', '5', '5', 'BWR-3', '1967-07-25', '1971-03-26', '2011-05-19', '439', 'WNA/IAEA', '2015-05-24 04:51:30'),
('228', 'Fukushima-Daiichi-2', '37.423000', '141.032000', 'JP', '5', '5', 'BWR-4', '1969-06-09', '1974-07-18', '2011-05-19', '760', 'WNA/IAEA', '2015-05-24 04:51:30'),
('229', 'Fukushima-Daiichi-3', '37.423000', '141.032000', 'JP', '5', '5', 'BWR-4', '1970-12-28', '1976-03-27', '2011-05-19', '760', 'WNA/IAEA', '2015-05-24 04:51:27'),
('230', 'Fukushima-Daiichi-4', '37.423000', '141.032000', 'JP', '5', '5', 'BWR-4', '1973-02-12', '1978-10-12', '2011-05-19', '760', 'WNA/IAEA', '2015-05-24 04:51:27'),
('231', 'Fukushima-Daiichi-5', '37.423000', '141.032000', 'JP', '5', '5', 'BWR-4', '1972-05-22', '1978-04-18', '2013-12-17', '760', 'WNA/IAEA', '2015-05-24 04:51:27'),
('232', 'Fukushima-Daiichi-6', '37.423000', '141.032000', 'JP', '5', '5', 'BWR-5', '1973-10-26', '1979-10-24', '2013-12-17', '1067', 'WNA/IAEA', '2015-05-24 04:51:27'),
('233', 'Fukushima-Daini-1', '37.315000', '141.024000', 'JP', '3', '5', 'BWR-5', '1976-03-16', '1982-04-20', default, '1067', 'WNA/IAEA', '2015-05-24 04:51:28'),
('234', 'Fukushima-Daini-2', '37.315000', '141.024000', 'JP', '3', '5', 'BWR-5', '1979-05-25', '1984-02-03', default, '1067', 'WNA/IAEA', '2015-05-24 04:51:28'),
('235', 'Fukushima-Daini-3', '37.315000', '141.024000', 'JP', '3', '5', 'BWR-5', '1981-03-23', '1985-06-21', default, '1067', 'WNA/IAEA', '2015-05-24 04:51:29'),
('236', 'Fukushima-Daini-4', '37.315000', '141.024000', 'JP', '3', '5', 'BWR-5', '1981-05-28', '1987-08-25', default, '1067', 'WNA/IAEA', '2015-05-24 04:51:29'),
('237', 'Fuqing-1', '25.443000', '119.453000', 'CN', '3', '21', 'CNP-1000', '2008-11-21', '2014-11-22', default, '1000', 'WNA/IAEA', '2016-03-09 18:43:50'),
('238', 'Fuqing-2', '25.443000', '119.453000', 'CN', '3', '21', 'CNP-1000', '2009-06-17', '2015-10-16', default, '1000', 'WNA/IAEA', '2016-03-09 18:43:55'),
('239', 'Fuqing-3', '25.720278', '119.383889', 'CN', '3', '21', 'CNP-1000', '2010-12-31', '2016-10-24', default, '1000', 'WNA/IAEA', '2017-02-10 23:59:36'),
('240', 'Fuqing-4', '25.720278', '119.383889', 'CN', '3', '21', 'CNP-1000', '2012-11-17', '2017-09-17', default, '1000', 'WNA/IAEA', '2018-03-10 14:52:08'),
('241', 'Fuqing-5', '25.720278', '119.383889', 'CN', '2', '21', 'HPR1000', '2015-05-07', default, default, '1000', 'WNA/IAEA', '2016-03-09 18:44:04'),
('242', 'Fuqing-6', '25.720278', '119.383889', 'CN', '2', '21', 'HPR1000', '2015-12-22', default, default, '1000', 'WNA/wikipedia/IAEA', '2016-03-09 18:44:14'),
('243', 'G-2 (Marcoule)', '44.142000', '4.713000', 'FR', '5', '8', default, '1955-03-01', '1959-04-22', '1980-02-02', '36', 'WNA/IAEA', '2015-05-24 04:50:51'),
('244', 'G-3 (Marcoule)', '44.142000', '4.713000', 'FR', '5', '8', default, '1956-03-01', '1960-04-04', '1984-06-20', '36', 'WNA/IAEA', '2015-05-24 04:50:50'),
('245', 'Garigliano', '41.258000', '13.835000', 'IT', '5', '5', 'BWR-1', '1959-11-01', '1964-06-01', '1982-03-01', '150', 'WNA/IAEA', '2015-05-24 04:51:26'),
('246', 'Ge Vallecitos', '37.613056', '-121.840000', 'US', '5', '5', '25', '1956-01-01', '1957-10-19', '1963-12-09', '24', 'IAEA', '2015-05-24 04:51:55'),
('247', 'Genkai-1', '33.518000', '129.837000', 'JP', '5', '21', 'M (2-loop)', '1971-09-15', '1975-10-15', '2015-04-27', '529', 'WNA/IAEA', '2015-05-24 04:51:27'),
('248', 'Genkai-2', '33.518000', '129.837000', 'JP', '3', '21', 'M (2-loop)', '1977-02-01', '1981-03-30', default, '529', 'WNA/IAEA', '2015-05-24 04:51:28'),
('249', 'Genkai-3', '33.518000', '129.837000', 'JP', '3', '21', 'M (4-loop)', '1988-06-01', '1994-03-18', default, '1127', 'WNA/IAEA', '2015-05-24 04:51:29'),
('250', 'Genkai-4', '33.518000', '129.837000', 'JP', '3', '21', 'M (4-loop)', '1992-07-15', '1997-07-25', default, '1127', 'WNA/IAEA', '2015-05-24 04:51:29'),
('251', 'Gentilly-1 (Demo)', '46.395000', '-72.357000', 'CA', '5', '12', 'HW BLWR 250', '1966-09-01', '1972-05-01', '1977-06-01', '250', 'WNA/IAEA', '2015-05-24 04:50:26'),
('252', 'Gentilly-2', '46.395000', '-72.357000', 'CA', '5', '20', 'CANDU 6', '1974-04-01', '1983-10-01', '2012-12-28', '645', 'WNA/IAEA', '2015-05-24 04:50:21'),
('253', 'GKN Dodewaard', '51.899000', '5.687000', 'NL', '5', '5', 'GE design', '1965-05-01', '1969-03-26', '1997-03-26', '54', 'WNA/IAEA', '2015-05-24 04:51:31'),
('254', 'Goesgen', '47.366000', '7.969000', 'CH', '3', '21', 'PWR 3 Loop', '1973-12-01', '1979-11-01', default, '920', 'WNA/IAEA', '2015-05-24 04:50:38'),
('255', 'Golfech-1', '44.105000', '0.845000', 'FR', '3', '21', 'P4 REP 1300', '1982-11-17', '1991-02-01', default, '1310', 'WNA/IAEA', '2015-05-24 04:51:04'),
('256', 'Golfech-2', '44.105000', '0.845000', 'FR', '3', '21', 'P4 REP 1300', '1984-10-01', '1994-03-04', default, '1310', 'WNA/IAEA', '2015-05-24 04:51:06'),
('257', 'Grafenrheinfeld', '49.984000', '10.186000', 'DE', '5', '21', 'PWR', '1975-01-01', '1982-06-17', '2015-06-27', '1225', 'WNA/IAEA', '2015-08-23 03:28:22'),
('258', 'Grand Gulf-1', '32.007000', '-91.045000', 'US', '3', '5', 'BWR-6 (Mark 3)', '1974-05-04', '1985-07-01', default, '1250', 'WNA/IAEA', '2015-05-24 04:51:49'),
('259', 'Gravelines-1', '51.014000', '2.138000', 'FR', '3', '21', 'CP1', '1975-02-01', '1980-11-25', default, '910', 'WNA/IAEA', '2015-05-24 04:50:52'),
('260', 'Gravelines-2', '51.014000', '2.138000', 'FR', '3', '21', 'CP1', '1975-03-01', '1980-12-01', default, '910', 'WNA/IAEA', '2015-05-24 04:50:52'),
('261', 'Gravelines-3', '51.014000', '2.138000', 'FR', '3', '21', 'CP1', '1975-12-01', '1981-06-01', default, '910', 'WNA/IAEA', '2015-05-24 04:50:53'),
('262', 'Gravelines-4', '51.014000', '2.138000', 'FR', '3', '21', 'CP1', '1976-04-01', '1981-10-01', default, '910', 'WNA/IAEA', '2015-05-24 04:50:53'),
('263', 'Gravelines-5', '51.014000', '2.138000', 'FR', '3', '21', 'CP1', '1979-10-01', '1985-01-15', default, '910', 'WNA/IAEA', '2015-05-24 04:51:01'),
('264', 'Gravelines-6', '51.014000', '2.138000', 'FR', '3', '21', 'CP1', '1979-10-01', '1985-10-25', default, '910', 'WNA/IAEA', '2015-05-24 04:51:02'),
('265', 'Greifswald-1', '54.143000', '13.668000', 'DE', '5', '21', 'VVER V-230', '1970-03-01', '1974-07-12', '1990-02-14', '440', 'WNA/IAEA', '2015-05-24 04:50:47'),
('266', 'Greifswald-2', '54.143000', '13.668000', 'DE', '5', '21', 'VVER V-230', '1970-03-01', '1975-04-16', '1990-02-14', '408', 'WNA/IAEA', '2015-05-24 04:50:47'),
('267', 'Greifswald-3', '54.143000', '13.668000', 'DE', '5', '21', 'VVER V-230', '1972-04-01', '1978-05-01', '1990-02-28', '408', 'WNA/IAEA', '2015-05-24 04:50:47'),
('268', 'Greifswald-4', '54.143000', '13.668000', 'DE', '5', '21', 'VVER V-230', '1972-04-01', '1979-11-01', '1990-07-22', '408', 'WNA/IAEA', '2015-05-24 04:50:47'),
('269', 'Greifswald-5', '54.143000', '13.668000', 'DE', '5', '21', 'VVER V-213', '1976-12-01', '1989-11-01', '1989-11-24', '408', 'WNA/IAEA', '2015-05-24 04:50:47'),
('270', 'Grohnde', '52.033000', '9.412000', 'DE', '3', '21', 'PWR', '1976-06-01', '1985-02-01', default, '1289', 'WNA/IAEA', '2015-05-24 04:50:46'),
('271', 'Grosswelzheim', '50.055000', '8.985000', 'DE', '5', '5', 'Superheated steam reactor', '1965-01-01', '1970-08-02', '1971-04-20', '23', 'WNA/IAEA', '2015-05-24 04:54:05'),
('272', 'Gundremmingen-A', '48.513000', '10.401000', 'DE', '5', '5', default, '1962-12-12', '1967-04-12', '1977-01-13', '237', 'WNA/IAEA', '2015-05-24 04:50:46'),
('273', 'Gundremmingen-B', '48.513000', '10.401000', 'DE', '5', '5', 'BWR-72', '1976-07-20', '1984-07-19', '2017-12-31', '1244', 'WNA/IAEA', '2018-03-10 14:51:13'),
('274', 'Gundremmingen-C', '48.513000', '10.401000', 'DE', '3', '5', 'BWR-72', '1976-07-20', '1985-01-18', default, '1249', 'WNA/IAEA', '2015-05-24 04:50:46'),
('275', 'H. B. Robinson-2', '34.402000', '-80.158000', 'US', '3', '21', 'WH 3LP (DRYAMB)', '1967-04-13', '1971-03-07', default, '700', 'WNA/IAEA', '2017-02-10 23:58:01'),
('276', 'Haddam Neck', '41.483000', '-72.500000', 'US', '5', '21', default, '1964-05-01', '1968-01-01', '1996-12-05', '582', 'WNA/IAEA', '2015-05-24 04:51:41'),
('277', 'Haiyang-1', '36.704000', '121.382000', 'CN', '3', '21', 'AP-1000', '2009-09-24', '2018-10-22', default, '1126', 'WNA/IAEA', '2019-06-02 20:18:34'),
('278', 'Haiyang-2', '36.704000', '121.382000', 'CN', '3', '21', 'AP-1000', '2010-06-20', '2019-01-09', default, '1126', 'WNA/IAEA', '2019-06-02 20:18:37'),
('279', 'Haiyang-3', '36.704000', '121.382000', 'CN', '1', '21', 'AP-1000', default, default, default, default, 'WNA/IAEA', default),
('280', 'Haiyang-4', '36.704000', '121.382000', 'CN', '1', '21', 'AP-1000', default, default, default, default, 'WNA/IAEA', default),
('281', 'Hallam', '40.559000', '-96.785000', 'US', '5', '19', 'LMGMR (SGR-Sodium cooled graphite moderated reactor)', '1959-01-01', '1963-11-01', '1964-09-01', '75', 'WNA/IAEA', '2015-08-23 03:28:28'),
('282', 'Hamaoka-1', '34.621000', '138.141000', 'JP', '5', '5', 'BWR-4', '1971-06-10', '1976-03-17', '2009-01-30', '516', 'WNA/IAEA', '2015-05-24 04:51:27'),
('283', 'Hamaoka-2', '34.621000', '138.141000', 'JP', '5', '5', 'BWR-4', '1974-06-14', '1978-11-29', '2009-01-30', '814', 'WNA/IAEA', '2015-05-24 04:51:28'),
('284', 'Hamaoka-3', '34.621000', '138.141000', 'JP', '3', '5', 'BWR-5', '1983-04-18', '1987-08-28', default, '1056', 'WNA/IAEA', '2015-05-24 04:51:29'),
('285', 'Hamaoka-4', '34.621000', '138.141000', 'JP', '3', '5', 'BWR-5', '1989-10-13', '1993-09-03', default, '1092', 'WNA/IAEA', '2015-05-24 04:51:29'),
('286', 'Hamaoka-5', '34.621000', '138.141000', 'JP', '3', '5', 'ABWR', '2000-07-12', '2005-01-18', default, '1325', 'WNA/IAEA', '2015-05-24 04:51:50'),
('287', 'Hamaoka-6', '34.621000', '138.141000', 'JP', '1', '1', default, default, default, default, default, 'WNA', default),
('288', 'Hanbit-1', '35.405000', '126.410000', 'KR', '3', '21', 'WH F', '1981-06-04', '1986-08-25', default, '903', 'IAEA', '2015-05-24 05:20:28'),
('289', 'Hanbit-2', '35.405000', '126.410000', 'KR', '3', '21', 'WH F', '1981-12-01', '1987-06-10', default, '903', 'IAEA', '2017-02-10 23:56:56'),
('290', 'Hanbit-3', '35.405000', '126.410000', 'KR', '3', '21', 'OPR-1000', '1989-12-23', '1995-03-31', default, '950', 'IAEA', '2015-05-24 05:20:27'),
('291', 'Hanbit-4', '35.405000', '126.410000', 'KR', '3', '21', 'OPR-1000', '1990-05-26', '1996-01-01', default, '950', 'IAEA', '2015-05-24 05:20:27'),
('292', 'Hanbit-5', '35.405000', '126.410000', 'KR', '3', '21', 'OPR-1000', '1997-06-29', '2002-05-21', default, '950', 'IAEA', '2015-05-24 05:20:28'),
('293', 'Hanbit-6', '35.405000', '126.410000', 'KR', '3', '21', 'OPR-1000', '1997-11-20', '2002-12-24', default, '950', 'IAEA', '2015-05-24 05:20:28'),
('294', 'Hanul-1', '37.090000', '129.384444', 'KR', '3', '21', 'France CPI', '1983-01-26', '1988-09-10', default, '903', 'IAEA', '2015-05-24 05:20:28'),
('295', 'Hanul-2', '37.090000', '129.384444', 'KR', '3', '21', 'France CPI', '1983-07-05', '1989-09-30', default, '903', 'IAEA', '2015-05-24 05:20:27'),
('296', 'Hanul-3', '37.090000', '129.384444', 'KR', '3', '21', 'OPR-1000', '1993-07-21', '1998-08-11', default, '950', 'IAEA', '2015-05-24 05:20:28'),
('297', 'Hanul-4', '37.090000', '129.384444', 'KR', '3', '21', 'OPR-1000', '1993-11-01', '1999-12-31', default, '950', 'IAEA', '2015-05-24 05:20:28'),
('298', 'Hanul-5', '37.090000', '129.384444', 'KR', '3', '21', 'OPR-1000', '1999-10-01', '2004-07-29', default, '950', 'IAEA', '2015-05-24 05:20:28'),
('299', 'Hanul-6', '37.090000', '129.384444', 'KR', '3', '21', 'OPR-1000', '2000-09-29', '2005-04-22', default, '950', 'IAEA', '2015-05-24 05:20:28'),
('300', 'Hartlepool-A1', '54.634000', '-1.180000', 'GB', '3', '8', 'AGR', '1968-10-01', '1989-04-01', default, '625', 'WNA/IAEA', '2015-05-24 04:51:17'),
('301', 'Hartlepool-A2', '54.634000', '-1.180000', 'GB', '3', '8', 'AGR', '1968-10-01', '1989-04-01', default, '600', 'WNA/IAEA', '2015-05-24 04:51:17'),
('302', 'Hatch-1', '31.935000', '-82.346000', 'US', '3', '5', 'BWR-4 (Mark 1)', '1968-09-30', '1975-12-31', default, '777', 'WNA/IAEA', '2015-05-24 04:51:44'),
('303', 'Hatch-2', '31.935000', '-82.346000', 'US', '3', '5', 'BWR-4 (Mark 1)', '1972-02-01', '1979-09-05', default, '784', 'WNA/IAEA', '2015-05-24 04:51:47'),
('304', 'Heysham-A1', '54.029000', '-2.912000', 'GB', '3', '8', 'AGR', '1970-12-01', '1989-04-01', default, '611', 'WNA/IAEA', '2015-05-24 04:51:18'),
('305', 'Heysham-A2', '54.029000', '-2.912000', 'GB', '3', '8', 'AGR', '1970-12-01', '1989-04-01', default, '611', 'WNA/IAEA', '2015-05-24 04:51:18'),
('306', 'Heysham-B1', '54.029000', '-2.912000', 'GB', '3', '8', 'AGR', '1980-08-01', '1989-04-01', default, '615', 'WNA/IAEA', '2015-05-24 04:51:18'),
('307', 'Heysham-B2', '54.029000', '-2.912000', 'GB', '3', '8', 'AGR', '1980-08-01', '1989-04-01', default, '615', 'WNA/IAEA', '2015-05-24 04:51:18'),
('308', 'Higashi-Dori-1 (Tohoku)', '41.188000', '141.393000', 'JP', '3', '5', 'BWR-5', '2000-11-07', '2005-12-08', default, '1067', 'WNA/IAEA', '2015-05-24 04:51:50'),
('309', 'Higashi-Dori-1 (Tokyo)', '41.185600', '141.388000', 'JP', '1', '1', default, default, default, default, default, 'WNA', default),
('310', 'Higashi-Dori-2 (Tohoku)', '41.185600', '141.390000', 'JP', '1', '1', default, default, default, default, default, 'WNA', default),
('311', 'Higashi-Dori-2 (Tokyo)', '41.185600', '141.389000', 'JP', '1', '1', default, default, default, default, default, 'WNA', default),
('312', 'Hinkley Point-A1', '51.209000', '-3.131000', 'GB', '5', '8', 'MAGNOX', '1957-11-01', '1965-03-30', '2000-05-23', '250', 'WNA/IAEA', '2015-05-24 04:51:19'),
('313', 'Hinkley Point-A2', '51.209000', '-3.131000', 'GB', '5', '8', 'MAGNOX', '1957-11-01', '1965-05-05', '2000-05-23', '250', 'WNA/IAEA', '2015-05-24 04:51:19'),
('314', 'Hinkley Point-B1', '51.209000', '-3.131000', 'GB', '3', '8', 'AGR', '1967-09-01', '1978-10-02', default, '625', 'WNA/IAEA', '2015-05-24 04:51:14'),
('315', 'Hinkley Point-B2', '51.209000', '-3.131000', 'GB', '3', '8', 'AGR', '1967-09-01', '1976-09-27', default, '625', 'WNA/IAEA', '2015-05-24 04:51:15'),
('316', 'Hinkley Point-C1', '51.208700', '-3.130500', 'GB', '2', '21', 'EPR-1750', '2018-12-11', default, default, '1630', 'WNA/IAEA', '2019-06-02 20:18:41'),
('317', 'Hinkley Point-C2', '51.208700', '-3.130500', 'GB', '1', '21', default, default, default, default, default, 'WNA', default),
('318', 'Hongshiding-1 (Rushan-1)', default, default, 'CN', '1', '21', default, default, default, default, default, 'WNA', default),
('319', 'Hongshiding-2 (Rushan-2)', default, default, 'CN', '1', '21', default, default, default, default, default, 'WNA', default),
('320', 'Hongyanhe-1', '39.797000', '121.476500', 'CN', '3', '21', 'CPR-1000', '2007-08-18', '2013-06-06', default, '1061', 'WNA/IAEA/GEO', '2015-08-23 03:28:28'),
('321', 'Hongyanhe-2', '39.797000', '121.476500', 'CN', '3', '21', 'CPR-1000', '2008-03-28', '2014-05-13', default, '1061', 'WNA/IAEA/GEO', '2015-08-23 03:28:28'),
('322', 'Hongyanhe-3', '39.797000', '121.476500', 'CN', '3', '21', 'CPR-1000', '2009-03-07', '2015-08-16', default, '1061', 'WNA/IAEA/GEO', '2017-09-25 03:20:36'),
('323', 'Hongyanhe-4', '39.797000', '121.476500', 'CN', '3', '21', 'CPR-1000', '2009-08-15', '2016-06-08', default, '1061', 'WNA/IAEA/GEO', '2019-06-02 20:18:47'),
('324', 'Hongyanhe-5', '39.797000', '121.483100', 'CN', '2', '21', 'ACPR-1000', '2015-03-29', default, default, '1061', 'WNA/IAEA/GEO', '2017-09-25 03:20:44'),
('325', 'Hongyanhe-6', '39.797000', '121.483100', 'CN', '2', '21', 'ACPR-1000', '2015-07-24', default, default, '1061', 'WNA/IAEA/GEO', '2017-09-25 03:20:51'),
('326', 'Hope Creek-1', '39.467000', '-75.535000', 'US', '3', '5', 'BWR-4 (Mark 1)', '1976-03-01', '1986-12-20', default, '1067', 'WNA/IAEA', '2015-05-24 04:51:47'),
('327', 'Humboldt Bay', '40.741000', '-124.210000', 'US', '5', '5', 'Natural cir.', '1960-11-01', '1963-08-01', '1976-07-02', '65', 'WNA/IAEA', '2015-05-24 04:51:41'),
('328', 'Hunterston-A1', '55.722000', '-4.893000', 'GB', '5', '8', 'MAGNOX', '1957-10-01', '1964-02-05', '1990-03-30', '150', 'WNA/IAEA', '2015-05-24 04:51:19'),
('329', 'Hunterston-A2', '55.722000', '-4.893000', 'GB', '5', '8', 'MAGNOX', '1957-10-01', '1964-07-01', '1989-12-31', '150', 'WNA/IAEA', '2015-05-24 04:51:19'),
('330', 'Hunterston-B1', '55.722000', '-4.893000', 'GB', '3', '8', 'AGR', '1967-11-01', '1976-02-06', default, '624', 'WNA/IAEA', '2015-05-24 04:51:15'),
('331', 'Hunterston-B2', '55.722000', '-4.893000', 'GB', '3', '8', 'AGR', '1967-11-01', '1977-03-31', default, '624', 'WNA/IAEA', '2015-05-24 04:51:16'),
('332', 'Ignalina-1', '55.604000', '26.562000', 'LT', '5', '17', 'RBMK-1500', '1977-05-01', '1985-05-01', '2004-12-31', '1500', 'WNA/IAEA', '2015-05-24 04:51:31'),
('333', 'Ignalina-2', '55.604000', '26.562000', 'LT', '5', '17', 'RBMK-1500', '1978-01-01', '1987-12-01', '2009-12-31', '1500', 'WNA/IAEA', '2015-05-24 04:51:31'),
('334', 'Ignalina-3', '55.604000', '26.562000', 'LT', '1', '17', 'RBMK-1500', default, default, default, default, 'WNA', default),
('335', 'Ikata-1', '33.491000', '132.309000', 'JP', '5', '21', 'M (2-loop)', '1973-09-01', '1977-09-30', '2016-05-10', '538', 'WNA/IAEA', '2017-02-10 23:56:25'),
('336', 'Ikata-2', '33.491000', '132.309000', 'JP', '5', '21', 'M (2-loop)', '1978-08-01', '1982-03-19', '2018-05-23', '538', 'WNA/IAEA', '2019-06-02 20:18:50'),
('337', 'Ikata-3', '33.491000', '132.309000', 'JP', '3', '21', 'M (3-loop)', '1990-10-01', '1994-12-15', default, '846', 'WNA/IAEA', '2015-05-24 04:51:29'),
('338', 'Indian Point-1', '41.270000', '-73.950000', 'US', '5', '21', 'PWR', '1956-05-01', '1962-10-01', '1974-10-31', '265', 'WNA/IAEA', '2015-05-24 04:51:43'),
('339', 'Indian Point-2', '41.270000', '-73.950000', 'US', '3', '21', 'WH 4LP (DRYAMB)', '1966-10-14', '1974-08-01', default, '873', 'WNA/IAEA', '2017-02-10 23:57:54'),
('340', 'Indian Point-3', '41.270000', '-73.950000', 'US', '3', '21', 'WH 4LP (DRYAMB)', '1968-11-01', '1976-08-30', default, '965', 'WNA/IAEA', '2017-02-10 23:58:17'),
('341', 'Isar-1', '48.607000', '12.296000', 'DE', '5', '5', 'BWR-69', '1972-05-01', '1979-03-21', '2011-08-06', '870', 'WNA/IAEA', '2015-05-24 04:50:42'),
('342', 'Isar-2', '48.607000', '12.296000', 'DE', '3', '21', 'Konvoi', '1982-09-15', '1988-04-09', default, '1285', 'WNA/IAEA', '2015-05-24 04:50:46'),
('343', 'Jaitapur-1', '16.595278', '73.341111', 'IN', '1', '21', default, default, default, default, default, 'WNA/wikipedia', default),
('344', 'Jaitapur-2', '16.595278', '73.341111', 'IN', '1', '21', default, default, default, default, default, 'WNA/wikipedia', default),
('345', 'Java-1 (Muria)', default, default, 'ID', '1', default, default, default, default, default, default, 'WNA', default),
('346', 'Jose Cabrera-1 (Zorita)', '40.362000', '-2.818000', 'ES', '5', '21', 'WH 1LP', '1964-06-24', '1969-08-13', '2006-04-30', '153', 'WNA/IAEA', '2017-02-10 23:56:06'),
('347', 'JPDR', '36.462500', '140.610000', 'JP', '5', '5', 'BWR-1', '1960-12-01', '1965-03-15', '1976-03-18', '10', 'IAEA', '2015-05-24 04:51:26'),
('348', 'Juelich', '50.903000', '6.421000', 'DE', '5', '9', 'Pebble bed reactor prototype', '1961-08-01', '1969-05-19', '1988-12-31', '13', 'WNA/IAEA', '2015-05-24 04:54:05'),
('349', 'Kahl', '50.059000', '8.987000', 'DE', '5', '5', 'BWR', '1958-07-01', '1962-02-01', '1985-11-25', '15', 'WNA/IAEA', '2015-05-24 04:50:42'),
('350', 'Kaiga-1', '14.865000', '74.438000', 'IN', '3', '20', 'Horizontal Pressure Tube type', '1989-09-01', '2000-11-16', default, '202', 'WNA/IAEA', '2015-05-24 04:54:05'),
('351', 'Kaiga-2', '14.865000', '74.438000', 'IN', '3', '20', 'Horizontal Pressure Tube type', '1989-12-01', '2000-03-16', default, '202', 'WNA/IAEA', '2015-05-24 04:54:05'),
('352', 'Kaiga-3', '14.865000', '74.438000', 'IN', '3', '20', 'Horizontal Pressure Tube type', '2002-03-30', '2007-05-06', default, '202', 'WNA/IAEA', '2015-05-24 04:54:05'),
('353', 'Kaiga-4', '14.865000', '74.438000', 'IN', '3', '20', 'Horizontal Pressure Tube type', '2002-05-10', '2011-01-20', default, '202', 'WNA/IAEA', '2015-05-24 04:54:06'),
('354', 'Kaiga-5', '14.868000', '74.441800', 'IN', '1', '21', default, default, default, default, default, 'WNA', default),
('355', 'Kaiga-6', '14.868000', '74.442200', 'IN', '1', '21', default, default, default, default, default, 'WNA', default),
('356', 'Kakrapar-1', '21.236000', '73.351000', 'IN', '3', '20', 'Horizontal Pressure Tube type', '1984-12-01', '1993-05-06', default, '202', 'WNA/IAEA', '2015-05-24 04:54:06'),
('357', 'Kakrapar-2', '21.236000', '73.351000', 'IN', '3', '20', 'Horizontal Pressure Tube type', '1985-04-01', '1995-09-01', default, '202', 'WNA/IAEA', '2015-05-24 04:54:05'),
('358', 'Kakrapar-3', '21.236000', '73.351000', 'IN', '2', '20', 'PHWR-700', '2010-11-22', default, default, '630', 'WNA/IAEA', '2015-05-24 04:51:57'),
('359', 'Kakrapar-4', '21.236000', '73.351000', 'IN', '2', '20', 'PHWR-700', '2010-11-22', default, default, '630', 'WNA/IAEA', '2015-05-24 04:51:57'),
('360', 'Kalinin-1', '57.903000', '35.057000', 'RU', '3', '21', 'VVER V-338', '1977-02-01', '1985-06-12', default, '950', 'WNA/IAEA', '2015-05-24 04:51:34'),
('361', 'Kalinin-2', '57.903000', '35.057000', 'RU', '3', '21', 'VVER V-338', '1982-02-01', '1987-03-03', default, '950', 'WNA/IAEA', '2015-05-24 04:51:34'),
('362', 'Kalinin-3', '57.903000', '35.057000', 'RU', '3', '21', 'VVER V-320', '1985-10-01', '2005-11-08', default, '950', 'WNA/IAEA', '2015-05-24 04:51:34'),
('363', 'Kalinin-4', '57.903000', '35.057000', 'RU', '3', '21', 'VVER V-320', '1986-08-01', '2012-12-25', default, '950', 'WNA/IAEA', '2015-05-24 04:51:35'),
('364', 'Kalpakkam (PFBR)', '12.553000', '80.174000', 'IN', '2', '7', 'Prototype', '2004-10-23', default, default, '470', 'WNA/IAEA', '2015-05-24 04:51:50'),
('365', 'Kalpakkam-1 (Madras-1 / MAPS1)', '12.553000', '80.174000', 'IN', '3', '20', 'Horizontal Pressure Tube type', '1971-01-01', '1984-01-27', default, '202', 'WNA/IAEA', '2015-05-24 04:54:06'),
('366', 'Kalpakkam-2 (Madras-2 / MAPS2)', '12.553000', '80.174000', 'IN', '3', '20', 'Horizontal Pressure Tube type', '1972-10-01', '1986-03-21', default, '202', 'WNA/IAEA', '2015-05-24 04:54:06'),
('367', 'Kaminoseki-1', default, default, 'JP', '1', '1', default, default, default, default, default, 'WNA', default),
('368', 'Kaminoseki-2', default, default, 'JP', '1', '1', default, default, default, default, default, 'WNA', default),
('369', 'Karachi-1 (Kanupp-1 / Kanupp)', '24.845000', '66.790000', 'PK', '3', '20', 'CANDU-137 MW', '1966-08-01', '1972-12-07', default, '125', 'WNA/IAEA', '2015-05-24 04:51:31'),
('370', 'Karlsruhe MZFR', '49.104000', '8.432000', 'DE', '5', '20', default, '1961-12-01', '1966-12-19', '1984-05-03', '50', 'WNA/IAEA', '2015-05-24 04:50:44'),
('371', 'Kashiwazaki Kariwa-1', '37.434000', '138.598000', 'JP', '3', '5', 'BWR-5', '1980-06-05', '1985-09-18', default, '1067', 'WNA/IAEA', '2015-05-24 04:51:28'),
('372', 'Kashiwazaki Kariwa-2', '37.434000', '138.598000', 'JP', '3', '5', 'BWR-5', '1985-11-18', '1990-09-28', default, '1067', 'WNA/IAEA', '2015-05-24 04:51:29'),
('373', 'Kashiwazaki Kariwa-3', '37.434000', '138.598000', 'JP', '3', '5', 'BWR-5', '1989-03-07', '1993-08-11', default, '1067', 'WNA/IAEA', '2015-05-24 04:51:30'),
('374', 'Kashiwazaki Kariwa-4', '37.434000', '138.598000', 'JP', '3', '5', 'BWR-5', '1990-03-05', '1994-08-11', default, '1067', 'WNA/IAEA', '2015-05-24 04:51:30'),
('375', 'Kashiwazaki Kariwa-5', '37.434000', '138.598000', 'JP', '3', '5', 'BWR-5', '1985-06-20', '1990-04-10', default, '1067', 'WNA/IAEA', '2015-05-24 04:51:29'),
('376', 'Kashiwazaki Kariwa-6', '37.434000', '138.598000', 'JP', '3', '5', 'ABWR', '1992-11-03', '1996-11-07', default, '1315', 'WNA/IAEA', '2015-05-24 04:51:30'),
('377', 'Kashiwazaki Kariwa-7', '37.434000', '138.598000', 'JP', '3', '5', 'ABWR', '1993-07-01', '1997-07-02', default, '1315', 'WNA/IAEA', '2015-05-24 04:51:30'),
('378', 'Kewaunee', '44.470000', '-87.498000', 'US', '5', '21', 'WH 2LP (DRYAMB)', '1968-08-06', '1974-06-16', '2013-05-07', '535', 'WNA/IAEA', '2017-02-10 23:58:26'),
('379', 'Khmelnitski-1', '50.301000', '26.649000', 'UA', '3', '21', 'VVER V-320', '1981-11-01', '1988-08-13', default, '950', 'WNA/IAEA', '2015-05-24 04:51:40'),
('380', 'Khmelnitski-2', '50.301000', '26.649000', 'UA', '3', '21', 'VVER V-320', '1985-02-01', '2005-12-15', default, '950', 'WNA/IAEA', '2015-05-24 04:51:40'),
('381', 'Khmelnitski-3', '50.303056', '26.642778', 'UA', '2', '21', 'VVER', '1986-03-01', default, default, '1035', 'IAEA', '2017-09-25 03:20:02'),
('382', 'Khmelnitski-4', '50.303056', '26.642778', 'UA', '2', '21', 'VVER', '1987-02-01', default, default, '1035', 'IAEA', '2017-09-25 03:20:09'),
('383', 'KNK-II', '49.098000', '8.441000', 'DE', '5', '7', 'Prototype', '1974-09-01', '1979-03-03', '1991-08-23', '18', 'WNA/IAEA', '2015-05-24 04:50:48'),
('384', 'Koeberg-1', '-33.677000', '18.433000', 'ZA', '3', '21', 'CP1', '1976-07-01', '1984-07-21', default, '921', 'WNA/IAEA', '2015-05-24 04:51:50'),
('385', 'Koeberg-2', '-33.677000', '18.433000', 'ZA', '3', '21', 'CP1', '1976-07-01', '1985-11-09', default, '921', 'WNA/IAEA', '2015-05-24 04:51:50'),
('386', 'Kola-1', '67.467000', '32.491000', 'RU', '3', '21', 'VVER V-230', '1970-05-01', '1973-12-28', default, '411', 'WNA/IAEA', '2015-05-24 04:51:32'),
('387', 'Kola-2', '67.467000', '32.491000', 'RU', '3', '21', 'VVER V-230', '1970-05-01', '1975-02-21', default, '411', 'WNA/IAEA', '2015-05-24 04:51:32'),
('388', 'Kola-3', '67.467000', '32.491000', 'RU', '3', '21', 'VVER V-213', '1977-04-01', '1982-12-03', default, '411', 'WNA/IAEA', '2015-05-24 04:51:34'),
('389', 'Kola-4', '67.467000', '32.491000', 'RU', '3', '21', 'VVER V-213', '1976-08-01', '1984-12-06', default, '411', 'WNA/IAEA', '2015-05-24 04:51:34'),
('390', 'Kori-1', '35.321000', '129.295000', 'KR', '5', '21', 'WH 60', '1972-08-01', '1978-04-29', '2017-06-18', '558', 'WNA/IAEA', '2017-09-25 03:19:42'),
('391', 'Kori-2', '35.321000', '129.295000', 'KR', '3', '21', 'WH F', '1977-12-23', '1983-07-25', default, '618', 'WNA/IAEA', '2017-02-10 23:56:42'),
('392', 'Kori-3', '35.321000', '129.295000', 'KR', '3', '21', 'WH F', '1979-10-01', '1985-09-30', default, '1001', 'WNA/IAEA', '2015-05-24 04:51:31'),
('393', 'Kori-4', '35.321000', '129.295000', 'KR', '3', '21', 'WH F', '1980-04-01', '1986-04-29', default, '903', 'WNA/IAEA', '2015-05-24 04:51:31'),
('394', 'Kozloduy-1', '43.744000', '23.776000', 'BG', '5', '21', 'VVER V-230', '1970-04-01', '1974-10-28', '2002-12-31', '408', 'WNA/IAEA', '2015-05-24 04:50:16'),
('395', 'Kozloduy-2', '43.744000', '23.776000', 'BG', '5', '21', 'VVER V-230', '1970-04-01', '1975-11-10', '2002-12-31', '408', 'WNA/IAEA', '2015-05-24 04:50:16'),
('396', 'Kozloduy-3', '43.744000', '23.776000', 'BG', '5', '21', 'VVER V-230', '1973-10-01', '1981-01-20', '2006-12-31', '408', 'WNA/IAEA', '2015-05-24 04:50:17'),
('397', 'Kozloduy-4', '43.744000', '23.776000', 'BG', '5', '21', 'VVER V-230', '1973-10-01', '1982-06-20', '2006-12-31', '408', 'WNA/IAEA', '2015-05-24 04:50:17'),
('398', 'Kozloduy-5', '43.744000', '23.776000', 'BG', '3', '21', 'VVER V-320', '1980-07-09', '1988-12-23', default, '953', 'WNA/IAEA', '2015-05-24 04:50:18'),
('399', 'Kozloduy-6', '43.744000', '23.776000', 'BG', '3', '21', 'VVER V-320', '1982-04-01', '1993-12-30', default, '963', 'WNA/IAEA', '2019-06-02 20:18:54'),
('400', 'Krsko', '45.939000', '15.516000', 'SI', '3', '21', 'WH 2LP', '1975-03-30', '1983-01-01', default, '632', 'WNA/IAEA', '2017-02-10 23:57:25'),
('401', 'Kruemmel', '53.410000', '10.410000', 'DE', '5', '5', 'BWR-69', '1974-04-05', '1984-03-28', '2011-08-06', '1260', 'WNA/IAEA', '2015-05-24 04:50:44'),
('402', 'Kudankulam-1', '8.167000', '77.713000', 'IN', '3', '21', 'VVER V-412', '2002-03-31', '2014-12-31', default, '917', 'WNA/IAEA', '2015-05-24 04:51:50'),
('403', 'Kudankulam-2', '8.167000', '77.713000', 'IN', '3', '21', 'VVER V-412', '2002-07-04', '2017-03-31', default, '917', 'WNA/IAEA', '2017-09-25 03:20:10'),
('404', 'Kudankulam-3', '8.167050', '77.708000', 'IN', '2', '21', 'VVER V-412', '2017-06-29', default, default, '917', 'WNA/IAEA', '2017-09-25 03:20:58'),
('405', 'Kudankulam-4', '8.166660', '77.708000', 'IN', '2', '21', 'VVER V-412', '2017-10-23', default, default, '917', 'WNA/IAEA', '2018-07-01 01:21:38'),
('406', 'Kudankulam-5', '8.166270', '77.708000', 'IN', '1', '21', default, default, default, default, default, 'WNA', default),
('407', 'Kudankulam-6', '8.165880', '77.708000', 'IN', '1', '21', default, default, default, default, default, 'WNA', default),
('408', 'Kumharia-1', default, default, 'IN', '1', '20', default, default, default, default, default, 'WNA', default),
('409', 'Kumharia-2', default, default, 'IN', '1', '20', default, default, default, default, default, 'WNA', default),
('410', 'Kumharia-3', default, default, 'IN', '1', '20', default, default, default, default, default, 'WNA', default),
('411', 'Kumharia-4', default, default, 'IN', '1', '20', default, default, default, default, default, 'WNA', default),
('412', 'Kuosheng-1', '25.203000', '121.662000', 'TW', '3', '5', 'BWR-6', '1975-11-19', '1981-12-28', default, '948', 'WNA/IAEA', '2018-03-10 14:52:04'),
('413', 'Kuosheng-2', '25.203000', '121.662000', 'TW', '3', '5', 'BWR-6', '1976-03-15', '1983-03-16', default, '948', 'WNA/IAEA', '2018-03-10 14:52:07'),
('414', 'Kursk-1', '51.674000', '35.607000', 'RU', '3', '17', 'RBMK-1000', '1972-06-01', '1977-10-12', default, '925', 'WNA/IAEA', '2015-05-24 04:51:34'),
('415', 'Kursk-2', '51.674000', '35.607000', 'RU', '3', '17', 'RBMK-1000', '1973-01-01', '1979-08-17', default, '925', 'WNA/IAEA', '2015-05-24 04:51:34'),
('416', 'Kursk-3', '51.674000', '35.607000', 'RU', '3', '17', 'RBMK-1000', '1978-04-01', '1984-03-30', default, '925', 'WNA/IAEA', '2015-05-24 04:51:35'),
('417', 'Kursk-4', '51.674000', '35.607000', 'RU', '3', '17', 'RBMK-1000', '1981-05-01', '1986-02-05', default, '925', 'WNA/IAEA', '2015-05-24 04:51:35'),
('418', 'LaCrosse', '43.559000', '-91.230000', 'US', '5', '5', default, '1963-03-01', '1969-11-07', '1987-04-30', '50', 'WNA/IAEA', '2015-05-24 04:51:48'),
('419', 'Laguna Verde-1', '19.719000', '-96.405000', 'MX', '3', '5', 'BWR-5', '1976-10-01', '1990-07-29', default, '780', 'WNA/IAEA', '2016-07-08 21:12:48'),
('420', 'Laguna Verde-2', '19.719000', '-96.405000', 'MX', '3', '5', 'BWR-5', '1977-06-01', '1995-04-10', default, '780', 'WNA/IAEA', '2016-03-09 18:43:28'),
('421', 'LaSalle-1', '41.246000', '-88.672000', 'US', '3', '5', 'BWR-5 (Mark 2)', '1973-09-10', '1984-01-01', default, '1078', 'WNA/IAEA', '2015-05-24 04:51:48'),
('422', 'LaSalle-2', '41.246000', '-88.672000', 'US', '3', '5', 'BWR-5 (Mark 2)', '1973-09-10', '1984-10-19', default, '1078', 'WNA/IAEA', '2015-05-24 04:51:48'),
('423', 'Latina', '41.427000', '12.808000', 'IT', '5', '8', 'MAGNOX', '1958-11-01', '1964-01-01', '1987-12-01', '200', 'WNA/IAEA', '2015-05-24 04:51:26'),
('424', 'Leibstadt', '47.601000', '8.183000', 'CH', '3', '5', 'BWR-6', '1974-01-01', '1984-12-15', default, '960', 'WNA/IAEA', '2015-05-24 04:50:39'),
('425', 'Leningrad 2-1', '59.837000', '29.039000', 'RU', '3', '21', 'VVER V-491', '2008-10-25', '2018-10-29', default, '1101', 'WNA/IAEA', '2019-06-02 20:19:04'),
('426', 'Leningrad 2-2', '59.837000', '29.039000', 'RU', '2', '21', 'VVER V-491', '2010-04-15', default, default, '1111', 'WNA/IAEA', '2017-09-25 03:20:34'),
('427', 'Leningrad 2-3', '59.837000', '29.039000', 'RU', '1', '21', 'VVER V-491', default, default, default, '1085', 'wikipedia', default),
('428', 'Leningrad 2-4', '59.837000', '29.039000', 'RU', '1', '21', 'VVER V-491', default, default, default, '1085', 'wikipedia', default),
('429', 'Leningrad-1', '59.837000', '29.039000', 'RU', '5', '17', 'RBMK-1000', '1970-03-01', '1974-11-01', '2018-12-22', '925', 'WNA/IAEA', '2019-06-02 20:19:08'),
('430', 'Leningrad-2', '59.837000', '29.039000', 'RU', '3', '17', 'RBMK-1000', '1970-06-01', '1976-02-11', default, '925', 'WNA/IAEA', '2015-05-24 04:51:34'),
('431', 'Leningrad-3', '59.837000', '29.039000', 'RU', '3', '17', 'RBMK-1000', '1973-12-01', '1980-06-29', default, '925', 'WNA/IAEA', '2015-05-24 04:51:34'),
('432', 'Leningrad-4', '59.837000', '29.039000', 'RU', '3', '17', 'RBMK-1000', '1975-02-01', '1981-08-29', default, '925', 'WNA/IAEA', '2015-05-24 04:51:34'),
('433', 'Lianyungang-1', default, default, 'CN', '1', '21', default, default, default, default, default, 'WNA', default),
('434', 'Lianyungang-2', default, default, 'CN', '1', '21', default, default, default, default, default, 'WNA', default),
('435', 'Limerick-1', '40.225000', '-75.584000', 'US', '3', '5', 'BWR-4 (Mark 2)', '1974-06-19', '1986-02-01', default, '1055', 'WNA/IAEA', '2015-05-24 04:51:47'),
('436', 'Limerick-2', '40.225000', '-75.584000', 'US', '3', '5', 'BWR-4 (Mark 2)', '1974-06-19', '1990-01-08', default, '1055', 'WNA/IAEA', '2015-05-24 04:51:47'),
('437', 'Lingao-1', '22.606000', '114.550000', 'CN', '3', '21', 'M310', '1997-05-15', '2002-05-28', default, '950', 'WNA/IAEA', '2015-05-24 04:50:40'),
('438', 'Lingao-2', '22.606000', '114.550000', 'CN', '3', '21', 'M310', '1997-11-28', '2003-01-08', default, '950', 'WNA/IAEA', '2015-05-24 04:50:40'),
('439', 'Lingao-3', '22.609000', '114.552000', 'CN', '3', '21', 'CPR-1000', '2005-12-15', '2010-09-15', default, '1007', 'WNA/IAEA', '2015-05-24 04:51:51'),
('440', 'Lingao-4', '22.609000', '114.552000', 'CN', '3', '21', 'CPR-1000', '2006-06-15', '2011-08-07', default, '1007', 'WNA/IAEA', '2015-05-24 04:51:51'),
('441', 'Lingen', '52.483000', '7.302000', 'DE', '5', '5', 'BWR with fossil fuel-fired superheater', '1964-10-01', '1968-10-01', '1977-01-05', '240', 'WNA/IAEA', '2015-05-24 04:54:05'),
('442', 'Longyou-1', default, default, 'CN', '1', '21', default, default, default, default, default, 'WNA', default),
('443', 'Longyou-2', default, default, 'CN', '1', '21', default, default, default, default, default, 'WNA', default),
('444', 'Loviisa-1', '60.372000', '26.342000', 'FI', '3', '21', 'VVER V-213', '1971-05-01', '1977-05-09', default, '420', 'WNA/IAEA', '2015-05-24 04:50:50'),
('445', 'Loviisa-2', '60.372000', '26.342000', 'FI', '3', '21', 'VVER V-213', '1972-08-01', '1981-01-05', default, '420', 'WNA/IAEA', '2015-05-24 04:50:50'),
('446', 'Lucens', '46.693000', '6.827000', 'CH', '5', '11', 'HWGCR: 2-loops', '1962-04-01', default, '1969-01-21', '6', 'WNA/IAEA', '2015-05-24 04:51:57'),
('447', 'Lungmen-1', '25.038000', '121.924000', 'TW', '2', '5', 'ABWR', '1999-03-31', default, default, '1300', 'WNA/IAEA', '2015-05-24 04:51:39'),
('448', 'Lungmen-2', '25.038000', '121.924000', 'TW', '2', '5', 'ABWR', '1999-08-30', default, default, '1300', 'WNA/IAEA', '2015-05-24 04:51:39'),
('449', 'Maanshan-1', '25.038000', '121.924000', 'TW', '3', '21', 'WH 3LP (WE 312)', '1978-08-21', '1984-07-27', default, '890', 'WNA/IAEA', '2017-02-10 23:57:27'),
('450', 'Maanshan-2', '25.038000', '121.924000', 'TW', '3', '21', 'WH 3LP (WE 312)', '1979-02-21', '1985-05-18', default, '890', 'WNA/IAEA', '2017-02-10 23:57:34'),
('451', 'Maine Yankee', '43.951000', '-69.695000', 'US', '5', '21', default, '1968-10-01', '1972-12-28', '1997-08-01', '825', 'WNA/IAEA', '2015-05-24 04:51:44'),
('452', 'McGuire-1', '35.433000', '-80.946000', 'US', '3', '21', 'WH 4LP (ICECND)', '1971-04-01', '1981-12-01', default, '1180', 'WNA/IAEA', '2017-02-10 23:58:55'),
('453', 'McGuire-2', '35.433000', '-80.946000', 'US', '3', '21', 'WH 4LP (ICECND)', '1971-04-01', '1984-03-01', default, '1180', 'WNA/IAEA', '2017-02-10 23:58:55'),
('454', 'Mihama-1', '35.701000', '135.962000', 'JP', '5', '21', 'WH 2LP', '1967-02-01', '1970-11-28', '2015-04-27', '320', 'WNA/IAEA', '2017-02-10 23:56:29'),
('455', 'Mihama-2', '35.701000', '135.962000', 'JP', '5', '21', 'M (2-loop)', '1968-05-29', '1972-07-25', '2015-04-27', '470', 'WNA/IAEA', '2015-05-24 04:51:30'),
('456', 'Mihama-3', '35.701000', '135.962000', 'JP', '3', '21', 'M (3-loop)', '1972-08-07', '1976-12-01', default, '780', 'WNA/IAEA', '2015-05-24 04:51:27'),
('457', 'Millstone-1', '41.312000', '-72.166000', 'US', '5', '5', default, '1966-05-01', '1971-03-01', '1998-07-01', '660', 'WNA/IAEA', '2015-05-24 04:51:41'),
('458', 'Millstone-2', '41.312000', '-72.166000', 'US', '3', '21', 'CE 2LP (DRYAMB)', '1969-11-01', '1975-12-26', default, '870', 'WNA/IAEA', '2017-02-10 23:58:48'),
('459', 'Millstone-3', '41.312000', '-72.166000', 'US', '3', '21', 'WH 4LP (DRYSUB)', '1974-08-09', '1986-04-23', default, '1159', 'WNA/IAEA', '2017-02-10 23:59:15'),
('460', 'Mochovce-1', '48.261000', '18.455000', 'SK', '3', '21', 'VVER V-213', '1983-10-13', '1998-10-29', default, '408', 'WNA/IAEA', '2015-05-24 04:51:38'),
('461', 'Mochovce-2', '48.261000', '18.455000', 'SK', '3', '21', 'VVER V-213', '1983-10-13', '2000-04-11', default, '408', 'WNA/IAEA', '2015-05-24 04:51:38'),
('462', 'Mochovce-3', '48.261000', '18.455000', 'SK', '2', '21', 'VVER V-213', '1987-01-27', default, default, '440', 'WNA/IAEA', '2015-05-24 04:51:38'),
('463', 'Mochovce-4', '48.261000', '18.455000', 'SK', '2', '21', 'VVER V-213', '1987-01-27', default, default, '440', 'WNA/IAEA', '2015-05-24 04:51:38'),
('464', 'Monju', '35.739000', '135.988000', 'JP', '5', '7', default, '1986-05-10', default, '2017-12-05', '246', 'WNA/IAEA', '2018-03-10 14:51:35'),
('465', 'Monticello', '45.334000', '-93.850000', 'US', '3', '5', 'BWR-3 (Mark 1)', '1967-06-19', '1971-06-30', default, '545', 'WNA/IAEA', '2017-02-10 23:58:02'),
('466', 'Muehleberg', '46.969000', '7.266000', 'CH', '3', '5', 'BWR-4', '1967-03-01', '1972-11-06', default, '306', 'WNA/IAEA', '2015-05-24 04:50:38'),
('467', 'Muelheim-Kaerlich', '50.409000', '7.485000', 'DE', '5', '21', 'PWR', '1975-01-15', '1987-08-18', '1988-09-09', '1219', 'WNA/IAEA', '2015-05-24 04:50:45'),
('468', 'Narora-1', '28.156000', '78.409000', 'IN', '3', '20', 'Horizontal Pressure Tube type', '1976-12-01', '1991-01-01', default, '202', 'WNA/IAEA', '2015-05-24 04:54:06'),
('469', 'Narora-2', '28.155000', '78.409000', 'IN', '3', '20', 'Horizontal Pressure Tube type', '1977-11-01', '1992-07-01', default, '202', 'WNA/IAEA', '2015-05-24 04:54:06'),
('470', 'Neckarwestheim-1', '49.039000', '9.176000', 'DE', '5', '21', 'PWR', '1972-02-01', '1976-12-01', '2011-08-06', '805', 'WNA/IAEA', '2015-05-24 04:50:42'),
('471', 'Neckarwestheim-2', '49.039000', '9.176000', 'DE', '3', '21', 'Konvoi', '1982-11-09', '1989-04-15', default, '1225', 'WNA/IAEA', '2015-05-24 04:50:46'),
('472', 'Niederaichbach', '48.604000', '12.304000', 'DE', '5', '11', 'pressure tube reactor', '1966-06-01', '1973-01-01', '1974-07-31', '100', 'WNA/IAEA', '2015-05-24 04:54:04'),
('473', 'Nine Mile Point-1', '43.522000', '-76.412000', 'US', '3', '5', 'BWR-2 (Mark 1)', '1965-04-12', '1969-12-01', default, '620', 'WNA/IAEA', '2015-05-24 04:51:41'),
('474', 'Nine Mile Point-2', '43.522000', '-76.412000', 'US', '3', '5', 'BWR-5 (Mark 2)', '1975-08-01', '1988-03-11', default, '1100', 'WNA/IAEA', '2015-05-24 04:51:48'),
('475', 'Ningde-1', '27.046000', '120.287000', 'CN', '3', '21', 'CPR-1000', '2008-02-18', '2013-04-15', default, '1018', 'WNA/IAEA', '2015-05-24 04:51:56'),
('476', 'Ningde-2', '27.046000', '120.287000', 'CN', '3', '21', 'CPR-1000', '2008-11-12', '2014-05-04', default, '1018', 'WNA/IAEA', '2015-05-24 04:51:56'),
('477', 'Ningde-3', '27.046000', '120.287000', 'CN', '3', '21', 'CPR-1000', '2010-01-08', '2015-06-10', default, '1018', 'WNA/IAEA', '2015-08-23 03:28:29'),
('478', 'Ningde-4', '27.046000', '120.287000', 'CN', '3', '21', 'CPR-1000', '2010-09-29', '2016-07-21', default, '1018', 'WNA/IAEA', '2016-10-03 22:05:23'),
('479', 'Ningde-5', '27.046000', '120.287000', 'CN', '1', '21', 'CPR-1000', default, default, default, default, 'WNA/wikipedia', default),
('480', 'Ningde-6', '27.046000', '120.287000', 'CN', '1', '21', 'CPR-1000', default, default, default, default, 'WNA/wikipedia', default),
('481', 'Nizhegorod-1', '55.786863', '42.372150', 'RU', '1', '21', default, default, default, default, default, 'WNA', default),
('482', 'Nizhegorod-2', '55.787102', '42.372150', 'RU', '1', '21', default, default, default, default, default, 'WNA', default),
('483', 'Nogent-1', '48.517000', '3.520000', 'FR', '3', '21', 'P4 REP 1300', '1981-05-26', '1988-02-24', default, '1310', 'WNA/IAEA', '2015-05-24 04:51:03'),
('484', 'Nogent-2', '48.517000', '3.520000', 'FR', '3', '21', 'P4 REP 1300', '1982-01-01', '1989-05-01', default, '1310', 'WNA/IAEA', '2015-05-24 04:51:03'),
('485', 'North Anna-1', '38.061000', '-77.792000', 'US', '3', '21', 'WH 3LP (DRYSUB)', '1971-02-19', '1978-06-06', default, '907', 'WNA/IAEA', '2017-02-10 23:58:49'),
('486', 'North Anna-2', '38.061000', '-77.792000', 'US', '3', '21', 'WH 3LP (DRYSUB)', '1971-02-19', '1980-12-14', default, '907', 'WNA/IAEA', '2017-02-10 23:58:50'),
('487', 'Novovoronezh 2-1', '51.273000', '39.197000', 'RU', '3', '21', 'VVER V-392M', '2008-06-24', '2017-02-27', default, '1100', 'WNA/IAEA', '2019-06-02 20:19:10'),
('488', 'Novovoronezh 2-2', '51.273000', '39.197000', 'RU', '3', '21', 'VVER V-392M', '2009-07-12', default, default, '1114', 'WNA/IAEA', '2019-06-02 20:19:13'),
('489', 'Novovoronezh-1', '51.275000', '39.206000', 'RU', '5', '21', 'VVER V-210', '1957-07-01', '1964-12-31', '1988-02-16', '197', 'WNA/IAEA', '2018-07-01 01:21:51'),
('490', 'Novovoronezh-2', '51.275000', '39.206000', 'RU', '5', '21', 'VVER V-365', '1964-06-01', '1970-04-14', '1990-08-29', '336', 'WNA/IAEA', '2018-07-01 01:21:53'),
('491', 'Novovoronezh-3', '51.275000', '39.206000', 'RU', '5', '21', 'VVER V-179', '1967-07-01', '1972-06-29', '2016-12-25', '385', 'WNA/IAEA', '2017-02-10 23:57:16'),
('492', 'Novovoronezh-4', '51.275000', '39.206000', 'RU', '3', '21', 'VVER V-179', '1967-07-01', '1973-03-24', default, '385', 'WNA/IAEA', '2015-05-24 04:51:32'),
('493', 'Novovoronezh-5', '52.381000', '39.211000', 'RU', '3', '21', 'VVER V-187', '1974-03-01', '1981-02-20', default, '950', 'WNA/IAEA', '2015-05-24 04:51:34'),
('494', 'Obrigheim', '49.365000', '9.077000', 'DE', '5', '21', default, '1965-03-15', '1969-03-31', '2005-05-11', '283', 'WNA/IAEA', '2015-05-24 04:50:46'),
('495', 'Oconee-1', '34.796000', '-82.894000', 'US', '3', '21', 'B&W LLP (DRYAMB)', '1967-11-06', '1973-07-15', default, '887', 'WNA/IAEA', '2017-02-10 23:58:05'),
('496', 'Oconee-2', '34.796000', '-82.894000', 'US', '3', '21', 'B&W LLP (DRYAMB)', '1967-11-06', '1974-09-09', default, '887', 'WNA/IAEA', '2017-02-10 23:58:08'),
('497', 'Oconee-3', '34.796000', '-82.894000', 'US', '3', '21', 'B&W LLP (DRYAMB)', '1967-11-06', '1974-12-16', default, '887', 'WNA/IAEA', '2017-02-10 23:58:18'),
('498', 'Ohi-1', '35.544000', '135.652000', 'JP', '5', '21', 'WH 4LP', '1972-10-26', '1979-03-27', '2018-03-01', '1120', 'WNA/IAEA', '2019-06-02 20:19:15'),
('499', 'Ohi-2', '35.544000', '135.652000', 'JP', '5', '21', 'WH 4LP', '1972-12-08', '1979-12-05', '2018-03-01', '1120', 'WNA/IAEA', '2019-06-02 20:19:18'),
('500', 'Ohi-3', '35.544000', '135.652000', 'JP', '3', '21', 'M (4-loop)', '1987-10-03', '1991-12-18', default, '1127', 'WNA/IAEA', '2015-05-24 04:51:30'),
('501', 'Ohi-4', '35.544000', '135.652000', 'JP', '3', '21', 'M (4-loop)', '1988-06-13', '1993-02-02', default, '1127', 'WNA/IAEA', '2015-05-24 04:51:30'),
('502', 'Ohma', '41.507000', '140.909000', 'JP', '2', '5', 'ABWR', '2010-05-07', default, default, '1328', 'WNA/IAEA', '2017-02-10 23:59:23'),
('503', 'Oldbury-A1', '51.649000', '-2.567000', 'GB', '5', '8', 'MAGNOX', '1962-05-01', '1967-12-31', '2012-02-29', '300', 'WNA/IAEA', '2015-05-24 04:51:11'),
('504', 'Oldbury-A2', '51.649000', '-2.567000', 'GB', '5', '8', 'MAGNOX', '1962-05-01', '1968-09-30', '2011-06-30', '300', 'WNA/IAEA', '2015-05-24 04:51:12'),
('505', 'Olkiluoto-1', '61.235000', '21.444000', 'FI', '3', '5', 'AA-III, BWR-2500', '1974-02-01', '1979-10-10', default, '660', 'WNA/IAEA', '2018-03-10 14:51:29'),
('506', 'Olkiluoto-2', '61.235000', '21.444000', 'FI', '3', '5', 'AA-III, BWR-2500', '1975-11-01', '1982-07-10', default, '660', 'WNA/IAEA', '2018-03-10 14:51:33'),
('507', 'Olkiluoto-3', '61.234000', '21.435000', 'FI', '2', '21', 'EPR', '2005-08-12', default, default, '1600', 'WNA/IAEA', '2015-05-24 04:51:50'),
('508', 'Olkiluoto-4', '61.234352', '21.436287', 'FI', '1', default, default, default, default, default, default, 'WNA', default),
('509', 'Onagawa-1', '38.400000', '141.504000', 'JP', '3', '5', 'BWR-4', '1980-07-08', '1984-06-01', default, '496', 'WNA/IAEA', '2015-05-24 04:51:28'),
('510', 'Onagawa-2', '38.400000', '141.504000', 'JP', '3', '5', 'BWR-5', '1991-04-12', '1995-07-28', default, '796', 'WNA/IAEA', '2015-05-24 04:51:30'),
('511', 'Onagawa-3', '38.400000', '141.504000', 'JP', '3', '5', 'BWR-5', '1998-01-23', '2002-01-30', default, '796', 'WNA/IAEA', '2015-05-24 04:51:30'),
('512', 'Oskarshamn-1', '57.415000', '16.666000', 'SE', '5', '5', 'AA-I', '1966-08-01', '1972-02-06', '2017-06-19', '440', 'WNA/IAEA', '2018-03-10 14:51:55'),
('513', 'Oskarshamn-2', '57.415000', '16.666000', 'SE', '5', '5', 'AA-II', '1969-09-01', '1975-01-01', '2016-12-22', '580', 'WNA/IAEA', '2018-03-10 14:51:56'),
('514', 'Oskarshamn-3', '57.415000', '16.666000', 'SE', '3', '5', 'AA-IV, BWR-3000', '1980-05-01', '1985-08-15', default, '1050', 'WNA/IAEA', '2018-03-10 14:51:50'),
('515', 'Oyster Creek', '39.815000', '-74.208000', 'US', '5', '5', 'BWR-2 (Mark 1)', '1964-12-15', '1969-12-01', '2018-09-17', '650', 'WNA/IAEA', '2018-10-13 22:30:27'),
('516', 'Paks-1', '46.574000', '18.855000', 'HU', '3', '21', 'VVER V-213', '1974-08-01', '1983-08-10', default, '408', 'WNA/IAEA', '2015-05-24 04:51:21'),
('517', 'Paks-2', '46.574000', '18.855000', 'HU', '3', '21', 'VVER V-213', '1974-08-01', '1984-11-14', default, '410', 'WNA/IAEA', '2015-05-24 04:51:21'),
('518', 'Paks-3', '46.574000', '18.855000', 'HU', '3', '21', 'VVER V-213', '1979-10-01', '1986-12-01', default, '410', 'WNA/IAEA', '2015-05-24 04:51:21'),
('519', 'Paks-4', '46.574000', '18.855000', 'HU', '3', '21', 'VVER V-213', '1979-10-01', '1987-11-01', default, '410', 'WNA/IAEA', '2015-05-24 04:51:21'),
('520', 'Palisades', '42.323000', '-86.316000', 'US', '3', '21', 'CE 2LP (DRYAMB)', '1967-03-14', '1971-12-31', default, '805', 'WNA/IAEA', '2017-02-10 23:57:59'),
('521', 'Palo Verde-1', '33.387000', '-112.863000', 'US', '3', '21', 'CE80 2LP (DRYAMB)', '1976-05-25', '1986-01-28', default, '1221', 'WNA/IAEA', '2017-02-10 23:59:21'),
('522', 'Palo Verde-2', '33.387000', '-112.863000', 'US', '3', '21', 'CE80 2LP (DRYAMB)', '1976-06-01', '1986-09-19', default, '1304', 'WNA/IAEA', '2017-02-10 23:59:22'),
('523', 'Palo Verde-3', '33.387000', '-112.863000', 'US', '3', '21', 'CE80 2LP (DRYAMB)', '1976-06-01', '1988-01-08', default, '1304', 'WNA/IAEA', '2017-02-10 23:59:23'),
('524', 'Paluel-1', '49.857000', '0.635000', 'FR', '3', '21', 'P4 REP 1300', '1977-08-15', '1985-12-01', default, '1330', 'WNA/IAEA', '2015-05-24 04:50:57'),
('525', 'Paluel-2', '49.857000', '0.635000', 'FR', '3', '21', 'P4 REP 1300', '1978-01-01', '1985-12-01', default, '1330', 'WNA/IAEA', '2015-05-24 04:50:57'),
('526', 'Paluel-3', '49.857000', '0.635000', 'FR', '3', '21', 'P4 REP 1300', '1979-02-01', '1986-02-01', default, '1330', 'WNA/IAEA', '2015-05-24 04:50:58'),
('527', 'Paluel-4', '49.857000', '0.635000', 'FR', '3', '21', 'P4 REP 1300', '1980-02-01', '1986-06-01', default, '1330', 'WNA/IAEA', '2015-05-24 04:50:58'),
('528', 'Pathfinder', '43.603000', '-96.636000', 'US', '5', '5', 'Prototype', '1959-01-01', '1966-08-01', '1967-10-01', '59', 'WNA/IAEA', '2017-02-10 23:57:35'),
('529', 'Peach Bottom-1', '39.759000', '-76.270000', 'US', '5', '9', default, '1962-02-01', '1967-06-01', '1974-11-01', '40', 'WNA/IAEA', '2015-05-24 04:51:41'),
('530', 'Peach Bottom-2', '39.759000', '-76.270000', 'US', '3', '5', 'BWR-4 (Mark 1)', '1968-01-31', '1974-07-05', default, '1065', 'WNA/IAEA', '2015-05-24 04:51:42'),
('531', 'Peach Bottom-3', '39.759000', '-76.270000', 'US', '3', '5', 'BWR-4 (Mark 1)', '1968-01-31', '1974-12-23', default, '1065', 'WNA/IAEA', '2015-05-24 04:51:42'),
('532', 'Pengze-1', default, default, 'CN', '1', '21', 'AP-1000', default, default, default, default, 'WNA', default),
('533', 'Pengze-2', default, default, 'CN', '1', '21', 'AP-1000', default, default, default, default, 'WNA', default),
('534', 'Penly-1', '49.975000', '1.215000', 'FR', '3', '21', 'P4 REP 1300', '1982-09-01', '1990-12-01', default, '1330', 'WNA/IAEA', '2015-05-24 04:51:05'),
('535', 'Penly-2', '49.975000', '1.215000', 'FR', '3', '21', 'P4 REP 1300', '1984-08-01', '1992-11-01', default, '1330', 'WNA/IAEA', '2015-05-24 04:51:05'),
('536', 'Penly-3', '49.977611', '1.214090', 'FR', '1', '21', default, default, default, default, default, 'WNA', default),
('537', 'Perry-1', '41.801000', '-81.147000', 'US', '3', '5', 'BWR-6 (Mark 3)', '1974-10-01', '1987-11-18', default, '1205', 'WNA/IAEA', '2015-05-24 04:51:49'),
('538', 'Phenix', '44.142000', '4.712000', 'FR', '5', '7', 'PH-250', '1968-11-01', '1974-07-14', '2010-02-01', '233', 'WNA/IAEA', '2015-05-24 04:50:50'),
('539', 'Philippsburg-1', '49.253000', '8.432000', 'DE', '5', '5', 'BWR-69', '1970-10-01', '1980-03-26', '2011-08-06', '864', 'WNA/IAEA', '2015-05-24 04:50:42'),
('540', 'Philippsburg-2', '49.253000', '8.432000', 'DE', '3', '21', 'PWR', '1977-07-07', '1985-04-18', default, '1268', 'WNA/IAEA', '2015-05-24 04:50:46'),
('541', 'Pickering-1', '43.812000', '-79.070000', 'CA', '3', '20', 'CANDU 500A', '1966-06-01', '1971-07-29', default, '508', 'WNA/IAEA', '2015-05-24 04:50:33'),
('542', 'Pickering-2', '43.812000', '-79.070000', 'CA', '5', '20', 'CANDU 500A', '1966-09-01', '1971-12-30', '2007-05-28', '508', 'WNA/IAEA', '2015-05-24 04:50:36'),
('543', 'Pickering-3', '43.812000', '-79.070000', 'CA', '5', '20', 'CANDU 500A', '1967-12-01', '1972-06-01', '2008-10-31', '508', 'WNA/IAEA', '2015-05-24 04:50:36'),
('544', 'Pickering-4', '43.812000', '-79.070000', 'CA', '3', '20', 'CANDU 500A', '1968-05-01', '1973-06-17', default, '508', 'WNA/IAEA', '2015-05-24 04:50:37'),
('545', 'Pickering-5', '43.812000', '-79.070000', 'CA', '3', '20', 'CANDU 500B', '1974-11-01', '1983-05-10', default, '516', 'WNA/IAEA', '2015-05-24 04:50:22'),
('546', 'Pickering-6', '43.812000', '-79.070000', 'CA', '3', '20', 'CANDU 500B', '1975-10-01', '1984-02-01', default, '516', 'WNA/IAEA', '2015-05-24 04:50:22'),
('547', 'Pickering-7', '43.812000', '-79.070000', 'CA', '3', '20', 'CANDU 500B', '1976-03-01', '1985-01-01', default, '516', 'WNA/IAEA', '2015-05-24 04:50:23'),
('548', 'Pickering-8', '43.812000', '-79.070000', 'CA', '3', '20', 'CANDU 500B', '1976-09-01', '1986-02-28', default, '516', 'WNA/IAEA', '2015-05-24 04:50:23'),
('549', 'Pilgrim-1', '41.945000', '-70.578000', 'US', '3', '5', 'BWR-3 (Mark 1)', '1968-08-26', '1972-12-01', default, '655', 'WNA/IAEA', '2015-05-24 04:51:43'),
('550', 'Piqua', '40.132222', '-84.234722', 'US', '5', '19', 'OCM (Organically Cooled and Moderated Reactor)', '1960-01-01', '1963-11-01', '1966-01-01', '11', 'IAEA', '2015-05-24 04:54:13'),
('551', 'Point Beach-1', '44.282000', '-87.534000', 'US', '3', '21', 'WH 2LP (DRYAMB)', '1967-07-19', '1970-12-21', default, '497', 'WNA/IAEA', '2017-02-10 23:58:03'),
('552', 'Point Beach-2', '44.282000', '-87.534000', 'US', '3', '21', 'WH 2LP (DRYAMB)', '1968-07-25', '1972-10-01', default, '497', 'WNA/IAEA', '2017-02-10 23:58:22'),
('553', 'Point Lepreau', '45.068000', '-66.455000', 'CA', '3', '20', 'CANDU 6', '1975-05-01', '1983-02-01', default, '660', 'WNA/IAEA', '2015-05-24 04:50:23'),
('554', 'Point Lepreau 2', '45.068000', '-66.454600', 'CA', '1', default, default, default, default, default, default, 'WNA', default),
('555', 'Prairie Island-1', '44.622000', '-92.631000', 'US', '3', '21', 'WH 2LP (DRYAMB)', '1968-06-25', '1973-12-16', default, '530', 'WNA/IAEA', '2017-02-10 23:58:12'),
('556', 'Prairie Island-2', '44.622000', '-92.631000', 'US', '3', '21', 'WH 2LP (DRYAMB)', '1969-06-25', '1974-12-21', default, '530', 'WNA/IAEA', '2017-02-10 23:58:28'),
('557', 'Qinshan-1', '30.440000', '120.950000', 'CN', '3', '21', 'CNP-300', '1985-03-20', '1994-04-01', default, '289', 'WNA/IAEA', '2017-09-25 03:19:32'),
('558', 'Qinshan-2-1 (Qinshan 2)', '30.440000', '120.950000', 'CN', '3', '21', 'CNP-600', '1996-06-02', '2002-04-15', default, '610', 'WNA/IAEA', '2015-05-24 04:50:40'),
('559', 'Qinshan-2-2 (Qinshan 3)', '30.440000', '120.950000', 'CN', '3', '21', 'CNP-600', '1997-04-01', '2004-05-03', default, '610', 'WNA/IAEA', '2015-05-24 04:50:40'),
('560', 'Qinshan-2-3 (Qinshan 4)', '30.440000', '120.950000', 'CN', '3', '21', 'CNP-600', '2006-04-28', '2010-10-05', default, '619', 'WNA/IAEA', '2015-05-24 04:51:51'),
('561', 'Qinshan-2-4 (Qinshan 5)', '30.440000', '120.950000', 'CN', '3', '21', 'CNP-600', '2007-01-28', '2011-12-30', default, '619', 'WNA/IAEA', '2015-05-24 04:51:51'),
('562', 'Qinshan-3-1 (Qinshan 6)', '30.440000', '120.950000', 'CN', '3', '20', 'CANDU 6', '1998-06-08', '2002-12-31', default, '677', 'WNA/IAEA', '2015-05-24 04:50:40'),
('563', 'Qinshan-3-2 (Qinshan 7)', '30.440000', '120.950000', 'CN', '3', '20', 'CANDU 6', '1998-09-25', '2003-07-24', default, '677', 'WNA/IAEA', '2015-05-24 04:51:50'),
('564', 'Quad Cities-1', '41.727000', '-90.308000', 'US', '3', '5', 'BWR-3 (Mark 1)', '1967-02-15', '1973-02-18', default, '789', 'WNA/IAEA', '2015-05-24 04:51:41'),
('565', 'Quad Cities-2', '41.727000', '-90.308000', 'US', '3', '5', 'BWR-3 (Mark 1)', '1967-02-15', '1973-03-10', default, '789', 'WNA/IAEA', '2015-05-24 04:51:42'),
('566', 'R. E. Ginna', '43.279000', '-77.311000', 'US', '3', '21', 'WH 2LP (DRYAMB)', '1966-04-25', '1970-07-01', default, '470', 'WNA/IAEA', '2017-02-10 23:57:51'),
('567', 'Rajasthan-1', '24.876000', '75.608000', 'IN', '3', '20', 'Horizontal Pressure Tube type', '1965-08-01', '1973-12-16', default, '207', 'WNA/IAEA', '2015-05-24 04:54:06'),
('568', 'Rajasthan-2', '24.876000', '75.608000', 'IN', '3', '20', 'Horizontal Pressure Tube type', '1968-04-01', '1981-04-01', default, '207', 'WNA/IAEA', '2015-05-24 04:54:06'),
('569', 'Rajasthan-3', '24.876000', '75.608000', 'IN', '3', '20', 'Horizontal Pressure Tube type', '1990-02-01', '2000-06-01', default, '202', 'WNA/IAEA', '2015-05-24 04:54:05'),
('570', 'Rajasthan-4', '24.876000', '75.608000', 'IN', '3', '20', 'Horizontal Pressure Tube type', '1990-10-01', '2000-12-23', default, '202', 'WNA/IAEA', '2015-05-24 04:54:05'),
('571', 'Rajasthan-5', '24.876000', '75.608000', 'IN', '3', '20', 'Horizontal Pressure Tube type', '2002-09-18', '2010-02-04', default, '202', 'WNA/IAEA', '2015-05-24 04:54:06'),
('572', 'Rajasthan-6', '24.876000', '75.608000', 'IN', '3', '20', 'Horizontal Pressure Tube type', '2003-01-20', '2010-03-31', default, '202', 'WNA/IAEA', '2015-05-24 04:54:06'),
('573', 'Rajasthan-7', '24.876000', '75.608000', 'IN', '2', '20', 'Horizontal Pressure Tube type', '2011-07-18', default, default, '630', 'WNA/IAEA', '2015-05-24 04:54:06'),
('574', 'Rajasthan-8', '24.876000', '75.608000', 'IN', '2', '20', 'Horizontal Pressure Tube type', '2011-09-30', default, default, '630', 'WNA/IAEA', '2015-05-24 04:54:06'),
('575', 'Rancho Seco-1', '38.345000', '-121.120000', 'US', '5', '21', default, '1969-04-01', '1975-04-17', '1989-06-07', '918', 'WNA/IAEA', '2015-05-24 04:51:44'),
('576', 'Rheinsberg', '53.147000', '12.991000', 'DE', '5', '21', 'VVER-70', '1960-01-01', '1966-10-11', '1990-06-01', '62', 'WNA/IAEA', '2015-05-24 04:50:47'),
('577', 'Ringhals-1', '57.259000', '12.111000', 'SE', '3', '5', 'AA-I', '1969-02-01', '1976-01-01', default, '760', 'WNA/IAEA', '2018-03-10 14:51:57'),
('578', 'Ringhals-2', '57.259000', '12.111000', 'SE', '3', '21', 'WH 3LP', '1970-10-01', '1975-05-01', default, '820', 'WNA/IAEA', '2017-02-10 23:57:24'),
('579', 'Ringhals-3', '57.259000', '12.111000', 'SE', '3', '21', 'WH 3LP', '1972-09-01', '1981-09-09', default, '915', 'WNA/IAEA', '2017-02-10 23:57:24'),
('580', 'Ringhals-4', '57.259000', '12.111000', 'SE', '3', '21', 'WH 3LP', '1973-11-01', '1983-11-21', default, '915', 'WNA/IAEA', '2017-02-10 23:57:21'),
('581', 'River Bend-1', '30.727000', '-91.372000', 'US', '3', '5', 'BWR-6 (Mark 3)', '1977-03-25', '1986-06-16', default, '966', 'WNA/IAEA', '2015-05-24 04:51:49'),
('582', 'Rolphton NPD', '46.201000', '-77.705000', 'CA', '5', '20', 'CANDU', '1958-01-01', '1962-10-01', '1987-08-01', '17', 'WNA/IAEA', '2015-05-24 04:50:20'),
('583', 'Rostov-1 (Volgodonsk-1)', '47.599000', '42.373000', 'RU', '3', '21', 'VVER V-320', '1981-09-01', '2001-12-25', default, '950', 'WNA/IAEA', '2015-05-24 04:51:35'),
('584', 'Rostov-2 (Volgodonsk-2)', '47.599000', '42.373000', 'RU', '3', '21', 'VVER V-320', '1983-05-01', '2010-12-10', default, '950', 'WNA/IAEA', '2015-05-24 04:51:35'),
('585', 'Rostov-3 (Volgodonsk-3)', '47.599000', '42.373000', 'RU', '3', '21', 'VVER V-320', '2009-09-15', '2015-09-17', default, '950', 'WNA/IAEA', '2017-02-10 23:57:13'),
('586', 'Rostov-4 (Volgodonsk-4)', '47.599000', '42.373000', 'RU', '3', '21', 'VVER V-320', '2010-06-16', '2018-09-28', default, '950', 'WNA/IAEA', '2019-06-02 20:19:20'),
('587', 'Rovno-1', '51.326000', '25.900000', 'UA', '3', '21', 'VVER V-213', '1973-08-01', '1981-09-22', default, '361', 'WNA/IAEA', '2015-05-24 04:51:40'),
('588', 'Rovno-2', '51.326000', '25.900000', 'UA', '3', '21', 'VVER V-213', '1973-10-01', '1982-07-29', default, '384', 'WNA/IAEA', '2015-05-24 04:51:40'),
('589', 'Rovno-3', '51.326000', '25.900000', 'UA', '3', '21', 'VVER V-320', '1980-02-01', '1987-05-16', default, '950', 'WNA/IAEA', '2015-05-24 04:51:40'),
('590', 'Rovno-4', '51.326000', '25.900000', 'UA', '3', '21', 'VVER V-320', '1986-08-01', '2006-04-06', default, '950', 'WNA/IAEA', '2015-05-24 04:51:40'),
('591', 'Salem-1', '39.463000', '-75.534000', 'US', '3', '21', 'WH 4LP (DRYAMB)', '1968-09-25', '1977-06-30', default, '1090', 'WNA/IAEA', '2017-02-10 23:58:08'),
('592', 'Salem-2', '39.463000', '-75.534000', 'US', '3', '21', 'WH 4LP (DRYAMB)', '1968-09-25', '1981-10-13', default, '1115', 'WNA/IAEA', '2017-02-10 23:58:29'),
('593', 'San Onofre-1', '33.368000', '-117.556000', 'US', '5', '21', default, '1964-05-01', '1968-01-01', '1992-11-30', '436', 'WNA/IAEA', '2015-05-24 04:51:41'),
('594', 'San Onofre-2', '33.368000', '-117.556000', 'US', '5', '21', 'CE (2-loop) DRYAMB', '1974-03-01', '1983-08-08', '2013-06-07', '1070', 'WNA/IAEA', '2015-05-24 04:54:11'),
('595', 'San Onofre-3', '33.368000', '-117.556000', 'US', '5', '21', 'CE (2-loop) DRYAMB', '1974-03-01', '1984-04-01', '2013-06-07', '1070', 'WNA/IAEA', '2015-05-24 04:54:11'),
('596', 'Sanmen-1', '29.101000', '121.642000', 'CN', '3', '21', 'AP-1000', '2009-04-19', '2018-09-21', default, '1157', 'WNA/IAEA', '2018-10-13 22:30:42'),
('597', 'Sanmen-2', '29.101000', '121.642000', 'CN', '3', '21', 'AP-1000', '2009-12-15', '2018-11-05', default, '1157', 'WNA/IAEA', '2019-06-02 20:19:24'),
('598', 'Sanmen-3', '29.101111', '121.651944', 'CN', '1', '21', default, default, default, default, default, 'WNA', default),
('599', 'Sanmen-4', '29.101111', '121.656944', 'CN', '1', '21', default, default, default, default, default, 'WNA', default),
('600', 'Sanming-1', default, default, 'CN', '1', '7', default, default, default, default, default, 'WNA', default),
('601', 'Sanming-2', default, default, 'CN', '1', '7', default, default, default, default, default, 'WNA', default),
('602', 'Santa Maria de Garona', '42.775000', '-3.205000', 'ES', '5', '5', 'BWR-3', '1966-09-01', '1971-05-11', '2017-08-02', '440', 'WNA/IAEA', '2017-09-25 03:19:35'),
('603', 'Saxton', '40.226944', '-78.241944', 'US', '5', '21', '25', '1960-01-01', '1967-03-01', '1972-05-01', '3', 'IAEA', '2015-05-24 04:51:55'),
('604', 'Seabrook-1', '42.897000', '-70.849000', 'US', '3', '21', 'WH 4LP (DRYAMB)', '1976-07-07', '1990-08-19', default, '1149', 'WNA/IAEA', '2017-02-10 23:59:16'),
('605', 'Sendai-1', '31.834000', '130.193000', 'JP', '3', '21', 'M (3-loop)', '1979-12-15', '1984-07-04', default, '846', 'WNA/IAEA', '2015-05-24 04:51:28'),
('606', 'Sendai-2', '31.834000', '130.193000', 'JP', '3', '21', 'M (3-loop)', '1981-10-12', '1985-11-28', default, '846', 'WNA/IAEA', '2015-05-24 04:51:29'),
('607', 'Sendai-3', default, default, 'JP', '1', '3', default, default, default, default, default, 'WNA', default),
('608', 'Sequoyah-1', '35.228000', '-85.094000', 'US', '3', '21', 'WH 4LP (ICECND)', '1970-05-27', '1981-07-01', default, '1148', 'WNA/IAEA', '2017-02-10 23:58:40'),
('609', 'Sequoyah-2', '35.228000', '-85.094000', 'US', '3', '21', 'WH 4LP (ICECND)', '1970-05-27', '1982-06-01', default, '1148', 'WNA/IAEA', '2017-02-10 23:58:43'),
('610', 'Shanwei-1', default, default, 'CN', '1', '21', default, default, default, default, default, 'WNA', default),
('611', 'Shaoguan-1', default, default, 'CN', '1', '21', default, default, default, default, default, 'WNA', default),
('612', 'Shaoguan-2', default, default, 'CN', '1', '21', default, default, default, default, default, 'WNA', default),
('613', 'Shaoguan-3', default, default, 'CN', '1', '21', default, default, default, default, default, 'WNA', default),
('614', 'Shaoguan-4', default, default, 'CN', '1', '21', default, default, default, default, default, 'WNA', default),
('615', 'Shearon Harris-1', '35.635000', '-78.955000', 'US', '3', '21', 'WH 3LP (DRYAMB)', '1978-01-28', '1987-05-02', default, '900', 'WNA/IAEA', '2017-02-10 23:58:59'),
('616', 'Shidao Bay-1', '37.166667', '122.416667', 'CN', '2', '9', 'HTR-PM', '2012-12-09', default, default, '200', 'IAEA', '2015-05-24 04:51:57'),
('617', 'Shika-1', '37.061000', '136.728000', 'JP', '3', '5', 'BWR-5', '1989-07-01', '1993-07-30', default, '505', 'WNA/IAEA', '2015-05-24 04:51:29'),
('618', 'Shika-2', '37.061000', '136.728000', 'JP', '3', '5', 'ABWR', '2001-08-20', '2006-03-15', default, '1304', 'WNA/IAEA', '2015-05-24 04:51:50'),
('619', 'Shimane-1', '35.537000', '132.999000', 'JP', '5', '5', 'BWR-3', '1970-07-02', '1974-03-29', '2015-04-30', '439', 'WNA/IAEA', '2015-05-24 04:51:30'),
('620', 'Shimane-2', '35.537000', '132.999000', 'JP', '3', '5', 'BWR-5', '1985-02-02', '1989-02-10', default, '789', 'WNA/IAEA', '2015-05-24 04:51:29'),
('621', 'Shimane-3', '35.537000', '132.999000', 'JP', '2', '5', 'ABWR', '2007-10-12', default, default, '1325', 'WNA/IAEA', '2015-05-24 04:51:51'),
('622', 'Shin Wolsong-1', '35.722000', '129.479000', 'KR', '3', '21', 'OPR-1000', '2007-11-20', '2012-07-31', default, '950', 'WNA/IAEA', '2015-05-24 05:13:40'),
('623', 'Shin Wolsong-2', '35.722000', '129.479000', 'KR', '3', '21', 'OPR-1000', '2008-09-23', '2015-07-24', default, '950', 'WNA/IAEA', '2015-08-23 03:28:27'),
('624', 'Shin-Hanul-1', '37.083889', '129.391667', 'KR', '2', '21', 'APR-1400', '2012-07-10', default, default, '1340', 'IAEA', '2015-05-24 04:51:53'),
('625', 'Shin-Hanul-2', '37.083889', '129.391667', 'KR', '2', '21', 'APR-1400', '2013-06-19', default, default, '1340', 'IAEA', '2015-05-24 04:51:53'),
('626', 'Shin-Kori-1', '35.327000', '129.302000', 'KR', '3', '21', 'OPR-1000', '2006-06-16', '2011-02-28', default, '998', 'WNA/IAEA', '2015-05-24 04:51:51'),
('627', 'Shin-Kori-2', '35.327000', '129.302000', 'KR', '3', '21', 'OPR-1000', '2007-06-05', '2012-07-20', default, '995', 'WNA/IAEA', '2015-05-24 04:51:51'),
('628', 'Shin-Kori-3', '35.327000', '129.302000', 'KR', '3', '21', 'APR-1400', '2008-10-16', '2016-12-20', default, '1340', 'WNA/IAEA', '2017-09-25 03:20:21'),
('629', 'Shin-Kori-4', '35.327000', '129.302000', 'KR', '3', '21', 'APR-1400', '2009-08-19', default, default, '1340', 'WNA/IAEA', '2019-06-02 20:19:26'),
('630', 'Shin-Kori-5', '35.327000', '129.302000', 'KR', '2', '21', 'APR-1400', '2017-04-01', default, default, '1340', 'WNA/wikipedia/IAEA', '2018-03-10 14:54:40'),
('631', 'Shin-Kori-6', '35.327000', '129.302000', 'KR', '2', '21', 'APR-1400', '2018-09-20', default, default, '1340', 'WNA/wikipedia/IAEA', '2018-10-13 22:30:47'),
('632', 'Shippingport', '40.630000', '-80.417778', 'US', '5', '21', 'PLWBR', '1954-01-01', '1958-05-26', '1982-10-01', '60', 'IAEA', '2015-05-24 04:51:54'),
('633', 'Shoreham', '40.960000', '-72.866000', 'US', '5', '5', default, '1972-11-01', '1986-08-01', '1989-05-01', '809', 'WNA/IAEA', '2017-02-10 23:58:37'),
('634', 'Sinop-1', '42.000000', '35.000000', 'TR', '1', '21', 'ATMEA-1', default, default, default, default, 'wikipedia', default),
('635', 'Sinop-2', '42.000000', '35.000000', 'TR', '1', '21', 'ATMEA-1', default, default, default, default, 'wikipedia', default),
('636', 'Sinop-3', '42.000000', '35.000000', 'TR', '1', '21', 'ATMEA-1', default, default, default, default, 'wikipedia', default),
('637', 'Sinop-4', '42.000000', '35.000000', 'TR', '1', '21', 'ATMEA-1', default, default, default, default, 'wikipedia', default),
('638', 'Sizewell-A1', '52.212000', '1.621000', 'GB', '5', '8', 'MAGNOX', '1961-04-01', '1966-03-25', '2006-12-31', '290', 'WNA/IAEA', '2015-05-24 04:51:10'),
('639', 'Sizewell-A2', '52.212000', '1.621000', 'GB', '5', '8', 'MAGNOX', '1961-04-01', '1966-09-15', '2006-12-31', '290', 'WNA/IAEA', '2015-05-24 04:51:11'),
('640', 'Sizewell-B', '52.212000', '1.621000', 'GB', '3', '21', 'SNUPPS', '1988-07-18', '1995-09-22', default, '1188', 'WNA/IAEA', '2015-05-24 04:51:18'),
('641', 'Sizewell-C1', '52.219390', '1.622800', 'GB', '1', '21', default, default, default, default, default, 'WNA', default),
('642', 'Sizewell-C2', '52.219390', '1.623800', 'GB', '1', '21', default, default, default, default, default, 'WNA', default),
('643', 'Smolensk-1', '54.169000', '33.245000', 'RU', '3', '17', 'RBMK-1000', '1975-10-01', '1983-09-30', default, '925', 'WNA/IAEA', '2015-05-24 04:51:34'),
('644', 'Smolensk-2', '54.169000', '33.245000', 'RU', '3', '17', 'RBMK-1000', '1976-06-01', '1985-07-02', default, '925', 'WNA/IAEA', '2015-05-24 04:51:34'),
('645', 'Smolensk-3', '54.169000', '33.245000', 'RU', '3', '17', 'RBMK-1000', '1984-05-01', '1990-10-12', default, '925', 'WNA/IAEA', '2015-05-24 04:51:36'),
('646', 'Sosnovy Bor-1', default, default, 'RU', '1', '21', 'VVER', default, default, default, default, 'WNA', default),
('647', 'South Texas-1', '28.797000', '-96.044000', 'US', '3', '21', 'WH 4LP (DRYAMB)', '1975-12-22', '1988-08-25', default, '1250', 'WNA/IAEA', '2017-02-10 23:59:20'),
('648', 'South Texas-2', '28.796000', '-96.044000', 'US', '3', '21', 'WH 4LP (DRYAMB)', '1975-12-22', '1989-06-19', default, '1250', 'WNA/IAEA', '2017-02-10 23:59:21'),
('649', 'South Ukraine-1', '47.811000', '31.220000', 'UA', '3', '21', 'VVER V-302', '1976-08-01', '1983-12-02', default, '950', 'WNA/IAEA', '2015-05-24 04:51:40'),
('650', 'South Ukraine-2', '47.811000', '31.220000', 'UA', '3', '21', 'VVER V-338', '1981-07-01', '1985-04-06', default, '950', 'WNA/IAEA', '2015-05-24 04:51:40'),
('651', 'South Ukraine-3', '47.811000', '31.220000', 'UA', '3', '21', 'VVER V-320', '1984-11-01', '1989-12-29', default, '950', 'WNA/IAEA', '2015-05-24 04:51:40'),
('652', 'St. Alban-1', '45.404000', '4.754000', 'FR', '3', '21', 'P4 REP 1300', '1979-01-29', '1986-05-01', default, '1335', 'WNA/IAEA', '2015-05-24 04:51:00'),
('653', 'St. Alban-2', '45.404000', '4.754000', 'FR', '3', '21', 'P4 REP 1300', '1979-07-31', '1987-03-01', default, '1335', 'WNA/IAEA', '2015-05-24 04:51:01'),
('654', 'St. Laurent-A1', '47.724000', '1.582000', 'FR', '5', '8', 'UNGG', '1963-10-01', '1969-06-01', '1990-04-18', '480', 'WNA/IAEA', '2015-05-24 04:51:06'),
('655', 'St. Laurent-A2', '47.724000', '1.582000', 'FR', '5', '8', 'UNGG', '1966-01-01', '1971-11-01', '1992-05-27', '515', 'WNA/IAEA', '2015-05-24 04:51:07'),
('656', 'St. Laurent-B1', '47.724000', '1.582000', 'FR', '3', '21', 'CP2', '1976-05-01', '1983-08-01', default, '915', 'WNA/IAEA', '2015-05-24 04:50:51'),
('657', 'St. Laurent-B2', '47.720000', '1.581000', 'FR', '3', '21', 'CP2', '1976-07-01', '1983-08-01', default, '880', 'WNA/IAEA', '2015-05-24 04:50:53'),
('658', 'St. Lucie-1', '27.348000', '-80.244000', 'US', '3', '21', 'CE 2LP (DRYAMB)', '1970-07-01', '1976-12-21', default, '830', 'WNA/IAEA', '2017-02-10 23:58:47'),
('659', 'St. Lucie-2', '27.348000', '-80.244000', 'US', '3', '21', 'CE 2LP (DRYAMB)', '1977-06-02', '1983-08-08', default, '830', 'WNA/IAEA', '2017-02-10 23:58:56'),
('660', 'Stade', '53.620000', '9.530000', 'DE', '5', '21', default, '1967-12-01', '1972-05-19', '2003-11-14', '630', 'WNA/IAEA', '2015-05-24 04:50:42'),
('661', 'Summer-1', '34.299000', '-81.314000', 'US', '3', '21', 'WH 3LP (DRYAMB)', '1973-03-21', '1984-01-01', default, '900', 'WNA/IAEA', '2017-02-10 23:58:58'),
('662', 'Summer-2', '34.295833', '-81.320278', 'US', '8', '21', 'AP-1000', '2013-03-09', default, default, '1117', 'IAEA', '2018-03-10 14:56:12'),
('663', 'Summer-3', '34.295833', '-81.320278', 'US', '8', '21', 'AP-1000', '2013-11-02', default, default, '1117', 'IAEA', '2018-03-10 14:56:13'),
('664', 'Super-Phenix', '45.760000', '5.474000', 'FR', '5', '7', 'Na-1200', '1976-12-13', '1986-12-01', '1998-12-31', '1200', 'WNA/IAEA', '2015-05-24 04:50:53'),
('665', 'Surry-1', '37.166000', '-76.700000', 'US', '3', '21', 'WH 3LP (DRYSUB)', '1968-06-25', '1972-12-22', default, '788', 'WNA/IAEA', '2017-02-10 23:58:10'),
('666', 'Surry-2', '37.166000', '-76.700000', 'US', '3', '21', 'WH 3LP (DRYSUB)', '1968-06-25', '1973-05-01', default, '788', 'WNA/IAEA', '2017-02-10 23:58:11'),
('667', 'Susquehanna-1', '41.093000', '-76.143000', 'US', '3', '5', 'BWR-4 (Mark 2)', '1973-11-02', '1983-06-08', default, '1065', 'WNA/IAEA', '2015-05-24 04:51:48'),
('668', 'Susquehanna-2', '41.093000', '-76.143000', 'US', '3', '5', 'BWR-4 (Mark 2)', '1973-11-02', '1985-02-12', default, '1065', 'WNA/IAEA', '2015-05-24 04:51:48'),
('669', 'Taishan-1', '21.949000', '112.956000', 'CN', '3', '21', 'EPR-1750', '2009-11-18', '2018-12-13', default, '1660', 'WNA/IAEA', '2019-06-02 20:19:27'),
('670', 'Taishan-2', '21.949000', '112.956000', 'CN', '2', '21', 'EPR-1750', '2010-04-15', default, default, '1660', 'WNA/IAEA', '2015-05-24 04:51:56'),
('671', 'Takahama-1', '35.520000', '135.503000', 'JP', '3', '21', 'M (3-loop)', '1970-04-25', '1974-11-14', default, '780', 'WNA/IAEA', '2015-05-24 04:51:30'),
('672', 'Takahama-2', '35.520000', '135.503000', 'JP', '3', '21', 'M (3-loop)', '1971-03-09', '1975-11-14', default, '780', 'WNA/IAEA', '2015-05-24 04:51:27'),
('673', 'Takahama-3', '35.520000', '135.503000', 'JP', '3', '21', 'M (3-loop)', '1980-12-12', '1985-01-17', default, '830', 'WNA/IAEA', '2015-05-24 04:51:28'),
('674', 'Takahama-4', '35.520000', '135.503000', 'JP', '3', '21', 'M (3-loop)', '1981-03-19', '1985-06-05', default, '830', 'WNA/IAEA', '2015-05-24 04:51:28'),
('675', 'Taohuajiang-1', default, default, 'CN', '1', '21', 'AP-1000', default, default, default, default, 'WNA', default),
('676', 'Taohuajiang-2', default, default, 'CN', '1', '21', 'AP-1000', default, default, default, default, 'WNA', default),
('677', 'Taohuajiang-3', default, default, 'CN', '1', '21', default, default, default, default, default, 'WNA', default),
('678', 'Taohuajiang-4', default, default, 'CN', '1', '21', default, default, default, default, default, 'WNA', default),
('679', 'Tarapur-1', '19.834000', '72.657000', 'IN', '3', '5', 'BWR-1 (Mark 2)', '1964-10-01', '1969-10-28', default, '200', 'WNA/IAEA', '2015-05-24 04:51:21'),
('680', 'Tarapur-2', '19.834000', '72.657000', 'IN', '3', '5', 'BWR-1 (Mark 2)', '1964-10-01', '1969-10-28', default, '200', 'WNA/IAEA', '2015-05-24 04:51:22'),
('681', 'Tarapur-3', '19.834000', '72.657000', 'IN', '3', '20', 'Horizontal Pressure Tube Type', '2000-05-12', '2006-08-18', default, '502', 'WNA/IAEA', '2015-05-24 04:54:06'),
('682', 'Tarapur-4', '19.834000', '72.657000', 'IN', '3', '20', 'Horizontal Pressure Tube Type', '2000-03-08', '2005-09-12', default, '502', 'WNA/IAEA', '2015-05-24 04:54:06'),
('683', 'Temelin-1', '49.181000', '14.377000', 'CZ', '3', '21', 'VVER V-320', '1987-02-01', '2002-06-10', default, '912', 'WNA/IAEA', '2015-05-24 04:50:40'),
('684', 'Temelin-2', '49.181000', '14.377000', 'CZ', '3', '21', 'VVER V-320', '1987-02-01', '2003-04-18', default, '912', 'WNA/IAEA', '2015-05-24 04:50:41'),
('685', 'Three Mile Island-1', '40.154000', '-76.727000', 'US', '3', '21', 'B&W LLP (DRYAMB)', '1968-05-18', '1974-09-02', default, '819', 'WNA/IAEA', '2017-02-10 23:58:19'),
('686', 'Three Mile Island-2', '40.154000', '-76.727000', 'US', '5', '21', default, '1969-11-01', '1978-12-30', '1979-03-28', '906', 'WNA/IAEA', '2015-05-24 04:51:44'),
('687', 'THTR-300', '51.680000', '7.972000', 'DE', '5', '9', 'Pebble bed reactor', '1971-05-03', '1987-06-01', '1988-09-29', '296', 'WNA/IAEA', '2015-05-24 04:54:05'),
('688', 'Tianwan-1', '34.690000', '119.456000', 'CN', '3', '21', 'VVER V-428', '1999-10-20', '2007-05-17', default, '990', 'WNA/IAEA', '2015-05-24 04:51:50'),
('689', 'Tianwan-2', '34.690000', '119.456000', 'CN', '3', '21', 'VVER V-428', '2000-09-20', '2007-08-16', default, '990', 'WNA/IAEA', '2015-05-24 04:51:50'),
('690', 'Tianwan-3', '34.686800', '119.456000', 'CN', '3', '21', 'VVER V-428M', '2012-12-27', '2018-02-14', default, '1060', 'WNA/IAEA', '2018-07-01 01:21:55'),
('691', 'Tianwan-4', '34.685800', '119.456000', 'CN', '3', '21', 'VVER V-428M', '2013-09-27', '2018-12-22', default, '1060', 'WNA/IAEA', '2019-06-02 20:19:28'),
('692', 'Tianwan-5', '34.683800', '119.456000', 'CN', '2', '21', 'CNP-1000', '2015-12-27', default, default, '1000', 'WNA/wikipedia/IAEA', '2016-03-09 18:44:20'),
('693', 'Tianwan-6', '34.682800', '119.456000', 'CN', '2', '21', 'CNP-1000', '2016-09-07', default, default, '1000', 'WNA/wikipedia/IAEA', '2017-09-25 03:20:53'),
('694', 'Tihange-1', '50.533000', '5.271000', 'BE', '3', '21', 'Framatome 3 loops reactor', '1970-06-01', '1975-10-01', default, '870', 'WNA/IAEA', '2015-05-24 04:54:04'),
('695', 'Tihange-2', '50.533000', '5.271000', 'BE', '3', '21', 'WH 3LP', '1976-04-01', '1983-06-01', default, '900', 'WNA/IAEA', '2017-02-10 23:55:40'),
('696', 'Tihange-3', '50.533000', '5.271000', 'BE', '3', '21', 'WH 3LP', '1978-11-01', '1985-09-01', default, '1020', 'WNA/IAEA', '2017-02-10 23:55:44'),
('697', 'Tokai-1', '36.466000', '140.612000', 'JP', '5', '8', 'MAGNOX', '1961-03-01', '1966-07-25', '1998-03-31', '159', 'WNA/IAEA', '2015-05-24 04:51:27'),
('698', 'Tokai-2', '36.466000', '140.612000', 'JP', '3', '5', 'BWR-5', '1973-10-03', '1978-11-28', default, '1056', 'WNA/IAEA', '2015-05-24 04:51:28'),
('699', 'Tomari-1', '43.038000', '140.515000', 'JP', '3', '21', 'M (2-loop)', '1985-04-18', '1989-06-22', default, '550', 'WNA/IAEA', '2015-05-24 04:51:29'),
('700', 'Tomari-2', '43.038000', '140.515000', 'JP', '3', '21', 'M (2-loop)', '1985-06-13', '1991-04-12', default, '550', 'WNA/IAEA', '2015-05-24 04:51:29'),
('701', 'Tomari-3', '43.038000', '140.515000', 'JP', '3', '21', 'M (3-loop)', '2004-11-18', '2009-12-22', default, '866', 'WNA/IAEA', '2015-05-24 04:51:50'),
('702', 'Torness-1', '55.966000', '-2.399000', 'GB', '3', '8', 'AGR', '1980-08-01', '1988-05-25', default, '645', 'WNA/IAEA', '2015-05-24 04:51:18'),
('703', 'Torness-2', '55.966000', '-2.399000', 'GB', '3', '8', 'AGR', '1980-08-01', '1989-02-03', default, '645', 'WNA/IAEA', '2015-05-24 04:51:18'),
('704', 'Trawsfynydd-1', '52.923000', '-3.947000', 'GB', '5', '8', 'MAGNOX', '1959-07-01', '1965-03-24', '1991-02-06', '250', 'WNA/IAEA', '2015-05-24 04:51:20'),
('705', 'Trawsfynydd-2', '52.922000', '-3.947000', 'GB', '5', '8', 'MAGNOX', '1959-07-01', '1965-03-24', '1991-02-04', '250', 'WNA/IAEA', '2015-05-24 04:51:20'),
('706', 'Tricastin-1', '44.330000', '4.733000', 'FR', '3', '21', 'CP1', '1974-11-01', '1980-12-01', default, '915', 'WNA/IAEA', '2015-05-24 04:50:51'),
('707', 'Tricastin-2', '44.330000', '4.733000', 'FR', '3', '21', 'CP1', '1974-12-01', '1980-12-01', default, '915', 'WNA/IAEA', '2015-05-24 04:50:51'),
('708', 'Tricastin-3', '44.331000', '4.733000', 'FR', '3', '21', 'CP1', '1975-04-01', '1981-05-11', default, '915', 'WNA/IAEA', '2015-05-24 04:50:53'),
('709', 'Tricastin-4', '44.331000', '4.733000', 'FR', '3', '21', 'CP1', '1975-05-01', '1981-11-01', default, '915', 'WNA/IAEA', '2015-05-24 04:50:53'),
('710', 'Trillo-1', '40.699000', '-2.622000', 'ES', '3', '21', 'PWR 3 loops', '1979-08-17', '1988-08-06', default, '990', 'WNA/IAEA', '2015-05-24 04:50:49'),
('711', 'Trino Vercellese', '45.182000', '8.278000', 'IT', '5', '21', default, '1961-01-07', default, default, '260', 'WNA', default),
('712', 'Trojan', '46.040000', '-122.887000', 'US', '5', '21', default, '1970-02-01', '1976-05-20', '1992-11-09', '1130', 'WNA/IAEA', '2015-05-24 04:51:47'),
('713', 'Tsuruga-1', '35.672000', '136.079000', 'JP', '5', '5', 'BWR-2', '1966-11-24', '1970-03-14', '2015-04-27', '341', 'WNA/IAEA', '2015-05-24 04:51:28'),
('714', 'Tsuruga-2', '35.672000', '136.079000', 'JP', '3', '21', 'M (4-loop)', '1982-11-06', '1987-02-17', default, '1115', 'WNA/IAEA', '2015-05-24 04:51:28'),
('715', 'Tsuruga-3', default, default, 'JP', '1', '21', default, default, default, default, default, 'WNA', default),
('716', 'Tsuruga-4', default, default, 'JP', '1', '21', default, default, default, default, default, 'WNA', default),
('717', 'Turkey Point-3', '25.435000', '-80.330000', 'US', '3', '21', 'WH 3LP (DRYAMB)', '1967-04-27', '1972-12-14', default, '693', 'WNA/IAEA', '2017-02-10 23:57:56'),
('718', 'Turkey Point-4', '25.435000', '-80.330000', 'US', '3', '21', 'WH 3LP (DRYAMB)', '1967-04-27', '1973-09-07', default, '693', 'WNA/IAEA', '2017-02-10 23:57:58'),
('719', 'Ulchin-1', '37.093000', '129.393000', 'KR', '3', '21', default, '1983-01-26', default, default, '920', 'WNA', default),
('720', 'Ulchin-2', '37.093000', '129.393000', 'KR', '3', '21', default, '1983-07-05', default, default, '920', 'WNA', default),
('721', 'Ulchin-3', '37.093000', '129.393000', 'KR', '3', '21', default, '1993-07-21', default, default, '960', 'WNA', default),
('722', 'Ulchin-4', '37.093000', '129.393000', 'KR', '3', '21', default, '1993-11-01', default, default, '960', 'WNA', default),
('723', 'Ulchin-5', '37.093000', '129.393000', 'KR', '3', '21', default, '1999-10-01', default, default, '950', 'WNA', default),
('724', 'Ulchin-6', '37.093000', '129.393000', 'KR', '3', '21', default, '1999-10-01', default, default, '950', 'WNA', default),
('725', 'Unterweser', '53.429000', '8.477000', 'DE', '5', '21', 'PWR', '1972-07-01', '1979-09-06', '2011-08-06', '1230', 'WNA/IAEA', '2015-05-24 04:50:42'),
('726', 'Vandellos-1', '40.949000', '0.867000', 'ES', '5', '8', default, '1968-06-21', '1972-08-02', '1990-07-31', '480', 'WNA/IAEA', '2015-05-24 04:50:49'),
('727', 'Vandellos-2', '40.949000', '0.867000', 'ES', '3', '21', 'WH 3LP', '1980-12-29', '1988-03-08', default, '930', 'WNA/IAEA', '2017-02-10 23:56:13'),
('728', 'Vermont Yankee', '42.779000', '-72.514000', 'US', '5', '5', 'BWR-4 (Mark 1)', '1967-12-11', '1972-11-30', '2014-12-29', '514', 'WNA/IAEA', '2015-05-24 04:51:42'),
('729', 'Visaginas-1', '55.605700', '26.575842', 'LT', '1', default, default, default, default, default, default, 'WNA', default),
('730', 'Visaginas-2', '55.605700', '26.575842', 'LT', '1', default, default, default, default, default, default, 'WNA', default),
('731', 'Vogtle-1', '33.143000', '-81.760000', 'US', '3', '21', 'WH 4LP (DRYAMB)', '1976-08-01', '1987-06-01', default, '1122', 'WNA/IAEA', '2017-02-10 23:59:15'),
('732', 'Vogtle-2', '33.143000', '-81.760000', 'US', '3', '21', 'WH 4LP (DRYAMB)', '1976-08-01', '1989-05-20', default, '1101', 'WNA/IAEA', '2017-02-10 23:59:16'),
('733', 'Vogtle-3', '33.139900', '-81.768600', 'US', '2', '21', 'AP-1000', '2013-03-12', default, default, '1117', 'WNA/IAEA', '2015-05-24 04:51:57'),
('734', 'Vogtle-4', '33.139900', '-81.771200', 'US', '2', '21', 'AP-1000', '2013-11-19', default, default, '1117', 'WNA/IAEA', '2015-05-24 04:51:58'),
('735', 'Waterford-3', '29.994000', '-90.471000', 'US', '3', '21', 'CE 2LP (DRYAMB)', '1974-11-14', '1985-09-24', default, '1104', 'WNA/IAEA', '2017-02-10 23:58:56'),
('736', 'Watts Bar-1', '35.601000', '-84.789000', 'US', '3', '21', 'WH 4LP (ICECND)', '1973-07-20', '1996-05-27', default, '1218', 'WNA/IAEA', '2017-02-10 23:58:57'),
('737', 'Watts Bar-2', '35.601000', '-84.789000', 'US', '3', '21', 'WH 4LP (ICECND)', '1973-09-01', '2016-10-19', default, '1165', 'WNA/IAEA', '2017-02-10 23:58:57'),
('738', 'Windscale AGR', '54.426000', '-3.505000', 'GB', '5', '8', 'AGR', '1958-11-01', '1963-03-01', '1981-04-03', '32', 'WNA/IAEA', '2015-05-24 04:51:19'),
('739', 'Winfrith SGHWR', '50.680000', '-2.272000', 'GB', '5', '24', default, '1963-05-01', '1968-01-01', '1990-09-11', '92', 'WNA/IAEA', '2015-05-24 04:51:12'),
('740', 'Wolf Creek', '38.239000', '-95.691000', 'US', '3', '21', 'WH 4LP (DRYAMB)', '1977-05-31', '1985-09-03', default, '1170', 'WNA/IAEA', '2017-02-10 23:59:19'),
('741', 'Wolsong-1', '35.710000', '129.476000', 'KR', '3', '20', 'CANDU 6', '1977-10-30', '1983-04-22', default, '629', 'WNA/IAEA', '2018-03-10 14:51:40'),
('742', 'Wolsong-2', '35.710000', '129.476000', 'KR', '3', '20', 'CANDU 6', '1992-09-25', '1997-07-01', default, '652', 'WNA/IAEA', '2017-09-25 03:19:44'),
('743', 'Wolsong-3', '35.710000', '129.476000', 'KR', '3', '20', 'CANDU 6', '1994-03-17', '1998-07-01', default, '665', 'WNA/IAEA', '2018-03-10 14:51:38'),
('744', 'Wolsong-4', '35.710000', '129.476000', 'KR', '3', '20', 'CANDU 6', '1994-07-22', '1999-10-01', default, '669', 'WNA/IAEA', '2015-05-24 05:13:27'),
('745', 'Wolsong-5', '35.710100', '129.481000', 'KR', '1', '20', default, default, default, default, default, 'WNA', default),
('746', 'Wolsong-6', '35.710100', '129.481000', 'KR', '1', '20', default, default, default, default, default, 'WNA', default),
('747', 'Wuergassen', '51.639000', '9.393000', 'DE', '5', '5', default, '1968-01-26', '1975-11-11', '1994-08-26', '640', 'WNA/IAEA', '2015-05-24 04:50:48'),
('748', 'Wuhu-1', default, default, 'CN', '1', '21', default, default, default, default, default, 'WNA', default),
('749', 'Wuhu-2', default, default, 'CN', '1', '21', default, default, default, default, default, 'WNA', default),
('750', 'Wylfa-1', '53.416000', '-4.480000', 'GB', '5', '8', 'MAGNOX', '1963-09-01', '1971-11-01', '2015-12-30', '550', 'WNA/IAEA', '2016-03-09 18:43:09'),
('751', 'Wylfa-2', '53.416000', '-4.480000', 'GB', '5', '8', 'MAGNOX', '1963-09-01', '1972-01-03', '2012-04-25', '550', 'WNA/IAEA', '2015-05-24 04:51:13'),
('752', 'Xianning-1', '29.660000', '114.670000', 'CN', '1', '21', 'AP-1000', default, default, default, default, 'WNA/wikipedia', default),
('753', 'Xianning-2', '29.660000', '114.670000', 'CN', '1', '21', 'AP-1000', default, default, default, default, 'WNA/wikipedia', default),
('754', 'Xiaomoshan (Jiulongshan) 1', default, default, 'CN', '1', '21', default, default, default, default, default, 'WNA', default),
('755', 'Xiaomoshan (Jiulongshan) 2', default, default, 'CN', '1', '21', default, default, default, default, default, 'WNA', default),
('756', 'Yangjiang-1', '21.706000', '112.256000', 'CN', '3', '21', 'CPR-1000', '2008-12-16', '2014-03-25', default, '1021', 'WNA/IAEA', '2015-05-24 04:51:52'),
('757', 'Yangjiang-2', '21.706000', '112.256000', 'CN', '3', '21', 'CPR-1000', '2009-06-04', '2015-06-05', default, '1000', 'WNA/IAEA', '2015-08-23 03:28:27'),
('758', 'Yangjiang-3', '21.706000', '112.256000', 'CN', '3', '21', 'CPR-1000', '2010-11-15', '2016-01-01', default, '1000', 'WNA/IAEA', '2016-03-09 18:43:57'),
('759', 'Yangjiang-4', '21.857500', '111.982500', 'CN', '3', '21', 'CPR-1000', '2012-11-17', '2017-03-15', default, '1000', 'WNA/IAEA', '2017-09-25 03:20:38'),
('760', 'Yangjiang-5', '21.857500', '111.982500', 'CN', '3', '21', 'ACPR-1000', '2013-09-18', '2018-07-12', default, '1021', 'IAEA', '2019-06-02 20:19:31'),
('761', 'Yangjiang-6', '21.857500', '111.982500', 'CN', '2', '21', 'ACPR-1000', '2013-12-23', default, default, '1000', 'IAEA', '2015-05-24 04:51:57'),
('762', 'Yanjiashan-1', default, default, 'CN', '1', '21', default, default, default, default, default, 'WNA', default),
('763', 'Yanjiashan-2', default, default, 'CN', '1', '21', default, default, default, default, default, 'WNA', default),
('764', 'Yankee Rowe', '42.728000', '-72.929000', 'US', '5', '21', 'PWR', '1957-11-01', '1961-07-01', '1991-10-01', '175', 'WNA/IAEA', '2015-05-24 04:51:43'),
('765', 'Yonggwang-1', '35.404000', '126.419000', 'KR', '3', '21', default, '1981-06-04', default, default, '900', 'WNA', default),
('766', 'Yonggwang-2', '35.404000', '126.419000', 'KR', '3', '21', default, '1981-12-01', default, default, '900', 'WNA', default),
('767', 'Yonggwang-3', '35.404000', '126.419000', 'KR', '3', '21', default, '1989-12-23', default, default, '950', 'WNA', default),
('768', 'Yonggwang-4', '35.404000', '126.419000', 'KR', '3', '21', default, '1990-05-26', default, default, '950', 'WNA', default),
('769', 'Yonggwang-5', '35.404000', '126.419000', 'KR', '3', '21', default, '1997-06-29', default, default, '950', 'WNA', default),
('770', 'Yonggwang-6', '35.404000', '126.419000', 'KR', '3', '21', default, '1997-11-20', default, default, '950', 'WNA', default),
('771', 'Zaporozhye-1', '47.508000', '34.627000', 'UA', '3', '21', 'VVER V-320', '1980-04-01', '1985-12-25', default, '950', 'WNA/IAEA', '2015-05-24 04:51:40'),
('772', 'Zaporozhye-2', '47.508000', '34.627000', 'UA', '3', '21', 'VVER V-320', '1981-01-01', '1986-02-15', default, '950', 'WNA/IAEA', '2015-05-24 04:51:40'),
('773', 'Zaporozhye-3', '47.508000', '34.627000', 'UA', '3', '21', 'VVER V-320', '1982-04-01', '1987-03-05', default, '950', 'WNA/IAEA', '2015-05-24 04:51:40'),
('774', 'Zaporozhye-4', '47.508000', '34.627000', 'UA', '3', '21', 'VVER V-320', '1983-04-01', '1988-04-14', default, '950', 'WNA/IAEA', '2015-05-24 04:51:40'),
('775', 'Zaporozhye-5', '47.508000', '34.627000', 'UA', '3', '21', 'VVER V-320', '1985-11-01', '1989-10-27', default, '950', 'WNA/IAEA', '2015-05-24 04:51:39'),
('776', 'Zaporozhye-6', '47.508000', '34.627000', 'UA', '3', '21', 'VVER V-320', '1986-06-01', '1996-09-17', default, '950', 'WNA/IAEA', '2015-05-24 04:51:39'),
('777', 'Zhangzhou-1', default, default, 'CN', '1', '21', default, default, default, default, default, 'WNA', default),
('778', 'Zion-1', '42.446000', '-87.801000', 'US', '5', '21', 'WH 4LP', '1968-12-01', '1973-12-31', '1998-02-13', '1040', 'WNA/IAEA', '2017-02-10 23:58:20'),
('779', 'Zion-2', '42.446000', '-87.801000', 'US', '5', '21', 'WH 4LP', '1968-12-01', '1974-09-17', '1998-02-13', '1040', 'WNA/IAEA', '2017-02-10 23:58:24'),
('780', 'Fangchenggang-3', '21.600000', '108.300000', 'CN', '2', '21', 'HPR1000', '2015-12-24', default, default, '1000', 'IAEA', '2016-03-09 18:44:20'),
('781', 'Barakah-4', '23.952748', '52.203298', 'AE', '2', '21', 'APR-1400', '2015-07-30', default, default, '1345', 'IAEA', '2016-03-09 18:44:24'),
('783', 'Kanupp-2', '24.845000', '66.790000', 'PK', '2', '21', 'ACP-1000', '2015-08-20', default, default, '1014', 'IAEA', '2017-02-10 23:59:38'),
('784', 'Fangchenggang-4', '21.600000', '108.300000', 'CN', '2', '21', 'HPR1000', '2016-12-23', default, default, '1000', 'IAEA', '2017-02-10 23:59:38'),
('785', 'Kanupp-3', '24.845000', '66.790000', 'PK', '2', '21', 'ACP-1000', '2016-05-31', default, default, '1014', 'IAEA', '2017-02-10 23:59:39'),
('786', 'Rooppur-1', '24.066667', '89.047222', 'BD', '2', '21', 'VVER V-523', '2017-11-30', default, default, '1080', 'IAEA', '2018-03-10 20:52:25'),
('787', 'Kursk 2-1', '51.674000', '35.607000', 'RU', '2', '21', 'VVER V-510K', '2018-04-29', default, default, '1175', 'IAEA', '2019-06-02 20:19:00'),
('788', 'Rooppur-2', '24.066667', '89.047222', 'BD', '2', '21', 'VVER V-523', '2018-07-14', default, default, '1080', 'IAEA', '2018-10-13 22:30:35'),
('789', 'Kursk 2-2', '51.674000', '35.607000', 'RU', '2', '21', 'VVER V-510K', '2019-04-15', default, default, '1175', 'IAEA', '2019-06-02 20:19:04');

update nuclear_power_plants
set power_plants_latitude = abs(power_plants_latitude), power_plants_longitude = abs(power_plants_longitude)
where power_plants_latitude < 0 or power_plants_longitude < 0;

update nuclear_power_plants
set power_plants_latitude = rand()*70
where round(power_plants_latitude,1) = 50.5;

update nuclear_power_plants
set power_plants_longitude = rand()*90
where round(power_plants_longitude,1) = 25.5;

insert into largest_production_centers(production_centers_name,production_centers_country_code,production_centers_budget,production_centers_establishment_date,production_centers_founder) values
('Rationale-124','ZW',2802719513,'2003-8-8','Ryzhanov Arseniy Mechislavovich'),
('Arbutus-138','ZM',121310568,'1976-1-11','Zukhin Solomon Vladimirovich'),
('Salem-198','ZA',3422511744,'1975-3-15','Gavrilov Rodion Anikitevich'),
('Arginine-99','YT',507987051,'1992-11-23','Bondarev Foka Ilyevich'),
('Remedy-42','YE',390219536,'2016-5-10','Panin Gabriel Pakhomovich'),
('Beer-325','WS',3084016124,'1963-8-2','Bolsunov Dmitry Vyacheslavovich'),
('Emanuel-367','WF',1988805105,'2005-7-19','Yafaev Kondrat Andriyanovich'),
('Condolence-372','VU',732297934,'1993-3-4','Yezhin Modest Bronislavovich'),
('Clattery-218','VN',738661606,'1985-12-10','Kirpa Prokhor Sergeevich'),
('Tractor-41','VI',1901517646,'1977-1-19','Need Andron Eugenevich'),
('Explosive-127','VG',1137042422,'1966-6-28','Mashkov Andron Ippolitovich'),
('Contrast-105','VE',3513245289,'1995-5-10','Shvardygula Veniamin Kapitonovich'),
('Sojourn-392','VC',3994987686,'1972-11-1','Sakharovsky Stanislav Fedotovich'),
('Liken-314','VA',878273102,'2008-1-29','Putintsev Sokrat Ipatievich'),
('Eyebright-226','UZ',927574624,'2014-1-26','Polishchuk Yakub Vyacheslavovich'),
('Shark-390','UY',101938686,'2008-5-2','Foroponov Adrian Anatolyevich'),
('Edinburgh-339','US',3814922200,'1985-4-21','Sigov Mikhail Andronikovich'),
('Proboscis-303','UM',3813492083,'1965-3-18','Zoshchenko Grigory Danilevich'),
('Matsumoto-330','UG',3431972384,'2016-10-23','Yagunov Oleg Miroslavovich'),
('Withdrawn-353','UA',2166317836,'1971-10-17','Venediktov Lavr Cheslavovich'),
('Georgetown-193','TZ',678132472,'2010-5-12','Gavrilov Vaclav Feliksovich'),
('Vertex-43','TW',227394629,'2006-11-27','Grachev Gennady Egorovich'),
('Chaucer-20','TV',2685900081,'1998-9-15','Berry Vadim Mikhailovich'),
('Quest-93','TT',2618698824,'2014-5-20','Krutikov Arthur Andriyanovich'),
('Carol-331','TR',1680105053,'2005-6-16','Sabitov Platon Naumovich'),
('Connote-84','TO',1812662676,'1969-7-4','Kopylov Evsey Ipatievich'),
('Rose-205','TN',850056536,'1994-12-5','Fedorov Elizar Eliseevich'),
('Pushy-375','TM',320553323,'1986-7-6','Cantonists Taras Nikanorovich'),
('Vetch-350','TK',2063855635,'1961-6-19','Yavorsky Vadim Rodionovich'),
('Limitate-362','TJ',2926564509,'1984-1-17','Veselovsky Feofan Ulyanovich'),
('Botswana-368','TH',818493865,'2016-4-29','Vikashev Vseslav Emilevich'),
('Dialogue-331','TG',3141882023,'1976-2-15','Tsyrkunov Dementy Adamovich'),
('Begging-241','TF',1145525142,'1979-2-1','Nikadenko Fadey Grigorievich'),
('Fealty-269','TD',1650901969,'1969-9-15','Sukhorukov Roman Serafimovich'),
('Southwest-349','TC',3984564691,'2016-11-29','Komissarov Ilya Kasyanovich'),
('Cicada-269','SZ',248069769,'2011-11-13','Zobov Mikhey Leonidovich'),
('Peasant-156','SY',228255975,'1996-8-13','Rusakov Methodius Andreevich'),
('Strickland-13','SV',1884302577,'2012-7-14','Lavrentiev Bogdan Onisimovich'),
('Limpet-258','ST',3473086635,'2009-6-3','Elmpt Prokhor Filimonovich'),
('Hidebound-383','SR',3523393344,'1966-4-24','Kresanov Arkady Iosifovich'),
('Keyhole-160','SO',3420709851,'2006-8-17','Abalyshev Ruben Anikitevich'),
('Siren-19','SN',585073902,'1970-1-4','Maltsov Luka Zakharovich'),
('Colon-164','SM',2448668851,'1986-8-12','Shidlovsky Gavrila Ignatievich'),
('Ukrainian-219','SL',3249776359,'1966-2-6','Terekhov Mikhey Semenovich'),
('Wynn-160','SK',1827882950,'1976-6-2','Dudakov Mikhey Vladislavovich'),
('Dichondra-242','SJ',254226517,'1986-4-2','Yatskovsky Venedikt Zinovievich'),
('Dichotomy-267','SI',2010104821,'1978-8-27','Andreichenko Vladilen Martyanovich'),
('Damselfly-204','SH',2251403836,'1966-8-26','Kharlamov Valentin Anikitevich'),
('Lowland-143','SG',997532914,'1991-3-24','Popov Kirill Tikhonovich'),
('Whittle-276','SE',2953314720,'1984-9-8','Rogov Irakli Iraklievich'),
('Verlag-209','SD',1993334264,'1991-9-19','Borkov Oleg Anikitevich'),
('Sophia-304','SC',2920782793,'2012-5-8','Slepinin Prokl Mironovich'),
('Brigand-322','SB',1945567138,'1972-4-21','Bogomazov Terenty Ipatovich'),
('Kennedy-121','SA',902645239,'1965-5-21','Yasinsky German Modestovich'),
('Aerodynamic-16','RW',3934559317,'1988-8-9','Karaulin Ilya Markovich'),
('Bilayer-23','RU',2359792809,'1969-12-21','Garkin Pakhom Modestovich'),
('Mccullough-198','RO',1495923898,'1988-2-21','Volkov Kim Vsevolodovich'),
('Welcome-251','RE',2877963752,'2007-6-19','Bragin Joseph Eliseevich'),
('Baptistery-157','QA',3161550224,'1965-3-13','Loskutov Kazimir Kazimirovich'),
('Halstead-263','PY',1951683101,'1975-2-1','Milekhin Karl Kirillovich'),
('Detent-116','PW',3470584071,'1962-1-22','Klimenko Savely Evgrafovich'),
('Animism-41','PT',262131213,'1985-5-15','Sarana Proclus Eugenevich'),
('Bleary-16','PS',2140857637,'1970-9-21','Koltyshev Artyom Apollinarievich'),
('Shoe-296','PR',1591561770,'1968-6-24','Abrosimov Nikon Sidorovich'),
('Folic-199','PN',89704407,'1989-5-12','Yavchunovsky Evsey Cheslavovich'),
('Jacksonville-156','PM',1567770518,'1981-3-25','Khitrovo Kondrat Zakharovich'),
('Mauritania-344','PL',1141997705,'2010-2-25','Bysov Vincent Ipatovich'),
('Profligate-125','PK',1477510544,'2017-5-27','Alexandrin Avdey Mikhailovich'),
('Poughkeepsie-267','PH',3552069453,'1979-7-7','Ignatiev Arthur Rodionovich'),
('Winkle-97','PG',1298447647,'1993-8-20','Chernakov Anatoly Timurovich'),
('Pectoral-115','PF',2342088035,'1993-9-3','Shikalov Rodion Kasyanovich'),
('Road-376','PE',2843507188,'2009-1-18','Klepakhov Mark Andreevich'),
('Pulverable-164','PA',559999502,'1982-7-23','Zagidullin Julian Ignatievich'),
('Capetown-35','OM',661248719,'2013-9-1','Hanykov Philip Fedotovich'),
('Etruria-212','NZ',2801873310,'2004-2-1','Salagin Kuzma Vsevolodovich'),
('Redcoat-55','NU',2394985085,'1994-11-25','Paulkin Evgeny Pakhomovich'),
('Numerology-75','NR',1566765468,'2013-4-12','Musorin Taras Vladimirovich'),
('Flannel-73','NP',3769917548,'1974-9-17','Kadtsyn Matvey Eliseevich'),
('Hernandez-126','NO',787022400,'2013-6-12','Kruzhkov Kondraty Artemievich'),
('Jewel-372','NL',3118586536,'1985-11-18','Boltonogov Bronislav Feoktistovich'),
('Inflexible-270','NI',1773529590,'1963-12-11','Krivorotov Aristarkh Ilyevich'),
('Mn-275','NG',2438803760,'2018-12-24','Nusuev Tikhon Kazimirovich'),
('Fleming-296','NF',1048797978,'1964-5-2','Agaltsov Vincent Nestorovich'),
('Russo-269','NE',226898207,'1977-5-18','Kuvshinov Bartholomew Gavrilevich'),
('Sharpen-175','NC',260430168,'1987-7-29','Yantsev Venedikt Tarasovich'),
('Estonia-380','NA',2875128599,'1961-10-29','Laer Nikolai Andriyanovich'),
('Conqueror-287','MZ',2014511576,'1999-2-5','Zavrazhny Serafim Nikonovich'),
('Gastronome-126','MY',3891010204,'2010-12-23','Kvartovsky Cheslav Timurovich'),
('Habitant-274','MX',857579109,'1972-10-1','Korzhaev Efrem Artemievich'),
('Certify-132','MW',758082990,'1970-4-14','Balaev Gavriil Matveevich'),
('Savanna-169','MV',2145288447,'1993-10-4','Stepnov Grigory Matveevich'),
('Stallion-399','MU',3605143804,'1971-7-14','Golubev Maksimilyan Grigorievich'),
('Chondrite-67','MT',3178988005,'1972-9-28','Zherdev Ruben Kondratievich'),
('Prolific-96','MS',2232676725,'2015-1-12','Sorokin Moses Nazarovich'),
('Pheromone-200','MR',2113794840,'2000-2-15','Yakovtsov Arseniy Yurievich'),
('Tart-326','MQ',171183520,'2009-11-17','Yakushchenko Polikarp Andronikovich'),
('Impermeable-59','MP',2061294163,'1965-11-7','Lisitsyn Afanasy Ilyevich'),
('Jones-199','MO',835228565,'1966-6-29','Zvyagin Vsevolod Gerasimovich'),
('Smithfield-271','MN',866663015,'1977-2-22','Kochenkov Proclus Ernstovich'),
('Crosslink-32','MM',2884578274,'1986-7-24','Suvorov Elizar Olegovich'),
('Carrot-22','ML',1989098536,'1979-2-6','Rashet Juno Georgievna'),
('Perceptive-195','MK',3214391678,'2015-2-11','Petrukhina Alina Vitalievna'),
('Hillmen-10','MH',2156760412,'1989-5-25','Shcherba Elena Yakovovna'),
('Tool-86','MG',1095215766,'1973-9-2','Kravchuk Svetlana Kazimirovna'),
('Smokescreen-318','MD',3349595855,'2012-2-12','Shirmanova Alexandra Nikitevna'),
('Shunt-128','MC',1009684237,'1966-12-24','Queen Juno Zakharovna'),
('Armenia-298','MA',657978255,'1974-9-9','Vinogradova Natalya Fedotovna'),
('Chug-137','LY',1301187726,'2015-4-5','Strakhova Sofya Stepanovna'),
('Yew-307','LV',3916499739,'1977-5-18','Yarilina Agniya Potapovna'),
('Dickinson-379','LU',1792123993,'1964-2-19','Nazarova Liliya Fedotovna'),
('Simplex-353','LT',476470728,'2011-4-1','Saibatalova Tamara Vsevolodovna'),
('Choosy-400','LS',3069219590,'2015-12-25','Guslyakova Marfa Igorevna'),
('Voodoo-168','LR',1388258819,'1999-2-9','Shulgina Svetlana Igorevna'),
('Poach-247','LK',3316075702,'1999-8-9','Tipalova Ksenia Zakharovna'),
('Malaise-37','LI',3704443788,'1991-3-1','Okladnikova Lidia Pavelovna'),
('Difficulty-64','LC',742724397,'1985-12-10','Belomestny Margarita Kazimirovna'),
('Funk-137','LB',3595979216,'1999-10-12','Ionova Diana Zakharovna'),
('Basaltic-127','LA',429390724,'1973-5-29','Lagutova Dina Vladlenovna'),
('Foothill-166','KZ',2357296155,'2002-6-19','Yarullina Rosalia Vsevolodovna'),
('Extradite-322','KY',2855907926,'2015-3-6','Kuvaeva Anfisa Nikolaevna'),
('Aforethought-10','KW',939731030,'2005-11-9','Tukaeva Liana Vyacheslavovna'),
('Scrubby-269','KR',3741640206,'2018-11-13','Russian Evdokia Yulievna'),
('Dietician-292','KP',181524602,'1985-2-3','Enotina Zinaida Ignatievna'),
('Tapir-295','KN',2494170944,'1999-1-13','Abumailova Kira Anatolievna'),
('Relevant-284','KM',1824761728,'1991-11-11','Kochubey Renata Fedotovna'),
('Wildebeest-14','KI',3650598509,'1991-7-5','Proskurkina Alla Efimovna'),
('Solicitude-129','KH',2409611406,'1976-8-17','Kudyashova Eva Gennadievna'),
('Asterisk-309','KG',3082377276,'1996-7-21','Neges Sofya Timurovna'),
('Boutique-244','KE',543149366,'1962-12-11','Yablokova Iraida Ilyevna'),
('Search-66','JP',3191926792,'1969-7-9','Agafonova Ekaterina Feliksovna'),
('Isocline-69','JO',878307765,'1990-11-27','Nasonova Regina Kuzmevna'),
('Prosper-130','JM',2620433498,'1990-4-24','Dubinkina Yaroslava Anatolievna'),
('Enzyme-216','IT',3104139489,'1961-12-25','Yachmenkova Kira Timurovna'),
('Kick-100','IS',3750659512,'1964-5-6','Ugolnikova Ksenia Rodionovna'),
('Crook-322','IR',2328306416,'1995-1-24','Yangosyarova Eleonora Nikitevna'),
('Cajole-68','IQ',3460766921,'2019-10-6','Tsutskikh Daria Fomevna'),
('Tibetan-57','IO',342615999,'1962-6-11','Yakunchikova Marina Stepanovna'),
('Candid-325','IN',91583206,'1975-1-7','Yamanova Ksenia Rodionovna'),
('Exegesis-133','IL',2567603790,'1961-5-16','Vitiugova Anna Rodionovna'),
('Portal-193','IE',1734885265,'1970-2-28','Zhvanetsa Irina Fomevna'),
('Confuse-385','ID',201504457,'2000-10-28','Solomina Angelina Mikheevna'),
('Barbiturate-284','HU',1249602685,'2019-2-16','Elmpt Iraida Mironovna'),
('Abbas-202','HT',892286001,'1974-9-8','Laricheva Vseslava Kuzmevna'),
('Polecat-102','HR',85529605,'1993-3-5','Andreeva Kristina Borisovna'),
('Shipman-133','HN',1920625318,'2007-4-11','Kazankova Inga Semenovna'),
('Bryce-177','HM',1536746931,'1969-1-14','Uksyuzova Nika Emelyanovna'),
('Seasonal-49','HK',3247299330,'1989-4-6','Nosatenko Marfa Karpovna'),
('Thrifty-305','GY',1553352035,'1998-8-19','Medvedeva Evgenia Nestorovna'),
('Genteel-159','GW',3127993634,'1970-10-11','Dubrovina Khristina Rodionovna'),
('Sepulchral-256','GU',1951123394,'1997-6-3','Lavrova Natalia Gennadievna'),
('Nun-183','GT',1248734217,'1997-8-14','Kasharina Olga Romanovna'),
('Fallout-42','GS',214351416,'2014-4-11','Nikonenko Valentina Danilevna'),
('Pete-100','GR',644305375,'2000-10-23','Ohrema Sofya Davidovna'),
('Offbeat-187','GQ',2518489962,'1979-5-19','Lazutkina Evdokia Feliksovna'),
('Shaky-68','GP',290329317,'1971-8-11','Plyukhina Liana Stanislavovna'),
('Crud-113','GN',400160779,'1996-11-26','Novokshonova Tamara Fomevna'),
('Technician-233','GM',3952951931,'1979-10-27','Kondakova Natalia Afanasievna'),
('Acerbity-164','GL',3640543972,'2018-1-19','Kovshutina Faina Yulievna'),
('Sorenson-53','GI',1959377879,'1961-7-14','Ovechkina Elizaveta Nikitevna'),
('Inconvenient-388','GH',1797413658,'1974-3-5','Yuveleva Nina Iraklievna'),
('Emitted-244','GF',826178161,'2012-6-7','Kaznova Lyubov Timurovna'),
('Suave-302','GE',1622150956,'1963-3-18','Rytova Galina Bronislavovna'),
('Thus-357','GD',877919443,'1987-7-24','Kataeva Vseslav Davidovna'),
('Slur-214','GB',1579538058,'1996-10-18','Kuprevich Stela Georgievna'),
('Muskegon-360','GA',2547266992,'1982-12-17','Bodrova Inga Potapovna'),
('Guinevere-170','FR',1018574530,'1979-5-9','Astredinova Anfisa Evgenievna'),
('Honeysuckle-84','FO',2532646072,'1977-12-16','Negutorova Emilia Olegovna'),
('Schoolmate-179','FM',2639098499,'1970-4-13','Yakimycheva Maria Kuzmevna'),
('Sermon-285','FK',1445431909,'2005-10-12','Kazakova Inessa Iraklievna'),
('Sad-260','FJ',3907150699,'1987-9-7','Mozgovoy Marina Semenovna'),
('Embargo-16','FI',3345570702,'1976-2-2','Dultseva Evgenia Rostislavovna'),
('Odious-238','ET',604472872,'1969-2-9','Lyalyushkina Evelina Leonidovna'),
('Toolmake-23','ES',1987442906,'2000-10-10','Galkina Sofya Afanasievna'),
('Reap-232','ER',3438420516,'2014-3-15','Bruchanova Angelina Kazimirovna'),
('Spandrel-252','EH',2306134846,'1964-5-15','Gornostaeva Natalia Igorevna'),
('Istanbul-113','EG',1506025633,'1964-5-6','Yaltseva Zlata Filippovna'),
('Lookup-126','EE',1808006360,'1992-9-15','Stain Renata Nikolaevna'),
('Splint-10','EC',3017823450,'1988-10-14','Dumpling Nona Mikheevna'),
('Voluptuous-123','DZ',2228289036,'1974-12-23','Yarykina Ulyana Elizarovna'),
('Mummy-390','DO',1194701890,'1983-1-27','Golovchenko Liana Mironovna'),
('Insert-69','DM',128562285,'1993-12-15','Novozhilova Klara Fedorovna'),
('Award-336','DK',1291692204,'2009-3-14','Saytakhmetova Yunona Nikolaevna'),
('Sulfurous-52','DJ',3372833262,'1962-11-21','Yasaveeva Agnia Zakharovna'),
('Chlorate-355','DE',113322483,'1978-2-11','Queen Evdokia Semenovna'),
('Pax-29','CZ',2630351396,'2009-12-20','Sycheva Agnia Yulievna'),
('Quicklime-11','CY',2720988195,'1970-7-15','Berlunova Arina Rostislavovna'),
('Miscellaneous-364','CX',1903321574,'2004-1-20','Erofeeva Regina Mironovna'),
('Tidewater-78','CV',2571964041,'2017-8-19','Yamilova Evgenia Ilarionovna'),
('Gosh-309','CU',3118891954,'1964-12-6','Yaklashkina Marfa Alekseevna'),
('Tamale-102','CR',897063605,'1997-4-9','Berlunova Maria Pavelovna'),
('Integrate-56','CO',2932076468,'2018-10-11','Shatova Lada Georgievna'),
('Haney-280','CN',2328365484,'2011-10-14','Sleptsova Aza Pavelovna'),
('Nutrition-254','CM',3417334524,'1982-7-21','Yaseva Eleanor Kuzmevna'),
('Preston-190','CL',1623717114,'2000-10-29','Kobzeva Margarita Timofeevna'),
('Collimate-328','CK',1548090516,'2014-3-13','Yastrebova Tamara Trofimovna'),
('Downplay-317','CI',3260267437,'1961-7-21','Kuznetsova Ksenia Ivanovna'),
('Sprout-134','CH',1911562480,'1961-3-18','Kapralova Agata Rodionovna'),
('Girl-185','CG',3774238219,'2005-6-4','Kumoviev Anisya Mironovna'),
('Poughkeepsie-385','CF',1663282622,'1981-2-24','Bolokana Daria Stepanovna'),
('Wagging-400','CD',1795659272,'1969-5-21','Barysheva Valeria Anatolievna'),
('Malevolent-241','CC',2929488748,'1997-4-22','Ryzhanov Arseniy Mechislavovich'),
('Conn-67','CA',3359706148,'1973-11-2','Zukhin Solomon Vladimirovich'),
('Remedy-353','BZ',3145172128,'1979-5-25','Gavrilov Rodion Anikitevich'),
('Legal-119','BY',682954106,'1986-1-8','Bondarev Foka Ilyevich'),
('Autocorrelate-353','BW',582549448,'1998-10-2','Panin Gabriel Pakhomovich'),
('Oval-16','BV',1791439095,'1980-10-23','Bolsunov Dmitry Vyacheslavovich'),
('Dogbane-97','BT',1181273618,'1989-7-15','Yafaev Kondrat Andriyanovich'),
('Buttermilk-367','BS',2049275103,'1967-5-14','Yezhin Modest Bronislavovich'),
('Glaucous-306','BR',1786179309,'1991-1-24','Kirpa Prokhor Sergeevich'),
('Backwater-389','BO',2082742568,'2001-1-1','Need Andron Eugenevich'),
('Forgery-241','BN',829922097,'2006-5-25','Mashkov Andron Ippolitovich'),
('Sophisticate-19','BM',684002062,'1963-1-6','Shvardygula Veniamin Kapitonovich'),
('Detach-108','BJ',490086104,'1991-9-5','Sakharovsky Stanislav Fedotovich'),
('Rootstock-28','BI',927373712,'2004-9-8','Putintsev Sokrat Ipatievich'),
('Sima-374','BH',1614501517,'2015-5-17','Polishchuk Yakub Vyacheslavovich'),
('Wastrel-318','BG',2936270083,'1963-9-18','Foroponov Adrian Anatolyevich'),
('Capacitate-159','BF',1034504800,'1993-3-6','Sigov Mikhail Andronikovich'),
('Businesswomen-302','BE',988164723,'1960-8-14','Zoshchenko Grigory Danilevich'),
('Blackout-128','BD',2614272968,'1985-5-27','Yagunov Oleg Miroslavovich'),
('Agglomerate-140','BB',2815249444,'1970-6-27','Venediktov Lavr Cheslavovich'),
('Hateful-113','BA',2535241594,'1987-7-18','Gavrilov Vaclav Feliksovich'),
('Camino-289','AZ',1563343964,'1967-3-21','Grachev Gennady Egorovich'),
('Slavery-137','AW',74519740,'1990-8-29','Berry Vadim Mikhailovich'),
('Chablis-245','AU',509096443,'2019-6-6','Krutikov Arthur Andriyanovich'),
('Cataleptic-78','AT',2586470023,'2008-12-4','Sabitov Platon Naumovich'),
('Waals-207','AS',2711071304,'1979-11-15','Kopylov Evsey Ipatievich'),
('Cognate-275','AR',3782782747,'2000-6-19','Fedorov Elizar Eliseevich'),
('Coadjutor-28','AQ',552840577,'2016-6-19','Cantonists Taras Nikanorovich'),
('Rifle-381','AO',2436539591,'1981-10-17','Yavorsky Vadim Rodionovich'),
('Bourn-207','AN',2023528587,'2001-4-4','Veselovsky Feofan Ulyanovich'),
('Meat-227','AM',86013429,'1992-1-20','Vikashev Vseslav Emilevich'),
('Wise-372','AL',623628059,'2003-8-5','Tsyrkunov Dementy Adamovich'),
('Absentee-16','AI',3631918931,'1979-5-28','Nikadenko Fadey Grigorievich'),
('Trounce-200','AG',1828513002,'2011-3-1','Sukhorukov Roman Serafimovich'),
('Citroen-148','AF',3908136613,'1968-1-7','Komissarov Ilya Kasyanovich'),
('Corona-207','AE',3373931171,'2011-7-10','Zobov Mikhey Leonidovich'),
('Tinker-347','AD',384945700,'2005-12-10','Rusakov Methodius Andreevich');

insert into weapons_types(weapons_types_name,weapons_types_type,weapons_types_cost,weapons_types_action_range,weapons_types_threat_level) values
('Decompress-913','laser weapon',36767,'short-range','high'),
('Geriatric-3748','torpedo weapon',17502,'medium-range','high'),
('Toroid-3483','nuclear weapon',18666,'medium-range','medium'),
('Concise-3219','rocket weapon',17675,'medium-range','low'),
('Palladia-1763','genetic weapon',37445,'long-range','low'),
('Stickpin-649','plasma weapon',34703,'medium-range','medium'),
('Dictate-3231','chemical weapon',17636,'short-range','high'),
('Granulate-1915','gas weapon',3833,'long-range','low'),
('Preservation-2710','gas weapon',39245,'medium-range','medium'),
('Declaration-571','rocket weapon',39523,'long-range','medium'),
('Sternum-1289','rocket weapon',1201,'medium-range','medium'),
('Everhart-103','nuclear weapon',35249,'short-range','low'),
('Hatch-1443','gas weapon',38361,'long-range','medium'),
('Sophomoric-2084','gas weapon',28514,'long-range','high'),
('Auckland-2271','rocket weapon',14826,'medium-range','low'),
('Duplicable-3441','rocket weapon',3883,'medium-range','low'),
('Pseudonym-4000','torpedo weapon',39170,'medium-range','medium'),
('Stapleton-889','nuclear weapon',12777,'long-range','low'),
('Logging-2786','gas weapon',21440,'medium-range','high'),
('None-3020','chemical weapon',21819,'short-range','medium'),
('Colic-1831','torpedo weapon',3098,'long-range','low'),
('Secrecy-2302','genetic weapon',3764,'long-range','high'),
('Firmware-3377','infra-sound weapon',21957,'long-range','medium'),
('Sidemen-101','infra-sound weapon',19823,'medium-range','medium'),
('Presbyterian-848','gas weapon',3994,'medium-range','high'),
('Indorse-3894','nuclear weapon',3189,'short-range','high'),
('Gavel-2501','torpedo weapon',18266,'medium-range','low'),
('Reportorial-364','torpedo weapon',28714,'long-range','high'),
('Elution-836','rocket weapon',25095,'medium-range','medium'),
('Skye-3642','biological weapon',32777,'long-range','medium'),
('Wrong-3584','firearms weapon',11741,'short-range','high'),
('Shelley-2715','gas weapon',10594,'short-range','medium'),
('Lysine-2684','laser weapon',15012,'short-range','high'),
('Fling-939','chemical weapon',35720,'long-range','low'),
('Impinge-3277','plasma weapon',35998,'medium-range','low'),
('Duodenal-1748','nuclear weapon',12651,'medium-range','low'),
('Hothead-2790','nuclear weapon',6151,'short-range','low'),
('Hermite-1166','plasma weapon',33132,'short-range','low'),
('Concede-2101','rocket weapon',16649,'medium-range','high'),
('Fumarole-1435','laser weapon',2376,'long-range','high'),
('Coriander-259','rocket weapon',14550,'short-range','high'),
('Toto-2529','plasma weapon',6778,'long-range','medium'),
('Phosgene-1154','firearms weapon',21636,'long-range','medium'),
('Yucca-2211','plasma weapon',17560,'short-range','medium'),
('Dispelling-2631','biological weapon',25551,'short-range','high'),
('Decollimate-3664','plasma weapon',16783,'short-range','medium'),
('Certificate-2547','gas weapon',2911,'medium-range','medium'),
('Magician-2748','nuclear weapon',24892,'long-range','low'),
('Navigable-1751','genetic weapon',7101,'long-range','low'),
('Ingot-531','firearms weapon',9619,'short-range','high'),
('Sulfa-1234','laser weapon',35720,'short-range','low'),
('Galenite-3879','firearms weapon',25465,'long-range','high'),
('Decode-2957','firearms weapon',38432,'long-range','high'),
('Barbour-3585','infra-sound weapon',11748,'medium-range','low'),
('Jeremiah-446','firearms weapon',38127,'medium-range','low'),
('Avignon-688','nuclear weapon',30279,'short-range','low'),
('Eva-1146','infra-sound weapon',8918,'short-range','high'),
('Bastard-1289','gas weapon',7285,'medium-range','low'),
('Skye-2181','plasma weapon',5379,'long-range','low'),
('Martian-3229','rocket weapon',18593,'short-range','high'),
('Pigeonfoot-172','biological weapon',39126,'short-range','high'),
('Houdaille-3909','torpedo weapon',12648,'long-range','medium'),
('Hebrew-514','rocket weapon',9145,'short-range','medium'),
('Afraid-2724','chemical weapon',9270,'medium-range','low'),
('Antic-1585','nuclear weapon',8592,'long-range','medium'),
('Finance-2785','torpedo weapon',18615,'short-range','high'),
('Snap-2139','torpedo weapon',39194,'medium-range','medium'),
('Tory-1422','biological weapon',25075,'medium-range','medium'),
('Answer-1575','firearms weapon',15687,'short-range','medium'),
('Lightfooted-120','rocket weapon',10046,'short-range','high'),
('Jewish-3393','infra-sound weapon',34019,'short-range','medium'),
('Glutinous-2134','biological weapon',27002,'short-range','high'),
('Whitman-3771','chemical weapon',14111,'medium-range','low'),
('Frangipani-2612','chemical weapon',32732,'medium-range','low'),
('Montgomery-261','plasma weapon',25487,'long-range','low'),
('E-1845','genetic weapon',29008,'long-range','high'),
('Persecution-2839','plasma weapon',14872,'medium-range','low'),
('Flash-3305','plasma weapon',26280,'short-range','low'),
('Limb-3516','chemical weapon',4354,'short-range','high'),
('Debit-1637','laser weapon',34419,'medium-range','low'),
('Doolittle-1129','gas weapon',31875,'short-range','medium'),
('Rumania-838','infra-sound weapon',15480,'short-range','medium'),
('Excisable-477','laser weapon',20433,'long-range','low'),
('Inexperience-1534','plasma weapon',16126,'short-range','medium'),
('Sparge-2819','gas weapon',1358,'short-range','low'),
('Berglund-2810','firearms weapon',35766,'medium-range','high'),
('Pipeline-3918','chemical weapon',29081,'medium-range','high'),
('Affirmation-3619','infra-sound weapon',15534,'short-range','high'),
('Bengali-1970','biological weapon',17865,'long-range','low'),
('Dyestuff-1293','plasma weapon',36853,'long-range','medium'),
('Hewett-2314','plasma weapon',25805,'short-range','low'),
('Befriend-1383','infra-sound weapon',20184,'short-range','low'),
('Ike-1097','plasma weapon',34764,'long-range','high'),
('Cop-2184','infra-sound weapon',28482,'long-range','high'),
('Prohibit-3054','genetic weapon',25345,'long-range','medium'),
('Coverall-1840','nuclear weapon',25429,'long-range','high'),
('Brochure-2182','plasma weapon',26665,'long-range','high'),
('Wotan-3935','infra-sound weapon',23363,'short-range','high'),
('Haitian-1003','plasma weapon',20660,'long-range','high'),
('Amass-623','plasma weapon',30091,'medium-range','low'),
('Imposture-3953','nuclear weapon',28834,'short-range','medium'),
('Se-495','genetic weapon',4412,'short-range','low'),
('Autopilot-2720','gas weapon',25866,'short-range','high'),
('Bayreuth-1116','nuclear weapon',7049,'short-range','low'),
('Surprise-2503','laser weapon',17772,'long-range','high'),
('Hawley-3725','firearms weapon',38713,'short-range','high'),
('Indirect-1162','firearms weapon',37198,'long-range','low'),
('Tonnage-701','biological weapon',38224,'short-range','high'),
('Subversive-3813','laser weapon',25869,'short-range','high'),
('Gamete-3042','firearms weapon',12466,'medium-range','high'),
('Seditious-2147','torpedo weapon',14456,'long-range','low'),
('Tycoon-3815','infra-sound weapon',17760,'long-range','medium'),
('Snipe-1534','genetic weapon',12779,'medium-range','medium'),
('Sportsmen-656','biological weapon',27261,'short-range','low'),
('Prospect-784','gas weapon',6752,'medium-range','low'),
('Lindholm-502','plasma weapon',12434,'medium-range','low'),
('Clearheaded-1846','torpedo weapon',20316,'short-range','low'),
('Nameplate-1670','biological weapon',27693,'medium-range','medium'),
('Wingmen-521','gas weapon',39073,'long-range','medium'),
('Bathos-1227','torpedo weapon',15342,'medium-range','high'),
('Emerald-2532','nuclear weapon',25614,'long-range','medium'),
('Accomplish-2979','laser weapon',20545,'short-range','low'),
('Gossip-3065','biological weapon',17690,'short-range','high'),
('Algonquian-1035','genetic weapon',30418,'long-range','medium'),
('Wiggins-1872','firearms weapon',36387,'medium-range','medium'),
('Belfry-1065','genetic weapon',25151,'long-range','medium'),
('Forbear-2760','plasma weapon',10515,'short-range','low'),
('Superficial-729','nuclear weapon',22416,'long-range','low'),
('Thurman-114','gas weapon',20353,'medium-range','high'),
('Highway-943','gas weapon',2707,'medium-range','medium'),
('Midstream-1759','firearms weapon',4560,'short-range','medium'),
('Batten-861','torpedo weapon',18789,'long-range','medium'),
('Moot-1746','rocket weapon',17431,'short-range','medium'),
('Pr-2567','biological weapon',29397,'medium-range','low'),
('Ragusan-2898','firearms weapon',13164,'long-range','medium'),
('Pious-3019','firearms weapon',9160,'short-range','low'),
('Jerusalem-152','torpedo weapon',32892,'long-range','high'),
('Adposition-1402','torpedo weapon',25516,'short-range','medium'),
('Brood-1668','plasma weapon',13660,'short-range','low'),
('Coruscate-3031','biological weapon',34898,'long-range','high'),
('Zeroes-1974','biological weapon',30216,'long-range','high'),
('Estrange-161','rocket weapon',34083,'long-range','high'),
('Weapon-1427','torpedo weapon',19214,'short-range','medium'),
('Handbook-3707','torpedo weapon',6919,'long-range','low'),
('Lipstick-1799','firearms weapon',33404,'long-range','low'),
('Hyphenate-3782','gas weapon',38830,'short-range','high'),
('Gala-2889','laser weapon',13814,'medium-range','low'),
('Cohesive-2421','genetic weapon',18842,'long-range','medium'),
('Refrain-415','plasma weapon',13463,'medium-range','low'),
('Peculiar-2647','genetic weapon',2547,'medium-range','low'),
('Citrus-656','biological weapon',29504,'short-range','high'),
('Axon-1359','gas weapon',7512,'medium-range','high'),
('Grandniece-251','rocket weapon',30341,'medium-range','high'),
('Capricious-2548','infra-sound weapon',20400,'long-range','low'),
('Metabole-2433','nuclear weapon',10201,'short-range','high'),
('Zirconium-1748','genetic weapon',38979,'medium-range','high'),
('Curbside-553','firearms weapon',21696,'long-range','high'),
('Dominant-664','plasma weapon',5036,'short-range','low'),
('Airman-1760','infra-sound weapon',4145,'short-range','low'),
('Icosahedra-1504','genetic weapon',39560,'long-range','low'),
('Thresh-1601','torpedo weapon',33086,'short-range','medium'),
('Transfix-1782','chemical weapon',14357,'long-range','low'),
('Decrement-1412','firearms weapon',8208,'short-range','high'),
('Carload-341','infra-sound weapon',29710,'long-range','high'),
('Inexplicit-2931','torpedo weapon',33025,'medium-range','high'),
('Olav-3762','firearms weapon',32618,'short-range','medium'),
('Rennet-1007','chemical weapon',1794,'long-range','medium'),
('Devil-1961','chemical weapon',22951,'short-range','high'),
('Individuate-1247','plasma weapon',27855,'short-range','high'),
('Sandman-1820','plasma weapon',15953,'short-range','medium'),
('Tropopause-899','gas weapon',38563,'short-range','medium'),
('Pupal-2552','biological weapon',3795,'short-range','medium'),
('Symposia-207','rocket weapon',26361,'short-range','high'),
('Most-1989','laser weapon',26107,'short-range','high'),
('Byronic-1449','infra-sound weapon',11155,'medium-range','medium'),
('Sculpture-3183','firearms weapon',4223,'medium-range','high'),
('Tugboat-2942','torpedo weapon',33656,'long-range','low'),
('Stealthy-834','rocket weapon',30205,'medium-range','medium'),
('Wotan-2027','firearms weapon',12438,'short-range','high'),
('Lady-175','chemical weapon',33275,'short-range','medium'),
('Hughes-980','gas weapon',38064,'medium-range','high'),
('Notify-833','plasma weapon',18090,'short-range','high'),
('Jacqueline-2732','biological weapon',10943,'long-range','high'),
('Canterelle-115','laser weapon',17256,'long-range','medium'),
('Obsidian-701','torpedo weapon',19260,'short-range','medium'),
('Auger-2230','biological weapon',25366,'short-range','medium'),
('Chronograph-734','plasma weapon',11143,'medium-range','medium'),
('Oxnard-3781','gas weapon',13474,'medium-range','high'),
('Hydrochloric-453','gas weapon',27153,'medium-range','medium'),
('Polyandry-1911','biological weapon',10556,'short-range','high'),
('Cit-3189','laser weapon',19522,'short-range','high'),
('Cocky-246','laser weapon',14490,'short-range','low'),
('Asher-721','infra-sound weapon',18753,'short-range','high'),
('Poi-2618','torpedo weapon',12716,'long-range','high'),
('Anorthosite-3629','plasma weapon',8898,'medium-range','low'),
('Shylock-2623','torpedo weapon',37794,'medium-range','medium'),
('Bernhard-652','torpedo weapon',14934,'short-range','high'),
('Paint-1457','laser weapon',26360,'short-range','low'),
('Frostbitten-1066','genetic weapon',20455,'medium-range','high'),
('Plaza-2809','chemical weapon',36109,'long-range','high'),
('Pooh-1597','firearms weapon',6774,'long-range','low'),
('Emblematic-2556','nuclear weapon',28030,'medium-range','low'),
('Mediocre-2635','torpedo weapon',38203,'medium-range','medium'),
('Lame-2572','biological weapon',21680,'medium-range','low'),
('Mcgee-3481','rocket weapon',38222,'long-range','medium'),
('Zodiac-454','plasma weapon',28604,'short-range','medium'),
('Indoor-1345','firearms weapon',30837,'long-range','high'),
('Ricotta-2240','nuclear weapon',38358,'medium-range','low'),
('Oblivious-2702','torpedo weapon',26853,'medium-range','low'),
('Retaliate-1127','plasma weapon',4537,'short-range','high'),
('Gamete-3687','torpedo weapon',32043,'medium-range','medium'),
('Spawn-1322','torpedo weapon',33607,'short-range','high'),
('Boca-3188','rocket weapon',21899,'medium-range','medium'),
('Marlene-409','gas weapon',31858,'long-range','low'),
('Convoy-3605','infra-sound weapon',5328,'long-range','high'),
('Scintillate-3005','genetic weapon',17104,'medium-range','medium'),
('Pill-1754','chemical weapon',39758,'medium-range','high'),
('Vacillate-3178','genetic weapon',20898,'medium-range','medium'),
('Deluge-3322','torpedo weapon',1860,'medium-range','medium'),
('Rejoice-3455','firearms weapon',28343,'short-range','medium'),
('Oneill-586','firearms weapon',32073,'long-range','medium'),
('Autocratic-1793','chemical weapon',17153,'medium-range','medium'),
('Executor-553','nuclear weapon',13936,'medium-range','medium'),
('Sienna-3502','genetic weapon',9146,'long-range','low'),
('Warplane-2317','rocket weapon',19626,'medium-range','medium'),
('Careworn-2232','biological weapon',12631,'short-range','medium'),
('Fm-3283','gas weapon',3783,'long-range','high'),
('Sanctity-323','firearms weapon',37714,'medium-range','low'),
('Waterman-830','plasma weapon',19953,'long-range','low'),
('Emblazon-2953','firearms weapon',21404,'short-range','high'),
('Iniquitous-685','nuclear weapon',37587,'long-range','low'),
('Anyhow-2388','torpedo weapon',19963,'medium-range','high'),
('Disciplinary-3262','rocket weapon',2795,'medium-range','high'),
('Purge-3747','chemical weapon',16353,'long-range','low'),
('Fum-2726','torpedo weapon',27014,'long-range','high'),
('Detach-3893','gas weapon',4817,'long-range','low'),
('Formaldehyde-3876','torpedo weapon',8501,'long-range','low'),
('Turret-884','genetic weapon',9920,'short-range','medium'),
('Stapleton-774','biological weapon',37955,'short-range','medium'),
('Nebulae-1207','infra-sound weapon',12579,'short-range','medium'),
('Hippocratic-2341','biological weapon',24466,'long-range','low'),
('Clout-165','infra-sound weapon',15671,'medium-range','high'),
('Pyridine-3804','genetic weapon',36862,'long-range','high'),
('Vilify-2853','firearms weapon',26819,'medium-range','low'),
('Ambrosial-1316','infra-sound weapon',15956,'long-range','high'),
('Libretto-2602','infra-sound weapon',17111,'long-range','medium'),
('Inflammable-849','firearms weapon',35028,'short-range','low'),
('Nitty-1949','plasma weapon',33797,'short-range','low'),
('Personage-1600','firearms weapon',39577,'medium-range','medium'),
('Spastic-2644','rocket weapon',10907,'long-range','high'),
('Cuny-1099','laser weapon',9177,'long-range','low'),
('Wholesome-2196','nuclear weapon',29988,'medium-range','medium'),
('Crosswise-2436','firearms weapon',31171,'short-range','medium'),
('Winthrop-1323','torpedo weapon',26315,'medium-range','low'),
('Hypochlorite-3186','rocket weapon',10708,'short-range','medium'),
('Inalienable-2830','laser weapon',4108,'medium-range','low'),
('Marimba-3200','chemical weapon',14467,'long-range','low'),
('Befitting-1503','infra-sound weapon',25869,'medium-range','low'),
('Isentropic-3441','genetic weapon',36986,'short-range','low'),
('Banish-1165','plasma weapon',12130,'long-range','medium'),
('Figurine-2519','firearms weapon',34934,'medium-range','low'),
('Trag-519','infra-sound weapon',28379,'medium-range','low'),
('Symbiosis-176','chemical weapon',17637,'long-range','medium'),
('Midterm-2904','genetic weapon',22548,'long-range','low'),
('Edwardian-422','firearms weapon',30142,'long-range','high'),
('Creek-956','torpedo weapon',34727,'medium-range','low'),
('Moron-2162','plasma weapon',39712,'short-range','low'),
('Sardine-2622','infra-sound weapon',20680,'long-range','low'),
('Filth-2493','infra-sound weapon',16909,'short-range','low'),
('Habib-3093','biological weapon',39792,'short-range','medium'),
('Houdini-1499','plasma weapon',1747,'short-range','high'),
('Alison-1101','infra-sound weapon',5400,'long-range','medium'),
('Involute-2135','gas weapon',14130,'long-range','medium'),
('Wineskin-446','nuclear weapon',26973,'long-range','medium'),
('Ozone-3716','gas weapon',24977,'long-range','high'),
('Palazzo-3691','plasma weapon',23824,'long-range','low'),
('Windsor-3938','laser weapon',32044,'short-range','low'),
('Ligature-3066','firearms weapon',31885,'medium-range','high'),
('Armload-3004','rocket weapon',39076,'short-range','low'),
('Testimony-2346','laser weapon',11536,'short-range','medium'),
('Ia-2238','nuclear weapon',14048,'short-range','low'),
('Volta-1118','firearms weapon',15612,'medium-range','medium'),
('Beam-3380','biological weapon',17316,'short-range','low'),
('Moses-3220','chemical weapon',8313,'medium-range','medium'),
('Diplomacy-750','torpedo weapon',6836,'short-range','low'),
('Tabulate-2229','firearms weapon',9989,'long-range','medium'),
('Cur-953','biological weapon',16553,'medium-range','low'),
('Abrasive-1898','genetic weapon',31743,'long-range','medium'),
('Walnut-1243','torpedo weapon',6332,'long-range','high'),
('Acolyte-1725','rocket weapon',12253,'medium-range','high'),
('Glissade-1936','plasma weapon',6593,'short-range','high'),
('Horsepower-195','chemical weapon',12204,'short-range','low'),
('Colloquy-3737','gas weapon',39958,'short-range','low'),
('Loy-2234','gas weapon',32643,'medium-range','high'),
('Hydrant-3447','biological weapon',26483,'long-range','medium'),
('Godson-2139','plasma weapon',27264,'long-range','medium'),
('Solicit-3250','laser weapon',21690,'medium-range','medium'),
('Plaid-182','genetic weapon',37333,'long-range','high'),
('Galveston-3711','genetic weapon',37943,'medium-range','low'),
('Thirtieth-1244','gas weapon',24870,'short-range','high'),
('Madam-3279','nuclear weapon',24706,'short-range','low'),
('Chancellor-618','plasma weapon',9359,'medium-range','high'),
('Calvin-489','rocket weapon',26035,'long-range','high'),
('Deer-685','infra-sound weapon',28373,'medium-range','low'),
('Coleus-2623','biological weapon',13141,'short-range','medium'),
('Admix-3087','plasma weapon',10306,'short-range','high'),
('Injurious-1198','rocket weapon',39959,'medium-range','high'),
('Gryphon-1925','gas weapon',10978,'short-range','medium'),
('Aztec-1283','rocket weapon',21511,'long-range','low'),
('Gagging-369','firearms weapon',22267,'long-range','low'),
('Nantucket-1481','gas weapon',3308,'long-range','high'),
('Stillwater-818','genetic weapon',16377,'long-range','low'),
('Profile-114','gas weapon',1523,'medium-range','medium'),
('Gore-3910','laser weapon',23818,'short-range','medium'),
('Myopic-3329','gas weapon',37668,'short-range','low'),
('Longhorn-1751','firearms weapon',27808,'long-range','low'),
('Caliber-234','gas weapon',3775,'long-range','low'),
('Vicinal-2206','infra-sound weapon',33528,'medium-range','high'),
('Wristwatch-393','genetic weapon',5163,'long-range','low'),
('Perspicacity-3281','chemical weapon',11698,'medium-range','medium'),
('Chinamen-2678','biological weapon',28464,'long-range','medium'),
('Southpaw-1350','nuclear weapon',20444,'short-range','high'),
('Blum-3127','plasma weapon',22195,'short-range','medium'),
('Mosquito-3761','firearms weapon',31678,'short-range','medium'),
('Capricorn-3750','torpedo weapon',24352,'long-range','high'),
('Loudspeaking-2414','gas weapon',16571,'medium-range','high'),
('Eureka-3534','laser weapon',3999,'medium-range','high'),
('Moloch-460','torpedo weapon',1660,'long-range','high'),
('Chairmen-530','nuclear weapon',35902,'medium-range','low'),
('Lineprinter-753','genetic weapon',3540,'short-range','medium'),
('Heyday-1000','chemical weapon',28881,'long-range','medium'),
('Propyl-1553','infra-sound weapon',23009,'medium-range','high'),
('Gaslight-3013','nuclear weapon',38777,'medium-range','low'),
('Valiant-3539','biological weapon',25187,'long-range','high'),
('Strawberry-401','rocket weapon',34328,'medium-range','medium'),
('Exegesis-2760','infra-sound weapon',4764,'long-range','low'),
('Household-393','infra-sound weapon',11150,'medium-range','medium'),
('Ferrer-2383','nuclear weapon',38458,'medium-range','medium'),
('Caw-2087','laser weapon',32673,'long-range','high'),
('Fain-3552','torpedo weapon',5623,'short-range','low'),
('Cameo-3595','infra-sound weapon',7056,'long-range','high'),
('Whod-3518','gas weapon',6691,'long-range','medium'),
('Proponent-3697','plasma weapon',1843,'short-range','high'),
('Manifest-1655','gas weapon',17432,'medium-range','low'),
('Mercenary-1126','infra-sound weapon',30374,'medium-range','low'),
('Pyrometer-3363','rocket weapon',18409,'medium-range','low'),
('Snobbish-1691','firearms weapon',36745,'short-range','high'),
('Pastoral-3225','chemical weapon',27822,'long-range','high'),
('Tonight-3698','chemical weapon',27127,'long-range','low'),
('Calamus-1149','genetic weapon',23241,'medium-range','medium'),
('Wilbur-1096','infra-sound weapon',18448,'short-range','medium'),
('Introject-3405','torpedo weapon',22095,'medium-range','high'),
('Mestizo-1441','firearms weapon',19929,'medium-range','low'),
('Inventive-1026','infra-sound weapon',26806,'short-range','high'),
('Chitin-782','laser weapon',35005,'long-range','medium'),
('Mcallister-1971','gas weapon',13341,'medium-range','medium'),
('Mercurial-3576','torpedo weapon',29388,'short-range','low'),
('Daimler-3569','infra-sound weapon',36738,'long-range','low'),
('Rickets-3935','chemical weapon',28785,'medium-range','low'),
('Orchis-1457','infra-sound weapon',15099,'short-range','medium'),
('Chromatograph-2926','infra-sound weapon',23604,'long-range','low'),
('Humane-546','infra-sound weapon',7747,'short-range','medium'),
('Creedal-3842','plasma weapon',19503,'long-range','low'),
('Consolation-1784','plasma weapon',8183,'medium-range','medium'),
('Insensible-1314','rocket weapon',36414,'medium-range','low'),
('Exonerate-2492','infra-sound weapon',4505,'long-range','high'),
('Pickoff-1908','chemical weapon',36585,'medium-range','high'),
('Searchlight-3510','laser weapon',27386,'short-range','high'),
('Split-2328','nuclear weapon',24199,'long-range','high'),
('Pretentious-904','gas weapon',12469,'medium-range','medium'),
('Cagey-407','plasma weapon',36370,'short-range','low'),
('Neutral-888','plasma weapon',4015,'medium-range','low'),
('Splat-1437','laser weapon',33498,'long-range','low'),
('Ireland-3025','infra-sound weapon',28985,'medium-range','low'),
('Short-2065','gas weapon',7857,'medium-range','low'),
('Convalescent-2172','nuclear weapon',12905,'medium-range','low'),
('Parsley-3721','plasma weapon',17277,'short-range','high'),
('Ribosome-2918','chemical weapon',8005,'medium-range','low'),
('Ernest-3152','laser weapon',37259,'short-range','high'),
('Cloak-2265','laser weapon',22134,'medium-range','high'),
('Caloric-2280','firearms weapon',23240,'long-range','high'),
('Roomy-669','gas weapon',5904,'medium-range','medium'),
('Studebaker-1651','torpedo weapon',35189,'long-range','high'),
('Doorway-1491','chemical weapon',29460,'short-range','medium'),
('Sound-1127','plasma weapon',17854,'short-range','high'),
('Hillcrest-3583','rocket weapon',3718,'long-range','high'),
('Nazi-3504','rocket weapon',2427,'medium-range','high'),
('Farley-3547','biological weapon',37061,'medium-range','high'),
('Sweat-1858','plasma weapon',36471,'medium-range','high'),
('Ironic-128','gas weapon',30775,'long-range','low'),
('Warehouseman-1830','chemical weapon',6012,'long-range','high'),
('Adoption-480','torpedo weapon',18300,'long-range','low'),
('Serenade-3237','rocket weapon',11946,'short-range','low'),
('Neil-800','plasma weapon',38033,'medium-range','medium'),
('Votive-1546','gas weapon',19962,'short-range','high'),
('Stipulate-1715','nuclear weapon',24769,'medium-range','low'),
('Noticeable-1543','genetic weapon',13280,'medium-range','high'),
('Contraception-387','biological weapon',15036,'long-range','high'),
('Exotic-1252','nuclear weapon',7119,'medium-range','medium'),
('Inveterate-2487','gas weapon',36113,'long-range','low'),
('Ithaca-2953','firearms weapon',18910,'medium-range','medium'),
('Catnip-1885','rocket weapon',37646,'long-range','medium'),
('Duckweed-643','biological weapon',4451,'short-range','low'),
('Darling-1814','torpedo weapon',34777,'long-range','high'),
('Ell-1973','torpedo weapon',17571,'medium-range','high'),
('Enzyme-1635','infra-sound weapon',34159,'long-range','low'),
('Pride-154','biological weapon',29777,'medium-range','medium'),
('Crank-1400','rocket weapon',8188,'medium-range','medium'),
('Epicure-1300','biological weapon',30288,'short-range','low'),
('Strenuous-3008','gas weapon',3884,'long-range','medium'),
('Scientific-1579','genetic weapon',32657,'short-range','high'),
('Pollinate-831','plasma weapon',32339,'medium-range','high'),
('Tinny-2213','genetic weapon',17424,'medium-range','high'),
('Intestinal-2442','plasma weapon',15938,'long-range','low'),
('Profuse-465','nuclear weapon',1219,'long-range','high'),
('Fragmentation-927','chemical weapon',26103,'short-range','high'),
('Buckshot-3932','plasma weapon',36063,'short-range','low'),
('Conserve-3692','infra-sound weapon',38148,'short-range','medium'),
('Proper-2539','biological weapon',8156,'medium-range','low'),
('Barren-3754','laser weapon',10090,'long-range','medium'),
('Orca-3972','chemical weapon',37972,'long-range','high'),
('Hypocritic-1797','genetic weapon',8314,'short-range','low'),
('Sibilant-2630','rocket weapon',9243,'long-range','high'),
('Immodest-2808','genetic weapon',1994,'medium-range','low'),
('Katie-1109','infra-sound weapon',38743,'short-range','high'),
('Crown-3779','nuclear weapon',7670,'short-range','medium'),
('Tuff-2356','infra-sound weapon',38437,'short-range','medium'),
('Vowel-3846','rocket weapon',38368,'long-range','high'),
('Bizarre-3805','firearms weapon',14666,'medium-range','low'),
('Chromatograph-3497','gas weapon',35141,'short-range','low'),
('Antonio-1127','torpedo weapon',37368,'long-range','low'),
('Trophic-3587','laser weapon',18806,'long-range','high'),
('Symbiote-3191','biological weapon',2563,'short-range','medium'),
('Nurse-3917','nuclear weapon',21053,'short-range','high'),
('Clot-1592','biological weapon',13659,'short-range','medium'),
('Wellwisher-3623','gas weapon',30800,'long-range','high'),
('Chivalrous-1868','firearms weapon',2256,'medium-range','low'),
('Panther-2239','plasma weapon',14651,'short-range','medium'),
('Menopause-3934','chemical weapon',28306,'long-range','medium'),
('Mana-617','gas weapon',30928,'medium-range','low'),
('Dervish-2098','genetic weapon',25620,'long-range','low'),
('Lotus-716','nuclear weapon',26611,'long-range','medium'),
('Harden-3791','plasma weapon',14476,'medium-range','high'),
('Midwinter-1183','genetic weapon',24534,'medium-range','low'),
('Woodcock-3576','chemical weapon',37868,'short-range','low'),
('Telephotography-1071','infra-sound weapon',30177,'short-range','low'),
('Abo-336','torpedo weapon',5520,'short-range','high'),
('Nosy-1758','firearms weapon',8389,'short-range','low'),
('Incessant-2632','gas weapon',6681,'medium-range','low'),
('Taxiway-2025','firearms weapon',27136,'short-range','low'),
('Mix-1629','nuclear weapon',17462,'medium-range','high'),
('Thereto-3768','biological weapon',26117,'long-range','high'),
('Several-3335','laser weapon',2061,'long-range','medium'),
('Lind-1947','plasma weapon',5722,'medium-range','low'),
('Pullover-3675','plasma weapon',13520,'medium-range','high'),
('Clam-3288','nuclear weapon',22626,'long-range','medium'),
('Pyroelectric-2530','rocket weapon',10912,'long-range','medium'),
('Maze-2047','genetic weapon',13656,'long-range','high'),
('Toni-1605','infra-sound weapon',29339,'medium-range','high'),
('Repressive-868','rocket weapon',28177,'medium-range','medium'),
('Reese-1358','rocket weapon',31985,'medium-range','high'),
('Sextuple-2349','biological weapon',38004,'medium-range','high'),
('Blameworthy-2119','torpedo weapon',27159,'long-range','low'),
('Parolee-3655','nuclear weapon',20424,'short-range','medium'),
('Sen-3111','infra-sound weapon',27671,'medium-range','medium'),
('Appleton-640','chemical weapon',15661,'medium-range','low'),
('Ratify-2377','nuclear weapon',26287,'long-range','medium'),
('Occupant-3851','chemical weapon',29502,'long-range','medium'),
('Dolomite-3455','plasma weapon',10025,'short-range','low'),
('Callosity-301','torpedo weapon',5241,'long-range','low'),
('Erosive-3287','gas weapon',36113,'medium-range','low'),
('Husbandry-3894','laser weapon',19027,'long-range','high'),
('Entry-823','gas weapon',10464,'long-range','high'),
('Yam-1571','torpedo weapon',4618,'short-range','high');

insert into weapons_warehouse(weapons_warehouse_ref_production_centers,weapons_warehouse_ref_weapons_types,weapons_warehouse_quantity) values
(1,326,58),(1,468,145),(1,419,101),
(2,181,157),(2,446,147),(2,292,127),
(3,19,68),(3,213,200),(3,393,51),
(4,445,34),(4,466,180),(4,165,130),
(5,186,30),(5,108,187),(5,196,139),
(6,451,86),(6,120,58),(6,264,95),
(7,159,155),(7,360,168),(7,11,156),
(8,4,32),(8,367,85),(8,146,57),
(9,326,175),(9,57,147),(9,173,38),
(10,357,107),(10,263,44),(10,192,74),
(11,289,172),(11,107,32),(11,71,51),
(12,316,190),(12,87,63),(12,230,94),
(13,31,50),(13,343,94),(13,178,143),
(14,425,150),(14,430,122),(14,116,146),
(15,463,141),(15,321,45),(15,298,114),
(16,68,164),(16,336,181),(16,15,173),
(17,379,57),(17,356,180),(17,430,49),
(18,359,41),(18,389,81),(18,23,167),
(19,37,68),(19,202,139),(19,195,155),
(20,103,42),(20,336,134),(20,166,115),
(21,13,172),(21,62,165),(21,462,39),
(22,124,82),(22,223,51),(22,404,131),
(23,155,100),(23,88,36),(23,90,171),
(24,271,122),(24,342,114),(24,366,69),
(25,250,172),(25,459,81),(25,60,159),
(26,114,101),(26,118,50),(26,129,174),
(27,468,72),(27,412,94),(27,32,129),
(28,59,96),(28,134,44),(28,128,84),
(29,418,172),(29,430,68),(29,366,166),
(30,113,83),(30,209,149),(30,257,87),
(31,120,144),(31,378,121),(31,59,52),
(32,274,43),(32,5,70),(32,122,113),
(33,300,192),(33,226,120),(33,111,34),
(34,44,189),(34,52,30),(34,421,110),
(35,203,55),(35,409,38),(35,435,34),
(36,440,155),(36,198,181),(36,291,173),
(37,446,169),(37,74,128),(37,318,162),
(38,405,155),(38,136,79),(38,340,130),
(39,246,85),(39,193,111),(39,303,140),
(40,472,50),(40,14,175),(40,67,168),
(41,15,80),(41,163,138),(41,214,193),
(42,467,198),(42,429,42),(42,440,164),
(43,333,97),(43,460,45),(43,193,96),
(44,115,63),(44,177,81),(44,6,91),
(45,201,188),(45,474,173),(45,326,137),
(46,433,69),(46,35,55),(46,309,167),
(47,222,80),(47,451,112),(47,440,128),
(48,216,198),(48,390,85),(48,101,144),
(49,17,160),(49,138,64),(49,376,32),
(50,85,148),(50,333,108),(50,377,89),
(51,339,46),(51,255,172),(51,249,78),
(52,411,149),(52,431,170),(52,433,130),
(53,211,196),(53,174,170),(53,94,86),
(54,46,116),(54,118,49),(54,441,77),
(55,162,137),(55,457,133),(55,343,120),
(56,129,195),(56,207,88),(56,173,121),
(57,134,176),(57,138,96),(57,431,50),
(58,115,163),(58,413,148),(58,423,105),
(59,329,183),(59,470,194),(59,344,96),
(60,333,115),(60,297,61),(60,254,197),
(61,452,41),(61,260,89),(61,437,152),
(62,369,40),(62,240,39),(62,163,97),
(63,284,61),(63,27,42),(63,136,161),
(64,440,145),(64,348,163),(64,309,175),
(65,163,181),(65,257,121),(65,174,88),
(66,414,44),(66,222,109),(66,327,162),
(67,226,164),(67,283,46),(67,327,83),
(68,344,145),(68,382,99),(68,244,40),
(69,409,100),(69,324,76),(69,347,195),
(70,106,187),(70,267,35),(70,49,182),
(71,238,107),(71,185,198),(71,287,81),
(72,115,137),(72,197,174),(72,89,196),
(73,112,124),(73,349,112),(73,124,169),
(74,249,97),(74,340,174),(74,471,137),
(75,377,48),(75,347,47),(75,87,144),
(76,447,44),(76,40,166),(76,140,122),
(77,182,93),(77,317,120),(77,70,92),
(78,324,159),(78,311,155),(78,292,196),
(79,401,31),(79,281,140),(79,425,168),
(80,55,141),(80,141,138),(80,67,118),
(81,416,167),(81,405,34),(81,161,102),
(82,260,33),(82,46,92),(82,73,138),
(83,419,107),(83,344,77),(83,222,189),
(84,347,76),(84,278,153),(84,196,126),
(85,178,72),(85,386,147),(85,33,124),
(86,419,109),(86,300,101),(86,191,164),
(87,248,190),(87,151,133),(87,449,55),
(88,449,144),(88,103,126),(88,340,126),
(89,403,186),(89,367,98),(89,348,155),
(90,201,105),(90,320,53),(90,237,93),
(91,204,155),(91,8,117),(91,429,42),
(92,89,167),(92,247,177),(92,275,123),
(93,413,103),(93,461,48),(93,109,33),
(94,261,169),(94,92,60),(94,27,82),
(95,340,32),(95,248,181),(95,169,121),
(96,297,165),(96,126,94),(96,464,60),
(97,81,106),(97,267,64),(97,6,186),
(98,432,148),(98,388,118),(98,424,45),
(99,239,40),(99,140,32),(99,183,187),
(100,82,33),(100,128,95),(100,123,103),
(101,189,65),(101,105,96),(101,9,67),
(102,317,154),(102,339,113),(102,63,88),
(103,335,71),(103,313,109),(103,42,194),
(104,365,189),(104,325,137),(104,14,77),
(105,283,161),(105,299,91),(105,167,128),
(106,228,31),(106,355,191),(106,50,162),
(107,29,113),(107,189,133),(107,228,73),
(108,31,107),(108,240,166),(108,274,108),
(109,351,38),(109,461,190),(109,461,31),
(110,269,147),(110,374,48),(110,269,43),
(111,108,97),(111,112,130),(111,208,108),
(112,441,175),(112,463,54),(112,211,170),
(113,355,103),(113,123,62),(113,153,109),
(114,61,156),(114,351,123),(114,190,67),
(115,170,42),(115,439,187),(115,231,132),
(116,60,166),(116,389,108),(116,424,113),
(117,89,193),(117,187,121),(117,380,87),
(118,76,117),(118,389,31),(118,138,128),
(119,346,37),(119,31,159),(119,123,101),
(120,226,128),(120,339,181),(120,311,92),
(121,294,144),(121,217,79),(121,211,80),
(122,327,194),(122,5,177),(122,176,167),
(123,187,69),(123,11,109),(123,79,192),
(124,388,172),(124,15,64),(124,390,84),
(125,310,200),(125,176,87),(125,103,188),
(126,4,112),(126,66,142),(126,232,100),
(127,167,75),(127,435,153),(127,423,161),
(128,285,87),(128,408,168),(128,23,146),
(129,8,53),(129,287,111),(129,232,166),
(130,206,126),(130,200,76),(130,1,182),
(131,315,110),(131,394,80),(131,353,123),
(132,157,86),(132,456,82),(132,158,127),
(133,248,105),(133,380,146),(133,114,187),
(134,33,170),(134,248,95),(134,429,96),
(135,249,83),(135,226,76),(135,457,41),
(136,429,102),(136,399,165),(136,289,117),
(137,149,107),(137,134,124),(137,295,46),
(138,54,196),(138,460,88),(138,44,54),
(139,42,129),(139,419,152),(139,88,36),
(140,456,115),(140,443,87),(140,373,54),
(141,142,79),(141,431,106),(141,413,179),
(142,309,193),(142,358,30),(142,394,56),
(143,54,124),(143,4,87),(143,229,169),
(144,469,108),(144,463,107),(144,370,42),
(145,414,61),(145,233,121),(145,181,153),
(146,464,199),(146,470,99),(146,185,116),
(147,420,68),(147,98,105),(147,263,137),
(148,106,110),(148,305,182),(148,347,54),
(149,301,83),(149,47,149),(149,33,149),
(150,154,163),(150,388,32),(150,299,158),
(151,72,138),(151,446,72),(151,428,159),
(152,33,31),(152,103,107),(152,167,94),
(153,137,97),(153,311,169),(153,235,71),
(154,332,106),(154,414,45),(154,363,124),
(155,108,100),(155,203,95),(155,268,167),
(156,404,186),(156,382,92),(156,187,133),
(157,261,167),(157,442,168),(157,388,59),
(158,35,35),(158,87,128),(158,14,116),
(159,326,88),(159,244,199),(159,291,82),
(160,81,137),(160,57,157),(160,467,78),
(161,287,136),(161,66,37),(161,428,65),
(162,296,126),(162,159,112),(162,461,191),
(163,307,131),(163,338,41),(163,389,134),
(164,186,87),(164,320,113),(164,305,102),
(165,359,50),(165,347,36),(165,42,103),
(166,327,175),(166,218,50),(166,15,71),
(167,425,75),(167,151,176),(167,42,61),
(168,202,103),(168,444,32),(168,450,198),
(169,189,61),(169,191,82),(169,454,175),
(170,50,136),(170,21,187),(170,289,135),
(171,319,171),(171,119,99),(171,146,80),
(172,442,194),(172,13,104),(172,56,185),
(173,28,34),(173,256,164),(173,474,140),
(174,310,85),(174,121,181),(174,182,93),
(175,185,97),(175,228,167),(175,155,142),
(176,472,44),(176,203,65),(176,408,124),
(177,198,44),(177,51,111),(177,362,85),
(178,42,35),(178,8,48),(178,398,121),
(179,289,182),(179,151,183),(179,229,115),
(180,336,95),(180,312,95),(180,388,46),
(181,157,117),(181,332,60),(181,191,141),
(182,59,113),(182,313,134),(182,364,52),
(183,333,98),(183,25,53),(183,251,171),
(184,213,189),(184,302,97),(184,79,157),
(185,99,101),(185,138,128),(185,288,91),
(186,115,187),(186,175,164),(186,142,94),
(187,31,92),(187,363,145),(187,319,165),
(188,118,195),(188,77,137),(188,195,50),
(189,245,54),(189,322,46),(189,313,200),
(190,471,134),(190,250,60),(190,346,126),
(191,302,110),(191,43,118),(191,166,56),
(192,273,94),(192,179,160),(192,434,102),
(193,462,35),(193,160,52),(193,269,142),
(194,215,178),(194,36,34),(194,107,147),
(195,86,57),(195,53,100),(195,119,54),
(196,405,57),(196,210,118),(196,393,200),
(197,154,114),(197,87,62),(197,450,186),
(198,38,145),(198,326,104),(198,438,181),
(199,29,103),(199,229,184),(199,436,30),
(200,160,158),(200,242,60),(200,368,177),
(201,468,57),(201,49,73),(201,360,40),
(202,382,128),(202,203,192),(202,88,197),
(203,365,127),(203,191,38),(203,51,119),
(204,310,125),(204,460,113),(204,73,60),
(205,391,102),(205,384,171),(205,8,85),
(206,407,69),(206,80,53),(206,282,197),
(207,366,157),(207,12,120),(207,273,168),
(208,382,108),(208,163,142),(208,2,195),
(209,430,179),(209,372,82),(209,237,191),
(210,79,137),(210,308,114),(210,208,48),
(211,181,149),(211,272,46),(211,173,185),
(212,421,135),(212,333,67),(212,266,139),
(213,2,72),(213,149,75),(213,103,82),
(214,14,166),(214,148,160),(214,461,181),
(215,224,55),(215,4,58),(215,197,52),
(216,284,159),(216,433,170),(216,382,43),
(217,110,183),(217,459,53),(217,464,69),
(218,361,72),(218,73,175),(218,159,133),
(219,194,120),(219,328,122),(219,313,86),
(220,354,118),(220,231,112),(220,86,39),
(221,132,51),(221,98,199),(221,322,48),
(222,175,50),(222,58,112),(222,53,191),
(223,427,48),(223,325,125),(223,383,125),
(224,460,186),(224,111,123),(224,162,187),
(225,299,142),(225,41,114),(225,474,123),
(226,375,117),(226,136,65),(226,2,117),
(227,11,68),(227,354,39),(227,39,89),
(228,150,114),(228,426,152),(228,158,157),
(229,284,58),(229,36,72),(229,258,100),
(230,154,71),(230,240,121),(230,272,129),
(231,452,96),(231,32,102),(231,21,60),
(232,390,101),(232,104,146),(232,158,96),
(233,387,95),(233,5,199),(233,54,49),
(234,49,146),(234,106,71),(234,43,101),
(235,420,186),(235,36,53),(235,27,137),
(236,260,176),(236,304,152),(236,295,191),
(237,90,180),(237,120,83),(237,275,115);

insert into weaponry_of_countries(weaponry_of_countries_ref_country_code,weaponry_of_countries_ref_weapons_types) values
('ZW',201),('ZW',231),('ZW',23),
('ZM',28),('ZM',397),('ZM',130),
('ZA',122),('ZA',237),('ZA',229),
('YT',293),('YT',249),('YT',83),
('YE',89),('YE',20),('YE',436),
('WS',277),('WS',10),('WS',447),
('WF',60),('WF',325),('WF',150),
('VU',162),('VU',20),('VU',200),
('VN',105),('VN',30),('VN',2),
('VI',205),('VI',216),('VI',244),
('VG',36),('VG',54),('VG',260),
('VE',414),('VE',307),('VE',44),
('VC',215),('VC',54),('VC',12),
('VA',275),('VA',122),('VA',169),
('UZ',271),('UZ',431),('UZ',91),
('UY',328),('UY',468),('UY',169),
('US',97),('US',355),('US',31),
('UM',280),('UM',114),('UM',469),
('UG',128),('UG',63),('UG',155),
('UA',254),('UA',78),('UA',317),
('TZ',37),('TZ',374),('TZ',268),
('TW',247),('TW',151),('TW',341),
('TV',408),('TV',55),('TV',293),
('TT',5),('TT',221),('TT',53),
('TR',271),('TR',448),('TR',319),
('TO',18),('TO',450),('TO',257),
('TN',384),('TN',146),('TN',112),
('TM',445),('TM',243),('TM',60),
('TK',24),('TK',449),('TK',371),
('TJ',263),('TJ',260),('TJ',95),
('TH',189),('TH',227),('TH',192),
('TG',402),('TG',183),('TG',346),
('TF',285),('TF',49),('TF',76),
('TD',17),('TD',390),('TD',381),
('TC',339),('TC',329),('TC',292),
('SZ',413),('SZ',143),('SZ',257),
('SY',226),('SY',339),('SY',108),
('SV',333),('SV',192),('SV',70),
('ST',188),('ST',418),('ST',88),
('SR',311),('SR',469),('SR',366),
('SO',2),('SO',32),('SO',137),
('SN',378),('SN',168),('SN',68),
('SM',6),('SM',61),('SM',260),
('SL',7),('SL',169),('SL',13),
('SK',11),('SK',396),('SK',237),
('SJ',201),('SJ',287),('SJ',291),
('SI',454),('SI',343),('SI',320),
('SH',413),('SH',134),('SH',189),
('SG',92),('SG',216),('SG',240),
('SE',13),('SE',107),('SE',181),
('SD',316),('SD',128),('SD',113),
('SC',320),('SC',103),('SC',307),
('SB',181),('SB',445),('SB',235),
('SA',25),('SA',116),('SA',358),
('RW',169),('RW',404),('RW',133),
('RU',108),('RU',435),('RU',258),
('RO',467),('RO',209),('RO',47),
('RE',166),('RE',298),('RE',219),
('QA',158),('QA',190),('QA',15),
('PY',250),('PY',447),('PY',406),
('PW',73),('PW',213),('PW',390),
('PT',368),('PT',90),('PT',286),
('PS',437),('PS',11),('PS',228),
('PR',139),('PR',113),('PR',321),
('PN',1),('PN',191),('PN',444),
('PM',387),('PM',331),('PM',432),
('PL',36),('PL',28),('PL',288),
('PK',366),('PK',310),('PK',432),
('PH',122),('PH',157),('PH',171),
('PG',430),('PG',191),('PG',1),
('PF',306),('PF',276),('PF',4),
('PE',75),('PE',336),('PE',361),
('PA',385),('PA',187),('PA',345),
('OM',256),('OM',29),('OM',77),
('NZ',38),('NZ',51),('NZ',101),
('NU',24),('NU',427),('NU',4),
('NR',270),('NR',39),('NR',131),
('NP',268),('NP',169),('NP',417),
('NO',78),('NO',228),('NO',155),
('NL',387),('NL',380),('NL',440),
('NI',442),('NI',264),('NI',112),
('NG',454),('NG',444),('NG',456),
('NF',443),('NF',185),('NF',39),
('NE',139),('NE',420),('NE',405),
('NC',370),('NC',38),('NC',473),
('NA',464),('NA',225),('NA',8),
('MZ',222),('MZ',172),('MZ',211),
('MY',364),('MY',101),('MY',290),
('MX',34),('MX',392),('MX',464),
('MW',82),('MW',253),('MW',397),
('MV',380),('MV',131),('MV',283),
('MU',454),('MU',286),('MU',269),
('MT',456),('MT',129),('MT',130),
('MS',276),('MS',261),('MS',156),
('MR',100),('MR',350),('MR',21),
('MQ',424),('MQ',78),('MQ',460),
('MP',196),('MP',115),('MP',293),
('MO',251),('MO',129),('MO',48),
('MN',97),('MN',442),('MN',247),
('MM',54),('MM',368),('MM',434),
('ML',462),('ML',212),('ML',419),
('MK',471),('MK',422),('MK',74),
('MH',444),('MH',390),('MH',397),
('MG',265),('MG',470),('MG',203),
('MD',191),('MD',462),('MD',224),
('MC',190),('MC',474),('MC',286),
('MA',55),('MA',89),('MA',311),
('LY',451),('LY',218),('LY',392),
('LV',262),('LV',237),('LV',145),
('LU',419),('LU',193),('LU',78),
('LT',195),('LT',465),('LT',181),
('LS',232),('LS',141),('LS',392),
('LR',153),('LR',314),('LR',374),
('LK',286),('LK',263),('LK',287),
('LI',349),('LI',326),('LI',131),
('LC',371),('LC',233),('LC',422),
('LB',397),('LB',257),('LB',142),
('LA',467),('LA',438),('LA',450),
('KZ',221),('KZ',256),('KZ',231),
('KY',228),('KY',249),('KY',188),
('KW',438),('KW',227),('KW',192),
('KR',133),('KR',175),('KR',300),
('KP',260),('KP',202),('KP',421),
('KN',141),('KN',362),('KN',122),
('KM',299),('KM',417),('KM',43),
('KI',231),('KI',407),('KI',336),
('KH',46),('KH',326),('KH',357),
('KG',177),('KG',234),('KG',31),
('KE',34),('KE',84),('KE',317),
('JP',180),('JP',374),('JP',387),
('JO',82),('JO',259),('JO',215),
('JM',107),('JM',235),('JM',59),
('IT',291),('IT',397),('IT',216),
('IS',316),('IS',168),('IS',285),
('IR',177),('IR',234),('IR',149),
('IQ',295),('IQ',117),('IQ',39),
('IO',396),('IO',41),('IO',18),
('IN',345),('IN',473),('IN',94),
('IL',66),('IL',244),('IL',130),
('IE',33),('IE',102),('IE',252),
('ID',312),('ID',129),('ID',245),
('HU',379),('HU',1),('HU',18),
('HT',41),('HT',407),('HT',45),
('HR',17),('HR',246),('HR',462),
('HN',10),('HN',209),('HN',47),
('HM',317),('HM',283),('HM',119),
('HK',14),('HK',28),('HK',251),
('GY',225),('GY',182),('GY',317),
('GW',8),('GW',238),('GW',65),
('GU',457),('GU',117),('GU',399),
('GT',41),('GT',243),('GT',100),
('GS',141),('GS',327),('GS',98),
('GR',338),('GR',39),('GR',363),
('GQ',28),('GQ',370),('GQ',45),
('GP',297),('GP',363),('GP',134),
('GN',101),('GN',404),('GN',273),
('GM',293),('GM',385),('GM',24),
('GL',150),('GL',131),('GL',71),
('GI',218),('GI',167),('GI',406),
('GH',348),('GH',333),('GH',387),
('GF',173),('GF',229),('GF',162),
('GE',383),('GE',204),('GE',178),
('GD',213),('GD',474),('GD',352),
('GB',326),('GB',353),('GB',327),
('GA',441),('GA',181),('GA',433),
('FR',361),('FR',227),('FR',142),
('FO',412),('FO',210),('FO',108),
('FM',319),('FM',154),('FM',188),
('FK',394),('FK',330),('FK',410),
('FJ',328),('FJ',339),('FJ',102),
('FI',351),('FI',391),('FI',296),
('ET',147),('ET',103),('ET',422),
('ES',349),('ES',58),('ES',143),
('ER',343),('ER',460),('ER',5),
('EH',374),('EH',439),('EH',378),
('EG',106),('EG',175),('EG',387),
('EE',10),('EE',323),('EE',6),
('EC',331),('EC',421),('EC',89),
('DZ',365),('DZ',455),('DZ',247),
('DO',333),('DO',106),('DO',388),
('DM',391),('DM',60),('DM',333),
('DK',84),('DK',420),('DK',176),
('DJ',221),('DJ',4),('DJ',19),
('DE',195),('DE',10),('DE',97),
('CZ',172),('CZ',331),('CZ',228),
('CY',290),('CY',158),('CY',38),
('CX',225),('CX',5),('CX',350),
('CV',451),('CV',43),('CV',349),
('CU',133),('CU',91),('CU',165),
('CR',312),('CR',426),('CR',342),
('CO',375),('CO',46),('CO',81),
('CN',207),('CN',457),('CN',139),
('CM',146),('CM',203),('CM',76),
('CL',273),('CL',136),('CL',213),
('CK',434),('CK',465),('CK',244),
('CI',428),('CI',356),('CI',132),
('CH',221),('CH',76),('CH',383),
('CG',435),('CG',242),('CG',307),
('CF',91),('CF',278),('CF',200),
('CD',60),('CD',56),('CD',220),
('CC',274),('CC',78),('CC',205),
('CA',105),('CA',35),('CA',277),
('BZ',202),('BZ',421),('BZ',117),
('BY',69),('BY',319),('BY',339),
('BW',305),('BW',472),('BW',305),
('BV',322),('BV',10),('BV',284),
('BT',185),('BT',303),('BT',19),
('BS',63),('BS',99),('BS',309),
('BR',226),('BR',229),('BR',159),
('BO',360),('BO',223),('BO',329),
('BN',46),('BN',59),('BN',407),
('BM',442),('BM',280),('BM',121),
('BJ',255),('BJ',69),('BJ',346),
('BI',300),('BI',359),('BI',401),
('BH',433),('BH',59),('BH',248),
('BG',368),('BG',219),('BG',151),
('BF',332),('BF',433),('BF',44),
('BE',362),('BE',250),('BE',34),
('BD',329),('BD',338),('BD',292),
('BB',41),('BB',353),('BB',131),
('BA',336),('BA',465),('BA',86),
('AZ',440),('AZ',301),('AZ',291),
('AW',32),('AW',331),('AW',440),
('AU',100),('AU',111),('AU',390),
('AT',4),('AT',6),('AT',156),
('AS',189),('AS',325),('AS',262),
('AR',472),('AR',79),('AR',273),
('AQ',62),('AQ',409),('AQ',389),
('AO',210),('AO',380),('AO',427),
('AN',368),('AN',329),('AN',182),
('AM',193),('AM',315),('AM',255),
('AL',20),('AL',194),('AL',396),
('AI',245),('AI',156),('AI',326),
('AG',458),('AG',271),('AG',49),
('AF',375),('AF',199),('AF',253),
('AE',163),('AE',166),('AE',248),
('AD',240),('AD',322),('AD',376);

insert into military_conflicts(military_conflicts_conflicting_party_1,military_conflicts_conflicting_party_2,military_conflicts_start_date,military_conflicts_end_date,military_conflicts_conflict_cause,military_conflicts_used_weapon) values
('MU','LV','1960-8-15','2010-4-8','Buddhism',395),
('MK','RE','1935-12-18','2009-4-10','struggle',406),
('KP','SE','1930-9-29','2012-7-13','anomaly',163),
('NA','SB','1946-7-1','2008-1-21','Anaheim',206),
('SE','BN','1955-1-25','2010-7-6','Anglican',460),
('ML','NL','1971-9-11','2015-10-8','meson',269),
('YT','GS','1990-2-9','2014-7-5','hailstorm',364),
('PM','MZ','1970-8-10','2018-6-11','Alcmena',394),
('KI','NE','1985-11-28','2005-4-13','inattentive',74),
('BA','NC','1905-8-16','2004-7-1','Orinoco',283),
('MG','BT','1933-8-28','2002-9-2','stonewall',400),
('CO','SE','1911-4-19','2012-5-13','Eucharist',86),
('JO','RU','1933-9-22','2001-5-27','rakish',284),
('RO','HN','1947-12-19','2009-5-27','Martinez',314),
('CY','BZ','1949-3-6','2018-11-24','together',155),
('ML','BD','1993-4-18','2018-12-17','distraught',122),
('KM','KZ','1983-6-8','2010-4-11','drive',324),
('KP','MX','1964-3-20','2014-4-14','gruesome',474),
('SG','SO','1944-5-3','2006-9-6','indefatigable',300),
('CK','TK','1908-3-9','2009-6-8','condescend',140),
('EG','IO','1930-3-13','2004-12-4','affirm',284),
('PK','CO','1962-4-25','2006-1-7','McNulty',147),
('GR','GE','1939-11-27','2011-5-7','expense',174),
('KH','AD','1998-2-18','2002-2-11','letterhead',83),
('PK','OM','1944-6-16','2006-5-10','algae',414),
('MA','IN','1983-5-24','2007-6-4','smile',368),
('UM','MY','1937-7-21','2003-5-5','feature',244),
('JP','LU','1976-7-18','2008-5-13','baton',120),
('BD','GW','1973-2-23','2013-8-4','bed',268),
('EH','BA','1981-11-28','2004-9-21','Gregory',154),
('CA','AF','1994-6-25','2019-8-3','plaguey',78),
('TZ','AF','1912-12-19','2002-9-13','layperson',157),
('MN','GD','1956-6-28','2006-6-23','ahem',305),
('FI','CM','1989-12-27','2000-11-28','accidental',369),
('KZ','SC','1909-12-26','2004-1-10','dietician',294),
('AZ','QA','1993-9-9','2012-12-19','claret',429),
('PA','GD','1940-9-20','2002-4-4','cerise',233),
('AE','IQ','1908-10-25','2011-4-29','sub',225),
('DE','QA','1950-1-11','2000-12-28','doctrinal',380),
('IN','TK','1977-10-3','2011-3-1','stationmaster',353),
('SH','LU','1925-12-12','2012-7-9','renaissance',390),
('EE','AF','1929-9-25','2012-9-28','Gilead',277),
('PH','SR','1985-7-16','2007-5-25','elegant',248),
('MG','SL','1993-1-16','2004-1-28','web',97),
('IE','BZ','1960-9-27','2000-11-23','Meier',342),
('DZ','LK','1989-11-2','2002-9-17','Gothic',345),
('AF','SB','1940-2-7','2012-2-12','pain',240),
('ES','IR','1954-10-8','2009-11-23','pinhead',101),
('UG','AZ','1924-4-17','2008-10-8','sketchy',368),
('TT','GR','1942-6-19','2014-10-18','litigious',52),
('GW','DJ','1981-11-18','2003-2-6','quadrillion',325),
('IR','KN','1937-10-25','2012-7-6','scops',401),
('FI','CH','1948-3-5','2008-4-7','dysentery',16),
('CK','KZ','1998-3-5','2012-9-23','mud',30),
('CY','CV','1929-6-19','2014-11-19','ti',203),
('LC','PR','1993-11-23','2001-8-27','infrastructure',175),
('AS','AT','1910-9-25','2006-10-4','doltish',374),
('ER','AL','1902-10-12','2014-7-21','midpoint',265),
('MS','GS','1935-8-7','2013-11-11','pianoforte',436),
('BR','CY','1916-4-1','2008-7-21','seacoast',198),
('EH','CL','1916-9-3','2003-9-6','noon',87),
('KN','ML','1938-9-21','2001-3-3','Arlington',54),
('SL','VG','1943-10-19','2010-5-20','watchman',418),
('BD','MY','1905-12-25','2004-4-9','extravaganza',171),
('BO','NO','1949-11-9','2004-5-13','orphan',158),
('YT','AL','1941-3-16','2015-8-3','couturier',450),
('NO','SR','1969-6-20','2018-1-25','Diogenes',431),
('GL','MM','1990-9-17','2009-4-5','Xerxes',259),
('GB','WF','1975-8-17','2008-12-28','adhesive',286),
('GW','UG','1906-10-15','2019-9-11','crumb',435),
('AZ','GU','1941-7-8','2006-1-12','acquiesce',41),
('KY','AO','1946-11-18','2010-10-3','Iverson',8),
('BN','AZ','1904-12-12','2004-11-12','sladang',257),
('TN','SJ','1900-12-17','2007-3-9','wrap',94),
('NI','GT','1987-3-3','2005-2-15','Madrid',328),
('TJ','HT','1974-9-2','2017-2-24','childbirth',119),
('MK','AD','1914-10-15','2004-9-20','withe',443),
('YT','SL','1948-10-26','2009-4-18','leaven',250),
('GE','HU','1907-10-22','2006-7-20','downy',232),
('KI','CN','1994-12-1','2007-9-12','opaque',380),
('IO','MN','1913-5-23','2010-9-10','comparison',313),
('NZ','VI','1992-12-24','2001-9-1','deallocate',310),
('ER','HM','1997-5-20','2018-2-14','herbicide',352),
('CV','CG','1992-5-13','2018-8-18','Taiwan',4),
('KP','PM','1994-10-15','2003-4-18','trailblazer',386),
('ML','IS','1981-8-14','2009-9-4','tincture',217),
('NL','SA','1950-4-3','2018-9-18','yawl',212),
('AT','MM','1989-1-19','2016-5-13','NRC',343),
('LS','ES','1985-10-27','2000-1-21','blueprint',325),
('BZ','MT','1900-11-5','2015-8-25','oft',180),
('MS','GY','1919-11-16','2015-12-16','swordfish',357),
('DM','VG','1932-3-20','2001-9-26','Juanita',10),
('IS','TR','1916-4-5','2001-6-4','hayfield',10),
('SK','MC','1970-9-29','2002-1-20','absolution',471),
('MO','UZ','1958-8-1','2007-9-1','cable',446),
('CZ','NR','1975-11-16','2001-1-22','crawl',446),
('EE','TR','1941-12-7','2013-2-6','godson',110),
('LC','AG','1935-10-15','2011-10-17','polygonal',389),
('CK','GL','1935-10-22','2003-8-26','Tito',266),
('SZ','FJ','1984-8-12','2016-10-15','hazelnut',157);

insert into fuel_enrichment(fuel_enrichment_enterprise,fuel_enrichment_fuel_amount,fuel_enrichment_time_since_start,fuel_enrichment_fuel_type) values
(213,60228,'1907-10-28 23-43-14','oxide'),
(17,10872,'1957-10-25 13-48-4','metal'),
(99,72948,'1996-12-19 0-40-34','nitride'),
(142,65228,'1934-5-27 5-29-37','oxide'),
(220,33869,'1994-10-13 7-14-10','mixed'),
(216,32652,'1900-3-3 2-8-2','oxide'),
(142,52031,'1974-1-26 8-31-58','nitride'),
(93,17124,'1939-11-15 11-34-42','nitride'),
(82,17965,'1967-9-2 21-49-44','oxide'),
(122,71968,'1970-12-19 18-23-50','nitride'),
(203,23684,'1950-9-22 15-37-51','nitride'),
(229,22606,'1902-1-19 5-23-43','metal'),
(120,75995,'1924-5-12 17-36-59','mixed'),
(129,10723,'1954-6-24 7-37-36','mixed'),
(16,38923,'1947-8-10 4-57-49','metal'),
(149,10559,'1985-7-27 8-25-24','oxide'),
(150,78372,'1904-6-19 18-42-50','oxide'),
(104,97454,'1974-8-17 21-57-14','mixed'),
(181,55649,'1932-12-26 10-39-4','metal'),
(144,1094,'1911-2-5 5-23-47','metal'),
(119,37165,'1953-4-19 14-23-40','oxide'),
(119,19513,'1926-12-2 14-41-2','mixed'),
(104,51775,'1946-12-19 21-45-6','nitride'),
(196,6743,'1994-1-21 11-50-29','metal'),
(69,99885,'1918-12-1 16-35-50','carbide'),
(153,38702,'1940-6-26 13-37-5','metal'),
(145,3508,'1951-5-27 11-47-12','carbide'),
(187,19247,'1935-4-1 11-35-2','mixed'),
(170,85981,'1978-3-21 13-47-32','oxide'),
(190,37582,'1936-12-24 5-17-57','mixed'),
(153,71178,'1965-8-20 14-52-57','mixed'),
(170,4073,'1922-6-17 17-4-17','nitride'),
(151,34414,'1995-1-19 9-45-8','metal'),
(199,43544,'1974-2-15 21-0-40','nitride'),
(220,89044,'1900-9-17 5-29-35','carbide'),
(142,35870,'1925-9-2 14-26-25','carbide'),
(140,50537,'1957-5-22 9-39-18','oxide'),
(184,75631,'1911-10-13 3-14-19','nitride'),
(138,89556,'1992-7-2 3-6-44','metal'),
(47,26956,'1927-11-3 6-43-16','mixed'),
(188,43300,'1913-5-29 11-13-35','mixed'),
(102,77583,'1993-1-4 20-5-40','carbide'),
(155,11250,'1963-8-29 4-27-48','carbide'),
(85,78407,'1987-9-27 2-40-36','oxide'),
(128,6315,'1939-9-9 8-4-56','carbide'),
(127,86176,'1982-3-26 20-6-29','mixed'),
(122,31995,'1922-2-15 7-39-20','metal'),
(176,56177,'1917-1-12 14-34-23','mixed'),
(125,88420,'1953-5-28 11-43-54','nitride'),
(186,17990,'1909-7-9 10-56-54','mixed'),
(119,15453,'1992-9-15 8-9-31','carbide'),
(199,24209,'1914-10-4 0-50-53','nitride'),
(149,49239,'1912-2-25 8-7-17','oxide'),
(125,51567,'1978-7-21 2-17-1','oxide'),
(114,67814,'1925-8-26 15-26-54','oxide'),
(116,33431,'1991-8-12 6-1-44','oxide'),
(78,99629,'1949-2-4 7-31-17','mixed'),
(144,11679,'1974-3-24 8-39-16','metal'),
(212,31314,'1983-12-6 19-24-23','mixed'),
(180,70786,'1985-1-1 10-0-44','carbide'),
(34,96177,'1926-11-5 19-57-5','carbide'),
(142,54675,'1968-8-28 18-1-33','mixed'),
(124,1242,'1936-12-7 9-59-13','nitride'),
(188,55499,'1959-12-28 23-27-39','oxide'),
(184,20357,'1911-7-5 6-0-42','carbide'),
(53,38850,'1948-1-29 16-2-32','nitride'),
(187,45301,'1983-5-11 8-57-59','nitride'),
(144,65767,'1971-11-20 15-6-29','carbide'),
(232,38253,'1975-1-15 13-8-29','metal'),
(73,52646,'1967-3-8 8-8-39','metal'),
(73,5411,'1995-8-19 11-50-48','metal'),
(184,93206,'1999-10-10 21-48-57','carbide'),
(163,44706,'1963-12-8 17-47-42','nitride'),
(211,40019,'1941-6-10 13-46-30','oxide'),
(96,21278,'1990-8-24 20-18-55','oxide'),
(131,48631,'1902-1-11 13-15-4','carbide'),
(136,80233,'1999-8-8 8-38-16','nitride'),
(169,20065,'1933-9-15 8-15-12','nitride'),
(227,47036,'1977-8-8 13-42-2','oxide'),
(200,99267,'1998-11-14 5-40-27','nitride'),
(157,3858,'1989-7-6 13-30-26','carbide'),
(20,76507,'1980-3-23 5-55-32','carbide'),
(184,52099,'1977-5-13 8-43-46','oxide'),
(148,31633,'1986-5-26 14-51-50','nitride'),
(195,40258,'1940-2-1 7-39-31','oxide'),
(157,50334,'1996-9-8 19-46-30','mixed'),
(96,57796,'1996-11-29 17-24-29','oxide'),
(220,34975,'1966-5-24 16-41-29','carbide'),
(210,55450,'1966-4-4 19-52-14','nitride'),
(100,62113,'1945-4-27 6-56-20','carbide'),
(7,21779,'1987-7-16 8-28-8','mixed'),
(30,30913,'1981-10-24 4-34-15','oxide'),
(163,59162,'1933-10-21 15-31-29','metal'),
(108,97693,'1987-1-7 23-11-16','metal'),
(151,54432,'1941-11-8 11-16-10','carbide'),
(108,53441,'1993-8-26 23-31-12','mixed'),
(150,18442,'1961-1-12 3-21-56','carbide'),
(155,56524,'1937-7-26 20-31-41','oxide'),
(17,30534,'1997-11-19 7-1-38','oxide'),
(199,32882,'1929-2-8 6-40-19','metal');

insert into activities(activities_start_time,activities_end_time,activities_subjects,activities_speaker) values
('2005-9-7 17:30:16','2011-11-16 14:32:57','air','Ryzhanov Arseniy Mechislavovich'),
('2005-6-26 4:5:16','2009-1-25 7:23:24','especial','Zukhin Solomon Vladimirovich'),
('2001-12-23 20:52:44','2012-8-27 10:50:5','abstention','Gavrilov Rodion Anikitevich'),
('2000-1-14 5:10:20','2012-7-24 3:3:22','Zoroaster','Bondarev Foka Ilyevich'),
('2003-4-17 0:10:47','2009-12-21 22:12:49','Bremen','Panin Gabriel Pakhomovich'),
('2005-10-16 12:2:7','2019-10-21 19:17:35','Dunbar','Bolsunov Dmitry Vyacheslavovich'),
('2000-11-27 11:24:50','2015-6-29 12:54:59','deadwood','Yafaev Kondrat Andriyanovich'),
('2003-12-29 10:53:36','2009-3-22 21:56:7','grizzle','Yezhin Modest Bronislavovich'),
('2005-10-6 19:8:50','2010-3-22 19:52:20','grata','Kirpa Prokhor Sergeevich'),
('2003-2-18 17:42:45','2011-5-17 3:18:7','gourmet','Need Andron Eugenevich'),
('2004-1-14 20:2:58','2019-2-14 15:46:20','Antonio','Mashkov Andron Ippolitovich'),
('2002-2-6 23:36:4','2009-12-22 3:11:39','conversant','Shvardygula Veniamin Kapitonovich'),
('2003-3-2 23:22:58','2010-9-5 7:51:25','lanthanide','Sakharovsky Stanislav Fedotovich'),
('2004-11-18 5:29:31','2009-1-14 19:15:30','sacral','Putintsev Sokrat Ipatievich'),
('2001-8-26 10:25:41','2008-2-29 15:0:16','parishioner','Polishchuk Yakub Vyacheslavovich'),
('2001-4-29 18:40:8','2014-9-13 10:25:45','generic','Foroponov Adrian Anatolyevich'),
('2001-3-1 13:46:37','2010-2-11 8:40:11','utmost','Sigov Mikhail Andronikovich'),
('2001-2-6 10:19:35','2016-3-15 0:52:31','respiration','Zoshchenko Grigory Danilevich'),
('1999-2-18 2:34:23','2019-10-15 18:38:40','Veda','Yagunov Oleg Miroslavovich'),
('1999-8-2 13:7:51','2016-7-29 21:17:19','sockeye','Venediktov Lavr Cheslavovich'),
('2000-9-12 10:37:39','2011-8-5 10:38:23','paroxysm','Gavrilov Vaclav Feliksovich'),
('2002-12-2 6:45:6','2016-9-8 19:15:52','leverage','Grachev Gennady Egorovich'),
('2001-5-29 12:59:4','2011-9-13 6:12:8','comrade','Berry Vadim Mikhailovich'),
('1999-2-10 6:15:18','2017-7-19 1:17:33','tall','Krutikov Arthur Andriyanovich'),
('2006-11-22 6:44:44','2011-11-25 10:26:11','Basel','Sabitov Platon Naumovich'),
('2005-8-1 0:2:6','2019-11-18 5:18:16','Shakespeare','Kopylov Evsey Ipatievich'),
('2004-8-18 1:18:54','2017-5-23 5:33:12','frolic','Fedorov Elizar Eliseevich'),
('2005-9-21 4:59:27','2010-3-3 0:59:52','simplectic','Cantonists Taras Nikanorovich'),
('2001-11-25 1:41:39','2010-10-29 7:6:41','isomer','Yavorsky Vadim Rodionovich'),
('1999-2-5 14:9:43','2013-11-17 23:54:35','repartee','Veselovsky Feofan Ulyanovich'),
('2003-2-19 17:23:55','2019-4-21 12:12:0','desk','Vikashev Vseslav Emilevich'),
('2005-10-9 15:44:38','2012-7-25 2:26:36','Malden','Tsyrkunov Dementy Adamovich'),
('1999-9-10 18:56:16','2018-7-4 8:52:15','Janos','Nikadenko Fadey Grigorievich'),
('2003-11-12 3:12:38','2008-8-3 5:13:34','Khrushchev','Sukhorukov Roman Serafimovich'),
('2004-1-7 19:28:4','2017-7-28 0:13:17','policemen','Komissarov Ilya Kasyanovich'),
('2001-8-19 5:47:19','2007-11-3 6:1:42','calorie','Zobov Mikhey Leonidovich'),
('2005-6-16 13:37:28','2017-9-26 23:29:41','quibble','Rusakov Methodius Andreevich'),
('2001-10-15 19:50:7','2015-12-10 2:15:3','Hurst','Lavrentiev Bogdan Onisimovich'),
('2005-8-14 10:56:15','2019-4-4 14:29:4','spray','Elmpt Prokhor Filimonovich'),
('2002-1-10 1:27:13','2019-6-6 13:6:47','Essen','Kresanov Arkady Iosifovich'),
('2003-10-16 23:37:8','2007-10-6 19:16:35','Osiris','Abalyshev Ruben Anikitevich'),
('2002-1-12 10:48:6','2010-10-1 10:19:13','crappie','Maltsov Luka Zakharovich'),
('2005-4-7 2:26:24','2013-7-17 15:26:26','Chandigarh','Shidlovsky Gavrila Ignatievich'),
('1999-10-5 6:57:16','2009-1-6 21:41:24','spit','Terekhov Mikhey Semenovich'),
('2006-7-15 13:9:46','2010-11-18 11:32:47','Judd','Dudakov Mikhey Vladislavovich'),
('2001-11-22 8:42:13','2019-5-7 17:41:40','laissez','Yatskovsky Venedikt Zinovievich'),
('2003-6-7 4:17:37','2017-6-15 6:42:15','stab','Andreichenko Vladilen Martyanovich'),
('2000-1-13 0:32:46','2014-9-22 19:26:8','hide','Kharlamov Valentin Anikitevich'),
('2001-10-7 20:21:52','2008-10-29 13:8:28','esteem','Popov Kirill Tikhonovich'),
('2004-9-15 15:45:19','2007-12-12 7:11:55','grasp','Rogov Irakli Iraklievich'),
('2005-3-2 19:41:2','2012-9-20 0:42:22','latent','Borkov Oleg Anikitevich'),
('2006-10-8 3:3:36','2013-6-23 21:58:33','approximant','Slepinin Prokl Mironovich'),
('2003-2-12 14:34:52','2009-7-1 17:38:14','herald','Bogomazov Terenty Ipatovich'),
('2001-1-12 20:43:48','2014-10-13 15:17:20','banister','Yasinsky German Modestovich'),
('1999-8-9 16:33:15','2010-6-4 14:29:35','swanky','Karaulin Ilya Markovich'),
('2004-11-8 13:35:25','2015-9-15 2:39:31','cremate','Garkin Pakhom Modestovich'),
('2002-12-29 12:10:23','2016-6-7 13:9:29','peasant','Volkov Kim Vsevolodovich'),
('2001-9-26 17:7:15','2009-12-6 15:37:49','muscular','Bragin Joseph Eliseevich'),
('2004-9-16 5:42:27','2011-2-3 7:56:9','proximal','Loskutov Kazimir Kazimirovich'),
('1999-3-29 20:57:0','2014-11-21 7:37:15','occupant','Milekhin Karl Kirillovich'),
('2003-1-20 18:12:43','2016-5-27 20:11:27','rector','Klimenko Savely Evgrafovich'),
('2003-7-21 6:10:50','2012-2-8 0:14:37','Fiberglas','Sarana Proclus Eugenevich'),
('2003-9-6 4:41:33','2014-10-1 23:21:57','protactinium','Koltyshev Artyom Apollinarievich'),
('2004-10-5 1:5:23','2016-6-2 3:47:28','industrious','Abrosimov Nikon Sidorovich'),
('1999-1-1 7:9:9','2016-10-13 13:28:22','Trojan','Yavchunovsky Evsey Cheslavovich'),
('2004-4-22 18:44:57','2019-11-16 4:3:40','hinterland','Khitrovo Kondrat Zakharovich'),
('2001-11-2 20:34:49','2010-3-7 2:18:20','Formosa','Bysov Vincent Ipatovich'),
('2005-4-22 13:28:10','2016-8-21 8:48:28','St','Alexandrin Avdey Mikhailovich'),
('2000-5-10 17:19:29','2011-12-7 13:37:44','patriarchy','Ignatiev Arthur Rodionovich'),
('2005-1-22 19:48:21','2009-2-6 19:58:34','folio','Chernakov Anatoly Timurovich'),
('1999-12-13 6:46:59','2018-9-6 18:45:46','oxygen','Shikalov Rodion Kasyanovich'),
('2003-5-14 5:38:32','2007-10-2 9:57:9','frosty','Klepakhov Mark Andreevich'),
('2004-6-15 16:57:30','2019-2-18 4:53:1','tempestuous','Zagidullin Julian Ignatievich'),
('2000-11-3 10:50:9','2016-11-21 15:2:33','accomplish','Hanykov Philip Fedotovich'),
('2000-1-17 18:25:22','2016-8-17 22:53:54','lateral','Salagin Kuzma Vsevolodovich'),
('2004-9-19 11:3:12','2012-8-21 8:15:43','hopeful','Paulkin Evgeny Pakhomovich'),
('2006-5-20 10:8:14','2017-4-21 11:30:54','foxtail','Musorin Taras Vladimirovich'),
('1999-1-28 2:54:44','2014-3-1 21:9:32','Birmingham','Kadtsyn Matvey Eliseevich'),
('2004-4-8 5:53:30','2007-2-5 18:52:51','comedian','Kruzhkov Kondraty Artemievich'),
('1999-6-18 21:38:7','2011-12-13 14:40:28','excelsior','Boltonogov Bronislav Feoktistovich'),
('2002-11-13 15:52:27','2007-5-3 1:12:50','week','Krivorotov Aristarkh Ilyevich'),
('1999-12-22 7:9:52','2019-10-17 11:32:8','Cantabrigian','Nusuev Tikhon Kazimirovich'),
('2002-4-28 22:41:39','2011-10-25 12:23:38','upgrade','Agaltsov Vincent Nestorovich'),
('2000-7-4 22:59:6','2008-4-15 2:29:19','dwarf','Kuvshinov Bartholomew Gavrilevich'),
('2004-12-10 2:40:1','2017-5-1 12:0:19','complete','Yantsev Venedikt Tarasovich'),
('2006-10-28 10:42:49','2015-5-12 19:0:3','seeing','Laer Nikolai Andriyanovich'),
('2003-8-8 13:1:48','2016-11-5 0:23:38','ceramic','Zavrazhny Serafim Nikonovich'),
('2002-11-19 6:1:22','2007-5-19 3:12:58','connotation','Kvartovsky Cheslav Timurovich'),
('2002-12-17 10:7:46','2017-8-28 2:44:24','metazoa','Korzhaev Efrem Artemievich'),
('2000-7-20 11:28:58','2013-11-18 12:9:29','runneth','Balaev Gavriil Matveevich'),
('1999-3-27 0:57:29','2019-9-11 10:16:55','Monica','Stepnov Grigory Matveevich'),
('2005-6-10 20:0:6','2010-11-2 1:1:17','tong','Golubev Maksimilyan Grigorievich'),
('2006-1-7 15:48:8','2016-7-5 0:40:7','impartation','Zherdev Ruben Kondratievich'),
('1999-8-2 20:30:31','2012-7-3 22:49:57','Buick','Sorokin Moses Nazarovich'),
('2004-9-6 14:39:14','2014-6-11 19:18:1','detractor','Yakovtsov Arseniy Yurievich'),
('2002-4-4 3:55:29','2018-8-4 6:58:26','deed','Yakushchenko Polikarp Andronikovich'),
('2005-4-15 13:58:27','2010-7-5 22:3:16','monster','Lisitsyn Afanasy Ilyevich'),
('2004-9-7 15:38:36','2015-9-1 14:20:34','Lynn','Zvyagin Vsevolod Gerasimovich'),
('2006-11-10 20:57:40','2012-5-9 21:59:57','new','Kochenkov Proclus Ernstovich'),
('2002-1-7 6:49:6','2011-10-10 13:26:13','doddering','Suvorov Elizar Olegovich'),
('2003-7-10 4:52:54','2008-6-1 22:20:23','bronchiole','Rashet Juno Georgievna'),
('2001-10-21 4:29:54','2008-9-26 17:55:29','eyeful','Petrukhina Alina Vitalievna'),
('2005-5-7 12:37:20','2010-5-16 20:59:25','impeccable','Shcherba Elena Yakovovna'),
('1999-2-10 13:18:8','2016-6-1 4:26:16','Lorraine','Kravchuk Svetlana Kazimirovna'),
('2001-4-13 2:52:54','2010-3-28 14:23:54','instrumentation','Shirmanova Alexandra Nikitevna'),
('2006-5-9 18:36:19','2019-2-14 13:4:35','shin','Queen Juno Zakharovna'),
('2004-10-9 0:15:5','2008-10-16 8:31:17','crocus','Vinogradova Natalya Fedotovna'),
('2004-5-27 12:24:51','2009-8-12 0:16:58','decompose','Strakhova Sofya Stepanovna'),
('2002-3-4 0:57:13','2007-5-27 16:10:22','spacetime','Yarilina Agniya Potapovna'),
('2002-12-5 20:37:1','2012-5-4 0:46:42','mind','Nazarova Liliya Fedotovna'),
('2004-9-6 3:29:7','2010-1-11 13:38:19','attack','Saibatalova Tamara Vsevolodovna'),
('2003-1-27 10:39:24','2015-1-27 9:7:55','fuse','Guslyakova Marfa Igorevna'),
('1999-11-10 18:16:7','2013-12-23 13:47:17','Sabina','Shulgina Svetlana Igorevna'),
('2004-9-21 17:3:29','2018-7-4 6:20:34','architecture','Tipalova Ksenia Zakharovna'),
('2004-3-10 6:15:36','2016-12-1 7:58:42','mayor','Okladnikova Lidia Pavelovna'),
('2002-11-5 21:5:19','2017-4-22 11:59:17','Holstein','Belomestny Margarita Kazimirovna'),
('2001-11-18 16:14:27','2007-4-27 20:4:25','corny','Ionova Diana Zakharovna'),
('2004-7-2 13:28:50','2017-4-17 20:13:48','bawdy','Lagutova Dina Vladlenovna'),
('2006-8-28 2:17:2','2013-1-7 5:12:59','stevedore','Yarullina Rosalia Vsevolodovna'),
('2003-12-23 13:29:43','2014-2-7 2:8:6','wheelbase','Kuvaeva Anfisa Nikolaevna'),
('2003-6-22 10:2:47','2017-3-4 19:25:14','wit','Tukaeva Liana Vyacheslavovna'),
('2005-3-12 12:38:12','2011-10-12 0:12:35','disturbance','Russian Evdokia Yulievna'),
('2000-2-18 15:16:45','2015-7-5 11:11:33','samovar','Enotina Zinaida Ignatievna'),
('2001-2-27 2:14:3','2019-4-19 4:57:25','Warburton','Abumailova Kira Anatolievna'),
('2003-5-12 10:14:24','2014-5-13 1:59:50','politicking','Kochubey Renata Fedotovna'),
('2003-4-14 23:16:59','2009-4-26 13:19:23','comatose','Proskurkina Alla Efimovna'),
('2004-11-28 5:5:22','2013-11-24 10:21:23','wile','Kudyashova Eva Gennadievna'),
('2004-1-15 19:53:41','2007-4-12 5:32:28','Venezuela','Neges Sofya Timurovna'),
('2000-2-12 17:37:7','2007-9-21 4:44:30','peak','Yablokova Iraida Ilyevna'),
('2005-4-5 0:36:51','2007-9-29 18:24:35','ICC','Agafonova Ekaterina Feliksovna'),
('1999-4-11 8:33:19','2013-1-5 19:0:54','Nassau','Nasonova Regina Kuzmevna'),
('2002-2-13 23:47:9','2019-11-5 14:9:57','priestess','Dubinkina Yaroslava Anatolievna'),
('1999-10-4 7:22:32','2016-1-16 2:40:17','windowsill','Yachmenkova Kira Timurovna'),
('2001-9-13 8:0:56','2011-9-26 14:2:18','stewardess','Ugolnikova Ksenia Rodionovna'),
('2006-4-27 22:53:8','2014-4-17 12:55:4','Knox','Yangosyarova Eleonora Nikitevna'),
('2001-12-16 5:47:44','2011-8-5 0:23:52','Schottky','Tsutskikh Daria Fomevna'),
('1999-8-7 10:23:53','2017-6-21 18:7:7','benight','Yakunchikova Marina Stepanovna'),
('2005-8-1 11:9:42','2008-5-13 23:19:54','apathetic','Yamanova Ksenia Rodionovna'),
('2004-4-14 21:32:46','2015-11-11 4:35:24','pap','Vitiugova Anna Rodionovna'),
('2002-1-26 20:30:37','2010-4-25 0:33:9','humble','Zhvanetsa Irina Fomevna'),
('2000-4-11 16:30:12','2016-3-8 17:38:40','disdain','Solomina Angelina Mikheevna'),
('2000-7-5 2:59:20','2007-10-28 4:35:21','Sloane','Elmpt Iraida Mironovna'),
('2001-3-21 14:38:5','2014-2-28 12:43:4','Kruse','Laricheva Vseslava Kuzmevna'),
('2005-12-23 5:32:13','2011-3-3 1:29:1','append','Andreeva Kristina Borisovna'),
('2001-11-19 13:15:53','2009-3-16 12:21:46','sierra','Kazankova Inga Semenovna'),
('2002-11-23 17:26:21','2017-10-12 12:55:41','stop','Uksyuzova Nika Emelyanovna'),
('1999-11-2 5:21:33','2016-2-29 12:32:4','boy','Nosatenko Marfa Karpovna'),
('2003-9-9 2:17:29','2009-10-2 3:18:1','meetinghouse','Medvedeva Evgenia Nestorovna'),
('2000-3-7 22:37:30','2010-10-24 14:32:3','nitride','Dubrovina Khristina Rodionovna'),
('2004-2-15 6:57:19','2009-1-23 21:14:18','recalcitrant','Lavrova Natalia Gennadievna'),
('1999-7-29 2:43:37','2016-12-3 20:4:3','spillover','Kasharina Olga Romanovna'),
('1999-1-26 20:31:45','2012-11-27 7:20:46','Barbara','Nikonenko Valentina Danilevna'),
('2000-7-28 16:43:8','2013-12-29 1:42:32','consanguine','Ohrema Sofya Davidovna'),
('2002-8-1 3:28:33','2015-1-18 22:39:31','inductee','Lazutkina Evdokia Feliksovna'),
('2001-8-26 2:6:49','2016-2-25 19:8:29','lain','Plyukhina Liana Stanislavovna'),
('2002-11-6 10:37:54','2016-8-12 22:40:6','sworn','Novokshonova Tamara Fomevna'),
('2002-5-23 6:16:43','2019-3-24 20:24:24','woodcarver','Kondakova Natalia Afanasievna'),
('1999-1-19 15:53:25','2009-9-15 14:14:28','McNeil','Kovshutina Faina Yulievna'),
('2003-1-12 2:24:9','2016-10-5 19:4:19','jamboree','Ovechkina Elizaveta Nikitevna'),
('2001-10-3 10:38:5','2012-5-25 21:14:48','sportsman','Yuveleva Nina Iraklievna'),
('2000-10-22 22:46:50','2011-2-22 12:30:2','bluet','Kaznova Lyubov Timurovna'),
('2003-10-6 5:17:48','2007-3-6 21:2:51','Hatfield','Rytova Galina Bronislavovna'),
('1999-2-15 5:51:39','2010-4-13 14:47:6','enunciable','Kataeva Vseslav Davidovna'),
('2004-6-3 6:2:44','2012-4-18 13:33:3','roof','Kuprevich Stela Georgievna'),
('2001-2-26 1:29:35','2011-1-18 19:46:21','sentinel','Bodrova Inga Potapovna'),
('2005-12-14 17:39:23','2016-2-20 14:58:3','proselyte','Astredinova Anfisa Evgenievna'),
('2004-11-27 10:36:55','2007-4-8 21:16:12','Ashland','Negutorova Emilia Olegovna'),
('2005-2-9 15:12:8','2017-7-27 21:17:10','Ozark','Yakimycheva Maria Kuzmevna'),
('2005-4-6 2:1:15','2012-8-4 18:24:23','scholastic','Kazakova Inessa Iraklievna'),
('2002-6-25 3:9:56','2010-10-13 2:22:38','gastronomic','Mozgovoy Marina Semenovna'),
('2003-10-21 9:4:7','2017-8-5 5:59:5','complex','Dultseva Evgenia Rostislavovna'),
('1999-3-9 17:9:34','2008-10-10 19:16:22','ethology','Lyalyushkina Evelina Leonidovna'),
('2000-5-14 20:48:14','2019-8-16 8:59:13','fortin','Galkina Sofya Afanasievna'),
('2005-2-20 19:20:15','2016-3-2 10:10:27','articulatory','Bruchanova Angelina Kazimirovna'),
('2003-10-5 15:16:16','2011-11-8 23:43:40','sideline','Gornostaeva Natalia Igorevna'),
('2000-8-24 17:53:44','2018-12-11 10:25:26','EPA','Yaltseva Zlata Filippovna'),
('2006-11-23 0:27:54','2008-12-29 12:1:4','colon','Stain Renata Nikolaevna'),
('1999-9-19 2:6:42','2007-2-12 16:51:31','Stockton','Dumpling Nona Mikheevna'),
('1999-9-21 11:43:25','2012-8-20 5:42:37','fodder','Yarykina Ulyana Elizarovna'),
('2003-2-6 16:1:16','2011-1-25 16:26:18','wearisome','Golovchenko Liana Mironovna'),
('2000-2-27 21:5:41','2010-2-6 5:2:29','locomotory','Novozhilova Klara Fedorovna'),
('2006-4-11 9:50:53','2010-3-8 1:54:9','max','Saytakhmetova Yunona Nikolaevna'),
('1999-7-27 19:55:29','2007-10-19 13:26:33','yield','Yasaveeva Agnia Zakharovna'),
('1999-10-19 3:22:30','2015-3-8 0:47:31','contraception','Queen Evdokia Semenovna'),
('2001-2-16 4:50:7','2019-11-17 15:37:14','bundle','Sycheva Agnia Yulievna'),
('1999-2-10 11:22:2','2007-7-3 6:1:15','retinal','Berlunova Arina Rostislavovna'),
('2006-12-1 1:40:56','2015-10-12 21:35:24','gum','Erofeeva Regina Mironovna'),
('2005-9-3 7:30:16','2014-3-23 9:24:17','inconspicuous','Yamilova Evgenia Ilarionovna'),
('2002-3-7 16:28:12','2014-11-27 14:35:51','runaway','Yaklashkina Marfa Alekseevna'),
('2003-1-24 0:42:31','2014-11-3 15:18:10','ginmill','Berlunova Maria Pavelovna'),
('2004-7-8 20:59:28','2018-7-5 7:24:43','henchmen','Shatova Lada Georgievna'),
('2006-10-27 7:56:55','2010-12-10 8:19:16','wherever','Sleptsova Aza Pavelovna'),
('2001-10-11 10:12:24','2016-9-14 12:40:25','McKay','Yaseva Eleanor Kuzmevna'),
('2002-8-13 12:11:37','2018-6-4 0:1:28','chain','Kobzeva Margarita Timofeevna'),
('2004-4-15 6:15:59','2013-7-22 6:55:13','cowhide','Yastrebova Tamara Trofimovna'),
('2002-9-27 13:50:4','2013-8-16 12:47:46','verity','Kuznetsova Ksenia Ivanovna'),
('2005-9-20 2:47:9','2009-12-10 22:52:37','lye','Kapralova Agata Rodionovna'),
('2004-2-29 6:12:1','2009-7-22 22:11:10','umpire','Kumoviev Anisya Mironovna'),
('2006-1-14 3:47:39','2014-6-3 1:58:57','airmass','Bolokana Daria Stepanovna'),
('1999-3-4 8:7:31','2016-8-26 15:4:48','slater','Barysheva Valeria Anatolievna'),
('2003-7-14 19:39:36','2009-1-23 6:13:2','thrown','Ryzhanov Arseniy Mechislavovich'),
('2002-2-19 7:14:55','2009-3-2 3:34:41','prosecutor','Zukhin Solomon Vladimirovich'),
('2002-3-20 1:7:7','2019-4-24 2:13:50','sandwich','Gavrilov Rodion Anikitevich'),
('2003-4-14 9:19:2','2016-3-15 4:59:30','rabbi','Bondarev Foka Ilyevich'),
('2001-1-11 4:9:24','2018-12-7 1:0:39','thistle','Panin Gabriel Pakhomovich'),
('2005-9-3 3:18:36','2019-10-21 18:42:0','Winnipesaukee','Bolsunov Dmitry Vyacheslavovich'),
('2002-11-27 6:43:35','2012-11-3 6:17:34','Cornelius','Yafaev Kondrat Andriyanovich'),
('2001-5-9 3:12:41','2016-3-2 13:5:45','cousin','Yezhin Modest Bronislavovich'),
('1999-6-2 19:13:45','2007-3-21 7:25:17','transform','Kirpa Prokhor Sergeevich'),
('2001-2-17 19:6:52','2012-2-5 10:23:22','ethereal','Need Andron Eugenevich'),
('1999-8-5 15:43:5','2015-12-23 12:15:41','acoustic','Mashkov Andron Ippolitovich'),
('2004-7-22 0:43:1','2011-3-4 6:40:9','justify','Shvardygula Veniamin Kapitonovich'),
('2000-2-17 21:5:31','2007-3-15 22:48:37','caloric','Sakharovsky Stanislav Fedotovich'),
('2000-2-5 17:10:25','2008-11-13 12:7:41','dodo','Putintsev Sokrat Ipatievich'),
('1999-4-27 16:46:42','2014-11-4 22:7:21','Tahiti','Polishchuk Yakub Vyacheslavovich'),
('2005-12-9 21:26:51','2014-7-12 0:21:25','motion','Foroponov Adrian Anatolyevich'),
('2003-11-23 21:6:1','2009-10-29 13:9:30','embedding','Sigov Mikhail Andronikovich'),
('2001-1-5 7:9:16','2013-5-6 7:26:55','spiteful','Zoshchenko Grigory Danilevich'),
('2001-5-7 13:49:9','2017-10-8 11:2:13','modulate','Yagunov Oleg Miroslavovich'),
('2001-4-13 3:46:14','2011-3-13 23:11:25','terrier','Venediktov Lavr Cheslavovich'),
('2005-12-24 12:33:24','2007-4-10 13:35:26','protract','Gavrilov Vaclav Feliksovich'),
('2005-10-5 10:15:50','2010-5-26 14:0:14','inhomogeneous','Grachev Gennady Egorovich'),
('2003-1-3 9:18:46','2012-6-8 20:52:1','cubic','Berry Vadim Mikhailovich'),
('1999-8-27 15:5:39','2009-5-6 19:16:39','ester','Krutikov Arthur Andriyanovich'),
('2000-1-3 0:55:54','2007-8-22 6:16:22','egotism','Sabitov Platon Naumovich'),
('2002-11-12 8:55:2','2011-1-13 15:21:39','venereal','Kopylov Evsey Ipatievich'),
('1999-8-15 7:21:43','2019-10-1 16:49:19','firm','Fedorov Elizar Eliseevich'),
('2002-3-17 20:11:30','2017-8-16 12:43:24','kinesic','Cantonists Taras Nikanorovich'),
('2001-3-13 14:18:0','2018-1-8 13:28:42','suture','Yavorsky Vadim Rodionovich'),
('2003-11-6 7:0:58','2014-11-29 14:6:10','gangling','Veselovsky Feofan Ulyanovich'),
('2000-5-12 17:15:46','2015-10-17 14:52:2','agglomerate','Vikashev Vseslav Emilevich'),
('2002-2-1 14:33:46','2010-3-23 0:57:26','MD','Tsyrkunov Dementy Adamovich'),
('2004-6-28 10:10:55','2012-11-2 0:36:7','exalt','Nikadenko Fadey Grigorievich'),
('2004-4-23 19:42:8','2009-6-8 8:17:38','potsherd','Sukhorukov Roman Serafimovich'),
('2003-1-5 16:40:5','2012-4-25 2:51:27','proclaim','Komissarov Ilya Kasyanovich'),
('2000-10-14 8:48:57','2018-1-25 8:42:19','loincloth','Zobov Mikhey Leonidovich'),
('1999-7-12 21:36:4','2019-6-22 23:23:5','ailanthus','Rusakov Methodius Andreevich'),
('2003-3-2 11:10:40','2012-3-14 15:44:36','peacemake','Lavrentiev Bogdan Onisimovich'),
('2002-11-17 18:48:33','2019-12-20 18:0:39','perpendicular','Elmpt Prokhor Filimonovich'),
('2004-12-16 11:7:26','2015-11-26 21:28:0','wattle','Kresanov Arkady Iosifovich'),
('2006-11-4 15:53:11','2011-11-11 5:6:50','GU','Abalyshev Ruben Anikitevich'),
('2001-6-8 19:1:58','2017-12-5 6:4:45','clad','Maltsov Luka Zakharovich'),
('2003-6-25 16:5:1','2009-2-28 8:16:41','Salesian','Shidlovsky Gavrila Ignatievich'),
('2006-6-1 12:44:7','2018-4-13 14:46:45','buteo','Terekhov Mikhey Semenovich'),
('2001-11-8 8:5:10','2019-10-23 7:26:10','philanthrope','Dudakov Mikhey Vladislavovich'),
('2000-2-27 23:0:56','2013-3-25 1:58:52','paramagnet','Yatskovsky Venedikt Zinovievich'),
('2005-8-15 10:9:45','2010-7-27 8:42:26','increasable','Andreichenko Vladilen Martyanovich'),
('2000-2-9 1:58:40','2010-9-22 19:46:33','merge','Kharlamov Valentin Anikitevich'),
('2001-11-27 17:10:59','2013-2-5 2:55:56','onrush','Popov Kirill Tikhonovich'),
('2003-6-2 21:10:34','2007-4-4 11:43:19','registrable','Rogov Irakli Iraklievich');

insert into activities_attendance(attendance_event,attendance_countrie) values
(162,'AZ'),(5,'NF'),(194,'BS'),
(2,'DK'),(164,'CF'),(170,'KG'),
(63,'BJ'),(15,'IS'),(41,'BG'),
(108,'FI'),(214,'MD'),(34,'DO'),
(38,'US'),(18,'PE'),(220,'CX'),
(203,'ZM'),(164,'NG'),(140,'DZ'),
(176,'TT'),(135,'CO'),(213,'LR'),
(223,'CX'),(195,'VE'),(106,'AQ'),
(245,'MM'),(24,'LY'),(130,'AN'),
(91,'MH'),(181,'MT'),(42,'NA'),
(77,'AZ'),(200,'GU'),(206,'BH'),
(132,'JP'),(228,'TF'),(20,'PT'),
(192,'MM'),(244,'SV'),(235,'MG'),
(185,'GE'),(103,'TM'),(242,'JM'),
(151,'BY'),(141,'EC'),(163,'AQ'),
(31,'BS'),(7,'NP'),(218,'BV'),
(108,'HM'),(212,'BG'),(68,'ET'),
(201,'NO'),(123,'RE'),(211,'SG'),
(168,'TR'),(72,'UM'),(135,'GI'),
(205,'GD'),(191,'LC'),(99,'AM'),
(91,'VA'),(179,'VN'),(186,'IT'),
(76,'HM'),(66,'EH'),(54,'VU'),
(155,'PA'),(188,'AW'),(131,'NA'),
(116,'SA'),(235,'TM'),(140,'KM'),
(69,'ER'),(245,'LB'),(48,'SJ'),
(156,'QA'),(11,'LS'),(229,'CY'),
(228,'AT'),(141,'LU'),(26,'ZA'),
(32,'MM'),(24,'HK'),(30,'SJ'),
(51,'PT'),(10,'KG'),(61,'CV'),
(122,'KE'),(222,'MH'),(1,'SB'),
(248,'JM'),(51,'KH'),(34,'SC'),
(144,'MP'),(96,'LT'),(68,'ES'),
(94,'TV'),(2,'KR'),(239,'DO'),
(61,'PG'),(131,'UZ'),(68,'ZW'),
(166,'GT'),(194,'UZ'),(182,'LT'),
(184,'RE'),(240,'AS'),(185,'AL'),
(138,'TZ'),(49,'ES'),(179,'HM'),
(162,'WS'),(139,'LR'),(3,'ST'),
(226,'BY'),(33,'SB'),(34,'NG'),
(7,'YE'),(139,'GW'),(234,'WF'),
(186,'GQ'),(97,'SH'),(61,'RO'),
(203,'UA'),(78,'DE'),(178,'SL'),
(180,'LT'),(91,'BS'),(204,'DZ'),
(106,'NI'),(22,'EH'),(247,'SC'),
(89,'BE'),(123,'NO'),(49,'LU'),
(91,'RW'),(174,'SK'),(202,'TO'),
(144,'ML'),(79,'PM'),(210,'MT'),
(220,'TM'),(55,'VN'),(189,'LR'),
(139,'VI'),(131,'WS'),(190,'AN'),
(240,'CG'),(224,'GQ'),(134,'LY'),
(97,'AR'),(35,'GI'),(205,'IR'),
(10,'SI'),(125,'HU'),(143,'SJ'),
(228,'NA'),(166,'YT'),(180,'TN'),
(75,'FI'),(166,'PW'),(192,'CZ'),
(185,'LC'),(212,'VU'),(226,'RU'),
(129,'MT'),(107,'MA'),(220,'NA'),
(26,'GE'),(188,'BB'),(158,'CC'),
(236,'MG'),(230,'EC'),(49,'OM'),
(129,'MG'),(24,'IE'),(82,'SA'),
(202,'BB'),(69,'EC'),(222,'SN'),
(230,'CH'),(36,'NL'),(246,'LK'),
(231,'DM'),(15,'CY'),(78,'PY'),
(139,'CN'),(210,'GA'),(31,'JP'),
(22,'UM'),(132,'EG'),(132,'EE'),
(94,'AN'),(115,'UY'),(44,'QA'),
(227,'GE'),(234,'JO'),(88,'BW'),
(124,'AO'),(74,'PH'),(207,'MT'),
(196,'TR'),(237,'VA'),(205,'JM'),
(241,'SK'),(164,'IO'),(152,'TV'),
(205,'IN'),(219,'YE'),(88,'BJ'),
(58,'LT'),(101,'JM'),(177,'LI'),
(223,'CZ'),(241,'SC'),(91,'HR'),
(220,'TH'),(48,'BY'),(198,'MH'),
(43,'SL'),(107,'GR'),(150,'AE'),
(164,'CL'),(84,'DZ'),(229,'HM'),
(186,'TT'),(16,'GL'),(233,'SM'),
(217,'PF'),(134,'UG'),(226,'ER'),
(225,'GU'),(79,'BG'),(82,'CA'),
(5,'GT'),(141,'AW'),(191,'VN'),
(44,'MU'),(237,'PG'),(125,'AO'),
(240,'IS'),(127,'AD'),(124,'TZ'),
(49,'IN'),(217,'IQ'),(28,'KI'),
(88,'LC'),(68,'JP'),(87,'SB'),
(9,'WS'),(107,'SE'),(5,'MZ'),
(241,'EC'),(134,'FM'),(159,'DJ'),
(112,'RE'),(177,'UM'),(117,'SG'),
(58,'US'),(121,'IE'),(242,'AZ'),
(121,'KE'),(30,'UM'),(166,'HU'),
(108,'JP'),(177,'NU'),(150,'CG'),
(147,'GS'),(110,'CD'),(151,'RW'),
(196,'SY'),(223,'SM'),(242,'VG'),
(91,'RU'),(170,'CD'),(233,'AE'),
(103,'IO'),(205,'MH'),(24,'SJ'),
(6,'BF'),(55,'NZ'),(54,'TN'),
(61,'BO'),(139,'CI'),(20,'AO'),
(237,'KR'),(238,'KI'),(125,'KR'),
(14,'BJ'),(13,'SZ'),(216,'NG'),
(188,'NP'),(233,'KH'),(78,'MH'),
(11,'CZ'),(17,'GD'),(126,'AF'),
(55,'GP'),(159,'HM'),(43,'MZ'),
(53,'ZA'),(156,'KH'),(229,'NU'),
(175,'FM'),(97,'QA'),(104,'PE'),
(84,'BE'),(187,'BD'),(249,'TC'),
(239,'EG'),(230,'KM'),(39,'ML'),
(52,'SL'),(101,'AI'),(42,'SK'),
(166,'WS'),(242,'UG'),(216,'ES'),
(52,'AF'),(34,'RO'),(3,'EH'),
(107,'FM'),(167,'QA'),(47,'GL'),
(173,'SG'),(216,'JP'),(196,'BI'),
(148,'CU'),(231,'PT'),(137,'BB'),
(142,'GE'),(140,'BF'),(37,'LT'),
(164,'KE'),(163,'SH'),(58,'BZ'),
(176,'NF'),(65,'NZ'),(32,'TW'),
(57,'PN'),(249,'TW'),(23,'NR'),
(217,'SG'),(123,'VA'),(167,'GE'),
(184,'LT'),(129,'JM'),(102,'GI'),
(160,'YE'),(206,'BZ'),(138,'BY'),
(48,'PK'),(192,'SA'),(27,'GH'),
(229,'LY'),(90,'MD'),(213,'RE'),
(191,'CC'),(77,'TZ'),(149,'SG'),
(172,'PR'),(91,'TJ'),(199,'TC'),
(153,'MD'),(8,'AM'),(24,'TT'),
(245,'TK'),(195,'SI'),(99,'CM'),
(170,'FR'),(179,'LA'),(152,'GB'),
(131,'IE'),(91,'BS'),(68,'IQ'),
(8,'KG'),(198,'AU'),(208,'VA'),
(234,'GE'),(194,'KW'),(96,'TD'),
(21,'RU'),(117,'KY'),(65,'NL'),
(40,'HU'),(56,'LU'),(143,'SR'),
(102,'EG'),(229,'EE'),(145,'FM'),
(134,'MR'),(6,'AM'),(35,'NF'),
(46,'RW'),(73,'MU'),(44,'ES'),
(84,'IS'),(101,'UZ'),(107,'IR'),
(154,'GY'),(159,'FI'),(81,'UZ'),
(20,'TC'),(138,'GM'),(196,'PE'),
(117,'GB'),(2,'TZ'),(76,'JP'),
(73,'KZ'),(127,'SK'),(99,'IR'),
(18,'BJ'),(82,'MS'),(181,'BH'),
(61,'GW'),(13,'CU'),(90,'MQ'),
(27,'CK'),(203,'BF'),(227,'BY'),
(241,'AO'),(219,'CG'),(37,'BO'),
(232,'LY'),(204,'SL'),(86,'KM'),
(133,'YT'),(214,'SY'),(40,'CI'),
(182,'IS'),(145,'BB'),(186,'KR'),
(81,'MK'),(27,'LS'),(153,'KH'),
(141,'GP'),(124,'CL'),(174,'UZ'),
(77,'LS'),(49,'NZ'),(73,'LU'),
(248,'SR'),(140,'PT'),(243,'CA'),
(206,'TO'),(213,'HU'),(69,'ET'),
(148,'ZA'),(132,'HU'),(35,'KY'),
(59,'BI'),(180,'IN'),(164,'SO'),
(224,'AS'),(191,'PT'),(107,'MG'),
(41,'YT'),(184,'IE'),(216,'GH'),
(67,'JP'),(181,'ML'),(90,'NF'),
(108,'TJ'),(35,'RE'),(51,'GP'),
(48,'BB'),(233,'QA'),(153,'MO'),
(151,'EG'),(170,'AR'),(129,'BS'),
(68,'NF'),(51,'TN'),(161,'BZ'),
(73,'GM'),(69,'MT'),(206,'CN'),
(147,'FM'),(116,'MN'),(197,'PM'),
(76,'VI'),(118,'AI'),(47,'NR'),
(237,'PG'),(146,'PG'),(129,'MY'),
(189,'TV'),(239,'ZW'),(14,'DZ'),
(247,'TD'),(165,'BJ'),(158,'SB'),
(1,'SL'),(39,'PS'),(201,'HT'),
(6,'RW'),(122,'MV'),(62,'TO'),
(117,'PH'),(71,'BW'),(62,'SD'),
(180,'HU'),(92,'ER'),(196,'ES'),
(1,'JM'),(140,'ZM'),(33,'HK'),
(41,'AN'),(113,'MR'),(144,'VE'),
(91,'GD'),(13,'TK'),(148,'SK'),
(202,'GQ'),(19,'MX'),(177,'YE'),
(48,'WS'),(44,'MP'),(153,'IN'),
(21,'KP'),(118,'EH'),(164,'VU'),
(195,'CZ'),(78,'CV'),(186,'MZ'),
(35,'CR'),(138,'SL'),(121,'GN'),
(37,'MC'),(238,'WS'),(124,'LA'),
(39,'SY'),(176,'CL'),(58,'GR'),
(82,'AS'),(59,'GN'),(226,'CZ'),
(46,'RE'),(204,'MC'),(102,'AW'),
(209,'HN'),(178,'MQ'),(209,'SZ'),
(25,'AG'),(46,'CU'),(119,'WS'),
(246,'CH'),(172,'SJ'),(162,'MV'),
(129,'VI'),(49,'HK'),(248,'SH'),
(207,'BY'),(244,'MK'),(32,'KP'),
(95,'GP'),(187,'PA'),(28,'SV'),
(222,'BA'),(188,'PM'),(115,'GE'),
(58,'MU'),(198,'SY'),(27,'GH'),
(133,'CD'),(58,'SR'),(224,'WS'),
(196,'IO'),(113,'PG'),(87,'LI'),
(160,'NG'),(120,'HT'),(160,'GH'),
(147,'PR'),(203,'MG'),(46,'PE'),
(62,'NI'),(116,'GP'),(161,'SN'),
(110,'SN'),(91,'ER'),(144,'SN'),
(77,'KG'),(199,'GR'),(161,'SH'),
(210,'CI'),(125,'IE'),(137,'TM'),
(105,'WF'),(19,'TV'),(37,'DE'),
(189,'JP'),(148,'TD'),(214,'MW'),
(180,'PT'),(170,'MX'),(3,'MO'),
(188,'TW'),(74,'AS'),(100,'YT'),
(154,'AI'),(52,'BT'),(64,'YE'),
(85,'TN'),(166,'BF'),(83,'GL'),
(232,'GY'),(129,'VC'),(52,'MR'),
(101,'CX'),(145,'GE'),(191,'MY'),
(64,'SV'),(192,'CA'),(248,'AS'),
(10,'NE'),(248,'GH'),(109,'LK'),
(243,'MH'),(233,'KE'),(109,'MP'),
(32,'CO'),(247,'TT'),(85,'TF'),
(9,'ET'),(19,'CL'),(155,'IN'),
(178,'MZ'),(129,'FM'),(114,'TR'),
(190,'IT'),(167,'ML'),(170,'BR'),
(105,'CC'),(249,'AI'),(104,'BT'),
(142,'BE'),(26,'CR'),(100,'TF'),
(106,'CZ'),(226,'AN'),(235,'PR'),
(195,'TR'),(131,'RW'),(57,'ES'),
(106,'GY'),(24,'CX'),(128,'AN'),
(235,'VG'),(18,'MT'),(87,'EH'),
(92,'BV'),(67,'GE'),(154,'MM'),
(198,'EE'),(197,'CZ'),(77,'IN'),
(243,'CF'),(230,'VI'),(214,'TR'),
(178,'PS'),(236,'LU'),(95,'PN'),
(178,'VU'),(85,'MH'),(138,'TJ'),
(118,'NZ'),(60,'MQ'),(64,'NI'),
(129,'LT'),(150,'NZ'),(74,'SE'),
(241,'QA'),(7,'LC'),(227,'GB'),
(186,'DZ'),(136,'PT'),(100,'PE'),
(173,'TK'),(231,'MK'),(116,'FJ'),
(214,'IS'),(115,'SG'),(234,'NC'),
(89,'GH'),(58,'CO'),(98,'CH'),
(198,'BM'),(2,'SD'),(119,'ZM'),
(173,'QA'),(202,'QA'),(195,'PR'),
(174,'VG'),(221,'AE'),(209,'CC'),
(144,'MD'),(195,'UA'),(139,'VE'),
(110,'CV'),(219,'PH'),(224,'EC'),
(195,'AI'),(54,'MN'),(50,'AO'),
(184,'DO'),(145,'CX'),(51,'IN'),
(86,'VI'),(180,'YT'),(150,'VE'),
(123,'LR'),(249,'HU'),(202,'GQ'),
(134,'NI'),(115,'BM'),(124,'YE'),
(64,'KP'),(141,'GU'),(108,'LU'),
(232,'NI'),(109,'NZ'),(156,'AN'),
(189,'CX'),(63,'KE'),(27,'GD'),
(18,'SA'),(211,'GN'),(89,'ZW'),
(183,'SG'),(90,'ET'),(33,'GQ'),
(46,'TM'),(62,'NP'),(112,'LA'),
(209,'MY'),(132,'SH'),(182,'GU'),
(234,'JP'),(26,'HU'),(11,'DZ'),
(47,'MQ'),(29,'FJ'),(168,'BG'),
(73,'CV'),(17,'DJ'),(154,'BM'),
(64,'MO'),(161,'MT'),(142,'TD'),
(54,'MQ'),(161,'CL'),(194,'NL'),
(78,'DE'),(245,'BR'),(83,'IO'),
(4,'KM'),(241,'MQ'),(189,'EC'),
(211,'PY'),(137,'TT'),(112,'TK'),
(29,'BG'),(76,'MZ'),(187,'GB'),
(101,'BR'),(131,'ZW'),(71,'GT'),
(58,'UM'),(81,'CO'),(17,'FI'),
(54,'SK'),(139,'KR'),(88,'SM'),
(198,'VE'),(15,'KY'),(211,'BH'),
(72,'JP'),(40,'GH'),(145,'CL'),
(67,'GM'),(14,'HK'),(93,'MW'),
(198,'MP'),(236,'ES'),(90,'FR'),
(90,'BN'),(51,'SL'),(215,'CV'),
(72,'KN'),(157,'IN'),(74,'UA'),
(230,'AZ'),(114,'GU'),(96,'PA'),
(140,'TR'),(61,'SI'),(39,'BO'),
(7,'TF'),(122,'SD'),(13,'QA'),
(195,'NA'),(65,'DZ'),(131,'KZ'),
(105,'PS'),(161,'MN'),(209,'MO'),
(85,'LY'),(3,'GT'),(179,'MW'),
(197,'LR'),(196,'NR'),(188,'DM'),
(180,'NE'),(92,'LC'),(198,'EE'),
(6,'AQ'),(49,'AZ'),(98,'IL'),
(40,'NG'),(222,'IL'),(230,'ZA'),
(221,'IL'),(16,'GA'),(92,'SI'),
(73,'NA'),(89,'TZ'),(192,'BM'),
(195,'MU'),(153,'IQ'),(166,'DZ'),
(84,'KW'),(205,'SA'),(126,'CI'),
(155,'SY'),(152,'ST'),(220,'PH'),
(133,'NO'),(73,'SE'),(128,'NE'),
(214,'BE'),(81,'CV'),(209,'BA'),
(67,'MY'),(184,'EG'),(52,'VA'),
(175,'TM'),(154,'TD'),(1,'KR'),
(215,'SE'),(53,'AD'),(131,'EH'),
(112,'ID'),(46,'ML'),(136,'RU'),
(7,'GA'),(84,'LY'),(222,'MZ'),
(215,'IR'),(214,'LR'),(56,'RE'),
(127,'HR'),(193,'GF'),(130,'NU'),
(228,'TC'),(202,'MX'),(227,'TW'),
(168,'LI'),(116,'MT'),(29,'MY'),
(36,'LU'),(248,'PE'),(130,'PW'),
(68,'TN'),(73,'ET'),(195,'SV'),
(133,'CO'),(28,'GE'),(47,'PF'),
(232,'LR'),(22,'SK'),(164,'PN'),
(120,'CI'),(106,'PF'),(241,'DZ'),
(38,'EH'),(44,'DO'),(213,'IS'),
(44,'LT'),(245,'MY'),(168,'BE'),
(229,'LB'),(200,'YE'),(58,'LY'),
(136,'KZ'),(207,'BI'),(76,'LV'),
(53,'IT'),(201,'NC'),(102,'GF');

update countries
set x = 300, y = -5
where Name = 'Russian Federation';

update countries
set x = 195, y = -20
where Name = 'Sweden';

update countries
set x = 300, y = 30
where Name = 'Kazakstan';

update countries
set x = 255, y = 54
where Name = 'Armenia';

update countries
set x = -50, y = 40
where Name = 'United States';

update countries
set x = -50, y = -5
where Name = 'Canada';

update countries
set x = 230, y = 30
where Name = 'Ukraine';

update countries
set x = 210, y = 54
where Name = 'Slovakia';

update countries
set x = 166, y = 13
where Name = 'United Kingdom';

update countries
set x = 195, y = 54
where Name = 'Italy';

update countries
set x = 190, y = 27
where Name = 'Germany';

update countries
set x = 185, y = 40
where Name = 'Belgium';

update countries
set x = 183, y = 27
where Name = 'Netherlands';

update countries
set x = 177, y = 35
where Name = 'France';

update countries
set x = 448, y = 70
where Name = 'Japan';

update countries
set x = 420, y = 130
where Name = 'Taiwan';

set global log_bin_trust_function_creators = 1;

# Функция, возвращающая самую мощную электростанцию в мире, которая функционирует на сегодняшний день
drop function if exists most_powerful_power_plant;
DELIMITER //
create function most_powerful_power_plant()
returns varchar(80)
begin
	declare most_powerful varchar(80);
    
	select power_plants_name into most_powerful
    from nuclear_power_plants where 
	(select max(power_plants_capacity) 
    from nuclear_power_plants) = power_plants_capacity
	and power_plants_status_id = 3;
    
	return most_powerful;
end//
DELIMITER ;

# Функция, возвращающая самое популярное вооружение, используемое странами во всём мире
drop function if exists most_popular_weapon;
DELIMITER //
create function most_popular_weapon()
returns varchar(80)
begin
	declare i int;
	declare weapon varchar(80);
    declare maximum int default 0;
    declare current_value int default 0;
    select count(*) into i from weapons_types;
    
    while i>0 do
		select count(*) into current_value from weaponry_of_countries
		where weaponry_of_countries_ref_weapons_types = i;
        
        if maximum < current_value then
			set maximum = current_value;
		end if;
        
		set i = i - 1;
	end while;
    
    select weapons_types_name into weapon from weapons_types
    where weapons_types_id = maximum;
    
	return weapon;
end//
DELIMITER ;

# Функция, возвращающая крупнейший по производству промышленный центр
drop function if exists largest_industrial_center;
DELIMITER //
create function largest_industrial_center()
returns varchar(80)
begin
	declare i int;
	declare center varchar(80);
    declare center_id int;
    declare maximum int default 0;
    declare current_value int default 0;
    select count(*) into i from largest_production_centers;
    
    while i>0 do
		select sum(weapons_warehouse_quantity) into current_value from weapons_warehouse
		where weapons_warehouse_ref_production_centers = i;
        
        if maximum < current_value then
			set maximum = current_value;
            set center_id = i;
		end if;
        
		set i = i - 1;
	end while;
    
    select production_centers_name into center from largest_production_centers
    where production_centers_id = center_id;
    
	return center;
end//
DELIMITER ;

# Функция, возвращающая самую конфликтную страну
drop function if exists most_conflicting_country;
DELIMITER //
create function most_conflicting_country()
returns varchar(80)
begin
	declare country varchar(80);
	declare part_1 varchar(80);
	declare part_2 varchar(80);
    declare counter_1 int;
    declare counter_2 int;
    
    select military_conflicts_conflicting_party_1 into part_1
	from military_conflicts
	group by military_conflicts_conflicting_party_1
	order by count(*) desc
	limit 1;
    
	select military_conflicts_conflicting_party_2 into part_2
	from military_conflicts
	group by military_conflicts_conflicting_party_2
	order by count(*) desc
	limit 1;
    
	select count(*) into counter_1
	from military_conflicts
	group by military_conflicts_conflicting_party_1
	order by count(*) desc
	limit 1;
    
	select count(*) into counter_2
	from military_conflicts
	group by military_conflicts_conflicting_party_2
	order by count(*) desc
	limit 1;
    
    if counter_1 >= counter_2 then
		select Name into country from countries
        where Code = part_1;
	else
		select Name into country from countries
        where Code = part_2;
	end if;
    
	return country;
end//
DELIMITER ;

# Функция, возвращающая предпреятие-лидер в незаконном обогащении ядерного топлива
drop function if exists enrichment_leader;
DELIMITER //
create function enrichment_leader()
returns varchar(80)
begin
	declare leader varchar(80);
	
    select production_centers_name into leader from largest_production_centers
	where production_centers_id = (select fuel_enrichment_enterprise from fuel_enrichment 
	where fuel_enrichment_fuel_amount = (select max(fuel_enrichment_fuel_amount) from fuel_enrichment));
    
	return leader;
end//
DELIMITER ;

# Функция, возвращающая страну с наибольшим объёмом ядерных отходов
drop function if exists most_waste;
DELIMITER //
create function most_waste()
returns varchar(80)
begin
	declare country_waste_leader varchar(80);
	
    select name into country_waste_leader from countries
	where code = (select nuclear_waste_country from nuclear_waste
	where nuclear_waste_volume = (select max(nuclear_waste_volume) from nuclear_waste)
	limit 1);
    
	return country_waste_leader;
end//
DELIMITER ;

# Процедура для изменения типов состояния реакторов
drop procedure if exists change_reactor_status;
DELIMITER //
create procedure change_reactor_status(reactor_name varchar(80), reactor_status varchar(80))
begin
	declare reactor_status_id int;
    declare reactor_id int;
	select plant_status_id from nuclear_plant_status 
    where plant_status_type = reactor_status
    into reactor_status_id;
    select power_plants_id from nuclear_power_plants 
    where power_plants_name = reactor_name
    into reactor_id;
    
    update nuclear_power_plants
    set power_plants_status_id = reactor_status_id
    where power_plants_id = reactor_id;
end//
DELIMITER ;

# Процедура для осуществления проверок на предприятиях
# Предприятие считается небезопасным, если оно производит вооружение массового уничтожения,
# основанное на биологически небезопасном сырье, или если его бюджет меньше затрат на содержание/утилизацию
# радиоактивных веществ
drop procedure if exists audit_the_enterprise;
DELIMITER //
create procedure audit_the_enterprise()
begin
	declare i int;
    declare malfunctions int;
    declare waste float;
    declare budget float;
    declare weapon_type varchar(80);
    select count(*) into i from largest_production_centers;
    
    while i>0 do
		select fuel_enrichment_fuel_amount into waste from fuel_enrichment
        where fuel_enrichment_enterprise = i
		group by fuel_enrichment_enterprise;
        
        select count(*) into malfunctions from fuel_enrichment
		where fuel_enrichment_enterprise = i;
        
        select production_centers_budget into budget from largest_production_centers
		where production_centers_id = i;
        
        select weapons_types_type into weapon_type from weapons_warehouse
		inner join largest_production_centers on 
		production_centers_id = weapons_warehouse_ref_production_centers
		inner join weapons_types on weapons_types_id = weapons_warehouse_ref_weapons_types
		where production_centers_id = i
		group by production_centers_id;
        
        if waste*100 > budget or weapon_type in ('nuclear weapon','gas weapon','rocket weapon') then
			insert into enterprise_audit_results
            (audit_results_enterprise,audit_results_audit_date,audit_results_malfunctions_number,audit_results_conclusion) 
            values 
            (i,now(),malfunctions,'unsafe');
		else
			insert into enterprise_audit_results
            (audit_results_enterprise,audit_results_audit_date,audit_results_malfunctions_number,audit_results_conclusion) 
            values 
            (i,now(),malfunctions,'safe');
        end if;
    
        set i = i - 1;
	end while;

end//
DELIMITER ;

call audit_the_enterprise();

# Процедура для вычисления радиоактивных отходов электростанций стран,
# по объемам реакторов, статусу и мощности электростанций
drop procedure if exists radioactive_waste;
DELIMITER //
create procedure radioactive_waste()
begin
	insert into nuclear_waste(nuclear_waste_country,nuclear_waste_volume)
	select power_plants_country_code,abs(power_plants_latitude*power_plants_longitude*power_plants_capacity) 
	from nuclear_power_plants
	where power_plants_status_id = 3
	group by power_plants_country_code;
end//
DELIMITER ;

call radioactive_waste();

# Процедура для вычисления потенциально опасных мест планеты по необходимым критериям:
# 1) наличие неисправного реактора на ядерной электростанции
# 2) наличие небезопасной дочерней структуры, вычисленной в таблице enterprise_audit_results
# 3) наличие потенциально опасного вооружения в стране
# 4) количество вооружённых конфликтов с использованием вооружений массового уничтожения
# 5) количество средств на утилизацию ядерных отходов превышает бюджет страны
drop procedure if exists dangerous_places;
DELIMITER //
create procedure dangerous_places(in output_limit int)
begin
	# №1
	(select name as country,x,y from countries
	inner join nuclear_power_plants on power_plants_country_code = code
	where power_plants_status_id = 5
	group by power_plants_id)
	union
    # №2
	(select name as country,x,y from countries
	inner join largest_production_centers on production_centers_country_code = code
	inner join enterprise_audit_results on production_centers_id = audit_results_enterprise
	where audit_results_conclusion = 'unsafe')
	union
    # №3
	(select name as country,x,y from countries
	inner join weaponry_of_countries on weaponry_of_countries_ref_country_code = code
	inner join weapons_types on weapons_types_id = weaponry_of_countries_ref_weapons_types
	where weapons_types_type = 'nuclear weapon' or 
	weapons_types_type = 'gas weapon')
    # №4
	union
	(select name as country,x,y from countries
	inner join military_conflicts on military_conflicts_conflicting_party_1 = code
	inner join weapons_types on weapons_types_id = military_conflicts_used_weapon
	where weapons_types_type = 'nuclear weapon' or 
	weapons_types_type = 'gas weapon')
	union
	(select name as country,x,y from countries
	inner join military_conflicts on military_conflicts_conflicting_party_2 = code
	inner join weapons_types on weapons_types_id = military_conflicts_used_weapon
	where weapons_types_type = 'nuclear weapon' or 
	weapons_types_type = 'gas weapon')
    # №5
	union
	(select name as country,x,y from countries
	inner join nuclear_waste on nuclear_waste_country = code
	where nuclear_waste_volume*100 > budget) limit output_limit;
end//
DELIMITER ;

# Процедура для получение полной информации по заданной стране
drop procedure if exists get_full_country_info;
DELIMITER //
create procedure get_full_country_info(in country_name varchar(80), in swich varchar(80))
begin
	case
		when swich = 'plants_info' then
			select 
			power_plants_name as plant,
			power_plants_latitude as latitude, 
			power_plants_longitude as longitude,
			plant_status_type as status, 
			reactor_type_description as reactor_type, 
			power_plants_reactor_model as reactor_model,
			power_plants_capacity as capacity, 
			power_plants_construction_start_at as construction_start
			from nuclear_power_plants
			inner join countries on code = power_plants_country_code
			inner join nuclear_plant_status on plant_status_id = power_plants_status_id
			inner join nuclear_reactor_type on reactor_type_id = power_plants_reactor_type_id
            where name = country_name
			group by power_plants_name;
		when swich = 'factory_info' then
			select 
			production_centers_name as factory_name,
			audit_results_conclusion as safty_intensifier,
			production_centers_budget as budget,
			fuel_enrichment_fuel_amount as fuel_enrichment_amount,
			fuel_enrichment_fuel_type as fuel_enrichment_type,
			production_centers_establishment_date as establishment_date,
			production_centers_founder as founder
			from largest_production_centers
			inner join countries on code = production_centers_country_code
			inner join fuel_enrichment on fuel_enrichment_enterprise = production_centers_id
			inner join enterprise_audit_results on audit_results_enterprise = production_centers_id
            where name = country_name
			group by production_centers_name;
		when swich = 'country_info' then
			select 
			code as code,
			Continent as continent,
			Region as region,
			SurfaceArea as area,
			Population as population,
			LifeExpectancy as life_expectancy,
			GNP as gnp,
			GovernmentForm as government_form,
			HeadOfState as head_of_state,
			budget as budget,
			weapons_types_name as weapon_name,
			weapons_types_type as weapon_type,
			weapons_types_threat_level as weapon_threat_level,
			nuclear_waste_volume as nuclear_waste_volume
			from countries
			inner join weaponry_of_countries on weaponry_of_countries_ref_country_code = code
			inner join weapons_types on weapons_types_id = weaponry_of_countries_ref_weapons_types
			inner join nuclear_waste on nuclear_waste_country = code
            where name = country_name
			group by name;
		when swich = 'activities_info' then
			select 
			Continent as continent,
			activities_subjects as subject,
			activities_start_time as start_time,
			activities_end_time as end_time,
			activities_speaker as speaker
			from activities_attendance
			inner join countries on code = attendance_countrie
			inner join activities on activities_id = attendance_event
            where name = country_name
			group by name;
		when swich = 'conflicts_info' then
			(select 
			Continent as continent,
			military_conflicts_start_date as start_date,
			military_conflicts_end_date as end_date,
			weapons_types_type as weapon,
			military_conflicts_conflict_cause as cause
			from military_conflicts
			inner join countries on military_conflicts_conflicting_party_1 = code
			inner join weapons_types on weapons_types_id = military_conflicts_used_weapon
            where name = country_name
			group by military_conflicts_id)
			union
			(select 
			Continent as continent,
			military_conflicts_start_date as start_date,
			military_conflicts_end_date as end_date,
			weapons_types_type as weapon,
			military_conflicts_conflict_cause as cause
			from military_conflicts
			inner join countries on military_conflicts_conflicting_party_2 = code
			inner join weapons_types on weapons_types_id = military_conflicts_used_weapon
            where name = country_name
			group by military_conflicts_id);
		when swich = 'financial_info' then
			select  
			name as customer, 
			production_centers_name as seller,
			weapons_types_name as purchase_name,
			weapons_types_type as purchase_type,
			weapons_types_action_range as action_range,
			history_order_date as order_date
			from financial_countries_history
			inner join countries on history_customer = code
			inner join largest_production_centers on production_centers_id = history_seller
			inner join weapons_types on weapons_types_id = history_purchase
            where name = country_name
			group by history_id;
    end case;
end//
DELIMITER ;

# Транзакция для инвестирования страной предприятия
drop procedure if exists invest;
DELIMITER //
create procedure invest (in country varchar(80), in fact varchar(80), in sum double)
begin
    declare factory int;
    select production_centers_id from largest_production_centers
    where fact = production_centers_name into factory;
    
	start transaction;
	
    update countries
	set budget = budget - sum
	where code = country and budget >= sum;
    
    if row_count()>0 then
		update largest_production_centers
		set production_centers_budget = production_centers_budget + sum
		where production_centers_id = factory;
        
        if row_count()>0 then 
			insert into investments_history
			(investments_value,investments_receiver,investments_sender,investments_date) values
			(sum,factory,country,now());
			commit;
		else rollback;
		end if;
	else rollback;
    end if;
end //
DELIMITER ;

call invest('AD', 'Rationale-124', 120000);

# Транзакция для облогания предприятия страны налогом
drop procedure if exists tax;
DELIMITER //
create procedure tax (in country varchar(80), in fact varchar(80), in sum double)
begin
    declare factory int;
    select production_centers_id from largest_production_centers
    where fact = production_centers_name into factory;
    
	start transaction;
	
    update largest_production_centers
	set production_centers_budget = production_centers_budget - sum
	where production_centers_id = factory and production_centers_budget >= sum;
    
    if row_count()>0 then
		update countries
		set budget = budget + sum
		where code = country;
        
        if row_count()>0 then 
			insert into tax_history
			(tax_value,tax_receiver,tax_sender,tax_date) values
			(sum,country,factory,now());
			commit;
		else rollback;
		end if;
	else rollback;
    end if;
end //
DELIMITER ;

call tax('AD', 'Rationale-124', 120000);

# Транзакция для покупки вооружений для определенной страны со склада определенного предприятия
drop procedure if exists weapons_purchase;
DELIMITER //
create procedure weapons_purchase (in customer varchar(80), in seller varchar(80), in purchase varchar(80))
begin
    declare factory int;
    declare country varchar(80);
    declare weapon int;
    declare sum float;
    select customer into country;
    select production_centers_id from largest_production_centers
    where seller = production_centers_name into factory;
    select weapons_types_id from weapons_types
    where purchase = weapons_types_name into weapon;
    select weapons_types_cost from weapons_types
    where purchase = weapons_types_name into sum;
    
	start transaction;
	
    update countries
	set budget = budget - sum
	where code = country and budget >= sum;
    
    if row_count()>0 then
		update largest_production_centers
		set production_centers_budget = production_centers_budget + sum
		where production_centers_id = factory;
        
        update weapons_warehouse
        set weapons_warehouse_quantity = weapons_warehouse_quantity - 1
        where weapons_warehouse_ref_production_centers = factory and weapons_warehouse_quantity > 0;
        
        if row_count()>0 then 
			insert into financial_countries_history
			(history_purchase,history_customer,history_seller,history_order_date) values
			(weapon,country,factory,now());
            
            insert into weaponry_of_countries
            (weaponry_of_countries_ref_country_code,weaponry_of_countries_ref_weapons_types) values
            (country,weapon);
			commit;
		else rollback;
		end if;
	else rollback;
    end if;
end //
DELIMITER ;

call weapons_purchase('AD', 'Rationale-124', 'Loudspeaking-2414');

# Вывод всей информации об электростанциях в разных странах
create or replace view plants_info
(country,plant,latitude,longitude,status,reactor_type,reactor_model,capacity,construction_start) as
select 
name as country, 
power_plants_name as plant,
power_plants_latitude as latitude, 
power_plants_longitude as longitude,
plant_status_type as status, 
reactor_type_description as reactor_type, 
power_plants_reactor_model as reactor_model,
power_plants_capacity as capacity, 
power_plants_construction_start_at as construction_start
from nuclear_power_plants
inner join countries on code = power_plants_country_code
inner join nuclear_plant_status on plant_status_id = power_plants_status_id
inner join nuclear_reactor_type on reactor_type_id = power_plants_reactor_type_id
group by power_plants_name;

# Вывод всей информации о крупнейших дочерних структурах и предприятиях в разных странах
create or replace view factory_info
(factory_name,country,safty_intensifier,fuel_enrichment_amount,budgetfuel_enrichment_amount,fuel_enrichment_type,establishment_date,founder) as
select 
production_centers_name as factory_name,
name as country,
audit_results_conclusion as safty_intensifier,
production_centers_budget as budget,
fuel_enrichment_fuel_amount as fuel_enrichment_amount,
fuel_enrichment_fuel_type as fuel_enrichment_type,
production_centers_establishment_date as establishment_date,
production_centers_founder as founder
from largest_production_centers
inner join countries on code = production_centers_country_code
inner join fuel_enrichment on fuel_enrichment_enterprise = production_centers_id
inner join enterprise_audit_results on audit_results_enterprise = production_centers_id
group by production_centers_name;

# Вывод всей информации о странах IAEA
create or replace view country_info
(name,code,continent,region,area,population,life_expectancy,gnp,government_form,
head_of_state,budget,weapon_name,weapon_type,weapon_threat_level,nuclear_waste_volume) as 
select 
name as name,
code as code,
Continent as continent,
Region as region,
SurfaceArea as area,
Population as population,
LifeExpectancy as life_expectancy,
GNP as gnp,
GovernmentForm as government_form,
HeadOfState as head_of_state,
budget as budget,
weapons_types_name as weapon_name,
weapons_types_type as weapon_type,
weapons_types_threat_level as weapon_threat_level,
nuclear_waste_volume as nuclear_waste_volume
from countries
inner join weaponry_of_countries on weaponry_of_countries_ref_country_code = code
inner join weapons_types on weapons_types_id = weaponry_of_countries_ref_weapons_types
inner join nuclear_waste on nuclear_waste_country = code
group by name;

# Вывод всей информации об активности стран
create or replace view activities_info
(name,continent,subject,start_time,end_time,speaker) as 
select 
name as name,
Continent as continent,
activities_subjects as subject,
activities_start_time as start_time,
activities_end_time as end_time,
activities_speaker as speaker
from activities_attendance
inner join countries on code = attendance_countrie
inner join activities on activities_id = attendance_event
group by name;

# Вывод информации о вооружённых конфликтах стран
create or replace view conflicts_info
(name,continent,start_date,end_date,weapon,cause) as
(select 
name as name,
Continent as continent,
military_conflicts_start_date as start_date,
military_conflicts_end_date as end_date,
weapons_types_type as weapon,
military_conflicts_conflict_cause as cause
from military_conflicts
inner join countries on military_conflicts_conflicting_party_1 = code
inner join weapons_types on weapons_types_id = military_conflicts_used_weapon
group by military_conflicts_id)
union
(select 
name as name,
Continent as continent,
military_conflicts_start_date as start_date,
military_conflicts_end_date as end_date,
weapons_types_type as weapon,
military_conflicts_conflict_cause as cause
from military_conflicts
inner join countries on military_conflicts_conflicting_party_2 = code
inner join weapons_types on weapons_types_id = military_conflicts_used_weapon
group by military_conflicts_id);

# Вывод финансовых историй стран членов IAEA
create or replace view financial_info
(customer,seller,purchase_name,purchase_type,action_range,order_date) as
select  
name as customer, 
production_centers_name as seller,
weapons_types_name as purchase_name,
weapons_types_type as purchase_type,
weapons_types_action_range as action_range,
history_order_date as order_date
from financial_countries_history
inner join countries on history_customer = code
inner join largest_production_centers on production_centers_id = history_seller
inner join weapons_types on weapons_types_id = history_purchase
group by history_id;

# Вывод истории инвестиций дочерних организаций странами членами IAEA
create or replace view investments_info
(investor,recipient,value,date) as 
select 
name as investor,
production_centers_name as recipient,
investments_value as value,
investments_date as date
from investments_history
inner join countries on investments_sender = code
inner join largest_production_centers on production_centers_id = investments_receiver
group by investments_id;

# Вывод налоговой истории дочерних организаций
create or replace view tax_info
(taxable,recipient,value,date) as 
select 
production_centers_name as taxable,
name as recipient,
tax_value as value,
tax_date as date
from tax_history
inner join countries on tax_receiver = code
inner join largest_production_centers on production_centers_id = tax_sender
group by tax_id;

drop trigger if exists del_nuclear_waste;
DELIMITER //
create trigger del_nuclear_waste before update on nuclear_waste for each row
begin
	if new.nuclear_waste_volume <= 0 then
		delete from nuclear_waste where new.nuclear_waste_id = nuclear_waste_id;
	end if;
end //
DELIMITER ;

drop trigger if exists del_fuel_enrichment;
DELIMITER //
create trigger del_fuel_enrichment before update on fuel_enrichment for each row
begin
	if new.fuel_enrichment_fuel_amount <= 0 then
		delete from fuel_enrichment where new.fuel_enrichment_id = fuel_enrichment_id;
	end if;
end //
DELIMITER ;

drop trigger if exists del_weapons_warehouse;
DELIMITER //
create trigger del_weapons_warehouse before update on weapons_warehouse for each row
begin
	if new.weapons_warehouse_quantity <= 0 then
		delete from weapons_warehouse where new.weapons_warehouse_id = weapons_warehouse_id;
	end if;
end //
DELIMITER ;

drop trigger if exists del_nuclear_waste;
DELIMITER //
create trigger del_nuclear_waste before update on nuclear_waste for each row
begin
	if new.nuclear_waste_volume <= 0 then
		delete from nuclear_waste where new.nuclear_waste_id = nuclear_waste_id;
	end if;
end //
DELIMITER ;

drop trigger if exists not_negative_country;
DELIMITER //
create trigger not_negative_country before update on countries for each row
begin
	if new.budget < 0 or new.SurfaceArea < 0 or new.Population < 0 or new.GNP < 0 then
		signal sqlstate '45000' set message_text = 'The value cannot be negative!';
	end if;
end //
DELIMITER ;

drop trigger if exists not_negative_plants;
DELIMITER //
create trigger not_negative_plants before update on nuclear_power_plants for each row
begin
	if new.power_plants_capacity < 0 then
		signal sqlstate '45000' set message_text = 'The value cannot be negative!';
	end if;
end //
DELIMITER ;

drop trigger if exists not_negative_production_centers;
DELIMITER //
create trigger not_negative_production_centers before update on largest_production_centers for each row
begin
	if new.production_centers_budget < 0 then
		signal sqlstate '45000' set message_text = 'The value cannot be negative!';
	end if;
end //
DELIMITER ;

drop trigger if exists not_negative_weapons_types;
DELIMITER //
create trigger not_negative_weapons_types before update on weapons_types for each row
begin
	if new.weapons_types_cost < 0 then
		signal sqlstate '45000' set message_text = 'The value cannot be negative!';
	end if;
end //
DELIMITER ;

drop trigger if exists not_negative_weapons_warehouse;
DELIMITER //
create trigger not_negative_weapons_warehouse before update on weapons_warehouse for each row
begin
	if new.weapons_warehouse_quantity < 0 then
		signal sqlstate '45000' set message_text = 'The value cannot be negative!';
	end if;
end //
DELIMITER ;

drop trigger if exists not_negative_fuel_enrichment;
DELIMITER //
create trigger not_negative_fuel_enrichment before update on fuel_enrichment for each row
begin
	if new.fuel_enrichment_fuel_amount < 0 then
		signal sqlstate '45000' set message_text = 'The value cannot be negative!';
	end if;
end //
DELIMITER ;

drop trigger if exists not_negative_nuclear_waste;
DELIMITER //
create trigger not_negative_nuclear_waste before update on nuclear_waste for each row
begin
	if new.nuclear_waste_volume < 0 then
		update nuclear_waste
		set nuclear_waste_volume = 0
		where new.nuclear_waste_id = nuclear_waste_id;
	end if;
end //
DELIMITER ;

create fulltext index ind_country_name on countries(name);
create fulltext index ind_power_plants_name on nuclear_power_plants(power_plants_name);
create fulltext index ind_production_centers on largest_production_centers(production_centers_name);
create fulltext index ind_weapons_types on weapons_types(weapons_types_name);