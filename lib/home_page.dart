import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'currency_selector_page.dart';
import 'rates_page.dart';
import '../services/api_service.dart';
import '../models/currency.dart';
import '../services/location_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Currency? currencyData;
  String? fromCurrency;
  String? toCurrency = 'USD';
  double amount = 0.0;
  double convertedAmount = 0.0;
  bool autoCurrencyEnabled = true;

  final TextEditingController _controller = TextEditingController(text: "0.00");
  final FocusNode _amountFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initApp();

    _amountFocusNode.addListener(() {
      if (_amountFocusNode.hasFocus) {
        if (_controller.text == "0.00") _controller.clear();
      } else {
        if (_controller.text.isEmpty) {
          _controller.text = "0.00";
          amount = 0.0;
          _updateConversion();
        } else {
          _finalizeAmount();
        }
      }
      setState(() {});
    });
  }

  void _finalizeAmount() {
    double val = double.tryParse(_controller.text) ?? 0.0;
    _controller.text = val.toStringAsFixed(2);
    amount = val;
    _updateConversion();
  }

  Future<void> _initApp() async {
    try {
      try {
        currencyData = await ApiService.fetchCurrency().timeout(
          const Duration(seconds: 6),
        );
      } catch (_) {
        currencyData = Currency(
          success: true,
          base: "EUR",
          rates: {
            "EUR": 1.0,
            "USD": 1.1,
            "GBP": 0.85,
            "JPY": 160.0,
            "SEK": 11.0,
            "RON": 4.95,
          },
        );
      }

      fromCurrency = await LocationService.getCurrencyFromLocation(
        currencyData!,
      ).timeout(const Duration(seconds: 4), onTimeout: () => "EUR");

      if (!currencyData!.rates.containsKey(fromCurrency)) fromCurrency = "EUR";
      if (!currencyData!.rates.containsKey(toCurrency)) toCurrency = "USD";

      LocationService.startCurrencyListener(
        currencyData: currencyData!,
        onCurrencyChanged: (currency) {
          if (!autoCurrencyEnabled || !mounted) return;
          if (currencyData == null || currency == fromCurrency) return;
          setState(() => fromCurrency = currency);
          _updateConversion();
        },
      );
      _updateConversion();
    } catch (_) {
      currencyData = Currency(
        success: true,
        base: "EUR",
        rates: {"EUR": 1.0, "USD": 1.1},
      );
      fromCurrency ??= "EUR";
      toCurrency ??= "USD";
      _updateConversion();
    } finally {
      if (mounted) setState(() {});
    }
  }

  double get unitRate {
    if (currencyData == null || fromCurrency == null || toCurrency == null) {
      return 0.0;
    }
    final rateFrom = currencyData!.rates[fromCurrency] ?? 1.0;
    final rateTo = currencyData!.rates[toCurrency] ?? 1.0;
    if (fromCurrency == toCurrency) return 1.0;
    return (1 / rateFrom) * rateTo;
  }

  void _updateConversion() {
    if (currencyData == null || fromCurrency == null || toCurrency == null) {
      return;
    }
    final rateFrom = currencyData!.rates[fromCurrency] ?? 1.0;
    final rateTo = currencyData!.rates[toCurrency] ?? 1.0;
    setState(() {
      convertedAmount = (fromCurrency == toCurrency)
          ? amount
          : (amount / rateFrom) * rateTo;
    });
  }

  @override
  void dispose() {
    LocationService.stopCurrencyListener();
    _controller.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (currencyData == null || fromCurrency == null) {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xFF121217),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false, // main fix
        backgroundColor: const Color(0xFF121217),
        appBar: AppBar(
          backgroundColor: const Color(0xFF121217),
          elevation: 0,
          centerTitle: true,
          toolbarHeight: isLandscape ? 60 : 120,
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Currency Converter',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: isLandscape ? 20 : 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  shadows: const [
                    Shadow(
                      blurRadius: 12,
                      color: Color(0xAA64B5F6),
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isLandscape ? 4 : 8),
              Text(
                'Student-developed app that instantly converts currencies',
                style: TextStyle(
                  fontSize: isLandscape ? 12 : 14,
                  color: const Color(0xFF9FBEDC),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: isLandscape ? _buildLandscape() : _buildPortrait(),
          ),
        ),
      ),
    );
  }

  Widget _buildPortrait() {
    return Column(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildCurrencyButton(fromCurrency!, true),
                  ),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: _buildAmountField()),
                ],
              ),
              const SizedBox(height: 12),
              _buildSwapButton(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildCurrencyButton(toCurrency!, false),
                  ),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: _buildResultBox()),
                ],
              ),
              const SizedBox(height: 24),
              _buildRatesButton(),
            ],
          ),
        ),
        _buildFooter(),
      ],
    );
  }

  Widget _buildLandscape() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildCurrencyButton(fromCurrency!, true),
                  ),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: _buildAmountField()),
                ],
              ),
              const SizedBox(height: 12),
              _buildSwapButton(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildCurrencyButton(toCurrency!, false),
                  ),
                  const SizedBox(width: 12),
                  Expanded(flex: 2, child: _buildResultBox()),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildRatesButton(),
              const SizedBox(height: 16),
              _buildFooter(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmountField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: _amountFocusNode.hasFocus
            ? [
                BoxShadow(
                  color: const Color(0xFF64B5F6).withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: TextField(
        controller: _controller,
        focusNode: _amountFocusNode,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(color: Colors.white, fontSize: 18),
        inputFormatters: [
          LengthLimitingTextInputFormatter(10),
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
        decoration: InputDecoration(
          labelText: 'Amount',
          labelStyle: const TextStyle(color: Color(0xFF8FCBF9)),
          filled: true,
          fillColor: const Color(0xFF141416),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF2E4A66), width: 2.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF64B5F6), width: 4.0),
          ),
        ),
        onChanged: (val) {
          amount = double.tryParse(val) ?? 0;
          _updateConversion();
        },
      ),
    );
  }

  Widget _buildCurrencyButton(String currency, bool isFrom) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E4A66), width: 2.0),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
        ),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, a, b) => CurrencySelectorPage(
                selectedCurrency: currency,
                currencyData: currencyData!,
              ),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );

          if (!mounted) return;
          if (result != null) {
            if (isFrom && result == toCurrency) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("From and To currencies cannot be the same."),
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }
            if (!isFrom && result == fromCurrency) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("From and To currencies cannot be the same."),
                  duration: Duration(seconds: 2),
                ),
              );
              return;
            }
            setState(() {
              if (isFrom) {
                fromCurrency = result;
              } else {
                toCurrency = result;
              }
            });
            _updateConversion();
          }
        },
        child: Row(
          children: [
            const Icon(Icons.monetization_on, color: Colors.blueGrey, size: 26),
            const SizedBox(width: 10),
            Text(
              currency,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.blueAccent,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwapButton() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1D3B57),
        borderRadius: BorderRadius.circular(100),
      ),
      child: IconButton(
        icon: const Icon(Icons.swap_vert, size: 34, color: Colors.white),
        onPressed: () {
          setState(() {
            final temp = fromCurrency;
            fromCurrency = toCurrency;
            toCurrency = temp;
          });
          _updateConversion();
        },
      ),
    );
  }

  Widget _buildResultBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 21),
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E4A66), width: 2.0),
      ),
      child: Text(
        convertedAmount.toStringAsFixed(2),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRatesButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, anim, anim2) => RatesPage(
                currencyData: currencyData!,
                fromCurrency: fromCurrency!,
              ),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E5A86),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
        child: const Text(
          'View Exchange Rates',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141416),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E4A66), width: 2.0),
      ),
      child: Text(
        '1 $fromCurrency = ${unitRate.toStringAsFixed(2)} $toCurrency',
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }
}
