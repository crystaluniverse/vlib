# Currency Module

A comprehensive currency handling module for V that supports both fiat and cryptocurrency operations, currency conversion, and amount parsing.

## Features

- Parse currency amounts from human-readable strings
- Support for fiat and cryptocurrencies
- Currency conversion and exchange rates
- USD value calculations
- Support for common currency symbols (€, $, £)
- Multiplier notation support (K for thousands, M for millions)

## Basic Usage

### Working with Amounts

```v
import freeflowuniverse.crystallib.data.currency

// Parse amount from string
mut amount := currency.amount_get('20 USD')!
mut amount2 := currency.amount_get('1.5k EUR')!  // k for thousands
mut amount3 := currency.amount_get('2M TFT')!    // M for millions

// Using currency symbols
mut amount4 := currency.amount_get('€100')!      // Euro
mut amount5 := currency.amount_get('$50')!       // USD
mut amount6 := currency.amount_get('£75')!       // GBP

// Get USD value
usd_value := amount.usd()  // converts to USD based on currency's USD value
```

### Currency Operations

```v
// Get a currency
mut usd := currency.get('USD')!
mut eur := currency.get('EUR')!
mut tft := currency.get('TFT')!

// Create an amount with specific currency
mut amount := Amount{
    currency: usd
    val: 100.0
}

// Exchange to different currency
mut eur_amount := amount.exchange(eur)!
```

## Amount String Format

The `amount_get` function supports various string formats:

```v
// All these formats are valid
amount_get('10.3 USD')    // Space separated
amount_get('10.3USD')     // No space
amount_get('10.3 usd')    // Case insensitive
amount_get('$10.3')       // Currency symbol
amount_get('10.3')        // Defaults to USD if no currency specified
amount_get('5k USD')      // k multiplier for thousands
amount_get('1M EUR')      // M multiplier for millions
```

### Multiplier Support

- `K` or `k`: Multiplies the amount by 1,000
- `M` or `m`: Multiplies the amount by 1,000,000

Examples:
```v
amount_get('5k USD')!     // 5,000 USD
amount_get('2.5K EUR')!   // 2,500 EUR
amount_get('1M TFT')!     // 1,000,000 TFT
```

## Currency Exchange

The module supports currency exchange operations based on USD values:

```v
// Create amounts in different currencies
mut usd_amount := currency.amount_get('100 USD')!
mut eur_amount := currency.amount_get('100 EUR')!

// Exchange USD to EUR
mut in_eur := usd_amount.exchange(eur_amount.currency)!

// Exchange EUR to USD
mut back_to_usd := eur_amount.exchange(usd_amount.currency)!
```

## USD Value Calculations

Every currency has a USD value that's used for conversions:

```v
mut amount := currency.amount_get('100 EUR')!

// Get USD equivalent
usd_value := amount.usd()

// The calculation is: amount.val * amount.currency.usdval
// For example, if EUR.usdval is 1.1:
// 100 EUR = 100 * 1.1 = 110 USD
```

## Error Handling

The module includes robust error handling:

```v
// Handle parsing errors
amount := currency.amount_get('invalid') or {
    println('Failed to parse amount: ${err}')
    return
}

// Handle exchange errors
converted := amount.exchange(target_currency) or {
    println('Failed to exchange currency: ${err}')
    return
}
```

## Currency Codes

- Standard 3-letter currency codes are used (USD, EUR, GBP, etc.)
- Special handling for cryptocurrency codes (TFT, BTC, etc.)
- Currency symbols (€, $, £) are automatically converted to their respective codes

## Notes

- All decimal values use US notation (dot as decimal separator)
- Commas in numbers are ignored (both "1,000" and "1000" are valid)
- Whitespace is flexible ("100USD" and "100 USD" are both valid)
- Case insensitive ("USD" and "usd" are equivalent)
