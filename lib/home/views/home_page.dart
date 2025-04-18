import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/auth/auth.dart';
import 'package:my_app/customer/customer.dart';
import 'package:my_app/loaner/loaner.dart';
import 'package:my_app/shop/shop.dart';

class TabScrollManager extends InheritedWidget {
  const TabScrollManager({
    required this.controllers,
    required super.child,
    super.key,
  });

  final List<ScrollController> controllers;

  static TabScrollManager? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TabScrollManager>();
  }

  @override
  bool updateShouldNotify(TabScrollManager oldWidget) {
    return controllers != oldWidget.controllers;
  }

  ScrollController getController(int index) => controllers[index];
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late final List<ScrollController> _scrollControllers;
  int _selectedIndex = 0;
  late final PageController _pageController;

  static const List<Widget> _pages = <Widget>[
    ShopTab(),
    LoanerView(),
  ];

  void _onItemTapped(int index) {
    if (index == _selectedIndex) {
      final controller = _scrollControllers[index];
      if (!controller.hasClients) return;
      controller.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _selectedIndex = index;
    }
  }

  void _onSearchChanged(String? value) {
    switch (_selectedIndex) {
      case 0:
        context.read<ShopBloc>().add(ShopGetItemsEvent(searchQuery: value));
      case 1:
        context.read<LoanerBloc>().add(LoadLoaners(searchQuery: value));
    }
  }

  void _showFilterSheet() {
    switch (_selectedIndex) {
      case 0:
        showModalBottomSheet<void>(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: context.read<CategoryBloc>()),
              BlocProvider.value(value: context.read<ShopBloc>()),
            ],
            child: FilterSheet(
              initialCategoryFilter: context.read<ShopBloc>().state.asLoaded?.categoryFilter,
              onApply: (category) => context.read<ShopBloc>().add(ShopGetItemsEvent(categoryFilter: category)),
            ),
          ),
        );
      case 1:
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: context.read<LoanerBloc>()),
              BlocProvider.value(value: context.read<CustomerBloc>()),
            ],
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: LoanerFilterSheet(
                initialFromDate: context.read<LoanerBloc>().state.asLoaded?.fromDate,
                initialToDate: context.read<LoanerBloc>().state.asLoaded?.toDate,
                initialLoanerFilter: context.read<LoanerBloc>().state.asLoaded?.loanerFilter,
                onApply: (fromDate, toDate, loanerFilter) => context.read<LoanerBloc>().add(
                      LoadLoaners(
                        fromDate: fromDate,
                        toDate: toDate,
                        loanerFilter: loanerFilter,
                      ),
                    ),
              ),
            ),
          ),
        );
    }
  }

  void _showSettingsSheet(VoidCallback onSignout) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<CategoryBloc>()),
          BlocProvider.value(value: context.read<ShopBloc>()),
          BlocProvider.value(value: context.read<CustomerBloc>()),
        ],
        child: SettingsSheet(onSignout: onSignout),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _scrollControllers = [
      ScrollController(),
      ScrollController(),
    ];
    context.read<LoanerBloc>().add(LoadLoaners());
    context.read<ShopBloc>().add(ShopGetItemsEvent());
    context.read<CategoryBloc>().add(CategoryGetEvent());
    context.read<CustomerBloc>().add(LoadCustomers());
  }

  @override
  void dispose() {
    for (final controller in _scrollControllers) {
      controller.dispose();
    }
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final iconList = <IconData>[
      Icons.store_rounded,
      Icons.handshake_rounded,
    ];

    final statusBarHeight = MediaQuery.of(context).viewPadding.top;
    // final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return TabScrollManager(
      controllers: _scrollControllers,
      child: Scaffold(
        extendBody: true,
        body: SafeArea(
          top: false,
          maintainBottomViewPadding: true,
          child: Stack(
            children: [
              Column(
                children: <Widget>[
                  Container(
                    height: statusBarHeight,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.primaryContainer,
                        ],
                      ),
                    ),
                  ),
                  Builder(
                    builder: (context) {
                      Widget buildShopHeader({bool hasFilter = false}) {
                        return ShopHeader(
                          hasFilter: hasFilter,
                          onSettingsPressed: () => _showSettingsSheet(
                            () => context.read<SignoutBloc>().add(const SignoutSubmitted()),
                          ),
                          onSearchChanged: _onSearchChanged,
                          onFilterPressed: _showFilterSheet,
                          searchController: _searchController,
                        );
                      }

                      final blocBuilders = {
                        0: BlocBuilder<ShopBloc, ShopState>(
                          builder: (context, state) {
                            return buildShopHeader(hasFilter: state.asLoaded?.categoryFilter != null);
                          },
                        ),
                        1: BlocBuilder<LoanerBloc, LoanerState>(
                          builder: (context, state) {
                            return buildShopHeader(hasFilter: state.asLoaded?.hasFilter ?? false);
                          },
                        ),
                      };

                      return blocBuilders[_selectedIndex] ?? buildShopHeader();
                    },
                  ),
                ],
              ),
              Container(
                margin: EdgeInsets.only(
                  top: statusBarHeight + 140,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadiusDirectional.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: MultiBlocProvider(
                  providers: [
                    BlocProvider.value(value: context.read<LoanerBloc>()),
                  ],
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: _pages,
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: SizedBox(
          height: 64,
          width: 64,
          child: FloatingActionButton(
            onPressed: () {
              switch (_selectedIndex) {
                case 0:
                  context.pushNamed(
                    AppRoutes.formShop,
                    extra: {
                      'shop': context.read<ShopBloc>(),
                      'category': context.read<CategoryBloc>(),
                      'onAdd': (ShopItemModel item) {},
                    },
                  );
                case 1:
                  context.pushNamed(
                    AppRoutes.formLoaner,
                    extra: {
                      'loanerBloc': context.read<LoanerBloc>(),
                      'customerBloc': context.read<CustomerBloc>(),
                    },
                  );
              }
            },
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimaryContainer,
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.add,
              size: 28,
              color: Colors.white,
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
        bottomNavigationBar: AnimatedBottomNavigationBar.builder(
          height: 72,
          itemCount: iconList.length,
          tabBuilder: (int index, bool isActive) => Icon(
            iconList[index],
            size: 26,
            color: isActive ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: .6),
          ),
          activeIndex: _selectedIndex,
          onTap: (index) {
            _pageController.jumpToPage(index);
            _onItemTapped(index);
            setState(() {});
          },
          gapLocation: GapLocation.end,
          notchSmoothness: NotchSmoothness.defaultEdge,
          notchMargin: 20,
          leftCornerRadius: 16,
          backgroundColor: colorScheme.surface,
          splashColor: colorScheme.primary.withValues(alpha: .3),
          splashRadius: 30,
          shadow: BoxShadow(
            offset: const Offset(0, 1),
            blurRadius: 12,
            spreadRadius: 0.5,
            color: Colors.black.withValues(alpha: .1),
          ),
        ),
      ),
    );
  }
}
