use IAEA;

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

select * from plants_info;
select * from factory_info;
select * from country_info;
select * from activities_info;
select * from conflicts_info;
select * from financial_info;
select * from investments_info;
select * from tax_info;