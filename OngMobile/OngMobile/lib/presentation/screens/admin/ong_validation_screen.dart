import 'package:flutter/material.dart';
import '../../../data/models/pending_ong_model.dart';
import '../../../data/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class OngValidationScreen extends StatefulWidget {
  final PendingOngModel ong;

  const OngValidationScreen({super.key, required this.ong});

  @override
  State<OngValidationScreen> createState() => _OngValidationScreenState();
}

class _OngValidationScreenState extends State<OngValidationScreen> {
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
      final success = await _apiService.approveOng(widget.ong.id);
      if (mounted) {
        setState(() => _isProcessing = false);
        if (success) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(loc.approveSuccess)));
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(loc.operationFailed)));
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
      final success = await _apiService.rejectOng(widget.ong.id);
      if (mounted) {
        setState(() => _isProcessing = false);
        if (success) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(loc.rejectSuccess)));
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(loc.operationFailed)));
        }
      }
    }
  }

  Future<void> _openDocument() async {
    if (widget.ong.verificationDocUrl != null) {
      final url =
          '${ApiConstants.rootUrl}/static/${widget.ong.verificationDocUrl}';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(loc.validationDetails)),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  if (widget.ong.logoUrl != null)
                    Center(
                      child: Image.network(
                        '${ApiConstants.rootUrl}/static/${widget.ong.logoUrl}',
                        height: 150,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image, size: 150),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // ONG Name
                  _buildInfoRow(loc.ongName, widget.ong.name),
                  const Divider(),

                  // Email
                  _buildInfoRow(loc.email, widget.ong.email),
                  const Divider(),

                  // Phone
                  _buildInfoRow(loc.phone, widget.ong.phone),
                  const Divider(),

                  // Address
                  _buildInfoRow(loc.specificAddress, widget.ong.address),
                  const Divider(),

                  // Domains
                  _buildInfoRow(loc.domains, widget.ong.domains),
                  const Divider(),

                  // Verification Document
                  if (widget.ong.verificationDocUrl != null) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _openDocument,
                      icon: const Icon(Icons.file_present),
                      label: Text(loc.verificationDocument),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],

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
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
