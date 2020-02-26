use IAEA;

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
select * from countries;
select * from largest_production_centers;
select * from investments_history;

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

select * from countries;
select * from largest_production_centers;
select * from tax_history;

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
select * from weapons_types;
select * from weapons_warehouse;
select * from countries;
select * from largest_production_centers;
select * from financial_countries_history;
select * from weaponry_of_countries;