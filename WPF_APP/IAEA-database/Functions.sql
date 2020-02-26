use IAEA;

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

select most_powerful_power_plant();

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

select most_popular_weapon();

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

select largest_industrial_center();

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

select most_conflicting_country();

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

select enrichment_leader();

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

select most_waste();