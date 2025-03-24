-- Sandardized Date Format

ALTER TABLE PortfolioProjectCT..NashvilleHousing
ADD SaleDateConverted date

Update PortfolioProjectCT..NashvilleHousing
SET SaleDateConverted = SaleDate


-- Populate property address data

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.propertyaddress,b.PropertyAddress)
FROM PortfolioProjectCT..NashvilleHousing AS a
INNER JOIN PortfolioProjectCT..NashvilleHousing AS b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

UPDATE a
SET PropertyAddress = ISNULL(a.propertyaddress,b.PropertyAddress)
FROM PortfolioProjectCT..NashvilleHousing AS a
INNER JOIN PortfolioProjectCT..NashvilleHousing AS b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL


-- Break out property addresses into individual columns (Address and City)

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1),
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))
FROM PortfolioProjectCT..NashvilleHousing

ALTER TABLE PortfolioProjectCT..NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255)

ALTER TABLE PortfolioProjectCT..NashvilleHousing
ADD PropertySplitCity NVARCHAR(255)

UPDATE PortfolioProjectCT..NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

UPDATE PortfolioProjectCT..NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))


-- Break out owner addresses into individual columns (Address and City)

SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM PortfolioProjectCT..NashvilleHousing

ALTER TABLE PortfolioProjectCT..NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255)

ALTER TABLE PortfolioProjectCT..NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255)

ALTER TABLE PortfolioProjectCT..NashvilleHousing
ADD OwnerSplitState NVARCHAR(255)

UPDATE PortfolioProjectCT..NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

UPDATE PortfolioProjectCT..NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

UPDATE PortfolioProjectCT..NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)


-- Change Y AND N to YES and NO in "Sold as Vacant" field

SELECT Distinct(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProjectCT..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant,
CASE
	WHEN SoldAsVacant = 'Y' THEN 'YES'
	WHEN SoldAsVacant = 'N' THEN 'NO'
	ELSE SoldAsVacant
END
FROM PortfolioProjectCT..NashvilleHousing

UPDATE PortfolioProjectCT..NashvilleHousing
SET SoldAsVacant = 
CASE
	WHEN SoldAsVacant = 'Y' THEN 'YES'
	WHEN SoldAsVacant = 'N' THEN 'NO'
	ELSE SoldAsVacant
END


-- Remove Duplicates

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
	             PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) AS row_num
FROM PortfolioProjectCT..NashvilleHousing
)

DELETE
FROM RowNumCTE
WHERE row_num > 1


-- Delete Unused Columns

ALTER TABLE PortfolioProjectCT..NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate