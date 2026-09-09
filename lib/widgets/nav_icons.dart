import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Custom bottom-nav icons (Home / Inbox / Profile) — replaces Material
/// icons with the app's own icon set. Each icon's stroke color is swapped
/// between grey (unselected) and purple (selected) via string templating.
///
/// Home and Account come from a wide 74x24 sprite sheet (icon centered
/// around x=36) and need the OverflowBox crop trick. Inbox is a normal
/// standalone 24x24 icon and is rendered directly instead.
class NavIcon extends StatelessWidget {
  final NavIconType type;
  final bool selected;
  final double size;

  const NavIcon({
    super.key,
    required this.type,
    required this.selected,
    this.size = 24,
  });

  static const _selectedColor = '#6C63FF';
  static const _unselectedColor = '#484C52';

  static const Map<NavIconType, String> _sheetSvgs = {
    NavIconType.home: '''
<svg width="74" height="24" viewBox="0 0 74 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M33.92 2.84004L28.53 7.04004C27.63 7.74004 26.9 9.23004 26.9 10.36V17.77C26.9 20.09 28.79 21.99 31.11 21.99H42.69C45.01 21.99 46.9 20.09 46.9 17.78V10.5C46.9 9.29004 46.09 7.74004 45.1 7.05004L38.92 2.72004C37.52 1.74004 35.27 1.79004 33.92 2.84004Z" stroke="COLOR" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M36.9 17.99V14.99" stroke="COLOR" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''',
    NavIconType.account: '''
<svg width="74" height="24" viewBox="0 0 74 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M36.9 12C39.6614 12 41.9 9.76142 41.9 7C41.9 4.23858 39.6614 2 36.9 2C34.1386 2 31.9 4.23858 31.9 7C31.9 9.76142 34.1386 12 36.9 12Z" stroke="COLOR" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M45.49 22C45.49 18.13 41.64 15 36.9 15C32.16 15 28.31 18.13 28.31 22" stroke="COLOR" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''',
  };

  static const String _inboxSvg = '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M12.0053 11H12.0143M8.00977 11H8.01874" stroke="COLOR" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M22 11C22 11.7708 21.9865 12.5232 21.9609 13.2497C21.8772 15.6232 21.8353 16.8099 20.8699 17.7826C19.9046 18.7552 18.6843 18.8074 16.2437 18.9118C15.5098 18.9432 14.7498 18.9667 13.9693 18.9815C13.2282 18.9955 12.8576 19.0026 12.532 19.1266C12.2064 19.2506 11.9325 19.4855 11.3845 19.9553L9.20503 21.8242C9.07273 21.9376 8.90419 22 8.72991 22C8.32679 22 8 21.6732 8 21.2701V18.9219C7.91842 18.9186 7.83715 18.9153 7.75619 18.9118C5.31569 18.8074 4.09545 18.7552 3.13007 17.7825C2.16469 16.8099 2.12282 15.6232 2.03909 13.2497C2.01346 12.5232 2 11.7708 2 11C2 10.2292 2.01346 9.47679 2.03909 8.7503C2.12282 6.37683 2.16469 5.19009 3.13007 4.21745C4.09545 3.24481 5.3157 3.1926 7.7562 3.08819C9.09517 3.0309 10.5209 3 12 3C12.3362 3 12.6697 3.0016 13 3.00474" stroke="COLOR" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M22 6.00002C22 6.00002 19.7905 8.99999 19 9C18.2094 9.00001 16 6 16 6M19 8.5V2" stroke="COLOR" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    final color = selected ? _selectedColor : _unselectedColor;

    if (type == NavIconType.inbox) {
      final svg = _inboxSvg.replaceAll('COLOR', color);
      return SizedBox(
        width: size,
        height: size,
        child: SvgPicture.string(svg, fit: BoxFit.contain),
      );
    }

    final svg = _sheetSvgs[type]!.replaceAll('COLOR', color);

    // The source SVGs are 74x24 with the icon centered around x=36-37,
    // so we clip a square window around that center instead of squashing
    // the whole wide canvas into a square (which would distort the icon).
    return SizedBox(
      width: size,
      height: size,
      child: ClipRect(
        child: Align(
          alignment: Alignment.center,
          widthFactor: size / 24,
          child: OverflowBox(
            maxWidth: 74 * (size / 24),
            maxHeight: 24 * (size / 24),
            child: SvgPicture.string(
              svg,
              width: 74 * (size / 24),
              height: 24 * (size / 24),
            ),
          ),
        ),
      ),
    );
  }
}

enum NavIconType { home, inbox, account }