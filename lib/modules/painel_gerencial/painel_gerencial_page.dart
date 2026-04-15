import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PainelGerencialPage extends StatelessWidget {
  const PainelGerencialPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Painel gerencial',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Indicadores gerenciais e acompanhamento de vendas',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 22),

            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: const [
                _KpiCard(
                  titulo: 'Total Hoje',
                  valor: 'R\$ 3.250,00',
                  icone: Icons.attach_money,
                ),
                _KpiCard(
                  titulo: 'Total no Mês',
                  valor: 'R\$ 48.900,00',
                  icone: Icons.bar_chart,
                ),
                _KpiCard(
                  titulo: 'Pedidos',
                  valor: '184',
                  icone: Icons.shopping_bag_outlined,
                ),
                _KpiCard(
                  titulo: 'Ingressos Vendidos',
                  valor: '327',
                  icone: Icons.confirmation_number_outlined,
                ),
              ],
            ),

            const SizedBox(height: 24),

            LayoutBuilder(
              builder: (context, constraints) {
                final mobile = constraints.maxWidth < 900;

                if (mobile) {
                  return Column(
                    children: const [
                      _PainelPizza(),
                      SizedBox(height: 16),
                      _PainelBarras(),
                    ],
                  );
                }

                return const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _PainelPizza()),
                    SizedBox(width: 16),
                    Expanded(child: _PainelBarras()),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            LayoutBuilder(
              builder: (context, constraints) {
                final mobile = constraints.maxWidth < 1100;

                if (mobile) {
                  return Column(
                    children: const [
                      _ListaRanking(
                        titulo: 'Produtos Mais Vendidos',
                        itens: [
                          '1. Heineken Long Neck - 120 un',
                          '2. Combo Whisky - 84 un',
                          '3. Água Mineral - 73 un',
                          '4. Red Bull - 66 un',
                        ],
                      ),
                      SizedBox(height: 16),
                      _ListaRanking(
                        titulo: 'Total de Vendas por Loja',
                        itens: [
                          'Canto da Ema - R\$ 18.500,00',
                          'Bar do Centro - R\$ 12.300,00',
                          'Arena Club - R\$ 9.980,00',
                        ],
                      ),
                      SizedBox(height: 16),
                      _ListaRanking(
                        titulo: 'Vendas de Ingressos',
                        itens: [
                          'Lote Promocional - 142 vendidos',
                          '1º Lote - 98 vendidos',
                          'VIP - 47 vendidos',
                        ],
                      ),
                    ],
                  );
                }

                return const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _ListaRanking(
                        titulo: 'Produtos Mais Vendidos',
                        itens: [
                          '1. Heineken Long Neck - 120 un',
                          '2. Combo Whisky - 84 un',
                          '3. Água Mineral - 73 un',
                          '4. Red Bull - 66 un',
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _ListaRanking(
                        titulo: 'Total de Vendas por Loja',
                        itens: [
                          'Canto da Ema - R\$ 18.500,00',
                          'Bar do Centro - R\$ 12.300,00',
                          'Arena Club - R\$ 9.980,00',
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _ListaRanking(
                        titulo: 'Vendas de Ingressos',
                        itens: [
                          'Lote Promocional - 142 vendidos',
                          '1º Lote - 98 vendidos',
                          'VIP - 47 vendidos',
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icone;

  const _KpiCard({
    required this.titulo,
    required this.valor,
    required this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icone, color: Colors.amber.shade800),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PainelPizza extends StatelessWidget {
  const _PainelPizza();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Participação por Loja',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 42,
                sections: [
                  PieChartSectionData(value: 40, title: '40%'),
                  PieChartSectionData(value: 30, title: '30%'),
                  PieChartSectionData(value: 20, title: '20%'),
                  PieChartSectionData(value: 10, title: '10%'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PainelBarras extends StatelessWidget {
  const _PainelBarras();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Produtos Mais Vendidos',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: BarChart(
              BarChartData(
                titlesData: FlTitlesData(show: true),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: true),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 120)]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 84)]),
                  BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 73)]),
                  BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 66)]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListaRanking extends StatelessWidget {
  final String titulo;
  final List<String> itens;

  const _ListaRanking({
    required this.titulo,
    required this.itens,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          ...itens.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                item,
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}