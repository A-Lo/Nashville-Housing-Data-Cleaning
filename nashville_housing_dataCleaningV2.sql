/*
Cleaning Data in SQL Queries using:
 JOINS(LEFT JOIN); CTE; WINDOW FUNCTIONS; UPDATE, ALTER, and DELETE TABLES.
*/

SELECT *
FROM public."Nashville_housing_data";
--WHERE uniqueid = '46919'LIMIT 100;

--Removing unnecessary white-space from the uniqueid-column name:
ALTER TABLE public."Nashville_housing_data"
RENAME COLUMN "uniqueid "  TO  uniqueid;

-----------------------------------------------------------------

-- 1) Standardize Saledate format:

SELECT cast(saledate as date)
FROM public."Nashville_housing_data";

ALTER TABLE public."Nashville_housing_data"
ALTER COLUMN saledate TYPE date;


-----------------------------------------------------------------

-- 2) Populate NULL-value property Address data using UPDATE:
-- If a record has a null-value in 'propertyaddress', we populate that record's
-- address with another record, that has the same 'parcelid', address.

-- Note: If it has the same 'parcelid', or mailing address, the address will be the same.


-- Counts the number of nulls values in property address
SELECT COUNT(parcelid) as count_nulls
FROM public."Nashville_housing_data"
WHERE propertyaddress IS NULL;
-- View the records where 'propertyid' is NULL-value
Select uniqueid, parcelid,propertyaddress, owneraddress, ownername
FROM public."Nashville_housing_data"
WHERE propertyaddress IS NULL;


-- Updating our table to populated NULL-values in the 'propertyaddress' field

---- First, checking if the our desired table LEFT join's properly:
WITH t2 AS (
	SELECT 	DISTINCT parcelid, propertyaddress
	FROM public."Nashville_housing_data"
	WHERE propertyaddress IS NOT NULL
)
SELECT  nash.uniqueid, nash.parcelid, nash.propertyaddress
		,t2.parcelid,t2.propertyaddress,
		COALESCE (nash.propertyaddress, t2.propertyaddress)
FROM public."Nashville_housing_data" nash
LEFT JOIN t2
ON nash.parcelid = t2.parcelid
WHERE nash.propertyaddress IS  NULL
ORDER BY nash.parcelid;

--UPDATE record(s) with null-values from Nashville_house_data table:
WITH t2 AS (
	SELECT 	DISTINCT parcelid, propertyaddress
	FROM public."Nashville_housing_data"
	WHERE propertyaddress IS NOT NULL
)
UPDATE public."Nashville_housing_data" as np
SET propertyaddress = COALESCE(np.propertyaddress, Sub_query.new_prop_address)
FROM
(	SELECT nash.uniqueid, nash.parcelid,
 	nash.propertyaddress
 	,t2.propertyaddress as new_prop_address
	FROM public."Nashville_housing_data" nash
	LEFT JOIN t2
	ON nash.parcelid = t2.parcelid
	WHERE nash.propertyaddress IS NULL
) as Sub_query
WHERE np.uniqueid = Sub_query.uniqueid
;




-----------------------------------------------------------------

--3) Breaking up address into seperate column (Address, City, and State)

-- propertyaddress(Address, City):---------------

-- Query check: Before the changes to actual table
SELECT 	propertyaddress,
		TRIM(SPLIT_PART(propertyaddress, ',',1 )) as property_split_address,
		TRIM(SPLIT_PART(propertyaddress, ',',2 )) as property_city
FROM public."Nashville_housing_data";

--property Address: Creating new column for just the property address in table
ALTER TABLE public."Nashville_housing_data"
ADD property_split_address varchar(255);

UPDATE public."Nashville_housing_data"
SET property_split_address = TRIM(SPLIT_PART(propertyaddress, ',',1 ));

-- property city: Creating new column for just the property city in table
ALTER TABLE public."Nashville_housing_data"
ADD property_city varchar(255);

UPDATE public."Nashville_housing_data"
SET property_city = TRIM(SPLIT_PART(propertyaddress, ',',2));

--Viewing change(s)
SELECT 	propertyaddress, property_split_address,
				property_city
FROM public."Nashville_housing_data";


-- OwnerAddress(Address, City, Stat): ---------------

SELECT 	owneraddress,
		TRIM(SPLIT_PART(owneraddress, ',', 1)) as owner_address,
		TRIM(SPLIT_PART(owneraddress, ',', 2)) as owner_city,
		TRIM(SPLIT_PART(owneraddress,',', 3)) as owner_state
FROM public."Nashville_housing_data" ;

-- Creating the owner_address attribute
ALTER TABLE public."Nashville_housing_data"
ADD owner_address varchar(255);

UPDATE public."Nashville_housing_data"
SET owner_address = TRIM(SPLIT_PART(owneraddress, ',', 1));

-- Creating the owner_city column:
ALTER TABLE public."Nashville_housing_data"
ADD owner_city varchar(255);

UPDATE public."Nashville_housing_data"
SET owner_city = TRIM(SPLIT_PART(owneraddress, ',', 2));

-- Creating owner_state column:
ALTER TABLE public."Nashville_housing_data"
ADD owner_state varchar(255);

UPDATE public."Nashville_housing_data"
SET owner_state = TRIM(SPLIT_PART(owneraddress,',',3));

-----------------------------------------------------------------

-- 4) Changing 'Y' and 'N' values in 'soldasvacant' column to 'Yes' and 'No'

-- COUNT: Distinct values in 'soldasvacant'
SELECT  soldasvacant, COUNT(soldasvacant)
FROM public."Nashville_housing_data"
GROUP BY soldasvacant;


SELECT	soldasvacant,
		CASE
			WHEN soldasvacant = 'Y' THEN 'Yes'
			WHEN soldasvacant = 'N' THEN 'No'
			ELSE soldasvacant
		END update
FROM public."Nashville_housing_data"
--WHERE soldasvacant = 'Y' OR soldasvacant = 'N'
;

-- UPDATE: The soldasvacant values
UPDATE public."Nashville_housing_data" as nash
SET soldasvacant = 	CASE
						WHEN soldasvacant = 'Y' THEN 'Yes'
						WHEN soldasvacant = 'N' THEN 'No'
						ELSE soldasvacant
					END ;

-----------------------------------------------------------------

-- 5) Remove duplicates

--QUERY
WITH Q1 AS(
SELECT 	parcelid, propertyaddress, saledate, saleprice,
		legalreference,
		ROW_NUMBER() OVER (PARTITION BY
							parcelid, propertyaddress, saledate, saleprice,
							legalreference
							ORDER BY parcelid
					   		) row_instance
FROM  public."Nashville_housing_data"
)
SELECT *
FROM Q1
WHERE row_instance > 1;


-- Removal of duplicates
WITH Q1 AS(
SELECT 	parcelid, propertyaddress, saledate, saleprice,
		legalreference,
		ROW_NUMBER() OVER (PARTITION BY
							parcelid, propertyaddress, saledate, saleprice,
							legalreference
							ORDER BY parcelid
					   		) row_instance
FROM  public."Nashville_housing_data"
)
DELETE *
FROM Q1
WHERE row_instance > 1;


-----------------------------------------------------------------

-- 6) 	Getting read of unused columns:
-- 	Removing duplicate columns (propertyaddress, owneraddress) since we have new ones
SELECT * FROM public."Nashville_housing_data" LIMIT 100;


ALTER TABLE public."Nashville_housing_data"
DROP COLUMN proptertyaddress, owneraddress;
