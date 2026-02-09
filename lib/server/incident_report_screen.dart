import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../auth/user_profile.dart';
import '../theme/avoo_theme.dart';

class IncidentReportScreen extends StatefulWidget {
  const IncidentReportScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<IncidentReportScreen> createState() => _IncidentReportScreenState();
}

class _IncidentReportScreenState extends State<IncidentReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '1');
  final _valueController = TextEditingController();
  final _commentController = TextEditingController();
  String _type = 'breakage';
  bool _submitting = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _valueController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final form = _formKey.currentState;
    if (form != null && !form.validate()) return;

    final quantity = int.tryParse(_quantityController.text.trim()) ?? 0;
    final value = double.tryParse(_valueController.text.trim()) ?? 0;
    if (quantity <= 0) {
      _showSnack('Veuillez saisir une quantité valide.');
      return;
    }
    if (value <= 0) {
      _showSnack('Veuillez saisir une valeur valide.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final incidentsRef = FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.profile.restaurantId)
          .collection('incidents');

      final incidentRef = incidentsRef.doc();

      await incidentRef.set({
        'type': _type,
        'quantity': quantity,
        'value': value,
        'comment': _commentController.text.trim(),
        'status': 'reported',
        'created_at': FieldValue.serverTimestamp(),
        'created_by': widget.profile.uid,
        'created_by_name': widget.profile.name,
      });

      if (!mounted) return;
      Navigator.of(context).pop();
      _showSnack('Incident déclaré.');
    } catch (e) {
      _showSnack("Impossible d'enregistrer l'incident.");
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AvooColors.bone,
      appBar: AppBar(
        title: const Text('Déclarer un incident'),
        backgroundColor: AvooColors.bone,
        foregroundColor: AvooColors.ink,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Type',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: [
                ChoiceChip(
                  label: const Text('Casse'),
                  selected: _type == 'breakage',
                  onSelected: (_) => setState(() => _type = 'breakage'),
                ),
                ChoiceChip(
                  label: const Text('Perte'),
                  selected: _type == 'loss',
                  onSelected: (_) => setState(() => _type = 'loss'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantité',
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                final qty = int.tryParse(value ?? '');
                if (qty == null || qty <= 0) {
                  return 'Quantité invalide';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _valueController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Valeur (€)',
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                final val = double.tryParse(value ?? '');
                if (val == null || val <= 0) {
                  return 'Valeur invalide';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Commentaire',
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Photo (optionnelle)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Stockage photo non activé.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AvooColors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text(_submitting ? 'Enregistrement...' : 'Enregistrer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
