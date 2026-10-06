import 'package:flutter/material.dart';
import '../models/currency.dart';
import 'utils/currency_utils.dart';

class CurrencySelectorPage extends StatefulWidget {
  final String selectedCurrency;
  final Currency currencyData;

  const CurrencySelectorPage({
    super.key,
    required this.selectedCurrency,
    required this.currencyData,
  });

  @override
  State<CurrencySelectorPage> createState() => _CurrencySelectorPageState();
}

class _CurrencySelectorPageState extends State<CurrencySelectorPage> {
  late List<String> allCurrencies;
  late List<String> filteredCurrencies;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    allCurrencies = widget.currencyData.rates.keys.toList()..sort();
    filteredCurrencies = List.from(allCurrencies);
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredCurrencies = allCurrencies.where((currency) {
        final countryName = currencyCodeToCountryName(currency).toLowerCase();
        return currency.toLowerCase().contains(query) ||
            countryName.contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: const Color(0xFF121217),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121217),
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFBEE7FF)),
        centerTitle: true,
        toolbarHeight: isLandscape ? 60 : 100,
        title: const Text(
          'Select Currency',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(
              height: isLandscape ? 40 : 60,
              child: TextField(
                controller: _searchController,
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
          Expanded(
            child: ListView.builder(
              itemCount: filteredCurrencies.length,
              itemBuilder: (context, index) {
                final currency = filteredCurrencies[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context, currency);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 12,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151515),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$currency (${currencyCodeToCountryName(currency)})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
