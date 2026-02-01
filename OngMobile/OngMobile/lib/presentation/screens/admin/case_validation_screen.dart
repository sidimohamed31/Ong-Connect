import 'package:flutter/material.dart';
import '../../../data/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../l10n/app_localizations.dart';

class CaseValidationScreen extends StatefulWidget {
  final Map<String, dynamic> caseData;

  const CaseValidationScreen({super.key, required this.caseData});

  @override
  State<CaseValidationScreen> createState() => _CaseValidationScreenState();
}

class _CaseValidationScreenState extends State<CaseValidationScreen> {
  final _apiService = ApiService();
  bool _isProcessing = false;

  Future<void> _approve() async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.approve),
        content: Text(loc.confirmApprove),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.approve),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isProcessing = true);
      final success = await _apiService.approveCase(widget.caseData['id']);
      if (mounted) {
        setState(() => _isProcessing = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.approveSuccess)),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.operationFailed)),
          );
        }
      }
    }
  }

  Future<void> _reject() async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.reject),
        content: Text(loc.confirmReject),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(loc.reject),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isProcessing = true);
      final success = await _apiService.rejectCase(widget.caseData['id']);
      if (mounted) {
        setState(() => _isProcessing = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.rejectSuccess)),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.operationFailed)),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.validationDetails),
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  if (widget.caseData['image_url'] != null)
                    Center(
                      child: Image.network(
                        '${ApiConstants.rootUrl}/static/${widget.caseData['image_url']}',
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image, size: 200),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Title
                  _buildInfoRow(loc.title, widget.caseData['title'] ?? ''),
                  const Divider(),

                  // Description
                  _buildInfoRow(
                      loc.description, widget.caseData['description'] ?? ''),
                  const Divider(),

                  // Category
                  _buildInfoRow(loc.category, widget.caseData['category'] ?? ''),
                  const Divider(),

                  // ONG
                  _buildInfoRow(loc.ong, widget.caseData['ong_name'] ?? ''),
                  const Divider(),

                  // Location
                  _buildInfoRow(
                    loc.location,
                    '${widget.caseData['wilaya'] ?? ''}, ${widget.caseData['moughataa'] ?? ''}',
                  ),
                  const Divider(),

                  // Status
                  _buildInfoRow(loc.status, widget.caseData['status'] ?? ''),
                  const Divider(),

                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _approve,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            loc.approve,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _reject,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            loc.reject,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
