use IAEA;

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