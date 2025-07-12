import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ride_insights.dart';
import '../providers/ride_provider.dart';

class RideInsightsScreen extends StatelessWidget {
  final String rideId;

  const RideInsightsScreen({
    super.key,
    required this.rideId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ride Analysis',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFE0E0E0),
          ),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFE0E0E0)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: const Color(0xFF0A0A0A),
      body: Consumer<RideProvider>(
        builder: (context, rideProvider, child) {
          final insights = rideProvider.getInsightsForRide(rideId);
          
          if (insights == null) {
            return _buildLoadingOrEmpty(context, rideProvider);
          }
          
          return _buildInsightsContent(context, insights);
        },
      ),
    );
  }

  Widget _buildLoadingOrEmpty(BuildContext context, RideProvider rideProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1A1A), Color(0xFF2A2A2A)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.analytics,
                  size: 64,
                  color: Color(0xFF00D4FF),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Analysis Available',
                  style: TextStyle(
                    color: Color(0xFFE0E0E0),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap below to analyze this ride',
                  style: TextStyle(
                    color: Color(0xFFB0B0B0),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    await rideProvider.analyzeRide(rideId);
                  },
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Analyze Ride'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D4FF),
                    foregroundColor: const Color(0xFF0A0A0A),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsContent(BuildContext context, RideInsights insights) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Overall Score Card
          _buildScoreCard(insights),
          
          const SizedBox(height: 16),
          
          // Metrics Cards
          _buildMetricsGrid(insights),
          
          const SizedBox(height: 16),
          
          // Insights Section
          _buildInsightsSection(insights),
          
          const SizedBox(height: 16),
          
          // Suggestions Section
          _buildSuggestionsSection(insights),
          
          const SizedBox(height: 16),
          
          // AI-specific sections
          if (insights.isAIAnalysis) ...[
            _buildAISpecificSections(insights),
            const SizedBox(height: 16),
          ],
          
          // Analysis Info
          _buildAnalysisInfo(insights),
        ],
      ),
    );
  }

  Widget _buildScoreCard(RideInsights insights) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(insights.scoreColor).withOpacity(0.2),
            const Color(0xFF1A1A1A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(insights.scoreColor).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                insights.rideStyleEmoji,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),
              Text(
                insights.rideStyle,
                style: const TextStyle(
                  color: Color(0xFFE0E0E0),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${insights.overallScore.toStringAsFixed(0)}/100',
            style: TextStyle(
              color: Color(insights.scoreColor),
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Overall Performance',
            style: const TextStyle(
              color: Color(0xFFB0B0B0),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            insights.summary,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFE0E0E0),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(RideInsights insights) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Speed Efficiency',
            '${insights.speedEfficiency.toStringAsFixed(0)}%',
            Icons.speed,
            const Color(0xFF00D4FF),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            'Energy Efficiency',
            '${insights.energyEfficiency.toStringAsFixed(0)}%',
            Icons.battery_charging_full,
            const Color(0xFF00FF88),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            'Route Quality',
            '${insights.routeQuality.toStringAsFixed(0)}%',
            Icons.route,
            const Color(0xFF7C4DFF),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFB0B0B0),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsSection(RideInsights insights) {
    if (insights.insights.isEmpty) return const SizedBox();
    
    return _buildSection(
      'Key Insights',
      Icons.lightbulb,
      const Color(0xFFFFB74D),
      insights.insights.map((insight) => _buildInsightItem(insight, Icons.insights)).toList(),
    );
  }

  Widget _buildSuggestionsSection(RideInsights insights) {
    if (insights.suggestions.isEmpty) return const SizedBox();
    
    return _buildSection(
      'Suggestions',
      Icons.tips_and_updates,
      const Color(0xFF00FF88),
      insights.suggestions.map((suggestion) => _buildInsightItem(suggestion, Icons.arrow_forward)).toList(),
    );
  }

  Widget _buildAISpecificSections(RideInsights insights) {
    return Column(
      children: [
        if (insights.moodAnalysis != null)
          _buildSection(
            'Mood Analysis',
            Icons.sentiment_satisfied,
            const Color(0xFF00D4FF),
            [_buildInsightItem(insights.moodAnalysis!, Icons.psychology)],
          ),
        
        if (insights.safetyTips?.isNotEmpty == true) ...[
          const SizedBox(height: 16),
          _buildSection(
            'Safety Tips',
            Icons.security,
            const Color(0xFFFF3366),
            insights.safetyTips!.map((tip) => _buildInsightItem(tip, Icons.security)).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSection(String title, IconData icon, Color color, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            const Color(0xFF1A1A1A),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInsightItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: const Color(0xFF00D4FF),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFE0E0E0),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisInfo(RideInsights insights) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF2A2A2A),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                insights.isAIAnalysis ? Icons.auto_awesome : Icons.analytics,
                size: 16,
                color: insights.isAIAnalysis ? const Color(0xFFFFB74D) : const Color(0xFF00D4FF),
              ),
              const SizedBox(width: 8),
              Text(
                insights.isAIAnalysis ? 'AI-Powered Analysis' : 'Local Analysis',
                style: TextStyle(
                  color: insights.isAIAnalysis ? const Color(0xFFFFB74D) : const Color(0xFF00D4FF),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Generated: ${insights.generatedAt.toString().split('.')[0]}',
            style: const TextStyle(
              color: Color(0xFFB0B0B0),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
