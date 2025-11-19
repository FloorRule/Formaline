import 'package:flutter/material.dart';

class SymbolKeyboard extends StatefulWidget {
  final Function(String) onKeyPressed;

  const SymbolKeyboard({super.key, required this.onKeyPressed});

  @override
  State<SymbolKeyboard> createState() => _SymbolKeyboardState();
}

class _SymbolKeyboardState extends State<SymbolKeyboard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<String> controlKeys = const ['⌫', '↵', ':'];

  // Symbol categories (renamed and reordered)
  final List<String> pageTitles = const [
    'Proof',
    'Set Names',
    'Elements',
    'Logic',
    'Set Theory',
    'Construction',
    'Functions',
  ];

  final List<List<String>> symbolPages = const [
    ['proof: ', ' let ', ' assume ', ' have ', ' show ', ' by ', ' QED '],
    ['A', 'B', 'C', 'D', 'E', 'F'],
    ['x', 'y', 'z', 'a', 'b', 'c'],
    ['∀', '∃', '→', '↔', '¬', '∧', '∨'],
    ['∈', '⊆', '⊂', '∅', '∪', '∩', '\\', '𝒫'],
    ['{', '|', '}', '(', ')', ',', '=', '≠', '×'],
    ['→', 'f', 'f(', ')', 'f⁻¹', "''", 'inj', 'surj', 'bij'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Fixed control keys
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: controlKeys.map((symbol) {
              return ElevatedButton(
                onPressed: () => widget.onKeyPressed(_translateControl(symbol)),
                child: Text(symbol, style: const TextStyle(fontSize: 24)),
              );
            }).toList(),
          ),
        ),

        // Page title
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            pageTitles[_currentPage],
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),

        // Page selector buttons
        SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
            children: List.generate(pageTitles.length, (index) {
            final selected = index == _currentPage;
            return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: OutlinedButton(
                onPressed: () {
                    _pageController.jumpToPage(index);
                    setState(() => _currentPage = index);
                },
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    minimumSize: const Size(0, 32),
                    backgroundColor: selected ? Colors.amber[100] : null,
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                    pageTitles[index],
                    style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    ),
                ),
                ),
            );
            }),
        ),
        ),


        // Swipeable symbol grid
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            itemCount: symbolPages.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, pageIndex) {
              final symbols = symbolPages[pageIndex];
              final isProofPage = pageIndex == 0;

              return GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(8),
                children: symbols.map((symbol) {
                  return ElevatedButton(
                    onPressed: () => widget.onKeyPressed(symbol),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        symbol,
                        style: TextStyle(
                          fontSize: isProofPage ? 14 : 24,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  String _translateControl(String symbol) {
    switch (symbol) {
      case '⌫':
        return 'BACKSPACE';
      case '↵':
        return 'ENTER';
      default:
        return symbol;
    }
  }
}
