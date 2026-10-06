import 'package:flutter/material.dart';
import '../models/currency.dart';
import 'utils/currency_utils.dart';

class RatesPage extends StatefulWidget {
  final Currency currencyData;
  final String fromCurrency;

  const RatesPage({
    super.key,
    required this.currencyData,
    required this.fromCurrency,
  });

  @override
  State<RatesPage> createState() => _RatesPageState();
}

class _RatesPageState extends State<RatesPage> {
  late String exchangecurrency;
  late List<String> allCurrencies;
  List<String> filteredCurrencies = [];
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();

    if (widget.currencyData.rates.containsKey(widget.fromCurrency)) {
      exchangecurrency = widget.fromCurrency;
    } else if (widget.currencyData.rates.containsKey(
      widget.currencyData.base,
    )) {
      exchangecurrency = widget.currencyData.base;
    } else {
      exchangecurrency = widget.currencyData.rates.keys.first;
    }

    allCurrencies = widget.currencyData.rates.keys.toList()..sort();
    filteredCurrencies = List.from(allCurrencies);

    searchFocus.addListener(() {
      setState(() {});
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      filteredCurrencies = allCurrencies
          .where((currency) {
            final codeMatch = currency.toLowerCase().contains(
              query.toLowerCase(),
            );
            final countryMatch = currencyCodeToCountryName(
              currency,
            ).toLowerCase().contains(query.toLowerCase());
            return codeMatch || countryMatch;
          })
          .take(4)
          .toList();
    });
  }

  void selectBaseCurrency(String currency) {
    setState(() {
      exchangecurrency = currency;
      searchController.clear();
      searchFocus.unfocus();
      filteredCurrencies = List.from(allCurrencies);
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exchangeRates = widget.currencyData.rates;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: const Color(0xFF121217),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF121217),
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFBEE7FF)),
        centerTitle: true,
        toolbarHeight: isLandscape ? 60 : 100,
        title: const Text(
          'Exchange Rates',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: SizedBox(
                  height: isLandscape ? 40 : 60,
                  child: TextField(
                    controller: searchController,
                    focusNode: searchFocus,
                    onChanged: _onSearchChanged,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Search currency or country",
                      hintStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.blueAccent,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF151515),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.blue.shade800),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF3B6EFF),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                    ),
                  ),
                ),
              ),
              // Main Rates List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: allCurrencies.length,
                  itemBuilder: (context, index) {
                    final currency = allCurrencies[index];
                    final baseRate = exchangeRates[exchangecurrency] ?? 1.0;
                    final targetRate = exchangeRates[currency] ?? 1.0;
                    final converted = baseRate == 0
                        ? 0.0
                        : (targetRate / baseRate);

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF151515),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.shade800.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '1 $exchangecurrency = ${converted.toStringAsFixed(2)} $currency',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // Floating Search
          if (searchController.text.isNotEmpty && filteredCurrencies.isNotEmpty)
            Positioned(
              top: isLandscape ? 52 : 72,
              left: 12,
              right: 12,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A22),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 10,
                    ),
                  ],
                  border: Border.all(color: Colors.blue.shade900),
                ),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredCurrencies.length,
                  itemBuilder: (context, index) {
                    final currency = filteredCurrencies[index];
                    final countryName = currencyCodeToCountryName(currency);

                    return ListTile(
                      title: Text(
                        '$currency ($countryName)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      onTap: () => selectBaseCurrency(currency),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
