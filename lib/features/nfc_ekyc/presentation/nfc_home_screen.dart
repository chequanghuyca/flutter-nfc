import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/nfc_document_reader.dart';
import '../domain/document_access_data.dart';
import '../domain/document_profile.dart';
import '../domain/document_read_result.dart';
import '../domain/identity_capture_result.dart';
import '../domain/vietnamese_cccd_profile.dart';
import 'identity_capture_screen.dart';
import 'nfc_read_controller.dart';

class NfcHomeScreen extends StatefulWidget {
  const NfcHomeScreen({
    super.key,
    this.reader,
    this.profile = const VietnameseCccdProfile(),
  });

  final NfcDocumentReader? reader;
  final DocumentProfile profile;

  @override
  State<NfcHomeScreen> createState() => _NfcHomeScreenState();
}

class _NfcHomeScreenState extends State<NfcHomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _documentNumberController = TextEditingController();
  late final NfcReadController _controller;
  DateTime? _dateOfBirth;
  DateTime? _dateOfExpiry;
  String? _dateError;
  IdentityCaptureResult? _captureResult;

  @override
  void initState() {
    super.initState();
    _controller = NfcReadController(
      reader: widget.reader ?? MrtdNfcDocumentReader(),
      profile: widget.profile,
    );
    _controller.refreshAvailability();
  }

  @override
  void dispose() {
    _controller.dispose();
    _documentNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: now,
      initialDate: _dateOfBirth ?? DateTime(now.year - 25),
      helpText: 'Chọn ngày sinh trên MRZ',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _dateOfBirth = picked;
      _dateError = null;
    });
  }

  Future<void> _pickDateOfExpiry() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 50, 12, 31),
      initialDate: _dateOfExpiry ?? DateTime(now.year + 5),
      helpText: 'Chọn ngày hết hạn trên MRZ',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _dateOfExpiry = picked;
      _dateError = null;
    });
  }

  Future<void> _startReading() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final datesAreValid = _dateOfBirth != null && _dateOfExpiry != null;
    setState(() {
      _dateError = datesAreValid ? null : 'Chọn đủ ngày sinh và ngày hết hạn.';
    });

    if (!(_formKey.currentState?.validate() ?? false) || !datesAreValid) {
      return;
    }

    await _controller.start(
      DocumentAccessData(
        documentNumber: _documentNumberController.text.trim(),
        dateOfBirth: _dateOfBirth!,
        dateOfExpiry: _dateOfExpiry!,
      ),
    );
  }

  Future<void> _captureIdentityDocument() async {
    if (_controller.state.isReading) return;
    final result = await Navigator.of(context).push<IdentityCaptureResult>(
      MaterialPageRoute(builder: (_) => const IdentityCaptureScreen()),
    );
    if (result == null || !mounted) return;

    _controller.reset();
    setState(() {
      _captureResult = result;
      _documentNumberController.text = result.accessData.documentNumber;
      _dateOfBirth = result.accessData.dateOfBirth;
      _dateOfExpiry = result.accessData.dateOfExpiry;
      _dateError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NFC eKYC Demo')),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final state = _controller.state;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                _Header(profile: widget.profile),
                const SizedBox(height: 20),
                _CaptureCard(
                  result: _captureResult,
                  enabled: !state.isReading,
                  onCapture: _captureIdentityDocument,
                ),
                const SizedBox(height: 20),
                _AvailabilityCard(
                  availability: state.availability,
                  onRefresh: state.isReading
                      ? null
                      : _controller.refreshAvailability,
                ),
                const SizedBox(height: 20),
                _buildInputForm(state),
                const SizedBox(height: 20),
                _ReadStatusCard(
                  state: state,
                  onCancel: _controller.cancel,
                  onReset: _controller.reset,
                ),
                if (state.result case final result?) ...[
                  const SizedBox(height: 20),
                  _ResultCard(result: result),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildInputForm(NfcReadState state) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '2. Kiểm tra dữ liệu MRZ',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                _captureResult == null
                    ? 'Hãy chụp CCCD để tự nhận diện. Bạn vẫn có thể nhập tay để kiểm thử.'
                    : 'OCR đã điền dữ liệu mở chip. Kiểm tra lại trước khi đọc NFC.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('document-number-field'),
                controller: _documentNumberController,
                enabled: !state.isReading,
                keyboardType: TextInputType.number,
                autofillHints: const [],
                maxLength: 9,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: widget.profile.documentNumberLabel,
                  helperText: widget.profile.documentNumberHint,
                  counterText: '',
                ),
                validator: (value) {
                  if (!RegExp(r'^\d{9}$').hasMatch(value?.trim() ?? '')) {
                    return 'Nhập đúng 9 chữ số.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _DateField(
                key: const Key('date-of-birth-field'),
                label: 'Ngày sinh',
                value: _dateOfBirth,
                enabled: !state.isReading,
                onTap: _pickDateOfBirth,
              ),
              const SizedBox(height: 12),
              _DateField(
                key: const Key('date-of-expiry-field'),
                label: 'Ngày hết hạn',
                value: _dateOfExpiry,
                enabled: !state.isReading,
                onTap: _pickDateOfExpiry,
              ),
              if (_dateError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _dateError!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const Key('start-reading-button'),
                onPressed: state.isReading ? null : _startReading,
                icon: const Icon(Icons.nfc_rounded),
                label: const Text('3. Bắt đầu đọc NFC'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.profile});

  final DocumentProfile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          profile.displayName,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        const Text(
          'Chụp hai mặt CCCD, đọc MRZ bằng OCR rồi mở chip theo chuẩn ICAO 9303. Toàn bộ xử lý ở trên thiết bị, không backend.',
        ),
      ],
    );
  }
}

