use IAEA;

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

call change_reactor_status('Ågesta','Shutdown');
select * from nuclear_plant_status;
select * from nuclear_power_plants;

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
select * from enterprise_audit_results;

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
select * from nuclear_waste;

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

call dangerous_places(1000);

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

call get_full_country_info('Russian Federation','plants_info');