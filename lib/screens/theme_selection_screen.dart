import 'package:flutter/material.dart';
import '../models/app_theme_preset.dart';
import '../services/theme_service.dart';
import 'dashboard_screen.dart';

/// Exibida logo após o cadastro. Apresenta os 4 temas pré-customizados
/// (Criança, Adolescente, Adulto, Idoso), cada um com preview real de
/// cor e fonte, para o usuário escolher a interface mais confortável.
class ThemeSelectionScreen extends StatefulWidget {
  const ThemeSelectionScreen({super.key});

  @override
  State<ThemeSelectionScreen> createState() => _ThemeSelectionScreenState();
}

class _ThemeSelectionScreenState extends State<ThemeSelectionScreen> {
  AppThemePreset _selected = AppThemePreset.adulto;
  bool _isSaving = false;

  Future<void> _confirmSelection() async {
    setState(() => _isSaving = true);
    await ThemeService.instance.setPreset(_selected);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                'Escolha o seu estilo',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Você pode mudar isso depois, quando quiser.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: ListView.separated(
                  itemCount: AppThemePreset.values.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final preset = AppThemePreset.values[index];
                    return _ThemePresetCard(
                      preset: preset,
                      isSelected: preset == _selected,
                      onTap: () => setState(() => _selected = preset),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),
              FilledButton(
                onPressed: _isSaving ? null : _confirmSelection,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Continuar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card de preview de um tema: renderiza usando as cores e a fonte
/// reais daquele preset, para o usuário ver exatamente como vai ficar.
class _ThemePresetCard extends StatelessWidget {
  final AppThemePreset preset;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemePresetCard({
    required this.preset,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final previewTheme = preset.buildThemeData();
    final borderColor = isSelected
        ? previewTheme.colorScheme.primary
        : Colors.grey.shade300;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: previewTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: previewTheme.colorScheme.primaryContainer,
              child: Icon(
                preset.icon,
                color: previewTheme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preset.label,
                    style: previewTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: previewTheme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    preset.description,
                    style: previewTheme.textTheme.bodySmall?.copyWith(
                      color: previewTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: previewTheme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}