class _CaptureCard extends StatelessWidget {
  const _CaptureCard({
    required this.result,
    required this.enabled,
    required this.onCapture,
  });

  final IdentityCaptureResult? result;
  final bool enabled;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '1. Chụp CCCD và đọc MRZ',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              result == null
                  ? 'Chụp mặt trước, sau đó quét vùng MRZ ở mặt sau.'
                  : 'Đã chụp hai mặt và đọc dữ liệu MRZ.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (result case final capture?) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _DocumentThumbnail(
                      label: 'Mặt trước',
                      bytes: capture.frontImageBytes,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DocumentThumbnail(
                      label: 'Mặt sau',
                      bytes: capture.backImageBytes,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Số CCCD nhận diện: ${capture.identityNumber}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 14),
            FilledButton.tonalIcon(
              key: const Key('start-document-capture-button'),
              onPressed: enabled ? onCapture : null,
              icon: const Icon(Icons.document_scanner_outlined),
              label: Text(result == null ? 'Chụp hai mặt CCCD' : 'Chụp lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentThumbnail extends StatelessWidget {
  const _DocumentThumbnail({required this.label, required this.bytes});

  final String label;
  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 85.6 / 54,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(bytes, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _AvailabilityCard extends StatelessWidget {
  const _AvailabilityCard({
    required this.availability,
    required this.onRefresh,
  });

  final NfcAvailability availability;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (availability) {
      NfcAvailability.available => (
        Icons.check_circle_outline,
        'NFC sẵn sàng',
        Colors.green,
      ),
      NfcAvailability.disabled => (
        Icons.toggle_off_outlined,
        'NFC đang tắt',
        Colors.orange,
      ),
      NfcAvailability.unsupported => (
        Icons.block_outlined,
        'Không hỗ trợ NFC',
        Colors.red,
      ),
      NfcAvailability.unknown => (
        Icons.help_outline,
        'Đang kiểm tra NFC',
        Colors.blueGrey,
      ),
    };

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label),
        trailing: IconButton(
          tooltip: 'Kiểm tra lại',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    super.key,
    required this.label,
    required this.value,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          enabled: enabled,
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(value == null ? 'Chạm để chọn' : _formatDate(value!)),
      ),
    );
  }
}

class _ReadStatusCard extends StatelessWidget {
  const _ReadStatusCard({
    required this.state,
    required this.onCancel,
    required this.onReset,
  });

  final NfcReadState state;
  final VoidCallback onCancel;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    if (state.phase == NfcReadPhase.idle) return const SizedBox.shrink();

    final isError = state.phase == NfcReadPhase.error;
    final isSuccess = state.phase == NfcReadPhase.success;
    return Card(
      margin: EdgeInsets.zero,
      color: isError
          ? Theme.of(context).colorScheme.errorContainer
          : isSuccess
          ? Colors.green.withValues(alpha: 0.12)
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  isError
                      ? Icons.error_outline
                      : isSuccess
                      ? Icons.check_circle_outline
                      : Icons.contactless_outlined,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    state.status,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            if (state.isReading) ...[
              const SizedBox(height: 14),
              LinearProgressIndicator(value: state.progress),
              const SizedBox(height: 8),
              Text('${(state.progress * 100).round()}%'),
              const SizedBox(height: 10),
              OutlinedButton(
                key: const Key('cancel-reading-button'),
                onPressed: onCancel,
                child: const Text('Hủy'),
              ),
            ],
            if (state.errorMessage case final message?) ...[
              const SizedBox(height: 10),
              Text(message),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final DocumentReadResult result;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Kết quả trên chip',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 14),
            if (result.portraitBytes case final bytes?) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  bytes,
                  height: 220,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const SizedBox(
                    height: 96,
                    child: Center(
                      child: Text(
                        'Đã đọc DG2 nhưng thiết bị không giải mã được ảnh.',
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            _ResultRow(label: 'Họ tên', value: result.fullName),
            _ResultRow(label: 'Số CCCD', value: result.identityNumber),
            _ResultRow(label: 'Số tài liệu MRZ', value: result.documentNumber),
            _ResultRow(
              label: 'Ngày sinh',
              value: _formatDate(result.dateOfBirth),
            ),
            _ResultRow(
              label: 'Ngày hết hạn',
              value: _formatDate(result.dateOfExpiry),
            ),
            _ResultRow(label: 'Quốc tịch', value: result.nationality),
            _ResultRow(label: 'Giới tính', value: result.gender),
            _ResultRow(
              label: 'Data groups',
              value: result.availableDataGroups.join(', '),
            ),
            _ResultRow(
              label: 'SOD',
              value: result.sodWasRead ? 'Đã đọc' : 'Không đọc được',
            ),
            const SizedBox(height: 8),
            Text(
              'Lưu ý: “Đã đọc SOD” không đồng nghĩa đã xác minh chữ ký chip với CSCA quốc gia.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 122,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: SelectableText(value.isEmpty ? '—' : value)),
        ],
      ),
    );
  }
}

String _formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
