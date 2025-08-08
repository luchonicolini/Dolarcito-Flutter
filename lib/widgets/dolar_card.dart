import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class CustomTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const CustomTabBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  final double iconSize = 22;
  final double circleSize = 50;
  final double tabBarHeight = 70;

  Color _tabColor(int index) {
    switch (index) {
      case 0:
        return CupertinoColors.activeBlue;
      case 1:
        return CupertinoColors.systemGreen;
      default:
        return CupertinoColors.systemGrey;
    }
  }

  String _tabTitle(int index) {
    switch (index) {
      case 0:
        return "Inicio";
      case 1:
        return "Conversión";
      default:
        return "";
    }
  }

  IconData _tabIcon(int index, bool isSelected) {
    switch (index) {
      case 0:
        return isSelected ? CupertinoIcons.house_fill : CupertinoIcons.house;
      case 1:
        return isSelected
            ? CupertinoIcons.arrow_2_squarepath
            : CupertinoIcons.arrow_2_squarepath;
      default:
        return CupertinoIcons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: tabBarHeight,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: CupertinoColors.systemGrey4.withOpacity(0.4),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(2, (index) {
                final isSelected = selectedIndex == index;
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onTabSelected(index);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              width: isSelected ? circleSize : 0,
                              height: isSelected ? circleSize : 0,
                              decoration: BoxDecoration(
                                color: _tabColor(index).withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Icon(
                              _tabIcon(index, isSelected),
                              size: iconSize,
                              color: isSelected
                                  ? _tabColor(index)
                                  : CupertinoColors.inactiveGray,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _tabTitle(index),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? _tabColor(index)
                                : CupertinoColors.inactiveGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
