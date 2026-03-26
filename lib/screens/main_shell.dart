import 'package:flutter/material.dart';
import 'package:notas_zincao_flutter/screens/nota_register_screen.dart';
import 'package:notas_zincao_flutter/screens/notas_retirada_screen.dart';
import 'package:notas_zincao_flutter/screens/produtos_estoque/produtos_estoque_screen.dart';
import 'package:notas_zincao_flutter/viewmodels/auth_viewmodel.dart';
import 'package:notas_zincao_flutter/widgets/app_header.dart';
import 'package:notas_zincao_flutter/widgets/header/header_nav_tabs.dart';

/// Shell principal da aplicação que gerencia a navegação entre Listagem e Cadastro.
/// Usa o [AppHeader] para controle.
class MainShell extends StatefulWidget {
  final AuthViewModel authViewModel;

  const MainShell({super.key, required this.authViewModel});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final PageController _pageController = PageController();

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        authViewModel: widget.authViewModel,
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        children: [
          NotasRetiradaScreen(authViewModel: widget.authViewModel),
          NotaRegisterScreen(authViewModel: widget.authViewModel),
          ProdutosEstoqueScreen(authViewModel: widget.authViewModel),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: HeaderNavTabs(
          currentIndex: _currentIndex,
          onTabSelected: _onTabSelected,
        ),
      ),
    );
  }
}
