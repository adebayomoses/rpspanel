# Convert between units

Converts energy, mass, money-scale and population units used by EIA and
BEA. Electricity is converted to Btu at the thermal equivalent of
3,412.14 Btu per kWh (the convention used in SEDS for electricity
consumption).

## Usage

``` r
convert_units(x, from, to)

convert_units_available()
```

## Arguments

- x:

  Numeric vector.

- from, to:

  Unit names (case-insensitive), for example `"billion Btu"`, `"MMBtu"`,
  `"thousand MWh"`, `"million metric tons"`, `"short ton"`,
  `"million dollars"`. See `convert_units_available()`.

## Value

Numeric vector in the `to` unit.

## Examples

``` r
convert_units(1, "trillion Btu", "billion Btu")
#> [1] 1000
convert_units(1000, "thousand MWh", "TWh")
#> [1] 1
convert_units(1, "million metric tons", "short ton")
#> [1] 1102311
```
